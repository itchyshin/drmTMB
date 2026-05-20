new_gaussian_ls_data <- function(n = 80) {
  x <- seq(-1, 1, length.out = n)
  z <- rep(seq(-0.8, 0.8, length.out = 5), length.out = n)
  mu <- 0.25 + 0.6 * x
  sigma <- exp(-0.3 + 0.25 * z)
  eps <- rep(c(-0.85, -0.1, 0.65, 1.15, -0.45), length.out = n)

  data.frame(
    y = mu + sigma * eps,
    x = x,
    z = z
  )
}

test_that("drmTMB fits fixed-effect Gaussian location-scale models", {
  set.seed(20260506)
  n <- 500
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(0.4, 0.7)
  beta_sigma <- c(-0.2, 0.35)
  mu <- beta_mu[[1]] + beta_mu[[2]] * dat$x
  sigma <- exp(beta_sigma[[1]] + beta_sigma[[2]] * dat$z)
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(unname(coef(fit, "mu")), beta_mu, tolerance = 0.12)
  expect_equal(unname(coef(fit, "sigma")), beta_sigma, tolerance = 0.12)
  expect_equal(fixef(fit), coef(fit))
  expect_equal(fixef(fit, "mu"), coef(fit, "mu"))
  expect_equal(ranef(fit), list())
  expect_snapshot(rho12(fit), error = TRUE)
  expect_length(predict(fit, dpar = "mu"), n)
  expect_equal(stats::fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)
  expect_true(all(stats::sigma(fit) > 0))
  expect_s3_class(stats::logLik(fit), "logLik")
  expect_equal(stats::nobs(fit), n)
  expect_equal(stats::df.residual(fit), fit$nobs - fit$df)
  expect_equal(
    stats::deviance(fit),
    -2 * as.numeric(stats::logLik(fit)),
    tolerance = 1e-12
  )
  expect_equal(
    stats::AIC(fit),
    stats::deviance(fit) + 2 * fit$df,
    tolerance = 1e-12
  )
})

