# After Task: The CI Blind Spot -- Tests Whose Premise `R CMD check` Deletes

## 1. Goal

Measure, then close, the gap that lets a test skip forever in CI and still be
counted as a pass: `.Rbuildignore` removes `tools/`, `docs/`, `pkgdown/`,
`bench/`, `_pkgdown.yml` and the simulation-results tree from the tarball that
`rcmdcheck` checks, so any test whose premise is one of those paths hits its own
`skip_if(!file.exists(...))` on every runner, forever.

## 2. Implemented

A single ubuntu job, `source-tree-tests`, in the existing `R-CMD-check.yaml`.
It loads the package in place with `pkgload::load_all()` and runs only the
affected subset against the **source checkout**. The subset is derived from
`.Rbuildignore` at run time and cross-checked against a committed manifest, so
the blind spot cannot silently grow (a new build-excluded test that no manifest
lists) or silently shrink (an existing entry whose premise becomes invisible).
The 4-shard matrix, its triggers, and the deliberate `pull_request`-only
`cancel-in-progress` rule are untouched; the new job inherits the same
concurrency group because it lives in the same workflow.

## 3. Mathematical Contract

No likelihood, parameterization, formula grammar, estimator, or model code
changed. This slice changes only what CI executes.

## 3a. Decisions and Rejected Alternatives

Rejected: a fifth shard (the shards check the tarball, which is the problem); a
second `R CMD check` (duplicates 40 minutes to gain nothing); a hand-maintained
file list (the failure being fixed is exactly a list that rots unnoticed);
auto-discovery with no manifest (a premise that disappears behind a variable
would leave the lane silently). Chosen: derive-and-cross-check, which fails on
drift in both directions and names the file.

Also rejected, and worth an owner decision: moving the four existing
source-tree steps (`capability_ledger`, the profile-fence guard, the evidence
citation guard) out of the 4-shard matrix, where they currently run **four
times per routine run**, into this single job. That is a real minutes saving but
it is not this slice.

## 4. Files Touched

- `.github/workflows/R-CMD-check.yaml` (additive: one new job, 61 lines)
- `tools/run-source-tree-tests.R` (new)
- `tools/source-tree-tests.txt` (new, generated)
- this after-task report

## 5. Checks Run

Measured on macOS, R 4.6.0. `main` moved twice during this slice, so the
inventory was measured twice; the later numbers are the ones reported.

- First measurement, at merge commit `f8f11699c` (both #1207 and #1208 open):
  35 files, **24,341** source assertions to **854** in the tarball,
  lane `[ FAIL 11 | WARN 0 | SKIP 4 | PASS 24341 ]` in 3m42s -- 9 cheatsheet
  failures (#1208) plus 2 reader-contract failures (#1207).
- Second measurement, at `origin/main` `eccb10299`, after #1207 merged.
- Third measurement, at `origin/main` **`df1aca4a6`**, after #1204 merged.
  Byte-for-byte identical to the second on every figure below, which is why the
  reported inventory is pinned to `df1aca4a6`.

Two-mode run of every candidate file -- once with the working directory in the
source tree, once inside the extracted `R CMD build --no-build-vignettes`
tarball -- at `df1aca4a6`:

- **35** test files change behaviour between the two trees (all 35; the scanner
  produced no false positives).
- **24,348** passing assertions in the source tree; **855** in the tarball.
- **23,493** assertions (96.5%) are structurally unreachable under `R CMD check`.
- **24** of the 35 files contribute **zero** assertions to the tarball run.
- Skips rise from **4** to **278** between the two trees.

Lane command on the source tree at `df1aca4a6`:
`[ FAIL 9 | WARN 0 | SKIP 4 | PASS 24348 ]`. The 9 failures are the live #1208
defect, which was still open when this was written. The manifest did not drift
across either merge: still 35 files, and #1204's new
`test-julia-predict-quantile.R` correctly does not join it.

Existing guards re-run and green with the change: `capability_ledger.py
--check`, the five wired `tools/tests/*.py` unittests, `check-evidence-citations.R`,
`test-phase18-actions-runner.R`, `test-phase18-task-seed-registry.R`.

## 6. Tests of the Tests

Three red controls, each restored byte-identically afterwards.

1. **Cheatsheet row removed.** The brief proposed deleting the `aicc()` row from
   `tools/function-cheatsheet-source.Rmd`; that row is *already missing* -- it is
   one of the nine live #1208 defects -- so the control used `objective_at()`
   instead. Lane went `FAIL 11` to `FAIL 12` (measured at `f8f11699c`) with a new named
   expectation,
   "Expected `source` to match string \"objective_at()\"". Restored; md5
   `ea05294eaea641ce130e6307a2366092` before and after.
2. **New build-excluded test, manifest not updated.** `--check` failed, naming
   the file under "NOT IN MANIFEST".
3. **Manifest entry removed, and a ghost entry added.** `--check` failed in both
   directions, with distinct messages.

## 7a. Issue Ledger

One defect in this slice's own work, caught by the lane it added: the new job's
comment quoted a simulation-results path literally, which tripped the D-50 guard
in `test-phase18-actions-runner.R` forbidding that string in any workflow file.
Reworded; the guard is green.

## 8. Consistency Audit

The derived set was checked against the two-mode measurement file by file: no
false positives (`test-gradient-conformance.R` names `CLAUDE.md` only in a
comment and is verifiably unaffected, and the scanner correctly ignores comment
lines) and no false negatives (all 35 derived files were independently measured
as behaviour-changing).

## 9. What Did Not Go Smoothly

The brief's suggested red control could not be planted, because the defect it
proposed planting was already live on `main`.

## 10. Known Residuals

The lane is **red on `main` today**, by 9 assertions, because #1208 is still
open. That redness is the evidence the lane works; it is also why this PR should
land after #1208.

## 11. Team Learning

A skip is not a pass, and a skip caused by the *build* rather than the
*environment* is permanent. Any `skip_if(!file.exists(...))` on a path that
`.Rbuildignore` removes is a test that will never run in CI.

## 12. Cross-Product Coverage

Not applicable; no family-by-structure surface changed.

## Next Actions

Merge #1208, then this (#1207 has landed). Consider de-duplicating the four
existing source-tree steps out of the shard matrix.
