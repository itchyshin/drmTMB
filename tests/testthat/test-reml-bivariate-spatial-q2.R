arc1b_spatial_kernel <- function(coords, jitter = 1e-6) {
  distances <- as.matrix(stats::dist(as.matrix(coords[, 1:2, drop = FALSE])))
  positive <- distances[distances > 0]
  range <- stats::median(positive)
  covariance <- exp(-distances / range)
  diag(covariance) <- diag(covariance) + jitter
  dimnames(covariance) <- list(rownames(coords), rownames(coords))
  covariance
}

arc1b_biv_spatial_fixture <- function(
  seed = 2026071402,
  n_site = 14L,
  n_each = 4L
) {
  set.seed(seed)
  site_levels <- paste0("site_", seq_len(n_site))
  theta <- seq(0, 1.5 * pi, length.out = n_site)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_site) / (3 * n_site),
    y = sin(theta)
  )
  rownames(coords) <- site_levels
  K <- arc1b_spatial_kernel(coords)
  L <- t(chol(K))

  truth <- c(
    tau1 = 0.80,
    tau2 = 0.65,
    rho_spatial = 0.35,
    sigma1 = 0.30,
    sigma2 = 0.35,
    rho12 = -0.20
  )
  z1 <- stats::rnorm(n_site)
  z2 <- stats::rnorm(n_site)
  a1 <- truth[["tau1"]] * as.vector(L %*% z1)
  a2 <- truth[["tau2"]] * as.vector(
    L %*% (
      truth[["rho_spatial"]] * z1 +
        sqrt(1 - truth[["rho_spatial"]]^2) * z2
    )
  )
  names(a1) <- names(a2) <- site_levels

  site <- rep(site_levels, each = n_each)
  x1 <- stats::rnorm(length(site))
  x2 <- stats::rnorm(length(site))
  e1 <- stats::rnorm(length(site))
  e2 <- truth[["rho12"]] * e1 +
    sqrt(1 - truth[["rho12"]]^2) * stats::rnorm(length(site))
  dat <- data.frame(
    y1 = 0.30 + 0.50 * x1 + a1[site] + truth[["sigma1"]] * e1,
    y2 = -0.20 - 0.25 * x2 + a2[site] + truth[["sigma2"]] * e2,
    x1 = x1,
    x2 = x2,
    site = site
  )
  list(data = dat, coords = coords, K = K, truth = truth)
}

