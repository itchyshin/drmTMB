# Regression tests for convergence-honesty triage F:
# #1470 rank-deficient distributional designs, #1496 dispersion-limit
# Wald standard errors, and #1251 scale-aware Hessian conditioning.

test_that("exact aliased columns are refused on every distributional design", {
  dat <- data.frame(
    y = stats::rnorm(30),
    x = seq(-1, 1, length.out = 30)
  )
  dat$xdup <- dat$x
  dat$x2 <- 2 * dat$x

  expect_error(
    drmTMB(bf(y ~ 1, sigma ~ x + xdup), data = dat),
    class = "drmTMB_rank_deficient_design"
  )
  expect_error(
    drmTMB(bf(y ~ x + xdup, sigma ~ 1), data = dat),
    "rank deficient"
  )
  expect_error(
    drmTMB(bf(y ~ 1, sigma ~ x + x2), data = dat),
    "x2"
  )
  expect_error(
    drmTMB(
      bf(y ~ 1, sigma ~ 1, nu ~ x + xdup),
      family = student(),
      data = dat
    ),
    "nu:"
  )

  biv <- data.frame(
    y1 = stats::rnorm(24),
    y2 = stats::rnorm(24),
    x = dat$x[seq_len(24)],
    xdup = dat$x[seq_len(24)]
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ 1,
        mu2 = y2 ~ 1,
        sigma1 = ~ 1,
        sigma2 = ~ 1,
        rho12 = ~ x + xdup
      ),
      family = biv_gaussian(),
      data = biv
    ),
    "rho12:"
  )

  X_sd <- cbind(`(Intercept)` = 1, x = dat$x, xdup = dat$xdup)
  expect_error(
    drmTMB:::drm_abort_rank_deficient_designs(list(sd_mu = X_sd)),
    "sd_mu"
  )

  expect_error(
    drmTMB:::drm_julia_bridge_payload_coef_labels(
      bf(y ~ 1, sigma ~ x + xdup),
      data = dat,
      env = environment()
    ),
    class = "drmTMB_rank_deficient_design"
  )

  dat$xnear <- dat$x + stats::rnorm(nrow(dat), sd = 1e-7)
  near <- suppressWarnings(drmTMB(
    bf(y ~ 1, sigma ~ x + xnear),
    data = dat
  ))
  expect_s3_class(near, "drmTMB")
  full <- drmTMB(bf(y ~ 1, sigma ~ x), data = dat)
  # Clean full-rank fit. This test does not add an absolute gradient cutoff.
  # The scale-free rule, max |cov.fixed %*% gradient| / SE > 1e-3, with a
  # 1e-3 absolute fallback only when there is no Hessian, is #1452 on PR #1503.
  expect_true(is_converged(full))
})

