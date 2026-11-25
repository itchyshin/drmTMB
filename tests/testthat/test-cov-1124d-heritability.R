# Heritability print method and the guards that fire before a ratio is formed.

test_that("print.drm_heritability reports the estimate and, for delta method, the SE", {
  printed <- data.frame(
    quantity = "heritability",
    component = "id",
    estimate = 0.25,
    se = 0.1,
    lower = 0.05,
    upper = 0.45,
    level = 0.95,
    method = "delta",
    stringsAsFactors = FALSE
  )
  class(printed) <- c("drm_heritability", "data.frame")
  text <- paste(capture.output(print(printed), type = "message"), collapse = "\n")
  expect_match(text, "<heritability>", fixed = TRUE)
  expect_match(text, "component =", fixed = TRUE)
  expect_match(text, "estimate: 0.25", fixed = TRUE)
  expect_match(text, "se: 0.1", fixed = TRUE)
  expect_match(text, "95% CI", fixed = TRUE)

  point <- printed
  point$method <- "point"
  point_text <- paste(capture.output(print(point), type = "message"), collapse = "\n")
  expect_false(grepl("se:", point_text, fixed = TRUE))
  expect_s3_class(print(point), "drm_heritability")
})

test_that("heritability refuses a profile interval and a non-Gaussian fit", {
  set.seed(1124)
  dat <- data.frame(y = stats::rnorm(12), x = stats::rnorm(12))
  gaussian_fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_error(
    heritability(gaussian_fit, method = "profile"),
    "not implemented"
  )
  expect_error(
    heritability(gaussian_fit),
    "at least one structured mean random-effect"
  )

  counts <- data.frame(y = stats::rpois(12, lambda = 2), x = dat$x)
  poisson_fit <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = counts,
    control = drm_control(se = FALSE)
  )
  expect_error(
    heritability(poisson_fit),
    "requires a Gaussian"
  )
  expect_error(
    icc(poisson_fit),
    "requires a Gaussian"
  )
})

test_that("component lookup and covariance alignment fail with the stored names", {
  expect_error(
    drmTMB:::drm_variance_ratio_resolve_component(
      c(id = 0.4, site = 0.2),
      "block",
      "heritability"
    ),
    "no structured component named"
  )

  object <- list(
    model = list(
      model_type = "gaussian",
      random = list(sigma = list(n_re = 1L, n_terms = 2L)),
      structured = list(phylo_mu = list(has = FALSE))
    ),
    random_effects = list(sigma = list(values = 1)),
    opt = list(par = c(log_sd_sigma = 0))
  )
  expect_null(drmTMB:::drm_sigma_residual_extra_positions(object))

  aligned <- object
  aligned$opt$par <- c(beta_sigma = 0)
  covariance <- matrix(1, nrow = 1L, ncol = 1L, dimnames = list("other", "other"))
  expect_error(
    drmTMB:::drm_variance_ratio_check_cov_alignment(
      aligned,
      covariance,
      "heritability"
    ),
    "do not match"
  )
})
