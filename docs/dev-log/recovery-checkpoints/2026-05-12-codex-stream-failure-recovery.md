# Codex Recovery Checkpoint

Generated: 2026-05-12 14:56:18 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: Recover from repeated Codex compaction or stream failures during the current covariance-profile branch
Suggested next step: Review this checkpoint, rerun git status and git diff, then prepare the PR or continue with a small comparator slice

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/biv-profile-next-slice...origin/main [ahead 1]
 M docs/dev-log/check-log.md
 M docs/dev-log/recovery-checkpoints/2026-05-12-codex-stream-failure-recovery.md
 M tests/testthat/test-gaussian-random-intercepts.R
?? docs/dev-log/after-task/2026-05-12-mu-sigma-transform-regression-test.md
```

### Changed Files

`git diff --name-status`

```text
M	docs/dev-log/check-log.md
M	docs/dev-log/recovery-checkpoints/2026-05-12-codex-stream-failure-recovery.md
M	tests/testthat/test-gaussian-random-intercepts.R
```

`git ls-files --others --exclude-standard`

```text
docs/dev-log/after-task/2026-05-12-mu-sigma-transform-regression-test.md
```

### Diff Stat

`git diff --stat`

```text
 docs/dev-log/check-log.md                          | 20 ++++++++++
 .../2026-05-12-codex-stream-failure-recovery.md    | 38 +++++++++++++++----
 tests/testthat/test-gaussian-random-intercepts.R   | 44 ++++++++++++++++++++++
 3 files changed, 94 insertions(+), 8 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
5580b59 Checkpoint covariance profile recovery work
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (6 sections)

# Check Log

Record meaningful development checks here.

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

## 2026-05-12 -- Focused covariance branch recovery validation

Scope:

- reran the focused validation surface for the current univariate `mu`/`sigma`
  covariance and covariance-profile branch after adding the recovery checkpoint
  tool;
- covered fit/parser behaviour, `check_drm()` diagnostics, manual phylogenetic
  TMB fixture compatibility, profile target rows, direct profile intervals, and
  summary covariance rows;
- did not change package implementation code.

Checks:

- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 621 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1899 expectations, 0 failures,
  0 warnings, and 0 skips.

## 2026-05-12 -- Codex recovery checkpoint tool

Scope:

- added `tools/codex-checkpoint.R`, a base-R recovery helper that captures
  branch/status, changed tracked files, untracked files, diff stat, current
  `HEAD`, newest check-log entries, newest after-task reports, and restart
  commands in one compact Markdown file;
- documented the recovery command in `AGENTS.md` so future long Codex runs can
  checkpoint before fragile handoffs or after stream failures;
- wrote a current durable checkpoint to
  `docs/dev-log/recovery-checkpoints/2026-05-12-codex-stream-failure-recovery.md`;
- kept the current covariance/profile implementation untouched.

Checks:

- First smoke run of `Rscript tools/codex-checkpoint.R --stdout --goal "Smoke test recovery checkpoint" --next "Inspect git status" --sections 2`:
  failed with an invalid regular expression in the path-shortening helper.
  Replaced the regex trim with a simpler `startsWith()`-based path trim.
- `Rscript tools/codex-checkpoint.R --stdout --goal "Smoke test recovery checkpoint" --next "Inspect git status" --sections 2`:
  passed and printed the expected branch/status, changed files, diff stat,
  newest check-log entries, newest after-task reports, and recovery commands.
- `Rscript tools/codex-checkpoint.R --output docs/dev-log/recovery-checkpoints/2026-05-12-codex-stream-failure-recovery.md --goal "Recover from repeated Codex compaction or stream failures during the current covariance-profile branch" --next "Review this checkpoint, rerun git status and git diff, then preserve a commit boundary or run focused validation" --sections 4`:
  passed and wrote the checkpoint file.
- `air format tools/codex-checkpoint.R`: passed.
- `Rscript -e "invisible(parse(file = 'tools/codex-checkpoint.R')); cat('parse ok\\n')"`:
  passed.
- `git diff --check`: passed.

Known limitations:

- no package tests were rerun for this process-only tool;
- the checkpoint records compact git/log evidence, not the full patch.

## 2026-05-12 -- Profile covariance status docs alignment

Scope:

- aligned `docs/design/12-profile-likelihood-cis.md` with the implemented
  direct covariance profile interval surface for the first univariate
  `mu`/`sigma` and bivariate `mu1`/`mu2` random-intercept correlations;
- updated `docs/design/28-double-hierarchical-endpoint.md` so direct covariance
  profile intervals are partly implemented while derived covariance summaries
  remain planned;
- updated `ROADMAP.md`, `NEWS.md`, and `docs/dev-log/known-limitations.md` to
  name direct covariance intervals through `confint(..., method = "profile")`
  and `summary(conf.int = TRUE, method = "profile", ci_parm = ...)`;
