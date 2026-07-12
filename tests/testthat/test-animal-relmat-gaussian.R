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

new_animal_sigma_slope_gaussian_data <- function(
  seed = 20260634,
  n_each = 9L,
  sd_known = c(`(Intercept)` = 0.28, x = 0.16),
  beta_mu = c(`(Intercept)` = 0.25, x = 0.20),
  beta_sigma = c(`(Intercept)` = -1.05)
) {
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
  intercept_effect <- as.vector(
    t(chol(A)) %*% stats::rnorm(nrow(A), sd = sd_known[["(Intercept)"]])
  )
  slope_effect <- as.vector(
    t(chol(A)) %*% stats::rnorm(nrow(A), sd = sd_known[["x"]])
  )
  names(intercept_effect) <- id_levels
  names(slope_effect) <- id_levels

  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), length(id_levels))
  log_sigma <- beta_sigma[[1L]] +
    intercept_effect[id] +
    slope_effect[id] * x
  y <- beta_mu[[1L]] +
    beta_mu[["x"]] * x +
    exp(log_sigma) * stats::rnorm(length(id))

  list(
    data = data.frame(y = y, x = x, id = id),
    pedigree = pedigree,
    A = A,
    Ainv = Ainv,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_known = sd_known
  )
}

new_known_relatedness_sigma_slope_data <- function(
  seed = 20260635,
  n_id = 8L,
  n_each = 9L,
  sd_known = c(`(Intercept)` = 0.28, x = 0.16),
  beta_mu = c(`(Intercept)` = 0.25, x = 0.20),
  beta_sigma = c(`(Intercept)` = -1.05)
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  intercept_effect <- as.vector(
    t(chol(K)) %*% stats::rnorm(n_id, sd = sd_known[["(Intercept)"]])
  )
  slope_effect <- as.vector(
    t(chol(K)) %*% stats::rnorm(n_id, sd = sd_known[["x"]])
  )
  names(intercept_effect) <- id_levels
  names(slope_effect) <- id_levels

  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  log_sigma <- beta_sigma[[1L]] +
    intercept_effect[id] +
    slope_effect[id] * x
  y <- beta_mu[[1L]] +
    beta_mu[["x"]] * x +
    exp(log_sigma) * stats::rnorm(length(id))

  list(
    data = data.frame(y = y, x = x, id = id),
    K = K,
    Q = Q,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_known = sd_known
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
  K <- sim$K
  Q <- sim$Q
  pedigree <- animal_sim$pedigree

  fit_relmat <- drmTMB(
    bf(y ~ x + relmat(1 + x | id, Q = Q), sigma ~ 1),
    family = gaussian(),
    data = sim$data
  )
  fit_relmat_K <- drmTMB(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1),
    family = gaussian(),
    data = sim$data
  )
  fit_animal <- drmTMB(
    bf(y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1),
    family = gaussian(),
    data = animal_sim$data
  )

  for (fit in list(fit_relmat, fit_relmat_K, fit_animal)) {
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

  expect_equal(
    as.numeric(stats::logLik(fit_relmat_K)),
    as.numeric(stats::logLik(fit_relmat)),
    tolerance = 1e-5
  )
  expect_equal(
    unname(coef(fit_relmat_K, "mu")),
    unname(coef(fit_relmat, "mu")),
    tolerance = 1e-5
  )
  expect_equal(
    unname(fit_relmat_K$sdpars$mu),
    unname(fit_relmat$sdpars$mu),
    tolerance = 1e-5
  )

  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 + x | p | id, Q = Q), sigma ~ 1),
      family = gaussian(),
      data = sim$data
    ),
    "all-four bivariate Gaussian block"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 + x | p | id, pedigree = pedigree), sigma ~ 1),
      family = gaussian(),
      data = animal_sim$data
    ),
    "all-four bivariate Gaussian block"
  )
})

