# Nested O3 estimator (R/aghq-coxreid.R, doc 224 S2): AGHQ inner marginalization over a
# scalar random effect + Cox-Reid outer adjustment, for non-Gaussian families. These tests
# validate the two levers deterministically against external / internal references BEFORE
# any Monte-Carlo (the arc's discipline). Slow (nested optimization) -> skip on CRAN.

skip_on_cran()

binom_ri_data <- function(seed = 11L, nid = 28L, ne = 6L) {
  set.seed(seed)
  g <- rep(seq_len(nid), each = ne); N <- nid * ne
  x <- stats::rnorm(N); u <- stats::rnorm(nid, 0, 0.8)
  y <- stats::rbinom(N, 1L, stats::plogis(-0.3 + 0.7 * x + u[g]))
  list(y = y, x = x, g = g, X = cbind(1, x), z = rep(1, N))
}

test_that("self-contained Golub-Welsch GH nodes match statmod", {
  skip_if_not_installed("statmod")
  for (nq in c(1L, 5L, 25L)) {
    a <- drm_o3_gh(nq); b <- statmod::gauss.quad(nq, "hermite")
    expect_equal(sort(a$x), sort(b$nodes), tolerance = 1e-10)
    expect_equal(sum(a$w), sqrt(pi), tolerance = 1e-10)   # int e^{-x^2} dx
  }
})

test_that("AGHQ marginal ML matches glmer(nAGQ=k) for a binomial random intercept", {
  skip_if_not_installed("lme4")
  d <- binom_ri_data()
  fit <- drm_o3_fit(d$y, d$X, d$z, d$g, "binomial", nodes = 25L, estimator = "aghq")
  gm <- lme4::glmer(y ~ x + (1 | g), family = binomial,
                    data = data.frame(y = d$y, x = d$x, g = factor(d$g)), nAGQ = 25L)
  gsd <- as.numeric(attr(lme4::VarCorr(gm)$g, "stddev"))
  expect_equal(fit$sd, gsd, tolerance = 1e-3)   # observed ~3.6e-5
})

test_that("nq=1 AGHQ collapses to the Laplace approximation", {
  d <- binom_ri_data()
  f1  <- drm_o3_fit(d$y, d$X, d$z, d$g, "binomial", nodes = 1L,  estimator = "aghq")
  f25 <- drm_o3_fit(d$y, d$X, d$z, d$g, "binomial", nodes = 25L, estimator = "aghq")
  # AGHQ lifts the downward Laplace integral bias -> nq=25 SD strictly above nq=1.
  expect_gt(f25$sd, f1$sd)
})

test_that("binomial ladder is monotone (Laplace < AGHQ < AGHQ+CoxReid) and the profile CI is finite", {
  d <- binom_ri_data()
  f_lap <- drm_o3_fit(d$y, d$X, d$z, d$g, "binomial", nodes = 1L,  estimator = "aghq")
  f_ag  <- drm_o3_fit(d$y, d$X, d$z, d$g, "binomial", nodes = 25L, estimator = "aghq")
  f_cr  <- drm_o3_fit(d$y, d$X, d$z, d$g, "binomial", nodes = 25L, estimator = "aghq_cr")
  expect_lt(f_lap$sd, f_ag$sd)
  expect_lt(f_ag$sd, f_cr$sd)                       # Cox-Reid is the bigger lever
  ci <- drm_o3_profile_ci(f_cr)
  expect_true(ci$finite)
  expect_lt(ci$lower, ci$estimate)
  expect_lt(ci$estimate, ci$upper)
})

test_that("cumulative_logit O3 runs and its bias ladder is monotone up", {
  set.seed(21L); K <- 4L; nid <- 28L; ne <- 8L; N <- nid * ne
  g <- rep(seq_len(nid), each = ne); x <- stats::rnorm(N)
  cut_t <- c(-1, 0, 1.2); u <- stats::rnorm(nid, 0, 0.8); mu <- 0.7 * x + u[g]
  y <- integer(N)
  for (i in seq_len(N)) {
    pk <- diff(c(0, stats::plogis(c(cut_t - mu[i], Inf))))
    y[i] <- sample.int(K, 1L, prob = pk)
  }
  X <- cbind(x); z <- rep(1, N)                     # NO intercept (identified by cutpoints)
  f_lap <- drm_o3_fit(y, X, z, g, "cumulative_logit", nodes = 1L,  estimator = "aghq")
  f_ag  <- drm_o3_fit(y, X, z, g, "cumulative_logit", nodes = 15L, estimator = "aghq")
  f_cr  <- drm_o3_fit(y, X, z, g, "cumulative_logit", nodes = 15L, estimator = "aghq_cr")
  expect_lt(f_lap$sd, f_ag$sd)
  expect_lt(f_ag$sd, f_cr$sd + 1e-4)
  ci <- drm_o3_profile_ci(f_cr)
  expect_true(is.finite(ci$estimate))
})
