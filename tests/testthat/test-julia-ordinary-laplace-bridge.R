# SHINICHI-1846-1117 (P6a option 3): engine = "julia" asks DRM.jl for its
# drmTMB-convention Laplace route (`marginal = "Laplace"`) on an ordinary mean
# `(1 | g)` with an `sd(g)` formula, so switching engines gives drmTMB's number.
# DRM.jl's own default (adaptive quadrature) is unchanged.
#
# Before the change the two engines differed on these cells by 0.007 to 0.05 in
# logLik (adaptive quadrature vs Laplace); after it they agree to ~1e-11.
# Tolerances are the ones the existing Julia-vs-TMB parity tests use
# (coefficients and logLik <= 1e-4).

ordinary_laplace_formula <- function(...) {
  drmTMB::bf(..., sd(g, coef = "(Intercept)") ~ 1)
}

test_that("bridge sends marginal = Laplace only on admitted ordinary (1 | g) + sd(g) shapes", {
  admitted <- drmTMB:::drm_julia_ordinary_laplace_admitted
  f <- function(...) drmTMB::bf(...)
  dat <- data.frame(y = 1, x = 0, z = 0, g = "a", h = "b")

  expect_true(admitted(ordinary_laplace_formula(y ~ x + (1 | g)), "poisson", "ML"))
  expect_true(admitted(
    ordinary_laplace_formula(y ~ x + (1 | g), sigma ~ x, nu ~ 1), "tweedie", "ML"
  ))
  expect_true(admitted(
    f(y ~ x + (1 | g), sd(g, coef = "(Intercept)") ~ z), "gamma", "ML"
  ))
  for (fam in drmTMB:::drm_julia_ordinary_laplace_families()) {
    expect_true(admitted(ordinary_laplace_formula(y ~ x + (1 | g)), fam, "ML"), info = fam)
  }

  # Routes with no Julia Laplace option, REML, offsets, other random shapes
  expect_false(admitted(ordinary_laplace_formula(y ~ x + (1 | g)), "beta_binomial", "ML"))
  expect_false(admitted(ordinary_laplace_formula(y ~ x + (1 | g)), "cumulative_logit", "ML"))
  expect_false(admitted(ordinary_laplace_formula(y ~ x + (1 | g)), "poisson", "REML"))
  expect_false(admitted(ordinary_laplace_formula(y ~ x + offset(z) + (1 | g)), "poisson", "ML"))
  expect_false(admitted(
    f(y ~ x + (1 | g) + (1 | h), sd(g, coef = "(Intercept)") ~ 1), "poisson", "ML"
  ))
  expect_false(admitted(
    f(y ~ x + (1 | g) + (0 + x | g), sd(g, coef = "(Intercept)") ~ 1), "poisson", "ML"
  ))
  expect_false(admitted(f(y ~ x + (1 | g)), "poisson", "ML"))
  expect_false(admitted(f(y ~ x), "poisson", "ML"))

  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = ordinary_laplace_formula(y ~ x + (1 | g)),
    family_type = "poisson", data = dat, env = environment()
  )
  expect_identical(payload$options$marginal, "Laplace")
  payload_reml <- drmTMB:::drm_julia_bridge_payload(
    formula = ordinary_laplace_formula(y ~ x + (1 | g)),
    family_type = "poisson", data = dat, env = environment(), method = "REML"
  )
  expect_null(payload_reml$options$marginal)
  payload_fe <- drmTMB:::drm_julia_bridge_payload(
    formula = drmTMB::bf(y ~ x), family_type = "poisson", data = dat,
    env = environment()
  )
  expect_null(payload_fe$options$marginal)
})

test_that("engine = 'julia' matches native drmTMB on ordinary (1 | g) + sd(g) cells (P6a, ML)", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()
  # drmTMB's own family lookup still calls the deprecated beta() internally.
  withr::local_options(lifecycle_verbosity = "quiet")

  set.seed(20261117)
  n <- 240L
  groups <- 12L
  g <- factor(rep(seq_len(groups), each = n / groups))
  x <- stats::rnorm(n)
  u <- stats::rnorm(groups, 0, 0.5)[g]
  p <- stats::plogis(0.2 + 0.3 * x + u)
  successes <- stats::rbinom(n, 8, stats::plogis(-0.2 + 0.5 * x + u))
  cells <- list(
    poisson = list(
      ordinary_laplace_formula(y ~ x + (1 | g)), stats::poisson(),
      data.frame(y = stats::rpois(n, exp(0.2 + 0.3 * x + u)), x, g)
    ),
    nbinom2 = list(
      ordinary_laplace_formula(y ~ x + (1 | g), sigma ~ 1), nbinom2(),
      data.frame(y = stats::rnbinom(n, size = 4, mu = exp(0.4 + 0.2 * x + u)), x, g)
    ),
    binomial = list(
      ordinary_laplace_formula(cbind(s, f) ~ x + (1 | g)), stats::binomial(),
      data.frame(s = successes, f = 8L - successes, x, g)
    ),
    beta = list(
      ordinary_laplace_formula(y ~ x + (1 | g), sigma ~ 1), beta_family(),
      data.frame(y = stats::rbeta(n, 12 * p, 12 * (1 - p)), x, g)
    ),
    gamma = list(
      ordinary_laplace_formula(y ~ x + (1 | g), sigma ~ 1), stats::Gamma(link = "log"),
      data.frame(y = stats::rgamma(n, shape = 3, rate = 3 / exp(0.4 + 0.2 * x + u)), x, g)
    ),
    tweedie = list(
      ordinary_laplace_formula(y ~ x + (1 | g), sigma ~ 1, nu ~ 1), tweedie(),
      data.frame(y = drmTMB:::rtweedie_compound(n, exp(0.3 + 0.3 * x + u), 0.5, 1.4), x, g)
    )
  )
  for (nm in names(cells)) {
    cell <- cells[[nm]]
    native <- drmTMB(cell[[1L]], family = cell[[2L]], data = cell[[3L]])
    julia <- drmTMB(cell[[1L]], family = cell[[2L]], data = cell[[3L]], engine = "julia")
    expect_equal(
      as.numeric(stats::logLik(julia)), as.numeric(stats::logLik(native)),
      tolerance = 1e-4, info = paste(nm, "logLik")
    )
    jl_mu <- stats::coef(julia, dpar = "mu")
    expect_equal(
      unname(jl_mu), unname(stats::coef(native, dpar = "mu")[names(jl_mu)]),
      tolerance = 1e-4, info = paste(nm, "mu coefficients")
    )
  }
})
