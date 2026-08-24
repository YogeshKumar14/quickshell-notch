#!/usr/bin/env python3
import os
import tempfile

def atomic_write(path, data, encoding="utf-8"):
    target_dir = os.path.dirname(os.path.abspath(path))
    os.makedirs(target_dir, exist_ok=True)
    
    # Create securely named temp file in the same directory for atomic rename
    tmp_fd, tmp_path = tempfile.mkstemp(prefix=f".{os.path.basename(path)}.", suffix=".tmp", dir=target_dir)
    try:
        with open(tmp_fd, "w", encoding=encoding) as fp:
            fp.write(data)
            fp.flush()
            os.fsync(fp.fileno())
        os.replace(tmp_path, path)
    finally:
        try:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
        except OSError:
            pass
