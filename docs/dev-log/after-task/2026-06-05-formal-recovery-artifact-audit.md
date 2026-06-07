# After Task: Formal Recovery Artifact Audit

## Goal

Run the seven formal recovery lanes requested before same-response
location-scale slope covariance work, then record which lanes support promotion
and which remain diagnostic.

## Implemented

The work did not change likelihood code. It dispatched, downloaded, and audited
seven GitHub Actions artifacts:

- `biv_gaussian_q2_scale_recovery`, run 27007018574.
- `biv_gaussian_q2_scale_slope_recovery`, run 27007018442.
- `biv_gaussian_mu_slope_recovery`, run 27007018453.
- `biv_gaussian_q4_location_recovery`, run 27007018436.
- `biv_gaussian_q6_location_recovery`, run 27007018475.
- `poisson_mu_re_recovery`, run 27007018434.
- `nbinom2_mu_re_recovery`, run 27007018459.

## Mathematical Contract

These artifacts measure operating characteristics for already fitted surfaces.
They do not add new syntax or a new likelihood. For the bivariate Gaussian
lanes, residual `rho12` remains the residual coscale parameter, while
group-level random-effect SDs and correlations are separate latent covariance
targets. Derived q > 2 correlations remain interval-unavailable unless a direct
interval route is added later.

## Files Changed

- `README.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-05-formal-recovery-artifact-audit.md`

## Checks Run

Downloaded each artifact with `gh run download` into
`/tmp/drmtmb-phase18-formal-runs/<run_id>` and audited the CSVs with base R.
The audited files were aggregate, manifest, failures, Wald coverage, and profile
coverage when the lane emitted profile intervals.

`rg -n "wired but not yet run|ready to run now|not yet run at formal scale|run at scale in Phase B|q4/q6.*ready|q4/q6.*promotion|formal artifacts are weak|not promotion evidence" README.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/157-capability-completion-worklist.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-05-formal-recovery-artifact-audit.md`
returned only the intended q4/q6 weak-evidence wording. `git diff --check`
passed. No package tests were rerun because this slice changed only
documentation and audited external Actions artifacts.

The workflow-level statuses were all `success`. The artifact-level evidence was
not uniformly supportive:

- q2 scale, q2 scale-slope, and slope-only `mu1`/`mu2` each completed 500/500
  replicates in both cells, with zero failure rows and aggregate convergence /
  `pdHess` / warning rates of 1 / 1 / 0.
- Poisson `mu` random effects completed 500/500 replicates in both cells, with
  convergence / `pdHess` / warning rates of 1 / 1 / 0. Fixed-effect Wald
  coverage ranged from 0.938 to 0.958. Profile coverage for random-effect SDs
  was weak, ranging from 0.669 to 0.831.
- NB2 `mu` random effects completed 500/500 replicates in both cells. Aggregate
  convergence was 0.998 and 1.000 with `pdHess` 1.000. Fixed-effect Wald
  coverage ranged from 0.930 to 0.982, but profile coverage for random-effect
  SDs was weak (0.647 to 0.822), and the first cell's fixed overdispersion
  estimates were poor.
- q4 location completed 500/500 manifest rows in both cells, but convergence was
  only 0.59 and 0.83, `pdHess` was 0.624 and 0.856, warning rates were 0.370
  and 0.144, and fixed-effect Wald coverage was well below nominal.
- q6 location had 6 and 4 replicate errors by cell, convergence of 0.075 and
  0.109, `pdHess` of 0.091 and 0.117, warning rates of 0.919 and 0.871, and
  Cholesky positive-definiteness errors. It is a fitted smoke/diagnostic route,
  not a recovery-ready route.

## Tests Of The Tests

The artifacts used `n_reps = 500`, `require_complete = true`, `cores = 10`,
and the manual Phase 18 Actions workflow on `main`. The audit checked manifest
counts instead of relying on workflow success, because q4 and q6 showed that a
green workflow can still contain weak or failed model evidence.

## Consistency Audit

README, doc 46, and doc 157 now distinguish three states:

1. q2 scale, q2 scale-slope, slope-only `mu1`/`mu2`, and Poisson `mu` have
   supportive formal recovery artifacts.
2. NB2 `mu` has usable formal artifacts with overdispersion and profile-SD
   cautions.
3. q4/q6 bivariate location artifacts are weak and should not enter power,
   coverage, or support-promotion grids until a numerical follow-up passes.

## GitHub Issue Maintenance

Issue #491 is the active local-R handoff/status issue. I posted the formal
recovery summary there:
<https://github.com/itchyshin/drmTMB/issues/491#issuecomment-4630620506>.
Issue #483 is already closed for the q2 scale-slope implementation, so this
audit did not reopen or close it.

## What Did Not Go Smoothly

The NB2 Actions job ran much longer than the other six lanes. A recovery
checkpoint was written for handoff while it was still running. The q6 workflow
returned success despite manifest error rows, so future artifact gates should
fail or flag support status from manifest and diagnostic summaries, not only
from workflow conclusion.

## Team Learning

Grace should treat `require_complete = true` as necessary but not sufficient.
Fisher and Rose need an explicit artifact-promotion gate that reads manifest,
convergence, `pdHess`, warning, and interval usability rows before any lane is
called recovery-ready.

## Known Limitations

The audit does not rerun package tests or refit models locally. It uses the
downloaded Actions artifacts as evidence. q4/q6 bivariate location blocks still
fit as named smoke/diagnostic routes, but their formal artifacts do not support
power-grid inclusion or broad recovery claims.

## Next Actions

Start item 3: implement same-response `mu`/`sigma` slope covariance only after
this evidence note is committed or otherwise kept with the branch.
