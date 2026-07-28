#!/usr/bin/env python3
import os
import json
import hashlib
from concurrent.futures import ThreadPoolExecutor

THUMB_DIR = os.path.expanduser("~/.cache/quickshell/thumbs")
THUMB_SIZE = (160, 110)

def ensure_thumb(full_path):
    """Generate a thumbnail if it doesn't exist or is outdated. Returns thumb path."""

    path_hash = hashlib.md5(full_path.encode()).hexdigest()[:12]
    thumb_name = f"{path_hash}.jpg"
    thumb_path = os.path.join(THUMB_DIR, thumb_name)

    # Skip if thumb exists and is newer than original
    if os.path.isfile(thumb_path):
        try:
            if os.path.getmtime(thumb_path) >= os.path.getmtime(full_path):
                return thumb_path
        except OSError:
            pass

    # Generate thumbnail
    try:
        from PIL import Image
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
            img.save(thumb_path, "JPEG", quality=70, optimize=True)
        return thumb_path
    except Exception:
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

def scan():
    os.makedirs(THUMB_DIR, exist_ok=True)
    home = os.path.expanduser("~")
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

    # Process thumbnails in parallel across CPU cores
    with ThreadPoolExecutor(max_workers=16) as executor:
        wallpapers = list(executor.map(process_wallpaper, items_to_process))

    # Sort alphabetically by name
    wallpapers.sort(key=lambda x: x["name"].lower())
    print(json.dumps(wallpapers))

if __name__ == "__main__":
    scan()