arc1b_spatial_q2_formula <- function(coords) {
  force(coords)
  bf(
    mu1 = y1 ~ x1 + spatial(1 | p | site, coords = coords),
    mu2 = y2 ~ x2 + spatial(1 | p | site, coords = coords),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
}

arc1b_reml_problem <- function(fx) {
  dat <- fx$data
  site_levels <- rownames(fx$coords)
  site_index <- match(dat$site, site_levels)
  K_obs <- fx$K[site_index, site_index, drop = FALSE]
  n <- nrow(dat)
  X1 <- stats::model.matrix(~x1, dat)
  X2 <- stats::model.matrix(~x2, dat)
  X <- rbind(
    cbind(X1, matrix(0, n, ncol(X2))),
    cbind(matrix(0, n, ncol(X1)), X2)
  )
  y <- c(dat$y1, dat$y2)
  identity_n <- diag(n)

  nll <- function(par, swap_correlations = FALSE) {
    tau1 <- exp(par[[1L]])
    tau2 <- exp(par[[2L]])
    rho_spatial <- 0.999999 * tanh(par[[3L]])
    sigma1 <- exp(par[[4L]])
    sigma2 <- exp(par[[5L]])
    rho12 <- 0.999999 * tanh(par[[6L]])
    if (isTRUE(swap_correlations)) {
      tmp <- rho_spatial
      rho_spatial <- rho12
      rho12 <- tmp
    }
    V11 <- tau1^2 * K_obs + sigma1^2 * identity_n
    V22 <- tau2^2 * K_obs + sigma2^2 * identity_n
    V12 <- rho_spatial * tau1 * tau2 * K_obs +
      rho12 * sigma1 * sigma2 * identity_n
    V <- rbind(cbind(V11, V12), cbind(V12, V22))
    chol_V <- chol(V)
    ViX <- backsolve(chol_V, forwardsolve(t(chol_V), X))
    Viy <- backsolve(chol_V, forwardsolve(t(chol_V), y))
    XtViX <- crossprod(X, ViX)
    beta <- solve(XtViX, crossprod(X, Viy))
    residual <- y - as.vector(X %*% beta)
    Vir <- backsolve(
      chol_V,
      forwardsolve(t(chol_V), residual)
    )
    log_det_V <- 2 * sum(log(diag(chol_V)))
    log_det_X <- as.numeric(determinant(XtViX, logarithm = TRUE)$modulus)
    0.5 * (
      (length(y) - ncol(X)) * log(2 * pi) +
        log_det_V +
        log_det_X +
        sum(residual * Vir)
    )
  }

  beta <- function(par) {
    tau1 <- exp(par[[1L]])
    tau2 <- exp(par[[2L]])
    rho_spatial <- 0.999999 * tanh(par[[3L]])
    sigma1 <- exp(par[[4L]])
    sigma2 <- exp(par[[5L]])
    rho12 <- 0.999999 * tanh(par[[6L]])
    V11 <- tau1^2 * K_obs + sigma1^2 * identity_n
    V22 <- tau2^2 * K_obs + sigma2^2 * identity_n
    V12 <- rho_spatial * tau1 * tau2 * K_obs +
      rho12 * sigma1 * sigma2 * identity_n
    V <- rbind(cbind(V11, V12), cbind(V12, V22))
    Vi <- solve(V)
    solve(crossprod(X, Vi %*% X), crossprod(X, Vi %*% y))
  }
  list(nll = nll, beta = beta, X = X, y = y, K_obs = K_obs)
}

arc1b_tmb_outer_to_common <- function(fit, par = fit$opt$par) {
  take <- function(name) unname(par[names(par) == name])
  c(
    take("log_sd_phylo")[[1L]],
    take("log_sd_phylo")[[2L]],
    take("eta_cor_phylo")[[1L]],
    take("beta_sigma1")[[1L]],
    take("beta_sigma2")[[1L]],
    take("beta_rho12")[[1L]]
  )
}

arc1b_common_to_tmb_outer <- function(fit, common) {
  par <- fit$opt$par
  par[names(par) == "log_sd_phylo"] <- common[1:2]
  par[names(par) == "eta_cor_phylo"] <- common[[3L]]
  par[names(par) == "beta_sigma1"] <- common[[4L]]
  par[names(par) == "beta_sigma2"] <- common[[5L]]
  par[names(par) == "beta_rho12"] <- common[[6L]]
  par
}

test_that("bivariate spatial q2 REML matches the dense restricted likelihood", {
  skip_on_cran()
  fx <- arc1b_biv_spatial_fixture()
  dat <- fx$data
  coords <- fx$coords
  fit <- drmTMB(
    arc1b_spatial_q2_formula(coords),
    family = biv_gaussian(),
    data = dat,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )

  expect_identical(fit$estimator, "REML")
  expect_identical(fit$opt$convergence, 0L)
  expect_identical(
    fit$model$tmb_random_names,
    c("u_phylo", "beta_mu1", "beta_mu2")
  )
  expect_equal(attr(stats::logLik(fit), "df"), length(fit$opt$par) + 4L)

  production_K <- solve(as.matrix(
    fit$model$structured$phylo_mu$precision$precision
  ))
  expect_equal(production_K, fx$K, tolerance = 1e-12)

  problem <- arc1b_reml_problem(fx)
  truth <- fx$truth
  start <- c(
    log(truth[["tau1"]]),
    log(truth[["tau2"]]),
    atanh(truth[["rho_spatial"]] / 0.999999),
    log(truth[["sigma1"]]),
    log(truth[["sigma2"]]),
    atanh(truth[["rho12"]] / 0.999999)
  )
  oracle <- stats::optim(
    start,
    problem$nll,
    method = "BFGS",
    control = list(reltol = 1e-12, maxit = 2000L)
  )
  expect_identical(oracle$convergence, 0L)

  common <- arc1b_tmb_outer_to_common(fit)
  expect_equal(problem$nll(common), fit$opt$objective, tolerance = 1e-5)
  expect_equal(common, oracle$par, tolerance = 2e-3)
  expect_equal(
    c(as.numeric(fit$par$mu1), as.numeric(fit$par$mu2)),
    as.numeric(problem$beta(common)),
    tolerance = 5e-5
  )

  displacements <- list(
    c(+0.06, -0.04, +0.05, +0.03, -0.02, -0.04),
    c(-0.05, +0.07, -0.04, -0.03, +0.05, +0.03)
  )
  tmb_base <- fit$obj$fn(arc1b_common_to_tmb_outer(fit, common))
  oracle_base <- problem$nll(common)
  for (displacement in displacements) {
    displaced <- common + displacement
    expect_equal(
      as.numeric(
        fit$obj$fn(arc1b_common_to_tmb_outer(fit, displaced)) - tmb_base
      ),
      as.numeric(problem$nll(displaced) - oracle_base),
      tolerance = 1e-5
    )
  }
  wrong_delta <- problem$nll(common + displacements[[1L]], TRUE) -
    problem$nll(common, TRUE)
  correct_delta <- problem$nll(common + displacements[[1L]]) - oracle_base
  expect_gt(abs(wrong_delta - correct_delta), 1e-3)

  expect_named(
    fit$sdpars$mu,
    c("mu1:spatial(1 | p | site)", "mu2:spatial(1 | p | site)")
  )
  expect_named(
    fit$corpars$spatial,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | site)"
  )
  pair <- corpairs(fit, level = "spatial")
  expect_equal(pair$level, "spatial")
  expect_equal(pair$class, "mean-mean")
  expect_equal(pair$estimate, unname(fit$corpars$spatial))
})

