# Issue #1661: same nobs is not the same rows.

row_identity_data <- function() {
  set.seed(1661)
  data.frame(y = rnorm(40), x = rnorm(40), x1 = rnorm(40), x2 = rnorm(40))
}

test_that("anova() refuses two fits that drop different rows", {
  d <- row_identity_data()
  dC <- d[-(1:5), ]
  dD <- d[-(6:10), ]
  mC <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dC)
  mD <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dD)
  expect_identical(nobs(mC), nobs(mD))
  expect_error(
    anova(mC, mD),
    regexp = "same rows",
    class = "drmTMB_lrt_row_mismatch"
  )
})

test_that("anova() and lrt_boundary() refuse different missing-row sets", {
  d <- row_identity_data()
  dA <- d
  dB <- d
  dA$x1[3] <- NA_real_
  dB$x2[8] <- NA_real_
  reduced <- drmTMB(
    bf(y ~ x1 + x2, sigma ~ 1),
    family = gaussian(),
    data = dA
  )
  full <- drmTMB(
    bf(y ~ x1 + x2 + x, sigma ~ 1),
    family = gaussian(),
    data = dB
  )
  expect_identical(nobs(reduced), nobs(full))
  expect_false(identical(rownames(reduced$data), rownames(full$data)))
  expect_error(anova(reduced, full), class = "drmTMB_lrt_row_mismatch")
  expect_error(lrt_boundary(full, reduced), class = "drmTMB_lrt_row_mismatch")
})

test_that("anova() still compares nested fits on one row set", {
  d <- row_identity_data()
  reduced <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = d)
  full <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d)
  tab <- anova(reduced, full)
  expect_true(is.finite(tab$Chisq[[2L]]))
  expect_identical(nobs(reduced), nobs(full))
})

test_that("a different observation count still names the counts", {
  d <- row_identity_data()
  reduced <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = d)
  full <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d[-1L, ])
  expect_error(anova(reduced, full), "different numbers of observations")
  expect_error(lrt_boundary(full, reduced), "same observations")
})
