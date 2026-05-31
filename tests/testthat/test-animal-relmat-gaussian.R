new_known_relatedness_gaussian_data <- function(seed = 2026052001) {
  set.seed(seed)
  n_id <- 8L
  n_each <- 7L
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  sd_known <- 0.65
  sigma <- 0.22
  known_effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_id, sd = sd_known))
  names(known_effect) <- id_levels
  y <- 0.25 + 0.45 * x + known_effect[id] + stats::rnorm(length(id), sd = sigma)
  list(
    data = data.frame(y = y, x = x, id = id),
    K = K,
    Q = Q,
    sd_known = sd_known,
    sigma = sigma
  )
}

new_known_location_scale_gaussian_data <- function(
  seed = 20260616,
  n_id = 7L,
  n_each = 7L,
  sd_known = c(mu = 0.35, sigma = 0.16),
  rho_known = -0.20
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  z_mu <- stats::rnorm(n_id)
  z_sigma <- rho_known * z_mu + sqrt(1 - rho_known^2) * stats::rnorm(n_id)
  known_mu <- as.vector(t(chol(K)) %*% z_mu) * sd_known[["mu"]]
  known_sigma <- as.vector(t(chol(K)) %*% z_sigma) * sd_known[["sigma"]]
  names(known_mu) <- id_levels
  names(known_sigma) <- id_levels

  id <- rep(id_levels, each = n_each)
  x <- stats::rnorm(length(id))
  log_sigma <- -1.10 + known_sigma[id]
  y <- 0.20 +
    0.25 * x +
    known_mu[id] +
    exp(log_sigma) * stats::rnorm(length(id))

  list(
    data = data.frame(y = unname(y), x = x, id = id),
    K = K,
    Q = Q,
    sd_known = sd_known,
    rho_known = rho_known
  )
}

new_known_relatedness_gaussian_slope_data <- function(seed = 2026052104) {
  set.seed(seed)
  n_id <- 8L
  n_each <- 7L
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  sd_intercept <- 0.55
  sd_slope <- 0.32
  intercept_effect <- as.vector(
    t(chol(K)) %*% stats::rnorm(n_id, sd = sd_intercept)
  )
  slope_effect <- as.vector(
    t(chol(K)) %*% stats::rnorm(n_id, sd = sd_slope)
  )
  names(intercept_effect) <- id_levels
  names(slope_effect) <- id_levels
  sigma <- 0.22
  y <- 0.25 +
    0.45 * x +
    intercept_effect[id] +
    slope_effect[id] * x +
    stats::rnorm(length(id), sd = sigma)
  list(
    data = data.frame(y = y, x = x, id = id),
    K = K,
    Q = Q,
    sd_intercept = sd_intercept,
    sd_slope = sd_slope,
    sigma = sigma
  )
}

new_animal_pedigree_gaussian_data <- function(seed = 2026052102) {
  set.seed(seed)
  pedigree <- data.frame(
    id = paste0("id", seq_len(8L)),
    dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
    stringsAsFactors = FALSE
  )
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  Ainv <- solve(A)
  id_levels <- rownames(A)
  n_each <- 6L
  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), length(id_levels))
  sd_known <- 0.60
  sigma <- 0.20
  known_effect <- as.vector(t(chol(A)) %*% stats::rnorm(nrow(A), sd = sd_known))
  names(known_effect) <- id_levels
  y <- 0.30 + 0.35 * x + known_effect[id] + stats::rnorm(length(id), sd = sigma)
  list(
    data = data.frame(y = y, x = x, id = id),
    pedigree = pedigree,
    A = A,
    Ainv = Ainv,
    sd_known = sd_known,
    sigma = sigma
  )
}

dense_known_relatedness_gaussian_nll <- function(y, mu, sigma, sd_known, K) {
  covariance <- sigma^2 * diag(length(y)) + sd_known^2 * K
  chol_covariance <- chol(covariance)
  residual <- y - mu
  scaled <- forwardsolve(t(chol_covariance), residual)
  0.5 *
    (length(y) *
      log(2 * pi) +
      2 * sum(log(diag(chol_covariance))) +
      sum(scaled^2))
}

