# Guard for docs/design/parity-fenced-capabilities.md.
#
# That file is the written boundary behind six capability rows whose bridge
# cell reads UNCITED on docs/design/parity-scoreboard.md. A boundary is only
# worth writing if it goes stale loudly: when a fence lifts, this test must
# fail so the entry gets rewritten rather than quietly outlived.
#
# Two kinds of check, both pure R -- no Julia session is started and nothing
# here can silently skip:
#   1. every fenced capability is named in the register, byte-for-byte as
#      docs/design/capability-status.md spells it, and every decision the
#      register leans on is cited by name;
#   2. every fence that is EXECUTABLE still refuses, with the message a reader
#      of the register would expect. These three refusals are raised by R-side
#      validation before any JuliaCall dispatch, which is why they are testable
#      without the engine.

drm_fenced_register <- function() {
  path <- testthat::test_path("..", "..", "docs", "design",
                              "parity-fenced-capabilities.md")
  skip_if_not(file.exists(path), "boundary register not in this checkout")
  readLines(path, warn = FALSE)
}

test_that("the register names every fenced capability exactly as capability-status.md does", {
  reg <- paste(drm_fenced_register(), collapse = "\n")
  status_path <- testthat::test_path("..", "..", "docs", "design",
                                     "capability-status.md")
  skip_if_not(file.exists(status_path), "capability-status.md not in this checkout")
  status <- readLines(status_path, warn = FALSE)

  fenced <- c(
    "AGHQ adaptive-quadrature marginal estimator",
    "Variational (VA/ELBO) marginal estimator",
    "Bivariate structured random effect on all four axes (q4 PLSM)",
    "Cross-family bivariate (different families for y1 y2)",
    "Missing-response handling (native, per fitted route)",
    "Missing-predictor imputation (mi())"
  )
  for (cap in fenced) {
    # the name is a real capability-status.md row, not a paraphrase
    expect_true(
      any(grepl(cap, status, fixed = TRUE)),
      info = paste0("not a capability-status.md row: ", cap)
    )
    expect_true(
      grepl(cap, reg, fixed = TRUE),
      info = paste0("boundary register does not name: ", cap)
    )
  }
})

test_that("the register cites the decision behind each fence it calls decided", {
  reg <- paste(drm_fenced_register(), collapse = "\n")
  # Each fence the register calls PERMANENT or DEFERRED must carry its citation.
  for (tok in c("D-127", "D-179 #3", "D-181 #1", "D-209", "#496", "#49")) {
    expect_true(grepl(tok, reg, fixed = TRUE),
                info = paste0("boundary register drops the citation: ", tok))
  }
  # And each entry must say what to do instead -- a boundary that only says
  # "not supported" is the gap restated.
  expect_equal(
    length(gregexpr("What to do instead today", reg, fixed = TRUE)[[1]]),
    5L # sections 1, 2, 3, 4 and 6; section 5 states its remedy inside the fence
  )
})

test_that("the cross-family fence still refuses natively (D-179 #3)", {
  set.seed(3)
  n <- 40L
  x <- stats::rnorm(n)
  d <- data.frame(
    y1 = 0.4 + 0.9 * x + stats::rnorm(n),
    y2 = stats::rpois(n, exp(0.3 + 0.2 * x)),
    x = x
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, rho12 = ~1),
      family = c(stats::gaussian(), stats::poisson()),
      data = d,
      engine = "tmb"
    ),
    "Mixed-response bivariate families are not implemented yet"
  )
})

test_that("the non-Gaussian observed-response mask fence still refuses on the bridge", {
  set.seed(4)
  n <- 40L
  x <- stats::rnorm(n)
  y <- stats::rpois(n, exp(0.6 + 0.4 * x))
  y[1:4] <- NA
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::poisson(),
      data = data.frame(y = y, x = x),
      engine = "julia",
      missing = miss_control(response = "include")
    ),
    "does not support this .*missing.* route yet"
  )
})

test_that("the mi() bridge fence still refuses before any Julia session (D-181 #1 / D-209)", {
  set.seed(5)
  n <- 40L
  x <- stats::rnorm(n)
  xm <- x
  xm[1:4] <- NA
  d <- data.frame(y = 0.3 + 0.5 * x + stats::rnorm(n), x = xm)
  expect_error(
    drmTMB(
      bf(y ~ mi(x)),
      family = stats::gaussian(),
      data = d,
      engine = "julia",
      impute = list(x = ~1)
    ),
    "requires missing = |Could not prepare the Julia joint missing-predictor model"
  )
})
