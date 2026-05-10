# After Task: Next-Five 0.1.0 Release-Gate Batch

## Goal

Finish five small release-gate tasks after sleep consolidation: turn the local
release checklist into a public issue, archive the Gaussian comparator
evidence, update the project evidence trail, then validate the package and site
before pushing.

## Completed Tasks

| Task | Phase | Result |
| --- | --- | --- |
| Archive Gaussian comparator evidence | Phase 7/8 validation, feeding Phase 17 | `tools/replicate-location-scale-gaussian.R` passed and the numeric result is archived in `docs/dev-log/comparator-results/2026-05-10-gaussian-location-scale-glmmtmb.md`. |
| Verify generated documentation | Phase 17 | `devtools::document()` completed after the comparator run and produced no file changes. |
| Open the `0.1.0` release checklist issue | Phase 17 | Created https://github.com/itchyshin/drmTMB/issues/1 from the local checklist. |
| Update release evidence | Phase 17 | Added the issue link and comparator evidence snapshot to the local release checklist and check log. |
| Validate, commit, push, and watch CI | Phase 17 | Local validation passed; commit, push, and GitHub Actions are the remaining out-of-file closing steps. |

## Mathematical Contract

The public model scale remains `sigma`. When a reader needs residual variance,
predictability, or malleability, the reported quantity should be derived as
`sigma^2`. This keeps the user-facing grammar aligned with `brms`-style
location-scale syntax while still allowing variance-facing summaries for
individual-difference analyses.

## Files Created Or Changed

- `docs/dev-log/comparator-results/2026-05-10-gaussian-location-scale-glmmtmb.md`
- `docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md`
- `docs/dev-log/after-task/2026-05-10-next-five-release-readiness.md`
- `docs/dev-log/after-task/2026-05-10-next-five-release-gate.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript tools/replicate-location-scale-gaussian.R`: passed. Fixed-effect
  maximum absolute differences were `1.372665e-06` for `mu` coefficients,
  `1.999083e-06` for `sigma` coefficients, and `3.964260e-10` for
  log-likelihood. Random-intercept maximum absolute differences were
  `6.226181e-08` for `mu` coefficients, `6.677708e-06` for `sigma`
  coefficients, `6.810643e-07` for the `mu` random-intercept SD, and
  `2.117218e-09` for log-likelihood.
- `Rscript -e "devtools::document()"`: completed and produced no file changes.
- `gh issue create --title "Release checklist: drmTMB 0.1.0 preview" --body-file docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md`:
  opened issue #1.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- internal-shorthand scan over active user-facing docs, design docs, current
  release-gate notes, vignettes, `_pkgdown.yml`, and `pkgdown-site` excluding
  `search.json`: no matches for the removed slash-author or author-style
  labels.
- unsupported-syntax scan over README, roadmap, NEWS, vignettes, R, tests, the
  release checklist, and this after-task note: hits were guardrail prose,
  planned-feature prose, and one negative test, not user examples teaching
  unsupported syntax.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.
- Commit, push, and GitHub Actions are pending until this report is committed.

## Tests Of The Tests

The comparator harness checks fitted coefficients, residual-scale coefficients,
random-intercept standard deviation where present, and log-likelihood against
independent `glmmTMB` fits. This does not prove the future covariance model; it
does prove that the current Gaussian `mu` and `sigma` overlap is still
numerically aligned.

## Consistency Audit

The release checklist, comparator result, and after-task notes all keep
`sigma` as the public scale parameter and describe variance-facing summaries
as derived `sigma^2`. The public issue is a tracking artifact, not a release
sign-off.

## What Did Not Go Smoothly

The previous release-readiness after-task note still said the checklist had
not been opened as a GitHub issue. This batch corrected that stale statement
with a follow-up note instead of leaving future readers to rediscover it.

## Team Learning

Grace should treat public issue creation as release infrastructure, not a
nice-to-have. Rose should scan previous after-task reports for stale
"not yet" statements whenever a follow-up batch completes them. Fisher and
Gauss now have archived comparator numbers rather than only a console run.

## Design-Doc And Pkgdown Updates

No design grammar, likelihood, or pkgdown navigation change was made in this
batch. The work updates release evidence and process notes only.

## Known Limitations And Next Actions

This batch does not implement new likelihoods, denominator aliases, ordinal
scale, skew-normal, or full covariance across individual differences. The next
step before closing the batch is to commit, push, and watch GitHub Actions.
