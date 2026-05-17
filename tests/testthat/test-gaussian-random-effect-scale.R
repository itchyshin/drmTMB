test_that("Gaussian sd(id) models recover a group-level random-intercept scale slope", {
  sim <- new_gaussian_re_scale_data()

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = sim$data
  )

  sd_hat <- predict(fit, dpar = "sd(id)")

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_lt(max(abs(unname(coef(fit, "mu")) - unname(sim$beta_mu))), 0.22)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - unname(sim$beta_sigma))), 0.18)
  expect_lt(max(abs(unname(coef(fit, "sd(id)")) - unname(sim$alpha))), 0.35)
  expect_true(all(sd_hat > 0))
  expect_equal(length(sd_hat), nlevels(sim$data$id))
  expect_gt(stats::cor(log(sd_hat), log(sim$tau_id)), 0.70)
  expect_named(fit$sdpars, "sd(id)")
  expect_false("mu" %in% names(fit$sdpars))
})

test_that("Gaussian sd(id) coefficients have aligned summary and vcov entries", {
  sim <- new_gaussian_re_scale_data(seed = 20260556)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = sim$data
  )
  vc <- stats::vcov(fit)
  smry <- summary(fit)

  expect_true(all(c("sd(id):(Intercept)", "sd(id):w") %in% rownames(vc)))
  expect_true(all(
    c("sd(id):(Intercept)", "sd(id):w") %in% rownames(smry$coefficients)
  ))
  expect_true(all(is.finite(diag(vc)[c("sd(id):(Intercept)", "sd(id):w")])))
  expect_true(all(
    smry$coefficients[c("sd(id):(Intercept)", "sd(id):w"), "std_error"] > 0
  ))
  expect_equal(
    smry$coefficients[c("sd(id):(Intercept)", "sd(id):w"), "estimate"],
    unname(coef(fit, "sd(id)")),
    ignore_attr = TRUE
  )
})

test_that("Gaussian sd(id) targets the correct coefficient after preceding blocks", {
  sim <- new_gaussian_re_scale_data(n_id = 24, n_each = 6, seed = 20260557)
  dat <- sim$data
  site_by_id <- factor(rep(letters[1:6], length.out = nlevels(dat$id)))
  dat$site <- site_by_id[dat$id]
  site_levels <- levels(dat$site)
  u0_site <- stats::rnorm(length(site_levels), sd = 0.25)
  u1_site <- stats::rnorm(length(site_levels), sd = 0.15)
  dat$y <- dat$y + u0_site[dat$site] + u1_site[dat$site] * dat$x

  fit <- drmTMB(
    bf(y ~ x + (1 + x | site) + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = dat
  )

  target_coef <- match("(1 | id)", fit$model$random$mu$labels)
  target_re <- which(fit$model$random$mu$term_id0 == target_coef - 1L)
  non_target_re <- setdiff(seq_len(fit$model$random$mu$n_re), target_re)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(unname(fit$model$random_scale$mu$target_coef), target_coef)
  expect_true(all(fit$model$random_scale$mu$re_sd_row0[target_re] >= 0))
  expect_true(all(fit$model$random_scale$mu$re_sd_row0[non_target_re] < 0))
  expect_equal(length(predict(fit, dpar = "sd(id)")), nlevels(dat$id))
})

test_that("Gaussian supports multiple random-effect scale formulas", {
  sim <- new_gaussian_multi_re_scale_data()

  fit <- drmTMB(
    bf(
      y ~ x + (1 | id) + (1 | site),
      sigma ~ z,
      sd(id) ~ w_id,
      sd(site) ~ w_site
    ),
    family = gaussian(),
    data = sim$data
  )

  sd_id <- predict(fit, dpar = "sd(id)")
  sd_site <- predict(fit, dpar = "sd(site)")

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(fit$coefficients, c("mu", "sigma", "sd(id)", "sd(site)"))
  expect_named(fit$sdpars, c("sd(id)", "sd(site)"))
  expect_false("mu" %in% names(fit$sdpars))
  expect_equal(length(sd_id), nlevels(sim$data$id))
  expect_equal(length(sd_site), nlevels(sim$data$site))
  expect_true(all(sd_id > 0))
  expect_true(all(sd_site > 0))
  expect_gt(stats::cor(log(sd_id), log(sim$tau_id)), 0.45)
  expect_gt(stats::cor(log(sd_site), log(sim$tau_site)), 0.35)
  expect_lt(max(abs(unname(coef(fit, "sd(id)")) - unname(sim$alpha_id))), 0.45)
  expect_lt(
    max(abs(unname(coef(fit, "sd(site)")) - unname(sim$alpha_site))),
    0.55
  )
})

test_that("Gaussian sd(id) reduces to constant random-intercept scale when slope is zero", {
  sim <- new_gaussian_re_scale_data(
    alpha = c(`(Intercept)` = log(0.6), w = 0),
    seed = 20260551
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(abs(coef(fit, "sd(id)")[[1L]] - sim$alpha[[1L]]), 0.30)
  expect_lt(abs(coef(fit, "sd(id)")[[2L]]), 0.30)
  expect_true(all(predict(fit, dpar = "sd(id)") > 0))
})

test_that("Gaussian sd(id) handles large scale slopes and factor predictors", {
  sim_large <- new_gaussian_re_scale_data(
    n_id = 56,
    n_each = 8,
    alpha = c(`(Intercept)` = log(0.45), w = 0.85),
    seed = 20260552
  )

  fit_large <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = sim_large$data
  )
  sd_large <- predict(fit_large, dpar = "sd(id)")

  expect_equal(fit_large$opt$convergence, 0)
  expect_true(all(is.finite(c(coef(fit_large, "sd(id)"), sd_large))))
  expect_true(all(sd_large > 0))
  expect_gt(max(sd_large) / min(sd_large), 1.5)

  sim_factor <- new_gaussian_re_scale_data(factor_w = TRUE, seed = 20260553)
  fit_factor <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = sim_factor$data
  )

  expect_equal(fit_factor$opt$convergence, 0)
  expect_true("whigh" %in% names(coef(fit_factor, "sd(id)")))
  expect_gt(unname(coef(fit_factor, "sd(id)")["whigh"]), 0)
  expect_true(all(predict(fit_factor, dpar = "sd(id)") > 0))
})

