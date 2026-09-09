# Temporal AR1 final-source recovery fixture

This is the successor to the historical local recovery fixture. It reruns the
same deterministic twelve-fit diagnostic after the temporal transition-scale
hardening, so the retained evidence is tied to the final estimator source.
The historical directory remains unchanged.

`tools/run-temporal-ar1-recovery.R` creates six AR1-only datasets and six
matched ordinary-intercept-plus-AR1 datasets. Each dataset has 80 series,
irregular integer occasions `0, 1, 3, 4, 6, 7`, a balanced between-series
predictor, and an independently permuted balanced within-series predictor.
Generating values are `beta = (0, 0.5, 0.5)`, temporal SD `0.8`, residual SD
`0.4`, persistence `-0.60, -0.30, 0.20, 0.45, 0.70, 0.85`, and ordinary-
intercept SD `0.6` for the matched models.

The runner records both required signed persistence starts for every fit. It
requires all twelve selected fits finite, exactly 24 retained attempts, mean
absolute fixed-effect error at most `0.20`, median absolute SD error at most
`0.35`, and median absolute persistence error at most `0.30`. The tables,
source commit, runner checksum, and `session-info.txt` are retained together.
