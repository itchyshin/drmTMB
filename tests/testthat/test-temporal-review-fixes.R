temporal_white_noise_data <- function(seed = 12L) {
  set.seed(seed)
  dat <- expand.grid(
    occasion = c(0L, 1L, 2L, 5L, 9L),
    id = sprintf("id_%02d", seq_len(30L)),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  dat$x <- stats::rnorm(nrow(dat))
  dat$y <- 0.3 * dat$x + stats::rnorm(nrow(dat))
  dat
}

test_that("temporal checks read the full fixed covariance, not the trimmed vcov()", {
  dat <- temporal_white_noise_data()
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  ))
  # vcov() stays trimmed to the mean coefficients ...
  expect_identical(colnames(stats::vcov(fit)), c("mu:(Intercept)", "mu:x"))
  # ... but the checks see every fixed parameter.
  covariance <- drmTMB:::drm_check_covariance(fit)
  expect_identical(nrow(covariance), length(fit$opt$par))
  # White noise leaves sigma and the temporal process unseparated: the
  # fixed-parameter covariance has a huge beta_sigma SE (about 1.5e4) while
  # the trimmed vcov() looks clean.
  fixed_se <- sqrt(diag(fit$sdr$cov.fixed))
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_gt(fixed_se[["beta_sigma"]], 1000)
  expect_true(all(sqrt(diag(stats::vcov(fit))) < 1))
  expect_identical(convergence_status(fit), "degenerate")
  expect_false(is_converged(fit))
  inflated <- drmTMB:::check_standard_errors_inflated(fit)
  expect_identical(inflated$status, "note")
  expect_match(inflated$value, "beta_sigma")
})

test_that("temporal summaries withhold sigma and SD standard errors", {
  dat <- temporal_white_noise_data(seed = 3L)
  dat$y <- dat$y + rep(stats::rnorm(30L, sd = 0.6), each = 5L)
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + (1 | id) + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  ))
  s <- summary(fit)
  expect_true(nrow(s$parameters) > 0L)
  expect_true(all(is.na(s$parameters$std_error)))
  expect_true(isTRUE(s$temporal_parameters_point_only))
  expect_message(print(s), "standard errors are withheld")
})

test_that("temporal AR1 transitions at very large gaps cost O(log gap)", {
  set.seed(31)
  big <- do.call(rbind, lapply(seq_len(30L), function(i) {
    data.frame(id = paste0("b", i), occasion = c(0L, 1L, 2L, 200000L), x = stats::rnorm(4L))
  }))
  big$y <- 0.3 * big$x + stats::rnorm(nrow(big))
  elapsed <- system.time(
    fit <- suppressWarnings(drmTMB(
      bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = big, family = gaussian(), REML = FALSE
    ))
  )[["elapsed"]]
  expect_true(is.finite(stats::logLik(fit)))
  expect_lt(elapsed, 60)
})

temporal_two_node_dense_nll <- function(dat, par) {
  beta <- unname(par[names(par) == "beta_mu"])
  sigma <- exp(unname(par[["beta_sigma"]]))
  sd_temporal <- exp(unname(par[["log_sd_temporal"]]))
  phi <- tanh(unname(par[["theta_temporal"]]))
  out <- 0
  for (id in unique(dat$id)) {
    rows <- which(dat$id == id)
    rows <- rows[order(dat$occasion[rows])]
    time <- dat$occasion[rows]
    V <- sd_temporal^2 * phi^abs(outer(time, time, "-"))
    diag(V) <- diag(V) + sigma^2
    residual <- dat$y[rows] - (beta[[1L]] + beta[[2L]] * dat$x[rows])
    root <- chol(V)
    out <- out + 0.5 * (
      length(rows) * log(2 * pi) + 2 * sum(log(diag(root))) +
        sum(forwardsolve(t(root), residual)^2)
    )
  }
  out
}

temporal_gap_fit <- function() {
  set.seed(41)
  gaps <- c(1L, 2L, 7L, 60L, 400L, 1200L)
  dat <- do.call(rbind, lapply(gaps, function(g) {
    data.frame(id = paste0("g", g), occasion = c(0L, g, 2L * g), x = stats::rnorm(3L))
  }))
  dat$y <- 0.2 + 0.5 * dat$x + stats::rnorm(nrow(dat))
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  ))
  list(dat = dat, fit = fit)
}

test_that("temporal AR1 marginal likelihood matches the dense oracle at large gaps", {
  setup <- temporal_gap_fit()
  par <- setup$fit$opt$par
  par[["log_sd_temporal"]] <- log(0.8)
  par[["beta_sigma"]] <- log(0.6)
  for (theta in c(-10, -3, -1, -0.4, 0, 0.4, 1, 3, 10)) {
    par[["theta_temporal"]] <- theta
    expect_equal(
      as.numeric(setup$fit$obj$fn(par)),
      temporal_two_node_dense_nll(setup$dat, par),
      tolerance = 1e-8,
      info = paste("theta =", theta)
    )
  }
})

test_that("temporal AR1 transition density is exact near the unit root", {
  # The marginal Laplace objective becomes numerically ill-conditioned when
  # the transition SD is ~1e-11, so the transition itself is checked on the
  # joint (non-Laplace) objective against the sech^2 * geometric-sum form.
  setup <- temporal_gap_fit()
  fit <- setup$fit
  env <- fit$obj$env
  joint <- TMB::MakeADFun(
    data = env$data, parameters = env$parList(), map = env$map,
    DLL = "drmTMB", silent = TRUE
  )
  temporal <- fit$model$structured$temporal_mu
  set.seed(99)
  u <- stats::rnorm(temporal$n_re, sd = 0.5)
  par <- joint$par
  par[names(par) == "u_temporal"] <- u
  par[["log_sd_temporal"]] <- log(0.8)
  par[["beta_sigma"]] <- log(0.6)
  beta <- unname(par[names(par) == "beta_mu"])
  reference <- function(theta) {
    phi <- tanh(theta)
    log_sech <- log(2) - abs(theta) - log1p(exp(-2 * abs(theta)))
    starts <- temporal$series_start0 + 1L
    out <- 0
    for (k in seq_len(length(starts) - 1L)) {
      first <- starts[[k]]
      last <- starts[[k + 1L]] - 1L
      out <- out - stats::dnorm(u[[first]], 0, 1, log = TRUE)
      for (node in seq.int(first + 1L, length.out = last - first)) {
        gap <- temporal$gap[[node]]
        sd <- exp(log_sech + 0.5 * log(sum((phi^2)^(0:(gap - 1L)))))
        out <- out - stats::dnorm(u[[node]], phi^gap * u[[node - 1L]], sd, log = TRUE)
      }
    }
    mu <- as.vector(fit$model$X$mu %*% beta) +
      0.8 * u[temporal$observation_node_index0 + 1L]
    out - sum(stats::dnorm(fit$model$y, mu, 0.6, log = TRUE))
  }
  for (theta in c(-25, -19, -1.0000001, -0.9999999, 0.9999999, 1.0000001, 3, 10, 18.5, 25)) {
    par[["theta_temporal"]] <- theta
    expect_equal(as.numeric(joint$fn(par)), reference(theta), tolerance = 1e-10,
                 info = paste("theta =", theta))
    expect_true(all(is.finite(joint$gr(par))), info = paste("theta =", theta))
  }
})
