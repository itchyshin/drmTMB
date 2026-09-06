# The all-or-nothing Julia routes -- structured, bivariate q2 structured,
# cross-family, and the joint missing-predictor adapter -- accept only a default
# `drm_control()`. They were already fail-CLOSED (nothing silently dropped), but
# their refusal named no field: a caller who set several settings learned only
# that "structured models currently accept only default control" and had to
# bisect to find which one. These tests pin that every refused setting is now
# named, and that the naming is DERIVED from `drm_control()` rather than listed
# by hand, so an eighteenth control field cannot go unnamed.

# One non-default value per `drm_control()` field. The totality test below fails
# if `drm_control()` grows a field this table does not name.
julia_refusal_name_probes <- function() {
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

test_that("a default control changes nothing and names nothing", {
  expect_equal(drm_julia_nondefault_control_fields(drm_control()), character())
  expect_equal(drm_julia_nondefault_control_fields(NULL), character())
  expect_equal(drm_julia_nondefault_control_fields(list()), character())
})

test_that("every non-optimizer drm_control() field is named when changed", {
  probes <- julia_refusal_name_probes()
  fields <- setdiff(names(drm_control()), "optimizer")
  # Totality: the probe table must cover the constructor EXACTLY. A new
  # `drm_control()` field with no probe here fails this expectation, so the
  # naming contract cannot fall behind the registry unnoticed.
  expect_equal(sort(names(probes)), sort(fields))
  for (field in fields) {
    expect_true(
      field %in% drm_julia_nondefault_control_fields(probes[[field]]),
      label = paste0("drm_control(", field, " = <non-default>) is named")
    )
  }
  # Every field except `optimizer_preset` names itself and nothing else.
  for (field in setdiff(fields, "optimizer_preset")) {
    expect_equal(
      drm_julia_nondefault_control_fields(probes[[field]]),
      field,
      label = paste0("drm_control(", field, " = <non-default>)")
    )
  }
})

test_that("optimizer_preset names the nlminb settings it rewrites too", {
  # Measured, not assumed: `optimizer_preset = "careful"` is a macro -- it also
  # rewrites the nlminb iteration budgets inside `optimizer`. Reporting all
  # three is the honest answer to "which of my settings did you refuse?", and a
  # caller who set only the preset would otherwise be puzzled by the extra
  # names, so this pins the behaviour rather than hiding it.
  expect_setequal(
    drm_julia_nondefault_control_fields(drm_control(optimizer_preset = "careful")),
    c("optimizer_preset", "optimizer$iter.max", "optimizer$eval.max")
  )
})

test_that("optimizer settings are named as the user wrote them", {
  expect_equal(
    drm_julia_nondefault_control_fields(
      drm_control(optimizer = list(g_tol = 1e-9))
    ),
    "optimizer$g_tol"
  )
  expect_equal(
    drm_julia_nondefault_control_fields(
      drm_control(optimizer = list(iter.max = 500L))
    ),
    "optimizer$iter.max"
  )
  # A bare list is read as optimizer-only, matching drm_parse_control().
  expect_equal(
    drm_julia_nondefault_control_fields(list(g_tol = 1e-9)),
    "optimizer$g_tol"
  )
  # Several at once are all named, not just the first.
  expect_setequal(
    drm_julia_nondefault_control_fields(
      drm_control(newton_polish = FALSE, se_group_sd = TRUE)
    ),
    c("se_group_sd", "newton_polish")
  )
})

test_that("naming agrees with the gate that does the refusing", {
  # If these ever disagreed, a route would refuse while reporting no offending
  # setting -- the exact uninformative message this file exists to prevent.
  probes <- c(
    julia_refusal_name_probes(),
    list(
      `optimizer$g_tol` = drm_control(optimizer = list(g_tol = 1e-9)),
      `optimizer$iter.max` = drm_control(optimizer = list(iter.max = 500L)),
      default = drm_control()
    )
  )
  for (nm in names(probes)) {
    expect_equal(
      drm_julia_default_control(probes[[nm]]),
      length(drm_julia_nondefault_control_fields(probes[[nm]])) == 0L,
      label = paste0("gate/naming agreement for ", nm)
    )
    expect_equal(
      drm_julia_joint_default_control(probes[[nm]]),
      length(drm_julia_nondefault_control_fields(probes[[nm]])) == 0L,
      label = paste0("joint gate/naming agreement for ", nm)
    )
  }
})

test_that("the shared refusal names the offending settings", {
  for (field in names(julia_refusal_name_probes())) {
    expect_error(
      drm_julia_abort_nondefault_control(
        route = "structured models",
        advice = "Use the native tmb path.",
        control = julia_refusal_name_probes()[[field]]
      ),
      field,
      fixed = TRUE,
      label = paste0("refusal names ", field)
    )
  }
  expect_error(
    drm_julia_abort_nondefault_control(
      route = "cross-family models",
      advice = "Use the native tmb path.",
      control = drm_control(optimizer = list(iter.max = 500L))
    ),
    "iter.max",
    fixed = TRUE
  )
})

test_that("every all-or-nothing route refuses through the naming helper", {
  # A static guard: reverting any of these call sites to a bare cli_abort()
  # would restore the unnamed message without failing any behavioural test,
  # because the routes themselves need a live Julia session to reach.
  routes <- list(
    structured = drmTMB:::drmTMB_julia_structured_bridge,
    biv_q2_structured = drmTMB:::drmTMB_julia_biv_known_structured_bridge,
    cross_family = drmTMB:::drmTMB_julia_xfam_bridge
  )
  for (nm in names(routes)) {
    body_text <- paste(deparse(body(routes[[nm]])), collapse = " ")
    expect_true(
      grepl("drm_julia_abort_nondefault_control", body_text, fixed = TRUE),
      label = paste0(nm, " route refuses through the naming helper")
    )
  }
  joint_text <- paste(
    deparse(body(drmTMB:::drm_julia_joint_prepare)),
    collapse = " "
  )
  expect_true(
    grepl("drm_julia_nondefault_control_fields", joint_text, fixed = TRUE)
  )
})
