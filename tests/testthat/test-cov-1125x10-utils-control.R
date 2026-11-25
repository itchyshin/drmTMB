# Coverage shard cursor-cloud-1125x10: utils.R and control.R internals.

test_that("internal %||% keeps only NULL as missing", {
  op <- drmTMB:::`%||%`
  expect_identical(NULL %||% 5, 5)
  expect_identical(NA %||% 5, NA)
  expect_identical(character() %||% "x", character())
  expect_identical(3 %||% 5, 3)
})

test_that("drm_suggest_closest_name returns prefix or adist matches", {
  choices <- c("sigma", "sigma1", "shape", "skew")
  expect_identical(
    drmTMB:::drm_suggest_closest_name("sig", choices),
    c("sigma", "sigma1")
  )
  expect_identical(
    drmTMB:::drm_suggest_closest_name("shap", choices),
    "shape"
  )
  expect_null(drmTMB:::drm_suggest_closest_name("zzz", choices))
  expect_null(drmTMB:::drm_suggest_closest_name("", choices))
  expect_null(drmTMB:::drm_suggest_closest_name(NA_character_, choices))
  expect_null(drmTMB:::drm_suggest_closest_name("x", character()))
})

test_that("drm_nlminb_control_names documents stats::nlminb keys", {
  nms <- drmTMB:::drm_nlminb_control_names()
  expect_true("iter.max" %in% nms)
  expect_true("eval.max" %in% nms)
  expect_true("maxiter" %in% nms)
  expect_true("rel.tol" %in% nms)
  expect_length(nms, 13L)
})

test_that("drm_optimizer_julia_bridge_names lists Julia-only controls", {
  julia <- drmTMB:::drm_optimizer_julia_bridge_names()
  expect_identical(julia, c("g_tol", "algorithm", "q4_vcov"))
})

test_that("drm_control_reserved_names blocks warm-start aliases", {
  reserved <- drmTMB:::drm_control_reserved_names()
  expect_true("se" %in% reserved)
  expect_true("keep_data" %in% reserved)
  expect_true("warm_start" %in% reserved)
  expect_true("multistart" %in% reserved)
  expect_false("optimizer" %in% reserved)
})

test_that("drm_control_validate_start enforces named finite scalars", {
  expect_null(drmTMB:::drm_control_validate_start(NULL))
  expect_identical(drmTMB:::drm_control_validate_start(list()), list())
  good <- list(`fixef:mu:(Intercept)` = 0.2)
  expect_identical(
    drmTMB:::drm_control_validate_start(good),
    good
  )
  expect_error(
    drmTMB:::drm_control_validate_start(c(1, 2)),
    "named list"
  )
  expect_error(
    drmTMB:::drm_control_validate_start(list(a = c(1, 2))),
    "single finite"
  )
  expect_error(
    drmTMB:::drm_control_validate_start(list("fixef:mu:(Intercept)" = Inf)),
    "single finite"
  )
})

test_that("drm_parse_control rejects reserved drm_control names in plain lists", {
  expect_error(
    drmTMB:::drm_parse_control(list(se = FALSE)),
    "reserved"
  )
  expect_error(
    drmTMB:::drm_parse_control(list(warm_start = TRUE)),
    "reserved"
  )
  ctl <- drmTMB:::drm_parse_control(list(eval.max = 200L))
  expect_s3_class(ctl, "drm_control")
})

test_that("drm_control_optimizer_preset returns budget presets", {
  expect_type(drmTMB:::drm_control_optimizer_preset("default"), "list")
  careful <- drmTMB:::drm_control_optimizer_preset("careful")
  expect_identical(careful$iter.max, 1000L)
  robust <- drmTMB:::drm_control_optimizer_preset("robust")
  expect_identical(robust$eval.max, 5000L)
})

test_that("drm_control_optim validates method-specific optimizer controls", {
  out <- drmTMB:::drm_control_optim(list(maxit = 50L), "BFGS")
  expect_identical(out$maxit, 50L)
  expect_error(
    drmTMB:::drm_control_optim(list(pg.tol = 1e-8), "BFGS"),
    "unsupported by"
  )
  expect_error(
    drmTMB:::drm_control_optim(list(fnscale = -1), "Nelder-Mead"),
    "fnscale"
  )
  expect_error(
    drmTMB:::drm_control_optim(list(foo = 1), "BFGS"),
    "unsupported by"
  )
  dup <- structure(list(1, 2), names = c("iter.max", "iter.max"))
  expect_error(
    drmTMB:::drm_control_optim(dup, "BFGS"),
    "must be unique"
  )
})

test_that("drm_sanitize_nlminb_controls warns on unknown nlminb keys", {
  sanitized <- drmTMB:::drm_sanitize_nlminb_controls(
    list(iter.max = 10L, itter.max = 5L)
  )
  expect_named(sanitized, "iter.max")
  expect_length(sanitized, 1L)
  expect_warning(
    drmTMB:::drm_sanitize_nlminb_controls(list(not_a_key = 1)),
    "Unknown"
  )
  julia_keys <- drmTMB:::drm_sanitize_nlminb_controls(
    list(g_tol = 1e-6, iter.max = 5L)
  )
  expect_true("g_tol" %in% names(julia_keys))
  expect_true("iter.max" %in% names(julia_keys))
})

test_that("drm_control_flag requires a scalar logical", {
  expect_true(drmTMB:::drm_control_flag(TRUE, "se"))
  expect_error(drmTMB:::drm_control_flag(NA, "se"), "TRUE")
  expect_error(drmTMB:::drm_control_flag(c(TRUE, FALSE), "se"), "TRUE")
})

test_that("drm_drop_model_frame_components clears model frames", {
  x <- list(model_frame = mtcars, model_frame_list = list(a = 1), keep = 1)
  y <- drmTMB:::drm_drop_model_frame_components(x)
  expect_null(y$model_frame)
  expect_null(y$model_frame_list)
  expect_identical(y$keep, 1)
  expect_identical(
    drmTMB:::drm_drop_model_frame_components("plain"),
    "plain"
  )
})

test_that("drm_apply_storage_control honours keep flags", {
  fit <- list(
    data = mtcars,
    model = list(data = mtcars, input_data = mtcars, model_frame = mtcars),
    obj = list(dummy = TRUE)
  )
  ctl <- drm_control(keep_data = FALSE, keep_model_frame = FALSE, keep_tmb_object = FALSE)
  trimmed <- drmTMB:::drm_apply_storage_control(fit, ctl)
  expect_null(trimmed$data)
  expect_null(trimmed$model$data)
  expect_null(trimmed$model$model_frame)
  expect_null(trimmed$obj)
})