import os
import time

from dotenv import load_dotenv
from google import genai
from google.genai import errors

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    raise RuntimeError("GEMINI_API_KEY was not found")

client = genai.Client(api_key=api_key)


def process_audio(audio_path: str, language: str = "Kannada"):
    audio_file = client.files.upload(file=audio_path)

    prompt = f"""
The patient's health information is spoken in {language}.

Process the audio and return exactly these three sections:

TRANSCRIPT:
Write the original speech in {language}.

ENGLISH:
Translate the transcript into English.

ANALYZED:
Extract the following information from the English translation:
- Patient name
- Age
- Symptoms
- Duration

Do not invent information that was not spoken.

Return exactly:

TRANSCRIPT:
<original {language} transcript>

ENGLISH:
<English translation>

ANALYZED:
Patient Name:
Age:
Symptoms:
Duration:
"""

    max_attempts = 3

    for attempt in range(1, max_attempts + 1):
        try:
            response = client.models.generate_content(
                model="gemini-3.8-flash",
                contents=[
                    audio_file,
                    prompt,
                ],
            )

            return response.text

        except errors.ServerError as e:
            # Gemini 503 errors are temporary service-side failures.
            if getattr(e, "code", None) != 503:
                raise

            if attempt == max_attempts:
                raise

            wait_seconds = 2 ** (attempt - 1)

            print(
                f"GEMINI 503: attempt {attempt}/{max_attempts}. "
                f"Retrying in {wait_seconds} seconds..."
            )

            time.sleep(wait_seconds)

    raise RuntimeError("Gemini audio processing failed")
