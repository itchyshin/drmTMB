test_that("variance ratio intervals refuse active fixed-effect priors", {
  d <- data.frame(x = rep(c(-1, 0, 1), 6), g = factor(rep(1:6, each = 3)))
  d$y <- 0.5 + 0.6*d$x + rep(c(-0.5, 0.2, 0.7, -0.3, 0.4, -0.4), each = 3) +
    rep(c(0.1, -0.2, 0.1), 6)
  fm <- bf(y ~ x + (1 | g), sigma ~ 1)
  p <- drm_priors(drm_prior_normal("mu", "x", sd = 0.8))
  z <- drm_priors(drm_prior_ridge("mu", "x", lambda = 0))
  active <- drmTMB(fm, data = d, priors = p)
  plain <- drmTMB(fm, data = d)
  zero <- drmTMB(fm, data = d, priors = z)

  for (accessor in list(heritability, icc, repeatability)) {
    for (method in c("delta", "profile")) {
      result <- tryCatch(accessor(active, method = method), error = identity)
      expect_true(inherits(result, "error") &&
        grepl("fixed-effect prior", conditionMessage(result), fixed = TRUE))
    }
    expect_no_error(accessor(plain, method = "delta"))
    expect_no_error(accessor(zero, method = "delta"))
    expect_equal(accessor(zero, method = "delta"), accessor(plain, method = "delta"), tolerance = 1e-7)
    expect_error(accessor(plain, method = "profile"), "not implemented")
    expect_error(accessor(zero, method = "profile"), "not implemented")
  }
  derived <- summary(active)$derived
  expect_true(nrow(derived) > 0L)
  expect_true(all(is.finite(derived$estimate)))
  # A MAP label by itself is not an active fixed-effect prior.
  other_map <- plain
  other_map$estimator <- "MAP"
  expect_no_error(icc(other_map, method = "delta"))
})
