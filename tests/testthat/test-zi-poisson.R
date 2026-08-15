new_zi_poisson_data <- function(n = 1800, seed = 20260608) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    habitat = factor(sample(c("open", "edge"), n, replace = TRUE))
  )
  beta_mu <- c(`(Intercept)` = 0.30, x = -0.35, habitatopen = 0.25)
  beta_zi <- c(`(Intercept)` = -0.90, z = 0.55, habitatopen = -0.45)
  X_mu <- stats::model.matrix(~ x + habitat, dat)
  X_zi <- stats::model.matrix(~ z + habitat, dat)
  mu <- exp(as.vector(X_mu %*% beta_mu))
  zi <- stats::plogis(as.vector(X_zi %*% beta_zi))
  dat$count <- ifelse(stats::runif(n) < zi, 0L, stats::rpois(n, lambda = mu))
  list(data = dat, beta_mu = beta_mu, beta_zi = beta_zi)
}

test_that("drmTMB fits zero-inflated Poisson models through a zi formula", {
  sim <- new_zi_poisson_data()

  fit <- drmTMB(
    bf(count ~ x + habitat, zi ~ z + habitat),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "zi_poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.12)
  expect_lt(max(abs(coef(fit, "zi") - sim$beta_zi)), 0.35)
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(predict(fit, dpar = "zi") > 0))
  expect_true(all(predict(fit, dpar = "zi") < 1))
  expect_equal(
    predict(fit, dpar = "mu"),
    exp(predict(fit, dpar = "mu", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, dpar = "zi"),
    stats::plogis(predict(fit, dpar = "zi", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(
    fitted(fit),
    (1 - predict(fit, dpar = "zi")) * predict(fit, dpar = "mu"),
    tolerance = 1e-12
  )
  expect_equal(sigma(fit), rep(1, nobs(fit)))

  ci <- confint(fit)
  expect_equal(
    ci$parm,
    c(
      "fixef:mu:(Intercept)",
      "fixef:mu:x",
      "fixef:mu:habitatopen",
      "fixef:zi:(Intercept)",
      "fixef:zi:z",
      "fixef:zi:habitatopen"
    )
  )
  expect_equal(
    ci$tmb_parameter,
    c("beta_mu", "beta_mu", "beta_mu", "beta_zi", "beta_zi", "beta_zi")
  )
  expect_true(all(ci$conf.status == "wald"))
})

test_that("zero-inflated Poisson likelihood matches independent calculation", {
  sim <- new_zi_poisson_data(n = 420, seed = 20260609)

  fit <- drmTMB(
    bf(count ~ x + habitat, zi ~ z + habitat),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_zi <- as.vector(fit$model$X$zi %*% coef(fit, "zi"))
  mu <- exp(eta_mu)
  zi <- stats::plogis(eta_zi)
  ll_independent <- ifelse(
    fit$model$y == 0,
    log(zi + (1 - zi) * stats::dpois(0, lambda = mu)),
    log1p(-zi) + stats::dpois(fit$model$y, lambda = mu, log = TRUE)
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), sum(ll_independent), tolerance = 1e-6)
})

test_that("zero-inflated Poisson supports exposure offsets in the mean formula", {
  sim <- new_zi_poisson_data(n = 420, seed = 20260618)
  dat <- sim$data
  dat$effort <- exp(stats::rnorm(nrow(dat), mean = 0, sd = 0.4))

  fit <- drmTMB(
    bf(count ~ x + habitat + offset(log(effort)), zi ~ z + habitat),
    family = stats::poisson(link = "log"),
    data = dat
  )

  eta_mu <- log(dat$effort) + as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_zi <- as.vector(fit$model$X$zi %*% coef(fit, "zi"))
  mu <- exp(eta_mu)
  zi <- stats::plogis(eta_zi)
  ll_independent <- ifelse(
    fit$model$y == 0,
    log(zi + (1 - zi) * stats::dpois(0, lambda = mu)),
    log1p(-zi) + stats::dpois(fit$model$y, lambda = mu, log = TRUE)
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), sum(ll_independent), tolerance = 1e-6)
  expect_equal(fit$model$offset$mu, log(dat$effort), tolerance = 1e-12)
})

test_that("zero-inflated Poisson methods return count-scale summaries", {
  sim <- new_zi_poisson_data(n = 260, seed = 20260610)
  fit <- drmTMB(
    bf(count ~ x + habitat, zi ~ z + habitat),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  mu <- predict(fit, dpar = "mu")
  zi <- predict(fit, dpar = "zi")
  response_mean <- (1 - zi) * mu
  expect_equal(fitted(fit), response_mean, tolerance = 1e-12)
  expect_equal(residuals(fit), fit$model$y - response_mean, tolerance = 1e-12)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - response_mean) / sqrt((1 - zi) * mu * (1 + zi * mu)),
    tolerance = 1e-12
  )
  newdata <- data.frame(
    x = c(-1, 0, 1),
    z = c(-1, 0, 1),
    habitat = factor(
      c("edge", "open", "edge"),
      levels = levels(fit$data$habitat)
    )
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    exp(as.vector(
      stats::model.matrix(~ x + habitat, newdata) %*% coef(fit, "mu")
    )),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "zi"),
    stats::plogis(as.vector(
      stats::model.matrix(~ z + habitat, newdata) %*% coef(fit, "zi")
    )),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260611)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) >= 0))
  expect_true(all(unlist(sims, use.names = FALSE) %% 1 == 0))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260611),
    simulate(fit, nsim = 2, seed = 20260611)
  )
})

