test_that("validate_check_scalar enforces one finite value inside bounds", {
  expect_equal(
    drmTMB:::validate_check_scalar(0.25, "tolerance", lower = 0, upper = 1),
    0.25
  )
  expect_error(
    drmTMB:::validate_check_scalar(c(0.1, 0.2), "tolerance"),
    "finite numeric scalar"
  )
  expect_error(
    drmTMB:::validate_check_scalar(NA_real_, "tolerance"),
    "finite numeric scalar"
  )
  expect_error(
    drmTMB:::validate_check_scalar(0, "tolerance", lower = 0, upper = 1),
    "between"
  )
})

test_that("check_penalized_fit records fixed-effect and SD prior runs", {
  d <- data.frame(
    x = rep(c(-1, 0, 1), 4),
    site = factor(rep(1:4, each = 3)),
    y = 0.3 + 0.5 * rep(c(-1, 0, 1), 4) + rep(c(0.1, -0.2, 0.15, -0.05), each = 3)
  )
  priors <- drm_priors(
    drm_prior_sd_gamma(group = "site", shape = 2.5, rate = 1.7)
  )
  fit <- suppressWarnings(
    drmTMB(bf(y ~ x + (1 | site), sigma ~ 1), data = d, family = gaussian(), priors = priors)
  )
  row <- drmTMB:::check_penalized_fit(fit)
  expect_equal(row$check, "penalized_map")
  expect_equal(row$status, "note")
  expect_match(row$message, "penalized objective", fixed = TRUE)
})

test_that("check_penalized_fit records phylogenetic MAP fits", {
  fit <- list(penalty = list(component = "phylo"))
  row <- drmTMB:::check_penalized_fit(fit)
  expect_equal(row$check, "penalized_map")
  expect_match(row$message, "penalized / maximum-a-posteriori", fixed = TRUE)
})

test_that("check_dropped_rows reports when row filters were not stored", {
  fit <- list(model = list(keep = NULL))
  row <- drmTMB:::check_dropped_rows(fit)
  expect_equal(row$check, "dropped_rows")
  expect_match(row$message, "not stored", fixed = TRUE)
})

test_that("check_known_v summarises diagonal meta_V", {
  dat <- data.frame(
    yi = c(0.12, 0.21, 0.09),
    x = c(-1, 0, 1),
    vi = c(0.04, 0.09, 0.16)
  )
  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = vi)),
    data = dat,
    family = gaussian()
  )
  row <- drmTMB:::check_known_v(fit)
  expect_equal(row$check, "known_sampling_covariance")
  expect_equal(row$status, "ok")
  expect_match(row$value, "type=diagonal", fixed = TRUE)
})

test_that("check_known_v flags negative known variances", {
  fit <- list(
    model = list(
      has_known_v = TRUE,
      V_known_type = "diagonal",
      V_known = c(0.04, -0.01)
    )
  )
  testthat::local_mocked_bindings(
    known_v_diag = function(object) object$model$V_known,
    .package = "drmTMB"
  )
  row <- drmTMB:::check_known_v(fit)
  expect_equal(row$status, "error")
  expect_match(row$message, "non-finite or negative", fixed = TRUE)
})