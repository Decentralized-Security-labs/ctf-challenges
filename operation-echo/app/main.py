"""Operation ECHO — FastAPI backend.

Pipeline for each /chat request:
  language gate  ->  input filter  ->  LLM call  ->  output filter
"""
import os

import httpx
from fastapi import FastAPI
from pydantic import BaseModel

from filters import input_filter_blocked, is_english, output_filter_redact
from system_prompt import SYSTEM_PROMPT

app = FastAPI(title="Operation ECHO")

OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")
MODEL_NAME = os.environ.get("MODEL_NAME", "llama3.2:3b")

NOT_AUTHORIZED = "I'm not authorized to discuss that."
NON_ENGLISH = "ECHO only communicates in English."


class ChatRequest(BaseModel):
    message: str


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/chat")
async def chat(req: ChatRequest):
    message = req.message.strip()

    if not message:
        return {"response": "Awaiting your query."}

    # 1. Language gate — English only.
    if not is_english(message):
        return {"response": NON_ENGLISH}

    # 2. Input filter — block direct-override phrasing.
    if input_filter_blocked(message):
        return {"response": NOT_AUTHORIZED}

    # 3. LLM call.
    try:
        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(
                f"{OLLAMA_HOST}/api/generate",
                json={
                    "model": MODEL_NAME,
                    "system": SYSTEM_PROMPT,
                    "prompt": message,
                    "stream": False,
                },
            )
            r.raise_for_status()
            raw = r.json().get("response", "")
    except (httpx.HTTPError, KeyError, ValueError):
        return {"response": "ECHO is temporarily unavailable. Try again."}

    # 4. Output filter — redact the flag in cleartext.
    return {"response": output_filter_redact(raw)}
