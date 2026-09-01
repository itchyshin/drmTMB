#!/usr/bin/env python3
"""Validate bounded session-routing evidence, not numerical native parity."""
import argparse
import copy
import hashlib
import json
import math
from pathlib import Path

CASES = ['ordinary_before', 'gaussian', 'bernoulli', 'two', 'ordinal',
         'categorical', 'punctuated_joint', 'ordinary_after']


def require(condition, message):
    if not condition:
        raise ValueError(message)


def finite_number(value):
    return not isinstance(value, bool) and isinstance(value, (int, float)) and math.isfinite(value)


def check(result, process):
    require(result.get('status') == 'PASS', 'session failed')
    require(list(result.get('checks', {})) == CASES, 'wrong workflow denominator')
    for name in CASES:
        case = result['checks'][name]
        require(case.get('status') == 'PASS', 'failed case: ' + name)
        require(finite_number(case.get('elapsed')) and case['elapsed'] >= 0, 'invalid case time')
        require(isinstance(case.get('value'), dict), 'missing case outputs')
        value = case['value']
        require(isinstance(value.get('coef'), dict) and {'mu', 'sigma'} <= set(value['coef']),
                'missing coefficient blocks')
        sizes = []
        for coefficients in value['coef'].values():
            values = coefficients if isinstance(coefficients, list) else [coefficients]
            require(len(values) > 0 and all(finite_number(x) for x in values), 'invalid coefficients')
            sizes.append(len(values))
        require(finite_number(value.get('loglik')), 'missing likelihood')
        if name not in ('ordinary_before', 'ordinary_after'):
            dimension = sum(sizes)
            covariance = value.get('covariance')
            require(isinstance(covariance, list) and len(covariance) == dimension and
                    all(isinstance(row, list) and len(row) == dimension and
                        all(finite_number(x) for x in row) for row in covariance), 'invalid covariance structure')
            variables = ['x1', 'x2'] if name == 'two' else ['x']
            tables = value.get('imputation')
            require(isinstance(tables, dict) and list(tables) == variables, 'missing imputation metadata')
            nrows = 180 if name in ('ordinal', 'categorical') else 160
            for variable, table in tables.items():
                require(isinstance(table, list) and len(table) == nrows, 'wrong original-row denominator')
                require([row.get('original_row') for row in table] == list(range(1, nrows + 1)), 'row restoration changed')
                for row in table:
                    require(row.get('variable') == variable and isinstance(row.get('observed'), bool) and
                            isinstance(row.get('model_row'), int) and
                            isinstance(row.get('source'), str) and isinstance(row.get('uncertainty_status'), str),
                            'invalid row metadata')
            require(isinstance(value.get('newdata'), list) and len(value['newdata']) == 8 and
                    all(isinstance(row, dict) and set(variables) <= set(row) for row in value['newdata']),
                    'missing newdata')
            require(isinstance(value.get('newdata_mu'), list) and len(value['newdata_mu']) == 8 and
                    all(finite_number(x) for x in value['newdata_mu']), 'missing newdata predictions')
            for field in ('mu_error', 'sigma_error'):
                require(finite_number(value.get(field)) and 0 <= value[field] < 1e-10,
                        'invalid prediction error: ' + name + ':' + field)
            require(set(value.get('refusals', {})) == {'profile', 'bootstrap'}, 'missing refusals')
            require(all(isinstance(x, str) and 'not implemented' in x
                        for x in value['refusals'].values()), 'unsupported inference accepted')
    require(result.get('repeat_equal') is True, 'ordinary route changed')
    require(result['checks']['ordinary_before']['value'] == result['checks']['ordinary_after']['value'],
            'ordinary outputs differ')
    require(finite_number(result.get('elapsed')) and result['elapsed'] >= 0, 'invalid session time')
    runtime = result.get('runtime', {})
    require(runtime.get('threads') == 1 and runtime.get('blas') == 1, 'wrong thread budget')
    require(process.get('exit_code') == 0 and process.get('timeout') is False, 'runner failed')
    require(finite_number(process.get('elapsed')) and 0 <= process['elapsed'] <= 120,
            'runner exceeded the registered bound')
    before, after = process.get('source_before'), process.get('source_after')
    require(isinstance(before, dict) and len(before) > 100, 'missing source manifest')
    require(before == after and process.get('source_unchanged') is True, 'source drift')
    require(runtime.get('source') in before, 'runtime source absent from manifest')
    julia_root = Path(runtime['source']).parent.parent
    r_bridge = [Path(name) for name in before if name.endswith('/R/julia-bridge.R')]
    require(len(r_bridge) == 1, 'missing R bridge source')
    r_root = r_bridge[0].parent.parent
    expected = set()
    for root, patterns in [(julia_root, ['src/**/*.jl', 'test/**/*.jl', 'Project.toml', 'Manifest.toml']),
                           (r_root, ['R/*.R', 'tests/testthat/*.R', 'src/drmTMB.so', 'DESCRIPTION', 'NAMESPACE'])]:
        for pattern in patterns:
            expected.update(str(p) for p in root.glob(pattern) if p.is_file())
    require(set(before) == expected, 'source file coverage differs from registered inputs')
    require(str(julia_root / 'src/bridge.jl') in before, 'missing Julia bridge source')
    require(all(isinstance(s, str) and len(s) == 64 for s in before.values()), 'invalid source hashes')


def self_test(result, process):
    def empty_ordinary(r, p):
        for name in ('ordinary_before', 'ordinary_after'):
            r['checks'][name]['value'] = {}

    def strip_outputs(r, p):
        value = r['checks']['gaussian']['value']
        r['checks']['gaussian']['value'] = {k: value[k] for k in ('mu_error', 'sigma_error', 'refusals')}

    def omit_bridge_sources(r, p):
        for field in ('source_before', 'source_after'):
            p[field] = {k: v for k, v in p[field].items()
                        if not k.endswith(('/R/julia-bridge.R', '/src/bridge.jl'))}

    edits = [empty_ordinary, strip_outputs, omit_bridge_sources,
        lambda r, p: r['checks'].pop('categorical'),
        lambda r, p: r['checks']['two'].update(status='FAIL'),
        lambda r, p: r['checks']['ordinal']['value'].update(mu_error=math.nan),
        lambda r, p: r['checks']['gaussian']['value'].update(sigma_error=1e-4),
        lambda r, p: r['checks']['bernoulli']['value']['refusals'].update(bootstrap='ACCEPTED'),
        lambda r, p: r.update(repeat_equal=False),
        lambda r, p: r['runtime'].update(threads=8),
        lambda r, p: p.update(timeout=True),
        lambda r, p: p.update(elapsed=121),
        lambda r, p: p.update(source_after={}),
    ]
    for i, edit in enumerate(edits):
        r, p = copy.deepcopy(result), copy.deepcopy(process)
        edit(r, p)
        try:
            check(r, p)
        except ValueError:
            continue
        raise ValueError('damage accepted: ' + str(i))
    print('DAMAGE_CONTROLS_REJECTED', len(edits))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('result', type=Path)
    parser.add_argument('process', type=Path)
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--verify-current-files', action='store_true')
    args = parser.parse_args()
    result = json.loads(args.result.read_text())
    process = json.loads(args.process.read_text())
    check(result, process)
    if args.verify_current_files:
        for name, expected in process['source_before'].items():
            require(hashlib.sha256(Path(name).read_bytes()).hexdigest() == expected,
                    'current file changed: ' + name)
    if args.self_test:
        self_test(result, process)
    print('SESSION_ROUTING_RECEIPT_PASS; no native parity, imputation, covariance or coverage verdict')
