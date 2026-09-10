pkgload::load_all(".", compile = TRUE, quiet = TRUE)

source(testthat::test_path("helper-temporal-homtoep-reference.R"))

homtoep_reduction_data <- function() {
  set.seed(202609103L)
  dat <- expand.grid(id = sprintf("s%02d", 1:10), occasion = c(0L, 2L, 4L, 6L))
  dat$x <- rep(c(-1, 1), length.out = nrow(dat))
  dat$y <- -0.1 + 0.35 * dat$x + stats::rnorm(nrow(dat), sd = 0.6)
  dat[sample.int(nrow(dat)), , drop = FALSE]
}

homtoep_reduction_fit <- function() {
  suppressWarnings(drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = occasion, structure = "homtoep"), sigma ~ 1),
    data = homtoep_reduction_data(), family = gaussian(), REML = FALSE
  ))
}

test_that("homtoep native provider reduces to AR1 and diagonal temporal covariance", {
  fit <- homtoep_reduction_fit()
  par <- fit$opt$par
  theta <- which(names(par) == "theta_temporal")
  phi <- -0.45

  ar1_par <- par
  ar1_par[theta] <- c(atanh(phi), rep(0, length(theta) - 1L))
  ar1_rho <- c(1, phi^seq_len(length(theta)))
  ar1_dense <- homtoep_dense_gaussian_nll(
    y = fit$model$y,
    X = as.matrix(fit$model$X$mu),
    beta = unname(ar1_par[names(ar1_par) == "beta_mu"]),
    id = fit$data$id,
    occasion = fit$data$occasion,
    sd_temporal = exp(unname(ar1_par[match("log_sd_temporal", names(ar1_par))])),
    sigma = exp(unname(ar1_par[match("beta_sigma", names(ar1_par))])),
    rho = ar1_rho
  )
  expect_equal(as.numeric(fit$obj$fn(ar1_par)), ar1_dense, tolerance = 1e-7)

  diagonal_par <- par
  diagonal_par[theta] <- 0
  diagonal_dense <- homtoep_dense_gaussian_nll(
    y = fit$model$y,
    X = as.matrix(fit$model$X$mu),
    beta = unname(diagonal_par[names(diagonal_par) == "beta_mu"]),
    id = fit$data$id,
    occasion = fit$data$occasion,
    sd_temporal = exp(unname(diagonal_par[match("log_sd_temporal", names(diagonal_par))])),
    sigma = exp(unname(diagonal_par[match("beta_sigma", names(diagonal_par))])),
    rho = c(1, rep(0, length(theta)))
  )
  expect_equal(as.numeric(fit$obj$fn(diagonal_par)), diagonal_dense, tolerance = 1e-7)
})

test_that("homtoep mutations expose invalid maps, compressed schedules, shared IDs, and missing normalizers", {
  fit <- homtoep_reduction_fit()
  temporal <- fit$model$structured$temporal_mu
  par <- fit$opt$par
  rho <- homtoep_reference_correlations(unname(par[names(par) == "theta_temporal"]))
  sd_temporal <- unname(fit$sdpars$mu[[temporal_mu_sd_label(temporal)]])
  sigma <- stats::sigma(fit)[[1L]]
  V <- homtoep_dense_covariance(
    fit$data$id, fit$data$occasion, sd_temporal, sigma, rho
  )

  expect_lt(min(eigen(toeplitz(c(1, 0.9, -0.9, 0.9)), symmetric = TRUE, only.values = TRUE)$values), 0)
  expect_true(all(eigen(toeplitz(rho), symmetric = TRUE, only.values = TRUE)$values > 0))

  irregular <- homtoep_reduction_data()
  irregular$occasion[irregular$id == "s01"] <- c(0L, 1L, 3L, 4L)
  expect_error(
    drmTMB:::build_temporal_mu_structure(
      list(group = "id", time = "occasion", structure = "homtoep"), irregular
    ),
    "equally spaced.*OU"
  )

  schedule <- sort(unique(fit$data$occasion))
  shared_lag <- abs(outer(match(fit$data$occasion, schedule), match(fit$data$occasion, schedule), "-"))
  shared <- matrix(
    sd_temporal^2 * rho[shared_lag + 1L],
    nrow = nrow(V), ncol = ncol(V)
  )
  diag(shared) <- diag(shared) + sigma^2
  cross_series <- outer(fit$data$id, fit$data$id, `!=`)
  expect_true(all(V[cross_series] == 0))
  expect_true(any(shared[cross_series] != 0))
  expect_false(isTRUE(all.equal(V, shared)))

  residual <- fit$model$y - as.vector(fit$model$X$mu %*% unname(par[names(par) == "beta_mu"]))
  normalized <- homtoep_dense_gaussian_nll(
    fit$model$y, as.matrix(fit$model$X$mu), unname(par[names(par) == "beta_mu"]),
    fit$data$id, fit$data$occasion, sd_temporal, sigma, rho
  )
  unnormalized <- 0.5 * sum(forwardsolve(t(chol(V)), residual)^2)
  expect_gt(abs(normalized - unnormalized), 1e-6)
})
