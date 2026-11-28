testthat::test_that("the generalized table fits fixed, residual-SD, and random-SD priors", {
  testthat::skip_if_not_installed("TMB")
  set.seed(41021)
  n_group <- 8L
  n_each <- 10L
  group <- factor(rep(seq_len(n_group), each = n_each))
  x <- rep(seq(-1, 1, length.out = n_each), n_group)
  b <- stats::rnorm(n_group, 0, 0.45)
  y <- 0.3 + 0.6 * x + b[group] + stats::rnorm(length(x), 0, 0.8)
  dat <- data.frame(y = y, x = x, group = group)
  formula <- drmTMB::bf(mu = y ~ x + (1 | group), sigma = ~1)
  priors <- data.frame(
    prior = c("normal(0,2)", "student_t(0,1.5,4)", "gamma(0.8,2)", "gamma(0.6,2)"),
    class = c("fixef", "fixef", "residual_sd", "ranef_sd"),
    dpar = c("mu", "mu", "sigma", "mu"),
    coef = c("(Intercept)", "x", "(Intercept)", "group"),
    scale = c("link", "link", "natural_sd", "natural_sd")
  )

  resolved <- drmTMB::drm_resolve_priors(formula, stats::gaussian(), dat, priors)
  testthat::expect_equal(resolved$kind, c("normal", "student_t", "gamma", "gamma"))
  testthat::expect_equal(resolved$class, c("fixed", "fixed", "ranef_sd", "residual_sd"))
  testthat::expect_equal(resolved$scale[3:4], c("natural_sd", "natural_sd"))
  testthat::expect_equal(resolved$rate[3:4], c(10 / 3, 2.5), tolerance = 1e-12)
  residual_without_scale <- priors[3, setdiff(names(priors), "scale"), drop = FALSE]
  testthat::expect_error(drmTMB::drm_resolve_priors(
    formula, stats::gaussian(), dat, residual_without_scale
  ), "explicitly specify")

  fit <- drmTMB::drmTMB(
    formula, data = dat, priors = priors,
    control = drmTMB::drm_control(logsigma_clamp = NULL)
  )
  beta <- fit$coefficients$mu
  sigma <- exp(unname(fit$coefficients$sigma[["(Intercept)"]]))
  eta_sd <- unname(fit$opt$par["log_sd_mu"])
  fixed_penalty <- -stats::dnorm(beta[["(Intercept)"]], mean = 0, sd = 2, log = TRUE) -
    (lgamma(2.5) - lgamma(2) - 0.5 * log(4 * pi) - log(1.5) -
       2.5 * log1p((beta[["x"]] / 1.5)^2 / 4))
  sd_penalty <- -stats::dgamma(sigma, shape = 2, rate = 2.5, log = TRUE) -
    stats::dgamma(exp(eta_sd), shape = 2, rate = 10 / 3, log = TRUE)

  testthat::expect_equal(fit$fixed_prior_penalty, fixed_penalty, tolerance = 1e-8)
  testthat::expect_equal(fit$sd_prior_penalty, -stats::dgamma(exp(eta_sd), shape = 2, rate = 10 / 3, log = TRUE), tolerance = 1e-8)
  testthat::expect_equal(fit$residual_sd_prior_penalty, -stats::dgamma(sigma, shape = 2, rate = 2.5, log = TRUE), tolerance = 1e-8)
  testthat::expect_equal(fit$log_prior, -(fixed_penalty + sd_penalty), tolerance = 1e-8)
  testthat::expect_equal(
    fit$penalized_objective,
    -as.numeric(stats::logLik(fit)) + fixed_penalty + sd_penalty,
    tolerance = 1e-8
  )
  testthat::expect_identical(attr(fit$priors, "input_table"), priors)
  testthat::expect_error(stats::confint(fit), "prior")

  # Independent dense-Gaussian likelihood and closed-form prior oracle. The
  # Hessian and score are differentiated from this oracle (Richardson steps
  # 1e-5 for the score and 1e-4 for the Hessian), not from package code.
  testthat::skip_if_not_installed("numDeriv")
  X <- cbind(`(Intercept)` = 1, x = dat$x)
  Z <- stats::model.matrix(~ 0 + group, data = dat)
  dense_nll <- function(theta) {
    beta <- theta[1:2]
    sigma_i <- exp(theta[[3L]])
    tau_i <- exp(theta[[4L]])
    V <- diag(sigma_i^2, nrow(dat)) + tau_i^2 * tcrossprod(Z)
    residual <- dat$y - drop(X %*% beta)
    data_nll <- 0.5 * (nrow(dat) * log(2 * pi) + as.numeric(determinant(V, logarithm = TRUE)$modulus) +
      drop(crossprod(residual, solve(V, residual))))
    normal_nll <- -stats::dnorm(beta[[1L]], 0, 2, log = TRUE)
    student_nll <- -stats::dt(beta[[2L]] / 1.5, df = 4, log = TRUE) + log(1.5)
    data_nll + normal_nll + student_nll -
      stats::dgamma(sigma_i, shape = 2, rate = 2.5, log = TRUE) -
      stats::dgamma(tau_i, shape = 2, rate = 10 / 3, log = TRUE)
  }
  center <- unname(fit$opt$par)
  points <- rbind(center,
    center + c(0.12, -0.07, 0.04, -0.08),
    center + c(-0.08, 0.09, -0.06, 0.05),
    center + c(0.04, 0.05, 0.03, -0.11),
    center + c(-0.06, -0.04, 0.08, 0.07))
  for (i in seq_len(nrow(points))) {
    point <- points[i, ]
    package_value <- fit$obj$fn(point)
    oracle_value <- dense_nll(point)
    testthat::expect_lte(abs(package_value - oracle_value) / max(1, abs(oracle_value)), 1e-8)
    oracle_gradient <- numDeriv::grad(dense_nll, point, method = "Richardson",
      method.args = list(eps = 1e-5))
    package_gradient <- fit$obj$gr(point)
    testthat::expect_lte(max(abs(package_gradient - oracle_gradient)), 1e-6)
    oracle_hessian <- numDeriv::hessian(dense_nll, point, method = "Richardson",
      method.args = list(eps = 1e-4))
    package_hessian <- vapply(seq_along(point), function(j) {
      shift <- numeric(length(point)); shift[[j]] <- 1e-4
      (fit$obj$gr(point + shift) - fit$obj$gr(point - shift)) / (2e-4)
    }, numeric(length(point)))
    testthat::expect_lte(max(abs(package_hessian - oracle_hessian) /
      pmax(1, abs(oracle_hessian))), 1e-5)
  }

  query_point <- unname(fit$opt$par)
  query_point[[2L]] <- 0.72
  beta_query <- query_point[1:2]
  sigma_query <- exp(query_point[[3L]])
  tau_query <- exp(query_point[[4L]])
  V_query <- diag(sigma_query^2, nrow(dat)) + tau_query^2 * tcrossprod(Z)
  residual_query <- dat$y - drop(X %*% beta_query)
  data_nll_query <- 0.5 * (nrow(dat) * log(2 * pi) +
    as.numeric(determinant(V_query, logarithm = TRUE)$modulus) +
    drop(crossprod(residual_query, solve(V_query, residual_query))))
  testthat::expect_equal(drmTMB::objective_at(fit, list("fixef:mu:x" = 0.72)),
    data_nll_query, tolerance = 1e-8)

  replay <- stats::update(fit, data = dat)
  testthat::expect_equal(replay$resolved_priors, fit$resolved_priors)
  testthat::expect_equal(replay$resolved_sd_prior, fit$resolved_sd_prior)
  testthat::expect_equal(replay$resolved_residual_sd_prior, fit$resolved_residual_sd_prior)
  testthat::expect_equal(replay$penalized_objective, fit$penalized_objective, tolerance = 1e-7)
  testthat::expect_equal(replay$log_prior, fit$log_prior, tolerance = 1e-7)
  testthat::expect_warning(stats::AIC(fit), class = "drmTMB_ic_map_warning")
  testthat::expect_warning(
    testthat::expect_error(drmTMB:::drm_lrtest(fit, fit), "MAP"),
    class = "drmTMB_lrtest_map_warning"
  )

  plain_fit <- drmTMB::drmTMB(formula, data = dat,
    control = drmTMB::drm_control(logsigma_clamp = NULL))
  testthat::expect_equal(as.numeric(stats::logLik(plain_fit)), -plain_fit$opt$objective,
    tolerance = 1e-8)
  testthat::expect_null(plain_fit$log_prior)
  testthat::expect_null(plain_fit$residual_sd_prior_penalty)
  testthat::expect_null(plain_fit$correlation_prior_penalty)
})

