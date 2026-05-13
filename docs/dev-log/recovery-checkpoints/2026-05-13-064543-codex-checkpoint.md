# Codex Recovery Checkpoint

Generated: 2026-05-13 06:45:43 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: slice 6 q3 TMB algebra probe and recent review-name cleanup complete
Suggested next step: start slice 6B: inspect the non-centered random-effect path and prototype a hidden q=3 sqrt_cov_scale() branch without user-facing syntax

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
ce5b274 Normalize recent covariance review names
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

## 2026-05-13 -- Slice 6 q=3 TMB algebra probe

Scope:

- added internal-only TMB data fields `re_cov_probe_theta`,
  `re_cov_probe_sd`, and `re_cov_probe_x` to the dormant covariance-block data
  contract;
- added a hidden `model_type == 98` branch that constructs
  `density::UNSTRUCTURED_CORR_t`, reports its correlation matrix, and evaluates
  either the unscaled density or a `density::VECSCALE()` density for a supplied
  q=3 probe vector;
- added a deterministic test asserting that the reported q=3 correlation
  matrix is symmetric, has unit diagonal, matches TMB's documented lower-triangle
  normalization, has positive eigenvalues, and yields finite objective and
  gradient;
- changed no user-facing syntax, no fitted-model likelihood branch, no real
  random-effect parameters, and no public q > 2 covariance support.

Checks:

- Jason inspected local TMB 1.9.21 headers and confirmed that
  `UNSTRUCTURED_CORR_t` plus `VECSCALE_t` is the right local primitive.
- Gauss reviewed the numerical plan and recommended the next slice use
  `sqrt_cov_scale()` for a non-centered prototype.
- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R`:
  passed.
- `Rscript -e 'devtools::load_all()'`: passed and recompiled `drmTMB`; the
  compiler emitted three existing Eigen/TMB header warnings, with no new
  `drmTMB.cpp` warnings.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 30 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils")'`:
  passed with 888 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.
- Post-crash recovery rerun on the same checkout: `git diff --check`,
  `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`, and the
  four-context targeted test above all passed again.

## 2026-05-13 -- Slice 5 guarded q=3 registry scaffold

Scope:

- changed `append_covariance_registry_block()` to enumerate all
  `q * (q - 1) / 2` member pairs through a private
  `covariance_registry_pair_rows()` helper;
- kept current fitted q=2 block behaviour unchanged while allowing internal
  q=3 scaffold registries to carry three members and three stable pair rows;
- added an `implemented` flag argument so internal q=3 scaffolds can be marked
  `FALSE`;
- kept `labelled_covariance_block_tmb_data()` guarded for implemented
  two-member blocks only, so no q > 2 registry can be exported to TMB yet;
- added a public bivariate guard test for the three-member shared-label route,
  which still errors before fitting;
- changed no accepted syntax, likelihood code, C++ code, fitted parameter
  estimates, or user-facing q > 2 support.

Checks:

- Boole inspected the parser and registry boundary and recommended a
  registry-only q=3 scaffold with parser and TMB gates closed.
- Curie inspected the tests and recommended deterministic internal q=3 pair-row
  assertions plus a TMB-export guard assertion.
- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R
  tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 24 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "biv-gaussian|gaussian-random-intercepts|covariance-block-registry")'`:
  passed with 837 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|corpairs|check-drm|profile-targets|biv-gaussian|gaussian-random-intercepts")'`:
  passed with 1196 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

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

- Gauss reviewed the C++ boundary risk before validation and recommended
  declaring the fields with `(void)` casts.
- Curie reviewed the test surface and recommended the exported-data assertion
  plus one no-op objective/gradient assertion.
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


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-slice-4-cpp-block-contract-visibility.md` (2026-05-13 06:45): # After Task: Slice 4 C++ Block Contract Visibility
- `docs/dev-log/after-task/2026-05-13-slice-6-q3-tmb-algebra-probe.md` (2026-05-13 06:43): # After Task: Slice 6 q=3 TMB Algebra Probe
- `docs/dev-log/after-task/2026-05-13-slice-5-guarded-q3-registry-scaffold.md` (2026-05-13 06:23): # After Task: Slice 5 Guarded q=3 Registry Scaffold
- `docs/dev-log/after-task/2026-05-13-slice-4-profile-target-registry-inventory.md` (2026-05-13 05:53): # After Task: Slice 4 `profile_targets()` Registry Inventory
- `docs/dev-log/after-task/2026-05-13-slice-4-check-drm-registry-diagnostics.md` (2026-05-13 05:47): # After Task: Slice 4 `check_drm()` Registry Diagnostics
- `docs/dev-log/after-task/2026-05-13-slice-4-corpairs-registry-extraction.md` (2026-05-13 05:37): # After Task: Slice 4 `corpairs()` Registry Extraction
- `docs/dev-log/after-task/2026-05-13-slice-4-dormant-tmb-block-contract.md` (2026-05-13 05:23): # After Task: Slice 4 Dormant TMB Block Contract
- `docs/dev-log/after-task/2026-05-13-slice-4-labelled-block-registry-compatibility.md` (2026-05-13 05:12): # After Task: Slice 4 Labelled Block Registry Compatibility

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
