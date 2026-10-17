# #1454: miss_control() with NA in a predictor must fail closed on
# engine = "julia" before the bridge starts. On b0cf1d8a the Julia early
# return skips the A-2 check (R/drmTMB.R) and drm_julia_drop_missing_rows()
# silently listwise-deletes (t5 J6, 6/6 Gaussian cells). Red-proof: these
# assertions fail on that head and pass after the check is shared.

miss_control_na_x_data <- function() {
  set.seed(20261016L)
  d <- data.frame(
    y = stats::rnorm(20),
    x = stats::rnorm(20),
    g = gl(5L, 4L)
  )
  d$x[1L] <- NA_real_
  d
}

test_that("#1454 miss_control() with NA in x fails closed on engine=julia", {
  d <- miss_control_na_x_data()
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g), sigma ~ 1),
      family = gaussian(),
      data = d,
      engine = "julia",
      missing = miss_control()
    ),
    "requires complete predictors"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g), sigma ~ 1),
      family = gaussian(),
      data = d,
      engine = "julia",
      missing = miss_control(predictor = "fail")
    ),
    "Missing values in: \"x\"",
    fixed = TRUE
  )
})

test_that("#1454 Poisson miss_control() with NA in x fails for the predictor, not resd", {
  set.seed(3L)
  d <- data.frame(y = stats::rpois(20, 2), x = stats::rnorm(20), g = gl(5L, 4L))
  d$x[2L] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g)),
      family = poisson(link = "log"),
      data = d,
      engine = "julia",
      missing = miss_control()
    ),
    "requires complete predictors"
  )
})

test_that("#1454 omitted missing still reaches the Julia bridge (drop, not fail)", {
  d <- miss_control_na_x_data()
  reached <- FALSE
  local_mocked_bindings(
    drmTMB_julia_bridge = function(...) {
      reached <<- TRUE
      stop("bridge reached", call. = FALSE)
    }
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g), sigma ~ 1),
      family = gaussian(),
      data = d,
      engine = "julia"
    ),
    "bridge reached",
    fixed = TRUE
  )
  expect_true(reached)
})

test_that("#1454 stored miss_control() fails on julia like the literal call", {
  d <- miss_control_na_x_data()
  ctl <- miss_control()
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g), sigma ~ 1),
      family = gaussian(),
      data = d,
      engine = "julia",
      missing = ctl
    ),
    "requires complete predictors"
  )
})
