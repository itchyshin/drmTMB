# After-task: R-Julia bridge Route C interval parity -> base_gaussian covered

**Date:** 2026-06-20
**Author:** Ada (autonomous, pushes held)
**Branch:** `shannon/overnight-audit-gaps-20260619` (drmTMB); DRM.jl engine =
`DRM.jl-direct-main` `f46035d`

## Task goal

Satisfy the exact promote-path the prior bridge-parity verdict recorded for the
Route C `base_gaussian_location_scale` cell ("add a bridge interval parity test:
native vs `engine="julia"` CI endpoints to a stated tolerance, Gaussian
location-scale"), verify it adversarially, and promote that single capability
cell `partial -> covered` if and only if earned.

## Files created or changed

- `tests/testthat/test-julia-tmb-parity.R` — added the "Route C interval parity"
  helper + test (Wald CI-endpoint parity, callr-isolated).
- `docs/dev-log/dashboard/julia-capabilities.tsv` — `base_gaussian_location_scale`
  `claim_status partial -> covered`; `next_action` + `claim_boundary` scoped text;
  `evidence_url` unchanged (GitHub issue URL, validator-required).
- `docs/dev-log/2026-06-20-bridge-parity-verification.md` — appended the
  promote-path "Update" section.
- `docs/dev-log/dashboard/status.json` — activity entry + `updated` timestamp.
- `docs/dev-log/check-log.md` — new top entry.
- This after-task report.

No package R/C++ code changed. The only code change is an additive, skip-guarded
test.

## Checks run and exact outcomes

- Measurement (callr-isolated, DRM.jl `f46035d`): Wald CI endpoints, all four
  Gaussian location-scale fixed-effect coefficients, both engines converged;
  per-coef endpoint deltas 5.6e-6 / 1.4e-6 / 1.3e-7 / 3.9e-6; **max |Δ| = 5.57e-6**.
  Profile path: native requires explicit `parm`; Julia bridge profile/bootstrap
  supports only phylogenetic SD targets — fixed-effect profile parity unavailable.
- `devtools::test(filter = "julia-tmb-parity")` with the bridge env: **12 PASS /
  0 FAIL / 1 SKIP** (skip = Route A tracked garbage-logLik bug).
- `python3 tools/validate-mission-control.py`: `mission_control_ok` (row counts
  and slice metrics unchanged by a TSV cell-status change).
- `git diff --check`: clean.

## Consistency audit

- The promotion moves exactly one surface: the `base_gaussian_location_scale` row
  in `julia-capabilities.tsv`. The aggregate `R-Julia bridge gate` matrix row
  (status.json + design 168 line 34) was deliberately left `partial` — it spans
  the Route A bug, q4/q8, structured, and cross-family routes.
- `evidence_url` kept as a GitHub issue URL to satisfy the validator's
  capability-row contract; the test reference lives in `next_action`.
- Terminology stable (`engine`, Wald, parity); no forbidden grammar terms.

## Tests of the tests

- The asserted bound is `<= 1e-4` while the measured value is ~5.6e-6 (~18x
  margin) — robust against minor cross-machine optimizer/BLAS variation while
  still a strong claim (interval widths are ~0.27). The cell prose cites the
  **asserted** bound as the guarantee (a Fisher+Rose required caveat), not the
  measured value.
- The test asserts the comparison is real: all four coefficients present and
  `conf.status == "wald"` in both engines, all endpoints finite, before the delta
  bound — so a silently-empty or NA confint cannot pass it.
- Rose and Fisher each independently traced the two covariance sources in source
  (native `sdr$cov.fixed` via `drm_sdreport_cov_fixed`; Julia `object$vcov` via
  `drm_julia_wald_confint`), confirming endpoint agreement tests covariance
  transport rather than re-testing the point estimate.

## What did not go smoothly

- The Julia bridge profile/bootstrap path does not cover fixed-effect targets
  (only phylo SD), so profile parity could not be measured. Handled by claiming
  Wald-only parity and recording the limitation, consistent with the pre-existing
  boundary.
- The cwd-reset hazard persisted; mitigated by pinning 540b paths and passing the
  bridge env vars on every invocation.

## Team learning and process improvements

- Bridge interval parity is best argued as **covariance transport**: when point
  estimates already agree, Wald-endpoint agreement isolates the SE/covariance
  term, which is independently computed on each engine. This is a reusable pattern
  for future bridge-cell promotions (Route B `rho12 ~ x` will need the analogous
  coefficient-parity test plus a dedicated capability row).

## Design-doc updates

- None to the formal design set; `168` matrix unchanged (the aggregate bridge row
  did not move). The capability registry (`julia-capabilities.tsv`) is the
  per-cell source of truth and was updated.

## pkgdown/documentation updates

- None required (internal capability-status promotion; no exported surface
  changed). The new test is skip-guarded and does not affect CRAN/CI on
  Julia-less machines.

## GitHub issue maintenance

- Deliberately unchanged (pushes held). The capability row already references
  `drmTMB#544` (the bridge gate/capability issue); the new evidence is recorded in
  the bridge-parity doc, check-log, and this report.

## Known limitations and next actions

- Covered is **Wald CI parity only** for the base Gaussian location-scale cell;
  profile/bootstrap fixed-effect bridge intervals stay gated; this is parity
  (engine agreement), not interval coverage.
- Next bridge step (from the promote-path): Route B `rho12 ~ x` coefficient-parity
  test + a new non-phylo bivariate-`rho12` bridge capability row (none exists).
- Route A (Gaussian phylo-mean) remains a tracked DRM.jl bug, blocking its parity.
