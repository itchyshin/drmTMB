# Hurdle Poisson / zero-truncated Poisson: `family = truncated_poisson()`
# (+ `hu ~ ...`). The likelihood is checked against hand computations and
# against the independent decomposition used by pscl::hurdle(): a logistic
# glm() for the zero part and VGAM::vglm(pospoisson) for the positive part.

log1mexp_ref <- function(a) {
  # log(1 - exp(-a)) for a > 0, stable (Maechler 2012)
  ifelse(a <= log(2), log(-expm1(-a)), log1p(-exp(-a)))
}

hurdle_pois_ll_hand <- function(y, mu, hu) {
  ll_pos <- stats::dpois(y, mu, log = TRUE) - log1mexp_ref(mu)
  sum(ifelse(y == 0, log(hu), log1p(-hu) + ll_pos))
}

new_hurdle_poisson_data <- function(n = 600, seed = 726) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n), w = stats::rnorm(n))
  mu <- exp(0.4 + 0.5 * dat$x)
  hu <- stats::plogis(-0.3 + 0.6 * dat$w)
  p0 <- stats::dpois(0, mu)
  positive <- stats::qpois(p0 + stats::runif(n) * (1 - p0), mu)
  dat$y <- ifelse(stats::runif(n) < hu, 0, positive)
  dat
}

test_that("truncated_poisson() is a drm_family with log mu link", {
  fam <- truncated_poisson()
  expect_s3_class(fam, "drm_family")
  expect_equal(fam$name, "truncated_poisson")
  expect_equal(unname(fam$links[["mu"]]), "log")
  expect_equal(fam$dpars, "mu")
})

