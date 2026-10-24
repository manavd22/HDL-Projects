import pathlib


def read_rgb(path, width=128, height=128):
    data = pathlib.Path(path).read_bytes()
    expected = width * height * 3
    if len(data) != expected:
        raise ValueError(f"{path}: expected {expected} bytes, got {len(data)}")
    return data


def patch_vectors(rgb, image_size, patch_size, mean, std):
    if image_size % patch_size != 0:
        raise ValueError("image_size must be divisible by patch_size")
    if len(mean) != 3 or len(std) != 3:
        raise ValueError("mean and std must have three channels")

    grid = image_size // patch_size
    patches = []
    for patch_y in range(grid):
        for patch_x in range(grid):
            vector = []
            # Match PyTorch Conv2d weight flattening order: C, KH, KW.
            for channel in range(3):
                for local_y in range(patch_size):
                    y = patch_y * patch_size + local_y
                    for local_x in range(patch_size):
                        x = patch_x * patch_size + local_x
                        offset = (y * image_size + x) * 3 + channel
                        normalized = ((rgb[offset] / 255.0) - mean[channel]) / std[channel]
                        vector.append(normalized)
            patches.append(vector)
    return patches