test_that("Gaussian sigma supports animal A-matrix one structured slope", {
  sim <- new_animal_sigma_slope_gaussian_data()
  A <- sim$A

  fit <- drmTMB(
    bf(y ~ x, sigma ~ animal(1 + x | id, A = A)),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 600, iter.max = 600)
    )
  )

  sd_names <- c("animal(1 | id)", "animal(0 + x | id)")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$structured$phylo_mu$type, "animal")
  expect_equal(
    drmTMB:::phylo_mu_dpars(fit$model$structured$phylo_mu),
    "sigma"
  )
  expect_equal(fit$model$structured$phylo_mu$q, 2L)
  expect_equal(
    fit$model$structured$phylo_mu$coef_names,
    c("(Intercept)", "x")
  )
  expect_null(fit$sdpars$mu)
  expect_named(fit$sdpars$sigma, sd_names)
  expect_true(all(is.finite(fit$sdpars$sigma[sd_names])))
  expect_true(all(unname(fit$sdpars$sigma[sd_names]) > 0))
  expect_equal(fit$corpars, list())

  animal_re <- ranef(fit, "animal_mu")
  expect_equal(animal_re, fit$random_effects$animal_mu)
  expect_named(animal_re$terms, sd_names)
  expect_length(animal_re$values, 2L * fit$model$structured$phylo_mu$n_re)

  targets <- profile_targets(fit)
  animal_targets <- targets[
    targets$parm %in% paste0("sd:sigma:", sd_names),
  ]
  animal_targets <- animal_targets[
    match(paste0("sd:sigma:", sd_names), animal_targets$parm),
  ]
  expect_equal(animal_targets$parm, paste0("sd:sigma:", sd_names))
  expect_equal(animal_targets$tmb_parameter, rep("log_sd_phylo", 2L))
  expect_equal(animal_targets$index, 1:2)
  expect_equal(animal_targets$target_type, rep("direct", 2L))
  expect_true(all(animal_targets$profile_ready))

  index <- fit$model$structured$phylo_mu$observation_node_index
  manual_animal <- animal_re$terms[[sd_names[[1L]]]][index] +
    sim$data$x * animal_re$terms[[sd_names[[2L]]]][index]
  expect_equal(
    drmTMB:::phylo_mu_contribution(fit, dpar = "sigma"),
    unname(manual_animal),
    tolerance = 1e-8
  )
  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  conditional_sigma <- predict(fit, dpar = "sigma", type = "link")
  expect_equal(
    unname(conditional_sigma),
    fixed_sigma + drmTMB:::phylo_mu_contribution(fit, dpar = "sigma"),
    tolerance = 1e-8
  )
  expect_true(is.finite(as.numeric(stats::logLik(fit))))

  matched_fit <- drmTMB(
    bf(
      y ~ x + animal(1 + x | id, A = A),
      sigma ~ animal(1 + x | id, A = A)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 800, iter.max = 800)
    )
  )
  mu_names <- c("mu:animal(1 | id)", "mu:animal(0 + x | id)")
  sigma_names <- c("sigma:animal(1 | id)", "sigma:animal(0 + x | id)")
  expect_equal(matched_fit$opt$convergence, 0)
  expect_equal(matched_fit$model$structured$phylo_mu$type, "animal")
  expect_equal(
    drmTMB:::phylo_mu_dpars(matched_fit$model$structured$phylo_mu),
    c("mu", "mu", "sigma", "sigma")
  )
  expect_equal(matched_fit$model$structured$phylo_mu$q, 4L)
  expect_equal(
    matched_fit$model$structured$phylo_mu$coef_names,
    c("(Intercept)", "x", "(Intercept)", "x")
  )
  expect_named(matched_fit$sdpars$mu, mu_names)
  expect_named(matched_fit$sdpars$sigma, sigma_names)
  expect_equal(matched_fit$corpars, list())
  expect_equal(
    structured_effects(matched_fit)$endpoint_member_set,
    "mu:(Intercept)+mu:x+sigma:(Intercept)+sigma:x"
  )
  expect_named(ranef(matched_fit, "animal_mu")$terms, c(mu_names, sigma_names))
  expect_true(is.finite(as.numeric(stats::logLik(matched_fit))))

  expect_error(
    drmTMB(
      bf(
        y ~ x + animal(1 + x | id, A = A),
        sigma ~ animal(1 | id, A = A)
      ),
      family = gaussian(),
      data = sim$data
    ),
    "matching intercept-only or one-slope structured terms"
  )
})

