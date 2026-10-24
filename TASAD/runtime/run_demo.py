from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
import time

from .compare_attention import compare
from .binary_loader import ModelBundle
from .model_back import run_back
from .model_front import run_front


def _run_checked(command, cwd):
    process = subprocess.run(command, cwd=cwd, text=True, capture_output=True)
    if process.returncode != 0:
        raise RuntimeError(
            "Command failed:\n"
            + " ".join(str(item) for item in command)
            + "\nSTDOUT:\n" + process.stdout
            + "\nSTDERR:\n" + process.stderr
        )
    return process


def run_rtl(root, rtl_path, work_dir, iverilog, vvp, timeout_seconds):
    sim_path = work_dir / "tasad_sim.out"
    compile_command = [
        iverilog,
        "-g2012",
        "-I", str(root / "tb"),
        "-s", "tb_tasad_application",
        "-o", str(sim_path),
        str(root / "tb" / "tb_tasad_application.sv"),
        str(rtl_path),
    ]
    _run_checked(compile_command, root)

    simulation_command = [
        vvp,
        str(sim_path),
        f"+QFILE={work_dir / 'Q.dat'}",
        f"+KFILE={work_dir / 'K.dat'}",
        f"+AFILE={work_dir / 'A_rtl.dat'}",
    ]
    started = time.time()
    process = subprocess.run(
        simulation_command,
        cwd=root,
        text=True,
        capture_output=True,
        timeout=timeout_seconds,
    )
    elapsed = time.time() - started
    if process.returncode != 0:
        raise RuntimeError(
            f"RTL simulation failed with exit code {process.returncode}\n"
            f"STDOUT:\n{process.stdout}\nSTDERR:\n{process.stderr}"
        )
    return elapsed, process.stdout


def main():
    parser = argparse.ArgumentParser(description="TASAD extensible flag software/RTL demo")
    parser.add_argument("--image", required=True, help="128x128 .rgb input")
    parser.add_argument("--backend", choices=["software", "rtl"], default="software")
    parser.add_argument("--rtl", default="src/TASAD.sv")
    parser.add_argument("--model-dir", default="model")
    parser.add_argument("--work-dir", default="work")
    parser.add_argument("--expected", default=None, help="Expected ISO code")
    parser.add_argument("--iverilog", default="iverilog")
    parser.add_argument("--vvp", default="vvp")
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--report", default="reports/rtl/latest.json")
    args = parser.parse_args()

    root = pathlib.Path(__file__).resolve().parents[1]
    image = pathlib.Path(args.image)
    if not image.is_absolute():
        image = root / image
    model_dir = pathlib.Path(args.model_dir)
    if not model_dir.is_absolute():
        model_dir = root / model_dir
    work_dir = pathlib.Path(args.work_dir)
    if not work_dir.is_absolute():
        work_dir = root / work_dir
    work_dir.mkdir(parents=True, exist_ok=True)

    class_codes = {
        item["iso"] for item in ModelBundle(model_dir).meta.get("classes", [])
    }
    expected = args.expected
    if expected is None and image.stem.upper() in class_codes:
        expected = image.stem.upper()

    front = run_front(image, model_dir, work_dir)
    software = run_back(work_dir / "A_golden.dat", model_dir, work_dir, expected)

    comparison = {"matched": 4096, "total": 4096, "pass": True, "examples": []}
    rtl_result = None
    simulation_seconds = None
    simulator_output = None

    if args.backend == "rtl":
        rtl_path = pathlib.Path(args.rtl)
        if not rtl_path.is_absolute():
            rtl_path = root / rtl_path
        if not rtl_path.exists():
            raise FileNotFoundError(f"Missing student RTL: {rtl_path}")
        simulation_seconds, simulator_output = run_rtl(
            root, rtl_path, work_dir, args.iverilog, args.vvp, args.timeout
        )
        comparison = compare(work_dir / "A_golden.dat", work_dir / "A_rtl.dat")
        rtl_result = run_back(work_dir / "A_rtl.dat", model_dir, work_dir, expected)

    report = {
        "input": str(image),
        "expected": expected,
        "backend": args.backend,
        "front": front,
        "software_prediction": software,
        "rtl_prediction": rtl_result,
        "attention_comparison": comparison,
        "rtl_simulation_wall_seconds": simulation_seconds,
        "simulator_output": simulator_output,
    }
    report_path = pathlib.Path(args.report)
    if not report_path.is_absolute():
        report_path = root / report_path
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    print("=" * 54)
    print(f"TASAD Flag-{len(class_codes)} Demo Report")
    print("=" * 54)
    print(f"Input image          : {image}")
    print(f"Expected class       : {expected or 'N/A'}")
    print(f"Software prediction  : {software['name']} ({software['confidence'] * 100:.2f}%)")
    if rtl_result is not None:
        print(f"RTL prediction       : {rtl_result['name']} ({rtl_result['confidence'] * 100:.2f}%)")
        print(f"Attention comparison : {'PASS' if comparison['pass'] else 'FAIL'}")
        print(f"Matched values       : {comparison['matched']} / 4096")
    print(f"Report               : {report_path}")
    print("=" * 54)

    if args.backend == "rtl" and not comparison["pass"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
