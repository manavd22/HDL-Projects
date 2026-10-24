import pathlib


def int8_to_hex(value):
    if not -128 <= value <= 127:
        raise ValueError(f"INT8 overflow: {value}")
    return f"{value & 0xFF:02X}"


def hex_to_int8(token):
    value = int(token.strip(), 16)
    if not 0 <= value <= 0xFF:
        raise ValueError(f"Not an 8-bit value: {token!r}")
    return value - 256 if value >= 128 else value


def uint16_to_hex(value):
    if not 0 <= value <= 65535:
        raise ValueError(f"UINT16 overflow: {value}")
    return f"{value:04X}"


def hex_to_uint16(token):
    value = int(token.strip(), 16)
    if not 0 <= value <= 0xFFFF:
        raise ValueError(f"Not a 16-bit value: {token!r}")
    return value


def _read_nonempty_lines(path):
    lines = [line.strip() for line in pathlib.Path(path).read_text(encoding="utf-8").splitlines()]
    return [line for line in lines if line]


def read_int8_dat(path, expected_count=None):
    values = [hex_to_int8(line) for line in _read_nonempty_lines(path)]
    if expected_count is not None and len(values) != expected_count:
        raise ValueError(f"{path}: expected {expected_count} values, got {len(values)}")
    return values


def write_int8_dat(path, values):
    output = "\n".join(int8_to_hex(int(v)) for v in values) + "\n"
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(path).write_text(output, encoding="utf-8")


def read_uint16_dat(path, expected_count=None):
    values = [hex_to_uint16(line) for line in _read_nonempty_lines(path)]
    if expected_count is not None and len(values) != expected_count:
        raise ValueError(f"{path}: expected {expected_count} values, got {len(values)}")
    return values


def write_uint16_dat(path, values):
    output = "\n".join(uint16_to_hex(int(v)) for v in values) + "\n"
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(path).write_text(output, encoding="utf-8")


def reshape(values, rows, cols):
    if len(values) != rows * cols:
        raise ValueError(f"reshape expected {rows * cols} values, got {len(values)}")
    return [list(values[r * cols:(r + 1) * cols]) for r in range(rows)]


def flatten(matrix):
    return [value for row in matrix for value in row]
