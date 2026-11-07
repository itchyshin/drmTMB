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
assert len(rows) == 23
nb2 = [r for r in rows if r['family'] == 'NegBinomial2' and r['route'] in ('plain', 'constant_sd')]
assert len(nb2) == 8
assert {r['seed'] for r in nb2} == {'20261022', '20261023', '20261024', '20261025'}
assert all(r['gradient_status'] == 'unavailable' and r['stored_current_delta'] == '0.0' for r in nb2)
zob = [r for r in rows if r['family'] == 'ZeroOneBeta']
assert len(zob) == 6
assert {r['attempt_phase'] for r in zob} == {'initial', 'frozen-verification', 'frozen-verification-final'}
for phase in {r['attempt_phase'] for r in zob}:
    pair = {r['seed']: r for r in zob if r['attempt_phase'] == phase}
    assert pair['20261409']['status'] == 'returned'
    assert pair['20261412']['status'] == 'error'
retained = json.loads((prefix / 'historical-initial/retained-index.json').read_text())
assert len(retained['files']) == 35
for item in retained['files']:
    path = root / item['retained_path']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], item['retained_path']
accepted = json.loads((prefix / 'frozen-verification-final/receipt.json').read_text())
assert accepted['status'] == 'EXECUTIONS_COMPLETED_SOURCE_UNCHANGED'
assert accepted['before'] == accepted['after'] and accepted['source_unchanged']
assert len(accepted['jobs']) == 5
for job in accepted['jobs']:
    assert job['exit_code'] == 0
    log = prefix / 'frozen-verification-final' / (job['name'] + '.log')
    assert hashlib.sha256(log.read_bytes()).hexdigest() == job['log_sha256'], job['name']
predecessor = json.loads((prefix / 'frozen-verification/receipt.json').read_text())
assert predecessor['status'] == 'ABORTED_ON_NATIVE_DLL_REBUILD'
assert predecessor['source_code_unchanged']
assert all(job['exit_code'] == 0 for job in predecessor['jobs'])
assert any(r['status'] == 'regression_passed' for r in rows if r['concern'] == 'Stored log-likelihood at optimum')
assert all(r['repair'] == 'none' and r['calibration'] == 'deferred' for r in rows)
print('ML_FIRST_ARTIFACT_INTEGRITY_PASS')
