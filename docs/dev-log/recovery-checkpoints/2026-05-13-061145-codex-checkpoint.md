# Codex Recovery Checkpoint

Generated: 2026-05-13 06:11:45 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: slice 4 labelled covariance block C++ visibility complete
Suggested next step: start slice 5 guarded three-member covariance block scaffold

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/labelled-covariance-block-design
```

### Changed Files

`git diff --name-status`

```text
(no output)
```

`git ls-files --others --exclude-standard`

```text
(no output)
```

### Diff Stat

`git diff --stat`

```text
(no output)
```

### Current Head

`git log -1 --oneline`

```text
c3eb657 Expose covariance block contract to TMB
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

## 2026-05-13 -- Slice 4 C++ visibility for dormant block contract

Scope:

- appended the labelled covariance block `tmb_data` contract to every
  `spec$tmb_data` list before `TMB::MakeADFun()`;
- declared the dormant `re_cov_*` fields in `src/drmTMB.cpp` and cast them to
  `void`, so the C++ template sees the contract without using it in the
  likelihood;
- added test helpers proving fitted registry `tmb_data` is present in
  `fit$model$tmb_data` and that scrambling the dormant fields leaves the
  objective and gradient unchanged for a representative labelled bivariate
  block;
- updated the direct phylogenetic TMB fixture with the empty block contract;
- changed no accepted syntax, optimized parameters, likelihood contribution,
  `corpairs()` rows, `check_drm()` diagnostics, or `profile_targets()` rows.

Checks:

- Dewey/Gauss-copy reviewed the C++ boundary risk before validation and
  recommended declaring the fields with `(void)` casts.
- Euler/Curie-copy reviewed the test surface and recommended the exported-data
  assertion plus one no-op objective/gradient assertion.
- `air format R/drmTMB.R tests/testthat/helper-covariance-blocks.R
  tests/testthat/test-biv-gaussian.R
  tests/testthat/test-gaussian-random-intercepts.R
  tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e 'devtools::load_all()'`: passed and recompiled `drmTMB`; the
  compiler emitted three existing Eigen/TMB header warnings, with no new
  `drmTMB.cpp` warnings.
- `Rscript -e 'devtools::test(filter =
  "biv-gaussian|gaussian-random-intercepts|phylo-utils")'`: passed with 857
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "corpairs|check-drm|profile-targets|biv-gaussian|gaussian-random-intercepts|phylo-utils")'`:
  passed with 1216 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "package-skeleton")'`: passed with 40
  expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 `profile_targets()` registry inventory

Scope:

- routed random-effect correlation rows in `profile_targets()` through
  `object$model$random$covariance_blocks` when covered two-member registry
  pairs are available;
- preserved target names, target classes, `dpar`, `term`, `tmb_parameter`,
  index, transformation, target type, readiness, and estimates for current
  covariance targets;
- kept fallback logic for old or partial objects by parsing any fitted
  `corpars` row not covered by the registry;
- changed no SD target rows, fixed-effect target rows, residual `rho12` target
  rows, likelihood code, or accepted syntax.

Checks:

- Meitner/Emmy-copy was asked to map the target inventory contracts before the
  closeout.
- `air format R/profile.R tests/testthat/test-profile-targets.R
  tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "profile-targets")'`: passed with 215
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "profile-targets|biv-gaussian|gaussian-random-intercepts|corpairs|check-drm")'`:
  passed with 1159 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 `check_drm()` registry diagnostics

Scope:

- routed the existing covariance diagnostics in `check_drm()` through
  `object$model$random$covariance_blocks` when covered two-member registry
  pairs are available;
- preserved current diagnostic row names, values, statuses, and messages for
  univariate `mu`/`sigma`, bivariate `mu1`/`mu2`, bivariate
  `sigma1`/`sigma2`, and same-response bivariate `mu`/`sigma` covariance
  blocks;
- kept fallback logic for older objects without a registry;
- changed no accepted syntax, likelihood code, TMB data passed to C++, or
  fitted parameter estimates.

Checks:

- Mill/Curie-copy mapped the existing `check_drm()` helper contracts and test
  expectations before editing.
- `air format R/check.R tests/testthat/test-check-drm.R
  tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "check-drm")'`: passed with 96
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "check-drm|biv-gaussian|gaussian-random-intercepts|corpairs|profile-targets")'`:
  passed with 1153 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-slice-4-cpp-block-contract-visibility.md` (2026-05-13 06:11): # After Task: Slice 4 C++ Block Contract Visibility
- `docs/dev-log/after-task/2026-05-13-slice-4-profile-target-registry-inventory.md` (2026-05-13 05:53): # After Task: Slice 4 `profile_targets()` Registry Inventory
- `docs/dev-log/after-task/2026-05-13-slice-4-check-drm-registry-diagnostics.md` (2026-05-13 05:47): # After Task: Slice 4 `check_drm()` Registry Diagnostics
- `docs/dev-log/after-task/2026-05-13-slice-4-corpairs-registry-extraction.md` (2026-05-13 05:37): # After Task: Slice 4 `corpairs()` Registry Extraction
- `docs/dev-log/after-task/2026-05-13-slice-4-dormant-tmb-block-contract.md` (2026-05-13 05:23): # After Task: Slice 4 Dormant TMB Block Contract
- `docs/dev-log/after-task/2026-05-13-slice-4-labelled-block-registry-compatibility.md` (2026-05-13 05:12): # After Task: Slice 4 Labelled Block Registry Compatibility
- `docs/dev-log/after-task/2026-05-13-slice-4-labelled-block-design-start.md` (2026-05-13 04:55): # After Task: Slice 4 Labelled Block Design Start
- `docs/dev-log/after-task/2026-05-13-bivariate-same-response-mu-sigma-covariance.md` (2026-05-13 04:41): # After Task: Bivariate Same-Response Mu/Sigma Covariance

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
