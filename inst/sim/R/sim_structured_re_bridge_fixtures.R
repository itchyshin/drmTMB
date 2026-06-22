phase18_structured_re_fixture_matrix <- function(dimension = "q1") {
  dimension <- phase18_structured_re_fixture_match_one(
    dimension,
    c("q1", "q2", "q4"),
    "dimension"
  )
  out <- switch(
    dimension,
    q1 = matrix(
      c(
        1.00,
        0.42,
        0.25,
        0.42,
        1.00,
        0.31,
        0.25,
        0.31,
        1.00
      ),
      nrow = 3L,
      byrow = TRUE
    ),
    q2 = matrix(
      c(
        1.00,
        0.35,
        0.18,
        0.11,
        0.35,
        1.00,
        0.27,
        0.15,
        0.18,
        0.27,
        1.00,
        0.33,
        0.11,
        0.15,
        0.33,
        1.00
      ),
      nrow = 4L,
      byrow = TRUE
    ),
    q4 = matrix(
      c(
        1.00,
        0.28,
        0.14,
        0.09,
        0.28,
        1.00,
        0.24,
        0.13,
        0.14,
        0.24,
        1.00,
        0.30,
        0.09,
        0.13,
        0.30,
        1.00
      ),
      nrow = 4L,
      byrow = TRUE
    )
  )
  dimnames(out) <- list(
    paste0("taxon", seq_len(nrow(out))),
    paste0("taxon", seq_len(ncol(out)))
  )
  out
}

phase18_structured_re_matrix_digest <- function(x, digits = 12L) {
  if (!is.matrix(x) || !is.numeric(x)) {
    stop("`x` must be a numeric matrix.", call. = FALSE)
  }
  if (
    !is.numeric(digits) ||
      length(digits) != 1L ||
      !is.finite(digits) ||
      digits != as.integer(digits) ||
      digits < 1L
  ) {
    stop("`digits` must be one positive whole number.", call. = FALSE)
  }
  values <- formatC(
    as.numeric(round(x, digits = as.integer(digits))),
    digits = as.integer(digits),
    format = "fg"
  )
  paste0(nrow(x), "x", ncol(x), ":", paste(values, collapse = ","))
}

phase18_structured_re_q1_payload_fixture <- function(
  endpoint = "mu",
  structured_type = "phylo",
  estimator = "ML",
  route = "native_tmb"
) {
  endpoint <- phase18_structured_re_fixture_match_one(
    endpoint,
    c("mu", "sigma", "mu_sigma"),
    "endpoint"
  )
  structured_type <- phase18_structured_re_fixture_match_one(
    structured_type,
    c("phylo", "spatial", "animal", "relmat"),
    "structured_type"
  )
  estimator <- phase18_structured_re_fixture_match_one(
    estimator,
    c("ML", "REML"),
    "estimator"
  )
  route <- phase18_structured_re_fixture_match_one(
    route,
    c("native_tmb", "direct_drmjl", "r_via_julia"),
    "route"
  )
  matrix_value <- phase18_structured_re_fixture_matrix("q1")
  coef <- c("(Intercept)" = 0.20, "x" = 0.45)
  if (endpoint %in% c("sigma", "mu_sigma")) {
    coef <- c(coef, "sigma:(Intercept)" = -0.15)
  }
  coef <- c(coef, "sd_structured(group)" = 0.35)
  vcov <- diag(c(0.010, 0.015, rep(0.020, length(coef) - 2L)))
  dimnames(vcov) <- list(names(coef), names(coef))

  list(
    payload_version = "structured_re_bridge_payload_v1",
    target = data.frame(
      target_id = paste(
        "q1",
        structured_type,
        endpoint,
        tolower(estimator),
        sep = "_"
      ),
      dimension = "q1",
      structured_type = structured_type,
      endpoint = endpoint,
      estimator = estimator,
      route = route,
      stringsAsFactors = FALSE
    ),
    matrix = list(
      matrix_id = paste("fixture", "q1", structured_type, sep = "_"),
      matrix_digest = phase18_structured_re_matrix_digest(matrix_value),
      value = matrix_value
    ),
    provenance = data.frame(
      source_ref = "inst/sim/R/sim_structured_re_bridge_fixtures.R",
      fixture_status = "deterministic_fixture",
      dirty_flag = "not_applicable",
      stringsAsFactors = FALSE
    ),
    estimates = list(
      coef = coef,
      vcov = vcov,
      logLik = -12.345
    ),
    fit_status = "fixture_only",
    inference = data.frame(
      extractor = c("profile", "bootstrap", "coverage", "corpair"),
      status = c(
        "not_evaluated",
        "not_evaluated",
        "not_evaluated",
        "not_applicable"
      ),
      unavailable_reason = c(
        "profile grid not run",
        "bootstrap refits not run",
        "coverage grid not calibrated",
        "q1 has no bivariate residual corpair"
      ),
      stringsAsFactors = FALSE
    )
  )
}

