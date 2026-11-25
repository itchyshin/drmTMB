# refs #1741: admit bivariate Gaussian REML with miss_control(response = "include").
# Reference logLik for the issue reproducer: DRModels.jl / issue #1741 comment
# (logLik -309.5849017 at fitted parameters, nobs 100).

test_that("bivariate Gaussian REML fits with response include (issue reproducer)", {
  skip_on_cran()
  set.seed(1)
  G <- 20L
  n <- 100L
  g <- factor(sample(rep(seq_len(G), length.out = n)))
  x1 <- stats::rnorm(n)
  x2 <- stats::rnorm(n)
  u <- matrix(stats::rnorm(2 * G, sd = 0.7), G, 2)
  e1 <- stats::rnorm(n)
  e2 <- 0.4 * e1 + sqrt(1 - 0.16) * stats::rnorm(n)
  y1 <- 1 + 0.5 * x1 + u[g, 1L] + e1
  y2 <- -1 + 0.8 * x2 + u[g, 2L] + e2
  y1[c(3L, 17L, 41L, 58L, 77L, 90L)] <- NA_real_
  d <- data.frame(y1, y2, x1, x2, g)
  f <- bf(
    mu1 = y1 ~ x1 + (1 | p | g),
    mu2 = y2 ~ x2 + (1 | p | g),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
  fit <- suppressWarnings(drmTMB(
    f,
    family = biv_gaussian(),
    data = d,
    REML = TRUE,
    missing = miss_control(response = "include"),
    control = drm_control(optimizer_preset = "robust")
  ))
  expect_equal(fit$estimator, "REML")
  expect_equal(fit$opt$convergence, 0L)
  expect_equal(fit$nobs, 100L)
  # Julia DRModels.jl / nlme long-format reference from issue #1741.
  expect_equal(as.numeric(logLik(fit)), -309.5849017, tolerance = 0.05)
})

test_that("fixed-effect bivariate Gaussian REML fits with response include", {
  skip_on_cran()
  set.seed(1741L)
  n <- 120L
  x1 <- stats::rnorm(n)
  x2 <- stats::rnorm(n)
  y1 <- 0.5 + 0.3 * x1 + stats::rnorm(n, sd = 0.5)
  y2 <- -0.2 + 0.4 * x2 + stats::rnorm(n, sd = 0.6)
  y1[c(5L, 22L, 44L)] <- NA_real_
  d <- data.frame(y1, y2, x1, x2)
  fit_reml <- suppressWarnings(drmTMB(
    bf(mu1 = y1 ~ x1, mu2 = y2 ~ x2, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = d,
    REML = TRUE,
    missing = miss_control(response = "include"),
    control = drm_control(optimizer_preset = "robust")
  ))
  fit_ml <- suppressWarnings(drmTMB(
    bf(mu1 = y1 ~ x1, mu2 = y2 ~ x2, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = d,
    REML = FALSE,
    missing = miss_control(response = "include"),
    control = drm_control(optimizer_preset = "robust")
  ))
  expect_equal(fit_reml$opt$convergence, 0L)
  expect_equal(c(as.numeric(fit_reml$par$mu1), as.numeric(fit_reml$par$mu2)),
               c(as.numeric(fit_ml$par$mu1), as.numeric(fit_ml$par$mu2)),
               tolerance = 1e-2)
})

test_that("REML response include refuses rank-deficient observed mu1 design", {
  skip_on_cran()
  n <- 12L
  g <- factor(rep(c("a", "b"), each = n / 2L))
  x1 <- stats::rnorm(n)
  x2 <- stats::rnorm(n)
  y1 <- x1 + stats::rnorm(n, sd = 0.2)
  y2 <- x2 + stats::rnorm(n, sd = 0.2)
  # Level "b" contributes only rows where y1 is missing -> mu1 design loses rank.
  y1[g == "b"] <- NA_real_
  d <- data.frame(y1, y2, x1, x2, g)
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x1 + g, mu2 = y2 ~ x2, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
      family = biv_gaussian(),
      data = d,
      REML = TRUE,
      missing = miss_control(response = "include")
    ),
    "full-rank fixed-effect design among the observed rows"
  )
})

test_that("univariate Gaussian REML still refuses response include with missing y", {
  skip_on_cran()
  set.seed(1)
  n <- 40L
  dat <- data.frame(
    id = rep(paste0("g", seq_len(5L)), each = 8L),
    x = stats::rnorm(n),
    y = stats::rnorm(n)
  )
  dat$y[[3L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id)),
      family = gaussian(),
      data = dat,
      REML = TRUE,
      missing = miss_control(response = "include")
    ),
    "missing-data engine"
  )
})

test_that("bivariate REML still refuses miss_control(predictor = model)", {
  skip_on_cran()
  set.seed(2)
  n <- 30L
  d <- data.frame(
    y1 = stats::rnorm(n),
    y2 = stats::rnorm(n),
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  d$z[[4L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + mi(z), mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
      family = biv_gaussian(),
      data = d,
      REML = TRUE,
      missing = miss_control(predictor = "model")
    ),
    "missing-data engine"
  )
})