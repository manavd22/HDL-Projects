from __future__ import annotations

import argparse
import json
import math
import pathlib

from .binary_loader import ModelBundle
from .dat_io import flatten, write_int8_dat, write_uint16_dat
from .image_raw import patch_vectors, read_rgb
from .matrix_ops import add, layer_norm, linear
from .state_io import write_float_matrix
from .tasad_reference import tasad_attention


def quantize_int8(matrix, gain):
    quantized = []
    saturated = 0
    count = 0
    for row in matrix:
        q_row = []
        for value in row:
            scaled = int(round(float(value) * float(gain)))
            clipped = max(-128, min(127, scaled))
            if clipped != scaled:
                saturated += 1
            q_row.append(clipped)
            count += 1
        quantized.append(q_row)
    ratio = saturated / count if count else 0.0
    return quantized, ratio


def run_front(image_path, model_dir, work_dir):
    model = ModelBundle(model_dir)
    meta = model.meta
    work = pathlib.Path(work_dir)
    work.mkdir(parents=True, exist_ok=True)

    image_size = int(meta["image_size"])
    patch_size = int(meta["patch_size"])
    embed_dim = int(meta["embedding_dim"])
    token_count = int(meta["token_count"])
    if (image_size // patch_size) ** 2 != token_count:
        raise ValueError("model metadata has inconsistent token count")
    if token_count != 64 or embed_dim != 64:
        raise ValueError("TASAD runtime requires token_count=64 and embedding_dim=64")

    rgb = read_rgb(image_path, image_size, image_size)
    patches = patch_vectors(rgb, image_size, patch_size, meta["mean"], meta["std"])

    tokens = linear(
        patches,
        model.tensor("patch_embedding.weight"),
        model.tensor("patch_embedding.bias"),
    )
    tokens = add(tokens, model.tensor("position_embedding"))
    residual = tokens

    normalized = layer_norm(
        tokens,
        model.tensor("norm1.weight"),
        model.tensor("norm1.bias"),
        float(meta.get("layer_norm_eps", 1.0e-5)),
    )
    q_float = linear(normalized, model.tensor("q_proj.weight"), model.tensor("q_proj.bias"))
    k_float = linear(normalized, model.tensor("k_proj.weight"), model.tensor("k_proj.bias"))
    v = linear(normalized, model.tensor("v_proj.weight"), model.tensor("v_proj.bias"))

    q_gain = float(model.tensor("quant.q_gain")[0])
    k_gain = float(model.tensor("quant.k_gain")[0])
    q_int, q_saturation = quantize_int8(q_float, q_gain)
    k_int, k_saturation = quantize_int8(k_float, k_gain)

    a_golden = tasad_attention(q_int, k_int)

    write_int8_dat(work / "Q.dat", flatten(q_int))
    write_int8_dat(work / "K.dat", flatten(k_int))
    write_uint16_dat(work / "A_golden.dat", flatten(a_golden))
    write_float_matrix(work / "V.bin", v)
    write_float_matrix(work / "residual.bin", residual)

    run_meta = {
        "image": str(pathlib.Path(image_path)),
        "image_size": image_size,
        "patch_size": patch_size,
        "token_count": token_count,
        "embedding_dim": embed_dim,
        "q_gain": q_gain,
        "k_gain": k_gain,
        "q_saturation_ratio": q_saturation,
        "k_saturation_ratio": k_saturation,
        "q_min": min(flatten(q_int)),
        "q_max": max(flatten(q_int)),
        "k_min": min(flatten(k_int)),
        "k_max": max(flatten(k_int)),
        "attention_scale": 32768,
        "ordering": "row-major",
    }
    (work / "run_meta.json").write_text(
        json.dumps(run_meta, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return run_meta


def main():
    parser = argparse.ArgumentParser(description="Run the pure-Python Tiny ViT front end")
    parser.add_argument("--image", required=True, help="128x128 headerless RGB file")
    parser.add_argument("--model-dir", default="model")
    parser.add_argument("--work-dir", default="work")
    args = parser.parse_args()
    report = run_front(args.image, args.model_dir, args.work_dir)
    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
