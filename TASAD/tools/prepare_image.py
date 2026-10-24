import argparse
from pathlib import Path

from PIL import Image


def letterbox(image, size, padding):
    image = image.convert("RGB")
    scale = min(size / image.width, size / image.height)
    new_size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    # Image.Resampling was added in newer Pillow releases.  The workstation
    # ships an older Pillow, where LANCZOS is defined directly on Image.
    resampling = getattr(Image, "Resampling", Image)
    image = image.resize(new_size, resampling.LANCZOS)
    canvas = Image.new("RGB", (size, size), (padding, padding, padding))
    canvas.paste(image, ((size - image.width) // 2, (size - image.height) // 2))
    return canvas


def main():
    parser = argparse.ArgumentParser(description="Convert PNG/JPEG to 128x128 headerless RGB")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--size", type=int, default=128)
    parser.add_argument("--padding", type=int, default=128)
    args = parser.parse_args()
    if not 0 <= args.padding <= 255:
        raise ValueError("padding must be in 0..255")
    with Image.open(args.input) as image:
        output = letterbox(image, args.size, args.padding)
    path = Path(args.output)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(output.tobytes())
    print(f"Wrote {len(output.tobytes())} bytes to {path}")


if __name__ == "__main__":
    main()
