# Coverage top-up for R/[g-o]*.R (Cursor cloud, 27 Nov 2026).
# Exercises user-facing contracts and named error branches without fits
# where possible, so runtime stays modest.

test_that("meta_vcov_bivariate() rejects contradictory and mismatched inputs", {
  expect_error(
    meta_vcov_bivariate(v1 = 1, v2 = 1, cov12 = 0, cor12 = 0),
    "only one of"
  )
  expect_error(
    meta_vcov_bivariate(v1 = c(1, 2), v2 = 1),
    "same length"
  )
  expect_error(
    meta_vcov_bivariate(v1 = 1, v2 = 4, cor12 = 1),
    "positive definite"
  )
  expect_error(
    meta_vcov_bivariate(v1 = 1, v2 = 4, cor12 = -1),
    "positive definite"
  )
})

test_that("drm_eval_call_weights() reads scalar and per-row weights from the call", {
  env <- new.env(parent = emptyenv())
  dat <- data.frame(y = 1:3, w = c(1, 2, 1))
  no_w <- drmTMB:::drm_eval_call_weights(quote(drmTMB(y ~ x)), dat, env)
  expect_null(no_w)
  scalar <- drmTMB:::drm_eval_call_weights(
    quote(drmTMB(y ~ x, weights = 2)),
    dat,
    env
  )
  expect_identical(scalar, 2)
  per_row <- drmTMB:::drm_eval_call_weights(
    quote(drmTMB(y ~ x, weights = w)),
    dat,
    env
  )
  expect_equal(per_row, dat$w)
  expect_error(
    drmTMB:::drm_eval_call_weights(
      quote(drmTMB(y ~ x, weights = bad_symbol)),
      dat,
      env
    ),
    "bad_symbol"
  )
})

test_that("drm_julia_call_joint() refuses when JuliaCall is not installed", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (identical(pkg, "JuliaCall")) {
        return(FALSE)
      }
      base::requireNamespace(pkg, ...)
    },
    .package = "base"
  )
  expect_error(
    drmTMB:::drm_julia_call_joint(list(schema = "joint")),
    "JuliaCall"
  )
})

test_that("drmTMB_julia_joint_bridge() surfaces preparation failures", {
  local_mocked_bindings(
    drm_eval_call_weights = function(...) NULL,
    drm_abort_julia_mi_nonunit_weights = function(...) invisible(FALSE),
    drm_weights_are_unit = function(...) TRUE,
    drm_julia_joint_prepare = function(...) {
      stop("prep failed", call. = FALSE)
    }
  )
  expect_error(
    drmTMB:::drmTMB_julia_joint_bridge(
      formula = NULL,
      family = gaussian(),
      data = data.frame(y = 1),
      env = parent.frame(),
      weights_missing = TRUE,
      control = drm_control(),
      impute = NULL,
      missing = NULL,
      call = quote(drmTMB(y ~ 1))
    ),
    "Could not prepare the Julia joint"
  )
})

test_that("print.drm_lrt_boundary() reports a negative statistic note", {
  neg <- structure(
    list(
      statistic = -0.01,
      q = 1L,
      pvalue = 0.5,
      pvalue_naive = 1,
      df = 1
    ),
    class = "drm_lrt_boundary"
  )
  txt <- paste(capture.output(print(neg)), collapse = "\n")
  expect_match(txt, "negative statistic", fixed = TRUE)
  expect_match(txt, "chi-bar-square", fixed = TRUE)
})

test_that("drm_mi_quadrature accuracy helpers warn on boundary Beta means", {
  mp <- list(
    enabled = TRUE,
    family = "beta",
    variable = "x",
    X = matrix(1, 3L, 1L),
    missing_index = 1:3
  )
  par <- list(beta_mi = qlogis(0.05), log_sigma_mi = 0)
  hits <- drmTMB:::drm_mi_quadrature_inaccurate_hits(mp, par, slot = 1L)
  expect_length(hits, 1L)
  expect_match(hits[[1L]], "0\\.05")
  expect_warning(
    drmTMB:::drm_warn_mi_quadrature_inaccurate(
      list(missing_predictor = mp),
      par
    ),
    class = "drmTMB_mi_quadrature_inaccurate"
  )
  gamma_mp <- list(
    enabled = TRUE,
    family = "gamma",
    variable = "z",
    X = matrix(1, 1L, 1L),
    missing_index = 1L
  )
  gamma_par <- list(log_sigma_mi = log(3.5))
  gamma_hits <- drmTMB:::drm_mi_quadrature_inaccurate_hits(
    gamma_mp,
    gamma_par,
    slot = 1L
  )
  expect_match(gamma_hits[[1L]], "CV 3\\.5")
})

test_that("drm_probe_mi_quadrature_objective() validates finite values", {
  par <- c(b = 0, a = 0)
  good <- list(
    fn = function(p) 12.5,
    gr = function(p) c(0, 0)
  )
  expect_equal(
    drmTMB:::drm_probe_mi_quadrature_objective(good, par, "probe"),
    12.5
  )
  bad_fn <- list(
    fn = function(p) NaN,
    gr = function(p) c(0, 0)
  )
  expect_error(
    drmTMB:::drm_probe_mi_quadrature_objective(bad_fn, par, "probe"),
    class = "drmTMB_mi_quadrature_nonfinite"
  )
  bad_gr <- list(
    fn = function(p) 1,
    gr = function(p) c(NA_real_, 0)
  )
  expect_error(
    drmTMB:::drm_probe_mi_quadrature_objective(bad_gr, par, "probe"),
    "gradient"
  )
})

test_that("drm_gaussian_aggregation_parity() uses the large-intercept default for wide means", {
  set.seed(1127)
  n <- 12L
  y <- stats::rnorm(n, mean = 1e5, sd = 1)
  X <- cbind(intercept = 1, x = rep(c(0, 1), each = n / 2L))
  Xs <- cbind(intercept = rep(1, n))
  out <- drmTMB:::drm_gaussian_aggregation_parity(y, X, Xs)
  expect_lt(abs(out$difference), 1e-6)
  expect_true(is.finite(out$aggregated_loglik))
})

test_that("objective_at() requires a retained TMB object", {
  dat <- data.frame(y = stats::rnorm(8), x = stats::rnorm(8))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE, keep_tmb_object = FALSE)
  )
  expect_error(
    objective_at(fit, at = list("fixef:mu:(Intercept)" = 0)),
    "keep_tmb_object"
  )
})

test_that(".drm_mesh_coordinates() rejects collinear planar inputs", {
  collinear <- cbind(x = c(0, 1, 2), y = c(0, 2, 4))
  expect_error(
    drmTMB:::.drm_mesh_coordinates(collinear),
    "two dimensions"
  )
})