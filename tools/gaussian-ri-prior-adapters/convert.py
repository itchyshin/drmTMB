#!/usr/bin/env python3
"""Transport frozen fixture inputs without expected values; normalize Julia TOML."""
import argparse
import json
import math
from pathlib import Path
import tomllib


def literal(value):
    if isinstance(value, dict):
        return '{' + ', '.join(json.dumps(k) + ' = ' + literal(v)
                               for k, v in value.items() if v is not None) + '}'
    if isinstance(value, list):
        return '[' + ', '.join(literal(v) for v in value) + ']'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, (int, float)) and math.isfinite(value):
        return repr(value)
    raise ValueError('unsupported or nonfinite fixture value')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['input-toml', 'input-json', 'julia-output'])
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.mode.startswith('input-'):
        data = json.loads(args.source.read_text())
        data = {k: v for k, v in data.items() if k != 'expected'}
        if args.mode == 'input-toml':
            text = '\n'.join(json.dumps(k) + ' = ' + literal(v) for k, v in data.items()) + '\n'
            parsed = tomllib.loads(text)
            assert parsed == data, 'TOML transport changed fixture input'
        else:
            text = json.dumps(data, allow_nan=False, indent=2) + '\n'
        args.output.write_text(text)
        return
    data = tomllib.loads(args.source.read_text())
    data['schema_version'] = 1
    data['engine'] = 'Julia/native'
    data['coordinate_scale'] = 'log_tau'
    point = data['point']
    point['status'] = 'boundary_evaluated' if data['boundary'] else 'evaluated'
    if 'fit' in data:
        fit = data['fit']
        fit['theta_native'] = fit['theta'][:]
        fit['theta'] = fit['theta'][:-1] + [fit['tau']]
        fit['prior'] = fit['objective'] - fit['data_nll']
    args.output.write_text(json.dumps(data, allow_nan=False, indent=2) + '\n')


if __name__ == '__main__':
    main()
