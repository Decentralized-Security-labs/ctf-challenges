"""Loads the rendered system prompt at runtime.

The real prompt (with the flag substituted in) is written to
system_prompt.txt at build time by the Dockerfile's flag-injection RUN
step. It is never committed to the repo — only the template is.
"""
from pathlib import Path

_PROMPT_PATH = Path(__file__).parent / "system_prompt.txt"

SYSTEM_PROMPT = _PROMPT_PATH.read_text()
