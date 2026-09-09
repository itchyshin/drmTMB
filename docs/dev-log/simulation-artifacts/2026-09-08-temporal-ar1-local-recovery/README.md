# Temporal AR1 local recovery fixture

This retained fixture is a deterministic recovery diagnostic for the first
Gaussian temporal AR1 implementation. It is not the ADEMP interval-calibration
campaign.

`tools/run-temporal-ar1-recovery.R` creates six AR1-only datasets and six
matched ordinary-intercept-plus-AR1 datasets. Each dataset has 80 series,
irregular integer occasions `0, 1, 3, 4, 6, 7`, one balanced between-series
predictor, and one independently permuted balanced within-series predictor.
The generating values are `beta = (0, 0.5, 0.5)`, temporal SD `0.8`, residual
SD `0.4`, and persistence `-0.60, -0.30, 0.20, 0.45, 0.70, 0.85`. The matched
models add ordinary-intercept SD `0.6`.

The runner records both required persistence starts for every fit. Its
predeclared acceptance criteria are all 12 selected fits finite, exactly 24
retained attempts, mean absolute fixed-effect error at most `0.20`, median
absolute SD error at most `0.35`, and median absolute persistence error at
most `0.30`. Results are written only after all fixtures run, including when a
criterion fails, so failures remain available for diagnosis.

The generated `raw-attempts.csv`, `recovery-estimates.csv`, `criteria.csv`,
`provenance.csv`, and `recovery-results.rds` files are immutable evidence for
this source commit. Re-running the runner intentionally creates a new evidence
set and requires a fresh review rather than silently replacing retained output.
