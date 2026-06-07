# After Task: Same-Response q2 Resume Scope Audit

## Goal

Resume from the 2026-06-06 package-validation checkpoint and decide whether the
same-response q2 branch was ready for PR review or needed one more consistency
patch.

## Implemented

The audit found and closed an accidental q8 all-endpoint support path. The
branch now stays scoped to the intended fitted same-response q2 `mu`/`sigma`
slope covariance route. Matching all-four `(1 + x | p | id)` terms across
`mu1`, `mu2`, `sigma1`, and `sigma2` are again rejected as planned q8 endpoint
syntax.

## Mathematical Contract

The fitted route remains one same-response slope-only pair, for example:

```r
mu1 = y1 ~ x + (0 + x | p | id)
sigma1 = ~ x + (0 + x | p | id)
mu2 = y2 ~ x
sigma2 = ~ x
rho12 = ~ 1
```

The all-four q8 endpoint,

```r
mu1 = y1 ~ x + (1 + x | p | id)
mu2 = y2 ~ x + (1 + x | p | id)
sigma1 = ~ x + (1 + x | p | id)
sigma2 = ~ x + (1 + x | p | id)
```

remains design-only until it has its own accepted parameterization, diagnostics,
simulation evidence, documentation, and tutorial warnings.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-biv-gaussian.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-06-same-response-q2-resume-scope-audit.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: 1,398 passes, no
  failures, warnings, or skips.
- `Rscript -e "devtools::test(filter = 'phase18-structured-workflow-registry|phase18-correlation-block-status')"`:
  331 passes, no failures, warnings, or skips.
- `rg -n "supports q8|new_biv_gaussian_q8|q=8 endpoint|q8 endpoint form|q8.*(now|is|are).*fitted|first matching q8|location-scale covariance blocks support either" R tests/testthat docs README.md ROADMAP.md NEWS.md --glob '!docs/dev-log/**'`
  found no fitted-q8 support code or success tests.
- `git diff --check` passed.
- `gh issue view 491 --json number,title,state,url,updatedAt` confirmed issue
  #491 is open.
- `Rscript tools/codex-checkpoint.R --goal "same-response q2 resume scope audit" --next "Review the corrected branch diff, commit the same-response q2 package changes, and open PR review if no further scope issues are found."`
  wrote
  `docs/dev-log/recovery-checkpoints/2026-06-06-164805-codex-checkpoint.md`.

## Tests Of The Tests

The q8 success test was removed because it contradicted the design-only q8
registry row and status documentation. The existing unsupported Phase 3 syntax
test now checks that all-four q8-style slope requests still fail with the
intercept-only all-four block boundary.

## Consistency Audit

README, ROADMAP, NEWS, design docs, and the Phase 18 registry already described
q8 as planned or design-only. The patch brings code and tests back into line
with those surfaces.

## GitHub Issue Maintenance

Issue #491 remains open and is still the active same-response q2 work-queue
issue. No new issue comment was posted for this local resume audit; the change
should be described in the PR before review.

## What Did Not Go Smoothly

The previous branch diff mixed the intended same-response q2 route with a q8
success fixture. That made the broad validation result look cleaner than the
scope actually was.

## Team Learning

Before closing a covariance slice, search for both stale unsupported wording and
accidental fitted-success tests for adjacent endpoints. A successful unit test
for a future endpoint is a scope leak, not validation evidence.

## Known Limitations

Full `devtools::test()`, `devtools::check()`, `pkgdown::check_pkgdown()`, and
`pkgdown::build_site()` were not rerun after this small scope patch. They passed
earlier in the same branch package-validation cleanup before the q8 path was
closed.

## Next Actions

Review the remaining branch diff for PR readability, then either open PR review
for the same-response q2 lane or make only issue/PR-description cleanup.
