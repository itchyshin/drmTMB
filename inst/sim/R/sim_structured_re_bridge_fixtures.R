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

phase18_structured_re_q2_payload_fixture <- function(
  structured_type = "phylo",
  estimator = "ML",
  route = "native_tmb"
) {
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
  if (!identical(estimator, "ML")) {
    stop(
      "q2 REML payload remains unsupported and is not HSquared AI-REML.",
      call. = FALSE
    )
  }
  if (identical(route, "r_via_julia") && !identical(structured_type, "phylo")) {
    stop(
      "R-via-Julia q2 bridge payload remains unavailable for non-phylo ",
      "structured types until row-specific bridge routes exist.",
      call. = FALSE
    )
  }

  matrix_value <- phase18_structured_re_fixture_matrix("q2")
  coef <- c(
    "mu1:(Intercept)" = 0.25,
    "mu1:x" = 0.50,
    "mu2:(Intercept)" = -0.10,
    "mu2:x" = 0.35,
    "sd_mu1:structured(group)" = 0.42,
    "sd_mu2:structured(group)" = 0.31,
    "cor_mu1_mu2:structured(group)" = 0.18
  )
  vcov <- diag(c(0.012, 0.016, 0.013, 0.017, 0.025, 0.024, 0.030))
  dimnames(vcov) <- list(names(coef), names(coef))

  list(
    payload_version = "structured_re_bridge_payload_v1",
    target = data.frame(
      target_id = paste(
        "q2",
        structured_type,
        "mu1_mu2",
        "ml",
        sep = "_"
      ),
      dimension = "q2",
      structured_type = structured_type,
      endpoint = "mu1_mu2",
      estimator = estimator,
      route = route,
      stringsAsFactors = FALSE
    ),
    matrix = list(
      matrix_id = paste("fixture", "q2", structured_type, sep = "_"),
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
      logLik = -23.456
    ),
    fit_status = "fixture_only",
    inference = data.frame(
      extractor = c("profile", "bootstrap", "coverage", "r_via_julia"),
      status = c(
        "not_evaluated",
        "not_evaluated",
        "not_evaluated",
        if (identical(route, "r_via_julia")) "available" else "unavailable"
      ),
      unavailable_reason = c(
        "profile grid not run",
        "bootstrap refits not run",
        "coverage grid not calibrated",
        if (identical(route, "r_via_julia")) {
          "q2 phylo complete-response exact-Gaussian ML fixture only"
        } else {
          "q2-specific bridge payload route not evaluated"
        }
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
    r_via_julia_status = c("fixture_available", "planned", "unsupported"),
    separated_from = c(
      "q2_plus_q2;q4",
      "q2;q4",
      "q2_ml;q4;HSquared_AI_REML"
    ),
    bridge_status = c("experimental", "planned", "unsupported"),
    claim_boundary = c(
      "Same-target q2 phylo ML fixture only; no broad bridge support promotion.",
      "Two q2 blocks are not full q4 structured covariance.",
      "q2 REML remains unsupported and is not HSquared AI-REML."
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q2_coefficient_order_map <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    payload <- phase18_structured_re_q2_payload_fixture(
      structured_type = structured_type,
      route = "native_tmb"
    )
    coef_order <- paste(names(payload$estimates$coef), collapse = ";")
    bridge_status <- if (identical(structured_type, "phylo")) {
      "experimental"
    } else {
      "planned"
    }
    data.frame(
      map_id = paste("q2", structured_type, "location_coef_order", sep = "_"),
      structured_type = structured_type,
      target = paste("gaussian_q2_mu1_mu2", structured_type, sep = "_"),
      route = "q2_bridge",
      estimator = "ML",
      coefficient_order = coef_order,
      fixed_effect_terms = "mu1:(Intercept);mu1:x;mu2:(Intercept);mu2:x",
      structured_terms = "sd_mu1:structured(group);sd_mu2:structured(group)",
      correlation_terms = "cor_mu1_mu2:structured(group)",
      extractor = "coef;vcov;summary",
      tolerance_quantity = "coef;logLik;structured_sd;structured_correlation",
      status = "covered",
      bridge_status = bridge_status,
      evidence_url = "docs/dev-log/after-task/2026-06-22-q2-coefficient-ordering-map.md",
      claim_boundary = paste(
        "Q2 coefficient order is fixture-level contract evidence only;",
        "q2 phylo bridge evidence is limited to one exact-Gaussian ML",
        "fixture and no broad q2 bridge support or interval coverage is",
        "promoted."
      ),
      next_gate = "Compare native direct and R-via-Julia q2 coefficients only after q2 bridge route design.",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phase18_structured_re_q2_payload_provenance <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    payload <- phase18_structured_re_q2_payload_fixture(
      structured_type = structured_type,
      route = "native_tmb"
    )
    target <- payload$target
    bridge_status <- if (identical(structured_type, "phylo")) {
      "experimental"
    } else {
      "planned"
    }
    data.frame(
      provenance_id = paste(
        "q2",
        structured_type,
        "payload_provenance",
        sep = "_"
      ),
      target = paste("gaussian_q2_mu1_mu2", structured_type, sep = "_"),
      structured_type = structured_type,
      dimension = target$dimension[[1L]],
      route = "q2_bridge",
      estimator = target$estimator[[1L]],
      payload_version = payload$payload_version,
      source_repo = "drmTMB;DRM.jl",
      source_branch = "codex/ai-reml-transfer-slices;codex/ai-reml-gaussian-mme-pilot",
      source_head = "b56aabd947b5;e016fc15b4fb",
      matrix_id = payload$matrix$matrix_id,
      matrix_digest = payload$matrix$matrix_digest,
      endpoint = target$endpoint[[1L]],
      required_levels = "group_index;matrix_row_names;matrix_col_names",
      version_fields = "payload_version;drmTMB_head;DRM.jl_head;estimator;route",
      dirty_state_policy = "local_dirty_state_must_be_reported;not_public_support",
      status = "covered",
      bridge_status = bridge_status,
      evidence_url = "docs/dev-log/after-task/2026-06-22-q2-payload-provenance.md",
      claim_boundary = paste(
        "Q2 payload provenance is a fixture-level audit contract only;",
        "q2 phylo bridge evidence is limited to one exact-Gaussian ML",
        "fixture and no broad q2 bridge support, q2 REML, q4 support,",
        "or interval coverage is promoted."
      ),
      next_gate = "Use this provenance map when designing the q2-specific bridge route.",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phase18_structured_re_q2_acceptance_gate <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    bridge_status <- if (identical(structured_type, "phylo")) {
      "experimental"
    } else {
      "planned"
    }
    data.frame(
      gate_id = paste("q2", structured_type, "parity_acceptance", sep = "_"),
      target = paste("gaussian_q2_mu1_mu2", structured_type, sep = "_"),
      structured_type = structured_type,
      dimension = "q2",
      estimator = "ML",
      native_status = "available_point_fixture",
      direct_drmjl_status = if (identical(structured_type, "phylo")) {
        "available_residual_correlation_point_export"
      } else if (identical(structured_type, "spatial")) {
        "available_fixed_covariance_residual_correlation_fixture"
      } else {
        "available_known_covariance_residual_correlation_point_export"
      },
      r_via_julia_status = if (identical(structured_type, "phylo")) {
        "available_q2_phylo_formula_bridge_fixture"
      } else {
        "planned_unimplemented"
      },
      tolerance_policy = if (identical(structured_type, "phylo")) {
        "native_direct_bridge_same_target_fixture_tolerances_met"
      } else {
        "not_applicable_until_bridge_route_exists"
      },
      acceptance_status = if (identical(structured_type, "phylo")) {
        "banked_phylo_fixture"
      } else {
        "blocked"
      },
      missing_evidence = if (identical(structured_type, "phylo")) {
        "none_for_phylo_fixture"
      } else {
        "r_via_julia_q2_route;same_target_tolerance"
      },
      required_before_acceptance = if (identical(structured_type, "phylo")) {
        "none_for_phylo_fixture"
      } else {
        paste(
          "native/direct/bridge same-target logLik coef structured_sd",
          "structured_correlation comparison"
        )
      },
      status = if (identical(structured_type, "phylo")) {
        "covered"
      } else {
        "blocked"
      },
      bridge_status = bridge_status,
      evidence_url = "docs/dev-log/after-task/2026-06-22-q2-parity-acceptance-blocker.md",
      claim_boundary = paste(
        if (identical(structured_type, "phylo")) {
          paste(
            "Q2 phylo parity is banked only for one complete-response",
            "exact-Gaussian ML native/direct/bridge fixture; no broad q2",
            "bridge support, q2 REML, q4 support, or interval coverage is",
            "promoted."
          )
        } else if (identical(structured_type, "spatial")) {
          paste(
            "Q2 spatial direct DRM.jl evidence is fixed-covariance fixture",
            "evidence only, not a range-estimating spatial route; parity",
            "acceptance remains blocked without an R-via-Julia q2 route and",
            "same-target tolerances."
          )
        } else {
          paste(
            "Q2 direct DRM.jl known-covariance fixture evidence is banked,",
            "but parity acceptance remains blocked without an R-via-Julia q2",
            "route and same-target tolerances; no q2 REML, q4 support, or",
            "interval coverage is promoted."
          )
        }
      ),
      next_gate = if (identical(structured_type, "phylo")) {
        "Implement spatial animal and relmat R-via-Julia q2 routes before aggregate q2 acceptance."
      } else {
        "Implement q2-specific R-via-Julia route before acceptance."
      },
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
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

phase18_structured_re_q4_phylocov_target_map <- function() {
  axis <- c("mu1", "mu2", "sigma1", "sigma2")
  sd_rows <- data.frame(
    map_id = paste0("q4_phylo_sd_", axis),
    target = "gaussian_q4_phylo",
    target_kind = "direct_sd",
    axis = axis,
    axis_pair = axis,
    direct_sd_target = paste0("sd_", axis),
    log_cholesky_target = paste0("log_cholesky_diag_", seq_along(axis)),
    correlation_target = "not_applicable",
    extractor = "summary;profile_targets",
    estimator = "ML",
    point_status = "mapped",
    interval_status = "not_evaluated",
    bridge_status = "experimental",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-phylocov-target-map.md",
    claim_boundary = paste(
      "Direct q4 SD target map only; no q4 parity, q4 REML, AI-REML,",
      "or interval coverage is promoted."
    ),
    next_gate = "Compare same-target q4 SD point estimates across native direct and bridge routes.",
    stringsAsFactors = FALSE
  )
  pairs <- utils::combn(axis, 2L)
  cor_axis_pair <- paste(pairs[1L, ], pairs[2L, ], sep = "_")
  cor_rows <- data.frame(
    map_id = paste0("q4_phylo_cor_", cor_axis_pair),
    target = "gaussian_q4_phylo",
    target_kind = "derived_correlation",
    axis = "among_axis_pair",
    axis_pair = cor_axis_pair,
    direct_sd_target = "not_direct",
    log_cholesky_target = paste0(
      "log_cholesky_offdiag_",
      pairs[1L, ],
      "_",
      pairs[2L, ]
    ),
    correlation_target = paste0("cor_", cor_axis_pair),
    extractor = "corpairs",
    estimator = "ML",
    point_status = "mapped_point_extractor",
    interval_status = "not_available",
    bridge_status = "experimental",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-phylocov-target-map.md",
    claim_boundary = paste(
      "Derived q4 correlation target map only; correlations are not direct SD",
      "targets and no q4 interval coverage is promoted."
    ),
    next_gate = "Compare corpairs point reconstruction before any interval wording.",
    stringsAsFactors = FALSE
  )
  rbind(sd_rows, cor_rows)
}

phase18_structured_re_q4_corpairs_parity_gate <- function() {
  data.frame(
    gate_id = "q4_phylo_corpairs_parity_gate",
    target = "gaussian_q4_phylo",
    extractor = "corpairs",
    native_status = "covered_calibrated_native_corpairs",
    direct_drmjl_status = "covered_point_export_matches_wrapper_corpairs",
    r_via_julia_status = "covered_calibrated_corpairs",
    parity_status = "covered_point_corpairs",
    missing_evidence = "interval_reliability;interval_coverage",
    required_before_acceptance = paste(
      "covered for same-fixture calibrated corpairs point parity;",
      "interval reliability remains separate"
    ),
    status = "covered",
    bridge_status = "experimental",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-calibrated-parity-probe.md",
    claim_boundary = paste(
      "Q4 corpairs point parity is covered on calibrated fixtures only;",
      "no broad q4 bridge support, q4 REML, AI-REML, interval reliability,",
      "or interval coverage is promoted."
    ),
    next_gate = paste(
      "Keep q4 interval reliability and coverage blocked until calibrated",
      "finite-interval evidence with denominators and MCSE exists."
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q4_profile_target_bridge_map <- function() {
  axis <- c("mu1", "mu2", "sigma1", "sigma2")
  data.frame(
    map_id = paste0("q4_profile_target_", axis),
    target = "gaussian_q4_phylo",
    axis = axis,
    native_profile_target = paste0(
      "sd:mu:",
      axis,
      ":phylo(1 | p | species)"
    ),
    bridge_profile_target = paste0("sd:", axis, ":phylo(1 | species)"),
    direct_sd_target = paste0("sd_", axis),
    native_tmb_parameter = "log_sd_phylo",
    native_profile_ready = "true",
    bridge_profile_ready = "target_inventory_only",
    interval_status = "not_evaluated",
    negative_evidence = paste(
      "no_same_fixture_native_direct_bridge_profile_comparison;",
      "no_profile_interval_reliability_evidence",
      sep = ""
    ),
    status = "covered",
    bridge_status = "experimental",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-profile-target-bridge-map.md",
    claim_boundary = paste(
      "Q4 profile target bridge map only; no q4 parity, q4 REML,",
      "AI-REML, interval reliability, or interval coverage is promoted."
    ),
    next_gate = paste(
      "Compare same-target q4 SD point estimates and interval availability",
      "across native direct and bridge routes."
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q4_scale_axis_interval_failure_ledger <- function() {
  axis <- c("sigma1", "sigma2")
  data.frame(
    failure_id = paste0("q4_scale_axis_interval_", axis),
    target = "gaussian_q4_phylo",
    axis = axis,
    direct_sd_target = paste0("sd_", axis),
    native_tmb_status = "30tip_plumbing;100tip_refit_failures",
    direct_drmjl_status = "known_scale_axis_undercoverage",
    r_via_julia_status = "target_inventory_only",
    failure_class = paste(
      "scale_axis_undercoverage_known;",
      "native_refit_failures_visible;",
      "no_same_fixture_bridge_interval_parity",
      sep = ""
    ),
    interval_claim_status = "blocked",
    status = "covered",
    bridge_status = "experimental",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-scale-axis-interval-failures.md",
    source_evidence = paste(
      "docs/dev-log/dashboard/bootstrap-refit-accounting.tsv;",
      "/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/",
      "docs/dev-log/after-task/2026-06-13-bivariate-bootstrap-sigma-a.md",
      sep = ""
    ),
    claim_boundary = paste(
      "Q4 scale-axis interval failure ledger only; no q4 interval reliability,",
      "interval coverage, q4 parity, q4 REML, AI-REML, or bridge support is",
      "promoted."
    ),
    next_gate = paste(
      "Diagnose scale-axis bias and refit failures before any q4 interval",
      "wording or coverage claim."
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q4_direct_drmjl_export_status <- function() {
  axis <- c("mu1", "mu2", "sigma1", "sigma2")
  data.frame(
    export_id = paste0("q4_direct_drmjl_export_", axis),
    target = paste0("gaussian_q4_phylo_sd_", axis),
    axis = axis,
    dimension = "q4",
    route = "direct_drmjl",
    estimator = "ML",
    direct_sd_target = paste0("sd_", axis),
    sigma_a_source = "fit.ranef.Sigma_a",
    direct_status = "available_point_target",
    bridge_status = "experimental",
    inference_status = "point_target_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-direct-drmjl-export.md",
    claim_boundary = paste(
      "Direct q4 DRM.jl export status only; no R-via-Julia q4 bridge parity,",
      "q4 REML, AI-REML, interval reliability, or interval coverage is",
      "promoted."
    ),
    next_gate = paste(
      "Compare same-target native R/TMB direct DRM.jl and R-via-Julia q4",
      "point outputs before bridge parity."
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q4_deterministic_fixture <- function() {
  species <- sprintf("sp%02d", seq_len(8L))
  tree_newick <- paste0(
    "(((sp01:0.10,sp02:0.10):0.10,(sp03:0.10,sp04:0.10):0.10):0.10,",
    "((sp05:0.10,sp06:0.10):0.10,(sp07:0.10,sp08:0.10):0.10):0.10);"
  )
  sigma_a <- matrix(
    c(
      0.1600,
      0.0400,
      0.0200,
      -0.0100,
      0.0400,
      0.0900,
      0.0100,
      0.0150,
      0.0200,
      0.0100,
      0.0400,
      0.0050,
      -0.0100,
      0.0150,
      0.0050,
      0.0225
    ),
    nrow = 4L,
    byrow = TRUE,
    dimnames = list(
      c("mu1", "mu2", "sigma1", "sigma2"),
      c("mu1", "mu2", "sigma1", "sigma2")
    )
  )
  latent <- data.frame(
    species = species,
    u_mu1 = c(-0.30, -0.22, -0.08, 0.02, 0.11, 0.20, 0.25, 0.02),
    u_mu2 = c(0.18, 0.08, -0.10, -0.18, -0.05, 0.05, 0.15, -0.13),
    u_sigma1 = c(-0.10, -0.05, -0.02, 0.01, 0.04, 0.07, 0.09, -0.04),
    u_sigma2 = c(0.06, 0.03, 0.00, -0.03, -0.06, 0.02, 0.05, -0.07),
    stringsAsFactors = FALSE
  )
  data <- data.frame(
    species = rep(species, each = 2L),
    replicate = rep(seq_len(2L), times = length(species)),
    x = rep(c(-0.5, 0.5), times = length(species)),
    stringsAsFactors = FALSE
  )
  idx <- match(data$species, latent$species)
  eps1 <- rep(c(-0.35, 0.35, -0.20, 0.20), length.out = nrow(data))
  eps2 <- rep(c(0.25, -0.25, 0.15, -0.15), length.out = nrow(data))
  beta <- list(
    mu1 = c(`(Intercept)` = 0.20, x = 0.40),
    mu2 = c(`(Intercept)` = -0.10, x = -0.25),
    sigma1 = c(`(Intercept)` = -0.20, x = 0.15),
    sigma2 = c(`(Intercept)` = 0.10, x = -0.10),
    rho12 = 0.25
  )
  eta_mu1 <- beta$mu1[[1L]] + beta$mu1[[2L]] * data$x + latent$u_mu1[idx]
  eta_mu2 <- beta$mu2[[1L]] + beta$mu2[[2L]] * data$x + latent$u_mu2[idx]
  eta_sigma1 <- beta$sigma1[[1L]] +
    beta$sigma1[[2L]] * data$x +
    latent$u_sigma1[idx]
  eta_sigma2 <- beta$sigma2[[1L]] +
    beta$sigma2[[2L]] * data$x +
    latent$u_sigma2[idx]
  sigma1 <- exp(eta_sigma1)
  sigma2 <- exp(eta_sigma2)
  rho12 <- beta$rho12
  data$y1 <- eta_mu1 + sigma1 * eps1
  data$y2 <- eta_mu2 + sigma2 * (rho12 * eps1 + sqrt(1 - rho12^2) * eps2)
  data$sigma1_truth <- sigma1
  data$sigma2_truth <- sigma2
  list(
    data = data,
    tree_newick = tree_newick,
    truth = list(
      axes = colnames(sigma_a),
      sigma_a = sigma_a,
      beta = beta,
      rho12 = rho12
    ),
    latent = latent
  )
}

phase18_structured_re_q4_deterministic_fixture_status <- function() {
  data.frame(
    fixture_id = "q4_deterministic_balanced8",
    target = "gaussian_q4_phylo",
    n_species = 8L,
    n_obs = 16L,
    tree_id = "balanced8_bl010_v1",
    axes = "mu1;mu2;sigma1;sigma2",
    direct_sd_targets = "sd_mu1;sd_mu2;sd_sigma1;sd_sigma2",
    truth_status = "known_truth_sigma_a",
    data_status = "deterministic_fixture",
    fit_status = "not_fit_in_fixture_contract",
    bridge_status = "planned",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-deterministic-fixture.md",
    claim_boundary = paste(
      "Deterministic q4 fixture data only; no q4 parity, R-via-Julia bridge",
      "support, q4 REML, AI-REML, interval reliability, or interval coverage is",
      "promoted."
    ),
    next_gate = "Use this fixture for same-target native direct and bridge q4 point comparison.",
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q4_tolerance_policy <- function() {
  data.frame(
    policy_id = c(
      "q4_loglik_tolerance",
      "q4_fixed_coefficient_tolerance",
      "q4_direct_sd_tolerance",
      "q4_derived_correlation_tolerance"
    ),
    target = "gaussian_q4_phylo",
    quantity = c(
      "logLik",
      "fixed_coefficients",
      "direct_sd_targets",
      "derived_correlations"
    ),
    comparator_routes = "native_tmb;direct_drmjl;r_via_julia",
    tolerance = c(
      "abs_delta <= 1e-3 after constant alignment",
      "max_abs_delta <= 5e-3 on link scale",
      "max_rel_delta <= 0.05 or max_abs_delta <= 0.02 near zero",
      "max_abs_delta <= 0.05"
    ),
    tolerance_scale = c(
      "log_likelihood",
      "link_scale",
      "response_sd_scale",
      "correlation_scale"
    ),
    required_fixture = "q4_deterministic_balanced8",
    acceptance_use = "predeclared_policy_only",
    status = "covered",
    bridge_status = "planned",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-tolerance-policy.md",
    claim_boundary = paste(
      "Q4 tolerance policy only; no q4 parity, R-via-Julia bridge support,",
      "q4 REML, AI-REML, interval reliability, or interval coverage is",
      "promoted."
    ),
    next_gate = "Apply these tolerances to same-fixture native direct and bridge point outputs.",
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q4_same_fixture_parity_probe <- function() {
  data.frame(
    probe_id = "q4_same_fixture_native_bridge_probe_20260622",
    target = "gaussian_q4_phylo",
    fixture_id = "q4_30tip_m3_seed42_live_probe",
    comparator_routes = "native_tmb;r_via_julia;direct_drmjl_not_compared",
    native_tmb_status = "nonconverged_false_convergence_code1",
    direct_drmjl_status = "point_matrix_export_available_not_compared",
    r_via_julia_status = "converged_point_extractor",
    loglik_delta = "0.0006700136",
    max_abs_cor_delta = "0.3958341",
    tolerance_result = paste(
      "negative_probe_superseded;logLik_within_1e-3;",
      "corpairs_delta_0.3958341_gt_0.05;",
      "native_nonconverged",
      sep = ""
    ),
    acceptance_status = "negative_probe_superseded_by_calibrated_probe",
    status = "covered",
    bridge_status = "experimental",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-same-fixture-parity-probe.md",
    claim_boundary = paste(
      "Q4 same-fixture parity probe is retained negative evidence superseded",
      "by the calibrated point-parity probe; no q4 REML, AI-REML, interval",
      "reliability, broad bridge support, or interval coverage is promoted."
    ),
    next_gate = paste(
      "Use the calibrated q4 point-parity probe for point status and keep",
      "interval reliability blocked until finite-interval evidence exists."
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q4_calibrated_parity_probe <- function() {
  data.frame(
    probe_id = c(
      "q4_calibrated_balanced32_seed20260802_n4",
      "q4_calibrated_balanced32_seed31_n8"
    ),
    target = "gaussian_q4_phylo",
    fixture_id = c(
      "q4_balanced32_seed20260802_n4",
      "q4_balanced32_seed31_n8"
    ),
    seed = c(20260802L, 31L),
    n_tip = 32L,
    n_each = c(4L, 8L),
    comparator_routes = "native_tmb;direct_drmjl;r_via_julia",
    native_tmb_status = "converged_relative_convergence_code0",
    direct_drmjl_status = "converged_point_matrix_export_matches_wrapper",
    r_via_julia_status = "converged_point_reconstruction",
    loglik_delta_native_bridge = c(
      "3.40338728506e-05",
      "7.54770563276e-05"
    ),
    loglik_delta_direct_bridge = c("0", "0"),
    max_abs_fixef_native_bridge = c(
      "0.002035353033554",
      "0.000701704920776"
    ),
    max_abs_sd_native_bridge = c(
      "0.000891728220382",
      "0.000599065985335"
    ),
    max_abs_sd_direct_bridge = c("0", "0"),
    max_abs_cor_native_bridge = c(
      "0.00683683079288",
      "0.00197031823787"
    ),
    max_abs_cor_direct_bridge = c("1.11022302463e-16", "0"),
    tolerance_result = c(
      paste(
        "covered_point_parity;direct_wrapper_match;",
        "default_q4_g_tol_1e-4;",
        "native_bridge_logLik_3.40338728506e-05_within_1e-3;",
        "fixed_sd_cor_within_point_tolerances",
        sep = ""
      ),
      paste(
        "covered_point_parity;direct_wrapper_match;",
        "default_q4_g_tol_1e-4;",
        "native_bridge_logLik_7.54770563276e-05_within_1e-3;",
        "fixed_sd_cor_within_point_tolerances",
        sep = ""
      )
    ),
    acceptance_status = c(
      "covered_point_parity_no_interval_evidence",
      "covered_point_parity_no_interval_evidence"
    ),
    reconstruction_status = "covered",
    status = "covered",
    bridge_status = "experimental",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-calibrated-parity-probe.md",
    claim_boundary = paste(
      "Calibrated q4 same-fixture point parity only after DRM.jl q4 default",
      "tolerance tuning; no broad q4 bridge support, q4 REML, AI-REML,",
      "interval reliability, or interval coverage is promoted."
    ),
    next_gate = paste(
      "Keep q4 interval reliability and coverage blocked until calibrated",
      "finite-interval evidence with denominators and MCSE exists."
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q4_parity_acceptance_gate <- function() {
  data.frame(
    gate_id = "q4_parity_acceptance_gate",
    target = "gaussian_q4_phylo",
    required_fixture = "q4_calibrated_balanced32_pair",
    required_quantities = "logLik;fixed_coefficients;direct_sd_targets;derived_correlations",
    native_status = "covered_calibrated_native_tmb_converged",
    direct_drmjl_status = "covered_point_export_matches_wrapper",
    r_via_julia_status = "covered_calibrated_point_parity",
    tolerance_policy = "predeclared",
    acceptance_status = "covered_point_parity_no_interval_claim",
    missing_evidence = paste(
      "interval_reliability;",
      "interval_coverage"
    ),
    status = "covered",
    bridge_status = "experimental",
    evidence_url = "docs/dev-log/after-task/2026-06-22-q4-calibrated-parity-probe.md",
    claim_boundary = paste(
      "Q4 point-parity acceptance is covered on calibrated fixtures only;",
      "no broad q4 bridge support, q4 REML, AI-REML, interval reliability,",
      "or interval coverage is promoted."
    ),
    next_gate = paste(
      "Keep q4 interval reliability and coverage blocked until calibrated",
      "finite-interval evidence with denominators and MCSE exists."
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
