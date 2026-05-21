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
  ped <- data.frame(
    id = unique(dat$id),
    dam = NA_character_,
    sire = NA_character_
  )
  bad_Q <- sim$Q
  rownames(bad_Q)[[1L]] <- "missing_id"

  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ x + animal(1 | id, pedigree = ped), sigma ~ 1),
      data = dat
    )
  )
  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ x + relmat(1 + x | id, Q = Q), sigma ~ 1),
      data = dat
    )
  )
  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ x + relmat(1 | id, Q = bad_Q), sigma ~ 1),
      data = dat
    )
  )
})
