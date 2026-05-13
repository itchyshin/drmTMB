# Codex Recovery Checkpoint

Generated: 2026-05-12 17:15:28 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: Recover crashed bivariate sigma1/sigma2 random-effect covariance lane
Suggested next step: Add focused tests and docs/check-log entries for the bivariate sigma1/sigma2 labelled random-intercept covariance block, then run targeted testthat checks.

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/biv-sigma-scale-covariance
 M R/drmTMB.R
 M R/methods.R
 M src/drmTMB.cpp
```

### Changed Files

`git diff --name-status`

```text
M	R/drmTMB.R
M	R/methods.R
M	src/drmTMB.cpp
```

`git ls-files --others --exclude-standard`

```text
(no output)
```

### Diff Stat

`git diff --stat`

```text
 R/drmTMB.R     | 254 +++++++++++++++++++++++++++++++++++++++++++++++++--------
 R/methods.R    |  31 +++++--
 src/drmTMB.cpp |  52 +++++++++++-
 3 files changed, 297 insertions(+), 40 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
f68bd2a Harden mu/sigma covariance profile support
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

## 2026-05-12 -- Mu/sigma sigma prediction contribution test

Scope:

- added a deterministic fitted-data prediction regression test for univariate
  Gaussian `mu`/`sigma` covariance models with both a matched labelled
  `mu`/`sigma` random-intercept block and an independent unlabelled `sigma`
  random-intercept block;
- checked that `sigma_random_effect_contribution()` equals the manual row-wise
  contribution from fitted `sigma` random effects and random-effect design
  values;
- checked that `predict(fit, dpar = "sigma", type = "link")` equals the fixed
  sigma linear predictor plus that random-effect contribution, and that
  `stats::sigma(fit)` is its response-scale exponentiation.

Checks:

- `air format tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 216 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 631 expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'sigma_random_effect_contribution|predict\([^\n]*dpar = "sigma"|mu/sigma covariance|mu/sigma' R tests README.md ROADMAP.md NEWS.md docs vignettes`:
  reviewed prediction and covariance wording touched by the claim; no
  source-doc changes needed for this test-only guard.
- `rg -n 'rho12|sigma1|sigma2|sd\(' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-gaussian-random-intercepts.R`:
  reviewed correlation terminology around `rho12` and group-level covariance;
  no stale wording introduced.

## 2026-05-12 -- Mu/sigma joint objective comparator

Scope:

- added a hand-coded R joint negative log-likelihood comparator for the
  univariate Gaussian `mu`/`sigma` covariance path;
- compared TMB's full fixed-plus-random objective at `last.par.best` with the
  independent R calculation for a model containing both a matched labelled
  `mu`/`sigma` block and an independent unlabelled `sigma` block;
- kept this as test-only hardening without changing likelihood or parser code.

Checks:

- First attempt with a tiny 5-group fixture did not converge reliably and used
  the wrong full-vector parameter extraction path; revised to a 12-group
  deterministic fixture and split `last.par.best` by TMB parameter names.
- `air format tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 212 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 627 expectations, 0 failures, 0 warnings, and 0 skips.

## 2026-05-12 -- Mu/sigma sigma-effect transform regression test

Scope:

- added a deterministic regression test for the internal
  `transform_sigma_random_effects()` path used by fitted univariate
  `mu`/`sigma` covariance blocks;
- checked that only matched labelled `sigma` random-effect rows use
  `rho * u_mu + sqrt(1 - rho^2) * u_sigma`;
- checked that an independent unlabelled `sigma` random-intercept block remains
  independent in the same model specification.

Checks:

- `air format tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 210 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 625 expectations, 0 failures, 0 warnings, and 0 skips.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-12-univariate-mu-sigma-covariance-bridge.md` (2026-05-12 16:41): # After Task: Univariate Mu/Sigma Covariance Bridge
- `docs/dev-log/after-task/2026-05-12-profile-covariance-status-docs.md` (2026-05-12 16:41): # After Task: Profile Covariance Status Docs
- `docs/dev-log/after-task/2026-05-12-mu-sigma-transform-regression-test.md` (2026-05-12 16:41): # After Task: Mu/Sigma Transform Regression Test
- `docs/dev-log/after-task/2026-05-12-mu-sigma-summary-covariance-rows.md` (2026-05-12 16:41): # After Task: Mu/Sigma Summary Covariance Rows
- `docs/dev-log/after-task/2026-05-12-mu-sigma-profile-target-rows.md` (2026-05-12 16:41): # After Task: Mu/Sigma Profile-Target Rows
- `docs/dev-log/after-task/2026-05-12-mu-sigma-profile-interval.md` (2026-05-12 16:41): # After Task: Mu/Sigma Profile Interval
- `docs/dev-log/after-task/2026-05-12-mu-sigma-prediction-contribution-test.md` (2026-05-12 16:41): # After Task: Mu/Sigma Prediction Contribution Test
- `docs/dev-log/after-task/2026-05-12-mu-sigma-joint-objective-comparator.md` (2026-05-12 16:41): # After Task: Mu/Sigma Joint Objective Comparator

## Recovery Commands

Run these at the start of the next task before assuming this checkpoint is
still current:

```sh
git status --short --branch
git diff --stat
git diff
sed -n '1,240p' docs/dev-log/check-log.md
ls -lt docs/dev-log/after-task | head
```

## Notes For The Next Agent

- Do not treat this checkpoint as approval for broad changes.
- Preserve unrelated user, Codex, or Claude Code edits.
- If the diff is large, identify the smallest safe next step before editing.
- If validation is stale or incomplete, report that explicitly.
