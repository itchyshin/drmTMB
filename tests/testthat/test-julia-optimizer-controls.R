# Translation-only tests for the engine = "julia" optimizer-control passthrough.
# These exercise the R-side control translator and option builder ONLY; they do
# not call JuliaCall, start Julia, or fit a model.

bridge_mean_phylo_payload <- function() {
  list(
    bivariate = FALSE,
    family_type = "gaussian",
    locscale_mode = "mean_only"
  )
}

bridge_locscale_phylo_payload <- function() {
  list(
    bivariate = FALSE,
    family_type = "gaussian",
    locscale_mode = "phylo_locscale"
  )
}

bridge_q4_phylo_payload <- function() {
  list(bivariate = TRUE, bivariate_dimension = "q4")
}

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
  # Sparse all-node mean-phylo: the current parity-tested 1e-8 default.
  expect_equal(
    drm_julia_bridge_options(
      bridge_mean_phylo_payload(),
      control_overrides = list()
    ),
    list(g_tol = 1e-8)
  )
  # Bivariate q=4 PLSM: DRM.jl defaults (empty payload).
  expect_equal(
    drm_julia_bridge_options(
      bridge_q4_phylo_payload(),
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

  # The user g_tol replaces the mean-phylo default; algorithm is added.
  expect_equal(
    drm_julia_bridge_options(
      bridge_mean_phylo_payload(),
      control_overrides = overrides
    ),
    list(g_tol = 1e-6, algorithm = "lbfgs")
  )

  # The fixed-effect path carries the overrides too.
  expect_equal(
    drm_julia_bridge_options(NULL, control_overrides = overrides),
    list(g_tol = 1e-6, algorithm = "lbfgs")
  )

  # q = 4 has a separate outer optimizer tolerance. A generic `g_tol`
  # kwarg is accepted by `drm()` but is not read by that route, so the bridge
  # must translate the public control to its q4-specific option name.
  expect_equal(
    drm_julia_bridge_options(
      bridge_q4_phylo_payload(),
      control_overrides = list(g_tol = 1e-6)
    ),
    list(q4_g_tol = 1e-6)
  )
})

test_that("q = 4 rejects algorithm controls that its optimizer cannot honour", {
  expect_error(
    drm_julia_bridge_options(
      bridge_q4_phylo_payload(),
      control_overrides = list(algorithm = "lbfgs")
    ),
    "q = 4.*algorithm"
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
  # design 258 S7.1: options also carries coef_labels; pin the control shape without it
  expect_equal(drm_test_options_sans_labels(payload$options), list(g_tol = 5e-5, algorithm = "gls"))
  expect_true(is.list(payload$options$coef_labels))
})

test_that("g_tol override coexists with REML on the sigma-phylo path", {
  opts <- drm_julia_bridge_options(
    bridge_locscale_phylo_payload(),
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

# ---------------------------------------------------------------------------
# The engine-control contract (drmTMB#1108): exactly `optimizer$g_tol`,
# `optimizer$algorithm` and (q4 only) `optimizer$q4_vcov` cross to DRM.jl.
# Everything else `drm_control()` carries must REFUSE, never silently drop.
# ---------------------------------------------------------------------------

# One non-default value per `drm_control()` field. The totality test below
# fails if `drm_control()` grows a field this table does not name, so the
# contract cannot fall behind the constructor unnoticed.
julia_control_nondefault_probes <- function() {
  list(
    se = drm_control(se = FALSE),
    se_report_covariance = drm_control(se_report_covariance = FALSE),
    se_skip_delta_method = drm_control(se_skip_delta_method = TRUE),
    se_group_sd = drm_control(se_group_sd = TRUE),
    keep_data = drm_control(keep_data = FALSE),
    keep_model_frame = drm_control(keep_model_frame = FALSE),
    keep_tmb_object = drm_control(keep_tmb_object = FALSE),
    sparse_fixed = drm_control(sparse_fixed = TRUE),
    aggregate_gaussian = drm_control(aggregate_gaussian = TRUE),
    logsigma_clamp = drm_control(logsigma_clamp = c(-20, 20)),
    logsigma_clamp_margin = drm_control(logsigma_clamp_margin = 6),
    optimizer_preset = drm_control(optimizer_preset = "careful"),
    newton_polish = drm_control(newton_polish = FALSE),
    multi_start = drm_control(multi_start = 5L),
    fallback_optimizer = drm_control(fallback_optimizer = "BFGS"),
    start = drm_control(start = list(`fixef:mu:(Intercept)` = 0.5))
  )
}

test_that("the refused-field set is DERIVED from drm_control(), not hand-listed", {
  # The fail-open defect this replaced was a hand-written list that named 9 of
  # the then-16 non-optimizer fields. Deriving the set is what makes the
  # contract fail closed when `drm_control()` grows.
  expect_equal(
    sort(drm_julia_unsupported_control_fields()),
    sort(setdiff(names(drm_control()), "optimizer"))
  )
  expect_false("optimizer" %in% drm_julia_unsupported_control_fields())
})

test_that("every non-optimizer drm_control() field refuses on the Julia path", {
  probes <- julia_control_nondefault_probes()
  fields <- setdiff(names(drm_control()), "optimizer")
  # Totality: the probe table must cover the constructor exactly. A new
  # `drm_control()` field with no probe here fails this expectation.
  expect_equal(sort(names(probes)), sort(fields))
  for (field in fields) {
    expect_error(
      drm_julia_translate_control(probes[[field]]),
      field,
      fixed = TRUE,
      label = paste0("drm_control(", field, " = <non-default>)")
    )
  }
})

test_that("the seven fields that used to be silently dropped now refuse", {
  # Regression pin on the exact defect measured 2026-09-05 at DRM.jl pin
  # 430ef64cc: each of these returned a fit byte-identical to the default one
  # (logLik -199.0299845089) with no error, so the user got neither the
  # setting nor a refusal. Named individually so a future refactor that
  # re-introduces a hand-written list cannot quietly re-open them.
  dropped <- c(
    "se_report_covariance",
    "se_skip_delta_method",
    "se_group_sd",
    "logsigma_clamp",
    "logsigma_clamp_margin",
    "newton_polish",
    "fallback_optimizer"
  )
  probes <- julia_control_nondefault_probes()
  for (field in dropped) {
    expect_error(
      drm_julia_translate_control(probes[[field]]),
      field,
      fixed = TRUE,
      label = paste0("silently-dropped field ", field)
    )
  }
  # `logsigma_clamp = NULL` is a non-default value too (the default is
  # c(-12, 12)) and was dropped by the same hole.
  expect_error(
    drm_julia_translate_control(drm_control(logsigma_clamp = NULL)),
    "logsigma_clamp",
    fixed = TRUE
  )
})

test_that("the whitelist is exactly g_tol, algorithm and q4_vcov", {
  expect_equal(
    drm_julia_translate_control(
      drm_control(optimizer = list(g_tol = 1e-9, algorithm = "gls"))
    ),
    list(g_tol = 1e-9, algorithm = "gls")
  )
  expect_equal(
    drm_julia_translate_control(drm_control(optimizer = list(q4_vcov = TRUE))),
    list(q4_vcov = TRUE)
  )
  # Anything else inside `optimizer` refuses by name.
  for (nm in c("rel.tol", "trace", "abs.tol", "step.min")) {
    ctrl <- drm_control(optimizer = stats::setNames(list(1), nm))
    expect_error(
      drm_julia_translate_control(ctrl),
      nm,
      fixed = TRUE,
      label = paste0("optimizer$", nm)
    )
  }
})
