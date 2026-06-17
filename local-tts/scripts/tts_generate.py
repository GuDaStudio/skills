#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import time
import wave
from pathlib import Path


ROOT = Path("/home/slam/OmniVoice-Studio")
PY = ROOT / ".venv/bin/python"
OMNI = ROOT / ".venv/bin/omnivoice-infer"
DEFAULT_TEXT = "Hello from local TTS."


def run(cmd: list[str], env: dict[str, str], cwd: Path) -> tuple[int, float]:
    start = time.perf_counter()
    proc = subprocess.run(cmd, cwd=str(cwd), env=env)
    return proc.returncode, time.perf_counter() - start


def wav_info(path: Path) -> dict:
    if not path.exists():
        return {}
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


def detect_cuda(env: dict[str, str]) -> bool:
    if env.get("CUDA_VISIBLE_DEVICES") == "":
        return False
    proc = subprocess.run(
        [str(PY), "-c", "import torch; print(int(torch.cuda.is_available()))"],
        cwd=str(ROOT),
        env=env,
        text=True,
        capture_output=True,
    )
    return proc.returncode == 0 and proc.stdout.strip() == "1"


def has_cjk(text: str) -> bool:
    return any("\u4e00" <= ch <= "\u9fff" for ch in text)


def pick_device(device: str, env: dict[str, str]) -> str:
    if device != "auto":
        return device
    return "cuda" if detect_cuda(env) else "cpu"


def pick_engine(engine: str, text: str) -> str:
    if engine != "auto":
        return engine
    return "omnivoice" if has_cjk(text) else "omnivoice"


def write_report(path: str | None, result: dict) -> None:
    if not path:
        return
    report_path = Path(path).expanduser().resolve()
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(result, indent=2, ensure_ascii=False))


def str_or_none(value: str | None) -> str:
    return "None" if value is None else value


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate one local TTS WAV with OmniVoice or VoxCPM.")
    parser.add_argument("--text", default=DEFAULT_TEXT)
    parser.add_argument("--output", required=True)
    parser.add_argument("--engine", choices=["auto", "omnivoice", "voxcpm"], default="auto")
    parser.add_argument("--device", choices=["auto", "cpu", "cuda"], default="auto")
    parser.add_argument("--num-step", type=int, default=4)
    parser.add_argument("--voxcpm-inference-timesteps", type=int, default=1)
    parser.add_argument("--max-length", type=int, default=128)
    parser.add_argument("--omni-model", default="k2-fsa/OmniVoice")
    parser.add_argument("--language", default=None)
    parser.add_argument("--instruct", default=None)
    parser.add_argument("--speed", type=float, default=None)
    parser.add_argument("--duration", type=float, default=None)
    parser.add_argument("--report-json", default=None)
    args = parser.parse_args()

    output = Path(args.output).expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    base_env = os.environ.copy()
    device = pick_device(args.device, base_env)
    env = base_env.copy()
    if device == "cpu":
        env["CUDA_VISIBLE_DEVICES"] = ""
    engine = pick_engine(args.engine, args.text)

    result = {
        "engine": engine,
        "device": device,
        "text": args.text,
        "output": str(output),
    }

    if engine == "omnivoice":
        cmd = [
            str(OMNI),
            "--model",
            args.omni_model,
            "--text",
            args.text,
            "--output",
            str(output),
            "--device",
            device,
            "--num_step",
            str(args.num_step),
            "--denoise",
            "False",
            "--postprocess_output",
            "False",
        ]
        if args.language:
            cmd += ["--language", args.language]
        if args.instruct:
            cmd += ["--instruct", args.instruct]
        if args.speed is not None:
            cmd += ["--speed", str(args.speed)]
        if args.duration is not None:
            cmd += ["--duration", str(args.duration)]
        returncode, elapsed = run(cmd, env, ROOT)
    else:
        script = output.with_suffix(".voxcpm.py")
        script.write_text(
            "from voxcpm import VoxCPM\n"
            "import soundfile as sf\n"
            "model = VoxCPM.from_pretrained('openbmb/VoxCPM-0.5B', load_denoiser=False)\n"
            f"wav = model.generate(text={args.text!r}, normalize=True, denoise=False, inference_timesteps={args.voxcpm_inference_timesteps}, max_length={args.max_length}, retry_badcase=False)\n"
            f"sf.write({str(output)!r}, wav, 16000)\n"
        )
        returncode, elapsed = run([str(PY), str(script)], env, ROOT)

    result["returncode"] = returncode
    result["elapsed_sec"] = elapsed
    result.update(wav_info(output))
    if result.get("audio_duration_sec"):
        result["rtf"] = elapsed / result["audio_duration_sec"]
    if args.language is not None:
        result["language"] = args.language
    if args.instruct is not None:
        result["instruct"] = args.instruct
    if args.speed is not None:
        result["speed"] = args.speed
    if args.duration is not None:
        result["duration"] = args.duration
    write_report(args.report_json, result)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return returncode


if __name__ == "__main__":
    raise SystemExit(main())
