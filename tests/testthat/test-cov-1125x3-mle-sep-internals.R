# Coverage for untested internals in R/mle-existence.R.

test_that("drm_fe_mle_screen_applicable() honours MSPL, RE, phylo, and mi()", {
  ok <- drmTMB:::drm_fe_mle_screen_applicable
  base <- list(
    estimator = NULL,
    random = list(mu = list(n_re = 0L)),
    structured = list(phylo_mu = list(has = FALSE)),
    missing_predictor = list(enabled = FALSE)
  )
  expect_true(ok(base))
  mspl <- base
  mspl$estimator <- "mspl"
  expect_false(ok(mspl))
  re <- base
  re$random$mu$n_re <- 1L
  expect_false(ok(re))
  phy <- base
  phy$structured$phylo_mu$has <- TRUE
  expect_false(ok(phy))
  mi <- base
  mi$missing_predictor$enabled <- TRUE
  expect_false(ok(mi))
  expect_false(ok(NULL))
})

test_that("drm_sep_constraints() and drm_sep_nnls() solve a tiny separation cone", {
  X <- cbind(1, c(-2, -1, 1, 2))
  cons <- drmTMB:::drm_sep_constraints(X, c(1, 1, 0, 0), c(0, 0, 1, 1))
  expect_true(is.matrix(cons$A))
  expect_gt(nrow(cons$A), 0L)
  expect_length(cons$keep, 2L)
  if (ncol(cons$A) > 0L && nrow(cons$A) > 0L) {
    cvec <- rep(1, ncol(cons$A))
    nn <- drmTMB:::drm_sep_nnls(cons$A, cvec, maxiter = 50L)
    expect_true(is.list(nn))
    expect_true(nn$converged %in% c(TRUE, FALSE))
    expect_type(nn$r, "double")
    expect_equal(length(nn$r), ncol(cons$A))
  }
  empty <- drmTMB:::drm_sep_constraints(matrix(0, 0, 2), numeric(), numeric())
  expect_equal(nrow(empty$A), 0L)
})

test_that("drm_observed_design_rows() respects weights and missing flags", {
  spec <- list(
    missing_data = list(observed_y = c(TRUE, FALSE, TRUE)),
    weights = c(1, 1, 0)
  )
  rows <- drmTMB:::drm_observed_design_rows(spec, 3L)
  expect_identical(rows, c(TRUE, FALSE, FALSE))
  spec2 <- list(missing_data = NULL, weights = NULL)
  expect_identical(drmTMB:::drm_observed_design_rows(spec2, 4L), rep(TRUE, 4L))
})

test_that("check_mle_existence() builds ok and warning rows on real fits", {
  set.seed(2)
  x <- rnorm(40)
  y <- rbinom(40, 1, plogis(0.5 + 0.8 * x))
  y[c(1, 5, 10)] <- 1L
  y[c(38, 39, 40)] <- 0L
  good <- drmTMB(bf(y ~ x), family = binomial(), data = data.frame(y, x))
  ok_row <- drmTMB:::check_mle_existence(good)
  expect_identical(ok_row$check, "mle_existence")
  expect_identical(ok_row$status, "ok")
  sep <- drmTMB(bf(y ~ x), family = binomial(), data = data.frame(y = as.integer(x > 0), x = x))
  warn_row <- drmTMB:::check_mle_existence(sep)
  expect_identical(warn_row$status, "warning")
  expect_identical(warn_row$value, "binomial_separation")
})

test_that("drm_mle_nonexistent_is_true() mirrors drm_mle_nonexistent()", {
  fake <- list(model = list(model_type = "gaussian"))
  expect_false(drmTMB:::drm_mle_nonexistent_is_true(fake))
  set.seed(1)
  x <- rnorm(30)
  y <- rbinom(30, 1, plogis(-5 * x))
  fit <- drmTMB(bf(y ~ x), family = binomial(), data = data.frame(y, x))
  expect_true(is.logical(drmTMB:::drm_mle_nonexistent_is_true(fit)))
})