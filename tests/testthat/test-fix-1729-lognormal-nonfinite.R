# Inf in a lognormal mu or sigma design must abort in drmTMB before lm.fit
# or nlminb, and the message must name the column (#1729). NA in a predictor
# stays on the complete-case path.

lognormal_nonfinite_case <- function(dpar) {
  set.seed(1729)
  d <- data.frame(
    y = exp(stats::rnorm(24)),
    x = stats::rnorm(24),
    z = stats::rnorm(24)
  )
  if (identical(dpar, "mu")) {
    d$x[1] <- Inf
    formula <- bf(y ~ x, sigma ~ 1)
    column <- "\\bx\\b"
  } else {
    d$z[1] <- Inf
    formula <- bf(y ~ 1, sigma ~ z)
    column <- "\\bz\\b"
  }
  list(data = d, formula = formula, column = column, dpar = dpar)
}

test_that("lognormal #1729: Inf in a mu predictor aborts and names the column", {
  case <- lognormal_nonfinite_case("mu")
  err <- expect_error(
    drmTMB(
      case$formula,
      family = lognormal(),
      data = case$data,
      control = drm_control(se = FALSE)
    ),
    class = "rlang_error"
  )
  msg <- conditionMessage(err)
  expect_match(msg, "Lognormal models require finite fixed-effect design values")
  expect_match(msg, case$column)
  expect_match(msg, "dpar = \"mu\"", fixed = TRUE)
})

test_that("lognormal #1729: Inf in a sigma predictor aborts and names the column", {
  case <- lognormal_nonfinite_case("sigma")
  err <- expect_error(
    drmTMB(
      case$formula,
      family = lognormal(),
      data = case$data,
      control = drm_control(se = FALSE)
    ),
    class = "rlang_error"
  )
  msg <- conditionMessage(err)
  expect_match(msg, "Lognormal models require finite fixed-effect design values")
  expect_match(msg, case$column)
  expect_match(msg, "dpar = \"sigma\"", fixed = TRUE)
})

test_that("lognormal #1729: NA in a predictor stays dropped", {
  set.seed(1729)
  d <- data.frame(y = exp(stats::rnorm(24)), x = stats::rnorm(24))
  d$x[1] <- NA_real_
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = lognormal(),
    data = d,
    control = drm_control(se = FALSE)
  )
  expect_equal(nobs(fit), 23L)
})