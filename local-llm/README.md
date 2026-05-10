# Your local LLM (with memory)

Three buttons. That's it.

1. **`setup.command`** — double-click once. Installs everything. ~10 min, ~2 GB download.
2. **`start.command`** — double-click whenever you want to chat. Opens your browser to it.
3. **`stop.command`** — double-click to shut it all down.

## Why this fixes the "I thought you remembered" problem

Cloud LLMs (Claude, ChatGPT, Cursor) **forget every session**. Each new chat is a stranger.

This setup is different:

- Every conversation is saved to a local SQLite database on your Mac, forever.
- You can pin facts to **Settings → Personalization → Memory** and the model will see them in every new chat.
- Nothing leaves your machine.

## What's running

- **Ollama** — runs the model locally, on your Mac's CPU/GPU.
- **Llama 3.2 3B** — the model (small, fast, fits anywhere).
- **Open WebUI** — the ChatGPT-style chat interface, at `http://localhost:8080`.

## Want a smarter model later?

Open Terminal, run:

```
ollama pull llama3.1:8b
```

Then pick it from the model dropdown in the chat UI. (Needs ~16 GB RAM to feel good.)

## If something breaks

- Logs: `local-llm/open-webui.log`
- Reinstall: just double-click `setup.command` again — it's idempotent.
