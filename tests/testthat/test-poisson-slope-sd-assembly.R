test_that("a unique Poisson slope gets coefficient-specific SD rows", {
  dat <- poisson_sd_fixture(groups = 12L, repeats = 5L)$data
  key <- 'sd(id, dpar = "mu", coef = "x")'
  explicit <- drm_build_poisson_spec(bf(
    y ~ x + (0 + x | id), sd(id, dpar = "mu", coef = "x") ~ w
  ), dat)
  simple <- drm_build_poisson_spec(bf(y ~ x + (0 + x | id), sd(id) ~ w), dat)
  expect_identical(explicit$random_scale$mu$target_identity[[key]]$coef, "x")
  expect_identical(explicit$random_scale$mu$target_identity[[key]]$design_value,
                   dat$x)
  expect_equal(explicit$random_scale$mu$X_list[[key]][, "w"],
               simple$random_scale$mu$X_list[["sd(id)"]][, "w"])
  expect_identical(explicit$random_scale$mu$re_sd_row0,
                   seq_len(nlevels(dat$id)) - 1L)
  expect_equal(as.numeric(explicit$tmb_data$mu_re_value[, 1L]), dat$x)
  expect_identical(explicit$random$mu$n_cors, 0L)
  expect_true(all(is.na(explicit$map$log_sd_mu)))
  expect_true(all(is.na(explicit$map$beta_sigma)))
})

test_that("Poisson slope SD keeps selector and unvalidated-combination boundaries", {
  dat <- poisson_sd_fixture(groups = 12L, repeats = 5L)$data
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (0 + x | id), sd(id, coef = "(Intercept)") ~ w
  ), dat), "Available targets")
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (1 | id) + (0 + x | id), sd(id) ~ w
  ), dat), "Ambiguous")
  # Independent same-group intercept + slope with a selected coefficient SD is
  # now admitted (fit evidence: test-poisson-additive-ordinary-sd-regression.R).
  expect_no_error(drm_build_poisson_spec(bf(
    y ~ x + (1 | id) + (0 + x | id), sd(id, coef = "x") ~ w
  ), dat))
  # One unlabelled correlated q2 block with a selected coefficient SD is now
  # admitted (evidence: docs/dev-log/after-task/2026-10-27-native-poisson-
  # correlated-q2-sd.md).
  q2 <- drm_build_poisson_spec(bf(
    y ~ x + (1 + x | id), sd(id, coef = "x") ~ w
  ), dat)
  expect_identical(q2$random_scale$mu$dpars, 'sd(id, coef = "x")')
  expect_identical(q2$random$mu$n_cors, 1L)
  binary <- dat
  binary$y <- as.integer(binary$y > 0)
  # Binomial slope-only SD is now admitted (evidence: docs/dev-log/after-task/
  # 2026-10-18-binomial-same-group-coefficient-sd.md and 2026-10-27-binomial-
  # nonlogit-ordinary-slope-sd.md; fit test test-binomial-nonlogit-ordinary-
  # slope-sd.R).
  bin_slope <- drm_build_binomial_spec(bf(
    y ~ x + (0 + x | id), sd(id, coef = "x") ~ w
  ), binary)
  expect_identical(bin_slope$model_type, "binomial")
  expect_identical(bin_slope$random_scale$mu$dpars, 'sd(id, coef = "x")')
  expect_identical(bin_slope$random$mu$n_cors, 0L)
  # Zero-inflated Poisson plus one independent slope with a selected SD is now
  # admitted (evidence: docs/dev-log/after-task/2026-10-24-poisson-zi-slope-
  # cross-engine.md). The same model without an sd() formula is still refused,
  # which is a source inconsistency with NB2 (see report); not asserted here.
  zi_slope <- drm_build_poisson_spec(bf(
    y ~ x + (0 + x | id), zi ~ 1, sd(id, coef = "x") ~ w
  ), dat)
  expect_identical(zi_slope$model_type, "zi_poisson")
  expect_identical(zi_slope$random_scale$mu$dpars, 'sd(id, coef = "x")')
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (0 + x | id), sd(id, coef = "x") ~ w
  ), dat, missing = miss_control(response = "include")), "complete data")
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (0 + x | p | id), sd(id, coef = "x", block = "p") ~ w
  ), dat), "Unsupported random-effect term")
  coords <- cbind(seq_len(nlevels(dat$id)), rep(0, nlevels(dat$id)))
  rownames(coords) <- levels(dat$id)
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (0 + x | id) + spatial(1 | id, coords = coords),
    sd(id, coef = "x") ~ w
  ), dat), "complete data|structured")
  dat$w[1L] <- dat$w[1L] + 0.1
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (0 + x | id), sd(id, coef = "x") ~ w
  ), dat), "constant within")
})
