#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
import wave
from pathlib import Path


DEFAULT_TEXT = "Hello from the local text to speech benchmark. This is a short performance test."
DEFAULT_ROOT = Path("/home/slam/OmniVoice-Studio")


def wav_info(path: Path) -> dict:
    with wave.open(str(path), "rb") as f:
        frames = f.getnframes()
        rate = f.getframerate()
        duration = frames / float(rate) if rate else 0.0
        return {
            "audio_duration_sec": duration,
            "sample_rate": rate,
            "channels": f.getnchannels(),
            "bytes": path.stat().st_size,
        }


def run_cmd(name: str, cmd: list[str], output: Path, env: dict[str, str], cwd: Path) -> dict:
    if output.exists():
        output.unlink()
    start = time.perf_counter()
    proc = subprocess.run(cmd, cwd=str(cwd), env=env, text=True, capture_output=True)
    elapsed = time.perf_counter() - start
    result = {
        "name": name,
        "ok": proc.returncode == 0,
        "returncode": proc.returncode,
        "elapsed_sec": elapsed,
        "output": str(output),
        "stdout_tail": proc.stdout[-2000:],
        "stderr_tail": proc.stderr[-4000:],
    }
    if output.exists():
        info = wav_info(output)
        result.update(info)
        duration = info["audio_duration_sec"]
        result["rtf"] = elapsed / duration if duration else None
    return result


def device_env(device: str) -> dict[str, str]:
    env = os.environ.copy()
    if device == "cpu":
        env["CUDA_VISIBLE_DEVICES"] = ""
    return env


def build_voxcpm_script(path: Path, text: str, output: Path) -> None:
    path.write_text(
        "from voxcpm import VoxCPM\n"
        "import soundfile as sf\n"
        "model = VoxCPM.from_pretrained('openbmb/VoxCPM-0.5B', load_denoiser=False)\n"
        f"wav = model.generate(text={text!r}, normalize=True, denoise=False, inference_timesteps=1, max_length=128, retry_badcase=False)\n"
        f"sf.write({str(output)!r}, wav, 16000)\n"
    )


def benchmark_device(root: Path, out_dir: Path, text: str, device: str) -> list[dict]:
    py = root / ".venv/bin/python"
    omni = root / ".venv/bin/omnivoice-infer"
    env = device_env(device)
    omni_out = out_dir / f"omnivoice_{device}.wav"
    vox_out = out_dir / f"voxcpm_{device}.wav"
    vox_script = out_dir / f"run_voxcpm_{device}_once.py"
    build_voxcpm_script(vox_script, text, vox_out)

    omni_cmd = [
        str(omni),
        "--text",
        text,
        "--output",
        str(omni_out),
        "--device",
        "cpu" if device == "cpu" else "cuda",
        "--num_step",
        "4",
        "--denoise",
        "False",
        "--postprocess_output",
        "False",
    ]

    return [
        run_cmd(f"omnivoice_{device}", omni_cmd, omni_out, env, root),
        run_cmd(f"voxcpm_{device}", [str(py), str(vox_script)], vox_out, env, root),
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="Benchmark local OmniVoice-Studio and VoxCPM TTS.")
    parser.add_argument("--root", default=str(DEFAULT_ROOT), help="OmniVoice-Studio repo path.")
    parser.add_argument("--out-dir", default="/tmp/tts_bench_run", help="Output directory for wav files and report.json.")
    parser.add_argument("--text", default=DEFAULT_TEXT, help="Text to synthesize.")
    parser.add_argument("--device", choices=["cpu", "cuda", "both"], default="cpu", help="Device mode to test.")
    args = parser.parse_args()

    root = Path(args.root).expanduser().resolve()
    out_dir = Path(args.out_dir).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    devices = ["cpu", "cuda"] if args.device == "both" else [args.device]
    results: list[dict] = []
    for device in devices:
        results.extend(benchmark_device(root, out_dir, args.text, device))

    report = {
        "root": str(root),
        "text": args.text,
        "device": args.device,
        "results": results,
    }
    report_path = out_dir / "report.json"
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False))
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if all(r["ok"] for r in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
