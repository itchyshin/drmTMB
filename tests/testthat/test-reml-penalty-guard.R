# REML and a penalty (MAP) are different estimators of the variance components
# (restricted likelihood vs maximum a posteriori), so combining them is
# undefined and rejected. Each alone is accepted.

test_that("REML and penalty cannot be combined", {
  skip_if_not_installed("ape")
  set.seed(1)
  n_id <- 12L
  n <- n_id * 4L
  dat <- data.frame(
    y = stats::rnorm(n),
    x = stats::rnorm(n),
    id = factor(rep(seq_len(n_id), each = 4L))
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1),
      family = gaussian(),
      data = dat,
      REML = TRUE,
      penalty = drm_phylo_penalty(sd_u = 1)
    ),
    "cannot be combined"
  )
  # each alone is accepted
  fit_reml <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat,
    REML = TRUE
  )
  expect_equal(fit_reml$estimator, "REML")
})
