test_that("Gaussian random intercepts agree with lme4 on an overlapping model", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260512)
  n_id <- 30
  n_each <- 8
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  u_id <- stats::rnorm(n_id, sd = 0.6)
  dat$y <- stats::rnorm(
    n,
    mean = 0.4 + 0.7 * dat$x + u_id[dat$id],
    sd = 0.5
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id)),
    family = gaussian(),
    data = dat
  )
  fit_lme4 <- lme4::lmer(y ~ x + (1 | id), data = dat, REML = FALSE)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(lme4::VarCorr(fit_lme4)$id, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(stats::AIC(fit), stats::AIC(fit_lme4), tolerance = 1e-4)
  expect_equal(stats::BIC(fit), stats::BIC(fit_lme4), tolerance = 1e-4)
})

test_that("Poisson random intercepts agree with lme4 on an overlapping model", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260620)
  n_id <- 32
  n_each <- 9
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  u_id <- stats::rnorm(n_id, sd = 0.45)
  dat$y <- stats::rpois(n, exp(0.25 - 0.35 * dat$x + u_id[dat$id]))

  fit <- drmTMB(
    bf(y ~ x + (1 | id)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  fit_lme4 <- lme4::glmer(
    y ~ x + (1 | id),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 5e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(lme4::VarCorr(fit_lme4)$id, "stddev")),
    tolerance = 5e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 5e-4
  )
})

test_that("Poisson independent random slopes agree with lme4 on an overlapping model", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260622)
  n_id <- 36
  n_each <- 12
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  u0 <- stats::rnorm(n_id, sd = 0.35)
  u1 <- stats::rnorm(n_id, sd = 0.30)
  dat$y <- stats::rpois(
    n,
    exp(0.30 - 0.20 * dat$x + u0[dat$id] + u1[dat$id] * dat$x)
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  fit_lme4 <- lme4::glmer(
    y ~ x + (1 | id) + (0 + x | id),
    family = stats::poisson(link = "log"),
    data = dat
  )
  sd_lme4 <- unname(unlist(lapply(
    lme4::VarCorr(fit_lme4),
    function(term) attr(term, "stddev")
  )))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-3
  )
  expect_equal(
    unname(fit$sdpars$mu),
    sd_lme4,
    tolerance = 1e-3
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-3
  )
})

test_that("Gaussian independent random slopes agree with lme4 on an overlapping model", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260514)
  n_id <- 36
  n_each <- 9
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  u0 <- stats::rnorm(n_id, sd = 0.5)
  u1 <- stats::rnorm(n_id, sd = 0.4)
  dat$y <- stats::rnorm(
    n,
    mean = 0.25 + 0.65 * dat$x + u0[dat$id] + u1[dat$id] * dat$x,
    sd = 0.45
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id)),
    family = gaussian(),
    data = dat
  )
  fit_lme4 <- lme4::lmer(
    y ~ x + (1 | id) + (0 + x | id),
    data = dat,
    REML = FALSE
  )
  sd_lme4 <- unname(unlist(lapply(
    lme4::VarCorr(fit_lme4),
    function(term) attr(term, "stddev")
  )))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    sd_lme4,
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
})

test_that("Gaussian correlated random slopes agree with lme4 on an overlapping model", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260521)
  n_id <- 32
  n_each <- 8
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  sd0 <- 0.5
  sd1 <- 0.35
  rho_re <- 0.4
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  u0 <- sd0 * z0
  u1 <- sd1 * (rho_re * z0 + sqrt(1 - rho_re^2) * z1)
  dat$y <- stats::rnorm(
    n,
    mean = 0.25 + 0.65 * dat$x + u0[dat$id] + u1[dat$id] * dat$x,
    sd = 0.45
  )

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id)),
    family = gaussian(),
    data = dat
  )
  fit_lme4 <- lme4::lmer(y ~ x + (1 + x | id), data = dat, REML = FALSE)
  vc_lme4 <- lme4::VarCorr(fit_lme4)$id

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(vc_lme4, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$corpars$mu),
    unname(attr(vc_lme4, "correlation")[1, 2]),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
})

test_that("labelled Gaussian correlated random slopes agree with lme4 semantics", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260538)
  n_id <- 32
  n_each <- 8
  n <- n_id * n_each
  dat <- data.frame(
    ID = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n),
    f = factor(rep(c("control", "treated"), length.out = n))
  )
  sd0 <- 0.5
  sd1 <- 0.35
  rho_re <- 0.4
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  u0 <- sd0 * z0
  u1 <- sd1 * (rho_re * z0 + sqrt(1 - rho_re^2) * z1)
  dat$y <- stats::rnorm(
    n,
    mean = 0.25 +
      0.65 * dat$x +
      0.2 * (dat$f == "treated") +
      u0[dat$ID] +
      u1[dat$ID] * dat$x,
    sd = 0.45
  )

  fit <- drmTMB(
    bf(y ~ x + f + (1 + x | p | ID)),
    family = gaussian(),
    data = dat
  )
  fit_lme4 <- lme4::lmer(y ~ x + f + (1 + x | ID), data = dat, REML = FALSE)
  vc_lme4 <- lme4::VarCorr(fit_lme4)$ID

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(vc_lme4, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$corpars$mu),
    unname(attr(vc_lme4, "correlation")[1, 2]),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
})

test_that("Gaussian sd(id) intercept-only random-effect scale agrees with lme4", {
  testthat::skip_if_not_installed("lme4")

  sim <- new_gaussian_re_scale_data(
    n_id = 30,
    n_each = 8,
    alpha = c(`(Intercept)` = log(0.6), w = 0),
    beta_sigma = c(`(Intercept)` = log(0.5), z = 0),
    seed = 20260560
  )
  dat <- sim$data

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ 1),
    family = gaussian(),
    data = dat
  )
  fit_lme4 <- lme4::lmer(y ~ x + (1 | id), data = dat, REML = FALSE)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    exp(unname(coef(fit, "sd(id)")[[1L]])),
    unname(attr(lme4::VarCorr(fit_lme4)$id, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
})

