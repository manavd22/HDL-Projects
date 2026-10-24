import hashlib
import json
import pathlib
import struct


def _product(shape):
    result = 1
    for dimension in shape:
        result *= int(dimension)
    return result


def _reshape(flat, shape):
    if not shape:
        return flat[0]
    if len(shape) == 1:
        return flat
    stride = _product(shape[1:])
    return [
        _reshape(flat[index * stride:(index + 1) * stride], shape[1:])
        for index in range(shape[0])
    ]


class ModelBundle:
    def __init__(self, model_dir):
        self.model_dir = pathlib.Path(model_dir)
        self.meta_path = self.model_dir / "model_meta.json"
        self.bin_path = self.model_dir / "model.bin"
        self.sha_path = self.model_dir / "model.sha256"

        if not self.meta_path.exists():
            raise FileNotFoundError(f"Missing {self.meta_path}")
        if not self.bin_path.exists():
            raise FileNotFoundError(f"Missing {self.bin_path}; run training/export_model.py first")

        self.meta = json.loads(self.meta_path.read_text(encoding="utf-8"))
        self.data = self.bin_path.read_bytes()
        self.tensors = {item["name"]: item for item in self.meta["tensors"]}
        self._cache = {}
        self._validate()

    def _validate(self):
        if self.meta.get("endianness") != "little":
            raise ValueError("Only little-endian model files are supported")

        intervals = []
        for tensor in self.meta["tensors"]:
            if tensor["dtype"] != "float32":
                raise ValueError(f"Unsupported dtype {tensor['dtype']} for {tensor['name']}")
            count = _product(tensor["shape"])
            byte_size = count * 4
            start = int(tensor["offset"])
            end = start + byte_size
            if start < 0 or end > len(self.data):
                raise ValueError(f"Tensor {tensor['name']} is outside model.bin")
            intervals.append((start, end, tensor["name"]))

        intervals.sort()
        for previous, current in zip(intervals, intervals[1:]):
            if current[0] < previous[1]:
                raise ValueError(f"Tensor overlap: {previous[2]} and {current[2]}")

        if self.sha_path.exists():
            expected = self.sha_path.read_text(encoding="utf-8").strip().split()[0]
            actual = hashlib.sha256(self.data).hexdigest()
            if actual != expected:
                raise ValueError(f"SHA-256 mismatch: expected {expected}, got {actual}")

    def tensor(self, name):
        if name in self._cache:
            return self._cache[name]
        if name not in self.tensors:
            raise KeyError(f"Tensor not found: {name}")
        info = self.tensors[name]
        count = _product(info["shape"])
        values = list(struct.unpack_from(f"<{count}f", self.data, int(info["offset"])))
        shaped = _reshape(values, info["shape"])
        self._cache[name] = shaped
        return shaped