test_that("Gaussian sigma supports relmat K/Q one structured slope", {
  sim <- new_known_relatedness_sigma_slope_data()
  K <- sim$K
  Q <- sim$Q

  fit_K <- drmTMB(
    bf(y ~ x, sigma ~ relmat(1 + x | id, K = K)),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 600, iter.max = 600)
    )
  )
  fit_Q <- drmTMB(
    bf(y ~ x, sigma ~ relmat(1 + x | id, Q = Q)),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 600, iter.max = 600)
    )
  )

  sd_names <- c("relmat(1 | id)", "relmat(0 + x | id)")
  for (fit in list(fit_K, fit_Q)) {
    expect_equal(fit$opt$convergence, 0)
    expect_equal(fit$model$structured$phylo_mu$type, "relmat")
    expect_equal(
      drmTMB:::phylo_mu_dpars(fit$model$structured$phylo_mu),
      "sigma"
    )
    expect_equal(fit$model$structured$phylo_mu$q, 2L)
    expect_equal(
      fit$model$structured$phylo_mu$coef_names,
      c("(Intercept)", "x")
    )
    expect_null(fit$sdpars$mu)
    expect_named(fit$sdpars$sigma, sd_names)
    expect_true(all(is.finite(fit$sdpars$sigma[sd_names])))
    expect_true(all(unname(fit$sdpars$sigma[sd_names]) > 0))
    expect_equal(fit$corpars, list())

    relmat_re <- ranef(fit, "relmat_mu")
    expect_equal(relmat_re, fit$random_effects$relmat_mu)
    expect_named(relmat_re$terms, sd_names)
    expect_length(relmat_re$values, 2L * fit$model$structured$phylo_mu$n_re)

    targets <- profile_targets(fit)
    relmat_targets <- targets[
      targets$parm %in% paste0("sd:sigma:", sd_names),
    ]
    relmat_targets <- relmat_targets[
      match(paste0("sd:sigma:", sd_names), relmat_targets$parm),
    ]
    expect_equal(relmat_targets$parm, paste0("sd:sigma:", sd_names))
    expect_equal(relmat_targets$tmb_parameter, rep("log_sd_phylo", 2L))
    expect_equal(relmat_targets$index, 1:2)
    expect_equal(relmat_targets$target_type, rep("direct", 2L))
    expect_true(all(relmat_targets$profile_ready))

    index <- fit$model$structured$phylo_mu$observation_node_index
    manual_relmat <- relmat_re$terms[[sd_names[[1L]]]][index] +
      sim$data$x * relmat_re$terms[[sd_names[[2L]]]][index]
    expect_equal(
      drmTMB:::phylo_mu_contribution(fit, dpar = "sigma"),
      unname(manual_relmat),
      tolerance = 1e-8
    )
    fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
    conditional_sigma <- predict(fit, dpar = "sigma", type = "link")
    expect_equal(
      unname(conditional_sigma),
      fixed_sigma + drmTMB:::phylo_mu_contribution(fit, dpar = "sigma"),
      tolerance = 1e-8
    )
    expect_true(is.finite(as.numeric(stats::logLik(fit))))
  }

  expect_equal(
    as.numeric(stats::logLik(fit_K)),
    as.numeric(stats::logLik(fit_Q)),
    tolerance = 1e-5
  )
  expect_equal(
    unname(coef(fit_K, "sigma")),
    unname(coef(fit_Q, "sigma")),
    tolerance = 1e-5
  )
  expect_equal(
    unname(fit_K$sdpars$sigma),
    unname(fit_Q$sdpars$sigma),
    tolerance = 1e-5
  )

  matched_K <- drmTMB(
    bf(
      y ~ x + relmat(1 + x | id, K = K),
      sigma ~ relmat(1 + x | id, K = K)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 800, iter.max = 800)
    )
  )
  matched_Q <- drmTMB(
    bf(
      y ~ x + relmat(1 + x | id, Q = Q),
      sigma ~ relmat(1 + x | id, Q = Q)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 800, iter.max = 800)
    )
  )
  mu_names <- c("mu:relmat(1 | id)", "mu:relmat(0 + x | id)")
  sigma_names <- c("sigma:relmat(1 | id)", "sigma:relmat(0 + x | id)")
  for (fit in list(matched_K, matched_Q)) {
    expect_equal(fit$opt$convergence, 0)
    expect_equal(fit$model$structured$phylo_mu$type, "relmat")
    expect_equal(
      drmTMB:::phylo_mu_dpars(fit$model$structured$phylo_mu),
      c("mu", "mu", "sigma", "sigma")
    )
    expect_equal(fit$model$structured$phylo_mu$q, 4L)
    expect_equal(
      fit$model$structured$phylo_mu$coef_names,
      c("(Intercept)", "x", "(Intercept)", "x")
    )
    expect_named(fit$sdpars$mu, mu_names)
    expect_named(fit$sdpars$sigma, sigma_names)
    expect_equal(fit$corpars, list())
    expect_equal(
      structured_effects(fit)$endpoint_member_set,
      "mu:(Intercept)+mu:x+sigma:(Intercept)+sigma:x"
    )
    expect_named(ranef(fit, "relmat_mu")$terms, c(mu_names, sigma_names))
    expect_true(is.finite(as.numeric(stats::logLik(fit))))
  }
  expect_equal(
    as.numeric(stats::logLik(matched_K)),
    as.numeric(stats::logLik(matched_Q)),
    tolerance = 1e-5
  )
  expect_equal(
    unname(matched_K$sdpars$mu),
    unname(matched_Q$sdpars$mu),
    tolerance = 1e-5
  )
  expect_equal(
    unname(matched_K$sdpars$sigma),
    unname(matched_Q$sdpars$sigma),
    tolerance = 1e-5
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
  relmat_q2_diagnostic <- relmat_check[
    relmat_check$check == "biv_relmat_q2_covariance",
    ,
    drop = FALSE
  ]
  animal_check <- check_drm(fit_animal)
  animal_q2_diagnostic <- animal_check[
    animal_check$check == "biv_animal_q2_covariance",
    ,
    drop = FALSE
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
  expect_equal(nrow(relmat_q2_diagnostic), 1L)
  expect_equal(relmat_q2_diagnostic$status, "ok")
  expect_match(relmat_q2_diagnostic$value, "rho_abs=")
  expect_match(relmat_q2_diagnostic$message, "relmat q2 location covariance")
  expect_equal(nrow(animal_q2_diagnostic), 1L)
  expect_equal(animal_q2_diagnostic$status, "ok")
  expect_match(animal_q2_diagnostic$value, "rho_abs=")
  expect_match(
    animal_q2_diagnostic$message,
    "Animal-model q2 location covariance"
  )
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

  near_relmat <- fit_relmat
  near_relmat$corpars$relmat[] <- 0.995
  near_relmat_chk <- check_drm(near_relmat, rho_boundary = 0.98)
  near_relmat_q2 <- near_relmat_chk[
    near_relmat_chk$check == "biv_relmat_q2_covariance",
    ,
    drop = FALSE
  ]

  near_animal <- fit_animal
  near_animal$corpars$animal[] <- 0.995
  near_animal_chk <- check_drm(near_animal, rho_boundary = 0.98)
  near_animal_q2 <- near_animal_chk[
    near_animal_chk$check == "biv_animal_q2_covariance",
    ,
    drop = FALSE
  ]

  expect_equal(near_relmat_q2$status, "warning")
  expect_match(near_relmat_q2$value, "rho_abs=0.9950")
  expect_match(near_relmat_q2$message, "close to \\+/-1")
  expect_false(attr(near_relmat_chk, "ok"))
  expect_equal(near_animal_q2$status, "warning")
  expect_match(near_animal_q2$value, "rho_abs=0.9950")
  expect_match(near_animal_q2$message, "close to \\+/-1")
  expect_false(attr(near_animal_chk, "ok"))
})

