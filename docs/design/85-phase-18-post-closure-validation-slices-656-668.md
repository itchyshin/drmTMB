# Phase 18 Post-Closure Validation Slices 656-668

Reader: `drmTMB` contributors checking the closeout of the broader Slices
639-668 post-closure validation block.

Slices 656-668 finish the validation lane that began in
`docs/design/84-phase-18-post-closure-validation-slices-639-655.md`. The
previous block already reran the full Phase 18 focused suite, full package
tests, `pkgdown::check_pkgdown()`, and `devtools::check(error_on = "never")`.
This note records the remaining closeout pass and a fresh focused rerun over
the closure-aware runner surfaces.

## Validation Scope

The pass checked that the closure-aware shared runner, Student-t shape runner,
bivariate residual `rho12` runner, interval-heavy runner, and Actions dispatch
plumbing still pass together after the Slice 655 handoff.

No likelihood, formula grammar, public API, roxygen topic, pkgdown navigation,
or rendered pkgdown site output changed in this block.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 656-659 | Rehydrate the partial 639-668 validation boundary | `docs/design/84-phase-18-post-closure-validation-slices-639-655.md` and the Phase 18 ledger were read before edits |
| 660-663 | Rerun closure-aware runner and interval-heavy focused checks | `phase18-sim-runner`, Student-t shape, bivariate `rho12`, interval-heavy, and Actions tests passed |
| 664-666 | Record validation-only status and unsupported boundaries | This note, the after-task report, and the check-log entry keep unsupported NB2/q4 and non-Gaussian sub-model random-effect lanes out |
| 667-668 | Close the broader post-closure validation block | Recovery checkpoint and final diff-hygiene checks belong to the overnight handoff |

## Commands

```sh
date '+%Y-%m-%d %H:%M:%S %Z %z'
git status --short --branch
nl -ba docs/design/41-phase-18-simulation-programme.md | sed -n '599,622p'
Rscript -e "devtools::test(filter = 'phase18-(sim-runner|student-shape-runner|biv-rho12-runner|student-shape-summary-smoke|biv-rho12-summary-smoke|interval-heavy-summary-smoke-runner|actions-runner)', reporter = 'summary')"
```

## Result

The focused closure bundle completed with exit code 0. The immediately
preceding Slice 639-655 block already recorded:

```text
devtools::test(filter = '^phase18-'): passed
devtools::test(): passed
pkgdown::check_pkgdown(): no problems
devtools::check(error_on = "never"): 0 errors, 0 warnings, 0 notes
```

This closes the requested Slices 639-668 post-closure validation lane as a
validation and documentation closeout. It does not promote public bootstrap
intervals, PSOCK support, NB2 `sigma` phylogeny, zero-inflated NB2 phylogeny,
q4 count covariance, broad NB2 structured parity, random effects in
shape/inflation/hurdle/one-inflation parameters, or mixed-response
non-Gaussian bivariate models.
