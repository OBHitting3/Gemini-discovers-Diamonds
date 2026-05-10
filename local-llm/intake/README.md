# Intake — your bouncer's desk

Old files don't get to walk into the model on their own. They go through here.

## The flow

1. Drop files into `inbox/`.
2. Double-click `triage.command`. It shows you one file at a time.
   - **k** = keep (moves to `keep/`)
   - **d** = discard (moves to `discard/` — still on disk, you can pull it back)
   - **s** = skip for later
   - **q** = quit
3. After triage, jot what you actually want the model to know into `memory.md`.
4. Paste a few paragraphs that sound like you into `voice.md`.
5. Double-click `build-system-prompt.command`. It copies a system prompt to your clipboard.
6. In Open WebUI, paste it under **Settings → Models → System Prompt**.

That's the whole loop.

## What's a "good" memory.md entry?

Short. One bullet per fact. The model reads this every chat, so don't let it bloat.

```
- I run Iron Forge Studios out of Palm Springs.
- My oldest brother is Keith. We're shooting outdoors content with his kids.
- I prefer concrete instructions over options.
```

## What's a "good" voice.md?

Anything you wrote. Three to five paragraphs is plenty. Don't perform — paste real text.

## To wipe the slate

Delete `memory.md` and `voice.md`. Done. The model goes blank.

## To keep the slate

These two files are your whole profile. Back them up by copying them anywhere. That's the whole portability story.
