#!/data/data/com.termux/files/usr/bin/bash
# The glue: record -> transcribe -> LLM -> speak.
# Requires the Termux:API app (from F-Droid) installed on the phone.
# Each stage is timed in milliseconds; the summary prints after every turn.
set -e

LLM="http://127.0.0.1:8080"
STT="http://127.0.0.1:8081"
TMP="$HOME/assistant/tmp/query"

# Millisecond timestamps.
stamp() { date +%s%N; }
ms() { echo $(( ($2 - $1) / 1000000 )); }

echo "Voice assistant ready. Ctrl-C to quit."

while true; do
  read -r -p "Press Enter, then speak. Press Enter again to stop. " _

  # Record until the user presses Enter (max 15 s safety limit).
  # termux-microphone-record refuses to overwrite an existing file, so
  # clear the previous recording first. It always produces AAC audio
  # regardless of the file extension, so record to .m4a and convert to
  # 16 kHz mono WAV for Whisper.
  rm -f "$TMP.m4a" "$TMP.wav"
  T_REC=$(stamp)
  termux-microphone-record -f "$TMP.m4a" -l 15
  read -r -p "... " _
  termux-microphone-record -q
  sleep 0.3
  T_CONV=$(stamp)
  ffmpeg -y -loglevel error -i "$TMP.m4a" -ar 16000 -ac 1 "$TMP.wav"

  # Speech -> text.
  T_STT=$(stamp)
  RAW=$(curl -s "$STT/inference" -F file=@"$TMP.wav")
  TEXT=$(echo "$RAW" | jq -r '.text // empty') || { echo "STT said: $RAW"; continue; }
  if [ -z "$TEXT" ]; then
    echo "(didn't catch that)"
    continue
  fi
  T_LLM=$(stamp)
  echo "You: $TEXT"

  # Text -> LLM.
  RAW=$(curl -s "$LLM/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg t "$TEXT" '{
      messages: [
        {role: "system", content: "You are a concise voice assistant. Answer in one or two short sentences."},
        {role: "user", content: $t}
      ]
    }')")
  REPLY=$(echo "$RAW" | jq -r '.choices[0].message.content // empty') || { echo "LLM said: $RAW"; continue; }

  if [ -z "$REPLY" ]; then
    echo "(the LLM returned nothing)"
    continue
  fi
  T_TTS=$(stamp)
  echo "Assistant: $REPLY"

  # Speak it with Android's built-in TTS (offline, no model download).
  termux-tts-speak "$REPLY"
  T_END=$(stamp)

  echo "Timings (ms): speech=$(ms $T_REC $T_CONV) convert=$(ms $T_CONV $T_STT) stt=$(ms $T_STT $T_LLM) llm=$(ms $T_LLM $T_TTS) tts=$(ms $T_TTS $T_END) total=$(ms $T_REC $T_END)"
done
