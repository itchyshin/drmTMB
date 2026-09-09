paired_phylo_temporal_ou_profile_fit <- function(seed = 202609097L) {
  fixture <- phylo_temporal_ou_oracle_fixture(seed = seed)
  tree <- fixture$tree
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree) +
         temporal(1 | species, time = elapsed, structure = "ou"), sigma ~ 1),
    data = fixture$data, family = gaussian(), REML = FALSE
  ))
  list(fit = fit, tree = tree)
}

test_that("paired phylogenetic-OU fixed-mean profile endpoints match dense reference", {
  case <- paired_phylo_temporal_ou_profile_fit()
  fit <- case$fit
  dense <- phylo_temporal_ou_dense_profile_ci(fit, case$tree, level = 0.90)
  public <- stats::confint(
    fit, parm = "fixef:mu:x", method = "profile", level = 0.90,
    profile_engine = "tmbprofile", profile_precision = "fast"
  )

  expect_identical(public$parm, "fixef:mu:x")
  expect_identical(public$method, "profile")
  expect_identical(public$conf.status, "profile")
  expect_equal(unname(public$lower), unname(dense[["lower"]]), tolerance = 5e-3)
  expect_equal(unname(public$upper), unname(dense[["upper"]]), tolerance = 5e-3)
})

test_that("paired phylogenetic-OU profile rejects deferred targets and flags irregular Hessians", {
  case <- paired_phylo_temporal_ou_profile_fit()
  fit <- case$fit
  targets <- profile_targets(fit)
  decay <- targets$parm[targets$target_class == "temporal-decay"]
  phylo_sd <- targets$parm[
    targets$target_class == "random-effect-sd" & targets$term == "phylo(1 | species)"
  ]

  expect_error(stats::confint(fit, parm = decay, method = "profile"),
               "mean regression coefficients only")
  expect_error(stats::profile(fit, parm = phylo_sd),
               "mean regression coefficients only")
  expect_error(stats::confint(fit, parm = "mu:x", method = "bootstrap"),
               "do not support.*bootstrap")
  expect_error(
    stats::confint(fit, parm = "mu:x", method = "profile", newdata = fit$data[1L, , drop = FALSE]),
    "do not support.*newdata"
  )
  expect_error(
    stats::confint(fit, parm = "mu:x", method = "profile", profile_engine = "endpoint"),
    "require.*tmbprofile"
  )

  irregular <- fit
  irregular$sdr$pdHess <- FALSE
  expect_warning(
    irregular_ci <- stats::confint(
      irregular, parm = "mu:x", method = "profile", level = 0.90,
      profile_engine = "tmbprofile", profile_precision = "fast"
    ),
    class = "drmTMB_temporal_profile_hessian_warning"
  )
  expect_identical(irregular_ci$conf.status, "profile")
  temporal_check <- check_drm(irregular)
  profile_row <- temporal_check[temporal_check$check == "temporal_mean_profile", , drop = FALSE]
  expect_identical(profile_row$status, "warning")
  expect_match(profile_row$value, "base_hessian_non_pd")
})
