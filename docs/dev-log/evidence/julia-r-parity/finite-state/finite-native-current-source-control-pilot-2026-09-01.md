# Current-source native stopping-control pilot — 2026-09-01

## Purpose

Test whether native `drmTMB` optimizer controls remove the ordinal/categorical
finite-state gradient discrepancy recorded by `finite-native-003`. This is a
**current-source diagnostic only**. It is not a replacement native reference:
the full frozen source manifest recorded in `finite-native-003.json` does not
match the current checkout, specifically because its historical
`R/julia-bridge.R` blob is not reachable from Git history.

## Command

```sh
Rscript /private/tmp/finite_native_stopping_current_source_pilot.R
```

The script regenerates the deterministic ordinal and categorical predictor-mask
fixtures, compares to `finite-native-003.json`, and evaluates two controls:
`drm_control(optimizer = list(rel.tol = 1e-12, eval.max = 5000L,
iter.max = 5000L))` and `drm_control(optimizer_preset = "robust")`.

## Result

| Control | Case | max parameter delta | objective delta | max native gradient | convergence |
|---|---|---:|---:|---:|---:|
| strict | ordinal | 2.20464853082e-06 | -2.87496959572e-09 | 1.512913787e-04 | 0 |
| strict | categorical | 0 | 0 | 9.39912184073e-04 | 1 |
| robust | ordinal | 0 | 0 | 1.57316970534e-03 | 0 |
| robust | categorical | 0 | 0 | 9.39912184073e-04 | 0 |

The strict ordinal run improves the native gradient versus the stored default
(about 1.57e-03) but does not meet a small-gradient criterion. The categorical
case is unchanged under strict control and reports singular convergence. These
results do not justify relaxing the Julia--R comparison tolerance or claiming a
native optimum.

## Next action

Recover the exact historical source manifest before any claim-bearing control
sweep. Until then, retain the current-source pilot as a diagnostic and keep the
finite-state parity gate open.
