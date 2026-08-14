# Recovery + regression tests for the 0.4.0 fix that routes nbinom2 structured
# `sigma` terms onto the scale predictor (log_sigma) instead of the mean (eta_mu).
#
# Before 0.4.0, `sigma ~ phylo/spatial/animal/relmat(...)` for nbinom2 was accepted
# and reported a `*_sigma` SD, but src/drmTMB.cpp model_type 7 added the structured
# effect to eta_mu (no phylo_mu_dpar == 1 branch, unlike beta model_type 10). The fit
# was therefore numerically identical to a mean-phylo model. See
# docs/dev-log/known-limitations.md and the census entry.

nb2_sigma_phylo_data <- function(seed, where = c("sigma", "mean"),
                                 n_sp = 45, n_each = 18, sd_u = 1.2) {
  where <- match.arg(where)
  set.seed(seed)
  tree <- ape::rcoal(n_sp)
  tree$tip.label <- paste0("sp", seq_len(n_sp))
  V <- ape::vcv(tree)
  V <- V / max(V)
  u <- as.numeric(MASS::mvrnorm(1, rep(0, n_sp), sd_u^2 * V))
  names(u) <- tree$tip.label
  sp <- rep(tree$tip.label, each = n_each)
  x <- rnorm(n_sp * n_each)
  if (where == "sigma") {
    mu_true <- exp(1.4 + 0.3 * x)               # constant-structure mean
    size <- exp(0.4 + u[sp])                    # dispersion varies by species
  } else {
    mu_true <- exp(0.6 + 0.3 * x + u[sp])       # phylo signal on the mean
    size <- rep(3, length(mu_true))
  }
  y <- rnbinom(length(mu_true), mu = mu_true, size = size)
  list(data = data.frame(y = y, x = x, sp = sp), tree = tree,
       true_log_size = tapply(log(size), sp, mean))
}

new_nb2_sigma_phylo_slope_data <- function(
  seed = 2026081753L,
  n_tip = 128L,
  n_each = 32L,
  sd_intercept = 0.55,
  sd_slope = 0.35,
  beta_mu = c(`(Intercept)` = 0.55, x = -0.15),
  beta_sigma = c(`(Intercept)` = -0.40)
) {
  set.seed(seed)
  tree <- ape::stree(n_tip, type = "balanced")
  tree$tip.label <- paste0("sp", seq_len(n_tip))
  tree$edge.length <- rep(1, nrow(tree$edge))
  covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  draw_field <- function(sd) {
    out <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_tip, sd = sd))
    names(out) <- tree$tip.label
    out
  }
  phylo_intercept <- draw_field(sd_intercept)
  phylo_slope <- draw_field(sd_slope)
  sp <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(sp))
  log_sigma <- beta_sigma[["(Intercept)"]] + phylo_intercept[sp] +
    x * phylo_slope[sp]
  eta_mu <- beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x
  y <- stats::rnbinom(length(sp), mu = exp(eta_mu), size = exp(-2 * log_sigma))
  list(
    data = data.frame(y = y, x = x, sp = sp), tree = tree,
    beta_mu = beta_mu, beta_sigma = beta_sigma,
    sd_intercept = sd_intercept, sd_slope = sd_slope
  )
}

nb2_sigma_phylo_slope_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  n_phylo <- nrow(data$Q_phylo)
  u_phylo <- matrix(par$u_phylo, nrow = n_phylo)
  expect_true(all(data$phylo_mu_dpar == 1L))
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  for (k in seq_len(ncol(u_phylo))) {
    log_sigma <- log_sigma + data$phylo_mu_value[, k] *
      u_phylo[data$phylo_mu_node_index + 1L, k]
  }
  quadratic <- vapply(
    seq_len(ncol(u_phylo)),
    function(k) {
      u <- u_phylo[, k]
      sum(u * as.vector(data$Q_phylo %*% u))
    },
    numeric(1L)
  )
  prior <- sum(0.5 * (
    n_phylo * log(2 * pi) + 2 * par$log_sd_phylo * n_phylo -
      data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo) * quadratic
  ))
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dnbinom(
    data$y[observed], size = exp(-2 * log_sigma[observed]),
    mu = exp(eta_mu[observed]), log = TRUE
  ))
}