test_that("drmTMB uses complete cases across Gaussian location-scale terms", {
  dat <- new_gaussian_ls_data(48)
  dat$unused <- NA_real_
  dat$y[4] <- NA_real_
  dat$x[13] <- NA_real_
  dat$z[25] <- NA_real_
  keep <- stats::complete.cases(dat[c("y", "x", "z")])

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(stats::nobs(fit), sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_equal(fit$data$y, dat$y[keep])
  expect_equal(fit$data$x, dat$x[keep])
  expect_equal(fit$data$z, dat$z[keep])
  expect_equal(sum(is.na(fit$data[c("y", "x", "z")])), 0)
  expect_length(predict(fit, dpar = "mu"), sum(keep))
  expect_length(predict(fit, dpar = "sigma"), sum(keep))
})

test_that("drmTMB fits explicit intercept-only sigma formulas", {
  dat <- new_gaussian_ls_data(64)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  sigma_coef <- coef(fit, "sigma")
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  sigma_response <- predict(fit, dpar = "sigma")

  expect_equal(fit$opt$convergence, 0)
  expect_equal(names(sigma_coef), "(Intercept)")
  expect_equal(
    sigma_link,
    rep(unname(sigma_coef), nrow(dat)),
    tolerance = 1e-12
  )
  expect_equal(sigma_response, exp(sigma_link), tolerance = 1e-12)
  expect_equal(min(sigma_response), max(sigma_response), tolerance = 1e-12)
})

test_that("predict() uses newdata for Gaussian location-scale fits", {
  dat <- new_gaussian_ls_data(72)
  newdata <- data.frame(
    x = c(-0.75, 0.2, 0.9),
    z = c(0.8, 0, -0.8)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expected_mu <- as.vector(
    stats::model.matrix(~x, newdata) %*% coef(fit, "mu")
  )
  expected_sigma_link <- as.vector(
    stats::model.matrix(~z, newdata) %*% coef(fit, "sigma")
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    expected_mu,
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma", type = "link"),
    expected_sigma_link,
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma"),
    exp(expected_sigma_link),
    tolerance = 1e-12
  )
  expect_error(
    predict(fit, newdata = list(x = 0, z = 0), dpar = "mu"),
    "data frame"
  )
})

test_that("fixed-effect formulas support standard R transformations and interactions", {
  set.seed(20260620)
  n <- 120
  dat <- data.frame(
    x = stats::runif(n, -1, 1),
    x1 = stats::rnorm(n),
    x2 = stats::rnorm(n),
    x3 = stats::rnorm(n),
    z = stats::runif(n, -1, 1)
  )
  dat$y <- 0.2 +
    0.3 * dat$x +
    0.2 * dat$x^2 +
    0.1 * dat$x1 * dat$x2 +
    stats::rnorm(n, sd = 0.5)

  fit <- drmTMB(
    drm_formula(
      y ~ poly(x, 2) + I(x^2) + (x1 + x2 + x3)^2,
      sigma ~ poly(z, 2) + x1:x2
    ),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    names(coef(fit, "mu")),
    c(
      "(Intercept)",
      "poly(x, 2)1",
      "poly(x, 2)2",
      "I(x^2)",
      "x1",
      "x2",
      "x3",
      "x1:x2",
      "x1:x3",
      "x2:x3"
    )
  )
  expect_equal(
    names(coef(fit, "sigma")),
    c("(Intercept)", "poly(z, 2)1", "poly(z, 2)2", "x1:x2")
  )

  newdata <- dat[1:4, ]
  mu_poly <- stats::poly(dat$x, 2)
  mu_poly_new <- stats::predict(mu_poly, newdata$x)
  expected_mu_X <- cbind(
    "(Intercept)" = 1,
    "poly(x, 2)1" = mu_poly_new[, 1],
    "poly(x, 2)2" = mu_poly_new[, 2],
    "I(x^2)" = newdata$x^2,
    "x1" = newdata$x1,
    "x2" = newdata$x2,
    "x3" = newdata$x3,
    "x1:x2" = newdata$x1 * newdata$x2,
    "x1:x3" = newdata$x1 * newdata$x3,
    "x2:x3" = newdata$x2 * newdata$x3
  )
  sigma_poly <- stats::poly(dat$z, 2)
  sigma_poly_new <- stats::predict(sigma_poly, newdata$z)
  expected_sigma_X <- cbind(
    "(Intercept)" = 1,
    "poly(z, 2)1" = sigma_poly_new[, 1],
    "poly(z, 2)2" = sigma_poly_new[, 2],
    "x1:x2" = newdata$x1 * newdata$x2
  )

  expect_equal(
    stats::model.matrix(fit$model$terms$mu, newdata),
    expected_mu_X,
    tolerance = 1e-12,
    ignore_attr = TRUE
  )
  expect_equal(
    stats::model.matrix(fit$model$terms$sigma, newdata),
    expected_sigma_X,
    tolerance = 1e-12,
    ignore_attr = TRUE
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    as.vector(expected_mu_X %*% coef(fit, "mu")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma", type = "link"),
    as.vector(expected_sigma_X %*% coef(fit, "sigma")),
    tolerance = 1e-12
  )
})

test_that("Gaussian likelihood weights are row log-likelihood multipliers", {
  dat <- new_gaussian_ls_data(75)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )
  fit_double <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat,
    weights = rep(2, nrow(dat))
  )

  expect_equal(stats::weights(fit), rep(1, nrow(dat)))
  expect_equal(stats::weights(fit_double), rep(2, nrow(dat)))
  expect_equal(coef(fit_double, "mu"), coef(fit, "mu"), tolerance = 1e-5)
  expect_equal(coef(fit_double, "sigma"), coef(fit, "sigma"), tolerance = 1e-5)
  expect_equal(
    as.numeric(stats::logLik(fit_double)),
    2 * as.numeric(stats::logLik(fit)),
    tolerance = 1e-4
  )
})

test_that("Gaussian likelihood weights match row duplication and zero-row dropping", {
  dat <- new_gaussian_ls_data(80)
  w <- rep(c(0, 1, 2, 3), length.out = nrow(dat))
  dat_expanded <- dat[rep(seq_len(nrow(dat)), w), , drop = FALSE]

  fit_weighted <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat,
    weights = w
  )
  fit_expanded <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat_expanded
  )

  expect_equal(stats::weights(fit_weighted), w)
  expect_equal(
    coef(fit_weighted, "mu"),
    coef(fit_expanded, "mu"),
    tolerance = 1e-5
  )
  expect_equal(
    coef(fit_weighted, "sigma"),
    coef(fit_expanded, "sigma"),
    tolerance = 1e-5
  )
  expect_equal(
    as.numeric(stats::logLik(fit_weighted)),
    as.numeric(stats::logLik(fit_expanded)),
    tolerance = 1e-4
  )
})

