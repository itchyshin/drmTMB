# R-side bivariate biv_gaussian profile/bootstrap confint marshalling.
#
# These tests exercise the pure R-side path: synthetic bridge result, no Julia.
# They cover:
#   (a) drm_julia_profile_targets_biv() — four target rows, one per axis.
#   (b) drm_julia_validate_inference_targets() — accepts the 4-row biv case.
#   (c) drm_julia_inference_confint_multi() — maps Julia vectors to a 4-row
#       confint data frame; handles NaN std_error (profile) and Inf upper.

# --- Synthetic bivariate fit helper ------------------------------------------

drm_julia_biv_synthetic_fit <- function() {
  skip_if_not_installed("ape")
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))

  # Four axes: resd_<dpar>_<term> coefficient naming mirrors what DRM.jl
  # returns for biv_gaussian.  The dpar labels in the formula terms are what
  # drm_julia_structured_parameters uses.
  biv_dpars <- c("mu1", "mu2", "sigma1", "sigma2")
  term_label <- "phylo(1 | species)"
  sd_vals <- c(mu1 = 1.2, mu2 = 0.9, sigma1 = 0.6, sigma2 = 0.4)
  sd_scale <- sqrt(2)  # structured_sd_scales value for the shared phylo term

  resd_names <- paste0("resd_", biv_dpars, "_", term_label)
  resd_coefs <- stats::setNames(
    log(sd_vals / sd_scale),
    paste0("resd_", term_label)  # name pattern used by drm_julia_structured_parameters
  )
  # Build names expected by drm_julia_structured_parameters: one resd_ entry
  # per axis, named "resd_<term_label>". But structured_parameters keys by
  # term_label; dpar comes from formula$entries. We bypass structured_parameters
  # here and directly craft sdpars to match what new_drmTMB_julia would build.
  sdpars <- list(
    mu1 = stats::setNames(sd_vals[["mu1"]], term_label),
    mu2 = stats::setNames(sd_vals[["mu2"]], term_label),
    sigma1 = stats::setNames(sd_vals[["sigma1"]], term_label),
    sigma2 = stats::setNames(sd_vals[["sigma2"]], term_label)
  )

  # Minimal bridge_payload with bivariate = TRUE and a non-NULL tree.
  bridge_payload <- list(
    bivariate = TRUE,
    tree = "((sp1,sp2),(sp3,(sp4,sp5)));",  # newick placeholder
    structured_sd_scales = stats::setNames(
      rep(sd_scale, length(biv_dpars)),
      rep(term_label, length(biv_dpars))
    )
  )

  # Minimal fit object (we don't need coefficients / vcov for pure target tests).
  structure(
    list(
      model = list(model_type = "biv_gaussian"),
      sdpars = sdpars,
      bridge_payload = bridge_payload,
      structured_sd_scales = bridge_payload$structured_sd_scales
    ),
    class = "drmTMB_julia"
  )
}

# --- (a) drm_julia_profile_targets detects biv_gaussian ----------------------

test_that("drm_julia_profile_targets returns 4 rows for biv_gaussian", {
  skip_if_not_installed("ape")
  fit <- drm_julia_biv_synthetic_fit()

  targets <- drmTMB:::drm_julia_profile_targets(fit)

  expect_equal(nrow(targets), 4L)
  expect_true(all(targets$target_class == "random-effect-sd"))
  expect_setequal(targets$dpar, c("mu1", "mu2", "sigma1", "sigma2"))
  expect_true(all(startsWith(targets$term, "phylo(")))
  expect_true(all(startsWith(targets$tmb_parameter, "resd_")))
  expect_true(all(targets$profile_ready))
  expect_true(all(targets$profile_note == "ready"))
  expect_true(all(targets$transformation == "exp"))
  expect_true(all(targets$scale == "response"))
  # Estimates are on the positive response scale.
  expect_true(all(targets$estimate > 0))
  # parm names follow "sd:<dpar>:phylo(1 | species)" pattern.
  expect_true(all(startsWith(targets$parm, "sd:")))
})

# --- (b) validate_inference_targets accepts bivariate 4-row targets ----------

test_that("drm_julia_validate_inference_targets accepts 4-row bivariate targets", {
  skip_if_not_installed("ape")
  fit <- drm_julia_biv_synthetic_fit()
  targets <- drmTMB:::drm_julia_profile_targets(fit)

  # Should not error.
  expect_no_error(drmTMB:::drm_julia_validate_inference_targets(targets))
})