test_that("Gaussian sd(id) prediction validates transformed newdata values", {
  sim <- new_gaussian_re_scale_data(n_id = 12, n_each = 4, seed = 20260561)
  dat <- transform(sim$data, w_pos = exp(w) + 0.2)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ log(w_pos)),
    family = gaussian(),
    data = dat,
    control = drm_control(optimizer = list(eval.max = 120L, iter.max = 120L))
  )

  expect_error(
    predict(
      fit,
      dpar = "sd(id)",
      newdata = data.frame(w_pos = 0),
      type = "link"
    ),
    "log\\(w_pos\\)"
  )
})

test_that("Gaussian sd(id) prediction validates factor levels in newdata", {
  sim <- new_gaussian_re_scale_data(
    n_id = 12,
    n_each = 4,
    factor_w = TRUE,
    seed = 20260562
  )
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 120L, iter.max = 120L))
  )
  high_factor <- data.frame(
    w = factor("high", levels = levels(sim$data$w))
  )

  expect_equal(
    predict(fit, dpar = "sd(id)", newdata = data.frame(w = "high")),
    predict(fit, dpar = "sd(id)", newdata = high_factor),
    ignore_attr = TRUE
  )
  expect_error(
    predict(fit, dpar = "sd(id)", newdata = data.frame(w = "medium")),
    "unknown factor level"
  )
})

test_that("Gaussian sd(id) variables participate in missingness", {
  sim <- new_gaussian_re_scale_data(n_id = 16, n_each = 5, seed = 20260554)
  dat <- sim$data
  dat$y[2] <- NA_real_
  dat$x[5] <- NA_real_
  dat$z[7] <- NA_real_
  dat$w[9] <- NA_real_
  dat$id[11] <- NA
  keep <- stats::complete.cases(dat[c("y", "x", "z", "w", "id")])

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_false(anyNA(fit$data[c("y", "x", "z", "w", "id")]))
})

test_that("Gaussian sd(id) rejects unsupported and ambiguous targets", {
  dat <- new_gaussian_re_scale_data(n_id = 8, n_each = 4, seed = 20260555)$data

  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z, sd(id) ~ w), family = gaussian(), data = dat),
    "No random-effect term matches"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ z, sd(site) ~ w),
      family = gaussian(),
      data = dat
    ),
    "No random-effect term matches"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | id), sigma ~ z, sd(id) ~ w),
      family = gaussian(),
      data = dat
    ),
    "Ambiguous random-effect scale target"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z, sd(id) ~ w),
      family = gaussian(),
      data = dat
    ),
    "Ambiguous random-effect scale target"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | p | id), sigma ~ z, sd(id) ~ w),
      family = gaussian(),
      data = dat
    ),
    "Labelled random-effect scale targets"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w, sd(id) ~ z),
      family = gaussian(),
      data = dat
    ),
    "Duplicate random-effect scale formula"
  )

  dat$w_obs <- stats::rnorm(nrow(dat))
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w_obs),
      family = gaussian(),
      data = dat
    ),
    "varies within"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x + (1 | id),
        sigma ~ z,
        sd(id, dpar = "mu", coef = "(Intercept)") ~ w
      ),
      family = gaussian(),
      data = dat
    ),
    "reserved but not implemented"
  )
  expect_error(
    bf(y ~ x + (1 | id), sd(id + site) ~ w),
    "simple grouping variable"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y ~ x,
        mu2 = z ~ x,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1,
        sd(id) ~ w
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "only support"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sd(id) ~ w),
      family = stats::poisson(),
      data = dat
    ),
    "Random-effect scale"
  )
})
