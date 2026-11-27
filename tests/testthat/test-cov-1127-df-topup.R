# Coverage top-up for R/[d-f]*.R (Cursor coverage 27 Nov 2026).
# Exercises user-facing validation and workflow branches with modest runtime.

test_that("drm_priors() requires drm_fixed_prior or drm_sd_prior entries", {
  expect_error(drm_priors(), "one or more")
  expect_error(drm_priors(list(not_a_prior = 1)), "one or more")
})

test_that("fixed prior constructors validate dpar, intercept coupling, and sd precision", {
  expect_error(drm_prior_normal("nu", "x", sd = 1), "mu.*sigma")
  expect_error(drm_prior_normal("mu", "x", sd = 1, intercept = "include"), "only when")
  expect_error(drm_prior_normal("mu", "all", sd = 1), "intercept")
  expect_error(drm_prior_normal("mu", "x", sd = 1e-200), "representable")
  expect_equal(drm_prior_ridge("mu", "x", lambda = 0)$sd, Inf)
})

test_that("drm_apply_fixed_priors_spec guards malformed collections and SD caps", {
  x <- model.matrix(~ x, data.frame(x = 1:3))
  spec <- list(
    X = list(mu = x),
    tmb_data = list(),
    random = list(mu = list(
      n_terms = 1L,
      group_names = "g",
      coef_names = "(Intercept)",
      covariance_labels = NA_character_,
      labels = "g"
    ))
  )
  expect_error(drmTMB:::drm_apply_fixed_priors_spec(spec, NULL), "drm_priors")
  bad <- structure(list(list(foo = 1)), class = "drm_priors")
  expect_error(drmTMB:::drm_apply_fixed_priors_spec(spec, bad), "Invalid prior")
  dup_sd <- drm_priors(
    drm_prior_sd_gamma(group = "g", shape = 2, rate = 3),
    drm_prior_sd_gamma(group = "g", shape = 2.2, rate = 1.1)
  )
  expect_error(drmTMB:::drm_apply_fixed_priors_spec(spec, dup_sd), "duplicate")
  three_sd <- drm_priors(
    drm_prior_sd_gamma(group = "a", shape = 2, rate = 3),
    drm_prior_sd_gamma(group = "b", shape = 2, rate = 3),
    drm_prior_sd_gamma(group = "c", shape = 2, rate = 3)
  )
  spec$random$mu <- list(
    n_terms = 3L,
    group_names = c("a", "b", "c"),
    coef_names = rep("(Intercept)", 3),
    covariance_labels = rep(NA_character_, 3),
    labels = c("g1", "g2", "g3")
  )
  expect_error(drmTMB:::drm_apply_fixed_priors_spec(spec, three_sd), "At most two")
})

test_that("drm_apply_fixed_priors_spec requires design metadata for broad selectors", {
  bare <- matrix(1:4, ncol = 1)
  colnames(bare) <- "x"
  spec <- list(X = list(mu = bare), tmb_data = list())
  p <- drm_priors(drm_prior_normal("mu", "all", sd = 1, intercept = "include"))
  expect_error(drmTMB:::drm_apply_fixed_priors_spec(spec, p), "assignment metadata")
})

test_that("drm_validate_fixed_prior_designs rejects rank-deficient prior designs", {
  dat <- data.frame(y = 1:4, x = 1:4, z = c(1, 2, 3, 4))
  aliased <- bf(y ~ x + z + I(x + z), sigma ~ 1)
  p <- drm_priors(drm_prior_normal("mu", "x", sd = 2))
  expect_error(drm_resolve_priors(aliased, gaussian(), dat, p), "full column rank")
})

test_that("drm_fixed_prior_phylo_lss classifies the phylogenetic LSS prior shape", {
  testthat::skip_if_not_installed("ape")
  tree <- ape::read.tree(text = "((a:0.5,b:0.5):0.5,(c:0.5,d:0.5):0.5);")
  d <- data.frame(
    y = c(.2, .7, .35, 1.1),
    x = c(-1, 0, .5, 1),
    sp = factor(c("a", "b", "c", "d")),
    z = c(-1, -.3, .4, 1)
  )
  f <- bf(
    y ~ x + phylo(1 | sp, tree = tree),
    sigma ~ x,
    sd(sp, level = "phylogenetic") ~ z
  )
  p <- drm_priors(
    drm_prior_normal("mu", "x", mean = 0.1, sd = 0.7),
    drm_prior_normal("sigma", "x", mean = -0.2, sd = 0.5)
  )
  lss <- drmTMB:::drm_fixed_prior_phylo_lss(p, f, "gaussian")
  expect_true(lss)
  expect_false(drmTMB:::drm_fixed_prior_phylo_lss(p, bf(y ~ x), "gaussian"))
  mixed <- drm_priors(
    drm_prior_normal("mu", "x", sd = 1),
    drm_prior_ridge("sigma", "x", lambda = 1)
  )
  expect_false(drmTMB:::drm_fixed_prior_phylo_lss(mixed, f, "gaussian"))
})

