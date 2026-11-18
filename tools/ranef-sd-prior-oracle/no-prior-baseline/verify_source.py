#!/usr/bin/env python3
"""Verify source blobs in two git-archive snapshots against pinned commits."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('repo', help='local drmTMB Git repository with both commits')
parser.add_argument('snapshots', help='directory containing base/ and candidate/')
parser.add_argument('--output', required=True, help='new path for the source-pin report')
args = parser.parse_args()
repo = Path(args.repo).resolve(strict=True)
root = Path(args.snapshots).resolve(strict=True)
pins = {'base': 'bfa7acf5bb85e298fe675c5713c34fa208abd860',
        'candidate': 'bcb6755861494aa8bfdc692067b8c861e97c06ce'}
out = {}
for label, rev in pins.items():
    raw = subprocess.check_output(['git', '-C', str(repo), 'ls-tree', '-rz', rev,
                                   '--', 'R', 'src', 'DESCRIPTION', 'NAMESPACE'])
    count = 0
    for item in raw.split(b'\0'):
        if not item:
            continue
        head, path = item.split(b'\t', 1)
        mode, kind, oid = head.split(b' ')
        if kind != b'blob':
            raise RuntimeError(f'unexpected tree entry: {item!r}')
        target = root / label / os.fsdecode(path)
        data = os.readlink(target).encode() if mode == b'120000' else target.read_bytes()
        actual = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest().encode()
        if actual != oid:
            raise RuntimeError(f'blob mismatch {label}: {target}')
        count += 1
    if count != 74:
        raise RuntimeError(f'unexpected source blob count for {label}: {count}')
    tree = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', rev + '^{tree}'], text=True).strip()
    out[label] = {'commit': rev, 'input_blobs_verified': count, 'tree': tree}
output = Path(args.output)
with output.open('x') as f:
    json.dump(out, f, indent=2)
    f.write('\n')
print(json.dumps(out, indent=2))
print('SOURCE_BLOB_CHECK_PASS')