test_that("zero-inflated Poisson approaches Poisson likelihood as zi approaches zero", {
  dat <- data.frame(y = c(0, 1, 2, 4, 7))
  fit <- drmTMB(
    bf(y ~ 1, zi ~ 1),
    family = stats::poisson(link = "log"),
    data = dat
  )

  par <- fit$obj$par
  par[["beta_mu"]] <- 0
  par[["beta_zi"]] <- -30
  ll_zip <- -fit$obj$fn(par)
  ll_pois <- sum(stats::dpois(dat$y, lambda = 1, log = TRUE))

  expect_equal(ll_zip, ll_pois, tolerance = 1e-6)
  expect_true(is.finite(fit$obj$fn(par)))
})

test_that("zero-inflated Poisson likelihood stays finite near certain structural zeros", {
  dat <- data.frame(y = c(0, 0, 1, 2))
  fit <- drmTMB(
    bf(y ~ 1, zi ~ 1),
    family = stats::poisson(link = "log"),
    data = dat
  )

  par <- fit$obj$par
  par[["beta_mu"]] <- 0
  par[["beta_zi"]] <- 30
  mu <- rep(1, nrow(dat))
  eta_zi <- rep(30, nrow(dat))
  logspace_add <- function(a, b) {
    m <- pmax(a, b)
    m + log(exp(a - m) + exp(b - m))
  }
  log_zi <- -log1p(exp(-eta_zi))
  log_one_minus_zi <- -log1p(exp(eta_zi))
  ll_zip <- ifelse(
    dat$y == 0,
    logspace_add(
      log_zi,
      log_one_minus_zi + stats::dpois(0, lambda = mu, log = TRUE)
    ),
    log_one_minus_zi + stats::dpois(dat$y, lambda = mu, log = TRUE)
  )

  expect_equal(-fit$obj$fn(par), sum(ll_zip), tolerance = 1e-6)
  expect_true(is.finite(fit$obj$fn(par)))
})

test_that("zero-inflated Poisson supports complete-case filtering", {
  sim <- new_zi_poisson_data(n = 80, seed = 20260612)
  dat <- sim$data
  dat$count[[1L]] <- -1
  dat$x[[1L]] <- NA
  dat$count[[2L]] <- 1.5
  dat$z[[2L]] <- NA

  fit <- drmTMB(
    bf(count ~ x + habitat, zi ~ z + habitat),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), nrow(dat) - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y >= 0))
  expect_true(all(fit$model$y %% 1 == 0))
})

test_that("zero-inflated Poisson rejects unsupported or invalid inputs", {
  dat <- data.frame(
    y = c(0, 1, 2, 3),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ 1, zi ~ x),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "at most one"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi = y ~ x),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "one-sided"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), zi ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Zero-inflated Poisson random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (0 + x | id), zi ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Zero-inflated Poisson random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ x + (1 | id)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Zero-inflation random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ x + (0 + x | id)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Zero-inflation random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ offset(rep(1, 4))),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ 0),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "zero-column"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_V(V = rep(0.1, 4)), zi ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "meta_V"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ 1, sd(id) ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y, y) ~ x, zi ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "mvbind"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ 1),
      family = stats::poisson(link = "log"),
      data = transform(dat, y = c(0, 1.5, 2, 3))
    ),
    "non-negative integer"
  )
  expect_false(exists(
    "zi_poisson",
    where = asNamespace("drmTMB"),
    inherits = FALSE
  ))
})

