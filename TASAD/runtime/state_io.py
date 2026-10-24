import pathlib
import struct


def write_float_matrix(path, matrix):
    if not matrix:
        raise ValueError("matrix is empty")
    cols = len(matrix[0])
    if any(len(row) != cols for row in matrix):
        raise ValueError("ragged matrix")
    flat = [float(value) for row in matrix for value in row]
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(path).write_bytes(struct.pack(f"<{len(flat)}f", *flat))


def read_float_matrix(path, rows, cols):
    data = pathlib.Path(path).read_bytes()
    expected = rows * cols * 4
    if len(data) != expected:
        raise ValueError(f"{path}: expected {expected} bytes, got {len(data)}")
    values = struct.unpack(f"<{rows * cols}f", data)
    return [list(values[r * cols:(r + 1) * cols]) for r in range(rows)]
