# q1 Sigma-Phylo REML Admission

## Task Goal

Fix the R-via-Julia Gaussian sigma-only phylo admission path so
`sigma ~ phylo(1 | species)` does not require a matching mean-side phylo term,
then bank sigma-only and balanced mu+sigma bridge-only REML evidence without
claiming native TMB REML parity or interval coverage.

## Files Created Or Changed

- `R/julia-bridge.R`: added the Gaussian sigma-only phylo payload branch with
  `locscale_mode = "sigma_only"`.
- `tests/testthat/test-julia-sigma-phylo-reml.R`: expanded the live REML
  subprocess to fit sigma-only and balanced mu+sigma routes separately.
- `docs/dev-log/dashboard/structured-re-q1-parity-fixture-contract.tsv`,
  `structured-re-executable-evidence.tsv`, `structured-re-balance-matrix.tsv`,
  and `structured-re-finish-100-slices.tsv`: recorded bridge-only REML evidence
  and kept broader parity/support wording blocked.
- `docs/dev-log/check-log.md`: recorded checks, outcomes, and the boundary.

## Checks Run And Outcomes

```sh
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot Rscript --vanilla -e 'devtools::test(filter = "julia-sigma-phylo-reml")'
```

Passed: 64/64 assertions, 0 failures, 0 warnings, 0 skips in 22.2 seconds.

```sh
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot Rscript --vanilla -e 'devtools::test(filter = "julia-tmb-parity|julia-sigma-phylo-reml")'
```

Passed: 80/80 assertions, 0 failures, 0 warnings, 0 skips in 75.5 seconds.

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
```

Passed. The validator reported 13 executable-evidence rows after the new
sigma-phylo REML row was added.

## Consistency Audit

The previous inconsistency was real: `drm_julia_reml_supported()` said
sigma-side REML was admissible, but `drm_julia_phylo_payload()` rejected the
sigma-only payload unless a mean-side phylo term was also present. The code,
tests, dashboard rows, and check-log now all separate sigma-only bridge REML
admission from balanced mu+sigma bridge REML admission.

## Tests Of The Tests

Before the fix, the expanded live test skipped because the callr subprocess
threw `engine = "julia" currently supports phylo(...) in the mu formula`.
After the payload branch was added, the same focused file passed without skips.
The test also checks `requested_REML` and `effective_REML`, so fallback-to-ML
would fail the gate.

## What Did Not Go Smoothly

The first sigma-only extractor used `fj$sdpars$mu[[...]]`, which throws on
`numeric(0)`. The test now uses a name-checked extractor and records missing
mean-side SD as `NA_real_` for the sigma-only route.

## Team Learning And Process Improvements

Boole/Rose lesson: support detectors and payload marshalling must be tested
together. A route can be mathematically and engine-side available while still
being unreachable through the R bridge if the payload branch assumes a sibling
axis.

## Design-Doc Updates

No formula grammar or likelihood design file changed. The change admits an
already-recognized Gaussian bridge route through the payload layer.

## pkgdown/Documentation Updates

No public docs or pkgdown pages changed in this slice. Public bridge wording
remains governed by the dashboard and known limitation rows.

## GitHub Issue Maintenance

No issue was posted or edited. Ayumi-facing communication remains parked until
the issue text is reviewed and the exact reply is approved.

## Known Limitations And Next Actions

This is bridge-only exact-Gaussian REML evidence. It does not provide native
TMB REML parity, same-target ML parity for the balanced mu+sigma route,
calibrated interval coverage, q2/q4 support, non-Gaussian REML, or broad public
bridge support. The next q1 work is same-target ML comparison for the balanced
mu+sigma route and boundary diagnostics for near-zero sigma-side SD fits.