- kept residual `rho12`, group-level `mu_sigma`, and bivariate group-level `mu`
  namespaces separate.

Checks:

- `air format docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'summary|profile-targets')"`: passed
  with 274 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `rg -n 'summary profile intervals remain planned|Profile-likelihood intervals for covariance summaries \| Planned|covariance summaries \| Planned|profile.*covariance.*Planned' docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  found only the intentional derived-summary interval limitation in
  `docs/design/12-profile-likelihood-cis.md`.
- `rg -n 'direct covariance profile intervals|corpars\$mu_sigma|eta_cor_mu_sigma|summary\(conf.int = TRUE|Profile-likelihood intervals for covariance summaries \| Partly implemented|first fitted group-level covariance rows|derived summary profile intervals remain planned' docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md tests/testthat/test-summary.R tests/testthat/test-profile-targets.R`:
  confirmed implemented-status wording, target parameter names, summary profile
  path, and the remaining derived-summary boundary.
- `LC_ALL=C rg -n '[^\x00-\x7F]' docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  no matches.
- `git diff --check`: passed.

## 2026-05-12 -- Covariance profile intervals in summary

Scope:

- added focused `summary(conf.int = TRUE, method = "profile")` checks for the
  implemented covariance rows already shown in `summary(fit)$parameters`;
- checked that the univariate
  `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)` row receives
  finite profile bounds around the fitted `corpars$mu_sigma` estimate;
- checked that the bivariate
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)` row receives finite
  profile bounds around the fitted `corpars$mu` estimate;
- kept the checks scoped to existing direct profile targets and left residual
  `rho12` as a separate residual-correlation row.

Checks:

- `air format tests/testthat/test-summary.R`: passed.
- `Rscript -e "devtools::test(filter = 'summary')"`: passed with 63
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'summary|profile-targets')"`: passed
  with 274 expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'summary\(conf.int = TRUE|corpars\$mu_sigma|corpars\$mu|residual rho12|profile bounds|method = "profile"' tests/testthat/test-summary.R docs/dev-log/after-task/2026-05-12-covariance-profile-intervals-in-summary.md docs/dev-log/check-log.md`:
  confirmed the summary profile path, covariance row estimates, residual-`rho12`
  boundary wording, and check-log entry.
- `git diff --check`: passed.

## 2026-05-12 -- Bivariate mu covariance profile interval

Scope:

- added a focused `confint(..., method = "profile")` regression test for the
  implemented bivariate `mu1`/`mu2` random-intercept covariance slice;
- checked that
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)` profiles on
  `eta_cor_mu`, reports a response-scale `tanh` interval, and keeps the
  interval finite, bounded inside `(-1, 1)`, and surrounding the fitted
  `corpars$mu` estimate;
- kept this separate from residual `rho12`, which remains a residual
  bivariate correlation target.

Checks:

- `air format tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 211
  expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'confint profile intervals transform bivariate mu|eta_cor_mu|corpars\$mu|residual rho12' tests/testthat/test-profile-targets.R docs/dev-log/after-task/2026-05-12-bivariate-mu-profile-interval.md docs/dev-log/check-log.md`:
  confirmed the new bivariate interval test, optimized TMB parameter name,
  fitted `corpars$mu` check, and residual-`rho12` boundary wording.
- `git diff --check`: passed.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-12-mu-sigma-transform-regression-test.md` (2026-05-12 14:56): # After Task: Mu/Sigma Transform Regression Test
- `docs/dev-log/after-task/2026-05-12-univariate-mu-sigma-covariance-bridge.md` (2026-05-12 14:02): # After Task: Univariate Mu/Sigma Covariance Bridge
- `docs/dev-log/after-task/2026-05-12-mu-sigma-summary-covariance-rows.md` (2026-05-12 14:02): # After Task: Mu/Sigma Summary Covariance Rows
- `docs/dev-log/after-task/2026-05-12-mu-sigma-profile-target-rows.md` (2026-05-12 14:02): # After Task: Mu/Sigma Profile-Target Rows
- `docs/dev-log/after-task/2026-05-12-mu-sigma-check-drm-diagnostic.md` (2026-05-12 14:02): # After Task: Mu/Sigma check_drm Diagnostic
- `docs/dev-log/after-task/2026-05-12-codex-recovery-checkpoint-tool.md` (2026-05-12 13:51): # After Task: Codex Recovery Checkpoint Tool
- `docs/dev-log/after-task/2026-05-12-profile-covariance-status-docs.md` (2026-05-12 13:32): # After Task: Profile Covariance Status Docs
- `docs/dev-log/after-task/2026-05-12-covariance-profile-intervals-in-summary.md` (2026-05-12 13:22): # After Task: Covariance Profile Intervals In Summary

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