test_that("hurdle Poisson fit matches glm + VGAM::vglm(pospoisson) decomposition", {
  skip_if_not_installed("VGAM")
  dat <- new_hurdle_poisson_data()
  fit <- drmTMB(
    bf(y ~ x, hu ~ w),
    family = truncated_poisson(),
    data = dat
  )
  expect_equal(fit$model$model_type, "hurdle_poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(coef(fit), c("mu", "hu"))

  zero_fit <- stats::glm(
    I(y == 0) ~ w,
    family = stats::binomial(),
    data = dat
  )
  pos <- dat[dat$y > 0, ]
  pos_fit <- suppressWarnings(VGAM::vglm(y ~ x, VGAM::pospoisson(), data = pos))
  expect_equal(
    unname(coef(fit, "hu")),
    unname(stats::coef(zero_fit)),
    tolerance = 1e-6
  )
  expect_equal(
    unname(coef(fit, "mu")),
    unname(VGAM::coef(pos_fit)),
    tolerance = 1e-6
  )
  expect_equal(
    as.numeric(logLik(fit)),
    as.numeric(stats::logLik(zero_fit)) + as.numeric(VGAM::logLik(pos_fit)),
    tolerance = 1e-6
  )
})

test_that("hurdle Poisson likelihood equals hand computation to 1e-10", {
  dat <- new_hurdle_poisson_data(n = 150, seed = 727)
  fit <- drmTMB(bf(y ~ x, hu ~ w), family = truncated_poisson(), data = dat)
  X_mu <- fit$model$X$mu
  X_hu <- fit$model$X$hu
  par_names <- names(fit$obj$par)
  set.seed(1)
  for (k in 1:5) {
    b_mu <- stats::rnorm(2, sd = 0.7)
    b_hu <- stats::rnorm(2, sd = 0.7)
    par <- fit$obj$par
    par[par_names == "beta_mu"] <- b_mu
    par[par_names == "beta_zi"] <- b_hu
    ll_hand <- hurdle_pois_ll_hand(
      dat$y,
      exp(as.vector(X_mu %*% b_mu)),
      stats::plogis(as.vector(X_hu %*% b_hu))
    )
    expect_equal(-fit$obj$fn(par), ll_hand, tolerance = 1e-10)
  }
  # tiny and large means: log1mexp stays accurate on both sides
  y_edge <- c(0, 1, 1, 2, 30)
  d_edge <- data.frame(y = y_edge)
  fit_edge <- drmTMB(bf(y ~ 1, hu ~ 1), family = truncated_poisson(), data = d_edge)
  for (b in c(-12, -4, -0.5, 3, 6)) {
    par <- fit_edge$obj$par
    par[names(par) == "beta_mu"] <- b
    par[names(par) == "beta_zi"] <- -0.4
    expect_equal(
      -fit_edge$obj$fn(par),
      hurdle_pois_ll_hand(y_edge, rep(exp(b), 5), stats::plogis(-0.4)),
      tolerance = 1e-10
    )
  }
})

test_that("hurdle Poisson reproduces the DRModels.jl n = 80 generated fixture", {
  # Data and constants copied from DRModels.jl test/test_hurdle.jl (generated
  # outputs: R glm + VGAM::vglm(pospoisson); data values only, no code).
  y <- c(0, 1, 3, 0, 1, 0, 3, 0, 0, 2, 0, 3, 4, 0, 4, 7, 0, 0, 0, 0, 0, 1, 6, 0, 0, 0, 0, 0, 1, 0, 2, 3, 2, 2, 0, 2, 0, 1, 0, 1, 0, 2, 1, 3, 3, 0, 5, 1, 0, 1, 1, 0, 5, 0, 3, 0, 3, 3, 0, 0, 0, 2, 0, 5, 0, 0, 3, 0, 4, 3, 2, 0, 0, 0, 1, 0, 0, 2, 4, 0)
  x <- c(0.093, -1.593, 2.332, 0.18, -2.515, 0.532, -0.098, -1.276, 1.172, -0.325, -0.562, -1.153, -0.578, -0.747, 0.152, 0.714, 1.328, -1.004, 0.866, 0.702, -0.487, 0.497, 1.432, -0.51, -0.528, -1.254, -0.302, -0.041, 0.566, -0.791, -0.78, 0.211, 0.682, 0.471, 0.276, 0.889, 0.377, 0.532, 0.697, 0.72, -1.778, -0.207, -0.506, -0.424, -1.042, 0.138, 0.578, -0.328, 0.375, 0.487, -0.371, 0.731, -0.019, 0.999, 0.423, -1.13, -0.311, 0.208, 0.623, 0.657, -0.355, -0.829, 1.072, 0.106, 0.227, -1.101, -1.207, -0.081, 1.924, -0.483, -0.468, -1.379, 0.676, -1.296, -1.075, 0.09, 0.027, -0.225, -0.152, -0.771)
  w <- c(1.419, 1.539, -0.011, -1.59, -0.287, 0.604, -0.752, 1.101, 1.052, 0.905, 1.031, -2.129, 0.101, 0.78, 0.206, 0.446, -0.483, 0.475, 0.827, -0.047, -2.175, -1.492, 0.514, -0.807, 0.392, 0.347, 0.522, 0.555, 0.399, -0.378, 1.576, 1.319, -2.051, 0.469, 0.875, -0.823, -0.236, 0.608, 0.908, 1.991, -0.02, 0.032, 0.832, -0.93, -0.685, -0.25, 0.587, 0.433, -0.004, 1.198, -1.407, 1.465, 0.227, 0.2, -0.088, 0.588, 0.408, 0.584, 0.536, 0.511, 0.03, -0.921, -0.732, 0.791, -0.167, -0.139, 0.434, -0.28, 0.681, -1.012, 0.795, -0.101, 2.34, 0.383, 1.67, 0.449, 0.038, -1.527, 0.65, 0.005)
  dat <- data.frame(y = y, x = x, w = w)
  fit <- drmTMB(bf(y ~ x, hu ~ w), family = truncated_poisson(), data = dat)
  expect_equal(fit$opt$convergence, 0)
  expect_equal(unname(coef(fit, "mu")), c(0.8576962504, 0.2575260765), tolerance = 1e-6)
  expect_equal(unname(coef(fit, "hu")), c(-0.0279126001, 0.1453952764), tolerance = 1e-6)
  expect_equal(as.numeric(logLik(fit)), -120.5723428573, tolerance = 1e-6)
})

test_that("plain zero-truncated Poisson matches VGAM::pospoisson", {
  skip_if_not_installed("VGAM")
  dat <- new_hurdle_poisson_data()
  pos <- dat[dat$y > 0, ]
  fit <- drmTMB(bf(y ~ x), family = truncated_poisson(), data = pos)
  expect_equal(fit$model$model_type, "truncated_poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_named(coef(fit), "mu")
  ref <- suppressWarnings(VGAM::vglm(y ~ x, VGAM::pospoisson(), data = pos))
  expect_equal(unname(coef(fit, "mu")), unname(VGAM::coef(ref)), tolerance = 1e-6)
  expect_equal(as.numeric(logLik(fit)), as.numeric(VGAM::logLik(ref)), tolerance = 1e-6)
  mu <- predict(fit, dpar = "mu")
  expect_equal(fitted(fit), mu / (1 - exp(-mu)), tolerance = 1e-12)
})

test_that("hurdle Poisson methods: predict, fitted, residuals, simulate, confint", {
  dat <- new_hurdle_poisson_data(n = 300, seed = 728)
  fit <- drmTMB(bf(y ~ x, hu ~ w), family = truncated_poisson(), data = dat)
  mu <- predict(fit, dpar = "mu")
  hu <- predict(fit, dpar = "hu")
  expect_equal(hu, stats::plogis(predict(fit, dpar = "hu", type = "link")), tolerance = 1e-12)
  q <- 1 - exp(-mu)
  m <- mu / q
  v <- m * (1 + mu - m)
  fitted_mean <- (1 - hu) * m
  hurdle_var <- (1 - hu) * v + hu * (1 - hu) * m^2
  expect_equal(fitted(fit), fitted_mean, tolerance = 1e-12)
  expect_equal(residuals(fit), fit$model$y - fitted_mean, tolerance = 1e-12)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - fitted_mean) / sqrt(hurdle_var),
    tolerance = 1e-12
  )
  expect_equal(sigma(fit), rep(1, nrow(dat)))
  newdata <- data.frame(x = c(-1, 0, 1), w = c(-1, 0, 1))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "hu"),
    stats::plogis(coef(fit, "hu")[[1]] + coef(fit, "hu")[[2]] * newdata$w),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    exp(coef(fit, "mu")[[1]] + coef(fit, "mu")[[2]] * newdata$x),
    tolerance = 1e-12
  )

  sims <- simulate(fit, nsim = 3, seed = 1)
  expect_equal(dim(sims), c(nrow(dat), 3L))
  s <- unlist(sims, use.names = FALSE)
  expect_true(all(s >= 0 & s %% 1 == 0))
  expect_true(any(s == 0) && any(s > 0))
  expect_equal(simulate(fit, nsim = 3, seed = 1), sims)
  # simulated zero share matches the model-implied hurdle probability
  big <- unlist(simulate(fit, nsim = 200, seed = 2), use.names = FALSE)
  expect_equal(mean(big == 0), mean(hu), tolerance = 0.02)

  ci <- confint(fit)
  expect_equal(
    ci$parm,
    c("fixef:mu:(Intercept)", "fixef:mu:x", "fixef:hu:(Intercept)", "fixef:hu:w")
  )
  expect_equal(ci$tmb_parameter, c("beta_mu", "beta_mu", "beta_zi", "beta_zi"))
  expect_true(all(is.finite(ci$lower) & is.finite(ci$upper) & ci$lower < ci$upper))
  expect_output(print(summary(fit)), "hu:w")
  printed <- paste(
    c(
      utils::capture.output(print(fit)),
      utils::capture.output(print(fit), type = "message")
    ),
    collapse = "\n"
  )
  expect_match(printed, "hurdle Poisson")
})

