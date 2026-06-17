---
name: local-tts
description: "Generate, verify, and benchmark the local OmniVoice-Studio and VoxCPM text-to-speech setups on this machine. Use when the user asks whether OmniVoice-Studio or voxcpm can run locally, wants sample speech generation, wants movie/video narration voiceover, wants final-effect/performance comparisons, or wants to integrate these local TTS engines into a skill or workflow."
---

# Local TTS

## Quick Start

Use the generation runner for normal TTS output:

```bash
python /home/slam/.codex/skills/local-tts/scripts/tts_generate.py --engine auto --device auto --text "你好，这是本地语音合成测试。" --output /tmp/local_tts.wav --report-json /tmp/local_tts.json
```

Use the benchmark runner when the user wants performance numbers:

```bash
python /home/slam/.codex/skills/local-tts/scripts/tts_benchmark.py --device both --out-dir /tmp/tts_bench_run
```

Default assumptions:
- OmniVoice-Studio repo: `/home/slam/OmniVoice-Studio`
- Python env: `/home/slam/OmniVoice-Studio/.venv`
- OmniVoice CLI: `/home/slam/OmniVoice-Studio/.venv/bin/omnivoice-infer`
- VoxCPM package installed inside the same venv

If `CUDA_VISIBLE_DEVICES` is set incorrectly, unset it for GPU tests. For CPU tests, the runners force `CUDA_VISIBLE_DEVICES=""`.

## Workflow

1. Check environment:
   - Run `env -u CUDA_VISIBLE_DEVICES /home/slam/OmniVoice-Studio/.venv/bin/python -c "import torch, voxcpm; print(torch.__version__, torch.cuda.is_available(), torch.cuda.device_count())"`.
   - Run `nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader` before GPU tests.
2. Use `tts_generate.py` for a normal short output file. Request `--report-json` when another agent or script needs structured output.
3. For user-facing narration longer than a few sentences, use the checked-delivery workflow below instead of one long raw generation.
4. Use `tts_benchmark.py` for wall-clock time, audio duration, RTF, sample rate, output path, and failures.
5. Separate cold-start/compile overhead from steady-state speed when interpreting VoxCPM GPU results.
6. Do not kill GPU processes unless the user explicitly authorizes it.

## Checked Delivery Workflow

Use this workflow before giving the user a local TTS result or uploading it to Baidu Netdisk.

1. Split long narration into short sentence groups and generate each chunk separately.
   - Keep a chunk to roughly 1-2 sentences.
   - Prefer OmniVoice with `--postprocess_output True` for these chunks if calling `omnivoice-infer` directly.
   - Use stable narration settings such as `--language Chinese --speed 0.95 --num_step 8 --instruct "男，青年，低音调"` unless the user asks for a different voice.
2. Concatenate chunks with `ffmpeg` or another audio tool; insert only short, intentional pauses.
3. Convert the deliverable to MP3 for compatibility:

```bash
ffmpeg -y -hide_banner -i input.wav \
  -af 'highpass=f=80,lowpass=f=8000,loudnorm=I=-16:TP=-1.5:LRA=11' \
  -ar 48000 -ac 1 -codec:a libmp3lame -b:a 192k output.mp3
```

4. Verify technical decode and loudness:

```bash
ffprobe -v error -show_entries format=duration,size,bit_rate:stream=codec_name,sample_rate,channels -of json output.mp3
ffmpeg -hide_banner -nostats -i output.mp3 -af silencedetect=noise=-35dB:d=0.8,volumedetect -f null -
```

5. Verify audible speech with ASR before delivery. Use faster-whisper from the OmniVoice venv; on this dual-GPU machine, `CUDA_VISIBLE_DEVICES=1` selects the RTX 4090:

