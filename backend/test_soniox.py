import os
from dotenv import load_dotenv
from soniox import SonioxClient
from soniox.types import CreateTranscriptionConfig

load_dotenv()

api_key = os.getenv("SONIOX_API_KEY")

if not api_key:
    raise RuntimeError("SONIOX_API_KEY was not found")

client = SonioxClient(api_key=api_key)

config = CreateTranscriptionConfig(
    language_hints=["kn"],
    language_hints_strict=True,
    enable_speaker_diarization=False,
    enable_language_identification=False,
    translation={
        "type": "one_way",
        "target_language": "en",
    },
)

result = client.stt.transcribe(
    file="kannda.ogg",
    model="stt-async-v5",
    config=config,
)

client.stt.wait(result.id)

status = client.stt.get(result.id)

print("\n--- SONIOX STATUS ---")
print("Status:", status.status)
print("Error type:", status.error_type)
print("Error message:", status.error_message)

if status.status == "completed":
    transcript = client.stt.get_transcript(result.id)

    print("\n--- SONIOX RESULT ---")
    print(transcript.text)