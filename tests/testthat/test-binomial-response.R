new_binomial_bernoulli_data <- function(n = 260, seed = 2026061601) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  eta <- -0.35 + 0.85 * dat$x - 0.40 * dat$z
  dat$y <- stats::rbinom(n, size = 1, prob = stats::plogis(eta))
  dat
}

new_binomial_count_data <- function(n = 220, seed = 2026061602) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    habitat = factor(sample(c("forest", "edge", "field"), n, replace = TRUE)),
    exposure = stats::runif(n, min = 0.75, max = 1.40),
    trials = sample(4:18, n, replace = TRUE)
  )
  eta <- -0.10 +
    0.70 * dat$x -
    0.25 * (dat$habitat == "field") +
    log(dat$exposure)
  dat$success <- stats::rbinom(
    n,
    size = dat$trials,
    prob = stats::plogis(eta)
  )
  dat$failure <- dat$trials - dat$success
  dat
}

expect_binomial_glm_parity <- function(fit, glm_fit, tolerance = 1e-5) {
  expect_equal(coef(fit, "mu"), stats::coef(glm_fit), tolerance = tolerance)
  expect_equal(
    predict(fit, type = "link"),
    unname(stats::predict(glm_fit, type = "link")),
    tolerance = tolerance
  )
  expect_equal(
    fitted(fit),
    unname(stats::fitted(glm_fit)),
    tolerance = tolerance
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(glm_fit)),
    tolerance = tolerance
  )
  expect_equal(stats::AIC(fit), stats::AIC(glm_fit), tolerance = tolerance)
  expect_equal(stats::BIC(fit), stats::BIC(glm_fit), tolerance = tolerance)
}

test_that("drmTMB fits fixed-effect Bernoulli logit models", {
  dat <- new_binomial_bernoulli_data()

  fit <- drmTMB(
    bf(y ~ x + z),
    family = stats::binomial(),
    data = dat
  )
  glm_fit <- stats::glm(y ~ x + z, family = stats::binomial(), data = dat)

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "binomial")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$denominator$encoding, "0/1")
  expect_equal(fit$model$trials, rep(1, nrow(dat)))
  expect_binomial_glm_parity(fit, glm_fit)

  expect_named(coef(fit), "mu")
  expect_named(coef(fit, "mu"), names(stats::coef(glm_fit)))
  expect_equal(sigma(fit), rep(1, nobs(fit)))

  ci <- confint(fit)
  expect_equal(ci$tmb_parameter, rep("beta_mu", length(coef(fit, "mu"))))
  expect_true(all(ci$conf.status == "wald"))
})

test_that("drmTMB fits two-column binomial counts with offsets", {
  dat <- new_binomial_count_data()

  fit <- drmTMB(
    bf(cbind(success, failure) ~ x + habitat + offset(log(exposure))),
    family = stats::binomial(link = "logit"),
    data = dat
  )
  glm_fit <- stats::glm(
    cbind(success, failure) ~ x + habitat + offset(log(exposure)),
    family = stats::binomial(link = "logit"),
    data = dat
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "binomial")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$denominator$encoding, "cbind(successes, failures)")
  expect_equal(fit$model$trials, dat$trials)
  expect_binomial_glm_parity(fit, glm_fit)

  ll_independent <- sum(stats::dbinom(
    fit$model$y,
    size = fit$model$trials,
    prob = fitted(fit),
    log = TRUE
  ))
  expect_equal(as.numeric(stats::logLik(fit)), ll_independent, tolerance = 1e-6)
})

test_that("binomial method surface returns event-probability quantities", {
  dat <- new_binomial_count_data(n = 160, seed = 2026061603)
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x + habitat),
    family = stats::binomial(),
    data = dat
  )

  expect_equal(predict(fit, dpar = "mu"), fitted(fit), tolerance = 1e-12)
  expect_true(all(fitted(fit) > 0 & fitted(fit) < 1))
  expect_equal(length(residuals(fit)), nobs(fit))
  expect_equal(length(residuals(fit, type = "pearson")), nobs(fit))
  expect_true(all(is.finite(residuals(fit, type = "pearson"))))
  expect_equal(
    rownames(vcov(fit)),
    paste0("mu:", names(coef(fit, "mu")))
  )
  expect_true(all(is.finite(diag(vcov(fit)))))
  expect_s3_class(summary(fit), "summary.drmTMB")

  sims <- simulate(fit, nsim = 3, seed = 2026061604)
  expect_s3_class(sims, "data.frame")
  expect_equal(ncol(sims), 3L)
  expect_true(all(as.matrix(sims) >= 0))
  expect_true(all(as.matrix(sims) <= fit$model$trials))
  expect_equal(
    simulate(fit, nsim = 2, seed = 2026061605),
    simulate(fit, nsim = 2, seed = 2026061605)
  )
})

test_that("binomial rejects unsupported response encodings and routes", {
  dat <- new_binomial_bernoulli_data(n = 80, seed = 2026061606)
  dat$prop <- c(0.2, rep(0:1, length.out = nrow(dat) - 1L))
  dat$trials <- sample(2:8, nrow(dat), replace = TRUE)
  dat$y_factor <- factor(dat$y, levels = c(0, 1))
  dat$success <- stats::rbinom(nrow(dat), size = dat$trials, prob = 0.45)
  dat$failure <- dat$trials - dat$success
  dat$bad_failure <- dat$failure
  dat$bad_failure[[1L]] <- -1

  expect_error(
    drmTMB(
      bf(prop ~ x),
      family = stats::binomial(),
      data = dat,
      weights = trials
    ),
    "Proportion responses with"
  )
  expect_error(
    drmTMB(bf(y_factor ~ x), family = stats::binomial(), data = dat),
    "not a factor"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, bad_failure) ~ x),
      family = stats::binomial(),
      data = dat
    ),
    "finite non-negative integers"
  )
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::binomial(link = "probit"),
      data = dat
    ),
    "link = \"logit\""
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = stats::binomial(), data = dat),
    "only the.*mu"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id)),
      family = stats::binomial(),
      data = transform(dat, id = gl(8, 10))
    ),
    "Random effects"
  )
  expect_error(
    drmTMB(bf(mvbind(y, y) ~ x), family = stats::binomial(), data = dat),
    "mvbind"
  )
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::binomial(),
      data = dat,
      engine = "julia"
    ),
    "Julia|julia|bridge|phylo|Gaussian"
  )
})
