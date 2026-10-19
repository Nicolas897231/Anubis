#!/usr/bin/env python3
"""Targeted text search. Require scoped path(s), cap matches and output bytes.

Examples:
 python scripts/ai/search_code.py 'getAuthenticatorAssuranceLevel' src/lib/auth
 python scripts/ai/search_code.py 'resetPasswordForEmail' src/app src/lib
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pattern')
    parser.add_argument('paths', nargs='+')
    parser.add_argument('--max-matches', type=int, default=30)
    parser.add_argument('--max-bytes', type=int, default=4000)
    parser.add_argument('--regex', action='store_true', help='Regex match; literal is default')
    args = parser.parse_args()
    if args.max_matches < 1 or args.max_bytes < 256:
        parser.error('max-matches >= 1, max-bytes >= 256')
    if not args.pattern.strip():
        parser.error('Nonempty pattern required')
    allowed = []
    for p in args.paths:
        candidate = Path(p)
        if any(x in {'.git','.env','.codex-output','node_modules','.next','codex-efficiency-setup'} for x in candidate.parts):
            parser.error('Unsafe or irrelevant search path: ' + p)
        if candidate.exists():
            allowed.append(p)
    if not allowed:
        print('BLOCKED: none of the requested paths exists; no whole-repo fallback.')
        return 2

    if shutil.which('rg'):
        cmd = ['rg', '--line-number', '--no-heading', '--color', 'never', '--glob', '!**/.env*',
               '--glob', '!**/.codex-output/**', '--glob', '!**/node_modules/**',
               '--glob', '!**/.next/**']
        if not args.regex:
            cmd.append('--fixed-strings')
        cmd += ['--', args.pattern, *allowed]
    elif shutil.which('git'):
        # git grep searches tracked files only. No silent widening to full repo.
        cmd = ['git', 'grep', '-n', '-I']
        cmd += ['-E' if args.regex else '-F', '-e', args.pattern, '--', *allowed]
    else:
        print('BLOCKED: install/use rg or run within tracked Git checkout.')
        return 2
    p = subprocess.run(cmd, capture_output=True, text=True, errors='replace', check=False)
    if p.returncode not in (0, 1):
        print('ERROR: scoped search failed; inspect paths/tool installation.')
        return p.returncode
    matches = p.stdout.splitlines()
    selected = '\n'.join(matches[:args.max_matches])
    raw = selected.encode('utf-8')
    if len(raw) > args.max_bytes:
        selected = raw[:args.max_bytes].decode('utf-8', errors='replace') + '\n...[byte cap]'
    print(selected if selected else '(no matches in targeted paths)')
    if len(matches) > args.max_matches:
        print(f'[matches: {len(matches)}, displayed: {args.max_matches}; narrow search]')
    return 0 if matches else 1


if __name__ == '__main__':
    sys.exit(main())
