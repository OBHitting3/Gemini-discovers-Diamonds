#!/usr/bin/env python3
"""
Faceless Shorts Automator – Full pipeline: topic → script → voice → video → YouTube.
Run from repo root: python scripts/run_pipeline.py "Your topic here"
"""
import argparse
import os
import sys
from pathlib import Path
from typing import Optional

# Repo root
REPO_ROOT = Path(__file__).resolve().parent.parent
CONFIG_DIR = REPO_ROOT / "config"
OUTPUT_DIR = REPO_ROOT / "output"  # shorts and temp files
AI_DISCLOSURE = "Script and voice generated with AI."


def log(msg: str) -> None:
    print(f"[pipeline] {msg}")


def load_env() -> None:
    env_file = CONFIG_DIR / ".env"
    if not env_file.exists():
        log("config/.env not found. Copy .env.example and add GEMINI_API_KEY, ELEVENLABS_API_KEY.")
        sys.exit(1)
    from dotenv import load_dotenv
    load_dotenv(env_file)
    if not os.getenv("GEMINI_API_KEY") or not os.getenv("ELEVENLABS_API_KEY"):
        log("Set GEMINI_API_KEY and ELEVENLABS_API_KEY in config/.env")
        sys.exit(1)


def _fallback_script(topic: str) -> str:
    """Use when Gemini returns 429 so pipeline still completes."""
    return (
        f"Here's something you might not know. {topic}. "
        "We're keeping this short so you get the idea in under a minute. "
        "More to explore on this channel. Thanks for watching."
    ).strip()


def step_script(topic: str) -> str:
    import time
    import google.generativeai as genai
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    model = genai.GenerativeModel("gemini-2.0-flash")
    prompt = f"""Write a YouTube Shorts script for this topic: "{topic}".
Rules: Under 60 seconds when read aloud (about 150 words max). Hook in the first 3 seconds. No intro like "Hey guys" – start with the hook. Output ONLY the script, no titles or labels."""
    try:
        response = model.generate_content(prompt)
        script = (response.text or "").strip()
        if script:
            log("Script generated.")
            return script
    except Exception as e:
        if "429" in str(e):
            log("Gemini rate limit; using fallback script so pipeline completes.")
            return _fallback_script(topic)
        raise
    return _fallback_script(topic)


def step_voice(script: str, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        from elevenlabs.client import ElevenLabs
        client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))
        voice_id = os.getenv("ELEVENLABS_VOICE_ID", "21m00Tcm4TlvDq8ikWAM")
        audio = client.text_to_speech.convert(
            voice_id=voice_id,
            text=script,
            model_id="eleven_multilingual_v2",
            output_format="mp3_44100_128",
        )
        with open(out_path, "wb") as f:
            if isinstance(audio, bytes):
                f.write(audio)
            else:
                for chunk in audio:
                    f.write(chunk)
        log(f"Voice saved to {out_path}")
    except Exception as e:
        if "401" in str(e) or "missing_permissions" in str(e) or "403" in str(e):
            log("ElevenLabs permission denied; using gTTS fallback.")
            from gtts import gTTS
            tts = gTTS(text=script, lang="en")
            tts.save(str(out_path))
            log(f"Voice (gTTS) saved to {out_path}")
        else:
            raise


def step_video(audio_path: Path, image_path: Optional[Path], out_path: Path) -> None:
    from moviepy import ImageClip
    from moviepy.audio.io.AudioFileClip import AudioFileClip
    if not image_path or not image_path.exists():
        from PIL import Image
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        img_path = OUTPUT_DIR / "_default_bg.png"
        img = Image.new("RGB", (1080, 1920), color=(45, 45, 55))
        img.save(img_path)
        image_path = img_path
    audio = AudioFileClip(str(audio_path))
    clip = (
        ImageClip(str(image_path))
        .with_duration(audio.duration)
        .with_fps(24)
        .with_audio(audio)
    )
    clip.write_videofile(
        str(out_path),
        fps=24,
        codec="libx264",
        audio_codec="aac",
        ffmpeg_params=["-pix_fmt", "yuv420p"],
        logger=None,
    )
    clip.close()
    audio.close()
    log(f"Video saved to {out_path}")


def step_upload(video_path: Path, title: str, description: str) -> Optional[str]:
    token_path = CONFIG_DIR / "youtube-oauth.json"
    if not token_path.exists():
        log("config/youtube-oauth.json not found. Run: python scripts/auth_youtube.py")
        return None
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload

    SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]
    creds = None
    if token_path.exists():
        creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            client_secrets = CONFIG_DIR / "client_secrets.json"
            if not client_secrets.exists():
                log("config/client_secrets.json not found. Get OAuth client ID (Desktop) from Google Cloud Console.")
                return None
            flow = InstalledAppFlow.from_client_secrets_file(str(client_secrets), SCOPES)
            creds = flow.run_local_server(port=0)
        with open(token_path, "w") as f:
            f.write(creds.to_json())
    youtube = build("youtube", "v3", credentials=creds)
    body = {
        "snippet": {
            "title": title[:100],
            "description": description,
            "categoryId": "22",
        },
        "status": {
            "privacyStatus": "public",
            "selfDeclaredMadeForKids": False,
        },
    }
    media = MediaFileUpload(str(video_path), mimetype="video/mp4", resumable=True)
    request = youtube.videos().insert(part="snippet,status", body=body, media_body=media)
    response = request.execute()
    video_id = response.get("id")
    log(f"Uploaded: https://youtube.com/shorts/{video_id}")
    return video_id


def main() -> int:
    parser = argparse.ArgumentParser(description="Faceless Shorts: topic → Short on YouTube")
    parser.add_argument("topic", help="Topic for the Short (e.g. 'Why the sky is blue')")
    parser.add_argument("--no-upload", action="store_true", help="Build video only; do not upload")
    parser.add_argument("--image", type=Path, help="Path to 9:16 background image (1080x1920)")
    args = parser.parse_args()

    load_env()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    topic = args.topic.strip()
    if not topic:
        log("Provide a topic.")
        return 1

    # Sanitize for filenames
    safe_name = "".join(c if c.isalnum() or c in " -_" else "_" for c in topic)[:50]
    audio_path = OUTPUT_DIR / f"{safe_name}.mp3"
    video_path = OUTPUT_DIR / f"{safe_name}.mp4"

    try:
        script = step_script(topic)
        step_voice(script, audio_path)
        step_video(audio_path, args.image, video_path)
        if not args.no_upload:
            desc = f"{topic}\n\n{AI_DISCLOSURE}"
            step_upload(video_path, title=f"{topic} | Short", description=desc)
        else:
            log("Skipped upload (--no-upload). Video ready: " + str(video_path))
    except Exception as e:
        log(f"Error: {e}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