test_that("Gaussian fixed-effect location-scale agrees with glmmTMB dispersion", {
  suppressWarnings(testthat::skip_if_not_installed("glmmTMB"))

  set.seed(20260620)
  n <- 240
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.30, x = -0.45)
  beta_sigma <- c(`(Intercept)` = log(0.55), z = 0.25)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )
  fit_glmmTMB <- suppressWarnings(glmmTMB::glmmTMB(
    y ~ x,
    dispformula = ~z,
    family = gaussian(),
    data = dat
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(glmmTMB::fixef(fit_glmmTMB)$cond),
    tolerance = 1e-4
  )
  expect_equal(
    unname(coef(fit, "sigma")),
    unname(glmmTMB::fixef(fit_glmmTMB)$disp),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_glmmTMB)),
    tolerance = 1e-4
  )
})

test_that("Gaussian random-intercept location-scale agrees with glmmTMB dispersion", {
  suppressWarnings(testthat::skip_if_not_installed("glmmTMB"))

  set.seed(20260621)
  n_id <- 24
  n_each <- 8
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.20, x = 0.50)
  beta_sigma <- c(`(Intercept)` = log(0.45), z = -0.20)
  sd_id <- 0.35
  u_id <- stats::rnorm(n_id, sd = sd_id)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x + u_id[dat$id]
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )
  fit_glmmTMB <- suppressWarnings(glmmTMB::glmmTMB(
    y ~ x + (1 | id),
    dispformula = ~z,
    family = gaussian(),
    data = dat
  ))
  vc_glmmTMB <- glmmTMB::VarCorr(fit_glmmTMB)$cond$id

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(glmmTMB::fixef(fit_glmmTMB)$cond),
    tolerance = 1e-4
  )
  expect_equal(
    unname(coef(fit, "sigma")),
    unname(glmmTMB::fixef(fit_glmmTMB)$disp),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(vc_glmmTMB, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_glmmTMB)),
    tolerance = 1e-4
  )
})

test_that("Gamma mean model agrees with base glm on an overlapping model", {
  set.seed(20260595)
  n <- 240
  dat <- data.frame(x = stats::rnorm(n))
  beta_mu <- c(0.2, -0.35)
  cv <- 0.55
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  dat$biomass <- stats::rgamma(n, shape = 1 / cv^2, scale = mu * cv^2)

  fit <- drmTMB(
    bf(biomass ~ x),
    family = stats::Gamma(link = "log"),
    data = dat
  )
  fit_glm <- stats::glm(
    biomass ~ x,
    family = stats::Gamma(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_glm)),
    tolerance = 1e-4
  )
})

test_that("negative-binomial 2 mean-dispersion agrees with MASS glm.nb", {
  testthat::skip_if_not_installed("MASS")

  set.seed(20260618)
  n <- 260
  dat <- data.frame(x = stats::rnorm(n))
  beta_mu <- c(`(Intercept)` = 0.25, x = -0.40)
  sigma <- 0.55
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  dat$count <- stats::rnbinom(n, size = 1 / sigma^2, mu = mu)

  fit <- drmTMB(
    bf(count ~ x, sigma ~ 1),
    family = nbinom2(),
    data = dat
  )
  fit_mass <- MASS::glm.nb(count ~ x, data = dat)

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_mass)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(sigma(fit)[[1L]]),
    unname(1 / sqrt(fit_mass$theta)),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_mass)),
    tolerance = 1e-4
  )
})

test_that("Gaussian meta-analysis agrees with metafor for ML tau2", {
  testthat::skip_if_not_installed("metafor")

  set.seed(20260513)
  n <- 80
  dat <- data.frame(
    x = stats::rnorm(n),
    vi = stats::runif(n, min = 0.01, max = 0.08)
  )
  tau <- 0.25
  dat$yi <- stats::rnorm(
    n,
    mean = 0.2 - 0.4 * dat$x,
    sd = sqrt(dat$vi + tau^2)
  )

  fit <- drmTMB(
    bf(yi ~ x + meta_known_V(V = vi)),
    family = gaussian(),
    data = dat
  )
  fit_metafor <- metafor::rma.uni(
    yi = yi,
    vi = vi,
    mods = ~x,
    data = dat,
    method = "ML"
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_metafor)),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]]^2,
    fit_metafor$tau2,
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_metafor)),
    tolerance = 1e-4
  )
})

test_that("dense known-V Gaussian meta-analysis agrees with metafor rma.mv", {
  testthat::skip_if_not_installed("metafor")

  set.seed(20260590)
  n <- 36
  dat <- data.frame(
    x = stats::rnorm(n),
    obs = factor(seq_len(n))
  )
  V <- 0.012 * outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  beta_mu <- c(0.15, -0.45)
  tau <- 0.28
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x
  Sigma <- V + diag(tau^2, n)
  dat$yi <- as.vector(mu + t(chol(Sigma)) %*% stats::rnorm(n))

  fit <- drmTMB(
    bf(yi ~ x + meta_known_V(V = V)),
    family = gaussian(),
    data = dat
  )
  fit_metafor <- metafor::rma.mv(
    yi = yi,
    V = V,
    mods = ~x,
    random = ~ 1 | obs,
    data = dat,
    method = "ML"
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_metafor)),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]]^2,
    fit_metafor$sigma2[[1L]],
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_metafor)),
    tolerance = 1e-4
  )
})
