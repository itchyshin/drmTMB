# After Task: Binomial Fixed-Effect Interval Calibration

## Goal

Bank the first MCSE-backed interval-calibration artifact for the fixed-effect
plain-binomial first slice after #569/#585 and the #591 `stats::glm()` parity
artifact. The target is bounded: Wald intervals for formula coefficients in
native TMB `stats::binomial(link = "logit")` models with 0/1 and
`cbind(successes, failures)` responses.

## Implemented

Generated and committed:

```text
docs/dev-log/simulation-artifacts/2026-06-17-binomial-fe-interval-calibration/
```

The artifact uses the existing Phase 18 `binomial_fixed_effect` writer with
six cells, 500 replicates per cell, master seed `20260617`, and the multicore
runner. It commits CSV summaries only; the temporary per-replicate RDS cache was
removed before commit.

## Mathematical Contract

The simulated model is:

```text
Y_i ~ Binomial(n_i, mu_i)
logit(mu_i) = beta_0 + beta_1 x_i
```

The binary cells use `n_i = 1`. The `cbind` cells sample row-level trial totals
from the documented trial bands and store successes and failures explicitly.
The inferential targets are the fixed `mu` coefficients `mu:(Intercept)` and
`mu:x` on the logit scale. The intervals are formula-coefficient Wald intervals
from the fitted `drmTMB` object.

## Results

The run attempted 3,000 fits and produced 6,000 coefficient rows. All 3,000
manifest rows returned `ok`, the failure table is header-only, the minimum
convergence rate was 1.000, the minimum `pdHess` rate was 1.000, and the
maximum warning rate was 0.000.

Wald coverage across the 12 cell-by-parameter rows ranged from 0.946 to 0.964.
Each row used 500 intervals, and the maximum coverage MCSE was 0.01010782.
The maximum absolute bias was 0.009026694, the maximum RMSE was 0.1413425, the
maximum bias MCSE was 0.006326178, and the maximum RMSE MCSE was 0.004502070.

The `stats::glm()` parity table stayed tight in the same run: maximum absolute
coefficient difference `1.502857e-08`, maximum absolute standard-error
difference `1.545213e-05`, maximum absolute `logLik` difference
`1.750777e-11`, and maximum absolute AIC/BIC difference `3.501555e-11`.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-17-binomial-fe-interval-calibration/`
- `docs/design/175-phase-18-binomial-fixed-effect-artifacts.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/159-drmtmb-0-2-0-release-readiness.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `tools/start-mission-control.sh`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-17-binomial-interval-calibration.md`

## Checks Run

```sh
Rscript --vanilla - <<'RSCRIPT'
devtools::load_all('.', quiet = TRUE)
# source Phase 18 helpers, then call phase18_write_binomial_fe_grid_outputs()
# with n_rep = 500L, master_seed = 20260617L, cores = 10L,
# backend = "multicore"
RSCRIPT
python3 -m json.tool docs/dev-log/dashboard/status.json >/tmp/status-json-binomial-interval.out
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/tmp/sweep-json-binomial-interval.out
python3 tools/validate-mission-control.py
sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/docs/dev-log/simulation-artifacts/2026-06-17-binomial-fe-interval-calibration/README.md
browser DOM check at http://127.0.0.1:8765/ for desktop and 390x844 mobile
git diff --check
rg -n '^(<<<<<<<|=======|>>>>>>>)' docs/design/175-phase-18-binomial-fixed-effect-artifacts.md docs/design/168-r-julia-finish-capability-matrix.md docs/design/157-capability-completion-worklist.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/159-drmtmb-0-2-0-release-readiness.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-17-binomial-interval-calibration.md docs/dev-log/simulation-artifacts/2026-06-17-binomial-fe-interval-calibration tools/start-mission-control.sh
rg -n 'non-identified|nonidentified|impossible|flat/unbounded|Bayesian only reads back the prior|REML on scale|REML.*scale' docs/design/175-phase-18-binomial-fixed-effect-artifacts.md docs/design/168-r-julia-finish-capability-matrix.md docs/design/157-capability-completion-worklist.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/159-drmtmb-0-2-0-release-readiness.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/simulation-artifacts/2026-06-17-binomial-fe-interval-calibration/README.md tools/start-mission-control.sh
```

## Tests Of The Tests

The artifact uses the same runner that already writes aggregate, manifest,
failure, Wald, Wald-coverage, and `stats::glm()` parity tables. This slice
tests the evidence path by making the promotion-candidate replicate count large
enough to report coverage MCSE near 0.01, then committing the failure ledger and
manifest beside the coverage summaries. A future regression in convergence,
`pdHess`, warning handling, interval construction, or GLM parity would be
visible in those committed tables.

The served-dashboard check verified the Evidence Gates section, the
500-replicate interval text, coverage range `0.946-0.964`, the numerical-guard
sensitivity row, the dirty-state repo truth, and the new artifact link on the
desktop page. At 390 by 844 mobile width, the same interval text, coverage
range, guard row, and artifact link were present with no horizontal overflow.

## Consistency Audit

This promotes the binomial evidence row from "interval calibration planned" to
"MCSE-backed fixed-effect Wald interval evidence banked" for the six audited
cells. It does not widen the public model surface. Random effects, structured
effects, bivariate or mixed-response binomial models, non-logit links,
proportion-plus-weights syntax, weights-as-trials, the Julia bridge, speed
claims, profile/bootstrap intervals, and release readiness remain unsupported
or planned.

## GitHub Issue Maintenance

Post the PR to #59 and #569 after opening. #342 should also receive a breadcrumb
because this improves the release-readiness evidence ledger while keeping the
release gate partial.

## Team Learning

Fisher and Curie: a 500-replicate fixed-effect binomial grid is cheap enough to
bank locally and gives interpretable coverage MCSE. Rose: the dashboard should
move from planned to banked only for the exact audited interval target, not for
nearby binomial surfaces. Grace: commit CSV evidence, not the bulky RDS cache.

## Known Limitations

This is fixed-effect Wald evidence only. It is not a profile or bootstrap
interval study, not a random-effect or structured-effect study, and not a
Julia-bridge or speed benchmark. Headline coverage language would need broader
conditions or a larger promotion grid.
