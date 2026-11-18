beta_binomial_inactive_sigma_sd_rank_fixture <- function() {
  dat <- data.frame(
    success = c(6L, 9L, 3L, 7L),
    failure = c(6L, 3L, 9L, 5L),
    x = c(-1, 0, 0.5, 1)
  )
  spec <- drmTMB:::drm_build_beta_binomial_spec(
    bf(cbind(success, failure) ~ x, sigma ~ 1),
    dat
  )
  list(
    model = list(
      X = spec$X,
      random_scale = spec$random_scale
    )
  )
}

test_that("rank checks ignore an inactive sigma SD design", {
  object <- beta_binomial_inactive_sigma_sd_rank_fixture()

  matrices <- drmTMB:::drm_fixed_effect_design_matrices(object)
  expect_false("sd_sigma" %in% names(matrices))
  expect_false(drmTMB:::drm_fixed_effect_rank_deficient(object))
  expect_null(drmTMB:::check_fixed_effect_rank_deficiency(object))
})

test_that("rank checks retain an active sigma SD design", {
  object <- list(
    model = list(
      X = list(
        mu = matrix(seq_len(4L), ncol = 1L),
        sd_sigma = matrix(0, nrow = 4L, ncol = 1L)
      ),
      random_scale = list(
        mu = list(n_models = 0L),
        sigma = list(n_models = 1L)
      )
    )
  )

  expect_true(drmTMB:::drm_fixed_effect_rank_deficient(object))
  check <- drmTMB:::check_fixed_effect_rank_deficiency(object)
  expect_identical(check$status, "warning")
  expect_match(check$value, "sd_sigma:rank=0/ncol=1")
})
