test_that("meta_V direct-SD grammar requires its matching location random effect", {
  set.seed(2026072412)
  n_study <- 6L
  n_each <- 4L
  n <- n_study * n_each
  dat <- data.frame(
    yi = stats::rnorm(n), x = stats::rnorm(n), z = stats::rnorm(n),
    study = factor(rep(seq_len(n_study), each = n_each)),
    z_study = rep(stats::rnorm(n_study), each = n_each)
  )
  V <- rep(0.02, n)
  expect_error(
    drmTMB(
      bf(
        yi ~ x + meta_V(V = V), sigma ~ z,
        sd(study) ~ z_study
      ),
      family = gaussian(), data = dat
    ),
    "No random-effect term matches `sd\\(study\\)`"
  )
})