test_that("bivariate Gaussian mu supports known-matrix q2 slope-only covariance", {
  sim <- new_biv_known_relatedness_gaussian_data()
  dat <- sim$data
  K <- sim$K
  Q <- sim$Q

  fit_relmat <- drmTMB(
    bf(
      mu1 = y1 ~ x + relmat(0 + x | p | id, Q = Q),
      mu2 = y2 ~ x + relmat(0 + x | p | id, Q = Q),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 500, iter.max = 500)
    )
  )
  fit_animal <- drmTMB(
    bf(
      mu1 = y1 ~ x + animal(0 + x | p | id, Ainv = Q),
      mu2 = y2 ~ x + animal(0 + x | p | id, Ainv = Q),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 500, iter.max = 500)
    )
  )
  fit_relmat_K <- drmTMB(
    bf(
      mu1 = y1 ~ x + relmat(0 + x | p | id, K = K),
      mu2 = y2 ~ x + relmat(0 + x | p | id, K = K),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 500, iter.max = 500)
    )
  )

  fixed_mu1 <- as.vector(
    stats::model.matrix(~x, dat) %*% coef(fit_relmat, "mu1")
  )
  fixed_mu2 <- as.vector(
    stats::model.matrix(~x, dat) %*% coef(fit_relmat, "mu2")
  )
  relmat_structured <- fit_relmat$model$structured$phylo_mu
  animal_structured <- fit_animal$model$structured$phylo_mu
  relmat_pairs <- corpairs(fit_relmat, level = "relmat")
  animal_pairs <- corpairs(fit_animal, level = "animal")
  relmat_cov <- summary(fit_relmat)$covariance
  animal_cov <- summary(fit_animal)$covariance
  targets <- profile_targets(fit_relmat)
  profile_names <- c(
    "sd:mu:mu1:relmat(0 + x | p | id)",
    "sd:mu:mu2:relmat(0 + x | p | id)",
    "cor:relmat:cor(mu1:x,mu2:x | p | id)"
  )
  profile <- targets[match(profile_names, targets$parm), , drop = FALSE]
  structured_row <- structured_effects(fit_relmat)

  expect_equal(fit_relmat$opt$convergence, 0)
  expect_equal(fit_animal$opt$convergence, 0)
  expect_equal(fit_relmat_K$opt$convergence, 0)
  expect_equal(relmat_structured$type, "relmat")
  expect_equal(animal_structured$type, "animal")
  expect_equal(relmat_structured$q, 2L)
  expect_equal(animal_structured$q, 2L)
  expect_equal(relmat_structured$coef_names, c("x", "x"))
  expect_equal(animal_structured$coef_names, c("x", "x"))
  expect_named(
    fit_relmat$sdpars$mu,
    c("mu1:relmat(0 + x | p | id)", "mu2:relmat(0 + x | p | id)")
  )
  expect_named(
    fit_animal$sdpars$mu,
    c("mu1:animal(0 + x | p | id)", "mu2:animal(0 + x | p | id)")
  )
  expect_named(fit_relmat$corpars$relmat, "cor(mu1:x,mu2:x | p | id)")
  expect_named(fit_animal$corpars$animal, "cor(mu1:x,mu2:x | p | id)")
  expect_equal(
    as.numeric(stats::logLik(fit_relmat_K)),
    as.numeric(stats::logLik(fit_relmat)),
    tolerance = 1e-5
  )
  expect_equal(nrow(relmat_pairs), 1L)
  expect_equal(relmat_pairs$from_coef, "x")
  expect_equal(relmat_pairs$to_coef, "x")
  expect_equal(relmat_pairs$class, "slope-slope")
  expect_equal(relmat_pairs$parameter, names(fit_relmat$corpars$relmat))
  expect_equal(nrow(animal_pairs), 1L)
  expect_equal(animal_pairs$from_coef, "x")
  expect_equal(animal_pairs$to_coef, "x")
  expect_equal(animal_pairs$class, "slope-slope")
  expect_equal(animal_pairs$parameter, names(fit_animal$corpars$animal))
  expect_equal(nrow(relmat_cov), 1L)
  expect_equal(relmat_cov$from_coef, "x")
  expect_equal(relmat_cov$to_coef, "x")
  expect_equal(relmat_cov$class, "slope-slope")
  expect_equal(relmat_cov$parameter, names(fit_relmat$corpars$relmat))
  expect_equal(nrow(animal_cov), 1L)
  expect_equal(animal_cov$from_coef, "x")
  expect_equal(animal_cov$to_coef, "x")
  expect_equal(animal_cov$class, "slope-slope")
  expect_equal(animal_cov$parameter, names(fit_animal$corpars$animal))
  expect_equal(profile$parm, profile_names)
  expect_equal(
    profile$tmb_parameter,
    c("log_sd_phylo", "log_sd_phylo", "eta_cor_phylo")
  )
  expect_equal(profile$index, c(1L, 2L, 1L))
  expect_equal(profile$target_type, rep("direct", 3L))
  expect_equal(profile$profile_ready, rep(TRUE, 3L))
  expect_equal(structured_row$endpoint_set, "mu1+mu2")
  expect_equal(structured_row$coefficient_set, "x+x")
  expect_equal(structured_row$endpoint_member_set, "mu1:x+mu2:x")
  expect_equal(structured_row$endpoint_member_count, 2L)
  expect_equal(structured_row$covariance_layout, "scalar")
  manual_mu1 <- fit_relmat$random_effects$relmat_mu$values[
    relmat_structured$observation_node_index
  ] *
    relmat_structured$value[, 1L]
  manual_mu2 <- fit_relmat$random_effects$relmat_mu$values[
    relmat_structured$observation_node_index + relmat_structured$n_re
  ] *
    relmat_structured$value[, 2L]
  expect_equal(
    drmTMB:::phylo_mu_contribution(fit_relmat, dpar = "mu1"),
    unname(manual_mu1),
    tolerance = 1e-10
  )
  expect_equal(
    drmTMB:::phylo_mu_contribution(fit_relmat, dpar = "mu2"),
    unname(manual_mu2),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit_relmat, dpar = "mu1"),
    fixed_mu1 + drmTMB:::phylo_mu_contribution(fit_relmat, dpar = "mu1"),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit_relmat, dpar = "mu2"),
    fixed_mu2 + drmTMB:::phylo_mu_contribution(fit_relmat, dpar = "mu2"),
    tolerance = 1e-10
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
  # Near-boundary bivariate-Gaussian q4 structured recovery fit whose q4
  # diagnostic-message classification is not reproducible across BLAS/LAPACK
  # builds (same fragile class as the spatial q4 block; shared check.R q4
  # location-scale path). Skip on CRAN; runs in the full tag-CI matrix + locally.
  skip_on_cran()
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
        multi_start = 3L,
        fallback_optimizer = "BFGS",
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
        multi_start = 3L,
        fallback_optimizer = "BFGS",
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