new_biv_known_relatedness_gaussian_data <- function(seed = 2026052101) {
  set.seed(seed)
  n_id <- 10L
  n_each <- 6L
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.40^abs(i - j))
  diag(K) <- diag(K) + 0.10
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  id <- rep(id_levels, each = n_each)
  x <- stats::rnorm(length(id))
  sd_known <- c(0.60, 0.50)
  rho_known <- 0.35
  sigma <- c(0.22, 0.24)
  rho12_true <- -0.10
  z1 <- stats::rnorm(n_id)
  z2 <- rho_known * z1 + sqrt(1 - rho_known^2) * stats::rnorm(n_id)
  known1 <- as.vector(t(chol(K)) %*% z1) * sd_known[[1L]]
  known2 <- as.vector(t(chol(K)) %*% z2) * sd_known[[2L]]
  names(known1) <- id_levels
  names(known2) <- id_levels
  e1 <- stats::rnorm(length(id))
  e2 <- rho12_true * e1 + sqrt(1 - rho12_true^2) * stats::rnorm(length(id))
  beta_mu1 <- c(`(Intercept)` = 0.25, x = 0.35)
  beta_mu2 <- c(`(Intercept)` = -0.15, x = -0.25)
  y1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * x + known1[id] + sigma[[1L]] * e1
  y2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * x + known2[id] + sigma[[2L]] * e2
  list(
    data = data.frame(y1 = y1, y2 = y2, x = x, id = id),
    K = K,
    Q = Q,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    sd_known = sd_known,
    rho_known = rho_known,
    sigma = sigma,
    rho12 = rho12_true
  )
}

new_biv_animal_pedigree_gaussian_data <- function(seed = 2026052103) {
  set.seed(seed)
  pedigree <- data.frame(
    id = paste0("id", seq_len(8L)),
    dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
    stringsAsFactors = FALSE
  )
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  Ainv <- solve(A)
  id_levels <- rownames(A)
  n_each <- 5L
  id <- rep(id_levels, each = n_each)
  x <- stats::rnorm(length(id))
  sd_known <- c(0.55, 0.45)
  rho_known <- 0.25
  sigma <- c(0.22, 0.24)
  rho12_true <- -0.05
  z1 <- stats::rnorm(nrow(A))
  z2 <- rho_known * z1 + sqrt(1 - rho_known^2) * stats::rnorm(nrow(A))
  known1 <- as.vector(t(chol(A)) %*% z1) * sd_known[[1L]]
  known2 <- as.vector(t(chol(A)) %*% z2) * sd_known[[2L]]
  names(known1) <- id_levels
  names(known2) <- id_levels
  e1 <- stats::rnorm(length(id))
  e2 <- rho12_true * e1 + sqrt(1 - rho12_true^2) * stats::rnorm(length(id))
  beta_mu1 <- c(`(Intercept)` = 0.25, x = 0.30)
  beta_mu2 <- c(`(Intercept)` = -0.20, x = -0.20)
  y1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * x + known1[id] + sigma[[1L]] * e1
  y2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * x + known2[id] + sigma[[2L]] * e2
  list(
    data = data.frame(y1 = y1, y2 = y2, x = x, id = id),
    pedigree = pedigree,
    A = A,
    Ainv = Ainv,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    sd_known = sd_known,
    rho_known = rho_known,
    sigma = sigma,
    rho12 = rho12_true
  )
}

