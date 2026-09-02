test_that("check_drm() reports hessian_conditioning as an ok row for a well-conditioned fit", {
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )

  chk <- check_drm(fit)
  row <- chk[chk$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "ok")
  expect_match(row$value, "min_eig=")
  expect_match(row$value, "cond=")

  # existing checks are untouched (additive only)
  expect_true("hessian_positive_definite" %in% chk$check)
})

test_that("check_drm() separates a well-conditioned fit from a genuinely ill-conditioned one", {
  set.seed(20260901)
  n <- 80
  x1 <- stats::rnorm(n)
  # x2 near-duplicates x1: near-perfect collinearity in the mu design.
  x2 <- x1 + stats::rnorm(n, sd = 1e-8)
  y <- 0.5 + 0.3 * x1 + stats::rnorm(n, sd = 0.5)
  dat <- data.frame(y = y, x1 = x1, x2 = x2)

  good_fit <- drmTMB(
    bf(y ~ x1, sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  ill_fit <- drmTMB(
    bf(y ~ x1 + x2, sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  good_row <- check_drm(good_fit)
  good_row <- good_row[good_row$check == "hessian_conditioning", ]
  ill_row <- check_drm(ill_fit)
  ill_row <- ill_row[ill_row$check == "hessian_conditioning", ]

  extract_cond <- function(value) {
    as.numeric(sub(".*cond=([^;]+).*", "\\1", value))
  }
  good_cond <- extract_cond(good_row$value)
  ill_cond <- extract_cond(ill_row$value)

  expect_true(is.finite(good_cond))
  expect_true(ill_cond > good_cond)
  expect_equal(ill_row$status, "warning")
})

test_that("check_drm() reports hessian_conditioning as a note when the TMB object is not retained", {
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(40),
    x = stats::rnorm(40)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = FALSE)
  )

  chk <- check_drm(fit)
  row <- chk[chk$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "note")
  expect_true(is.na(row$value))
  expect_match(row$message, "not retained")
})

test_that("check_drm() reports hessian_conditioning as a warning when obj$he() errors", {
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(40),
    x = stats::rnorm(40)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  broken <- fit
  broken$obj$he <- function(par) stop("test hessian failure")
  chk <- check_drm(broken)
  row <- chk[chk$check == "hessian_conditioning", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "warning")
  expect_match(row$message, "test hessian failure")
})

test_that("check_drm() existing check names are unchanged by hessian_conditioning", {
  set.seed(20260901)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  expect_true(all(
    c(
      "optimizer_convergence",
      "optimizer_budget",
      "finite_objective",
      "fixed_gradient",
      "sdreport_status",
      "hessian_positive_definite",
      "hessian_conditioning",
      "standard_errors_finite",
      "dropped_rows",
      "positive_scale"
    ) %in%
      chk$check
  ))
})
