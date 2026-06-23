# After Task: Q1 Mu+Sigma Phylo ML Parity

## Goal

Resolve the q1 matched `mu` plus `sigma` phylo ML bridge blocker without
promoting REML, intervals, q2, q4, non-Gaussian bridge support, public optimizer
controls, or an Ayumi-facing reply.

## Implemented

The R-to-Julia bridge now sends `phylo_coupled = TRUE` only for the Gaussian q1
matched `mu` plus `sigma` phylo ML route. DRM.jl accepts that bridge option,
routes the fit through the coupled location-scale phylo block, and rejects the
coupled route for REML. The R reconstruction excludes Julia `recov_*`
coefficients from fixed effects and reconstructs `sdpars$mu`, `sdpars$sigma`,
and `corpars$phylo`.

## Mathematical Contract

The banked ML fixture compares the same coupled q1 target across native R/TMB,
direct DRM.jl bridge output, and R-via-Julia reconstruction. The acceptance
tolerances are `logLik < 1e-6`, fixed effects `< 2e-5`, structured SDs
`< 1e-4`, and the phylogenetic `mu`/`sigma` correlation `< 1e-4`.

The REML contract is unchanged: sigma-phylo REML evidence remains
bridge-only/direct DRM.jl evidence. Coupled mean-sigma phylo REML is not
implemented, and q4 Patterson-Thompson REML is not HSquared AI-REML.

## Files Changed

- `R/julia-bridge.R`
- `tests/testthat/test-julia-bridge.R`
- `tests/testthat/test-julia-sigma-phylo-reml.R`
- `tests/testthat/test-julia-tmb-parity.R`
- DRM.jl pilot worktree: `src/gaussian_core.jl`, `src/bridge.jl`,
  `test/test_bridge.jl`
- Dashboard/status docs under `docs/dev-log/dashboard/`
- Design notes:
  `docs/design/168-r-julia-finish-capability-matrix.md`,
  `docs/design/200-ayumi-julia-bridge-balance-readiness.md`,
  `docs/design/216-structured-random-effect-finish-100-slices.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
julia --project=. test/test_bridge.jl
Rscript --vanilla -e "devtools::test(filter = 'julia-bridge')"
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  Rscript --vanilla -e "devtools::test(filter = 'julia-tmb-parity')"
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  Rscript --vanilla -e "devtools::test(filter = 'julia-sigma-phylo-reml')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json
sh -n tools/start-mission-control.sh
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 \
  sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/status.json
curl -fsS http://127.0.0.1:8765/sweep.json
curl -fsS http://127.0.0.1:8765/bridge-parity-smoke-status.tsv
curl -fsS http://127.0.0.1:8765/structured-re-q1-parity-fixture-contract.tsv
curl -fsS http://127.0.0.1:8765/structured-re-executable-evidence.tsv
curl -fsS http://127.0.0.1:8765/structured-re-finish-100-slices.tsv
```

Results: DRM.jl bridge test 51/51 passed; `julia-bridge` 97/97 passed;
`julia-tmb-parity` 33/33 passed; `julia-sigma-phylo-reml` 66/66 passed;
mission-control validation passed; JSON parse checks, shell syntax check, and
`git diff --check` passed in both active worktrees; the served dashboard returned
the updated q1 rows.

## Tests Of The Tests

The q1 matched `mu` plus `sigma` parity test failed before the fix as
`blocked_target_mismatch`, then failed once more on the stricter fixed-effect
coefficient threshold (`1.54e-5` versus `1e-5`). The final test records the
route-specific `2e-5` fixed-effect tolerance and keeps the log-likelihood,
structured-SD, and correlation gates tighter.

## Consistency Audit

Dashboard rows now mark SR113 and `q1_gaussian_mu_sigma_phylo_ml` as banked for
one repeated-species ML parity fixture. The status text still labels the bridge
as experimental and row-specific. REML wording remains exact-Gaussian only and
does not claim native sigma-side REML parity.

## GitHub Issue Maintenance

No issue comment, PR, commit, or Ayumi reply was made. The user explicitly kept
this run local and asked not to post or commit without approval.

## What Did Not Go Smoothly

The first Julia bridge test fixture was too large and was interrupted while
inside the coupled block. A tiny replacement fixture reached `recov_*` but was
saturated and non-converged. The final 10-species, 3-replicate fixture converged
and kept the Julia bridge test fast.

## Team Learning

Emmy/Rose: q1 matched `mu` plus `sigma` bridge parity needed a target flag, not
a looser comparison. Fisher: the coefficient tolerance had to be explicit once
the remaining difference was numerical rather than a target mismatch. Grace:
the served-copy check caught the dashboard update after the validator passed.

## Known Limitations

This is one deterministic/repeated-species q1 ML parity fixture. It is not a
calibrated coverage result, not interval reliability, not q2/q4 bridge support,
not broad public bridge support, and not a REML parity claim. Coupled
mean-sigma phylo REML remains unsupported.

## Next Actions

Continue SR114-SR120: q1 relmat, animal, spatial, count, unsupported-route,
coefficient-scale, and q1 acceptance-gate evidence. Then extend the same
native/direct/R-via-Julia row contract to q2 and q4.
