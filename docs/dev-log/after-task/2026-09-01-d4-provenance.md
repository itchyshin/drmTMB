# D4: a build-provenance surface for drmTMB (DRM.jl#473)

Date: 2026-09-01 · Lane: Claude Code · Branch: `claude/rev-parity-d4-provenance`

## Goal

`packageVersion("drmTMB")` cannot tell a fixture, receipt, or bug report which
BUILD produced it. Measured 2026-08-24: every banked R<->Julia parity number
labelled `drmTMB 0.7.0` was measured against a build 16 shipped-file commits
behind `origin/main` on `R/`, `src/`, and `NAMESPACE`, and both report the
same version string. Add `drm_provenance()`, stamp it onto fitted objects,
and give DRM.jl#473 the developer-tool script it asks for.

**The gap is live, not historical, and it grew while this slice was in
flight.** Re-measured 2026-09-01 on this machine:

```r
> packageDescription("drmTMB")$Built
[1] "R 4.6.0; aarch64-apple-darwin23; 2026-08-28 00:59:31 UTC; unix"
> packageVersion("drmTMB")
[1] '0.7.0'
```
```sh
$ git rev-parse origin/main
27073059ea2be3ce2efd53b3d7255a927c479d63
$ git log --oneline --since=2026-08-28 origin/main -- R/ src/ NAMESPACE | wc -l
21
```

The installed build predates 21 commits to `R/`, `src/`, and `NAMESPACE` on
`origin/main` -- up from the 16 DRM.jl#473 measured on 2026-08-24 -- while
`packageVersion("drmTMB")` still reads `"0.7.0"` for both. Re-running the two
commands above at any later date will show the count move again; that
movement is the problem this slice exists to make visible.

## What is claimed

- `drm_provenance()` is exported and documented. It returns a stable,
  seven-field record: `package_version`, `git_sha`, `git_dirty`,
  `build_time`, `source`, `reason`, `queried_at`.
- The git SHA and dirty flag are captured **once, at build time**, never at
  call time. `./configure` and `configure.win` run plain `git rev-parse
  HEAD` / `git rev-parse --is-inside-work-tree` / `git status --porcelain`
  directly (no R dependency at that point) and write
  `inst/build-provenance.dcf` before `inst/` is copied into the installed
  package. The bake is non-fatal: no git binary, or a source tree that is
  not a git checkout (e.g. a released tarball, where `.git` is excluded via
  `.Rbuildignore`), writes `NA` fields with a stated `reason` rather than
  failing the install.
- `drm_provenance()` only ever reads the baked `inst/build-provenance.dcf`
  via `system.file()`. It never shells out to git. Three `source` states:
  `"baked"` (git info known), `"baked-without-git"` (`configure` ran, but
  git itself was unavailable at build time), `"unavailable"` (no baked file
  at all -- e.g. `devtools::load_all()`, or an install whose `configure`
  step did not run). Every non-`"baked"` state carries a `reason` string.
- Every `drmTMB` fit object now carries the record at `fit$provenance`
  (`R/drmTMB.R`, added to the fit list right before `class(fit) <-
  "drmTMB"`).
- `tools/drmtmb_provenance.R` is the separate script form DRM.jl#473 asks
  for, at exactly that path, for stamping build anchors into Julia-side
  fixture receipts. It is a developer tool, not a shipped component.
- Tests: `tests/testthat/test-provenance.R`, written first (TDD) and
  confirmed skipping/failing before any implementation existed. Covers the
  record shape and field types, the no-git degraded path (via
  `drmtmb_capture_git_state()` against a plain tempdir with no `.git`), the
  dirty-tree flag (a real temp git repo, committed then modified), the
  script-level `drmtmb_provenance()` composition, and that a fitted object
  carries the stamp. 80 assertions pass under `devtools::test(filter =
  "provenance")` (this filter also matches the pre-existing
  `test-arc6-f3-provenance-smoke-runner.R`, which is why the count is above
  the ~8 `test_that()` blocks added here).
- `configure`'s three states (no git, clean, dirty) were verified directly
  by running it in an isolated scratch git repo outside this checkout (not
  by a full `R CMD build`/`INSTALL` round trip, which would need to compile
  the C++ TMB source and was reserved for the `--as-cran` run below).
