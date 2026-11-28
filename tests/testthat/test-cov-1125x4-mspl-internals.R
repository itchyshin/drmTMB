# R/mspl-estimator.R admission helpers and inference fences.

mspl_like <- function(estimator = "MSPL") {
  structure(list(estimator = estimator, mspl = list(wald = list(status = "rank"))), class = "drmTMB")
}

test_that("drm_match_estimator() round-trips ML and MSPL spellings", {
  expect_identical(drmTMB:::drm_match_estimator("ml"), "ml")
  expect_identical(drmTMB:::drm_match_estimator("MSPL"), "mspl")
  expect_error(drmTMB:::drm_match_estimator("reml"), "should be one of")
})

test_that("drm_is_mspl() detects fitted objects and strings", {
  expect_true(drmTMB:::drm_is_mspl(mspl_like()))
  expect_false(drmTMB:::drm_is_mspl(list(estimator = "ML", class = "drmTMB")))
  expect_true(drmTMB:::drm_is_mspl("mspl"))
})

test_that("drm_abort_mspl_inference() errors only on MSPL fits", {
  expect_invisible(drmTMB:::drm_abort_mspl_inference(list(estimator = "ML"), "vcov"))
  expect_error(
    drmTMB:::drm_abort_mspl_inference(mspl_like(), "vcov"),
    class = "drmTMB_mspl_inference_unsupported"
  )
})

test_that("drm_mspl_link_name() maps link_code integers", {
  expect_identical(drmTMB:::drm_mspl_link_name(0L), "logit")
  expect_identical(drmTMB:::drm_mspl_link_name(1L), "probit")
  expect_identical(drmTMB:::drm_mspl_link_name(2L), "cloglog")
  expect_error(drmTMB:::drm_mspl_link_name(9L), "unsupported link code")
})

test_that("warn_mspl_wald_unavailable() warns on failed SPD gate", {
  fit <- mspl_like()
  expect_warning(
    warn <- drmTMB:::warn_mspl_wald_unavailable(fit),
    class = "drmTMB_mspl_wald_unavailable"
  )
  fit$mspl$wald$status <- "ok"
  expect_invisible(drmTMB:::warn_mspl_wald_unavailable(fit))
})

test_that("drm_mspl_vcov() returns NA matrix when wald is not SPD", {
  fit <- mspl_like()
  fit$opt <- list(par = c(beta_mu = 0, log_sd_mu = -1))
  m <- drmTMB:::drm_mspl_vcov(fit)
  expect_true(all(is.na(m)))
  expect_equal(dim(m), c(2L, 2L))
})