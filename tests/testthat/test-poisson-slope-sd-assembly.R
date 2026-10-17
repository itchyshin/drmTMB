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
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (1 | id) + (0 + x | id), sd(id, coef = "x") ~ w
  ), dat), "same group|more than one coefficient")
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (1 + x | id), sd(id, coef = "x") ~ w
  ), dat), "correlated")
  binary <- dat
  binary$y <- as.integer(binary$y > 0)
  expect_error(drm_build_binomial_spec(bf(
    y ~ x + (0 + x | id), sd(id, coef = "x") ~ w
  ), binary), "intercept")
  expect_error(drm_build_poisson_spec(bf(
    y ~ x + (0 + x | id), zi ~ 1, sd(id, coef = "x") ~ w
  ), dat), "zero-inflated|zi")
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
