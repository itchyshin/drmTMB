# #1775: for a non-Gaussian engine = "julia" fit with an ordinary random-effect
# bar in a mean dpar, the bridge slot is the population-level value (random
# effects at zero). fitted() and residuals() used to return it silently, which
# differs from engine = "tmb" by whole units. They now refuse with the reason
# predict() gives. Static: hand-built bridge objects, no Julia.

population_fit <- function(formula, model_type, family) {
  dat <- data.frame(
    y = c(0, 2, 1, 3), x = c(-1, 0, 1, 2), z = c(0.2, -0.1, 0.4, 0),
    g = c("b", "a", "b", "a")
  )
  structure(
    list(
      formula = formula,
      family = family,
      model = list(model_type = model_type),
      data = dat,
      coefficients = list(mu = c("(Intercept)" = 0.5, x = 0.3)),
      fitted = c(9, 8, 7, 6),
      residuals = c(1, 2, 3, 4),
      engine = "julia"
    ),
    class = "drmTMB_julia"
  )
}

test_that("non-Gaussian ordinary random effects refuse population fitted()/residuals() (#1775)", {
  cases <- list(
    list(bf(y ~ x + (1 | g), sd(g) ~ 1), "poisson", stats::poisson()),
    list(bf(y ~ x + (0 + x | g), sd(g) ~ 1), "nbinom2", nbinom2()),
    list(bf(y ~ x + (1 | g), sd(g) ~ 1), "binomial", stats::binomial()),
    list(bf(y ~ x + (1 | g), sigma ~ 1, sd(g) ~ 1 + z), "beta", beta_family())
  )
  for (cs in cases) {
    fit <- population_fit(cs[[1]], cs[[2]], cs[[3]])
    expect_error(stats::fitted(fit), "did not retain its random-effect payload", fixed = TRUE)
    expect_error(stats::residuals(fit), "did not retain its random-effect payload", fixed = TRUE)
    expect_error(stats::fitted(fit), "engine = \"tmb\"", fixed = TRUE)
  }
})

test_that("a random effect only in zi is refused too (#1775)", {
  fit <- population_fit(bf(y ~ x, zi ~ z + (1 | g), sd(g) ~ 1), "poisson", stats::poisson())
  expect_error(stats::fitted(fit), "did not retain its random-effect payload", fixed = TRUE)
})

test_that("fixed-effect and Gaussian bridge fits keep the slot (#1775 scope)", {
  fe <- population_fit(bf(y ~ x), "poisson", stats::poisson())
  expect_identical(stats::fitted(fe), c(9, 8, 7, 6))
  expect_identical(stats::residuals(fe), c(1, 2, 3, 4))
  gauss <- population_fit(bf(y ~ x + (1 | g), sigma ~ 1), "gaussian", stats::gaussian())
  expect_identical(stats::fitted(gauss), c(9, 8, 7, 6))
})

test_that("live ZIP (1 | g) fit: fitted() refuses instead of the fixed-effects-only value (#1775)", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(1)
  ng <- 40L
  m <- 10L
  n <- ng * m
  g <- factor(rep(seq_len(ng), each = m))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u <- stats::rnorm(ng, 0, 0.5)[g]
  zero <- stats::runif(n) < stats::plogis(-0.8 + 0.5 * z)
  d <- data.frame(x, z, g, y = ifelse(zero, 0, stats::rpois(n, exp(0.6 + 0.4 * x + u))))
  fit <- drmTMB(bf(y ~ x + (1 | g), zi ~ z, sd(g) ~ 1),
                family = stats::poisson(), data = d, engine = "julia")
  expect_error(stats::fitted(fit), "did not retain its random-effect payload", fixed = TRUE)
  expect_error(stats::residuals(fit), "did not retain its random-effect payload", fixed = TRUE)
  # Coefficients and logLik stay available.
  expect_true(is.finite(as.numeric(stats::logLik(fit))))
  expect_named(coef(fit, dpar = "mu"), c("(Intercept)", "x"))
})
