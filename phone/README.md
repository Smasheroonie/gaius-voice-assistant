# Voice assistant on the Fairphone (Termux)

Everything runs on the phone: Whisper for speech-to-text, Qwen3 4B as the
LLM, Android's built-in TTS for speech. No cloud, no accounts.

## Prerequisites

1. Install F-Droid, then install **Termux** and **Termux:API** from it
   (both are needed; Termux:API is the app plus the `termux-api` package
   that setup installs inside Termux).
2. Grant Termux microphone permission (Android Settings → Apps → Termux →
   Permissions).

## Setup

In Termux:

    bash setup-termux.sh

This builds llama.cpp and whisper.cpp from source (expect 30-60 minutes
total on the phone) and downloads the two models (~3 GB). Keep the phone
plugged in during this.

## Running

Three Termux sessions (swipe from the left edge → New session):

    ./start-llm.sh     # session 1: LLM on port 8080
    ./start-stt.sh     # session 2: Whisper on port 8081
    ./assistant.sh     # session 3: the assistant loop

## Notes

- First response after starting the LLM is slow (model load); later ones
  are faster.
- Expect roughly 3-8 tokens/second on CPU. The Vulkan/GPU build is a
  later optimisation; the scripts are written so nothing else changes
  when you switch.
- The system prompt in assistant.sh keeps replies short on purpose:
  every token is spoken latency. Tune it once things work.
- When the home server exists, change LLM= to point at its Tailscale IP
  and nothing else in this directory needs to change.
