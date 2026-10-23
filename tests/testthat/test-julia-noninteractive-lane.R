# Regression cover for the non-interactive CRAN-lane misclassification
# (Ayumi-495/LS_ecogeographical-rules#29, fixed on main in 54366baa 2026-08-30).
#
# `engine = "julia"` used to abort in an ordinary `Rscript` session, because the
# CRAN-lane predicate inferred "package check" from `!interactive()`. A scripted
# analysis is a supported way to use this package; it is not R CMD check. The fix
# added `nzchar(_R_CHECK_PACKAGE_NAME_)`.
#
# WHY THIS FILE EXISTS: the fix shipped without a test that fails without it.
# Measured 2026-09-03 in this worktree -- reverting the `nzchar()` conjunct leaves
# test-cran-lane-filter.R fully green (32 passed, 0 failed), because every case it
# asserts either sets `_R_CHECK_PACKAGE_NAME_` or is already exempted by
# NOT_CRAN / DRMTMB_JULIA_TESTS. The user-facing case -- a plain non-interactive
# session with NO check marker at all -- was never asserted, so the bug could be
# reintroduced with CI green. The first test below is that missing assertion.
#
# WHICH MARKER, AND WHY: measured with probe packages under `R CMD check --no-manual`
# (docs/dev-log/evidence/julia-r-parity/check-lane-markers/):
#
#   lane                  _R_CHECK_PACKAGE_NAME_   TESTTHAT_IS_CHECKING
#   examples (\examples)  set                      unset
#   tests/testthat.R      set                      unset
#   inside test_check()   set                      set
#   vignette rebuild      UNSET                    UNSET
#
# So `_R_CHECK_PACKAGE_NAME_` is the only marker covering every check lane that can
# reach drm_julia_setup(); `TESTTHAT_IS_CHECKING` alone would miss the examples lane,
# which is the lane the guard was written for (the #1061 Ligges R-release hang).
# The vignette rebuild carries no marker at all -- see the last test.

lane_env <- function(...) {
  base <- c(
    DRMTMB_JULIA_TESTS = "", NOT_CRAN = "", `_R_CHECK_PACKAGE_NAME_` = ""
  )
  overrides <- c(...)
  base[names(overrides)] <- overrides
  base
}

test_that("a plain non-interactive Rscript session is NOT the CRAN lane (#29 regression)", {
  # THE assertion the fix lacked: no check marker anywhere, non-interactive.
  # Fails against the pre-fix predicate; passes against the shipped one.
  expect_false(
    drmTMB:::drm_julia_cran_lane_blocked(
      is_interactive = FALSE, environ = lane_env()
    )
  )
  # ... and an unrelated _R_CHECK_* switch a user or runner may set on their own
  # must not be mistaken for the package-check marker.
  expect_false(
    drmTMB:::drm_julia_cran_lane_blocked(
      is_interactive = FALSE,
      environ = lane_env(`_R_CHECK_TIMINGS_` = "0", `_R_CHECK_FORCE_SUGGESTS_` = "false")
    )
  )
})

test_that("every R CMD check lane that can reach Julia setup is still blocked", {
  # examples lane, and tests/testthat.R before test_check()
  expect_true(
    drmTMB:::drm_julia_cran_lane_blocked(
      is_interactive = FALSE, environ = lane_env(`_R_CHECK_PACKAGE_NAME_` = "drmTMB")
    )
  )
  # inside test_check(): both markers present
  expect_true(
    drmTMB:::drm_julia_cran_lane_blocked(
      is_interactive = FALSE,
      environ = lane_env(
        `_R_CHECK_PACKAGE_NAME_` = "drmTMB", TESTTHAT_IS_CHECKING = "true"
      )
    )
  )
})

test_that("the two documented opt-outs still override a real check lane", {
  expect_false(
    drmTMB:::drm_julia_cran_lane_blocked(
      is_interactive = FALSE,
      environ = lane_env(
        `_R_CHECK_PACKAGE_NAME_` = "drmTMB", DRMTMB_JULIA_TESTS = "true"
      )
    )
  )
  expect_false(
    drmTMB:::drm_julia_cran_lane_blocked(
      is_interactive = FALSE,
      environ = lane_env(`_R_CHECK_PACKAGE_NAME_` = "drmTMB", NOT_CRAN = "true")
    )
  )
})

test_that("no EVALUATED vignette chunk reaches engine = \"julia\"", {
  # The vignette rebuild subprocess carries NO check marker (measured, table above),
  # so the shipped predicate cannot recognise it as a check lane. Today that is safe
  # only because no evaluated chunk calls engine = "julia" -- the julia-engine.Rmd
  # blocks are display-only ```r fences, not ```{r} chunks. An evaluated chunk would
  # boot Julia during CRAN's vignette rebuild and could hang it the way #1061 did.
  # This pins the assumption the predicate rests on rather than trusting it to hold.
  vig_dir <- testthat::test_path("..", "..", "vignettes")
  skip_if_not(dir.exists(vig_dir), "vignettes/ not present in this lane")
  vigs <- list.files(vig_dir, pattern = "[.]Rmd$", full.names = TRUE)
  skip_if(length(vigs) == 0L, "no vignettes found")

  offenders <- character()
  for (v in vigs) {
    lines <- readLines(v, warn = FALSE)
    in_eval_chunk <- FALSE
    header <- ""
    for (ln in lines) {
      if (grepl("^```\\{[rR][ ,}]", ln)) {
        header <- trimws(ln)
        in_eval_chunk <- !grepl("eval\\s*=\\s*FALSE", ln)
        next
      }
      if (grepl("^```\\s*$", ln)) {
        in_eval_chunk <- FALSE
        header <- ""
        next
      }
      if (in_eval_chunk && grepl('engine\\s*=\\s*"julia"', ln)) {
        offenders <- c(offenders, paste0(basename(v), " ", header))
      }
    }
  }
  expect_equal(unique(offenders), character())
})

test_that("the vignette-chunk scanner actually detects an offending chunk", {
  # Positive control for the negative assertion above: the scanner must find a
  # planted evaluated chunk, or its "no offenders" result would be vacuous.
  tmp <- withr::local_tempdir()
  writeLines(
    c("```{r demo}", 'drmTMB(y ~ x, data = d, engine = "julia")', "```",
      "```r", 'drmTMB(y ~ x, data = d, engine = "julia")', "```",
      "```{r skipped, eval=FALSE}", 'drmTMB(y ~ x, data = d, engine = "julia")', "```"),
    file.path(tmp, "planted.Rmd")
  )
  scan_one <- function(v) {
    lines <- readLines(v, warn = FALSE)
    in_eval_chunk <- FALSE
    hits <- character()
    for (ln in lines) {
      if (grepl("^```\\{[rR][ ,}]", ln)) {
        in_eval_chunk <- !grepl("eval\\s*=\\s*FALSE", ln)
        next
      }
      if (grepl("^```\\s*$", ln)) {
        in_eval_chunk <- FALSE
        next
      }
      if (in_eval_chunk && grepl('engine\\s*=\\s*"julia"', ln)) hits <- c(hits, ln)
    }
    hits
  }
  # exactly one hit: the evaluated ```{r demo} chunk. The display-only ```r fence
  # and the eval=FALSE chunk must NOT be flagged.
  expect_length(scan_one(file.path(tmp, "planted.Rmd")), 1L)
})
