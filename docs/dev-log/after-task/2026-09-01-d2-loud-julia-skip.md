# 2026-09-01 -- D2: loud Julia-bridge skip (issue #1081, option 1)

## What changed

Issue #1081 option 1: make a green test run state its own boundary when the
`engine = "julia"` bridge glue was never exercised.

- `tests/testthat/helper-julia-bridge-path.R`: added a package-private
  counter (`drm_julia_bridge_summary_env$ran` / `$skipped`), reset/record
  helpers, and `drm_julia_bridge_summary_line()`, which formats an accurate
  one-line summary in both directions (never claims UNTESTED when at least
  one live test ran, always says UNTESTED when none did). The existing
  `drm_skip_live_julia()` body was renamed to `.drm_skip_live_julia_impl()`
  (logic unchanged) and wrapped in a `tryCatch(skip = ...)` that records a
  skip and re-throws the same skip condition, or records a live run when the
  impl returns normally, so testthat's own skip bookkeeping is untouched.
- `tests/testthat/teardown-julia-bridge-summary.R` (new): prints
  `drm_julia_bridge_summary_line()` via `message()`. testthat sources
  `teardown-*.R` files after all `test-*.R` files in the same `test_env()`
  used by helpers, so this fires under `devtools::test()`, `test_check()`,
  and `R CMD check` alike, and fires regardless of any `filter` argument.
- `tests/testthat/test-julia-bridge-summary.R` (new): tests the counter and
  `drm_julia_bridge_summary_line()` directly (skip-only, live-only, mixed),
  plus two tests driving `drm_skip_live_julia()` itself through its two
  branches. Written before the helper functions existed, so it exercised the
  intended fail-first shape (undefined-function errors) ahead of the
  implementation.
- `tests/testthat/test-cran-lane-filter.R`: one line added
  (`drm_julia_bridge_summary_reset()`) at the end of the pre-existing
  `"drm_skip_live_julia skips on CRAN unless DRMTMB_JULIA_TESTS=true"` test.
  This test is itself in the CRAN-lane allowlist (context
  `cran-lane-filter`), and it calls `drm_skip_live_julia()` three times under
  mocked `NOT_CRAN` / `DRMTMB_JULIA_TESTS` values to exercise the gate's own
  branches as a contract test. Before this line, those three calls were
  silently counted into the same global tally as real bridge usage, so the
  first CRAN-lane run of this feature reported
  `Julia bridge: 2 live tests ran, 1 skipped; bridge glue was exercised in
  this configuration.` even though zero `test-julia-*.R` files were sourced
  under the CRAN-lane filter. That was caught only by actually running the
  CRAN-lane entry point, not by `devtools::test()` (see below), and is the
  reason this reset line exists.

Nothing under `.github/workflows/`, `R/julia-bridge.R`,
`inst/extdata/julia-capabilities.tsv`, or
`docs/dev-log/coordination-board.md` was touched. No CI job was added or
scheduled; no `local_mocked_bindings()` usage was reduced. This is option 1
only.

## Measured test counts

### The configuration the issue is about: CRAN lane, `NOT_CRAN` unset, non-interactive

Run as R CMD check itself would run it -- `Rscript tests/testthat.R` with
cwd set to `tests/`, and `NOT_CRAN`, `DRMTMB_JULIA_TESTS`, `DRM_JL_PHYLO_PATH`
all explicitly unset (`env -u NOT_CRAN -u DRMTMB_JULIA_TESTS -u
DRM_JL_PHYLO_PATH Rscript testthat.R`), which routes through the
`drm_cran_test_filter()` allowlist branch of `tests/testthat.R` (none of the
`test-julia-*.R` files are in that allowlist, so none of them are even
sourced).

Result: `[ FAIL 2 | WARN 19 | SKIP 24 | PASS 3570 ]`, and the literal final
line of output was:

```
Julia bridge: 0 live tests skipped; bridge glue is UNTESTED in this configuration.
```

This is the load-bearing evidence for this slice: it confirms the message
fires, with the correct (zero) count, in the exact configuration the issue
describes. The 2 failures are pre-existing and unrelated to this change --
both are `test-missing-predictor-gaussian.R:291` and `:296`
("imputed() reports MD3a missing-predictor conditional modes"), a small
numerical-precision mismatch in unrelated conditional-mode arithmetic. This
file was not touched by this slice and the failure is present on `main`.

Before the `test-cran-lane-filter.R` fix described above, this same command
reported `Julia bridge: 2 live tests ran, 1 skipped; bridge glue was
exercised in this configuration.` -- an inaccurate claim, caused by that
file's own mocked-branch contract test polluting the global tally. That is
what the reset line fixes.

### `devtools::test(filter = "julia")`

`[ FAIL 0 | WARN 0 | SKIP 26 | PASS 1090 ]`, final line:
`Julia bridge: 18 live tests ran; bridge glue was exercised in this
configuration.`

**This run does not, and cannot, reproduce the silence the issue is about.**
`devtools::test()` sets `NOT_CRAN=true` internally (a documented devtools
behaviour, not specific to this package), so every `drm_skip_live_julia()`
call in every `test-julia-*.R` file takes the "proceed" branch and attempts a
real Julia call (the 26 `SKIP`s downstream are from `DRM.jl` engine/checkout
not being available locally, not from the CRAN-lane gate). A future reader
must not treat this run as verification that the CRAN-lane message fires
correctly -- it structurally cannot, because `devtools::test()` never
recreates the `NOT_CRAN`-unset, non-interactive configuration the issue
describes. Only the `Rscript tests/testthat.R` run above does that.

### Full suite

**Not run**, per explicit instruction. The full `devtools::test()` suite
takes 43-46 minutes in this repository and three agents were already running
it in parallel when this instruction arrived; the coordinator owns a single
integration-gate full-suite run afterwards. `devtools::test(filter =
"julia")` (above) and the CRAN-lane `Rscript tests/testthat.R` run (above)
are the two runs this slice's verification rests on.

## What this does NOT claim

- This does not give `engine = "julia"` any CI coverage. In the CRAN-lane
  configuration (which is what routine PR/R CMD check runs execute, per the
  issue), zero `test-julia-*.R` files are sourced and zero bridge assertions
  execute, exactly as before this change. The only difference is that the
  run's own output now says so in one line, instead of a green summary that
  looked identical whether the bridge ran or not.
- This does not add, modify, or schedule any GitHub Actions job (option 2 of
  the issue) and does not reduce `local_mocked_bindings()` usage in the
  routing tests (option 3 of the issue). Both are explicitly out of scope
  for this slice.
- This does not change `drm_skip_live_julia()`'s skip/proceed logic. The
  CRAN-lane hard-stop, the `DRMTMB_JULIA_TESTS=true` opt-in, and the
  `interactive()` fallback for local exploration are byte-for-byte the same
  predicate, now inside `.drm_skip_live_julia_impl()`, just wrapped for
  counting.
- The teardown message is per-`testthat.R`-process (the counters live in a
  package-private environment created fresh each R session), not a
  cross-run or cross-CI-job aggregate. It cannot say anything about a prior
  or a different CI job's run.
