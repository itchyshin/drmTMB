# Case weights with mi() predictor models (#1459) and the posterior-centred
# mi() prior quadrature (#1476 Beta/zero-one-Beta, #1477 Gamma).
#
# Contract under test: a row weight w multiplies the row's response term and
# its mi() prior term once each, so an integer weight gives the same fit as
# duplicating the row, a zero weight drops the row, and missing weights are a
# classed error. The quadrature integrates each missing-x row's marginal
# accurately over the admitted prior range.

mi_w_gaussian_data <- function() {
  z <- seq(-1.5, 1.5, length.out = 48)
  w <- cos(seq_along(z) / 5)
  x_full <- 0.25 + 0.8 * z - 0.15 * w + 0.08 * sin(seq_along(z))
  y <- 0.7 + 1.4 * x_full - 0.35 * z + 0.12 * cos(seq_along(z) / 3)
  dat <- data.frame(y = y, x = x_full, z = z, w = w)
  dat$x[c(6, 17, 31, 42)] <- NA_real_
  dat
}

mi_w_grouped_gaussian_data <- function() {
  group <- factor(rep(letters[1:8], each = 7))
  z <- seq(-1.4, 1.4, length.out = length(group))
  group_shift <- rep(seq(-0.45, 0.45, length.out = 8), each = 7)
  x_full <- 0.15 + 0.65 * z + group_shift + 0.05 * sin(seq_along(z))
  y <- 0.6 + 1.35 * x_full - 0.25 * z + 0.08 * cos(seq_along(z) / 4)
  dat <- data.frame(y = y, x = x_full, z = z, group = group)
  dat$x[c(4, 15, 26, 41, 52)] <- NA_real_
  dat
}

mi_w_beta_data <- function() {
  n <- 72
  z <- seq(-1.8, 1.8, length.out = n)
  x_full <- stats::plogis(-0.25 + 0.9 * z + 0.18 * sin(seq_len(n) / 5))
  y <- 0.35 + 1.25 * x_full - 0.30 * z + 0.04 * cos(seq_len(n) / 4)
  dat <- data.frame(y = y, z = z, x = x_full)
  dat$x[c(8, 19, 34, 51, 67)] <- NA_real_
  dat
}

mi_w_gamma_data <- function() {
  n <- 78
  z <- seq(-1.7, 1.7, length.out = n)
  mean_full <- exp(0.20 + 0.45 * z)
  x_full <- mean_full * (1 + 0.18 * sin(seq_len(n) / 4))
  y <- 0.35 + 0.75 * x_full - 0.20 * z + 0.04 * cos(seq_len(n) / 5)
  dat <- data.frame(y = y, z = z, x = x_full)
  dat$x[c(8, 20, 35, 53, 70)] <- NA_real_
  dat
}

mi_w_nbinom2_data <- function() {
  n <- 90
  z <- seq(-1.6, 1.7, length.out = n)
  x <- 0.2 + 0.7 * z + 0.15 * cos(seq_len(n) / 3)
  mu <- exp(0.3 + 0.4 * z + 0.55 * x)
  y <- pmax(0, round(mu + sqrt(mu) * cos(seq_len(n) / 4)))
  dat <- data.frame(y = y, z = z, x = x)
  dat$x[c(8, 19, 31, 46, 57, 70, 83)] <- NA_real_
  dat
}

