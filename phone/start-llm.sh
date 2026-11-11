#!/data/data/com.termux/files/usr/bin/bash
# Start the LLM server (OpenAI-compatible API on port 8080).
# 4 threads = the 4 performance cores of the Snapdragon 7s Gen 3.
BASE="$HOME/assistant"
exec "$BASE/llama.cpp/build/bin/llama-server" \
  -m "$BASE/models/Qwen3-4B-Q4_K_M.gguf" \
  --port 8080 -t 4 -c 2048