```bash
CUDA_VISIBLE_DEVICES=1 /home/slam/OmniVoice-Studio/.venv/bin/python - <<'PY'
from faster_whisper import WhisperModel
path = "output.mp3"
model = WhisperModel("small", device="cuda", compute_type="float16")
segments, info = model.transcribe(path, language="zh", beam_size=5, vad_filter=False)
texts = []
last_end = 0.0
for seg in segments:
    texts.append(seg.text.strip())
    last_end = max(last_end, float(seg.end))
    print(f"[{seg.start:.2f}-{seg.end:.2f}] {seg.text.strip()}")
print({"language": info.language, "duration": info.duration, "last_end": last_end, "text": "".join(texts)})
PY
```

Pass criteria:
- `ffprobe` duration and file size are plausible for the requested output.
- `volumedetect` mean volume is not near silence, and `silencedetect` does not show large unintended blank spans.
- ASR returns recognizable speech across the whole file, especially near the end.
- Do not upload or share the file until these checks pass.
- Prefer delivering the checked MP3. Keep the WAV as a working artifact unless the user explicitly asks for WAV.

Known good pattern from the 4090 test: chunked OmniVoice generation, postprocessing enabled, final MP3 at 48 kHz mono 192 kbps, then ASR verification. A 64.8 second checked sample transcribed continuously from start to finish and avoided the earlier mostly blank long-WAV failure.

## Generation

Auto-select engine and device:

```bash
python /home/slam/.codex/skills/local-tts/scripts/tts_generate.py --engine auto --device auto --text "Hello." --output /tmp/local_tts.wav --report-json /tmp/local_tts.json
```

Force OmniVoice:

```bash
python /home/slam/.codex/skills/local-tts/scripts/tts_generate.py --engine omnivoice --device cuda --text "Hello." --output /tmp/local_tts.wav
```

Force VoxCPM:

```bash
python /home/slam/.codex/skills/local-tts/scripts/tts_generate.py --engine voxcpm --device cuda --text "Hello." --output /tmp/local_tts.wav
```

Movie narration preset:

```bash
python /home/slam/.codex/skills/local-tts/scripts/tts_generate.py \
  --engine omnivoice \
  --device cuda \
  --language Chinese \
  --speed 0.95 \
  --num-step 8 \
  --instruct "男，青年，低音调" \
  --text "在这个看似平静的小镇里，一场被隐藏多年的秘密，正在悄悄浮出水面。" \
  --output /tmp/movie_narration.wav \
  --report-json /tmp/movie_narration.json
```

Use `--duration` when a narration segment must match a fixed video slot. Prefer `--speed 0.9` to `1.0` for suspense narration, and `--num-step 8` for better quality than the fastest benchmark setting.

OmniVoice `--instruct` accepts fixed labels, not arbitrary prose. Chinese labels must use full-width comma, for example `男，青年，低音调`, `女，中年，中音调`, or `男，中年，低音调`.

## Benchmark

CPU only:

```bash
python /home/slam/.codex/skills/local-tts/scripts/tts_benchmark.py --device cpu --out-dir /tmp/tts_bench_cpu
```

GPU only:

```bash
python /home/slam/.codex/skills/local-tts/scripts/tts_benchmark.py --device cuda --out-dir /tmp/tts_bench_gpu
```

Custom text:

```bash
python /home/slam/.codex/skills/local-tts/scripts/tts_benchmark.py --device both --text "你好，这是本地语音合成测试。" --out-dir /tmp/tts_bench_zh
```

## Interpretation

Use `elapsed_sec / audio_duration_sec` as RTF. Lower is faster. RTF is only a rough comparison when engines produce different output durations or sample rates.

OmniVoice-Studio is the app/integration layer. Prefer it when the user needs a service, UI, API, or multi-engine workflow.

VoxCPM is a direct model library. Prefer it when the user needs direct programmatic TTS calls and accepts model-level setup/latency tradeoffs.

`tts_generate.py --engine auto` currently chooses OmniVoice as the stable default integration path. Force `--engine voxcpm` when direct VoxCPM behavior is specifically needed.

Read `references/local-results.md` when the user asks what has already been tested on this machine.