# mc-0662 (zero-inflated Poisson, mu ~ spatial(1 | site, coords = coords))
# and mc-0667 (zi ~ spatial(1 | site, coords = coords)) response-mask
# evidence. `zi_dense_spatial_precision()` is an independent hand-rolled
# re-derivation of the exponential-kernel GMRF prior drmTMB builds internally
# for `spatial()` (median-positive-distance range, jitter = 1e-6); it is not
# read from `fit$model$tmb_data`, matching the sibling oracle convention in
# test-zero-one-beta.R's `dense_zoib_spatial_precision()`.
zi_dense_spatial_precision <- function(coords, site_levels, jitter = 1e-6) {
  coords <- as.matrix(coords)[site_levels, seq_len(2L), drop = FALSE]
  distances <- as.matrix(stats::dist(coords))
  positive <- distances[distances > 0]
  range <- stats::median(positive)
  if (!is.finite(range) || range <= 0) range <- max(positive)
  K <- exp(-distances / range)
  diag(K) <- diag(K) + jitter
  chol_K <- chol(K)
  list(
    Q = chol2inv(chol_K),
    log_det_Q = -2 * sum(log(diag(chol_K))),
    levels = site_levels
  )
}

zi_central_gradient <- function(fn, par) {
  vapply(seq_along(par), function(i) {
    step <- 1e-6 * max(1, abs(par[[i]]))
    plus <- minus <- par
    plus[[i]] <- plus[[i]] + step
    minus[[i]] <- minus[[i]] - step
    (fn(plus) - fn(minus)) / (2 * step)
  }, numeric(1))
}

new_zi_poisson_spatial_mu_data <- function(
  seed = 2026081912L,
  n_site = 64L,
  n_each = 50L,
  sd_spatial = 0.45,
  beta_mu = c(`(Intercept)` = 0.35, x = -0.30),
  beta_zi = c(`(Intercept)` = -0.90)
) {
  set.seed(seed)
  site_levels <- paste0("site_", seq_len(n_site))
  theta <- seq(0, 1.5 * pi, length.out = n_site)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_site) / (3 * n_site),
    y = sin(theta)
  )
  rownames(coords) <- site_levels
  precision <- zi_dense_spatial_precision(coords, site_levels)
  covariance <- solve(precision$Q)
  spatial_effect <- as.vector(
    t(chol(covariance)) %*% stats::rnorm(n_site, sd = sd_spatial)
  )
  names(spatial_effect) <- site_levels
  site <- rep(site_levels, each = n_each)
  x <- stats::rnorm(length(site))
  eta_mu <- beta_mu[["(Intercept)"]] +
    beta_mu[["x"]] * x +
    spatial_effect[site]
  mu <- exp(eta_mu)
  zi <- stats::plogis(beta_zi[["(Intercept)"]])
  count <- ifelse(
    stats::runif(length(site)) < zi, 0L, stats::rpois(length(site), mu)
  )
  list(
    data = data.frame(count = count, x = x, site = site),
    coords = coords,
    beta_mu = beta_mu,
    beta_zi = beta_zi,
    sd_spatial = sd_spatial
  )
}

# Independent oracle: hand-written two-component zero-inflated Poisson
# mixture (pi + (1 - pi) f(0) at y = 0; (1 - pi) f(y) at y > 0, matching
# src/drmTMB.cpp model_type == 8) plus the GMRF quadratic-form prior on the
# spatial `mu` latent field.
zi_poisson_spatial_mu_nll <- function(fit, par, coords, site) {
  d <- fit$model$tmb_data
  u <- as.vector(par$u_phylo)
  precision <- zi_dense_spatial_precision(coords, unique(as.character(site)))
  expected_node_index <- match(site, precision$levels)
  expect_equal(d$phylo_mu_node_index + 1L, unname(expected_node_index))
  eta_mu <- as.vector(d$X_mu %*% par$beta_mu) +
    d$phylo_mu_value[, 1] * u[expected_node_index]
  eta_zi <- as.vector(d$X_zi %*% par$beta_zi)
  mu <- exp(eta_mu)
  zi <- stats::plogis(eta_zi)
  ll <- ifelse(
    d$y == 0,
    log(zi + (1 - zi) * stats::dpois(0, lambda = mu)),
    log1p(-zi) + stats::dpois(d$y, lambda = mu, log = TRUE)
  )
  prior <- 0.5 * (
    length(u) * log(2 * pi) +
      2 * length(u) * par$log_sd_phylo -
      precision$log_det_Q +
      exp(-2 * par$log_sd_phylo) * sum(u * as.vector(precision$Q %*% u))
  )
  observed <- as.logical(d$observed_y)
  prior - sum(d$weights[observed] * ll[observed])
}

