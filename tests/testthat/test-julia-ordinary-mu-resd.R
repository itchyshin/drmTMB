# #1551: Poisson / Gamma ordinary (1 | g) abort after the Julia fit because
# coef_labels has no `resd` entry (Julia names: ["resd_g"]). Red-proof: these
# assertions fail on cursor/julia-setup-segfault-4acf (b0cf1d8a) and pass
# after the label + Laplace payload change. No Julia process is started.

ordinary_ri_data <- function(family = "poisson", seed = 20261016L) {
  set.seed(seed)
  n <- 40L
  g <- gl(8L, 5L)
  x <- stats::rnorm(n)
  if (identical(family, "poisson")) {
    y <- stats::rpois(n, lambda = exp(0.2 + 0.3 * x))
  } else {
    y <- stats::rgamma(n, shape = 4, scale = exp(0.2 + 0.3 * x) / 4)
  }
  data.frame(y = y, x = x, g = g)
}

test_that("#1551 Poisson ordinary (1 | g) sends a resd label for resd_g", {
  d <- ordinary_ri_data("poisson")
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = drmTMB::bf(y ~ x + (1 | g)),
    data = d,
    env = environment(),
    family_type = "poisson"
  )
  expect_identical(labels$resd, "g")
  expect_identical(labels$mu, c("(Intercept)", "x"))
})

test_that("#1551 Gamma ordinary (1 | g) sends a resd label for resd_g", {
  d <- ordinary_ri_data("gamma")
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = drmTMB::bf(y ~ x + (1 | g), sigma ~ 1),
    data = d,
    env = environment(),
    family_type = "gamma"
  )
  expect_identical(labels$resd, "g")
  expect_identical(labels$mu, c("(Intercept)", "x"))
  expect_identical(labels$sigma, "(Intercept)")
})

test_that("#1551 Poisson/Gamma ordinary (1 | g) request marginal Laplace", {
  # Payload assembly uses `%||%` (#1550 on R < 4.4). The helper is the
  # contract the payload reads; labels are checked above without that path.
  form_p <- drmTMB::bf(y ~ x + (1 | g))
  form_g <- drmTMB::bf(y ~ x + (1 | g), sigma ~ 1)
  expect_true(drmTMB:::drm_julia_poisson_gamma_ordinary_ri(form_p, "poisson"))
  expect_true(drmTMB:::drm_julia_poisson_gamma_ordinary_ri(form_g, "gamma"))
  expect_identical(drmTMB:::drm_julia_ordinary_mu_ri_group(form_p), "g")
  expect_identical(drmTMB:::drm_julia_ordinary_mu_ri_group(form_g), "g")
})

test_that("#1551 sibling: Gaussian ordinary (1 | g) still has no resd label", {
  # Gaussian (1 | g) uses the conditional-components route. Sending resd
  # would be an unknown dpar on that path (test-coefficient-labels.R).
  set.seed(1L)
  d <- data.frame(y = rnorm(30), x = rnorm(30), g = gl(5, 6))
  form <- drmTMB::bf(y ~ x + (1 | g), sigma ~ 1)
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = form,
    data = d,
    env = environment(),
    family_type = "gaussian"
  )
  expect_null(labels$resd)
  expect_false(drmTMB:::drm_julia_poisson_gamma_ordinary_ri(form, "gaussian"))
})

test_that("#1551 sibling: nbinom2 ordinary (1 | g) is still unlabelled", {
  # Same missing-resd abort on t6. This lane only labels Poisson/Gamma so
  # nbinom2/beta with sigma ~ x cannot silently take AGHQ (DRModels.jl#943).
  set.seed(2L)
  d <- data.frame(y = stats::rnbinom(40, size = 4, mu = 3), x = rnorm(40), g = gl(8, 5))
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = drmTMB::bf(y ~ x + (1 | g), sigma ~ 1),
    data = d,
    env = environment(),
    family_type = "nbinom2"
  )
  expect_null(labels$resd)
})
