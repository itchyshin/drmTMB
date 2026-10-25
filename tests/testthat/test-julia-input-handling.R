# Regression tests for the Julia-engine input gates (#1450, #1471, #1483).
# None of these tests install Julia. A gate that should open is asserted by
# stopping at the pre-dispatch requirement that sits after the weights and
# control checks: missing JuliaCall, or a JuliaCall install with no
# DRModels.jl checkout. A gate that should stay closed errors first.

julia_input_dat <- function() {
  data.frame(y = c(0.2, -0.4, 0.1, 0.8, -0.2, 0.3), x = 1:6)
}

julia_gate_message <- function(expr) {
  tryCatch(
    {
      force(expr)
      "NO_ERROR"
    },
    error = function(e) conditionMessage(e)
  )
}

# The open gate must get past weights and control and stop before a Julia
# process starts. CI installs the suggested JuliaCall package and then stops
# on the missing checkout; a machine without that package stops one step earlier.
expect_pre_julia_dispatch <- function(message) {
  expect_false(grepl("NO_ERROR", message, fixed = TRUE))
  expect_match(message, "JuliaCall|DRModels\\.jl")
}

test_that("the Julia bridge null-coalesce operator is defined", {
  # Formula marshalling calls `%||%` before JuliaCall. Without a definition
  # the weights and control gates cannot be observed at dispatch.
  expect_identical(NULL %||% 1L, 1L)
  expect_identical(2L %||% 1L, 2L)
  expect_identical(list() %||% NULL, list())
})

test_that("engine = julia accepts weights = NULL and still refuses a weight vector (#1450)", {
  dat <- julia_input_dat()
  # The entry point must read the value. `missing(weights)` is what refused NULL.
  body_text <- paste(deparse(body(drmTMB), width.cutoff = 500L), collapse = " ")
  expect_true(grepl(
    "weights_missing = drm_julia_weights_absent(",
    body_text,
    fixed = TRUE
  ))
  expect_false(grepl(
    "weights_missing = base::missing(weights)",
    body_text,
    fixed = TRUE
  ))

  expect_true(drm_julia_weights_absent(NULL))
  expect_true(drm_julia_weights_absent())
  expect_false(drm_julia_weights_absent(c(1, 1)))
  # An expression that cannot be evaluated is still "weights were supplied".
  expect_false(drm_julia_weights_absent(no_such_julia_weight_object))

  wrapper <- function(formula, data, weights = NULL, engine = "tmb") {
    drmTMB(formula, data = data, weights = weights, engine = engine)
  }

  # Literal NULL and a wrapper that forwards NULL both pass the weights gate.
  for (expr in list(
    quote(drmTMB(
      bf(y ~ x, sigma ~ 1), data = dat, engine = "julia", weights = NULL
    )),
    quote(wrapper(bf(y ~ x, sigma ~ 1), data = dat, engine = "julia"))
  )) {
    message <- julia_gate_message(eval(expr))
    expect_false(grepl("weights", message, fixed = TRUE))
    expect_pre_julia_dispatch(message)
  }

  # A real weight vector is refused before Julia is loaded. The same flag
  # feeds the ordinary, structured, bivariate q2, cross-family, and joint
  # routes, so this refusal is the shared gate.
  message <- julia_gate_message(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      engine = "julia",
      weights = rep(1, nrow(dat))
    )
  )
  expect_match(message, "does not support")
  expect_match(message, "weights")
  expect_false(grepl("JuliaCall", message, fixed = TRUE))

  # A data column wins over a same-named NULL in the caller. Native evaluation
  # uses that column; the Julia gate must refuse it rather than fit unweighted.
  dat_w <- dat
  dat_w$w <- rep(1, nrow(dat_w))
  w <- NULL
  native_w <- evaluate_likelihood_weights_arg(
    weights_expr = quote(w),
    data = dat_w,
    env = environment()
  )
  expect_equal(native_w, dat_w$w)
  expect_false(drm_julia_weights_absent(quote(w), data = dat_w, env = environment()))
  message <- julia_gate_message(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat_w,
      engine = "julia",
      weights = w
    )
  )
  expect_match(message, "does not support")
  expect_match(message, "weights")
  expect_false(grepl("JuliaCall", message, fixed = TRUE))
  expect_false(grepl("DRModels", message, fixed = TRUE))

  # The same symbol with no column evaluates to NULL and means no weights.
  message <- julia_gate_message(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      engine = "julia",
      weights = w
    )
  )
  expect_false(grepl("does not support", message, fixed = TRUE))
  expect_pre_julia_dispatch(message)

  message <- julia_gate_message(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      engine = "julia",
      weights = no_such_julia_weight_object
    )
  )
  expect_match(message, "weights")
  expect_false(grepl("JuliaCall", message, fixed = TRUE))
})

