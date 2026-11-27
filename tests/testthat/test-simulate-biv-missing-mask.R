# Issue #1906: bivariate simulate() must mask missing-response rows like residuals().

missing_response_biv_gaussian_data_local <- function() {
  x <- seq(-1.5, 1.7, length.out = 36)
  i <- seq_along(x)
  y1 <- 0.4 + 0.8 * x + 0.16 * sin(0.7 * i)
  y2 <- -0.2 - 0.5 * x + 0.14 * cos(0.5 * i) + 0.04 * sin(0.9 * i)
  dat <- data.frame(y1 = y1, y2 = y2, x = x)
  dat$y1[c(5, 14, 29)] <- NA_real_
  dat$y2[c(8, 14, 31)] <- NA_real_
  dat
}

expect_biv_simulate_masks <- function(fit, observed_y1, observed_y2, seed) {
  sims <- stats::simulate(fit, nsim = 2L, seed = seed, re.form = NULL)
  y1_cols <- grep("_y1$", names(sims), value = TRUE)
  y2_cols <- grep("_y2$", names(sims), value = TRUE)
  for (col in y1_cols) {
    expect_true(all(is.na(sims[!observed_y1, col])))
    expect_true(all(!is.na(sims[observed_y1, col])))
  }
  for (col in y2_cols) {
    expect_true(all(is.na(sims[!observed_y2, col])))
    expect_true(all(!is.na(sims[observed_y2, col])))
  }
}

test_that("#1906: biv_lognormal simulate() masks missing y1 and y2", {
  set.seed(19061L)
  n <- 40L
  x <- stats::rnorm(n)
  dat <- data.frame(
    x = x,
    y1 = exp(0.2 + 0.3 * x + 0.2 * stats::rnorm(n)),
    y2 = exp(-0.1 - 0.2 * x + 0.25 * stats::rnorm(n))
  )
  observed_y1 <- rep(TRUE, n)
  observed_y2 <- rep(TRUE, n)
  observed_y1[c(3L, 11L)] <- FALSE
  observed_y2[c(7L, 11L)] <- FALSE
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_lognormal(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit$missing_data <- list(
    response_policy = "include",
    observed_y1 = observed_y1,
    observed_y2 = observed_y2
  )
  expect_biv_simulate_masks(fit, observed_y1, observed_y2, seed = 1906L)
})

test_that("#1906: biv_student simulate() masks missing y1 and y2", {
  set.seed(19062L)
  n <- 40L
  x <- stats::rnorm(n)
  dat <- data.frame(
    x = x,
    y1 = 0.2 + 0.4 * x + 0.3 * stats::rnorm(n),
    y2 = -0.1 - 0.2 * x + 0.35 * stats::rnorm(n)
  )
  observed_y1 <- rep(TRUE, n)
  observed_y2 <- rep(TRUE, n)
  observed_y1[c(4L, 18L)] <- FALSE
  observed_y2[c(9L, 18L)] <- FALSE
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      nu = ~1,
      rho12 = ~1
    ),
    family = biv_student(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit$missing_data <- list(
    response_policy = "include",
    observed_y1 = observed_y1,
    observed_y2 = observed_y2
  )
  expect_biv_simulate_masks(fit, observed_y1, observed_y2, seed = 19063L)
})

test_that("drm_mask_biv_simulate_data_frame masks paired simulate columns", {
  object <- list(
    missing_data = list(
      response_policy = "include",
      observed_y1 = c(TRUE, FALSE, TRUE),
      observed_y2 = c(TRUE, TRUE, FALSE)
    )
  )
  sims <- data.frame(
    sim_1_y1 = c(1, 2, 3),
    sim_1_y2 = c(4, 5, 6),
    sim_2_y1 = c(7, 8, 9),
    sim_2_y2 = c(10, 11, 12)
  )
  masked <- drmTMB:::drm_mask_biv_simulate_data_frame(object, sims)
  expect_equal(masked$sim_1_y1, c(1, NA, 3))
  expect_equal(masked$sim_1_y2, c(4, 5, NA))
  expect_equal(masked$sim_2_y1, c(7, NA, 9))
  expect_equal(masked$sim_2_y2, c(10, 11, NA))
})