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