test_that("bivariate Gaussian supports animal and relmat q4 all-four one-slope blocks", {
  skip_on_cran()
  sim <- new_biv_known_relatedness_q4_gaussian_data()
  dat <- sim$data
  K <- sim$K
  Q <- sim$Q

  q8_control <- drm_control(
    se = FALSE,
    fallback_optimizer = "BFGS",
    optimizer = list(eval.max = 350, iter.max = 350)
  )
  fit_animal <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + animal(1 + x | p | id, A = K),
        mu2 = y2 ~ x + animal(1 + x | p | id, A = K),
        sigma1 = ~ z + animal(1 + x | p | id, A = K),
        sigma2 = ~ z + animal(1 + x | p | id, A = K),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = q8_control
    )
  )
  fit_relmat_K <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + relmat(1 + x | p | id, K = K),
        mu2 = y2 ~ x + relmat(1 + x | p | id, K = K),
        sigma1 = ~ z + relmat(1 + x | p | id, K = K),
        sigma2 = ~ z + relmat(1 + x | p | id, K = K),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = q8_control
    )
  )
  fit_relmat_Q <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + relmat(1 + x | p | id, Q = Q),
        mu2 = y2 ~ x + relmat(1 + x | p | id, Q = Q),
        sigma1 = ~ z + relmat(1 + x | p | id, Q = Q),
        sigma2 = ~ z + relmat(1 + x | p | id, Q = Q),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = q8_control
    )
  )

  q8_dpars <- rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 2L)
  q8_coef <- rep(c("(Intercept)", "x"), times = 4L)
  q8_members <- paste0(q8_dpars, ":", q8_coef)
  q8_sd_names <- function(provider) {
    paste0(
      q8_dpars,
      ":",
      provider,
      "(",
      ifelse(q8_coef == "(Intercept)", "1", "0 + x"),
      " | p | id)"
    )
  }
  expect_q8_relatedness <- function(fit, level, sd_names) {
    structured <- fit$model$structured$phylo_mu
    structured_row <- structured_effects(fit)
    q8_pairs <- corpairs(fit, level = level)
    q8_pairs_ci <- corpairs(fit, level = level, conf.int = TRUE)
    q8_targets <- profile_targets(fit)
    q8_cor_targets <- q8_targets[
      startsWith(q8_targets$parm, paste0("cor:", level, ":")),
      ,
      drop = FALSE
    ]
    sd_match <- match(paste0("sd:mu:", sd_names), q8_targets$parm)
    q8_sd_targets <- q8_targets[sd_match, , drop = FALSE]

    expect_equal(fit$opt$convergence, 0L)
    expect_true(is.finite(fit$opt$objective))
    expect_equal(structured$q, 8L)
    expect_equal(structured$dpars, q8_dpars)
    expect_equal(structured$coef_names, q8_coef)
    expect_equal(structured$covariance_mode, "unstructured")
    expect_equal(structured$block_ids, rep(1L, 8L))
    expect_equal(
      structured_row$endpoint_member_set,
      paste(q8_members, collapse = "+")
    )
    expect_equal(structured_row$endpoint_member_count, 8L)
    expect_named(fit$sdpars$mu, sd_names)
    expect_equal(sum(names(fit$opt$par) == "theta_phylo"), 28L)
    expect_equal(length(fit$corpars[[level]]), 28L)
    expect_equal(nrow(q8_pairs), 28L)
    expect_equal(q8_pairs$parameter, names(fit$corpars[[level]]))
    expect_equal(nrow(q8_pairs_ci), 28L)
    expect_equal(nrow(q8_cor_targets), 28L)
    expect_equal(q8_cor_targets$tmb_parameter, rep("theta_phylo", 28L))
    expect_equal(q8_cor_targets$target_type, rep("derived", 28L))
    expect_false(any(q8_cor_targets$profile_ready))
    expect_equal(
      q8_cor_targets$profile_note,
      rep("derived_unstructured_correlation", 28L)
    )
    expect_equal(q8_pairs_ci$profile_target, q8_cor_targets$parm)
    expect_equal(
      q8_pairs_ci$conf.status,
      rep("derived_interval_unavailable", 28L)
    )
    expect_equal(q8_pairs_ci$interval_source, rep("not_available", 28L))
    expect_true(all(is.na(q8_pairs_ci$conf.low)))
    expect_false(anyNA(sd_match))
    expect_equal(q8_sd_targets$parm, paste0("sd:mu:", sd_names))
    expect_equal(q8_sd_targets$tmb_parameter, rep("log_sd_phylo", 8L))
    expect_equal(q8_sd_targets$index, seq_len(8L))
    expect_equal(q8_sd_targets$target_type, rep("direct", 8L))

    fixed_mu1 <- as.vector(fit$model$X$mu1 %*% coef(fit, "mu1"))
    fixed_sigma2 <- as.vector(fit$model$X$sigma2 %*% coef(fit, "sigma2"))
    expect_equal(
      unname(predict(fit, dpar = "mu1", type = "link")),
      fixed_mu1 + drmTMB:::phylo_mu_contribution(fit, dpar = "mu1"),
      tolerance = 1e-8
    )
    expect_equal(
      unname(predict(fit, dpar = "sigma2", type = "link")),
      fixed_sigma2 + drmTMB:::phylo_mu_contribution(fit, dpar = "sigma2"),
      tolerance = 1e-8
    )
  }

  expect_q8_relatedness(fit_animal, "animal", q8_sd_names("animal"))
  expect_q8_relatedness(fit_relmat_K, "relmat", q8_sd_names("relmat"))
  expect_q8_relatedness(fit_relmat_Q, "relmat", q8_sd_names("relmat"))
  expect_equal(
    as.numeric(stats::logLik(fit_animal)),
    as.numeric(stats::logLik(fit_relmat_K)),
    tolerance = 1e-5
  )
  expect_equal(
    names(fit_relmat_K$sdpars$mu),
    names(fit_relmat_Q$sdpars$mu)
  )
  expect_equal(
    names(fit_relmat_K$corpars$relmat),
    names(fit_relmat_Q$corpars$relmat)
  )
})

