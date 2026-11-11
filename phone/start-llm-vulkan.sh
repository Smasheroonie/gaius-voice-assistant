#!/data/data/com.termux/files/usr/bin/bash
# Start the LLM server using the Vulkan/GPU build (port 8080).
# Build it first with:
#   pkg install vulkan-headers vulkan-loader-android
#   cd ~/assistant/llama.cpp
#   cmake -B build-vulkan -DGGML_VULKAN=ON
#   cmake --build build-vulkan --config Release -j4
#
# Notes: the first query after starting is slow (shader compilation);
# benchmark on the second query onward. If Vulkan is slower than CPU,
# keep using start-llm.sh.
BASE="$HOME/assistant"
exec "$BASE/llama.cpp/build-vulkan/bin/llama-server" \
  -m "$BASE/models/Qwen3-4B-Q4_K_M.gguf" \
  --port 8080 -t 4 -c 2048 -ngl 99
