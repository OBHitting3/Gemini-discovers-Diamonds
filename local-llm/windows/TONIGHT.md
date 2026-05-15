# Tonight — get the PC ready for 6 AM

Phone in one hand, this in the other. Five checkpoints. After each, **text me what you see** and I'll send the next.

**The key move:** once Checkpoint 3 (Sunshine + Moonlight) is done, you can run the rest of the setup *from your phone, from anywhere on the Wi-Fi.* You don't have to keep sitting at the PC.

---

## Checkpoint 1 — Power on, get to the desktop

1. Press the power button on the front of the tower.
2. Wait for fans to spin and the monitor to light up.
3. Click through any Windows first-time setup screens (language, country, keyboard, Wi-Fi, account, name).
4. Stop when you see the Windows **desktop** — a wallpaper with icons and a taskbar.

**Text me:** "Desktop is up" — or describe whatever screen you're stuck on.

---

## Checkpoint 2 — Confirm internet works

1. Bottom-right of the screen, near the clock — small network icon.
   - Wi-Fi waves or an ethernet plug = connected.
   - Globe with a slash = not connected.
2. If not connected: click the network icon → click your home Wi-Fi → password → Connect.
3. Open Microsoft Edge (blue swirly "e"). Go to **google.com**. If the search page loads, internet works.

**Text me:** "Internet works" — or "stuck at <whatever>."

---

## Checkpoint 3 — Sunshine on the PC + Moonlight on the phone

Sunshine streams the PC's screen + keyboard/mouse to your phone over Wi-Fi. Moonlight is the phone app that receives it. Open source. Free. Low latency.

### On the PC

1. In Edge, go to: **https://github.com/LizardByte/Sunshine/releases**
2. The top entry is the latest release. Scroll to **Assets**. Click **sunshine-windows-installer.exe**.
3. When it finishes downloading, run it. Click through Next → Install → Finish. If Windows asks to run as administrator, say yes. If it offers to install the ViGEm gamepad driver, accept (harmless if you don't use a gamepad).
4. After install, Sunshine opens a browser tab at **https://localhost:47990**.
5. Browser will warn "your connection isn't private" — that's expected for localhost. Click **Advanced → Continue to localhost (unsafe)**.
6. Sunshine asks you to create a username and password. **Write them down.** You'll need them in 30 seconds.

### On the phone

7. Install **Moonlight Game Streaming** from the App Store (iOS) or Play Store (Android). The icon is a small purple/blue moon.
8. Open Moonlight. Make sure your phone is on the **same Wi-Fi** as the PC.
9. The PC's name appears as a tile in Moonlight. Tap it.
10. A 4-digit PIN appears on your phone.
11. Back on the PC: in the Sunshine browser tab, click **PIN** in the left menu → type the PIN → **Send**.
12. The phone shows "paired." Tap the **Desktop** entry — your PC's screen now appears full-screen on your phone, and you control it with touch.

**Text me:** "Paired, I'm in" — or where it got stuck.

> From this point on, you can be on the couch. Everything below is done through Moonlight (or stay at the PC — either works).

---

## Checkpoint 4 — Install LM Studio + download a model

LM Studio is one app. Chat, models, memory — all in one window. No terminal.

1. On the PC screen (or via Moonlight from your phone), open Edge. Go to **https://lmstudio.ai**
2. Click **Download for Windows**.
3. When the download finishes, run the installer. Next → Next → Install → Finish. LM Studio opens.
4. Left side, click the **magnifying glass** icon (Discover).
5. Search for: **llama-3.1-8b-instruct**
6. On the top result, click the green **Download** button. ~5 GB. 10–20 minutes.

**Text me when the green "Downloaded" check appears:** "Model downloaded."

---

## Checkpoint 5 — System prompt + test message

1. Left side of LM Studio, click the **speech-bubble** icon (Chat).
2. Model dropdown at top → pick **Llama 3.1 8B Instruct**.
3. Right side, find **System Prompt**. Open it.
4. Paste the contents of `local-llm/windows/system-prompt.txt` (I'll text you the exact text too).
5. In the chat box, type: **What do you remember about me?**

**Text me:** "It replied" + paste the reply.

---

## After Checkpoint 5 — pin for tomorrow

1. Right-click the LM Studio icon on the taskbar → **Pin to taskbar**.
2. Right-click the desktop → New → Shortcut → browse to LM Studio → name it "LLM" → Finish.
3. Close everything. Walk away. Sleep.

## 6 AM tomorrow

One click on the LLM icon. App opens. Type. Done.

If you'd rather run it from your phone tomorrow: open Moonlight → tap Desktop → tap the LLM icon. Same result.
