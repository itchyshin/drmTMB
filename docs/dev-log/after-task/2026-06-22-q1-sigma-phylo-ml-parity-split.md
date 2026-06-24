# After Task: q1 Sigma-Phylo ML Parity Split

## Goal

Bank the next q1 bridge parity evidence without hiding the difference between sigma-only phylo and matched `mu` plus `sigma` phylo routes.

## Implemented

`tests/testthat/test-julia-tmb-parity.R` now includes a repeated-species q1 Gaussian phylo fixture that fits native R/TMB, direct DRM.jl bridge output, and R-via-Julia for sigma-only and matched `mu` plus `sigma` formulas. The sigma-only route must pass log-likelihood, fixed-effect, and `sd_sigma` parity. The matched route is classified as either passed or `blocked_target_mismatch`; the current active DRM.jl worktree produces the blocked classification because direct DRM.jl and R-via-Julia agree with each other while native R/TMB does not meet the same-target log-likelihood gate.

## Mathematical Contract

The banked claim is ML parity for one q1 Gaussian sigma-only phylogenetic random effect on the scale endpoint:

`y ~ x`, `sigma ~ phylo(1 | species, tree = tree)`.

The gate compares the same repeated-species dataset under native R/TMB, direct DRM.jl, and R-via-Julia with `|delta logLik| < 1e-6`, max fixed-effect delta `< 1e-5`, and `|delta sd_sigma| < 1e-4`. The matched formula,

`y ~ x + phylo(1 | species, tree = tree)`, `sigma ~ phylo(1 | species, tree = tree)`,

is not promoted because the native R/TMB likelihood target did not match the direct/R-via-Julia target in the diagnostic fixture.

## Files Changed

- `tests/testthat/test-julia-tmb-parity.R`
- `docs/dev-log/dashboard/bridge-parity-smoke-status.tsv`
- `docs/dev-log/dashboard/structured-re-q1-parity-fixture-contract.tsv`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-balance-matrix.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/200-ayumi-julia-bridge-balance-readiness.md`
- `docs/design/216-structured-random-effect-finish-100-slices.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tests/testthat/test-julia-tmb-parity.R
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot Rscript --vanilla -e "devtools::test(filter = 'julia-tmb-parity')"
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot Rscript --vanilla -e "devtools::test(filter = 'julia-sigma-phylo-reml')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/status.json >/dev/null
curl -fsS http://127.0.0.1:8765/sweep.json >/dev/null
curl -fsS http://127.0.0.1:8765/bridge-parity-smoke-status.tsv | rg -n "q1_gaussian_sigma_phylo_ml|q1_gaussian_mu_sigma_phylo_ml"
curl -fsS http://127.0.0.1:8765/structured-re-q1-parity-fixture-contract.tsv | rg -n "q1_sigma_phylo|q1_mu_sigma"
curl -fsS http://127.0.0.1:8765/structured-re-executable-evidence.tsv | rg -n "q1_sigma_phylo_ml|q1_mu_sigma_phylo_ml"
```

## Tests Of The Tests

The new test uses a repeated-species fixture with nonzero scale-side phylogenetic variation. The first exploratory one-tip-per-species fixture gave near-zero SD estimates, so it was not used as the banked parity fixture. The matched `mu` plus `sigma` route is retained as a live diagnostic instead of being deleted or silently treated as support.

## Consistency Audit

The q1 parity fixture table, bridge parity smoke table, structured balance matrix, executable-evidence ledger, finish-slice ledger, dashboard JSON, and design docs now all say the same thing: sigma-only q1 phylo ML parity is banked for one fixture; matched q1 `mu` plus `sigma` parity is blocked pending target or parameterization reconciliation.

## GitHub Issue Maintenance

No GitHub issue was opened or commented on. This is local evidence for the current mission-control lane, and the user explicitly reserved Ayumi-facing work for later approval.

## What Did Not Go Smoothly

The first diagnostic looked excellent numerically, but the SDs collapsed near zero and would have been weak evidence. The stronger repeated-species fixture exposed the useful split: sigma-only parity passed, while matched `mu` plus `sigma` did not match native R/TMB on log-likelihood.

## Team Learning

Rose and Fisher should require a non-degenerate structured SD before treating a bridge parity test as meaningful. Emmy should keep direct DRM.jl and R-via-Julia agreement separate from native R/TMB target agreement, because the matched `mu` plus `sigma` route can satisfy the former without satisfying the latter.

## Known Limitations

This is one q1 sigma-only Gaussian phylo ML fixture. It is not interval coverage, not REML parity, not q2 or q4 bridge support, not non-Gaussian REML, and not public bridge promotion. The matched q1 `mu` plus `sigma` route remains blocked.

## Next Actions

Resolve the matched q1 `mu` plus `sigma` target or parameterization difference, then continue SR114-SR120 with relmat, animal, spatial, count, unsupported-route, coefficient-scale, and q1 acceptance-gate evidence.
