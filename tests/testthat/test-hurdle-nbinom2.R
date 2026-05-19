new_hurdle_nbinom2_data <- function(n = 1800, seed = 20260623) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    w = stats::rnorm(n),
    habitat = factor(rep(c("open", "closed"), length.out = n))
  )
  beta_mu <- c(`(Intercept)` = 0.40, x = -0.22, habitatopen = 0.20)
  beta_sigma <- c(`(Intercept)` = -0.75, z = 0.18)
  beta_hu <- c(`(Intercept)` = -0.85, w = 0.45, habitatopen = -0.35)
  X_mu <- stats::model.matrix(~ x + habitat, dat)
  X_sigma <- stats::model.matrix(~z, dat)
  X_hu <- stats::model.matrix(~ w + habitat, dat)
  mu <- exp(as.vector(X_mu %*% beta_mu))
  sigma <- exp(as.vector(X_sigma %*% beta_sigma))
  hu <- stats::plogis(as.vector(X_hu %*% beta_hu))
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  hurdle_zero <- stats::runif(n) < hu
  positive_u <- p0 + pmax(stats::runif(n), .Machine$double.eps) * (1 - p0)
  dat$count <- ifelse(
    hurdle_zero,
    0,
    stats::qnbinom(positive_u, size = 1 / sigma^2, mu = mu)
  )
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    beta_hu = beta_hu
  )
}

test_that("drmTMB fits fixed-effect hurdle nbinom2 models", {
  sim <- new_hurdle_nbinom2_data()

  fit <- drmTMB(
    bf(count ~ x + habitat, sigma ~ z, hu ~ w + habitat),
    family = truncated_nbinom2(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "hurdle_nbinom2")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_named(coef(fit), c("mu", "sigma", "hu"))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.18)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.25)
  expect_lt(max(abs(coef(fit, "hu") - sim$beta_hu)), 0.35)
  expect_true(any(fit$model$y == 0))
  expect_true(any(fit$model$y > 0))
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(sigma(fit) > 0))
  expect_true(all(predict(fit, dpar = "hu") > 0))
  expect_true(all(predict(fit, dpar = "hu") < 1))
  expect_equal(
    predict(fit, dpar = "hu"),
    stats::plogis(predict(fit, dpar = "hu", type = "link")),
    tolerance = 1e-12
  )

  ci <- confint(fit)
  expect_equal(
    ci$parm,
    c(
      "fixef:mu:(Intercept)",
      "fixef:mu:x",
      "fixef:mu:habitatopen",
      "fixef:sigma:(Intercept)",
      "fixef:sigma:z",
      "fixef:hu:(Intercept)",
      "fixef:hu:w",
      "fixef:hu:habitatopen"
    )
  )
  expect_equal(
    ci$tmb_parameter,
    c(
      "beta_mu",
      "beta_mu",
      "beta_mu",
      "beta_sigma",
      "beta_sigma",
      "beta_zi",
      "beta_zi",
      "beta_zi"
    )
  )
  expect_true(all(ci$conf.status == "wald"))
})

test_that("hurdle nbinom2 likelihood matches independent calculation", {
  sim <- new_hurdle_nbinom2_data(n = 420, seed = 20260624)

  fit <- drmTMB(
    bf(count ~ x + habitat, sigma ~ z, hu ~ w + habitat),
    family = truncated_nbinom2(),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  eta_hu <- as.vector(fit$model$X$hu %*% coef(fit, "hu"))
  mu <- exp(eta_mu)
  sigma <- exp(eta_sigma)
  hu <- stats::plogis(eta_hu)
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  ll_positive <- stats::dnbinom(
    fit$model$y,
    size = 1 / sigma^2,
    mu = mu,
    log = TRUE
  ) -
    log1p(-p0)
  ll_independent <- sum(ifelse(
    fit$model$y == 0,
    log(hu),
    log1p(-hu) + ll_positive
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)
})

test_that("hurdle nbinom2 methods return unconditional summaries", {
  sim <- new_hurdle_nbinom2_data(n = 300, seed = 20260625)
  fit <- drmTMB(
    bf(count ~ x + habitat, sigma ~ z, hu ~ w + habitat),
    family = truncated_nbinom2(),
    data = sim$data
  )

  mu <- predict(fit, dpar = "mu")
  sigma <- sigma(fit)
  hu <- predict(fit, dpar = "hu")
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  positive_mean <- mu / (1 - p0)
  component_var <- mu + sigma^2 * mu^2
  positive_var <- (component_var + mu^2) / (1 - p0) - positive_mean^2
  fitted_mean <- (1 - hu) * positive_mean
  hurdle_var <- (1 - hu) * positive_var + hu * (1 - hu) * positive_mean^2

  expect_equal(fitted(fit), fitted_mean, tolerance = 1e-12)
  expect_equal(predict(fit, dpar = "sigma", type = "response"), sigma)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - fitted_mean) / sqrt(hurdle_var),
    tolerance = 1e-12
  )
  expect_equal(residuals(fit), fit$model$y - fitted_mean, tolerance = 1e-12)
  newdata <- data.frame(
    x = c(-1, 0, 1),
    z = c(-1, 0, 1),
    w = c(-1, 0, 1),
    habitat = factor(
      c("closed", "open", "closed"),
      levels = levels(sim$data$habitat)
    )
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "hu"),
    stats::plogis(as.vector(
      stats::model.matrix(~ w + habitat, newdata) %*% coef(fit, "hu")
    )),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260626)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) >= 0))
  expect_true(all(unlist(sims, use.names = FALSE) %% 1 == 0))
  expect_true(any(unlist(sims, use.names = FALSE) == 0))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260626),
    simulate(fit, nsim = 2, seed = 20260626)
  )
})

