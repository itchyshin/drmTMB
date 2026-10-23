# Which environment markers does `R CMD check` actually set, in which lane?

Measured 2026-09-03 on macOS (darwin 25.6.0), R 4.6, with throwaway probe packages
built and checked by `R CMD build` + `R CMD check --no-manual`. Each probe prints
`Sys.getenv()` from one lane; the values below are read out of the resulting
`*.Rcheck/` logs.

This exists because `drm_julia_cran_lane_blocked()` has to answer one question --
"am I inside a package check?" -- and the first answer it shipped with
(`!interactive()`) was wrong in a way that blocked a real user
(Ayumi-495/LS_ecogeographical-rules#29: `engine = "julia"` aborted in an ordinary
`Rscript` session). Replacing a wrong inference with a guessed one would not be an
improvement, so the replacement marker was measured rather than assumed.

## Result

| lane                                | `_R_CHECK_PACKAGE_NAME_` | `TESTTHAT_IS_CHECKING` |
|-------------------------------------|--------------------------|------------------------|
| `\examples` in an `.Rd` file        | set (`envprobe`)         | unset                  |
| `tests/testthat.R`, before `test_check()` | set (`envprobe`)   | unset                  |
| inside `test_check()` / `test_that()` | set (`envprobe`)       | `true`                 |
| vignette rebuild (`knitr` subprocess) | **unset**              | **unset**              |

Verbatim probe lines:

    EXAMPLE_LANE     _R_CHECK_PACKAGE_NAME_=[envprobe] TESTTHAT_IS_CHECKING=[]   interactive=FALSE
    TEST_LANE        _R_CHECK_PACKAGE_NAME_=[envprobe] TESTTHAT_IS_CHECKING=[]   interactive=FALSE
    INSIDE_TESTTHAT  _R_CHECK_PACKAGE_NAME_=[envprobe] TESTTHAT_IS_CHECKING=[true]
    VIGNETTE_LANE    _R_CHECK_PACKAGE_NAME_=[]         TESTTHAT_IS_CHECKING=[]

A second probe dumped every `Sys.getenv()` name matching
`CHECK|CRAN|TESTTHAT|R_LIBS|R_SESSION|BUILD|VIGNETTE|R_TESTS|_R_` from the vignette
lane. The complete set was `R_LIBS`, `R_LIBS_SITE`, `R_LIBS_USER`,
`R_SESSION_TMPDIR`, `_R_BIBTOOLS_CACHE_BIBENTRIES_` -- **no check marker of any
kind**.

## What follows for the predicate

1. `_R_CHECK_PACKAGE_NAME_` is the only marker present in every check lane that can
   reach `drm_julia_setup()`. The shipped fix uses it.
2. `TESTTHAT_IS_CHECKING` alone would be **wrong**: it is absent from the examples
   lane, which is precisely the lane the guard was written for (#1061, where a
   CRAN-lane `engine = "julia"` call hung Ligges' R-release check for ~10448 s).
3. The vignette rebuild is **invisible** to any marker-based predicate. It is safe
   today only because no evaluated vignette chunk calls `engine = "julia"` -- the
   `julia-engine.Rmd` examples are display-only ` ```r ` fences, not ` ```{r} `
   chunks. That is an assumption the predicate rests on, so
   `tests/testthat/test-julia-noninteractive-lane.R` pins it with a scanner (and a
   positive control proving the scanner can actually detect a planted chunk).

## Why this is a test file and not just a note

Reverting the `nzchar(_R_CHECK_PACKAGE_NAME_)` conjunct and re-running the existing
`tests/testthat/test-cran-lane-filter.R` leaves it **fully green -- 32 passed, 0
failed** (measured in this worktree, 2026-09-03). Every case it asserts either sets
`_R_CHECK_PACKAGE_NAME_` or is already exempted by `NOT_CRAN` / `DRMTMB_JULIA_TESTS`,
so the one case a user actually hits -- a non-interactive session with no check
marker at all -- was never asserted. The fix could have been reverted with CI green.
The new file fails 2 assertions against the reverted predicate.
