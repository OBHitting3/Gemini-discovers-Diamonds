# Tonight — get the PC ready for 6 AM

You're at the CyberPower PC. Phone in one hand, this in the other.
Four checkpoints. After each one, **text me what you see** and I'll send the next.

---

## Checkpoint 1 — Power on, get to the desktop

1. Press the power button on the front of the tower.
2. Wait for fans to spin and the monitor to light up.
3. Click through any Windows first-time setup screens (language, country, keyboard, Wi-Fi, Microsoft account or local account, name).
4. Stop when you see the Windows **desktop** — a wallpaper with icons and a taskbar across the bottom.

**Text me:** "Desktop is up" — or describe whatever screen you're stuck on.

---

## Checkpoint 2 — Confirm internet works

1. Look at the bottom-right of the screen, near the clock. There's a small network icon.
   - Wi-Fi waves or an ethernet plug = connected.
   - Globe with a circle through it = not connected.
2. If not connected: click the network icon → click your home Wi-Fi name → type the password → Connect.
3. Open Microsoft Edge (the blue swirly "e" icon). Go to **google.com**. If a search page loads, internet works.

**Text me:** "Internet works" — or "stuck at <whatever>."

---

## Checkpoint 3 — Install LM Studio and download a model

LM Studio is one app. Chat, models, memory — all in one window. No terminal.

1. In Edge, go to **https://lmstudio.ai**
2. Click **Download for Windows**.
3. When the download finishes (bottom of the browser, or in your Downloads folder), double-click the installer.
4. Click Next → Next → Install → Finish. LM Studio opens.
5. On the left side of the LM Studio window, click the **magnifying glass** icon (Discover).
6. In the search box, type: **llama-3.1-8b-instruct**
7. On the top result, click the green **Download** button. ~5 GB. 10–20 minutes depending on your connection.

**Text me when the green "Downloaded" check appears:** "Model downloaded."

---

## Checkpoint 4 — System prompt + test message

1. On the left side of LM Studio, click the **speech-bubble** icon (Chat).
2. At the top of the window, click the model dropdown → pick **Llama 3.1 8B Instruct**.
3. On the right side of the screen there's a panel. Find the field labeled **System Prompt**.
4. Open the file `local-llm/windows/system-prompt.txt` from this repo (I'll text you the exact text too). Copy the whole thing. Paste it in.
5. In the chat box at the bottom, type: **What do you remember about me?**
6. Send.

**Text me:** "It replied" + paste what it said.

---

## After Checkpoint 4 — pin for tomorrow

1. Find LM Studio on the taskbar (the icon at the bottom of the screen).
2. Right-click it → **Pin to taskbar**.
3. Right-click the desktop → New → Shortcut → browse to LM Studio → name it "LLM" → Finish. Now you have a big desktop icon too.
4. Close everything. Walk away. Sleep.

## 6 AM tomorrow

One click on that icon. App opens. Type. Done.
