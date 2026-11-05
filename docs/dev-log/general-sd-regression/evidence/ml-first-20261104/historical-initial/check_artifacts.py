"""Byte-integrity and retained-attempt check only; no scientific fit is run."""
import csv
import hashlib
import json
from pathlib import Path

prefix = Path(__file__).resolve().parent
root = next(p for p in prefix.parents if (p / 'DESCRIPTION').is_file())
manifest = json.loads((prefix / 'artifact-manifest.json').read_text())
for item in manifest['files']:
    path = root / item['path']
    assert path.is_file(), item['path']
    assert path.stat().st_size == item['bytes'], item['path']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], item['path']
with (root / 'docs/dev-log/general-sd-regression/gap-reproduction-20261104.tsv').open() as f:
    rows = list(csv.DictReader(f, delimiter='\t'))
assert len(rows) == 18
nb2 = [r for r in rows if r['family'] == 'NegBinomial2' and r['route'] in ('plain', 'constant_sd')]
assert len(nb2) == 8
assert {r['seed'] for r in nb2} == {'20261022', '20261023', '20261024', '20261025'}
assert all(r['gradient_status'] == 'unavailable' and r['stored_current_delta'] == '0.0' for r in nb2)
zob = {r['seed']: r for r in rows if r['family'] == 'ZeroOneBeta'}
assert zob['20261409']['status'] == 'returned'
assert zob['20261412']['status'] == 'error'
assert all(r['repair'] == 'none' and r['calibration'] == 'deferred' for r in rows)
print('ML_FIRST_ARTIFACT_INTEGRITY_PASS')
