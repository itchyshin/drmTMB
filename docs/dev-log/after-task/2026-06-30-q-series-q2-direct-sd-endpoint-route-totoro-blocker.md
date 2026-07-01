# Q-Series q2 Direct-SD Endpoint Route Totoro Blocker

Date: 2026-06-30

## Scope

This task tested one named interval-repair candidate for one target only:
`qseries_phylo_q2_mu1_mu2_intercept`, estimand `sd_mu2_intercept`, under
`endpoint_zero_boundary_profile_channel`.

It also updated the Q-Series status surfaces so the exact phylo q2 intercept row
points at the new target-level blocker while the other q2 retained-denominator
rows remain on the broader repair-smoke review.

## Evidence

- Local schema smoke:
  `docs/dev-log/simulation-artifacts/2026-06-30-q2-direct-sd-endpoint-route-phylo-local/`
  with `n=2`, fit/converged/pdHess/profile finite `2/2`.
- Totoro target smoke:
  `docs/dev-log/simulation-artifacts/2026-06-30-q2-direct-sd-endpoint-route-phylo-totoro/`
  with 32 one-replicate shards.
- Dashboard row:
  `docs/dev-log/dashboard/structured-re-q2-direct-sd-endpoint-route-smoke.tsv`.

Totoro result:

- fit/converged/pdHess/Wald finite/profile finite: `32/32`.
- Wald coverage: `0.9375`, MCSE `0.042791`, lower/upper misses `0/2`.
- Profile coverage: `0.8750`, MCSE `0.058463`, lower/upper misses `0/4`.

## Decision

This route is blocked for top-up. The engine stability signal is clean, but the
interval shape remains unacceptable even in a small target-scoped smoke.

This promotes exactly no Q-Series row under `endpoint_zero_boundary_profile_channel`
with all attempted rows retained and does not claim `interval_status`,
`coverage_status`, `inference_ready`, `supported`, direct-correlation repair,
q2 slope inheritance, q2-plus inheritance, q4/q8, non-Gaussian intervals, REML,
AI-REML, bridge support, or public support.

## Validation

- `python3 tools/validate-mission-control.py`: passed with
  `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test(filter = "profile-targets")'`: 816 PASS / 0 FAIL.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test(filter = "structured-re-conversion-contracts")'`: 10201 PASS
  / 0 FAIL.
- `git diff --check`: passed.

## Next Gate

Do not top up this route. Design a new q2 direct-SD interval repair route for
phylo `sd_mu2_intercept`, or write a blocker decision. Direct correlations and
q2-plus remain separate routes. Fisher/Rose/Grace review is required before any
support-cell status edit.
