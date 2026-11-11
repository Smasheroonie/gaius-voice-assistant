#!/data/data/com.termux/files/usr/bin/bash
# The glue: record -> transcribe -> LLM -> speak.
# Requires the Termux:API app (from F-Droid) installed on the phone.
set -e

LLM="http://127.0.0.1:8080"
STT="http://127.0.0.1:8081"
TMP="$HOME/assistant/tmp/query.wav"

echo "Voice assistant ready. Ctrl-C to quit."

while true; do
  read -r -p "Press Enter, then speak. Press Enter again to stop. " _

  # Record until the user presses Enter (max 15 s safety limit).
  termux-microphone-record -f "$TMP" -l 15
  read -r -p "... " _
  termux-microphone-record -q
  sleep 0.3

  # Speech -> text.
  TEXT=$(curl -s "$STT/inference" -F file=@"$TMP" | jq -r '.text // empty')
  if [ -z "$TEXT" ]; then
    echo "(didn't catch that)"
    continue
  fi
  echo "You: $TEXT"

  # Text -> LLM.
  REPLY=$(curl -s "$LLM/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg t "$TEXT" '{
      messages: [
        {role: "system", content: "You are a concise voice assistant. Answer in one or two short sentences."},
        {role: "user", content: $t}
      ]
    }')" | jq -r '.choices[0].message.content // empty')

  if [ -z "$REPLY" ]; then
    echo "(the LLM returned nothing)"
    continue
  fi
  echo "Assistant: $REPLY"

  # Speak it with Android's built-in TTS (offline, no model download).
  termux-tts-speak "$REPLY"
done
