# Voice assistant on the Fairphone (Termux)

Everything runs on the phone: Whisper for speech-to-text, Qwen3 4B as the
LLM, Android's built-in TTS for speech. No cloud, no accounts.

## Fresh install, from zero

1. Install **F-Droid** (from f-droid.org in the browser, allowing the
   "unknown sources" prompt).
2. From F-Droid, install **Termux** and **Termux:API**. Never mix in the
   Play Store Termux; it is incompatible with F-Droid add-ons.
3. Android Settings → Apps → Termux → Permissions → allow Microphone.
   Same for the Termux:API app.
4. Android Settings → Apps → Termux → Battery → **Unrestricted**, so
   Android doesn't kill long builds.
5. Copy this `phone/` directory onto the phone (e.g. download the zip,
   then in Termux: `pkg install unzip` and unzip it into `~/phone`).
6. In Termux:

       cd ~/phone
       bash setup-termux.sh

   This realigns the known Termux curl/openssl mismatch, installs all
   packages, builds llama.cpp and whisper.cpp (30-60 min total, phone
   plugged in and screen on), and downloads the models (~3 GB).

## Running

First, if you unzipped manually, make the scripts executable (Android's
unzip drops the permission bit):

    chmod +x *.sh

Then, three Termux sessions (swipe from the left edge → New session):

    ./start-llm.sh     # session 1: LLM on port 8080
    ./start-stt.sh     # session 2: Whisper on port 8081
    ./assistant.sh     # session 3: the assistant loop

assistant.sh prints per-stage timings (speech/convert/stt/llm/tts/total
in ms) after every turn.

## Troubleshooting notes (learned the hard way)

- `CANNOT LINK EXECUTABLE ... libcurl.so`: run
  `pkg reinstall -y curl openssl openssl-tool git` (setup does this).
- Recordings are AAC in disguise: termux-microphone-record ignores the
  extension, so the script records .m4a and converts with ffmpeg to
  16 kHz mono WAV for Whisper.
- termux-microphone-record refuses to overwrite an existing file; the
  script deletes the previous recording first.
- If a server response isn't JSON, the script prints it raw: read what
  stage said what.

## Appendix: optional Vulkan/GPU build

Worth it only if the CPU benchmark bothers you. Expect the first query
after starting to be slow (shader compilation); judge from the second.

    pkg install vulkan-headers glslc        # or: pkg install glslang,
                                            # then build shaderc from
                                            # source if glslc is missing
    pkg install spirv-headers               # + spirv-tools if asked for
    cd ~/assistant/llama.cpp
    cmake -B build-vulkan -DGGML_VULKAN=ON \
      -DVulkan_INCLUDE_DIR=$PREFIX/include \
      -DVulkan_LIBRARY=/system/lib64/libvulkan.so
    cmake --build build-vulkan -j2

Then use ./start-llm-vulkan.sh instead of ./start-llm.sh. If Vulkan is
slower than CPU, keep using the CPU build. Do NOT install swiftshader
to satisfy dependencies: it is software rendering and makes the
benchmark meaningless.

## Benchmark log

| Hardware / backend | Result |
|---|---|
| i7-6700K, GLM-4-9B Q4, CPU | 3.66 tok/s |
| Fairphone 6, Qwen3 4B Q4, CPU | 7.24 tok/s (first end-to-end run) |
| Fairphone 6, Qwen3 4B Q4, Vulkan | (fill in) |

## Migration path

When the home server exists, change `LLM=` in assistant.sh to the
server's Tailscale address. Nothing else changes: the phone keeps
Whisper and TTS, the server runs the bigger model.
