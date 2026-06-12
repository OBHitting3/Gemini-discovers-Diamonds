"""faster-whisper wrapper. GPU on the 5090 by default; falls back to CPU.

Loaded lazily so the API and worker don't pay model startup cost unless
audio is processed.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Optional, Union


class WhisperTranscriber:
    _model = None  # singleton

    def __init__(
        self,
        model_size: Optional[str] = None,
        device: Optional[str] = None,
        compute_type: Optional[str] = None,
    ):
        self.model_size = model_size or os.environ.get("WHISPER_MODEL", "large-v3")
        self.device = device or os.environ.get("WHISPER_DEVICE", "cuda")
        self.compute_type = compute_type or os.environ.get("WHISPER_COMPUTE_TYPE", "float16")

    def _ensure_model(self):
        if WhisperTranscriber._model is not None:
            return WhisperTranscriber._model
        from faster_whisper import WhisperModel
        try:
            WhisperTranscriber._model = WhisperModel(
                self.model_size,
                device=self.device,
                compute_type=self.compute_type,
            )
        except Exception as e:
            # Fall back to CPU int8 if GPU init fails.
            print(f"[whisper] GPU init failed ({e}); falling back to CPU int8", flush=True)
            WhisperTranscriber._model = WhisperModel(
                self.model_size, device="cpu", compute_type="int8"
            )
        return WhisperTranscriber._model

    def transcribe(self, source: Union[str, Path, bytes]) -> dict:
        model = self._ensure_model()
        if isinstance(source, bytes):
            import io
            audio_obj = io.BytesIO(source)
        else:
            audio_obj = str(source)
        segments, info = model.transcribe(audio_obj, beam_size=5, vad_filter=True)
        text_parts: list[str] = []
        for seg in segments:
            text_parts.append(seg.text)
        return {
            "text": "".join(text_parts).strip(),
            "language": info.language,
            "language_probability": info.language_probability,
            "duration": info.duration,
        }