test_that("engine = julia accepts type-equivalent control defaults (#1471)", {
  defaults <- list(
    margin_integer = drm_control(logsigma_clamp_margin = 3L),
    clamp_integer = drm_control(logsigma_clamp = c(-12L, 12L)),
    empty_start = drm_control(start = list())
  )
  for (ctrl in defaults) {
    expect_equal(drm_julia_translate_control(ctrl), list())
    expect_true(drm_julia_default_control(ctrl))
    expect_true(drm_julia_joint_default_control(ctrl))
    expect_equal(drm_julia_nondefault_control_fields(ctrl), character())
  }

  # The double-stored defaults stay accepted, and a real change still refuses
  # on every gate that used to call identical().
  expect_equal(
    drm_julia_translate_control(drm_control(logsigma_clamp_margin = 3)),
    list()
  )
  expect_error(
    drm_julia_translate_control(drm_control(logsigma_clamp_margin = 4L)),
    "logsigma_clamp_margin",
    fixed = TRUE
  )
  expect_error(
    drm_julia_translate_control(drm_control(logsigma_clamp = c(-20L, 20L))),
    "logsigma_clamp",
    fixed = TRUE
  )
  expect_error(
    drm_julia_translate_control(
      drm_control(start = list(`fixef:mu:(Intercept)` = 0.5))
    ),
    "start",
    fixed = TRUE
  )
  expect_false(drm_julia_default_control(drm_control(logsigma_clamp_margin = 4L)))
  expect_false(
    drm_julia_joint_default_control(drm_control(start = list(`fixef:mu:(Intercept)` = 0)))
  )
  expect_equal(
    drm_julia_nondefault_control_fields(drm_control(logsigma_clamp_margin = 4L)),
    "logsigma_clamp_margin"
  )

  # The public entry reaches JuliaCall instead of naming an unchanged setting.
  dat <- julia_input_dat()
  for (ctrl in defaults) {
    message <- julia_gate_message(
      drmTMB(bf(y ~ x, sigma ~ 1), data = dat, engine = "julia", control = ctrl)
    )
    expect_false(grepl("does not support", message, fixed = TRUE))
    expect_pre_julia_dispatch(message)
  }
  message <- julia_gate_message(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      engine = "julia",
      control = drm_control(logsigma_clamp_margin = 4L)
    )
  )
  expect_match(message, "logsigma_clamp_margin")
  expect_false(grepl("JuliaCall", message, fixed = TRUE))
})

julia_input_fit <- function(class, convergence = 0L, vcov = NULL) {
  structure(
    list(opt = list(convergence = convergence), vcov = vcov),
    class = class
  )
}

test_that("is_converged(include_hessian) reads the Julia covariance (#1483)", {
  pd <- matrix(c(2, 0.1, 0.1, 1), 2, 2)
  bad <- matrix(c(1, 0, 0, -1), 2, 2)
  classes <- list(
    julia = "drmTMB_julia",
    joint = c("drmTMB_julia_joint", "drmTMB_julia"),
    xfam = c("drmTMB_julia_xfam", "drmTMB_julia")
  )
  for (class in classes) {
    fit <- julia_input_fit(class, vcov = pd)
    expect_true(is_converged(fit))
    expect_true(is_converged(fit, include_hessian = FALSE))
    expect_true(is_converged(fit, include_hessian = TRUE))

    indefinite <- julia_input_fit(class, vcov = bad)
    expect_true(is_converged(indefinite))
    expect_false(is_converged(indefinite, include_hessian = TRUE))

    missing_vcov <- julia_input_fit(class, vcov = NULL)
    expect_true(is_converged(missing_vcov))
    expect_false(is_converged(missing_vcov, include_hessian = TRUE))

    nonfinite <- julia_input_fit(class, vcov = matrix(c(1, NA, NA, 1), 2, 2))
    expect_false(is_converged(nonfinite, include_hessian = TRUE))

    stopped <- julia_input_fit(class, convergence = 1L, vcov = pd)
    expect_false(is_converged(stopped))
    expect_false(is_converged(stopped, include_hessian = TRUE))

    expect_error(is_converged(fit, include_hessian = "x"), "include_hessian")
    expect_error(is_converged(fit, include_hessian = NA), "include_hessian")
    expect_error(is_converged(fit, include_hessian = c(TRUE, FALSE)), "include_hessian")
    expect_error(is_converged(fit, unknown_option = TRUE), "reserved")
  }
})
