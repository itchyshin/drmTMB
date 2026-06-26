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
          switch(
            structured_type,
            phylo = "q2 phylo complete-response exact-Gaussian ML fixture only",
            spatial = "q2 fixed-covariance spatial complete-response exact-Gaussian ML fixture only",
            animal = "q2 animal A-matrix complete-response exact-Gaussian ML fixture only",
            relmat = "q2 relmat K-matrix complete-response exact-Gaussian ML fixture only"
          )
        } else {
          "q2-specific bridge payload route not evaluated"
        }
      ),
      stringsAsFactors = FALSE
    )
  )
}

phase18_structured_re_mu_slope_payload_fixture <- function(
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
    "ML",
    "estimator"
  )
  route <- phase18_structured_re_fixture_match_one(
    route,
    c("native_tmb", "direct_drmjl", "r_via_julia"),
    "route"
  )
  implemented_structured_types <- c("phylo", "spatial", "animal", "relmat")
  if (!structured_type %in% implemented_structured_types) {
    stop(
      "The one-slope structured mu bridge fixture is banked only for phylo, ",
      "fixed-covariance spatial, animal A-matrix, and relmat K-matrix ",
      "cells.",
      call. = FALSE
    )
  }

  matrix_value <- phase18_structured_re_fixture_matrix("q1")
  coef <- c(
    "mu:(Intercept)" = 0.20,
    "mu:x" = 0.45,
    "sd_mu:structured(Intercept)" = 0.35,
    "sd_mu:structured(x)" = 0.18
  )
  vcov <- diag(c(0.010, 0.015, 0.020, 0.022))
  dimnames(vcov) <- list(names(coef), names(coef))

  list(
    payload_version = "structured_re_bridge_payload_v1",
    target = data.frame(
      target_id = paste0("q1_", structured_type, "_mu_one_slope_ml"),
      dimension = "q1",
      structured_type = structured_type,
      endpoint = "mu",
      slope_class = "independent_one_slope",
      estimator = estimator,
      route = route,
      stringsAsFactors = FALSE
    ),
    matrix = list(
      matrix_id = paste0("fixture_q1_", structured_type, "_mu_slope"),
      matrix_digest = phase18_structured_re_matrix_digest(matrix_value),
      value = matrix_value
    ),
    provenance = data.frame(
      source_ref = "inst/sim/R/sim_structured_re_bridge_fixtures.R",
      fixture_status = "deterministic_mu_slope_fixture",
      dirty_flag = "not_applicable",
      stringsAsFactors = FALSE
    ),
    estimates = list(
      coef = coef,
      vcov = vcov,
      logLik = -15.678
    ),
    fit_status = "fixture_only",
    inference = data.frame(
      extractor = c(
        "profile",
        "bootstrap",
        "coverage",
        "sigma_slope",
        "corpair"
      ),
      status = c(
        "not_evaluated",
        "not_evaluated",
        "not_evaluated",
        "not_applicable",
        "not_applicable"
      ),
      unavailable_reason = c(
        "profile grid not run",
        "bootstrap refits not run",
        "coverage grid not calibrated",
        "residual-scale structured slope is a separate cell",
        "independent one-slope mu fixture has no labelled covariance corpair"
      ),
      stringsAsFactors = FALSE
    )
  )
}

phase18_structured_re_sigma_slope_payload_fixture <- function(
  structured_type = "relmat",
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
    "ML",
    "estimator"
  )
  route <- phase18_structured_re_fixture_match_one(
    route,
    c("native_tmb", "direct_drmjl", "r_via_julia"),
    "route"
  )

  matrix_value <- phase18_structured_re_fixture_matrix("q1")
  coef <- c(
    "sigma:(Intercept)" = -0.10,
    "sigma:x" = 0.22,
    "sd_sigma:structured(Intercept)" = 0.28,
    "sd_sigma:structured(x)" = 0.16
  )
  vcov <- diag(c(0.011, 0.014, 0.021, 0.023))
  dimnames(vcov) <- list(names(coef), names(coef))

  list(
    payload_version = "structured_re_bridge_payload_v1",
    target = data.frame(
      target_id = paste0("q1_", structured_type, "_sigma_one_slope_ml"),
      dimension = "q1",
      structured_type = structured_type,
      endpoint = "sigma",
      slope_class = "independent_one_slope",
      estimator = estimator,
      route = route,
      stringsAsFactors = FALSE
    ),
    matrix = list(
      matrix_id = paste0("fixture_q1_", structured_type, "_sigma_slope"),
      matrix_digest = phase18_structured_re_matrix_digest(matrix_value),
      value = matrix_value
    ),
    provenance = data.frame(
      source_ref = "inst/sim/R/sim_structured_re_bridge_fixtures.R",
      fixture_status = "deterministic_sigma_slope_fixture",
      dirty_flag = "not_applicable",
      stringsAsFactors = FALSE
    ),
    estimates = list(
      coef = coef,
      vcov = vcov,
      logLik = -16.789
    ),
    fit_status = "fixture_only",
    inference = data.frame(
      extractor = c(
        "profile",
        "bootstrap",
        "coverage",
        "mu_sigma_slope",
        "corpair"
      ),
      status = c(
        "not_evaluated",
        "not_evaluated",
        "not_evaluated",
        "not_applicable",
        "not_applicable"
      ),
      unavailable_reason = c(
        "profile grid not run",
        "bootstrap refits not run",
        "coverage grid not calibrated",
        "matched mu+sigma structured slope is a separate cell",
        "independent one-slope sigma fixture has no labelled covariance corpair"
      ),
      stringsAsFactors = FALSE
    )
  )
}

phase18_structured_re_mu_sigma_slope_payload_fixture <- function(
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
    "ML",
    "estimator"
  )
  route <- phase18_structured_re_fixture_match_one(
    route,
    c("native_tmb", "direct_drmjl", "r_via_julia"),
    "route"
  )

  matrix_value <- phase18_structured_re_fixture_matrix("q1")
  coef <- c(
    "mu:(Intercept)" = 0.20,
    "mu:x" = 0.45,
    "sigma:(Intercept)" = -0.10,
    "sigma:x" = 0.22,
    "sd_mu:structured(Intercept)" = 0.35,
    "sd_mu:structured(x)" = 0.18,
    "sd_sigma:structured(Intercept)" = 0.28,
    "sd_sigma:structured(x)" = 0.16
  )
  vcov <- diag(c(0.010, 0.015, 0.011, 0.014, 0.020, 0.022, 0.021, 0.023))
  dimnames(vcov) <- list(names(coef), names(coef))

  list(
    payload_version = "structured_re_bridge_payload_v1",
    target = data.frame(
      target_id = paste0("q1_", structured_type, "_mu_sigma_one_slope_ml"),
      dimension = "q1_plus_q1",
      structured_type = structured_type,
      endpoint = "mu+sigma",
      slope_class = "independent_one_slope",
      estimator = estimator,
      route = route,
      stringsAsFactors = FALSE
    ),
    matrix = list(
      matrix_id = paste0("fixture_q1_", structured_type, "_mu_sigma_slope"),
      matrix_digest = phase18_structured_re_matrix_digest(matrix_value),
      value = matrix_value
    ),
    provenance = data.frame(
      source_ref = "inst/sim/R/sim_structured_re_bridge_fixtures.R",
      fixture_status = "deterministic_mu_sigma_slope_fixture",
      dirty_flag = "not_applicable",
      stringsAsFactors = FALSE
    ),
    estimates = list(
      coef = coef,
      vcov = vcov,
      logLik = -17.89
    ),
    fit_status = "fixture_only",
    inference = data.frame(
      extractor = c(
        "profile",
        "bootstrap",
        "coverage",
        "labelled_slope_covariance",
        "corpair",
        "REML",
        "AI_REML"
      ),
      status = c(
        "not_evaluated",
        "not_evaluated",
        "not_evaluated",
        "not_applicable",
        "not_applicable",
        "unsupported",
        "unsupported"
      ),
      unavailable_reason = c(
        "profile grid not run",
        "bootstrap refits not run",
        "coverage grid not calibrated",
        "matched mu+sigma fixture keeps independent endpoint members",
        "matched q1 plus q1 fixture has no labelled covariance corpair",
        "q1 plus q1 REML is not banked by this fixture",
        "AI-REML is outside this fixture contract"
      ),
      stringsAsFactors = FALSE
    )
  )
}

phase18_structured_re_q2_slope_payload_fixture <- function(
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
    "ML",
    "estimator"
  )
  route <- phase18_structured_re_fixture_match_one(
    route,
    c("native_tmb", "direct_drmjl", "r_via_julia"),
    "route"
  )

  matrix_value <- phase18_structured_re_fixture_matrix("q2")
  coef <- c(
    "mu1:x" = 0.50,
    "mu2:x" = 0.35,
    "sd_mu1:structured(x)" = 0.42,
    "sd_mu2:structured(x)" = 0.31,
    "cor_mu1_mu2:structured(x)" = 0.18
  )
  vcov <- diag(c(0.016, 0.017, 0.025, 0.024, 0.030))
  dimnames(vcov) <- list(names(coef), names(coef))

  list(
    payload_version = "structured_re_bridge_payload_v1",
    target = data.frame(
      target_id = paste0("q2_", structured_type, "_mu1_mu2_one_slope_ml"),
      dimension = "q2",
      structured_type = structured_type,
      endpoint = "mu1+mu2",
      slope_class = "labelled_slope_covariance",
      estimator = estimator,
      route = route,
      stringsAsFactors = FALSE
    ),
    matrix = list(
      matrix_id = paste0("fixture_q2_", structured_type, "_mu1_mu2_slope"),
      matrix_digest = phase18_structured_re_matrix_digest(matrix_value),
      value = matrix_value
    ),
    provenance = data.frame(
      source_ref = "inst/sim/R/sim_structured_re_bridge_fixtures.R",
      fixture_status = "deterministic_q2_slope_fixture",
      dirty_flag = "not_applicable",
      stringsAsFactors = FALSE
    ),
    estimates = list(
      coef = coef,
      vcov = vcov,
      logLik = -24.567
    ),
    fit_status = "fixture_only",
    inference = data.frame(
      extractor = c(
        "profile",
        "bootstrap",
        "coverage",
        "intercept_plus_slope_q4",
        "REML",
        "AI_REML"
      ),
      status = c(
        "not_evaluated",
        "not_evaluated",
        "not_evaluated",
        "not_applicable",
        "unsupported",
        "unsupported"
      ),
      unavailable_reason = c(
        "profile grid not run",
        "bootstrap refits not run",
        "coverage grid not calibrated",
        "slope-only q2 fixture is not intercept-plus-slope q4/q8",
        "q2 slope-only REML is not banked by this fixture",
        "AI-REML is outside this fixture contract"
      ),
      stringsAsFactors = FALSE
    )
  )
}

