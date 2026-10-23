# Fixed-effect inference for the univariate general-covariance Julia bridge.
#
# The point-fit route already supplies its one covariance provider as K, A, or
# coords. These tests require the stored payload and fixed-effect inference
# refit to preserve that provider without starting Julia.

drm_julia_structured_inference_result <- function(n) {
  list(
    coef_names = c("mu_(Intercept)", "mu_x", "sigma_(Intercept)"),
    coefficients = c(0.2, 0.4, -0.1),
    vcov = diag(c(0.04, 0.01, 0.02)),
    loglik = -12.5,
    aic = 31,
    bic = 34,
    df = 3L,
    nobs = as.integer(n),
    converged = TRUE,
    fitted = rep(0, n),
    conditional_re = NULL,
    residuals = rep(0, n),
    sigma = exp(-0.1),
    corpairs = list()
  )
}

drm_julia_structured_inference_case <- function(provider) {
  dat <- data.frame(
    id = rep(c("a", "b", "c"), each = 2L),
    x = c(-1, 0, 1, -1, 0, 1),
    y = c(0.2, 0.5, 1.1, 0.4, 0.8, 1.3)
  )
  K <- matrix(c(1, 0.2, 0.1, 0.2, 1, 0.3, 0.1, 0.3, 1), 3, 3)
  A <- matrix(c(1, 0.4, 0.2, 0.4, 1, 0.5, 0.2, 0.5, 1), 3, 3)
  coords <- data.frame(
    east = c(0, 1, 0),
    north = c(0, 0, 1),
    row.names = c("a", "b", "c")
  )
  form <- switch(
    provider,
    relmat = drmTMB::bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
    animal = drmTMB::bf(y ~ x + animal(1 | id, A = A), sigma ~ 1),
    spatial = drmTMB::bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1)
  )
  payload <- drmTMB:::drm_julia_structured_payload(
    formula = form,
    family_type = "gaussian",
    data = dat,
    env = environment()
  )
  list(form = form, data = dat, payload = payload, env = environment())
}

drm_julia_structured_inference_object <- function(case) {
  drmTMB:::new_drmTMB_julia(
    result = drm_julia_structured_inference_result(nrow(case$data)),
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = case$form,
    family = stats::gaussian(),
    data = case$data,
    family_type = "gaussian",
    structured_sd_scales = case$payload$structured_sd_scales,
    bridge_payload = case$payload
  )
}

test_that("univariate structured fits retain the point-fit provider payload", {
  case <- drm_julia_structured_inference_case("relmat")
  testthat::local_mocked_bindings(
    drm_julia_call_structured = function(...) {
      drm_julia_structured_inference_result(nrow(case$data))
    },
    .package = "drmTMB"
  )

  fit <- drmTMB:::drmTMB_julia_structured_bridge(
    formula = case$form,
    family = stats::gaussian(),
    data = case$data,
    env = case$env,
    weights_missing = TRUE,
    control = NULL,
    impute = NULL,
    missing = list(),
    call = quote(drmTMB(form, data = dat, engine = "julia"))
  )

  expect_identical(fit$bridge_payload$kwarg, "K")
  expect_identical(fit$bridge_payload$matrix, case$payload$matrix)
  targets <- drmTMB:::drm_julia_wald_targets(fit)
  expect_true(all(targets$profile_ready))
})

test_that("structured providers reach fixed-effect profile and bootstrap refits", {
  skip_if_not_installed("JuliaCall")

  captured <- list()
  testthat::local_mocked_bindings(
    drm_julia_setup = function(...) invisible(TRUE),
    .package = "drmTMB"
  )
  testthat::local_mocked_bindings(
    julia_call = function(...) {
      args <- list(...)
      captured[[length(captured) + 1L]] <<- args
      method <- args[[10L]]
      list(
        lower = 0.1,
        upper = 0.7,
        status = method,
        message = "mocked structured inference",
        threaded = FALSE,
        worker_threads = 1L,
        julia_threads = 1L,
        blas_threads = 1L,
        elapsed = 0.01,
        used = 2L,
        failed = 0L
      )
    },
    .package = "JuliaCall"
  )

  for (provider in c("relmat", "animal", "spatial")) {
    case <- drm_julia_structured_inference_case(provider)
    fit <- drm_julia_structured_inference_object(case)
    expected_K <- if (identical(case$payload$kwarg, "K")) case$payload$matrix else NULL
    expected_A <- if (identical(case$payload$kwarg, "A")) case$payload$matrix else NULL
    expected_coords <- if (identical(case$payload$kwarg, "coords")) case$payload$matrix else NULL

    for (method in c("profile", "bootstrap")) {
      ci <- stats::confint(
        fit,
        parm = "fixef:mu:x",
        method = method,
        R = 2L,
        seed = 4001L
      )
      sent <- captured[[length(captured)]]
      expect_identical(sent[[1L]], "drmTMB_drm_bridge_fixef_inference")
      expect_identical(sent[[5L]], NULL)
      expect_identical(sent[[6L]], expected_K)
      expect_identical(sent[[7L]], expected_A)
      expect_identical(sent[[8L]], expected_coords)
      expect_identical(sent[[10L]], method)
      expect_identical(ci$method, method)
    }

    if (identical(provider, "spatial")) {
      expect_identical(case$payload$kwarg, "K")
      expect_match(case$payload$formula$mu, "relmat(1 | id)", fixed = TRUE)
    }
  }
})

test_that("generated bootstrap refits retain every structured provider", {
  setup_source <- paste(deparse(body(drmTMB:::drm_julia_setup)), collapse = "\n")
  forwarded <- "tree = tree_obj, K = K, A = A, coords = coords, threads = threads"

  expect_identical(
    length(gregexpr(forwarded, setup_source, fixed = TRUE)[[1L]]),
    2L
  )
})
