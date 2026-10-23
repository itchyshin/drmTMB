# Prediction-scale contracts for a Julia-bridge object.  These fixtures contain
# only post-marshalling R payloads, so they do not need JuliaCall or a fitted
# engine.

julia_prediction_scale_fixture <- function(
  formula,
  model_type = "gaussian",
  data,
  coefficients,
  dpars = NULL,
  fitted = NULL
) {
  structure(
    list(
      formula = formula,
      family = switch(
        model_type,
        gaussian = stats::gaussian(),
        gamma = stats::Gamma(link = "log"),
        stats::gaussian()
      ),
      model = list(model_type = model_type),
      data = data,
      coefficients = coefficients,
      dpars = dpars,
      fitted = fitted,
      engine = "julia"
    ),
    class = "drmTMB_julia"
  )
}

test_that("stored fixed-effect dpars use their canonical link scale", {
  dat <- data.frame(y = c(1, 2), x = c(-1, 1))
  eta <- c(-0.4, 0.7)
  fit <- julia_prediction_scale_fixture(
    drmTMB::bf(y ~ x, sigma ~ 1), "gamma", dat,
    coefficients = list(mu = c("(Intercept)" = 0.15, x = 0.55),
                        sigma = c("(Intercept)" = -0.2)),
    dpars = list(mu = exp(eta), sigma = rep(exp(-0.2), 2L)),
    # A legacy response slot must not override the per-dpar bridge payload.
    fitted = rep(99, 2L)
  )

  expect_equal(predict(fit, dpar = "mu", type = "response"), exp(eta))
  expect_equal(predict(fit, dpar = "mu", type = "link"), eta)
  expect_equal(predict(fit, dpar = "sigma", type = "link"), rep(-0.2, 2L))
})

test_that("Gaussian sigma supports fixed-effect newdata predictions", {
  dat <- data.frame(y = c(-1, 0, 1), x = c(-1, 0, 1))
  fit <- julia_prediction_scale_fixture(
    drmTMB::bf(y ~ x, sigma ~ x), "gaussian", dat,
    coefficients = list(mu = c("(Intercept)" = 0.3, x = 0.4),
                        sigma = c("(Intercept)" = -0.2, x = 0.5)),
    dpars = list(mu = c(-0.1, 0.3, 0.7), sigma = exp(c(-0.7, -0.2, 0.3)))
  )
  nd <- data.frame(x = c(-2, 0, 2))
  expected_link <- -0.2 + 0.5 * nd$x

  expect_equal(predict(fit, newdata = nd, dpar = "sigma", type = "link"), expected_link)
  expect_equal(predict(fit, newdata = nd, dpar = "sigma", type = "response"), exp(expected_link))
  expect_error(
    predict(fit, newdata = data.frame(x = NA_real_), dpar = "sigma"),
    "finite, non-missing"
  )
})

test_that("omitted default atom formula is admitted only for intercept-only coefficients", {
  dat <- data.frame(y = c(-1, 0, 1), x = c(-1, 0, 1))
  fit <- julia_prediction_scale_fixture(
    drmTMB::bf(y ~ x), "gaussian", dat,
    coefficients = list(mu = c("(Intercept)" = 0.3, x = 0.4),
                        sigma = c("(Intercept)" = -0.6)),
    dpars = list(mu = c(-0.1, 0.3, 0.7), sigma = rep(exp(-0.6), 3L))
  )

  expect_equal(
    predict(fit, newdata = data.frame(x = c(4, -2)), dpar = "sigma", type = "link"),
    rep(-0.6, 2L)
  )
  fit$coefficients$sigma <- c("(Intercept)" = -0.6, x = 0.1)
  expect_error(
    predict(fit, newdata = data.frame(x = 1), dpar = "sigma"),
    "formula entry|intercept"
  )
})

test_that("newdata preserves factor and no-intercept scale designs", {
  dat <- data.frame(
    y = c(-1, 0, 1, 2),
    x = c(-2, -1, 1, 2),
    g = factor(c("a", "b", "a", "b"), levels = c("a", "b"))
  )
  fit <- julia_prediction_scale_fixture(
    drmTMB::bf(y ~ 0 + x, sigma ~ 0 + g), "gaussian", dat,
    coefficients = list(mu = c(x = 0.5), sigma = c(ga = -0.7, gb = 0.2)),
    dpars = list(mu = 0.5 * dat$x, sigma = exp(ifelse(dat$g == "a", -0.7, 0.2)))
  )
  nd <- data.frame(x = c(1, -1), g = factor(c("b", "a"), levels = c("a", "b")))

  expect_equal(predict(fit, newdata = nd, dpar = "mu", type = "link"), c(0.5, -0.5))
  expect_equal(predict(fit, newdata = nd, dpar = "sigma", type = "link"), c(0.2, -0.7))
})

test_that("stored structured predictions refuse an absent conditional payload", {
  dat <- data.frame(y = c(1, 2), x = c(-1, 1))
  formula <- list(entries = list(
    list(dpar = "mu", rhs = quote(0 + x), structured = list(list(type = "phylo"))),
    list(dpar = "sigma", rhs = quote(1), structured = list())
  ))
  fit <- julia_prediction_scale_fixture(
    formula, "gaussian", dat,
    coefficients = list(mu = c(x = 0.5), sigma = c("(Intercept)" = -0.2)),
    dpars = list(mu = c(-0.5, 0.5), sigma = rep(exp(-0.2), 2L))
  )

  expect_error(predict(fit, dpar = "mu", type = "response"), "conditional.*retain")
  expect_error(predict(fit, dpar = "mu", type = "link"), "conditional.*retain")
})