phase18_structured_re_q4_intercept_payload_fixture <- function(
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
    "ML",
    "estimator"
  )
  route <- phase18_structured_re_fixture_match_one(
    route,
    c("native_tmb", "direct_drmjl", "r_via_julia"),
    "route"
  )

  endpoint_members <- paste0(
    c("mu1", "mu2", "sigma1", "sigma2"),
    ":(Intercept)"
  )
  sd_terms <- paste0(
    "sd_",
    c("mu1", "mu2", "sigma1", "sigma2"),
    ":structured(Intercept)"
  )
  cor_pairs <- utils::combn(c("mu1", "mu2", "sigma1", "sigma2"), 2L)
  cor_terms <- apply(
    cor_pairs,
    2L,
    function(pair) {
      paste0(
        "cor_",
        pair[[1L]],
        "_",
        pair[[2L]],
        ":structured(Intercept)"
      )
    }
  )
  coef <- c(
    setNames(c(0.25, -0.10, -1.00, -1.10), endpoint_members),
    setNames(c(0.42, 0.31, 0.22, 0.20), sd_terms),
    setNames(seq(0.04, 0.18, length.out = length(cor_terms)), cor_terms)
  )
  vcov <- diag(seq(0.010, 0.024, length.out = length(coef)))
  dimnames(vcov) <- list(names(coef), names(coef))
  matrix_value <- phase18_structured_re_fixture_matrix("q4")

  list(
    payload_version = "structured_re_bridge_payload_v1",
    target = data.frame(
      target_id = paste0("q4_intercept_", structured_type, "_all_four_ml"),
      dimension = "q4",
      structured_type = structured_type,
      endpoint = "mu1+mu2+sigma1+sigma2",
      slope_class = "intercept_only",
      estimator = estimator,
      route = route,
      stringsAsFactors = FALSE
    ),
    matrix = list(
      matrix_id = paste0(
        "fixture_q4_intercept_",
        structured_type,
        "_all_four"
      ),
      matrix_digest = phase18_structured_re_matrix_digest(matrix_value),
      value = matrix_value
    ),
    provenance = data.frame(
      source_ref = "inst/sim/R/sim_structured_re_bridge_fixtures.R",
      fixture_status = "deterministic_q4_intercept_fixture",
      dirty_flag = "not_applicable",
      stringsAsFactors = FALSE
    ),
    estimates = list(
      coef = coef,
      vcov = vcov,
      logLik = -39.012
    ),
    fit_status = "fixture_only",
    inference = data.frame(
      extractor = c(
        "profile",
        "bootstrap",
        "coverage",
        "derived_correlations",
        "REML",
        "AI_REML"
      ),
      status = c(
        "not_evaluated",
        "not_evaluated",
        "not_evaluated",
        "derived_interval_unavailable",
        "unsupported",
        "unsupported"
      ),
      unavailable_reason = c(
        "profile grid not run",
        "bootstrap refits not run",
        "coverage grid not calibrated",
        "q4 all-four intercept correlations are derived-only in this fixture",
        "q4 intercept REML is not banked by this fixture",
        "AI-REML is outside this fixture contract"
      ),
      stringsAsFactors = FALSE
    )
  )
}

phase18_structured_re_q4_location_slope_payload_fixture <- function(
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
    "ML",
    "estimator"
  )
  route <- phase18_structured_re_fixture_match_one(
    route,
    c("native_tmb", "direct_drmjl", "r_via_julia"),
    "route"
  )

  endpoint_members <- paste0(
    rep(c("mu1", "mu2"), each = 2L),
    ":",
    rep(c("(Intercept)", "x"), times = 2L)
  )
  member_tokens <- gsub(
    "[:()]",
    "_",
    gsub("\\+", "_", endpoint_members)
  )
  member_tokens <- gsub("_+", "_", gsub("_$", "", member_tokens))
  sd_terms <- paste0("sd_", endpoint_members, ":structured")
  cor_pairs <- utils::combn(seq_along(endpoint_members), 2L)
  cor_terms <- apply(
    cor_pairs,
    2L,
    function(index) {
      paste0(
        "cor_",
        member_tokens[[index[[1L]]]],
        "_",
        member_tokens[[index[[2L]]]],
        ":structured"
      )
    }
  )
  coef <- c(
    setNames(c(0.25, 0.50, -0.10, 0.35), endpoint_members),
    setNames(c(0.42, 0.19, 0.31, 0.17), sd_terms),
    setNames(seq(0.04, 0.18, length.out = length(cor_terms)), cor_terms)
  )
  vcov <- diag(seq(0.010, 0.024, length.out = length(coef)))
  dimnames(vcov) <- list(names(coef), names(coef))
  matrix_value <- phase18_structured_re_fixture_matrix("q4")

  list(
    payload_version = "structured_re_bridge_payload_v1",
    target = data.frame(
      target_id = paste0(
        "q4_location_slope_",
        structured_type,
        "_mu1_mu2_ml"
      ),
      dimension = "q4",
      structured_type = structured_type,
      endpoint = "mu1+mu2",
      slope_class = "labelled_slope_covariance",
      estimator = estimator,
      route = route,
      stringsAsFactors = FALSE
    ),
    matrix = list(
      matrix_id = paste0(
        "fixture_q4_location_slope_",
        structured_type,
        "_mu1_mu2"
      ),
      matrix_digest = phase18_structured_re_matrix_digest(matrix_value),
      value = matrix_value
    ),
    provenance = data.frame(
      source_ref = "inst/sim/R/sim_structured_re_bridge_fixtures.R",
      fixture_status = "deterministic_q4_location_slope_fixture",
      dirty_flag = "not_applicable",
      stringsAsFactors = FALSE
    ),
    estimates = list(
      coef = coef,
      vcov = vcov,
      logLik = -33.789
    ),
    fit_status = "fixture_only",
    inference = data.frame(
      extractor = c(
        "profile",
        "bootstrap",
        "coverage",
        "partial_location_scale",
        "derived_correlations",
        "REML",
        "AI_REML"
      ),
      status = c(
        "not_evaluated",
        "not_evaluated",
        "not_evaluated",
        "not_applicable",
        "not_evaluated",
        "unsupported",
        "unsupported"
      ),
      unavailable_reason = c(
        "profile grid not run",
        "bootstrap refits not run",
        "coverage grid not calibrated",
        "mu1+mu2 q4 location fixture has no structured sigma endpoints",
        "derived correlation intervals are not run by this fixture",
        "q4 location slope REML is not banked by this fixture",
        "AI-REML is outside this fixture contract"
      ),
      stringsAsFactors = FALSE
    )
  )
}

