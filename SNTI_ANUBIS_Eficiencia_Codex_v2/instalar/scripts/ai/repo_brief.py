#!/usr/bin/env python3
"""Compact Git-oriented context. Read-only. Does NOT crawl the source tree."""
import argparse
import subprocess
import sys


def git(*args: str) -> tuple[int, str]:
    p = subprocess.run(['git', *args], capture_output=True, text=True, errors='replace', check=False)
    return p.returncode, (p.stdout or p.stderr)


def limit(s: str, budget: int) -> str:
    raw = s.encode('utf-8')
    if len(raw) <= budget:
        return s.strip()
    return raw[:budget].decode('utf-8', errors='replace').rstrip() + '\n...[truncated]'


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--max-bytes', type=int, default=4000)
    args = parser.parse_args()
    if args.max_bytes < 600:
        parser.error('max-bytes must be >= 600')
    rc, root = git('rev-parse', '--show-toplevel')
    if rc:
        print('BLOCKED: no readable Git repository in this folder. No git init or repairs performed.')
        return 2
    _, branch = git('branch', '--show-current')
    _, latest = git('log', '-1', '--format=%h %s')
    _, status = git('status', '--short', '--untracked-files=normal')
    _, diff = git('diff', '--stat')
    _, staged = git('diff', '--cached', '--stat')
    blocks = [f'ROOT: {root.strip()}', f'BRANCH: {branch.strip()}', f'HEAD: {latest.strip()}',
              'STATUS:\n' + (status.strip() or '(clean)'),
              'UNSTAGED DIFF STAT:\n' + (diff.strip() or '(none)'),
              'STAGED DIFF STAT:\n' + (staged.strip() or '(none)')]
    print(limit('\n\n'.join(blocks), args.max_bytes))
    return 0


if __name__ == '__main__':
    sys.exit(main())
