#!/usr/bin/env python3
import os
import sys
import json
import hashlib
from concurrent.futures import ThreadPoolExecutor

try:
    from PIL import Image
except ImportError:
    Image = None

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "core"))

THUMB_DIR = os.path.expanduser("~/.cache/quickshell/thumbs")
THUMB_SIZE = (160, 110)

def ensure_thumb(full_path):
    """Generate a thumbnail if it doesn't exist or is outdated. Returns thumb path."""
    if not Image:
        return full_path

    path_hash = hashlib.md5(full_path.encode()).hexdigest()[:12]
    thumb_name = f"{path_hash}.jpg"
    thumb_path = os.path.join(THUMB_DIR, thumb_name)

    # Fast skip if thumb exists, is non-empty, and is newer than original
    if os.path.isfile(thumb_path):
        try:
            if os.path.getmtime(thumb_path) >= os.path.getmtime(full_path) and os.path.getsize(thumb_path) > 0:
                return thumb_path
        except OSError:
            pass

    # Generate thumbnail
    tmp_path = f"{thumb_path}.{os.getpid()}_{hash(full_path) & 0xffffffff}.tmp"
    try:
        with Image.open(full_path) as img:
            img.thumbnail(THUMB_SIZE, Image.LANCZOS)
            if img.mode in ("RGBA", "P", "LA"):
                bg = Image.new("RGB", img.size, (0, 0, 0))
                if img.mode == "P":
                    img = img.convert("RGBA")
                bg.paste(img, mask=img.split()[-1] if "A" in img.mode else None)
                img = bg
            elif img.mode != "RGB":
                img = img.convert("RGB")
            img.save(tmp_path, "JPEG", quality=70, optimize=True)
        os.replace(tmp_path, thumb_path)
        return thumb_path
    except Exception:
        try:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
        except OSError:
            pass
        return full_path

def process_wallpaper(item):
    name, entry, full_path, folder_name = item
    thumb = ensure_thumb(full_path)
    return {
        "name": name,
        "filename": entry,
        "path": full_path,
        "thumb": thumb,
        "folder": folder_name
    }

def scan(target_dir=""):
    os.makedirs(THUMB_DIR, exist_ok=True)
    home = os.path.expanduser("~")
    if target_dir:
        dirs = [os.path.expanduser(target_dir)]
    else:
        dirs = [
            os.path.join(home, "Pictures", "Wallpapers"),
            os.path.join(home, "Pictures", "WallpaperMinimal"),
            os.path.join(home, "Pictures")
        ]

    valid_exts = {".png", ".jpg", ".jpeg", ".webp", ".gif"}
    items_to_process = []
    seen = set()

    for d in dirs:
        if not os.path.isdir(d):
            continue
        folder_name = os.path.basename(d)
        for entry in os.listdir(d):
            full_path = os.path.join(d, entry)
            if not os.path.isfile(full_path):
                continue
            ext = os.path.splitext(entry)[1].lower()
            if ext in valid_exts and full_path not in seen:
                seen.add(full_path)
                name = os.path.splitext(entry)[0].replace("-", " ").replace("_", " ").title()
                items_to_process.append((name, entry, full_path, folder_name))

    # Process thumbnails in parallel (4 workers bounds memory on large sets)
    with ThreadPoolExecutor(max_workers=4) as executor:
        wallpapers = list(executor.map(process_wallpaper, items_to_process))

    # Sort alphabetically by name
    wallpapers.sort(key=lambda x: x["name"].lower())
    print(json.dumps(wallpapers))

if __name__ == "__main__":
    scan(sys.argv[1] if len(sys.argv) > 1 else "")