new_biv_known_relatedness_q4_gaussian_data <- function(seed = 2026052111) {
  set.seed(seed)
  n_id <- 12L
  n_each <- 7L
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.32^abs(i - j))
  diag(K) <- diag(K) + 0.12
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  z <- rep(rep(c(-0.5, 0.5), length.out = n_each), n_id)
  beta_mu1 <- c(`(Intercept)` = 0.20, x = 0.28)
  beta_mu2 <- c(`(Intercept)` = -0.15, x = -0.22)
  beta_sigma1 <- c(`(Intercept)` = -1.05, z = 0.12)
  beta_sigma2 <- c(`(Intercept)` = -1.10, z = -0.10)
  sd_known <- c(mu1 = 0.42, mu2 = 0.36, sigma1 = 0.16, sigma2 = 0.14)
  corr <- matrix(
    c(
      1.00,
      0.35,
      0.12,
      -0.08,
      0.35,
      1.00,
      0.10,
      0.18,
      0.12,
      0.10,
      1.00,
      0.30,
      -0.08,
      0.18,
      0.30,
      1.00
    ),
    nrow = 4L,
    byrow = TRUE,
    dimnames = list(names(sd_known), names(sd_known))
  )
  covariance <- diag(sd_known) %*% corr %*% diag(sd_known)
  effect <- t(chol(K)) %*%
    matrix(stats::rnorm(n_id * 4L), nrow = n_id) %*%
    chol(covariance)
  dimnames(effect) <- list(id_levels, names(sd_known))
  eta_mu1 <- beta_mu1[[1L]] + beta_mu1[["x"]] * x + effect[id, "mu1"]
  eta_mu2 <- beta_mu2[[1L]] + beta_mu2[["x"]] * x + effect[id, "mu2"]
  log_sigma1 <- beta_sigma1[[1L]] +
    beta_sigma1[["z"]] * z +
    effect[id, "sigma1"]
  log_sigma2 <- beta_sigma2[[1L]] +
    beta_sigma2[["z"]] * z +
    effect[id, "sigma2"]
  rho12_true <- -0.08
  e1 <- stats::rnorm(length(id))
  e2 <- rho12_true * e1 + sqrt(1 - rho12_true^2) * stats::rnorm(length(id))
  y1 <- eta_mu1 + exp(log_sigma1) * e1
  y2 <- eta_mu2 + exp(log_sigma2) * e2

  list(
    data = data.frame(y1 = y1, y2 = y2, x = x, z = z, id = id),
    K = K,
    Q = Q,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    beta_sigma1 = beta_sigma1,
    beta_sigma2 = beta_sigma2,
    sd_known = sd_known,
    corr = corr,
    rho12 = rho12_true
  )
}

dense_biv_known_relatedness_gaussian_nll <- function(
  y1,
  y2,
  mu1,
  mu2,
  sigma1,
  sigma2,
  rho12,
  sd_known,
  rho_known,
  K
) {
  n <- length(y1)
  i1 <- seq.int(1L, by = 2L, length.out = n)
  i2 <- seq.int(2L, by = 2L, length.out = n)
  covariance <- matrix(0, nrow = 2L * n, ncol = 2L * n)
  covariance[i1, i1] <- sd_known[[1L]]^2 * K
  covariance[i2, i2] <- sd_known[[2L]]^2 * K
  covariance[i1, i2] <- rho_known * sd_known[[1L]] * sd_known[[2L]] * K
  covariance[i2, i1] <- t(covariance[i1, i2])
  covariance[cbind(i1, i1)] <- covariance[cbind(i1, i1)] + sigma1^2
  covariance[cbind(i2, i2)] <- covariance[cbind(i2, i2)] + sigma2^2
  residual_cov <- rho12 * sigma1 * sigma2
  covariance[cbind(i1, i2)] <- covariance[cbind(i1, i2)] + residual_cov
  covariance[cbind(i2, i1)] <- covariance[cbind(i2, i1)] + residual_cov

  y <- as.vector(rbind(y1, y2))
  mu <- as.vector(rbind(mu1, mu2))
  chol_covariance <- chol(covariance)
  residual <- y - mu
  scaled <- forwardsolve(t(chol_covariance), residual)
  0.5 *
    (length(y) *
      log(2 * pi) +
      2 * sum(log(diag(chol_covariance))) +
      sum(scaled^2))
}

test_that("animal pedigree helper builds additive relationships", {
  pedigree <- data.frame(
    id = c("offspring2", "dam", "sire", "offspring1"),
    dam = c("dam", NA, NA, "dam"),
    sire = c("sire", NA, NA, "sire"),
    stringsAsFactors = FALSE
  )
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  expected <- matrix(
    c(
      1.0,
      0.0,
      0.5,
      0.5,
      0.0,
      1.0,
      0.5,
      0.5,
      0.5,
      0.5,
      1.0,
      0.5,
      0.5,
      0.5,
      0.5,
      1.0
    ),
    nrow = 4L,
    byrow = TRUE,
    dimnames = list(
      c("dam", "sire", "offspring2", "offspring1"),
      c("dam", "sire", "offspring2", "offspring1")
    )
  )
  expect_equal(A, expected)
})