test_that("Poisson-limit dispersion coefficients are flagged, not given a usable Wald SE", {
  data(InsectSprays, package = "datasets")
  sprays <- drmTMB(
    bf(count ~ spray, sigma ~ spray),
    family = nbinom2(),
    data = InsectSprays
  )
  spray_e <- unname(coef(sprays, "sigma")[["sprayE"]])
  expect_lt(spray_e, log(sqrt(1e-3)))

  # expect_warning() returns the condition, not the value.
  expect_warning(
    sm <- summary(sprays),
    class = "drmTMB_dispersion_boundary_warning"
  )
  expect_true(is.na(sm$coefficients["sigma:sprayE", "std_error"]))
  expect_equal(sm$coefficients["sigma:sprayE", "estimate"], spray_e)
  other <- setdiff(grep("^sigma:", rownames(sm$coefficients), value = TRUE), "sigma:sprayE")
  expect_true(all(is.finite(sm$coefficients[other, "std_error"])))
  expect_true(is.finite(stats::vcov(sprays)["sigma:sprayE", "sigma:sprayE"]))

  expect_warning(
    ci <- confint(sprays, parm = "fixef:sigma:sprayE"),
    class = "drmTMB_dispersion_boundary_warning"
  )
  expect_equal(ci$conf.status, "boundary_limit")
  expect_equal(ci$interval_source, "not_available")
  expect_true(is.na(ci$lower) && is.na(ci$upper))

  profile_table <- ci
  profile_table$method <- "profile"
  profile_table$conf.status <- "profile"
  profile_table$interval_source <- "profile"
  profile_table$lower <- -1
  profile_table$upper <- 1
  kept <- drmTMB:::drm_mask_dispersion_boundary_confint(
    sprays,
    profile_table,
    warn = FALSE
  )
  expect_equal(kept$lower, -1)
  expect_equal(kept$upper, 1)
  expect_equal(kept$conf.status, "profile")
  expect_equal(kept$interval_source, "profile")

  bootstrap_table <- profile_table
  bootstrap_table$method <- "bootstrap"
  bootstrap_table$conf.status <- "bootstrap"
  bootstrap_table$interval_source <- "bootstrap"
  kept_boot <- drmTMB:::drm_mask_dispersion_boundary_confint(
    sprays,
    bootstrap_table,
    warn = FALSE
  )
  expect_equal(kept_boot$conf.status, "bootstrap")
  expect_equal(kept_boot$lower, -1)

  chk <- check_drm(sprays)
  boundary <- chk[chk$check == "dispersion_boundary", ]
  expect_equal(boundary$status, "warning")
  expect_false(attr(chk, "ok"))
  expect_message(print(sprays), "dispersion boundary")

  flat <- data.frame(y = rep(5L, 40))
  intercept <- drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = flat
  )
  expect_warning(
    sm_intercept <- summary(intercept),
    class = "drmTMB_dispersion_boundary_warning"
  )
  expect_true(is.na(sm_intercept$coefficients["sigma:(Intercept)", "std_error"]))
  sigma_row <- sm_intercept$parameters$parm == "sigma"
  expect_true(is.na(sm_intercept$parameters$std_error[sigma_row]))

  set.seed(1496)
  n <- 80
  x <- stats::rnorm(n)
  mu <- exp(0.4 + 0.3 * x)
  dispersed <- data.frame(
    y = stats::rnbinom(n, mu = mu, size = 1 / 0.8^2),
    x = x
  )
  ordinary <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = nbinom2(),
    data = dispersed
  )
  ordinary_check <- check_drm(ordinary)
  expect_equal(
    ordinary_check$status[ordinary_check$check == "dispersion_boundary"],
    "ok"
  )
  expect_true(all(is.finite(summary(ordinary)$coefficients$std_error)))
})

