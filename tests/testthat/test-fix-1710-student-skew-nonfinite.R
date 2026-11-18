# Inf in a Student-t or skew-normal fixed-effect design must abort in drmTMB
# before lm.fit or nlminb. NA in a predictor stays on the existing
# complete-case path (#1710).

nonfinite_design_case <- function(family, dpar) {
  set.seed(1)
  d <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20), z = stats::rnorm(20))
  if (dpar == "mu") {
    d$x[1] <- Inf
    formula <- bf(y ~ x, sigma ~ 1, nu ~ 1)
    column <- "\\bx\\b"
  } else if (dpar == "sigma") {
    d$z[1] <- Inf
    formula <- bf(y ~ 1, sigma ~ z, nu ~ 1)
    column <- "\\bz\\b"
  } else {
    d$z[1] <- Inf
    formula <- bf(y ~ 1, sigma ~ 1, nu ~ z)
    column <- "\\bz\\b"
  }
  list(data = d, formula = formula, column = column, family = family, dpar = dpar)
}

expect_nonfinite_design_abort <- function(family, family_label, dpar) {
  case <- nonfinite_design_case(family, dpar)
  err <- expect_error(
    drmTMB(
      case$formula,
      family = case$family,
      data = case$data,
      control = drm_control(se = FALSE)
    ),
    class = "rlang_error"
  )
  expect_match(
    conditionMessage(err),
    sprintf("%s models require finite fixed-effect design values", family_label)
  )
  expect_match(conditionMessage(err), case$column)
  expect_match(conditionMessage(err), sprintf("dpar = \"%s\"", dpar), fixed = TRUE)
}

test_that("student #1710: Inf in a mu predictor aborts and names the column", {
  expect_nonfinite_design_abort(student(), "Student-t", "mu")
})

test_that("student #1710: Inf in a sigma predictor aborts and names the column", {
  expect_nonfinite_design_abort(student(), "Student-t", "sigma")
})

test_that("student #1710: Inf in a nu predictor aborts and names the column", {
  expect_nonfinite_design_abort(student(), "Student-t", "nu")
})

test_that("skew-normal #1710: Inf in a mu predictor aborts and names the column", {
  expect_nonfinite_design_abort(skew_normal(), "skew-normal", "mu")
})

test_that("skew-normal #1710: Inf in a sigma predictor aborts and names the column", {
  expect_nonfinite_design_abort(skew_normal(), "skew-normal", "sigma")
})

test_that("skew-normal #1710: Inf in a nu predictor aborts and names the column", {
  expect_nonfinite_design_abort(skew_normal(), "skew-normal", "nu")
})

test_that("student #1710: NA in a predictor stays dropped", {
  set.seed(1)
  d <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  d$x[1] <- NA_real_
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = student(),
    data = d,
    control = drm_control(se = FALSE)
  )
  expect_equal(nobs(fit), 19L)
})

test_that("skew-normal #1710: NA in a predictor stays dropped", {
  set.seed(1)
  d <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  d$x[1] <- NA_real_
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = skew_normal(),
    data = d,
    control = drm_control(se = FALSE)
  )
  expect_equal(nobs(fit), 19L)
})