test_that("Gaussian mu fits relmat and animal known-precision intercepts", {
  sim <- new_known_relatedness_gaussian_data()
  dat <- sim$data
  K <- sim$K
  Q <- sim$Q

  fit_relmat <- drmTMB(
    bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ 1),
    data = dat
  )
  fit_animal <- drmTMB(
    bf(y ~ x + animal(1 | id, Ainv = Q), sigma ~ 1),
    data = dat
  )

  expect_equal(fit_relmat$opt$convergence, 0)
  expect_equal(fit_animal$opt$convergence, 0)
  expect_named(fit_relmat$sdpars$mu, "relmat(1 | id)")
  expect_named(fit_animal$sdpars$mu, "animal(1 | id)")
  expect_named(fit_relmat$random_effects, "relmat_mu")
  expect_named(fit_animal$random_effects, "animal_mu")
  expect_length(fit_relmat$random_effects$relmat_mu$values, nrow(sim$Q))
  expect_length(fit_animal$random_effects$animal_mu$values, nrow(sim$Q))

  checks <- check_drm(fit_relmat)
  relmat_check <- checks[checks$check == "relmat_mu_diagnostics", ]
  expect_equal(nrow(relmat_check), 1L)
  expect_equal(relmat_check$status, "ok")
  expect_match(relmat_check$value, "matrix_type=precision")

  targets <- profile_targets(fit_relmat)
  relmat_target <- targets[targets$parm == "sd:mu:relmat(1 | id)", ]
  expect_equal(nrow(relmat_target), 1L)
  expect_equal(relmat_target$tmb_parameter, "log_sd_phylo")
  expect_true(relmat_target$profile_ready)

  fit_relmat_K <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
    data = dat
  )
  fit_animal_A <- drmTMB(
    bf(y ~ x + animal(1 | id, A = K), sigma ~ 1),
    data = dat
  )
  expect_equal(
    as.numeric(stats::logLik(fit_relmat_K)),
    as.numeric(stats::logLik(fit_relmat)),
    tolerance = 1e-5
  )
  expect_equal(
    as.numeric(stats::logLik(fit_animal_A)),
    as.numeric(stats::logLik(fit_animal)),
    tolerance = 1e-5
  )
})

test_that("Gaussian supports animal and relmat residual-scale structured effects", {
  sim <- new_known_location_scale_gaussian_data()
  dat <- sim$data
  Q <- sim$Q

  fit_relmat <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, Q = Q),
      sigma ~ relmat(1 | id, Q = Q)
    ),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 400, iter.max = 400)
    )
  )
  fit_animal <- drmTMB(
    bf(
      y ~ x + animal(1 | id, Ainv = Q),
      sigma ~ animal(1 | id, Ainv = Q)
    ),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 400, iter.max = 400)
    )
  )

  expect_equal(fit_relmat$opt$convergence, 0)
  expect_equal(fit_animal$opt$convergence, 0)
  expect_named(fit_relmat$sdpars$mu, "mu:relmat(1 | id)")
  expect_named(fit_relmat$sdpars$sigma, "sigma:relmat(1 | id)")
  expect_named(fit_animal$sdpars$mu, "mu:animal(1 | id)")
  expect_named(fit_animal$sdpars$sigma, "sigma:animal(1 | id)")
  expect_named(
    fit_relmat$corpars$relmat,
    "cor(mu:(Intercept),sigma:(Intercept) | relmat | id)"
  )
  expect_named(
    fit_animal$corpars$animal,
    "cor(mu:(Intercept),sigma:(Intercept) | animal | id)"
  )

  fixed_sigma <- as.vector(
    fit_relmat$model$X$sigma %*% coef(fit_relmat, "sigma")
  )
  expect_equal(
    unname(predict(fit_relmat, dpar = "sigma", type = "link")),
    fixed_sigma + drmTMB:::phylo_mu_contribution(fit_relmat, dpar = "sigma"),
    tolerance = 1e-8
  )
  expect_true(
    "sd:sigma:sigma:relmat(1 | id)" %in% profile_targets(fit_relmat)$parm
  )
  expect_true(
    "sd:sigma:sigma:animal(1 | id)" %in% profile_targets(fit_animal)$parm
  )
  expect_equal(corpairs(fit_relmat, level = "relmat")$class, "mean-scale")
  expect_equal(corpairs(fit_animal, level = "animal")$class, "mean-scale")
})

