# R/temporal.R helpers beyond test-temporal-lag-witnesses.R / homtoep stability.

test_that("empty_temporal_mu_structure() documents the disabled layout", {
  e <- drmTMB:::empty_temporal_mu_structure()
  expect_false(e$has)
  expect_identical(e$type, "temporal")
  expect_identical(e$n_series, 0L)
  expect_identical(e$n_re, 0L)
  expect_length(e$series_levels, 0L)
  expect_identical(e$observation_node_index0, 0L)
})

test_that("temporal_structure_name() formats AR1 and HOMTOEP labels", {
  ar1 <- list(structure = "ar1")
  hom <- list(structure = "homtoep")
  expect_equal(drmTMB:::temporal_structure_name(ar1), "Temporal AR1")
  expect_equal(drmTMB:::temporal_structure_name(hom), "Temporal HOMTOEP")
})

test_that("validate_temporal_raw_data() validates ids, times, and duplicate keys", {
  term <- list(group = "id", time = "t", structure = "ar1")
  good <- data.frame(id = c("a", "a", "b"), t = c(1, 2, 1))
  expect_invisible(drmTMB:::validate_temporal_raw_data(term, good))

  expect_error(
    drmTMB:::validate_temporal_raw_data(term, data.frame(wrong = 1)),
    "Missing temporal column"
  )
  bad_na <- good
  bad_na$t[[2L]] <- NA_real_
  expect_error(drmTMB:::validate_temporal_raw_data(term, bad_na), "must be complete")

  frac <- good
  frac$t[[2L]] <- 1.5
  expect_error(drmTMB:::validate_temporal_raw_data(term, frac), "finite integers")

  dup <- data.frame(id = c("a", "a"), t = c(1, 1))
  expect_error(drmTMB:::validate_temporal_raw_data(term, dup), "unique")
})

test_that("temporal_homtoep_levinson() builds lag correlations and AR coefficients", {
  theta <- c(0.2, -0.1)
  lev <- drmTMB:::temporal_homtoep_levinson(theta)
  expect_equal(lev$rho[[1L]], 1)
  expect_equal(length(lev$rho), length(theta) + 1L)
  expect_equal(nrow(lev$ar), length(theta) + 1L)
  expect_true(all(is.finite(lev$log_v)))

  zero <- drmTMB:::temporal_homtoep_levinson(numeric())
  expect_equal(zero$rho, 1)
  expect_equal(drmTMB:::temporal_homtoep_correlations(theta), lev$rho)
})

test_that("temporal_homtoep_levinson() stays stable for large reflection parameters", {
  theta <- c(5, -5, 3)
  lev <- drmTMB:::temporal_homtoep_levinson(theta)
  expect_true(all(abs(lev$rho) <= 1 + sqrt(.Machine$double.eps)))
  expect_true(all(is.finite(lev$log_v)))
})
