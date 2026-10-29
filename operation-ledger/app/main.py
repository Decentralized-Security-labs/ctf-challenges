"""Operation LEDGER - FastAPI backend.

Pipeline for each /chat request:
  user question  ->  LLM writes T-SQL  ->  run_sql  ->  LLM summarizes

The raw query result is always appended to the reply, so it is never hidden
behind a model summary.
"""
import os

import httpx
from fastapi import FastAPI
from pydantic import BaseModel

from system_prompt import SYSTEM_PROMPT
from tools import extract_sql, run_sql

app = FastAPI(title="Operation LEDGER")

OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")
MODEL_NAME = os.environ.get("MODEL_NAME", "qwen2.5-coder:7b")

GEN_INSTRUCTION = (
    "User question:\n{message}\n\n"
    "If answering needs data, write ONE T-SQL query for SQL Server inside a "
    "```sql code block and nothing else. If you will not run a query, reply "
    "in plain text without a code block."
)

SUMMARY_SYSTEM = (
    "You are LEDGER, a reporting assistant. Answer the user's question using "
    "the SQL result below. Be concise and do not invent data."
)


class ChatRequest(BaseModel):
    message: str


async def _generate(system: str, prompt: str) -> str:
    async with httpx.AsyncClient(timeout=120) as client:
        r = await client.post(
            f"{OLLAMA_HOST}/api/generate",
            json={
                "model": MODEL_NAME,
                "system": system,
                "prompt": prompt,
                "stream": False,
            },
        )
        r.raise_for_status()
        return r.json().get("response", "")


def _render(blocks) -> str:
    if not blocks:
        return "(no rows returned)"
    lines = []
    for columns, rows in blocks:
        if columns:
            lines.append(" | ".join(columns))
        for row in rows:
            lines.append(" | ".join("" if v is None else str(v) for v in row))
    return "\n".join(lines) if lines else "(no rows returned)"


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/chat")
async def chat(req: ChatRequest):
    message = req.message.strip()
    if not message:
        return {"response": "Awaiting your query."}

    # 1. Ask the model to turn the question into SQL.
    try:
        generated = await _generate(SYSTEM_PROMPT, GEN_INSTRUCTION.format(message=message))
    except (httpx.HTTPError, KeyError, ValueError):
        return {"response": "LEDGER is temporarily unavailable. Try again."}

    sql = extract_sql(generated)
    if not sql:
        # No query emitted: the model chatted or refused. Pass it through.
        return {"response": generated.strip() or "I can only help with read-only reports."}

    # 2. Run whatever SQL the model produced.
    try:
        blocks = run_sql(sql)
    except Exception as exc:  # surface DB errors back to the user
        return {"response": f"Query failed: {exc}"}

    result_text = _render(blocks)

    # 3. Summarize, then always append the raw result.
    try:
        summary = await _generate(
            SUMMARY_SYSTEM,
            f"Question: {message}\n\nSQL result:\n{result_text}\n\nAnswer:",
        )
    except (httpx.HTTPError, KeyError, ValueError):
        summary = ""

    prefix = f"{summary.strip()}\n\n" if summary.strip() else ""
    return {"response": f"{prefix}[query result]\n{result_text}"}