test_that("Gaussian mu fits animal pedigree intercepts", {
  sim <- new_animal_pedigree_gaussian_data()
  dat <- sim$data
  pedigree <- sim$pedigree
  A <- sim$A
  Ainv <- sim$Ainv

  fit_pedigree <- drmTMB(
    bf(y ~ x + animal(1 | id, pedigree = pedigree), sigma ~ 1),
    data = dat
  )
  fit_A <- drmTMB(
    bf(y ~ x + animal(1 | id, A = A), sigma ~ 1),
    data = dat
  )
  fit_Ainv <- drmTMB(
    bf(y ~ x + animal(1 | id, Ainv = Ainv), sigma ~ 1),
    data = dat
  )

  checks <- check_drm(fit_pedigree)
  animal_check <- checks[checks$check == "animal_mu_diagnostics", ]

  expect_equal(fit_pedigree$opt$convergence, 0)
  expect_equal(
    as.numeric(stats::logLik(fit_pedigree)),
    as.numeric(stats::logLik(fit_A)),
    tolerance = 1e-5
  )
  expect_equal(
    as.numeric(stats::logLik(fit_pedigree)),
    as.numeric(stats::logLik(fit_Ainv)),
    tolerance = 1e-5
  )
  expect_named(fit_pedigree$sdpars$mu, "animal(1 | id)")
  expect_named(fit_pedigree$random_effects, "animal_mu")
  expect_equal(nrow(animal_check), 1L)
  expect_match(animal_check$value, "matrix_type=covariance")
})

test_that("animal and relmat Gaussian mu support one structured slope", {
  sim <- new_known_relatedness_gaussian_slope_data()
  animal_sim <- new_animal_pedigree_gaussian_data(seed = 2026052105)
  Q <- sim$Q
  pedigree <- animal_sim$pedigree

  fit_relmat <- drmTMB(
    bf(y ~ x + relmat(1 + x | id, Q = Q), sigma ~ 1),
    family = gaussian(),
    data = sim$data
  )
  fit_animal <- drmTMB(
    bf(y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1),
    family = gaussian(),
    data = animal_sim$data
  )

  for (fit in list(fit_relmat, fit_animal)) {
    type <- fit$model$structured$phylo_mu$type
    key <- paste0(type, "_mu")
    sd_names <- c(paste0(type, "(1 | id)"), paste0(type, "(0 + x | id)"))
    expect_equal(fit$opt$convergence, 0)
    expect_equal(fit$model$structured$phylo_mu$q, 2L)
    expect_equal(
      fit$model$structured$phylo_mu$coef_names,
      c("(Intercept)", "x")
    )
    expect_named(fit$sdpars$mu, sd_names)
    expect_true(all(is.finite(fit$sdpars$mu[sd_names])))
    expect_true(all(unname(fit$sdpars$mu[sd_names]) > 0))
    expect_equal(fit$corpars, list())

    structured_re <- ranef(fit, key)
    expect_equal(structured_re, fit$random_effects[[key]])
    expect_named(structured_re$terms, sd_names)
    expect_length(
      structured_re$values,
      2L * fit$model$structured$phylo_mu$n_re
    )

    targets <- profile_targets(fit)
    sd_targets <- targets[
      targets$parm %in% paste0("sd:mu:", sd_names),
    ]
    sd_targets <- sd_targets[
      match(paste0("sd:mu:", sd_names), sd_targets$parm),
    ]
    expect_equal(sd_targets$parm, paste0("sd:mu:", sd_names))
    expect_equal(sd_targets$tmb_parameter, rep("log_sd_phylo", 2L))
    expect_equal(sd_targets$index, 1:2)
    expect_equal(sd_targets$target_type, rep("direct", 2L))
    expect_true(all(sd_targets$profile_ready))

    chk <- check_drm(fit)
    known_check <- chk[chk$check == paste0(type, "_mu_diagnostics"), ]
    expect_equal(nrow(known_check), 1L)
    expect_match(known_check$value, "n_coef=2", fixed = TRUE)
    expect_match(known_check$value, "min_structured_sd=", fixed = TRUE)
    expect_match(known_check$value, "min_sd_ratio=", fixed = TRUE)
  }

  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 + x | p | id, Q = Q), sigma ~ 1),
      family = gaussian(),
      data = sim$data
    ),
    "covariance-block labels currently require intercept-only structured terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 + x | p | id, pedigree = pedigree), sigma ~ 1),
      family = gaussian(),
      data = animal_sim$data
    ),
    "covariance-block labels currently require intercept-only structured terms"
  )
})

