"""
process_utils.py — Shared child process lifecycle utilities.

Provides the set_pdeathsig() helper used by all scripts that spawn
long-lived child processes (cava, nmcli monitor, bluetoothctl).
When the parent QuickShell daemon is killed, children receive SIGTERM
automatically via the Linux PR_SET_PDEATHSIG prctl, preventing orphan
process leaks.

Usage:
    from process_utils import set_pdeathsig
    subprocess.Popen([...], preexec_fn=set_pdeathsig)
"""

import signal
import ctypes


def set_pdeathsig():
    """Set PR_SET_PDEATHSIG on the current process so it receives SIGTERM
    when its parent process dies.

    This MUST be passed as ``preexec_fn`` to ``subprocess.Popen`` for every
    long-lived child process spawned by QuickShell scripts.  Without it,
    killing the QuickShell daemon leaves orphaned children consuming CPU.

    The function is a no-op on non-Linux platforms or if libc cannot be loaded.
    """
    try:
        libc = ctypes.CDLL("libc.so.6")
        PR_SET_PDEATHSIG = 1
        libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
    except Exception:
        pass