test_that("Gaussian likelihood weights follow model-row filtering", {
  dat <- new_gaussian_ls_data(48)
  dat$y[3] <- NA_real_
  dat$x[7] <- NA_real_
  dat$z[11] <- NA_real_
  dat$w <- seq_len(nrow(dat))
  keep <- stats::complete.cases(dat[c("y", "x", "z")])

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat,
    weights = w
  )

  expect_equal(fit$model$keep, keep)
  expect_equal(stats::weights(fit), dat$w[keep])
  expect_equal(length(stats::weights(fit)), stats::nobs(fit))
})

test_that("Gaussian likelihood weights validate malformed inputs", {
  dat <- new_gaussian_ls_data(12)

  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z), data = dat, weights = rep(1, 11)),
    "one value per row"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z), data = dat, weights = c(rep(1, 11), -1)),
    "non-negative"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z), data = dat, weights = c(rep(1, 11), NA)),
    "finite and non-missing"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z), data = dat, weights = rep(0, 12)),
    "at least one positive"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z), data = dat, weights = matrix(1, nrow = 12)),
    "numeric vector"
  )
})

test_that("drmTMB handles factor predictors and default sigma", {
  set.seed(20260507)
  n <- 240
  dat <- data.frame(
    group = factor(rep(c("control", "treatment"), each = n / 2))
  )
  dat$y <- stats::rnorm(
    n,
    mean = 1 + 0.6 * (dat$group == "treatment"),
    sd = 0.8
  )

  fit <- drmTMB(
    bf(y ~ group),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_length(coef(fit, "mu"), 2)
  expect_length(coef(fit, "sigma"), 1)
  sims <- simulate(fit, nsim = 2, seed = 1)
  expect_s3_class(sims, "data.frame")
  expect_equal(dim(sims), c(n, 2))
})

test_that("Phase 1 rejects unsupported model syntax clearly", {
  dat <- data.frame(
    y = seq(-1, 1, length.out = 10),
    y2 = seq(0.5, 1.5, length.out = 10),
    x = seq(1, 2, length.out = 10),
    z = seq(0, 1, length.out = 10),
    id = rep(1:2, each = 5)
  )
  K <- diag(2)
  rownames(K) <- colnames(K) <- c("1", "2")

  expect_error(
    drmTMB(bf(y ~ x), family = poisson(), data = dat),
    "non-negative integer"
  )
  expect_error(
    drmTMB(bf(mu1 = y ~ x, mu2 = y ~ x), family = gaussian(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(y ~ x, shape ~ x), family = gaussian(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(y ~ x + (0 + x + z | id)), family = gaussian(), data = dat),
    "ordinary Gaussian location block"
  )
  expect_error(
    drmTMB(bf(y ~ x, rho12 = ~x), family = gaussian(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 + x | id, tree = tree)),
      family = gaussian(),
      data = dat
    ),
    "intercept-only phylogenetic"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + spatial(1 + x + z | id, coords = coords)),
      family = gaussian(),
      data = dat
    ),
    "intercept and one-slope structured terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + spatial(1 | id, mesh = mesh)),
      family = gaussian(),
      data = dat
    ),
    "mesh fitting is planned"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ spatial(1 | id, coords = coords)),
      family = gaussian(),
      data = dat
    ),
    "planned, not implemented"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y ~ x + spatial(1 | id, coords = coords),
        mu2 = y2 ~ x,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "planned, not implemented"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y ~ x + phylo(1 | id, tree = tree),
        mu2 = y2 ~ x,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "must be matched"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ gr(id, cov = diag(1))),
      family = gaussian(),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 | id, pedigree = pedigree), sigma ~ 1),
      family = gaussian(),
      data = dat
    ),
    "Pedigree-derived animal-model precision"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1),
      family = gaussian(),
      data = dat
    ),
    "Only intercept-only `animal\\(\\)` `mu` effects are implemented"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1),
      family = gaussian(),
      data = dat
    ),
    "Only intercept-only `relmat\\(\\)` `mu` effects are implemented"
  )
  expect_error(
    drmTMB(bf(y ~ x, sd(id) ~ 1), family = gaussian(), data = dat),
    "No random-effect term matches"
  )
})
