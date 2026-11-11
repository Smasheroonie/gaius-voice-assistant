#!/data/data/com.termux/files/usr/bin/bash
# One-time setup for the voice assistant on the Fairphone (Termux).
# Run: bash setup-termux.sh
set -e

echo "== Installing packages =="
pkg install -y git cmake clang curl jq make termux-api

BASE="$HOME/assistant"
mkdir -p "$BASE/models" "$BASE/tmp"
cd "$BASE"

echo "== Building llama.cpp (CPU, ~15-30 min on the phone) =="
if [ ! -d llama.cpp ]; then
  git clone --depth 1 https://github.com/ggml-org/llama.cpp
fi
cd llama.cpp
cmake -B build -DGGML_NATIVE=ON
cmake --build build --config Release -j4
cd "$BASE"

echo "== Building whisper.cpp (~10-20 min) =="
if [ ! -d whisper.cpp ]; then
  git clone --depth 1 https://github.com/ggml-org/whisper.cpp
fi
cd whisper.cpp
cmake -B build -DGGML_NATIVE=ON
cmake --build build --config Release -j4
cd "$BASE"

echo "== Downloading models =="
# LLM: Qwen3 4B, Apache-2.0, ~2.5 GB in Q4
if [ ! -f models/Qwen3-4B-Q4_K_M.gguf ]; then
  curl -L -o models/Qwen3-4B-Q4_K_M.gguf \
    https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf
fi
# STT: Whisper small, ~466 MB
if [ ! -f models/ggml-small.bin ]; then
  curl -L -o models/ggml-small.bin \
    https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
fi

echo "== Done =="
echo "Next: run ./start-llm.sh and ./start-stt.sh in separate Termux sessions,"
echo "then ./assistant.sh in a third."
