from __future__ import annotations

import argparse
import json
import pathlib

from .dat_io import read_uint16_dat


def compare(golden_path, actual_path, max_examples=16):
    golden = read_uint16_dat(golden_path, 4096)
    actual = read_uint16_dat(actual_path, 4096)
    mismatches = []
    for index, (expected, observed) in enumerate(zip(golden, actual)):
        if expected != observed:
            if len(mismatches) < max_examples:
                mismatches.append({
                    "index": index,
                    "row": index // 64,
                    "col": index % 64,
                    "gold_hex": f"{expected:04X}",
                    "rtl_hex": f"{observed:04X}",
                    "difference": observed - expected,
                })
    matched = sum(1 for expected, observed in zip(golden, actual) if expected == observed)
    return {
        "matched": matched,
        "total": 4096,
        "pass": matched == 4096,
        "examples": mismatches,
    }


def main():
    parser = argparse.ArgumentParser(description="Compare TASAD attention outputs")
    parser.add_argument("--gold", required=True)
    parser.add_argument("--rtl", required=True)
    parser.add_argument("--json-out", default=None)
    parser.add_argument("--max-examples", type=int, default=16)
    args = parser.parse_args()
    result = compare(args.gold, args.rtl, args.max_examples)
    print(f"Attention exact match: {result['matched']} / {result['total']}")
    print(f"Result               : {'PASS' if result['pass'] else 'FAIL'}")
    for item in result["examples"]:
        print(
            f"  [{item['index']:4d}] row={item['row']:2d} col={item['col']:2d} "
            f"gold={item['gold_hex']} rtl={item['rtl_hex']} diff={item['difference']}"
        )
    if args.json_out:
        pathlib.Path(args.json_out).write_text(
            json.dumps(result, indent=2), encoding="utf-8"
        )
    raise SystemExit(0 if result["pass"] else 1)


if __name__ == "__main__":
    main()