testthat::test_that("LKJ priors target the natural Gaussian random-slope correlation", {
  testthat::skip_if_not_installed("TMB")
  set.seed(41022)
  n_group <- 10L
  n_each <- 12L
  group <- factor(rep(seq_len(n_group), each = n_each))
  x <- rep(seq(-1, 1, length.out = n_each), n_group)
  intercept <- stats::rnorm(n_group, 0, 0.4)
  slope <- stats::rnorm(n_group, 0, 0.25)
  y <- 0.2 + 0.5 * x + intercept[group] + slope[group] * x +
    stats::rnorm(length(x), 0, 0.7)
  dat <- data.frame(y = y, x = x, group = group)
  formula <- drmTMB::bf(mu = y ~ x + (1 + x | group), sigma = ~1)
  priors <- data.frame(
    prior = "lkj(2)", class = "correlation", dpar = "mu", group = "group",
    coef = "", from_coef = "(Intercept)", to_coef = "x",
    scale = "natural_correlation"
  )

  correlation_without_scale <- priors[, setdiff(names(priors), "scale"), drop = FALSE]
  testthat::expect_error(drmTMB::drm_resolve_priors(
    formula, stats::gaussian(), dat, correlation_without_scale
  ), "explicitly specify")

  resolved <- drmTMB::drm_resolve_priors(formula, stats::gaussian(), dat, priors)
  testthat::expect_equal(resolved$kind, "lkj")
  testthat::expect_equal(resolved$group, "group")
  testthat::expect_equal(resolved$from_coef, "(Intercept)")
  testthat::expect_equal(resolved$to_coef, "x")
  testthat::expect_equal(resolved$class, "correlation")
  testthat::expect_equal(resolved$block, "gaussian_q2")
  testthat::expect_equal(resolved$scale, "natural_correlation")
  testthat::expect_equal(resolved$support_guard, 0.99999999)
  testthat::expect_equal(
    resolved$log_normalizer,
    log(2 * (resolved$support_guard - resolved$support_guard^3 / 3)),
    tolerance = 1e-14
  )

  fit <- drmTMB::drmTMB(
    formula, data = dat, priors = priors,
    control = drmTMB::drm_control(logsigma_clamp = NULL)
  )
  rho <- 0.99999999 * tanh(unname(fit$opt$par["eta_cor_mu"]))
  eta <- 2
  guard <- 0.99999999
  log_normalizer <- log(2 * (guard - guard^3 / 3))
  expected <- log_normalizer - (eta - 1) * log1p(-rho^2)
  testthat::expect_equal(fit$correlation_prior_penalty, expected, tolerance = 1e-8)
  testthat::expect_equal(fit$log_prior, -expected, tolerance = 1e-8)
  testthat::expect_equal(
    fit$penalized_objective,
    -as.numeric(stats::logLik(fit)) + expected,
    tolerance = 1e-8
  )

  testthat::skip_if_not_installed("numDeriv")
  positions <- fit$opt$par
  mu_pos <- which(names(positions) == "beta_mu")
  sigma_pos <- which(names(positions) == "beta_sigma")
  sd_pos <- which(names(positions) == "log_sd_mu")
  cor_pos <- which(names(positions) == "eta_cor_mu")
  Z <- matrix(0, nrow(dat), 2L * n_group)
  for (g in seq_len(n_group)) {
    rows <- which(group == levels(group)[[g]])
    Z[rows, c(2L * g - 1L, 2L * g)] <- cbind(1, x[rows])
  }
  dense_nll <- function(theta) {
    beta <- theta[mu_pos]
    sigma_i <- exp(theta[sigma_pos])
    sd_i <- exp(theta[sd_pos])
    eta_i <- theta[[cor_pos]]
    rho_i <- 0.99999999 * tanh(eta_i)
    D <- matrix(c(sd_i[[1L]]^2, rho_i * sd_i[[1L]] * sd_i[[2L]],
      rho_i * sd_i[[1L]] * sd_i[[2L]], sd_i[[2L]]^2), 2L, 2L)
    V <- diag(sigma_i^2, nrow(dat)) + Z %*% kronecker(diag(n_group), D) %*% t(Z)
    residual <- dat$y - drop(cbind(1, x) %*% beta)
    lkj_nll <- log_normalizer - (eta - 1) * log1p(-rho_i^2)
    0.5 * (nrow(dat) * log(2 * pi) + as.numeric(determinant(V, logarithm = TRUE)$modulus) +
      drop(crossprod(residual, solve(V, residual)))) + lkj_nll
  }
  offsets <- rbind(rep(0, length(positions)),
    rep(c(0.03, -0.04, 0.05, -0.02, 0.06), length.out = length(positions)),
    rep(c(-0.04, 0.02, -0.03, 0.04, -0.05), length.out = length(positions)),
    rep(c(0.02, 0.05, 0.04, -0.03, 0.02), length.out = length(positions)),
    rep(c(-0.03, -0.02, 0.01, 0.05, 0.04), length.out = length(positions)))
  for (i in seq_len(nrow(offsets))) {
    point <- unname(positions) + offsets[i, ]
    reference <- dense_nll(point)
    testthat::expect_lte(abs(fit$obj$fn(point) - reference) / max(1, abs(reference)), 1e-8)
    reference_gradient <- numDeriv::grad(dense_nll, point, method = "Richardson", method.args = list(eps = 1e-5))
    testthat::expect_lte(max(abs(fit$obj$gr(point) - reference_gradient)), 1e-6)
    reference_hessian <- numDeriv::hessian(dense_nll, point, method = "Richardson", method.args = list(eps = 1e-4))
    package_hessian <- vapply(seq_along(point), function(j) {
      shift <- numeric(length(point)); shift[[j]] <- 1e-4
      (fit$obj$gr(point + shift) - fit$obj$gr(point - shift)) / (2e-4)
    }, numeric(length(point)))
    testthat::expect_lte(max(abs(package_hessian - reference_hessian) /
      pmax(1, abs(reference_hessian))), 1e-5)
  }
  query_point <- unname(positions)
  query_point[[mu_pos[[2L]]]] <- query_point[[mu_pos[[2L]]]] + 0.08
  rho_query <- 0.99999999 * tanh(query_point[[cor_pos]])
  lkj_nll_query <- log_normalizer - (eta - 1) * log1p(-rho_query^2)
  testthat::expect_equal(drmTMB::objective_at(fit,
    list("fixef:mu:x" = query_point[[mu_pos[[2L]]]])),
    dense_nll(query_point) - lkj_nll_query, tolerance = 1e-8)

  replay <- stats::update(fit, data = dat)
  testthat::expect_equal(replay$resolved_correlation_prior, fit$resolved_correlation_prior)
  testthat::expect_equal(replay$correlation_prior_penalty, fit$correlation_prior_penalty,
    tolerance = 1e-7)
})