test_that("bivariate Gaussian known-matrix one-slope location blocks expose partial q4 members", {
  sim <- new_biv_known_relatedness_q4_gaussian_data()
  dat <- sim$data
  K <- sim$K
  Q <- sim$Q
  control <- drm_control(
    se = FALSE,
    fallback_optimizer = "BFGS",
    optimizer = list(eval.max = 350, iter.max = 350)
  )

  fit_animal <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + animal(1 + x | p | id, A = K),
        mu2 = y2 ~ x + animal(1 + x | p | id, A = K),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = control
    )
  )
  fit_relmat_Q <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + relmat(1 + x | p | id, Q = Q),
        mu2 = y2 ~ x + relmat(1 + x | p | id, Q = Q),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = control
    )
  )
  fit_relmat_K <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + relmat(1 + x | p | id, K = K),
        mu2 = y2 ~ x + relmat(1 + x | p | id, K = K),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = control
    )
  )

  q4_dpars <- rep(c("mu1", "mu2"), each = 2L)
  q4_coef <- rep(c("(Intercept)", "x"), times = 2L)
  q4_members <- paste0(q4_dpars, ":", q4_coef)
  expect_known_partial <- function(fit, level, provider) {
    sd_names <- paste0(
      q4_dpars,
      ":",
      provider,
      "(",
      ifelse(q4_coef == "(Intercept)", "1", "0 + x"),
      " | p | id)"
    )
    structured <- fit$model$structured$phylo_mu
    structured_row <- structured_effects(fit)
    pairs <- corpairs(fit, level = level)
    targets <- profile_targets(fit)
    cor_targets <- targets[
      startsWith(targets$parm, paste0("cor:", level, ":")),
      ,
      drop = FALSE
    ]

    expect_true(is.finite(fit$opt$objective))
    expect_equal(structured$type, provider)
    expect_equal(structured$q, 4L)
    expect_equal(structured$dpars, q4_dpars)
    expect_equal(structured$coef_names, q4_coef)
    expect_equal(structured$covariance_mode, "unstructured")
    expect_equal(structured$block_ids, rep(1L, 4L))
    expect_equal(
      structured_row$endpoint_member_set,
      paste(q4_members, collapse = "+")
    )
    expect_equal(structured_row$endpoint_member_count, 4L)
    expect_named(fit$sdpars$mu, sd_names)
    expect_equal(sum(names(fit$opt$par) == "theta_phylo"), 6L)
    expect_equal(length(fit$corpars[[level]]), 6L)
    expect_equal(nrow(pairs), 6L)
    expect_equal(nrow(cor_targets), 6L)
    expect_equal(cor_targets$tmb_parameter, rep("theta_phylo", 6L))
    expect_equal(cor_targets$target_type, rep("derived", 6L))
    expect_false(any(cor_targets$profile_ready))
  }

  expect_known_partial(fit_animal, "animal", "animal")
  expect_known_partial(fit_relmat_K, "relmat", "relmat")
  expect_known_partial(fit_relmat_Q, "relmat", "relmat")
  expect_equal(
    as.numeric(stats::logLik(fit_relmat_K)),
    as.numeric(stats::logLik(fit_relmat_Q)),
    tolerance = 1e-5
  )
  expect_equal(
    names(fit_relmat_K$sdpars$mu),
    names(fit_relmat_Q$sdpars$mu)
  )
  expect_equal(
    names(fit_relmat_K$corpars$relmat),
    names(fit_relmat_Q$corpars$relmat)
  )
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