test_that("zero-inflated Poisson spatial mu response mask has oracle and recovery evidence", {
  sim <- new_zi_poisson_spatial_mu_data()
  dat <- sim$data
  dat$count[seq(1L, nrow(dat), by = 50L)] <- NA_real_
  observed <- !is.na(dat$count)
  coords <- sim$coords
  # (single deterministic seed)
  cat(
    "\nmc-0662 fixture: n =", nrow(dat), " n_observed =", sum(observed),
    " zeros(observed) =", sum(dat$count[observed] == 0, na.rm = TRUE),
    " positives(observed) =", sum(dat$count[observed] > 0, na.rm = TRUE), "\n"
  )
  control <- drm_control(
    se = FALSE,
    optimizer = list(eval.max = 800, iter.max = 800)
  )
  fit_masked <- drmTMB(
    bf(count ~ x + spatial(1 | site, coords = coords), zi ~ 1),
    family = stats::poisson(link = "log"),
    data = dat,
    missing = miss_control(response = "include"),
    control = control
  )
  fit_observed <- drmTMB(
    bf(count ~ x + spatial(1 | site, coords = coords), zi ~ 1),
    family = stats::poisson(link = "log"),
    data = dat[observed, , drop = FALSE],
    control = control
  )
  cat(
    "mc-0662 fit_masked: convergence =", fit_masked$opt$convergence,
    " message =", fit_masked$opt$message, "\n"
  )
  cat(
    "mc-0662 fit_observed: convergence =", fit_observed$opt$convergence,
    " message =", fit_observed$opt$message, "\n"
  )

  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-.025, .025, length.out = length(obj$par))
  oracle_fn <- function(v) {
    zi_poisson_spatial_mu_nll(fit_masked, obj$env$parList(v), coords, dat$site)
  }

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(
    as.numeric(obj$gr(probe)), zi_central_gradient(oracle_fn, probe),
    tolerance = 2e-5
  )
  expect_missing_response_sentinel_invariant(
    fit_masked, response = "y", sentinels = c(0, 12)
  )
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "zi"), coef(fit_observed, "zi"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  # The mu intercept is not checked: a mean-zero spatial GMRF's finite draw
  # rarely averages to exactly zero, so the fixed intercept absorbs part of
  # the realized spatial mean (the same confound the zero-one-beta spatial mu
  # response-mask siblings avoid by checking only the slope coefficient).
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), .15)
  expect_lt(abs(coef(fit_masked, "zi")[[1L]] - sim$beta_zi[["(Intercept)"]]), .25)
  expect_lt(
    abs(fit_masked$sdpars$mu[["spatial(1 | site)"]] - sim$sd_spatial), .25
  )
})

new_zi_poisson_spatial_zi_data <- function(
  seed = 2026081922L,
  n_site = 64L,
  n_each = 50L,
  sd_spatial = 0.60,
  beta_mu = c(`(Intercept)` = 0.30, x = -0.25),
  beta_zi = c(`(Intercept)` = -1.00)
) {
  set.seed(seed)
  site_levels <- paste0("site_", seq_len(n_site))
  theta <- seq(0, 1.5 * pi, length.out = n_site)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_site) / (3 * n_site),
    y = sin(theta)
  )
  rownames(coords) <- site_levels
  precision <- zi_dense_spatial_precision(coords, site_levels)
  covariance <- solve(precision$Q)
  spatial_effect <- as.vector(
    t(chol(covariance)) %*% stats::rnorm(n_site, sd = sd_spatial)
  )
  names(spatial_effect) <- site_levels
  site <- rep(site_levels, each = n_each)
  x <- stats::rnorm(length(site))
  mu <- exp(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
  eta_zi <- beta_zi[["(Intercept)"]] + spatial_effect[site]
  zi <- stats::plogis(eta_zi)
  count <- ifelse(
    stats::runif(length(site)) < zi, 0L, stats::rpois(length(site), mu)
  )
  list(
    data = data.frame(count = count, x = x, site = site),
    coords = coords,
    beta_mu = beta_mu,
    beta_zi = beta_zi,
    sd_spatial = sd_spatial
  )
}