testthat::test_that("LKJ priors target an intercept-only bivariate residual correlation", {
  testthat::skip_if_not_installed("TMB")
  set.seed(41023)
  n <- 80L
  z1 <- stats::rnorm(n)
  z2 <- 0.35 * z1 + sqrt(1 - 0.35^2) * stats::rnorm(n)
  dat <- data.frame(y1 = z1, y2 = z2)
  formula <- drmTMB::bf(mu1 = y1 ~ 1, mu2 = y2 ~ 1, rho12 = ~1)
  priors <- data.frame(
    prior = "lkj(2)", class = "correlation", dpar = "rho12",
    coef = "(Intercept)", scale = "natural_correlation"
  )

  preview <- drmTMB::drm_resolve_priors(formula,
    family = drmTMB::biv_gaussian(), data = dat, priors = priors)
  testthat::expect_equal(preview$class, "correlation")
  testthat::expect_equal(preview$block, "bivariate_residual")
  testthat::expect_equal(preview$scale, "natural_correlation")

  fit <- drmTMB::drmTMB(
    formula, family = drmTMB::biv_gaussian(), data = dat, priors = priors
  )
  testthat::expect_equal(fit$resolved_correlation_prior$support_guard, 0.999999)
  testthat::expect_equal(
    fit$resolved_correlation_prior$log_normalizer,
    log(2 * (0.999999 - 0.999999^3 / 3)),
    tolerance = 1e-14
  )
  eta_rho <- unname(fit$coefficients$rho12[["(Intercept)"]])
  rho <- 0.999999 * tanh(eta_rho)
  eta <- 2
  guard <- 0.999999
  log_normalizer <- log(2 * (guard - guard^3 / 3))
  expected <- log_normalizer - log1p(-rho^2)
  testthat::expect_equal(fit$correlation_prior_penalty, expected, tolerance = 1e-8)
  testthat::expect_equal(fit$log_prior, -expected, tolerance = 1e-8)

  testthat::skip_if_not_installed("numDeriv")
  positions <- fit$opt$par
  mu1_pos <- which(names(positions) == "beta_mu1")
  mu2_pos <- which(names(positions) == "beta_mu2")
  sigma1_pos <- which(names(positions) == "beta_sigma1")
  sigma2_pos <- which(names(positions) == "beta_sigma2")
  rho_pos <- which(names(positions) == "beta_rho12")
  dense_nll <- function(theta) {
    sigma1_i <- exp(theta[[sigma1_pos]])
    sigma2_i <- exp(theta[[sigma2_pos]])
    rho_i <- 0.999999 * tanh(theta[[rho_pos]])
    u <- (dat$y1 - theta[[mu1_pos]]) / sigma1_i
    v <- (dat$y2 - theta[[mu2_pos]]) / sigma2_i
    determinant <- 1 - rho_i^2
    data_nll <- n * (log(2 * pi) + log(sigma1_i) + log(sigma2_i) + 0.5 * log(determinant)) +
      sum(u^2 - 2 * rho_i * u * v + v^2) / (2 * determinant)
    lkj_nll <- log_normalizer - (eta - 1) * log(determinant)
    data_nll + lkj_nll
  }
  # Independent analytic score for the dense bivariate likelihood. Taking a
  # numerical Hessian directly from dense_nll is cancellation-prone for the
  # mu1/log-sigma2 cross term at the fitted center, where its exact value is
  # essentially zero. Differentiate this score instead, after checking it
  # against finite differences of the independently written objective below.
  dense_score <- function(theta) {
    sigma1_i <- exp(theta[[sigma1_pos]])
    sigma2_i <- exp(theta[[sigma2_pos]])
    rho_i <- guard * tanh(theta[[rho_pos]])
    determinant <- 1 - rho_i^2
    u <- (dat$y1 - theta[[mu1_pos]]) / sigma1_i
    v <- (dat$y2 - theta[[mu2_pos]]) / sigma2_i
    quadratic <- sum(u^2 - 2 * rho_i * u * v + v^2)
    drho_deta <- guard * (1 - tanh(theta[[rho_pos]])^2)
    d_nll_d_rho <- (2 - n) * rho_i / determinant -
      sum(u * v) / determinant + rho_i * quadratic / determinant^2
    unname(c(
      sum((-u + rho_i * v) / (sigma1_i * determinant)),
      sum((-v + rho_i * u) / (sigma2_i * determinant)),
      n + sum((-u^2 + rho_i * u * v) / determinant),
      n + sum((-v^2 + rho_i * u * v) / determinant),
      d_nll_d_rho * drho_deta
    ))
  }
  offsets <- rbind(rep(0, length(positions)),
    c(0.04, -0.03, 0.02, -0.04, 0.05),
    c(-0.03, 0.05, -0.04, 0.03, -0.06),
    c(0.02, 0.02, 0.03, -0.02, 0.04),
    c(-0.05, -0.01, 0.01, 0.05, -0.03))
  for (i in seq_len(nrow(offsets))) {
    point <- unname(positions) + offsets[i, ]
    reference <- dense_nll(point)
    testthat::expect_lte(abs(fit$obj$fn(point) - reference) / max(1, abs(reference)), 1e-8)
    objective_gradient <- numDeriv::grad(dense_nll, point, method = "Richardson", method.args = list(eps = 1e-5))
    reference_gradient <- dense_score(point)
    testthat::expect_lte(max(abs(reference_gradient - objective_gradient)), 1e-6)
    testthat::expect_lte(max(abs(fit$obj$gr(point) - reference_gradient)), 1e-6)
    reference_hessian <- numDeriv::jacobian(dense_score, point, method = "Richardson", method.args = list(eps = 1e-4))
    package_hessian <- vapply(seq_along(point), function(j) {
      shift <- numeric(length(point)); shift[[j]] <- 1e-4
      (fit$obj$gr(point + shift) - fit$obj$gr(point - shift)) / (2e-4)
    }, numeric(length(point)))
    testthat::expect_lte(max(abs(package_hessian - reference_hessian) /
      pmax(1, abs(reference_hessian))), 1e-5)
    testthat::expect_lte(max(abs(fit$obj$he(point) - reference_hessian) /
      pmax(1, abs(reference_hessian))), 1e-5)
  }
})