test_that("dispersion-limit detection covers sibling families without changing estimates", {
  limit_sigma <- function(model_type) {
    X <- matrix(1, 4, 1, dimnames = list(NULL, "(Intercept)"))
    list(
      model = list(
        model_type = model_type,
        X = list(sigma = X, mu = X)
      ),
      coefficients = list(
        sigma = c(`(Intercept)` = -8),
        mu = c(`(Intercept)` = 0)
      )
    )
  }
  for (model_type in c(
    "nbinom2",
    "zi_nbinom2",
    "hurdle_nbinom2",
    "truncated_nbinom2"
  )) {
    report <- drmTMB:::drm_dispersion_boundary_report(limit_sigma(model_type))
    expect_true(isTRUE(report$at_limit), info = model_type)
    expect_true("sigma:(Intercept)" %in% report$coefficient_rows, info = model_type)
  }
  for (model_type in c("beta", "beta_binomial", "zero_one_beta")) {
    expect_null(
      drmTMB:::drm_dispersion_boundary_report(limit_sigma(model_type)),
      info = model_type
    )
  }

  student <- list(
    model = list(
      model_type = "student",
      X = list(nu = matrix(1, 3, 1, dimnames = list(NULL, "(Intercept)")))
    ),
    coefficients = list(nu = c(`(Intercept)` = 8))
  )
  student_report <- drmTMB:::drm_dispersion_boundary_report(student)
  expect_true(student_report$at_limit)
  expect_true("nu:(Intercept)" %in% student_report$coefficient_rows)

  biv <- list(
    model = list(
      model_type = "biv_student",
      X = list(nu1 = matrix(1, 3, 1, dimnames = list(NULL, "(Intercept)")))
    ),
    coefficients = list(nu1 = c(`(Intercept)` = 8))
  )
  biv_report <- drmTMB:::drm_dispersion_boundary_report(biv)
  expect_true(biv_report$at_limit)
  expect_true("nu1:(Intercept)" %in% biv_report$coefficient_rows)

  partial <- list(
    model = list(
      model_type = "nbinom2",
      X = list(
        sigma = cbind(`(Intercept)` = 1, x = c(0, 1)),
        mu = cbind(`(Intercept)` = 1, x = c(0, 0))
      )
    ),
    coefficients = list(
      sigma = c(`(Intercept)` = -8, x = 12),
      mu = c(`(Intercept)` = 1, x = 0)
    )
  )
  partial_report <- drmTMB:::drm_dispersion_boundary_report(partial)
  expect_true(partial_report$at_limit)
  expect_length(partial_report$coefficient_rows, 0L)

  expect_null(drmTMB:::drm_dispersion_boundary_report(list(
    model = list(
      model_type = "gaussian",
      X = list(sigma = matrix(1, 2, 1, dimnames = list(NULL, "(Intercept)")))
    ),
    coefficients = list(sigma = c(`(Intercept)` = -8))
  )))
  expect_null(drmTMB:::drm_dispersion_boundary_report(list(
    model = list(
      model_type = "gamma",
      X = list(sigma = matrix(1, 2, 1, dimnames = list(NULL, "(Intercept)")))
    ),
    coefficients = list(sigma = c(`(Intercept)` = -8))
  )))
})

test_that("clean airquality location-scale conditioning is ok and a collinear design still notes", {
  aq <- na.omit(airquality)
  clean <- drmTMB(
    bf(Ozone ~ Temp + Wind, sigma ~ Temp),
    data = aq
  )
  clean_row <- check_drm(clean)
  clean_row <- clean_row[clean_row$check == "hessian_conditioning", ]
  expect_equal(clean_row$status, "ok")
  expect_match(clean_row$message, "correlation-scaled")

  set.seed(1251)
  n <- 80
  x <- stats::rnorm(n)
  x2 <- x + stats::rnorm(n, sd = 1e-6)
  y <- 0.2 + 0.5 * x + stats::rnorm(n, sd = 0.4)
  ill <- drmTMB(
    bf(y ~ x + x2, sigma ~ 1),
    data = data.frame(y = y, x = x, x2 = x2)
  )
  testthat::skip_if_not(
    isTRUE(ill$sdr$pdHess),
    "platform LAPACK did not return a positive-definite Hessian for the ill-conditioned fixture"
  )
  ill_row <- check_drm(ill)
  ill_row <- ill_row[ill_row$check == "hessian_conditioning", ]
  expect_equal(ill_row$status, "note")
  expect_match(ill_row$message, "correlation-scaled")
  expect_match(ill_row$value, "cond=")
})

