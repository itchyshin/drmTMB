# After Task: Source-bound Bernoulli SD bridge rerun (v4)

## Goal

Recheck the Bernoulli two-engine vertical slice against the current source after the SD target resolver changed, then bind the result to an exact source manifest.

## Implemented

No model code changed. Five live Julia bridge tests completed, covering existing Bernoulli synthetic recovery and cross-engine point/output checks for the tested ordinary intercept, independent-slope, and correlated q2 routes.

## Mathematical Contract

Bernoulli random-effect SD predictors act on the link-scale latent effect. The model does not add a free Bernoulli residual SD. This rerun does not change that contract.

## Files Changed

- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.d/2026-10-20-julia-binomial-sd-source-bound-rerun-v4.md`
- `docs/dev-log/after-task/2026-10-20-julia-binomial-sd-source-bound-rerun-v4.md`
- `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261020-v4/sources-before.sha256`
- `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261020-v4/sources-after.sha256`
- `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261020-v4/test-console.log`

## Checks Run

`DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRMTMB_JULIA_TESTS=true NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-sd", reporter = "summary", stop_on_failure = TRUE)'` completed with five live Julia bridge tests, no test failures or skips, and 131.45 seconds elapsed. All 167 source/test hashes matched before and after. The exact command, source pins, manifest hashes, and raw-log hash are in the check-log shard.

## Tests Of The Tests

The captured test summary reports five live Julia tests; this was not a skip-only run. Existing synthetic cases check point recovery and paired output behavior against native TMB. No new test was added in this verification slice.

## Consistency Audit

The refreshed manifest includes the current `R/random-effect-targets.R`, which had changed since v3. The Bernoulli bridge, TMB source, Julia source, and focused bridge tests stayed byte-identical during this run. The gate update limits G2 to the tested vertical slice; G3 still owns the broader family, effect, provider, and endpoint universe. No package behavior, public API, formula documentation, NEWS, README, or pkgdown content changed.

## GitHub Issue Maintenance

The read-only search found open issues #59 (simulation framework), #61 (release readiness), and #1463 (the October test sweep). None was changed: this source-bound Bernoulli check does not complete those broader programmes, and interval coverage remains deferred.

## What Did Not Go Smoothly

The v3 manifest no longer described the current target resolver, so it could not seal the current snapshot. The v4 run captured a fresh 167-file manifest and raw log. The two Hessian warnings remained present and limit Wald interpretation for the affected fits. The shared `docs/dev-log/check-log.md` has 424 cross-reference changes in other branches, so this lane updated its scoped check-log shard and left the shared file untouched.

## Team Learning

When a fit-affecting resolver changes after a source-bound run, refresh the complete source manifest and rerun the live bridge before advancing a gate.

## Known Limitations

The result supports only the tested Bernoulli ordinary intercept, independent-slope, and correlated q2 slice. It does not establish structured Bernoulli providers, complete Bernoulli parity, calibrated interval coverage, or completion of G3 and later gates. Wald standard errors for the boundary-affected fits are not trustworthy.

## Next Actions

Continue with an unowned G3 capability row after checking both drmTMB and DRM.jl ownership. Keep coverage calibration deferred and retain the full approved capability universe.
