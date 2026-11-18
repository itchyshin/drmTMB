#!/usr/bin/env bash
# Run in the isolated R source tree after separately recording source/toolchain pins.
set -euo pipefail
: "${R_SOURCE_ROOT:?set the isolated R source directory}"
: "${J_SOURCE_ROOT:?set the isolated Julia source directory}"
: "${JULIA_BIN:?set the qualified Julia executable}"
output="${1:?usage: run-validation.sh NEW_OUTPUT_DIRECTORY [--preflight]}"
[[ "$output" = /* ]] || { echo 'Output directory must be absolute' >&2; exit 2; }
count=12
if [[ "${2:-}" == "--preflight" ]]; then count=4; elif [[ -n "${2:-}" ]]; then exit 2; fi
[[ ! -e "$output" ]] || { echo 'Refusing to overwrite an earlier validation attempt' >&2; exit 2; }
mkdir -p "$output"/{input,r-native,julia-native,bridge,logs}
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=4
export DRMODELS_JL_PATH="$J_SOURCE_ROOT"
export JULIA_HOME="${JULIA_BIN%/*}"
adapter="$R_SOURCE_ROOT/tools/gaussian-ri-prior-adapters"
oracle="$R_SOURCE_ROOT/tools/gaussian-ri-prior-validation"
for index in $(seq 1 "$count"); do
    id=$(printf 'ri_%02d' "$index")
    python3 "$adapter/convert.py" input-json "$oracle/fixtures/$id.json" "$output/input/$id.json"
    python3 "$adapter/convert.py" input-toml "$oracle/fixtures/$id.json" "$output/input/$id.toml"
    (
        cd "$R_SOURCE_ROOT"
        Rscript --vanilla "$adapter/r-native.R" "$output/input/$id.json" "$output/r-native/$id.json"
    ) > "$output/logs/$id-r-native.log" 2>&1
    "$JULIA_BIN" --project="$J_SOURCE_ROOT" \
        "$J_SOURCE_ROOT/tools/gaussian-ri-prior-adapters/julia-native.jl" \
        "$output/input/$id.toml" "$output/julia-native/$id.toml" --fit \
        > "$output/logs/$id-julia-native.log" 2>&1
    python3 "$adapter/convert.py" julia-output "$output/julia-native/$id.toml" "$output/julia-native/$id.json"
    (
        cd "$R_SOURCE_ROOT"
        Rscript --vanilla "$adapter/r-bridge.R" "$output/input/$id.json" "$output/bridge/$id.json"
    ) > "$output/logs/$id-bridge.log" 2>&1
    python3 "$adapter/compare.py" --fit "$output/r-native/$id.json" \
        "$output/julia-native/$id.json" "$output/bridge/$id.json" \
        > "$output/logs/$id-independent-verification.log" 2>&1
    echo "$id all three routes independently verified"
done
python3 - "$output" "$count" <<'PY'
import json, pathlib, sys
root, count = pathlib.Path(sys.argv[1]), int(sys.argv[2])
expected = {f'ri_{i:02d}' for i in range(1, count + 1)}
engines = {'r-native': 'R/TMB', 'julia-native': 'Julia/native', 'bridge': 'R/Julia-bridge'}
for route, engine in engines.items():
    files = sorted((root / route).glob('ri_*.json'))
    assert len(files) == count, (route, len(files), count)
    results = [json.loads(p.read_text()) for p in files]
    assert {r['id'] for r in results} == expected, route
    assert all(r['engine'] == engine for r in results), route
report = {'status': 'PASS', 'fixtures': count, 'routes': list(engines),
          'package_fits': count * 3,
          'scope': 'native fixed-point checks and native/bridge fitted checks; no bridge arbitrary-point Hessian'}
(root / 'SUMMARY.json').write_text(json.dumps(report, indent=2) + '\n')
print('THREE_ROUTE_VALIDATION_PASS')
PY
