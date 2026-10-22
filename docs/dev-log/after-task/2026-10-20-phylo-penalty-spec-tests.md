# After task: fit-free tests for the phylogenetic penalty helpers

## Goal

Add direct tests for the internal helpers that build, parse, and apply a
phylogenetic penalty specification, without changing package behaviour.

## Implemented

The existing test-only PR file, `tests/testthat/test-phylo-penalty-spec.R`,
remains unchanged. Its 63 fit-free expectations cover the penalty object's
class and fields, input validation, accepted and rejected parser inputs,
specification updates, the two-SD correlation guard, and default printing.
The original PR also reported 75 passes for the broader `filter = "penalty"`
run; that broader result was not repeated during this closeout.

## Mathematical contract

No likelihood, prior, estimator, parameterization, or public interface changed.
The tests characterize the existing `sd_u`, `sd_alpha`, `rate`, and `cor_sd`
specification and its validation only. They do not establish recovery or
calibration for penalized fits.

## Files changed

- `docs/dev-log/after-task/2026-10-20-phylo-penalty-spec-tests.md` — completed
  this closeout report.
- `docs/dev-log/check-log.md` — recorded the source sync and focused result.

The test file and package source were not edited in this closeout. Current
`main` was merged into the isolated PR preparation branch from
`7820315cc904358edbf3635515ebd3a73dbb7f31`; the PR test remained present and
the histories had no changed-path overlap. The shared primary checkout was
left untouched.

## Checks run

- `git diff --check github/main...HEAD` before the documentation edits: clean.
- `Rscript -e 'devtools::test(filter = "phylo-penalty-spec", reporter = "summary")'`
  on the synced source completed with 63 successful expectations and no
  failures. Environment: R 4.6.0, macOS Tahoe 26.7.1, ARM64. The test file
  SHA-256 was `f514b2031745d15392082fc6b08751c2fe8cb79b99f309567f5f674369238e71`
  (Git blob `a2a8f08ad5c8309da60fce6406940121f9eb9236`).
- No model fits were run. The full package suite and `R CMD check` were not run.

## Tests of the tests

The tests exercise the helper branches directly, including malformed inputs
and unsupported combinations. The Quaas A-inverse check compares the sparse
helper result with `solve(A)` at tolerance `1e-10`; covariance/precision checks
also compare their product with the identity. The current focused run confirms
the test file still passes after syncing `main`. The earlier 75-pass broader
filter result remains historical evidence.

## Consistency audit

Inspected `R/penalty.R`, design notes 172 and 174, and the existing fit-level
tests. The helper names and tested fields agree with the implementation; no
public documentation, examples, NEWS, roadmap, or pkgdown navigation needed
updating for a test-only addition. The task-specific search
`rg -n 'drm_phylo_penalty|drm_parse_phylo_penalty|drm_apply_phylo_penalty_spec' README.md NEWS.md docs/design/172-phylo-penalized-map.md docs/design/174-controls-and-convergence.md docs/dev-log/known-limitations.md tests/testthat/test-phylo-penalty-spec.R`
found the expected implementation and documentation references. No code or
user-facing claims changed.

## GitHub issue maintenance

The PR has no linked issue. Searches for open issues matching “phylogenetic
penalty” and `drm_phylo_penalty` returned no results. No issue was opened,
commented on, or closed.

## What did not go smoothly

The PR branch was 13 commits behind current `main`. Merging current `main` into
the isolated preparation branch completed without conflicts and preserved the
test file. No other task failure occurred.

## Team learning

Test-only PRs still need a source-pinned check-log record and an after-task
report. Keep focused fit-free results distinct from broader filters that may
run model fits.

## Known limitations

These are characterization tests for helper behavior. They do not test a
penalized model fit, statistical recovery, interval calibration, or coverage;
those claims remain governed by the existing fit-level and simulation
evidence.

## Next actions

Push this PR branch to refresh exact-head CI. Review the new CI result before
any promotion or merge decision. This closeout does not mark the PR ready or
merge it.

## Prose review

Style: 2/10, moderate confidence; genre/coverage: concise developer closeout,
read in full. Evidence/repair: the Goal states the test-only purpose first,
and Checks run gives the exact command, result, and environment; no change was
needed. Gates: science = not applicable (no model claim added); facts = pass
against the source, commands, and live repository state recorded here;
references = not applicable (none used). Provenance: self-review, report
revision after the synced-source rerun, 2026-10-22; prior report/example
patterns were seen.
