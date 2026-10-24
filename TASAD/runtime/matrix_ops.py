import math


def zeros(rows, cols):
    return [[0.0] * cols for _ in range(rows)]


def matmul(a, b):
    if not a or not b:
        raise ValueError("matmul requires non-empty matrices")
    a_cols = len(a[0])
    if any(len(row) != a_cols for row in a):
        raise ValueError("ragged left matrix")
    if len(b) != a_cols:
        raise ValueError(f"matmul shape mismatch: {len(a)}x{a_cols} and {len(b)}x{len(b[0])}")
    b_cols = len(b[0])
    if any(len(row) != b_cols for row in b):
        raise ValueError("ragged right matrix")

    bt = list(zip(*b))
    out = []
    for a_row in a:
        out.append([sum(x * y for x, y in zip(a_row, b_col)) for b_col in bt])
    return out


def linear(x, weight, bias):
    if not weight:
        raise ValueError("linear weight is empty")
    in_features = len(weight[0])
    if any(len(row) != in_features for row in weight):
        raise ValueError("ragged linear weight")
    if bias is not None and len(bias) != len(weight):
        raise ValueError("linear bias size mismatch")

    out = []
    for x_row in x:
        if len(x_row) != in_features:
            raise ValueError(f"linear input has {len(x_row)} features, expected {in_features}")
        row_out = []
        for out_idx, w_row in enumerate(weight):
            value = sum(v * w for v, w in zip(x_row, w_row))
            if bias is not None:
                value += bias[out_idx]
            row_out.append(value)
        out.append(row_out)
    return out


def add(a, b):
    if len(a) != len(b):
        raise ValueError("matrix row mismatch")
    out = []
    for ar, br in zip(a, b):
        if len(ar) != len(br):
            raise ValueError("matrix column mismatch")
        out.append([x + y for x, y in zip(ar, br)])
    return out


def layer_norm(x, weight, bias, eps=1.0e-5):
    if len(weight) != len(bias):
        raise ValueError("LayerNorm parameter mismatch")
    n = len(weight)
    out = []
    for row in x:
        if len(row) != n:
            raise ValueError(f"LayerNorm expected {n} features, got {len(row)}")
        mean = sum(row) / n
        variance = sum((value - mean) ** 2 for value in row) / n
        inv_std = 1.0 / math.sqrt(variance + eps)
        out.append([
            ((row[i] - mean) * inv_std) * weight[i] + bias[i]
            for i in range(n)
        ])
    return out


def gelu_scalar(x):
    return 0.5 * x * (1.0 + math.erf(x / math.sqrt(2.0)))


def gelu(x):
    return [[gelu_scalar(value) for value in row] for row in x]


def mean_rows(x):
    if not x:
        raise ValueError("mean_rows requires a non-empty matrix")
    cols = len(x[0])
    if any(len(row) != cols for row in x):
        raise ValueError("ragged matrix")
    return [sum(row[c] for row in x) / len(x) for c in range(cols)]


def softmax(values):
    if not values:
        return []
    maximum = max(values)
    exps = [math.exp(value - maximum) for value in values]
    denominator = sum(exps)
    return [value / denominator for value in exps]
