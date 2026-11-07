"""Verify bounded prior receipts against the source files they identify."""
from pathlib import Path
import csv
import hashlib
import json
import math
import re
import subprocess
import sys
here = Path(__file__).resolve().parent
root = here.parents[2]
evidence = here / 'evidence'
julia_root = Path('/Users/z3437171/.codex/worktrees/drmodels-fixed-priors-20261105/DRM.jl')


def check_pairs(rows):
    required = {'gaussian-mu-sigma', 'binomial-partial', 'gaussian-zero-ridge',
                'gaussian-factor-interaction', 'gaussian-no-intercept-factor'}
    assert {r['case'] for r in rows} == required and len(rows) == 5
    for row in rows:
        for field, bound in {'coef_max_abs': 1e-6, 'loglik_abs': 1e-8,
                             'prior_abs': 1e-8, 'objective_abs': 1e-8,
                             'prior_gradient_abs': 1e-6}.items():
            x = float(row[field])
            assert math.isfinite(x) and 0 <= x <= bound, (row['case'], field, x)
        assert row['estimator'] == ('ML' if row['case'] == 'gaussian-zero-ridge' else 'MAP')


stage = sys.argv[1]
if stage == 'r':
    expected = json.loads((evidence / 'r-closeout-source-manifest.json').read_text())
    actual = json.loads(subprocess.check_output(
        [sys.executable, str(here / 'source-manifest.py'), str(root)], text=True))
    assert expected == actual, 'R implementation/test source changed after validation'
    assert 'R_PRIOR_ORACLES_PASS' in (evidence / 'r-closeout-focused.log').read_text()
    controls = list(csv.DictReader((evidence / 'r-prior-negative-controls.csv').open()))
    assert len(controls) == 6 and all(r['rejected'] == 'TRUE' for r in controls)
    assert 'PRIOR_NEGATIVE_CONTROLS_PASS 6/6' in (evidence / 'r-prior-negative-controls.log').read_text()
    print('PRIORS_R_RECEIPT_PASS negative_controls=6')
elif stage == 'julia':
    manifest = (evidence / 'julia-source.sha256').read_bytes()
    assert hashlib.sha256(manifest).hexdigest() == 'a30e347285f925af2e128ed6350fafe4d6b9035668444606bfa2fcea13e26653'
    seen = set()
    for line in manifest.decode().splitlines():
        digest, name = line.split('  ', 1)
        seen.add(name)
        assert hashlib.sha256((julia_root / name).read_bytes()).hexdigest() == digest, name
    assert seen == {'Project.toml'} | {p.relative_to(julia_root).as_posix()
                                     for p in (julia_root / 'src').rglob('*.jl')}
    for line in (evidence / 'julia-tests.sha256').read_text().splitlines():
        digest, name = line.split('  ', 1)
        assert hashlib.sha256((julia_root / name).read_bytes()).hexdigest() == digest, name
    log = (evidence / 'julia-focused-final.log').read_text()
    rows = re.findall(r'\|\s+(\d+)\s+(\d+)\s+[\d.]+s\s*$', log, re.MULTILINE)
    assert rows and all(a == b for a, b in rows) and sum(int(b) for _, b in rows) == 82
    assert 'ERROR:' not in log
    print('PRIORS_JULIA_RECEIPT_PASS')
elif stage == 'pair':
    rows = list(csv.DictReader((evidence / 'live-pair-closeout.csv').open()))
    check_pairs(rows)
    bad = [dict(r) for r in rows]
    bad[0]['coef_max_abs'] = '0.01'
    for mutation in [bad, rows[:-1]]:
        try:
            check_pairs(mutation)
        except AssertionError:
            pass
        else:
            raise AssertionError('Pair receipt verifier accepted a broken control')
    assert 'LIVE_PRIOR_PAIR_PASS' in (evidence / 'live-pair-closeout.log').read_text()
    print('PRIORS_PAIR_RECEIPT_PASS negative_controls=2')
else:
    raise SystemExit('Use r, julia or pair')
