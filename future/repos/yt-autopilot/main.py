#!/usr/bin/env python3
"""YouTube Autopilot - First video generator"""
import os
import sys
import logging
from pathlib import Path
from dotenv import load_dotenv
from openai import OpenAI
from elevenlabs.client import ElevenLabs
from elevenlabs import save
from PIL import Image, ImageDraw
from moviepy.editor import ImageClip, AudioFileClip, CompositeVideoClip, TextClip
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

load_dotenv()
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

def generate_script(topic: str) -> str:
    """Generate script with OpenAI"""
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
            prompt = f"""Create a 60-second YouTube video script about: {topic}

            Requirements:
            - Hook viewers in first 5 seconds
            - Conversational, energetic tone  
            - Clear intro, body, conclusion
            - End with call-to-action
            - 150-180 words total

            Return ONLY narration text."""
                
                    logger.info("Generating script...")
                        response = client.chat.completions.create(
                                model="gpt-4o",
                                        messages=[{"role": "user", "content": prompt}],
                                                max_tokens=2000,
                                                        temperature=0.7
                                                            )
                                                                return response.choices[0].message.content.strip()

                                                                def synthesize_voice(script: str, output_dir: Path) -> Path:
                                                                    """Synthesize voice with ElevenLabs"""
                                                                        client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))
                                                                            logger.info("Synthesizing voice...")
                                                                                audio = client.generate(text=script, voice="pNInz6obpgDQGcFmaJgB", model="eleven_monolingual_v1")
                                                                                    audio_path = output_dir / "narration.mp3"
                                                                                        save(audio, str(audio_path))
                                                                                            return audio_path

                                                                                            def assemble_video(script: str, audio_path: Path, output_dir: Path) -> Path:
                                                                                                """Create video with background and text"""
                                                                                                    logger.info("Creating video...")
                                                                                                        
                                                                                                            # Background gradient
                                                                                                                img = Image.new('RGB', (1920, 1080), color='#1a1a2e')
                                                                                                                    draw = ImageDraw.Draw(img)
                                                                                                                        for y in range(1080):
                                                                                                                                color_value = int(26 + (y / 1080) * 30)
                                                                                                                                        draw.line([(0, y), (1920, y)], fill=(color_value, color_value, color_value + 20))
                                                                                                                                            
                                                                                                                                                bg_path = output_dir / "background.png"
                                                                                                                                                    img.save(bg_path)
                                                                                                                                                        
                                                                                                                                                            # Load audio for duration
                                                                                                                                                                audio = AudioFileClip(str(audio_path))
                                                                                                                                                                    duration = audio.duration
                                                                                                                                                                        
                                                                                                                                                                            # Create clips
                                                                                                                                                                                bg_clip = ImageClip(str(bg_path)).set_duration(duration)
                                                                                                                                                                                    title_text = TextClip("AI Content Automation", fontsize=70, color='white', font='Arial-Bold', method='caption', size=(1720, None)).set_position('center').set_duration(duration)
                                                                                                                                                                                        
                                                                                                                                                                                            video = CompositeVideoClip([bg_clip, title_text]).set_audio(audio)
                                                                                                                                                                                                
                                                                                                                                                                                                    output_path = output_dir / "final_video.mp4"
                                                                                                                                                                                                        video.write_videofile(str(output_path), fps=30, codec='libx264', audio_codec='aac', logger=None)
                                                                                                                                                                                                            return output_path

                                                                                                                                                                                                            def upload_to_youtube(video_path: Path, title: str, description: str) -> str:
                                                                                                                                                                                                                """Upload to YouTube"""
                                                                                                                                                                                                                    logger.info("Authenticating with YouTube...")
                                                                                                                                                                                                                        client_secrets = os.getenv("YOUTUBE_CLIENT_SECRETS_FILE", "client_secrets.json")
                                                                                                                                                                                                                            flow = InstalledAppFlow.from_client_secrets_file(client_secrets, ['https://www.googleapis.com/auth/youtube.upload'])
                                                                                                                                                                                                                                credentials = flow.run_local_server(port=8080)
                                                                                                                                                                                                                                    youtube = build('youtube', 'v3', credentials=credentials)
                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                            body = {
                                                                                                                                                                                                                                                    'snippet': {'title': title, 'description': f"{description}\\n\\n🤖 Generated with AI", 'tags': ['AI', 'automation'], 'categoryId': '28'},
                                                                                                                                                                                                                                                            'status': {'privacyStatus': 'public'}
                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                        media = MediaFileUpload(str(video_path), chunksize=-1, resumable=True)
                                                                                                                                                                                                                                                                            request = youtube.videos().insert(part='snippet,status', body=body, media_body=media)
                                                                                                                                                                                                                                                                                response = request.execute()
                                                                                                                                                                                                                                                                                    return response['id']

                                                                                                                                                                                                                                                                                    def main():
                                                                                                                                                                                                                                                                                        logger.info("🚀 YouTube Autopilot Starting...")
                                                                                                                                                                                                                                                                                            topic = "Introduction to AI Content Automation"
                                                                                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                                                    try:
                                                                                                                                                                                                                                                                                                            output_dir = Path("output")
                                                                                                                                                                                                                                                                                                                    output_dir.mkdir(exist_ok=True)
                                                                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                                                                                    script = generate_script(topic)
                                                                                                                                                                                                                                                                                                                                            logger.info(f"Script: {script[:100]}...")
                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                            audio_path = synthesize_voice(script, output_dir)
                                                                                                                                                                                                                                                                                                                                                                    logger.info(f"Audio: {audio_path}")
                                                                                                                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                                                                                                                                    video_path = assemble_video(script, audio_path, output_dir)
                                                                                                                                                                                                                                                                                                                                                                                            logger.info(f"Video: {video_path}")
                                                                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                                                                            video_id = upload_to_youtube(video_path, topic, script)
                                                                                                                                                                                                                                                                                                                                                                                                                    logger.info(f"✅ SUCCESS! https://youtube.com/watch?v={video_id}")
                                                                                                                                                                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                                                                                                                                                                                except Exception as e:
                                                                                                                                                                                                                                                                                                                                                                                                                                        logger.error(f"❌ ERROR: {e}")
                                                                                                                                                                                                                                                                                                                                                                                                                                                sys.exit(1)

                                                                                                                                                                                                                                                                                                                                                                                                                                                if __name__ == "__main__":
                                                                                                                                                                                                                                                                                                                                                                                                                                                    main()