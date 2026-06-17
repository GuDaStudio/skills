# Local Results

Machine state observed on 2026-06-16:

- GPU: NVIDIA GeForce RTX 4060 Ti
- Torch in `/home/slam/OmniVoice-Studio/.venv`: `2.8.0+cu128`
- CUDA runtime reported by torch: `12.8`
- `env -u CUDA_VISIBLE_DEVICES` detects one CUDA GPU.
- VoxCPM package is installed in `/home/slam/OmniVoice-Studio/.venv`.
- OmniVoice-Studio diagnostics and backend health check passed previously.

Benchmark text:

```text
Hello from the local text to speech benchmark. This is a short performance test.
```

Observed benchmark:

| Engine | Device | Elapsed | Audio | RTF | Sample rate |
| --- | ---: | ---: | ---: | ---: | ---: |
| OmniVoice | CPU | 59.9s | 5.04s | 11.88 | 24000 |
| VoxCPM | CPU | 70.8s | 10.16s | 6.97 | 16000 |
| OmniVoice | CUDA | 10.9s | 5.04s | 2.17 | 24000 |
| VoxCPM | CUDA | 55.9s | 10.16s | 5.50 | 16000 |

Interpret with care: outputs differ in duration and sample rate, and VoxCPM GPU includes heavy first-run torch compile/warmup overhead.
