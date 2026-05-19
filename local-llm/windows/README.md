# Windows setup — the whole plan, one page

**Tonight (~45–75 min, mostly waiting):** [TONIGHT.md](TONIGHT.md). Five checkpoints, one at a time. Text me what you see after each.

- C1: power on
- C2: internet
- C3: **Sunshine on PC + Moonlight on phone** — pairs them so the rest can be done from your phone
- C4: install LM Studio + download model
- C5: paste system prompt + test

**Tomorrow 6 AM:** [MORNING.md](MORNING.md). One click — at the PC or via Moonlight on your phone.

**The system prompt to paste at Checkpoint 5:** [system-prompt.txt](system-prompt.txt).

## Why LM Studio (not Ollama, not Open WebUI, not Docker)

- One app. One installer. No terminal. No GitHub on this PC.
- Built-in chat UI. Conversations save automatically to this PC.
- Built-in system prompt field — that's where your "about me" and voice samples go.
- Native Windows. Uses your GPU automatically. CyberPower-class hardware will be fast.

The fancier stacks (Ollama + Open WebUI) add three more moving parts that don't help you do anything new — they just add things that can break at 6 AM.

## The principle

Two text files = your whole profile:
- "About this user" section (top of `system-prompt.txt`) = facts you want it to know.
- "How this user talks" section (middle of `system-prompt.txt`) = paragraphs of your writing.

Edit either one anytime by opening LM Studio → System Prompt panel → edit → save the chat. Done.

To wipe the slate: clear those two sections. Model goes blank.
