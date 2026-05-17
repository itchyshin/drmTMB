emmeans_methods_control <- function(se = TRUE, keep_model_frame = TRUE) {
  drm_control(
    se = se,
    keep_model_frame = keep_model_frame,
    optimizer = list(eval.max = 120L, iter.max = 120L)
  )
}

emmeans_methods_data <- function(n = 60L) {
  x <- rep(c(-0.5, 0.5), length.out = n)
  habitat <- factor(rep(c("reef", "kelp", "sand"), length.out = n))
  data.frame(
    y = 0.2 + 0.4 * x + 0.3 * (habitat == "kelp") + stats::rnorm(n, sd = 0.1),
    x = x,
    habitat = habitat,
    id = factor(rep(seq_len(12L), length.out = n))
  )
}

test_that("emmeans method matches fixed-effect mu predictions", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260537)
  dat <- emmeans_methods_data()
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat, at = list(x = 0))
  out <- summary(emm)
  grid <- data.frame(
    x = 0,
    habitat = factor(out$habitat, levels = levels(dat$habitat))
  )

  expect_equal(
    out$emmean,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "link")),
    tolerance = 1e-10
  )
  expect_true(all(is.finite(out$SE)))
  expect_equal(out$df, rep(Inf, nrow(out)))
})

test_that("emmeans response scale follows the fitted mu inverse link", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260538)
  dat <- emmeans_methods_data(n = 75L)
  lambda <- exp(0.2 + 0.4 * dat$x + 0.3 * (dat$habitat == "kelp"))
  dat$count <- stats::rpois(nrow(dat), lambda = lambda)
  fit <- drmTMB(
    bf(count ~ x + habitat),
    family = stats::poisson(link = "log"),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat, at = list(x = 0))
  link <- summary(emm)
  response <- summary(emm, type = "response")
  grid <- data.frame(
    x = 0,
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )
  eta <- unname(predict(fit, newdata = grid, dpar = "mu", type = "link"))
  mu <- unname(predict(fit, newdata = grid, dpar = "mu", type = "response"))

  expect_equal(link$emmean, eta, tolerance = 1e-10)
  expect_equal(response$response, mu, tolerance = 1e-10)
})

test_that("emmeans response scale handles logit mu families", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260540)
  dat <- emmeans_methods_data(n = 90L)
  mu <- stats::plogis(-0.2 + 0.5 * dat$x + 0.4 * (dat$habitat == "kelp"))
  sigma <- 0.35
  dat$prop <- stats::rbeta(
    nrow(dat),
    shape1 = mu / sigma^2,
    shape2 = (1 - mu) / sigma^2
  )
  fit <- drmTMB(
    bf(prop ~ x + habitat, sigma ~ 1),
    family = beta(),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat, at = list(x = 0))
  link <- summary(emm)
  response <- summary(emm, type = "response")
  grid <- data.frame(
    x = 0,
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )
  eta <- unname(predict(fit, newdata = grid, dpar = "mu", type = "link"))
  fitted_mu <- unname(
    predict(fit, newdata = grid, dpar = "mu", type = "response")
  )

  expect_equal(link$emmean, eta, tolerance = 1e-10)
  expect_equal(response$response, fitted_mu, tolerance = 1e-10)
})

test_that("emmeans method rejects unsupported drmTMB paths", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260539)
  dat <- emmeans_methods_data()
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ x),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  expect_error(
    emmeans::emmeans(fit, ~habitat, at = list(x = 0), dpar = "sigma"),
    "dpar = \"mu\""
  )

  no_se_fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = FALSE)
  )
  expect_error(
    emmeans::emmeans(no_se_fit, ~habitat, at = list(x = 0)),
    "Refit with"
  )

  no_frame_fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(keep_model_frame = FALSE)
  )
  expect_error(
    emmeans::emmeans(no_frame_fit, ~habitat, at = list(x = 0)),
    "keep_model_frame = TRUE"
  )

  random_fit <- drmTMB(
    bf(y ~ x + habitat + (1 | id), sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )
  expect_error(
    emmeans::emmeans(random_fit, ~habitat, at = list(x = 0)),
    "mu random effects"
  )
})
