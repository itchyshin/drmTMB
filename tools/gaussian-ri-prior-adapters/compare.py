#!/usr/bin/env python3
"""Compare package exports with the independent frozen dense Gaussian oracle."""
import argparse
import copy
import json
from pathlib import Path
import sys

ORACLE = Path(__file__).resolve().parents[1] / 'gaussian-ri-prior-validation'
sys.path.insert(0, str(ORACLE))
import numpy as np
from verify import LIMITS, evaluate, err


def check(result, include_fit=False):
    fixture = json.loads((ORACLE / 'fixtures' / (result['id'] + '.json')).read_text())
    expected = fixture['expected']
    report = {'id': result['id'], 'engine': result['engine'], 'errors': {}, 'unavailable': []}

    def close(label, actual, reference, limit):
        actual, reference = np.asarray(actual, dtype=float), np.asarray(reference, dtype=float)
        assert actual.shape == reference.shape, (label, actual.shape, reference.shape)
        assert np.isfinite(actual).all() and np.isfinite(reference).all(), label
        error = err(actual, reference)
        report['errors'][label] = error
        assert error <= limit, (result['id'], label, error, limit)

    point = result.get('point', {})
    status = point.get('status', 'unavailable')
    if status in ('evaluated', 'boundary_evaluated', 'boundary_fixed_only_value'):
        value, gradient = evaluate(fixture)
        no_prior = copy.deepcopy(fixture)
        no_prior['priors'] = []
        data_nll, _ = evaluate(no_prior)
        close('point_objective', point['objective'], expected['nll'], LIMITS['value'])
        close('point_data_nll', point['data_nll'], data_nll, LIMITS['value'])
        close('point_prior', point['prior'], value - data_nll, LIMITS['value'])
        close('point_decomposition', point['objective'], point['data_nll'] + point['prior'], LIMITS['value'])
        if fixture['point']['tau'] > 0:
            gradient = np.asarray(expected['gradient'], float)
            hessian = np.asarray(expected['hessian'], float)
            if result.get('coordinate_scale', 'natural_tau') == 'log_tau':
                tau = fixture['point']['tau']
                hessian[-1, -1] = tau * tau * hessian[-1, -1] + tau * gradient[-1]
                hessian[:-1, -1] *= tau
                hessian[-1, :-1] *= tau
                gradient[-1] *= tau
            close('point_gradient', point['gradient'], gradient, LIMITS['gradient'])
            close('point_hessian', point['hessian'], hessian, LIMITS['hessian'])
        else:
            report['unavailable'].append('log-SD derivatives at exact zero; separate boundary-model value checked')
    else:
        assert result['engine'] == 'R/Julia-bridge', ('missing native point evaluation', status)
        report['unavailable'].append('arbitrary-point bridge gradient/Hessian interface')

    if include_fit:
        fit = result['fit']
        theta = fit['theta']
        nb, ng = len(fixture['point']['beta']), len(fixture['point']['gamma'])
        assert len(theta) == nb + ng + 1 and theta[-1] >= 0
        assert np.isfinite(theta).all()
        point = {'beta': theta[:nb], 'gamma': theta[nb:nb + ng], 'tau': theta[-1]}
        value, _ = evaluate(fixture, point)
        no_prior = copy.deepcopy(fixture)
        no_prior['priors'] = []
        data_nll, _ = evaluate(no_prior, point)
        close('fit_objective_at_returned_point', fit['objective'], value, LIMITS['value'])
        close('fit_data_nll', fit['data_nll'], data_nll, LIMITS['value'])
        close('fit_prior', fit['prior'], value - data_nll, LIMITS['value'])
        refs = json.loads((ORACLE / 'fit-reference-totoro.json').read_text())
        best = next(x['best'] for x in refs['results'] if x['id'] == result['id'])
        assert best['eligible'], 'reference lacks verified stationarity'
        close('fit_optimum_objective', fit['objective'], best['nll'], LIMITS['fit_objective'])
        # Compare beta/gamma, not near-boundary log(group SD) coordinates.
        close('fit_coefficients', theta[:-1], best['point']['beta'] + best['point']['gamma'], LIMITS['identified_coefficient'])
        if not best['boundary']:
            close('fit_interior_group_sd', theta[-1], best['point']['tau'], LIMITS['identified_coefficient'])
        else:
            report['boundary_group_sd'] = {'reference': 0.0, 'candidate': theta[-1]}
        assert 'convergence' in fit or 'converged' in fit, 'missing explicit optimizer status'
        if 'convergence' in fit:
            assert fit['convergence'] == 0, fit
        if 'converged' in fit:
            assert fit['converged'] is True, fit
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('results', nargs='+', type=Path)
    parser.add_argument('--fit', action='store_true')
    args = parser.parse_args()
    reports = [check(json.loads(path.read_text()), args.fit) for path in args.results]
    print(json.dumps({'status': 'PASS', 'results': reports}, indent=2, allow_nan=False))
    print('INDEPENDENT_COMPARISON_PASS')


if __name__ == '__main__':
    main()