test_that("bivariate spatial q2 REML keeps adjacent shapes rejected", {
  skip_on_cran()
  fx <- arc1b_biv_spatial_fixture(n_site = 8L, n_each = 3L)
  dat <- fx$data
  coords <- fx$coords
  Q <- solve(fx$K)
  dimnames(Q) <- list(rownames(coords), rownames(coords))

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + spatial(1 | site, coords = coords),
        mu2 = y2 ~ x2 + spatial(1 | site, coords = coords),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "requires matching labelled"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + spatial(0 + x1 | p | site, coords = coords),
        mu2 = y2 ~ x2 + spatial(0 + x1 | p | site, coords = coords),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "requires matching labelled"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + spatial(1 + x1 | p | site, coords = coords),
        mu2 = y2 ~ x2 + spatial(1 + x1 | p | site, coords = coords),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "requires matching labelled"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + spatial(1 | p | site, coords = coords),
        mu2 = y2 ~ x2 + spatial(1 | p | site, coords = coords),
        sigma1 = ~x1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "constant.*sigma1"
  )
  expect_error(
    drmTMB(
      arc1b_spatial_q2_formula(coords),
      family = biv_gaussian(), data = dat, REML = TRUE,
      weights = rep(c(1, 2), length.out = nrow(dat))
    ),
    "unit weights"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + spatial(1 | p | site, coords = coords) + (1 | g | id),
        mu2 = y2 ~ x2 + spatial(1 | p | site, coords = coords) + (1 | g | id),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(),
      data = transform(dat, id = rep(seq_len(nrow(dat) / 2L), each = 2L)),
      REML = TRUE
    ),
    "no other random-effect layer"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + animal(1 | p | site, Ainv = Q),
        mu2 = y2 ~ x2 + animal(1 | p | site, Ainv = Q),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "animal/relatedness providers"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | site, Q = Q),
        mu2 = y2 ~ x2 + relmat(1 | p | site, Q = Q),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "animal/relatedness providers"
  )
})
