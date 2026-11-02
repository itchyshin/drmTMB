test_that("Julia admits only the matching Binomial relmat slope SD route", {
  id_levels <- paste0("id", 1:4)
  K <- diag(4L)
  dimnames(K) <- list(id_levels, id_levels)
  data <- data.frame(
    id = factor(rep(id_levels, each = 2L), levels = id_levels),
    x = rep(c(-1, 1), 4L),
    z = rep(c(-1, 1), each = 4L),
    y = c(0L, 1L, 1L, 0L, 1L, 0L, 0L, 1L)
  )
  formula <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )

  expect_true(drm_julia_binomial_relmat_sd_route_admitted(formula))
  payload <- drm_julia_structured_payload(
    formula, "binomial", data, environment()
  )
  expect_match(payload$formula[[1L]], "relmat\\(0 \\+ x \\| id\\)")
  expect_identical(payload$formula[[2L]], "sd(id, relmat) ~ z")
  expect_equal(unname(payload$matrix), unname(K))
  expect_true("sd" %in% names(payload$coef_labels))

  intercept_slope <- bf(
    y ~ x + relmat(1 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  extra_iid <- bf(
    y ~ x + (1 | site) + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  expect_false(drm_julia_binomial_relmat_sd_route_admitted(intercept_slope))
  expect_false(drm_julia_binomial_relmat_sd_route_admitted(extra_iid))
})

test_that("Julia and TMB fit Binomial relmat slope SD regression for each link", {
  skip_on_cran()
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")

  set.seed(20261028L)
  n_group <- 64L
  n_each <- 32L
  id_levels <- paste0("g", seq_len(n_group))
  marginal_scale <- seq(0.8, 1.6, length.out = n_group)
  correlation <- outer(seq_len(n_group), seq_len(n_group), function(i, j) {
    0.4^abs(i - j)
  })
  K <- outer(marginal_scale, marginal_scale) * correlation
  dimnames(K) <- list(id_levels, id_levels)
  z_group <- sample(rep(c(-1, 1), each = n_group / 2L))
  alpha <- c(`(Intercept)` = -0.75, z = 0.5)
  slope_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  unit_slope <- as.vector(t(chol(K)) %*% stats::rnorm(n_group))
  id_index <- rep(seq_len(n_group), each = n_each)
  id <- factor(id_levels[id_index], levels = id_levels)
  x <- rep(seq(-1.5, 1.5, length.out = n_each), times = n_group)
  eta <- -0.1 + 0.35 * x + x * (slope_sd * unit_slope)[id_index]
  dat <- data.frame(id, x, z = z_group[id_index], y = 0L)
  form <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )

  logit_fit <- NULL
  for (link in c("logit", "probit", "cloglog")) {
    probability <- switch(
      link,
      logit = stats::plogis(eta),
      probit = stats::pnorm(eta),
      cloglog = -expm1(-exp(eta))
    )
    set.seed(20261029L)
    dat$y <- stats::rbinom(length(id_index), 1L, probability)
    family <- stats::binomial(link = link)
    fit_julia <- drmTMB(form, family = family, data = dat, engine = "julia")
    fit_tmb <- drmTMB(
      form,
      family = family,
      data = dat,
      engine = "tmb",
      control = drm_control(se = FALSE)
    )
    julia_coef <- coef(fit_julia, "sd_relmat(id)")
    tmb_coef <- coef(fit_tmb, "sd_relmat(id)")
    julia_sd <- predict(fit_julia, dpar = "sd_relmat(id)")
    tmb_sd <- predict(fit_tmb, dpar = "sd_relmat(id)")
    names(julia_sd) <- sub("^sd_relmat\\(id\\):", "", names(julia_sd))
    names(tmb_sd) <- sub("^sd_relmat\\(id\\):", "", names(tmb_sd))

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

  simulation_seed <- 20261030L
  draws <- simulate(logit_fit, nsim = 1L, seed = simulation_seed)
  draws_repeat <- simulate(logit_fit, nsim = 1L, seed = simulation_seed)
  expect_identical(draws$sim_1, draws_repeat$sim_1)
  expect_length(draws$sim_1, nrow(logit_fit$data))
  expect_true(all(draws$sim_1 %in% c(0L, 1L)))
})
