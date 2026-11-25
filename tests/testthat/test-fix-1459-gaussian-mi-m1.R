# Regression for #1459 (M1): continuous Gaussian mi() imputation prior must be
# scaled by weights(i), as the binary mi() branch already is.

mi_fix_1459_data <- function() {
  n <- 48
  z <- seq(-1.5, 1.5, length.out = n)
  x <- 0.25 + 0.8 * z + 0.08 * sin(seq_len(n))
  y <- 0.7 + 1.4 * x - 0.35 * z + 0.12 * cos(seq_len(n) / 3)
  dat <- data.frame(y = y, z = z, x = x)
  dat$x[c(6, 18, 30)] <- NA_real_
  dat
}

fit_gaussian_mi_1459 <- function(dat, weights = NULL) {
  withCallingHandlers(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE),
      weights = weights
    ),
    warning = function(w) {
      if (inherits(w, "drmTMB_mi_weights_prior_unweighted")) {
        invokeRestart("muffleWarning")
      }
    }
  )
}

test_that("Gaussian mi() row weight 2 matches duplicating that row at the optimum (#1459)", {
  dat <- mi_fix_1459_data()
  weights <- rep(1, nrow(dat))
  weights[[2L]] <- 2
  fit_w2 <- fit_gaussian_mi_1459(dat, weights = weights)
  fit_dup <- fit_gaussian_mi_1459(rbind(dat, dat[2, , drop = FALSE]))
  expect_equal(fit_w2$opt$convergence, 0L)
  expect_equal(fit_dup$opt$convergence, 0L)
  p <- fit_w2$opt$par
  expect_equal(
    as.numeric(fit_dup$obj$fn(p)),
    as.numeric(fit_w2$obj$fn(p)),
    tolerance = 1e-9
  )
  expect_equal(
    unname(unlist(coef(fit_w2))),
    unname(unlist(coef(fit_dup))),
    tolerance = 1e-5
  )
})