test_that("scale-free NB2 limit keeps a well-identified fit and drops beta", {
  well <- list(
    model = list(
      model_type = "nbinom2",
      X = list(
        sigma = matrix(1, 4, 1, dimnames = list(NULL, "(Intercept)")),
        mu = matrix(1, 4, 1, dimnames = list(NULL, "(Intercept)"))
      )
    ),
    coefficients = list(
      sigma = c(`(Intercept)` = 0.5 * log(1 / 2000)),
      mu = c(`(Intercept)` = log(1000))
    )
  )
  well_report <- drmTMB:::drm_dispersion_boundary_report(well)
  expect_false(well_report$at_limit)
  expect_length(well_report$coefficient_rows, 0L)

  set.seed(1496)
  n <- 400
  y <- stats::rnbinom(n, mu = 1000, size = 2000)
  identified <- drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = data.frame(y = y)
  )
  mu_hat <- unname(exp(coef(identified, "mu")[["(Intercept)"]]))
  sigma2_hat <- unname(exp(2 * coef(identified, "sigma")[["(Intercept)"]]))
  expect_gt(mu_hat * sigma2_hat, 0.1)
  identified_check <- check_drm(identified)
  expect_equal(
    identified_check$status[identified_check$check == "dispersion_boundary"],
    "ok"
  )
  sm <- summary(identified)
  expect_true(is.finite(sm$coefficients["sigma:(Intercept)", "std_error"]))
  expect_lt(sm$coefficients["sigma:(Intercept)", "std_error"], 1)

  set.seed(1496)
  phi <- 5000
  mu <- 0.4
  beta_y <- stats::rbeta(200, mu * phi, (1 - mu) * phi)
  beta_fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = beta_family(),
    data = data.frame(y = beta_y)
  )
  expect_null(drmTMB:::drm_dispersion_boundary_report(beta_fit))
  beta_sm <- summary(beta_fit)
  expect_true(is.finite(beta_sm$coefficients["sigma:(Intercept)", "std_error"]))
  expect_lt(beta_sm$coefficients["sigma:(Intercept)", "std_error"], 1)
})

test_that("boundary_limit rows are unavailable to parameter and corpair plots", {
  expect_true("boundary_limit" %in% drmTMB:::interval_status_levels())

  surface <- data.frame(
    conf.status = c("wald", "boundary_limit"),
    interval_source = c("wald", "not_available"),
    conf.low = c(0, NA),
    conf.high = c(1, NA),
    stringsAsFactors = FALSE
  )
  expect_equal(
    drmTMB:::plot_parameter_surface_interval_available(surface),
    c(TRUE, FALSE)
  )

  pairs <- data.frame(
    conf.low = c(0, NA),
    conf.high = c(1, NA),
    .drmTMB_conf_status = c("wald", "boundary_limit"),
    .drmTMB_interval_source = c("wald", "not_available"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  expect_equal(
    drmTMB:::plot_corpairs_interval_available(pairs),
    c(TRUE, FALSE)
  )
})

test_that("rank check uses complete cases, sparse QR, and the Julia cross-family designs", {
  X_na <- cbind(
    `(Intercept)` = 1,
    x = c(1, 2, NA),
    xdup = c(1, 2, NA)
  )
  expect_error(
    drmTMB:::drm_abort_rank_deficient_designs(list(mu = X_na)),
    class = "drmTMB_rank_deficient_design"
  )
  X_full <- cbind(a = c(1, 2, NA), b = c(0, 1, 4))
  expect_length(drmTMB:::drm_aliased_columns(X_full), 0L)

  A <- Matrix::rsparsematrix(12, 3, density = 0.8)
  A <- cbind(A, A[, 1] + A[, 2])
  colnames(A) <- c("a", "b", "c", "ab")
  aliased <- drmTMB:::drm_aliased_columns(A)
  expect_true("ab" %in% aliased)

  dat <- data.frame(
    y = stats::rnorm(12),
    x = c(1:6, 1:6),
    xdup = c(1:6, 1:6)
  )
  expect_error(
    drmTMB:::drm_julia_xfam_axis(
      list(response = "y", rhs = quote(x + xdup), dpar = "mu1"),
      data = dat,
      env = environment(),
      dpar = "mu1"
    ),
    class = "drmTMB_rank_deficient_design"
  )
  expect_error(
    drmTMB:::drm_julia_xfam_sigma(
      list(response = NA_character_, rhs = quote(x + xdup), dpar = "sigma1"),
      mu = list(y = dat$y, response = "y"),
      tag = "gaussian",
      data = dat,
      env = environment(),
      dpar = "sigma1"
    ),
    class = "drmTMB_rank_deficient_design"
  )
})
