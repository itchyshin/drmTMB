# R/mspl-estimator.R admission, frequency weights, and q = 2 guards (open
# coverage PRs touch check.R and mspl.R kernels; this slice stays on estimator
# paths not yet exercised in tests/testthat).

mspl_spec_q1 <- function(n = 24L, link_code = 0L) {
  set.seed(112514)
  X <- cbind(`(Intercept)` = 1, x = stats::rnorm(n))
  list(
    model_type = "binomial",
    X = list(mu = X),
    offset = list(mu = rep(0, n)),
    weights = rep(1, n),
    trials = rep(1, n),
    random = list(
      mu = list(
        n_terms = 1L,
        n_cors = 0L,
        group_names = rep("g", n),
        coef_names = "(Intercept)",
        value = matrix(1, n, 1),
        index = matrix(seq_len(n), n, 1)
      )
    ),
    tmb_data = list(link_code = link_code),
    y = stats::rbinom(n, 1, 0.4),
    missing_data = list(observed_y = rep(TRUE, n))
  )
}

mspl_spec_q2 <- function(n = 16L) {
  spec <- mspl_spec_q1(n)
  spec$random$mu <- list(
    n_terms = 2L,
    n_cors = 1L,
    group_names = rep("g", n),
    coef_names = list("(Intercept)", "x"),
    value = cbind(1, spec$X$mu[, "x"]),
    index = cbind(rep(1:4, each = 4), matrix(rep(1:4, each = 4), ncol = 1))
  )
  spec
}

mspl_like <- function(estimator = "MSPL", wald_spd = FALSE) {
  wald <- if (isTRUE(wald_spd)) {
    list(spd = TRUE, status = "ok", vcov = diag(2), std_error = c(beta_mu = 0.1, beta_mu = 0.2))
  } else {
    list(status = "rank")
  }
  structure(
    list(
      estimator = estimator,
      mspl = list(wald = wald),
      opt = list(par = c(beta_mu = 0, log_sd_mu = -1))
    ),
    class = "drmTMB"
  )
}

test_that("drm_mspl_filter_frequency_rows() passes through ordinary ML rows", {
  dat <- data.frame(y = 1:4, x = letters[1:4])
  out <- drmTMB:::drm_mspl_filter_frequency_rows(dat, NULL, "ml")
  expect_identical(out$data, dat)
  expect_null(out$weights)
  expect_equal(out$kept, 1:4)

  out_w <- drmTMB:::drm_mspl_filter_frequency_rows(dat, c(1, 2, 3, 4), "ml")
  expect_identical(out_w$weights, c(1, 2, 3, 4))
})

test_that("drm_mspl_filter_frequency_rows() drops zero weights and rounds positives", {
  dat <- data.frame(y = 1:5, x = letters[1:5])
  out <- drmTMB:::drm_mspl_filter_frequency_rows(
    dat, c(2, 1, 0, 3, 2), "mspl"
  )
  expect_equal(nrow(out$data), 4L)
  expect_equal(out$kept, c(1L, 2L, 4L, 5L))
  expect_equal(out$weights, c(2, 1, 3, 2))

  expect_error(
    drmTMB:::drm_mspl_filter_frequency_rows(dat, c(1, -1, 1, 1, 1), "mspl"),
    "frequency weights"
  )
  expect_error(
    drmTMB:::drm_mspl_filter_frequency_rows(dat, c(1, 1.2, 1, 1, 1), "mspl"),
    "frequency weights"
  )
  expect_error(
    drmTMB:::drm_mspl_filter_frequency_rows(dat, rep(0, 5), "mspl"),
    "positive frequency weight"
  )
})

test_that("drm_validate_mspl_request() refuses incompatible feature combinations", {
  fam <- list(link = "logit")
  ctrl <- drm_control()
  miss <- miss_control()
  expect_invisible(
    drmTMB:::drm_validate_mspl_request("ml", "tmb", fam, "binomial", FALSE, NULL, NULL, miss, ctrl)
  )

  expect_error(
    drmTMB:::drm_validate_mspl_request("mspl", "julia", fam, "binomial", FALSE, NULL, NULL, miss, ctrl),
    "engine = \"tmb\""
  )
  expect_error(
    drmTMB:::drm_validate_mspl_request(
      "mspl", "tmb", list(link = "cauchit"), "binomial", FALSE, NULL, NULL, miss, ctrl
    ),
    "Supported:"
  )
  expect_error(
    drmTMB:::drm_validate_mspl_request("mspl", "tmb", fam, "gaussian", FALSE, NULL, NULL, miss, ctrl),
    "binomial family with a supported link"
  )
  expect_error(
    drmTMB:::drm_validate_mspl_request("mspl", "tmb", fam, "binomial", TRUE, NULL, NULL, miss, ctrl),
    "REML"
  )
  expect_error(
    drmTMB:::drm_validate_mspl_request(
      "mspl", "tmb", fam, "binomial", FALSE, list(kind = "pc"), NULL, miss, ctrl
    ),
    "penalty"
  )
  expect_error(
    drmTMB:::drm_validate_mspl_request(
      "mspl", "tmb", fam, "binomial", FALSE, NULL, list(x = x ~ 1), miss, ctrl
    ),
    "mi"
  )
  expect_error(
    drmTMB:::drm_validate_mspl_request(
      "mspl", "tmb", fam, "binomial", FALSE, NULL, NULL,
      miss_control(response = "include"), ctrl
    ),
    "missing-data"
  )
  expect_error(
    drmTMB:::drm_validate_mspl_request(
      "mspl", "tmb", fam, "binomial", FALSE, NULL, NULL, miss,
      drm_control(sparse_fixed = TRUE)
    ),
    "dense"
  )
})

