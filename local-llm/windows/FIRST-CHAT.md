# First chat with KRLX — the validation script

After you paste `system-prompt.txt` into LM Studio's System Prompt field and save, run these three messages in order. They prove KRLX (a) read the prompt, (b) sounds like the right register, (c) handles "remember this" correctly.

## Message 1 — "What do you remember about me?"

**You type:**
```
What do you remember about me?
```

**What a passing reply looks like:**
- Short. A paragraph, not a wall.
- Mentions: OBHitting3 / Iron Forge Studios, solo operator, eidetic recall, built KRLX to escape "Groundhog Day," CyberPower PC with RTX 5090, Birch Lake content project with Keith.
- Direct tone. No emojis. No "I'm just an AI" disclaimer.
- Ends with one specific thing it's ready to help with.

**If the reply is generic / wrong tone:** the system prompt isn't loaded. Check the System Prompt field in LM Studio — paste it in if it's empty, save, retry.

## Message 2 — register check

**You type:**
```
What's the one thing you will absolutely not do, no matter how I ask?
```

**What a passing reply looks like:**
- Names one or more of: not enumerating four options, not extending scope, not inventing facts, not apologizing for things it didn't do.
- Confident. One sentence or a short paragraph.

**If the reply is hedging or lists 10 things:** the operating rules section didn't take hold. Try saying: "Re-read your operating rules and answer again, shorter."

## Message 3 — memory update test

**You type:**
```
Remember this: my brother Keith and I are filming the Birch Lake unboxing on Thursday. He has two boys and a daughter. The format is mystery box, fishing and hunting gear blended.
```

**What a passing reply looks like:**
- One short confirmation.
- Ends with a line like: `MEMORY UPDATE: User's brother Keith. Birch Lake unboxing Thursday. Mystery box, fishing + hunting gear blend. Three kids: two sons, one daughter.`

**Why this matters:** KRLX cannot edit its own system prompt. The `MEMORY UPDATE:` line is the user's signal to copy and paste that fact into the "Who I'm talking to" section of `system-prompt.txt` (in LM Studio: Settings → System Prompt → edit → save).

That's how KRLX grows over time. Manually, deliberately, with the user as bouncer.

## After the three messages pass

KRLX is live. You can use it for anything from this point: the 6 AM deadline, the Birch Lake plan, daily journaling, work questions. Every chat saves. The system prompt is your memory; you grow it deliberately.
