# refs #1741: REML + miss_control(response = "include") stays refused on structured
# location routes (named error); corpair / fixed-effect bivariate keep the generic gate.

test_that("REML response include refuses structured location with a named error", {
  skip_on_cran()
  set.seed(1741L)
  n <- 24L
  labels <- paste0("id", seq_len(n))
  K <- outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(labels, labels)
  dat <- data.frame(
    y = stats::rnorm(n) + 0.3,
    x = stats::rnorm(n),
    id = factor(labels, levels = labels)
  )
  dat$y[[3L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K)),
      family = gaussian(),
      data = dat,
      REML = TRUE,
      missing = miss_control(response = "include")
    ),
    class = "drmTMB_reml_structured_missing_response_unsupported"
  )
})

test_that("issue #1741 corpair route still hits the generic missing-data engine gate", {
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
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + (1 | p | g),
        mu2 = y2 ~ x2 + (1 | p | g),
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = d,
      REML = TRUE,
      missing = miss_control(response = "include")
    ),
    "missing-data engine"
  )
})

test_that("fixed-effect bivariate REML still refuses response include with missing y", {
  skip_on_cran()
  set.seed(1741L)
  n <- 120L
  x1 <- stats::rnorm(n)
  x2 <- stats::rnorm(n)
  y1 <- 0.5 + 0.3 * x1 + stats::rnorm(n, sd = 0.5)
  y2 <- -0.2 + 0.4 * x2 + stats::rnorm(n, sd = 0.6)
  y1[c(5L, 22L, 44L)] <- NA_real_
  d <- data.frame(y1, y2, x1, x2)
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x1, mu2 = y2 ~ x2, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
      family = biv_gaussian(),
      data = d,
      REML = TRUE,
      missing = miss_control(response = "include")
    ),
    "missing-data engine"
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