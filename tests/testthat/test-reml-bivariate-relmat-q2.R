arc1b_s2r_K <- function(g) {
  level <- sprintf("id_%03d", seq_len(g))
  K <- outer(seq_len(g), seq_len(g), function(i, j) 0.4^abs(i - j))
  dimnames(K) <- list(level, level)
  K
}

arc1b_s2r_fixture <- function(seed = 2026071502L, g = 14L, m = 4L) {
  set.seed(seed)
  K <- arc1b_s2r_K(g)
  level <- rownames(K)
  L <- t(chol(K))
  truth <- c(
    tau1 = 0.80,
    tau2 = 0.65,
    rho_K = 0.35,
    sigma1 = 0.30,
    sigma2 = 0.35,
    rho12 = -0.20
  )
  z1 <- stats::rnorm(g)
  z2 <- stats::rnorm(g)
  u1 <- truth[["tau1"]] * as.vector(L %*% z1)
  u2 <- truth[["tau2"]] * as.vector(
    L %*% (
      truth[["rho_K"]] * z1 +
        sqrt(1 - truth[["rho_K"]]^2) * z2
    )
  )
  names(u1) <- names(u2) <- level
  id <- factor(rep(level, each = m), levels = level)
  x1 <- stats::rnorm(length(id))
  x2 <- stats::rnorm(length(id))
  e1 <- stats::rnorm(length(id))
  e2 <- truth[["rho12"]] * e1 +
    sqrt(1 - truth[["rho12"]]^2) * stats::rnorm(length(id))
  data <- data.frame(
    y1 = 0.30 + 0.50 * x1 + u1[as.character(id)] + truth[["sigma1"]] * e1,
    y2 = -0.20 - 0.25 * x2 + u2[as.character(id)] + truth[["sigma2"]] * e2,
    x1 = x1,
    x2 = x2,
    z = stats::rnorm(length(id)),
    ecology = stats::rnorm(length(id)),
    id = id,
    cluster = factor(rep(seq_len(length(id) / 2L), each = 2L))
  )
  list(data = data, K = K, truth = truth)
}

