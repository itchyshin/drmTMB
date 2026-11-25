# corpairs() and associate_pairs() after separate fits (R/methods.R, R/associate-pairs.R).

cov_1125x7_pair <- function() {
  set.seed(112585)
  dat <- data.frame(
    y1 = stats::rnorm(16),
    y2 = stats::rnorm(16),
    y_bin = stats::rbinom(16, 1, 0.5),
    x = stats::rnorm(16),
    g = rep(c("a", "b"), each = 8)
  )
  list(
    gaussian = drmTMB(
      bf(y1 ~ x, sigma ~ 1),
      data = dat,
      control = drm_control(se = FALSE)
    ),
    binomial = drmTMB(
      bf(y_bin ~ x),
      family = binomial(),
      data = dat,
      control = drm_control(se = FALSE)
    ),
    bivariate = drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
      family = biv_gaussian(),
      data = dat,
      control = drm_control(se = FALSE)
    )
  )
}

test_that("corpairs() summarises group-level correlations for a bivariate Gaussian fit", {
  fits <- cov_1125x7_pair()
  cp <- corpairs(fits$bivariate, conf.int = FALSE)
  expect_s3_class(cp, "data.frame")
  expect_true(nrow(cp) >= 1L)
  expect_true(all(c("estimate", "class", "parameter") %in% names(cp)))
})

test_that("plot_corpairs() accepts corpairs rows when ggplot2 is available", {
  skip_if_not(requireNamespace("ggplot2", quietly = TRUE))
  fits <- cov_1125x7_pair()
  cp <- corpairs(fits$bivariate, conf.int = FALSE)
  plt <- plot_corpairs(cp, label = "parameter", interval = FALSE)
  expect_s3_class(plt, "ggplot")
})

test_that("associate_pairs() links a Gaussian margin with a binomial margin", {
  fits <- cov_1125x7_pair()
  assoc <- associate_pairs(
    fits$gaussian,
    fits$binomial,
    kernel = latent_normal(),
    association = ~ 1
  )
  expect_s3_class(assoc, "drm_pair_association")
  expect_true(is.finite(assoc$eta))
  expect_equal(assoc$status, "interior")
})