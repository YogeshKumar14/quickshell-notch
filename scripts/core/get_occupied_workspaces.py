import subprocess
import json

try:
    out = subprocess.check_output(["hyprctl", "workspaces", "-j"]).decode("utf-8")
    workspaces = json.loads(out)
    occupied = [ws["id"] for ws in workspaces if ws.get("windows", 0) > 0]
    print(json.dumps(occupied))
except Exception:
    print("[]")
