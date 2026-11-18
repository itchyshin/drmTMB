test_that("Julia admits only the matching Binomial spatial SD route", {
  levels <- paste0("s", 1:4)
  coords <- cbind(east = 1:4, north = c(0, 1, 0, -1))
  rownames(coords) <- levels
  data <- data.frame(
    site = factor(levels, levels = levels),
    x = c(-1, 1, -1, 1), z = c(-1, -1, 1, 1),
    y = c(0L, 1L, 1L, 0L)
  )
  formula <- bf(
    y ~ x + spatial(0 + x | site, coords = coords),
    sd(site, level = "spatial") ~ z
  )

  expect_true(drm_julia_binomial_spatial_sd_route_admitted(formula))
  expect_no_error(drm_julia_refuse_binomial_nonlogit_sd(
    formula, stats::binomial(link = "probit")
  ))
  expect_no_error(drm_julia_refuse_binomial_nonlogit_sd(
    formula, stats::binomial(link = "cloglog")
  ))
  payload <- drm_julia_structured_payload(
    formula, "binomial", data, environment()
  )
  expect_match(payload$formula[[1L]], "relmat\\(0 \\+ x \\| site\\)")
  expect_identical(payload$formula[[2L]], "sd(site, relmat) ~ z")
  expected_precision <- drm_spatial_coords_precision(
    coords, site = data$site, group = "site"
  )$precision
  expect_equal(unname(payload$matrix),
               unname(solve(as.matrix(expected_precision))))
  expect_identical(payload$kwarg, "K")
  expect_true("sd" %in% names(payload$coef_labels))
  target <- parse_sd_lhs(formula$entries[[2L]]$lhs)
  fit_stub <- list(formula = formula, coefficients = list(mu = 0, sd = 0))
  expect_identical(drm_julia_sd_fit_block(fit_stub, target), "sd")
  expect_named(drm_julia_lss_dpar_aliases(fit_stub), "sd_spatial(site)")

  intercept_slope <- bf(
    y ~ x + spatial(1 + x | site, coords = coords),
    sd(site, level = "spatial") ~ z
  )
  extra_iid <- bf(
    y ~ x + (1 | observer) + spatial(0 + x | site, coords = coords),
    sd(site, level = "spatial") ~ z
  )
  wrong_group <- bf(
    y ~ x + spatial(0 + x | site, coords = coords),
    sd(other, level = "spatial") ~ z
  )
  expect_false(drm_julia_binomial_spatial_sd_route_admitted(intercept_slope))
  expect_false(drm_julia_binomial_spatial_sd_route_admitted(extra_iid))
  expect_false(drm_julia_binomial_spatial_sd_route_admitted(wrong_group))
})

test_that("Julia and TMB fit Binomial spatial slope SD regression for each link", {
  skip_on_cran()
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")

  set.seed(20261030L)
  n_site <- 64L
  n_each <- 48L
  site_levels <- paste0("s", seq_len(n_site))
  axis <- seq(0, 1, length.out = n_site)
  coords <- cbind(east = axis, north = sin(2 * pi * axis))
  rownames(coords) <- site_levels
  precision <- drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  covariance <- solve(as.matrix(precision$precision))
  dimnames(covariance) <- list(site_levels, site_levels)
  z_site <- sample(rep(c(-1, 1), length.out = n_site))
  alpha <- c(`(Intercept)` = log(0.55), z = 0.5)
  site_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_site)
  latent <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_site))
  site_index <- rep(seq_len(n_site), each = n_each)
  site <- factor(site_levels[site_index], levels = site_levels)
  x <- rep(seq(-1.5, 1.5, length.out = n_each), times = n_site)
  eta <- -0.2 + 0.25 * x + x * (site_sd * latent)[site_index]
  dat <- data.frame(site, x, z = z_site[site_index], y = 0L)
  form <- bf(
    y ~ x + spatial(0 + x | site, coords = coords),
    sd(site, level = "spatial") ~ z
  )

  logit_fit <- NULL
  for (link in c("logit", "probit", "cloglog")) {
    probability <- switch(
      link,
      logit = stats::plogis(eta),
      probit = stats::pnorm(eta),
      cloglog = -expm1(-exp(eta))
    )
    set.seed(20261031L)
    dat$y <- stats::rbinom(length(site_index), 1L, probability)
    family <- stats::binomial(link = link)
    fit_julia <- drmTMB(form, family = family, data = dat, engine = "julia")
    fit_tmb <- drmTMB(
      form, family = family, data = dat, engine = "tmb",
      control = drm_control(se = FALSE)
    )
    julia_coef <- coef(fit_julia, "sd_spatial(site)")
    tmb_coef <- coef(fit_tmb, "sd_spatial(site)")
    julia_sd <- predict(fit_julia, dpar = "sd_spatial(site)")
    tmb_sd <- predict(fit_tmb, dpar = "sd_spatial(site)")
    names(julia_sd) <- sub("^sd_spatial\\(site\\):", "", names(julia_sd))
    names(tmb_sd) <- sub("^sd_spatial\\(site\\):", "", names(tmb_sd))

    expect_equal(fit_tmb$opt$convergence, 0L, info = link)
    expect_equal(fit_julia$opt$convergence, 0L, info = link)
    expect_equal(unname(julia_coef), unname(tmb_coef), tolerance = 0.1,
                 info = link)
    expect_lt(abs(julia_coef[["z"]] - alpha[["z"]]), 0.45)
    expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
                 tolerance = 0.1, info = link)
    expect_setequal(names(julia_sd), names(tmb_sd))
    expect_equal(unname(julia_sd[names(tmb_sd)]), unname(tmb_sd),
                 tolerance = 0.1, info = link)
    if (identical(link, "logit")) logit_fit <- fit_julia
  }

  simulation_seed <- 20261032L
  draws <- simulate(logit_fit, nsim = 1L, seed = simulation_seed)
  draws_repeat <- simulate(logit_fit, nsim = 1L, seed = simulation_seed)
  expect_identical(draws$sim_1, draws_repeat$sim_1)
  expect_length(draws$sim_1, nrow(logit_fit$data))
  expect_true(all(draws$sim_1 %in% c(0L, 1L)))
})
