# Independent D-263 review of PR #1367

Reviewer: Cursor reviewer subagent, not the builder.
PR: https://github.com/itchyshin/drmTMB/pull/1367
Branch reviewed: `cursor/dinnage-arc3-a3-misc-20260915` at `08016da8a28c45c4b39af8c8809f56b76bd40a45`
Review branch: `cursor/dinnage-arc3-a3-review-20260915`
Date: 2026-09-15

## Verdict

Changes requested.

The beta-binomial numerical change is scoped to the existing univariate family
and the main likelihood algebra matches the existing beta and zero-one beta
guard pattern. The PR is not merge-ready because CI is red on the C17/C14
current-source compatibility guard, and because one changed likelihood surface,
`drm_response_log_density()` case 14, is not exercised by the added Curie test.

## Findings

### P1: C17/C14 current-source compatibility receipt is stale after `src/drmTMB.cpp` changed

The PR changes `src/drmTMB.cpp` in the beta-binomial block, which is one of the
files watched by the C17/C14 current-source compatibility guard. The release
shards fail before `R CMD check` because
`tools/tests/test_capability_ledger.py` calls
`check_c17_c14_current_source_compatibility()`, and that guard compares current
git blobs for `R/drmTMB.R`, `R/methods.R`, `src/drmTMB.cpp`,
`tests/testthat/test-zero-one-beta.R`, and the C17/C14 runner.

Local reproduction:

```sh
python3 tools/capability_ledger.py --check
python3 -m unittest tools/tests/test_capability_ledger.py
```

The first command passes. The unit test fails with:

```text
mc-0568: current source blob differs for src/drmTMB.cpp
    receipt 969c04240f620b08ed7617cfcf7ee30bc7260c8b
    current 38fb2224af1671f5e5832e8c68ae1be646a98639
```

Relevant code and data:

- `src/drmTMB.cpp` lines 3629-3654 changed the model-14 beta-binomial
  transformation.
- `tools/capability_ledger.py` lines 2083-2105 fail closed when a watched blob
  changes.
- `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`
  still points the three rows at older source evidence.

The fix is the one printed by the guard: rerun
`R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-lane-c-c17c1-c14-model15-compatibility.R`,
then repoint `raw_attempts_path`, `provenance_path`, `summary_path`, and
`current_source_sha` for the affected rows without widening
`source_fingerprint`.

### P1: Curie test does not exercise the changed response-kernel path

The PR changes two likelihood implementations for model type 14:

- the main beta-binomial objective in `src/drmTMB.cpp` lines 3629-3668;
- `drm_response_log_density()` case 14 in `src/drm_response_kernels.h` lines
  129-152.

The added Curie test in `tests/testthat/test-dinnage-audit-a3-curie.R` fits a
plain beta-binomial response and then calls `fit$obj$fn(par)`. That exercises
the main objective path, but it does not set up a missing-predictor `mi()` model
or any other route that calls `drm_response_log_density()` for model type 14.

This leaves one of the two changed Md-H surfaces untested. A regression in the
header copy, including a future mismatch between the main block and the
two-point missing-predictor kernel, would pass the new test.

Add a focused test that forces the beta-binomial response through
`drm_response_log_density()` case 14, for example with the existing binary
missing-predictor route, and checks the same finite/reference likelihood at an
extreme logit mean.

### P1: Wave A3 owed issues are not all implemented in this PR

The PR body says seven owed issues are still follow-up work on this PR:
`#1324`, `#1326`, `#1344`, `#1348`, `#1350`, `#1357`, and `#1358`. The diff only
touches `src/drmTMB.cpp`, `src/drm_response_kernels.h`, and
`tests/testthat/test-dinnage-audit-a3-curie.R`, so only `#1325` has an
implementation attempt here.

If PR #1367 is meant to close the whole Wave A3 issue set, it should not merge
until those items land. If this PR is intentionally scoped to `#1325` only, the
branch title/body and owed-issue tracking should be narrowed so reviewers do not
infer that the other Dinnage findings are closed.

## Per-Issue Verdicts

- `#1324` numeric-kernel oracle exclusion accounting: not addressed in this
  diff.
- `#1325` beta-binomial numerical guards: implementation is directionally
  correct for the main objective, but not merge-ready until the C17/C14 receipt
  is refreshed and the response-kernel path is tested.
- `#1326` estimator exactness label: not addressed in this diff.
- `#1344` phylo extra-tip note and branch-length wording: not addressed in this
  diff.
- `#1348` pair-association RNG seed restoration: not addressed in this diff.
- `#1350` AGHQ/Cox-Reid optimizer controls and convergence checks: not
  addressed in this diff.
- `#1357` `summary(fit)$nobs`: not addressed in this diff.
- `#1358` `summary(fit)$derived` redirect to `sdpars`: not addressed in this
  diff.

## Compile, Test, and CI Evidence

- `Rscript -e "devtools::load_all(quiet = TRUE)"`: passed locally on the PR
  branch, so the changed TMB code compiles locally.
- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-dinnage-audit-a3-curie.R', reporter = 'summary')"`:
  passed locally with two expectations.
- `git diff --check origin/main...HEAD`: passed locally.
- `python3 tools/capability_ledger.py --check`: passed locally.
- Full local reproduction of the CI "Validate generated capability ledger" step
  failed in `tools/tests/test_capability_ledger.py` with the stale
  `src/drmTMB.cpp` blob described above.
- GitHub Actions for PR #1367: `os-matrix` passed, all four Ubuntu release
  shards failed at "Validate generated capability ledger", and the source-tree
  blind-spot job was still in progress when this audit was written.

## Scope and API Checks

- Package scope: preserved. The implemented change is within the existing
  univariate `beta_binomial()` likelihood.
- Likelihood coherence: the main objective now uses the same nudge and shape
  floor pattern as the beta-shaped sibling families, with
  `phi = exp(-2 * log_sigma)`, `alpha = mu * phi`, and
  `beta_shape = (1 - mu) * phi`.
- Parameter transformations: directionally correct for the changed beta-binomial
  path. The test currently checks only `eta_mu = 700`; the header path and the
  negative extreme should also be covered.
- Curie inclusion: present as `tests/testthat/test-dinnage-audit-a3-curie.R`,
  but incomplete for the duplicated response-kernel path.
- C17 status: `R/drmTMB.R` and `R/methods.R` are untouched, but the C17/C14 guard
  also watches `src/drmTMB.cpp`; that guard is currently red and must be
  refreshed before merge.