mi_w_fit <- function(kind, dat, w_row = NULL) {
  impute <- switch(
    kind,
    gaussian = list(x = x ~ z + w),
    grouped = list(x = x ~ z + (1 | group)),
    beta = list(x = impute_model(x ~ z, family = beta_family())),
    gamma = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
    nbinom2 = list(x = impute_model(x ~ z, family = gaussian()))
  )
  family <- if (identical(kind, "nbinom2")) nbinom2() else gaussian()
  drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = dat,
    family = family,
    weights = w_row,
    impute = impute,
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

mi_w_data <- function(kind) {
  switch(
    kind,
    gaussian = mi_w_gaussian_data(),
    grouped = mi_w_grouped_gaussian_data(),
    beta = mi_w_beta_data(),
    gamma = mi_w_gamma_data(),
    nbinom2 = mi_w_nbinom2_data()
  )
}

mi_w_duplicate <- function(dat, rows) {
  out <- dat[c(seq_len(nrow(dat)), rows), , drop = FALSE]
  rownames(out) <- NULL
  out
}

mi_w_estimates <- function(fit) {
  par <- fit$obj$env$last.par.best
  random <- fit$obj$env$random
  if (length(random) > 0L) {
    par <- par[-random]
  }
  # The nbinom2 fixture sits at the Poisson limit (log sigma ~ -12), where the
  # dispersion is unidentified and its log moves freely along a flat ridge.
  # Compare it on the natural scale, where both fits agree that sigma ~ 0.
  if (identical(fit$model$model_type, "nbinom2")) {
    par[names(par) == "beta_sigma"] <- exp(par[names(par) == "beta_sigma"])
  }
  par
}

test_that("unit weights reproduce the unweighted mi() fit (check 1)", {
  for (kind in c("gaussian", "grouped", "beta", "gamma", "nbinom2")) {
    dat <- mi_w_data(kind)
    fit_none <- mi_w_fit(kind, dat)
    fit_one <- mi_w_fit(kind, dat, w_row = rep(1, nrow(dat)))
    expect_equal(
      as.numeric(logLik(fit_one)),
      as.numeric(logLik(fit_none)),
      tolerance = 1e-10,
      info = kind
    )
    expect_equal(
      mi_w_estimates(fit_one),
      mi_w_estimates(fit_none),
      tolerance = 1e-8,
      info = kind
    )
  }
})

test_that("an integer weight of 2 equals duplicating the row (checks 2 and 7)", {
  # One row with a missing predictor and one with an observed predictor, so
  # both the latent/quadrature prior term and the observed prior term are
  # covered. The Gaussian and quadrature routes are exact; nbinom2 uses a
  # Laplace curvature correction and agrees to Laplace accuracy.
  cases <- list(
    gaussian = c(6L, 10L),
    grouped = c(15L, 20L),
    beta = c(19L, 30L),
    gamma = c(20L, 40L),
    nbinom2 = c(19L, 50L)
  )
  for (kind in names(cases)) {
    dat <- mi_w_data(kind)
    rows <- cases[[kind]]
    expect_true(is.na(dat$x[[rows[[1L]]]]), info = kind)
    expect_false(is.na(dat$x[[rows[[2L]]]]), info = kind)
    w_row <- rep(1, nrow(dat))
    w_row[rows] <- 2
    fit_w <- mi_w_fit(kind, dat, w_row = w_row)
    fit_dup <- mi_w_fit(kind, mi_w_duplicate(dat, rows))
    tol <- if (identical(kind, "nbinom2")) 1e-4 else 1e-7
    expect_lt(
      abs(as.numeric(logLik(fit_w)) - as.numeric(logLik(fit_dup))),
      if (identical(kind, "nbinom2")) 5e-3 else 1e-6
    )
    expect_equal(
      mi_w_estimates(fit_w),
      mi_w_estimates(fit_dup),
      tolerance = tol,
      info = kind
    )
    # predict() honours the weights: the weighted fit and the duplicated fit
    # predict the same mean for the original rows (missing-x rows use the
    # conditional predictor value, which does not depend on the weight).
    expect_equal(
      as.numeric(predict(fit_w, dpar = "mu")),
      as.numeric(predict(fit_dup, dpar = "mu"))[seq_len(nrow(dat))],
      tolerance = if (identical(kind, "nbinom2")) 1e-3 else 1e-6,
      info = kind
    )
  }
})

test_that("the Gaussian mi() weight is not the old unweighted prior (#1459)", {
  # Constant weight 3 on every row must give exactly the estimates of the
  # unweighted fit (the MLE does not move under a constant weight) and three
  # times its log-likelihood. Before the fix the prior stayed unweighted and
  # both statements failed.
  dat <- mi_w_gaussian_data()
  fit_1 <- mi_w_fit("gaussian", dat)
  fit_3 <- mi_w_fit("gaussian", dat, w_row = rep(3, nrow(dat)))
  expect_equal(mi_w_estimates(fit_3), mi_w_estimates(fit_1), tolerance = 1e-6)
  expect_equal(
    as.numeric(logLik(fit_3)),
    3 * as.numeric(logLik(fit_1)),
    tolerance = 1e-8
  )
})

test_that("zero weights drop the row and missing weights are refused (checks 3 and 7)", {
  for (kind in c("gaussian", "beta", "gamma", "nbinom2")) {
    dat <- mi_w_data(kind)
    miss_rows <- which(is.na(dat$x))
    obs_row <- which(!is.na(dat$x))[[5L]]
    drop <- c(miss_rows[[1L]], obs_row)
    w_row <- rep(1, nrow(dat))
    w_row[drop] <- 0
    fit_zero <- mi_w_fit(kind, dat, w_row = w_row)
    fit_drop <- mi_w_fit(kind, dat[-drop, , drop = FALSE])
    expect_true(is.finite(fit_zero$obj$fn(fit_zero$obj$par)), info = kind)
    expect_true(all(is.finite(fit_zero$obj$gr(fit_zero$obj$par))), info = kind)
    expect_equal(
      as.numeric(logLik(fit_zero)),
      as.numeric(logLik(fit_drop)),
      tolerance = 1e-8,
      info = kind
    )
    expect_equal(
      mi_w_estimates(fit_zero),
      mi_w_estimates(fit_drop),
      tolerance = 1e-6,
      info = kind
    )
    w_na <- rep(1, nrow(dat))
    w_na[miss_rows[[1L]]] <- NA_real_
    expect_error(
      mi_w_fit(kind, dat, w_row = w_na),
      class = "drmTMB_weights_invalid"
    )
  }
})

test_that("simulate() on a weighted mi() fit draws one finite value per row", {
  dat <- mi_w_beta_data()
  w_row <- rep(1, nrow(dat))
  w_row[c(19L, 30L)] <- 2
  fit <- mi_w_fit("beta", dat, w_row = w_row)
  sims <- simulate(fit, nsim = 3, seed = 11)
  expect_equal(dim(sims), c(nrow(dat), 3L))
  expect_true(all(is.finite(as.matrix(sims))))
})

test_that("Gamma mi() recovers the predictor mean and CV at CV 0.05 and 0.10 (check 5, #1477)", {
  # The #1477 repro, enlarged so recovery can be judged: the old 20-node
  # Gauss-Laguerre rule plateaued at CV ~0.125 below CV 0.10.
  run <- function(cv, seed, n = 300L, nmiss = 60L) {
    set.seed(seed)
    z <- stats::rnorm(n)
    mean_x <- exp(2 + 0.2 * z)
    x <- stats::rgamma(n, shape = 1 / cv^2, scale = mean_x * cv^2)
    y <- 1 + 0.5 * x + stats::rnorm(n, 0, 0.5)
    dat <- data.frame(y = y, x = x, z = z)
    dat$x[sample(n, nmiss)] <- NA_real_
    fit <- drmTMB(
      bf(y ~ mi(x), sigma ~ 1),
      data = dat,
      impute = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    )
    list(fit = fit, dat = dat)
  }
  for (cv in c(0.05, 0.10)) {
    res <- run(cv, seed = 1477L)
    fit <- res$fit
    dat <- res$dat
    expect_equal(fit$opt$convergence, 0L)
    sigma_mi <- unname(coef(fit, "sigma_mi_x"))
    beta_mi <- unname(coef(fit, "mi_x"))
    expect_lt(abs(sigma_mi - cv) / cv, 0.15)
    expect_lt(abs(beta_mi[[1L]] - 2), 0.02)
    expect_lt(abs(beta_mi[[2L]] - 0.2), 0.02)
    expect_lt(abs(unname(coef(fit, "mu"))[[2L]] - 0.5), 0.05)

    # The fitted log-likelihood equals an independent high-precision
    # reference built with integrate() at the fitted parameters.
    beta_mu <- coef(fit, "mu")
    sigma <- exp(unname(coef(fit, "sigma")))
    shape <- 1 / sigma_mi^2
    mean_x <- exp(beta_mi[[1L]] + beta_mi[[2L]] * dat$z)
    ref <- 0
    for (i in seq_len(nrow(dat))) {
      if (!is.na(dat$x[[i]])) {
        ref <- ref +
          stats::dgamma(dat$x[[i]], shape = shape, scale = mean_x[[i]] / shape, log = TRUE) +
          stats::dnorm(dat$y[[i]], beta_mu[[1L]] + beta_mu[[2L]] * dat$x[[i]], sigma, log = TRUE)
      } else {
        ref <- ref + mi_reference_log_marginal(
          function(x) {
            stats::dgamma(x, shape = shape, scale = mean_x[[i]] / shape, log = TRUE) +
              stats::dnorm(dat$y[[i]], beta_mu[[1L]] + beta_mu[[2L]] * x, sigma, log = TRUE)
          },
          0,
          Inf
        )
      }
    }
    expect_lt(abs(as.numeric(logLik(fit)) - ref), 1e-6)
  }
})

test_that("Gamma mi() rule is accurate where the old Gauss-Laguerre rule collapsed (#1477)", {
  quad <- drmTMB:::drm_mi_gauss_hermite()
  # The issue's single row: mu = 10, CV 10%, y = 7, y | x ~ N(2 + 0.5 x, 0.5).
  # The old rule returned 1.559e-06 against the exact 0.5647.
  for (cv in c(2, 1, 0.3, 0.1, 0.05, 0.01)) {
    k <- 1 / cv^2
    theta <- 10 / k
    for (y in c(7, 8)) {
      for (sd_y in c(0.5, 0.05)) {
        rule <- drmTMB:::drm_mi_gamma_posterior_rule(
          k, theta, r0 = y - 2, bx = 0.5, sd_y = sd_y, quad = quad
        )
        ref <- mi_reference_log_marginal(
          function(x) {
            stats::dgamma(x, shape = k, scale = theta, log = TRUE) +
              stats::dnorm(y, 2 + 0.5 * x, sd_y, log = TRUE)
          },
          0,
          Inf
        )
        expect_lt(abs(rule$log_denom - ref), 1e-6)
      }
    }
  }
  rule <- drmTMB:::drm_mi_gamma_posterior_rule(100, 0.1, 5, 0.5, 0.5, quad)
  expect_equal(exp(rule$log_denom), 0.5647, tolerance = 1e-3)
})

test_that("Beta mi() prior weights sum to one with finite log-weights (check 6, #1476)", {
  quad <- drmTMB:::drm_mi_gauss_hermite()
  expect_equal(sum(quad$weights), 1, tolerance = 1e-14)
  shapes <- c(1e-3, 0.05, 0.3, 0.9, 1, 4, 50, 1e3, 1e4)
  for (a in shapes) {
    for (b in shapes) {
      prior <- drmTMB:::drm_mi_beta_prior_rule(a, b, quad)
      expect_true(all(is.finite(prior$log_weights)), info = paste(a, b))
      expect_lt(abs(sum(exp(prior$log_weights)) - 1), 1e-10)
      expect_true(all(prior$x >= 0 & prior$x <= 1), info = paste(a, b))
      post <- drmTMB:::drm_mi_beta_posterior_rule(
        a, b, r0 = 0.6, bx = 2, sd_y = 0.1, quad = quad
      )
      expect_true(all(is.finite(post$log_terms)), info = paste(a, b))
      expect_true(is.finite(post$log_denom), info = paste(a, b))
    }
  }
  for (k in c(0.05, 0.5, 1, 100, 1e4)) {
    prior <- drmTMB:::drm_mi_gamma_prior_rule(k, 2 / k, quad)
    expect_true(all(is.finite(prior$log_weights)))
    expect_lt(abs(sum(exp(prior$log_weights)) - 1), 1e-10)
  }
})

test_that("Beta mi() rule matches a high-precision reference (#1476)", {
  quad <- drmTMB:::drm_mi_gauss_hermite()
  # The issue's end-to-end row: y = 1.5, y | x ~ N(1 + 2 x, 0.1), mu = 0.5,
  # sigma = 0.05. The old 15-node rule gave -10.04 against -8.74.
  phi <- 1 / 0.05^2
  rule <- drmTMB:::drm_mi_beta_posterior_rule(
    0.5 * phi, 0.5 * phi, r0 = 0.5, bx = 2, sd_y = 0.1, quad = quad
  )
  expect_equal(rule$log_denom, -8.74, tolerance = 2e-3)
  for (mu in c(0.5, 0.3, 0.1, 0.9)) {
    for (sigma in c(0.5, 0.2, 0.1, 0.05, 0.01)) {
      a <- mu / sigma^2
      b <- (1 - mu) / sigma^2
      if (min(a, b) < 1) next
      tol <- if (min(a, b) >= 2) 1e-5 else 1e-3
      for (sd_y in c(0.5, 0.1)) {
        y <- 1 + 2 * mu + 0.3
        rule <- drmTMB:::drm_mi_beta_posterior_rule(
          a, b, r0 = y - 1, bx = 2, sd_y = sd_y, quad = quad
        )
        ref <- mi_reference_log_marginal(
          function(x) {
            stats::dbeta(x, a, b, log = TRUE) +
              stats::dnorm(y, 1 + 2 * x, sd_y, log = TRUE)
          },
          0,
          1
        )
        expect_lt(abs(rule$log_denom - ref), tol)
      }
    }
  }
})

test_that("TMB Beta mi() objective stays finite for prior shapes below one (check 6)", {
  dat <- mi_w_beta_data()
  fit <- mi_w_fit("beta", dat)
  par <- fit$obj$par
  # sigma_mi = 3 gives phi = 1/9, so both prior shapes are below 0.11.
  par[names(par) == "log_sigma_mi"] <- log(3)
  expect_true(is.finite(fit$obj$fn(par)))
  expect_true(all(is.finite(fit$obj$gr(par))))
  rep <- fit$obj$report(par)
  expect_true(all(is.finite(rep$mi_x_full)))
  expect_true(all(rep$mi_x_full >= 0 & rep$mi_x_full <= 1))
})

mi_w_nbinom2_dispersed_data <- function() {
  set.seed(4401)
  n <- 120
  z <- stats::rnorm(n)
  x <- 0.2 + 0.7 * z + stats::rnorm(n, 0, 0.5)
  mu <- exp(0.3 + 0.4 * z + 0.9 * x)
  y <- stats::rnbinom(n, size = 2, mu = mu)
  dat <- data.frame(y = y, z = z, x = x)
  dat$x[sample(n, 14)] <- NA_real_
  dat
}

test_that("fractional weights on latent nbinom2 mi() rows behave (#1459 review)", {
  # Moderate dispersion, so the log-sigma ridge of the Poisson-limit fixture
  # does not hide a bias. A weight on the latent row must multiply that
  # row's marginal, so (a) a constant weight leaves the MLE unchanged and
  # scales logLik, and (b) a tiny weight on the latent rows is the same fit
  # as dropping them. The earlier correction sat inside the Laplace problem
  # and failed both (slope 1.17 -> 0.05 at weight 1e-6 on 14 rows).
  dat <- mi_w_nbinom2_dispersed_data()
  miss <- which(is.na(dat$x))
  fit_1 <- mi_w_fit("nbinom2", dat)
  est_1 <- mi_w_estimates(fit_1)

  for (w in c(0.1, 0.5, 3)) {
    fit_c <- mi_w_fit("nbinom2", dat, w_row = rep(w, nrow(dat)))
    expect_equal(mi_w_estimates(fit_c), est_1, tolerance = 2e-3, info = w)
    expect_lt(
      abs(as.numeric(logLik(fit_c)) - w * as.numeric(logLik(fit_1))),
      5e-3 * max(1, w)
    )
  }

  w_tiny <- rep(1, nrow(dat))
  w_tiny[miss] <- 1e-6
  fit_tiny <- mi_w_fit("nbinom2", dat, w_row = w_tiny)
  w_zero <- rep(1, nrow(dat))
  w_zero[miss] <- 0
  fit_zero <- mi_w_fit("nbinom2", dat, w_row = w_zero)
  # Dropping the latent rows leaves no missing predictor, so the reference
  # is the ordinary nbinom2 fit on the observed rows: its mu and sigma
  # coefficients are those of the zero-weight mi() fit (the predictor prior
  # only moves the imputation-model parameters).
  fit_obs <- drmTMB(
    bf(y ~ z + x, sigma ~ 1),
    data = dat[-miss, , drop = FALSE],
    family = nbinom2(),
    control = drm_control(se = FALSE)
  )
  mu_ref <- unname(coef(fit_obs, "mu"))
  sigma_ref <- unname(coef(fit_obs, "sigma"))
  for (fit in list(fit_zero, fit_tiny)) {
    expect_equal(unname(coef(fit, "mu")), mu_ref, tolerance = 2e-3)
    expect_equal(unname(coef(fit, "sigma")), sigma_ref, tolerance = 5e-3)
  }
  expect_equal(
    as.numeric(logLik(fit_zero)),
    as.numeric(logLik(fit_tiny)),
    tolerance = 1e-4
  )

  # The latent modes (what predict() and imputed() read) must not depend on
  # the weight: with a constant weight the fitted parameters are the same, so
  # the fitted x_miss must agree too. (The earlier correction moved it by up
  # to 0.7 at weight 0.01.)
  x_miss_of <- function(fit) {
    fit$obj$env$parList(fit$obj$env$last.par.best)$x_miss
  }
  x_1 <- x_miss_of(fit_1)
  for (w in c(0.1, 4)) {
    fit_w <- mi_w_fit("nbinom2", dat, w_row = rep(w, nrow(dat)))
    expect_equal(x_miss_of(fit_w), x_1, tolerance = 5e-3, info = w)
  }
})