# Independent oracle: same two-component mixture as
# `zi_poisson_spatial_mu_nll()`, but the GMRF quadratic-form prior attaches
# to the spatial `zi` latent field (src/drmTMB.cpp model_type == 8,
# phylo_mu_dpar code 3 = zi) instead of `mu`.
zi_poisson_spatial_zi_nll <- function(fit, par, coords, site) {
  d <- fit$model$tmb_data
  u <- as.vector(par$u_phylo)
  precision <- zi_dense_spatial_precision(coords, unique(as.character(site)))
  expected_node_index <- match(site, precision$levels)
  expect_equal(d$phylo_mu_node_index + 1L, unname(expected_node_index))
  eta_mu <- as.vector(d$X_mu %*% par$beta_mu)
  eta_zi <- as.vector(d$X_zi %*% par$beta_zi) +
    d$phylo_mu_value[, 1] * u[expected_node_index]
  mu <- exp(eta_mu)
  zi <- stats::plogis(eta_zi)
  ll <- ifelse(
    d$y == 0,
    log(zi + (1 - zi) * stats::dpois(0, lambda = mu)),
    log1p(-zi) + stats::dpois(d$y, lambda = mu, log = TRUE)
  )
  prior <- 0.5 * (
    length(u) * log(2 * pi) +
      2 * length(u) * par$log_sd_phylo -
      precision$log_det_Q +
      exp(-2 * par$log_sd_phylo) * sum(u * as.vector(precision$Q %*% u))
  )
  observed <- as.logical(d$observed_y)
  prior - sum(d$weights[observed] * ll[observed])
}

test_that("zero-inflated Poisson spatial zi response mask has oracle and recovery evidence", {
  sim <- new_zi_poisson_spatial_zi_data()
  dat <- sim$data
  dat$count[seq(1L, nrow(dat), by = 50L)] <- NA_real_
  observed <- !is.na(dat$count)
  coords <- sim$coords
  # (single deterministic seed)
  cat(
    "\nmc-0667 fixture: n =", nrow(dat), " n_observed =", sum(observed),
    " zeros(observed) =", sum(dat$count[observed] == 0, na.rm = TRUE),
    " positives(observed) =", sum(dat$count[observed] > 0, na.rm = TRUE), "\n"
  )
  control <- drm_control(
    se = FALSE,
    optimizer = list(eval.max = 800, iter.max = 800)
  )
  fit_masked <- drmTMB(
    bf(count ~ x, zi ~ spatial(1 | site, coords = coords)),
    family = stats::poisson(link = "log"),
    data = dat,
    missing = miss_control(response = "include"),
    control = control
  )
  fit_observed <- drmTMB(
    bf(count ~ x, zi ~ spatial(1 | site, coords = coords)),
    family = stats::poisson(link = "log"),
    data = dat[observed, , drop = FALSE],
    control = control
  )
  cat(
    "mc-0667 fit_masked: convergence =", fit_masked$opt$convergence,
    " message =", fit_masked$opt$message, "\n"
  )
  cat(
    "mc-0667 fit_observed: convergence =", fit_observed$opt$convergence,
    " message =", fit_observed$opt$message, "\n"
  )

  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-.025, .025, length.out = length(obj$par))
  oracle_fn <- function(v) {
    zi_poisson_spatial_zi_nll(fit_masked, obj$env$parList(v), coords, dat$site)
  }

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(
    as.numeric(obj$gr(probe)), zi_central_gradient(oracle_fn, probe),
    tolerance = 2e-5
  )
  expect_missing_response_sentinel_invariant(
    fit_masked, response = "y", sentinels = c(0, 12)
  )
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "zi"), coef(fit_observed, "zi"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$zi, fit_observed$sdpars$zi, tolerance = 1e-6)
  # `mu` carries no structured term here, so both its coefficients are
  # unconfounded and checked directly. The zi intercept is not checked: a
  # mean-zero spatial GMRF's finite draw rarely averages to exactly zero, so
  # the fixed zi intercept absorbs part of the realized spatial mean (see the
  # matching comment on the mc-0662/mc-0641 mu-intercept confound above).
  expect_lt(
    max(abs(unname(coef(fit_masked, "mu")) - unname(sim$beta_mu))), .15
  )
  expect_lt(
    abs(fit_masked$sdpars$zi[["spatial(1 | site)"]] - sim$sd_spatial), .25
  )
})