test_that("drm_validate_fixed_prior_request enforces control and SD-only admission", {
  p <- drm_priors(drm_prior_normal("mu", "x", sd = 2))
  d <- data.frame(y = 1:6, x = 1:6, g = factor(rep(1:3, 2)))
  f <- bf(y ~ x + (1 | g), sigma ~ 1)
  validate <- drmTMB:::drm_validate_fixed_prior_request
  expect_error(
    validate(p, f, gaussian(), d, control = list(logsigma_clamp = c(-2, 2))),
    "logsigma_clamp"
  )
  expect_error(
    validate(p, f, gaussian(), d, control = drm_control(sparse_fixed = TRUE)),
    "dense"
  )
  expect_error(
    validate(p, f, gaussian(), d, control = drm_control(aggregate_gaussian = TRUE)),
    "dense"
  )
  expect_error(validate(p, f, gaussian(), d, penalty = list(mu = 1)), "penalty")
  sd_only <- drm_priors(drm_prior_sd_gamma(group = "g", shape = 2, rate = 3))
  expect_error(
    validate(sd_only, bf(y ~ x, sigma ~ 1), gaussian(), d),
    "random intercept"
  )
})

test_that("drm_abort_fixed_prior_inference names SD-prior fits", {
  f <- structure(
    list(
      resolved_priors = data.frame(precision = 0),
      resolved_sd_prior = data.frame(shape = 2)
    ),
    class = "drmTMB"
  )
  expect_error(drm_abort_fixed_prior_inference(f, "confint"), "SD prior")
})

test_that("drm_resolve_priors validates formula and data types", {
  p <- drm_priors(drm_prior_normal("mu", "x", sd = 2))
  d <- data.frame(y = 1:4, x = 1:4)
  expect_error(drm_resolve_priors(y ~ x, gaussian(), d, p), "bf")
  expect_error(drm_resolve_priors(bf(y ~ x), gaussian(), as.matrix(d), p), "data frame")
})

test_that("prior tables cannot target a coefficient literally named all", {
  d <- data.frame(y = 1:4, all = 1:4)
  tab <- data.frame(prior = "normal(0,2)", class = "fixef", coef = "")
  expect_error(
    drm_resolve_priors(bf(y ~ all, sigma = ~1), gaussian(), d, tab),
    "literally named"
  )
})

test_that("mi() returns its argument for model-frame construction", {
  expect_identical(mi(7L), 7L)
  expect_identical(mi(c(1, NA, 3)), c(1, NA, 3))
})

test_that("predict(type = quantile) rejects boundary probabilities", {
  set.seed(2711)
  dat <- data.frame(
    y = stats::rnorm(25),
    x = stats::rnorm(25)
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, family = gaussian())
  expect_error(predict(fit, type = "quantile", prob = 0), "between 0 and 1")
  expect_error(predict(fit, type = "quantile", prob = 1), "between 0 and 1")
  expect_error(predict(fit, type = "quantile", prob = c(0.5, NA_real_)), "between 0 and 1")
})

test_that("bivariate quantile routing requires a response-identifying dpar", {
  set.seed(2712)
  dat <- data.frame(
    y1 = stats::rnorm(30),
    y2 = stats::rnorm(30),
    x = stats::rnorm(30)
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = dat
  )
  expect_error(
    predict(fit, type = "quantile", prob = 0.5, dpar = "rho12"),
    "dpar"
  )
})

test_that("exceedance() and centile_chart() reject reserved dots and bad covariates", {
  testthat::skip_if_not_installed("ggplot2")
  set.seed(2713)
  dat <- data.frame(y = stats::rnorm(30), x = stats::rnorm(30))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, family = gaussian())
  expect_error(exceedance(fit, threshold = 0, extra = 1), "reserved")
  expect_error(centile_chart(fit, covariate = "x", extra = 1), "reserved")
  expect_error(centile_chart(fit, covariate = c("x", "y")), "single")
  expect_error(centile_chart(fit, covariate = ""), "single")
  expect_error(centile_chart(fit, covariate = NA_character_), "single")
})

test_that("single-predictor centile charts state that no other covariates remain", {
  testthat::skip_if_not_installed("ggplot2")
  set.seed(2714)
  dat <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, family = gaussian())
  p <- centile_chart(fit, covariate = "x", n = 12L)
  expect_s3_class(p, "ggplot")
  expect_match(p$labels$subtitle, "No other covariates")
})

test_that("drm_quantile_prob_labels formats percentage column names", {
  labs <- drmTMB:::drm_quantile_prob_labels(c(0.025, 0.5, 0.975))
  expect_equal(labs, c("2.5%", "50%", "97.5%"))
})