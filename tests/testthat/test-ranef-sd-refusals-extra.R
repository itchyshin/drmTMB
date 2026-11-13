test_that("SD Gamma prior rejects invalid scalar parameters and selectors", {
  make <- function(...) drm_prior_sd_gamma(group = "g", shape = 2, rate = 3, ...)
  for (b in c(0, -1, NaN, Inf)) {
    expect_error(drm_prior_sd_gamma(group = "g", shape = 2, rate = b), "rate")
  }
  for (a in c(1, 0, -1, NaN, Inf)) {
    expect_error(drm_prior_sd_gamma(group = "g", shape = a, rate = 3), "shape")
  }
  expect_error(make(dpar = "sigma"), "dpar")
  expect_error(make(coef = "all"), "Intercept")
  for (g in list("", NA_character_, character())) {
    expect_error(drm_prior_sd_gamma(group = g, shape = 2, rate = 3), "group")
  }
})

test_that("SD prior admission refuses unsupported models before fitting", {
  d <- data.frame(y = rep(c(0, 1), 6), x = rep(c(-1, 0, 1), 4),
                  g = factor(rep(1:4, each = 3)))
  d$h <- d$g # Different names with identical partitions remain unidentifiable.
  p <- drm_priors(drm_prior_sd_gamma(group = "g", shape = 2, rate = 3))
  validate <- drmTMB:::drm_validate_fixed_prior_request
  simple <- bf(y ~ x + (1 | g), sigma ~ 1)
  expect_no_error(validate(p, simple, gaussian(), d))
  two_groups <- bf(y ~ x + (1 | g) + (1 | h))
  expect_error(validate(p, two_groups, gaussian(), d), "distinct partitions")
  distinct <- d
  distinct$h <- factor(rep(1:3, 4))
  expect_no_error(validate(p, two_groups, gaussian(), distinct))
  for (f in list(bf(y ~ x + (1 + x | g)),
                 bf(y ~ x + (1 | g) + (1 | g)),
                 bf(y ~ x + (1 | block | g)),
                 bf(y ~ x + (1 || g)),
                 bf(y ~ x + phylo(1 | g, tree = tree)),
                 bf(y ~ x, sigma ~ 1 + (1 | g)))) {
    expect_error(validate(p, f, gaussian(), d), "fixed-effect-only")
  }
  expect_error(validate(p, simple, binomial(), d), "Gaussian mean random intercept")
  expect_error(validate(p, simple, gaussian(), d, REML = TRUE), "REML")
  expect_error(validate(p, simple, gaussian(), d, weights = c(2, rep(1, 11))), "unit weights")
  for (column in c("y", "x", "g")) {
    missing <- d
    missing[[column]][1] <- NA
    expect_error(validate(p, simple, gaussian(), missing), "complete")
  }
  wrong <- drm_priors(drm_prior_sd_gamma(group = "h", shape = 2, rate = 3))
  expect_error(drm_resolve_priors(simple, gaussian(), d, wrong), "target")
  # Check the public fit entry as well as the shared pre-fit admission guard.
  expect_error(drmTMB(simple, family = binomial(), data = d, priors = p), "Gaussian")
  expect_error(drmTMB(bf(y ~ x + (1 + x | g)), data = d, priors = p), "fixed-effect-only")
  expect_error(drmTMB(simple, data = d, priors = p, REML = TRUE), "REML")
  expect_error(drmTMB(simple, data = d, priors = p, weights = c(2, rep(1, 11))), "unit weights")
  incomplete <- d; incomplete$x[1] <- NA
  expect_error(drmTMB(simple, data = incomplete, priors = p), "complete")
})
