#!/usr/bin/env python3
"""
atomic_write.py — Crash-resilient atomic file write utility.

Performs an atomic write via temporary file creation, explicit fsync to disk,
and atomic rename (os.replace). This guarantees zero configuration file
corruption even in the event of power loss or daemon crash.

Usage:
    from atomic_write import atomic_write
    atomic_write("/path/to/config.json", '{"key": "value"}')
"""

import os
import tempfile


def atomic_write(path: str, data: str, encoding: str = "utf-8") -> None:
    """Atomically write string data to a file path.

    Args:
        path: Target destination file path.
        data: String content to write.
        encoding: File character encoding (default utf-8).
    """
    target_dir = os.path.dirname(os.path.abspath(path))
    os.makedirs(target_dir, exist_ok=True)

    tmp_fd, tmp_path = tempfile.mkstemp(
        prefix=f".{os.path.basename(path)}.",
        suffix=".tmp",
        dir=target_dir
    )
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