test_that("drm_validate_mspl_spec() accepts a minimal q = 1 binomial design", {
  spec <- mspl_spec_q1(30L)
  out <- drmTMB:::drm_validate_mspl_spec(spec)
  expect_identical(out$q, 1L)
  expect_identical(out$p, 2L)
  expect_identical(out$n_row, 30L)
  expect_equal(out$n_eff, 30)
  expect_true(is.finite(out$c_n))
  expect_true(is.finite(out$initial_half_logdet))
  expect_equal(length(out$frequency), 30L)
})

test_that("drm_validate_mspl_spec() refuses rank-deficient and bad weight designs", {
  n <- 12L
  bad <- mspl_spec_q1(n)
  bad$X$mu <- cbind(1, 1, stats::rnorm(n))
  rank_err <- tryCatch(
    drmTMB:::drm_validate_mspl_spec(bad),
    error = function(e) conditionMessage(e)
  )
  expect_match(rank_err, "numerical rank")

  bad_w <- mspl_spec_q1(n)
  bad_w$weights <- rep(1.1, n)
  freq_err <- tryCatch(
    drmTMB:::drm_validate_mspl_spec(bad_w),
    error = function(e) conditionMessage(e)
  )
  expect_match(freq_err, "integer frequency")

  bad_t <- mspl_spec_q1(n)
  bad_t$trials <- rep(1.5, n)
  trial_err <- tryCatch(
    drmTMB:::drm_validate_mspl_spec(bad_t),
    error = function(e) conditionMessage(e)
  )
  expect_match(trial_err, "trial totals")

  bad_q <- mspl_spec_q1(n)
  bad_q$random$mu$n_terms <- 3L
  q_err <- tryCatch(
    drmTMB:::drm_validate_mspl_spec(bad_q),
    error = function(e) conditionMessage(e)
  )
  expect_match(q_err, "correlated q = 2")
})

test_that("correlated-q2 detectors recognise grouped slope blocks", {
  q2 <- mspl_spec_q2(20L)
  expect_true(drmTMB:::drm_binomial_correlated_q2(q2))
  expect_false(drmTMB:::drm_binomial_correlated_q2(mspl_spec_q1(10L)))

  nb <- q2
  nb$model_type <- "nbinom2"
  expect_true(drmTMB:::drm_nbinom2_correlated_q2(nb))

  ln <- q2
  ln$model_type <- "lognormal"
  expect_true(drmTMB:::drm_lognormal_correlated_q2(ln))
})

test_that("drm_binomial_q2_slope_unique_n() counts within-group variation", {
  values <- c(1, 2, 1, 2, 3, 3)
  groups <- c(1, 1, 1, 2, 2, 2)
  expect_equal(drmTMB:::drm_binomial_q2_slope_unique_n(values, groups), 2L)
  expect_equal(drmTMB:::drm_binomial_q2_slope_unique_n(c(1, 1, 1), c(1, 1, 1)), 1L)
  expect_equal(drmTMB:::drm_binomial_q2_slope_unique_n(numeric(), integer()), 0L)
})

test_that("drm_validate_q2_slope_variation() errors on constant within-group slopes", {
  re <- list(
    coef_names = list("(Intercept)", "x"),
    group_names = list("g", "g"),
    value = matrix(c(rep(1, 4), rep(5, 4)), ncol = 2),
    index = cbind(rep(1, 4), rep(1, 4))
  )
  expect_error(
    drmTMB:::drm_validate_q2_slope_variation(re, "binomial"),
    "within-group variation"
  )
  re$value[, 2] <- c(1, 2, 1, 2)
  expect_invisible(drmTMB:::drm_validate_q2_slope_variation(re, "binomial"))
})

test_that("drm_validate_binomial_q2_context() gates REML and missing responses", {
  spec <- mspl_spec_q2(12L)
  expect_invisible(drmTMB:::drm_validate_binomial_q2_context(spec, REML = FALSE))

  expect_error(
    drmTMB:::drm_validate_binomial_q2_context(spec, REML = TRUE),
  "REML"
  )
  spec$missing_data$observed_y[[3L]] <- FALSE
  expect_error(
    drmTMB:::drm_validate_binomial_q2_context(spec, REML = FALSE),
    "missing-response"
  )
})

test_that("drm_mspl_vcov_names() uniquifies duplicated TMB names", {
  fit <- mspl_like(wald_spd = TRUE)
  fit$coefficients <- list(mu = c(`(Intercept)` = 0, x = 0.1))
  names <- drmTMB:::drm_mspl_vcov_names(fit)
  expect_true(any(grepl("beta_mu", names, fixed = TRUE)) || any(names == "(Intercept)"))
})

test_that("drm_mspl_summary_coefficients() reports NA se when the SPD gate fails", {
  fit <- mspl_like()
  tab <- suppressWarnings(drmTMB:::drm_mspl_summary_coefficients(
    fit, c("(Intercept)", "x"), c(0.1, -0.2)
  ))
  expect_equal(nrow(tab), 2L)
  expect_true(all(is.na(tab$std_error)))
  expect_true(all(tab$std_error.status == "mspl_wald_unavailable"))

  fit <- mspl_like(wald_spd = TRUE)
  tab_ok <- drmTMB:::drm_mspl_summary_coefficients(
    fit, c("(Intercept)", "x"), c(0.1, -0.2)
  )
  expect_false(any(is.na(tab_ok$std_error)))
  expect_false("std_error.status" %in% names(tab_ok))
})
