# The MSPL Jeffreys weight must follow the link, in BOTH implementations.
#
# Regression for the defect fixed here: the `use_mspl == 1` block in
# src/drmTMB.cpp computed log(n) - softplus(eta) - softplus(-eta) -- the logit
# working weight -- with no link_code branch, while R/mspl.R's kernels were
# already link-general. The two implementations disagreed for probit and
# cloglog, and nothing detected it because the entry-point guard admits only
# logit, so the disagreement was unreachable from the public API.
#
# These tests pin the R half and the mapping. The C++ half is exercised
# end-to-end on the evidence branch `claude/mspl-nonlogit-evidence`, whose
# G0b parity sweep drives eta along a separation ray into both tails and
# agrees with these kernels to 3.6e-16 (logit), 5.4e-16 (probit) and
# 1.7e-14 (cloglog).

test_that("link_code maps to the name the MSPL kernels expect", {
  expect_identical(drm_mspl_link_name(0L), "logit")
  expect_identical(drm_mspl_link_name(1L), "probit")
  expect_identical(drm_mspl_link_name(2L), "cloglog")
  expect_identical(drm_mspl_link_name(NULL), "logit")
  expect_error(drm_mspl_link_name(7L), "unsupported link code")
})

test_that("the Jeffreys weight actually differs by link", {
  # A test asserting only that each link RUNS would have passed against the
  # broken version. Assert the values differ.
  eta <- c(-2, -0.5, 0, 0.75, 3)
  w <- lapply(c("logit", "probit", "cloglog"), function(lk) {
    exp(mspl_log_weight(eta, rep(1, length(eta)), lk))
  })
  names(w) <- c("logit", "probit", "cloglog")
  expect_false(isTRUE(all.equal(w$logit, w$probit)))
  expect_false(isTRUE(all.equal(w$logit, w$cloglog)))
  expect_false(isTRUE(all.equal(w$probit, w$cloglog)))
})

test_that("omega(0) matches the closed form for each link", {
  # omega(0) is what calibrates the softness constant c_n = omega(0)^(-1/2) *
  # sqrt(p/n): 2 for logit, 1.2533 for probit, 1.3108 for cloglog. drmTMB ships
  # the logit value for every link, which is why these constants are worth
  # pinning even though c_n is not link-aware yet (design 253, Addendum 3).
  w0 <- vapply(c("logit", "probit", "cloglog"),
               function(lk) exp(mspl_log_weight(0, 1, lk)), numeric(1))
  expect_equal(unname(w0[["logit"]]), 1 / 4, tolerance = 1e-12)
  expect_equal(unname(w0[["probit"]]), 2 / pi, tolerance = 1e-12)
  expect_equal(unname(w0[["cloglog"]]), 1 / (exp(1) - 1), tolerance = 1e-12)
})

test_that("the Jeffreys half-logdet differs by link on the same design", {
  set.seed(11)
  X <- cbind(1, rnorm(40))
  b <- c(-0.3, 0.8)
  j <- vapply(c("logit", "probit", "cloglog"), function(lk) {
    r <- mspl_jeffreys(X = X, beta = b, offset = rep(0, nrow(X)),
                       trials = rep(1L, nrow(X)), frequency = rep(1L, nrow(X)),
                       link = lk)
    expect_true(isTRUE(r$ok))
    r$half_logdet
  }, numeric(1))
  expect_equal(length(unique(round(j, 8))), 3L)
})

test_that("the guard now admits probit and cloglog as well as logit", {
  # SUPERSEDED 2026-08-12. When this file was written the link threading below
  # was explicitly NOT to be read as opening the fence, and this test asserted
  # the fence held. The fence has since been opened deliberately, on the
  # evidence in docs/dev-log/simulation-artifacts/2026-08-11-mspl-nonlogit-links/
  # (finiteness, calibrated standard errors, and an immaterial c_n mismatch).
  # The assertion is inverted rather than deleted so the contract change is
  # visible in the history rather than silently disappearing.
  skip_if_not_installed("testthat")
  d <- data.frame(y = c(0, 1, 0, 1, 1, 0, 1, 0), trt = c(0, 0, 1, 1, 0, 1, 1, 0),
                  block = factor(c(1, 1, 2, 2, 3, 3, 4, 4)))
  for (lk in c("logit", "probit", "cloglog")) {
    fit <- drmTMB(bf(y ~ trt + (1 | block)), family = binomial(link = lk),
                  data = d, estimator = "mspl")
    expect_identical(fit$mspl$link, lk)
  }
})