phase18_structured_re_reconstruct_fixture <- function(payload) {
  phase18_structured_re_assert_payload_fixture(payload)
  coef <- payload$estimates$coef
  vcov <- payload$estimates$vcov
  target <- payload$target

  list(
    coef = data.frame(
      term = names(coef),
      estimate = as.numeric(coef),
      stringsAsFactors = FALSE
    ),
    vcov = vcov,
    summary = data.frame(
      payload_version = payload$payload_version,
      target_id = target$target_id[[1L]],
      dimension = target$dimension[[1L]],
      endpoint = target$endpoint[[1L]],
      estimator = target$estimator[[1L]],
      route = target$route[[1L]],
      logLik = payload$estimates$logLik,
      fit_status = payload$fit_status,
      reconstruction_status = "reconstructed_from_fixture",
      stringsAsFactors = FALSE
    ),
    unavailable = payload$inference
  )
}

phase18_structured_re_parity_status <- function(
  native,
  direct,
  bridge = NULL,
  tolerance = 1e-6,
  blocked_reason = "route_a_all_node_loglik_bug"
) {
  phase18_structured_re_assert_reconstruction(native, "native")
  phase18_structured_re_assert_reconstruction(direct, "direct")
  phase18_structured_re_fixture_assert_positive_number(tolerance, "tolerance")

  native_direct_coef_delta <- phase18_structured_re_coef_delta(native, direct)
  native_direct_loglik_delta <- abs(
    native$summary$logLik[[1L]] - direct$summary$logLik[[1L]]
  )

  if (is.null(bridge)) {
    return(data.frame(
      dimension = native$summary$dimension[[1L]],
      endpoint = native$summary$endpoint[[1L]],
      estimator = native$summary$estimator[[1L]],
      native_status = "available",
      direct_drmjl_status = "available",
      r_via_julia_status = "blocked",
      max_abs_coef_delta = native_direct_coef_delta,
      abs_loglik_delta = native_direct_loglik_delta,
      tolerance = tolerance,
      parity_status = "blocked",
      blocked_reason = blocked_reason,
      claim_boundary = paste(
        "Native and direct fixture agreement does not promote R-via-Julia",
        "bridge support."
      ),
      stringsAsFactors = FALSE
    ))
  }

  phase18_structured_re_assert_reconstruction(bridge, "bridge")
  coef_delta <- max(
    native_direct_coef_delta,
    phase18_structured_re_coef_delta(native, bridge),
    phase18_structured_re_coef_delta(direct, bridge)
  )
  loglik_delta <- max(
    native_direct_loglik_delta,
    abs(native$summary$logLik[[1L]] - bridge$summary$logLik[[1L]]),
    abs(direct$summary$logLik[[1L]] - bridge$summary$logLik[[1L]])
  )
  passed <- coef_delta <= tolerance && loglik_delta <= tolerance

  data.frame(
    dimension = native$summary$dimension[[1L]],
    endpoint = native$summary$endpoint[[1L]],
    estimator = native$summary$estimator[[1L]],
    native_status = "available",
    direct_drmjl_status = "available",
    r_via_julia_status = "available",
    max_abs_coef_delta = coef_delta,
    abs_loglik_delta = loglik_delta,
    tolerance = tolerance,
    parity_status = if (passed) "passed" else "failed",
    blocked_reason = if (passed) "" else "fixture_delta_exceeds_tolerance",
    claim_boundary = paste(
      "Fixture agreement is a deterministic contract only; live bridge",
      "promotion still needs row-specific fit evidence."
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q2_fixture_contract <- function() {
  data.frame(
    fixture_id = c(
      "q2_phylo_same_target_ml",
      "q2_plus_q2_not_q4",
      "q2_reml_unsupported_boundary"
    ),
    dimension = c("q2", "q2_plus_q2", "q2"),
    structured_type = "phylo",
    estimator = c("ML", "ML", "REML"),
    target = c(
      "mu1_mu2_same_structured_matrix",
      "two_independent_q2_blocks",
      "q2_exact_gaussian_reml"
    ),
    native_status = c("fixture_available", "planned", "unsupported"),
    direct_drmjl_status = c("fixture_available", "planned", "unsupported"),
    r_via_julia_status = c("planned", "planned", "unsupported"),
    separated_from = c(
      "q2_plus_q2;q4",
      "q2;q4",
      "q2_ml;q4;HSquared_AI_REML"
    ),
    bridge_status = c("planned", "planned", "unsupported"),
    claim_boundary = c(
      "Same-target q2 fixture only; no bridge support promotion.",
      "Two q2 blocks are not full q4 structured covariance.",
      "q2 REML remains unsupported and is not HSquared AI-REML."
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q4_fixture_contract <- function() {
  data.frame(
    fixture_id = c(
      "q4_direct_sd_extractor_fixture",
      "q4_derived_correlation_boundary",
      "q4_interval_unavailable_boundary"
    ),
    dimension = "q4",
    structured_type = "phylo",
    estimator = "ML",
    direct_sd_targets = c(
      "sd_mu1;sd_mu2;sd_sigma1;sd_sigma2",
      "sd_mu1;sd_mu2;sd_sigma1;sd_sigma2",
      "sd_mu1;sd_mu2;sd_sigma1;sd_sigma2"
    ),
    derived_correlation_targets = c(
      "six cross-axis correlations",
      "six cross-axis correlations",
      "six cross-axis correlations"
    ),
    point_status = c("fixture_available", "fixture_available", "planned"),
    interval_status = c("not_evaluated", "not_applicable", "unavailable"),
    bridge_status = c("planned", "unsupported", "planned"),
    claim_boundary = c(
      "Direct q4 SD extractor fixture only; no interval or coverage claim.",
      "Derived correlations are extractor outputs, not direct SD targets.",
      "no interval claim until calibrated profile/bootstrap evidence."
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_assert_payload_fixture <- function(payload) {
  if (!is.list(payload)) {
    stop("`payload` must be a list.", call. = FALSE)
  }
  missing <- setdiff(
    c(
      "payload_version",
      "target",
      "matrix",
      "provenance",
      "estimates",
      "fit_status",
      "inference"
    ),
    names(payload)
  )
  if (length(missing) > 0L) {
    stop(
      "`payload` is missing ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (!is.data.frame(payload$target) || nrow(payload$target) != 1L) {
    stop("`payload$target` must be a one-row data frame.", call. = FALSE)
  }
  if (
    !all(c("matrix_id", "matrix_digest", "value") %in% names(payload$matrix))
  ) {
    stop("`payload$matrix` is missing required fields.", call. = FALSE)
  }
  if (!all(c("coef", "vcov", "logLik") %in% names(payload$estimates))) {
    stop("`payload$estimates` is missing required fields.", call. = FALSE)
  }
  if (
    !is.numeric(payload$estimates$coef) ||
      is.null(names(payload$estimates$coef))
  ) {
    stop(
      "`payload$estimates$coef` must be a named numeric vector.",
      call. = FALSE
    )
  }
  if (!is.matrix(payload$estimates$vcov)) {
    stop("`payload$estimates$vcov` must be a matrix.", call. = FALSE)
  }
  invisible(payload)
}

phase18_structured_re_assert_reconstruction <- function(x, name) {
  if (!is.list(x)) {
    stop("`", name, "` must be a list.", call. = FALSE)
  }
  missing <- setdiff(c("coef", "vcov", "summary", "unavailable"), names(x))
  if (length(missing) > 0L) {
    stop(
      "`",
      name,
      "` is missing ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (
    !is.data.frame(x$coef) ||
      !all(c("term", "estimate") %in% names(x$coef))
  ) {
    stop("`", name, "$coef` must contain term and estimate.", call. = FALSE)
  }
  if (!is.matrix(x$vcov)) {
    stop("`", name, "$vcov` must be a matrix.", call. = FALSE)
  }
  if (
    !is.data.frame(x$summary) ||
      !all(
        c("dimension", "endpoint", "estimator", "logLik") %in% names(x$summary)
      )
  ) {
    stop("`", name, "$summary` is missing required fields.", call. = FALSE)
  }
  invisible(x)
}

phase18_structured_re_coef_delta <- function(lhs, rhs) {
  common <- intersect(lhs$coef$term, rhs$coef$term)
  if (length(common) == 0L) {
    return(Inf)
  }
  lhs_est <- lhs$coef$estimate[match(common, lhs$coef$term)]
  rhs_est <- rhs$coef$estimate[match(common, rhs$coef$term)]
  max(abs(lhs_est - rhs_est))
}

phase18_structured_re_fixture_match_one <- function(x, choices, name) {
  if (!is.character(x) || length(x) != 1L || !nzchar(x)) {
    stop("`", name, "` must be one non-empty string.", call. = FALSE)
  }
  if (!x %in% choices) {
    stop("`", name, "` contains unsupported value: ", x, ".", call. = FALSE)
  }
  x
}

phase18_structured_re_fixture_assert_positive_number <- function(x, name) {
  ok <- is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    x > 0
  if (!ok) {
    stop("`", name, "` must be one positive finite number.", call. = FALSE)
  }
  invisible(x)
}
