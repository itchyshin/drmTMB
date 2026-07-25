test_that("biv_associate fits reviewed margins and preserves the staged contract", {
  set.seed(20260725)
  n <- 80L
  dat <- data.frame(x = stats::rnorm(n))
  z_continuous <- stats::rnorm(n)
  z_binary <- .30 * z_continuous + sqrt(1 - .30^2) * stats::rnorm(n)
  dat$continuous <- .2 + .5 * dat$x + z_continuous
  dat$binary <- as.integer(z_binary > stats::qnorm(.4))

  one_call <- biv_associate(
    bf(mu = continuous ~ x, sigma = ~ 1),
    bf(mu = binary ~ x),
    family = list(stats::gaussian(), stats::binomial()), data = dat
  )
  manual <- associate_pairs(
    drmTMB(bf(mu = continuous ~ x, sigma = ~ 1), stats::gaussian(), dat),
    drmTMB(bf(mu = binary ~ x), stats::binomial(), dat),
    kernel = latent_normal(), association = ~ 1
  )

  expect_s3_class(one_call, "drm_pair_association")
  expect_identical(one_call$stage, "two-stage frozen margins")
  expect_equal(one_call$eta, manual$eta, tolerance = 1e-7)
  expect_equal(one_call$logLik, manual$logLik, tolerance = 1e-7)
  expect_error(vcov(one_call), "unavailable")
})

test_that("biv_associate requires two marginal formulas and families", {
  dat <- data.frame(y = c(0, 1, 0, 1), x = 1:4)
  expect_error(
    biv_associate(y ~ x, bf(mu = y ~ x), list(binomial(), binomial()), dat),
    "must be created"
  )
  expect_error(
    biv_associate(bf(mu = y ~ x), bf(mu = y ~ x), binomial(), dat),
    "two-element list"
  )
})

test_that("biv_associate exposes the bounded Bernoulli x NB2 association slope", {
  set.seed(20260724)
  n <- 110L
  dat <- data.frame(habitat_score = seq(-1.2, 1.2, length.out = n))
  p <- stats::plogis(-0.3 + 0.25 * dat$habitat_score)
  mu <- exp(0.6 + 0.15 * dat$habitat_score)
  sigma <- rep(0.7, n)
  eta <- 0.999999 * tanh(-0.05 + 0.55 * dat$habitat_score)
  z_b <- stats::rnorm(n)
  z_c <- eta * z_b + sqrt(1 - eta^2) * stats::rnorm(n)
  dat$bred <- as.integer(z_b > stats::qnorm(p, lower.tail = FALSE))
  dat$offspring <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_c, mu, sigma)

  assoc <- biv_associate(
    bf(mu = bred ~ habitat_score),
    bf(mu = offspring ~ habitat_score, sigma = ~ 1),
    family = list(binomial(), nbinom2()), data = dat,
    association = ~ habitat_score
  )
  expect_true(assoc$status %in% c("interior", "near_boundary"))
  expect_named(association(assoc), c("term", "association_link", "status", "boundary"))
  expect_equal(association(assoc)$term, c("(Intercept)", "habitat_score"))
  expect_length(association(assoc, type = "fitted")$eta, n)
})