- **Self-test that this actually solves the motivating problem**: added
  `test_that("two different builds produce distinguishable provenance --
  the problem this slice solves", ...)`, which commits twice to an isolated
  scratch git repo and confirms `drmtmb_capture_git_state()` -- the exact
  capture path `configure` duplicates -- returns two different, non-`NA`
  SHAs for the two commits. If two different builds could still produce
  identical provenance records, this feature would not have solved the
  problem DRM.jl#473 and the 16-then-21-commit gap describe. Passes.

## What is NOT claimed

- No Julia-side implementation exists, and none was created. This is
  drmTMB-side only, ahead of DRM.jl, not parity with it.
- `configure.win` was written to the same design as `configure` but was not
  executed on Windows in this session (this environment is macOS); its
  batch-file git-availability and quoting logic is best-effort, not
  verified end-to-end.
- `R CMD check --as-cran` was run once, on macOS only, not on the
  CRAN-relevant multi-OS matrix. See the result below for what that single
  run showed.
- Neither `configure` nor `drm_provenance()` attempts to reconcile a dirty
  build with which *uncommitted* changes were present -- `git_dirty = TRUE`
  is a boolean flag, not a diff. That is deliberately out of scope; the
  record identifies a build, not a patch.

## The `.Rbuildignore` decision (do not re-litigate)

`.Rbuildignore` already excludes the whole `tools/` directory
(`^tools$`) from the built source tarball -- correctly, since it holds
~300 developer/campaign scripts, and DRM.jl#473's requested
`tools/drmtmb_provenance.R` is one more such developer tool, not a shipped
component. Two workaround options were considered and rejected before
implementation started:

1. **Carve a regex exception into `.Rbuildignore`** so
   `tools/drmtmb_provenance.R` alone ships while the rest of `tools/` stays
   excluded. Rejected: `.Rbuildignore` patterns are Perl regexes matched
   against every path in the source tree; "exclude the directory except one
   file" is easy to get subtly wrong, and getting it wrong risks shipping
   some of the other ~300 dev/campaign scripts to CRAN.
2. **Move the script outside `tools/`** (package root, or a new small
   directory) so it ships without touching the ignore rule. Rejected: this
   fights DRM.jl#473, which explicitly asks for the script *at*
   `tools/drmtmb_provenance.R`.

**Decision: break the dependency instead.** `.Rbuildignore` is untouched.
`configure`/`configure.win` do not source or call
`tools/drmtmb_provenance.R` at all -- they re-implement the same few `git
rev-parse`/`git status --porcelain` lines directly in shell/batch. Nothing
that must ship depends on a file that is (correctly) excluded from the
tarball, and `tools/drmtmb_provenance.R` stays exactly where the upstream
issue wants it, free to depend on nothing but base R for its own
(unshipped, developer-only) use. The duplication is called out in comments
in both `configure` and `tools/drmtmb_provenance.R`, with an instruction to
keep the two in sync if the git-capture logic ever changes.

## A second bug found and fixed along the way

Baking `inst/build-provenance.dcf` into the working source tree makes it an
**untracked file** on the very next `git status` -- so every subsequent
`devtools::install()`/`R CMD INSTALL` from the same git checkout would see
`git_dirty = TRUE` purely because of the file the bake step itself just
wrote, self-polluting the flag it exists to report accurately. Fixed by
adding `/inst/build-provenance.dcf` to `.gitignore`. Verified in an
isolated scratch repo: with the file gitignored, a `configure` run after a
clean commit reports `GitDirty: FALSE`; modifying a tracked file reports
`GitDirty: TRUE` for the same SHA.

## Verification

- `Rscript -e 'devtools::document()'`: regenerated `NAMESPACE` (one new
  export line, `drm_provenance`) and `man/drm_provenance.Rd`.
  `devtools::document()` also touched `man/confint.drmTMB.Rd` on an
  unrelated `\code{}`-wrapping rendering difference (pre-existing
  roxygen2/markdown-flag drift, unconnected to this change); that file was
  restored to the committed `HEAD` version rather than shipped as part of
  this diff.
