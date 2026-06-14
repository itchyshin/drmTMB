# Translation-only tests for the engine = "julia" optimizer-control passthrough.
# These exercise the R-side control translator and option builder ONLY; they do
# not call JuliaCall, start Julia, or fit a model.

test_that("default drm_control() yields no Julia optimizer overrides", {
  expect_equal(drm_julia_translate_control(drm_control()), list())
  expect_equal(drm_julia_translate_control(NULL), list())
  expect_equal(drm_julia_translate_control(list()), list())
})

test_that("default control leaves each route's option payload unchanged", {
  # Fixed-effect Gaussian: empty payload (DRM.jl's own g_tol default).
  expect_equal(
    drm_julia_bridge_options(NULL, control_overrides = list()),
    list()
  )
  # Sparse all-node phylo: the parity-tested 1e-4 default.
  expect_equal(
    drm_julia_bridge_options(
      list(bivariate = FALSE),
      control_overrides = list()
    ),
    list(g_tol = 1e-4)
  )
  # Bivariate q=4 PLSM: DRM.jl defaults (empty payload).
  expect_equal(
    drm_julia_bridge_options(
      list(bivariate = TRUE),
      control_overrides = list()
    ),
    list()
  )
})

test_that("tuned drm_control() forwards g_tol and algorithm", {
  overrides <- drm_julia_translate_control(
    drm_control(optimizer = list(g_tol = 1e-6, algorithm = "lbfgs"))
  )
  expect_equal(overrides, list(g_tol = 1e-6, algorithm = "lbfgs"))

  # The user g_tol replaces the sparse-phylo 1e-4 default; algorithm is added.
  expect_equal(
    drm_julia_bridge_options(
      list(bivariate = FALSE),
      control_overrides = overrides
    ),
    list(g_tol = 1e-6, algorithm = "lbfgs")
  )

  # The fixed-effect path carries the overrides too.
  expect_equal(
    drm_julia_bridge_options(NULL, control_overrides = overrides),
    list(g_tol = 1e-6, algorithm = "lbfgs")
  )
})

test_that("a tuned control flows through the full bridge payload builder", {
  formula <- bf(y ~ x, sigma ~ 1)
  data <- data.frame(y = rnorm(8), x = rnorm(8))
  payload <- drm_julia_bridge_payload(
    formula = formula,
    family_type = "gaussian",
    data = data,
    env = environment(),
    control_overrides = drm_julia_translate_control(
      drm_control(optimizer = list(g_tol = 5e-5, algorithm = "gls"))
    )
  )
  expect_equal(payload$options, list(g_tol = 5e-5, algorithm = "gls"))
})

test_that("g_tol override coexists with REML on the sigma-phylo path", {
  opts <- drm_julia_bridge_options(
    list(bivariate = FALSE),
    method = "REML",
    control_overrides = list(g_tol = 1e-7)
  )
  expect_equal(opts, list(g_tol = 1e-7, method = "REML"))
})

test_that("unsupported TMB-only controls abort with a clear message", {
  expect_error(
    drm_julia_translate_control(drm_control(se = FALSE)),
    "does not support"
  )
  expect_error(
    drm_julia_translate_control(drm_control(keep_tmb_object = FALSE)),
    "does not support"
  )
  expect_error(
    drm_julia_translate_control(drm_control(sparse_fixed = TRUE)),
    "does not support"
  )
  expect_error(
    drm_julia_translate_control(drm_control(aggregate_gaussian = TRUE)),
    "does not support"
  )
  expect_error(
    drm_julia_translate_control(drm_control(optimizer_preset = "careful")),
    "does not support"
  )
})

test_that("nlminb iteration caps are rejected on the Julia path", {
  # DRM.jl's drm() exposes no iteration-cap kwarg on the bridge path, so these
  # are rejected rather than silently dropped.
  expect_error(
    drm_julia_translate_control(drm_control(optimizer = list(iter.max = 500))),
    "does not support"
  )
  expect_error(
    drm_julia_translate_control(drm_control(optimizer = list(eval.max = 500))),
    "does not support"
  )
})

test_that("invalid optimizer values abort before crossing the bridge", {
  expect_error(
    drm_julia_translate_control(
      drm_control(optimizer = list(algorithm = "newton"))
    ),
    "must be one of"
  )
  expect_error(
    drm_julia_translate_control(drm_control(optimizer = list(g_tol = -1))),
    "single positive number"
  )
  expect_error(
    drm_julia_translate_control(drm_control(optimizer = list(g_tol = c(1, 2)))),
    "single positive number"
  )
})

test_that("a bare optimizer list is translated via the drm_control parser", {
  expect_equal(
    drm_julia_translate_control(list(g_tol = 1e-6)),
    list(g_tol = 1e-6)
  )
})