test_that("drm_julia_validate_inference_targets still errors on wrong row count", {
  skip_if_not_installed("ape")
  fit <- drm_julia_biv_synthetic_fit()
  targets <- drmTMB:::drm_julia_profile_targets(fit)

  # 3-row subset is neither univariate (1 row) nor bivariate (4 rows).
  expect_error(
    drmTMB:::drm_julia_validate_inference_targets(targets[1:3, ]),
    regexp = "profile and bootstrap"
  )
})

# --- (c) drm_julia_inference_confint_multi maps Julia vectors to 4-row df ---

drm_julia_biv_fake_result <- function(
  uppers = c(2.4, 1.8, 1.2, 0.8),
  bounded = c(TRUE, TRUE, TRUE, FALSE),
  method = "profile"
) {
  # Mimics what DRM.jl returns as result$multi == TRUE.
  list(
    method = method,
    multi = TRUE,
    param = c("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2"),
    estimate = c(1.2, 0.9, 0.6, 0.4),
    std_error = c(NaN, NaN, NaN, NaN),  # NaN for profile
    lower = log(c(0.6, 0.4, 0.3, 0.2)),  # log scale; exp'd in confint_multi
    upper = ifelse(is.infinite(uppers), Inf, log(uppers)),
    bounded = bounded,
    status = rep("ok", 4L),
    message = rep("", 4L),
    elapsed = 1.23,
    threaded = FALSE,
    worker_threads = NA_integer_,
    julia_threads = NA_integer_,
    blas_threads = NA_integer_
  )
}

test_that("drm_julia_inference_confint_multi returns a 4-row data frame (profile)", {
  skip_if_not_installed("ape")
  fit <- drm_julia_biv_synthetic_fit()
  targets <- drmTMB:::drm_julia_profile_targets(fit)
  result <- drm_julia_biv_fake_result()

  ci <- drmTMB:::drm_julia_inference_confint_multi(
    targets = targets,
    result = result,
    level = 0.95,
    method = "profile"
  )

  expect_equal(nrow(ci), 4L)
  expect_true(is.data.frame(ci))
  expect_setequal(
    ci$parm,
    c(
      "sd:mu1:phylo(1 | species)",
      "sd:mu2:phylo(1 | species)",
      "sd:sigma1:phylo(1 | species)",
      "sd:sigma2:phylo(1 | species)"
    )
  )
  expect_true(all(ci$method == "profile"))
  expect_true(all(ci$scale == "response"))
  expect_true(all(ci$level == 0.95))
  # lower must be positive (exp of log lower * scale).
  expect_true(all(ci$lower > 0))
  # upper must be positive or Inf — never NA.
  expect_true(all(ci$upper > 0 | is.infinite(ci$upper)))
  expect_false(any(is.na(ci$upper)))
  # profile.engine should be set.
  expect_true(all(ci$profile.engine == "julia_profile_result"))
})

test_that("drm_julia_inference_confint_multi preserves Inf upper (flat axis)", {
  skip_if_not_installed("ape")
  fit <- drm_julia_biv_synthetic_fit()
  targets <- drmTMB:::drm_julia_profile_targets(fit)
  # Make the last axis's upper == Inf (bounded = FALSE).
  result <- drm_julia_biv_fake_result(
    uppers = c(2.4, 1.8, 1.2, Inf),
    bounded = c(TRUE, TRUE, TRUE, FALSE)
  )
  result$upper[[4L]] <- Inf

  ci <- drmTMB:::drm_julia_inference_confint_multi(
    targets = targets,
    result = result,
    level = 0.95,
    method = "profile"
  )

  # The fourth axis (sigma2) must have Inf upper, not NA.
  sigma2_row <- ci[grepl("sigma2", ci$parm), ]
  expect_equal(nrow(sigma2_row), 1L)
  expect_true(is.infinite(sigma2_row$upper))
  expect_false(is.na(sigma2_row$upper))
})

test_that("drm_julia_inference_confint_multi works for bootstrap (no bounded)", {
  skip_if_not_installed("ape")
  fit <- drm_julia_biv_synthetic_fit()
  targets <- drmTMB:::drm_julia_profile_targets(fit)
  result <- drm_julia_biv_fake_result(method = "bootstrap")
  result$bounded <- NULL  # bootstrap does not return bounded
  result$std_error <- c(0.3, 0.2, 0.15, 0.1)  # finite for bootstrap
  result$used <- 199L
  result$failed <- 0L

  ci <- drmTMB:::drm_julia_inference_confint_multi(
    targets = targets,
    result = result,
    level = 0.95,
    method = "bootstrap"
  )

  expect_equal(nrow(ci), 4L)
  expect_true(all(ci$method == "bootstrap"))
  # bootstrap-specific columns.
  expect_true("bootstrap.n" %in% names(ci))
  expect_true(all(ci$bootstrap.n == 199L))
  expect_true(all(ci$bootstrap.failed == 0L))
})