arc1b_s2r_formula <- function(K) {
  force(K)
  bf(
    mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
    mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
}

arc1b_s2r_multi_label_formula <- function(K, n_blocks) {
  block_terms <- paste(
    sprintf("relmat(1 | p%d | id, K = K)", seq_len(n_blocks)),
    collapse = " + "
  )
  environment <- environment()
  do.call(bf, list(
    mu1 = stats::as.formula(
      paste("y1 ~ x1 +", block_terms),
      env = environment
    ),
    mu2 = stats::as.formula(
      paste("y2 ~ x2 +", block_terms),
      env = environment
    ),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  ))
}

arc1b_s2r_problem <- function(fx) {
  dat <- fx$data
  index <- match(as.character(dat$id), rownames(fx$K))
  K_obs <- fx$K[index, index, drop = FALSE]
  Q <- solve(fx$K)
  Q_obs <- Q[index, index, drop = FALSE]
  n <- nrow(dat)
  X1 <- stats::model.matrix(~x1, dat)
  X2 <- stats::model.matrix(~x2, dat)
  X <- rbind(
    cbind(X1, matrix(0, n, ncol(X2))),
    cbind(matrix(0, n, ncol(X1)), X2)
  )
  y <- c(dat$y1, dat$y2)
  identity_n <- diag(n)

  components <- function(par, wrong_precision = FALSE) {
    tau1 <- exp(par[[1L]])
    tau2 <- exp(par[[2L]])
    rho_K <- 0.999999 * tanh(par[[3L]])
    sigma1 <- exp(par[[4L]])
    sigma2 <- exp(par[[5L]])
    rho12 <- 0.999999 * tanh(par[[6L]])
    kernel <- if (isTRUE(wrong_precision)) Q_obs else K_obs
    V11 <- tau1^2 * kernel + sigma1^2 * identity_n
    V22 <- tau2^2 * kernel + sigma2^2 * identity_n
    V12 <- rho_K * tau1 * tau2 * kernel +
      rho12 * sigma1 * sigma2 * identity_n
    V <- rbind(cbind(V11, V12), cbind(V12, V22))
    chol_V <- chol(V)
    ViX <- backsolve(chol_V, forwardsolve(t(chol_V), X))
    Viy <- backsolve(chol_V, forwardsolve(t(chol_V), y))
    XtViX <- crossprod(X, ViX)
    beta <- solve(XtViX, crossprod(X, Viy))
    residual <- y - as.vector(X %*% beta)
    Vir <- backsolve(chol_V, forwardsolve(t(chol_V), residual))
    list(
      beta = beta,
      nll = 0.5 * (
        (length(y) - ncol(X)) * log(2 * pi) +
          2 * sum(log(diag(chol_V))) +
          as.numeric(determinant(XtViX, logarithm = TRUE)$modulus) +
          sum(residual * Vir)
      )
    )
  }
  list(
    nll = function(par, wrong_precision = FALSE) {
      components(par, wrong_precision)$nll
    },
    beta = function(par) components(par)$beta
  )
}

arc1b_s2r_tmb_to_common <- function(fit, par = fit$opt$par) {
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

arc1b_s2r_common_to_tmb <- function(fit, common) {
  par <- fit$opt$par
  par[names(par) == "log_sd_phylo"] <- common[1:2]
  par[names(par) == "eta_cor_phylo"] <- common[[3L]]
  par[names(par) == "beta_sigma1"] <- common[[4L]]
  par[names(par) == "beta_sigma2"] <- common[[5L]]
  par[names(par) == "beta_rho12"] <- common[[6L]]
  par
}

test_that("bivariate relmat K q2 REML matches dense restricted likelihood", {
  skip_on_cran()
  fx <- arc1b_s2r_fixture()
  fit <- drmTMB(
    arc1b_s2r_formula(fx$K),
    family = biv_gaussian(),
    data = fx$data,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )

  expect_true(drmTMB:::drm_reml_admits_biv_relmat_q2_intercept(fit$model))
  for (provider in c("animal", "spatial", "phylo")) {
    other_provider <- fit$model
    other_provider$structured$phylo_mu$type <- provider
    expect_false(
      drmTMB:::drm_reml_admits_biv_relmat_q2_intercept(other_provider),
      info = provider
    )
  }

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

  problem <- arc1b_s2r_problem(fx)
  truth <- fx$truth
  start <- c(
    log(truth[["tau1"]]),
    log(truth[["tau2"]]),
    atanh(truth[["rho_K"]] / 0.999999),
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

  common <- arc1b_s2r_tmb_to_common(fit)
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
  tmb_base <- fit$obj$fn(arc1b_s2r_common_to_tmb(fit, common))
  oracle_base <- problem$nll(common)
  for (displacement in displacements) {
    displaced <- common + displacement
    expect_equal(
      as.numeric(
        fit$obj$fn(arc1b_s2r_common_to_tmb(fit, displaced)) - tmb_base
      ),
      as.numeric(problem$nll(displaced) - oracle_base),
      tolerance = 1e-5
    )
  }
  wrong_delta <- problem$nll(
    common + displacements[[1L]],
    wrong_precision = TRUE
  ) - problem$nll(common, wrong_precision = TRUE)
  correct_delta <- problem$nll(common + displacements[[1L]]) - oracle_base
  expect_gt(abs(wrong_delta - correct_delta), 1e-3)

  expect_named(
    fit$sdpars$mu,
    c("mu1:relmat(1 | p | id)", "mu2:relmat(1 | p | id)")
  )
  expect_equal(unname(fit$sdpars$mu), exp(common[1:2]), tolerance = 1e-8)
  expect_named(
    fit$corpars$relmat,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  )
  expect_equal(
    unname(fit$corpars$relmat),
    0.999999 * tanh(common[[3L]]),
    tolerance = 1e-8
  )
  expect_equal(
    c(
      unname(stats::sigma(fit)$sigma1[[1L]]),
      unname(stats::sigma(fit)$sigma2[[1L]])
    ),
    exp(common[4:5]),
    tolerance = 1e-8
  )
  expect_equal(
    unname(rho12(fit)[[1L]]),
    0.999999 * tanh(common[[6L]]),
    tolerance = 1e-8
  )
  pair <- corpairs(fit, level = "relmat")
  expect_equal(pair$estimate, unname(fit$corpars$relmat))
})

test_that("bivariate relmat K q2 REML keeps K ordering and neighbours exact", {
  skip_on_cran()
  fx <- arc1b_s2r_fixture(seed = 2026071504L)
  dat <- fx$data
  K <- fx$K
  dat$id2 <- dat$id
  fit <- drmTMB(
    arc1b_s2r_formula(K),
    family = biv_gaussian(), data = dat, REML = TRUE
  )
  reverse <- rev(seq_len(nrow(K)))
  K_permuted <- K[reverse, reverse, drop = FALSE]
  fit_permuted <- drmTMB(
    arc1b_s2r_formula(K_permuted),
    family = biv_gaussian(), data = dat, REML = TRUE
  )
  expect_equal(fit_permuted$opt$objective, fit$opt$objective, tolerance = 1e-6)
  expect_equal(fit_permuted$opt$par, fit$opt$par, tolerance = 1e-6)
  expect_equal(fit_permuted$par$mu1, fit$par$mu1, tolerance = 1e-6)
  expect_equal(fit_permuted$par$mu2, fit$par$mu2, tolerance = 1e-6)
  expect_equal(fit_permuted$sdpars$mu, fit$sdpars$mu, tolerance = 1e-6)
  expect_equal(fit_permuted$corpars$relmat, fit$corpars$relmat, tolerance = 1e-6)
  expect_equal(stats::sigma(fit_permuted), stats::sigma(fit), tolerance = 1e-6)
  expect_equal(rho12(fit_permuted), rho12(fit), tolerance = 1e-6)

  Q <- solve(K)

  fit_ml_K <- drmTMB(
    arc1b_s2r_formula(K),
    family = biv_gaussian(), data = dat, REML = FALSE
  )
  fit_ml_Q <- drmTMB(
    bf(
      mu1 = y1 ~ x1 + relmat(1 | p | id, Q = Q),
      mu2 = y2 ~ x2 + relmat(1 | p | id, Q = Q),
      sigma1 = ~1, sigma2 = ~1, rho12 = ~1
    ),
    family = biv_gaussian(), data = dat, REML = FALSE
  )
  expect_identical(fit_ml_K$estimator, "ML")
  expect_identical(fit_ml_Q$estimator, "ML")
  expect_identical(fit_ml_K$opt$convergence, 0L)
  expect_identical(fit_ml_Q$opt$convergence, 0L)
  expect_equal(fit_ml_Q$opt$objective, fit_ml_K$opt$objective, tolerance = 1e-5)
  expect_equal(fit_ml_Q$sdpars$mu, fit_ml_K$sdpars$mu, tolerance = 1e-5)

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, Q = Q),
        mu2 = y2 ~ x2 + relmat(1 | p | id, Q = Q),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "supplied-.*K|relatedness|deferred"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | p | id, Q = Q),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "same grouping variable and matrix object|same representation|matching"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | id, K = K),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "matching labelled|label"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p1 | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | p2 | id, K = K),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "matching labelled|same.*label|exact fixed-covariance"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | p | id2, K = K),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "same grouping|matching labelled|exact fixed-covariance"
  )
  K_alt <- outer(
    seq_len(nrow(K)), seq_len(ncol(K)),
    function(i, j) 0.5^abs(i - j)
  )
  dimnames(K_alt) <- dimnames(K)
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | p | id, K = K_alt),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "same grouping variable and matrix object|matching labelled"
  )
  K_copy <- K
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | p | id, K = K_copy),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "same grouping variable and matrix object|matching labelled"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
        mu2 = y2 ~ x2,
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "matched in.*mu1.*mu2|matching labelled"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(0 + z | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(0 + z | p | id, K = K),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "intercept|q2|deferred"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 + z | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 + z | p | id, K = K),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "q4|slopes|exact fixed-covariance"
  )
  for (n_blocks in c(2L, 3L, 4L, 6L)) {
    expect_error(
      drmTMB(
        arc1b_s2r_multi_label_formula(K, n_blocks),
        family = biv_gaussian(), data = dat, REML = TRUE
      ),
      "Only one.*relmat|contains.*relmat|exactly one|multiple|q4|q6|q8|q12|matching labelled|fixed-covariance",
      info = paste0("q", 2L * n_blocks)
    )
  }
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
        sigma1 = ~1 + relmat(1 | s | id, K = K),
        sigma2 = ~1 + relmat(1 | s | id, K = K),
        rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "scale-side|exact fixed-covariance|location blocks"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1,
        mu2 = y2 ~ x2,
        sigma1 = ~1 + relmat(1 | s | id, K = K),
        sigma2 = ~1 + relmat(1 | s | id, K = K),
        rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "scale-side|exact fixed-covariance|location blocks"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
        sigma1 = ~x1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "constant|intercept"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, K = K) + (1 | r | cluster),
        mu2 = y2 ~ x2 + relmat(1 | p | id, K = K) + (1 | r | cluster),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "no other random-effect layer|other.*layer"
  )
  expect_error(
    drmTMB(
      arc1b_s2r_formula(K),
      family = biv_gaussian(), data = dat, REML = TRUE,
      weights = rep(c(1, 2), length.out = nrow(dat))
    ),
    "unit weights"
  )
  dat_na <- dat
  dat_na$y2[[1L]] <- NA_real_
  expect_error(
    drmTMB(
      arc1b_s2r_formula(K),
      family = biv_gaussian(), data = dat_na, REML = TRUE,
      missing = miss_control(response = "include")
    ),
    "missing-data engines|complete"
  )

  V <- diag(2L * nrow(dat)) * 0.05
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + meta_V(V = V) + relmat(1 | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "cannot yet be combined with.*meta_V|Known covariance"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1,
        sd1(id) ~ ecology
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "No bivariate location random-effect term matches|direct ordinary"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
        mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1,
        corpair(id, level = "relmat", block = "p", from = "mu1", to = "mu2") ~
          ecology
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "Predictor-dependent relmat|corpair|planned"
  )
  expect_error(
    drmTMB(
      arc1b_s2r_formula(K),
      family = student(), data = dat, REML = TRUE
    ),
    "bivariate|Gaussian"
  )
  expect_error(
    drmTMB(
      arc1b_s2r_formula(K),
      family = biv_gaussian(), data = dat, REML = TRUE,
      estimator = "AI-REML"
    ),
    "does not use arguments"
  )

  Q_animal <- solve(K)
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + animal(1 | p | id, Ainv = Q_animal),
        mu2 = y2 ~ x2 + animal(1 | p | id, Ainv = Q_animal),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "animal"
  )

  K_no_names <- unname(K)
  expect_error(
    drmTMB(
      arc1b_s2r_formula(K_no_names),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "non-empty row and column names"
  )
  K_duplicate <- K
  rownames(K_duplicate)[[2L]] <- rownames(K_duplicate)[[1L]]
  colnames(K_duplicate)[[2L]] <- colnames(K_duplicate)[[1L]]
  expect_error(
    drmTMB(
      arc1b_s2r_formula(K_duplicate),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "names must be unique"
  )
  K_unmatched <- K
  rownames(K_unmatched)[[nrow(K_unmatched)]] <- "id_not_fitted"
  colnames(K_unmatched)[[ncol(K_unmatched)]] <- "id_not_fitted"
  expect_error(
    drmTMB(
      arc1b_s2r_formula(K_unmatched),
      family = biv_gaussian(), data = dat, REML = TRUE
    ),
    "not present|unmatched|fitted group|matrix names|id_"
  )
})