test_that("ordinary random effects are stripped for newdata and refused when stored", {
  dat <- data.frame(
    y = c(1, 2, 3, 4), x = c(-2, -1, 1, 2),
    g = factor(c("a", "a", "b", "b"))
  )
  formula <- list(entries = list(
    list(dpar = "mu", rhs = quote(0 + x + (1 | g)), structured = list()),
    list(dpar = "sigma", rhs = quote(1), structured = list())
  ))
  fit <- julia_prediction_scale_fixture(
    formula, "gaussian", dat,
    coefficients = list(mu = c(x = 0.5), sigma = c("(Intercept)" = -0.2))
  )

  expect_equal(
    predict(fit, newdata = data.frame(x = c(-1, 3)), dpar = "mu", type = "link"),
    c(-0.5, 1.5)
  )
  expect_error(predict(fit, dpar = "mu"), "conditional.*retain")
})

test_that("known sampling covariance markers are not fixed predictors", {
  dat <- data.frame(
    y = c(-1, 0, 1), x = c(-1, 0, 1), z = c(0, 1, 2),
    v = c(0.1, 0.2, 0.4)
  )
  fit <- julia_prediction_scale_fixture(
    drmTMB::bf(y ~ x + meta_V(V = v), sigma ~ z), "gaussian", dat,
    coefficients = list(mu = c("(Intercept)" = 0.2, x = 0.5),
                        sigma = c("(Intercept)" = -0.4, z = 0.3))
  )
  nd <- data.frame(x = c(-2, 3), z = c(1, 4))

  expect_equal(predict(fit, dpar = "mu", type = "link"), c(-0.3, 0.2, 0.7))
  expect_equal(predict(fit, newdata = nd, dpar = "mu", type = "link"), c(-0.8, 1.7))
  expect_equal(predict(fit, dpar = "sigma", type = "response"), exp(-0.4 + 0.3 * dat$z))
  expect_equal(predict(fit, newdata = nd, dpar = "sigma", type = "response"), exp(-0.4 + 0.3 * nd$z))

  # `meta_known_V()` remains the deprecated compatibility alias. It must be
  # stripped through the shared parser predicate too, including fresh data
  # without a known-variance column.
  fit$formula <- suppressWarnings(
    drmTMB::bf(y ~ x + meta_known_V(V = v), sigma ~ z)
  )
  expect_equal(predict(fit, newdata = nd, dpar = "mu", type = "link"), c(-0.8, 1.7))
})

test_that("stored lognormal mu and guarded rho use coefficient-scale contracts", {
  dat <- data.frame(y = c(1, 2), x = c(-1, 1))
  lognormal_fit <- julia_prediction_scale_fixture(
    drmTMB::bf(y ~ x, sigma ~ 1), "lognormal", dat,
    coefficients = list(mu = c("(Intercept)" = 0.2, x = 0.4),
                        sigma = c("(Intercept)" = -0.3)),
    # DRM.jl's raw lognormal mu payload is exp(eta); native dpar = mu is eta.
    dpars = list(mu = exp(c(-0.2, 0.6)), sigma = rep(exp(-0.3), 2L))
  )
  expect_equal(predict(lognormal_fit, dpar = "mu", type = "link"), c(-0.2, 0.6))
  expect_equal(predict(lognormal_fit, dpar = "mu", type = "response"), c(-0.2, 0.6))

  rho_formula <- list(entries = list(
    list(dpar = "rho12", rhs = quote(1), structured = list())
  ))
  rho_fit <- julia_prediction_scale_fixture(
    rho_formula, "biv_gaussian", dat,
    coefficients = list(rho12 = c("(Intercept)" = 0.5)),
    dpars = list(rho12 = tanh(0.5))
  )
  expect_equal(predict(rho_fit, dpar = "rho12", type = "link"), rep(0.5, 2L))
  expect_equal(
    predict(rho_fit, dpar = "rho12", type = "response"),
    rep(0.999999 * tanh(0.5), 2L)
  )
})

test_that("legacy objects infer only verified family metadata and refuse offsets", {
  dat <- data.frame(y = c(1, 2), x = c(-1, 1))
  legacy <- julia_prediction_scale_fixture(
    drmTMB::bf(y ~ x, sigma ~ 1), "gaussian", dat,
    coefficients = list(mu = c("(Intercept)" = 0.2, x = 0.5),
                        sigma = c("(Intercept)" = -0.4))
  )
  legacy$model <- NULL
  expect_equal(predict(legacy, dpar = "mu", type = "link"), c(-0.3, 0.7))

  legacy$formula <- drmTMB::bf(y ~ x + offset(x), sigma ~ 1)
  expect_error(predict(legacy, dpar = "mu"), "offset")
})

test_that("unsupported non-dpar coefficient blocks refuse prediction", {
  dat <- data.frame(y = c(1, 2), x = c(-1, 1))
  fit <- julia_prediction_scale_fixture(
    drmTMB::bf(y ~ x, sigma ~ 1), "gamma", dat,
    coefficients = list(mu = c("(Intercept)" = 0.2, x = 0.5),
                        sigma = c("(Intercept)" = -0.2)),
    dpars = NULL,
    fitted = c(1, 2)
  )
  fit$coefficients$sd_group <- c("(Intercept)" = 0.1)

  expect_error(predict(fit, dpar = "sd_group", type = "link"), "canonical prediction link")
})