test_that("truncated Poisson distribution functions follow the hurdle algebra", {
  dat <- new_hurdle_poisson_data(n = 200, seed = 729)
  fit <- drmTMB(bf(y ~ x, hu ~ w), family = truncated_poisson(), data = dat)
  entry <- drm_family_dpq(fit)
  expect_equal(entry$status, "reference")
  params <- data.frame(
    mu = predict(fit, dpar = "mu"),
    hu = predict(fit, dpar = "hu")
  )
  total <- Reduce(`+`, lapply(0:60, function(k) entry$d(k, params)))
  expect_equal(total, rep(1, nrow(params)), tolerance = 1e-10)
  expect_equal(
    Reduce(`+`, lapply(0:5, function(k) entry$d(k, params))),
    entry$p(5, params),
    tolerance = 1e-12
  )
  expect_equal(entry$d(0, params), params$hu)
  for (u in c(0.05, 0.4, 0.9)) {
    qy <- entry$q(u, params)
    expect_true(all(entry$p(qy, params) >= u - 1e-12))
    expect_true(all(entry$p(pmax(qy - 1, 0), params) < u | qy == 0))
  }
})

test_that("truncated_poisson refuses unsupported inputs with guidance", {
  dat <- data.frame(
    y = c(0, 1, 2, 3, 1, 2),
    x = c(0, 1, 0, 1, 1, 0),
    id = factor(c(1, 1, 2, 2, 3, 3))
  )
  fam <- truncated_poisson()
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, hu ~ 1), family = fam, data = dat),
    "no .*sigma"
  )
  expect_error(
    drmTMB(bf(y ~ x, zi ~ 1, hu ~ 1), family = fam, data = dat),
    "only support"
  )
  expect_error(drmTMB(bf(y ~ x, hu = y ~ x), family = fam, data = dat), "one-sided")
  expect_error(drmTMB(bf(y ~ x, hu ~ 1, hu ~ x), family = fam, data = dat), "at most one")
  expect_error(drmTMB(bf(y ~ x, hu ~ 0), family = fam, data = dat), "zero-column")
  expect_error(drmTMB(bf(y ~ x + (1 | id), hu ~ 1), family = fam, data = dat))
  expect_error(drmTMB(bf(y ~ x, hu ~ x + (1 | id)), family = fam, data = dat))
  expect_error(
    drmTMB(bf(y ~ x, hu ~ 1), family = fam, data = transform(dat, y = c(0, -1, 2, 3, 1, 2))),
    "non-negative integer"
  )
  expect_error(
    drmTMB(bf(y ~ x, hu ~ 1), family = fam, data = transform(dat, y = c(0, 1.5, 2, 3, 1, 2))),
    "non-negative integer"
  )
  expect_error(
    drmTMB(bf(y ~ x, hu ~ 1), family = fam, data = transform(dat, y = 0)),
    "at least one positive"
  )
  # plain truncated model needs strictly positive counts and points to hu
  expect_error(
    drmTMB(bf(y ~ x), family = fam, data = dat),
    "positive integer"
  )
  # missing-response masking and mi() are not implemented: clear refusal
  expect_error(
    drmTMB(
      bf(y ~ x, hu ~ 1),
      family = fam,
      data = dat,
      missing = miss_control(response = "include")
    ),
    "not implemented"
  )
})

