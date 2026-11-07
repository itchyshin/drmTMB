# Pure reference checks, no fitted package or TMB dependency.
source("tools/general-sd-regression/scalar-binomial-reference.R")
library(testthat)

test_that("adaptive integration respects Bernoulli and count identities", {
  ref <- scalar_binomial_log_marginal
  for (link in c("logit", "probit")) {
    for (s in c(0.1, 0.8, 3)) {
      expect_equal(ref(1, 1, 0, s, link)$log_marginal, log(0.5), tolerance = 1e-9)
    }
  }
  for (s in c(0.2, 1.7, 4)) {
    expect_equal(ref(1, 1, 0.7, s, "probit")$log_marginal,
                 pnorm(0.7 / sqrt(1 + s^2), log.p = TRUE), tolerance = 1e-9)
  }
  expect_equal(ref(c(1, 0), c(1, 1), c(-0.7, 0.3), 0)$log_marginal,
               sum(dbinom(c(1, 0), 1, plogis(c(-0.7, 0.3)), log = TRUE)))
  for (link in c("logit", "probit", "cloglog")) {
    outcomes <- expand.grid(first = 0:2, second = 0:1)
    logs <- vapply(seq_len(nrow(outcomes)), function(i) {
      ref(as.numeric(outcomes[i, ]), c(2, 1), c(-0.5, 0.8), 1.4, link)$log_marginal
    }, numeric(1))
    expect_equal(sum(exp(logs)), 1, tolerance = 1e-8)
  }
})

test_that("reference is stable, ordered and fails closed", {
  ref <- scalar_binomial_log_marginal
  expect_equal(ref(1, 1, -100, 0.5)$log_marginal, -99.875, tolerance = 1e-8)
  expect_equal(ref(1, 1, -1000, 0.5, "cloglog")$log_marginal,
               -999.875, tolerance = 1e-8)
  expect_equal(ref(c(1, 0), c(2, 3), c(-0.5, 0.8), 1.4)$log_marginal,
               ref(c(0, 1), c(3, 2), c(0.8, -0.5), 1.4)$log_marginal)
  ordinary <- ref(c(1, 0), c(2, 3), c(-0.5, 0.8), 1.4)
  tighter <- ref(c(1, 0), c(2, 3), c(-0.5, 0.8), 1.4, rel.tol = 1e-10)
  expect_equal(ordinary$log_marginal, tighter$log_marginal, tolerance = 1e-8)
  expect_true(is.finite(ordinary$relative_error))
  expect_lte(ordinary$relative_error, 1e-7)
  expect_error(ref(1, 1, 0, -1), "sd")
  expect_error(ref(2, 1, 0, 1), "counts")
  expect_error(ref(1, 1, c(0, 1), 1), "length")
  expect_error(ref(1, 1, NA_real_, 1), "finite")
  expect_error(ref(1, 1, 0, 1, "identity"), "link")
  expect_error(ref(1, 1, 0, 1, c("logit", "probit")), "link")
})
cat("SCALAR_BINOMIAL_REFERENCE_PASS\n")
