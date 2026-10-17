test_that("binomial scalar SD selectors resolve the same real intercept axis", {
  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L)$data
  simple <- drm_build_binomial_spec(bf(y ~ x + (1 | id), sd(id) ~ w), dat)
  explicit <- drm_build_binomial_spec(bf(
    y ~ x + (1 | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w
  ), dat)
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  expect_identical(explicit$random_scale$mu$dpars, key)
  expect_equal(explicit$random_scale$mu$X_list[[key]],
               simple$random_scale$mu$X_list[["sd(id)"]], ignore_attr = TRUE)
  expect_identical(explicit$random_scale$mu$re_sd_row0,
                   simple$random_scale$mu$re_sd_row0)
  expect_identical(explicit$random_scale$mu$target_identity[[key]]$provider,
                   "ordinary")
  expect_identical(explicit$random_scale$mu$target_identity[[key]]$coef,
                   "(Intercept)")
  expect_identical(explicit$random_scale$mu$target_identity[[key]]$dpar,
                   "mu")
  expect_equal(explicit$tmb_data$X_sd_mu, explicit$random_scale$mu$X,
               ignore_attr = TRUE)
})

test_that("a unique labelled binomial intercept has stable selected identity", {
  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L)$data
  key <- 'sd(id, block = "p")'
  spec <- drm_build_binomial_spec(bf(
    y ~ x + (1 | p | id), sd(id, block = "p") ~ w
  ), dat)
  expect_identical(spec$random_scale$mu$dpars, key)
  expect_identical(spec$random_scale$mu$target_identity[[key]]$block, "p")
  expect_identical(spec$random_scale$mu$target_identity[[key]]$source_label,
                   "(1 | p | id)")
  expect_identical(spec$random_scale$mu$target_identity[[key]]$latent_pos0,
                   seq_len(nlevels(dat$id)) - 1L)
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(nlevels(dat$id)) - 1L)
})

test_that("two independent q1 groups keep distinct latent row and coefficient maps", {
  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L)$data
  dat$site <- factor(rep(seq_len(6L), length.out = nrow(dat)))
  dat$v <- seq(-1, 1, length.out = 6L)[as.integer(dat$site)]
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  spec <- drm_build_binomial_spec(bf(
    y ~ x + (1 | id) + (1 | site),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(site) ~ v
  ), dat)
  sd_re <- spec$random_scale$mu
  expect_identical(sd_re$dpars, c(key, "sd(site)"))
  expect_equal(sd_re$target_coef, stats::setNames(1:2, sd_re$dpars))
  expect_identical(sd_re$re_sd_row0,
                   seq_len(spec$random$mu$n_re) - 1L)
  expect_identical(sd_re$target_identity[["sd(site)"]]$group, "site")
  expect_equal(nrow(sd_re$X_list[[key]]), nlevels(dat$id))
  expect_equal(nrow(sd_re$X_list[["sd(site)"]]), nlevels(dat$site))
})

test_that("binomial scalar selectors fail closed on ambiguity, mismatch and duplicates", {
  dat <- binomial_sd_fixture(groups = 12L, repeats = 4L)$data
  expect_error(drm_build_binomial_spec(bf(
    y ~ x + (1 | id) + (0 + x | id), sd(id) ~ w
  ), dat), "Ambiguous.*id")
  expect_error(drm_build_binomial_spec(bf(
    y ~ x + (1 | id) + (0 + x | id),
    sd(id, coef = "(Intercept)") ~ w
  ), dat), "random-slope|intercept|q1", ignore.case = TRUE)
  expect_error(drm_build_binomial_spec(bf(
    y ~ x + (1 | p | id), sd(id, block = "q") ~ w
  ), dat), "Available targets")
  expect_error(drm_build_binomial_spec(bf(
    y ~ x + (1 | id), sd(id, coef = "x") ~ w
  ), dat), "Available targets")
  expect_error(drm_build_binomial_spec(bf(
    y ~ x + (1 | id), sd(id) ~ w,
    sd(id, dpar = "mu", coef = "(Intercept)") ~ 1
  ), dat), "Duplicate random-effect scale target")
  expect_error(drm_build_binomial_spec(bf(
    y ~ x + (1 | p | id) + (1 | q | id),
    sd(id, block = "p") ~ w
  ), dat), "Overlapping random-effect terms")
})