phase18_structured_re_q4_slope_payload_fixture <- function(
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
    "ML",
    "estimator"
  )
  route <- phase18_structured_re_fixture_match_one(
    route,
    c("native_tmb", "direct_drmjl", "r_via_julia"),
    "route"
  )

  endpoint_members <- paste0(
    rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 2L),
    ":",
    rep(c("(Intercept)", "x"), times = 4L)
  )
  member_tokens <- gsub(
    "[:()]",
    "_",
    gsub("\\+", "_", endpoint_members)
  )
  member_tokens <- gsub("_+", "_", gsub("_$", "", member_tokens))
  sd_terms <- paste0("sd_", endpoint_members, ":structured")
  cor_pairs <- utils::combn(seq_along(endpoint_members), 2L)
  cor_terms <- apply(
    cor_pairs,
    2L,
    function(index) {
      paste0(
        "cor_",
        member_tokens[[index[[1L]]]],
        "_",
        member_tokens[[index[[2L]]]],
        ":structured"
      )
    }
  )
  coef <- c(
    setNames(
      c(0.25, 0.50, -0.10, 0.35, -1.00, 0.12, -1.10, -0.10),
      endpoint_members
    ),
    setNames(c(0.42, 0.19, 0.31, 0.17, 0.22, 0.11, 0.20, 0.10), sd_terms),
    setNames(seq(0.02, 0.29, length.out = length(cor_terms)), cor_terms)
  )
  vcov <- diag(seq(0.010, 0.030, length.out = length(coef)))
  dimnames(vcov) <- list(names(coef), names(coef))
  matrix_value <- phase18_structured_re_fixture_matrix("q4")

  list(
    payload_version = "structured_re_bridge_payload_v1",
    target = data.frame(
      target_id = paste0("q4_slope_", structured_type, "_all_four_ml"),
      dimension = "q8",
      structured_type = structured_type,
      endpoint = "mu1+mu2+sigma1+sigma2",
      slope_class = "labelled_slope_covariance",
      estimator = estimator,
      route = route,
      stringsAsFactors = FALSE
    ),
    matrix = list(
      matrix_id = paste0("fixture_q4_slope_", structured_type, "_all_four"),
      matrix_digest = phase18_structured_re_matrix_digest(matrix_value),
      value = matrix_value
    ),
    provenance = data.frame(
      source_ref = "inst/sim/R/sim_structured_re_bridge_fixtures.R",
      fixture_status = "deterministic_q4_slope_fixture",
      dirty_flag = "not_applicable",
      stringsAsFactors = FALSE
    ),
    estimates = list(
      coef = coef,
      vcov = vcov,
      logLik = -48.901
    ),
    fit_status = "fixture_only",
    inference = data.frame(
      extractor = c(
        "profile",
        "bootstrap",
        "coverage",
        "derived_correlations",
        "REML",
        "AI_REML"
      ),
      status = c(
        "not_evaluated",
        "not_evaluated",
        "not_evaluated",
        "derived_interval_unavailable",
        "unsupported",
        "unsupported"
      ),
      unavailable_reason = c(
        "profile grid not run",
        "bootstrap refits not run",
        "coverage grid not calibrated",
        "q4 all-four one-slope correlations are derived-only in this fixture",
        "q4 slope REML is not banked by this fixture",
        "AI-REML is outside this fixture contract"
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

phase18_structured_re_mu_slope_parity_fixture_contract <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    implemented <- structured_type %in%
      c("phylo", "spatial", "animal", "relmat")
    coefficient_order <- if (implemented) {
      payload <- phase18_structured_re_mu_slope_payload_fixture(structured_type)
      paste(names(payload$estimates$coef), collapse = ";")
    } else {
      "planned"
    }
    data.frame(
      fixture_id = paste0("mu_slope_", structured_type, "_same_target_ml"),
      formula_cell = switch(
        structured_type,
        phylo = "phylo(1 + x | species, tree = tree) in mu",
        spatial = "spatial(1 + x | site, coords = coords) in mu",
        animal = "animal(1 + x | id, A = A) in mu",
        relmat = "relmat(1 + x | id, K = K) in mu"
      ),
      structured_type = structured_type,
      dimension = "q1",
      endpoint = "mu",
      slope_class = "independent_one_slope",
      estimator = "ML",
      native_status = if (implemented) "fixture_available" else "planned",
      direct_drmjl_status = if (implemented) "fixture_available" else "planned",
      r_via_julia_status = if (implemented) "fixture_available" else "planned",
      coefficient_order = coefficient_order,
      matrix_slot = switch(
        structured_type,
        phylo = "tree",
        spatial = "coords",
        animal = "A",
        relmat = "K"
      ),
      input_scale = switch(
        structured_type,
        phylo = "ultrametric_tree_branch_lengths",
        spatial = "coordinates_to_fixed_covariance_K",
        animal = "additive_covariance",
        relmat = "user_covariance"
      ),
      parity_status = if (implemented) {
        "covered_same_target_fixture"
      } else {
        "planned"
      },
      bridge_status = if (implemented) "fixture_parity" else "planned",
      interval_status = "planned",
      coverage_status = "planned",
      evidence_url = "tests/testthat/test-structured-re-bridge-fixtures.R",
      claim_boundary = switch(
        structured_type,
        phylo = paste(
          "Phylo one-slope mu fixture parity is a deterministic",
          "native/direct/R-via-Julia contract only; no broad bridge support,",
          "sigma slope support, labelled covariance, interval reliability,",
          "or coverage is promoted."
        ),
        spatial = paste(
          "Spatial one-slope mu fixture parity is fixed-covariance only;",
          "no range-estimating spatial support, broad bridge support, sigma",
          "slope support, labelled covariance, interval reliability, or",
          "coverage is promoted."
        ),
        animal = paste(
          "Animal one-slope mu fixture parity uses an A-matrix contract only;",
          "no pedigree/Ainv bridge marshalling, broad bridge support, sigma",
          "slope support, labelled covariance, interval reliability, or",
          "coverage is promoted."
        ),
        relmat = paste(
          "Relmat one-slope mu fixture parity uses a K-matrix contract with",
          "runtime K/Q same-target parity evidence; no broad bridge support,",
          "sigma slope support, labelled covariance, interval reliability,",
          "or coverage is promoted."
        )
      ),
      next_gate = switch(
        structured_type,
        phylo = "Use this exact fixture as the template for provider-specific same-target bridge parity; keep interval and coverage gates separate.",
        spatial = "Use this fixed-covariance fixture as the spatial same-target bridge-parity template; keep range-estimating spatial, interval, and coverage gates separate.",
        animal = "Use this A-matrix fixture as the animal same-target bridge-parity template; keep pedigree/Ainv, interval, and coverage gates separate.",
        relmat = "Use this K-matrix fixture with runtime K/Q same-target parity evidence; keep sigma slopes, interval, and coverage gates separate."
      ),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phase18_structured_re_sigma_slope_parity_fixture_contract <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    payload <- phase18_structured_re_sigma_slope_payload_fixture(
      structured_type
    )
    data.frame(
      fixture_id = paste0("sigma_slope_", structured_type, "_same_target_ml"),
      formula_cell = switch(
        structured_type,
        phylo = "phylo(1 + x | species, tree = tree) in sigma",
        spatial = "spatial(1 + x | site, coords = coords) in sigma",
        animal = "animal(1 + x | id, A = A) in sigma",
        relmat = "relmat(1 + x | id, K = K) in sigma"
      ),
      structured_type = structured_type,
      dimension = "q1",
      endpoint = "sigma",
      slope_class = "independent_one_slope",
      estimator = "ML",
      native_status = "fixture_available",
      direct_drmjl_status = "fixture_available",
      r_via_julia_status = "fixture_available",
      coefficient_order = paste(names(payload$estimates$coef), collapse = ";"),
      matrix_slot = switch(
        structured_type,
        phylo = "tree",
        spatial = "coords",
        animal = "A",
        relmat = "K"
      ),
      input_scale = switch(
        structured_type,
        phylo = "ultrametric_tree_branch_lengths",
        spatial = "coordinates_to_fixed_covariance_K",
        animal = "additive_covariance",
        relmat = "user_covariance"
      ),
      parity_status = "covered_same_target_fixture",
      bridge_status = "fixture_parity",
      interval_status = "planned",
      coverage_status = "planned",
      evidence_url = "tests/testthat/test-structured-re-bridge-fixtures.R",
      claim_boundary = switch(
        structured_type,
        phylo = paste(
          "Phylo one-slope sigma fixture parity is a deterministic",
          "native/direct/R-via-Julia contract only; no broad bridge support,",
          "matched mu+sigma slope cell, labelled covariance, interval",
          "reliability, or coverage is promoted."
        ),
        spatial = paste(
          "Spatial one-slope sigma fixture parity is fixed-covariance only;",
          "no range-estimating spatial support, broad bridge support,",
          "matched mu+sigma slope cell, labelled covariance, interval",
          "reliability, or coverage is promoted."
        ),
        animal = paste(
          "Animal one-slope sigma fixture parity uses an A-matrix contract",
          "only; no pedigree/Ainv bridge marshalling, broad bridge support,",
          "matched mu+sigma slope cell, labelled covariance, interval",
          "reliability, or coverage is promoted."
        ),
        relmat = paste(
          "Relmat one-slope sigma fixture parity uses a K-matrix contract",
          "with runtime K/Q same-target parity evidence; no broad bridge",
          "support, matched mu+sigma slope cell, labelled covariance,",
          "interval reliability, or coverage is promoted."
        )
      ),
      next_gate = switch(
        structured_type,
        phylo = "Use this exact sigma fixture as the phylo same-target bridge-parity template; keep interval and coverage gates separate.",
        spatial = "Use this fixed-covariance sigma fixture as the spatial same-target bridge-parity template; keep range-estimating spatial, interval, and coverage gates separate.",
        animal = "Use this A-matrix sigma fixture as the animal same-target bridge-parity template; keep pedigree/Ainv, interval, and coverage gates separate.",
        relmat = "Use this K-matrix sigma fixture with runtime K/Q same-target parity evidence; keep intervals and coverage separate."
      ),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phase18_structured_re_mu_sigma_slope_parity_fixture_contract <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    payload <- phase18_structured_re_mu_sigma_slope_payload_fixture(
      structured_type
    )
    data.frame(
      fixture_id = paste0(
        "mu_sigma_slope_",
        structured_type,
        "_same_target_ml"
      ),
      formula_cell = switch(
        structured_type,
        phylo = "phylo(1 + x | species, tree = tree) in mu and sigma",
        spatial = "spatial(1 + x | site, coords = coords) in mu and sigma",
        animal = "animal(1 + x | id, A = A) in mu and sigma",
        relmat = "relmat(1 + x | id, K = K) in mu and sigma"
      ),
      structured_type = structured_type,
      dimension = "q1_plus_q1",
      endpoint = "mu+sigma",
      slope_class = "independent_one_slope",
      estimator = "ML",
      native_status = "fixture_available",
      direct_drmjl_status = "fixture_available",
      r_via_julia_status = "fixture_available",
      coefficient_order = paste(names(payload$estimates$coef), collapse = ";"),
      matrix_slot = switch(
        structured_type,
        phylo = "tree",
        spatial = "coords",
        animal = "A",
        relmat = "K"
      ),
      input_scale = switch(
        structured_type,
        phylo = "ultrametric_tree_branch_lengths",
        spatial = "coordinates_to_fixed_covariance_K",
        animal = "additive_covariance",
        relmat = "user_covariance"
      ),
      parity_status = "covered_same_target_fixture",
      bridge_status = "fixture_parity",
      interval_status = "planned",
      coverage_status = "planned",
      evidence_url = "tests/testthat/test-structured-re-bridge-fixtures.R",
      claim_boundary = switch(
        structured_type,
        phylo = paste(
          "Matched phylo mu+sigma one-slope fixture parity is a",
          "deterministic native/direct/R-via-Julia contract for the four",
          "endpoint members only; no broad bridge support, labelled slope",
          "covariance, interval reliability, coverage, REML, or AI-REML is",
          "promoted."
        ),
        spatial = paste(
          "Matched spatial mu+sigma one-slope fixture parity is",
          "fixed-covariance only; no range-estimating spatial support, broad",
          "bridge support, labelled slope covariance, interval reliability,",
          "coverage, REML, or AI-REML is promoted."
        ),
        animal = paste(
          "Matched animal mu+sigma one-slope fixture parity uses an A-matrix",
          "contract only; no pedigree/Ainv bridge marshalling, broad bridge",
          "support, labelled slope covariance, interval reliability,",
          "coverage, REML, or AI-REML is promoted."
        ),
        relmat = paste(
          "Matched relmat mu+sigma one-slope fixture parity uses a K-matrix",
          "contract with runtime K/Q same-target parity evidence; no Q",
          "bridge marshalling, broad bridge support, labelled slope",
          "covariance, interval reliability, coverage, REML, or AI-REML is",
          "promoted."
        )
      ),
      next_gate = switch(
        structured_type,
        phylo = "Use this exact matched fixture for calibrated interval diagnostics; keep coverage, REML, and AI-REML separate.",
        spatial = "Use this fixed-covariance matched fixture for calibrated interval diagnostics; keep range-estimating spatial, coverage, REML, and AI-REML separate.",
        animal = "Use this A-matrix matched fixture for calibrated interval diagnostics; keep pedigree/Ainv, coverage, REML, and AI-REML separate.",
        relmat = "Use this K-matrix matched fixture with runtime K/Q same-target parity evidence for calibrated interval diagnostics; keep Q bridge marshalling, coverage, REML, and AI-REML separate."
      ),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phase18_structured_re_q2_slope_parity_fixture_contract <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    payload <- phase18_structured_re_q2_slope_payload_fixture(
      structured_type
    )
    data.frame(
      fixture_id = paste0("q2_slope_", structured_type, "_same_target_ml"),
      formula_cell = switch(
        structured_type,
        phylo = "phylo(0 + x | p | species, tree = tree) in mu1 and mu2",
        spatial = "spatial(0 + x | p | site, coords = coords) in mu1 and mu2",
        animal = "animal(0 + x | p | id, A = A) in mu1 and mu2",
        relmat = "relmat(0 + x | p | id, K = K) in mu1 and mu2"
      ),
      structured_type = structured_type,
      dimension = "q2",
      endpoint = "mu1+mu2",
      slope_class = "labelled_slope_covariance",
      estimator = "ML",
      native_status = "fixture_available",
      direct_drmjl_status = "fixture_available",
      r_via_julia_status = "fixture_available",
      coefficient_order = paste(names(payload$estimates$coef), collapse = ";"),
      matrix_slot = switch(
        structured_type,
        phylo = "tree",
        spatial = "coords",
        animal = "A",
        relmat = "K"
      ),
      input_scale = switch(
        structured_type,
        phylo = "ultrametric_tree_branch_lengths",
        spatial = "coordinates_to_fixed_covariance_K",
        animal = "additive_covariance",
        relmat = "user_covariance"
      ),
      parity_status = "covered_same_target_fixture",
      bridge_status = "fixture_parity",
      interval_status = "planned",
      coverage_status = "planned",
      evidence_url = "tests/testthat/test-structured-re-bridge-fixtures.R",
      claim_boundary = switch(
        structured_type,
        phylo = paste(
          "Phylo slope-only q2 mu1/mu2 fixture parity is a deterministic",
          "native/direct/R-via-Julia contract for the two slope endpoint",
          "members only; no broad bridge support, intercept-plus-slope",
          "q4/q8, interval reliability, coverage, REML, or AI-REML is",
          "promoted."
        ),
        spatial = paste(
          "Spatial slope-only q2 mu1/mu2 fixture parity is fixed-covariance",
          "only; no range-estimating spatial support, broad bridge support,",
          "intercept-plus-slope q4/q8, interval reliability, coverage,",
          "REML, or AI-REML is promoted."
        ),
        animal = paste(
          "Animal slope-only q2 mu1/mu2 fixture parity uses an A-matrix",
          "contract only; no pedigree/Ainv bridge marshalling, broad bridge",
          "support, intercept-plus-slope q4/q8, interval reliability,",
          "coverage, REML, or AI-REML is promoted."
        ),
        relmat = paste(
          "Relmat slope-only q2 mu1/mu2 fixture parity uses a K-matrix",
          "contract with runtime K/Q same-target parity evidence; no Q",
          "bridge marshalling, broad bridge support, intercept-plus-slope",
          "q4/q8, interval reliability, coverage, REML, or AI-REML is",
          "promoted."
        )
      ),
      next_gate = switch(
        structured_type,
        phylo = "Use this exact slope-only q2 fixture for calibrated interval diagnostics; keep intercept-plus-slope q4/q8, coverage, REML, and AI-REML separate.",
        spatial = "Use this fixed-covariance slope-only q2 fixture for calibrated interval diagnostics; keep range-estimating spatial, coverage, REML, and AI-REML separate.",
        animal = "Use this A-matrix slope-only q2 fixture for calibrated interval diagnostics; keep pedigree/Ainv, coverage, REML, and AI-REML separate.",
        relmat = "Use this K-matrix slope-only q2 fixture with runtime K/Q same-target parity evidence for calibrated interval diagnostics; keep Q bridge marshalling, coverage, REML, and AI-REML separate."
      ),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phase18_structured_re_q4_intercept_parity_fixture_contract <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    payload <- phase18_structured_re_q4_intercept_payload_fixture(
      structured_type
    )
    data.frame(
      fixture_id = paste0("q4_intercept_", structured_type, "_same_target_ml"),
      formula_cell = switch(
        structured_type,
        phylo = "phylo(1 | p | species, tree = tree) in all four endpoints",
        spatial = "spatial(1 | p | site, coords = coords) in all four endpoints",
        animal = "animal(1 | p | id, A = A) in all four endpoints",
        relmat = "relmat(1 | p | id, K = K) in all four endpoints"
      ),
      structured_type = structured_type,
      dimension = "q4",
      endpoint = "mu1+mu2+sigma1+sigma2",
      slope_class = "intercept_only",
      estimator = "ML",
      native_status = "fixture_available",
      direct_drmjl_status = "fixture_available",
      r_via_julia_status = "fixture_available",
      coefficient_order = paste(names(payload$estimates$coef), collapse = ";"),
      matrix_slot = switch(
        structured_type,
        phylo = "tree",
        spatial = "coords",
        animal = "A",
        relmat = "K"
      ),
      input_scale = switch(
        structured_type,
        phylo = "ultrametric_tree_branch_lengths",
        spatial = "coordinates_to_fixed_covariance_K",
        animal = "additive_covariance",
        relmat = "user_covariance"
      ),
      parity_status = "covered_same_target_fixture",
      bridge_status = "fixture_parity",
      interval_status = "planned",
      coverage_status = "planned",
      evidence_url = "tests/testthat/test-structured-re-bridge-fixtures.R",
      claim_boundary = switch(
        structured_type,
        phylo = paste(
          "Phylo q4 all-four intercept fixture parity is a deterministic",
          "native/direct/R-via-Julia contract for the exact four-endpoint",
          "q4 map only; no interval reliability, interval coverage, q4",
          "REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad",
          "bridge support, or public support is promoted."
        ),
        spatial = paste(
          "Spatial q4 all-four intercept fixture parity is fixed-covariance",
          "only for the exact four-endpoint q4 map; no range-estimating",
          "spatial support, interval reliability, interval coverage, q4",
          "REML, native-TMB q4 REML, q4 AI-REML, broad bridge support, or",
          "public support is promoted."
        ),
        animal = paste(
          "Animal q4 all-four intercept fixture parity uses an A-matrix",
          "contract for the exact four-endpoint q4 map only; no",
          "pedigree/Ainv bridge marshalling, interval reliability, interval",
          "coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, broad bridge",
          "support, or public support is promoted."
        ),
        relmat = paste(
          "Relmat q4 all-four intercept fixture parity uses a K-matrix",
          "contract for the exact four-endpoint q4 map only; Q precision",
          "marshalling remains separate, and no Q bridge marshalling,",
          "interval reliability, interval coverage, q4 REML, native-TMB q4",
          "REML, q4 AI-REML, broad bridge support, or public support is",
          "promoted."
        )
      ),
      next_gate = switch(
        structured_type,
        phylo = "Use the existing q4 phylo parity gate for calibrated interval diagnostics; keep coverage, q4 REML, and AI-REML separate.",
        spatial = "Use this fixed-covariance q4 intercept fixture for interval diagnostics; keep range-estimating spatial, coverage, q4 REML, and AI-REML separate.",
        animal = "Use this A-matrix q4 intercept fixture for interval diagnostics; keep pedigree/Ainv, coverage, q4 REML, and AI-REML separate.",
        relmat = "Use this K-matrix q4 intercept fixture for interval diagnostics; keep Q bridge marshalling, coverage, q4 REML, and AI-REML separate."
      ),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phase18_structured_re_q4_intercept_interval_diagnostic_plan <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  endpoint_members <- c("mu1", "mu2", "sigma1", "sigma2")
  endpoint_labels <- paste0(endpoint_members, ":(Intercept)")
  cor_pairs <- utils::combn(endpoint_members, 2L, simplify = FALSE)

  rows <- lapply(structured_types, function(structured_type) {
    contract <- phase18_structured_re_q4_intercept_parity_fixture_contract()
    provider_contract <- contract[
      contract$structured_type == structured_type,
      ,
      drop = FALSE
    ]
    if (nrow(provider_contract) != 1L) {
      stop("missing q4 intercept fixture contract for ", structured_type)
    }

    formula_cell <- provider_contract$formula_cell[[1L]]
    cell_id <- paste0("qseries_", structured_type, "_q4_all_four_intercept")
    group_label <- switch(
      structured_type,
      phylo = "species",
      spatial = "site",
      animal = "id",
      relmat = "id"
    )
    provider_boundary <- switch(
      structured_type,
      phylo = "Phylo",
      spatial = "Fixed-covariance spatial",
      animal = "Animal A-matrix",
      relmat = "Relmat K-matrix"
    )
    provider_clause <- switch(
      structured_type,
      phylo = "",
      spatial = " no range-estimating spatial support,",
      animal = " no pedigree/Ainv bridge marshalling,",
      relmat = " no Q bridge marshalling,"
    )
    next_gate <- switch(
      structured_type,
      phylo = "Run deterministic phylo target-level Wald/profile/bootstrap smoke before calibrated coverage wording.",
      spatial = "Run deterministic fixed-covariance target-level Wald/profile/bootstrap smoke before calibrated coverage wording.",
      animal = "Run deterministic A-matrix target-level Wald/profile/bootstrap smoke before calibrated coverage wording.",
      relmat = "Run deterministic K-matrix target-level Wald/profile/bootstrap smoke before calibrated coverage wording."
    )

    direct_rows <- lapply(seq_along(endpoint_members), function(index) {
      endpoint <- endpoint_members[[index]]
      endpoint_label <- endpoint_labels[[index]]
      data.frame(
        diagnostic_id = paste(
          "q4_intercept_interval",
          structured_type,
          "sd",
          endpoint,
          sep = "_"
        ),
        cell_id = cell_id,
        formula_cell = formula_cell,
        structured_type = structured_type,
        target_kind = "direct_sd",
        endpoint_member = endpoint_label,
        estimand = paste0("sd_", endpoint, "_intercept"),
        profile_target = paste0(
          "sd:mu:",
          endpoint,
          ":",
          structured_type,
          "(1 | p | ",
          group_label,
          ")"
        ),
        interval_methods = "wald;profile;bootstrap",
        required_fit_evidence = paste(
          "point_fit",
          "extractor_ready",
          "profile_targets_direct_ready",
          "same_target_fixture_parity",
          sep = ";"
        ),
        required_interval_evidence = paste(
          "finite_direct_sd_intervals_by_method",
          "coverage_mcse<=0.01",
          sep = ";"
        ),
        denominator_fields = paste(
          "coverage_denominator",
          "n_total",
          "n_fit_ok",
          "n_failed_fit",
          "n_pdhess",
          "n_interval_finite",
          "n_interval_unavailable",
          "coverage_mcse",
          sep = ";"
        ),
        current_blocker = "interval_diagnostics_not_run",
        status = "planned",
        evidence_url = "docs/dev-log/after-task/2026-06-25-q4-intercept-interval-diagnostic-plan.md",
        claim_boundary = paste0(
          provider_boundary,
          " q4 all-four intercept direct-SD interval diagnostic plan only;",
          provider_clause,
          " no interval reliability, interval coverage, q4 REML,",
          " native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad",
          " bridge support, public support, or calibrated coverage wording",
          " is promoted."
        ),
        next_gate = next_gate,
        stringsAsFactors = FALSE
      )
    })

    cor_rows <- lapply(cor_pairs, function(pair) {
      left <- pair[[1L]]
      right <- pair[[2L]]
      axis_pair <- paste(left, right, sep = "_")
      data.frame(
        diagnostic_id = paste(
          "q4_intercept_interval",
          structured_type,
          "cor",
          axis_pair,
          sep = "_"
        ),
        cell_id = cell_id,
        formula_cell = formula_cell,
        structured_type = structured_type,
        target_kind = "derived_correlation",
        endpoint_member = paste0(
          left,
          ":(Intercept)+",
          right,
          ":(Intercept)"
        ),
        estimand = paste0("cor_", axis_pair),
        profile_target = paste0(
          "derived:",
          structured_type,
          ":cor(",
          left,
          ":(Intercept),",
          right,
          ":(Intercept) | p | ",
          group_label,
          ")"
        ),
        interval_methods = "delta;profile;bootstrap",
        required_fit_evidence = paste(
          "point_fit",
          "extractor_ready",
          "corpairs_point_reconstruction",
          "same_target_fixture_parity",
          "derived_interval_reconstruction_planned",
          sep = ";"
        ),
        required_interval_evidence = paste(
          "finite_derived_correlation_intervals_by_method",
          "coverage_mcse<=0.01",
          sep = ";"
        ),
        denominator_fields = paste(
          "coverage_denominator",
          "n_total",
          "n_fit_ok",
          "n_failed_fit",
          "n_pdhess",
          "n_interval_finite",
          "n_interval_unavailable",
          "coverage_mcse",
          sep = ";"
        ),
        current_blocker = "derived_correlation_interval_reconstruction_not_available",
        status = "planned",
        evidence_url = "docs/dev-log/after-task/2026-06-25-q4-intercept-interval-diagnostic-plan.md",
        claim_boundary = paste0(
          provider_boundary,
          " q4 all-four intercept derived-correlation interval diagnostic",
          " plan only; derived correlation interval reconstruction is not",
          " available, and",
          provider_clause,
          " no interval reliability, interval coverage, q4 REML,",
          " native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad",
          " bridge support, public support, or calibrated coverage wording",
          " is promoted."
        ),
        next_gate = paste(
          "Design derived-correlation interval reconstruction before",
          "calibrated coverage wording."
        ),
        stringsAsFactors = FALSE
      )
    })

    do.call(rbind, c(direct_rows, cor_rows))
  })

  do.call(rbind, rows)
}

phase18_structured_re_q4_location_slope_parity_fixture_contract <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    payload <- phase18_structured_re_q4_location_slope_payload_fixture(
      structured_type
    )
    data.frame(
      fixture_id = paste0(
        "q4_location_slope_",
        structured_type,
        "_same_target_ml"
      ),
      formula_cell = switch(
        structured_type,
        phylo = "phylo(1 + x | p | species, tree = tree) in mu1 and mu2",
        spatial = "spatial(1 + x | p | site, coords = coords) in mu1 and mu2",
        animal = "animal(1 + x | p | id, A = A) in mu1 and mu2",
        relmat = "relmat(1 + x | p | id, K = K) in mu1 and mu2"
      ),
      structured_type = structured_type,
      dimension = "q4",
      endpoint = "mu1+mu2",
      slope_class = "labelled_slope_covariance",
      estimator = "ML",
      native_status = "fixture_available",
      direct_drmjl_status = "fixture_available",
      r_via_julia_status = "fixture_available",
      coefficient_order = paste(names(payload$estimates$coef), collapse = ";"),
      matrix_slot = switch(
        structured_type,
        phylo = "tree",
        spatial = "coords",
        animal = "A",
        relmat = "K"
      ),
      input_scale = switch(
        structured_type,
        phylo = "ultrametric_tree_branch_lengths",
        spatial = "coordinates_to_fixed_covariance_K",
        animal = "additive_covariance",
        relmat = "user_covariance"
      ),
      parity_status = "covered_same_target_fixture",
      bridge_status = "fixture_parity",
      interval_status = "planned",
      coverage_status = "planned",
      evidence_url = "tests/testthat/test-structured-re-bridge-fixtures.R",
      claim_boundary = switch(
        structured_type,
        phylo = paste(
          "Phylo q4 location one-slope fixture parity is a deterministic",
          "native/direct/R-via-Julia contract for the exact four-member",
          "q4 location endpoint map only; no broad bridge support,",
          "partial location-scale support, interval reliability, coverage,",
          "q4 REML, AI-REML, public support, or broader q8 support is",
          "promoted."
        ),
        spatial = paste(
          "Spatial q4 location one-slope fixture parity is fixed-covariance",
          "only for the exact four-member q4 location endpoint map; no",
          "range-estimating spatial support, broad bridge support, partial",
          "location-scale support, interval reliability, coverage, q4 REML,",
          "AI-REML, public support, or broader q8 support is promoted."
        ),
        animal = paste(
          "Animal q4 location one-slope fixture parity uses an A-matrix",
          "contract for the exact four-member q4 location endpoint map only;",
          "no pedigree/Ainv bridge marshalling, broad bridge support, partial",
          "location-scale support, interval reliability, coverage, q4 REML,",
          "AI-REML, public support, or broader q8 support is promoted."
        ),
        relmat = paste(
          "Relmat q4 location one-slope fixture parity uses a K-matrix",
          "contract for the exact four-member q4 location endpoint map only;",
          "Q precision marshalling remains separate, and no broad bridge",
          "support, partial location-scale support, interval reliability,",
          "coverage, q4 REML, AI-REML, public support, or broader q8 support",
          "is promoted."
        )
      ),
      next_gate = switch(
        structured_type,
        phylo = "Use this exact q4 location fixture for interval diagnostics; keep partial location-scale, coverage, q4 REML, and AI-REML separate.",
        spatial = "Use this fixed-covariance q4 location fixture for interval diagnostics; keep range-estimating spatial, partial location-scale, coverage, q4 REML, and AI-REML separate.",
        animal = "Use this A-matrix q4 location fixture for interval diagnostics; keep pedigree/Ainv, partial location-scale, coverage, q4 REML, and AI-REML separate.",
        relmat = "Use this K-matrix q4 location fixture for interval diagnostics; keep Q precision marshalling, partial location-scale, coverage, q4 REML, and AI-REML separate."
      ),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phase18_structured_re_q4_slope_parity_fixture_contract <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    payload <- phase18_structured_re_q4_slope_payload_fixture(
      structured_type
    )
    data.frame(
      fixture_id = paste0("q4_slope_", structured_type, "_same_target_ml"),
      formula_cell = switch(
        structured_type,
        phylo = "phylo(1 + x | p | species, tree = tree) in all four endpoints",
        spatial = "spatial(1 + x | p | site, coords = coords) in all four endpoints",
        animal = "animal(1 + x | p | id, A = A) in all four endpoints",
        relmat = "relmat(1 + x | p | id, K = K) in all four endpoints"
      ),
      structured_type = structured_type,
      dimension = "q8",
      endpoint = "mu1+mu2+sigma1+sigma2",
      slope_class = "labelled_slope_covariance",
      estimator = "ML",
      native_status = "fixture_available",
      direct_drmjl_status = "fixture_available",
      r_via_julia_status = "fixture_available",
      coefficient_order = paste(names(payload$estimates$coef), collapse = ";"),
      matrix_slot = switch(
        structured_type,
        phylo = "tree",
        spatial = "coords",
        animal = "A",
        relmat = "K"
      ),
      input_scale = switch(
        structured_type,
        phylo = "ultrametric_tree_branch_lengths",
        spatial = "coordinates_to_fixed_covariance_K",
        animal = "additive_covariance",
        relmat = "user_covariance"
      ),
      parity_status = "covered_same_target_fixture",
      bridge_status = "fixture_parity",
      interval_status = "planned",
      coverage_status = "planned",
      evidence_url = "tests/testthat/test-structured-re-bridge-fixtures.R",
      claim_boundary = switch(
        structured_type,
        phylo = paste(
          "Phylo q4 all-four one-slope fixture parity is a deterministic",
          "native/direct/R-via-Julia contract for the exact eight-member",
          "q8 endpoint map only; no broad bridge support, interval",
          "reliability, coverage, q4 REML, or AI-REML is promoted."
        ),
        spatial = paste(
          "Spatial q4 all-four one-slope fixture parity is fixed-covariance",
          "only for the exact eight-member q8 endpoint map; no",
          "range-estimating spatial support, broad bridge support, interval",
          "reliability, coverage, q4 REML, or AI-REML is promoted."
        ),
        animal = paste(
          "Animal q4 all-four one-slope fixture parity uses an A-matrix",
          "contract for the exact eight-member q8 endpoint map only; no",
          "pedigree/Ainv bridge marshalling, broad bridge support, interval",
          "reliability, coverage, q4 REML, or AI-REML is promoted."
        ),
        relmat = paste(
          "Relmat q4 all-four one-slope fixture parity uses a K-matrix",
          "contract with runtime K/Q same-target parity evidence for the",
          "exact eight-member q8 endpoint map; no Q bridge marshalling,",
          "broad bridge support, interval reliability, coverage, q4 REML,",
          "or AI-REML is promoted."
        )
      ),
      next_gate = switch(
        structured_type,
        phylo = "Use this exact q4-slope fixture for interval diagnostics; keep coverage, q4 REML, and AI-REML separate.",
        spatial = "Use this fixed-covariance q4-slope fixture for interval diagnostics; keep range-estimating spatial, coverage, q4 REML, and AI-REML separate.",
        animal = "Use this A-matrix q4-slope fixture for interval diagnostics; keep pedigree/Ainv, coverage, q4 REML, and AI-REML separate.",
        relmat = "Use this K-matrix q4-slope fixture with runtime K/Q same-target parity evidence for interval diagnostics; keep Q bridge marshalling, coverage, q4 REML, and AI-REML separate."
      ),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phase18_structured_re_relmat_kq_one_slope_native_parity_contract <- function() {
  claim_boundary <- paste(
    "Native R/TMB relmat K/Q same-target parity is banked only for",
    "the exact named one-slope cell; Q precision remains native",
    "runtime evidence only and is not direct DRM.jl or R-via-Julia",
    "bridge evidence. No broad bridge support, interval reliability,",
    "coverage, REML, AI-REML, q4 REML, native-TMB q4 REML, q4 AI-REML,",
    "HSquared AI-REML, non-Gaussian REML, public support, or broader",
    "q8 support is promoted."
  )
  next_gate <- paste(
    "Use this native K/Q parity only as runtime evidence; review Q",
    "precision payload marshalling, matrix digest, level alignment,",
    "coefficient order, and provenance separately before any bridge",
    "update."
  )
  data.frame(
    parity_id = c(
      "relmat_kq_native_q1_mu_one_slope",
      "relmat_kq_native_q1_sigma_one_slope",
      "relmat_kq_native_q1_mu_sigma_one_slope",
      "relmat_kq_native_q2_mu1_mu2_one_slope",
      "relmat_kq_native_q4_mu1_mu2_one_slope",
      "relmat_kq_native_q8_all_four_one_slope"
    ),
    cell_id = c(
      "qseries_relmat_q1_mu_one_slope",
      "qseries_relmat_q1_sigma_one_slope",
      "qseries_relmat_q1_mu_sigma_one_slope",
      "qseries_relmat_q2_mu1_mu2_one_slope",
      "qseries_relmat_q4_mu1_mu2_one_slope",
      "qseries_relmat_q4_all_four_one_slope_planned"
    ),
    formula_cell = c(
      "relmat(1 + x | id, K/Q = ...) in mu",
      "relmat(1 + x | id, K/Q = ...) in sigma",
      "relmat(1 + x | id, K/Q = ...) in mu and sigma",
      "relmat(0 + x | p | id, K/Q = ...) in mu1 and mu2",
      "relmat(1 + x | p | id, K/Q = ...) in mu1 and mu2",
      "relmat(1 + x | p | id, K/Q = ...) in all four endpoints"
    ),
    dimension_pattern = c("q1", "q1", "q1_plus_q1", "q2", "q4", "q8"),
    endpoint_set = c(
      "mu",
      "sigma",
      "mu+sigma",
      "mu1+mu2",
      "mu1+mu2",
      "mu1+mu2+sigma1+sigma2"
    ),
    slope_class = c(
      "independent_one_slope",
      "independent_one_slope",
      "independent_one_slope",
      "labelled_slope_covariance",
      "labelled_slope_covariance",
      "labelled_slope_covariance"
    ),
    k_input_scale = "user_covariance",
    q_input_scale = "user_precision",
    k_runtime_status = "point_fit",
    q_runtime_status = "point_fit",
    parity_status = "runtime_kq_same_target_parity",
    extractor_status = "matched_member_identity",
    bridge_q_status = "unsupported",
    direct_drmjl_q_status = "unsupported",
    r_via_julia_q_status = "unsupported",
    interval_status = "planned",
    coverage_status = "planned",
    evidence_url = "tests/testthat/test-animal-relmat-gaussian.R",
    claim_boundary = claim_boundary,
    next_gate = next_gate,
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_relmat_q_payload_cells <- function() {
  data.frame(
    suffix = c(
      "q1_mu_one_slope",
      "q1_sigma_one_slope",
      "q1_mu_sigma_one_slope",
      "q2_mu1_mu2_one_slope",
      "q4_mu1_mu2_one_slope",
      "q8_all_four_one_slope"
    ),
    boundary_id = c(
      "relmat_q_bridge_q1_mu_one_slope",
      "relmat_q_bridge_q1_sigma_one_slope",
      "relmat_q_bridge_q1_mu_sigma_one_slope",
      "relmat_q_bridge_q2_mu1_mu2_one_slope",
      "relmat_q_bridge_q4_mu1_mu2_one_slope",
      "relmat_q_bridge_q8_all_four_one_slope"
    ),
    cell_id = c(
      "qseries_relmat_q1_mu_one_slope",
      "qseries_relmat_q1_sigma_one_slope",
      "qseries_relmat_q1_mu_sigma_one_slope",
      "qseries_relmat_q2_mu1_mu2_one_slope",
      "qseries_relmat_q4_mu1_mu2_one_slope",
      "qseries_relmat_q4_all_four_one_slope_planned"
    ),
    formula_cell = c(
      "relmat(1 + x | id, K/Q = ...) in mu",
      "relmat(1 + x | id, K/Q = ...) in sigma",
      "relmat(1 + x | id, K/Q = ...) in mu and sigma",
      "relmat(0 + x | p | id, K/Q = ...) in mu1 and mu2",
      "relmat(1 + x | p | id, K/Q = ...) in mu1 and mu2",
      "relmat(1 + x | p | id, K/Q = ...) in all four endpoints"
    ),
    dimension_pattern = c("q1", "q1", "q1_plus_q1", "q2", "q4", "q8"),
    endpoint_set = c(
      "mu",
      "sigma",
      "mu+sigma",
      "mu1+mu2",
      "mu1+mu2",
      "mu1+mu2+sigma1+sigma2"
    ),
    slope_class = c(
      "independent_one_slope",
      "independent_one_slope",
      "independent_one_slope",
      "labelled_slope_covariance",
      "labelled_slope_covariance",
      "labelled_slope_covariance"
    ),
    coefficient_order_policy = c(
      "mu:(Intercept);mu:x",
      "sigma:(Intercept);sigma:x",
      "mu:(Intercept);mu:x;sigma:(Intercept);sigma:x",
      "mu1:x;mu2:x",
      "mu1:(Intercept);mu1:x;mu2:(Intercept);mu2:x",
      paste(
        "mu1:(Intercept);mu1:x;mu2:(Intercept);mu2:x;",
        "sigma1:(Intercept);sigma1:x;sigma2:(Intercept);sigma2:x",
        sep = ""
      )
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_relmat_q_payload_contract_review <- function() {
  cells <- phase18_structured_re_relmat_q_payload_cells()
  claim_boundary <- paste(
    "Relmat Q payload contract review only; native Q runtime parity is not",
    "Q bridge evidence, and this reviewed contract is not implementation.",
    "Direct DRM.jl Q support, R-via-Julia Q support, broad bridge support,",
    "interval reliability, coverage, REML, AI-REML, q4 REML, native-TMB q4",
    "REML, q4 AI-REML, HSquared AI-REML, non-Gaussian REML, public support,",
    "and broader q8 support remain unpromoted."
  )
  next_gate <- paste(
    "Implement exact Q precision payload transport only after this reviewed",
    "DRM.jl payload contract is matched in code: Q precision source, matrix",
    "digest, level alignment, missing-level policy, coefficient order, and",
    "provenance must be tested before direct DRM.jl or R-via-Julia Q bridge",
    "status can move."
  )
  data.frame(
    contract_id = paste0("relmat_q_payload_contract_", cells$suffix),
    gate_id = paste0("relmat_q_payload_gate_", cells$suffix),
    boundary_id = cells$boundary_id,
    cell_id = cells$cell_id,
    formula_cell = cells$formula_cell,
    dimension_pattern = cells$dimension_pattern,
    endpoint_set = cells$endpoint_set,
    slope_class = cells$slope_class,
    payload_schema_status = "contract_reviewed",
    payload_review_status = "reviewed_not_implemented",
    matrix_id_policy = "stable_relmat_q_payload_id_per_formula_cell",
    matrix_digest_policy = "digest_user_supplied_Q_precision_matrix_without_inverting",
    input_scale_policy = "user_precision",
    precision_source_policy = "Q_argument_must_be_explicit_precision_source",
    level_alignment_policy = "rownames_and_colnames_must_match_observed_relmat_levels_after_data_ordering",
    missing_level_policy = "fail_closed_on_missing_or_extra_levels_before_julia_call",
    coefficient_order_policy = cells$coefficient_order_policy,
    provenance_policy = "record_repo_branch_head_payload_version_formula_cell_matrix_digest_input_scale_levels_and_dirty_state",
    conversion_policy = "no_implicit_Q_to_K_conversion_in_R_bridge_payload",
    direct_drmjl_q_status = "unsupported",
    r_via_julia_q_status = "unsupported",
    bridge_q_status = "unsupported",
    implementation_status = "contract_only_not_implemented",
    acceptance_status = "blocked_pending_exact_q_transport",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-26-relmat-q-payload-contract-review.md",
    claim_boundary = claim_boundary,
    next_gate = next_gate,
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_relmat_q_payload_marshalling_gate <- function() {
  contract <- phase18_structured_re_relmat_q_payload_contract_review()
  required_payload_fields <- paste(
    c(
      "matrix_id",
      "matrix_digest",
      "input_scale",
      "precision_source",
      "level_alignment",
      "missing_level_policy",
      "coefficient_order",
      "provenance"
    ),
    collapse = ";"
  )
  required_payload_checks <- paste(
    c(
      "precision_source=Q",
      "digest_user_Q",
      "level_names_match_observed_ids",
      "coefficient_order_matches_endpoint_members",
      "no_implicit_K_conversion",
      "provenance_records_precision_input"
    ),
    collapse = ";"
  )
  claim_boundary <- paste(
    "Relmat Q payload-marshalling gate only; native Q runtime parity is not",
    "Q bridge evidence, and the reviewed payload contract is not bridge",
    "implementation. It does not promote direct DRM.jl Q support,",
    "R-via-Julia Q support, broad bridge support, interval reliability,",
    "coverage, REML, AI-REML, q4 REML, native-TMB q4 REML, q4 AI-REML,",
    "HSquared AI-REML, non-Gaussian REML, public support, or broader q8",
    "support."
  )
  next_gate <- paste(
    "Use the reviewed DRM.jl payload contract to implement exact Q precision",
    "source, matrix digest, level alignment, missing-level policy, coefficient",
    "order, and provenance tests before direct DRM.jl or R-via-Julia Q bridge",
    "status can move."
  )
  data.frame(
    gate_id = contract$gate_id,
    boundary_id = contract$boundary_id,
    cell_id = contract$cell_id,
    formula_cell = contract$formula_cell,
    dimension_pattern = contract$dimension_pattern,
    endpoint_set = contract$endpoint_set,
    slope_class = contract$slope_class,
    native_q_status = "runtime_kq_same_target_parity",
    required_payload_fields = required_payload_fields,
    required_payload_checks = required_payload_checks,
    payload_schema_status = contract$payload_schema_status,
    payload_review_status = contract$payload_review_status,
    direct_drmjl_q_status = contract$direct_drmjl_q_status,
    r_via_julia_q_status = contract$r_via_julia_q_status,
    bridge_q_status = contract$bridge_q_status,
    acceptance_status = contract$acceptance_status,
    status = contract$status,
    evidence_url = "docs/dev-log/dashboard/structured-re-relmat-q-payload-contract-review.tsv",
    claim_boundary = claim_boundary,
    next_gate = next_gate,
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_relmat_q_drmjl_provider_readiness <- function() {
  data.frame(
    readiness_id = c(
      "drmjl_q2_known_precision_bridge_primitive_pr299",
      "drmjl_q2_known_precision_provider_contract_pr300",
      "drmtmb_relmat_q_transport_gate_after_pr665"
    ),
    dependency_ref = c(
      "DRM.jl#299",
      "DRM.jl#300",
      "drmTMB#665_payload_contract"
    ),
    repo = c("DRM.jl", "DRM.jl", "drmTMB"),
    branch = c(
      "codex/q2-known-precision-bridge",
      "codex/q2-known-precision-provider-contract",
      "codex/relmat-q-payload-contract-review"
    ),
    base_branch = c(
      "codex/q2-q4-direct-export-contracts",
      "codex/q2-known-precision-bridge",
      "codex/pr-stack-readiness-656-662"
    ),
    head_oid = c(
      "c2c2404cb9883d3a7f111b7f2256572049d9f873",
      "e9510f230fb34e33ebf206e632eb8397c093f0a1",
      "9216d723665414f0965e329dc580a4975fd80e42"
    ),
    review_state = "draft",
    merge_state_status = "CLEAN",
    ci_status = c(
      "manual_workflow_success",
      "manual_workflow_success",
      "manual_r_cmd_check_success"
    ),
    documenter_status = c(
      "manual_workflow_success",
      "manual_workflow_success",
      "not_applicable"
    ),
    local_validation_status = c(
      "local_recheck_passed",
      "local_recheck_passed",
      "mission_control_passed"
    ),
    scope_boundary = c(
      paste(
        "Upstream q2 known-precision bridge primitive for complete-response",
        "exact-Gaussian ML fixtures only; not an R relmat Q payload route."
      ),
      paste(
        "Upstream q2 known-precision provider contract for relmat(Q) and",
        "animal(Ainv) identity only; not six-cell drmTMB relmat Q support."
      ),
      paste(
        "R-side relmat Q payload contract and marshalling gate only; exact",
        "Q precision transport remains unimplemented."
      )
    ),
    upstream_dependency_status = c(
      "draft_green_not_merged",
      "draft_green_not_merged",
      "waiting_for_drmjl_299_300_review_merge"
    ),
    relmat_q_bridge_status = c(
      "not_r_bridge_transport",
      "not_r_bridge_transport",
      "unsupported"
    ),
    drmtmb_transport_status = c(
      "blocked_pending_upstream_merge_and_r_payload_implementation",
      "blocked_pending_upstream_merge_and_r_payload_implementation",
      "contract_only_not_implemented"
    ),
    evidence_url = c(
      "https://github.com/itchyshin/DRM.jl/pull/299",
      "https://github.com/itchyshin/DRM.jl/pull/300",
      "docs/dev-log/dashboard/structured-re-relmat-q-payload-contract-review.tsv"
    ),
    claim_boundary = c(
      paste(
        "DRM.jl #299 is draft upstream q2 known-precision primitive evidence",
        "only; it is not merged, not R-via-Julia relmat Q transport, not",
        "broad bridge support, not interval reliability, not coverage, not",
        "REML, not AI-REML, and not public support."
      ),
      paste(
        "DRM.jl #300 is draft upstream provider-contract evidence only;",
        "relmat(Q) and animal(Ainv) identity is not six-cell drmTMB relmat",
        "Q bridge implementation, not broad bridge support, not interval",
        "reliability, not coverage, not REML, not AI-REML, and not public",
        "support."
      ),
      paste(
        "drmTMB relmat Q payload contract review is not implementation.",
        "Direct DRM.jl Q support, R-via-Julia Q support, broad bridge",
        "support, interval reliability, coverage, REML, AI-REML, q4 REML,",
        "native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, non-Gaussian",
        "REML, public support, and broader q8 support remain unpromoted."
      )
    ),
    next_gate = c(
      paste(
        "After DRM.jl #297 and #298 are accepted, review #299 at diff",
        "granularity; merge only after approval, then keep #300 stacked",
        "until #299 is accepted."
      ),
      paste(
        "After #299 is accepted, retarget or rebase #300, rerun CI and",
        "Documenter, and merge only after approval; do not treat draft-green",
        "provider evidence as drmTMB bridge support."
      ),
      paste(
        "After #299 and #300 are accepted, implement exact Q precision",
        "payload transport matching the reviewed contract: Q source, matrix",
        "digest, level alignment, missing-level policy, coefficient order,",
        "and provenance."
      )
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_relmat_q_drmjl_stack_review <- function() {
  data.frame(
    review_id = c(
      "drmjl_pr297_loconly_reml_review",
      "drmjl_pr298_q2_q4_direct_export_review",
      "drmjl_pr299_q2_known_precision_bridge_review",
      "drmjl_pr300_q2_known_precision_provider_review",
      "drmtmb_pr666_relmat_q_readiness_decision"
    ),
    dependency_ref = c(
      "DRM.jl#297",
      "DRM.jl#298",
      "DRM.jl#299",
      "DRM.jl#300",
      "drmTMB#666"
    ),
    repo = c("DRM.jl", "DRM.jl", "DRM.jl", "DRM.jl", "drmTMB"),
    branch = c(
      "codex/ai-reml-gaussian-mme-pilot",
      "codex/q2-q4-direct-export-contracts",
      "codex/q2-known-precision-bridge",
      "codex/q2-known-precision-provider-contract",
      "codex/relmat-q-drmjl-provider-readiness"
    ),
    base_branch = c(
      "main",
      "codex/ai-reml-gaussian-mme-pilot",
      "codex/q2-q4-direct-export-contracts",
      "codex/q2-known-precision-bridge",
      "codex/relmat-q-payload-contract-review"
    ),
    head_oid = c(
      "2ca40a50cbc66634c25ae52a410cdda3bbb701d2",
      "17c6374f8f76bca2503030b9524adde7a576dc24",
      "c2c2404cb9883d3a7f111b7f2256572049d9f873",
      "e9510f230fb34e33ebf206e632eb8397c093f0a1",
      "1a73dd62192f7248d2e1dedd32939cb2cb65489a"
    ),
    pr_url = c(
      "https://github.com/itchyshin/DRM.jl/pull/297",
      "https://github.com/itchyshin/DRM.jl/pull/298",
      "https://github.com/itchyshin/DRM.jl/pull/299",
      "https://github.com/itchyshin/DRM.jl/pull/300",
      "https://github.com/itchyshin/drmTMB/pull/666"
    ),
    review_scope = c(
      paste(
        "exact-Gaussian location-only REML diagnostic review at the PR head;",
        "not relmat Q transport."
      ),
      paste(
        "q2/q4 direct export contract review at the exact PR head;",
        "point/export evidence only."
      ),
      paste(
        "q2 known-precision bridge primitive review at the exact PR head;",
        "complete-response exact-Gaussian ML fixtures only."
      ),
      paste(
        "q2 known-precision provider contract review at the exact PR head;",
        "relmat(Q) and animal(Ainv) identity only."
      ),
      paste(
        "drmTMB relmat Q provider-readiness gate exact review after #665;",
        "dependency evidence only."
      )
    ),
    remote_ci_status = c(
      "attached_pr_checks_green",
      "manual_workflow_success",
      "manual_workflow_success",
      "manual_workflow_success",
      "manual_r_cmd_check_success"
    ),
    remote_documenter_status = c(
      "attached_documenter_green",
      "manual_documenter_success",
      "manual_documenter_success",
      "manual_documenter_success",
      "not_applicable"
    ),
    exact_head_local_tests = c(
      "julia --project=. test/test_location_only_reml_mme.jl",
      paste(
        "julia --project=. test/test_bridge_q2_direct_export.jl;",
        "julia --project=. test/test_bridge_q4_direct_export.jl;",
        "julia --project=. test/test_bridge.jl"
      ),
      paste(
        "julia --project=. test/test_bridge_q2_direct_export.jl;",
        "julia --project=. test/test_bridge.jl;",
        "julia --project=. test/test_bridge_q4_direct_export.jl"
      ),
      paste(
        "julia --project=. test/test_bridge_q2_direct_export.jl;",
        "julia --project=. test/test_bridge.jl;",
        "julia --project=. test/test_bridge_q4_direct_export.jl"
      ),
      paste(
        "python3 tools/validate-mission-control.py;",
        "base-R provider-readiness generator/TSV round trip"
      )
    ),
    local_test_assertions = c(
      "602/602",
      "212/212",
      "228/228",
      "264/264",
      "not_applicable"
    ),
    merge_state_status = rep("CLEAN_DRAFT", 5L),
    review_decision = c(
      "reviewed_green_keep_draft_until_approval",
      "reviewed_green_keep_draft_until_297_accepted",
      "reviewed_green_keep_draft_until_298_accepted",
      "reviewed_green_keep_draft_until_299_accepted",
      "banked_dependency_gate_keep_draft_until_stack_order"
    ),
    downstream_permission = c(
      "does_not_unblock_relmat_q_transport",
      "unblocks_review_of_299_300_only_not_transport",
      "candidate_dependency_after_merge_not_support",
      "provider_contract_after_merge_not_transport",
      "next_code_slice_blocked_not_transport_until_upstream_merge"
    ),
    claim_boundary = c(
      paste(
        "DRM.jl #297 is Gaussian location-only REML diagnostic evidence only;",
        "not q4 REML, not native-TMB q4 REML, not q4 AI-REML, not",
        "HSquared AI-REML, not non-Gaussian REML, not broad bridge support,",
        "not interval reliability, not coverage, and not public support."
      ),
      paste(
        "DRM.jl #298 is q2/q4 direct export contract evidence only; not q2",
        "REML, not q4 REML, not native-TMB q4 REML, not q4 AI-REML, not",
        "HSquared AI-REML, not non-Gaussian REML, not broad bridge support,",
        "not interval reliability, not coverage, and not public support."
      ),
      paste(
        "DRM.jl #299 is q2 known-precision primitive evidence only; not",
        "merged, not R-via-Julia relmat Q transport, not q2 REML, not q4",
        "REML, not native-TMB q4 REML, not q4 AI-REML, not HSquared",
        "AI-REML, not non-Gaussian REML, not broad bridge support, not",
        "interval reliability, not coverage, and not public support."
      ),
      paste(
        "DRM.jl #300 is q2 known-precision provider-contract evidence only;",
        "relmat(Q) and animal(Ainv) identity is not drmTMB relmat Q",
        "transport, not q2 REML, not q4 REML, not native-TMB q4 REML,",
        "not q4 AI-REML, not HSquared AI-REML, not non-Gaussian REML,",
        "not broad bridge support, not interval reliability, not coverage,",
        "and not public support."
      ),
      paste(
        "drmTMB #666 is dependency-readiness evidence only; it is not",
        "relmat Q payload transport, not direct DRM.jl Q export from drmTMB,",
        "not R-via-Julia Q transport, not q4 REML, not native-TMB q4 REML,",
        "not q4 AI-REML, not HSquared AI-REML, not non-Gaussian REML, not",
        "broad bridge support, not interval reliability, not coverage, not",
        "public support, and not broader q8 support."
      )
    ),
    next_gate = c(
      paste(
        "After approval, merge #297 first; then retarget #298 to main and",
        "rerun ordinary PR checks."
      ),
      paste(
        "After #297 is accepted, retarget #298 to main, rerun CI and",
        "Documenter, and merge only after approval."
      ),
      paste(
        "After #298 is accepted, retarget or rebase #299, rerun CI and",
        "Documenter, then merge only after approval."
      ),
      paste(
        "After #299 is accepted, retarget or rebase #300, rerun CI and",
        "Documenter, then merge only after approval."
      ),
      paste(
        "After #297, #298, #299, and #300 are accepted and #666 is reviewed,",
        "implement exact Q precision payload transport matching Q source,",
        "matrix digest, level alignment, missing-level policy, coefficient",
        "order, and provenance."
      )
    ),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_q2_fixture_contract <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  boundary <- vapply(
    structured_types,
    function(structured_type) {
      switch(
        structured_type,
        phylo = paste(
          "Q2 phylo ML fixture only; no broad bridge support promotion."
        ),
        spatial = paste(
          "Q2 spatial ML fixture is fixed-covariance only; no",
          "range-estimating spatial, mesh/SPDE, or broad bridge support",
          "promotion."
        ),
        animal = paste(
          "Q2 animal ML fixture uses an A matrix only; no pedigree/Ainv",
          "marshalling or broad bridge support promotion."
        ),
        relmat = paste(
          "Q2 relmat ML fixture uses a K matrix only; no Q precision",
          "marshalling or broad bridge support promotion."
        )
      )
    },
    character(1L)
  )
  data.frame(
    fixture_id = c(
      paste0("q2_", structured_types, "_same_target_ml"),
      "q2_plus_q2_not_q4",
      "q2_reml_unsupported_boundary"
    ),
    dimension = c(rep("q2", length(structured_types)), "q2_plus_q2", "q2"),
    structured_type = c(structured_types, "phylo", "phylo"),
    estimator = c(rep("ML", length(structured_types)), "ML", "REML"),
    target = c(
      paste0("mu1_mu2_", structured_types, "_same_structured_matrix"),
      "two_independent_q2_blocks",
      "q2_exact_gaussian_reml"
    ),
    native_status = c(
      rep("fixture_available", length(structured_types)),
      "planned",
      "unsupported"
    ),
    direct_drmjl_status = c(
      rep("fixture_available", length(structured_types)),
      "planned",
      "unsupported"
    ),
    r_via_julia_status = c(
      rep("fixture_available", length(structured_types)),
      "planned",
      "unsupported"
    ),
    separated_from = c(
      rep("q2_plus_q2;q4", length(structured_types)),
      "q2;q4",
      "q2_ml;q4;HSquared_AI_REML"
    ),
    bridge_status = c(
      rep("experimental", length(structured_types)),
      "planned",
      "unsupported"
    ),
    claim_boundary = c(
      boundary,
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
    evidence_url <- switch(
      structured_type,
      phylo = "docs/dev-log/after-task/2026-06-22-q2-coefficient-ordering-map.md",
      spatial = "docs/dev-log/after-task/2026-06-23-q2-spatial-fixed-bridge-parity.md",
      animal = "docs/dev-log/after-task/2026-06-23-q2-known-structured-bridge-parity.md",
      relmat = "docs/dev-log/after-task/2026-06-23-q2-known-structured-bridge-parity.md"
    )
    claim_boundary <- switch(
      structured_type,
      phylo = paste(
        "Q2 coefficient order is fixture-level contract evidence only;",
        "q2 phylo bridge evidence is limited to one exact-Gaussian ML",
        "fixture and no broad q2 bridge support or interval coverage is",
        "promoted."
      ),
      spatial = paste(
        "Q2 coefficient order is fixture-level contract evidence for one",
        "fixed-covariance q2 spatial bridge fixture; no range-estimating",
        "spatial route, q2 REML, q4 support, broad public bridge support,",
        "or interval coverage is promoted."
      ),
      animal = paste(
        "Q2 coefficient order is fixture-level contract evidence for one",
        "q2 animal A-matrix bridge fixture; no pedigree/Ainv bridge",
        "marshalling, q2 REML, q4 support, broad public bridge support,",
        "or interval coverage is promoted."
      ),
      relmat = paste(
        "Q2 coefficient order is fixture-level contract evidence for one",
        "q2 relmat K-matrix bridge fixture; no Q precision marshalling,",
        "q2 REML, q4 support, broad public bridge support, or interval",
        "coverage is promoted."
      )
    )
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
      bridge_status = "experimental",
      evidence_url = evidence_url,
      claim_boundary = claim_boundary,
      next_gate = "Keep q2 coefficient-order evidence scoped to route-specific fixtures before widening REML, q4, or interval claims.",
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
    matrix_slot <- switch(
      structured_type,
      phylo = "tree",
      spatial = "coords",
      animal = "A",
      relmat = "K"
    )
    input_scale <- switch(
      structured_type,
      phylo = "ultrametric_tree_branch_lengths",
      spatial = "coordinates_to_fixed_covariance_K",
      animal = "additive_covariance",
      relmat = "user_covariance"
    )
    missing_level_policy <- switch(
      structured_type,
      phylo = paste(
        "error_if_observed_species_absent_from_tree;",
        "extra_tree_tips_allowed",
        sep = ""
      ),
      spatial = paste(
        "error_if_coords_missing_observed_group_or_vary_within_group;",
        "extra_coordinate_rows_not_supported",
        sep = ""
      ),
      animal = paste(
        "error_if_observed_id_absent_from_matrix;",
        "extra_matrix_levels_allowed",
        sep = ""
      ),
      relmat = paste(
        "error_if_observed_id_absent_from_matrix;",
        "extra_matrix_levels_allowed",
        sep = ""
      )
    )
    bridge_marshalling <- switch(
      structured_type,
      phylo = "tree_serialized_by_phylo_bridge_fixture",
      spatial = paste(
        "coords_converted_to_fixed_covariance_K_fixture;",
        "range_estimating_spatial_not_promoted",
        sep = ""
      ),
      animal = "A_covariance_bridge_fixture_only;pedigree_Ainv_not_marshaled",
      relmat = "K_covariance_bridge_fixture_only;Q_precision_not_marshaled"
    )
    evidence_url <- switch(
      structured_type,
      phylo = "docs/dev-log/after-task/2026-06-22-q2-payload-provenance.md",
      spatial = "docs/dev-log/after-task/2026-06-23-q2-spatial-fixed-bridge-parity.md",
      animal = "docs/dev-log/after-task/2026-06-23-q2-known-structured-bridge-parity.md",
      relmat = "docs/dev-log/after-task/2026-06-23-q2-known-structured-bridge-parity.md"
    )
    claim_boundary <- switch(
      structured_type,
      phylo = paste(
        "Q2 payload provenance is a fixture-level audit contract only;",
        "q2 phylo bridge evidence is limited to one exact-Gaussian ML",
        "fixture and no broad q2 bridge support, q2 REML, q4 support,",
        "or interval coverage is promoted."
      ),
      spatial = paste(
        "Q2 spatial payload provenance is fixture-level audit evidence for",
        "one fixed-covariance exact-Gaussian ML spatial bridge route; no",
        "range-estimating spatial route, mesh/SPDE route, q2 REML, q4",
        "support, broad public bridge support, or interval coverage is",
        "promoted."
      ),
      animal = paste(
        "Q2 animal payload provenance is fixture-level audit evidence for",
        "one exact-Gaussian ML A-matrix bridge route; no pedigree/Ainv",
        "bridge marshalling, q2 REML, q4 support, broad public bridge",
        "support, or interval coverage is promoted."
      ),
      relmat = paste(
        "Q2 relmat payload provenance is fixture-level audit evidence for",
        "one exact-Gaussian ML K-matrix bridge route; no Q precision bridge",
        "marshalling, q2 REML, q4 support, broad public bridge support,",
        "or interval coverage is promoted."
      )
    )
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
      matrix_slot = matrix_slot,
      input_scale = input_scale,
      missing_level_policy = missing_level_policy,
      bridge_marshalling = bridge_marshalling,
      endpoint = target$endpoint[[1L]],
      required_levels = "group_index;matrix_row_names;matrix_col_names",
      version_fields = "payload_version;drmTMB_head;DRM.jl_head;estimator;route",
      dirty_state_policy = "local_dirty_state_must_be_reported;not_public_support",
      status = "covered",
      bridge_status = "experimental",
      evidence_url = evidence_url,
      claim_boundary = claim_boundary,
      next_gate = "Keep q2 provenance tied to route-specific fixtures before widening REML, q4, or interval claims.",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phase18_structured_re_q2_acceptance_gate <- function() {
  structured_types <- c("phylo", "spatial", "animal", "relmat")
  rows <- lapply(structured_types, function(structured_type) {
    r_via_julia_status <- switch(
      structured_type,
      phylo = "available_q2_phylo_formula_bridge_fixture",
      spatial = "available_q2_fixed_covariance_spatial_formula_bridge_fixture",
      animal = "available_q2_known_covariance_formula_bridge_fixture",
      relmat = "available_q2_known_covariance_formula_bridge_fixture"
    )
    acceptance_status <- switch(
      structured_type,
      phylo = "banked_phylo_fixture",
      spatial = "banked_fixed_covariance_spatial_fixture",
      animal = "banked_known_covariance_fixture",
      relmat = "banked_known_covariance_fixture"
    )
    missing_evidence <- switch(
      structured_type,
      phylo = "none_for_phylo_fixture",
      spatial = "none_for_fixed_covariance_spatial_fixture",
      animal = "none_for_known_covariance_fixture",
      relmat = "none_for_known_covariance_fixture"
    )
    evidence_url <- switch(
      structured_type,
      phylo = "docs/dev-log/after-task/2026-06-22-q2-parity-acceptance-blocker.md",
      spatial = "docs/dev-log/after-task/2026-06-23-q2-spatial-fixed-bridge-parity.md",
      animal = "docs/dev-log/after-task/2026-06-23-q2-known-structured-bridge-parity.md",
      relmat = "docs/dev-log/after-task/2026-06-23-q2-known-structured-bridge-parity.md"
    )
    claim_boundary <- switch(
      structured_type,
      phylo = paste(
        "Q2 phylo parity is banked only for one complete-response",
        "exact-Gaussian ML native/direct/bridge fixture; no broad q2",
        "bridge support, q2 REML, q4 support, or interval coverage is",
        "promoted."
      ),
      spatial = paste(
        "Q2 spatial parity is banked for one complete-response",
        "exact-Gaussian ML native/direct/R-via-Julia fixed-covariance",
        "spatial formula fixture; this is not a range-estimating spatial",
        "route, mesh/SPDE route, q2 REML, q4 support, broad public bridge",
        "support, or interval coverage."
      ),
      animal = paste(
        "Q2 animal parity is banked for one complete-response exact-Gaussian",
        "ML native/direct/bridge A-matrix fixture; no pedigree/Ainv bridge",
        "marshalling, q2 REML, q4 support, range-estimating spatial route,",
        "broad public bridge support, or interval coverage is promoted."
      ),
      relmat = paste(
        "Q2 relmat parity is banked for one complete-response exact-Gaussian",
        "ML native/direct/bridge K-matrix fixture; no Q precision bridge",
        "marshalling, q2 REML, q4 support, range-estimating spatial route,",
        "broad public bridge support, or interval coverage is promoted."
      )
    )
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
      r_via_julia_status = r_via_julia_status,
      tolerance_policy = "native_direct_bridge_same_target_fixture_tolerances_met",
      acceptance_status = acceptance_status,
      missing_evidence = missing_evidence,
      required_before_acceptance = missing_evidence,
      status = "covered",
      bridge_status = "experimental",
      evidence_url = evidence_url,
      claim_boundary = claim_boundary,
      next_gate = "Keep aggregate q2 acceptance scoped to complete-response exact-Gaussian ML fixed-covariance and known-matrix fixtures before widening REML, q4, or interval claims.",
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
