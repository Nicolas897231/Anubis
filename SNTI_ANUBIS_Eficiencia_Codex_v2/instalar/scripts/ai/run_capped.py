#!/usr/bin/env python3
"""Run a targeted command with capped terminal output, private log and exit code.

NEVER run commands that print API keys, JWTs, TOTP/recovery tokens or passwords.
Example: python scripts/ai/run_capped.py --max-bytes 4000 -- git diff --stat
"""
import argparse
import datetime as dt
import os
from pathlib import Path
import subprocess
import sys
import time


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--max-bytes', type=int, default=4000)
    parser.add_argument('--timeout', type=int, default=180)
    parser.add_argument('--log-dir', default='.codex-output')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    if not command or args.max_bytes < 512 or args.timeout < 1:
        parser.error('Provide command after --, max-bytes >= 512, timeout >= 1')

    logdir = Path(args.log_dir)
    logdir.mkdir(parents=True, exist_ok=True)
    if os.name != 'nt':
        os.chmod(logdir, 0o700)
    stamp = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    logfile = logdir / f'cmd-{stamp}-{os.getpid()}.log'
    start = time.monotonic()
    timed_out = False

    try:
        with logfile.open('xb') as output:
            if os.name != 'nt':
                os.chmod(logfile, 0o600)
            with subprocess.Popen(command, stdout=output, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL) as proc:
                try:
                    code = proc.wait(timeout=args.timeout)
                except subprocess.TimeoutExpired:
                    timed_out = True
                    proc.kill()
                    proc.wait()
                    code = 124
    except FileNotFoundError:
        print('ERROR: command executable not found', file=sys.stderr)
        return 127
    except KeyboardInterrupt:
        print('Interrupted. Check whether a child process is still running.', file=sys.stderr)
        return 130
    except OSError as exc:
        print(f'ERROR: {exc.__class__.__name__}', file=sys.stderr)
        return 1

    total = logfile.stat().st_size
    if total <= args.max_bytes:
        shown = logfile.read_bytes()
        print(shown.decode('utf-8', errors='replace'), end='')
    else:
        head_budget = int(args.max_bytes * .60)
        tail_budget = args.max_bytes - head_budget
        with logfile.open('rb') as f:
            head = f.read(head_budget)
            f.seek(-tail_budget, os.SEEK_END)
            tail = f.read(tail_budget)
        print(head.decode('utf-8', errors='replace'), end='')
        print(f'\n...[output capped: {total} total bytes; review private log locally if needed]...\n')
        print(tail.decode('utf-8', errors='replace'), end='')
    print(f'\n[exit={code} | timeout={timed_out} | seconds={time.monotonic()-start:.1f} | bytes={total} | private_log={logfile}]')
    return code if code >= 0 else 128 + abs(code)


if __name__ == '__main__':
    sys.exit(main())
