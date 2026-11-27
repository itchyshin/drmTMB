# Cursor coverage ac2 (27 Nov): CRAN-lane smokes for R/[a-c]* modules still at
# 0% under covr::package_coverage(type = "tests"). Slow nested paths use
# skip_on_cran() like test-aghq-coxreid.R.

ac2_tiny_gaussian <- function(n = 28L, seed = 112701L) {
  set.seed(seed)
  x <- stats::rnorm(n)
  data.frame(y = 0.15 + 0.55 * x + stats::rnorm(n, sd = 0.6), x = x)
}

ac2_gaussian_bernoulli_margins <- function(dat = ac2_tiny_gaussian()) {
  set.seed(112702L)
  z_g <- stats::rnorm(nrow(dat))
  z_b <- 0.28 * z_g + sqrt(1 - 0.28^2) * stats::rnorm(nrow(dat))
  dat$trait <- dat$y
  dat$hit <- as.integer(z_b > stats::qnorm(0.55))
  list(
    gaussian = drmTMB(bf(mu = trait ~ x, sigma = ~ 1), gaussian(), dat),
    binary = drmTMB(bf(mu = hit ~ x), binomial(), dat),
    data = dat
  )
}

test_that("drm_o3_gh() Golub-Welsch nodes match the documented Hermite weights", {
  skip_if_not_installed("statmod")
  a <- drmTMB:::drm_o3_gh(5L)
  b <- statmod::gauss.quad(5L, "hermite")
  expect_equal(sort(a$x), sort(b$nodes), tolerance = 1e-10)
  expect_equal(sum(a$w), sqrt(pi), tolerance = 1e-10)
  expect_equal(drmTMB:::drm_o3_npar("binomial", 2L, 4L), 2L)
  expect_equal(drmTMB:::drm_o3_npar("cumulative_logit", 2L, 4L), 5L)
  split <- drmTMB:::drm_o3_split(c(0.1, 0.2, -0.3, 0.4, 0.5), "cumulative_logit", 2L)
  expect_equal(split$beta, c(0.1, 0.2))
  expect_equal(split$theta, c(-0.3, 0.4, 0.5))
})

test_that("worm_plot() and qq_plot() render a tiny gaussian fit on CRAN", {
  skip_if_not_installed("ggplot2")
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), gaussian(), ac2_tiny_gaussian())
  expect_s3_class(worm_plot(fit), "ggplot")
  expect_s3_class(qq_plot(fit), "ggplot")
  expect_error(worm_plot(fit, reserved = TRUE), "reserved")
  expect_s3_class(worm_plot(fit, seed = 1127L, nsim = 3L), "ggplot")
  expect_s3_class(qq_plot(fit, seed = 1127L, nsim = 3L), "ggplot")
})

test_that("bootstrap shard helpers record deterministic replicate ledgers", {
  dat <- ac2_tiny_gaussian()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), gaussian(), dat)
  shard <- drmTMB:::drm_bootstrap_shard
  ledger_fn <- drmTMB:::drm_bootstrap_ledger
  combine <- drmTMB:::drm_bootstrap_combine
  left <- shard(fit, parm = "fixef:mu:x", indices = 1:2, seed = 1127L)
  right <- shard(fit, parm = "fixef:mu:x", indices = 3:4, seed = 1127L)
  combined <- combine(left, right)
  whole <- shard(fit, parm = "fixef:mu:x", indices = 1:4, seed = 1127L)
  expect_identical(combined$attempts, whole$attempts)
  ledger <- ledger_fn(combined)
  expect_identical(ledger$attempted, 4L)
  expect_identical(ledger$usable + ledger$refit_error + ledger$refit_nonconverged +
    ledger$target_missing + ledger$worker_died, 4L)
})

test_that("coevolution accessors refuse fits without a q = 4 Sigma_a", {
  dat <- ac2_tiny_gaussian()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), gaussian(), dat)
  expect_error(coevolution_cor(fit), "4 x 4")
  expect_error(coevolution_vc(fit), "4 x 4")
  expect_error(coevolution_summary(fit), "4 x 4")
})

test_that("associate_pairs() gaussian x bernoulli hits Godambe covariance", {
  margins <- ac2_gaussian_bernoulli_margins()
  assoc <- associate_pairs(
    margins$gaussian,
    margins$binary,
    kernel = latent_normal(),
    association = ~ 1
  )
  expect_s3_class(assoc, "drm_pair_association")
  expect_identical(assoc$components$pair_class, "gaussian_bernoulli")
  expect_s3_class(latent_normal(), "drm_pair_kernel")
  expect_warning(
    v <- vcov(assoc),
    class = "drmTMB_association_inference_warning"
  )
  expect_equal(colnames(v), "alpha")
  expect_true(all(is.finite(diag(v))))
})

test_that("associate_pairs() gaussian x nbinom2 uses the count sandwich", {
  set.seed(112704L)
  dat <- ac2_tiny_gaussian(32L)
  z <- stats::rnorm(nrow(dat))
  dat$count <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(
    z, exp(0.2 + 0.1 * dat$x), rep(0.55, nrow(dat))
  )
  gaussian <- drmTMB(bf(mu = y ~ x, sigma = ~ 1), gaussian(), dat)
  count <- drmTMB(bf(mu = count ~ x, sigma = ~ 1), nbinom2(), dat)
  assoc <- associate_pairs(
    gaussian, count, kernel = latent_normal(), association = ~ 1
  )
  expect_identical(assoc$components$pair_class, "gaussian_nbinom2")
  expect_warning(sqrt(diag(vcov(assoc))), class = "drmTMB_association_inference_warning")
})

test_that("associate_pairs() bernoulli x bernoulli uses the staged sandwich", {
  set.seed(112703L)
  dat <- ac2_tiny_gaussian(36L)
  z1 <- stats::rnorm(nrow(dat))
  z2 <- 0.25 * z1 + sqrt(1 - 0.25^2) * stats::rnorm(nrow(dat))
  dat$e1 <- as.integer(z1 > 0)
  dat$e2 <- as.integer(z2 > stats::qnorm(0.45))
  f1 <- drmTMB(bf(mu = e1 ~ x), binomial(), dat)
  f2 <- drmTMB(bf(mu = e2 ~ x), binomial(), dat)
  assoc <- associate_pairs(f1, f2, kernel = latent_normal(), association = ~ 1)
  expect_identical(assoc$components$pair_class, "bernoulli_bernoulli")
  expect_warning(
    se <- sqrt(diag(vcov(assoc))),
    class = "drmTMB_association_inference_warning"
  )
  expect_true(all(is.finite(se)))
})

test_that("NOT_CRAN: aghq binomial nested fit and profile CI stay finite", {
  skip_on_cran()
  set.seed(11L)
  nid <- 12L
  ne <- 5L
  g <- rep(seq_len(nid), each = ne)
  N <- nid * ne
  x <- stats::rnorm(N)
  u <- stats::rnorm(nid, 0, 0.6)
  y <- stats::rbinom(N, 1L, stats::plogis(-0.2 + 0.6 * x + u[g]))
  fit <- drmTMB:::drm_o3_fit(
    y, cbind(1, x), rep(1, N), g, "binomial",
    nodes = 7L, estimator = "aghq_cr"
  )
  expect_true(fit$sd > 0)
  ci <- drmTMB:::drm_o3_profile_ci(fit)
  expect_true(ci$finite)
  expect_lt(ci$lower, ci$upper)
})