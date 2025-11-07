# convert_images.py
# Re-encodes all files in this folder to real JPEGs Flutter can load.
# Writes new .jpg files next to the originals.

import os
from PIL import Image, UnidentifiedImageError

def convert_one(path):
    base, _ = os.path.splitext(path)
    out_path = base + ".jpg"
    try:
        with Image.open(path) as im:
            # Convert to RGB (handles png/webp/heic etc.)
            if im.mode not in ("RGB", "L"):
                im = im.convert("RGB")
            im.save(out_path, "JPEG", quality=90, optimize=True)
            print(f"OK: {path} -> {out_path}")
    except UnidentifiedImageError:
        print(f"UNSUPPORTED/CORRUPT: {path}")
    except Exception as e:
        print(f"ERROR: {path} -> {e}")

def main():
    for name in os.listdir():
        if name.lower().startswith("_backup"):
            continue
        if not os.path.isfile(name):
            continue
        convert_one(name)

if __name__ == "__main__":
    main()