test_that("hurdle nbinom2 supports default sigma and complete-case filtering", {
  sim <- new_hurdle_nbinom2_data(n = 120, seed = 20260627)
  fit_default_sigma <- drmTMB(
    bf(count ~ x, hu ~ w),
    family = truncated_nbinom2(),
    data = sim$data
  )

  expect_equal(fit_default_sigma$opt$convergence, 0)
  expect_length(coef(fit_default_sigma, "sigma"), 1)
  expect_equal(ncol(fit_default_sigma$model$X$sigma), 1)

  dat <- sim$data[seq_len(50), ]
  dat$count[[1L]] <- -1
  dat$x[[1L]] <- NA
  dat$count[[2L]] <- 1.5
  dat$w[[2L]] <- NA

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z, hu ~ w),
    family = truncated_nbinom2(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), nrow(dat) - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y >= 0))
  expect_true(all(fit$model$y %% 1 == 0))
})

test_that("hurdle nbinom2 approaches hurdle zero-truncated Poisson as sigma approaches zero", {
  dat <- data.frame(y = c(0, 0, 1, 1, 2, 4, 7))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1, hu ~ 1),
    family = truncated_nbinom2(),
    data = dat
  )

  par <- fit$obj$par
  par[["beta_mu"]] <- 0
  par[["beta_sigma"]] <- -20
  par[["beta_zi"]] <- stats::qlogis(0.25)
  ll_nb <- -fit$obj$fn(par)
  ll_pois <- sum(ifelse(
    dat$y == 0,
    log(0.25),
    log(0.75) +
      stats::dpois(dat$y, lambda = 1, log = TRUE) -
      log1p(-stats::dpois(0, lambda = 1))
  ))

  expect_equal(ll_nb, ll_pois, tolerance = 1e-6)
  expect_true(is.finite(fit$obj$fn(par)))
})

test_that("hurdle nbinom2 rejects unsupported or invalid inputs", {
  dat <- data.frame(
    y = c(0, 1, 2, 3),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(bf(y ~ x, zi ~ 1, hu ~ 1), family = truncated_nbinom2(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(y ~ x, hu = y ~ x), family = truncated_nbinom2(), data = dat),
    "one-sided"
  )
  expect_error(
    drmTMB(bf(y ~ x, hu ~ 1, hu ~ x), family = truncated_nbinom2(), data = dat),
    "at most one"
  )
  expect_error(
    drmTMB(bf(y ~ x, hu ~ 0), family = truncated_nbinom2(), data = dat),
    "zero-column"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), hu ~ 1),
      family = truncated_nbinom2(),
      data = dat
    ),
    "Hurdle .* random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (0 + x | id), hu ~ 1),
      family = truncated_nbinom2(),
      data = dat
    ),
    "Hurdle .* random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, hu ~ x + (1 | id)),
      family = truncated_nbinom2(),
      data = dat
    ),
    "Hurdle random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, hu ~ x + (0 + x | id)),
      family = truncated_nbinom2(),
      data = dat
    ),
    "Hurdle random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, hu ~ 1, sd(id) ~ 1),
      family = truncated_nbinom2(),
      data = dat
    ),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_known_V(V = rep(0.1, 4)), sigma ~ 1, hu ~ 1),
      family = truncated_nbinom2(),
      data = dat
    ),
    "meta_known_V"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, hu ~ 1),
      family = truncated_nbinom2(),
      data = transform(dat, y = c(0, -1, 2, 3))
    ),
    "non-negative integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, hu ~ 1),
      family = truncated_nbinom2(),
      data = transform(dat, y = c(0, 1.5, 2, 3))
    ),
    "non-negative integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, hu ~ 1),
      family = truncated_nbinom2(),
      data = transform(dat, y = 0)
    ),
    "at least one positive"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y, y) ~ x, hu ~ 1),
      family = truncated_nbinom2(),
      data = dat
    ),
    "mvbind"
  )
  expect_error(
    drmTMB(
      bf(cbind(y, y) ~ x, hu ~ 1),
      family = truncated_nbinom2(),
      data = dat
    ),
    "single positive-count response"
  )
})