test_that("poisson() + hu stays refused and points to truncated_poisson()", {
  dat <- data.frame(y = c(0, 1, 2, 3, 1, 2), x = c(0, 1, 0, 1, 1, 0))
  expect_error(
    drmTMB(bf(y ~ x, hu ~ 1), family = poisson(), data = dat),
    "truncated_poisson"
  )
})

test_that("emmeans and the Julia bridge refuse truncated_poisson cleanly", {
  dat <- new_hurdle_poisson_data(n = 150, seed = 730)
  fit <- drmTMB(bf(y ~ x, hu ~ w), family = truncated_poisson(), data = dat)
  expect_error(drm_validate_emmeans_mu_target(fit, "mu"), "not implemented")
  expect_error(
    drmTMB(
      bf(y ~ x, hu ~ w),
      family = truncated_poisson(),
      data = dat,
      engine = "julia"
    )
  )
})

test_that("fitted_distribution() and profile() work on a hurdle Poisson fit", {
  dat <- new_hurdle_poisson_data(n = 250, seed = 731)
  fit <- drmTMB(bf(y ~ x, hu ~ w), family = truncated_poisson(), data = dat)
  fd <- fitted_distribution(fit)
  hu <- predict(fit, dpar = "hu")
  mu <- predict(fit, dpar = "mu")
  expect_equal(
    fd$p(2)[1:5],
    (hu + (1 - hu) * (stats::ppois(2, mu) - stats::dpois(0, mu)) /
      (1 - stats::dpois(0, mu)))[1:5],
    tolerance = 1e-12
  )
  pr <- profile(fit, parm = "fixef:hu:w")
  expect_s3_class(pr, "profile.drmTMB")
})
