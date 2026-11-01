# The homogeneous Toeplitz map from partial autocorrelations
# r_m = tanh(theta_m) must stay usable when |theta| is large and tanh rounds
# to +/-1: there, forming sigma^2 R and factorising it can lose positive
# definiteness in floating point (NaN or -Inf likelihoods). The map and the
# native likelihood use the Levinson--Durbin prediction-error form instead.

yule_walker_residuals <- function(rho, ar_last) {
  K <- length(rho)
  vapply(seq_len(K - 1L), function(k) {
    lags <- abs(k - seq_len(K - 1L))
    rho[[k + 1L]] - sum(ar_last * rho[lags + 1L])
  }, numeric(1L))
}

test_that("the map satisfies Yule-Walker and recovers its PACs at moderate theta", {
  set.seed(20261002)
  for (K in 2:12) {
    for (draw in seq_len(20)) {
      theta <- stats::runif(K - 1L, -2, 2)
      lev <- drmTMB:::temporal_homtoep_levinson(theta)
      expect_lt(max(abs(yule_walker_residuals(lev$rho, lev$ar[K, seq_len(K - 1L)]))), 1e-12)
      expect_gt(min(eigen(stats::toeplitz(lev$rho), symmetric = TRUE, only.values = TRUE)$values), 0)
      # Independent Durbin-Levinson recursion on the mapped correlations.
      pac <- numeric(K - 1L)
      phi <- numeric()
      v <- 1
      for (m in seq_len(K - 1L)) {
        prev <- if (m == 1L) 0 else sum(phi * lev$rho[m:2L])
        pac[[m]] <- (lev$rho[[m + 1L]] - prev) / v
        phi <- c(phi - pac[[m]] * rev(phi), pac[[m]])
        v <- v * (1 - pac[[m]]^2)
      }
      expect_equal(pac, tanh(theta), tolerance = 1e-8)
    }
  }
})

test_that("the map stays finite and Yule-Walker-consistent at large |theta|", {
  extreme <- list(
    c(8, -8, 5, 0, 3),
    c(15, 15, -15, 12, 0.1),
    c(18.5, 0, 0, 0, 0),
    c(-40, 40, -40, 40, -40),
    stats::setNames(rep(25, 11), NULL)
  )
  for (theta in extreme) {
    K <- length(theta) + 1L
    lev <- drmTMB:::temporal_homtoep_levinson(theta)
    expect_true(all(is.finite(lev$rho)))
    expect_true(all(abs(lev$rho) <= 1 + 1e-12))
    expect_true(all(is.finite(lev$log_v)))
    expect_true(all(diff(lev$log_v) <= 0))
    # log(1 - r^2) = log(sech^2 theta) exactly, even where 1 - tanh^2 rounds.
    expect_equal(
      diff(lev$log_v),
      log(4) - 2 * abs(theta) - 2 * log1p(exp(-2 * abs(theta))),
      tolerance = 1e-12
    )
    expect_lt(max(abs(yule_walker_residuals(lev$rho, lev$ar[K, seq_len(K - 1L)]))), 1e-10)
  }
  # tanh(18.5) rounds to 1: 1 - tanh^2 is off by about 30%, the stable form
  # is exact.
  expect_gt(abs((1 - tanh(18.5)^2) / exp(log(4) - 37 - 2 * log1p(exp(-37))) - 1), 0.1)
})

test_that("the native homtoep likelihood is finite and matches the prediction-error form at extreme theta", {
  set.seed(20261003)
  n_site <- 30L
  K <- 6L
  dat <- data.frame(
    site = factor(rep(sprintf("s%02d", seq_len(n_site)), each = K)),
    occasion = rep(0:(K - 1L), n_site),
    x = stats::rnorm(n_site * K)
  )
  R <- stats::toeplitz(c(1, 0.5, 0.3, 0.2, 0.1, 0.05))
  dat$y <- 1 + 0.4 * dat$x + unlist(lapply(seq_len(n_site), function(i) {
    as.vector(t(chol(R)) %*% stats::rnorm(K, sd = 0.8))
  }))
  fit <- drmTMB(
    bf(y ~ x + temporal(1 | site, time = occasion, structure = "homtoep"),
       sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  )
  par <- fit$opt$par
  theta_at <- which(names(par) == "theta_temporal")
  reference_nll <- function(par) {
    beta <- unname(par[names(par) == "beta_mu"])
    sigma <- exp(unname(par[names(par) == "beta_sigma"]))
    lev <- drmTMB:::temporal_homtoep_levinson(unname(par[theta_at]))
    X <- cbind(1, dat$x)
    r <- dat$y - as.vector(X %*% beta)
    total <- 0
    for (s in split(seq_len(nrow(dat)), dat$site)) {
      x <- r[s][order(dat$occasion[s])]
      for (t in seq_len(K)) {
        pred <- if (t == 1L) 0 else sum(lev$ar[t, seq_len(t - 1L)] * x[(t - 1L):1L])
        v <- sigma^2 * exp(lev$log_v[[t]])
        total <- total + 0.5 * (log(2 * pi) + log(v)) + 0.5 * (x[[t]] - pred)^2 / v
      }
    }
    total
  }
  expect_equal(fit$obj$fn(par), reference_nll(par), tolerance = 1e-8)
  for (theta in list(c(8, -8, 5, 0, 3), c(15, 15, -15, 12, 0.1), c(18.5, 0, 0, 0, 0))) {
    p <- par
    p[theta_at] <- theta
    value <- fit$obj$fn(p)
    expect_true(is.finite(value))
    expect_equal(value, reference_nll(p), tolerance = 1e-6)
  }
})
