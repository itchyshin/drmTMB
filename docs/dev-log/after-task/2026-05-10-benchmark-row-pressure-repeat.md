# After Task: 500k Row-Pressure Repeat

## Goal

Repeat the 500,000-row, 1,000-species memory-light Gaussian phylogenetic
baseline before adding new stressors.

## Implemented

- Ran the same current-schema benchmark row a second time.
- Added the repeated row to `docs/dev-log/benchmark-results.md`.
- Recorded the exact command and summary in `docs/dev-log/check-log.md`.

## Mathematical Contract

The benchmark used the existing univariate Gaussian phylogenetic location
model:

```r
y ~ x1 + x2 + phylo(1 | species, tree = tree)
sigma ~ 1
```

No likelihood, parameterization, formula grammar, fitted-object API, or
benchmark generator changed.

## Files Changed

- `docs/dev-log/benchmark-results.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-row-pressure-repeat.md`

## Checks Run

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 500000 --species 1000 --eval-max 220 --iter-max 220 --memory-light true --output /tmp/drmTMB-row-pressure-current-schema-repeat-004be10.csv`:
  passed.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-row-pressure-current-schema-repeat-004be10.csv`:
  passed and marked the row as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-row-pressure-current-schema-repeat-004be10.csv', check.names = FALSE); print(x[, c('rows','species','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat','sd_phylo_hat')]);"`:
  passed.
- `air format docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-row-pressure-repeat.md`:
  passed.
- `rg -n "timing usable, repeat|133\\.997|5,066,604,544|row-pressure-current-schema-repeat|50 iterations, 74 function" docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-row-pressure-repeat.md`:
  passed and found the repeated-row evidence.
- `git diff --check`: passed.

## Result

The repeated 500,000-row, 1,000-species memory-light row converged with
convergence code 0, optimizer message `relative convergence (4)`, 50
iterations, 74 function evaluations, and 50 gradient evaluations.

| Scenario | Fit seconds | Fit object MB | Model matrix MB | TMB data MB | Post-fit R heap MB | macOS max RSS bytes | macOS peak footprint bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 500k rows, 1k species, memory-light repeat | 133.997 | 221.206 | 76.296 | 105.249 | 1092.205 | 5,066,604,544 | 2,028,277,504 |

## Tests Of The Tests

The summary helper marked the row as `timing_usable` with
`diagnostics_recorded`. The optimizer message and evaluation counts matched
the first 500k row.

## Consistency Audit

The repeat supports a cautious row-pressure claim for this one Gaussian
phylogenetic benchmark path. It does not test factor-heavy designs,
`sigma ~ x1` at 500k rows, bivariate covariance, non-Gaussian families,
10,000 species, or million-row workloads.

## What Did Not Go Smoothly

Nothing failed. The local max RSS stayed near 5 GB, so the repeat strengthens
the memory caveat rather than removing it.

## Team Learning

Curie was right to request a repeat before adding a new stressor. Rose should
keep repeat rows visible when they are used to support planning claims.

## Known Limitations

This is still a local benchmark on one machine. It is not a formal performance
study and does not justify million-row readiness.

## Next Actions

- Add a 500k `sigma ~ x1` row only after the current CI queue is green.
- Keep factor-heavy 500k testing blocked until sparse fixed-effect design
  work begins.
