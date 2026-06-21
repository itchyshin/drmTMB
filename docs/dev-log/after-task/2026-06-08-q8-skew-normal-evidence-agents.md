# After Task: Q8 And Skew-Normal Evidence Agents

## Goal

Run the next evidence batch in two groups: q8 stress evidence, q8 diagnostic
interpretation, fixed-effect skew-normal formal-pilot evidence, fixed-effect
skew-normal false-positive evidence, stale-claim scanning, docs/status
synchronization, package-test closeout, and issue/after-task reporting.

## Implemented

The q8 diagnostic writer now has a live five-row stress-audit artifact set under
`docs/dev-log/simulation-artifacts/2026-06-08-q8-stress-audit/`. The fixed-effect
`skew_normal()` lane now has a three-cell formal-pilot artifact set under
`docs/dev-log/simulation-artifacts/2026-06-08-skew-normal-formal-pilot/` and a
one-cell symmetric false-positive artifact set under
`docs/dev-log/simulation-artifacts/2026-06-08-skew-normal-false-positive/`.

The status docs now say what those artifacts support: q8 remains
`hold_diagnostic`, and fixed-effect `skew_normal()` remains an implemented first
slice with pilot/diagnostic artifacts, not a formal-recovery-ready or
comparator-backed skew-normal programme.

## Mathematical Contract

The q8 audit stays inside the ordinary bivariate Gaussian all-endpoint route:
matching labelled `(1 + x | p | id)` blocks in `mu1`, `mu2`, `sigma1`, and
`sigma2`, with eight endpoint SDs and 28 latent group-level correlations.
Residual `rho12` remains a residual coscale parameter, not a group-level q8
correlation.

The skew-normal pilot stays inside the univariate fixed-effect
location-scale-shape route. Public `mu` is `E[y]`, public `sigma` is `SD[y]`,
and `nu` is residual slant. Random effects, structured effects, known sampling
covariance, bivariate skew-normal, residual `rho12`, skew-t, and latent
`skew(id)` are still outside the admitted surface.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/125-phase-18-next-two-team-slices-1619-1718.md`
- `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/158-phase-19-comparator-matrix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `inst/sim/README.md`
- `vignettes/robust-student.Rmd`

Artifact and note paths created by the agent batch:

- `docs/dev-log/simulation-artifacts/2026-06-08-q8-stress-audit/`
- `docs/dev-log/simulation-artifacts/2026-06-08-skew-normal-formal-pilot/`
- `docs/dev-log/simulation-artifacts/2026-06-08-skew-normal-false-positive/`
- `docs/dev-log/agent-notes/2026-06-08-stale-claim-scan.md`

## Checks Run

```sh
Rscript --vanilla -e 'devtools::test(filter = "phase18-skew-normal-fixed-effect|skew-normal-location-scale|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
```

Result: passed.

## Tests Of The Tests

The focused test run rechecked the q8 endpoint recovery and diagnostic contract,
the skew-normal fixed-effect artifact helpers, and the skew-normal
location-scale tests after the new artifact runs. The new evidence itself is
not a CRAN test; it is an opt-in local artifact batch.

## Consistency Audit

The stale-claim scan found old planned-only skew-normal wording in
`vignettes/robust-student.Rmd`, `docs/design/158-phase-19-comparator-matrix.md`,
`docs/design/41-phase-18-simulation-programme.md`,
`docs/design/125-phase-18-next-two-team-slices-1619-1718.md`, and
`docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md`. Those
active-surface claims were repaired. The scan did not find a direct active claim
that q8 coverage or power is ready; the ambiguous ROADMAP phrase "source or
artifact coverage" was changed to "source tests or artifact evidence".

## GitHub Issue Maintenance

The installed GitHub app connector could not write comments because GitHub
returned HTTP 403. The local `gh` token was able to write both updates:

- Skew-normal issue #3:
  https://github.com/itchyshin/drmTMB/issues/3#issuecomment-4653210543
- Q8/individual-difference covariance issue #5:
  https://github.com/itchyshin/drmTMB/issues/5#issuecomment-4653212564

No new issue was opened because existing issues covered both lanes.

## What Did Not Go Smoothly

The q8 logging attempt first failed because `sink(type = "message")` was pointed
at a path rather than an open connection. The successful run wrote its log after
that was corrected. The skew-normal formal-pilot runner initially tried
`system.file()` and installed-package loading, but untracked local simulation
helpers and the local `rskew_normal_public` helper required `pkgload::load_all()`
plus direct sourcing of `inst/sim/R/*.R`.

## Team Learning

The evidence routes are useful now, but they are telling us to slow promotion
down. Q8 needs convergence/Hessian and interval strategy work before any power
claim. Fixed-effect skew-normal needs Hessian, recovery, false-positive, and
comparator work before it is more than a first-slice diagnostic surface.

## Known Limitations

Q8 remains fitted and diagnostic-artifact ready only. The 2026-06-08 stress
audit completed all manifests but converged only 2/5 fits and had 0/5
positive-Hessian fits.

Fixed-effect `skew_normal()` remains implemented only for univariate
fixed-effect `mu`, `sigma`, and `nu`. The 2026-06-08 formal pilot converged 9/9
fits but had 0/9 positive-Hessian fits, and the symmetric false-positive cell
fit `|nu| = 0.981` under true `nu = 0`.

## Next Actions

1. For q8, design a staged-start or optimizer/Hessian audit before any larger
   stress or recovery run.
2. For skew-normal, rerun the formal pilot with a Hessian-focused diagnostic and
   an external comparator map before expanding replicate counts.
3. Keep q8 and skew-normal artifacts in the diagnostic/failure-ledger lane until
   promotion criteria are explicit and passed.