testthat::test_that("prior-table selectors reject invalid and duplicate targets", {
  dat <- data.frame(y = c(0.2, 0.8, 0.5, 1.4, 1, 1.6), x = c(-1, 0, 1, -1, 0, 1),
                    group = factor(rep(1:3, each = 2)))
  f <- drmTMB::bf(mu = y ~ x + (1 | group), sigma = ~1)
  bad_group <- data.frame(prior = "gamma(0.6,2)", class = "ranef_sd",
    dpar = "mu", group = "missing", coef = "missing", scale = "natural_sd")
  testthat::expect_error(drmTMB::drm_resolve_priors(f, stats::gaussian(), dat, bad_group),
    "unknown|target")
  bad_df <- data.frame(prior = "student_t(0,1,0)", class = "fixef",
    dpar = "mu", coef = "x", scale = "link")
  testthat::expect_error(drmTMB::drm_resolve_priors(f, stats::gaussian(), dat, bad_df), "df")
  bad_corr <- data.frame(prior = "lkj(2)", class = "correlation", dpar = "mu",
    group = "group", coef = "", from_coef = "(Intercept)", to_coef = "missing",
    scale = "natural_correlation")
  testthat::expect_error(drmTMB::drm_resolve_priors(f, stats::gaussian(), dat, bad_corr),
    "correlation|target")
  duplicate <- data.frame(prior = c("normal(0,2)", "student_t(0,1,4)"),
    class = "fixef", dpar = "mu", coef = "x", scale = "link")
  testthat::expect_error(drmTMB::drm_resolve_priors(f, stats::gaussian(), dat, duplicate),
    "overlap|same coefficient")
  t_table <- data.frame(prior = "student_t(0,1,4)", class = "fixef",
    dpar = "mu", coef = "x", scale = "link")
  testthat::expect_error(drmTMB::drmTMB(f, data = dat, priors = t_table,
    engine = "julia"), "does not support this combination of prior targets")
})
