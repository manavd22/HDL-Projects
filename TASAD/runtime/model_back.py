from __future__ import annotations

import argparse
import json
import math
import pathlib

from .binary_loader import ModelBundle
from .dat_io import read_uint16_dat, reshape
from .matrix_ops import add, gelu, layer_norm, linear, matmul, mean_rows, softmax
from .state_io import read_float_matrix


def run_back(attention_path, model_dir, work_dir, expected=None):
    model = ModelBundle(model_dir)
    meta = model.meta
    work = pathlib.Path(work_dir)

    a_int = reshape(read_uint16_dat(attention_path, 4096), 64, 64)
    attention = [[value / 32768.0 for value in row] for row in a_int]
    # Preserve hardware truncation. Do not renormalize attention rows.

    v = read_float_matrix(work / "V.bin", 64, 64)
    residual = read_float_matrix(work / "residual.bin", 64, 64)

    context = matmul(attention, v)
    projected = linear(context, model.tensor("out_proj.weight"), model.tensor("out_proj.bias"))
    x = add(residual, projected)

    norm2 = layer_norm(
        x,
        model.tensor("norm2.weight"),
        model.tensor("norm2.bias"),
        float(meta.get("layer_norm_eps", 1.0e-5)),
    )
    hidden = linear(norm2, model.tensor("ffn.0.weight"), model.tensor("ffn.0.bias"))
    hidden = gelu(hidden)
    ffn_out = linear(hidden, model.tensor("ffn.2.weight"), model.tensor("ffn.2.bias"))
    x = add(x, ffn_out)

    x = layer_norm(
        x,
        model.tensor("final_norm.weight"),
        model.tensor("final_norm.bias"),
        float(meta.get("layer_norm_eps", 1.0e-5)),
    )
    pooled = mean_rows(x)
    logits = linear([pooled], model.tensor("classifier.weight"), model.tensor("classifier.bias"))[0]
    probabilities = softmax(logits)
    prediction = max(range(len(logits)), key=lambda index: logits[index])

    class_records = sorted(meta["classes"], key=lambda item: int(item["id"]))
    class_info = class_records[prediction]
    result = {
        "prediction_id": prediction,
        "iso": class_info["iso"],
        "name": class_info["display_name"],
        "confidence": probabilities[prediction],
        "logits": logits,
        "probabilities": probabilities,
        "expected": expected,
        "correct": None if expected is None else class_info["iso"] == expected,
        "num_classes": int(meta["num_classes"]),
        "attention_row_sum_min": min(sum(row) for row in attention),
        "attention_row_sum_max": max(sum(row) for row in attention),
    }
    return result


def main():
    parser = argparse.ArgumentParser(description="Run the pure-Python Tiny ViT back end")
    parser.add_argument("--attention", required=True)
    parser.add_argument("--model-dir", default="model")
    parser.add_argument("--work-dir", default="work")
    parser.add_argument("--expected", default=None)
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="show confidence, logits, probabilities, and other debug details",
    )
    args = parser.parse_args()
    result = run_back(args.attention, args.model_dir, args.work_dir, args.expected)

    print("=" * 54)
    print(f"TASAD Flag-{result['num_classes']} RTL Back-end Report")
    print("=" * 54)
    print(f"RTL attention input  : {pathlib.Path(args.attention).resolve()}")
    print(f"Back-end prediction  : {result['name']} ({result['iso']})")
    print(f"Confidence           : {result['confidence'] * 100.0:.2f}%")
    if result["correct"] is not None:
        print(f"Expected class       : {result['expected']}")
        print(f"Result               : {'CORRECT' if result['correct'] else 'INCORRECT'}")
    print("=" * 54)

    if args.verbose:
        print(f"Class ID   : {result['prediction_id']}")
        print(f"Confidence : {result['confidence'] * 100.0:.2f}%")
        if result["correct"] is not None:
            print(f"Expected   : {result['expected']}")
            print(f"Correct    : {'YES' if result['correct'] else 'NO'}")
        print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
