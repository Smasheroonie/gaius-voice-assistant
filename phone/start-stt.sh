#!/data/data/com.termux/files/usr/bin/bash
# Start the Whisper speech-to-text server (port 8081).
BASE="$HOME/assistant"
exec "$BASE/whisper.cpp/build/bin/whisper-server" \
  -m "$BASE/models/ggml-small.bin" \
  --port 8081 -t 4 -l en
