#!/usr/bin/env python3
import os

def atomic_write(path, data, encoding="utf-8"):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding=encoding) as fp:
        fp.write(data)
        fp.flush()
        os.fsync(fp.fileno())
    os.replace(tmp, path)