- `devtools::test(filter = "provenance")`: `[ FAIL 0 | WARN 0 | SKIP 0 |
  PASS 83 ]`. Per the coordinator's explicit instruction, the full
  `devtools::test()` suite was **not** run directly in this session (it
  takes 40+ minutes; running it stand-alone, outside a `check()`, was
  reserved for a separate integration gate). It ran anyway as an unavoidable
  part of `R CMD check` below, since `tests/testthat.R` is part of the
  checked package.
- `devtools::check(args = "--as-cran")`, i.e. `R CMD check
  drmTMB_0.7.0.tar.gz --as-cran --as-cran --no-manual` (devtools passed
  `--as-cran` twice; harmless to the result, noted here so the exact
  invocation is reproducible if anyone re-runs it -- drop the duplicate on
  a re-run). Duration: 25m 23.3s total; the `tests/testthat.R` step alone
  took 19-21 minutes (this is the full suite, run because `R CMD check`
  cannot skip `tests/`, not a choice made in this session).

  **Real result, verbatim:**

  ```
  Status: 1 WARNING, 1 NOTE

  0 errors | 1 warning | 0 notes
  ```

  (`devtools::check()`'s own coloured summary at the very end reports
  "0 notes" because it does not have a `* checking ...` line to attach the
  NOTE to -- the NOTE is a standalone timing annotation on the
  `tests/testthat.R` run itself, `Running 'testthat.R' [19m/21m]` followed
  by a bare `[19m/21m] NOTE` line, not a distinct checked item with its own
  message. The raw `R CMD check` `Status:` line, which is authoritative,
  reports it as one NOTE. Both readings agree there is no *additional* NOTE
  text beyond that duration flag -- e.g. no "undocumented objects" NOTE
  naming `drm_julia_joint_prepare`/`drm_julia_joint_result` or anything
  else. `devtools::check()` also errored its own wrapper (`Error: R CMD
  check found WARNINGs`) because it treats a WARNING as a hard failure for
  its exit code; that is `devtools`' policy on top of a real, single
  `R CMD check` WARNING, not evidence of a separate problem.)

  The one WARNING, verbatim:

  ```
  * checking top-level files ... WARNING
    A complete check needs the 'checkbashisms' script.
    See section 'Configure and cleanup' in the 'Writing R Extensions'
    manual.
  ```

  This is an environment limitation (the `checkbashisms` binary is not
  installed on this machine), not a defect in `configure`/`configure.win`.
  `R CMD check` cannot verify the new `configure` script avoids bashisms
  without that tool; it did not report finding any. Not fixed in this
  session (installing `checkbashisms` is outside this slice's scope), and
  called out here rather than left implicit.

  **0 ERRORs.** The C++ install step, all Rd/NAMESPACE/documentation
  checks, `checking examples` (which runs `drm_provenance()`'s own
  `@examples` block), `checking examples with --run-donttest`, and the full
  `tests/testthat.R` suite (which includes every test in the package, not
  just `test-provenance.R`) all passed clean.

## Unrelated documentation drift found by `devtools::document()` (excluded)

`devtools::document()` also generated `man/drm_julia_joint_prepare.Rd` and
`man/drm_julia_joint_result.Rd`. Checked before deciding: both functions
(`R/julia-joint-missing.R`, `R/julia-joint-methods.R`, last touched at
`6ca8f9377`) carry a `#' @keywords internal` roxygen block but no `@export`
tag, and neither `.Rd` exists on `HEAD`. This is `document()` catching up on
two pre-existing internal functions that were documented in source but never
had their Rd regenerated/committed -- unrelated to provenance.

**Decision: (a) exclude them.** This slice is about build provenance;
shipping two unrelated Rd pages would make the diff harder to review and
quietly claim documentation work not done here. Neither function is
`@export`ed, so `R CMD check --as-cran` does not need them (that check only
flags undocumented *exported* objects) -- confirmed by the check result
above, which has no NOTE about missing documentation. The next person to run
`devtools::document()` on this branch or on `origin/main` will see the same
two untracked files; that is expected and not a regression this slice
introduced.

## Constraints respected

- Did not touch `inst/extdata/julia-capabilities.tsv`,
  `docs/dev-log/coordination-board.md`, `R/julia-bridge.R`,
  `.github/workflows/`.
- No `DESCRIPTION` version bump, no release action (D-164).
- No merge to `main`; commits live on `claude/rev-parity-d4-provenance`
  only.