test_that("bivariate Gaussian mu fits relmat and animal q2 known-matrix covariance", {
  sim <- new_biv_known_relatedness_gaussian_data()
  dat <- sim$data
  K <- sim$K
  Q <- sim$Q

  fit_relmat <- drmTMB(
    bf(
      mu1 = y1 ~ x + relmat(1 | p | id, Q = Q),
      mu2 = y2 ~ x + relmat(1 | p | id, Q = Q),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )
  fit_animal <- drmTMB(
    bf(
      mu1 = y1 ~ x + animal(1 | p | id, Ainv = Q),
      mu2 = y2 ~ x + animal(1 | p | id, Ainv = Q),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )

  fixed_mu1 <- as.vector(
    stats::model.matrix(~x, dat) %*% coef(fit_relmat, "mu1")
  )
  fixed_mu2 <- as.vector(
    stats::model.matrix(~x, dat) %*% coef(fit_relmat, "mu2")
  )
  K_obs <- sim$K[dat$id, dat$id]
  dense_nll <- dense_biv_known_relatedness_gaussian_nll(
    y1 = dat$y1,
    y2 = dat$y2,
    mu1 = fixed_mu1,
    mu2 = fixed_mu2,
    sigma1 = stats::sigma(fit_relmat)$sigma1[[1L]],
    sigma2 = stats::sigma(fit_relmat)$sigma2[[1L]],
    rho12 = rho12(fit_relmat)[[1L]],
    sd_known = unname(fit_relmat$sdpars$mu),
    rho_known = unname(fit_relmat$corpars$relmat),
    K = K_obs
  )
  relmat_pairs <- corpairs(fit_relmat, level = "relmat")
  animal_pairs <- corpairs(fit_animal, level = "animal")
  relmat_cov <- summary(fit_relmat)$covariance
  relmat_check <- check_drm(fit_relmat)
  relmat_diagnostic <- relmat_check[
    relmat_check$check == "relmat_mu_diagnostics",
  ]
  targets <- profile_targets(fit_relmat)
  relmat_profile_names <- c(
    "sd:mu:mu1:relmat(1 | p | id)",
    "sd:mu:mu2:relmat(1 | p | id)",
    "cor:relmat:cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  )
  relmat_profile <- targets[
    match(relmat_profile_names, targets$parm),
    ,
    drop = FALSE
  ]

  expect_equal(fit_relmat$opt$convergence, 0)
  expect_equal(fit_animal$opt$convergence, 0)
  expect_named(
    fit_relmat$sdpars$mu,
    c("mu1:relmat(1 | p | id)", "mu2:relmat(1 | p | id)")
  )
  expect_named(
    fit_animal$sdpars$mu,
    c("mu1:animal(1 | p | id)", "mu2:animal(1 | p | id)")
  )
  expect_named(
    fit_relmat$corpars$relmat,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  )
  expect_named(
    fit_animal$corpars$animal,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  )
  expect_named(fit_relmat$random_effects, "relmat_mu")
  expect_named(fit_animal$random_effects, "animal_mu")
  expect_equal(length(fit_relmat$random_effects$relmat_mu$values), 2L * nrow(Q))
  expect_equal(length(fit_animal$random_effects$animal_mu$values), 2L * nrow(Q))
  expect_equal(fit_relmat$opt$objective, dense_nll, tolerance = 1e-4)
  expect_equal(nrow(relmat_pairs), 1L)
  expect_equal(relmat_pairs$estimate, unname(fit_relmat$corpars$relmat))
  expect_equal(nrow(animal_pairs), 1L)
  expect_equal(animal_pairs$estimate, unname(fit_animal$corpars$animal))
  expect_equal(relmat_cov$level, "relmat")
  expect_equal(relmat_cov$parameter, names(fit_relmat$corpars$relmat))
  expect_equal(nrow(relmat_diagnostic), 1L)
  expect_equal(relmat_diagnostic$status, "ok")
  expect_match(relmat_diagnostic$value, "n_coef=2")
  expect_equal(relmat_profile$parm, relmat_profile_names)
  expect_equal(
    relmat_profile$tmb_parameter,
    c("log_sd_phylo", "log_sd_phylo", "eta_cor_phylo")
  )
  expect_equal(relmat_profile$index, c(1L, 2L, 1L))
  expect_equal(relmat_profile$target_type, rep("direct", 3L))

  fit_relmat_K <- drmTMB(
    bf(
      mu1 = y1 ~ x + relmat(1 | p | id, K = K),
      mu2 = y2 ~ x + relmat(1 | p | id, K = K),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )
  expect_equal(
    as.numeric(stats::logLik(fit_relmat_K)),
    as.numeric(stats::logLik(fit_relmat)),
    tolerance = 1e-5
  )
})

test_that("bivariate Gaussian mu fits animal q2 pedigree covariance", {
  sim <- new_biv_animal_pedigree_gaussian_data()
  dat <- sim$data
  pedigree <- sim$pedigree
  A <- sim$A

  fit_pedigree <- drmTMB(
    bf(
      mu1 = y1 ~ x + animal(1 | p | id, pedigree = pedigree),
      mu2 = y2 ~ x + animal(1 | p | id, pedigree = pedigree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )
  fit_A <- drmTMB(
    bf(
      mu1 = y1 ~ x + animal(1 | p | id, A = A),
      mu2 = y2 ~ x + animal(1 | p | id, A = A),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )

  animal_pairs <- corpairs(fit_pedigree, level = "animal")

  expect_equal(fit_pedigree$opt$convergence, 0)
  expect_equal(
    as.numeric(stats::logLik(fit_pedigree)),
    as.numeric(stats::logLik(fit_A)),
    tolerance = 1e-5
  )
  expect_named(
    fit_pedigree$sdpars$mu,
    c("mu1:animal(1 | p | id)", "mu2:animal(1 | p | id)")
  )
  expect_named(
    fit_pedigree$corpars$animal,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  )
  expect_equal(nrow(animal_pairs), 1L)
})

test_that("bivariate Gaussian supports animal and relmat q4 known-matrix blocks", {
  sim <- new_biv_known_relatedness_q4_gaussian_data()
  dat <- sim$data
  Q <- sim$Q

  fit_relmat <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + relmat(1 | p | id, Q = Q),
        mu2 = y2 ~ x + relmat(1 | p | id, Q = Q),
        sigma1 = ~ z + relmat(1 | p | id, Q = Q),
        sigma2 = ~ z + relmat(1 | p | id, Q = Q),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = drm_control(
        se = FALSE,
        optimizer = list(eval.max = 800, iter.max = 800)
      )
    )
  )
  fit_animal <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + animal(1 | p | id, Ainv = Q),
        mu2 = y2 ~ x + animal(1 | p | id, Ainv = Q),
        sigma1 = ~ z + animal(1 | p | id, Ainv = Q),
        sigma2 = ~ z + animal(1 | p | id, Ainv = Q),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = drm_control(
        se = FALSE,
        optimizer = list(eval.max = 800, iter.max = 800)
      )
    )
  )

  relmat_pairs <- corpairs(fit_relmat, level = "relmat")
  animal_pairs <- corpairs(fit_animal, level = "animal")
  relmat_cov <- summary(fit_relmat)$covariance
  relmat_targets <- profile_targets(fit_relmat)
  relmat_cor_targets <- relmat_targets[
    startsWith(relmat_targets$parm, "cor:relmat:"),
    ,
    drop = FALSE
  ]
  relmat_check <- check_drm(fit_relmat)
  q4_check <- relmat_check[
    relmat_check$check == "biv_relmat_q4_covariance",
    ,
    drop = FALSE
  ]

  expect_true(is.finite(fit_relmat$opt$objective))
  expect_true(is.finite(fit_animal$opt$objective))
  expect_named(
    fit_relmat$sdpars$mu,
    c(
      "mu1:relmat(1 | p | id)",
      "mu2:relmat(1 | p | id)",
      "sigma1:relmat(1 | p | id)",
      "sigma2:relmat(1 | p | id)"
    )
  )
  expect_named(
    fit_animal$sdpars$mu,
    c(
      "mu1:animal(1 | p | id)",
      "mu2:animal(1 | p | id)",
      "sigma1:animal(1 | p | id)",
      "sigma2:animal(1 | p | id)"
    )
  )
  expect_equal(sum(names(fit_relmat$opt$par) == "theta_phylo"), 6L)
  expect_equal(sum(names(fit_animal$opt$par) == "theta_phylo"), 6L)
  expect_equal(nrow(relmat_pairs), 6L)
  expect_equal(nrow(animal_pairs), 6L)
  expect_equal(nrow(relmat_cov), 6L)
  expect_equal(relmat_pairs$level, rep("relmat", 6L))
  expect_equal(animal_pairs$level, rep("animal", 6L))
  expect_equal(
    as.integer(table(relmat_pairs$class)[
      c("mean-mean", "mean-scale", "scale-scale")
    ]),
    c(1L, 4L, 1L)
  )
  expect_equal(nrow(corpairs(fit_relmat, class = "location-scale")), 4L)
  expect_equal(relmat_cov$parameter, relmat_pairs$parameter)
  expect_equal(nrow(relmat_cor_targets), 6L)
  expect_equal(relmat_cor_targets$tmb_parameter, rep("theta_phylo", 6L))
  expect_equal(relmat_cor_targets$target_type, rep("derived", 6L))
  expect_false(any(relmat_cor_targets$profile_ready))
  expect_equal(
    relmat_cor_targets$profile_note,
    rep("derived_unstructured_correlation", 6L)
  )
  expect_equal(nrow(q4_check), 1L)
  expect_match(q4_check$value, "q=4")
  expect_match(q4_check$message, "relmat q4 location-scale")
  expect_lt(max(abs(coef(fit_relmat, "mu1") - sim$beta_mu1)), 0.45)
  expect_lt(max(abs(coef(fit_relmat, "mu2") - sim$beta_mu2)), 0.45)
  expect_lt(max(abs(coef(fit_relmat, "sigma1") - sim$beta_sigma1)), 0.45)
  expect_lt(max(abs(coef(fit_relmat, "sigma2") - sim$beta_sigma2)), 0.45)
})

test_that("relmat known-precision likelihood matches dense marginal Gaussian", {
  sim <- new_known_relatedness_gaussian_data(seed = 2026052002)
  dat <- sim$data
  Q <- sim$Q
  fit <- drmTMB(
    bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ 1),
    data = dat
  )

  beta <- coef(fit, "mu")
  X <- stats::model.matrix(~x, dat)
  mu <- as.vector(X %*% beta)
  sigma <- unname(sigma(fit))
  sd_known <- unname(fit$sdpars$mu[["relmat(1 | id)"]])
  K_obs <- sim$K[dat$id, dat$id]
  expect_equal(
    as.numeric(stats::logLik(fit)),
    -dense_known_relatedness_gaussian_nll(
      y = dat$y,
      mu = mu,
      sigma = sigma,
      sd_known = sd_known,
      K = K_obs
    ),
    tolerance = 1e-5
  )
})

test_that("animal and relmat reject unsupported or malformed known matrices", {
  sim <- new_known_relatedness_gaussian_data()
  dat <- sim$data
  Q <- sim$Q
  ped_sim <- new_animal_pedigree_gaussian_data()
  pedigree_valid <- ped_sim$pedigree
  pedigree_missing_parent <- pedigree_valid
  pedigree_missing_parent$dam[[5L]] <- "missing"
  pedigree_cycle <- pedigree_valid
  pedigree_cycle$dam[[1L]] <- "id5"
  bad_Q <- sim$Q
  rownames(bad_Q)[[1L]] <- "missing_id"

  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 | id, pedigree = pedigree_missing_parent), sigma ~ 1),
      data = ped_sim$data
    ),
    "parents must appear"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 | id, pedigree = pedigree_cycle), sigma ~ 1),
      data = ped_sim$data
    ),
    "parent-offspring cycles"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, Q = bad_Q), sigma ~ 1),
      data = dat
    ),
    "row and column names must match"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y ~ x + relmat(1 | id, Q = Q),
        mu2 = y ~ x + relmat(1 | id, Q = Q),
        sigma1 = ~ relmat(1 | id, Q = Q),
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Partial relmat location-scale blocks"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y ~ x + animal(1 | id, Ainv = Q),
        mu2 = y ~ x + animal(1 | id, Ainv = Q),
        sigma1 = ~ animal(1 | id, Ainv = Q),
        sigma2 = ~ animal(1 | id, Ainv = Q),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "explicit covariance-block label"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y ~ x + relmat(1 | p | id, Q = Q),
        mu2 = y ~ x + relmat(1 | q | id, Q = Q),
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "same covariance-block label"
  )
})