nb2_sigma_central_gradient <- function(fn, par) {
  vapply(seq_along(par), function(i) {
    step <- 1e-6 * max(1, abs(par[[i]]))
    plus <- minus <- par
    plus[[i]] <- plus[[i]] + step
    minus[[i]] <- minus[[i]] - step
    (fn(plus) - fn(minus)) / (2 * step)
  }, numeric(1L))
}

fit_ll <- function(f) tryCatch(as.numeric(logLik(f)), error = function(e) NA_real_)

test_that("nbinom2 structured sigma recovers scale structure (0.4.0 routing fix)", {
  skip_on_cran()
  skip_fragile_recovery()
  skip_if_not_installed("ape")
  skip_if_not_installed("MASS")
  d <- nb2_sigma_phylo_data(202, where = "sigma")
  tree <- d$tree
  dat <- d$data
  ctrl <- drm_control(se = FALSE)
  f0 <- drmTMB(bf(y ~ x), family = nbinom2(), data = dat, control = ctrl)
  fM <- drmTMB(bf(y ~ x + phylo(1 + x | sp, tree = tree)),
               family = nbinom2(), data = dat, control = ctrl)
  fS <- drmTMB(bf(y ~ x, sigma ~ phylo(1 + x | sp, tree = tree)),
               family = nbinom2(), data = dat, control = ctrl)

  # scale-structured data: sigma~phylo must explain far more than mu~phylo
  expect_gt(fit_ll(fS) - fit_ll(f0), 15)
  expect_gt((fit_ll(fS) - fit_ll(f0)) - (fit_ll(fM) - fit_ll(f0)), 10)

  # the fitted per-species sigma must vary and track the true dispersion
  ps <- predict(fS, dpar = "sigma")
  by_sp <- tapply(as.numeric(ps), dat$sp, mean)
  expect_gt(sd(by_sp), 0.05)
  expect_gt(abs(suppressWarnings(cor(by_sp, d$true_log_size[names(by_sp)]))), 0.6)
})

test_that("NB2 phylo log-sigma response mask has oracle and recovery evidence", {
  skip_if_not_installed("ape")
  sim <- new_nb2_sigma_phylo_slope_data()
  dat <- sim$data
  dat$y[seq(1L, nrow(dat), by = 32L)] <- NA_integer_
  observed <- !is.na(dat$y)
  tree <- sim$tree
  formula <- bf(y ~ x, sigma ~ phylo(1 + x | sp, tree = tree))
  fit_masked <- drmTMB(
    formula, family = nbinom2(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = nbinom2(), data = dat[observed, , drop = FALSE],
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
  expect_equal(obj$fn(probe), nb2_sigma_phylo_slope_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), nb2_sigma_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$sigma, fit_observed$sdpars$sigma, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]), 0.20)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.15)
  expect_lt(abs(coef(fit_masked, "sigma")[["(Intercept)"]] - sim$beta_sigma[["(Intercept)"]]), 0.20)
  expect_lt(abs(unname(fit_masked$sdpars$sigma[[1L]]) - sim$sd_intercept), 0.25)
  expect_lt(abs(unname(fit_masked$sdpars$sigma[[2L]]) - sim$sd_slope), 0.22)
})

test_that("nbinom2 structured sigma does NOT absorb a mean-phylo signal (mis-wire guard)", {
  skip_on_cran()
  skip_fragile_recovery()
  skip_if_not_installed("ape")
  skip_if_not_installed("MASS")
  d <- nb2_sigma_phylo_data(101, where = "mean")
  tree <- d$tree
  dat <- d$data
  ctrl <- drm_control(se = FALSE)
  f0 <- drmTMB(bf(y ~ x), family = nbinom2(), data = dat, control = ctrl)
  fM <- drmTMB(bf(y ~ x + phylo(1 + x | sp, tree = tree)),
               family = nbinom2(), data = dat, control = ctrl)
  fS <- drmTMB(bf(y ~ x, sigma ~ phylo(1 + x | sp, tree = tree)),
               family = nbinom2(), data = dat, control = ctrl)

  # a mean-phylo signal must be captured by mu~phylo, not by sigma~phylo
  expect_gt(fit_ll(fM) - fit_ll(f0), 5)
  # sigma~phylo must NOT recover the mean signal (would indicate the mis-wire returned)
  expect_lt(fit_ll(fS) - fit_ll(f0), 3)
})
