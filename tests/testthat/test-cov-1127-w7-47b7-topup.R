# Whole-package covr lane w7 (27 Nov): rank band 16–18 with open-PR substitutions.
# Nominal ranks 16–18 on main @ 2c76be050 are claimed elsewhere (#1944 phylo-utils,
# #1933 family-dpq, #1912/#1950 random-effect-targets). This file targets the next
# unclaimed high-mass modules: associate-pairs validators, anova boundary logic, and
# plot_corpairs ggplot mapping helpers.

w7_margin_fit_stub <- function(
  n = 6L,
  class = "drmTMB",
  estimator = "ML",
  reml = FALSE,
  keep = TRUE,
  weights = 1,
  has_known_v = FALSE,
  random_names = NULL,
  sdpars = list(),
  random_effects = list(),
  random_n_terms = 0L,
  phylo = FALSE,
  offset_nonzero = FALSE,
  response_policy = "drop"
) {
  dat <- data.frame(y = rnorm(n), x = seq_len(n))
  offs <- if (offset_nonzero) list(mu = rep(0.1, n)) else NULL
  structure(
    list(
      REML = reml,
      estimator = estimator,
      missing_data = list(response_policy = response_policy),
      model = list(
        keep = if (keep) rep(TRUE, n) else c(rep(TRUE, n - 1L), FALSE),
        random = list(structure(list(n_terms = random_n_terms), class = "drm_random")),
        random_names = random_names,
        weights = rep(weights, n),
        has_known_v = has_known_v,
        offset = offs,
        structured = list(phylo_mu = list(has = phylo)),
        variables = names(dat)
      ),
      data = dat,
      nobs = if (keep) n else n - 1L,
      random_effects = random_effects,
      sdpars = sdpars
    ),
    class = class
  )
}

test_that("drm_pair_validate_kernel() requires latent_normal()", {
  expect_error(
    drmTMB:::drm_pair_validate_kernel(structure(list(name = "other"), class = "drm_pair_kernel")),
    "Arc 6 requires"
  )
  expect_error(
    drmTMB:::drm_pair_validate_kernel(list(name = "latent_normal")),
    "Arc 6 requires"
  )
  expect_invisible(
    drmTMB:::drm_pair_validate_kernel(latent_normal())
  )
})

test_that("drm_pair_descriptor() lists roles and rejects unknown pair classes", {
  desc <- drmTMB:::drm_pair_descriptor("gaussian_bernoulli")
  expect_s3_class(desc, "drm_pair_descriptor")
  expect_equal(desc$roles, c("gaussian", "bernoulli"))
  expect_error(
    drmTMB:::drm_pair_descriptor("not_a_pair"),
    "Unsupported frozen-margin pair descriptor"
  )
})

test_that("drm_pair_validate_fit() enforces ML complete-pair margin contracts", {
  good <- w7_margin_fit_stub()
  expect_invisible(drmTMB:::drm_pair_validate_fit(good, "fit_1"))

  expect_error(
    drmTMB:::drm_pair_validate_fit(structure(list(), class = "lm"), "fit_1"),
    "must be a fitted"
  )
  reml <- w7_margin_fit_stub(estimator = "REML")
  expect_error(
    drmTMB:::drm_pair_validate_fit(reml, "fit_1"),
    "fixed-effect ML"
  )

  dropped <- w7_margin_fit_stub(keep = FALSE)
  expect_error(
    drmTMB:::drm_pair_validate_fit(dropped, "fit_1"),
    "without dropped rows"
  )

  re <- w7_margin_fit_stub(random_names = c("g"))
  expect_error(
    drmTMB:::drm_pair_validate_fit(re, "fit_1"),
    "random or structured"
  )

  weighted <- w7_margin_fit_stub(weights = 2)
  expect_error(
    drmTMB:::drm_pair_validate_fit(weighted, "fit_1"),
    "unit weights"
  )

  offset_fit <- w7_margin_fit_stub(offset_nonzero = TRUE)
  expect_error(
    drmTMB:::drm_pair_validate_fit(offset_fit, "fit_1"),
    "offset"
  )
})

test_that("drm_aicc_from_loglik() aborts without df/nobs and matches the AICc formula", {
  expect_error(
    drmTMB:::drm_aicc_from_loglik(-10, k = NULL, n = 20),
    "reports `df` and `nobs`"
  )
  expect_identical(drmTMB:::drm_aicc_from_loglik(-1, k = 3, n = 3), Inf)
  expect_equal(drmTMB:::drm_aicc_from_loglik(-5, k = 2, n = 10), 10 + 4 + 2 * 2 * 3 / 7)
})

test_that("drm_anova_vc_labels() tags SD blocks by distributional parameter", {
  obj <- list(
    sdpars = list(mu = c("(1 | g)" = 1, x = 0.5), sigma = c("(1 | g)" = 0.2)),
    corpars = list(rho12 = c("(Intercept)" = 0.1))
  )
  sd <- drmTMB:::drm_anova_vc_labels(obj, "sdpars")
  expect_equal(sd, c("mu:(1 | g)", "mu:x", "sigma:(1 | g)"))
  cor <- drmTMB:::drm_anova_vc_labels(obj, "corpars")
  expect_equal(cor, "rho12:(Intercept)")
})

test_that("drm_anova_boundary() detects chi-bar eligibility and extra-parameter mismatches", {
  reduced <- list(
    sdpars = list(mu = c("(1 | g)" = 1)),
    corpars = list(),
    df = 4
  )
  full_one_sd <- list(
    sdpars = list(mu = c("(1 | g)" = 1, x = 0.2)),
    corpars = list(),
    df = 5
  )
  one <- drmTMB:::drm_anova_boundary(reduced, full_one_sd)
  expect_true(one$applies)
  expect_equal(one$q, 1L)
  expect_equal(one$added_sd, "mu:x")

  full_two_sd <- list(
    sdpars = list(mu = c("(1 | g)" = 1, x = 0.2, z = 0.1)),
    corpars = list(),
    df = 6
  )
  two <- drmTMB:::drm_anova_boundary(reduced, full_two_sd)
  expect_true(two$applies)
  expect_equal(two$q, 2L)

  corr_change <- list(
    sdpars = list(mu = c("(1 | g)" = 1)),
    corpars = list(rho12 = c("(Intercept)" = 0)),
    df = 5
  )
  mixed <- drmTMB:::drm_anova_boundary(reduced, corr_change)
  expect_false(mixed$applies)
})

test_that("plot_corpairs mapping helpers build the expected ggplot aesthetics", {
  testthat::skip_if_not_installed("ggplot2")
  aes_no_colour <- drmTMB:::plot_corpairs_mapping(FALSE)
  expect_s3_class(aes_no_colour, "uneval")
  expect_equal(names(aes_no_colour), c("x", "y"))

  aes_colour <- drmTMB:::plot_corpairs_mapping(TRUE)
  expect_equal(names(aes_colour), c("x", "y", "colour"))

  interval <- drmTMB:::plot_corpairs_interval_mapping()
  expect_setequal(
    names(interval),
    c("x", "xend", "y", "yend")
  )

  eye <- drmTMB:::plot_corpairs_eye_mapping(TRUE)
  expect_equal(
    names(eye),
    c("x", "ymin", "ymax", "group", "fill")
  )
  expect_equal(names(drmTMB:::plot_corpairs_eye_mapping(FALSE)), c("x", "ymin", "ymax", "group"))
})