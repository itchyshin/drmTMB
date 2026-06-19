# After Task: Scale-Phylo Clamp-Active Diagnostic

## Goal

Bank one conservative scale-side phylogenetic `log(sigma)` guard artifact for
the active `drmTMB#59` numerical-guard sensitivity ledger.

## Implemented

The artifact
`docs/dev-log/simulation-artifacts/2026-06-18-scale-phylo-clamp-active-diagnostic/`
adds a reproducible runner, CSV tables, run summary, session info, and README
for a one-observation-per-tip Gaussian scale-side phylogenetic stress model.
It compares the default `log(sigma)` clamp, `logsigma_clamp = NULL`, and a wide
`logsigma_clamp = c(-25, 25)` on moderate and extreme residual-shock cells.

## Mathematical Contract

The fitted model is
`y ~ x + phylo(1 | species, tree = tree)` and
`sigma ~ x + phylo(1 | species, tree = tree)`. The location is the conditional
mean `mu`; the scale is `sigma`, modelled through `log(sigma)`. The
`log(sigma)` soft-clamp is a numerical overflow guard. If it is active at the
optimum, the fit is a guarded diagnostic fit; the clamp does not create
identifiability for a scale-side phylogenetic random field with one
observation per tip.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-18-scale-phylo-clamp-active-diagnostic/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-18-scale-phylo-clamp-active-diagnostic.md`

## Checks Run

- `/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-18-scale-phylo-clamp-active-diagnostic/run-pilot.R`

## Tests Of The Tests

The pre-artifact probe showed that using `library(drmTMB)` loaded an older
installed package and failed to expose the current `logsigma_clamp` control.
The committed runner uses `devtools::load_all(repo_root, quiet = TRUE)` from
its own path, so it exercises the current checkout. The final run reproduces
the intended hard case: default-clamp extreme residual shock reports
`logsigma_clamp_active = warning` at `log(sigma) = 13.93`, while disabled and
wide clamp settings on the same data keep false convergence and fixed-gradient
warnings visible without reporting clamp activation.

## Consistency Audit

The numerical-guard audit, finish worklist, capability matrix, dashboard
status, sweep text, check-log entry, artifact README, and this report all keep
the claim diagnostic-only. The wording does not promote scale-side
phylogenetic recovery accuracy, interval coverage, power, q4/q8 covariance
readiness, bivariate scale-route readiness, release readiness, CRAN readiness,
Julia bridge parity, missing-data behavior, or non-Gaussian REML/AI-REML.

## GitHub Issue Maintenance

No issue was closed. This remains evidence depth for the active
`drmTMB#59` numerical-guard sensitivity ledger.

## What Did Not Go Smoothly

The first fresh-seed artifact run showed the same false-convergence and
large-gradient pattern but did not cross the upper-clamp warning threshold. The
runner now uses the deterministic data seed from the successful probe so the
artifact records the intended clamp-active exposure.

## Team Learning

Hao's guardrail is still the right posture: a numerical guard should leave a
status trace when it matters, and other diagnostics must still prevent the fit
from being treated as inferentially clean.

## Known Limitations

This is a six-fit diagnostic artifact. It uses `se = FALSE`, so Hessian and
standard-error checks are intentionally notes rather than inference evidence.
It does not estimate bias, RMSE, MCSE, coverage, profile intervals, bootstrap
intervals, or operating-characteristic stability.

## Next Actions

Keep `drmTMB#59` active. The next safe guard slice is still broader evidence
depth: Student-t calibration, bivariate scale-route stress, larger
guard-sensitivity grids, or interval consequences for already fitted routes.
