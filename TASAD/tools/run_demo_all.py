from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description="Run every demo defined by an exported model")
    parser.add_argument("--backend", choices=["software", "rtl"], default="software")
    parser.add_argument("--rtl", default="src/TASAD.sv")
    parser.add_argument("--output", default="reports/rtl/demo_all.csv")
    parser.add_argument("--model-dir", default="model")
    parser.add_argument("--demo-dir", default="demo")
    parser.add_argument("--work-dir", default="work/demo_all")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    model_dir = root / args.model_dir
    metadata = json.loads((model_dir / "model_meta.json").read_text(encoding="utf-8"))
    isos = [
        item["iso"]
        for item in sorted(metadata["classes"], key=lambda item: int(item["id"]))
    ]
    rows = []
    overall = True
    for iso in isos:
        report = root / "reports" / "rtl" / f"{iso}.json"
        command = [
            sys.executable, "-m", "runtime.run_demo",
            "--image", f"{args.demo_dir}/{iso}.rgb",
            "--backend", args.backend,
            "--expected", iso,
            "--model-dir", args.model_dir,
            "--work-dir", f"{args.work_dir}/{iso}",
            "--report", str(report),
        ]
        if args.backend == "rtl":
            command.extend(["--rtl", args.rtl])
        process = subprocess.run(command, cwd=root, text=True)
        if not report.exists():
            rows.append([iso, iso, "ERROR", "ERROR", 0, "FAIL"])
            overall = False
            continue
        data = json.loads(report.read_text(encoding="utf-8"))
        sw = data["software_prediction"]["iso"]
        rtl = data["rtl_prediction"]["iso"] if data["rtl_prediction"] else "N/A"
        matched = data["attention_comparison"]["matched"]
        passed = process.returncode == 0 and sw == iso
        if args.backend == "rtl":
            passed = passed and rtl == iso and matched == 4096
        overall &= passed
        rows.append([iso, iso, sw, rtl, matched, "PASS" if passed else "FAIL"])

    output = root / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(["iso", "expected", "software_pred", "rtl_pred", "attention_match", "result"])
        writer.writerows(rows)
    print(output)
    raise SystemExit(0 if overall else 1)


if __name__ == "__main__":
    main()
