hurdle_relmat_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  eta_mu <- as.vector(data$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  eta_hu <- as.vector(data$X_zi %*% par$beta_zi)
  index <- data$phylo_mu_node_index + 1L
  eta_hu <- eta_hu + data$phylo_mu_value[, 1L] * par$u_phylo[index]
  quadratic <- sum(par$u_phylo * as.vector(data$Q_phylo %*% par$u_phylo))
  prior <- 0.5 * (
    nrow(data$Q_phylo) * log(2 * pi) +
      2 * nrow(data$Q_phylo) * par$log_sd_phylo[[1L]] -
      data$log_det_Q_phylo +
      exp(-2 * par$log_sd_phylo[[1L]]) * quadratic
  )
  observed <- as.logical(data$observed_y)
  y <- data$y[observed]
  eta_mu <- eta_mu[observed]
  log_sigma <- log_sigma[observed]
  eta_hu <- eta_hu[observed]
  log_p0 <- stats::dnbinom(0, size = exp(-2 * log_sigma), mu = exp(eta_mu), log = TRUE)
  log_trunc <- log1p(-exp(log_p0))
  log_positive <- stats::dnbinom(
    y, size = exp(-2 * log_sigma), mu = exp(eta_mu), log = TRUE
  ) - log_trunc
  log_hu <- stats::plogis(eta_hu, log.p = TRUE)
  log_not_hu <- stats::plogis(eta_hu, lower.tail = FALSE, log.p = TRUE)
  prior - sum(data$weights[observed] * ifelse(y == 0, log_hu, log_not_hu + log_positive))
}

hurdle_relmat_gradient <- function(fn, par, step = 1e-6) {
  vapply(seq_along(par), function(i) {
    plus <- minus <- par
    plus[[i]] <- plus[[i]] + step
    minus[[i]] <- minus[[i]] - step
    (fn(plus) - fn(minus)) / (2 * step)
  }, numeric(1L))
}

hurdle_relmat_fixture <- function(
  n_id = 80L, n_each = 30L, seed = 2026081810L
) {
  set.seed(seed)
  levels_id <- paste0("hr", seq_len(n_id))
  id <- factor(rep(levels_id, each = n_each), levels = levels_id)
  x <- stats::rnorm(length(id))
  sd_hu <- 0.9
  field <- stats::setNames(stats::rnorm(n_id, sd = sd_hu), levels_id)
  eta_hu <- -0.8 + field[as.character(id)]
  mu <- exp(0.5 + 0.2 * x)
  y_positive <- stats::rnbinom(length(id), mu = mu, size = 12)
  while (any(y_positive == 0L)) {
    zero <- y_positive == 0L
    y_positive[zero] <- stats::rnbinom(sum(zero), mu = mu[zero], size = 12)
  }
  Q <- diag(n_id)
  dimnames(Q) <- list(levels_id, levels_id)
  list(
    data = data.frame(
      y = ifelse(stats::rbinom(length(id), 1L, stats::plogis(eta_hu)) == 1L, 0L, y_positive),
      x = x, id = id
    ),
    Q = Q, beta_mu = c("(Intercept)" = 0.5, x = 0.2),
    beta_sigma = log(1 / sqrt(12)), beta_hu = -0.8, sd_hu = sd_hu
  )
}

test_that("hurdle NB2 relmat hu response mask has oracle and recovery evidence", {
  sim <- hurdle_relmat_fixture()
  dat <- sim$data
  dat$y[seq(1L, nrow(dat), by = 30L)] <- NA_real_
  observed <- !is.na(dat$y)
  Q <- sim$Q
  formula <- bf(y ~ x, sigma ~ 1, hu ~ relmat(1 | id, Q = Q))
  fit_masked <- drmTMB(
    formula, family = truncated_nbinom2(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = truncated_nbinom2(), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), hurdle_relmat_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), hurdle_relmat_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "hu"), coef(fit_observed, "hu"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$hu, fit_observed$sdpars$hu, tolerance = 1e-6)
  expect_lt(max(abs(coef(fit_masked, "mu") - sim$beta_mu)), 0.12)
  expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - sim$beta_sigma), 0.16)
  expect_lt(abs(coef(fit_masked, "hu")[[1L]] - sim$beta_hu), 0.20)
  expect_lt(abs(fit_masked$sdpars$hu[["relmat(1 | id)"]] - sim$sd_hu), 0.25)
})
