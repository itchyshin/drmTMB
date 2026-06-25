structured_re_dashboard_path <- function(file) {
  candidates <- c(
    testthat::test_path(
      "..",
      "..",
      "docs",
      "dev-log",
      "dashboard",
      file
    ),
    file.path(getwd(), "docs", "dev-log", "dashboard", file)
  )
  candidates <- candidates[file.exists(candidates)]
  testthat::skip_if(
    length(candidates) == 0L,
    paste("dashboard source file not available:", file)
  )
  normalizePath(candidates[[1L]], winslash = "/", mustWork = TRUE)
}

structured_re_read_dashboard_tsv <- function(file) {
  utils::read.delim(
    structured_re_dashboard_path(file),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

structured_re_artifact_path <- function(...) {
  parts <- c(...)
  candidates <- c(
    do.call(testthat::test_path, as.list(c("..", "..", parts))),
    do.call(file.path, as.list(c(getwd(), parts)))
  )
  candidates <- candidates[file.exists(candidates)]
  testthat::skip_if(
    length(candidates) == 0L,
    paste(
      "artifact source file not available:",
      do.call(file.path, as.list(parts))
    )
  )
  normalizePath(candidates[[1L]], winslash = "/", mustWork = TRUE)
}

structured_re_expect_all_match <- function(x, pattern, fixed = TRUE) {
  expect_equal(grepl(pattern, x, fixed = fixed), rep(TRUE, length(x)))
}

test_that("q-series support-cell dashboard owns exact structured rows", {
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    qseries,
    c(
      "cell_id",
      "formula_cell",
      "family_class",
      "family",
      "structure_provider",
      "dimension_pattern",
      "endpoint_set",
      "slope_class",
      "covariance_layout",
      "route",
      "estimator_requested",
      "estimator_effective",
      "fit_status",
      "extractor_status",
      "bridge_status",
      "interval_status",
      "coverage_status",
      "authority_status",
      "evidence_url",
      "claim_boundary",
      "denominator_policy",
      "next_gate"
    )
  )
  expect_equal(anyDuplicated(qseries$cell_id), 0L)
  expect_false(any(qseries$cell_id == ""))

  required_cells <- c(
    "qseries_ordinary_q1_intercept",
    "qseries_ordinary_q1_independent_slope",
    "qseries_ordinary_q2_mu1_mu2_intercept",
    "qseries_ordinary_q8_all_endpoint_one_slope",
    "qseries_phylo_q1_mu_intercept",
    "qseries_phylo_q1_sigma_intercept",
    "qseries_phylo_q1_mu_sigma_intercept",
    "qseries_phylo_q1_mu_one_slope",
    "qseries_spatial_q1_sigma_intercept",
    "qseries_spatial_q1_mu_sigma_intercept",
    "qseries_spatial_q1_mu_one_slope",
    "qseries_animal_q1_sigma_intercept",
    "qseries_animal_q1_mu_sigma_intercept",
    "qseries_animal_q1_mu_one_slope",
    "qseries_relmat_q1_mu_one_slope",
    "qseries_relmat_q1_sigma_intercept",
    "qseries_relmat_q1_mu_sigma_intercept",
    "qseries_phylo_q1_sigma_one_slope",
    "qseries_spatial_q1_sigma_one_slope",
    "qseries_animal_q1_sigma_one_slope",
    "qseries_relmat_q1_sigma_one_slope",
    "qseries_phylo_q2_mu1_mu2_intercept",
    "qseries_spatial_q2_mu1_mu2_intercept",
    "qseries_animal_q2_mu1_mu2_intercept",
    "qseries_relmat_q2_mu1_mu2_intercept",
    "qseries_phylo_q2_mu1_mu2_one_slope",
    "qseries_spatial_q2_mu1_mu2_one_slope",
    "qseries_animal_q2_mu1_mu2_one_slope",
    "qseries_relmat_q2_mu1_mu2_one_slope",
    "qseries_phylo_q4_mu1_mu2_one_slope",
    "qseries_spatial_q4_mu1_mu2_one_slope",
    "qseries_animal_q4_mu1_mu2_one_slope",
    "qseries_relmat_q4_mu1_mu2_one_slope",
    "qseries_phylo_q2_plus_q2_intercept",
    "qseries_spatial_q2_plus_q2_sigma_rejected",
    "qseries_animal_q2_plus_q2_sigma_rejected",
    "qseries_relmat_q2_plus_q2_sigma_rejected",
    "qseries_phylo_q4_all_four_intercept",
    "qseries_spatial_q4_all_four_intercept",
    "qseries_animal_q4_all_four_intercept",
    "qseries_relmat_q4_all_four_intercept",
    "qseries_phylo_q4_all_four_one_slope_planned",
    "qseries_spatial_q4_all_four_one_slope_planned",
    "qseries_animal_q4_all_four_one_slope_planned",
    "qseries_relmat_q4_all_four_one_slope_planned",
    "qseries_phylo_q6_planned",
    "qseries_spatial_q6_planned",
    "qseries_animal_q6_planned",
    "qseries_relmat_q6_planned",
    "qseries_phylo_q8_planned",
    "qseries_spatial_q8_planned",
    "qseries_animal_q8_planned",
    "qseries_relmat_q8_planned",
    "qseries_phylo_interaction_q1_mu",
    "qseries_phylo_poisson_q1_mu_intercept",
    "qseries_phylo_nbinom2_q1_mu_intercept",
    "qseries_nongaussian_structured_slopes_planned",
    "qseries_phylo_direct_sd_univariate",
    "qseries_phylo_direct_sd_bivariate"
  )
  expect_true(all(required_cells %in% qseries$cell_id))

  evidence_statuses <- c(
    "planned",
    "unsupported",
    "parser_ready",
    "point_fit",
    "extractor_ready",
    "fixture_parity",
    "interval_feasible",
    "inference_ready",
    "supported",
    "diagnostic_only",
    "blocked"
  )
  for (field in c(
    "fit_status",
    "extractor_status",
    "bridge_status",
    "interval_status",
    "coverage_status"
  )) {
    expect_setequal(
      setdiff(unique(qseries[[field]]), evidence_statuses),
      character()
    )
  }

  structured_q8_runtime_cells <- c(
    "qseries_phylo_q4_all_four_one_slope_planned",
    "qseries_spatial_q4_all_four_one_slope_planned",
    "qseries_animal_q4_all_four_one_slope_planned",
    "qseries_relmat_q4_all_four_one_slope_planned"
  )
  structured_q8 <- qseries[
    qseries$dimension_pattern == "q8" &
      qseries$structure_provider != "ordinary",
    ,
    drop = FALSE
  ]
  expect_true(all(
    structured_q8$fit_status %in%
      c(
        "planned",
        "unsupported",
        "blocked"
      ) |
      structured_q8$cell_id %in% structured_q8_runtime_cells
  ))

  q4_rows <- qseries[qseries$dimension_pattern == "q4", , drop = FALSE]
  expect_false(any(
    q4_rows$coverage_status %in%
      c(
        "inference_ready",
        "supported"
      )
  ))

  native_sigma_slope <- qseries[
    qseries$cell_id %in%
      c(
        "qseries_phylo_q1_sigma_one_slope",
        "qseries_spatial_q1_sigma_one_slope",
        "qseries_animal_q1_sigma_one_slope",
        "qseries_relmat_q1_sigma_one_slope"
      ),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(native_sigma_slope), 4L)
  expect_equal(native_sigma_slope$route, rep("native_tmb", 4L))
  expect_equal(native_sigma_slope$fit_status, rep("point_fit", 4L))
  expect_equal(native_sigma_slope$extractor_status, rep("extractor_ready", 4L))
  expect_equal(native_sigma_slope$interval_status, rep("planned", 4L))
  expect_equal(native_sigma_slope$coverage_status, rep("planned", 4L))
  expect_equal(native_sigma_slope$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    native_sigma_slope$evidence_url,
    rep(
      "docs/dev-log/dashboard/structured-re-sigma-slope-parity-fixture.tsv",
      4L
    )
  )
  spatial_sigma_slope <- native_sigma_slope[
    native_sigma_slope$structure_provider == "spatial",
    ,
    drop = FALSE
  ]
  expect_match(
    spatial_sigma_slope$claim_boundary,
    "fixed-covariance",
    fixed = TRUE
  )
  animal_sigma_slope <- native_sigma_slope[
    native_sigma_slope$structure_provider == "animal",
    ,
    drop = FALSE
  ]
  expect_match(
    animal_sigma_slope$claim_boundary,
    "A-matrix",
    fixed = TRUE
  )
  relmat_sigma_slope <- native_sigma_slope[
    native_sigma_slope$structure_provider == "relmat",
    ,
    drop = FALSE
  ]
  expect_match(
    relmat_sigma_slope$claim_boundary,
    "K/Q",
    fixed = TRUE
  )

  native_q2_slope <- qseries[
    qseries$cell_id %in%
      c(
        "qseries_phylo_q2_mu1_mu2_one_slope",
        "qseries_spatial_q2_mu1_mu2_one_slope",
        "qseries_animal_q2_mu1_mu2_one_slope",
        "qseries_relmat_q2_mu1_mu2_one_slope"
      ),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(native_q2_slope), 4L)
  expect_equal(
    native_q2_slope$route,
    rep("native_direct_bridge_fixture", 4L)
  )
  expect_equal(native_q2_slope$dimension_pattern, rep("q2", 4L))
  expect_equal(native_q2_slope$endpoint_set, rep("mu1+mu2", 4L))
  expect_equal(
    native_q2_slope$slope_class,
    rep("labelled_slope_covariance", 4L)
  )
  expect_equal(
    native_q2_slope$covariance_layout,
    rep("labelled_structured_slope_covariance", 4L)
  )
  expect_equal(native_q2_slope$fit_status, rep("point_fit", 4L))
  expect_equal(native_q2_slope$extractor_status, rep("extractor_ready", 4L))
  expect_equal(native_q2_slope$bridge_status, rep("fixture_parity", 4L))
  expect_equal(native_q2_slope$interval_status, rep("planned", 4L))
  expect_equal(native_q2_slope$coverage_status, rep("planned", 4L))
  expect_equal(
    native_q2_slope$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
  structured_re_expect_all_match(
    native_q2_slope$formula_cell,
    "0 + x | p",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q2_slope$claim_boundary,
    "slope-only",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q2_slope$claim_boundary,
    "broad bridge support",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q2_slope$claim_boundary,
    "interval reliability",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q2_slope$claim_boundary,
    "coverage",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q2_slope$claim_boundary,
    "REML",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q2_slope$claim_boundary,
    "AI-REML",
    fixed = TRUE
  )
  expect_equal(
    native_q2_slope$evidence_url,
    rep(
      "docs/dev-log/dashboard/structured-re-q2-slope-parity-fixture.tsv",
      4L
    )
  )

  native_q4_location_slope <- qseries[
    qseries$cell_id %in%
      c(
        "qseries_phylo_q4_mu1_mu2_one_slope",
        "qseries_spatial_q4_mu1_mu2_one_slope",
        "qseries_animal_q4_mu1_mu2_one_slope",
        "qseries_relmat_q4_mu1_mu2_one_slope"
      ),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(native_q4_location_slope), 4L)
  expect_equal(
    native_q4_location_slope$route,
    rep("native_direct_bridge_fixture", 4L)
  )
  expect_equal(native_q4_location_slope$dimension_pattern, rep("q4", 4L))
  expect_equal(native_q4_location_slope$endpoint_set, rep("mu1+mu2", 4L))
  expect_equal(
    native_q4_location_slope$covariance_layout,
    rep("labelled_structured_location_intercept_slope_covariance", 4L)
  )
  expect_equal(native_q4_location_slope$fit_status, rep("point_fit", 4L))
  expect_equal(
    native_q4_location_slope$extractor_status,
    rep("extractor_ready", 4L)
  )
  expect_equal(
    native_q4_location_slope$bridge_status,
    rep("fixture_parity", 4L)
  )
  expect_equal(native_q4_location_slope$interval_status, rep("planned", 4L))
  expect_equal(native_q4_location_slope$coverage_status, rep("planned", 4L))
  expect_equal(
    native_q4_location_slope$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
  structured_re_expect_all_match(
    native_q4_location_slope$formula_cell,
    "1 + x | p",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q4_location_slope$claim_boundary,
    "same-target fixture",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q4_location_slope$claim_boundary,
    "partial location-scale support",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q4_location_slope$claim_boundary,
    "interval reliability",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q4_location_slope$claim_boundary,
    "coverage",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q4_location_slope$claim_boundary,
    "q4 REML",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    native_q4_location_slope$claim_boundary,
    "AI-REML",
    fixed = TRUE
  )
  expect_equal(
    native_q4_location_slope$evidence_url,
    rep(
      "docs/dev-log/dashboard/structured-re-q4-location-slope-parity-fixture.tsv",
      4L
    )
  )
})

test_that("relmat Q bridge-boundary dashboard stays support-cell scoped", {
  boundary <- structured_re_read_dashboard_tsv(
    "structured-re-relmat-q-bridge-boundary.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    boundary,
    c(
      "boundary_id",
      "cell_id",
      "formula_cell",
      "dimension_pattern",
      "endpoint_set",
      "slope_class",
      "native_k_status",
      "native_q_status",
      "bridge_k_status",
      "bridge_q_status",
      "direct_drmjl_q_status",
      "r_via_julia_q_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(boundary), 6L)
  expect_equal(anyDuplicated(boundary$boundary_id), 0L)
  expect_setequal(
    boundary$boundary_id,
    c(
      "relmat_q_bridge_q1_mu_one_slope",
      "relmat_q_bridge_q1_sigma_one_slope",
      "relmat_q_bridge_q1_mu_sigma_one_slope",
      "relmat_q_bridge_q2_mu1_mu2_one_slope",
      "relmat_q_bridge_q4_mu1_mu2_one_slope",
      "relmat_q_bridge_q8_all_four_one_slope"
    )
  )
  expect_true(all(boundary$cell_id %in% qseries$cell_id))
  qseries_boundary <- qseries[
    match(boundary$cell_id, qseries$cell_id),
    ,
    drop = FALSE
  ]
  expect_equal(qseries_boundary$structure_provider, rep("relmat", 6L))
  expect_equal(boundary$dimension_pattern, qseries_boundary$dimension_pattern)
  expect_equal(boundary$endpoint_set, qseries_boundary$endpoint_set)
  expect_equal(boundary$native_k_status, rep("fixture_available", 6L))
  expect_equal(
    boundary$native_q_status,
    rep("runtime_kq_same_target_parity", 6L)
  )
  expect_equal(
    boundary$native_q_status[
      boundary$boundary_id == "relmat_q_bridge_q4_mu1_mu2_one_slope"
    ],
    "runtime_kq_same_target_parity"
  )
  expect_equal(
    boundary$evidence_url[
      boundary$boundary_id == "relmat_q_bridge_q4_mu1_mu2_one_slope"
    ],
    "docs/dev-log/dashboard/structured-re-relmat-q4-location-kq-native-parity.tsv"
  )
  expect_equal(boundary$bridge_k_status, rep("experimental", 6L))
  expect_equal(boundary$bridge_q_status, rep("unsupported", 6L))
  expect_equal(boundary$direct_drmjl_q_status, rep("unsupported", 6L))
  expect_equal(boundary$r_via_julia_q_status, rep("unsupported", 6L))
  expect_equal(boundary$status, rep("covered", 6L))
  structured_re_expect_all_match(
    boundary$formula_cell,
    "K/Q",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    boundary$claim_boundary,
    "Q precision",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    boundary$claim_boundary,
    "not direct DRM.jl or R-via-Julia bridge evidence",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    boundary$claim_boundary,
    "broad bridge support",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    boundary$claim_boundary,
    "coverage",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    boundary$claim_boundary,
    "REML",
    fixed = TRUE
  )
})

test_that("relmat q4 location K/Q parity sidecar is native-only", {
  parity <- structured_re_read_dashboard_tsv(
    "structured-re-relmat-q4-location-kq-native-parity.tsv"
  )
  boundary <- structured_re_read_dashboard_tsv(
    "structured-re-relmat-q-bridge-boundary.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    parity,
    c(
      "parity_id",
      "cell_id",
      "formula_cell",
      "dimension_pattern",
      "endpoint_set",
      "slope_class",
      "k_input_scale",
      "q_input_scale",
      "k_runtime_status",
      "q_runtime_status",
      "parity_status",
      "extractor_status",
      "bridge_q_status",
      "direct_drmjl_q_status",
      "r_via_julia_q_status",
      "interval_status",
      "coverage_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(parity), 1L)
  expect_equal(
    parity$parity_id,
    "relmat_q4_location_one_slope_kq_native_parity"
  )
  expect_equal(parity$cell_id, "qseries_relmat_q4_mu1_mu2_one_slope")
  qseries_row <- qseries[match(parity$cell_id, qseries$cell_id), , drop = FALSE]
  expect_equal(qseries_row$structure_provider, "relmat")
  expect_equal(parity$dimension_pattern, qseries_row$dimension_pattern)
  expect_equal(parity$endpoint_set, qseries_row$endpoint_set)
  expect_equal(parity$slope_class, qseries_row$slope_class)
  expect_equal(
    parity$formula_cell,
    "relmat(1 + x | p | id, K/Q = ...) in mu1 and mu2"
  )
  expect_equal(parity$k_input_scale, "user_covariance")
  expect_equal(parity$q_input_scale, "user_precision")
  expect_equal(parity$k_runtime_status, "point_fit")
  expect_equal(parity$q_runtime_status, "point_fit")
  expect_equal(parity$parity_status, "runtime_kq_same_target_parity")
  expect_equal(parity$extractor_status, "matched_member_identity")
  expect_equal(parity$bridge_q_status, "unsupported")
  expect_equal(parity$direct_drmjl_q_status, "unsupported")
  expect_equal(parity$r_via_julia_q_status, "unsupported")
  expect_equal(parity$interval_status, "planned")
  expect_equal(parity$coverage_status, "planned")
  expect_equal(
    parity$evidence_url,
    "tests/testthat/test-animal-relmat-gaussian.R"
  )

  boundary_row <- boundary[
    boundary$boundary_id == "relmat_q_bridge_q4_mu1_mu2_one_slope",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(boundary_row), 1L)
  expect_equal(boundary_row$native_q_status, parity$parity_status)
  expect_equal(
    boundary_row$evidence_url,
    "docs/dev-log/dashboard/structured-re-relmat-q4-location-kq-native-parity.tsv"
  )
  structured_re_expect_all_match(parity$claim_boundary, "Native R/TMB")
  structured_re_expect_all_match(
    parity$claim_boundary,
    "K/Q same-target parity"
  )
  structured_re_expect_all_match(parity$claim_boundary, "Q precision")
  structured_re_expect_all_match(
    parity$claim_boundary,
    "not direct DRM.jl or R-via-Julia bridge evidence"
  )
  structured_re_expect_all_match(parity$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(
    parity$claim_boundary,
    "partial location-scale support"
  )
  structured_re_expect_all_match(parity$claim_boundary, "interval reliability")
  structured_re_expect_all_match(parity$claim_boundary, "coverage")
  structured_re_expect_all_match(parity$claim_boundary, "q4 REML")
  structured_re_expect_all_match(parity$claim_boundary, "native-TMB q4 REML")
  structured_re_expect_all_match(parity$claim_boundary, "q4 AI-REML")
  structured_re_expect_all_match(parity$claim_boundary, "HSquared AI-REML")
  structured_re_expect_all_match(parity$claim_boundary, "non-Gaussian REML")
  structured_re_expect_all_match(parity$claim_boundary, "public support")
  structured_re_expect_all_match(parity$claim_boundary, "broader q8 support")
  structured_re_expect_all_match(parity$next_gate, "payload marshalling")
})

test_that("q2 slope-only parity fixture dashboard is provider-specific", {
  fixture <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-parity-fixture.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    fixture,
    c(
      "fixture_id",
      "formula_cell",
      "structured_type",
      "dimension",
      "endpoint",
      "slope_class",
      "estimator",
      "native_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "coefficient_order",
      "matrix_slot",
      "input_scale",
      "parity_status",
      "bridge_status",
      "interval_status",
      "coverage_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(fixture), 4L)
  expect_setequal(
    fixture$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(fixture$dimension, rep("q2", 4L))
  expect_equal(fixture$endpoint, rep("mu1+mu2", 4L))
  expect_equal(fixture$slope_class, rep("labelled_slope_covariance", 4L))
  expect_equal(fixture$estimator, rep("ML", 4L))
  expect_equal(fixture$native_status, rep("fixture_available", 4L))
  expect_equal(fixture$direct_drmjl_status, rep("fixture_available", 4L))
  expect_equal(fixture$r_via_julia_status, rep("fixture_available", 4L))
  expect_equal(fixture$bridge_status, rep("fixture_parity", 4L))
  expect_equal(fixture$interval_status, rep("planned", 4L))
  expect_equal(fixture$coverage_status, rep("planned", 4L))
  expect_equal(
    fixture$coefficient_order,
    rep(
      paste(
        "mu1:x;mu2:x;",
        "sd_mu1:structured(x);sd_mu2:structured(x);",
        "cor_mu1_mu2:structured(x)",
        sep = ""
      ),
      4L
    )
  )
  expect_equal(fixture$matrix_slot, c("tree", "coords", "A", "K"))
  structured_re_expect_all_match(fixture$claim_boundary, "slope-only q2")
  structured_re_expect_all_match(fixture$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(fixture$claim_boundary, "q4/q8")
  structured_re_expect_all_match(fixture$claim_boundary, "coverage")
  structured_re_expect_all_match(fixture$claim_boundary, "REML")
  structured_re_expect_all_match(fixture$claim_boundary, "AI-REML")
  structured_re_expect_all_match(fixture$next_gate, "interval diagnostics")
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "spatial"],
    "fixed-covariance"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "animal"],
    "A-matrix"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "relmat"],
    "K-matrix"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "relmat"],
    "Q bridge"
  )

  qseries_ready <- qseries[
    qseries$cell_id %in%
      paste0("qseries_", fixture$structured_type, "_q2_mu1_mu2_one_slope"),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_ready), 4L)
  expect_equal(qseries_ready$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    qseries_ready$evidence_url,
    rep(
      "docs/dev-log/dashboard/structured-re-q2-slope-parity-fixture.tsv",
      4L
    )
  )
  expect_equal(
    qseries_ready$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q2 slope-only interval plan remains target-level", {
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    plan,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "interval_methods",
      "required_fit_evidence",
      "required_interval_evidence",
      "denominator_fields",
      "current_blocker",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(plan), 12L)
  expect_setequal(
    plan$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_setequal(plan$target_kind, c("direct_sd", "direct_correlation"))
  expect_equal(
    plan$endpoint_member,
    rep(c("mu1:x", "mu2:x", "mu1:x+mu2:x"), 4L)
  )
  expect_equal(
    plan$estimand,
    rep(c("sd_mu1_x", "sd_mu2_x", "cor_mu1_mu2_x"), 4L)
  )
  expect_equal(plan$current_blocker, rep("interval_diagnostics_not_run", 12L))
  expect_equal(plan$status, rep("planned", 12L))

  for (provider in c("phylo", "spatial", "animal", "relmat")) {
    provider_rows <- plan[plan$structured_type == provider, , drop = FALSE]
    expect_equal(
      provider_rows$cell_id,
      rep(paste0("qseries_", provider, "_q2_mu1_mu2_one_slope"), 3L)
    )
  }

  expect_setequal(
    plan$profile_target,
    c(
      "sd:mu:mu1:phylo(0 + x | p | species)",
      "sd:mu:mu2:phylo(0 + x | p | species)",
      "cor:phylo:cor(mu1:x,mu2:x | p | species)",
      "sd:mu:mu1:spatial(0 + x | p | site)",
      "sd:mu:mu2:spatial(0 + x | p | site)",
      "cor:spatial:cor(mu1:x,mu2:x | p | site)",
      "sd:mu:mu1:animal(0 + x | p | id)",
      "sd:mu:mu2:animal(0 + x | p | id)",
      "cor:animal:cor(mu1:x,mu2:x | p | id)",
      "sd:mu:mu1:relmat(0 + x | p | id)",
      "sd:mu:mu2:relmat(0 + x | p | id)",
      "cor:relmat:cor(mu1:x,mu2:x | p | id)"
    )
  )
  structured_re_expect_all_match(plan$interval_methods, "wald")
  structured_re_expect_all_match(plan$interval_methods, "profile")
  structured_re_expect_all_match(plan$interval_methods, "bootstrap")
  structured_re_expect_all_match(plan$required_fit_evidence, "point_fit")
  structured_re_expect_all_match(
    plan$required_fit_evidence,
    "same_target_fixture_parity"
  )
  structured_re_expect_all_match(
    plan$required_interval_evidence,
    "finite_intervals_by_method"
  )
  structured_re_expect_all_match(
    plan$required_interval_evidence,
    "coverage_mcse<=0.01"
  )
  structured_re_expect_all_match(
    plan$denominator_fields,
    "coverage_denominator"
  )
  structured_re_expect_all_match(plan$denominator_fields, "coverage_mcse")
  structured_re_expect_all_match(plan$claim_boundary, "no interval reliability")
  structured_re_expect_all_match(plan$claim_boundary, "interval coverage")
  structured_re_expect_all_match(plan$claim_boundary, "q4/q8")
  structured_re_expect_all_match(plan$claim_boundary, "REML")
  structured_re_expect_all_match(plan$claim_boundary, "AI-REML")
  structured_re_expect_all_match(plan$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(plan$next_gate, "before calibrated coverage")
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "relmat"],
    "Q bridge"
  )

  qseries_plan <- qseries[qseries$cell_id %in% plan$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_plan), 4L)
  expect_equal(qseries_plan$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_plan$interval_status, rep("planned", 4L))
  expect_equal(qseries_plan$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_plan$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q2 slope-only interval status remains diagnostic-only", {
  status <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-interval-diagnostic-status.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q2-slope-interval-smoke",
      "structured-re-q2-slope-interval-smoke-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    status,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_artifact",
      "observed_target_rows",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_finite_intervals",
      "wald_status",
      "profile_status",
      "bootstrap_status",
      "interval_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(status), 12L)
  expect_equal(nrow(artifact), 36L)
  expect_setequal(
    status$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_setequal(status$target_kind, c("direct_sd", "direct_correlation"))
  expect_equal(
    status$endpoint_member,
    rep(c("mu1:x", "mu2:x", "mu1:x+mu2:x"), 4L)
  )
  expect_equal(status$observed_target_rows, rep(1L, 12L))
  expect_equal(status$n_fit_ok, rep(1L, 12L))
  expect_equal(status$n_converged, rep(1L, 12L))
  expect_equal(status$n_pdhess, rep(1L, 12L))
  expect_equal(status$bootstrap_status, rep("finite", 12L))
  expect_equal(status$interval_claim_status, rep("diagnostic_only", 12L))
  expect_equal(status$status, rep("covered", 12L))

  all_finite <- status[
    status$interval_status == "wald_profile_bootstrap_finite",
    c("structured_type", "endpoint_member"),
    drop = FALSE
  ]
  expect_equal(nrow(all_finite), 10L)
  expect_setequal(
    paste(all_finite$structured_type, all_finite$endpoint_member),
    c(
      "phylo mu1:x",
      "phylo mu2:x",
      "phylo mu1:x+mu2:x",
      "spatial mu1:x",
      "spatial mu2:x",
      "spatial mu1:x+mu2:x",
      "animal mu1:x",
      "animal mu2:x",
      "relmat mu1:x",
      "relmat mu2:x"
    )
  )

  wald_bootstrap <- status[
    status$interval_status == "wald_bootstrap_finite_profile_failed",
    c("structured_type", "endpoint_member"),
    drop = FALSE
  ]
  expect_equal(nrow(wald_bootstrap), 2L)
  expect_setequal(
    paste(wald_bootstrap$structured_type, wald_bootstrap$endpoint_member),
    c(
      "animal mu1:x+mu2:x",
      "relmat mu1:x+mu2:x"
    )
  )

  bootstrap_only <- status[
    status$interval_status == "bootstrap_only_finite_boundary",
    c("structured_type", "endpoint_member"),
    drop = FALSE
  ]
  expect_equal(nrow(bootstrap_only), 0L)
  expect_equal(
    status$n_finite_intervals,
    c(3L, 3L, 3L, 3L, 3L, 3L, 3L, 3L, 2L, 3L, 3L, 2L)
  )
  structured_re_expect_all_match(status$claim_boundary, "interval smoke only")
  structured_re_expect_all_match(
    status$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(status$claim_boundary, "interval coverage")
  structured_re_expect_all_match(status$claim_boundary, "q4/q8")
  structured_re_expect_all_match(status$claim_boundary, "REML")
  structured_re_expect_all_match(status$claim_boundary, "AI-REML")
  structured_re_expect_all_match(status$claim_boundary, "broad bridge support")

  qseries_status <- qseries[qseries$cell_id %in% status$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )

  artifact_finite <- stats::aggregate(
    interval_finite ~ provider + endpoint_member,
    artifact,
    function(x) sum(tolower(as.character(x)) == "true")
  )
  names(artifact_finite)[
    names(artifact_finite) == "provider"
  ] <- "structured_type"
  merged <- merge(
    status[, c("structured_type", "endpoint_member", "n_finite_intervals")],
    artifact_finite,
    by = c("structured_type", "endpoint_member"),
    sort = FALSE
  )
  expect_equal(nrow(merged), 12L)
  expect_equal(merged$n_finite_intervals, merged$interval_finite)
})

test_that("q2 slope-only interval stability probe remains diagnostic-only", {
  status <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-interval-stability-probe.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q2-slope-interval-stability-probe",
      "structured-re-q2-slope-interval-stability-probe-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    status,
    c(
      "probe_id",
      "cell_id",
      "variant",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_artifact",
      "n_each",
      "intended_sd_mu1_x",
      "intended_sd_mu2_x",
      "intended_cor_mu1_mu2_x",
      "residual_sd1",
      "residual_sd2",
      "observed_target_rows",
      "n_fit_ok",
      "n_pdhess",
      "estimate",
      "wald_status",
      "profile_status",
      "stability_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(status), 24L)
  expect_equal(nrow(artifact), 48L)
  expect_setequal(status$variant, c("strong", "stronger_slope"))
  expect_setequal(
    status$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_setequal(status$target_kind, c("direct_sd", "direct_correlation"))
  expect_equal(status$observed_target_rows, rep(1L, 24L))
  expect_equal(status$n_fit_ok, rep(1L, 24L))
  expect_equal(status$wald_status, rep("finite", 24L))
  expect_equal(status$profile_status, rep("finite", 24L))
  expect_equal(status$stability_status, rep("wald_profile_finite", 24L))
  expect_equal(status$failure_class, rep("none", 24L))
  expect_equal(status$interval_claim_status, rep("diagnostic_only", 24L))
  expect_equal(status$status, rep("covered", 24L))
  expect_equal(status$n_pdhess, rep(1L, 24L))

  partial <- status[
    status$stability_status == "partial_finite",
    c("variant", "structured_type", "endpoint_member"),
    drop = FALSE
  ]
  expect_equal(nrow(partial), 0L)
  expect_equal(
    sum(status$stability_status == "wald_profile_nonfinite_boundary"),
    0L
  )
  structured_re_expect_all_match(status$claim_boundary, "stability probe only")
  structured_re_expect_all_match(
    status$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(status$claim_boundary, "interval coverage")
  structured_re_expect_all_match(status$claim_boundary, "q4/q8")
  structured_re_expect_all_match(status$claim_boundary, "REML")
  structured_re_expect_all_match(status$claim_boundary, "AI-REML")
  structured_re_expect_all_match(status$claim_boundary, "broad bridge support")

  qseries_status <- qseries[qseries$cell_id %in% status$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )

  artifact_finite <- stats::aggregate(
    interval_finite ~ variant + provider + endpoint_member,
    artifact,
    function(x) sum(tolower(as.character(x)) == "true")
  )
  names(artifact_finite)[names(artifact_finite) == "provider"] <-
    "structured_type"
  merged <- merge(
    status[, c("variant", "structured_type", "endpoint_member")],
    artifact_finite,
    by = c("variant", "structured_type", "endpoint_member"),
    sort = FALSE
  )
  status_finite <- as.integer(status$wald_status == "finite") +
    as.integer(status$profile_status == "finite")
  expect_equal(nrow(merged), 24L)
  expect_equal(sort(merged$interval_finite), sort(status_finite))
})

test_that("q2 slope-only denominator admission remains diagnostic-only", {
  denom <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-denominator-admission.tsv"
  )
  status <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-interval-diagnostic-status.tsv"
  )
  stability <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-interval-stability-probe.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    denom,
    c(
      "denominator_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_interval_status",
      "source_stability_probe",
      "source_interval_artifact",
      "source_stability_artifact",
      "smoke_interval_status",
      "smoke_n_finite_intervals",
      "smoke_wald_status",
      "smoke_profile_status",
      "smoke_bootstrap_status",
      "stability_variant_count",
      "stability_wald_profile_finite_count",
      "stability_pdhess_true_count",
      "denominator_admission",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(denom), 12L)
  expect_setequal(
    denom$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(
    denom$endpoint_member,
    rep(c("mu1:x", "mu2:x", "mu1:x+mu2:x"), 4L)
  )
  expect_equal(denom$coverage_status, rep("not_evaluated", 12L))
  expect_equal(denom$interval_claim_status, rep("diagnostic_only", 12L))
  expect_equal(denom$status, rep("covered", 12L))
  expect_equal(denom$stability_variant_count, rep(2L, 12L))
  expect_equal(denom$stability_wald_profile_finite_count, rep(2L, 12L))
  expect_equal(denom$stability_pdhess_true_count, rep(2L, 12L))

  not_admitted <- denom[
    denom$denominator_admission == "not_admitted_profile_failure",
    c("structured_type", "endpoint_member", "smoke_interval_status"),
    drop = FALSE
  ]
  expect_equal(nrow(not_admitted), 2L)
  expect_setequal(
    paste(not_admitted$structured_type, not_admitted$endpoint_member),
    c("animal mu1:x+mu2:x", "relmat mu1:x+mu2:x")
  )
  expect_equal(
    not_admitted$smoke_interval_status,
    rep("wald_bootstrap_finite_profile_failed", 2L)
  )

  admitted <- denom[
    denom$denominator_admission == "diagnostic_denominator_candidate",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(admitted), 10L)
  expect_equal(
    admitted$smoke_interval_status,
    rep("wald_profile_bootstrap_finite", 10L)
  )
  expect_equal(admitted$smoke_n_finite_intervals, rep(3L, 10L))
  expect_equal(denom$smoke_bootstrap_status, rep("finite", 12L))
  structured_re_expect_all_match(
    denom$claim_boundary,
    "denominator-admission diagnostic only"
  )
  structured_re_expect_all_match(
    denom$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(denom$claim_boundary, "interval coverage")
  structured_re_expect_all_match(denom$claim_boundary, "coverage acceptance")
  structured_re_expect_all_match(denom$claim_boundary, "q4/q8")
  structured_re_expect_all_match(denom$claim_boundary, "REML")
  structured_re_expect_all_match(denom$claim_boundary, "AI-REML")
  structured_re_expect_all_match(denom$claim_boundary, "broad bridge support")

  status_key <- status[, c(
    "structured_type",
    "endpoint_member",
    "interval_status",
    "n_finite_intervals",
    "wald_status",
    "profile_status",
    "bootstrap_status"
  )]
  names(status_key) <- c(
    "structured_type",
    "endpoint_member",
    "smoke_interval_status",
    "smoke_n_finite_intervals",
    "smoke_wald_status",
    "smoke_profile_status",
    "smoke_bootstrap_status"
  )
  merged_status <- merge(
    denom,
    status_key,
    by = c("structured_type", "endpoint_member"),
    suffixes = c("", ".source"),
    sort = FALSE
  )
  expect_equal(nrow(merged_status), 12L)
  for (field in names(status_key)[-(1:2)]) {
    expect_equal(
      merged_status[[field]],
      merged_status[[paste0(field, ".source")]]
    )
  }

  stability_counts <- stats::aggregate(
    cbind(
      wald_profile_finite = stability$wald_status == "finite" &
        stability$profile_status == "finite",
      pdhess_true = stability$n_pdhess == 1L
    ) ~ structured_type + endpoint_member,
    stability,
    sum
  )
  merged_stability <- merge(
    denom,
    stability_counts,
    by = c("structured_type", "endpoint_member"),
    sort = FALSE
  )
  expect_equal(nrow(merged_stability), 12L)
  expect_equal(
    merged_stability$stability_wald_profile_finite_count,
    merged_stability$wald_profile_finite
  )
  expect_equal(
    merged_stability$stability_pdhess_true_count,
    merged_stability$pdhess_true
  )

  qseries_status <- qseries[qseries$cell_id %in% denom$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q2 slope-only denominator extension remains diagnostic-only", {
  extension <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-denominator-extension.tsv"
  )
  admission <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-denominator-admission.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q2-slope-denominator-extension",
      "structured-re-q2-slope-denominator-extension-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    extension,
    c(
      "extension_id",
      "cell_id",
      "variant",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_admission",
      "source_artifact",
      "n_each",
      "intended_sd_mu1_x",
      "intended_sd_mu2_x",
      "intended_cor_mu1_mu2_x",
      "residual_sd1",
      "residual_sd2",
      "admission_status",
      "observed_target_rows",
      "n_fit_ok",
      "n_pdhess",
      "estimate",
      "wald_status",
      "profile_status",
      "extension_status",
      "denominator_extension_status",
      "failure_class",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(extension), 24L)
  expect_equal(nrow(artifact), 48L)
  expect_setequal(extension$variant, c("extension_seed_a", "extension_seed_b"))
  expect_setequal(
    extension$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(extension$observed_target_rows, rep(1L, 24L))
  expect_equal(extension$n_fit_ok, rep(1L, 24L))
  expect_equal(extension$n_pdhess, rep(1L, 24L))
  expect_equal(extension$wald_status, rep("finite", 24L))
  expect_equal(extension$profile_status, rep("finite", 24L))
  expect_equal(extension$extension_status, rep("wald_profile_finite", 24L))
  expect_equal(extension$failure_class, rep("none", 24L))
  expect_equal(extension$coverage_status, rep("not_evaluated", 24L))
  expect_equal(extension$interval_claim_status, rep("diagnostic_only", 24L))
  expect_equal(extension$status, rep("covered", 24L))

  candidates <- extension[
    extension$denominator_extension_status == "extension_candidate",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(candidates), 20L)
  expect_equal(
    candidates$admission_status,
    rep("diagnostic_denominator_candidate", 20L)
  )

  held_out <- extension[
    extension$denominator_extension_status == "not_admitted_from_smoke",
    c("variant", "structured_type", "endpoint_member", "admission_status"),
    drop = FALSE
  ]
  expect_equal(nrow(held_out), 4L)
  expect_setequal(
    paste(held_out$variant, held_out$structured_type, held_out$endpoint_member),
    c(
      "extension_seed_a animal mu1:x+mu2:x",
      "extension_seed_b animal mu1:x+mu2:x",
      "extension_seed_a relmat mu1:x+mu2:x",
      "extension_seed_b relmat mu1:x+mu2:x"
    )
  )
  expect_equal(
    held_out$admission_status,
    rep("not_admitted_profile_failure", 4L)
  )

  admission_key <- admission[, c(
    "structured_type",
    "endpoint_member",
    "denominator_admission"
  )]
  names(admission_key)[3L] <- "admission_status"
  merged_admission <- merge(
    extension,
    admission_key,
    by = c("structured_type", "endpoint_member"),
    suffixes = c("", ".source"),
    sort = FALSE
  )
  expect_equal(nrow(merged_admission), 24L)
  expect_equal(
    merged_admission$admission_status,
    merged_admission$admission_status.source
  )

  artifact_finite <- stats::aggregate(
    interval_finite ~ variant + provider + endpoint_member,
    artifact,
    function(x) sum(tolower(as.character(x)) == "true")
  )
  names(artifact_finite)[names(artifact_finite) == "provider"] <-
    "structured_type"
  merged_artifact <- merge(
    extension,
    artifact_finite,
    by = c("variant", "structured_type", "endpoint_member"),
    sort = FALSE
  )
  expect_equal(nrow(merged_artifact), 24L)
  expect_equal(merged_artifact$interval_finite, rep(2L, 24L))

  structured_re_expect_all_match(
    extension$claim_boundary,
    "denominator-extension diagnostic only"
  )
  structured_re_expect_all_match(
    extension$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(
    extension$claim_boundary,
    "coverage acceptance"
  )
  structured_re_expect_all_match(extension$claim_boundary, "q4/q8")
  structured_re_expect_all_match(extension$claim_boundary, "REML")
  structured_re_expect_all_match(extension$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    extension$claim_boundary,
    "broad bridge support"
  )

  qseries_status <- qseries[
    qseries$cell_id %in% extension$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q2 slope-only replicated denominator rule keeps coverage blocked", {
  rule <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-replicated-denominator-rule.tsv"
  )
  admission <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-denominator-admission.tsv"
  )
  extension <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-denominator-extension.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    rule,
    c(
      "rule_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_admission",
      "source_extension",
      "source_interval_status",
      "source_stability_probe",
      "admission_status",
      "extension_variant_count",
      "extension_wald_profile_finite_count",
      "extension_candidate_count",
      "smoke_profile_status",
      "current_denominator_action",
      "pregrid_min_replicates",
      "seed_policy",
      "failed_profile_retention",
      "nonconverged_fit_retention",
      "nonfinite_interval_retention",
      "bootstrap_refit_retention",
      "mcse_threshold",
      "coverage_evaluable",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(rule), 12L)
  expect_setequal(
    rule$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(
    rule$endpoint_member,
    rep(c("mu1:x", "mu2:x", "mu1:x+mu2:x"), 4L)
  )
  expect_equal(rule$pregrid_min_replicates, rep(150L, 12L))
  expect_equal(
    rule$seed_policy,
    rep("predeclared_seed_manifest_required_before_execution", 12L)
  )
  expect_equal(rule$failed_profile_retention, rep("retain_in_denominator", 12L))
  expect_equal(
    rule$nonconverged_fit_retention,
    rep("retain_in_denominator", 12L)
  )
  expect_equal(
    rule$nonfinite_interval_retention,
    rep("retain_in_denominator", 12L)
  )
  expect_equal(
    rule$bootstrap_refit_retention,
    rep("record_attempts_and_retain_target_denominator", 12L)
  )
  expect_equal(rule$mcse_threshold, rep(0.01, 12L))
  expect_equal(rule$coverage_evaluable, rep(FALSE, 12L))
  expect_equal(rule$coverage_status, rep("not_evaluated", 12L))
  expect_equal(rule$interval_claim_status, rep("diagnostic_only", 12L))
  expect_equal(rule$status, rep("covered", 12L))

  eligible <- rule[
    rule$current_denominator_action == "eligible_for_pregrid_with_retention",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(eligible), 10L)
  expect_equal(
    eligible$admission_status,
    rep("diagnostic_denominator_candidate", 10L)
  )
  expect_equal(eligible$extension_candidate_count, rep(2L, 10L))

  held_out <- rule[
    rule$current_denominator_action ==
      "visible_holdout_until_smoke_profile_reconciled",
    c(
      "structured_type",
      "endpoint_member",
      "admission_status",
      "extension_candidate_count",
      "smoke_profile_status"
    ),
    drop = FALSE
  ]
  expect_equal(nrow(held_out), 2L)
  expect_setequal(
    paste(held_out$structured_type, held_out$endpoint_member),
    c("animal mu1:x+mu2:x", "relmat mu1:x+mu2:x")
  )
  expect_equal(
    held_out$admission_status,
    rep("not_admitted_profile_failure", 2L)
  )
  expect_equal(held_out$extension_candidate_count, rep(0L, 2L))
  expect_equal(held_out$smoke_profile_status, rep("nonfinite", 2L))

  admission_key <- admission[, c(
    "structured_type",
    "endpoint_member",
    "denominator_admission",
    "smoke_profile_status"
  )]
  names(admission_key)[3L] <- "admission_status"
  merged_admission <- merge(
    rule,
    admission_key,
    by = c("structured_type", "endpoint_member"),
    suffixes = c("", ".source"),
    sort = FALSE
  )
  expect_equal(nrow(merged_admission), 12L)
  expect_equal(
    merged_admission$admission_status,
    merged_admission$admission_status.source
  )
  expect_equal(
    merged_admission$smoke_profile_status,
    merged_admission$smoke_profile_status.source
  )

  extension_counts <- stats::aggregate(
    cbind(
      extension_candidate = extension$denominator_extension_status ==
        "extension_candidate",
      wald_profile_finite = extension$wald_status == "finite" &
        extension$profile_status == "finite"
    ) ~ structured_type + endpoint_member,
    extension,
    sum
  )
  merged_extension <- merge(
    rule,
    extension_counts,
    by = c("structured_type", "endpoint_member"),
    sort = FALSE
  )
  expect_equal(nrow(merged_extension), 12L)
  expect_equal(
    merged_extension$extension_candidate_count,
    merged_extension$extension_candidate
  )
  expect_equal(
    merged_extension$extension_wald_profile_finite_count,
    merged_extension$wald_profile_finite
  )
  expect_equal(rule$extension_variant_count, rep(2L, 12L))
  expect_equal(rule$extension_wald_profile_finite_count, rep(2L, 12L))

  structured_re_expect_all_match(
    rule$claim_boundary,
    "replicated-denominator rule only"
  )
  structured_re_expect_all_match(
    rule$claim_boundary,
    "no coverage-evaluable denominator evidence"
  )
  structured_re_expect_all_match(rule$claim_boundary, "calibrated coverage")
  structured_re_expect_all_match(rule$claim_boundary, "interval reliability")
  structured_re_expect_all_match(rule$claim_boundary, "q4/q8")
  structured_re_expect_all_match(rule$claim_boundary, "REML")
  structured_re_expect_all_match(rule$claim_boundary, "AI-REML")
  structured_re_expect_all_match(rule$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(rule$claim_boundary, "DRAC execution")
  structured_re_expect_all_match(rule$claim_boundary, "SR150 readiness")

  qseries_status <- qseries[qseries$cell_id %in% rule$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q2 slope-only coverage pregrid dry-run does not execute coverage", {
  pregrid <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-coverage-pregrid-dry-run.tsv"
  )
  rule <- structured_re_read_dashboard_tsv(
    "structured-re-q2-slope-replicated-denominator-rule.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  seed_manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q2-slope-coverage-pregrid-dry-run",
      "structured-re-q2-slope-coverage-pregrid-seed-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  cell_manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q2-slope-coverage-pregrid-dry-run",
      "structured-re-q2-slope-coverage-pregrid-cell-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    pregrid,
    c(
      "pregrid_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_rule",
      "source_seed_manifest",
      "source_cell_manifest",
      "current_denominator_action",
      "denominator_role",
      "planned_replicates",
      "planned_cells",
      "seed_manifest_rows",
      "target_cell_manifest_rows",
      "total_cell_manifest_rows",
      "nominal_coverage",
      "nominal_mcse_at_150",
      "replicates_for_mcse_threshold",
      "mcse_threshold",
      "mcse_threshold_status",
      "interval_methods",
      "retention_policy",
      "execution_status",
      "coverage_evaluable",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(pregrid), 12L)
  expect_equal(nrow(seed_manifest), 150L)
  expect_equal(nrow(cell_manifest), 1500L)
  expect_equal(seed_manifest$replicate_index, seq_len(150L))
  expect_equal(seed_manifest$seed, 730000L + seq_len(150L))
  expect_equal(
    seed_manifest$seed_role,
    rep("predeclared_q2_slope_pregrid", 150L)
  )
  expect_equal(seed_manifest$execution_status, rep("not_executed", 150L))

  expect_equal(pregrid$seed_manifest_rows, rep(150L, 12L))
  expect_equal(pregrid$total_cell_manifest_rows, rep(1500L, 12L))
  expect_equal(pregrid$nominal_coverage, rep(0.95, 12L))
  expect_equal(pregrid$nominal_mcse_at_150, rep(0.017795, 12L))
  expect_equal(pregrid$replicates_for_mcse_threshold, rep(475L, 12L))
  expect_equal(pregrid$mcse_threshold, rep(0.01, 12L))
  expect_equal(pregrid$mcse_threshold_status, rep("not_met_by_sr150", 12L))
  expect_equal(pregrid$execution_status, rep("not_executed", 12L))
  expect_equal(pregrid$coverage_evaluable, rep(FALSE, 12L))
  expect_equal(pregrid$coverage_status, rep("not_evaluated", 12L))
  expect_equal(pregrid$interval_claim_status, rep("diagnostic_only", 12L))
  expect_equal(pregrid$status, rep("covered", 12L))
  expect_equal(
    pregrid$retention_policy,
    rep(
      paste0(
        "retain_failed_profiles;retain_nonconverged_fits;",
        "retain_nonfinite_intervals;record_bootstrap_refit_attempts"
      ),
      12L
    )
  )

  executable <- pregrid[
    pregrid$denominator_role == "pregrid_target",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(executable), 10L)
  expect_equal(
    executable$current_denominator_action,
    rep("eligible_for_pregrid_with_retention", 10L)
  )
  expect_equal(executable$planned_replicates, rep(150L, 10L))
  expect_equal(executable$planned_cells, rep(150L, 10L))
  expect_equal(executable$target_cell_manifest_rows, rep(150L, 10L))

  held_out <- pregrid[
    pregrid$denominator_role == "visible_holdout",
    c(
      "structured_type",
      "endpoint_member",
      "current_denominator_action",
      "planned_replicates",
      "planned_cells",
      "target_cell_manifest_rows"
    ),
    drop = FALSE
  ]
  expect_equal(nrow(held_out), 2L)
  expect_setequal(
    paste(held_out$structured_type, held_out$endpoint_member),
    c("animal mu1:x+mu2:x", "relmat mu1:x+mu2:x")
  )
  expect_equal(
    held_out$current_denominator_action,
    rep("visible_holdout_until_smoke_profile_reconciled", 2L)
  )
  expect_equal(held_out$planned_replicates, rep(0L, 2L))
  expect_equal(held_out$planned_cells, rep(0L, 2L))
  expect_equal(held_out$target_cell_manifest_rows, rep(0L, 2L))

  cell_counts <- stats::aggregate(
    pregrid_cell_id ~ structured_type + endpoint_member,
    cell_manifest,
    length
  )
  names(cell_counts)[3L] <- "n_cells"
  expect_equal(nrow(cell_counts), 10L)
  expect_equal(cell_counts$n_cells, rep(150L, 10L))
  expect_false(any(
    paste(cell_manifest$structured_type, cell_manifest$endpoint_member) %in%
      c("animal mu1:x+mu2:x", "relmat mu1:x+mu2:x")
  ))
  expect_equal(cell_manifest$replicate_index, rep(seq_len(150L), 10L))
  expect_equal(cell_manifest$seed, rep(730000L + seq_len(150L), 10L))
  expect_equal(cell_manifest$execution_status, rep("not_executed", 1500L))
  expect_equal(cell_manifest$coverage_evaluable, rep(FALSE, 1500L))

  rule_key <- rule[, c(
    "structured_type",
    "endpoint_member",
    "current_denominator_action"
  )]
  merged_rule <- merge(
    pregrid,
    rule_key,
    by = c("structured_type", "endpoint_member"),
    suffixes = c("", ".source"),
    sort = FALSE
  )
  expect_equal(nrow(merged_rule), 12L)
  expect_equal(
    merged_rule$current_denominator_action,
    merged_rule$current_denominator_action.source
  )

  structured_re_expect_all_match(
    pregrid$claim_boundary,
    "coverage pre-grid dry-run only"
  )
  structured_re_expect_all_match(
    pregrid$claim_boundary,
    "no coverage-evaluable denominator evidence"
  )
  structured_re_expect_all_match(pregrid$claim_boundary, "calibrated coverage")
  structured_re_expect_all_match(pregrid$claim_boundary, "interval reliability")
  structured_re_expect_all_match(pregrid$claim_boundary, "q4/q8")
  structured_re_expect_all_match(pregrid$claim_boundary, "REML")
  structured_re_expect_all_match(pregrid$claim_boundary, "AI-REML")
  structured_re_expect_all_match(pregrid$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(pregrid$claim_boundary, "DRAC execution")
  structured_re_expect_all_match(pregrid$claim_boundary, "SR150 readiness")

  qseries_status <- qseries[
    qseries$cell_id %in% pregrid$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("mu-slope parity fixture dashboard keeps phylo-only fixture boundary", {
  fixture <- structured_re_read_dashboard_tsv(
    "structured-re-mu-slope-parity-fixture.tsv"
  )

  expect_named(
    fixture,
    c(
      "fixture_id",
      "formula_cell",
      "structured_type",
      "dimension",
      "endpoint",
      "slope_class",
      "estimator",
      "native_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "coefficient_order",
      "matrix_slot",
      "input_scale",
      "parity_status",
      "bridge_status",
      "interval_status",
      "coverage_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(fixture), 4L)
  expect_setequal(
    fixture$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )

  implemented <- fixture[
    fixture$structured_type %in% c("phylo", "spatial", "animal", "relmat"),
    ,
    drop = FALSE
  ]
  relmat <- fixture[fixture$structured_type == "relmat", , drop = FALSE]

  expect_equal(implemented$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    implemented$parity_status,
    rep("covered_same_target_fixture", 4L)
  )
  expect_equal(
    implemented$coefficient_order,
    rep(
      "mu:(Intercept);mu:x;sd_mu:structured(Intercept);sd_mu:structured(x)",
      4L
    )
  )
  expect_equal(relmat$matrix_slot, "K")
  expect_match(relmat$claim_boundary, "K-matrix", fixed = TRUE)
  expect_match(relmat$claim_boundary, "K/Q same-target parity", fixed = TRUE)
  expect_match(relmat$next_gate, "K/Q same-target parity", fixed = TRUE)
  structured_re_expect_all_match(fixture$claim_boundary, "coverage")
})

test_that("sigma-slope parity fixture dashboard is provider-specific", {
  fixture <- structured_re_read_dashboard_tsv(
    "structured-re-sigma-slope-parity-fixture.tsv"
  )

  expect_named(
    fixture,
    c(
      "fixture_id",
      "formula_cell",
      "structured_type",
      "dimension",
      "endpoint",
      "slope_class",
      "estimator",
      "native_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "coefficient_order",
      "matrix_slot",
      "input_scale",
      "parity_status",
      "bridge_status",
      "interval_status",
      "coverage_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(fixture), 4L)
  expect_setequal(
    fixture$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(fixture$endpoint, rep("sigma", 4L))
  expect_equal(fixture$slope_class, rep("independent_one_slope", 4L))
  expect_equal(fixture$estimator, rep("ML", 4L))
  expect_equal(fixture$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    fixture$parity_status,
    rep("covered_same_target_fixture", 4L)
  )
  expect_equal(
    fixture$coefficient_order,
    rep(
      "sigma:(Intercept);sigma:x;sd_sigma:structured(Intercept);sd_sigma:structured(x)",
      4L
    )
  )
  expect_equal(fixture$matrix_slot, c("tree", "coords", "A", "K"))
  expect_match(fixture$claim_boundary, "broad bridge support", fixed = TRUE)
  expect_match(fixture$claim_boundary, "matched mu+sigma", fixed = TRUE)
  expect_match(fixture$claim_boundary, "coverage", fixed = TRUE)
  expect_match(
    fixture$claim_boundary[fixture$structured_type == "spatial"],
    "fixed-covariance",
    fixed = TRUE
  )
  expect_match(
    fixture$claim_boundary[fixture$structured_type == "animal"],
    "A-matrix",
    fixed = TRUE
  )
  expect_match(
    fixture$claim_boundary[fixture$structured_type == "relmat"],
    "K-matrix",
    fixed = TRUE
  )
})

test_that("sigma-slope interval plan remains sigma-only and target-level", {
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-sigma-slope-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    plan,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "interval_methods",
      "required_fit_evidence",
      "required_interval_evidence",
      "denominator_fields",
      "current_blocker",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(plan), 8L)
  expect_setequal(
    plan$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(plan$target_kind, rep("direct_sd", 8L))
  expect_equal(
    plan$endpoint_member,
    rep(c("sigma:(Intercept)", "sigma:x"), 4L)
  )
  expect_setequal(
    plan$profile_target,
    c(
      "sd:sigma:phylo(1 | species)",
      "sd:sigma:phylo(0 + x | species)",
      "sd:sigma:spatial(1 | site)",
      "sd:sigma:spatial(0 + x | site)",
      "sd:sigma:animal(1 | id)",
      "sd:sigma:animal(0 + x | id)",
      "sd:sigma:relmat(1 | id)",
      "sd:sigma:relmat(0 + x | id)"
    )
  )
  expect_setequal(plan$direct_sd_target, c("sd_sigma_intercept", "sd_sigma_x"))
  expect_equal(plan$current_blocker, rep("interval_diagnostics_not_run", 8L))
  expect_equal(plan$status, rep("planned", 8L))
  structured_re_expect_all_match(plan$interval_methods, "wald")
  structured_re_expect_all_match(plan$interval_methods, "profile")
  structured_re_expect_all_match(plan$interval_methods, "bootstrap")
  structured_re_expect_all_match(plan$required_fit_evidence, "point_fit")
  structured_re_expect_all_match(
    plan$required_fit_evidence,
    "same_target_fixture_parity"
  )
  structured_re_expect_all_match(plan$claim_boundary, "no interval reliability")
  structured_re_expect_all_match(plan$claim_boundary, "interval coverage")
  structured_re_expect_all_match(plan$claim_boundary, "REML")
  structured_re_expect_all_match(plan$claim_boundary, "AI-REML")
  structured_re_expect_all_match(plan$claim_boundary, "matched mu+sigma")
  structured_re_expect_all_match(plan$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(plan$next_gate, "before calibrated coverage")

  qseries_plan <- qseries[qseries$cell_id %in% plan$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_plan), 4L)
  expect_equal(qseries_plan$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_plan$interval_status, rep("planned", 4L))
  expect_equal(qseries_plan$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_plan$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("sigma-slope interval status remains diagnostic-only", {
  status <- structured_re_read_dashboard_tsv(
    "structured-re-sigma-slope-interval-diagnostic-status.tsv"
  )
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-sigma-slope-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-sigma-slope-interval-smoke",
      "structured-re-sigma-slope-interval-smoke-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    status,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "source_artifact",
      "observed_target_rows",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_finite_intervals",
      "wald_status",
      "profile_status",
      "bootstrap_status",
      "interval_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(status), 8L)
  expect_equal(nrow(artifact), 24L)
  expect_equal(status$observed_target_rows, rep(1L, 8L))
  expect_equal(status$n_fit_ok, rep(1L, 8L))
  expect_equal(status$n_converged, rep(1L, 8L))
  expect_equal(status$n_pdhess, rep(1L, 8L))
  expect_equal(status$bootstrap_status, rep("finite", 8L))
  expect_equal(status$interval_claim_status, rep("diagnostic_only", 8L))
  expect_equal(status$status, rep("covered", 8L))

  all_finite <- status[
    status$interval_status == "wald_profile_bootstrap_finite",
    c("structured_type", "endpoint_member", "n_finite_intervals"),
    drop = FALSE
  ]
  expect_equal(nrow(all_finite), 7L)
  expect_setequal(
    paste(all_finite$structured_type, all_finite$endpoint_member),
    c(
      "phylo sigma:(Intercept)",
      "phylo sigma:x",
      "spatial sigma:(Intercept)",
      "spatial sigma:x",
      "animal sigma:(Intercept)",
      "relmat sigma:(Intercept)",
      "relmat sigma:x"
    )
  )
  expect_equal(all_finite$n_finite_intervals, rep(3L, 7L))

  profile_failed <- status[
    status$interval_status == "wald_bootstrap_finite_profile_failed",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(profile_failed), 1L)
  expect_equal(profile_failed$structured_type, "animal")
  expect_equal(profile_failed$endpoint_member, "sigma:x")
  expect_equal(profile_failed$n_finite_intervals, 2L)
  expect_equal(profile_failed$wald_status, "finite")
  expect_equal(profile_failed$profile_status, "nonfinite")
  expect_equal(profile_failed$bootstrap_status, "finite")
  expect_equal(profile_failed$failure_class, "profile_failed_or_nonfinite")

  plan_key <- plan[, c("structured_type", "endpoint_member")]
  status_key <- status[, c("structured_type", "endpoint_member")]
  expect_equal(
    sort(paste(status_key$structured_type, status_key$endpoint_member)),
    sort(paste(plan_key$structured_type, plan_key$endpoint_member))
  )
  artifact_key <- paste(
    artifact$provider,
    artifact$endpoint_member,
    artifact$interval_method,
    sep = "::"
  )
  expect_equal(anyDuplicated(artifact_key), 0L)
  expect_setequal(artifact$interval_method, c("wald", "profile", "bootstrap"))
  expect_equal(sum(artifact$interval_finite), sum(status$n_finite_intervals))
  expect_equal(unique(artifact$profile_ready), TRUE)

  structured_re_expect_all_match(
    status$claim_boundary,
    "sigma-only one-slope interval smoke only"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(status$claim_boundary, "interval coverage")
  structured_re_expect_all_match(status$claim_boundary, "REML")
  structured_re_expect_all_match(status$claim_boundary, "AI-REML")
  structured_re_expect_all_match(status$claim_boundary, "matched mu+sigma")
  structured_re_expect_all_match(status$claim_boundary, "broad bridge support")

  qseries_status <- qseries[qseries$cell_id %in% status$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("sigma-slope interval stability probe remains diagnostic-only", {
  status <- structured_re_read_dashboard_tsv(
    "structured-re-sigma-slope-interval-stability-probe.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-sigma-slope-interval-stability-probe",
      "structured-re-sigma-slope-interval-stability-probe-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    status,
    c(
      "probe_id",
      "cell_id",
      "variant",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "source_artifact",
      "n_each",
      "intended_sd_sigma_intercept",
      "intended_sd_sigma_x",
      "observed_target_rows",
      "n_fit_ok",
      "n_pdhess",
      "estimate",
      "wald_status",
      "profile_status",
      "stability_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(status), 16L)
  expect_equal(nrow(artifact), 32L)
  expect_setequal(status$variant, c("strong", "stronger_sigma"))
  expect_setequal(
    status$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_setequal(
    status$endpoint_member,
    c("sigma:(Intercept)", "sigma:x")
  )
  expect_setequal(
    status$profile_target,
    c(
      "sd:sigma:phylo(1 | species)",
      "sd:sigma:phylo(0 + x | species)",
      "sd:sigma:spatial(1 | site)",
      "sd:sigma:spatial(0 + x | site)",
      "sd:sigma:animal(1 | id)",
      "sd:sigma:animal(0 + x | id)",
      "sd:sigma:relmat(1 | id)",
      "sd:sigma:relmat(0 + x | id)"
    )
  )
  expect_equal(status$target_kind, rep("direct_sd", 16L))
  expect_setequal(
    status$direct_sd_target,
    c("sd_sigma_intercept", "sd_sigma_x")
  )
  expect_equal(status$n_each[status$variant == "strong"], rep(22L, 8L))
  expect_equal(
    status$n_each[status$variant == "stronger_sigma"],
    rep(24L, 8L)
  )
  expect_equal(
    unique(status$intended_sd_sigma_intercept[status$variant == "strong"]),
    0.60
  )
  expect_equal(
    unique(status$intended_sd_sigma_x[status$variant == "strong"]),
    0.45
  )
  expect_equal(
    unique(
      status$intended_sd_sigma_intercept[
        status$variant == "stronger_sigma"
      ]
    ),
    0.85
  )
  expect_equal(
    unique(status$intended_sd_sigma_x[status$variant == "stronger_sigma"]),
    0.65
  )
  expect_equal(status$observed_target_rows, rep(1L, 16L))
  expect_equal(status$n_fit_ok, rep(1L, 16L))
  expect_equal(status$n_pdhess, rep(1L, 16L))
  expect_equal(status$wald_status, rep("finite", 16L))
  expect_equal(status$profile_status, rep("finite", 16L))
  expect_equal(status$stability_status, rep("wald_profile_finite", 16L))
  expect_equal(status$failure_class, rep("none", 16L))
  expect_equal(status$interval_claim_status, rep("diagnostic_only", 16L))
  expect_equal(status$status, rep("covered", 16L))

  artifact_key <- paste(
    artifact$variant,
    artifact$provider,
    artifact$endpoint_member,
    artifact$interval_method,
    sep = "::"
  )
  expect_equal(anyDuplicated(artifact_key), 0L)
  expect_setequal(artifact$interval_method, c("wald", "profile"))
  expect_equal(sum(artifact$interval_finite), 32L)
  expect_equal(unique(artifact$profile_ready), TRUE)

  structured_re_expect_all_match(
    status$claim_boundary,
    "sigma-only one-slope stability probe only"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(status$claim_boundary, "interval coverage")
  structured_re_expect_all_match(status$claim_boundary, "REML")
  structured_re_expect_all_match(status$claim_boundary, "AI-REML")
  structured_re_expect_all_match(status$claim_boundary, "matched mu+sigma")
  structured_re_expect_all_match(status$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "relmat"],
    "Q bridge"
  )

  qseries_status <- qseries[qseries$cell_id %in% status$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("sigma-slope denominator admission remains diagnostic-only", {
  denom <- structured_re_read_dashboard_tsv(
    "structured-re-sigma-slope-denominator-admission.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    denom,
    c(
      "denominator_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "source_interval_status",
      "source_stability_probe",
      "source_interval_artifact",
      "source_stability_artifact",
      "smoke_interval_status",
      "smoke_n_finite_intervals",
      "smoke_wald_status",
      "smoke_profile_status",
      "smoke_bootstrap_status",
      "stability_variant_count",
      "stability_wald_profile_finite_count",
      "stability_pdhess_true_count",
      "denominator_admission",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(denom), 8L)
  expect_setequal(
    denom$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_setequal(denom$endpoint_member, c("sigma:(Intercept)", "sigma:x"))
  expect_equal(denom$target_kind, rep("direct_sd", 8L))
  expect_setequal(
    denom$direct_sd_target,
    c("sd_sigma_intercept", "sd_sigma_x")
  )
  expect_equal(denom$stability_variant_count, rep(2L, 8L))
  expect_equal(denom$stability_wald_profile_finite_count, rep(2L, 8L))
  expect_equal(denom$stability_pdhess_true_count, rep(2L, 8L))
  expect_equal(denom$smoke_bootstrap_status, rep("finite", 8L))
  expect_equal(denom$coverage_status, rep("not_evaluated", 8L))
  expect_equal(denom$interval_claim_status, rep("diagnostic_only", 8L))
  expect_equal(denom$status, rep("covered", 8L))

  admitted <- denom[
    denom$denominator_admission == "diagnostic_denominator_candidate",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(admitted), 7L)
  expect_equal(
    admitted$smoke_interval_status,
    rep("wald_profile_bootstrap_finite", 7L)
  )
  expect_equal(admitted$smoke_n_finite_intervals, rep(3L, 7L))
  expect_equal(admitted$smoke_wald_status, rep("finite", 7L))
  expect_equal(admitted$smoke_profile_status, rep("finite", 7L))

  holdout <- denom[
    denom$denominator_admission == "not_admitted_profile_failure",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(holdout), 1L)
  expect_equal(holdout$structured_type, "animal")
  expect_equal(holdout$endpoint_member, "sigma:x")
  expect_equal(
    holdout$smoke_interval_status,
    "wald_bootstrap_finite_profile_failed"
  )
  expect_equal(holdout$smoke_n_finite_intervals, 2L)
  expect_equal(holdout$smoke_wald_status, "finite")
  expect_equal(holdout$smoke_profile_status, "nonfinite")

  structured_re_expect_all_match(
    denom$claim_boundary,
    "denominator-admission diagnostic only"
  )
  structured_re_expect_all_match(
    denom$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(denom$claim_boundary, "interval coverage")
  structured_re_expect_all_match(denom$claim_boundary, "coverage acceptance")
  structured_re_expect_all_match(denom$claim_boundary, "matched mu+sigma")
  structured_re_expect_all_match(denom$claim_boundary, "q4/q8")
  structured_re_expect_all_match(denom$claim_boundary, "REML")
  structured_re_expect_all_match(denom$claim_boundary, "AI-REML")
  structured_re_expect_all_match(denom$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(
    denom$claim_boundary[denom$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    denom$claim_boundary[denom$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    denom$claim_boundary[denom$structured_type == "relmat"],
    "Q bridge"
  )

  qseries_status <- qseries[qseries$cell_id %in% denom$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("sigma-slope replicated denominator rule keeps coverage blocked", {
  rule <- structured_re_read_dashboard_tsv(
    "structured-re-sigma-slope-replicated-denominator-rule.tsv"
  )
  admission <- structured_re_read_dashboard_tsv(
    "structured-re-sigma-slope-denominator-admission.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    rule,
    c(
      "rule_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "source_admission",
      "source_stability_probe",
      "source_interval_status",
      "admission_status",
      "stability_variant_count",
      "stability_wald_profile_finite_count",
      "stability_pdhess_true_count",
      "smoke_profile_status",
      "current_denominator_action",
      "pregrid_min_replicates",
      "seed_policy",
      "failed_profile_retention",
      "nonconverged_fit_retention",
      "nonfinite_interval_retention",
      "bootstrap_refit_retention",
      "mcse_threshold",
      "coverage_evaluable",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(rule), 8L)
  expect_setequal(
    rule$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_setequal(rule$endpoint_member, c("sigma:(Intercept)", "sigma:x"))
  expect_equal(rule$target_kind, rep("direct_sd", 8L))
  expect_setequal(
    rule$direct_sd_target,
    c("sd_sigma_intercept", "sd_sigma_x")
  )
  expect_equal(rule$stability_variant_count, rep(2L, 8L))
  expect_equal(rule$stability_wald_profile_finite_count, rep(2L, 8L))
  expect_equal(rule$stability_pdhess_true_count, rep(2L, 8L))
  expect_equal(rule$pregrid_min_replicates, rep(150L, 8L))
  expect_equal(
    rule$seed_policy,
    rep("predeclared_seed_manifest_required_before_execution", 8L)
  )
  expect_equal(rule$failed_profile_retention, rep("retain_in_denominator", 8L))
  expect_equal(
    rule$nonconverged_fit_retention,
    rep("retain_in_denominator", 8L)
  )
  expect_equal(
    rule$nonfinite_interval_retention,
    rep("retain_in_denominator", 8L)
  )
  expect_equal(
    rule$bootstrap_refit_retention,
    rep("record_attempts_and_retain_target_denominator", 8L)
  )
  expect_equal(rule$mcse_threshold, rep(0.01, 8L))
  expect_equal(rule$coverage_evaluable, rep(FALSE, 8L))
  expect_equal(rule$coverage_status, rep("not_evaluated", 8L))
  expect_equal(rule$interval_claim_status, rep("diagnostic_only", 8L))
  expect_equal(rule$status, rep("covered", 8L))

  eligible <- rule[
    rule$current_denominator_action == "eligible_for_pregrid_with_retention",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(eligible), 7L)
  expect_equal(
    eligible$admission_status,
    rep("diagnostic_denominator_candidate", 7L)
  )
  expect_equal(eligible$smoke_profile_status, rep("finite", 7L))

  held_out <- rule[
    rule$current_denominator_action ==
      "visible_holdout_until_smoke_profile_reconciled",
    c(
      "structured_type",
      "endpoint_member",
      "admission_status",
      "smoke_profile_status"
    ),
    drop = FALSE
  ]
  expect_equal(nrow(held_out), 1L)
  expect_equal(held_out$structured_type, "animal")
  expect_equal(held_out$endpoint_member, "sigma:x")
  expect_equal(held_out$admission_status, "not_admitted_profile_failure")
  expect_equal(held_out$smoke_profile_status, "nonfinite")

  admission_key <- admission[, c(
    "structured_type",
    "endpoint_member",
    "denominator_admission",
    "smoke_profile_status"
  )]
  names(admission_key)[3L] <- "admission_status"
  merged_admission <- merge(
    rule,
    admission_key,
    by = c("structured_type", "endpoint_member"),
    suffixes = c("", ".source"),
    sort = FALSE
  )
  expect_equal(nrow(merged_admission), 8L)
  expect_equal(
    merged_admission$admission_status,
    merged_admission$admission_status.source
  )
  expect_equal(
    merged_admission$smoke_profile_status,
    merged_admission$smoke_profile_status.source
  )

  structured_re_expect_all_match(
    rule$claim_boundary,
    "replicated-denominator rule only"
  )
  structured_re_expect_all_match(
    rule$claim_boundary,
    "no coverage-evaluable denominator evidence"
  )
  structured_re_expect_all_match(rule$claim_boundary, "calibrated coverage")
  structured_re_expect_all_match(rule$claim_boundary, "interval reliability")
  structured_re_expect_all_match(rule$claim_boundary, "matched mu+sigma")
  structured_re_expect_all_match(rule$claim_boundary, "q4/q8")
  structured_re_expect_all_match(rule$claim_boundary, "REML")
  structured_re_expect_all_match(rule$claim_boundary, "AI-REML")
  structured_re_expect_all_match(rule$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(rule$claim_boundary, "DRAC execution")
  structured_re_expect_all_match(rule$claim_boundary, "SR150 readiness")

  qseries_status <- qseries[qseries$cell_id %in% rule$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("sigma-slope coverage pregrid dry-run remains not executed", {
  pregrid <- structured_re_read_dashboard_tsv(
    "structured-re-sigma-slope-coverage-pregrid-dry-run.tsv"
  )
  rule <- structured_re_read_dashboard_tsv(
    "structured-re-sigma-slope-replicated-denominator-rule.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  seed_manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-sigma-slope-coverage-pregrid-dry-run",
      "structured-re-sigma-slope-coverage-pregrid-seed-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  cell_manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-sigma-slope-coverage-pregrid-dry-run",
      "structured-re-sigma-slope-coverage-pregrid-cell-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    pregrid,
    c(
      "pregrid_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "source_rule",
      "source_seed_manifest",
      "source_cell_manifest",
      "current_denominator_action",
      "denominator_role",
      "planned_replicates",
      "planned_cells",
      "seed_manifest_rows",
      "target_cell_manifest_rows",
      "total_cell_manifest_rows",
      "nominal_coverage",
      "nominal_mcse_at_150",
      "replicates_for_mcse_threshold",
      "mcse_threshold",
      "mcse_threshold_status",
      "interval_methods",
      "retention_policy",
      "execution_status",
      "coverage_evaluable",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(pregrid), 8L)
  expect_equal(nrow(seed_manifest), 150L)
  expect_equal(nrow(cell_manifest), 1050L)
  expect_equal(seed_manifest$replicate_index, seq_len(150L))
  expect_equal(seed_manifest$seed, 740000L + seq_len(150L))
  expect_equal(
    seed_manifest$seed_role,
    rep("predeclared_sigma_slope_pregrid", 150L)
  )
  expect_equal(seed_manifest$execution_status, rep("not_executed", 150L))

  expect_equal(pregrid$seed_manifest_rows, rep(150L, 8L))
  expect_equal(pregrid$total_cell_manifest_rows, rep(1050L, 8L))
  expect_equal(pregrid$nominal_coverage, rep(0.95, 8L))
  expect_equal(pregrid$nominal_mcse_at_150, rep(0.017795, 8L))
  expect_equal(pregrid$replicates_for_mcse_threshold, rep(475L, 8L))
  expect_equal(pregrid$mcse_threshold, rep(0.01, 8L))
  expect_equal(pregrid$mcse_threshold_status, rep("not_met_by_sr150", 8L))
  expect_equal(
    pregrid$interval_methods,
    rep("wald;endpoint_profile;bootstrap", 8L)
  )
  expect_equal(pregrid$execution_status, rep("not_executed", 8L))
  expect_equal(pregrid$coverage_evaluable, rep(FALSE, 8L))
  expect_equal(pregrid$coverage_status, rep("not_evaluated", 8L))
  expect_equal(pregrid$interval_claim_status, rep("diagnostic_only", 8L))
  expect_equal(pregrid$status, rep("covered", 8L))

  targets <- pregrid[
    pregrid$denominator_role == "pregrid_target",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(targets), 7L)
  expect_equal(targets$planned_replicates, rep(150L, 7L))
  expect_equal(targets$planned_cells, rep(150L, 7L))
  expect_equal(targets$target_cell_manifest_rows, rep(150L, 7L))

  holdout <- pregrid[
    pregrid$denominator_role == "visible_holdout",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(holdout), 1L)
  expect_equal(holdout$structured_type, "animal")
  expect_equal(holdout$endpoint_member, "sigma:x")
  expect_equal(holdout$planned_replicates, 0L)
  expect_equal(holdout$planned_cells, 0L)
  expect_equal(holdout$target_cell_manifest_rows, 0L)

  rule_key <- rule[, c(
    "structured_type",
    "endpoint_member",
    "current_denominator_action"
  )]
  merged_rule <- merge(
    pregrid,
    rule_key,
    by = c("structured_type", "endpoint_member"),
    suffixes = c("", ".source"),
    sort = FALSE
  )
  expect_equal(nrow(merged_rule), 8L)
  expect_equal(
    merged_rule$current_denominator_action,
    merged_rule$current_denominator_action.source
  )

  cell_key <- paste(
    cell_manifest$structured_type,
    cell_manifest$endpoint_member
  )
  expect_equal(anyDuplicated(cell_manifest$pregrid_cell_id), 0L)
  expect_equal(
    unique(cell_manifest$current_denominator_action),
    "eligible_for_pregrid_with_retention"
  )
  expect_equal(unique(cell_manifest$execution_status), "not_executed")
  expect_equal(unique(cell_manifest$coverage_evaluable), FALSE)
  expect_equal(
    sort(as.integer(table(cell_key))),
    rep(150L, 7L)
  )
  expect_equal(sum(cell_key == "animal sigma:x"), 0L)

  structured_re_expect_all_match(
    pregrid$claim_boundary,
    "coverage pre-grid dry-run only"
  )
  structured_re_expect_all_match(
    pregrid$claim_boundary,
    "no coverage-evaluable denominator evidence"
  )
  structured_re_expect_all_match(pregrid$claim_boundary, "calibrated coverage")
  structured_re_expect_all_match(pregrid$claim_boundary, "interval reliability")
  structured_re_expect_all_match(pregrid$claim_boundary, "matched mu+sigma")
  structured_re_expect_all_match(pregrid$claim_boundary, "q4/q8")
  structured_re_expect_all_match(pregrid$claim_boundary, "REML")
  structured_re_expect_all_match(pregrid$claim_boundary, "AI-REML")
  structured_re_expect_all_match(pregrid$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(pregrid$claim_boundary, "DRAC execution")
  structured_re_expect_all_match(pregrid$claim_boundary, "SR150 readiness")

  qseries_status <- qseries[
    qseries$cell_id %in% pregrid$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("matched mu+sigma one-slope readiness records native point fits only", {
  readiness <- structured_re_read_dashboard_tsv(
    "structured-re-mu-sigma-slope-readiness.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    readiness,
    c(
      "readiness_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "dimension_pattern",
      "endpoint_set",
      "slope_class",
      "desired_endpoint_member_set",
      "current_separate_mu_evidence",
      "current_separate_sigma_evidence",
      "extractor_identity_gate",
      "runtime_status",
      "bridge_status",
      "interval_status",
      "coverage_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(readiness), 4L)
  expect_setequal(
    readiness$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(readiness$dimension_pattern, rep("q1_plus_q1", 4L))
  expect_equal(readiness$endpoint_set, rep("mu+sigma", 4L))
  expect_equal(readiness$slope_class, rep("independent_one_slope", 4L))
  expect_equal(
    readiness$desired_endpoint_member_set,
    rep("mu:(Intercept);mu:x;sigma:(Intercept);sigma:x", 4L)
  )
  expect_equal(
    readiness$current_separate_mu_evidence,
    rep(
      "docs/dev-log/dashboard/structured-re-mu-slope-parity-fixture.tsv",
      4L
    )
  )
  expect_equal(
    readiness$current_separate_sigma_evidence,
    rep(
      "docs/dev-log/dashboard/structured-re-sigma-slope-parity-fixture.tsv",
      4L
    )
  )
  expect_equal(
    readiness$extractor_identity_gate,
    rep("endpoint_member_identity_ready", 4L)
  )
  expect_equal(readiness$runtime_status, rep("point_fit", 4L))
  expect_equal(readiness$bridge_status, rep("planned", 4L))
  expect_equal(readiness$interval_status, rep("planned", 4L))
  expect_equal(readiness$coverage_status, rep("planned", 4L))
  structured_re_expect_all_match(readiness$claim_boundary, "point-fit")
  structured_re_expect_all_match(readiness$claim_boundary, "coverage")
  structured_re_expect_all_match(readiness$next_gate, "bridge fixture")
  expect_equal(
    readiness$evidence_url,
    c(
      "tests/testthat/test-phylo-gaussian.R",
      "tests/testthat/test-spatial-gaussian.R",
      "tests/testthat/test-animal-relmat-gaussian.R",
      "tests/testthat/test-animal-relmat-gaussian.R"
    )
  )

  qseries_ready <- qseries[
    qseries$cell_id %in% readiness$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_ready), 4L)
  expect_equal(qseries_ready$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_ready$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_ready$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_ready$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_ready$interval_status, rep("planned", 4L))
  expect_equal(qseries_ready$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_ready$evidence_url,
    rep(
      "docs/dev-log/dashboard/structured-re-mu-sigma-slope-parity-fixture.tsv",
      4L
    )
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "four endpoint members"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "native point-fit"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "same-target fixture"
  )
  structured_re_expect_all_match(
    qseries_ready$next_gate,
    "interval diagnostics"
  )
})

test_that("q4 all-four one-slope identity ledger records exact runtime promotion", {
  preflight <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-identity-preflight.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    preflight,
    c(
      "identity_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "dimension_pattern",
      "endpoint_set",
      "slope_class",
      "desired_endpoint_member_set",
      "coefficient_order",
      "planned_direct_sd_target_set",
      "direct_sd_target_count",
      "labelled_covariance_pair_count",
      "covariance_layout",
      "extractor_identity_gate",
      "runtime_status",
      "bridge_status",
      "interval_status",
      "coverage_status",
      "source_qseries_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(preflight), 4L)
  expect_setequal(
    preflight$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(preflight$dimension_pattern, rep("q8", 4L))
  expect_equal(preflight$endpoint_set, rep("mu1+mu2+sigma1+sigma2", 4L))
  expect_equal(
    preflight$slope_class,
    rep("labelled_slope_covariance", 4L)
  )
  expect_equal(
    preflight$desired_endpoint_member_set,
    rep(
      paste(
        c(
          "mu1:(Intercept)",
          "mu1:x",
          "mu2:(Intercept)",
          "mu2:x",
          "sigma1:(Intercept)",
          "sigma1:x",
          "sigma2:(Intercept)",
          "sigma2:x"
        ),
        collapse = ";"
      ),
      4L
    )
  )
  expect_equal(
    preflight$coefficient_order,
    rep("(Intercept);x;(Intercept);x;(Intercept);x;(Intercept);x", 4L)
  )
  expect_equal(
    preflight$planned_direct_sd_target_set,
    rep(
      paste(
        c(
          "sd_mu1_intercept",
          "sd_mu1_x",
          "sd_mu2_intercept",
          "sd_mu2_x",
          "sd_sigma1_intercept",
          "sd_sigma1_x",
          "sd_sigma2_intercept",
          "sd_sigma2_x"
        ),
        collapse = ";"
      ),
      4L
    )
  )
  expect_equal(preflight$direct_sd_target_count, rep(8L, 4L))
  expect_equal(preflight$labelled_covariance_pair_count, rep(28L, 4L))
  expect_equal(
    preflight$covariance_layout,
    rep("labelled_structured_endpoint_covariance", 4L)
  )
  runtime_providers <- c("phylo", "spatial", "animal", "relmat")
  expect_equal(
    preflight$extractor_identity_gate,
    ifelse(
      preflight$structured_type %in% runtime_providers,
      "runtime_test",
      "preflight_only"
    )
  )
  expect_equal(
    preflight$runtime_status,
    ifelse(
      preflight$structured_type %in% runtime_providers,
      "point_fit",
      "planned"
    )
  )
  expect_equal(preflight$bridge_status, rep("planned", 4L))
  expect_equal(preflight$interval_status, rep("planned", 4L))
  expect_equal(preflight$coverage_status, rep("planned", 4L))
  structured_re_expect_all_match(
    preflight$claim_boundary[!preflight$structured_type %in% runtime_providers],
    "preflight only"
  )
  structured_re_expect_all_match(
    preflight$claim_boundary[preflight$structured_type %in% runtime_providers],
    "runtime point-fit"
  )
  structured_re_expect_all_match(
    preflight$claim_boundary[preflight$structured_type %in% runtime_providers],
    "extractor evidence"
  )
  structured_re_expect_all_match(preflight$claim_boundary, "runtime")
  structured_re_expect_all_match(preflight$claim_boundary, "coverage")
  structured_re_expect_all_match(preflight$claim_boundary, "q4 REML")
  structured_re_expect_all_match(preflight$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    preflight$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(
    preflight$next_gate[!preflight$structured_type %in% runtime_providers],
    "runtime mapping"
  )
  structured_re_expect_all_match(
    preflight$next_gate[preflight$structured_type %in% runtime_providers],
    "bridge fixture"
  )

  qseries_planned <- qseries[
    qseries$cell_id %in% preflight$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_planned), 4L)
  qseries_planned <- qseries_planned[
    match(preflight$cell_id, qseries_planned$cell_id),
    ,
    drop = FALSE
  ]
  expect_equal(
    qseries_planned$route,
    rep("native_direct_bridge_fixture", 4L)
  )
  expect_equal(
    qseries_planned$fit_status,
    rep("point_fit", 4L)
  )
  expect_equal(
    qseries_planned$extractor_status,
    rep("extractor_ready", 4L)
  )
  expect_equal(qseries_planned$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_planned$interval_status, rep("planned", 4L))
  expect_equal(qseries_planned$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_planned$evidence_url,
    rep(
      "docs/dev-log/dashboard/structured-re-q4-slope-parity-fixture.tsv",
      4L
    )
  )
  expect_equal(
    qseries_planned$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
  structured_re_expect_all_match(
    qseries_planned$claim_boundary[
      !preflight$structured_type %in% runtime_providers
    ],
    "eight-member identity preflight"
  )
  structured_re_expect_all_match(
    qseries_planned$claim_boundary[
      preflight$structured_type %in% runtime_providers
    ],
    "native ML point-fit"
  )
  structured_re_expect_all_match(
    qseries_planned$claim_boundary[
      preflight$structured_type %in% runtime_providers
    ],
    "exact eight-member endpoint map"
  )
  structured_re_expect_all_match(
    qseries_planned$claim_boundary,
    "same-target fixture"
  )
  structured_re_expect_all_match(
    qseries_planned$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(qseries_planned$claim_boundary, "q4 REML")
  structured_re_expect_all_match(qseries_planned$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    qseries_planned$claim_boundary[
      !preflight$structured_type %in% runtime_providers
    ],
    "public support remains planned"
  )
  structured_re_expect_all_match(
    qseries_planned$claim_boundary[
      preflight$structured_type %in% runtime_providers
    ],
    "public support remain planned"
  )
  structured_re_expect_all_match(
    qseries_planned$next_gate[
      !preflight$structured_type %in% runtime_providers
    ],
    "runtime mapping"
  )
  structured_re_expect_all_match(
    qseries_planned$next_gate[preflight$structured_type %in% runtime_providers],
    "interval diagnostics"
  )
})

test_that("q4 location one-slope parity fixture records exact bridge fixture only", {
  fixture <- structured_re_read_dashboard_tsv(
    "structured-re-q4-location-slope-parity-fixture.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    fixture,
    c(
      "fixture_id",
      "formula_cell",
      "structured_type",
      "dimension",
      "endpoint",
      "slope_class",
      "estimator",
      "native_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "coefficient_order",
      "matrix_slot",
      "input_scale",
      "parity_status",
      "bridge_status",
      "interval_status",
      "coverage_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(fixture), 4L)
  expect_setequal(
    fixture$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(fixture$dimension, rep("q4", 4L))
  expect_equal(fixture$endpoint, rep("mu1+mu2", 4L))
  expect_equal(fixture$slope_class, rep("labelled_slope_covariance", 4L))
  expect_equal(fixture$estimator, rep("ML", 4L))
  expect_equal(fixture$native_status, rep("fixture_available", 4L))
  expect_equal(fixture$direct_drmjl_status, rep("fixture_available", 4L))
  expect_equal(fixture$r_via_julia_status, rep("fixture_available", 4L))
  expect_equal(fixture$bridge_status, rep("fixture_parity", 4L))
  expect_equal(fixture$interval_status, rep("planned", 4L))
  expect_equal(fixture$coverage_status, rep("planned", 4L))

  expected_endpoint_members <- c(
    "mu1:(Intercept)",
    "mu1:x",
    "mu2:(Intercept)",
    "mu2:x"
  )
  q4_location_member_token <- function(member) {
    gsub("[()]", "", gsub(":", "_", member))
  }
  expected_sd_terms <- paste0("sd_", expected_endpoint_members, ":structured")
  expected_cor_terms <- utils::combn(
    expected_endpoint_members,
    2L,
    FUN = function(pair) {
      paste0(
        "cor_",
        q4_location_member_token(pair[[1L]]),
        "_",
        q4_location_member_token(pair[[2L]]),
        ":structured"
      )
    }
  )
  expected_order <- paste(
    c(expected_endpoint_members, expected_sd_terms, expected_cor_terms),
    collapse = ";"
  )
  coefficient_terms <- strsplit(
    fixture$coefficient_order[[1L]],
    ";",
    fixed = TRUE
  )[[1L]]
  expect_length(coefficient_terms, 14L)
  expect_equal(coefficient_terms[seq_len(4L)], expected_endpoint_members)
  expect_equal(sum(grepl("^sd_", coefficient_terms)), 4L)
  expect_equal(sum(grepl("^cor_", coefficient_terms)), 6L)
  expect_equal(fixture$coefficient_order, rep(expected_order, 4L))
  expect_equal(fixture$matrix_slot, c("tree", "coords", "A", "K"))
  expect_equal(
    fixture$input_scale,
    c(
      "ultrametric_tree_branch_lengths",
      "coordinates_to_fixed_covariance_K",
      "additive_covariance",
      "user_covariance"
    )
  )
  structured_re_expect_all_match(
    fixture$claim_boundary,
    "q4 location one-slope"
  )
  structured_re_expect_all_match(fixture$claim_boundary, "four-member q4")
  structured_re_expect_all_match(fixture$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(
    fixture$claim_boundary,
    "partial location-scale"
  )
  structured_re_expect_all_match(fixture$claim_boundary, "interval reliability")
  structured_re_expect_all_match(fixture$claim_boundary, "coverage")
  structured_re_expect_all_match(fixture$claim_boundary, "q4 REML")
  structured_re_expect_all_match(fixture$claim_boundary, "AI-REML")
  structured_re_expect_all_match(fixture$claim_boundary, "broader q8 support")
  structured_re_expect_all_match(fixture$next_gate, "interval diagnostics")
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "animal"],
    "pedigree/Ainv"
  )
  relmat_boundary <- fixture$claim_boundary[fixture$structured_type == "relmat"]
  structured_re_expect_all_match(relmat_boundary, "K-matrix")
  structured_re_expect_all_match(relmat_boundary, "Q precision")
  expect_false(grepl("K/Q same-target parity", relmat_boundary, fixed = TRUE))

  qseries_ready <- qseries[
    qseries$cell_id %in%
      paste0("qseries_", fixture$structured_type, "_q4_mu1_mu2_one_slope"),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_ready), 4L)
  qseries_ready <- qseries_ready[
    match(
      paste0("qseries_", fixture$structured_type, "_q4_mu1_mu2_one_slope"),
      qseries_ready$cell_id
    ),
    ,
    drop = FALSE
  ]
  expect_equal(qseries_ready$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_ready$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_ready$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_ready$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_ready$interval_status, rep("planned", 4L))
  expect_equal(qseries_ready$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_ready$evidence_url,
    rep(
      "docs/dev-log/dashboard/structured-re-q4-location-slope-parity-fixture.tsv",
      4L
    )
  )
  expect_equal(
    qseries_ready$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "native ML point-fit"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "exact four-member q4 location endpoint map"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "same-target fixture"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "partial location-scale"
  )
  structured_re_expect_all_match(qseries_ready$claim_boundary, "coverage")
  structured_re_expect_all_match(qseries_ready$claim_boundary, "q4 REML")
  structured_re_expect_all_match(qseries_ready$claim_boundary, "AI-REML")
  structured_re_expect_all_match(qseries_ready$claim_boundary, "public support")
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "broader q8 support"
  )
  structured_re_expect_all_match(
    qseries_ready$next_gate,
    "interval diagnostics"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary[qseries_ready$structure_provider == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary[qseries_ready$structure_provider == "animal"],
    "pedigree/Ainv"
  )
  relmat_qseries_boundary <- qseries_ready$claim_boundary[
    qseries_ready$structure_provider == "relmat"
  ]
  structured_re_expect_all_match(relmat_qseries_boundary, "Q precision")
  expect_false(
    grepl("K/Q same-target parity", relmat_qseries_boundary, fixed = TRUE)
  )
})

test_that("q4 location one-slope interval plan remains target-level", {
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-q4-location-slope-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    plan,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "interval_methods",
      "required_fit_evidence",
      "required_interval_evidence",
      "denominator_fields",
      "current_blocker",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(plan), 40L)
  expect_setequal(
    plan$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  for (provider in c("phylo", "spatial", "animal", "relmat")) {
    provider_rows <- plan[plan$structured_type == provider, , drop = FALSE]
    expect_equal(nrow(provider_rows), 10L)
    expect_equal(sum(provider_rows$target_kind == "direct_sd"), 4L)
    expect_equal(sum(provider_rows$target_kind == "derived_correlation"), 6L)
    expect_equal(
      provider_rows$cell_id,
      rep(paste0("qseries_", provider, "_q4_mu1_mu2_one_slope"), 10L)
    )
  }

  expected_members <- c(
    "mu1:(Intercept)",
    "mu1:x",
    "mu2:(Intercept)",
    "mu2:x"
  )
  direct_rows <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
  derived_rows <- plan[
    plan$target_kind == "derived_correlation",
    ,
    drop = FALSE
  ]
  for (provider in c("phylo", "spatial", "animal", "relmat")) {
    provider_direct <- direct_rows[
      direct_rows$structured_type == provider,
      ,
      drop = FALSE
    ]
    expect_setequal(provider_direct$endpoint_member, expected_members)
  }

  expect_setequal(
    direct_rows$estimand,
    c(
      "sd_mu1_intercept",
      "sd_mu1_x",
      "sd_mu2_intercept",
      "sd_mu2_x"
    )
  )
  structured_re_expect_all_match(
    direct_rows$required_fit_evidence,
    "profile_targets_direct_ready"
  )
  structured_re_expect_all_match(
    direct_rows$required_fit_evidence,
    "same_target_fixture_parity"
  )
  structured_re_expect_all_match(
    direct_rows$required_interval_evidence,
    "finite_direct_sd_intervals_by_method"
  )
  expect_equal(
    direct_rows$current_blocker,
    rep("interval_diagnostics_not_run", 16L)
  )

  structured_re_expect_all_match(
    derived_rows$required_fit_evidence,
    "corpairs_point_reconstruction"
  )
  structured_re_expect_all_match(
    derived_rows$required_fit_evidence,
    "derived_interval_reconstruction_planned"
  )
  structured_re_expect_all_match(
    derived_rows$required_interval_evidence,
    "finite_derived_correlation_intervals_by_method"
  )
  expect_equal(
    derived_rows$current_blocker,
    rep("derived_correlation_interval_reconstruction_not_available", 24L)
  )
  structured_re_expect_all_match(
    derived_rows$claim_boundary,
    "derived correlation interval reconstruction is not available"
  )

  structured_re_expect_all_match(plan$interval_methods, "profile")
  structured_re_expect_all_match(plan$interval_methods, "bootstrap")
  structured_re_expect_all_match(plan$required_fit_evidence, "point_fit")
  structured_re_expect_all_match(plan$required_fit_evidence, "extractor_ready")
  structured_re_expect_all_match(
    plan$required_interval_evidence,
    "coverage_mcse<=0.01"
  )
  structured_re_expect_all_match(
    plan$denominator_fields,
    "coverage_denominator"
  )
  structured_re_expect_all_match(plan$denominator_fields, "coverage_mcse")
  expect_equal(plan$status, rep("planned", 40L))
  structured_re_expect_all_match(plan$claim_boundary, "q4 location one-slope")
  structured_re_expect_all_match(plan$claim_boundary, "partial location-scale")
  structured_re_expect_all_match(plan$claim_boundary, "no interval reliability")
  structured_re_expect_all_match(plan$claim_boundary, "interval coverage")
  structured_re_expect_all_match(plan$claim_boundary, "q4 REML")
  structured_re_expect_all_match(plan$claim_boundary, "AI-REML")
  structured_re_expect_all_match(plan$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(plan$claim_boundary, "public support")
  structured_re_expect_all_match(plan$claim_boundary, "broader q8 support")
  structured_re_expect_all_match(plan$next_gate, "before calibrated coverage")
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "animal"],
    "pedigree/Ainv"
  )
  relmat_boundary <- plan$claim_boundary[plan$structured_type == "relmat"]
  structured_re_expect_all_match(relmat_boundary, "Q precision")
  expect_equal(
    grepl("K/Q same-target parity", relmat_boundary, fixed = TRUE),
    rep(FALSE, length(relmat_boundary))
  )

  qseries_plan <- qseries[qseries$cell_id %in% plan$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_plan), 4L)
  expect_equal(qseries_plan$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_plan$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_plan$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_plan$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_plan$interval_status, rep("planned", 4L))
  expect_equal(qseries_plan$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_plan$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q4 location one-slope interval smoke records bounded direct-SD status", {
  status <- structured_re_read_dashboard_tsv(
    "structured-re-q4-location-slope-interval-diagnostic-status.tsv"
  )
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-q4-location-slope-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-location-slope-interval-smoke",
      "structured-re-q4-location-slope-interval-smoke-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    status,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_artifact",
      "observed_target_rows",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_finite_intervals",
      "wald_status",
      "profile_status",
      "bootstrap_status",
      "interval_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(status), 16L)
  expect_setequal(
    status$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  for (provider in c("phylo", "spatial", "animal", "relmat")) {
    provider_status <- status[
      status$structured_type == provider,
      ,
      drop = FALSE
    ]
    expect_equal(nrow(provider_status), 4L)
    expect_setequal(
      provider_status$endpoint_member,
      c("mu1:(Intercept)", "mu1:x", "mu2:(Intercept)", "mu2:x")
    )
    expect_equal(
      provider_status$cell_id,
      rep(paste0("qseries_", provider, "_q4_mu1_mu2_one_slope"), 4L)
    )
  }

  expect_equal(status$target_kind, rep("direct_sd", 16L))
  expect_equal(status$observed_target_rows, rep(1L, 16L))
  expect_equal(status$n_fit_ok, rep(1L, 16L))
  expect_equal(status$n_converged, rep(1L, 16L))
  expect_equal(status$n_pdhess, rep(1L, 16L))
  expect_equal(status$n_finite_intervals, rep(2L, 16L))
  expect_equal(status$wald_status, rep("finite", 16L))
  expect_equal(status$profile_status, rep("finite", 16L))
  expect_equal(status$bootstrap_status, rep("not_run_smoke_budget", 16L))
  expect_equal(
    status$interval_status,
    rep("wald_profile_finite_bootstrap_failed", 16L)
  )
  expect_equal(
    status$failure_class,
    rep("bootstrap_not_run_smoke_budget", 16L)
  )
  expect_equal(status$interval_claim_status, rep("diagnostic_only", 16L))
  expect_equal(status$status, rep("covered", 16L))
  structured_re_expect_all_match(status$claim_boundary, "q4 location one-slope")
  structured_re_expect_all_match(
    status$claim_boundary,
    "direct-SD interval smoke"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "derived-correlation intervals still blocked"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(status$claim_boundary, "interval coverage")
  structured_re_expect_all_match(status$claim_boundary, "q4 REML")
  structured_re_expect_all_match(status$claim_boundary, "AI-REML")
  structured_re_expect_all_match(status$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(status$claim_boundary, "public support")
  structured_re_expect_all_match(
    status$claim_boundary,
    "partial location-scale"
  )
  structured_re_expect_all_match(status$claim_boundary, "broader q8 support")
  structured_re_expect_all_match(status$claim_boundary, "calibrated coverage")
  structured_re_expect_all_match(status$next_gate, "denominator accounting")
  structured_re_expect_all_match(status$next_gate, "coverage-grid design")
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "animal"],
    "pedigree/Ainv"
  )
  relmat_boundary <- status$claim_boundary[status$structured_type == "relmat"]
  structured_re_expect_all_match(relmat_boundary, "Q precision")
  expect_equal(
    grepl("K/Q same-target parity", relmat_boundary, fixed = TRUE),
    rep(FALSE, length(relmat_boundary))
  )

  direct_plan <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
  status_key <- paste(status$structured_type, status$endpoint_member)
  plan_key <- paste(direct_plan$structured_type, direct_plan$endpoint_member)
  status_ordered <- status[order(status_key), , drop = FALSE]
  plan_ordered <- direct_plan[order(plan_key), , drop = FALSE]
  for (field in c(
    "cell_id",
    "formula_cell",
    "target_kind",
    "estimand",
    "profile_target"
  )) {
    expect_equal(status_ordered[[field]], plan_ordered[[field]])
  }

  artifact_path <- paste(
    "docs/dev-log/simulation-artifacts/2026-06-24-q4-location-slope-interval-smoke",
    "structured-re-q4-location-slope-interval-smoke-results.tsv",
    sep = "/"
  )
  expect_equal(status$source_artifact, rep(artifact_path, 16L))
  expect_equal(
    status$evidence_url,
    rep(
      "docs/dev-log/after-task/2026-06-24-q4-location-slope-interval-smoke-status.md",
      16L
    )
  )

  expect_equal(nrow(artifact), 48L)
  expect_equal(artifact$target_kind, rep("direct_sd", 48L))
  expect_equal(artifact$variant, rep("strong", 48L))
  expect_equal(artifact$n_levels, rep(8L, 48L))
  expect_equal(artifact$n_each, rep(24L, 48L))
  expect_equal(artifact$convergence, rep(0L, 48L))
  expect_equal(artifact$pdHess, rep(TRUE, 48L))
  structured_re_expect_all_match(artifact$profile_note, "ready")
  expect_equal(
    artifact$method_status[artifact$interval_method == "wald"],
    rep("finite", 16L)
  )
  expect_equal(
    artifact$method_status[artifact$interval_method == "profile"],
    rep("finite", 16L)
  )
  expect_equal(
    artifact$method_status[artifact$interval_method == "bootstrap"],
    rep("not_run_smoke_budget", 16L)
  )

  qseries_status <- qseries[qseries$cell_id %in% status$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_status$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_status$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q4 location one-slope bootstrap budget probe stays diagnostic-only", {
  probe <- structured_re_read_dashboard_tsv(
    "structured-re-q4-location-slope-bootstrap-budget-probe.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-location-slope-bootstrap-budget-probe",
      "structured-re-q4-location-slope-bootstrap-budget-probe-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    probe,
    c(
      "probe_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_interval_status",
      "source_interval_artifact",
      "source_bootstrap_artifact",
      "bootstrap_replicates",
      "bootstrap_seed",
      "observed_target_rows",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "bootstrap_status",
      "bootstrap_finite",
      "bootstrap_lower",
      "bootstrap_upper",
      "conf_status",
      "method_message",
      "method_warnings",
      "estimate",
      "profile_ready",
      "profile_note",
      "probe_status",
      "denominator_status",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(probe), 4L)
  expect_setequal(
    probe$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(probe$target_kind, rep("direct_sd", 4L))
  expect_equal(probe$endpoint_member, rep("mu1:(Intercept)", 4L))
  expect_equal(probe$estimand, rep("sd_mu1_intercept", 4L))
  expect_equal(probe$bootstrap_replicates, rep(2L, 4L))
  expect_equal(probe$bootstrap_seed, rep(41L, 4L))
  expect_equal(
    probe$denominator_status,
    rep("representative_bootstrap_probe_only", 4L)
  )
  expect_equal(probe$coverage_status, rep("not_evaluated", 4L))
  expect_equal(probe$interval_claim_status, rep("diagnostic_only", 4L))
  expect_equal(probe$status, rep("covered", 4L))
  structured_re_expect_all_match(
    probe$claim_boundary,
    "bootstrap budget probe only"
  )
  structured_re_expect_all_match(
    probe$claim_boundary,
    "no all-target bootstrap denominator"
  )
  structured_re_expect_all_match(
    probe$claim_boundary,
    "no derived-correlation intervals"
  )
  structured_re_expect_all_match(
    probe$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(probe$claim_boundary, "interval coverage")
  structured_re_expect_all_match(probe$claim_boundary, "q4 REML")
  structured_re_expect_all_match(probe$claim_boundary, "AI-REML")
  structured_re_expect_all_match(probe$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(probe$claim_boundary, "public support")
  structured_re_expect_all_match(
    probe$claim_boundary,
    "partial location-scale"
  )
  structured_re_expect_all_match(probe$claim_boundary, "broader q8 support")
  structured_re_expect_all_match(probe$claim_boundary, "calibrated coverage")
  structured_re_expect_all_match(probe$next_gate, "Totoro")
  structured_re_expect_all_match(probe$next_gate, "DRAC")
  structured_re_expect_all_match(probe$next_gate, "coverage-grid design")

  phylo <- probe[probe$structured_type == "phylo", , drop = FALSE]
  skipped <- probe[probe$structured_type != "phylo", , drop = FALSE]
  expect_equal(phylo$observed_target_rows, 1L)
  expect_equal(phylo$n_fit_ok, 1L)
  expect_equal(phylo$n_converged, 1L)
  expect_equal(phylo$n_pdhess, 1L)
  expect_equal(phylo$bootstrap_status, "finite")
  expect_true(isTRUE(phylo$bootstrap_finite))
  expect_true(is.finite(phylo$bootstrap_lower))
  expect_true(is.finite(phylo$bootstrap_upper))
  expect_gt(phylo$bootstrap_upper, phylo$bootstrap_lower)
  expect_equal(phylo$conf_status, "bootstrap")
  expect_match(phylo$method_message, "successful refits", fixed = TRUE)
  expect_true(is.finite(phylo$estimate))
  expect_true(isTRUE(phylo$profile_ready))
  expect_equal(phylo$profile_note, "ready")
  expect_equal(phylo$probe_status, "bootstrap_budget_probe_finite")

  expect_equal(skipped$observed_target_rows, rep(0L, 3L))
  expect_equal(skipped$n_fit_ok, rep(0L, 3L))
  expect_equal(skipped$n_converged, rep(0L, 3L))
  expect_equal(skipped$n_pdhess, rep(0L, 3L))
  expect_equal(
    skipped$bootstrap_status,
    rep("not_run_after_phylo_budget_probe", 3L)
  )
  expect_equal(skipped$bootstrap_finite, rep(FALSE, 3L))
  expect_true(all(is.na(skipped$bootstrap_lower)))
  expect_true(all(is.na(skipped$bootstrap_upper)))
  expect_equal(
    skipped$conf_status,
    rep("not_run_after_phylo_budget_probe", 3L)
  )
  expect_true(all(is.na(skipped$estimate)))
  expect_equal(skipped$profile_ready, rep(FALSE, 3L))
  expect_equal(
    skipped$probe_status,
    rep("bootstrap_budget_probe_not_run_budget", 3L)
  )
  structured_re_expect_all_match(skipped$method_message, "bootstrap omitted")

  source_status <- "docs/dev-log/dashboard/structured-re-q4-location-slope-interval-diagnostic-status.tsv"
  source_interval_artifact <- paste(
    "docs/dev-log/simulation-artifacts/2026-06-24-q4-location-slope-interval-smoke",
    "structured-re-q4-location-slope-interval-smoke-results.tsv",
    sep = "/"
  )
  source_bootstrap_artifact <- paste(
    "docs/dev-log/simulation-artifacts/2026-06-24-q4-location-slope-bootstrap-budget-probe",
    "structured-re-q4-location-slope-bootstrap-budget-probe-results.tsv",
    sep = "/"
  )
  expect_equal(probe$source_interval_status, rep(source_status, 4L))
  expect_equal(
    probe$source_interval_artifact,
    rep(source_interval_artifact, 4L)
  )
  expect_equal(
    probe$source_bootstrap_artifact,
    rep(source_bootstrap_artifact, 4L)
  )
  expect_equal(
    probe$evidence_url,
    rep(
      "docs/dev-log/after-task/2026-06-24-q4-location-slope-bootstrap-budget-probe.md",
      4L
    )
  )

  expect_equal(nrow(artifact), 4L)
  expect_setequal(
    artifact$provider,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(artifact$interval_method, rep("bootstrap", 4L))
  artifact_phylo <- artifact[artifact$provider == "phylo", , drop = FALSE]
  artifact_skipped <- artifact[artifact$provider != "phylo", , drop = FALSE]
  expect_equal(artifact_phylo$method_status, "finite")
  expect_true(isTRUE(artifact_phylo$interval_finite))
  expect_true(is.finite(artifact_phylo$lower))
  expect_true(is.finite(artifact_phylo$upper))
  expect_equal(
    artifact_skipped$method_status,
    rep("not_run_after_phylo_budget_probe", 3L)
  )
  expect_equal(artifact_skipped$interval_finite, rep(FALSE, 3L))
  expect_true(all(is.na(artifact_skipped$lower)))
  expect_true(all(is.na(artifact_skipped$upper)))

  qseries_probe <- qseries[qseries$cell_id %in% probe$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_probe), 4L)
  expect_equal(qseries_probe$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_probe$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_probe$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_probe$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_probe$interval_status, rep("planned", 4L))
  expect_equal(qseries_probe$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_probe$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q4 location one-slope bootstrap dispatch plan stays not submitted", {
  dispatch <- structured_re_read_dashboard_tsv(
    "structured-re-q4-location-slope-bootstrap-dispatch-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-location-slope-bootstrap-dispatch-plan",
      "structured-re-q4-location-slope-bootstrap-dispatch-target-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    dispatch,
    c(
      "dispatch_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_interval_status",
      "source_interval_artifact",
      "source_budget_probe",
      "source_budget_artifact",
      "source_budget_endpoint_member",
      "source_budget_status",
      "target_manifest",
      "planned_runner",
      "planned_backends",
      "planned_shard",
      "provider_rotation_index",
      "target_index",
      "bootstrap_replicates",
      "bootstrap_seed",
      "retention_policy",
      "scheduler_status",
      "compute_status",
      "denominator_status",
      "coverage_evaluable",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(manifest, dispatch)
  expect_equal(nrow(dispatch), 16L)
  expect_equal(dispatch$provider_rotation_index, seq_len(16L))
  expect_equal(dispatch$bootstrap_seed, 4100L + seq_len(16L))
  expect_equal(dispatch$bootstrap_replicates, rep(2L, 16L))
  expect_equal(dispatch$target_index, rep(seq_len(4L), each = 4L))
  expect_setequal(
    dispatch$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(
    unname(as.integer(table(dispatch$structured_type)[
      c("animal", "phylo", "relmat", "spatial")
    ])),
    rep(4L, 4L)
  )
  expect_setequal(
    dispatch$endpoint_member,
    c("mu1:(Intercept)", "mu1:x", "mu2:(Intercept)", "mu2:x")
  )
  expect_equal(
    unname(as.integer(table(dispatch$endpoint_member))),
    rep(4L, 4L)
  )
  expect_equal(dispatch$target_kind, rep("direct_sd", 16L))
  expect_equal(
    dispatch$source_budget_endpoint_member,
    rep("mu1:(Intercept)", 16L)
  )
  expect_equal(
    dispatch$source_budget_status[dispatch$structured_type == "phylo"],
    rep("bootstrap_budget_probe_finite", 4L)
  )
  expect_equal(
    dispatch$source_budget_status[dispatch$structured_type != "phylo"],
    rep("bootstrap_budget_probe_not_run_budget", 12L)
  )
  structured_re_expect_all_match(
    dispatch$planned_runner,
    "planned; not executed"
  )
  expect_equal(
    dispatch$planned_backends,
    rep("totoro_cpu_worker;drac_slurm_array", 16L)
  )
  expect_equal(
    dispatch$scheduler_status,
    rep("dry_run_not_submitted", 16L)
  )
  expect_equal(dispatch$compute_status, rep("not_executed", 16L))
  expect_equal(dispatch$denominator_status, rep("dispatch_plan_only", 16L))
  expect_equal(dispatch$coverage_evaluable, rep(FALSE, 16L))
  expect_equal(dispatch$coverage_status, rep("not_evaluated", 16L))
  expect_equal(dispatch$interval_claim_status, rep("diagnostic_only", 16L))
  expect_equal(dispatch$status, rep("covered", 16L))
  structured_re_expect_all_match(
    dispatch$retention_policy,
    "retain_failed_profiles"
  )
  structured_re_expect_all_match(
    dispatch$retention_policy,
    "record_bootstrap_refit_attempts"
  )
  structured_re_expect_all_match(
    dispatch$retention_policy,
    "retain_scheduler_exit_status"
  )
  structured_re_expect_all_match(
    dispatch$claim_boundary,
    "bootstrap dispatch plan only"
  )
  structured_re_expect_all_match(
    dispatch$claim_boundary,
    "no submitted Totoro job"
  )
  structured_re_expect_all_match(
    dispatch$claim_boundary,
    "no submitted DRAC job"
  )
  structured_re_expect_all_match(
    dispatch$claim_boundary,
    "no all-target bootstrap denominator evidence"
  )
  structured_re_expect_all_match(
    dispatch$claim_boundary,
    "no derived-correlation intervals"
  )
  structured_re_expect_all_match(
    dispatch$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(dispatch$claim_boundary, "interval coverage")
  structured_re_expect_all_match(dispatch$claim_boundary, "q4 REML")
  structured_re_expect_all_match(dispatch$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    dispatch$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(dispatch$claim_boundary, "public support")
  structured_re_expect_all_match(
    dispatch$claim_boundary,
    "partial location-scale"
  )
  structured_re_expect_all_match(dispatch$claim_boundary, "broader q8 support")
  structured_re_expect_all_match(dispatch$claim_boundary, "calibrated coverage")
  structured_re_expect_all_match(dispatch$next_gate, "Totoro")
  structured_re_expect_all_match(dispatch$next_gate, "DRAC")
  structured_re_expect_all_match(dispatch$next_gate, "target outcome")
  structured_re_expect_all_match(dispatch$next_gate, "coverage-grid design")
  expect_false(any(grepl(
    "K/Q same-target parity",
    dispatch$claim_boundary[dispatch$structured_type == "relmat"],
    fixed = TRUE
  )))

  qseries_dispatch <- qseries[
    qseries$cell_id %in% unique(dispatch$cell_id),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_dispatch), 4L)
  expect_equal(qseries_dispatch$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_dispatch$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_dispatch$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_dispatch$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_dispatch$interval_status, rep("planned", 4L))
  expect_equal(qseries_dispatch$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_dispatch$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q4 location one-slope bootstrap runner contract stays dry-run", {
  runner <- structured_re_read_dashboard_tsv(
    "structured-re-q4-location-slope-bootstrap-runner-contract.tsv"
  )
  dispatch <- structured_re_read_dashboard_tsv(
    "structured-re-q4-location-slope-bootstrap-dispatch-plan.tsv"
  )
  manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-location-slope-bootstrap-runner-contract",
      "structured-re-q4-location-slope-bootstrap-runner-target-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  run_log <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-location-slope-bootstrap-runner-contract",
      "structured-re-q4-location-slope-bootstrap-runner-run-log.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    runner,
    c(
      "runner_id",
      "dispatch_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "mode",
      "selected",
      "source_dispatch_manifest",
      "selected_manifest",
      "run_log",
      "bootstrap_replicates",
      "bootstrap_seed",
      "retention_policy",
      "scheduler_status",
      "compute_status",
      "denominator_status",
      "coverage_evaluable",
      "coverage_status",
      "interval_claim_status",
      "execution_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(manifest, runner)
  expect_equal(nrow(runner), 16L)
  expect_equal(nrow(run_log), 1L)
  expect_equal(
    runner$dispatch_id,
    dispatch$dispatch_id
  )
  expect_equal(
    runner$runner_id,
    paste0("q4_location_slope_bootstrap_runner_", dispatch$dispatch_id)
  )
  expect_equal(runner$cell_id, dispatch$cell_id)
  expect_equal(runner$formula_cell, dispatch$formula_cell)
  expect_equal(runner$structured_type, dispatch$structured_type)
  expect_equal(runner$target_kind, dispatch$target_kind)
  expect_equal(runner$endpoint_member, dispatch$endpoint_member)
  expect_equal(runner$estimand, dispatch$estimand)
  expect_equal(runner$profile_target, dispatch$profile_target)
  expect_equal(runner$bootstrap_replicates, dispatch$bootstrap_replicates)
  expect_equal(runner$bootstrap_seed, dispatch$bootstrap_seed)
  expect_equal(runner$retention_policy, dispatch$retention_policy)
  expect_equal(runner$mode, rep("dry-run", 16L))
  expect_equal(runner$selected, rep(TRUE, 16L))
  expect_equal(
    runner$source_dispatch_manifest,
    rep(
      paste(
        "docs/dev-log/dashboard",
        "structured-re-q4-location-slope-bootstrap-dispatch-plan.tsv",
        sep = "/"
      ),
      16L
    )
  )
  expect_equal(
    runner$selected_manifest,
    rep(
      paste(
        "docs/dev-log/simulation-artifacts",
        "2026-06-24-q4-location-slope-bootstrap-runner-contract",
        "structured-re-q4-location-slope-bootstrap-runner-target-manifest.tsv",
        sep = "/"
      ),
      16L
    )
  )
  expect_equal(
    runner$run_log,
    rep(
      paste(
        "docs/dev-log/simulation-artifacts",
        "2026-06-24-q4-location-slope-bootstrap-runner-contract",
        "structured-re-q4-location-slope-bootstrap-runner-run-log.tsv",
        sep = "/"
      ),
      16L
    )
  )
  expect_equal(runner$scheduler_status, rep("dry_run_not_submitted", 16L))
  expect_equal(runner$compute_status, rep("not_executed", 16L))
  expect_equal(runner$denominator_status, rep("runner_contract_only", 16L))
  expect_equal(runner$coverage_evaluable, rep(FALSE, 16L))
  expect_equal(runner$coverage_status, rep("not_evaluated", 16L))
  expect_equal(runner$interval_claim_status, rep("diagnostic_only", 16L))
  expect_equal(runner$execution_status, rep("validated_not_executed", 16L))
  expect_equal(runner$status, rep("covered", 16L))
  structured_re_expect_all_match(
    runner$claim_boundary,
    "runner contract only"
  )
  structured_re_expect_all_match(
    runner$claim_boundary,
    "no bootstrap refits executed"
  )
  structured_re_expect_all_match(
    runner$claim_boundary,
    "no Totoro job submitted"
  )
  structured_re_expect_all_match(
    runner$claim_boundary,
    "no DRAC job submitted"
  )
  structured_re_expect_all_match(
    runner$claim_boundary,
    "no all-target bootstrap denominator evidence"
  )
  structured_re_expect_all_match(
    runner$claim_boundary,
    "no derived-correlation intervals"
  )
  structured_re_expect_all_match(runner$claim_boundary, "q4 REML")
  structured_re_expect_all_match(runner$claim_boundary, "AI-REML")
  structured_re_expect_all_match(runner$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(runner$claim_boundary, "calibrated coverage")
  structured_re_expect_all_match(runner$next_gate, "one provider shard")
  structured_re_expect_all_match(runner$next_gate, "denominator accounting")
  expect_false(any(grepl(
    "coverage_evaluable = TRUE",
    runner$claim_boundary,
    fixed = TRUE
  )))

  expect_equal(run_log$selected_targets, 16L)
  expect_equal(run_log$mode, "dry-run")
  expect_equal(run_log$shard_id, "all-targets")
  expect_equal(run_log$provider_filter, "all")
  expect_equal(run_log$endpoint_member_filter, "all")
  expect_equal(run_log$execution_status, "validated_not_executed")
  expect_equal(run_log$scheduler_status, "dry_run_not_submitted")
  expect_equal(run_log$compute_status, "not_executed")
  expect_equal(run_log$denominator_status, "runner_contract_only")
  expect_equal(run_log$coverage_evaluable, FALSE)
  expect_equal(run_log$coverage_status, "not_evaluated")
  expect_equal(run_log$interval_claim_status, "diagnostic_only")
  expect_equal(run_log$status, "covered")

  for (provider in c("phylo", "spatial", "animal", "relmat")) {
    shard_id <- paste0("provider-", provider)
    shard_manifest <- utils::read.delim(
      structured_re_artifact_path(
        "docs",
        "dev-log",
        "simulation-artifacts",
        "2026-06-24-q4-location-slope-bootstrap-runner-contract",
        paste0(
          "structured-re-q4-location-slope-bootstrap-runner-target-manifest-",
          shard_id,
          ".tsv"
        )
      ),
      sep = "\t",
      quote = "",
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
    shard_log <- utils::read.delim(
      structured_re_artifact_path(
        "docs",
        "dev-log",
        "simulation-artifacts",
        "2026-06-24-q4-location-slope-bootstrap-runner-contract",
        paste0(
          "structured-re-q4-location-slope-bootstrap-runner-run-log-",
          shard_id,
          ".tsv"
        )
      ),
      sep = "\t",
      quote = "",
      check.names = FALSE,
      stringsAsFactors = FALSE
    )

    expect_equal(nrow(shard_manifest), 4L)
    expect_equal(nrow(shard_log), 1L)
    expect_equal(shard_manifest$structured_type, rep(provider, 4L))
    expect_setequal(shard_manifest$endpoint_member, dispatch$endpoint_member)
    expect_equal(shard_manifest$mode, rep("dry-run", 4L))
    expect_equal(
      shard_manifest$selected_manifest,
      rep(
        paste(
          "docs/dev-log/simulation-artifacts",
          "2026-06-24-q4-location-slope-bootstrap-runner-contract",
          paste0(
            "structured-re-q4-location-slope-bootstrap-runner-target-manifest-",
            shard_id,
            ".tsv"
          ),
          sep = "/"
        ),
        4L
      )
    )
    expect_equal(
      shard_manifest$run_log,
      rep(
        paste(
          "docs/dev-log/simulation-artifacts",
          "2026-06-24-q4-location-slope-bootstrap-runner-contract",
          paste0(
            "structured-re-q4-location-slope-bootstrap-runner-run-log-",
            shard_id,
            ".tsv"
          ),
          sep = "/"
        ),
        4L
      )
    )
    expect_false(any(
      shard_manifest$selected_manifest %in% runner$selected_manifest
    ))
    expect_false(any(shard_manifest$run_log %in% runner$run_log))
    expect_equal(shard_log$selected_targets, 4L)
    expect_equal(shard_log$shard_id, shard_id)
    expect_equal(shard_log$provider_filter, provider)
    expect_equal(shard_log$endpoint_member_filter, "all")
    expect_equal(shard_log$execution_status, "validated_not_executed")
    expect_equal(shard_log$compute_status, "not_executed")
    expect_equal(shard_log$denominator_status, "runner_contract_only")
    expect_equal(shard_log$coverage_evaluable, FALSE)
    expect_equal(shard_log$coverage_status, "not_evaluated")
  }
})

test_that("q4 all-four one-slope parity fixture records exact bridge fixture only", {
  fixture <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-parity-fixture.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    fixture,
    c(
      "fixture_id",
      "formula_cell",
      "structured_type",
      "dimension",
      "endpoint",
      "slope_class",
      "estimator",
      "native_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "coefficient_order",
      "matrix_slot",
      "input_scale",
      "parity_status",
      "bridge_status",
      "interval_status",
      "coverage_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(fixture), 4L)
  expect_setequal(
    fixture$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(fixture$dimension, rep("q8", 4L))
  expect_equal(fixture$endpoint, rep("mu1+mu2+sigma1+sigma2", 4L))
  expect_equal(fixture$slope_class, rep("labelled_slope_covariance", 4L))
  expect_equal(fixture$estimator, rep("ML", 4L))
  expect_equal(fixture$native_status, rep("fixture_available", 4L))
  expect_equal(fixture$direct_drmjl_status, rep("fixture_available", 4L))
  expect_equal(fixture$r_via_julia_status, rep("fixture_available", 4L))
  expect_equal(fixture$bridge_status, rep("fixture_parity", 4L))
  expect_equal(fixture$interval_status, rep("planned", 4L))
  expect_equal(fixture$coverage_status, rep("planned", 4L))

  expected_endpoint_members <- c(
    "mu1:(Intercept)",
    "mu1:x",
    "mu2:(Intercept)",
    "mu2:x",
    "sigma1:(Intercept)",
    "sigma1:x",
    "sigma2:(Intercept)",
    "sigma2:x"
  )
  coefficient_terms <- strsplit(
    fixture$coefficient_order[[1L]],
    ";",
    fixed = TRUE
  )[[1L]]
  expect_length(coefficient_terms, 44L)
  expect_equal(coefficient_terms[seq_len(8L)], expected_endpoint_members)
  expect_equal(sum(grepl("^sd_", coefficient_terms)), 8L)
  expect_equal(sum(grepl("^cor_", coefficient_terms)), 28L)
  expect_equal(
    fixture$coefficient_order,
    rep(fixture$coefficient_order[[1L]], 4L)
  )
  expect_equal(fixture$matrix_slot, c("tree", "coords", "A", "K"))
  expect_equal(
    fixture$input_scale,
    c(
      "ultrametric_tree_branch_lengths",
      "coordinates_to_fixed_covariance_K",
      "additive_covariance",
      "user_covariance"
    )
  )
  structured_re_expect_all_match(
    fixture$claim_boundary,
    "q4 all-four one-slope"
  )
  structured_re_expect_all_match(fixture$claim_boundary, "eight-member q8")
  structured_re_expect_all_match(fixture$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(fixture$claim_boundary, "interval reliability")
  structured_re_expect_all_match(fixture$claim_boundary, "coverage")
  structured_re_expect_all_match(fixture$claim_boundary, "q4 REML")
  structured_re_expect_all_match(fixture$claim_boundary, "AI-REML")
  structured_re_expect_all_match(fixture$next_gate, "interval diagnostics")
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "relmat"],
    "K/Q same-target parity"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "relmat"],
    "Q bridge"
  )

  qseries_ready <- qseries[
    qseries$cell_id %in%
      paste0(
        "qseries_",
        fixture$structured_type,
        "_q4_all_four_one_slope_planned"
      ),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_ready), 4L)
  qseries_ready <- qseries_ready[
    match(
      paste0(
        "qseries_",
        fixture$structured_type,
        "_q4_all_four_one_slope_planned"
      ),
      qseries_ready$cell_id
    ),
    ,
    drop = FALSE
  ]
  expect_equal(qseries_ready$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_ready$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_ready$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_ready$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_ready$interval_status, rep("planned", 4L))
  expect_equal(qseries_ready$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_ready$evidence_url,
    rep(
      "docs/dev-log/dashboard/structured-re-q4-slope-parity-fixture.tsv",
      4L
    )
  )
  expect_equal(
    qseries_ready$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "native ML point-fit"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "exact eight-member endpoint map"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "same-target fixture"
  )
  structured_re_expect_all_match(
    qseries_ready$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(qseries_ready$claim_boundary, "q4 REML")
  structured_re_expect_all_match(qseries_ready$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    qseries_ready$next_gate,
    "interval diagnostics"
  )
})

test_that("q4 all-four intercept parity fixture records provider bridge fixture", {
  fixture <- structured_re_read_dashboard_tsv(
    "structured-re-q4-intercept-parity-fixture.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    fixture,
    c(
      "fixture_id",
      "formula_cell",
      "structured_type",
      "dimension",
      "endpoint",
      "slope_class",
      "estimator",
      "native_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "coefficient_order",
      "matrix_slot",
      "input_scale",
      "parity_status",
      "bridge_status",
      "interval_status",
      "coverage_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(fixture), 4L)
  expect_setequal(
    fixture$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(fixture$dimension, rep("q4", 4L))
  expect_equal(fixture$endpoint, rep("mu1+mu2+sigma1+sigma2", 4L))
  expect_equal(fixture$slope_class, rep("intercept_only", 4L))
  expect_equal(fixture$estimator, rep("ML", 4L))
  expect_equal(fixture$native_status, rep("fixture_available", 4L))
  expect_equal(fixture$direct_drmjl_status, rep("fixture_available", 4L))
  expect_equal(fixture$r_via_julia_status, rep("fixture_available", 4L))
  expect_equal(fixture$bridge_status, rep("fixture_parity", 4L))
  expect_equal(fixture$interval_status, rep("planned", 4L))
  expect_equal(fixture$coverage_status, rep("planned", 4L))

  expected_endpoint_members <- c(
    "mu1:(Intercept)",
    "mu2:(Intercept)",
    "sigma1:(Intercept)",
    "sigma2:(Intercept)"
  )
  coefficient_terms <- strsplit(
    fixture$coefficient_order[[1L]],
    ";",
    fixed = TRUE
  )[[1L]]
  expect_length(coefficient_terms, 14L)
  expect_equal(coefficient_terms[seq_len(4L)], expected_endpoint_members)
  expect_equal(sum(grepl("^sd_", coefficient_terms)), 4L)
  expect_equal(sum(grepl("^cor_", coefficient_terms)), 6L)
  expect_equal(
    fixture$coefficient_order,
    rep(fixture$coefficient_order[[1L]], 4L)
  )
  expect_equal(fixture$matrix_slot, c("tree", "coords", "A", "K"))
  expect_equal(
    fixture$input_scale,
    c(
      "ultrametric_tree_branch_lengths",
      "coordinates_to_fixed_covariance_K",
      "additive_covariance",
      "user_covariance"
    )
  )
  structured_re_expect_all_match(
    fixture$claim_boundary,
    "q4 all-four intercept"
  )
  structured_re_expect_all_match(fixture$claim_boundary, "four-endpoint q4")
  structured_re_expect_all_match(fixture$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(fixture$claim_boundary, "interval reliability")
  structured_re_expect_all_match(fixture$claim_boundary, "interval coverage")
  structured_re_expect_all_match(fixture$claim_boundary, "q4 REML")
  structured_re_expect_all_match(fixture$claim_boundary, "native-TMB q4 REML")
  structured_re_expect_all_match(fixture$claim_boundary, "q4 AI-REML")
  structured_re_expect_all_match(fixture$next_gate, "interval diagnostics")
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "relmat"],
    "Q bridge"
  )

  provider_rows <- qseries[
    qseries$cell_id %in%
      paste0(
        "qseries_",
        c("spatial", "animal", "relmat"),
        "_q4_all_four_intercept"
      ),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(provider_rows), 3L)
  provider_rows <- provider_rows[
    match(
      paste0(
        "qseries_",
        c("spatial", "animal", "relmat"),
        "_q4_all_four_intercept"
      ),
      provider_rows$cell_id
    ),
    ,
    drop = FALSE
  ]
  expect_equal(
    provider_rows$route,
    rep("native_direct_bridge_fixture", 3L)
  )
  expect_equal(provider_rows$fit_status, rep("point_fit", 3L))
  expect_equal(provider_rows$extractor_status, rep("extractor_ready", 3L))
  expect_equal(provider_rows$bridge_status, rep("fixture_parity", 3L))
  expect_equal(provider_rows$interval_status, rep("planned", 3L))
  expect_equal(provider_rows$coverage_status, rep("planned", 3L))
  expect_equal(
    provider_rows$evidence_url,
    rep(
      "docs/dev-log/dashboard/structured-re-q4-intercept-parity-fixture.tsv",
      3L
    )
  )
  expect_equal(
    provider_rows$denominator_policy,
    rep("fixture_not_coverage", 3L)
  )
  structured_re_expect_all_match(
    provider_rows$claim_boundary,
    "native ML point-fit"
  )
  structured_re_expect_all_match(
    provider_rows$claim_boundary,
    "exact four-endpoint q4 map"
  )
  structured_re_expect_all_match(
    provider_rows$claim_boundary,
    "same-target fixture"
  )
  structured_re_expect_all_match(
    provider_rows$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(provider_rows$claim_boundary, "q4 REML")
  structured_re_expect_all_match(provider_rows$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    provider_rows$next_gate,
    "structured-re-q4-intercept-hessian-bootstrap-diagnostic.tsv"
  )
  structured_re_expect_all_match(
    provider_rows$next_gate,
    "denominator accounting"
  )
})

test_that("q4 all-four one-slope interval plan remains target-level", {
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    plan,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "interval_methods",
      "required_fit_evidence",
      "required_interval_evidence",
      "denominator_fields",
      "current_blocker",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(plan), 144L)
  expect_setequal(
    plan$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  for (provider in c("phylo", "spatial", "animal", "relmat")) {
    provider_rows <- plan[plan$structured_type == provider, , drop = FALSE]
    expect_equal(nrow(provider_rows), 36L)
    expect_equal(sum(provider_rows$target_kind == "direct_sd"), 8L)
    expect_equal(sum(provider_rows$target_kind == "derived_correlation"), 28L)
    expect_equal(
      provider_rows$cell_id,
      rep(paste0("qseries_", provider, "_q4_all_four_one_slope_planned"), 36L)
    )
  }

  expected_members <- c(
    "mu1:(Intercept)",
    "mu1:x",
    "mu2:(Intercept)",
    "mu2:x",
    "sigma1:(Intercept)",
    "sigma1:x",
    "sigma2:(Intercept)",
    "sigma2:x"
  )
  direct_rows <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
  derived_rows <- plan[
    plan$target_kind == "derived_correlation",
    ,
    drop = FALSE
  ]
  for (provider in c("phylo", "spatial", "animal", "relmat")) {
    provider_direct <- direct_rows[
      direct_rows$structured_type == provider,
      ,
      drop = FALSE
    ]
    expect_setequal(provider_direct$endpoint_member, expected_members)
  }

  expect_setequal(
    direct_rows$estimand,
    c(
      "sd_mu1_intercept",
      "sd_mu1_x",
      "sd_mu2_intercept",
      "sd_mu2_x",
      "sd_sigma1_intercept",
      "sd_sigma1_x",
      "sd_sigma2_intercept",
      "sd_sigma2_x"
    )
  )
  structured_re_expect_all_match(
    direct_rows$required_fit_evidence,
    "profile_targets_direct_ready"
  )
  structured_re_expect_all_match(
    direct_rows$required_fit_evidence,
    "same_target_fixture_parity"
  )
  structured_re_expect_all_match(
    direct_rows$required_interval_evidence,
    "finite_direct_sd_intervals_by_method"
  )
  expect_equal(
    direct_rows$current_blocker,
    rep("interval_diagnostics_not_run", 32L)
  )

  structured_re_expect_all_match(
    derived_rows$required_fit_evidence,
    "corpairs_point_reconstruction"
  )
  structured_re_expect_all_match(
    derived_rows$required_fit_evidence,
    "derived_interval_reconstruction_planned"
  )
  structured_re_expect_all_match(
    derived_rows$required_interval_evidence,
    "finite_derived_correlation_intervals_by_method"
  )
  expect_equal(
    derived_rows$current_blocker,
    rep("derived_correlation_interval_reconstruction_not_available", 112L)
  )
  structured_re_expect_all_match(
    derived_rows$claim_boundary,
    "derived correlation interval reconstruction is not available"
  )

  structured_re_expect_all_match(plan$interval_methods, "profile")
  structured_re_expect_all_match(plan$interval_methods, "bootstrap")
  structured_re_expect_all_match(plan$required_fit_evidence, "point_fit")
  structured_re_expect_all_match(plan$required_fit_evidence, "extractor_ready")
  structured_re_expect_all_match(
    plan$required_interval_evidence,
    "coverage_mcse<=0.01"
  )
  structured_re_expect_all_match(
    plan$denominator_fields,
    "coverage_denominator"
  )
  structured_re_expect_all_match(plan$denominator_fields, "coverage_mcse")
  expect_equal(plan$status, rep("planned", 144L))
  structured_re_expect_all_match(plan$claim_boundary, "q4 all-four one-slope")
  structured_re_expect_all_match(plan$claim_boundary, "no interval reliability")
  structured_re_expect_all_match(plan$claim_boundary, "interval coverage")
  structured_re_expect_all_match(plan$claim_boundary, "q4 REML")
  structured_re_expect_all_match(plan$claim_boundary, "AI-REML")
  structured_re_expect_all_match(plan$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(plan$next_gate, "before calibrated coverage")
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "relmat"],
    "Q bridge"
  )

  qseries_plan <- qseries[qseries$cell_id %in% plan$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_plan), 4L)
  expect_equal(qseries_plan$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_plan$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_plan$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_plan$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_plan$interval_status, rep("planned", 4L))
  expect_equal(qseries_plan$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_plan$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q4 all-four intercept interval plan remains target-level", {
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-q4-intercept-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    plan,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "interval_methods",
      "required_fit_evidence",
      "required_interval_evidence",
      "denominator_fields",
      "current_blocker",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(plan), 40L)
  expect_setequal(
    plan$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  for (provider in c("phylo", "spatial", "animal", "relmat")) {
    provider_rows <- plan[plan$structured_type == provider, , drop = FALSE]
    expect_equal(nrow(provider_rows), 10L)
    expect_equal(sum(provider_rows$target_kind == "direct_sd"), 4L)
    expect_equal(sum(provider_rows$target_kind == "derived_correlation"), 6L)
    expect_equal(
      provider_rows$cell_id,
      rep(paste0("qseries_", provider, "_q4_all_four_intercept"), 10L)
    )
  }

  direct_rows <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
  derived_rows <- plan[
    plan$target_kind == "derived_correlation",
    ,
    drop = FALSE
  ]
  expect_setequal(
    direct_rows$endpoint_member,
    paste0(c("mu1", "mu2", "sigma1", "sigma2"), ":(Intercept)")
  )
  expect_setequal(
    direct_rows$estimand,
    c(
      "sd_mu1_intercept",
      "sd_mu2_intercept",
      "sd_sigma1_intercept",
      "sd_sigma2_intercept"
    )
  )
  expect_setequal(
    derived_rows$estimand,
    c(
      "cor_mu1_mu2",
      "cor_mu1_sigma1",
      "cor_mu1_sigma2",
      "cor_mu2_sigma1",
      "cor_mu2_sigma2",
      "cor_sigma1_sigma2"
    )
  )

  structured_re_expect_all_match(
    direct_rows$required_fit_evidence,
    "profile_targets_direct_ready"
  )
  structured_re_expect_all_match(
    direct_rows$required_interval_evidence,
    "finite_direct_sd_intervals_by_method"
  )
  expect_equal(
    direct_rows$current_blocker,
    rep("interval_diagnostics_not_run", 16L)
  )
  structured_re_expect_all_match(
    derived_rows$required_fit_evidence,
    "corpairs_point_reconstruction"
  )
  structured_re_expect_all_match(
    derived_rows$required_fit_evidence,
    "derived_interval_reconstruction_planned"
  )
  structured_re_expect_all_match(
    derived_rows$required_interval_evidence,
    "finite_derived_correlation_intervals_by_method"
  )
  expect_equal(
    derived_rows$current_blocker,
    rep("derived_correlation_interval_reconstruction_not_available", 24L)
  )

  structured_re_expect_all_match(plan$interval_methods, "profile")
  structured_re_expect_all_match(plan$interval_methods, "bootstrap")
  structured_re_expect_all_match(plan$required_fit_evidence, "point_fit")
  structured_re_expect_all_match(plan$required_fit_evidence, "extractor_ready")
  structured_re_expect_all_match(
    plan$required_interval_evidence,
    "coverage_mcse<=0.01"
  )
  structured_re_expect_all_match(
    plan$denominator_fields,
    "coverage_denominator"
  )
  structured_re_expect_all_match(plan$denominator_fields, "coverage_mcse")
  expect_equal(plan$status, rep("planned", 40L))
  structured_re_expect_all_match(plan$claim_boundary, "q4 all-four intercept")
  structured_re_expect_all_match(plan$claim_boundary, "no interval reliability")
  structured_re_expect_all_match(plan$claim_boundary, "interval coverage")
  structured_re_expect_all_match(plan$claim_boundary, "native-TMB q4 REML")
  structured_re_expect_all_match(plan$claim_boundary, "HSquared AI-REML")
  structured_re_expect_all_match(plan$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(
    plan$claim_boundary,
    "calibrated coverage wording"
  )
  structured_re_expect_all_match(
    derived_rows$claim_boundary,
    "derived correlation interval reconstruction is not available"
  )
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "relmat"],
    "Q bridge"
  )

  qseries_plan <- qseries[qseries$cell_id %in% plan$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_plan), 4L)
  expect_equal(qseries_plan$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_plan$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_plan$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_plan$interval_status, rep("planned", 4L))
  expect_equal(qseries_plan$coverage_status, rep("planned", 4L))
})

test_that("q4 all-four intercept interval status stays diagnostic-only", {
  status <- structured_re_read_dashboard_tsv(
    "structured-re-q4-intercept-interval-diagnostic-status.tsv"
  )
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-q4-intercept-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-25-q4-intercept-interval-smoke",
      "structured-re-q4-intercept-interval-smoke-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    status,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_artifact",
      "observed_target_rows",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_finite_intervals",
      "wald_status",
      "profile_status",
      "bootstrap_status",
      "interval_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(status), 16L)
  expect_equal(nrow(artifact), 48L)
  expect_setequal(
    status$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(status$target_kind, rep("direct_sd", 16L))
  expect_equal(status$observed_target_rows, rep(1L, 16L))
  expect_equal(status$n_fit_ok, rep(1L, 16L))
  expect_equal(status$n_converged, rep(1L, 16L))
  expect_equal(status$interval_claim_status, rep("diagnostic_only", 16L))
  expect_equal(status$status, rep("covered", 16L))
  expect_setequal(
    status$endpoint_member,
    paste0(c("mu1", "mu2", "sigma1", "sigma2"), ":(Intercept)")
  )

  direct_plan <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
  plan_key <- paste(direct_plan$structured_type, direct_plan$endpoint_member)
  status_key <- paste(status$structured_type, status$endpoint_member)
  expect_setequal(status_key, plan_key)
  for (key in status_key) {
    status_row <- status[status_key == key, , drop = FALSE]
    plan_row <- direct_plan[plan_key == key, , drop = FALSE]
    expect_equal(nrow(status_row), 1L)
    expect_equal(nrow(plan_row), 1L)
    for (field in c(
      "cell_id",
      "formula_cell",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target"
    )) {
      expect_equal(status_row[[field]], plan_row[[field]])
    }
    artifact_rows <- artifact[
      artifact$provider == status_row$structured_type &
        artifact$endpoint_member == status_row$endpoint_member,
      ,
      drop = FALSE
    ]
    expect_equal(nrow(artifact_rows), 3L)
    expect_setequal(
      artifact_rows$interval_method,
      c("wald", "profile", "bootstrap")
    )
    expect_equal(artifact_rows$profile_ready, rep(TRUE, 3L))
  }

  blocked <- status[status$structured_type != "animal", , drop = FALSE]
  expect_equal(blocked$n_pdhess, rep(0L, 12L))
  expect_equal(blocked$n_finite_intervals, rep(0L, 12L))
  expect_equal(
    blocked$wald_status,
    rep("not_run_pdhess_false", 12L)
  )
  expect_equal(
    blocked$profile_status,
    rep("not_run_pdhess_false", 12L)
  )
  expect_equal(
    blocked$bootstrap_status,
    rep("not_run_pdhess_false", 12L)
  )
  expect_equal(blocked$interval_status, rep("no_finite_intervals", 12L))
  expect_equal(blocked$failure_class, rep("fit_pdhess_false", 12L))

  animal <- status[status$structured_type == "animal", , drop = FALSE]
  expect_equal(animal$n_pdhess, rep(1L, 4L))
  expect_equal(animal$n_finite_intervals, rep(2L, 4L))
  expect_equal(animal$wald_status, rep("finite", 4L))
  expect_equal(animal$profile_status, rep("finite", 4L))
  expect_equal(animal$bootstrap_status, rep("nonfinite", 4L))
  expect_equal(
    animal$interval_status,
    rep("wald_profile_finite_bootstrap_failed", 4L)
  )
  expect_equal(
    animal$failure_class,
    rep("bootstrap_failed_or_nonfinite", 4L)
  )

  structured_re_expect_all_match(
    status$claim_boundary,
    "q4 all-four intercept"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "direct-SD interval smoke only"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "derived-correlation intervals still blocked"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(status$claim_boundary, "interval coverage")
  structured_re_expect_all_match(status$claim_boundary, "native-TMB q4 REML")
  structured_re_expect_all_match(status$claim_boundary, "HSquared AI-REML")
  structured_re_expect_all_match(status$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(status$claim_boundary, "public support")
  structured_re_expect_all_match(
    status$claim_boundary,
    "calibrated coverage wording"
  )
  structured_re_expect_all_match(status$next_gate, "denominator accounting")
  structured_re_expect_all_match(status$next_gate, "coverage-grid design")
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "relmat"],
    "Q bridge"
  )

  qseries_status <- qseries[
    qseries$cell_id %in% status$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_status$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
})

test_that("q4 all-four intercept denominator precheck blocks admission", {
  precheck <- structured_re_read_dashboard_tsv(
    "structured-re-q4-intercept-denominator-precheck.tsv"
  )
  status <- structured_re_read_dashboard_tsv(
    "structured-re-q4-intercept-interval-diagnostic-status.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    precheck,
    c(
      "denominator_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_interval_status",
      "source_interval_artifact",
      "smoke_interval_status",
      "smoke_n_finite_intervals",
      "smoke_wald_status",
      "smoke_profile_status",
      "smoke_bootstrap_status",
      "smoke_n_fit_ok",
      "smoke_n_converged",
      "smoke_n_pdhess",
      "precheck_diagnosis",
      "denominator_admission",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(precheck), 16L)
  expect_setequal(
    precheck$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(precheck$target_kind, rep("direct_sd", 16L))
  expect_equal(precheck$coverage_status, rep("not_evaluated", 16L))
  expect_equal(precheck$interval_claim_status, rep("diagnostic_only", 16L))
  expect_equal(precheck$status, rep("covered", 16L))

  precheck_key <- paste(precheck$structured_type, precheck$endpoint_member)
  status_key <- paste(status$structured_type, status$endpoint_member)
  expect_setequal(precheck_key, status_key)
  for (key in precheck_key) {
    precheck_row <- precheck[precheck_key == key, , drop = FALSE]
    status_row <- status[status_key == key, , drop = FALSE]
    expect_equal(nrow(precheck_row), 1L)
    expect_equal(nrow(status_row), 1L)
    for (field in c(
      "cell_id",
      "formula_cell",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target"
    )) {
      expect_equal(precheck_row[[field]], status_row[[field]])
    }
    expect_equal(
      precheck_row$source_interval_status,
      "docs/dev-log/dashboard/structured-re-q4-intercept-interval-diagnostic-status.tsv"
    )
    expect_equal(
      precheck_row$source_interval_artifact,
      status_row$source_artifact
    )
    expect_equal(
      precheck_row$smoke_interval_status,
      status_row$interval_status
    )
    expect_equal(
      precheck_row$smoke_n_finite_intervals,
      status_row$n_finite_intervals
    )
    expect_equal(precheck_row$smoke_wald_status, status_row$wald_status)
    expect_equal(precheck_row$smoke_profile_status, status_row$profile_status)
    expect_equal(
      precheck_row$smoke_bootstrap_status,
      status_row$bootstrap_status
    )
    expect_equal(precheck_row$smoke_n_fit_ok, status_row$n_fit_ok)
    expect_equal(precheck_row$smoke_n_converged, status_row$n_converged)
    expect_equal(precheck_row$smoke_n_pdhess, status_row$n_pdhess)
  }

  hessian_blocked <- precheck[
    precheck$structured_type %in% c("phylo", "spatial", "relmat"),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(hessian_blocked), 12L)
  expect_equal(hessian_blocked$precheck_diagnosis, rep("pdhess_blocker", 12L))
  expect_equal(
    hessian_blocked$denominator_admission,
    rep("not_admitted_pdhess_false", 12L)
  )
  expect_equal(hessian_blocked$smoke_n_pdhess, rep(0L, 12L))
  expect_equal(hessian_blocked$smoke_n_finite_intervals, rep(0L, 12L))

  animal <- precheck[precheck$structured_type == "animal", , drop = FALSE]
  expect_equal(nrow(animal), 4L)
  expect_equal(animal$precheck_diagnosis, rep("bootstrap_blocker", 4L))
  expect_equal(
    animal$denominator_admission,
    rep("not_admitted_bootstrap_nonfinite", 4L)
  )
  expect_equal(animal$smoke_n_pdhess, rep(1L, 4L))
  expect_equal(animal$smoke_n_finite_intervals, rep(2L, 4L))
  expect_equal(animal$smoke_wald_status, rep("finite", 4L))
  expect_equal(animal$smoke_profile_status, rep("finite", 4L))
  expect_equal(animal$smoke_bootstrap_status, rep("nonfinite", 4L))

  structured_re_expect_all_match(
    precheck$claim_boundary,
    "direct-SD denominator precheck only"
  )
  structured_re_expect_all_match(
    precheck$claim_boundary,
    "derived-correlation intervals still blocked"
  )
  structured_re_expect_all_match(
    precheck$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(precheck$claim_boundary, "interval coverage")
  structured_re_expect_all_match(precheck$claim_boundary, "native-TMB q4 REML")
  structured_re_expect_all_match(precheck$claim_boundary, "HSquared AI-REML")
  structured_re_expect_all_match(
    precheck$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(
    precheck$claim_boundary,
    "denominator admission"
  )
  structured_re_expect_all_match(
    precheck$claim_boundary,
    "DRAC/Totoro execution"
  )
  structured_re_expect_all_match(precheck$next_gate, "denominator accounting")
  structured_re_expect_all_match(precheck$next_gate, "coverage-grid design")

  qseries_status <- qseries[
    qseries$cell_id %in% precheck$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q4 all-four intercept Hessian/bootstrap diagnostic stays blocked", {
  diagnostic <- structured_re_read_dashboard_tsv(
    "structured-re-q4-intercept-hessian-bootstrap-diagnostic.tsv"
  )
  precheck <- structured_re_read_dashboard_tsv(
    "structured-re-q4-intercept-denominator-precheck.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    diagnostic,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "source_denominator_precheck",
      "source_interval_status",
      "source_interval_artifact",
      "source_artifact",
      "n_levels",
      "n_each",
      "intended_sd_mu1_intercept",
      "intended_sd_mu2_intercept",
      "intended_sd_sigma1_intercept",
      "intended_sd_sigma2_intercept",
      "fit_convergence",
      "n_pdhess",
      "logLik",
      "max_abs_gradient_fixed",
      "optimizer_attempt_count",
      "optimizer_selected",
      "optimizer_selected_preset",
      "optimizer_selected_status",
      "fallback_selected",
      "optimizer_attempt_presets",
      "optimizer_attempt_statuses",
      "cov_fixed_status",
      "cov_fixed_dim",
      "cov_fixed_finite_count",
      "cov_fixed_total",
      "min_cov_fixed_eigenvalue",
      "max_cov_fixed_eigenvalue",
      "n_cov_fixed_nonpositive_eigenvalues",
      "raw_hessian_status",
      "raw_hessian_message",
      "direct_sd_target_count",
      "n_profile_ready_direct_sd",
      "min_direct_sd_estimate",
      "max_direct_sd_estimate",
      "max_abs_derived_correlation",
      "n_abs_derived_correlation_gt_0_95",
      "n_derived_correlation_zero",
      "n_precheck_targets",
      "n_precheck_not_admitted_pdhess_false",
      "n_precheck_not_admitted_bootstrap_nonfinite",
      "smoke_interval_statuses",
      "smoke_wald_statuses",
      "smoke_profile_statuses",
      "smoke_bootstrap_statuses",
      "smoke_failure_classes",
      "n_smoke_bootstrap_nonfinite",
      "precheck_diagnosis",
      "denominator_admission",
      "diagnostic_status",
      "coverage_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(diagnostic), 4L)
  expect_setequal(
    diagnostic$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(diagnostic$n_levels, rep(8L, 4L))
  expect_equal(diagnostic$n_each, rep(18L, 4L))
  expect_equal(diagnostic$direct_sd_target_count, rep(4L, 4L))
  expect_equal(diagnostic$n_profile_ready_direct_sd, rep(4L, 4L))
  expect_equal(diagnostic$n_precheck_targets, rep(4L, 4L))
  expect_equal(
    diagnostic$source_denominator_precheck,
    rep(
      "docs/dev-log/dashboard/structured-re-q4-intercept-denominator-precheck.tsv",
      4L
    )
  )
  expect_equal(
    diagnostic$source_interval_status,
    rep(
      "docs/dev-log/dashboard/structured-re-q4-intercept-interval-diagnostic-status.tsv",
      4L
    )
  )
  expect_equal(
    diagnostic$source_interval_artifact,
    rep(
      paste0(
        "docs/dev-log/simulation-artifacts/",
        "2026-06-25-q4-intercept-interval-smoke/",
        "structured-re-q4-intercept-interval-smoke-results.tsv"
      ),
      4L
    )
  )
  expect_equal(diagnostic$coverage_status, rep("not_evaluated", 4L))
  expect_equal(diagnostic$interval_claim_status, rep("diagnostic_only", 4L))
  expect_equal(diagnostic$status, rep("covered", 4L))
  expect_equal(
    diagnostic$raw_hessian_status,
    rep("unavailable_random_effects", 4L)
  )
  structured_re_expect_all_match(
    diagnostic$raw_hessian_message,
    "Hessian not yet implemented"
  )

  precheck_by_provider <- split(precheck, precheck$structured_type)
  for (provider in diagnostic$structured_type) {
    row <- diagnostic[diagnostic$structured_type == provider, , drop = FALSE]
    provider_precheck <- precheck_by_provider[[provider]]
    expect_equal(row$formula_cell, provider_precheck$formula_cell[[1L]])
    expect_equal(
      row$n_precheck_not_admitted_pdhess_false,
      sum(
        provider_precheck$denominator_admission == "not_admitted_pdhess_false"
      )
    )
    expect_equal(
      row$n_precheck_not_admitted_bootstrap_nonfinite,
      sum(
        provider_precheck$denominator_admission ==
          "not_admitted_bootstrap_nonfinite"
      )
    )
  }

  hessian_blocked <- diagnostic[
    diagnostic$structured_type %in% c("phylo", "spatial", "relmat"),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(hessian_blocked), 3L)
  expect_equal(hessian_blocked$n_pdhess, rep(0L, 3L))
  expect_equal(hessian_blocked$cov_fixed_status, rep("finite_indefinite", 3L))
  expect_equal(
    hessian_blocked$n_precheck_not_admitted_pdhess_false,
    rep(4L, 3L)
  )
  expect_equal(
    hessian_blocked$n_precheck_not_admitted_bootstrap_nonfinite,
    rep(0L, 3L)
  )
  expect_equal(
    hessian_blocked$smoke_bootstrap_statuses,
    rep("not_run_pdhess_false", 3L)
  )
  expect_equal(
    hessian_blocked$diagnostic_status,
    rep("pdhess_false;indefinite_cov_fixed", 3L)
  )

  animal <- diagnostic[diagnostic$structured_type == "animal", , drop = FALSE]
  expect_equal(nrow(animal), 1L)
  expect_equal(animal$n_pdhess, 1L)
  expect_equal(animal$cov_fixed_status, "finite_positive")
  expect_equal(animal$smoke_wald_statuses, "finite")
  expect_equal(animal$smoke_profile_statuses, "finite")
  expect_equal(animal$smoke_bootstrap_statuses, "nonfinite")
  expect_equal(animal$n_smoke_bootstrap_nonfinite, 4L)
  expect_equal(animal$precheck_diagnosis, "bootstrap_blocker")
  expect_equal(animal$denominator_admission, "not_admitted_bootstrap_nonfinite")
  expect_equal(
    animal$diagnostic_status,
    "bootstrap_nonfinite_after_pdhess_true"
  )

  structured_re_expect_all_match(
    diagnostic$claim_boundary,
    "Hessian/bootstrap diagnostic only"
  )
  structured_re_expect_all_match(
    diagnostic$claim_boundary,
    "derived-correlation intervals still blocked"
  )
  structured_re_expect_all_match(
    diagnostic$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(diagnostic$claim_boundary, "interval coverage")
  structured_re_expect_all_match(
    diagnostic$claim_boundary,
    "native-TMB q4 REML"
  )
  structured_re_expect_all_match(diagnostic$claim_boundary, "HSquared AI-REML")
  structured_re_expect_all_match(
    diagnostic$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(
    diagnostic$claim_boundary,
    "denominator admission"
  )
  structured_re_expect_all_match(
    diagnostic$claim_boundary,
    "DRAC/Totoro execution"
  )
  structured_re_expect_all_match(diagnostic$next_gate, "denominator accounting")
  structured_re_expect_all_match(diagnostic$next_gate, "coverage-grid design")

  qseries_status <- qseries[
    qseries$cell_id %in% diagnostic$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
  structured_re_expect_all_match(
    qseries_status$next_gate,
    "structured-re-q4-intercept-hessian-bootstrap-diagnostic.tsv"
  )
})

test_that("q4 all-four one-slope interval status stays Hessian-blocked", {
  status <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-interval-diagnostic-status.tsv"
  )
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-interval-smoke",
      "structured-re-q4-slope-interval-smoke-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    status,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "estimand",
      "profile_target",
      "source_artifact",
      "observed_target_rows",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_finite_intervals",
      "wald_status",
      "profile_status",
      "bootstrap_status",
      "interval_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(status), 32L)
  expect_equal(nrow(artifact), 96L)
  expect_setequal(
    status$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expected_members <- c(
    "mu1:(Intercept)",
    "mu1:x",
    "mu2:(Intercept)",
    "mu2:x",
    "sigma1:(Intercept)",
    "sigma1:x",
    "sigma2:(Intercept)",
    "sigma2:x"
  )
  for (provider in c("phylo", "spatial", "animal", "relmat")) {
    provider_status <- status[
      status$structured_type == provider,
      ,
      drop = FALSE
    ]
    expect_setequal(provider_status$endpoint_member, expected_members)
  }
  expect_equal(status$target_kind, rep("direct_sd", 32L))
  expect_equal(status$observed_target_rows, rep(1L, 32L))
  expect_equal(status$n_fit_ok, rep(1L, 32L))
  expect_equal(status$n_converged, rep(1L, 32L))
  expect_equal(status$n_pdhess, rep(0L, 32L))
  expect_equal(status$n_finite_intervals, rep(0L, 32L))
  expect_equal(status$wald_status, rep("not_run_pdhess_false", 32L))
  expect_equal(status$profile_status, rep("not_run_pdhess_false", 32L))
  expect_equal(status$bootstrap_status, rep("not_run_pdhess_false", 32L))
  expect_equal(status$interval_status, rep("no_finite_intervals", 32L))
  expect_equal(status$failure_class, rep("fit_pdhess_false", 32L))
  expect_equal(status$interval_claim_status, rep("diagnostic_only", 32L))
  expect_equal(status$status, rep("covered", 32L))

  direct_plan <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
  merged_plan <- merge(
    status[, c("structured_type", "endpoint_member", "profile_target")],
    direct_plan[, c("structured_type", "endpoint_member", "profile_target")],
    by = c("structured_type", "endpoint_member"),
    suffixes = c("_status", "_plan"),
    sort = FALSE
  )
  expect_equal(nrow(merged_plan), 32L)
  expect_equal(
    merged_plan$profile_target_status,
    merged_plan$profile_target_plan
  )
  structured_re_expect_all_match(
    status$profile_target[
      grepl("sigma", status$endpoint_member, fixed = TRUE)
    ],
    "sd:mu:sigma"
  )

  artifact_key <- paste(
    artifact$provider,
    artifact$endpoint_member,
    artifact$interval_method,
    sep = "::"
  )
  expect_equal(anyDuplicated(artifact_key), 0L)
  expect_setequal(artifact$interval_method, c("wald", "profile", "bootstrap"))
  expect_equal(artifact$method_status, rep("not_run_pdhess_false", 96L))
  expect_equal(
    tolower(as.character(artifact$interval_finite)),
    rep("false", 96L)
  )
  expect_equal(tolower(as.character(artifact$profile_ready)), rep("true", 96L))

  structured_re_expect_all_match(
    status$claim_boundary,
    "direct-SD interval smoke only"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "derived-correlation intervals still blocked"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(status$claim_boundary, "interval coverage")
  structured_re_expect_all_match(status$claim_boundary, "q4 REML")
  structured_re_expect_all_match(status$claim_boundary, "AI-REML")
  structured_re_expect_all_match(status$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(status$next_gate, "denominator accounting")
  structured_re_expect_all_match(status$next_gate, "coverage-grid design")

  qseries_status <- qseries[qseries$cell_id %in% status$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_status$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_status$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q4 all-four one-slope interval stability probe stays Hessian-blocked", {
  stability <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-interval-stability-probe.tsv"
  )
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-interval-stability-probe",
      "structured-re-q4-slope-interval-stability-probe-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expected_names <- c(
    "probe_id",
    "cell_id",
    "variant",
    "formula_cell",
    "structured_type",
    "target_kind",
    "endpoint_member",
    "estimand",
    "profile_target",
    "source_artifact",
    "n_levels",
    "n_each",
    "intended_sd_mu1_intercept",
    "intended_sd_mu1_x",
    "intended_sd_mu2_intercept",
    "intended_sd_mu2_x",
    "intended_sd_sigma1_intercept",
    "intended_sd_sigma1_x",
    "intended_sd_sigma2_intercept",
    "intended_sd_sigma2_x",
    "observed_target_rows",
    "n_fit_ok",
    "n_pdhess",
    "estimate",
    "wald_status",
    "profile_status",
    "stability_status",
    "failure_class",
    "interval_claim_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate"
  )
  expect_named(stability, expected_names)
  expect_equal(nrow(stability), 64L)
  expect_equal(nrow(artifact), 128L)
  expect_setequal(stability$variant, c("strong", "more_levels"))
  expect_setequal(
    stability$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )

  expected_members <- c(
    "mu1:(Intercept)",
    "mu1:x",
    "mu2:(Intercept)",
    "mu2:x",
    "sigma1:(Intercept)",
    "sigma1:x",
    "sigma2:(Intercept)",
    "sigma2:x"
  )
  for (variant in c("strong", "more_levels")) {
    for (provider in c("phylo", "spatial", "animal", "relmat")) {
      provider_status <- stability[
        stability$variant == variant &
          stability$structured_type == provider,
        ,
        drop = FALSE
      ]
      expect_setequal(provider_status$endpoint_member, expected_members)
      expect_equal(nrow(provider_status), 8L)
    }
  }

  expect_equal(stability$target_kind, rep("direct_sd", 64L))
  expect_equal(stability$observed_target_rows, rep(1L, 64L))
  expect_equal(stability$n_fit_ok, rep(1L, 64L))
  expect_equal(stability$n_pdhess, rep(0L, 64L))
  expect_equal(stability$wald_status, rep("not_run_pdhess_false", 64L))
  expect_equal(stability$profile_status, rep("not_run_pdhess_false", 64L))
  expect_equal(stability$stability_status, rep("pdhess_blocked", 64L))
  expect_equal(stability$failure_class, rep("fit_pdhess_false", 64L))
  expect_equal(stability$interval_claim_status, rep("diagnostic_only", 64L))
  expect_equal(stability$status, rep("covered", 64L))

  strong <- stability[stability$variant == "strong", , drop = FALSE]
  more_levels <- stability[stability$variant == "more_levels", , drop = FALSE]
  expect_equal(unique(strong$n_levels), 8L)
  expect_equal(unique(strong$n_each), 24L)
  expect_equal(unique(strong$intended_sd_mu1_intercept), 0.70)
  expect_equal(unique(strong$intended_sd_mu1_x), 0.48)
  expect_equal(unique(strong$intended_sd_mu2_intercept), 0.62)
  expect_equal(unique(strong$intended_sd_mu2_x), 0.44)
  expect_equal(unique(strong$intended_sd_sigma1_intercept), 0.50)
  expect_equal(unique(strong$intended_sd_sigma1_x), 0.34)
  expect_equal(unique(strong$intended_sd_sigma2_intercept), 0.46)
  expect_equal(unique(strong$intended_sd_sigma2_x), 0.30)
  expect_equal(unique(more_levels$n_levels), 16L)
  expect_equal(unique(more_levels$n_each), 12L)
  expect_equal(unique(more_levels$intended_sd_mu1_intercept), 0.62)
  expect_equal(unique(more_levels$intended_sd_mu1_x), 0.42)
  expect_equal(unique(more_levels$intended_sd_mu2_intercept), 0.56)
  expect_equal(unique(more_levels$intended_sd_mu2_x), 0.38)
  expect_equal(unique(more_levels$intended_sd_sigma1_intercept), 0.42)
  expect_equal(unique(more_levels$intended_sd_sigma1_x), 0.28)
  expect_equal(unique(more_levels$intended_sd_sigma2_intercept), 0.40)
  expect_equal(unique(more_levels$intended_sd_sigma2_x), 0.26)

  direct_plan <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
  merged_plan <- merge(
    stability[, c("structured_type", "endpoint_member", "profile_target")],
    direct_plan[, c("structured_type", "endpoint_member", "profile_target")],
    by = c("structured_type", "endpoint_member"),
    suffixes = c("_stability", "_plan"),
    sort = FALSE
  )
  expect_equal(nrow(merged_plan), 64L)
  expect_equal(
    merged_plan$profile_target_stability,
    merged_plan$profile_target_plan
  )
  structured_re_expect_all_match(
    stability$profile_target[
      grepl("sigma", stability$endpoint_member, fixed = TRUE)
    ],
    "sd:mu:sigma"
  )

  artifact_key <- paste(
    artifact$variant,
    artifact$provider,
    artifact$endpoint_member,
    artifact$interval_method,
    sep = "::"
  )
  expect_equal(anyDuplicated(artifact_key), 0L)
  expect_setequal(artifact$interval_method, c("wald", "profile"))
  expect_equal(artifact$method_status, rep("not_run_pdhess_false", 128L))
  expect_equal(
    tolower(as.character(artifact$interval_finite)),
    rep("false", 128L)
  )
  expect_equal(tolower(as.character(artifact$profile_ready)), rep("true", 128L))
  expect_equal(artifact$pdHess, rep(FALSE, 128L))

  structured_re_expect_all_match(
    stability$claim_boundary,
    "direct-SD interval stability probe only"
  )
  structured_re_expect_all_match(
    stability$claim_boundary,
    "derived-correlation intervals still blocked"
  )
  structured_re_expect_all_match(
    stability$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(stability$claim_boundary, "interval coverage")
  structured_re_expect_all_match(stability$claim_boundary, "q4 REML")
  structured_re_expect_all_match(stability$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    stability$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(stability$next_gate, "Hessian failures")
  structured_re_expect_all_match(stability$next_gate, "denominator accounting")
  structured_re_expect_all_match(stability$next_gate, "coverage-grid design")

  qseries_status <- qseries[
    qseries$cell_id %in% stability$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_status$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_status$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q4 all-four one-slope Hessian geometry stays diagnostic-only", {
  geometry <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-hessian-geometry.tsv"
  )
  stability <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-interval-stability-probe.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-hessian-geometry",
      "structured-re-q4-slope-hessian-geometry-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expected_names <- c(
    "geometry_id",
    "cell_id",
    "variant",
    "formula_cell",
    "structured_type",
    "source_stability_probe",
    "source_stability_artifact",
    "source_artifact",
    "n_levels",
    "n_each",
    "intended_sd_mu1_intercept",
    "intended_sd_mu1_x",
    "intended_sd_mu2_intercept",
    "intended_sd_mu2_x",
    "intended_sd_sigma1_intercept",
    "intended_sd_sigma1_x",
    "intended_sd_sigma2_intercept",
    "intended_sd_sigma2_x",
    "fit_convergence",
    "n_pdhess",
    "logLik",
    "max_abs_gradient_fixed",
    "optimizer_attempt_count",
    "optimizer_selected",
    "optimizer_selected_preset",
    "optimizer_selected_status",
    "fallback_selected",
    "optimizer_attempt_presets",
    "optimizer_attempt_statuses",
    "cov_fixed_status",
    "cov_fixed_dim",
    "cov_fixed_finite_count",
    "cov_fixed_total",
    "min_cov_fixed_eigenvalue",
    "max_cov_fixed_eigenvalue",
    "n_cov_fixed_nonpositive_eigenvalues",
    "raw_hessian_status",
    "raw_hessian_message",
    "direct_sd_target_count",
    "n_profile_ready_direct_sd",
    "min_direct_sd_estimate",
    "max_direct_sd_estimate",
    "n_direct_sd_at_lower_bound",
    "n_mu_direct_sd_at_lower_bound",
    "n_sigma_direct_sd_at_lower_bound",
    "min_mu_direct_sd_estimate",
    "min_sigma_direct_sd_estimate",
    "max_abs_derived_correlation",
    "n_abs_derived_correlation_gt_0_95",
    "n_derived_correlation_zero",
    "geometry_status",
    "interval_claim_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate"
  )
  expect_named(geometry, expected_names)
  expect_named(artifact, expected_names)
  expect_equal(nrow(geometry), 8L)
  expect_equal(nrow(artifact), 8L)
  expect_equal(artifact$geometry_id, geometry$geometry_id)
  expect_setequal(geometry$variant, c("strong", "more_levels"))
  expect_setequal(
    geometry$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  for (variant in c("strong", "more_levels")) {
    for (provider in c("phylo", "spatial", "animal", "relmat")) {
      provider_geometry <- geometry[
        geometry$variant == variant &
          geometry$structured_type == provider,
        ,
        drop = FALSE
      ]
      expect_equal(nrow(provider_geometry), 1L)
    }
  }

  strong <- geometry[geometry$variant == "strong", , drop = FALSE]
  more_levels <- geometry[geometry$variant == "more_levels", , drop = FALSE]
  expect_equal(unique(strong$n_levels), 8L)
  expect_equal(unique(strong$n_each), 24L)
  expect_equal(unique(strong$intended_sd_mu1_intercept), 0.70)
  expect_equal(unique(strong$intended_sd_mu1_x), 0.48)
  expect_equal(unique(strong$intended_sd_mu2_intercept), 0.62)
  expect_equal(unique(strong$intended_sd_mu2_x), 0.44)
  expect_equal(unique(strong$intended_sd_sigma1_intercept), 0.50)
  expect_equal(unique(strong$intended_sd_sigma1_x), 0.34)
  expect_equal(unique(strong$intended_sd_sigma2_intercept), 0.46)
  expect_equal(unique(strong$intended_sd_sigma2_x), 0.30)
  expect_equal(unique(more_levels$n_levels), 16L)
  expect_equal(unique(more_levels$n_each), 12L)
  expect_equal(unique(more_levels$intended_sd_mu1_intercept), 0.62)
  expect_equal(unique(more_levels$intended_sd_mu1_x), 0.42)
  expect_equal(unique(more_levels$intended_sd_mu2_intercept), 0.56)
  expect_equal(unique(more_levels$intended_sd_mu2_x), 0.38)
  expect_equal(unique(more_levels$intended_sd_sigma1_intercept), 0.42)
  expect_equal(unique(more_levels$intended_sd_sigma1_x), 0.28)
  expect_equal(unique(more_levels$intended_sd_sigma2_intercept), 0.40)
  expect_equal(unique(more_levels$intended_sd_sigma2_x), 0.26)

  expect_equal(geometry$fit_convergence, rep(0L, 8L))
  expect_equal(geometry$n_pdhess, rep(0L, 8L))
  expect_equal(geometry$cov_fixed_status, rep("nonfinite", 8L))
  expect_equal(geometry$cov_fixed_dim, rep("45x45", 8L))
  expect_equal(geometry$cov_fixed_finite_count, rep(0L, 8L))
  expect_equal(geometry$cov_fixed_total, rep(2025L, 8L))
  expect_equal(is.na(geometry$min_cov_fixed_eigenvalue), rep(TRUE, 8L))
  expect_equal(is.na(geometry$max_cov_fixed_eigenvalue), rep(TRUE, 8L))
  expect_equal(
    is.na(geometry$n_cov_fixed_nonpositive_eigenvalues),
    rep(TRUE, 8L)
  )
  expect_equal(
    geometry$raw_hessian_status,
    rep("unavailable_random_effects", 8L)
  )
  structured_re_expect_all_match(
    geometry$raw_hessian_message,
    "Hessian not yet implemented for models with random effects."
  )

  expect_equal(geometry$direct_sd_target_count, rep(8L, 8L))
  expect_equal(geometry$n_profile_ready_direct_sd, rep(8L, 8L))
  expect_equal(geometry$n_direct_sd_at_lower_bound, rep(4L, 8L))
  expect_equal(geometry$n_mu_direct_sd_at_lower_bound, rep(0L, 8L))
  expect_equal(geometry$n_sigma_direct_sd_at_lower_bound, rep(4L, 8L))
  expect_equal(
    geometry$min_sigma_direct_sd_estimate >= 0.049 &
      geometry$min_sigma_direct_sd_estimate <= 0.051,
    rep(TRUE, 8L)
  )
  expect_equal(geometry$min_mu_direct_sd_estimate > 0.05, rep(TRUE, 8L))
  expect_equal(
    geometry$max_abs_gradient_fixed >= 0 &
      geometry$max_abs_gradient_fixed < 0.05,
    rep(TRUE, 8L)
  )
  expect_equal(
    geometry$max_abs_derived_correlation >= 0 &
      geometry$max_abs_derived_correlation <= 1,
    rep(TRUE, 8L)
  )

  expect_equal(sum(geometry$fallback_selected), 7L)
  expect_setequal(
    geometry$geometry_status,
    c(
      "sigma_sd_lower_bound;nonfinite_cov_fixed",
      "sigma_sd_lower_bound;nonfinite_cov_fixed;fallback_selected"
    )
  )
  expect_equal(
    geometry$geometry_status[geometry$fallback_selected],
    rep("sigma_sd_lower_bound;nonfinite_cov_fixed;fallback_selected", 7L)
  )
  expect_equal(
    geometry$geometry_status[!geometry$fallback_selected],
    "sigma_sd_lower_bound;nonfinite_cov_fixed"
  )

  stability_keys <- unique(
    paste(stability$variant, stability$structured_type, sep = "::")
  )
  geometry_keys <- paste(geometry$variant, geometry$structured_type, sep = "::")
  expect_setequal(geometry_keys, stability_keys)
  expect_equal(
    geometry$source_stability_probe,
    rep(
      "docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv",
      8L
    )
  )
  expect_equal(
    geometry$source_stability_artifact,
    rep(
      paste(
        "docs/dev-log/simulation-artifacts/",
        "2026-06-24-q4-slope-interval-stability-probe/",
        "structured-re-q4-slope-interval-stability-probe-results.tsv",
        sep = ""
      ),
      8L
    )
  )
  expect_equal(
    geometry$source_artifact,
    rep(
      paste(
        "docs/dev-log/simulation-artifacts/",
        "2026-06-24-q4-slope-hessian-geometry/",
        "structured-re-q4-slope-hessian-geometry-results.tsv",
        sep = ""
      ),
      8L
    )
  )

  expect_equal(geometry$interval_claim_status, rep("diagnostic_only", 8L))
  expect_equal(geometry$status, rep("covered", 8L))
  structured_re_expect_all_match(
    geometry$claim_boundary,
    "Hessian-geometry diagnostic only"
  )
  structured_re_expect_all_match(
    geometry$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(geometry$claim_boundary, "interval coverage")
  structured_re_expect_all_match(geometry$claim_boundary, "q4 REML")
  structured_re_expect_all_match(geometry$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    geometry$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(geometry$claim_boundary, "broader q8 support")
  structured_re_expect_all_match(geometry$next_gate, "lower-bound geometry")
  structured_re_expect_all_match(geometry$next_gate, "denominator accounting")

  qseries_status <- qseries[
    qseries$cell_id %in% geometry$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_status$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_status$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("q4 sigma-axis differential records partial-axis guard blockers", {
  differential <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-sigma-axis-differential.tsv"
  )
  geometry <- structured_re_read_dashboard_tsv(
    "structured-re-q4-slope-hessian-geometry.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-sigma-axis-differential",
      "structured-re-q4-slope-sigma-axis-differential-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expected_names <- c(
    "differential_id",
    "cell_id",
    "variant",
    "model_axis",
    "formula_cell",
    "structured_type",
    "structured_endpoint_set",
    "structured_member_count",
    "source_hessian_geometry",
    "source_artifact",
    "n_levels",
    "n_each",
    "intended_sd_mu1_intercept",
    "intended_sd_mu1_x",
    "intended_sd_mu2_intercept",
    "intended_sd_mu2_x",
    "intended_sd_sigma1_intercept",
    "intended_sd_sigma1_x",
    "intended_sd_sigma2_intercept",
    "intended_sd_sigma2_x",
    "fit_convergence",
    "n_pdhess",
    "logLik",
    "max_abs_gradient_fixed",
    "optimizer_attempt_count",
    "optimizer_selected",
    "optimizer_selected_preset",
    "optimizer_selected_status",
    "fallback_selected",
    "optimizer_attempt_presets",
    "optimizer_attempt_statuses",
    "cov_fixed_status",
    "cov_fixed_dim",
    "cov_fixed_finite_count",
    "cov_fixed_total",
    "min_cov_fixed_eigenvalue",
    "max_cov_fixed_eigenvalue",
    "n_cov_fixed_nonpositive_eigenvalues",
    "raw_hessian_status",
    "raw_hessian_message",
    "direct_sd_target_count",
    "n_profile_ready_direct_sd",
    "min_direct_sd_estimate",
    "max_direct_sd_estimate",
    "n_direct_sd_at_lower_bound",
    "n_mu_direct_sd_at_lower_bound",
    "n_sigma_direct_sd_at_lower_bound",
    "min_mu_direct_sd_estimate",
    "min_sigma_direct_sd_estimate",
    "max_abs_derived_correlation",
    "n_abs_derived_correlation_gt_0_95",
    "n_derived_correlation_zero",
    "differential_status",
    "interval_claim_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate"
  )
  expect_named(differential, expected_names)
  expect_named(artifact, expected_names)
  expect_equal(nrow(differential), 24L)
  expect_equal(nrow(artifact), 24L)
  expect_equal(artifact$differential_id, differential$differential_id)
  expect_setequal(differential$variant, c("strong", "more_levels"))
  expect_setequal(
    differential$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_setequal(
    differential$model_axis,
    c("all_four_slope", "mu_axis_only", "sigma_axis_only")
  )
  for (variant in c("strong", "more_levels")) {
    for (provider in c("phylo", "spatial", "animal", "relmat")) {
      provider_rows <- differential[
        differential$variant == variant &
          differential$structured_type == provider,
        ,
        drop = FALSE
      ]
      expect_equal(nrow(provider_rows), 3L)
      expect_setequal(
        provider_rows$model_axis,
        c("all_four_slope", "mu_axis_only", "sigma_axis_only")
      )
    }
  }

  all_four <- differential[
    differential$model_axis == "all_four_slope",
    ,
    drop = FALSE
  ]
  mu_axis <- differential[
    differential$model_axis == "mu_axis_only",
    ,
    drop = FALSE
  ]
  sigma_axis <- differential[
    differential$model_axis == "sigma_axis_only",
    ,
    drop = FALSE
  ]

  expect_equal(
    all_four$structured_endpoint_set,
    rep("mu1+mu2+sigma1+sigma2", 8L)
  )
  expect_equal(all_four$structured_member_count, rep(8L, 8L))
  expect_equal(mu_axis$structured_endpoint_set, rep("mu1+mu2", 8L))
  expect_equal(mu_axis$structured_member_count, rep(4L, 8L))
  expect_equal(sigma_axis$structured_endpoint_set, rep("sigma1+sigma2", 8L))
  expect_equal(sigma_axis$structured_member_count, rep(4L, 8L))

  geometry_keys <- paste(geometry$variant, geometry$structured_type, sep = "::")
  all_four_keys <- paste(all_four$variant, all_four$structured_type, sep = "::")
  expect_setequal(all_four_keys, geometry_keys)
  expect_equal(all_four$fit_convergence, rep(0L, 8L))
  expect_equal(all_four$n_pdhess, rep(0L, 8L))
  expect_equal(all_four$cov_fixed_status, rep("nonfinite", 8L))
  expect_equal(all_four$direct_sd_target_count, rep(8L, 8L))
  expect_equal(all_four$n_sigma_direct_sd_at_lower_bound, rep(4L, 8L))
  expect_equal(all_four$n_mu_direct_sd_at_lower_bound, rep(0L, 8L))
  expect_equal(sum(all_four$fallback_selected), 7L)
  expect_setequal(
    all_four$differential_status,
    c(
      "baseline;sigma_sd_lower_bound;nonfinite_cov_fixed",
      "baseline;sigma_sd_lower_bound;nonfinite_cov_fixed;fallback_selected"
    )
  )

  expect_equal(mu_axis$fit_convergence, rep(0L, 8L))
  expect_equal(mu_axis$n_pdhess, rep(1L, 8L))
  expect_true(all(mu_axis$optimizer_attempt_count >= 1L))
  expect_equal(sum(mu_axis$fallback_selected), 2L)
  expect_equal(mu_axis$cov_fixed_status, rep("finite_positive", 8L))
  expect_equal(mu_axis$cov_fixed_finite_count, rep(361L, 8L))
  expect_equal(mu_axis$cov_fixed_total, rep(361L, 8L))
  expect_equal(mu_axis$n_cov_fixed_nonpositive_eigenvalues, rep(0L, 8L))
  expect_equal(
    mu_axis$raw_hessian_status,
    rep("unavailable_random_effects", 8L)
  )
  expect_equal(mu_axis$direct_sd_target_count, rep(4L, 8L))
  expect_equal(mu_axis$n_profile_ready_direct_sd, rep(4L, 8L))
  expect_equal(mu_axis$n_direct_sd_at_lower_bound, rep(0L, 8L))
  expect_equal(mu_axis$n_mu_direct_sd_at_lower_bound, rep(0L, 8L))
  expect_equal(mu_axis$n_sigma_direct_sd_at_lower_bound, rep(0L, 8L))
  expect_false(any(is.na(mu_axis$min_direct_sd_estimate)))
  expect_false(any(is.na(mu_axis$max_abs_derived_correlation)))
  expect_setequal(
    mu_axis$differential_status,
    c(
      "mu_axis_only;pdhess_true;no_direct_sd_lower_bound;cov_fixed_finite_positive",
      paste(
        "mu_axis_only;pdhess_true;no_direct_sd_lower_bound;",
        "cov_fixed_finite_positive;fallback_selected",
        sep = ""
      )
    )
  )
  structured_re_expect_all_match(
    mu_axis$raw_hessian_message,
    "Hessian not yet implemented for models with random effects"
  )

  expect_equal(sigma_axis$fit_convergence, rep(NA_integer_, 8L))
  expect_equal(sigma_axis$n_pdhess, rep(0L, 8L))
  expect_equal(sigma_axis$optimizer_attempt_count, rep(0L, 8L))
  expect_equal(sigma_axis$fallback_selected, rep(FALSE, 8L))
  expect_equal(sigma_axis$cov_fixed_status, rep("missing", 8L))
  expect_equal(sigma_axis$cov_fixed_total, rep(0L, 8L))
  expect_equal(sigma_axis$raw_hessian_status, rep("not_run_fit_error", 8L))
  expect_equal(sigma_axis$direct_sd_target_count, rep(0L, 8L))
  expect_equal(sigma_axis$n_profile_ready_direct_sd, rep(0L, 8L))
  expect_equal(is.na(sigma_axis$min_direct_sd_estimate), rep(TRUE, 8L))
  expect_equal(is.na(sigma_axis$max_abs_derived_correlation), rep(TRUE, 8L))
  expect_equal(
    sigma_axis$differential_status,
    rep("sigma_axis_only;fit_error", 8L)
  )
  structured_re_expect_all_match(
    sigma_axis$raw_hessian_message,
    "location-scale blocks are not implemented"
  )
  structured_re_expect_all_match(
    sigma_axis$raw_hessian_message,
    "Use matching labelled intercepts"
  )

  expect_equal(
    differential$source_hessian_geometry,
    rep(
      "docs/dev-log/dashboard/structured-re-q4-slope-hessian-geometry.tsv",
      24L
    )
  )
  expect_equal(
    differential$source_artifact,
    rep(
      paste(
        "docs/dev-log/simulation-artifacts/",
        "2026-06-24-q4-slope-sigma-axis-differential/",
        "structured-re-q4-slope-sigma-axis-differential-results.tsv",
        sep = ""
      ),
      24L
    )
  )
  expect_equal(differential$interval_claim_status, rep("diagnostic_only", 24L))
  expect_equal(differential$status, rep("covered", 24L))
  structured_re_expect_all_match(
    differential$claim_boundary,
    "sigma-axis differential diagnostic only"
  )
  structured_re_expect_all_match(
    differential$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(
    differential$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(differential$claim_boundary, "q4 REML")
  structured_re_expect_all_match(differential$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    differential$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(
    differential$next_gate,
    "denominator accounting"
  )

  qseries_status <- qseries[
    qseries$cell_id %in% differential$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$route, rep("native_direct_bridge_fixture", 4L))
  expect_equal(qseries_status$fit_status, rep("point_fit", 4L))
  expect_equal(qseries_status$extractor_status, rep("extractor_ready", 4L))
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("matched mu+sigma one-slope parity fixture records bridge fixture only", {
  fixture <- structured_re_read_dashboard_tsv(
    "structured-re-mu-sigma-slope-parity-fixture.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    fixture,
    c(
      "fixture_id",
      "formula_cell",
      "structured_type",
      "dimension",
      "endpoint",
      "slope_class",
      "estimator",
      "native_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "coefficient_order",
      "matrix_slot",
      "input_scale",
      "parity_status",
      "bridge_status",
      "interval_status",
      "coverage_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(fixture), 4L)
  expect_setequal(
    fixture$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(fixture$dimension, rep("q1_plus_q1", 4L))
  expect_equal(fixture$endpoint, rep("mu+sigma", 4L))
  expect_equal(fixture$slope_class, rep("independent_one_slope", 4L))
  expect_equal(fixture$native_status, rep("fixture_available", 4L))
  expect_equal(fixture$direct_drmjl_status, rep("fixture_available", 4L))
  expect_equal(fixture$r_via_julia_status, rep("fixture_available", 4L))
  expect_equal(fixture$bridge_status, rep("fixture_parity", 4L))
  expect_equal(fixture$interval_status, rep("planned", 4L))
  expect_equal(fixture$coverage_status, rep("planned", 4L))
  expect_equal(
    fixture$coefficient_order,
    rep(
      paste(
        "mu:(Intercept);mu:x;sigma:(Intercept);sigma:x;",
        "sd_mu:structured(Intercept);sd_mu:structured(x);",
        "sd_sigma:structured(Intercept);sd_sigma:structured(x)",
        sep = ""
      ),
      4L
    )
  )
  expect_equal(fixture$matrix_slot, c("tree", "coords", "A", "K"))
  structured_re_expect_all_match(fixture$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(fixture$claim_boundary, "coverage")
  structured_re_expect_all_match(fixture$claim_boundary, "REML")
  structured_re_expect_all_match(fixture$claim_boundary, "AI-REML")
  structured_re_expect_all_match(fixture$next_gate, "interval diagnostics")
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "spatial"],
    "fixed-covariance"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "animal"],
    "A-matrix"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "relmat"],
    "K-matrix"
  )
  structured_re_expect_all_match(
    fixture$claim_boundary[fixture$structured_type == "relmat"],
    "Q bridge"
  )

  qseries_ready <- qseries[
    qseries$cell_id %in%
      paste0(
        "qseries_",
        fixture$structured_type,
        "_q1_mu_sigma_one_slope"
      ),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_ready), 4L)
  expect_equal(qseries_ready$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    qseries_ready$evidence_url,
    rep(
      "docs/dev-log/dashboard/structured-re-mu-sigma-slope-parity-fixture.tsv",
      4L
    )
  )
  expect_equal(
    qseries_ready$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("matched mu+sigma one-slope interval plan remains target-level", {
  plan <- structured_re_read_dashboard_tsv(
    "structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )

  expect_named(
    plan,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "interval_methods",
      "required_fit_evidence",
      "required_interval_evidence",
      "denominator_fields",
      "current_blocker",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(plan), 16L)
  expect_setequal(
    plan$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(plan$target_kind, rep("direct_sd", 16L))
  expect_equal(plan$current_blocker, rep("interval_diagnostics_not_run", 16L))
  expect_equal(plan$status, rep("planned", 16L))

  expected_endpoints <- c(
    "mu:(Intercept)",
    "mu:x",
    "sigma:(Intercept)",
    "sigma:x"
  )
  for (provider in c("phylo", "spatial", "animal", "relmat")) {
    provider_rows <- plan[plan$structured_type == provider, , drop = FALSE]
    expect_setequal(provider_rows$endpoint_member, expected_endpoints)
    expect_equal(
      provider_rows$cell_id,
      rep(paste0("qseries_", provider, "_q1_mu_sigma_one_slope"), 4L)
    )
  }

  expect_setequal(
    plan$direct_sd_target,
    c("sd_mu_intercept", "sd_mu_x", "sd_sigma_intercept", "sd_sigma_x")
  )
  expect_setequal(
    plan$profile_target,
    c(
      "sd:mu:mu:phylo(1 | species)",
      "sd:mu:mu:phylo(0 + x | species)",
      "sd:sigma:sigma:phylo(1 | species)",
      "sd:sigma:sigma:phylo(0 + x | species)",
      "sd:mu:mu:spatial(1 | site)",
      "sd:mu:mu:spatial(0 + x | site)",
      "sd:sigma:sigma:spatial(1 | site)",
      "sd:sigma:sigma:spatial(0 + x | site)",
      "sd:mu:mu:animal(1 | id)",
      "sd:mu:mu:animal(0 + x | id)",
      "sd:sigma:sigma:animal(1 | id)",
      "sd:sigma:sigma:animal(0 + x | id)",
      "sd:mu:mu:relmat(1 | id)",
      "sd:mu:mu:relmat(0 + x | id)",
      "sd:sigma:sigma:relmat(1 | id)",
      "sd:sigma:sigma:relmat(0 + x | id)"
    )
  )

  structured_re_expect_all_match(plan$interval_methods, "wald")
  structured_re_expect_all_match(plan$interval_methods, "profile")
  structured_re_expect_all_match(plan$interval_methods, "bootstrap")
  structured_re_expect_all_match(plan$required_fit_evidence, "point_fit")
  structured_re_expect_all_match(
    plan$required_fit_evidence,
    "same_target_fixture_parity"
  )
  structured_re_expect_all_match(
    plan$required_interval_evidence,
    "finite_intervals_by_method"
  )
  structured_re_expect_all_match(
    plan$required_interval_evidence,
    "coverage_mcse<=0.01"
  )
  structured_re_expect_all_match(
    plan$denominator_fields,
    "coverage_denominator"
  )
  structured_re_expect_all_match(plan$denominator_fields, "coverage_mcse")
  structured_re_expect_all_match(plan$claim_boundary, "no interval reliability")
  structured_re_expect_all_match(plan$claim_boundary, "interval coverage")
  structured_re_expect_all_match(plan$claim_boundary, "REML")
  structured_re_expect_all_match(plan$claim_boundary, "AI-REML")
  structured_re_expect_all_match(plan$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(plan$next_gate, "before calibrated coverage")

  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    plan$claim_boundary[plan$structured_type == "relmat"],
    "Q bridge"
  )

  qseries_plan <- qseries[qseries$cell_id %in% plan$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_plan), 4L)
  expect_equal(qseries_plan$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_plan$interval_status, rep("planned", 4L))
  expect_equal(qseries_plan$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_plan$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("matched mu+sigma one-slope interval status remains diagnostic-only", {
  status <- structured_re_read_dashboard_tsv(
    "structured-re-mu-sigma-slope-interval-diagnostic-status.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-mu-sigma-slope-interval-smoke",
      "structured-re-mu-sigma-slope-interval-smoke-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    status,
    c(
      "diagnostic_id",
      "cell_id",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "source_artifact",
      "observed_target_rows",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_finite_intervals",
      "wald_status",
      "profile_status",
      "bootstrap_status",
      "interval_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(status), 16L)
  expect_equal(nrow(artifact), 48L)
  expect_setequal(
    status$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(status$target_kind, rep("direct_sd", 16L))
  expect_equal(status$observed_target_rows, rep(1L, 16L))
  expect_equal(status$n_fit_ok, rep(1L, 16L))
  expect_equal(status$n_converged, rep(1L, 16L))
  expect_equal(status$n_pdhess, rep(1L, 16L))
  expect_equal(status$bootstrap_status, rep("finite", 16L))
  expect_equal(status$interval_claim_status, rep("diagnostic_only", 16L))
  expect_equal(status$status, rep("covered", 16L))

  all_finite <- status[
    status$interval_status == "wald_profile_bootstrap_finite",
    c("structured_type", "endpoint_member"),
    drop = FALSE
  ]
  expect_equal(nrow(all_finite), 5L)
  expect_equal(
    all_finite$structured_type,
    c(
      "phylo",
      "phylo",
      "spatial",
      "spatial",
      "relmat"
    )
  )
  expect_equal(
    all_finite$endpoint_member,
    c(
      "mu:(Intercept)",
      "mu:x",
      "mu:(Intercept)",
      "mu:x",
      "mu:(Intercept)"
    )
  )

  wald_bootstrap <- status[
    status$interval_status == "wald_bootstrap_finite_profile_failed",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(wald_bootstrap), 1L)
  expect_equal(wald_bootstrap$structured_type, "relmat")
  expect_equal(wald_bootstrap$endpoint_member, "sigma:(Intercept)")
  expect_equal(wald_bootstrap$n_finite_intervals, 2L)
  expect_equal(wald_bootstrap$failure_class, "profile_failed_or_nonfinite")

  bootstrap_only <- status[
    status$interval_status == "bootstrap_only_finite_boundary",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(bootstrap_only), 10L)
  expect_equal(bootstrap_only$n_finite_intervals, rep(1L, 10L))
  expect_equal(bootstrap_only$wald_status, rep("nonfinite", 10L))
  expect_equal(bootstrap_only$profile_status, rep("nonfinite", 10L))
  structured_re_expect_all_match(
    bootstrap_only$failure_class,
    "wald_boundary_or_nonfinite"
  )
  structured_re_expect_all_match(
    bootstrap_only$failure_class,
    "profile_failed_or_nonfinite"
  )

  structured_re_expect_all_match(status$claim_boundary, "interval smoke only")
  structured_re_expect_all_match(
    status$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(status$claim_boundary, "interval coverage")
  structured_re_expect_all_match(status$claim_boundary, "REML")
  structured_re_expect_all_match(status$claim_boundary, "AI-REML")
  structured_re_expect_all_match(status$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(status$next_gate, "coverage")
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "relmat"],
    "Q bridge"
  )

  artifact_key <- paste(
    artifact$provider,
    artifact$endpoint_member,
    artifact$interval_method,
    sep = "::"
  )
  expect_equal(anyDuplicated(artifact_key), 0L)
  expect_setequal(artifact$interval_method, c("wald", "profile", "bootstrap"))
  expect_equal(sum(artifact$interval_finite), sum(status$n_finite_intervals))
  expect_equal(
    unique(artifact$profile_ready),
    TRUE
  )

  qseries_status <- qseries[qseries$cell_id %in% status$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("matched mu+sigma one-slope interval stability probe stays diagnostic-only", {
  status <- structured_re_read_dashboard_tsv(
    "structured-re-mu-sigma-slope-interval-stability-probe.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-mu-sigma-slope-interval-stability-probe",
      "structured-re-mu-sigma-slope-interval-stability-probe-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    status,
    c(
      "probe_id",
      "cell_id",
      "variant",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "source_artifact",
      "n_each",
      "intended_sd_mu_intercept",
      "intended_sd_mu_x",
      "intended_sd_sigma_intercept",
      "intended_sd_sigma_x",
      "observed_target_rows",
      "n_fit_ok",
      "n_pdhess",
      "estimate",
      "wald_status",
      "profile_status",
      "stability_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(status), 32L)
  expect_equal(nrow(artifact), 64L)
  expect_setequal(status$variant, c("strong", "stronger_sigma"))
  expect_setequal(
    status$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_setequal(
    status$endpoint_member,
    c("mu:(Intercept)", "mu:x", "sigma:(Intercept)", "sigma:x")
  )
  expect_equal(status$target_kind, rep("direct_sd", 32L))
  expect_equal(status$n_each, rep(20L, 32L))
  expect_equal(status$observed_target_rows, rep(1L, 32L))
  expect_equal(status$n_fit_ok, rep(1L, 32L))
  expect_equal(status$n_pdhess, rep(1L, 32L))
  expect_equal(status$interval_claim_status, rep("diagnostic_only", 32L))
  expect_equal(status$status, rep("covered", 32L))

  finite <- status[
    status$stability_status == "wald_profile_finite",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(finite), 28L)
  expect_equal(finite$wald_status, rep("finite", 28L))
  expect_equal(finite$profile_status, rep("finite", 28L))
  expect_equal(finite$failure_class, rep("none", 28L))

  boundary <- status[
    status$stability_status == "wald_profile_nonfinite_boundary",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(boundary), 4L)
  expect_equal(boundary$structured_type, rep("spatial", 4L))
  expect_equal(
    paste(boundary$variant, boundary$endpoint_member, sep = "::"),
    c(
      "strong::mu:(Intercept)",
      "strong::mu:x",
      "stronger_sigma::mu:(Intercept)",
      "stronger_sigma::mu:x"
    )
  )
  expect_equal(boundary$wald_status, rep("nonfinite", 4L))
  expect_equal(boundary$profile_status, rep("nonfinite", 4L))
  expect_equal(
    boundary$failure_class,
    rep(
      "wald_boundary_or_nonfinite;profile_failed_or_nonfinite",
      4L
    )
  )

  structured_re_expect_all_match(status$claim_boundary, "stability probe only")
  structured_re_expect_all_match(
    status$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(status$claim_boundary, "interval coverage")
  structured_re_expect_all_match(status$claim_boundary, "REML")
  structured_re_expect_all_match(status$claim_boundary, "AI-REML")
  structured_re_expect_all_match(status$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "spatial"],
    "range-estimating"
  )
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "animal"],
    "pedigree/Ainv"
  )
  structured_re_expect_all_match(
    status$claim_boundary[status$structured_type == "relmat"],
    "Q bridge"
  )

  artifact_key <- paste(
    artifact$variant,
    artifact$provider,
    artifact$endpoint_member,
    artifact$interval_method,
    sep = "::"
  )
  expect_equal(anyDuplicated(artifact_key), 0L)
  expect_setequal(artifact$interval_method, c("wald", "profile"))
  expect_equal(sum(artifact$interval_finite), 2L * nrow(finite))
  expect_equal(unique(artifact$profile_ready), TRUE)

  qseries_status <- qseries[qseries$cell_id %in% status$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 4L)
  expect_equal(qseries_status$bridge_status, rep("fixture_parity", 4L))
  expect_equal(qseries_status$interval_status, rep("planned", 4L))
  expect_equal(qseries_status$coverage_status, rep("planned", 4L))
  expect_equal(
    qseries_status$denominator_policy,
    rep("fixture_not_coverage", 4L)
  )
})

test_that("spatial mu boundary diagnostic separates seed and profile failures", {
  status <- structured_re_read_dashboard_tsv(
    "structured-re-spatial-mu-boundary-diagnostic.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-spatial-mu-boundary-diagnostic",
      "structured-re-spatial-mu-boundary-diagnostic-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    status,
    c(
      "diagnostic_id",
      "cell_id",
      "design_id",
      "seed",
      "n_each",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "source_artifact",
      "intended_sd_mu_intercept",
      "intended_sd_mu_x",
      "intended_sd_sigma_intercept",
      "intended_sd_sigma_x",
      "realized_sd_mu_intercept",
      "realized_sd_mu_x",
      "realized_sd_sigma_intercept",
      "realized_sd_sigma_x",
      "observed_target_rows",
      "n_fit_ok",
      "n_pdhess",
      "estimate",
      "wald_status",
      "profile_status",
      "diagnostic_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(status), 12L)
  expect_equal(nrow(artifact), 24L)
  expect_setequal(
    status$design_id,
    c(
      "smoke_seed102",
      "strong_seed202",
      "strong_seed102",
      "strong_seed302",
      "strong_n50_seed202",
      "mu_dominant_seed202"
    )
  )
  expect_equal(status$structured_type, rep("spatial", 12L))
  expect_equal(status$target_kind, rep("direct_sd", 12L))
  expect_setequal(status$endpoint_member, c("mu:(Intercept)", "mu:x"))
  expect_equal(status$observed_target_rows, rep(1L, 12L))
  expect_equal(status$n_fit_ok, rep(1L, 12L))
  expect_equal(status$n_pdhess, rep(1L, 12L))
  expect_equal(status$interval_claim_status, rep("diagnostic_only", 12L))
  expect_equal(status$status, rep("covered", 12L))

  finite <- status[
    status$diagnostic_status == "wald_profile_finite",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(finite), 8L)
  expect_equal(finite$wald_status, rep("finite", 8L))
  expect_equal(finite$profile_status, rep("finite", 8L))
  expect_equal(finite$failure_class, rep("none", 8L))

  partial <- status[
    status$diagnostic_status == "wald_finite_profile_nonfinite",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(partial), 2L)
  expect_equal(
    paste(partial$design_id, partial$endpoint_member, sep = "::"),
    c("strong_n50_seed202::mu:x", "mu_dominant_seed202::mu:x")
  )
  expect_equal(partial$wald_status, rep("finite", 2L))
  expect_equal(partial$profile_status, rep("nonfinite", 2L))
  expect_equal(partial$failure_class, rep("profile_failed_or_nonfinite", 2L))

  boundary <- status[
    status$diagnostic_status == "wald_profile_nonfinite_boundary",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(boundary), 2L)
  expect_equal(
    paste(boundary$design_id, boundary$endpoint_member, sep = "::"),
    c("strong_seed202::mu:(Intercept)", "strong_seed202::mu:x")
  )
  expect_equal(boundary$wald_status, rep("nonfinite", 2L))
  expect_equal(boundary$profile_status, rep("nonfinite", 2L))
  expect_equal(
    boundary$failure_class,
    rep(
      "wald_boundary_or_nonfinite;profile_failed_or_nonfinite",
      2L
    )
  )

  structured_re_expect_all_match(
    status$claim_boundary,
    "spatial-mu boundary diagnostic only"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "range-estimating spatial support"
  )
  structured_re_expect_all_match(
    status$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(status$claim_boundary, "interval coverage")
  structured_re_expect_all_match(status$claim_boundary, "REML")
  structured_re_expect_all_match(status$claim_boundary, "AI-REML")
  structured_re_expect_all_match(status$claim_boundary, "broad bridge support")
  structured_re_expect_all_match(status$claim_boundary, "public support")

  artifact_key <- paste(
    artifact$design_id,
    artifact$endpoint_member,
    artifact$interval_method,
    sep = "::"
  )
  expect_equal(anyDuplicated(artifact_key), 0L)
  expect_setequal(artifact$interval_method, c("wald", "profile"))
  expect_equal(sum(artifact$interval_finite), 18L)
  expect_equal(sum(artifact$interval_finite), 2L * nrow(finite) + nrow(partial))
  expect_equal(unique(artifact$profile_ready), TRUE)

  qseries_status <- qseries[qseries$cell_id %in% status$cell_id, , drop = FALSE]
  expect_equal(nrow(qseries_status), 1L)
  expect_equal(qseries_status$bridge_status, "fixture_parity")
  expect_equal(qseries_status$interval_status, "planned")
  expect_equal(qseries_status$coverage_status, "planned")
  expect_equal(qseries_status$denominator_policy, "fixture_not_coverage")
})

test_that("spatial mu x endpoint-profile geometry identifies lower-side failures", {
  geometry <- structured_re_read_dashboard_tsv(
    "structured-re-spatial-mu-profile-geometry.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-spatial-mu-profile-geometry",
      "structured-re-spatial-mu-profile-geometry-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    geometry,
    c(
      "geometry_id",
      "cell_id",
      "design_id",
      "seed",
      "n_each",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "source_artifact",
      "source_diagnostic",
      "intended_sd_mu_intercept",
      "intended_sd_mu_x",
      "intended_sd_sigma_intercept",
      "intended_sd_sigma_x",
      "realized_sd_mu_intercept",
      "realized_sd_mu_x",
      "realized_sd_sigma_intercept",
      "realized_sd_sigma_x",
      "estimate",
      "profile_ready",
      "profile_side",
      "side_status",
      "side_message",
      "side_warnings",
      "theta_hat",
      "curvature_se",
      "initial_step",
      "step_source",
      "theta",
      "endpoint",
      "root_error",
      "n_eval",
      "bracket_step",
      "n_bracket_step",
      "fit_convergence",
      "n_pdhess",
      "logLik",
      "diagnostic_status",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(geometry), 12L)
  expect_equal(nrow(artifact), 12L)
  expect_equal(geometry, artifact)
  expect_setequal(
    geometry$design_id,
    c(
      "smoke_seed102",
      "strong_seed202",
      "strong_seed102",
      "strong_seed302",
      "strong_n50_seed202",
      "mu_dominant_seed202"
    )
  )
  expect_setequal(geometry$profile_side, c("lower", "upper"))
  expect_equal(geometry$structured_type, rep("spatial", 12L))
  expect_equal(geometry$endpoint_member, rep("mu:x", 12L))
  expect_equal(geometry$direct_sd_target, rep("sd_mu_x", 12L))
  expect_equal(geometry$profile_ready, rep(TRUE, 12L))
  expect_equal(geometry$fit_convergence, rep(0L, 12L))
  expect_equal(geometry$n_pdhess, rep(1L, 12L))
  expect_equal(geometry$interval_claim_status, rep("diagnostic_only", 12L))
  expect_equal(geometry$status, rep("covered", 12L))

  upper <- geometry[geometry$profile_side == "upper", , drop = FALSE]
  expect_equal(nrow(upper), 6L)
  expect_equal(upper$side_status, rep("ok", 6L))
  expect_equal(upper$diagnostic_status, rep("side_profile_ok", 6L))
  expect_equal(all(is.finite(upper$endpoint)), TRUE)
  expect_equal(all(upper$endpoint > 0), TRUE)

  lower_errors <- geometry[
    geometry$diagnostic_status == "lower_endpoint_optimizer_error",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(lower_errors), 3L)
  expect_equal(
    lower_errors$design_id,
    c("strong_seed202", "strong_n50_seed202", "mu_dominant_seed202")
  )
  expect_equal(lower_errors$profile_side, rep("lower", 3L))
  expect_equal(lower_errors$side_status, rep("error", 3L))
  expect_equal(
    lower_errors$side_message,
    rep("NA/NaN gradient evaluation", 3L)
  )
  structured_re_expect_all_match(
    lower_errors$side_warnings,
    "NA/NaN function evaluation"
  )
  expect_equal(lower_errors$theta, rep(NA_real_, 3L))
  expect_equal(lower_errors$endpoint, rep(NA_real_, 3L))
  expect_equal(lower_errors$n_eval, rep(NA_integer_, 3L))

  ok_sides <- geometry[
    geometry$diagnostic_status == "side_profile_ok",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(ok_sides), 9L)
  expect_equal(ok_sides$side_status, rep("ok", 9L))
  expect_equal(all(is.finite(ok_sides$root_error)), TRUE)
  expect_equal(all(ok_sides$root_error < 1e-3), TRUE)

  structured_re_expect_all_match(
    geometry$claim_boundary,
    "endpoint-profile geometry diagnostic only"
  )
  structured_re_expect_all_match(
    geometry$claim_boundary,
    "range-estimating spatial support"
  )
  structured_re_expect_all_match(
    geometry$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(geometry$claim_boundary, "interval coverage")
  structured_re_expect_all_match(geometry$claim_boundary, "REML")
  structured_re_expect_all_match(geometry$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    geometry$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(geometry$claim_boundary, "public support")

  qseries_status <- qseries[
    qseries$cell_id %in% geometry$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 1L)
  expect_equal(qseries_status$bridge_status, "fixture_parity")
  expect_equal(qseries_status$interval_status, "planned")
  expect_equal(qseries_status$coverage_status, "planned")
  expect_equal(qseries_status$denominator_policy, "fixture_not_coverage")
})

test_that("spatial mu x profile strategy confirms fallback is not enough", {
  strategy <- structured_re_read_dashboard_tsv(
    "structured-re-spatial-mu-profile-strategy.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-spatial-mu-profile-strategy",
      "structured-re-spatial-mu-profile-strategy-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    strategy,
    c(
      "strategy_id",
      "cell_id",
      "design_id",
      "requested_engine",
      "effective_engine",
      "seed",
      "n_each",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "source_artifact",
      "source_geometry",
      "intended_sd_mu_intercept",
      "intended_sd_mu_x",
      "intended_sd_sigma_intercept",
      "intended_sd_sigma_x",
      "realized_sd_mu_intercept",
      "realized_sd_mu_x",
      "realized_sd_sigma_intercept",
      "realized_sd_sigma_x",
      "estimate",
      "profile_ready",
      "method_status",
      "interval_finite",
      "lower",
      "upper",
      "conf_status",
      "method_message",
      "method_warnings",
      "strategy_status",
      "interval_claim_status",
      "denominator_admission",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(strategy), 12L)
  expect_equal(strategy, artifact)
  expect_setequal(
    strategy$design_id,
    c(
      "smoke_seed102",
      "strong_seed202",
      "strong_n50_seed202",
      "mu_dominant_seed202"
    )
  )
  expect_setequal(
    strategy$requested_engine,
    c("endpoint", "auto", "tmbprofile")
  )
  expect_equal(strategy$structured_type, rep("spatial", 12L))
  expect_equal(strategy$endpoint_member, rep("mu:x", 12L))
  expect_equal(strategy$direct_sd_target, rep("sd_mu_x", 12L))
  expect_equal(strategy$profile_ready, rep(TRUE, 12L))
  expect_equal(strategy$denominator_admission, rep("not_admitted", 12L))
  expect_equal(strategy$interval_claim_status, rep("diagnostic_only", 12L))
  expect_equal(strategy$status, rep("covered", 12L))

  finite <- strategy[
    strategy$strategy_status == "finite_control",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(finite), 3L)
  expect_equal(finite$design_id, rep("smoke_seed102", 3L))
  expect_equal(finite$method_status, rep("finite", 3L))
  expect_equal(finite$interval_finite, rep(TRUE, 3L))
  expect_equal(finite$conf_status, rep("profile", 3L))
  expect_equal(finite$method_message, rep("ok", 3L))
  expect_equal(
    paste(finite$requested_engine, finite$effective_engine, sep = "::"),
    c("endpoint::endpoint", "auto::endpoint", "tmbprofile::tmbprofile")
  )
  expect_equal(all(is.finite(finite$lower)), TRUE)
  expect_equal(all(is.finite(finite$upper)), TRUE)
  expect_equal(all(finite$lower > 0), TRUE)
  expect_equal(all(finite$upper > finite$lower), TRUE)

  nonfinite <- strategy[
    strategy$strategy_status != "finite_control",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(nonfinite), 9L)
  expect_equal(nonfinite$method_status, rep("nonfinite", 9L))
  expect_equal(nonfinite$interval_finite, rep(FALSE, 9L))
  expect_equal(nonfinite$conf_status, rep("profile_failed", 9L))
  expect_equal(nonfinite$lower, rep(NA_real_, 9L))
  expect_equal(nonfinite$upper, rep(NA_real_, 9L))
  endpoint_rows <- nonfinite[
    nonfinite$requested_engine == "endpoint",
    ,
    drop = FALSE
  ]
  fallback_rows <- nonfinite[
    nonfinite$requested_engine %in% c("auto", "tmbprofile"),
    ,
    drop = FALSE
  ]
  expect_equal(
    endpoint_rows$method_message,
    rep("NA/NaN gradient evaluation", 3L)
  )
  expect_equal(fallback_rows$method_message, rep("nonfinite_interval", 6L))
  expect_equal(
    endpoint_rows$effective_engine,
    rep("endpoint", 3L)
  )
  expect_equal(fallback_rows$effective_engine, rep("tmbprofile", 6L))

  boundary <- nonfinite[
    nonfinite$design_id == "strong_seed202",
    ,
    drop = FALSE
  ]
  lower_side <- nonfinite[
    nonfinite$design_id %in% c("strong_n50_seed202", "mu_dominant_seed202"),
    ,
    drop = FALSE
  ]
  expect_equal(boundary$strategy_status, rep("boundary_not_rescued", 3L))
  expect_equal(lower_side$strategy_status, rep("lower_side_not_rescued", 6L))

  structured_re_expect_all_match(
    strategy$claim_boundary,
    "profile-strategy diagnostic only"
  )
  structured_re_expect_all_match(
    strategy$claim_boundary,
    "range-estimating spatial support"
  )
  structured_re_expect_all_match(
    strategy$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(strategy$claim_boundary, "interval coverage")
  structured_re_expect_all_match(strategy$claim_boundary, "REML")
  structured_re_expect_all_match(strategy$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    strategy$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(strategy$claim_boundary, "public support")
  structured_re_expect_all_match(
    strategy$claim_boundary,
    "coverage denominator admission"
  )

  qseries_status <- qseries[
    qseries$cell_id %in% strategy$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 1L)
  expect_equal(qseries_status$bridge_status, "fixture_parity")
  expect_equal(qseries_status$interval_status, "planned")
  expect_equal(qseries_status$coverage_status, "planned")
  expect_equal(qseries_status$denominator_policy, "fixture_not_coverage")
})

test_that("spatial mu x lower-start diagnostic keeps problem rows out of denominators", {
  lower_start <- structured_re_read_dashboard_tsv(
    "structured-re-spatial-mu-lower-start-diagnostic.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-spatial-mu-lower-start-diagnostic",
      "structured-re-spatial-mu-lower-start-diagnostic-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    lower_start,
    c(
      "diagnostic_id",
      "cell_id",
      "design_id",
      "strategy",
      "start_mode",
      "step_rule",
      "optimizer_eval_max",
      "optimizer_iter_max",
      "seed",
      "n_each",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "profile_side",
      "source_artifact",
      "source_geometry",
      "source_strategy",
      "intended_sd_mu_intercept",
      "intended_sd_mu_x",
      "intended_sd_sigma_intercept",
      "intended_sd_sigma_x",
      "realized_sd_mu_intercept",
      "realized_sd_mu_x",
      "realized_sd_sigma_intercept",
      "realized_sd_sigma_x",
      "estimate",
      "profile_ready",
      "theta_hat",
      "curvature_se",
      "cutoff",
      "initial_step",
      "step_source",
      "theta",
      "endpoint",
      "root_error",
      "n_eval",
      "bracket_step",
      "n_bracket_step",
      "side_status",
      "side_message",
      "side_warnings",
      "fit_convergence",
      "n_pdhess",
      "diagnostic_status",
      "interval_claim_status",
      "denominator_admission",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(lower_start), 16L)
  expect_equal(lower_start, artifact)
  expect_setequal(
    lower_start$design_id,
    c(
      "smoke_seed102",
      "strong_seed202",
      "strong_n50_seed202",
      "mu_dominant_seed202"
    )
  )
  expect_setequal(
    lower_start$strategy,
    c(
      "baseline_warm_curvature",
      "reset_curvature",
      "reset_capped_step1",
      "reset_fixed_step025"
    )
  )
  expect_equal(lower_start$structured_type, rep("spatial", 16L))
  expect_equal(lower_start$endpoint_member, rep("mu:x", 16L))
  expect_equal(lower_start$profile_side, rep("lower", 16L))
  expect_equal(lower_start$direct_sd_target, rep("sd_mu_x", 16L))
  expect_equal(lower_start$profile_ready, rep(TRUE, 16L))
  expect_equal(lower_start$fit_convergence, rep(0L, 16L))
  expect_equal(lower_start$n_pdhess, rep(1L, 16L))
  expect_equal(lower_start$denominator_admission, rep("not_admitted", 16L))
  expect_equal(lower_start$interval_claim_status, rep("diagnostic_only", 16L))
  expect_equal(lower_start$status, rep("covered", 16L))

  finite <- lower_start[
    lower_start$diagnostic_status == "finite_control",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(finite), 4L)
  expect_equal(finite$design_id, rep("smoke_seed102", 4L))
  expect_equal(finite$side_status, rep("ok", 4L))
  expect_equal(finite$side_message, rep("ok", 4L))
  expect_equal(all(is.finite(finite$endpoint)), TRUE)
  expect_equal(all(finite$endpoint > 0), TRUE)
  expect_equal(all(is.finite(finite$root_error)), TRUE)
  expect_equal(all(finite$root_error < 1e-3), TRUE)

  boundary <- lower_start[
    lower_start$diagnostic_status == "boundary_not_rescued",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(boundary), 4L)
  expect_equal(boundary$design_id, rep("strong_seed202", 4L))
  expect_equal(boundary$side_status, rep("error", 4L))
  expect_equal(
    boundary$side_message,
    rep("NA/NaN gradient evaluation", 4L)
  )
  expect_equal(boundary$endpoint, rep(NA_real_, 4L))

  not_rescued <- lower_start[
    lower_start$diagnostic_status == "lower_side_not_rescued",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(not_rescued), 8L)
  expect_setequal(
    not_rescued$design_id,
    c("strong_n50_seed202", "mu_dominant_seed202")
  )
  expect_equal(not_rescued$side_status, rep("error", 8L))
  expect_equal(
    not_rescued$side_message,
    rep("NA/NaN gradient evaluation", 8L)
  )
  expect_equal(not_rescued$endpoint, rep(NA_real_, 8L))

  strategy_map <- unique(
    lower_start[c("strategy", "start_mode", "step_rule", "step_source")]
  )
  strategy_map <- strategy_map[order(strategy_map$strategy), ]
  row.names(strategy_map) <- NULL
  expect_equal(nrow(strategy_map), 4L)
  expect_equal(
    strategy_map,
    data.frame(
      strategy = c(
        "baseline_warm_curvature",
        "reset_capped_step1",
        "reset_curvature",
        "reset_fixed_step025"
      ),
      start_mode = c("warm", "reset", "reset", "reset"),
      step_rule = c("curvature", "capped_1", "curvature", "fixed_025"),
      step_source = c(
        "curvature",
        "curvature_capped_1",
        "curvature",
        "fixed_025"
      ),
      stringsAsFactors = FALSE
    )
  )

  structured_re_expect_all_match(
    lower_start$claim_boundary,
    "lower-side start diagnostic only"
  )
  structured_re_expect_all_match(
    lower_start$claim_boundary,
    "range-estimating spatial support"
  )
  structured_re_expect_all_match(
    lower_start$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(
    lower_start$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(lower_start$claim_boundary, "REML")
  structured_re_expect_all_match(lower_start$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    lower_start$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(lower_start$claim_boundary, "public support")
  structured_re_expect_all_match(
    lower_start$claim_boundary,
    "coverage denominator admission"
  )

  qseries_status <- qseries[
    qseries$cell_id %in% lower_start$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 1L)
  expect_equal(qseries_status$bridge_status, "fixture_parity")
  expect_equal(qseries_status$interval_status, "planned")
  expect_equal(qseries_status$coverage_status, "planned")
  expect_equal(qseries_status$denominator_policy, "fixture_not_coverage")
})

test_that("spatial mu x domain-guard diagnostic keeps problem rows out of denominators", {
  domain_guard <- structured_re_read_dashboard_tsv(
    "structured-re-spatial-mu-domain-guard-diagnostic.tsv"
  )
  qseries <- structured_re_read_dashboard_tsv(
    "structured-re-q-series-support-cells.tsv"
  )
  artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-spatial-mu-domain-guard-diagnostic",
      "structured-re-spatial-mu-domain-guard-diagnostic-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(
    domain_guard,
    c(
      "diagnostic_id",
      "cell_id",
      "design_id",
      "seed",
      "n_each",
      "formula_cell",
      "structured_type",
      "target_kind",
      "endpoint_member",
      "direct_sd_target",
      "profile_target",
      "profile_side",
      "source_artifact",
      "source_lower_start",
      "domain_offsets",
      "n_domain_offsets",
      "n_fixed_objective_finite",
      "n_fixed_gradient_finite",
      "n_fixed_gradient_bad_total",
      "intended_sd_mu_intercept",
      "intended_sd_mu_x",
      "intended_sd_sigma_intercept",
      "intended_sd_sigma_x",
      "realized_sd_mu_intercept",
      "realized_sd_mu_x",
      "realized_sd_sigma_intercept",
      "realized_sd_sigma_x",
      "estimate",
      "theta_hat",
      "profile_ready",
      "guarded_initial_step",
      "fn_penalty_status",
      "fn_penalty_endpoint",
      "fn_penalty_root_error",
      "fn_penalty_n_eval",
      "fn_penalty_message",
      "zero_gr_penalty_status",
      "zero_gr_penalty_endpoint",
      "zero_gr_penalty_root_error",
      "zero_gr_penalty_n_eval",
      "zero_gr_penalty_message",
      "diagnostic_status",
      "interval_claim_status",
      "denominator_admission",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(domain_guard), 4L)
  expect_equal(domain_guard, artifact)
  expect_setequal(
    domain_guard$design_id,
    c(
      "smoke_seed102",
      "strong_seed202",
      "strong_n50_seed202",
      "mu_dominant_seed202"
    )
  )
  expect_equal(
    domain_guard$cell_id,
    rep(
      "qseries_spatial_q1_mu_sigma_one_slope",
      4L
    )
  )
  expect_equal(domain_guard$structured_type, rep("spatial", 4L))
  expect_equal(domain_guard$target_kind, rep("direct_sd", 4L))
  expect_equal(domain_guard$endpoint_member, rep("mu:x", 4L))
  expect_equal(domain_guard$direct_sd_target, rep("sd_mu_x", 4L))
  expect_equal(
    domain_guard$profile_target,
    rep("sd:mu:mu:spatial(0 + x | site)", 4L)
  )
  expect_equal(domain_guard$profile_side, rep("lower", 4L))
  expect_equal(
    domain_guard$domain_offsets,
    rep(
      "0;-0.001;-0.01;-0.05;-0.1;-0.25;-0.5;-1;-3",
      4L
    )
  )
  expect_equal(domain_guard$n_domain_offsets, rep(9L, 4L))
  expect_equal(domain_guard$n_fixed_objective_finite, rep(9L, 4L))
  expect_equal(domain_guard$n_fixed_gradient_finite, rep(9L, 4L))
  expect_equal(domain_guard$n_fixed_gradient_bad_total, rep(0L, 4L))
  expect_equal(domain_guard$profile_ready, rep(TRUE, 4L))
  expect_equal(domain_guard$guarded_initial_step, rep(0.25, 4L))
  expect_equal(domain_guard$denominator_admission, rep("not_admitted", 4L))
  expect_equal(domain_guard$interval_claim_status, rep("diagnostic_only", 4L))
  expect_equal(domain_guard$status, rep("covered", 4L))

  for (path in unique(c(
    domain_guard$source_artifact,
    domain_guard$source_lower_start,
    domain_guard$evidence_url
  ))) {
    expect_true(file.exists(structured_re_artifact_path(path)))
  }

  finite <- domain_guard[
    domain_guard$diagnostic_status == "finite_control",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(finite), 1L)
  expect_equal(finite$design_id, "smoke_seed102")
  expect_equal(finite$fn_penalty_status, "finite")
  expect_equal(finite$zero_gr_penalty_status, "finite")
  expect_equal(finite$fn_penalty_message, "ok")
  expect_equal(finite$zero_gr_penalty_message, "ok")
  expect_true(is.finite(finite$fn_penalty_endpoint))
  expect_true(is.finite(finite$zero_gr_penalty_endpoint))
  expect_true(finite$fn_penalty_endpoint > 0)
  expect_true(finite$zero_gr_penalty_endpoint > 0)
  expect_true(is.finite(finite$fn_penalty_root_error))
  expect_true(is.finite(finite$zero_gr_penalty_root_error))
  expect_true(finite$fn_penalty_root_error < 1e-3)
  expect_true(finite$zero_gr_penalty_root_error < 1e-3)

  problem <- domain_guard[
    domain_guard$diagnostic_status != "finite_control",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(problem), 3L)
  expect_equal(problem$fn_penalty_status, rep("nonfinite", 3L))
  expect_equal(problem$zero_gr_penalty_status, rep("nonfinite", 3L))
  expect_equal(
    problem$fn_penalty_message,
    rep("both X-convergence and relative convergence (5)", 3L)
  )
  expect_equal(
    problem$zero_gr_penalty_message,
    rep("both X-convergence and relative convergence (5)", 3L)
  )
  expect_equal(problem$fn_penalty_endpoint, rep(NA_real_, 3L))
  expect_equal(problem$zero_gr_penalty_endpoint, rep(NA_real_, 3L))
  expect_equal(problem$fn_penalty_root_error, rep(NA_real_, 3L))
  expect_equal(problem$zero_gr_penalty_root_error, rep(NA_real_, 3L))
  expect_equal(problem$fn_penalty_n_eval, rep(NA_integer_, 3L))
  expect_equal(problem$zero_gr_penalty_n_eval, rep(NA_integer_, 3L))
  expect_equal(
    problem$diagnostic_status[problem$design_id == "strong_seed202"],
    "optimizer_path_boundary_not_rescued"
  )
  expect_equal(
    problem$diagnostic_status[
      problem$design_id %in% c("strong_n50_seed202", "mu_dominant_seed202")
    ],
    rep("optimizer_path_lower_not_rescued", 2L)
  )

  structured_re_expect_all_match(
    domain_guard$claim_boundary,
    "domain-guard diagnostic only"
  )
  structured_re_expect_all_match(
    domain_guard$claim_boundary,
    "range-estimating spatial support"
  )
  structured_re_expect_all_match(
    domain_guard$claim_boundary,
    "no interval reliability"
  )
  structured_re_expect_all_match(
    domain_guard$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(domain_guard$claim_boundary, "REML")
  structured_re_expect_all_match(domain_guard$claim_boundary, "AI-REML")
  structured_re_expect_all_match(
    domain_guard$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(domain_guard$claim_boundary, "public support")
  structured_re_expect_all_match(
    domain_guard$claim_boundary,
    "coverage denominator admission"
  )

  qseries_status <- qseries[
    qseries$cell_id %in% domain_guard$cell_id,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(qseries_status), 1L)
  expect_equal(qseries_status$bridge_status, "fixture_parity")
  expect_equal(qseries_status$interval_status, "planned")
  expect_equal(qseries_status$coverage_status, "planned")
  expect_equal(qseries_status$denominator_policy, "fixture_not_coverage")
})

test_that("q4 two-shard aggregator rejects unsafe shard evidence", {
  shard_source <- structured_re_artifact_path(
    "docs",
    "dev-log",
    "simulation-artifacts",
    "2026-06-23-q4-stabilized-preflight",
    "q4-derived-correlation-delta-grid-two-shard-rehearsal"
  )
  aggregator <- structured_re_artifact_path(
    "docs",
    "dev-log",
    "simulation-artifacts",
    "2026-06-23-q4-stabilized-preflight",
    "aggregate-calibrated-grid-delta-shards.R"
  )
  repo_root <- dirname(structured_re_artifact_path("DESCRIPTION"))

  local_shard_root <- function() {
    root <- tempfile("q4-two-shard-")
    dir.create(root, recursive = TRUE)
    ok <- file.copy(
      file.path(shard_source, c("shard_01", "shard_02")),
      root,
      recursive = TRUE
    )
    expect_true(all(ok))
    root
  }

  run_aggregator <- function(
    root,
    n_shards = 2L,
    expected_cells = 4L,
    expected_target_rows = 24L,
    ...
  ) {
    command <- paste(
      shQuote(file.path(R.home("bin"), "Rscript")),
      paste(
        c(
          "--vanilla",
          shQuote(aggregator),
          shQuote(paste0("--repo-root=", repo_root)),
          shQuote(paste0("--shard-root=", root)),
          paste0("--n-shards=", n_shards),
          paste0("--expected-cells=", expected_cells),
          paste0("--expected-target-rows=", expected_target_rows),
          "--aggregate-label=test_negative_path",
          ...
        ),
        collapse = " "
      ),
      "2>&1"
    )
    output <- suppressWarnings(system(
      command,
      intern = TRUE
    ))
    status <- attr(output, "status", exact = TRUE)
    list(status = if (is.null(status)) 0L else status, output = output)
  }

  missing_root <- local_shard_root()
  on.exit(unlink(missing_root, recursive = TRUE), add = TRUE)
  unlink(file.path(missing_root, "shard_02"), recursive = TRUE)
  missing <- run_aggregator(missing_root)
  expect_false(identical(missing$status, 0L))
  expect_true(any(grepl(
    "Missing shard manifests",
    missing$output,
    fixed = TRUE
  )))

  mismatch_root <- local_shard_root()
  on.exit(unlink(mismatch_root, recursive = TRUE), add = TRUE)
  mismatch <- run_aggregator(mismatch_root, expected_cells = 5L)
  expect_false(identical(mismatch$status, 0L))
  mismatch_manifest <- utils::read.delim(
    file.path(
      mismatch_root,
      "aggregate",
      "q4-derived-correlation-delta-grid-test_negative_path-aggregate-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  expect_equal(mismatch_manifest$aggregate_status, "aggregate_count_mismatch")

  missing_cell_root <- local_shard_root()
  on.exit(unlink(missing_cell_root, recursive = TRUE), add = TRUE)
  manifest_path <- file.path(
    missing_cell_root,
    "shard_01",
    "q4-derived-correlation-delta-grid-shard_01-manifest.tsv"
  )
  manifest <- utils::read.delim(
    manifest_path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  cell_outputs <- strsplit(manifest$cell_outputs[[1]], ";", fixed = TRUE)[[1]]
  cell_outputs[[
    1
  ]] <- "docs/dev-log/simulation-artifacts/missing-cell-output.tsv"
  manifest$cell_outputs[[1]] <- paste(cell_outputs, collapse = ";")
  utils::write.table(
    manifest,
    file = manifest_path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = ""
  )
  missing_cell <- run_aggregator(missing_cell_root)
  expect_false(identical(missing_cell$status, 0L))
  expect_true(any(grepl(
    "Missing cell output files",
    missing_cell$output,
    fixed = TRUE
  )))

  duplicate_root <- local_shard_root()
  on.exit(unlink(duplicate_root, recursive = TRUE), add = TRUE)
  shard_01_log_path <- file.path(
    duplicate_root,
    "shard_01",
    "q4-derived-correlation-delta-grid-shard_01-run-log.tsv"
  )
  shard_02_log_path <- file.path(
    duplicate_root,
    "shard_02",
    "q4-derived-correlation-delta-grid-shard_02-run-log.tsv"
  )
  shard_01_log <- utils::read.delim(
    shard_01_log_path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  shard_02_log <- utils::read.delim(
    shard_02_log_path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  first_cell <- shard_01_log$cell_id[shard_01_log$action == "computed"][[1]]
  shard_02_log$cell_id[shard_02_log$action == "computed"][[1]] <- first_cell
  utils::write.table(
    shard_02_log,
    file = shard_02_log_path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = ""
  )
  duplicate <- run_aggregator(duplicate_root)
  expect_false(identical(duplicate$status, 0L))
  duplicate_manifest <- utils::read.delim(
    file.path(
      duplicate_root,
      "aggregate",
      "q4-derived-correlation-delta-grid-test_negative_path-aggregate-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  expect_equal(
    duplicate_manifest$aggregate_status,
    "aggregate_duplicate_cell_ids"
  )
})

test_that("q1 bridge payload contract keeps provenance and support bounded", {
  payload <- structured_re_read_dashboard_tsv(
    "structured-re-q1-bridge-payload-contract.tsv"
  )

  expect_named(
    payload,
    c(
      "contract_id",
      "target",
      "route",
      "estimator",
      "required_payload_fields",
      "required_provenance",
      "unsupported_fields",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  structured_re_expect_all_match(payload$required_payload_fields, "matrix_id")
  structured_re_expect_all_match(
    payload$required_payload_fields,
    "matrix_digest"
  )
  structured_re_expect_all_match(payload$required_provenance, "versions")
  structured_re_expect_all_match(payload$required_provenance, "dirty_flags")
  structured_re_expect_all_match(payload$unsupported_fields, "coverage_payload")
  expect_equal(payload$bridge_status, rep("planned", nrow(payload)))

  loconly <- payload[
    payload$contract_id == "q1_exact_gaussian_loconly_reml_payload",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(loconly), 1L)
  expect_equal(loconly$estimator, "REML")
  expect_match(loconly$claim_boundary, "not HSquared AI-REML", fixed = TRUE)
  expect_match(loconly$unsupported_fields, "q4_reml_payload", fixed = TRUE)

  count <- payload[payload$target == "count_q1_mu_structured", , drop = FALSE]
  expect_equal(nrow(count), 1L)
  expect_equal(count$estimator, "ML")
  expect_match(count$claim_boundary, "no non-Gaussian REML claim", fixed = TRUE)
})

test_that("q1 reconstruction and parity ledgers keep unavailable routes explicit", {
  maps <- structured_re_read_dashboard_tsv(
    "structured-re-q1-reconstruction-map.tsv"
  )
  parity <- structured_re_read_dashboard_tsv(
    "structured-re-q1-parity-fixture-contract.tsv"
  )

  corpairs <- maps[maps$map_id == "q1_corpairs_unavailable_map", , drop = FALSE]
  expect_equal(nrow(corpairs), 1L)
  expect_equal(corpairs$bridge_status, "unsupported")
  expect_equal(corpairs$unavailable_status, "not_applicable")
  expect_match(corpairs$claim_boundary, "no bivariate corpair", fixed = TRUE)

  vcov_map <- maps[maps$extractor == "vcov", , drop = FALSE]
  expect_equal(nrow(vcov_map), 1L)
  expect_match(vcov_map$claim_boundary, "no interval or coverage", fixed = TRUE)

  fixed_scale <- maps[
    maps$map_id == "q1_fixed_coef_link_scale_map",
    ,
    drop = FALSE
  ]
  sd_scale <- maps[
    maps$map_id == "q1_structured_sd_response_scale_map",
    ,
    drop = FALSE
  ]
  recov <- maps[
    maps$map_id == "q1_phylo_mu_sigma_recov_map",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(fixed_scale), 1L)
  expect_equal(nrow(sd_scale), 1L)
  expect_equal(nrow(recov), 1L)
  expect_equal(fixed_scale$extractor, "coef")
  expect_equal(sd_scale$extractor, "summary")
  expect_equal(recov$extractor, "summary")
  expect_match(fixed_scale$reconstruction_output, "link-scale", fixed = TRUE)
  expect_match(sd_scale$reconstruction_output, "response-scale", fixed = TRUE)
  expect_match(recov$reconstruction_output, "Cholesky", fixed = TRUE)
  expect_match(fixed_scale$claim_boundary, "exclude resd/recov", fixed = TRUE)
  expect_match(sd_scale$claim_boundary, "response scale", fixed = TRUE)
  expect_match(recov$claim_boundary, "q1 Gaussian mu+sigma", fixed = TRUE)

  expect_true(all(parity$r_via_julia_path != "planned"))
  expect_true(all(parity$bridge_status %in% c("experimental", "planned")))
  expect_true(any(parity$bridge_status == "experimental"))
  expect_true(all(parity$status %in% c("covered", "planned")))
  expect_true(all(nchar(parity$claim_boundary) > 0))
  expect_true(any(grepl(
    "remain separate",
    parity$claim_boundary,
    fixed = TRUE
  )))
  expect_true(any(grepl("REML", parity$claim_boundary, fixed = TRUE)))
  expect_equal(nchar(parity$next_gate) > 0, rep(TRUE, nrow(parity)))
  expect_true(any(grepl("coverage", parity$next_gate, fixed = TRUE)))
  expect_true(any(grepl("NB2", parity$next_gate, fixed = TRUE)))

  provider_scale <- parity[
    parity$target %in%
      c(
        "gaussian_q1_sigma_spatial",
        "gaussian_q1_mu_sigma_spatial",
        "gaussian_q1_sigma_animal",
        "gaussian_q1_mu_sigma_animal",
        "gaussian_q1_sigma_relmat",
        "gaussian_q1_mu_sigma_relmat"
      ),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(provider_scale), 6L)
  expect_equal(provider_scale$status, rep("covered", 6L))
  expect_equal(provider_scale$bridge_status, rep("experimental", 6L))
  structured_re_expect_all_match(
    provider_scale$claim_boundary,
    "remain separate"
  )

  spatial_scale <- provider_scale[
    grepl("spatial", provider_scale$target, fixed = TRUE),
    ,
    drop = FALSE
  ]
  animal_scale <- provider_scale[
    grepl("animal", provider_scale$target, fixed = TRUE),
    ,
    drop = FALSE
  ]
  relmat_scale <- provider_scale[
    grepl("relmat", provider_scale$target, fixed = TRUE),
    ,
    drop = FALSE
  ]
  structured_re_expect_all_match(
    spatial_scale$claim_boundary,
    "fixed-covariance"
  )
  structured_re_expect_all_match(
    spatial_scale$claim_boundary,
    "range-estimating"
  )
  structured_re_expect_all_match(animal_scale$claim_boundary, "A-matrix")
  structured_re_expect_all_match(animal_scale$claim_boundary, "pedigree")
  structured_re_expect_all_match(relmat_scale$claim_boundary, "K-matrix")
  structured_re_expect_all_match(
    relmat_scale$claim_boundary,
    "Q bridge marshalling"
  )
})

test_that("q1 parity acceptance gate ties fixtures, maps, and negative evidence", {
  finish <- structured_re_read_dashboard_tsv(
    "structured-re-finish-100-slices.tsv"
  )
  parity <- structured_re_read_dashboard_tsv(
    "structured-re-q1-parity-fixture-contract.tsv"
  )
  maps <- structured_re_read_dashboard_tsv(
    "structured-re-q1-reconstruction-map.tsv"
  )
  evidence <- structured_re_read_dashboard_tsv(
    "structured-re-executable-evidence.tsv"
  )
  closeout <- structured_re_read_dashboard_tsv(
    "structured-re-closeout-package.tsv"
  )

  banked_q1 <- parity[
    parity$status == "covered" & parity$bridge_status == "experimental",
    ,
    drop = FALSE
  ]
  expect_true(nrow(banked_q1) >= 13L)
  expect_true(all(grepl("coef", banked_q1$parity_quantity, fixed = TRUE)))
  expect_true(all(grepl("logLik", banked_q1$parity_quantity, fixed = TRUE)))
  expect_true(all(nzchar(banked_q1$tolerance)))
  expect_true(all(banked_q1$r_via_julia_path != "planned"))
  expect_setequal(
    c(
      "gaussian_q1_mu_relmat",
      "gaussian_q1_sigma_spatial",
      "gaussian_q1_mu_sigma_spatial",
      "gaussian_q1_sigma_animal",
      "gaussian_q1_mu_sigma_animal",
      "gaussian_q1_sigma_relmat",
      "gaussian_q1_mu_sigma_relmat"
    ),
    intersect(
      c(
        "gaussian_q1_mu_relmat",
        "gaussian_q1_sigma_spatial",
        "gaussian_q1_mu_sigma_spatial",
        "gaussian_q1_sigma_animal",
        "gaussian_q1_mu_sigma_animal",
        "gaussian_q1_sigma_relmat",
        "gaussian_q1_mu_sigma_relmat"
      ),
      banked_q1$target
    )
  )

  expect_setequal(
    c(
      "q1_fixed_coef_link_scale_map",
      "q1_structured_sd_response_scale_map",
      "q1_phylo_mu_sigma_recov_map"
    ),
    intersect(
      c(
        "q1_fixed_coef_link_scale_map",
        "q1_structured_sd_response_scale_map",
        "q1_phylo_mu_sigma_recov_map"
      ),
      maps$map_id
    )
  )
  expect_true("q1_unsupported_route_preflight_tests" %in% evidence$evidence_id)
  expect_true("q1_coefficient_scale_map_tests" %in% evidence$evidence_id)
  expect_true("q1_parity_acceptance_gate_tests" %in% evidence$evidence_id)

  gate <- closeout[
    closeout$closeout_id == "q1_parity_acceptance_gate",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(gate), 1L)
  expect_equal(gate$status, "covered")
  expect_match(gate$claim_boundary, "not broad bridge support", fixed = TRUE)

  sr120 <- finish[finish$slice_id == "SR120", , drop = FALSE]
  expect_equal(nrow(sr120), 1L)
  expect_equal(sr120$status, "banked")
  expect_equal(sr120$bridge_status, "experimental")
  expect_match(sr120$claim_boundary, "not broad bridge support", fixed = TRUE)
})

test_that("q2 contracts separate q2, q2-plus-q2, q4, and REML", {
  targets <- structured_re_read_dashboard_tsv(
    "structured-re-q2-target-contract.tsv"
  )
  native <- structured_re_read_dashboard_tsv(
    "structured-re-q2-native-evidence.tsv"
  )
  boundary <- structured_re_read_dashboard_tsv(
    "structured-re-q2-bridge-boundary.tsv"
  )
  payload <- structured_re_read_dashboard_tsv(
    "structured-re-q2-payload-contract.tsv"
  )
  provenance <- structured_re_read_dashboard_tsv(
    "structured-re-q2-payload-provenance.tsv"
  )
  acceptance <- structured_re_read_dashboard_tsv(
    "structured-re-q2-acceptance-gate.tsv"
  )
  order_map <- structured_re_read_dashboard_tsv(
    "structured-re-q2-coefficient-order-map.tsv"
  )
  direct_q2 <- structured_re_read_dashboard_tsv(
    "structured-re-q2-direct-drmjl-export.tsv"
  )

  q2_ml <- targets[
    targets$dimension == "q2" & targets$estimator == "ML",
    ,
    drop = FALSE
  ]
  expect_equal(q2_ml$inference_status, rep("point_only", nrow(q2_ml)))
  structured_re_expect_all_match(q2_ml$separated_from, "q4")

  q2_plus <- targets[targets$dimension == "q2_plus_q2", , drop = FALSE]
  expect_equal(nrow(q2_plus), 1L)
  expect_equal(
    q2_plus$evidence_url,
    "docs/dev-log/after-task/2026-06-22-q2-plus-q2-boundary-contract.md"
  )
  expect_match(q2_plus$claim_boundary, "not full q4", fixed = TRUE)
  expect_match(q2_plus$claim_boundary, "bridge support", fixed = TRUE)

  reml <- targets[targets$target_id == "q2_reml_boundary", , drop = FALSE]
  expect_equal(nrow(reml), 1L)
  expect_equal(reml$profile_status, "unsupported")
  expect_equal(reml$bridge_status, "unsupported")
  expect_match(reml$claim_boundary, "not HSquared AI-REML", fixed = TRUE)

  expect_equal(
    native$inference_status[native$estimator == "ML"],
    rep("point_only", sum(native$estimator == "ML"))
  )
  native_reml <- native[native$estimator == "REML", , drop = FALSE]
  expect_equal(nrow(native_reml), 1L)
  expect_equal(native_reml$status, "unsupported")
  expect_match(native_reml$claim_boundary, "unsupported", fixed = TRUE)
  spatial_native <- native[
    native$evidence_id == "q2_spatial_location_ml",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(spatial_native), 1L)
  expect_equal(
    spatial_native$evidence_url,
    "docs/dev-log/after-task/2026-06-22-q2-spatial-native-fixture.md"
  )
  expect_match(spatial_native$claim_boundary, "fixture-level", fixed = TRUE)
  expect_match(spatial_native$claim_boundary, "bridge parity", fixed = TRUE)
  animal_relmat_native <- native[
    native$evidence_id %in% c("q2_animal_location_ml", "q2_relmat_location_ml"),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(animal_relmat_native), 2L)
  expect_equal(
    animal_relmat_native$evidence_url,
    rep(
      "docs/dev-log/after-task/2026-06-22-q2-animal-relmat-native-fixtures.md",
      2L
    )
  )
  expect_match(
    animal_relmat_native$claim_boundary,
    "fixture-level",
    fixed = TRUE
  )
  expect_match(
    animal_relmat_native$claim_boundary,
    "bridge parity",
    fixed = TRUE
  )

  expect_setequal(
    boundary$bridge_status,
    c("experimental", "intentional_error", "planned", "unsupported")
  )
  expect_equal(nchar(boundary$negative_evidence) > 0, rep(TRUE, nrow(boundary)))
  structured_re_expect_all_match(boundary$claim_boundary, "bridge")
  scale_only <- boundary[
    boundary$boundary_id == "q2_scale_only_structured_rejections",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(scale_only), 1L)
  expect_equal(scale_only$bridge_status, "intentional_error")
  expect_equal(
    scale_only$evidence_url,
    "docs/dev-log/after-task/2026-06-22-q2-scale-only-rejection-boundary.md"
  )
  expect_match(scale_only$negative_evidence, "sigma1/sigma2-only", fixed = TRUE)
  expect_match(scale_only$claim_boundary, "not q2 bridge support", fixed = TRUE)

  expect_named(
    payload,
    c(
      "contract_id",
      "target",
      "route",
      "estimator",
      "required_payload_fields",
      "required_provenance",
      "unsupported_fields",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  structured_re_expect_all_match(
    payload$required_payload_fields,
    "matrix_digest"
  )
  structured_re_expect_all_match(payload$required_provenance, "versions")
  structured_re_expect_all_match(payload$unsupported_fields, "q4_payload")
  q2_phylo_payload <- payload[
    payload$contract_id == "q2_phylo_location_payload",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(q2_phylo_payload), 1L)
  expect_equal(q2_phylo_payload$bridge_status, "experimental")
  expect_match(q2_phylo_payload$claim_boundary, "Q2 phylo", fixed = TRUE)
  q2_reml_payload <- payload[
    payload$contract_id == "q2_location_reml_payload_boundary",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(q2_reml_payload), 1L)
  expect_equal(q2_reml_payload$bridge_status, "unsupported")
  expect_match(
    q2_reml_payload$claim_boundary,
    "not HSquared AI-REML",
    fixed = TRUE
  )

  expect_named(
    provenance,
    c(
      "provenance_id",
      "target",
      "structured_type",
      "dimension",
      "route",
      "estimator",
      "payload_version",
      "source_repo",
      "source_branch",
      "source_head",
      "matrix_id",
      "matrix_digest",
      "matrix_slot",
      "input_scale",
      "missing_level_policy",
      "bridge_marshalling",
      "endpoint",
      "required_levels",
      "version_fields",
      "dirty_state_policy",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(provenance), 4L)
  expect_setequal(
    provenance$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(
    provenance$payload_version,
    rep("structured_re_bridge_payload_v1", 4L)
  )
  structured_re_expect_all_match(provenance$source_repo, "DRM.jl")
  structured_re_expect_all_match(
    provenance$source_branch,
    "codex/ai-reml-gaussian-mme-pilot"
  )
  structured_re_expect_all_match(provenance$source_head, "e016fc15b4fb")
  structured_re_expect_all_match(provenance$matrix_digest, "4x4:")
  structured_re_expect_all_match(provenance$required_levels, "matrix_row_names")
  structured_re_expect_all_match(provenance$version_fields, "payload_version")
  structured_re_expect_all_match(
    provenance$dirty_state_policy,
    "not_public_support"
  )
  phylo_provenance <- provenance[
    provenance$structured_type == "phylo",
    ,
    drop = FALSE
  ]
  non_phylo_provenance <- provenance[
    provenance$structured_type != "phylo",
    ,
    drop = FALSE
  ]
  expect_equal(phylo_provenance$bridge_status, "experimental")
  expect_match(
    phylo_provenance$claim_boundary,
    "no broad q2 bridge support",
    fixed = TRUE
  )
  spatial_provenance <- provenance[
    provenance$structured_type == "spatial",
    ,
    drop = FALSE
  ]
  known_provenance <- provenance[
    provenance$structured_type %in% c("animal", "relmat"),
    ,
    drop = FALSE
  ]
  expect_equal(spatial_provenance$bridge_status, "experimental")
  expect_equal(known_provenance$bridge_status, rep("experimental", 2L))
  expect_match(
    spatial_provenance$claim_boundary,
    "fixed-covariance",
    fixed = TRUE
  )
  expect_match(
    spatial_provenance$claim_boundary,
    "no range-estimating spatial route",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    known_provenance$claim_boundary,
    "fixture-level audit evidence"
  )

  expect_named(
    acceptance,
    c(
      "gate_id",
      "target",
      "structured_type",
      "dimension",
      "estimator",
      "native_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "tolerance_policy",
      "acceptance_status",
      "missing_evidence",
      "required_before_acceptance",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(acceptance), 4L)
  expect_setequal(
    acceptance$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  structured_re_expect_all_match(
    acceptance$native_status,
    "available_point_fixture"
  )
  phylo_acceptance <- acceptance[
    acceptance$structured_type == "phylo",
    ,
    drop = FALSE
  ]
  non_phylo_acceptance <- acceptance[
    acceptance$structured_type != "phylo",
    ,
    drop = FALSE
  ]
  expect_equal(
    phylo_acceptance$direct_drmjl_status,
    "available_residual_correlation_point_export"
  )
  expect_equal(
    phylo_acceptance$r_via_julia_status,
    "available_q2_phylo_formula_bridge_fixture"
  )
  expect_equal(phylo_acceptance$acceptance_status, "banked_phylo_fixture")
  expect_equal(phylo_acceptance$status, "covered")
  expect_equal(phylo_acceptance$bridge_status, "experimental")
  expect_equal(phylo_acceptance$missing_evidence, "none_for_phylo_fixture")
  expect_equal(
    phylo_acceptance$required_before_acceptance,
    "none_for_phylo_fixture"
  )
  expect_match(
    phylo_acceptance$claim_boundary,
    "no broad q2 bridge support",
    fixed = TRUE
  )
  spatial_acceptance <- non_phylo_acceptance[
    non_phylo_acceptance$structured_type == "spatial",
    ,
    drop = FALSE
  ]
  known_acceptance <- non_phylo_acceptance[
    non_phylo_acceptance$structured_type %in% c("animal", "relmat"),
    ,
    drop = FALSE
  ]
  expect_equal(
    spatial_acceptance$r_via_julia_status,
    "available_q2_fixed_covariance_spatial_formula_bridge_fixture"
  )
  expect_equal(
    spatial_acceptance$acceptance_status,
    "banked_fixed_covariance_spatial_fixture"
  )
  expect_equal(spatial_acceptance$status, "covered")
  expect_equal(spatial_acceptance$bridge_status, "experimental")
  expect_equal(
    known_acceptance$acceptance_status,
    rep("banked_known_covariance_fixture", 2L)
  )
  expect_equal(known_acceptance$status, rep("covered", 2L))
  expect_equal(known_acceptance$bridge_status, rep("experimental", 2L))
  expect_equal(
    spatial_acceptance$direct_drmjl_status,
    "available_fixed_covariance_residual_correlation_fixture"
  )
  expect_equal(
    known_acceptance$direct_drmjl_status,
    rep("available_known_covariance_residual_correlation_point_export", 2L)
  )
  expect_match(
    spatial_acceptance$missing_evidence,
    "none_for_fixed_covariance_spatial_fixture",
    fixed = TRUE
  )
  expect_equal(
    known_acceptance$missing_evidence,
    rep("none_for_known_covariance_fixture", 2L)
  )
  expect_false(
    any(grepl(
      "direct_q2_fit",
      non_phylo_acceptance$missing_evidence,
      fixed = TRUE
    ))
  )
  expect_match(
    spatial_acceptance$required_before_acceptance,
    "none_for_fixed_covariance_spatial_fixture",
    fixed = TRUE
  )
  expect_equal(
    known_acceptance$required_before_acceptance,
    rep("none_for_known_covariance_fixture", 2L)
  )
  expect_match(
    spatial_acceptance$claim_boundary,
    "fixed-covariance",
    fixed = TRUE
  )
  expect_match(
    spatial_acceptance$claim_boundary,
    "not a range-estimating spatial route",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    known_acceptance$claim_boundary,
    "complete-response exact-Gaussian ML"
  )

  expect_named(
    direct_q2,
    c(
      "export_id",
      "target",
      "structured_type",
      "dimension",
      "route",
      "estimator",
      "coefficient_order",
      "direct_status",
      "bridge_status",
      "unavailable_reason",
      "claim_boundary",
      "evidence_url",
      "next_gate"
    )
  )
  expect_equal(nrow(direct_q2), 4L)
  phylo_direct <- direct_q2[
    direct_q2$structured_type == "phylo",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(phylo_direct), 1L)
  expect_equal(
    phylo_direct$direct_status,
    "available_residual_correlation_point_export"
  )
  expect_equal(phylo_direct$bridge_status, "experimental")
  expect_match(
    phylo_direct$claim_boundary,
    "q2 phylo residual-correlation",
    fixed = TRUE
  )
  expect_match(
    phylo_direct$claim_boundary,
    "no broad q2 bridge support",
    fixed = TRUE
  )
  spatial_direct <- direct_q2[
    direct_q2$structured_type == "spatial",
    ,
    drop = FALSE
  ]
  known_cov_direct <- direct_q2[
    direct_q2$structured_type %in% c("animal", "relmat"),
    ,
    drop = FALSE
  ]
  expect_equal(
    spatial_direct$direct_status,
    "available_fixed_covariance_residual_correlation_fixture"
  )
  expect_equal(
    known_cov_direct$direct_status,
    rep("available_known_covariance_residual_correlation_point_export", 2L)
  )
  expect_match(
    spatial_direct$claim_boundary,
    "no broad q2 bridge support",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    known_cov_direct$claim_boundary,
    "bridge parity fixture",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    known_cov_direct$bridge_status,
    "experimental",
    fixed = TRUE
  )
  expect_equal(spatial_direct$bridge_status, "experimental")
  expect_match(
    spatial_direct$claim_boundary,
    "not a range-estimating spatial route",
    fixed = TRUE
  )
  expect_false(
    any(grepl(
      "no R-via-Julia q2 bridge support",
      direct_q2$claim_boundary,
      fixed = TRUE
    ))
  )
  structured_re_expect_all_match(
    spatial_direct$claim_boundary,
    "fixed-covariance",
    fixed = TRUE
  )
  expect_match(
    spatial_direct$claim_boundary,
    "not a range-estimating spatial route",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    direct_q2$claim_boundary,
    "interval coverage",
    fixed = TRUE
  )

  expect_named(
    order_map,
    c(
      "map_id",
      "structured_type",
      "target",
      "route",
      "estimator",
      "coefficient_order",
      "fixed_effect_terms",
      "structured_terms",
      "correlation_terms",
      "extractor",
      "tolerance_quantity",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(order_map), 4L)
  expect_setequal(
    order_map$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(
    order_map$coefficient_order,
    rep(
      paste(
        "mu1:(Intercept)",
        "mu1:x",
        "mu2:(Intercept)",
        "mu2:x",
        "sd_mu1:structured(group)",
        "sd_mu2:structured(group)",
        "cor_mu1_mu2:structured(group)",
        sep = ";"
      ),
      4L
    )
  )
  expect_true(all(grepl(
    "structured_correlation",
    order_map$tolerance_quantity,
    fixed = TRUE
  )))
  phylo_order <- order_map[order_map$structured_type == "phylo", , drop = FALSE]
  non_phylo_order <- order_map[
    order_map$structured_type != "phylo",
    ,
    drop = FALSE
  ]
  spatial_order <- order_map[
    order_map$structured_type == "spatial",
    ,
    drop = FALSE
  ]
  known_order <- order_map[
    order_map$structured_type %in% c("animal", "relmat"),
    ,
    drop = FALSE
  ]
  expect_match(
    phylo_order$claim_boundary,
    "no broad q2 bridge support",
    fixed = TRUE
  )
  expect_match(
    spatial_order$claim_boundary,
    "fixed-covariance",
    fixed = TRUE
  )
  expect_equal(spatial_order$bridge_status, "experimental")
  expect_equal(known_order$bridge_status, rep("experimental", 2L))
  structured_re_expect_all_match(
    known_order$claim_boundary,
    "fixture-level contract evidence"
  )
})

test_that("q4 contracts keep smoke, extractor, and interval boundaries separate", {
  targets <- structured_re_read_dashboard_tsv(
    "structured-re-q4-target-contract.tsv"
  )
  phylocov_map <- structured_re_read_dashboard_tsv(
    "structured-re-q4-phylocov-target-map.tsv"
  )
  profile_map <- structured_re_read_dashboard_tsv(
    "structured-re-q4-profile-target-bridge-map.tsv"
  )
  scale_failures <- structured_re_read_dashboard_tsv(
    "structured-re-q4-scale-axis-interval-failures.tsv"
  )
  interval_plan <- structured_re_read_dashboard_tsv(
    "structured-re-q4-interval-diagnostic-plan.tsv"
  )
  interval_status <- structured_re_read_dashboard_tsv(
    "structured-re-q4-interval-diagnostic-status.tsv"
  )
  convergence_probe <- structured_re_read_dashboard_tsv(
    "structured-re-q4-convergence-probe.tsv"
  )
  boundary_probe <- structured_re_read_dashboard_tsv(
    "structured-re-q4-boundary-separated-probe.tsv"
  )
  hessian_status <- structured_re_read_dashboard_tsv(
    "structured-re-q4-hessian-diagnostic-status.tsv"
  )
  stabilized_fixture_design <- structured_re_read_dashboard_tsv(
    "structured-re-q4-stabilized-fixture-design.tsv"
  )
  stabilized_preflight <- structured_re_read_dashboard_tsv(
    "structured-re-q4-stabilized-preflight.tsv"
  )
  stabilized_denominator <- structured_re_read_dashboard_tsv(
    "structured-re-q4-stabilized-denominator-extension.tsv"
  )
  stabilized_profile_smoke <- structured_re_read_dashboard_tsv(
    "structured-re-q4-stabilized-profile-smoke.tsv"
  )
  stabilized_all_direct_profile <- structured_re_read_dashboard_tsv(
    "structured-re-q4-stabilized-all-direct-profile.tsv"
  )
  stabilized_profile_denominator <- structured_re_read_dashboard_tsv(
    "structured-re-q4-stabilized-profile-denominator-status.tsv"
  )
  stabilized_eligible_profile <- structured_re_read_dashboard_tsv(
    "structured-re-q4-stabilized-eligible-profile.tsv"
  )
  stabilized_coverage_design <- structured_re_read_dashboard_tsv(
    "structured-re-q4-stabilized-coverage-design.tsv"
  )
  stabilized_grid_runner_contract <- structured_re_read_dashboard_tsv(
    "structured-re-q4-stabilized-grid-runner-contract.tsv"
  )
  stabilized_grid_smoke_status <- structured_re_read_dashboard_tsv(
    "structured-re-q4-stabilized-grid-smoke-status.tsv"
  )
  derived_correlation_interval_contract <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-interval-contract.tsv"
  )
  derived_correlation_interval_smoke <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-interval-smoke.tsv"
  )
  derived_correlation_delta_diagnostic <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-diagnostic.tsv"
  )
  derived_correlation_delta_grid_contract <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-contract.tsv"
  )
  derived_correlation_delta_grid_smoke <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-smoke-status.tsv"
  )
  derived_correlation_delta_grid_mini <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-mini-status.tsv"
  )
  derived_correlation_delta_grid_ademp <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-ademp-contract.tsv"
  )
  derived_correlation_delta_grid_resumable <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv"
  )
  derived_correlation_delta_grid_drac_plan <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-drac-shard-plan.tsv"
  )
  derived_correlation_delta_grid_drac_dispatch_pack <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv"
  )
  derived_correlation_delta_grid_two_shard <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-two-shard-rehearsal.tsv"
  )
  derived_correlation_delta_grid_local_four_shard <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-local-four-shard-rehearsal.tsv"
  )
  derived_correlation_delta_grid_local_eight_shard_medium <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal.tsv"
  )
  derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid <- structured_re_read_dashboard_tsv(
    "structured-re-q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid.tsv"
  )
  stabilized_grid_dry_run <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-stabilized-calibrated-grid-dry-run.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  stabilized_grid_smoke_results <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-stabilized-calibrated-grid-smoke-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_interval_smoke_results <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-interval-smoke-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_diagnostic_results <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-diagnostic-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_smoke_results <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-smoke-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_mini_results <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-mini-results.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_ademp_dry_run <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-ademp-dry-run.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_resumable_manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-resumable-smoke-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_resumable_run_log <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-resumable-smoke-run-log.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_drac_plan_artifact <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-drac-shard-plan.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_drac_dispatch_manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-drac-dispatch-pack",
      "q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_drac_dispatch_array_script <- readLines(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-drac-dispatch-pack",
      "slurm",
      "q4-derived-correlation-delta-grid-array.sbatch"
    )
  )
  derived_correlation_delta_grid_drac_dispatch_worker_script <- readLines(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-drac-dispatch-pack",
      "slurm",
      "q4-derived-correlation-delta-grid-array-worker.sh"
    )
  )
  derived_correlation_delta_grid_drac_dispatch_totoro_script <- readLines(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-drac-dispatch-pack",
      "slurm",
      "q4-derived-correlation-delta-grid-totoro-worker.sh"
    )
  )
  derived_correlation_delta_grid_drac_dispatch_aggregate_script <- readLines(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-drac-dispatch-pack",
      "slurm",
      "q4-derived-correlation-delta-grid-aggregate.sh"
    )
  )
  derived_correlation_delta_grid_two_shard_manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-two-shard-rehearsal",
      "aggregate",
      "q4-derived-correlation-delta-grid-two_shard_rehearsal-aggregate-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_two_shard_summary <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-two-shard-rehearsal",
      "aggregate",
      "q4-derived-correlation-delta-grid-two_shard_rehearsal-aggregate-summary.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_local_four_shard_manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-local-four-shard-rehearsal",
      "aggregate",
      "q4-derived-correlation-delta-grid-local_four_shard_rehearsal-aggregate-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_local_four_shard_summary <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-local-four-shard-rehearsal",
      "aggregate",
      "q4-derived-correlation-delta-grid-local_four_shard_rehearsal-aggregate-summary.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_local_eight_shard_medium_manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal",
      "aggregate",
      "q4-derived-correlation-delta-grid-local_eight_shard_medium_rehearsal-aggregate-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_local_eight_shard_medium_summary <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal",
      "aggregate",
      "q4-derived-correlation-delta-grid-local_eight_shard_medium_rehearsal-aggregate-summary.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid",
      "aggregate",
      "q4-derived-correlation-delta-grid-local_sixteen_shard_mcse_pregrid-aggregate-manifest.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary <- utils::read.delim(
    structured_re_artifact_path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-23-q4-stabilized-preflight",
      "q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid",
      "aggregate",
      "q4-derived-correlation-delta-grid-local_sixteen_shard_mcse_pregrid-aggregate-summary.tsv"
    ),
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  resumable_cell_outputs <- strsplit(
    derived_correlation_delta_grid_resumable_manifest$cell_outputs[[1]],
    ";",
    fixed = TRUE
  )[[1]]
  derived_correlation_delta_grid_resumable_cell <- do.call(
    rbind,
    lapply(resumable_cell_outputs, function(path) {
      cell_output_parts <- strsplit(path, "/", fixed = TRUE)[[1]]
      utils::read.delim(
        do.call(structured_re_artifact_path, as.list(cell_output_parts)),
        sep = "\t",
        quote = "",
        check.names = FALSE,
        stringsAsFactors = FALSE
      )
    })
  )
  direct_exports <- structured_re_read_dashboard_tsv(
    "structured-re-q4-direct-drmjl-export.tsv"
  )
  deterministic_fixture <- structured_re_read_dashboard_tsv(
    "structured-re-q4-deterministic-fixture.tsv"
  )
  tolerance_policy <- structured_re_read_dashboard_tsv(
    "structured-re-q4-tolerance-policy.tsv"
  )
  same_fixture_probe <- structured_re_read_dashboard_tsv(
    "structured-re-q4-same-fixture-parity-probe.tsv"
  )
  calibrated_probe <- structured_re_read_dashboard_tsv(
    "structured-re-q4-calibrated-parity-probe.tsv"
  )
  parity_gate <- structured_re_read_dashboard_tsv(
    "structured-re-q4-parity-acceptance-gate.tsv"
  )
  extractor <- structured_re_read_dashboard_tsv(
    "structured-re-q4-extractor-parity.tsv"
  )
  corpairs_gate <- structured_re_read_dashboard_tsv(
    "structured-re-q4-corpairs-parity-gate.tsv"
  )
  boundary <- structured_re_read_dashboard_tsv(
    "structured-re-q4-bridge-boundary.tsv"
  )
  reml_audit <- structured_re_read_dashboard_tsv(
    "structured-re-q4-reml-requested-effective-audit.tsv"
  )

  expect_setequal(targets$interval_status, c("not_evaluated", "unsupported"))
  sd_targets <- targets[targets$estimator == "ML", , drop = FALSE]
  structured_re_expect_all_match(sd_targets$direct_sd_targets, "sd_mu1")
  structured_re_expect_all_match(
    sd_targets$derived_correlation_targets,
    "six cross-axis correlations"
  )

  reml <- targets[
    targets$target_id == "q4_native_reml_boundary",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(reml), 1L)
  expect_equal(reml$profile_status, "unsupported")
  expect_match(reml$claim_boundary, "not HSquared AI-REML", fixed = TRUE)

  expect_setequal(
    extractor$interval_status,
    c("not_available", "not_evaluated")
  )
  summary_cov <- extractor[
    extractor$extractor_id == "q4_phylo_summary_covariance",
    ,
    drop = FALSE
  ]
  profile_targets <- extractor[
    extractor$extractor_id == "q4_phylo_profile_targets",
    ,
    drop = FALSE
  ]
  corpairs <- extractor[
    extractor$extractor_id == "q4_phylo_corpairs",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(summary_cov), 1L)
  expect_equal(nrow(profile_targets), 1L)
  expect_equal(nrow(corpairs), 1L)
  expect_match(summary_cov$claim_boundary, "no interval coverage", fixed = TRUE)
  expect_match(profile_targets$claim_boundary, "interval-ready", fixed = TRUE)
  expect_match(corpairs$claim_boundary, "not q4 interval parity", fixed = TRUE)

  expect_named(
    phylocov_map,
    c(
      "map_id",
      "target",
      "target_kind",
      "axis",
      "axis_pair",
      "direct_sd_target",
      "log_cholesky_target",
      "correlation_target",
      "extractor",
      "estimator",
      "point_status",
      "interval_status",
      "bridge_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(phylocov_map), 10L)
  q4_sd_map <- phylocov_map[
    phylocov_map$target_kind == "direct_sd",
    ,
    drop = FALSE
  ]
  q4_cor_map <- phylocov_map[
    phylocov_map$target_kind == "derived_correlation",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(q4_sd_map), 4L)
  expect_equal(nrow(q4_cor_map), 6L)
  expect_setequal(
    q4_sd_map$direct_sd_target,
    c("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2")
  )
  expect_equal(q4_cor_map$direct_sd_target, rep("not_direct", 6L))
  structured_re_expect_all_match(q4_cor_map$extractor, "corpairs")
  structured_re_expect_all_match(
    phylocov_map$claim_boundary,
    "interval coverage"
  )

  expect_named(
    profile_map,
    c(
      "map_id",
      "target",
      "axis",
      "native_profile_target",
      "bridge_profile_target",
      "direct_sd_target",
      "native_tmb_parameter",
      "native_profile_ready",
      "bridge_profile_ready",
      "interval_status",
      "negative_evidence",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(profile_map), 4L)
  expect_equal(
    profile_map$axis,
    c("mu1", "mu2", "sigma1", "sigma2")
  )
  expect_equal(
    profile_map$native_profile_target,
    c(
      "sd:mu:mu1:phylo(1 | p | species)",
      "sd:mu:mu2:phylo(1 | p | species)",
      "sd:mu:sigma1:phylo(1 | p | species)",
      "sd:mu:sigma2:phylo(1 | p | species)"
    )
  )
  expect_equal(
    profile_map$bridge_profile_target,
    c(
      "sd:mu1:phylo(1 | species)",
      "sd:mu2:phylo(1 | species)",
      "sd:sigma1:phylo(1 | species)",
      "sd:sigma2:phylo(1 | species)"
    )
  )
  expect_equal(profile_map$native_profile_ready, rep("true", 4L))
  expect_equal(
    profile_map$bridge_profile_ready,
    rep("target_inventory_only", 4L)
  )
  expect_equal(profile_map$interval_status, rep("not_evaluated", 4L))
  structured_re_expect_all_match(
    profile_map$negative_evidence,
    "no_same_fixture_native_direct_bridge_profile_comparison"
  )
  structured_re_expect_all_match(profile_map$claim_boundary, "no q4 parity")
  structured_re_expect_all_match(
    profile_map$claim_boundary,
    "interval coverage"
  )

  expect_named(
    scale_failures,
    c(
      "failure_id",
      "target",
      "axis",
      "direct_sd_target",
      "native_tmb_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "bridge_status",
      "evidence_url",
      "source_evidence",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(scale_failures), 2L)
  expect_equal(scale_failures$axis, c("sigma1", "sigma2"))
  expect_equal(scale_failures$direct_sd_target, c("sd_sigma1", "sd_sigma2"))
  structured_re_expect_all_match(
    scale_failures$native_tmb_status,
    "100tip_refit_failures"
  )
  structured_re_expect_all_match(
    scale_failures$direct_drmjl_status,
    "known_scale_axis_undercoverage"
  )
  structured_re_expect_all_match(
    scale_failures$r_via_julia_status,
    "target_inventory_only"
  )
  structured_re_expect_all_match(
    scale_failures$failure_class,
    "scale_axis_undercoverage_known"
  )
  expect_equal(scale_failures$interval_claim_status, rep("blocked", 2L))
  expect_equal(scale_failures$status, rep("covered", 2L))
  expect_equal(scale_failures$bridge_status, rep("experimental", 2L))
  structured_re_expect_all_match(
    scale_failures$source_evidence,
    "bootstrap-refit-accounting.tsv"
  )
  structured_re_expect_all_match(
    scale_failures$source_evidence,
    "bivariate-bootstrap-sigma-a.md"
  )
  structured_re_expect_all_match(
    scale_failures$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    scale_failures$claim_boundary,
    "interval coverage"
  )

  expect_named(
    interval_plan,
    c(
      "diagnostic_id",
      "slice_id",
      "target",
      "target_kind",
      "axis_pair",
      "direct_sd_target",
      "derived_correlation_target",
      "interval_methods",
      "required_fit_evidence",
      "required_interval_evidence",
      "denominator_fields",
      "current_blocker",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(interval_plan), 10L)
  expect_setequal(
    interval_plan$target_kind,
    c("direct_sd", "derived_correlation")
  )
  expect_equal(interval_plan$slice_id, rep("SR150", nrow(interval_plan)))
  direct_plan <- interval_plan[
    interval_plan$target_kind == "direct_sd",
    ,
    drop = FALSE
  ]
  derived_plan <- interval_plan[
    interval_plan$target_kind == "derived_correlation",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(direct_plan), 4L)
  expect_equal(nrow(derived_plan), 6L)
  expect_setequal(
    direct_plan$direct_sd_target,
    c("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2")
  )
  expect_equal(derived_plan$direct_sd_target, rep("not_direct", 6L))
  structured_re_expect_all_match(derived_plan$required_fit_evidence, "corpairs")
  structured_re_expect_all_match(
    interval_plan$required_interval_evidence,
    "finite"
  )
  structured_re_expect_all_match(
    interval_plan$required_interval_evidence,
    "coverage_mcse<=0.01",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    interval_plan$denominator_fields,
    "coverage_denominator"
  )
  expect_equal(interval_plan$status, rep("planned", nrow(interval_plan)))
  structured_re_expect_all_match(
    interval_plan$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    interval_plan$claim_boundary,
    "interval coverage"
  )

  expect_named(
    interval_status,
    c(
      "diagnostic_id",
      "slice_id",
      "target",
      "target_kind",
      "axis_pair",
      "direct_sd_target",
      "derived_correlation_target",
      "source_artifact",
      "observed_target_rows",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_finite_intervals",
      "interval_status",
      "failure_class",
      "interval_claim_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(interval_status), 10L)
  direct_status <- interval_status[
    interval_status$target_kind == "direct_sd",
    ,
    drop = FALSE
  ]
  derived_status <- interval_status[
    interval_status$target_kind == "derived_correlation",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(direct_status), 4L)
  expect_equal(nrow(derived_status), 6L)
  expect_equal(as.integer(direct_status$observed_target_rows), rep(2L, 4L))
  expect_equal(as.integer(direct_status$n_fit_ok), rep(2L, 4L))
  expect_equal(as.integer(direct_status$n_converged), rep(0L, 4L))
  expect_equal(as.integer(direct_status$n_pdhess), rep(0L, 4L))
  expect_equal(as.integer(direct_status$n_finite_intervals), rep(0L, 4L))
  expect_equal(direct_status$interval_status, rep("wald_unavailable", 4L))
  structured_re_expect_all_match(
    direct_status$failure_class,
    "no_finite_wald_intervals"
  )
  expect_equal(as.integer(derived_status$observed_target_rows), rep(0L, 6L))
  expect_equal(
    derived_status$failure_class,
    rep("derived_correlation_interval_reconstruction_not_available", 6L)
  )
  expect_equal(
    interval_status$interval_claim_status,
    rep("blocked", nrow(interval_status))
  )
  expect_equal(interval_status$status, rep("covered", nrow(interval_status)))
  structured_re_expect_all_match(
    interval_status$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    interval_status$claim_boundary,
    "interval coverage"
  )

  expect_named(
    convergence_probe,
    c(
      "probe_id",
      "slice_id",
      "target",
      "n_tip",
      "m",
      "replicate",
      "optimizer_preset",
      "fit_ok",
      "convergence",
      "converged",
      "pdHess",
      "elapsed_sec",
      "message",
      "diagnostic_class",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(convergence_probe), 15L)
  expect_setequal(
    convergence_probe$optimizer_preset,
    c("default", "careful", "robust")
  )
  expect_equal(convergence_probe$fit_ok, rep("true", nrow(convergence_probe)))
  expect_equal(convergence_probe$pdHess, rep("false", nrow(convergence_probe)))
  dense <- convergence_probe[
    convergence_probe$m == "4" &
      convergence_probe$n_tip == "10" &
      convergence_probe$converged == "true",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(dense), 3L)
  expect_equal(
    dense$diagnostic_class,
    rep("optimizer_converged_pdhess_false", 3L)
  )
  structured_re_expect_all_match(
    convergence_probe$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    convergence_probe$claim_boundary,
    "interval coverage"
  )

  expect_named(
    boundary_probe,
    c(
      "probe_id",
      "slice_id",
      "target",
      "fixture",
      "n_tip",
      "m",
      "seed",
      "optimizer_preset",
      "fit_ok",
      "convergence",
      "converged",
      "pdHess",
      "elapsed_sec",
      "message",
      "min_direct_sd_estimate",
      "max_abs_derived_correlation",
      "diagnostic_class",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(boundary_probe), 12L)
  expect_setequal(
    boundary_probe$optimizer_preset,
    c("default", "careful", "robust")
  )
  expect_setequal(boundary_probe$seed, c("202606777", "202606778"))
  expect_equal(boundary_probe$fit_ok, rep("true", nrow(boundary_probe)))
  expect_equal(boundary_probe$pdHess, rep("false", nrow(boundary_probe)))
  boundary_converged <- boundary_probe[
    boundary_probe$converged == "true",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(boundary_converged), 2L)
  expect_equal(
    boundary_converged$diagnostic_class,
    rep("optimizer_converged_pdhess_false_boundary_correlation", 2L)
  )
  expect_gt(min(as.numeric(boundary_probe$max_abs_derived_correlation)), 0.9)
  structured_re_expect_all_match(
    boundary_probe$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    boundary_probe$claim_boundary,
    "interval coverage"
  )

  expect_named(
    hessian_status,
    c(
      "diagnostic_id",
      "slice_id",
      "target",
      "fixture",
      "optimizer_preset",
      "converged",
      "pdHess",
      "metric",
      "value",
      "diagnostic_class",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(hessian_status), 8L)
  expect_setequal(
    hessian_status$metric,
    c(
      "max_abs_gradient_fixed",
      "min_cov_fixed_eigenvalue",
      "max_cov_fixed_eigenvalue",
      "min_direct_sd_estimate",
      "max_direct_sd_estimate",
      "min_abs_derived_correlation",
      "max_abs_derived_correlation",
      "finite_wald_direct_sd_intervals"
    )
  )
  expect_equal(hessian_status$converged, rep("true", nrow(hessian_status)))
  expect_equal(hessian_status$pdHess, rep("false", nrow(hessian_status)))
  min_eigen <- hessian_status[
    hessian_status$metric == "min_cov_fixed_eigenvalue",
    ,
    drop = FALSE
  ]
  expect_lt(as.numeric(min_eigen$value), 0)
  min_sd <- hessian_status[
    hessian_status$metric == "min_direct_sd_estimate",
    ,
    drop = FALSE
  ]
  expect_lt(as.numeric(min_sd$value), 1e-4)
  wald <- hessian_status[
    hessian_status$metric == "finite_wald_direct_sd_intervals",
    ,
    drop = FALSE
  ]
  expect_equal(wald$value, "0_of_4")
  structured_re_expect_all_match(
    hessian_status$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    hessian_status$claim_boundary,
    "interval coverage"
  )

  expect_named(
    stabilized_fixture_design,
    c(
      "design_id",
      "slice_id",
      "target",
      "blocker",
      "evidence_input",
      "required_design_change",
      "acceptance_metric",
      "acceptance_threshold",
      "owner_members",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_fixture_design), 6L)
  expect_equal(
    stabilized_fixture_design$slice_id,
    rep("SR150", nrow(stabilized_fixture_design))
  )
  expect_setequal(
    stabilized_fixture_design$blocker,
    c(
      "near_zero_direct_sd_estimates",
      "derived_correlations_near_boundary",
      "optimizer_converged_pdhess_false",
      "zero_finite_direct_sd_intervals",
      "no_calibrated_denominator_accounting",
      "bridge_and_native_routes_not_equivalent_for_intervals"
    )
  )
  expect_setequal(
    stabilized_fixture_design$acceptance_metric,
    c(
      "min_direct_sd_estimate",
      "max_abs_derived_correlation",
      "pdHess_and_cov_fixed_eigenspectrum",
      "finite_direct_sd_intervals_by_method",
      "denominator_fields",
      "parity_routes"
    )
  )
  expect_equal(
    stabilized_fixture_design$status,
    rep("covered", nrow(stabilized_fixture_design))
  )
  structured_re_expect_all_match(
    stabilized_fixture_design$evidence_input,
    ".tsv"
  )
  structured_re_expect_all_match(
    stabilized_fixture_design$acceptance_threshold,
    "[<>=]|n_total|native_tmb",
    fixed = FALSE
  )
  structured_re_expect_all_match(
    stabilized_fixture_design$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_fixture_design$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    stabilized_fixture_design$claim_boundary,
    "AI-REML"
  )

  expect_named(
    stabilized_preflight,
    c(
      "preflight_id",
      "slice_id",
      "target",
      "fixture",
      "seed",
      "n_tip",
      "n_each",
      "sd_scale",
      "corr_offdiag",
      "fit_ok",
      "convergence",
      "converged",
      "pdHess",
      "max_gradient",
      "min_direct_sd_estimate",
      "max_abs_derived_correlation",
      "finite_wald_direct_sd_intervals",
      "direct_sd_interval_status",
      "diagnostic_class",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_preflight), 4L)
  expect_setequal(stabilized_preflight$seed, c("202606901", "202606902"))
  expect_setequal(as.numeric(stabilized_preflight$sd_scale), c(0.35, 0.50))
  expect_equal(stabilized_preflight$n_tip, rep(32L, 4L))
  expect_equal(stabilized_preflight$n_each, rep(8L, 4L))
  expect_lt(max(as.numeric(stabilized_preflight$max_gradient)), 1e-3)
  expect_lt(
    max(as.numeric(stabilized_preflight$max_abs_derived_correlation)),
    0.9
  )
  pdhess_true <- stabilized_preflight[
    stabilized_preflight$pdHess == "true",
    ,
    drop = FALSE
  ]
  pdhess_false <- stabilized_preflight[
    stabilized_preflight$pdHess == "false",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(pdhess_true), 2L)
  expect_equal(nrow(pdhess_false), 2L)
  expect_equal(pdhess_true$converged, rep("true", 2L))
  expect_equal(pdhess_true$finite_wald_direct_sd_intervals, rep("4_of_4", 2L))
  expect_equal(pdhess_true$direct_sd_interval_status, rep("wald_finite", 2L))
  expect_equal(
    pdhess_true$diagnostic_class,
    rep("converged_pdhess_true_finite_wald_direct_sd_intervals", 2L)
  )
  expect_equal(
    pdhess_false$finite_wald_direct_sd_intervals,
    rep("not_evaluated", 2L)
  )
  expect_equal(pdhess_false$direct_sd_interval_status, rep("pdhess_false", 2L))
  structured_re_expect_all_match(
    stabilized_preflight$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_preflight$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    stabilized_preflight$claim_boundary,
    "q4 REML"
  )

  expect_named(
    stabilized_denominator,
    c(
      "summary_id",
      "slice_id",
      "target",
      "fixture",
      "sd_scale",
      "n_total",
      "n_fit_ok",
      "n_converged",
      "n_pdhess",
      "n_finite_wald_direct_sd_intervals",
      "n_pdhess_false",
      "gradient_warning_rows",
      "min_direct_sd_pdhess_true",
      "max_abs_cor_pdhess_true",
      "denominator_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_denominator), 2L)
  expect_setequal(as.numeric(stabilized_denominator$sd_scale), c(0.35, 0.50))
  expect_equal(as.integer(stabilized_denominator$n_total), c(4L, 4L))
  expect_equal(as.integer(stabilized_denominator$n_fit_ok), c(4L, 4L))
  expect_equal(as.integer(stabilized_denominator$n_converged), c(2L, 3L))
  expect_equal(as.integer(stabilized_denominator$n_pdhess), c(2L, 3L))
  expect_equal(
    as.integer(stabilized_denominator$n_finite_wald_direct_sd_intervals),
    c(2L, 3L)
  )
  expect_equal(as.integer(stabilized_denominator$n_pdhess_false), c(2L, 1L))
  expect_equal(
    as.integer(stabilized_denominator$gradient_warning_rows),
    c(0L, 1L)
  )
  expect_equal(
    stabilized_denominator$denominator_status,
    c(
      "denominator_preflight_only",
      "denominator_preflight_with_gradient_warning"
    )
  )
  expect_equal(
    stabilized_denominator$status,
    rep("covered", nrow(stabilized_denominator))
  )
  structured_re_expect_all_match(
    stabilized_denominator$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_denominator$claim_boundary,
    "interval coverage"
  )

  expect_named(
    stabilized_profile_smoke,
    c(
      "smoke_id",
      "slice_id",
      "target",
      "fixture",
      "seed",
      "sd_scale",
      "parm",
      "fit_convergence",
      "pdHess",
      "max_gradient",
      "profile_precision",
      "profile_elapsed_sec",
      "lower",
      "upper",
      "profile_engine",
      "conf_status",
      "profile_boundary",
      "profile_message",
      "diagnostic_class",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_profile_smoke), 1L)
  expect_equal(stabilized_profile_smoke$seed, 202606902L)
  expect_equal(as.numeric(stabilized_profile_smoke$sd_scale), 0.50)
  expect_equal(stabilized_profile_smoke$pdHess, "true")
  expect_lt(as.numeric(stabilized_profile_smoke$max_gradient), 1e-3)
  expect_equal(stabilized_profile_smoke$profile_precision, "fast")
  expect_equal(stabilized_profile_smoke$profile_engine, "tmbprofile")
  expect_equal(stabilized_profile_smoke$conf_status, "profile")
  expect_equal(stabilized_profile_smoke$profile_boundary, "false")
  expect_lt(
    as.numeric(stabilized_profile_smoke$lower),
    as.numeric(stabilized_profile_smoke$upper)
  )
  expect_equal(
    stabilized_profile_smoke$diagnostic_class,
    "profile_smoke_finite_direct_sd_interval"
  )
  structured_re_expect_all_match(
    stabilized_profile_smoke$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_profile_smoke$claim_boundary,
    "interval coverage"
  )

  expect_named(
    stabilized_all_direct_profile,
    c(
      "profile_id",
      "slice_id",
      "target",
      "fixture",
      "seed",
      "sd_scale",
      "axis",
      "parm",
      "fit_convergence",
      "pdHess",
      "max_gradient",
      "profile_precision",
      "profile_elapsed_sec",
      "lower",
      "upper",
      "profile_engine",
      "conf_status",
      "profile_boundary",
      "profile_message",
      "diagnostic_class",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_all_direct_profile), 4L)
  expect_setequal(
    stabilized_all_direct_profile$axis,
    c("mu1", "mu2", "sigma1", "sigma2")
  )
  expect_equal(stabilized_all_direct_profile$seed, rep(202606902L, 4L))
  expect_equal(
    as.numeric(stabilized_all_direct_profile$sd_scale),
    rep(0.50, 4L)
  )
  expect_equal(stabilized_all_direct_profile$pdHess, rep("true", 4L))
  expect_lt(max(as.numeric(stabilized_all_direct_profile$max_gradient)), 1e-3)
  expect_equal(stabilized_all_direct_profile$profile_precision, rep("fast", 4L))
  expect_gt(
    min(as.numeric(stabilized_all_direct_profile$profile_elapsed_sec)),
    0
  )
  expect_equal(
    stabilized_all_direct_profile$profile_engine,
    rep("tmbprofile", 4L)
  )
  expect_equal(stabilized_all_direct_profile$conf_status, rep("profile", 4L))
  expect_equal(stabilized_all_direct_profile$profile_boundary, rep("false", 4L))
  expect_true(
    all(
      as.numeric(stabilized_all_direct_profile$lower) <
        as.numeric(stabilized_all_direct_profile$upper)
    )
  )
  expect_equal(
    stabilized_all_direct_profile$diagnostic_class,
    rep("all_direct_profile_finite_direct_sd_interval", 4L)
  )
  structured_re_expect_all_match(
    stabilized_all_direct_profile$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_all_direct_profile$claim_boundary,
    "interval coverage"
  )

  expect_named(
    stabilized_profile_denominator,
    c(
      "denominator_id",
      "slice_id",
      "target",
      "fixture",
      "seed",
      "sd_scale",
      "fit_ok",
      "converged",
      "pdHess",
      "max_gradient",
      "finite_wald_direct_sd_intervals",
      "profile_eligible",
      "profile_attempted",
      "direct_profile_rows",
      "profile_finite_rows",
      "profile_status",
      "blocker",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_profile_denominator), 8L)
  expect_setequal(stabilized_profile_denominator$seed, 202606901:202606904)
  expect_setequal(
    as.numeric(stabilized_profile_denominator$sd_scale),
    c(0.35, 0.50)
  )
  expect_equal(
    sum(stabilized_profile_denominator$profile_eligible == "true"),
    4L
  )
  expect_equal(
    sum(
      stabilized_profile_denominator$profile_status == "eligible_not_profiled"
    ),
    0L
  )
  expect_equal(
    sum(
      stabilized_profile_denominator$profile_status == "blocked_pdhess_false"
    ),
    3L
  )
  expect_equal(
    sum(
      stabilized_profile_denominator$profile_status ==
        "held_for_gradient_warning"
    ),
    1L
  )
  expect_equal(
    sum(
      stabilized_profile_denominator$profile_status ==
        "all_direct_profiles_finite"
    ),
    4L
  )
  expect_equal(
    sum(as.integer(stabilized_profile_denominator$profile_finite_rows)),
    16L
  )
  gradient_hold <- stabilized_profile_denominator[
    stabilized_profile_denominator$profile_status ==
      "held_for_gradient_warning",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(gradient_hold), 1L)
  expect_gt(as.numeric(gradient_hold$max_gradient), 1e-3)
  structured_re_expect_all_match(
    stabilized_profile_denominator$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_profile_denominator$claim_boundary,
    "interval coverage"
  )

  expect_named(
    stabilized_eligible_profile,
    c(
      "profile_id",
      "slice_id",
      "target",
      "fixture",
      "seed",
      "sd_scale",
      "axis",
      "parm",
      "fit_convergence",
      "pdHess",
      "max_gradient",
      "profile_precision",
      "fit_elapsed_sec",
      "profile_elapsed_sec",
      "lower",
      "upper",
      "profile_engine",
      "conf_status",
      "profile_boundary",
      "profile_message",
      "warning_context",
      "diagnostic_class",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_eligible_profile), 12L)
  expect_setequal(
    stabilized_eligible_profile$seed,
    c(202606902L, 202606903L, 202606904L)
  )
  expect_setequal(
    as.numeric(stabilized_eligible_profile$sd_scale),
    c(0.35, 0.50)
  )
  expect_setequal(
    stabilized_eligible_profile$axis,
    c("mu1", "mu2", "sigma1", "sigma2")
  )
  expect_equal(stabilized_eligible_profile$pdHess, rep("true", 12L))
  expect_lt(max(as.numeric(stabilized_eligible_profile$max_gradient)), 1e-3)
  expect_equal(
    stabilized_eligible_profile$profile_engine,
    rep("tmbprofile", 12L)
  )
  expect_equal(stabilized_eligible_profile$conf_status, rep("profile", 12L))
  expect_equal(stabilized_eligible_profile$profile_boundary, rep("false", 12L))
  expect_true(
    all(
      as.numeric(stabilized_eligible_profile$lower) <
        as.numeric(stabilized_eligible_profile$upper)
    )
  )
  structured_re_expect_all_match(
    stabilized_eligible_profile$warning_context,
    "regularize_values_duplicate_x"
  )
  structured_re_expect_all_match(
    stabilized_eligible_profile$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_eligible_profile$claim_boundary,
    "interval coverage"
  )

  expect_named(
    stabilized_coverage_design,
    c(
      "design_id",
      "slice_id",
      "target",
      "design_component",
      "current_evidence",
      "required_next_artifact",
      "planned_n_rep",
      "denominator_policy",
      "warning_policy",
      "acceptance_metric",
      "blocked_until",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_coverage_design), 8L)
  expect_setequal(
    stabilized_coverage_design$design_component,
    c(
      "direct_sd_profile_grid",
      "pdhess_failure_denominator",
      "gradient_warning_policy",
      "profile_warning_policy",
      "derived_correlation_interval_gap",
      "bootstrap_refit_accounting",
      "route_specific_boundary",
      "MCSE_report_policy"
    )
  )
  expect_equal(stabilized_coverage_design$planned_n_rep, rep(500L, 8L))
  expect_equal(stabilized_coverage_design$status, rep("covered", 8L))
  structured_re_expect_all_match(
    stabilized_coverage_design$denominator_policy,
    "denominator"
  )
  structured_re_expect_all_match(
    stabilized_coverage_design$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_coverage_design$claim_boundary,
    "interval coverage"
  )
  expect_match(
    stabilized_coverage_design$current_evidence[
      stabilized_coverage_design$design_component == "direct_sd_profile_grid"
    ],
    "16 finite direct q4 SD profile rows"
  )
  expect_match(
    stabilized_coverage_design$current_evidence[
      stabilized_coverage_design$design_component ==
        "pdhess_failure_denominator"
    ],
    "3 of 8"
  )
  expect_match(
    stabilized_coverage_design$current_evidence[
      stabilized_coverage_design$design_component == "gradient_warning_policy"
    ],
    "0.0048295879"
  )
  expect_match(
    stabilized_coverage_design$current_evidence[
      stabilized_coverage_design$design_component == "profile_warning_policy"
    ],
    "duplicate-`x`"
  )

  expect_named(
    stabilized_grid_runner_contract,
    c(
      "contract_id",
      "slice_id",
      "target",
      "executable",
      "mode",
      "output_artifact",
      "required_columns",
      "denominator_policy",
      "warning_policy",
      "validation_gate",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_grid_runner_contract), 8L)
  expect_setequal(
    stabilized_grid_runner_contract$contract_id,
    c(
      "q4_stabilized_grid_entrypoint",
      "q4_stabilized_grid_seed_contract",
      "q4_stabilized_grid_direct_target_contract",
      "q4_stabilized_grid_derived_target_contract",
      "q4_stabilized_grid_denominator_contract",
      "q4_stabilized_grid_warning_contract",
      "q4_stabilized_grid_mcse_contract",
      "q4_stabilized_grid_boundary_contract"
    )
  )
  expect_equal(stabilized_grid_runner_contract$mode, rep("dry_run", 8L))
  expect_equal(stabilized_grid_runner_contract$status, rep("covered", 8L))
  structured_re_expect_all_match(
    stabilized_grid_runner_contract$denominator_policy,
    "denominator"
  )
  structured_re_expect_all_match(
    stabilized_grid_runner_contract$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_grid_runner_contract$claim_boundary,
    "interval coverage"
  )

  expect_named(
    stabilized_grid_dry_run,
    c(
      "dry_run_id",
      "slice_id",
      "target",
      "requested_n_rep",
      "seed_start",
      "sd_scale_levels",
      "direct_sd_targets",
      "derived_correlation_targets",
      "denominator_fields",
      "warning_fields",
      "output_schema",
      "status",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_grid_dry_run), 1L)
  expect_equal(stabilized_grid_dry_run$requested_n_rep, 0L)
  expect_equal(stabilized_grid_dry_run$seed_start, 202607001L)
  structured_re_expect_all_match(
    stabilized_grid_dry_run$denominator_fields,
    "n_profile_warning"
  )
  structured_re_expect_all_match(
    stabilized_grid_dry_run$warning_fields,
    "regularize_values_duplicate_x_count"
  )
  structured_re_expect_all_match(
    stabilized_grid_dry_run$output_schema,
    "coverage_mcse"
  )
  structured_re_expect_all_match(
    stabilized_grid_dry_run$output_schema,
    "failure_rate_mcse"
  )

  expect_named(
    stabilized_grid_smoke_status,
    c(
      "smoke_id",
      "slice_id",
      "target",
      "source_script",
      "output_artifact",
      "observed_replicates",
      "observed_target_rows",
      "direct_sd_rows",
      "derived_correlation_rows",
      "fit_status",
      "interval_status",
      "mcse_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(stabilized_grid_smoke_status), 8L)
  expect_setequal(
    stabilized_grid_smoke_status$smoke_id,
    c(
      "q4_stabilized_grid_smoke_entrypoint",
      "q4_stabilized_grid_smoke_direct_sd_rows",
      "q4_stabilized_grid_smoke_derived_correlation_rows",
      "q4_stabilized_grid_smoke_denominator_fields",
      "q4_stabilized_grid_smoke_warning_fields",
      "q4_stabilized_grid_smoke_mcse_fields",
      "q4_stabilized_grid_smoke_claim_boundary",
      "q4_stabilized_grid_smoke_next_gate"
    )
  )
  expect_equal(
    stabilized_grid_smoke_status$output_artifact,
    rep("q4-stabilized-calibrated-grid-smoke-results.tsv", 8L)
  )
  expect_equal(
    stabilized_grid_smoke_status$mcse_status,
    rep("insufficient_replicates", 8L)
  )
  expect_equal(stabilized_grid_smoke_status$status, rep("covered", 8L))
  structured_re_expect_all_match(
    stabilized_grid_smoke_status$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_grid_smoke_status$claim_boundary,
    "interval coverage"
  )

  expect_named(
    stabilized_grid_smoke_results,
    c(
      "replicate_id",
      "seed",
      "sd_scale",
      "axis",
      "target_name",
      "target_kind",
      "true_value",
      "fit_status",
      "convergence",
      "converged",
      "pdHess",
      "max_gradient",
      "fit_elapsed_sec",
      "interval_method",
      "interval_status",
      "lower",
      "upper",
      "warning_context",
      "failure_reason",
      "coverage_indicator",
      "coverage_mcse",
      "failure_rate_mcse",
      "mcse_status",
      "claim_boundary"
    )
  )
  expect_equal(nrow(stabilized_grid_smoke_results), 10L)
  expect_equal(
    stabilized_grid_smoke_results$replicate_id,
    rep("smoke_001", 10L)
  )
  expect_equal(stabilized_grid_smoke_results$seed, rep(202606902L, 10L))
  expect_equal(stabilized_grid_smoke_results$fit_status, rep("fit_ok", 10L))
  expect_equal(stabilized_grid_smoke_results$pdHess, rep(TRUE, 10L))
  expect_equal(
    stabilized_grid_smoke_results$mcse_status,
    rep("insufficient_replicates", 10L)
  )
  direct_smoke <- stabilized_grid_smoke_results[
    stabilized_grid_smoke_results$target_kind == "direct_sd",
    ,
    drop = FALSE
  ]
  derived_smoke <- stabilized_grid_smoke_results[
    stabilized_grid_smoke_results$target_kind == "derived_correlation",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(direct_smoke), 4L)
  expect_equal(nrow(derived_smoke), 6L)
  expect_setequal(
    direct_smoke$target_name,
    c("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2")
  )
  expect_equal(direct_smoke$interval_method, rep("wald", 4L))
  expect_equal(direct_smoke$interval_status, rep("finite", 4L))
  expect_equal(
    direct_smoke$coverage_indicator,
    rep("covered_by_interval", 4L)
  )
  expect_setequal(
    derived_smoke$target_name,
    c(
      "cor_mu1_mu2",
      "cor_mu1_sigma1",
      "cor_mu1_sigma2",
      "cor_mu2_sigma1",
      "cor_mu2_sigma2",
      "cor_sigma1_sigma2"
    )
  )
  expect_equal(
    derived_smoke$interval_status,
    rep("derived_correlation_interval_not_reconstructed", 6L)
  )
  expect_equal(
    derived_smoke$failure_reason,
    rep("derived_correlation_interval_reconstruction_not_available", 6L)
  )
  expect_equal(
    derived_smoke$coverage_indicator,
    rep("not_evaluated", 6L)
  )
  structured_re_expect_all_match(
    stabilized_grid_smoke_results$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    stabilized_grid_smoke_results$claim_boundary,
    "interval coverage"
  )

  expect_named(
    derived_correlation_interval_contract,
    c(
      "contract_id",
      "slice_id",
      "target",
      "axis_pair",
      "derived_correlation_target",
      "point_source",
      "interval_source",
      "current_interval_status",
      "reconstruction_route",
      "required_payload_fields",
      "required_methods",
      "denominator_policy",
      "mcse_policy",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_interval_contract), 6L)
  expect_equal(
    derived_correlation_interval_contract$slice_id,
    rep("SR150", 6L)
  )
  expect_setequal(
    derived_correlation_interval_contract$derived_correlation_target,
    c(
      "cor_mu1_mu2",
      "cor_mu1_sigma1",
      "cor_mu1_sigma2",
      "cor_mu2_sigma1",
      "cor_mu2_sigma2",
      "cor_sigma1_sigma2"
    )
  )
  expect_equal(
    derived_correlation_interval_contract$current_interval_status,
    rep("not_available", 6L)
  )
  expect_equal(
    derived_correlation_interval_contract$reconstruction_route,
    rep("planned_delta_or_profile_reconstruction", 6L)
  )
  structured_re_expect_all_match(
    derived_correlation_interval_contract$point_source,
    "corpairs"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_contract$interval_source,
    "q4-stabilized-calibrated-grid-smoke-results.tsv"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_contract$required_payload_fields,
    "Sigma_a"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_contract$required_payload_fields,
    "failure_reason"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_contract$required_methods,
    "delta"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_contract$required_methods,
    "profile"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_contract$required_methods,
    "bootstrap"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_contract$denominator_policy,
    "unavailable"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_contract$mcse_policy,
    "coverage_mcse"
  )
  expect_equal(derived_correlation_interval_contract$status, rep("covered", 6L))
  structured_re_expect_all_match(
    derived_correlation_interval_contract$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_contract$claim_boundary,
    "interval coverage"
  )

  expected_q4_derived_correlations <- c(
    "cor_mu1_mu2",
    "cor_mu1_sigma1",
    "cor_mu1_sigma2",
    "cor_mu2_sigma1",
    "cor_mu2_sigma2",
    "cor_sigma1_sigma2"
  )

  expect_named(
    derived_correlation_interval_smoke,
    c(
      "smoke_id",
      "slice_id",
      "target",
      "axis_pair",
      "derived_correlation_target",
      "source_script",
      "output_artifact",
      "point_status",
      "profile_target_status",
      "interval_status",
      "interval_source",
      "denominator_policy",
      "mcse_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_interval_smoke), 6L)
  expect_equal(derived_correlation_interval_smoke$slice_id, rep("SR150", 6L))
  expect_equal(
    derived_correlation_interval_smoke$target,
    rep("gaussian_q4_phylo", 6L)
  )
  expect_setequal(
    derived_correlation_interval_smoke$derived_correlation_target,
    expected_q4_derived_correlations
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke$source_script,
    "run-derived-correlation-interval-smoke.R"
  )
  expect_equal(
    derived_correlation_interval_smoke$output_artifact,
    rep("q4-derived-correlation-interval-smoke-results.tsv", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke$point_status,
    rep("corpairs_point_reconstructed", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke$profile_target_status,
    rep("profile_target_mapped", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke$interval_status,
    rep("derived_interval_unavailable", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke$interval_source,
    rep("not_available", 6L)
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke$denominator_policy,
    "unavailable"
  )
  expect_equal(
    derived_correlation_interval_smoke$mcse_status,
    rep("insufficient_replicates", 6L)
  )
  expect_equal(derived_correlation_interval_smoke$status, rep("covered", 6L))
  structured_re_expect_all_match(
    derived_correlation_interval_smoke$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_interval_smoke_results,
    c(
      "replicate_id",
      "seed",
      "sd_scale",
      "axis_pair",
      "target_name",
      "target_kind",
      "true_value",
      "estimate",
      "fit_status",
      "convergence",
      "converged",
      "pdHess",
      "max_gradient",
      "fit_elapsed_sec",
      "parameter",
      "from_dpar",
      "to_dpar",
      "class",
      "profile_target",
      "interval_method",
      "interval_status",
      "interval_source",
      "lower",
      "upper",
      "warning_context",
      "failure_reason",
      "coverage_indicator",
      "coverage_mcse",
      "failure_rate_mcse",
      "mcse_status",
      "claim_boundary"
    )
  )
  expect_equal(nrow(derived_correlation_interval_smoke_results), 6L)
  expect_equal(
    derived_correlation_interval_smoke_results$replicate_id,
    rep("derived_smoke_001", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$seed,
    rep(202606902L, 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$target_kind,
    rep("derived_correlation", 6L)
  )
  expect_setequal(
    derived_correlation_interval_smoke_results$target_name,
    expected_q4_derived_correlations
  )
  expect_equal(
    derived_correlation_interval_smoke_results$fit_status,
    rep("fit_ok", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$convergence,
    rep(0L, 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$converged,
    rep(TRUE, 6L)
  )
  expect_equal(derived_correlation_interval_smoke_results$pdHess, rep(TRUE, 6L))
  structured_re_expect_all_match(
    derived_correlation_interval_smoke_results$profile_target,
    "cor:phylo:"
  )
  expect_equal(
    derived_correlation_interval_smoke_results$interval_status,
    rep("derived_interval_unavailable", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$interval_source,
    rep("not_available", 6L)
  )
  expect_equal(
    is.na(derived_correlation_interval_smoke_results$interval_method),
    rep(TRUE, 6L)
  )
  expect_equal(
    is.na(derived_correlation_interval_smoke_results$lower),
    rep(TRUE, 6L)
  )
  expect_equal(
    is.na(derived_correlation_interval_smoke_results$upper),
    rep(TRUE, 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$warning_context,
    rep("none", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$failure_reason,
    rep("derived_interval_unavailable_by_profile_targets", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$coverage_indicator,
    rep("not_evaluated", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$coverage_mcse,
    rep("not_computed_single_replicate", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$failure_rate_mcse,
    rep("not_computed_single_replicate", 6L)
  )
  expect_equal(
    derived_correlation_interval_smoke_results$mcse_status,
    rep("insufficient_replicates", 6L)
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke_results$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke_results$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke_results$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke_results$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_interval_smoke_results$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_diagnostic,
    c(
      "diagnostic_id",
      "slice_id",
      "target",
      "axis_pair",
      "derived_correlation_target",
      "source_script",
      "output_artifact",
      "reconstruction_status",
      "report_match_status",
      "interval_method",
      "interval_status",
      "interval_source",
      "denominator_policy",
      "mcse_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_diagnostic), 6L)
  expect_equal(derived_correlation_delta_diagnostic$slice_id, rep("SR150", 6L))
  expect_equal(
    derived_correlation_delta_diagnostic$target,
    rep("gaussian_q4_phylo", 6L)
  )
  expect_setequal(
    derived_correlation_delta_diagnostic$derived_correlation_target,
    expected_q4_derived_correlations
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic$source_script,
    "run-derived-correlation-delta-diagnostic.R"
  )
  expect_equal(
    derived_correlation_delta_diagnostic$output_artifact,
    rep("q4-derived-correlation-delta-diagnostic-results.tsv", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic$reconstruction_status,
    rep("finite_difference_delta_available", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic$report_match_status,
    rep("corpairs_matches_report", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic$interval_method,
    rep("wald_delta_finite_difference", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic$interval_status,
    rep("finite_delta_diagnostic", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic$interval_source,
    rep("finite_difference_delta", 6L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic$denominator_policy,
    "denominator"
  )
  expect_equal(
    derived_correlation_delta_diagnostic$mcse_status,
    rep("insufficient_replicates", 6L)
  )
  expect_equal(derived_correlation_delta_diagnostic$status, rep("covered", 6L))
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic$claim_boundary,
    "broad bridge support"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic$next_gate,
    "MCSE"
  )

  expect_named(
    derived_correlation_delta_diagnostic_results,
    c(
      "replicate_id",
      "seed",
      "sd_scale",
      "axis_pair",
      "target_name",
      "target_kind",
      "true_value",
      "corpairs_estimate",
      "report_estimate",
      "max_abs_report_corpairs_delta",
      "delta_se",
      "lower",
      "upper",
      "interval_method",
      "interval_status",
      "interval_source",
      "boundary_clamped",
      "gradient_l2",
      "finite_difference_step_min",
      "finite_difference_step_max",
      "theta_parameter_count",
      "theta_covariance_status",
      "fit_status",
      "convergence",
      "converged",
      "pdHess",
      "max_gradient",
      "fit_elapsed_sec",
      "warning_context",
      "coverage_indicator",
      "coverage_mcse",
      "failure_rate_mcse",
      "mcse_status",
      "claim_boundary"
    )
  )
  expect_equal(nrow(derived_correlation_delta_diagnostic_results), 6L)
  expect_equal(
    derived_correlation_delta_diagnostic_results$replicate_id,
    rep("derived_delta_001", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$seed,
    rep(202606902L, 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$target_kind,
    rep("derived_correlation", 6L)
  )
  expect_setequal(
    derived_correlation_delta_diagnostic_results$target_name,
    expected_q4_derived_correlations
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$interval_method,
    rep("wald_delta_finite_difference", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$interval_status,
    rep("finite_delta_diagnostic", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$interval_source,
    rep("finite_difference_delta", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$boundary_clamped,
    rep(FALSE, 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$theta_parameter_count,
    rep(6L, 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$theta_covariance_status,
    rep("finite", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$fit_status,
    rep("fit_ok", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$convergence,
    rep(0L, 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$converged,
    rep(TRUE, 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$pdHess,
    rep(TRUE, 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$warning_context,
    rep("none", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$coverage_indicator,
    rep("not_evaluated", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$coverage_mcse,
    rep("not_computed_single_replicate", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$failure_rate_mcse,
    rep("not_computed_single_replicate", 6L)
  )
  expect_equal(
    derived_correlation_delta_diagnostic_results$mcse_status,
    rep("insufficient_replicates", 6L)
  )
  expect_lt(
    max(
      derived_correlation_delta_diagnostic_results$max_abs_report_corpairs_delta
    ),
    1e-8
  )
  expect_gt(min(derived_correlation_delta_diagnostic_results$delta_se), 0)
  expect_gt(min(derived_correlation_delta_diagnostic_results$gradient_l2), 0)
  expect_true(
    all(
      derived_correlation_delta_diagnostic_results$lower <
        derived_correlation_delta_diagnostic_results$upper
    )
  )
  expect_gte(min(derived_correlation_delta_diagnostic_results$lower), -1)
  expect_lte(max(derived_correlation_delta_diagnostic_results$upper), 1)
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic_results$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic_results$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic_results$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic_results$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_diagnostic_results$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_grid_contract,
    c(
      "contract_id",
      "slice_id",
      "target",
      "contract_component",
      "source_artifact",
      "required_input",
      "required_output_fields",
      "denominator_policy",
      "mcse_policy",
      "failure_policy",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_contract), 8L)
  expect_setequal(
    derived_correlation_delta_grid_contract$contract_id,
    c(
      "q4_derived_delta_grid_entrypoint",
      "q4_derived_delta_grid_seed_scale",
      "q4_derived_delta_grid_theta_report",
      "q4_derived_delta_grid_interval_fields",
      "q4_derived_delta_grid_target_set",
      "q4_derived_delta_grid_denominator",
      "q4_derived_delta_grid_mcse",
      "q4_derived_delta_grid_claim_boundary"
    )
  )
  expect_equal(
    derived_correlation_delta_grid_contract$slice_id,
    rep("SR150", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_contract$target,
    rep("gaussian_q4_phylo", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_contract$denominator_policy,
    rep("all_fit_success_warning_failure_rows_retained", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_contract$mcse_policy,
    "coverage_mcse"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_contract$mcse_policy,
    "failure_rate_mcse"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_contract$failure_policy,
    "failure_reason"
  )
  expect_equal(
    derived_correlation_delta_grid_contract$status,
    rep("covered", 8L)
  )
  expect_match(
    derived_correlation_delta_grid_contract$required_output_fields[
      derived_correlation_delta_grid_contract$contract_id ==
        "q4_derived_delta_grid_denominator"
    ],
    "coverage_indicator"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_contract$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_contract$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_contract$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_contract$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_contract$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_grid_smoke,
    c(
      "smoke_id",
      "slice_id",
      "target",
      "smoke_component",
      "source_script",
      "output_artifact",
      "observed_replicates",
      "observed_target_rows",
      "finite_delta_rows",
      "retained_denominator_rows",
      "theta_report_status",
      "interval_status",
      "mcse_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_smoke), 8L)
  expect_setequal(
    derived_correlation_delta_grid_smoke$smoke_id,
    c(
      "q4_derived_delta_grid_smoke_entrypoint",
      "q4_derived_delta_grid_smoke_seed_scale",
      "q4_derived_delta_grid_smoke_theta_report",
      "q4_derived_delta_grid_smoke_interval_fields",
      "q4_derived_delta_grid_smoke_target_set",
      "q4_derived_delta_grid_smoke_denominator",
      "q4_derived_delta_grid_smoke_mcse",
      "q4_derived_delta_grid_smoke_claim_boundary"
    )
  )
  expect_equal(derived_correlation_delta_grid_smoke$slice_id, rep("SR150", 8L))
  expect_equal(
    derived_correlation_delta_grid_smoke$target,
    rep("gaussian_q4_phylo", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke$source_script,
    "run-calibrated-grid-delta-smoke.R"
  )
  expect_equal(
    derived_correlation_delta_grid_smoke$output_artifact,
    rep("q4-derived-correlation-delta-grid-smoke-results.tsv", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke$observed_replicates,
    rep(1L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke$observed_target_rows,
    rep(6L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke$finite_delta_rows,
    rep(6L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke$retained_denominator_rows,
    rep(6L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke$theta_report_status,
    rep("full_vector_theta_phylo_report_reconstruction", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke$interval_status,
    rep("finite_delta_diagnostic", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke$mcse_status,
    rep("insufficient_replicates", 8L)
  )
  expect_equal(derived_correlation_delta_grid_smoke$status, rep("covered", 8L))
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_grid_smoke_results,
    c(
      "replicate_id",
      "seed",
      "sd_scale",
      "axis_pair",
      "target_name",
      "target_kind",
      "true_value",
      "fit_status",
      "convergence",
      "converged",
      "pdHess",
      "max_gradient",
      "fit_elapsed_sec",
      "warning_context",
      "failure_reason",
      "theta_parameter_count",
      "theta_covariance_status",
      "corpairs_estimate",
      "report_estimate",
      "max_abs_report_corpairs_delta",
      "gradient_l2",
      "finite_difference_step_min",
      "finite_difference_step_max",
      "delta_se",
      "lower",
      "upper",
      "interval_method",
      "interval_status",
      "interval_source",
      "boundary_clamped",
      "coverage_indicator",
      "coverage_mcse",
      "failure_rate_mcse",
      "mcse_status",
      "claim_boundary"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_smoke_results), 6L)
  expect_equal(
    derived_correlation_delta_grid_smoke_results$replicate_id,
    rep("delta_grid_smoke_001", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$seed,
    rep(202606902L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$target_kind,
    rep("derived_correlation", 6L)
  )
  expect_setequal(
    derived_correlation_delta_grid_smoke_results$target_name,
    expected_q4_derived_correlations
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$fit_status,
    rep("fit_ok", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$convergence,
    rep(0L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$converged,
    rep(TRUE, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$pdHess,
    rep(TRUE, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$warning_context,
    rep("none", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$failure_reason,
    rep("none", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$theta_parameter_count,
    rep(6L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$theta_covariance_status,
    rep("finite", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$interval_method,
    rep("wald_delta_finite_difference", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$interval_status,
    rep("finite_delta_diagnostic", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$interval_source,
    rep("finite_difference_delta", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$boundary_clamped,
    rep(FALSE, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$coverage_indicator,
    rep("not_evaluated", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$coverage_mcse,
    rep("not_computed_single_replicate", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$failure_rate_mcse,
    rep("not_computed_single_replicate", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_smoke_results$mcse_status,
    rep("insufficient_replicates", 6L)
  )
  expect_lt(
    max(
      derived_correlation_delta_grid_smoke_results$max_abs_report_corpairs_delta
    ),
    1e-8
  )
  expect_gt(min(derived_correlation_delta_grid_smoke_results$delta_se), 0)
  expect_gt(min(derived_correlation_delta_grid_smoke_results$gradient_l2), 0)
  expect_true(
    all(
      derived_correlation_delta_grid_smoke_results$lower <
        derived_correlation_delta_grid_smoke_results$upper
    )
  )
  expect_gte(min(derived_correlation_delta_grid_smoke_results$lower), -1)
  expect_lte(max(derived_correlation_delta_grid_smoke_results$upper), 1)
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke_results$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke_results$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke_results$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke_results$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_smoke_results$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_grid_mini,
    c(
      "mini_id",
      "slice_id",
      "target",
      "mini_component",
      "source_script",
      "output_artifact",
      "scale_levels",
      "observed_replicates",
      "observed_seed_scale_cells",
      "observed_target_rows",
      "finite_delta_rows",
      "retained_denominator_rows",
      "boundary_clamped_rows",
      "theta_report_status",
      "interval_status",
      "coverage_accounting_status",
      "mcse_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_mini), 8L)
  expect_setequal(
    derived_correlation_delta_grid_mini$mini_id,
    c(
      "q4_derived_delta_grid_mini_entrypoint",
      "q4_derived_delta_grid_mini_seed_scale",
      "q4_derived_delta_grid_mini_theta_report",
      "q4_derived_delta_grid_mini_interval_fields",
      "q4_derived_delta_grid_mini_target_set",
      "q4_derived_delta_grid_mini_denominator",
      "q4_derived_delta_grid_mini_mcse",
      "q4_derived_delta_grid_mini_claim_boundary"
    )
  )
  expect_equal(derived_correlation_delta_grid_mini$slice_id, rep("SR150", 8L))
  expect_equal(
    derived_correlation_delta_grid_mini$target,
    rep("gaussian_q4_phylo", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini$source_script,
    "run-calibrated-grid-delta-mini.R"
  )
  expect_equal(
    derived_correlation_delta_grid_mini$output_artifact,
    rep("q4-derived-correlation-delta-grid-mini-results.tsv", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$scale_levels,
    rep("0.35;0.50", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$observed_replicates,
    rep(2L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$observed_seed_scale_cells,
    rep(4L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$observed_target_rows,
    rep(24L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$finite_delta_rows,
    rep(24L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$retained_denominator_rows,
    rep(24L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$boundary_clamped_rows,
    rep(5L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$theta_report_status,
    rep("full_vector_theta_phylo_report_reconstruction", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$interval_status,
    rep("finite_delta_diagnostic", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$coverage_accounting_status,
    rep("diagnostic_true-value_accounting_retains_all_rows", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini$mcse_status,
    rep("computed_mini_grid_diagnostic_not_calibrated", 8L)
  )
  expect_equal(derived_correlation_delta_grid_mini$status, rep("covered", 8L))
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_grid_mini_results,
    names(derived_correlation_delta_grid_smoke_results)
  )
  expect_equal(nrow(derived_correlation_delta_grid_mini_results), 24L)
  expect_setequal(
    derived_correlation_delta_grid_mini_results$replicate_id,
    c(
      "delta_grid_mini_sd035_001",
      "delta_grid_mini_sd035_002",
      "delta_grid_mini_sd050_001",
      "delta_grid_mini_sd050_002"
    )
  )
  expect_setequal(
    derived_correlation_delta_grid_mini_results$seed,
    c(202606902L, 202606903L)
  )
  expect_setequal(
    derived_correlation_delta_grid_mini_results$sd_scale,
    c(0.35, 0.5)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$target_kind,
    rep("derived_correlation", 24L)
  )
  expect_setequal(
    derived_correlation_delta_grid_mini_results$target_name,
    expected_q4_derived_correlations
  )
  expect_equal(
    unname(as.integer(table(
      derived_correlation_delta_grid_mini_results$target_name
    ))),
    rep(4L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$fit_status,
    rep("fit_ok", 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$converged,
    rep(TRUE, 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$pdHess,
    rep(TRUE, 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$warning_context,
    rep("none", 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$failure_reason,
    rep("none", 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$theta_parameter_count,
    rep(6L, 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$theta_covariance_status,
    rep("finite", 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$interval_status,
    rep("finite_delta_diagnostic", 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$coverage_indicator,
    rep("delta_diagnostic_covers_true", 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$mcse_status,
    rep("computed_mini_grid_diagnostic_not_calibrated", 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$coverage_mcse,
    rep(0, 24L)
  )
  expect_equal(
    derived_correlation_delta_grid_mini_results$failure_rate_mcse,
    rep(0, 24L)
  )
  expect_equal(
    sum(derived_correlation_delta_grid_mini_results$boundary_clamped),
    5L
  )
  expect_lt(
    max(
      derived_correlation_delta_grid_mini_results$max_abs_report_corpairs_delta
    ),
    1e-8
  )
  expect_gt(min(derived_correlation_delta_grid_mini_results$delta_se), 0)
  expect_gt(min(derived_correlation_delta_grid_mini_results$gradient_l2), 0)
  expect_true(
    all(
      derived_correlation_delta_grid_mini_results$lower <
        derived_correlation_delta_grid_mini_results$upper
    )
  )
  expect_gte(min(derived_correlation_delta_grid_mini_results$lower), -1)
  expect_lte(max(derived_correlation_delta_grid_mini_results$upper), 1)
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini_results$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini_results$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini_results$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini_results$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_mini_results$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_grid_ademp,
    c(
      "contract_id",
      "slice_id",
      "target",
      "contract_component",
      "source_script",
      "output_artifact",
      "planned_n_rep",
      "scale_levels",
      "planned_seed_scale_cells",
      "planned_target_rows",
      "coverage_mcse_threshold",
      "coverage_mcse_at_nominal",
      "failure_rate_reference",
      "failure_rate_mcse_at_reference",
      "denominator_policy",
      "boundary_clamp_policy",
      "mcse_policy",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_ademp), 8L)
  expect_setequal(
    derived_correlation_delta_grid_ademp$contract_id,
    c(
      "q4_derived_delta_grid_ademp_entrypoint",
      "q4_derived_delta_grid_ademp_aims",
      "q4_derived_delta_grid_ademp_dgp",
      "q4_derived_delta_grid_ademp_estimands",
      "q4_derived_delta_grid_ademp_methods",
      "q4_derived_delta_grid_ademp_performance",
      "q4_derived_delta_grid_ademp_denominator",
      "q4_derived_delta_grid_ademp_claim_boundary"
    )
  )
  expect_equal(derived_correlation_delta_grid_ademp$slice_id, rep("SR150", 8L))
  expect_equal(
    derived_correlation_delta_grid_ademp$target,
    rep("gaussian_q4_phylo", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$source_script,
    "run-calibrated-grid-delta-ademp-dry-run.R"
  )
  expect_equal(
    derived_correlation_delta_grid_ademp$output_artifact,
    rep("q4-derived-correlation-delta-grid-ademp-dry-run.tsv", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp$planned_n_rep,
    rep(500L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp$scale_levels,
    rep("0.35;0.50", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp$planned_seed_scale_cells,
    rep(1000L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp$planned_target_rows,
    rep(6000L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp$coverage_mcse_threshold,
    rep(0.01, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp$coverage_mcse_at_nominal,
    rep(0.009747, 8L),
    tolerance = 1e-6
  )
  expect_equal(
    derived_correlation_delta_grid_ademp$failure_rate_reference,
    rep(0.05, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp$failure_rate_mcse_at_reference,
    rep(0.009747, 8L),
    tolerance = 1e-6
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$denominator_policy,
    "retain_fit_errors"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$denominator_policy,
    "boundary_clamped"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$boundary_clamp_policy,
    "count_clamped_rows"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$mcse_policy,
    "coverage_mcse_threshold_0.01"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$mcse_policy,
    "failure_rate_mcse"
  )
  expect_equal(derived_correlation_delta_grid_ademp$status, rep("covered", 8L))
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_grid_ademp_dry_run,
    c(
      "dry_run_id",
      "slice_id",
      "target",
      "sd_scale",
      "axis_pair",
      "target_name",
      "target_kind",
      "true_value",
      "planned_n_rep",
      "seed_start",
      "seed_end",
      "planned_seed_scale_cells",
      "planned_target_rows",
      "nominal_coverage",
      "coverage_mcse_threshold",
      "coverage_mcse_at_nominal",
      "failure_rate_reference",
      "failure_rate_mcse_at_reference",
      "interval_method",
      "denominator_policy",
      "boundary_clamp_policy",
      "warning_policy",
      "failure_policy",
      "mcse_policy",
      "output_schema",
      "status",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_ademp_dry_run), 12L)
  expected_ademp_ids <- with(
    expand.grid(
      scale = c("035", "050"),
      axis = sub("^cor_", "", expected_q4_derived_correlations),
      stringsAsFactors = FALSE
    ),
    paste0("q4_delta_ademp_sd", scale, "_", axis)
  )
  expect_setequal(
    derived_correlation_delta_grid_ademp_dry_run$dry_run_id,
    expected_ademp_ids
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$slice_id,
    rep("SR150", 12L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$target,
    rep("gaussian_q4_phylo", 12L)
  )
  expect_setequal(
    derived_correlation_delta_grid_ademp_dry_run$sd_scale,
    c(0.35, 0.5)
  )
  expect_setequal(
    derived_correlation_delta_grid_ademp_dry_run$target_name,
    expected_q4_derived_correlations
  )
  expect_equal(
    unname(as.integer(table(
      derived_correlation_delta_grid_ademp_dry_run$target_name
    ))),
    rep(2L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$target_kind,
    rep("derived_correlation", 12L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$true_value,
    rep(0.05, 12L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$planned_n_rep,
    rep(500L, 12L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$seed_start,
    rep(202607500L, 12L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$seed_end,
    rep(202607999L, 12L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$planned_seed_scale_cells,
    rep(1000L, 12L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$planned_target_rows,
    rep(6000L, 12L)
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$coverage_mcse_at_nominal,
    rep(0.009747, 12L),
    tolerance = 1e-6
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$failure_rate_mcse_at_reference,
    rep(0.009747, 12L),
    tolerance = 1e-6
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$interval_method,
    rep("wald_delta_finite_difference", 12L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$denominator_policy,
    "retain_fit_errors"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$denominator_policy,
    "pdHess_false"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$denominator_policy,
    "boundary_clamped"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$output_schema,
    "coverage_mcse"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$output_schema,
    "failure_rate_mcse"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$output_schema,
    "boundary_clamped"
  )
  expect_equal(
    derived_correlation_delta_grid_ademp_dry_run$status,
    rep("dry_run_contract", 12L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_ademp_dry_run$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_grid_resumable,
    c(
      "smoke_id",
      "slice_id",
      "target",
      "smoke_component",
      "source_script",
      "delegated_smoke_script",
      "contract_source",
      "manifest_artifact",
      "run_log_artifact",
      "cell_output_root",
      "observed_cells",
      "computed_actions",
      "skipped_actions",
      "observed_target_rows",
      "finite_delta_rows",
      "retained_denominator_rows",
      "boundary_clamped_rows",
      "denominator_policy",
      "resumability_status",
      "mcse_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_resumable), 8L)
  expect_setequal(
    derived_correlation_delta_grid_resumable$smoke_id,
    c(
      "q4_derived_delta_grid_resumable_entrypoint",
      "q4_derived_delta_grid_resumable_output_root",
      "q4_derived_delta_grid_resumable_compute",
      "q4_derived_delta_grid_resumable_resume_skip",
      "q4_derived_delta_grid_resumable_target_rows",
      "q4_derived_delta_grid_resumable_denominator",
      "q4_derived_delta_grid_resumable_mcse",
      "q4_derived_delta_grid_resumable_claim_boundary"
    )
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$slice_id,
    rep("SR150", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$target,
    rep("gaussian_q4_phylo", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable$source_script,
    "run-calibrated-grid-delta-resumable-smoke.R"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable$delegated_smoke_script,
    "run-calibrated-grid-delta-smoke.R"
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$contract_source,
    rep("q4-derived-correlation-delta-grid-ademp-dry-run.tsv", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$observed_cells,
    rep(24L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$computed_actions,
    rep(24L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$skipped_actions,
    rep(24L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$observed_target_rows,
    rep(144L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$finite_delta_rows,
    rep(142L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$retained_denominator_rows,
    rep(144L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$boundary_clamped_rows,
    rep(27L, 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable$denominator_policy,
    "retain_fit_errors"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable$denominator_policy,
    "boundary_clamped"
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$resumability_status,
    rep("resume_skip_verified", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$mcse_status,
    rep("insufficient_replicates_resumability_smoke", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable$status,
    rep("covered", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_grid_resumable_manifest,
    c(
      "manifest_id",
      "slice_id",
      "target",
      "source_script",
      "delegated_smoke_script",
      "contract_source",
      "output_root",
      "manifest_artifact",
      "run_log_artifact",
      "cell_outputs",
      "planned_n_rep",
      "scale_levels",
      "cell_limit",
      "observed_cells",
      "computed_actions",
      "skipped_actions",
      "observed_target_rows",
      "finite_delta_rows",
      "retained_denominator_rows",
      "warning_rows",
      "failure_rows",
      "boundary_clamped_rows",
      "coverage_evaluable_rows",
      "coverage_mcse",
      "failure_rate_mcse",
      "mcse_status",
      "resumability_status",
      "denominator_policy",
      "status",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_resumable_manifest), 1L)
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$manifest_id,
    "q4_derived_delta_grid_resumable_smoke_manifest"
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$slice_id,
    "SR150"
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$target,
    "gaussian_q4_phylo"
  )
  expect_match(
    derived_correlation_delta_grid_resumable_manifest$source_script,
    "run-calibrated-grid-delta-resumable-smoke.R",
    fixed = TRUE
  )
  expect_match(
    derived_correlation_delta_grid_resumable_manifest$delegated_smoke_script,
    "run-calibrated-grid-delta-smoke.R",
    fixed = TRUE
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$contract_source,
    "q4-derived-correlation-delta-grid-ademp-dry-run.tsv"
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$planned_n_rep,
    8L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$scale_levels,
    "0.35;0.5;0.65"
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$cell_limit,
    24L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$observed_cells,
    24L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$computed_actions,
    24L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$skipped_actions,
    24L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$observed_target_rows,
    144L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$finite_delta_rows,
    142L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$retained_denominator_rows,
    144L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$warning_rows,
    48L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$failure_rows,
    30L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$boundary_clamped_rows,
    27L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$coverage_evaluable_rows,
    0L
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$coverage_mcse,
    "not_computed_resumability_smoke"
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$failure_rate_mcse,
    "not_computed_resumability_smoke"
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$mcse_status,
    "insufficient_replicates_resumability_smoke"
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$resumability_status,
    "resume_skip_verified"
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_manifest$status,
    "resumability_smoke_verified"
  )

  expect_named(
    derived_correlation_delta_grid_resumable_run_log,
    c(
      "run_label",
      "cell_id",
      "slice_id",
      "target",
      "seed",
      "sd_scale",
      "cell_index",
      "cell_output",
      "action",
      "previous_output_detected",
      "child_status",
      "observed_target_rows",
      "finite_delta_rows",
      "retained_denominator_rows",
      "warning_rows",
      "failure_rows",
      "boundary_clamped_rows",
      "coverage_evaluable_rows",
      "coverage_mcse",
      "failure_rate_mcse",
      "mcse_status",
      "resumability_status",
      "denominator_policy",
      "claim_boundary",
      "next_gate"
    )
  )
  expected_resumable_grid <- expand.grid(
    sd_scale = c(0.35, 0.50, 0.65),
    seed = 202607500L:202607507L,
    KEEP.OUT.ATTRS = FALSE
  )
  expected_resumable_grid$cell_index <- seq_len(nrow(expected_resumable_grid))
  expected_resumable_grid$scale_tag <- c("035", "050", "065")[
    match(expected_resumable_grid$sd_scale, c(0.35, 0.50, 0.65))
  ]
  expected_resumable_grid$cell_id <- paste0(
    "q4_delta_resumable_sd",
    expected_resumable_grid$scale_tag,
    "_seed",
    expected_resumable_grid$seed
  )
  expected_resumable_finite <- c(
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    5L,
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    6L,
    5L,
    6L
  )
  expected_resumable_warnings <- c(
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    6L,
    0L,
    0L,
    6L,
    6L,
    6L,
    6L,
    0L,
    0L,
    6L,
    0L,
    0L,
    6L,
    6L,
    0L
  )
  expected_resumable_failures <- c(
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    6L,
    6L,
    6L,
    6L,
    0L,
    0L,
    0L,
    0L,
    0L,
    0L,
    6L,
    0L
  )
  expected_resumable_clamped <- c(
    2L,
    0L,
    0L,
    3L,
    1L,
    0L,
    1L,
    0L,
    0L,
    3L,
    1L,
    0L,
    3L,
    1L,
    3L,
    1L,
    1L,
    0L,
    2L,
    1L,
    0L,
    2L,
    1L,
    1L
  )

  expect_equal(nrow(derived_correlation_delta_grid_resumable_run_log), 48L)
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$run_label,
    c(rep("r56_totoro_compute", 24L), rep("r56_totoro_resume", 24L))
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$action,
    c(rep("computed", 24L), rep("skipped_existing", 24L))
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$previous_output_detected,
    c(rep(FALSE, 24L), rep(TRUE, 24L))
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$cell_id,
    rep(expected_resumable_grid$cell_id, 2L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$seed,
    rep(expected_resumable_grid$seed, 2L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$sd_scale,
    rep(expected_resumable_grid$sd_scale, 2L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$child_status,
    rep(0L, 48L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$observed_target_rows,
    rep(6L, 48L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$finite_delta_rows,
    rep(expected_resumable_finite, 2L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$retained_denominator_rows,
    rep(6L, 48L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$warning_rows,
    rep(expected_resumable_warnings, 2L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$failure_rows,
    rep(expected_resumable_failures, 2L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$boundary_clamped_rows,
    rep(expected_resumable_clamped, 2L)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_run_log$mcse_status,
    rep("insufficient_replicates_resumability_smoke", 48L)
  )

  expect_named(
    derived_correlation_delta_grid_resumable_cell,
    names(derived_correlation_delta_grid_smoke_results)
  )
  expect_equal(nrow(derived_correlation_delta_grid_resumable_cell), 144L)
  expect_setequal(
    derived_correlation_delta_grid_resumable_cell$target_name,
    expected_q4_derived_correlations
  )
  expect_equal(
    as.integer(table(
      derived_correlation_delta_grid_resumable_cell$target_name
    )),
    rep(24L, length(expected_q4_derived_correlations))
  )
  expect_equal(
    sort(unique(derived_correlation_delta_grid_resumable_cell$seed)),
    202607500L:202607507L
  )
  expect_equal(
    sort(unique(derived_correlation_delta_grid_resumable_cell$sd_scale)),
    c(0.35, 0.50, 0.65)
  )
  expect_equal(
    derived_correlation_delta_grid_resumable_cell$fit_status,
    rep("fit_ok", 144L)
  )
  expect_equal(
    sum(derived_correlation_delta_grid_resumable_cell$converged),
    102L
  )
  expect_equal(
    sum(derived_correlation_delta_grid_resumable_cell$pdHess),
    114L
  )
  expect_equal(
    as.integer(table(
      derived_correlation_delta_grid_resumable_cell$interval_status
    )[
      c("finite_delta_diagnostic", "delta_unavailable")
    ]),
    c(142L, 2L)
  )
  expect_equal(
    as.integer(table(
      derived_correlation_delta_grid_resumable_cell$failure_reason
    )[
      c("none", "delta_interval_unavailable")
    ]),
    c(142L, 2L)
  )
  expect_equal(
    sum(
      derived_correlation_delta_grid_resumable_cell$warning_context != "none"
    ),
    48L
  )
  expect_equal(
    sum(derived_correlation_delta_grid_resumable_cell$boundary_clamped),
    27L
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable_cell$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable_cell$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable_cell$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable_cell$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_resumable_cell$claim_boundary,
    "broad bridge support"
  )

  expect_named(
    derived_correlation_delta_grid_drac_plan,
    c(
      "plan_id",
      "slice_id",
      "target",
      "plan_component",
      "source_script",
      "plan_artifact",
      "planned_n_rep",
      "scale_levels",
      "planned_workers",
      "planned_shards",
      "planned_seed_scale_cells",
      "planned_target_rows",
      "cells_per_shard",
      "write_isolation",
      "aggregate_gate",
      "mcse_policy",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_drac_plan), 8L)
  expect_setequal(
    derived_correlation_delta_grid_drac_plan$plan_id,
    c(
      "q4_derived_delta_grid_drac_shard_plan_entrypoint",
      "q4_derived_delta_grid_drac_shard_plan_workers",
      "q4_derived_delta_grid_drac_shard_plan_assignment",
      "q4_derived_delta_grid_drac_shard_plan_write_isolation",
      "q4_derived_delta_grid_drac_shard_plan_aggregate",
      "q4_derived_delta_grid_drac_shard_plan_mcse",
      "q4_derived_delta_grid_drac_shard_plan_hsquared_boundary",
      "q4_derived_delta_grid_drac_shard_plan_sr150_gate"
    )
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$slice_id,
    rep("SR150", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$target,
    rep("gaussian_q4_phylo", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$source_script,
    "run-calibrated-grid-delta-drac-shard-plan.R"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$plan_artifact,
    "q4-derived-correlation-delta-grid-drac-shard-plan.tsv"
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$planned_n_rep,
    rep(500L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$scale_levels,
    rep("0.35;0.5", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$planned_workers,
    rep(9L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$planned_shards,
    rep(9L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$planned_seed_scale_cells,
    rep(1000L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$planned_target_rows,
    rep(6000L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$cells_per_shard,
    rep("112;111;111;111;111;111;111;111;111", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$write_isolation,
    rep("private_shard_root_no_shared_append", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$aggregate_gate,
    "unique_cell_ids_equal_1000"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$mcse_policy,
    "coverage_mcse_at_0.95_equals_0.009747"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$mcse_policy,
    "failure_rate_mcse_at_0.05_equals_0.009747"
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan$status,
    rep("covered", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$claim_boundary,
    "HSquared transfer"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan$claim_boundary,
    "broad bridge support"
  )
  expect_match(
    derived_correlation_delta_grid_drac_plan$next_gate[
      derived_correlation_delta_grid_drac_plan$plan_id ==
        "q4_derived_delta_grid_drac_shard_plan_hsquared_boundary"
    ],
    "Study HSquared AI-REML source",
    fixed = TRUE
  )
  expect_match(
    derived_correlation_delta_grid_drac_plan$next_gate[
      derived_correlation_delta_grid_drac_plan$plan_id ==
        "q4_derived_delta_grid_drac_shard_plan_sr150_gate"
    ],
    "two-shard rehearsal",
    fixed = TRUE
  )

  expect_named(
    derived_correlation_delta_grid_drac_plan_artifact,
    c(
      "shard_id",
      "slice_id",
      "target",
      "worker_label",
      "worker_role",
      "n_shards",
      "shard_index",
      "planned_n_rep",
      "seed_start",
      "seed_end",
      "scale_levels",
      "planned_total_cells",
      "planned_total_target_rows",
      "planned_shard_cells",
      "planned_shard_target_rows",
      "cell_index_min",
      "cell_index_max",
      "shard_output_root",
      "shard_manifest",
      "shard_run_log",
      "aggregate_manifest",
      "aggregate_summary",
      "runner_command",
      "resume_command",
      "write_isolation",
      "assignment_policy",
      "aggregate_gate",
      "denominator_policy",
      "coverage_mcse_at_nominal",
      "failure_rate_mcse_at_reference",
      "mcse_status",
      "status",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_drac_plan_artifact), 9L)
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$shard_id,
    sprintf("q4_delta_drac_shard_%02d", seq_len(9L))
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$worker_label,
    c(
      "drac01",
      "drac02",
      "drac03",
      "drac04",
      "drac05",
      "drac06",
      "drac07",
      "drac08",
      "totoro"
    )
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$worker_role,
    c(rep("drac_cpu_worker", 8L), "totoro_cpu_worker")
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$n_shards,
    rep(9L, 9L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$shard_index,
    seq_len(9L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$planned_n_rep,
    rep(500L, 9L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$planned_total_cells,
    rep(1000L, 9L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$planned_total_target_rows,
    rep(6000L, 9L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$planned_shard_cells,
    c(112L, rep(111L, 8L))
  )
  expect_equal(
    sum(derived_correlation_delta_grid_drac_plan_artifact$planned_shard_cells),
    1000L
  )
  expect_equal(
    sum(
      derived_correlation_delta_grid_drac_plan_artifact$planned_shard_target_rows
    ),
    6000L
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$shard_output_root,
    "q4-derived-correlation-delta-grid-drac-shards"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$runner_command,
    "--n-shards=9"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$runner_command,
    "--cell-limit=1000"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$runner_command,
    "--force=false"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$runner_command,
    "--allow-large=true"
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$write_isolation,
    rep("private_shard_root_no_shared_append", 9L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$assignment_policy,
    rep("round_robin_by_seed_scale_cell_index", 9L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$aggregate_gate,
    "unique cell_id values, 1000 seed-scale cells, 6000 target rows"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$denominator_policy,
    "retain_fit_errors"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$denominator_policy,
    "pdHess_false"
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$coverage_mcse_at_nominal,
    rep(0.009747, 9L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$failure_rate_mcse_at_reference,
    rep(0.009747, 9L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$mcse_status,
    rep("planned_mcse_gate_not_run", 9L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_plan_artifact$status,
    rep("planned_not_run", 9L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_plan_artifact$claim_boundary,
    "HSquared transfer"
  )

  expect_named(
    derived_correlation_delta_grid_drac_dispatch_pack,
    c(
      "pack_id",
      "slice_id",
      "target",
      "pack_component",
      "source_script",
      "pack_manifest",
      "slurm_array_script",
      "worker_script",
      "totoro_worker_script",
      "aggregate_script",
      "planned_n_rep",
      "scale_levels",
      "planned_shards",
      "planned_drac_array_tasks",
      "planned_totoro_shards",
      "planned_seed_scale_cells",
      "planned_target_rows",
      "cells_per_shard",
      "scheduler_status",
      "compute_status",
      "storage_policy",
      "aggregate_gate",
      "mcse_policy",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_drac_dispatch_pack), 8L)
  expect_setequal(
    derived_correlation_delta_grid_drac_dispatch_pack$pack_id,
    c(
      "q4_derived_delta_grid_drac_dispatch_pack_entrypoint",
      "q4_derived_delta_grid_drac_dispatch_pack_slurm_array",
      "q4_derived_delta_grid_drac_dispatch_pack_worker",
      "q4_derived_delta_grid_drac_dispatch_pack_totoro",
      "q4_derived_delta_grid_drac_dispatch_pack_aggregate",
      "q4_derived_delta_grid_drac_dispatch_pack_storage",
      "q4_derived_delta_grid_drac_dispatch_pack_mcse",
      "q4_derived_delta_grid_drac_dispatch_pack_sr150_gate"
    )
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$slice_id,
    rep("SR150", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$target,
    rep("gaussian_q4_phylo", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$source_script,
    "write-calibrated-grid-delta-drac-dispatch-pack.R"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$pack_manifest,
    "q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$slurm_array_script,
    "q4-derived-correlation-delta-grid-array.sbatch"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$worker_script,
    "q4-derived-correlation-delta-grid-array-worker.sh"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$totoro_worker_script,
    "q4-derived-correlation-delta-grid-totoro-worker.sh"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$aggregate_script,
    "q4-derived-correlation-delta-grid-aggregate.sh"
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$planned_n_rep,
    rep(500L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$scale_levels,
    rep("0.35;0.5", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$planned_shards,
    rep(9L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$planned_drac_array_tasks,
    rep(8L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$planned_totoro_shards,
    rep(1L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$planned_seed_scale_cells,
    rep(1000L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$planned_target_rows,
    rep(6000L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$cells_per_shard,
    rep("112;111;111;111;111;111;111;111;111", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$scheduler_status,
    rep("slurm_array_dry_run_not_submitted", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$compute_status,
    rep("not_submitted", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$storage_policy,
    rep("project_backed_private_shards_no_login_node_compute", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$aggregate_gate,
    "after_all_9_shard_manifests_expect_1000_cells_6000_rows_compute_rate_mcse_true"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$mcse_policy,
    "coverage_mcse_at_0.95_equals_0.009747"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$mcse_policy,
    "failure_rate_mcse_at_0.05_equals_0.009747"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$mcse_policy,
    "diagnostic_rate_mcse_requires_compute_rate_mcse_true"
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_pack$status,
    rep("covered", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$claim_boundary,
    "interval coverage"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$claim_boundary,
    "q4 REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$claim_boundary,
    "HSquared transfer"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$claim_boundary,
    "DRAC readiness"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_pack$next_gate,
    "no compute on login nodes"
  )

  expect_named(
    derived_correlation_delta_grid_drac_dispatch_manifest,
    c(
      "pack_id",
      "slice_id",
      "target",
      "pack_component",
      "artifact_path",
      "planned_n_rep",
      "scale_levels",
      "planned_shards",
      "planned_drac_array_tasks",
      "planned_totoro_shards",
      "planned_seed_scale_cells",
      "planned_target_rows",
      "scheduler",
      "scheduler_status",
      "compute_status",
      "account_placeholder",
      "time_limit",
      "mem",
      "cpus_per_task",
      "output_root",
      "aggregate_label",
      "aggregate_gate",
      "mcse_policy",
      "storage_policy",
      "status",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_drac_dispatch_manifest), 6L)
  expect_setequal(
    derived_correlation_delta_grid_drac_dispatch_manifest$pack_component,
    c(
      "manifest",
      "drac_slurm_array",
      "drac_array_worker",
      "totoro_worker",
      "aggregate_afterok",
      "readme"
    )
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_manifest$planned_drac_array_tasks,
    rep(8L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_manifest$planned_totoro_shards,
    rep(1L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_manifest$scheduler_status,
    rep("dry_run_not_submitted", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_drac_dispatch_manifest$compute_status,
    rep("not_submitted", 6L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_manifest$scheduler,
    "slurm_template_for_drac_plus_separate_totoro_worker"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_manifest$output_root,
    "q4-derived-correlation-delta-grid-drac-shards"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_drac_dispatch_manifest$mcse_policy,
    "diagnostic_rate_mcse_requires_compute_rate_mcse_true"
  )

  expect_true(any(grepl(
    "#SBATCH --array=1-8",
    derived_correlation_delta_grid_drac_dispatch_array_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "#SBATCH --cpus-per-task=4",
    derived_correlation_delta_grid_drac_dispatch_array_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "#SBATCH --mem=16G",
    derived_correlation_delta_grid_drac_dispatch_array_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "#SBATCH --account=def-pi-placeholder",
    derived_correlation_delta_grid_drac_dispatch_array_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "SLURM_ARRAY_TASK_ID",
    derived_correlation_delta_grid_drac_dispatch_worker_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "--shard-index=\"${SHARD_INDEX}\"",
    derived_correlation_delta_grid_drac_dispatch_worker_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "--force=true",
    derived_correlation_delta_grid_drac_dispatch_worker_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "--reset-output=true",
    derived_correlation_delta_grid_drac_dispatch_worker_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "--force=false",
    derived_correlation_delta_grid_drac_dispatch_worker_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "SHARD_INDEX=9",
    derived_correlation_delta_grid_drac_dispatch_totoro_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "r63_totoro_compute",
    derived_correlation_delta_grid_drac_dispatch_totoro_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "--n-shards=9",
    derived_correlation_delta_grid_drac_dispatch_totoro_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "--expected-cells=1000",
    derived_correlation_delta_grid_drac_dispatch_aggregate_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "--expected-target-rows=6000",
    derived_correlation_delta_grid_drac_dispatch_aggregate_script,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "--compute-rate-mcse=true",
    derived_correlation_delta_grid_drac_dispatch_aggregate_script,
    fixed = TRUE
  )))
  expect_false(any(grepl(
    "gpu",
    tolower(c(
      derived_correlation_delta_grid_drac_dispatch_array_script,
      derived_correlation_delta_grid_drac_dispatch_worker_script,
      derived_correlation_delta_grid_drac_dispatch_totoro_script,
      derived_correlation_delta_grid_drac_dispatch_aggregate_script
    )),
    fixed = TRUE
  )))

  expect_named(
    derived_correlation_delta_grid_two_shard,
    c(
      "rehearsal_id",
      "slice_id",
      "target",
      "rehearsal_component",
      "source_script",
      "aggregate_script",
      "aggregate_manifest",
      "aggregate_summary",
      "n_shards",
      "expected_cells",
      "unique_cells",
      "computed_actions",
      "skipped_actions",
      "observed_target_rows",
      "finite_delta_rows",
      "retained_denominator_rows",
      "boundary_clamped_rows",
      "coverage_evaluable_rows",
      "write_isolation",
      "aggregate_status",
      "mcse_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_two_shard), 8L)
  expect_setequal(
    derived_correlation_delta_grid_two_shard$rehearsal_id,
    c(
      "q4_derived_delta_grid_two_shard_entrypoint",
      "q4_derived_delta_grid_two_shard_private_outputs",
      "q4_derived_delta_grid_two_shard_resume",
      "q4_derived_delta_grid_two_shard_aggregate",
      "q4_derived_delta_grid_two_shard_denominator",
      "q4_derived_delta_grid_two_shard_mcse",
      "q4_derived_delta_grid_two_shard_no_drac_gate",
      "q4_derived_delta_grid_two_shard_claim_boundary"
    )
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$slice_id,
    rep("SR150", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$target,
    rep("gaussian_q4_phylo", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard$source_script,
    "run-calibrated-grid-delta-resumable-smoke.R"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard$aggregate_script,
    "aggregate-calibrated-grid-delta-shards.R"
  )
  expect_equal(derived_correlation_delta_grid_two_shard$n_shards, rep(2L, 8L))
  expect_equal(
    derived_correlation_delta_grid_two_shard$expected_cells,
    rep(4L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$unique_cells,
    rep(4L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$computed_actions,
    rep(4L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$skipped_actions,
    rep(4L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$observed_target_rows,
    rep(24L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$finite_delta_rows,
    rep(24L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$retained_denominator_rows,
    rep(24L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$boundary_clamped_rows,
    rep(6L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$coverage_evaluable_rows,
    rep(0L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$write_isolation,
    rep("private_shard_root_no_shared_append", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$aggregate_status,
    rep("aggregate_verified", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$mcse_status,
    rep("insufficient_replicates_two_shard_rehearsal", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard$status,
    rep("covered", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard$claim_boundary,
    "HSquared transfer"
  )
  expect_match(
    derived_correlation_delta_grid_two_shard$next_gate[
      derived_correlation_delta_grid_two_shard$rehearsal_id ==
        "q4_derived_delta_grid_two_shard_no_drac_gate"
    ],
    "Do not use DRAC unless local or totoro evidence is insufficient",
    fixed = TRUE
  )

  expect_named(
    derived_correlation_delta_grid_two_shard_manifest,
    c(
      "aggregate_id",
      "slice_id",
      "target",
      "n_shards",
      "shard_manifests",
      "shard_run_logs",
      "unique_cells",
      "computed_actions",
      "skipped_actions",
      "expected_cells",
      "expected_target_rows",
      "observed_target_rows",
      "finite_delta_rows",
      "retained_denominator_rows",
      "warning_rows",
      "failure_rows",
      "boundary_clamped_rows",
      "coverage_evaluable_rows",
      "coverage_mcse",
      "failure_rate_mcse",
      "mcse_status",
      "denominator_policy",
      "aggregate_status",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_two_shard_manifest), 1L)
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$aggregate_id,
    "q4_delta_grid_two_shard_rehearsal_aggregate"
  )
  expect_equal(derived_correlation_delta_grid_two_shard_manifest$n_shards, 2L)
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$unique_cells,
    4L
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$computed_actions,
    4L
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$skipped_actions,
    4L
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$expected_target_rows,
    24L
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$observed_target_rows,
    24L
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$finite_delta_rows,
    24L
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$retained_denominator_rows,
    24L
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$boundary_clamped_rows,
    6L
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$coverage_evaluable_rows,
    0L
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$mcse_status,
    "insufficient_replicates_two_shard_rehearsal"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard_manifest$denominator_policy,
    "retain_fit_errors"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard_manifest$denominator_policy,
    "pdHess_false"
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_manifest$aggregate_status,
    "aggregate_verified"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard_manifest$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard_manifest$claim_boundary,
    "AI-REML"
  )

  expect_named(
    derived_correlation_delta_grid_two_shard_summary,
    c(
      "target_name",
      "observed_rows",
      "finite_delta_rows",
      "warning_rows",
      "failure_rows",
      "boundary_clamped_rows",
      "coverage_evaluable_rows",
      "retained_denominator_rows",
      "coverage_rate",
      "failure_rate",
      "warning_rate",
      "boundary_clamp_rate",
      "coverage_mcse",
      "failure_rate_mcse",
      "warning_rate_mcse",
      "boundary_clamp_rate_mcse",
      "aggregate_label",
      "mcse_status",
      "claim_boundary"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_two_shard_summary), 6L)
  expect_setequal(
    derived_correlation_delta_grid_two_shard_summary$target_name,
    expected_q4_derived_correlations
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$observed_rows,
    rep(4L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$finite_delta_rows,
    rep(4L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$warning_rows,
    rep(0L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$failure_rows,
    rep(0L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$boundary_clamped_rows,
    c(0L, 3L, 0L, 1L, 1L, 1L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$coverage_evaluable_rows,
    rep(0L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$retained_denominator_rows,
    rep(4L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$coverage_rate,
    rep("not_evaluable_two_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$failure_rate,
    rep(0, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$warning_rate,
    rep(0, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$boundary_clamp_rate,
    c(0, 0.75, 0, 0.25, 0.25, 0.25)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$coverage_mcse,
    rep("not_computed_two_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$failure_rate_mcse,
    rep("not_computed_two_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$warning_rate_mcse,
    rep("not_computed_two_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$boundary_clamp_rate_mcse,
    rep("not_computed_two_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$aggregate_label,
    rep("two_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_two_shard_summary$mcse_status,
    rep("insufficient_replicates_two_shard_rehearsal", 6L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard_summary$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_two_shard_summary$claim_boundary,
    "HSquared transfer"
  )

  expect_named(
    derived_correlation_delta_grid_local_four_shard,
    c(
      "rehearsal_id",
      "slice_id",
      "target",
      "rehearsal_component",
      "source_script",
      "aggregate_script",
      "aggregate_manifest",
      "aggregate_summary",
      "n_shards",
      "expected_cells",
      "unique_cells",
      "computed_actions",
      "skipped_actions",
      "observed_target_rows",
      "finite_delta_rows",
      "retained_denominator_rows",
      "warning_rows",
      "failure_rows",
      "boundary_clamped_rows",
      "coverage_evaluable_rows",
      "write_isolation",
      "aggregate_status",
      "mcse_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(derived_correlation_delta_grid_local_four_shard), 8L)
  expect_setequal(
    derived_correlation_delta_grid_local_four_shard$rehearsal_id,
    c(
      "q4_derived_delta_grid_local_four_shard_entrypoint",
      "q4_derived_delta_grid_local_four_shard_private_outputs",
      "q4_derived_delta_grid_local_four_shard_resume",
      "q4_derived_delta_grid_local_four_shard_aggregate",
      "q4_derived_delta_grid_local_four_shard_denominator",
      "q4_derived_delta_grid_local_four_shard_warning_failure_boundary",
      "q4_derived_delta_grid_local_four_shard_no_drac_gate",
      "q4_derived_delta_grid_local_four_shard_claim_boundary"
    )
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$slice_id,
    rep("SR150", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$target,
    rep("gaussian_q4_phylo", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard$source_script,
    "run-calibrated-grid-delta-resumable-smoke.R"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard$aggregate_script,
    "aggregate-calibrated-grid-delta-shards.R"
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$n_shards,
    rep(4L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$expected_cells,
    rep(12L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$unique_cells,
    rep(12L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$computed_actions,
    rep(12L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$skipped_actions,
    rep(12L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$observed_target_rows,
    rep(72L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$finite_delta_rows,
    rep(71L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$retained_denominator_rows,
    rep(72L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$warning_rows,
    rep(24L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$failure_rows,
    rep(18L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$boundary_clamped_rows,
    rep(17L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$coverage_evaluable_rows,
    rep(0L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$write_isolation,
    rep("private_shard_root_no_shared_append", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$aggregate_status,
    rep("aggregate_verified", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$mcse_status,
    rep("insufficient_replicates_local_four_shard_rehearsal", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard$status,
    rep("covered", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard$claim_boundary,
    "HSquared transfer"
  )
  expect_match(
    derived_correlation_delta_grid_local_four_shard$next_gate[
      derived_correlation_delta_grid_local_four_shard$rehearsal_id ==
        "q4_derived_delta_grid_local_four_shard_no_drac_gate"
    ],
    "Do not use DRAC unless local or totoro evidence is insufficient",
    fixed = TRUE
  )

  expect_named(
    derived_correlation_delta_grid_local_four_shard_manifest,
    c(
      "aggregate_id",
      "slice_id",
      "target",
      "n_shards",
      "shard_manifests",
      "shard_run_logs",
      "unique_cells",
      "computed_actions",
      "skipped_actions",
      "expected_cells",
      "expected_target_rows",
      "observed_target_rows",
      "finite_delta_rows",
      "retained_denominator_rows",
      "warning_rows",
      "failure_rows",
      "boundary_clamped_rows",
      "coverage_evaluable_rows",
      "coverage_mcse",
      "failure_rate_mcse",
      "mcse_status",
      "denominator_policy",
      "aggregate_status",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(
    nrow(derived_correlation_delta_grid_local_four_shard_manifest),
    1L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$aggregate_id,
    "q4_delta_grid_local_four_shard_rehearsal_aggregate"
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$n_shards,
    4L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$unique_cells,
    12L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$computed_actions,
    12L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$skipped_actions,
    12L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$expected_target_rows,
    72L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$observed_target_rows,
    72L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$finite_delta_rows,
    71L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$retained_denominator_rows,
    72L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$warning_rows,
    24L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$failure_rows,
    18L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$boundary_clamped_rows,
    17L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$coverage_evaluable_rows,
    0L
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$mcse_status,
    "insufficient_replicates_local_four_shard_rehearsal"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard_manifest$denominator_policy,
    "retain_fit_errors"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard_manifest$denominator_policy,
    "pdHess_false"
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_manifest$aggregate_status,
    "aggregate_verified"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard_manifest$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard_manifest$claim_boundary,
    "AI-REML"
  )

  expect_named(
    derived_correlation_delta_grid_local_four_shard_summary,
    c(
      "target_name",
      "observed_rows",
      "finite_delta_rows",
      "warning_rows",
      "failure_rows",
      "boundary_clamped_rows",
      "coverage_evaluable_rows",
      "retained_denominator_rows",
      "coverage_rate",
      "failure_rate",
      "warning_rate",
      "boundary_clamp_rate",
      "coverage_mcse",
      "failure_rate_mcse",
      "warning_rate_mcse",
      "boundary_clamp_rate_mcse",
      "aggregate_label",
      "mcse_status",
      "claim_boundary"
    )
  )
  expect_equal(
    nrow(derived_correlation_delta_grid_local_four_shard_summary),
    6L
  )
  expect_setequal(
    derived_correlation_delta_grid_local_four_shard_summary$target_name,
    expected_q4_derived_correlations
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$observed_rows,
    rep(12L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$finite_delta_rows,
    c(12L, 12L, 11L, 12L, 12L, 12L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$warning_rows,
    rep(4L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$failure_rows,
    rep(3L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$boundary_clamped_rows,
    c(0L, 4L, 1L, 2L, 2L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$coverage_evaluable_rows,
    rep(0L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$retained_denominator_rows,
    rep(12L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$coverage_rate,
    rep("not_evaluable_local_four_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$failure_rate,
    rep(0.25, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$warning_rate,
    rep(0.333333333333333, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$boundary_clamp_rate,
    c(
      0,
      0.333333333333333,
      0.0833333333333333,
      0.166666666666667,
      0.166666666666667,
      0.666666666666667
    )
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$coverage_mcse,
    rep("not_computed_local_four_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$failure_rate_mcse,
    rep("not_computed_local_four_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$warning_rate_mcse,
    rep("not_computed_local_four_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$boundary_clamp_rate_mcse,
    rep("not_computed_local_four_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$aggregate_label,
    rep("local_four_shard_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_four_shard_summary$mcse_status,
    rep("insufficient_replicates_local_four_shard_rehearsal", 6L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard_summary$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_four_shard_summary$claim_boundary,
    "HSquared transfer"
  )

  expect_named(
    derived_correlation_delta_grid_local_eight_shard_medium,
    names(derived_correlation_delta_grid_local_four_shard)
  )
  expect_equal(
    nrow(derived_correlation_delta_grid_local_eight_shard_medium),
    8L
  )
  expect_setequal(
    derived_correlation_delta_grid_local_eight_shard_medium$rehearsal_id,
    c(
      "q4_derived_delta_grid_local_eight_shard_medium_entrypoint",
      "q4_derived_delta_grid_local_eight_shard_medium_private_outputs",
      "q4_derived_delta_grid_local_eight_shard_medium_resume",
      "q4_derived_delta_grid_local_eight_shard_medium_aggregate",
      "q4_derived_delta_grid_local_eight_shard_medium_denominator",
      "q4_derived_delta_grid_local_eight_shard_medium_warning_failure_boundary",
      "q4_derived_delta_grid_local_eight_shard_medium_no_drac_gate",
      "q4_derived_delta_grid_local_eight_shard_medium_claim_boundary"
    )
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$slice_id,
    rep("SR150", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$target,
    rep("gaussian_q4_phylo", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium$source_script,
    "run-calibrated-grid-delta-resumable-smoke.R"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium$aggregate_script,
    "aggregate-calibrated-grid-delta-shards.R"
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$n_shards,
    rep(8L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$expected_cells,
    rep(48L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$unique_cells,
    rep(48L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$computed_actions,
    rep(48L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$skipped_actions,
    rep(48L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$observed_target_rows,
    rep(288L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$finite_delta_rows,
    rep(276L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$retained_denominator_rows,
    rep(288L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$warning_rows,
    rep(156L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$failure_rows,
    rep(108L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$boundary_clamped_rows,
    rep(61L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$coverage_evaluable_rows,
    rep(0L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$write_isolation,
    rep("private_shard_root_no_shared_append", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$aggregate_status,
    rep("aggregate_verified", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$mcse_status,
    rep("insufficient_replicates_local_eight_shard_medium_rehearsal", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium$status,
    rep("covered", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium$claim_boundary,
    "HSquared transfer"
  )
  expect_match(
    derived_correlation_delta_grid_local_eight_shard_medium$next_gate[
      derived_correlation_delta_grid_local_eight_shard_medium$rehearsal_id ==
        "q4_derived_delta_grid_local_eight_shard_medium_no_drac_gate"
    ],
    "Do not use DRAC unless local or totoro evidence is insufficient",
    fixed = TRUE
  )

  expect_named(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest,
    names(derived_correlation_delta_grid_local_four_shard_manifest)
  )
  expect_equal(
    nrow(derived_correlation_delta_grid_local_eight_shard_medium_manifest),
    1L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$aggregate_id,
    "q4_delta_grid_local_eight_shard_medium_rehearsal_aggregate"
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$n_shards,
    8L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$unique_cells,
    48L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$computed_actions,
    48L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$skipped_actions,
    48L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$expected_target_rows,
    288L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$observed_target_rows,
    288L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$finite_delta_rows,
    276L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$retained_denominator_rows,
    288L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$warning_rows,
    156L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$failure_rows,
    108L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$boundary_clamped_rows,
    61L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$coverage_evaluable_rows,
    0L
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$mcse_status,
    "insufficient_replicates_local_eight_shard_medium_rehearsal"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$denominator_policy,
    "retain_fit_errors"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$denominator_policy,
    "pdHess_false"
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$aggregate_status,
    "aggregate_verified"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium_manifest$claim_boundary,
    "AI-REML"
  )

  expect_named(
    derived_correlation_delta_grid_local_eight_shard_medium_summary,
    names(derived_correlation_delta_grid_local_four_shard_summary)
  )
  expect_equal(
    nrow(derived_correlation_delta_grid_local_eight_shard_medium_summary),
    6L
  )
  expect_setequal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$target_name,
    expected_q4_derived_correlations
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$observed_rows,
    rep(48L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$finite_delta_rows,
    c(46L, 47L, 43L, 47L, 47L, 46L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$warning_rows,
    rep(26L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$failure_rows,
    rep(18L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$boundary_clamped_rows,
    c(0L, 8L, 12L, 8L, 8L, 25L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$coverage_evaluable_rows,
    rep(0L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$retained_denominator_rows,
    rep(48L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$coverage_rate,
    rep("not_evaluable_local_eight_shard_medium_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$failure_rate,
    rep(0.375, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$warning_rate,
    rep(0.541666666666667, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$boundary_clamp_rate,
    c(
      0,
      0.166666666666667,
      0.25,
      0.166666666666667,
      0.166666666666667,
      0.520833333333333
    )
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$coverage_mcse,
    rep("not_computed_local_eight_shard_medium_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$failure_rate_mcse,
    rep("not_computed_local_eight_shard_medium_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$warning_rate_mcse,
    rep("not_computed_local_eight_shard_medium_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$boundary_clamp_rate_mcse,
    rep("not_computed_local_eight_shard_medium_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$aggregate_label,
    rep("local_eight_shard_medium_rehearsal", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$mcse_status,
    rep("insufficient_replicates_local_eight_shard_medium_rehearsal", 6L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_eight_shard_medium_summary$claim_boundary,
    "HSquared transfer"
  )

  expect_named(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid,
    names(derived_correlation_delta_grid_local_four_shard)
  )
  expect_equal(
    nrow(derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid),
    8L
  )
  expect_setequal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$rehearsal_id,
    c(
      "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_entrypoint",
      "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_private_outputs",
      "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_resume",
      "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_aggregate",
      "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_denominator",
      "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_diagnostic_mcse",
      "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_no_drac_gate",
      "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_claim_boundary"
    )
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$slice_id,
    rep("SR150", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$target,
    rep("gaussian_q4_phylo", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$source_script,
    "run-calibrated-grid-delta-resumable-smoke.R"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$aggregate_script,
    "aggregate-calibrated-grid-delta-shards.R"
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$n_shards,
    rep(16L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$expected_cells,
    rep(96L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$unique_cells,
    rep(96L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$computed_actions,
    rep(96L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$skipped_actions,
    rep(96L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$observed_target_rows,
    rep(576L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$finite_delta_rows,
    rep(555L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$retained_denominator_rows,
    rep(576L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$warning_rows,
    rep(306L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$failure_rows,
    rep(192L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$boundary_clamped_rows,
    rep(126L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$coverage_evaluable_rows,
    rep(0L, 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$write_isolation,
    rep("private_shard_root_no_shared_append", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$aggregate_status,
    rep("aggregate_verified", 8L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$mcse_status,
    rep(
      "diagnostic_rate_mcse_computed_coverage_not_evaluable_local_sixteen_shard_mcse_pregrid",
      8L
    )
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$status,
    rep("covered", 8L)
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$claim_boundary,
    "AI-REML"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$claim_boundary,
    "HSquared transfer"
  )
  expect_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$next_gate[
      derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$rehearsal_id ==
        "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_diagnostic_mcse"
    ],
    "coverage remains not_evaluable",
    fixed = TRUE
  )
  expect_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$next_gate[
      derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid$rehearsal_id ==
        "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_no_drac_gate"
    ],
    "Do not use DRAC unless local or totoro runtime is insufficient",
    fixed = TRUE
  )

  expect_named(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest,
    names(derived_correlation_delta_grid_local_four_shard_manifest)
  )
  expect_equal(
    nrow(
      derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest
    ),
    1L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$aggregate_id,
    "q4_delta_grid_local_sixteen_shard_mcse_pregrid_aggregate"
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$n_shards,
    16L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$unique_cells,
    96L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$computed_actions,
    96L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$skipped_actions,
    96L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$expected_target_rows,
    576L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$observed_target_rows,
    576L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$finite_delta_rows,
    555L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$retained_denominator_rows,
    576L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$warning_rows,
    306L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$failure_rows,
    192L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$boundary_clamped_rows,
    126L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$coverage_evaluable_rows,
    0L
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$coverage_mcse,
    "not_evaluable_local_sixteen_shard_mcse_pregrid"
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$failure_rate_mcse,
    0.0483650833406674,
    tolerance = 1e-12
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$mcse_status,
    "diagnostic_rate_mcse_computed_coverage_not_evaluable_local_sixteen_shard_mcse_pregrid"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$denominator_policy,
    "retain_fit_errors"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$denominator_policy,
    "pdHess_false"
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$aggregate_status,
    "aggregate_verified"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_manifest$claim_boundary,
    "AI-REML"
  )

  expect_named(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary,
    names(derived_correlation_delta_grid_local_four_shard_summary)
  )
  expect_equal(
    nrow(
      derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary
    ),
    6L
  )
  expect_setequal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$target_name,
    expected_q4_derived_correlations
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$observed_rows,
    rep(96L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$finite_delta_rows,
    c(94L, 94L, 89L, 94L, 91L, 93L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$warning_rows,
    rep(51L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$failure_rows,
    rep(32L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$boundary_clamped_rows,
    c(0L, 17L, 22L, 17L, 19L, 51L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$coverage_evaluable_rows,
    rep(0L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$retained_denominator_rows,
    rep(96L, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$coverage_rate,
    rep("not_evaluable_local_sixteen_shard_mcse_pregrid", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$failure_rate,
    rep(0.333333333333333, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$warning_rate,
    rep(0.53125, 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$boundary_clamp_rate,
    c(
      0,
      0.177083333333333,
      0.229166666666667,
      0.177083333333333,
      0.197916666666667,
      0.53125
    )
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$coverage_mcse,
    rep("not_evaluable_local_sixteen_shard_mcse_pregrid", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$failure_rate_mcse,
    rep(0.0481125224324688, 6L),
    tolerance = 1e-12
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$warning_rate_mcse,
    rep(0.0509312687906457, 6L),
    tolerance = 1e-12
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$boundary_clamp_rate_mcse,
    c(
      0,
      0.0389610952303824,
      0.0428963510437703,
      0.0389610952303824,
      0.0406644884648323,
      0.0509312687906457
    ),
    tolerance = 1e-12
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$aggregate_label,
    rep("local_sixteen_shard_mcse_pregrid", 6L)
  )
  expect_equal(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$mcse_status,
    rep(
      "diagnostic_rate_mcse_computed_coverage_not_evaluable_local_sixteen_shard_mcse_pregrid",
      6L
    )
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$claim_boundary,
    "no q4 interval reliability"
  )
  structured_re_expect_all_match(
    derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_summary$claim_boundary,
    "HSquared transfer"
  )

  expect_named(
    direct_exports,
    c(
      "export_id",
      "target",
      "axis",
      "dimension",
      "route",
      "estimator",
      "direct_sd_target",
      "sigma_a_source",
      "direct_status",
      "bridge_status",
      "inference_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(direct_exports), 4L)
  expect_equal(direct_exports$axis, c("mu1", "mu2", "sigma1", "sigma2"))
  expect_equal(
    direct_exports$direct_sd_target,
    c("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2")
  )
  expect_equal(direct_exports$route, rep("direct_drmjl", 4L))
  expect_equal(direct_exports$estimator, rep("ML", 4L))
  expect_equal(
    direct_exports$direct_status,
    rep("available_point_target", 4L)
  )
  expect_equal(direct_exports$bridge_status, rep("experimental", 4L))
  expect_equal(direct_exports$inference_status, rep("point_target_only", 4L))
  expect_equal(direct_exports$status, rep("covered", 4L))
  structured_re_expect_all_match(
    direct_exports$claim_boundary,
    "no R-via-Julia q4 bridge parity"
  )
  structured_re_expect_all_match(
    direct_exports$claim_boundary,
    "interval coverage"
  )

  expect_named(
    deterministic_fixture,
    c(
      "fixture_id",
      "target",
      "n_species",
      "n_obs",
      "tree_id",
      "axes",
      "direct_sd_targets",
      "truth_status",
      "data_status",
      "fit_status",
      "bridge_status",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(deterministic_fixture), 1L)
  expect_equal(deterministic_fixture$fixture_id, "q4_deterministic_balanced8")
  expect_equal(deterministic_fixture$n_species, 8L)
  expect_equal(deterministic_fixture$n_obs, 16L)
  expect_equal(deterministic_fixture$truth_status, "known_truth_sigma_a")
  expect_equal(deterministic_fixture$data_status, "deterministic_fixture")
  expect_equal(
    deterministic_fixture$fit_status,
    "not_fit_in_fixture_contract"
  )
  expect_equal(deterministic_fixture$bridge_status, "planned")
  expect_match(
    deterministic_fixture$direct_sd_targets,
    "sd_sigma2",
    fixed = TRUE
  )
  expect_match(
    deterministic_fixture$claim_boundary,
    "no q4 parity",
    fixed = TRUE
  )
  expect_match(
    deterministic_fixture$claim_boundary,
    "interval coverage",
    fixed = TRUE
  )

  expect_named(
    tolerance_policy,
    c(
      "policy_id",
      "target",
      "quantity",
      "comparator_routes",
      "tolerance",
      "tolerance_scale",
      "required_fixture",
      "acceptance_use",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(tolerance_policy), 4L)
  expect_setequal(
    tolerance_policy$quantity,
    c(
      "logLik",
      "fixed_coefficients",
      "direct_sd_targets",
      "derived_correlations"
    )
  )
  structured_re_expect_all_match(
    tolerance_policy$comparator_routes,
    "native_tmb;direct_drmjl;r_via_julia"
  )
  expect_true(all(nzchar(tolerance_policy$tolerance)))
  expect_equal(
    tolerance_policy$required_fixture,
    rep("q4_deterministic_balanced8", 4L)
  )
  expect_equal(
    tolerance_policy$acceptance_use,
    rep("predeclared_policy_only", 4L)
  )
  expect_equal(tolerance_policy$status, rep("covered", 4L))
  expect_equal(tolerance_policy$bridge_status, rep("planned", 4L))
  structured_re_expect_all_match(
    tolerance_policy$claim_boundary,
    "no q4 parity"
  )
  structured_re_expect_all_match(
    tolerance_policy$claim_boundary,
    "interval coverage"
  )

  expect_named(
    same_fixture_probe,
    c(
      "probe_id",
      "target",
      "fixture_id",
      "comparator_routes",
      "native_tmb_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "loglik_delta",
      "max_abs_cor_delta",
      "tolerance_result",
      "acceptance_status",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(same_fixture_probe), 1L)
  expect_equal(same_fixture_probe$target, "gaussian_q4_phylo")
  expect_equal(
    same_fixture_probe$native_tmb_status,
    "nonconverged_false_convergence_code1"
  )
  expect_equal(
    same_fixture_probe$direct_drmjl_status,
    "point_matrix_export_available_not_compared"
  )
  expect_equal(
    same_fixture_probe$r_via_julia_status,
    "converged_point_extractor"
  )
  expect_equal(
    same_fixture_probe$acceptance_status,
    "negative_probe_superseded_by_calibrated_probe"
  )
  expect_equal(same_fixture_probe$status, "covered")
  expect_equal(same_fixture_probe$bridge_status, "experimental")
  expect_gt(as.numeric(same_fixture_probe$max_abs_cor_delta), 0.05)
  expect_lt(as.numeric(same_fixture_probe$loglik_delta), 1e-3)
  expect_match(
    same_fixture_probe$tolerance_result,
    "native_nonconverged",
    fixed = TRUE
  )
  expect_match(
    same_fixture_probe$tolerance_result,
    "gt_0.05",
    fixed = TRUE
  )
  expect_match(
    same_fixture_probe$claim_boundary,
    "retained negative evidence",
    fixed = TRUE
  )
  expect_match(
    same_fixture_probe$claim_boundary,
    "interval coverage",
    fixed = TRUE
  )

  expect_named(
    calibrated_probe,
    c(
      "probe_id",
      "target",
      "fixture_id",
      "seed",
      "n_tip",
      "n_each",
      "comparator_routes",
      "native_tmb_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "loglik_delta_native_bridge",
      "loglik_delta_direct_bridge",
      "max_abs_fixef_native_bridge",
      "max_abs_sd_native_bridge",
      "max_abs_sd_direct_bridge",
      "max_abs_cor_native_bridge",
      "max_abs_cor_direct_bridge",
      "tolerance_result",
      "acceptance_status",
      "reconstruction_status",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(calibrated_probe), 2L)
  expect_equal(calibrated_probe$target, rep("gaussian_q4_phylo", 2L))
  expect_equal(calibrated_probe$n_tip, rep(32L, 2L))
  structured_re_expect_all_match(
    calibrated_probe$comparator_routes,
    "native_tmb;direct_drmjl;r_via_julia"
  )
  expect_equal(
    calibrated_probe$direct_drmjl_status,
    rep("converged_point_matrix_export_matches_wrapper", 2L)
  )
  expect_equal(
    all(as.numeric(calibrated_probe$loglik_delta_direct_bridge) < 1e-12),
    TRUE
  )
  expect_equal(
    all(as.numeric(calibrated_probe$max_abs_cor_direct_bridge) < 1e-12),
    TRUE
  )
  expect_equal(
    all(as.numeric(calibrated_probe$loglik_delta_native_bridge) < 1e-3),
    TRUE
  )
  expect_equal(
    all(as.numeric(calibrated_probe$max_abs_fixef_native_bridge) < 5e-3),
    TRUE
  )
  expect_equal(
    all(as.numeric(calibrated_probe$max_abs_sd_native_bridge) < 0.02),
    TRUE
  )
  expect_equal(
    all(as.numeric(calibrated_probe$max_abs_cor_native_bridge) < 0.05),
    TRUE
  )
  expect_equal(calibrated_probe$reconstruction_status, rep("covered", 2L))
  expect_equal(calibrated_probe$status, rep("covered", 2L))
  structured_re_expect_all_match(
    calibrated_probe$tolerance_result,
    "direct_wrapper_match"
  )
  structured_re_expect_all_match(
    calibrated_probe$tolerance_result,
    "within_1e-3"
  )
  structured_re_expect_all_match(
    calibrated_probe$claim_boundary,
    "no broad q4 bridge support"
  )
  structured_re_expect_all_match(
    calibrated_probe$claim_boundary,
    "interval coverage"
  )

  expect_named(
    parity_gate,
    c(
      "gate_id",
      "target",
      "required_fixture",
      "required_quantities",
      "native_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "tolerance_policy",
      "acceptance_status",
      "missing_evidence",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(parity_gate), 1L)
  expect_equal(parity_gate$gate_id, "q4_parity_acceptance_gate")
  expect_equal(parity_gate$required_fixture, "q4_calibrated_balanced32_pair")
  expect_match(
    parity_gate$required_quantities,
    "direct_sd_targets",
    fixed = TRUE
  )
  expect_equal(
    parity_gate$native_status,
    "covered_calibrated_native_tmb_converged"
  )
  expect_equal(
    parity_gate$direct_drmjl_status,
    "covered_point_export_matches_wrapper"
  )
  expect_equal(
    parity_gate$r_via_julia_status,
    "covered_calibrated_point_parity"
  )
  expect_equal(parity_gate$tolerance_policy, "predeclared")
  expect_equal(
    parity_gate$acceptance_status,
    "covered_point_parity_no_interval_claim"
  )
  expect_equal(parity_gate$status, "covered")
  expect_equal(parity_gate$bridge_status, "experimental")
  expect_match(
    parity_gate$missing_evidence,
    "interval_reliability",
    fixed = TRUE
  )
  expect_match(parity_gate$missing_evidence, "interval_coverage", fixed = TRUE)
  expect_match(
    parity_gate$claim_boundary,
    "no broad q4 bridge support",
    fixed = TRUE
  )
  expect_match(parity_gate$claim_boundary, "interval coverage", fixed = TRUE)

  expect_named(
    corpairs_gate,
    c(
      "gate_id",
      "target",
      "extractor",
      "native_status",
      "direct_drmjl_status",
      "r_via_julia_status",
      "parity_status",
      "missing_evidence",
      "required_before_acceptance",
      "status",
      "bridge_status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_equal(nrow(corpairs_gate), 1L)
  expect_equal(corpairs_gate$parity_status, "covered_point_corpairs")
  expect_equal(corpairs_gate$status, "covered")
  expect_equal(corpairs_gate$r_via_julia_status, "covered_calibrated_corpairs")
  expect_match(
    corpairs_gate$missing_evidence,
    "interval_reliability",
    fixed = TRUE
  )
  expect_match(
    corpairs_gate$claim_boundary,
    "no broad q4 bridge support",
    fixed = TRUE
  )

  derived <- boundary[
    boundary$boundary_id == "q4_derived_correlations_interval_block",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(derived), 1L)
  expect_equal(derived$bridge_status, "unsupported")
  expect_match(derived$claim_boundary, "interval reliability", fixed = TRUE)

  point <- boundary[
    boundary$boundary_id == "q4_phylo_calibrated_point_parity",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(point), 1L)
  expect_match(point$claim_boundary, "calibrated point parity", fixed = TRUE)
  expect_match(point$claim_boundary, "no broad bridge support", fixed = TRUE)

  expect_setequal(
    reml_audit$audit_id,
    c(
      "native_tmb_q4_ml_effective",
      "native_tmb_q4_reml_rejection",
      "direct_drmjl_q4_patterson_thompson",
      "r_via_julia_q4_patterson_thompson",
      "hsquared_ai_reml_boundary"
    )
  )
  expect_equal(reml_audit$status, rep("covered", nrow(reml_audit)))
  structured_re_expect_all_match(
    reml_audit$claim_boundary,
    "not HSquared AI-REML"
  )
  structured_re_expect_all_match(reml_audit$claim_boundary, "interval coverage")
  native_reml <- reml_audit[
    reml_audit$audit_id == "native_tmb_q4_reml_rejection",
    ,
    drop = FALSE
  ]
  expect_equal(native_reml$effective_estimator, "unsupported_no_native_q4_reml")
  bridge_reml <- reml_audit[
    reml_audit$audit_id == "r_via_julia_q4_patterson_thompson",
    ,
    drop = FALSE
  ]
  expect_equal(bridge_reml$bridge_status, "experimental")
})

test_that("ADEMP design ledger requires MCSE and denominator policies", {
  design <- structured_re_read_dashboard_tsv("structured-re-ademp-design.tsv")

  expect_setequal(design$dimension, c("q1", "q2", "q4"))
  structured_re_expect_all_match(design$mcse_target, "500 replicates")
  structured_re_expect_all_match(design$failed_fit_policy, "denominators")
  structured_re_expect_all_match(
    design$interval_policy,
    "coverage|planned",
    fixed = FALSE
  )
  structured_re_expect_all_match(design$claim_boundary, "design only")
  expect_equal(design$status, rep("covered", nrow(design)))
})

test_that("coverage calibration ledger banks pilots without coverage claims", {
  calibration <- structured_re_read_dashboard_tsv(
    "structured-re-coverage-calibration-status.tsv"
  )

  expect_named(
    calibration,
    c(
      "calibration_id",
      "slice_id",
      "dimension",
      "calibration_surface",
      "artifact",
      "evidence_class",
      "grid_status",
      "interval_methods",
      "bootstrap_accounting",
      "mcse_policy",
      "failure_policy",
      "report_section",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_setequal(calibration$slice_id, paste0("SR", 142:149))
  expect_setequal(calibration$dimension, c("q1", "q2", "q4", "q1_q2_q4"))
  structured_re_expect_all_match(calibration$mcse_policy, "MCSE", fixed = FALSE)
  structured_re_expect_all_match(
    calibration$failure_policy,
    "denominator|ok;error",
    fixed = FALSE
  )
  structured_re_expect_all_match(
    calibration$claim_boundary,
    "no .*coverage|not coverage",
    fixed = FALSE
  )
  expect_equal(calibration$status, rep("covered", nrow(calibration)))

  q1 <- calibration[calibration$slice_id == "SR142", , drop = FALSE]
  expect_equal(nrow(q1), 1L)
  expect_equal(q1$evidence_class, "diagnostic_pilot")
  expect_match(q1$grid_status, "1_finite_interval", fixed = TRUE)
  expect_match(q1$claim_boundary, "no calibrated q1 coverage", fixed = TRUE)

  q2 <- calibration[calibration$slice_id == "SR143", , drop = FALSE]
  expect_equal(nrow(q2), 1L)
  expect_match(q2$grid_status, "0_finite_intervals", fixed = TRUE)
  expect_match(q2$claim_boundary, "narrow q2 fixture parity", fixed = TRUE)
  expect_match(q2$claim_boundary, "no q2 interval coverage", fixed = TRUE)

  q4 <- calibration[calibration$slice_id == "SR144", , drop = FALSE]
  expect_equal(nrow(q4), 1L)
  expect_equal(q4$evidence_class, "diagnostic_pilot")
  expect_match(q4$grid_status, "0_converged", fixed = TRUE)
  expect_match(q4$claim_boundary, "no q4", fixed = TRUE)
  expect_match(q4$claim_boundary, "AI-REML", fixed = TRUE)

  bootstrap <- calibration[calibration$slice_id == "SR146", , drop = FALSE]
  expect_equal(nrow(bootstrap), 1L)
  expect_match(bootstrap$claim_boundary, "not coverage by itself", fixed = TRUE)
})

test_that("coverage acceptance gate keeps SR150 blocked", {
  gates <- structured_re_read_dashboard_tsv(
    "structured-re-coverage-acceptance-gate.tsv"
  )

  expect_named(
    gates,
    c(
      "gate_id",
      "slice_id",
      "dimension",
      "calibration_surface",
      "source_artifact",
      "gate_status",
      "planned_n_rep",
      "observed_target_rows",
      "finite_interval_rows",
      "mcse_status",
      "missing_evidence",
      "failure_policy",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_setequal(
    gates$gate_id,
    c(
      "q1_coverage_acceptance_gate",
      "q2_coverage_acceptance_gate",
      "q4_coverage_acceptance_gate",
      "integrated_coverage_acceptance_gate"
    )
  )
  expect_equal(gates$slice_id, rep("SR150", nrow(gates)))
  expect_equal(gates$gate_status, rep("blocked", nrow(gates)))
  expect_equal(gates$status, rep("blocked", nrow(gates)))
  expect_true(all(as.integer(gates$planned_n_rep) >= 475L))
  structured_re_expect_all_match(
    gates$failure_policy,
    "denominator",
    fixed = TRUE
  )
  structured_re_expect_all_match(
    gates$claim_boundary,
    "no .*coverage|not calibrated coverage",
    fixed = FALSE
  )

  q4 <- gates[gates$dimension == "q4", , drop = FALSE]
  expect_equal(nrow(q4), 1L)
  expect_match(q4$claim_boundary, "q4 REML", fixed = TRUE)
  expect_match(q4$claim_boundary, "AI-REML", fixed = TRUE)
  expect_match(q4$missing_evidence, "finite_intervals", fixed = TRUE)

  integrated <- gates[gates$dimension == "q1_q2_q4", , drop = FALSE]
  expect_equal(nrow(integrated), 1L)
  expect_match(integrated$missing_evidence, "calibrated_grid", fixed = TRUE)
})

test_that("structured coverage diagnostic pilot artifact keeps failures visible", {
  summary <- utils::read.csv(structured_re_artifact_path(
    "docs",
    "dev-log",
    "simulation-artifacts",
    "2026-06-22-structured-coverage-unblock-pilots",
    "tables",
    "structured-coverage-pilot-summary.csv"
  ))
  rows <- utils::read.csv(structured_re_artifact_path(
    "docs",
    "dev-log",
    "simulation-artifacts",
    "2026-06-22-structured-coverage-unblock-pilots",
    "tables",
    "structured-coverage-pilot-rows.csv"
  ))

  expect_setequal(
    summary$cell,
    c("q1_phylo_mu", "q2_phylo_mu", "q4_phylo_all_four")
  )
  expect_equal(summary$claim_status, rep("pilot_only", nrow(summary)))
  expect_equal(sum(summary$n_target_rows), nrow(rows))

  q1 <- summary[summary$cell == "q1_phylo_mu", , drop = FALSE]
  expect_equal(q1$n_replicate, 3L)
  expect_equal(q1$n_fit_ok, 3L)
  expect_equal(q1$n_pdhess, 3L)
  expect_equal(q1$n_finite_intervals, 1L)
  expect_equal(q1$coverage, 1)

  q2 <- summary[summary$cell == "q2_phylo_mu", , drop = FALSE]
  expect_equal(q2$n_replicate, 3L)
  expect_equal(q2$n_target_rows, 6L)
  expect_equal(q2$n_finite_intervals, 0L)
  expect_true(is.na(q2$coverage))

  q4 <- summary[summary$cell == "q4_phylo_all_four", , drop = FALSE]
  expect_equal(q4$n_replicate, 2L)
  expect_equal(q4$n_target_rows, 8L)
  expect_equal(q4$n_converged, 0L)
  expect_equal(q4$n_finite_intervals, 0L)
  expect_true(is.na(q4$coverage))

  expect_true(all(rows$fit_ok))
  expect_true(any(rows$conf_status == "wald"))
  expect_true(any(rows$conf_status == "wald_unavailable"))
})

test_that("native REML scope ledger keeps requested and effective estimators explicit", {
  reml <- structured_re_read_dashboard_tsv(
    "structured-re-native-reml-scope-status.tsv"
  )

  expect_named(
    reml,
    c(
      "scope_id",
      "slice_id",
      "target",
      "route",
      "requested_estimator",
      "effective_estimator",
      "support_status",
      "diagnostic_fields",
      "negative_evidence",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_setequal(reml$slice_id, paste0("SR", 151:159))
  structured_re_expect_all_match(reml$diagnostic_fields, "requested_estimator")
  structured_re_expect_all_match(reml$diagnostic_fields, "effective_estimator")
  expect_equal(reml$status, rep("covered", nrow(reml)))

  q1_mu <- reml[reml$slice_id == "SR152", , drop = FALSE]
  expect_equal(nrow(q1_mu), 1L)
  expect_equal(q1_mu$effective_estimator, "REML")
  expect_match(q1_mu$claim_boundary, "mean-side phylo only", fixed = TRUE)

  q1_sigma <- reml[reml$slice_id == "SR153", , drop = FALSE]
  expect_equal(q1_sigma$effective_estimator, "unsupported")
  expect_match(q1_sigma$claim_boundary, "negative evidence", fixed = TRUE)

  q4 <- reml[reml$slice_id == "SR155", , drop = FALSE]
  expect_equal(q4$effective_estimator, "unsupported")
  expect_match(q4$claim_boundary, "HSquared AI-REML", fixed = TRUE)

  optimizer <- reml[reml$slice_id == "SR158", , drop = FALSE]
  expect_equal(optimizer$effective_estimator, "unsupported")
  expect_match(optimizer$claim_boundary, "unsupported", fixed = TRUE)

  non_gaussian <- reml[reml$slice_id == "SR159", , drop = FALSE]
  expect_equal(non_gaussian$effective_estimator, "ML_or_Laplace")
  expect_match(non_gaussian$claim_boundary, "non-Gaussian REML", fixed = TRUE)
})

test_that("scope gate ledger keeps unsupported structured gaps explicit", {
  scope <- structured_re_read_dashboard_tsv(
    "structured-re-scope-gate-status.tsv"
  )

  expect_named(
    scope,
    c(
      "gate_id",
      "slice_id",
      "wave",
      "target",
      "route_or_surface",
      "support_status",
      "evidence_class",
      "required_before_support",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_setequal(scope$slice_id, paste0("SR", 160:170))
  expect_equal(scope$status, rep("covered", nrow(scope)))

  reml_gate <- scope[scope$slice_id == "SR160", , drop = FALSE]
  expect_equal(nrow(reml_gate), 1L)
  expect_match(reml_gate$support_status, "blocked", fixed = TRUE)
  expect_match(
    reml_gate$claim_boundary,
    "does not promote q1 sigma-side",
    fixed = TRUE
  )

  unsupported <- scope[
    scope$slice_id %in% c("SR162", "SR164", "SR166", "SR168", "SR169"),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(unsupported), 5L)
  structured_re_expect_all_match(unsupported$support_status, "unsupported")

  interaction <- scope[scope$slice_id == "SR165", , drop = FALSE]
  expect_equal(nrow(interaction), 1L)
  expect_match(interaction$claim_boundary, "q1 pair-level", fixed = TRUE)

  rho12 <- scope[scope$slice_id == "SR168", , drop = FALSE]
  expect_match(rho12$claim_boundary, "residual rho12", fixed = TRUE)
})

test_that("R docs sync status ledger keeps public wording conservative", {
  docs <- structured_re_read_dashboard_tsv(
    "structured-re-r-docs-sync-status.tsv"
  )

  expect_named(
    docs,
    c(
      "sync_id",
      "slice_id",
      "surface",
      "source_file",
      "sync_status",
      "evidence_class",
      "required_terms",
      "deferred_terms",
      "scan_command",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_setequal(docs$slice_id, paste0("SR", 171:180))
  expect_equal(docs$status, rep("covered", nrow(docs)))
  structured_re_expect_all_match(
    docs$scan_command[docs$slice_id != "SR180"],
    "rg -n"
  )

  formula <- docs[docs$slice_id == "SR171", , drop = FALSE]
  expect_equal(formula$sync_status, "fixed")
  expect_match(formula$claim_boundary, "does not promote support", fixed = TRUE)

  errors <- docs[docs$slice_id == "SR175", , drop = FALSE]
  expect_match(errors$source_file, "R/drmTMB.R", fixed = TRUE)
  expect_match(errors$claim_boundary, "adds no bridge support", fixed = TRUE)

  forbidden <- docs[docs$slice_id == "SR179", , drop = FALSE]
  expect_match(forbidden$claim_boundary, "no broad support claim", fixed = TRUE)
  expect_match(forbidden$deferred_terms, "AI-REML", fixed = TRUE)

  acceptance <- docs[docs$slice_id == "SR180", , drop = FALSE]
  expect_match(
    acceptance$scan_command,
    "validate-mission-control",
    fixed = TRUE
  )
})

test_that("Julia twin status ledger records current direct and gate evidence", {
  twin <- structured_re_read_dashboard_tsv(
    "structured-re-julia-twin-status.tsv"
  )

  expect_named(
    twin,
    c(
      "sync_id",
      "slice_id",
      "repo",
      "branch",
      "head",
      "dirty_state",
      "surface",
      "evidence_class",
      "test_command",
      "test_result",
      "status",
      "evidence_url",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_setequal(twin$slice_id, paste0("SR", 181:190))
  expect_equal(twin$status, rep("covered", nrow(twin)))
  expect_equal(
    grepl("^[0-9a-f]{40}(;[0-9a-f]{40})?$", twin$head),
    rep(TRUE, nrow(twin))
  )

  direct <- twin[twin$slice_id == "SR181", , drop = FALSE]
  expect_equal(direct$repo, "DRM.jl")
  expect_match(direct$test_result, "q2 116/116 pass", fixed = TRUE)
  expect_match(
    direct$test_result,
    "R q2 phylo/animal/relmat/spatial parity 126/126 pass",
    fixed = TRUE
  )
  expect_match(direct$test_result, "q4 36/36 pass", fixed = TRUE)
  expect_match(direct$test_result, "point-matrix export", fixed = TRUE)
  expect_match(
    direct$claim_boundary,
    "not broad public R bridge support",
    fixed = TRUE
  )

  env <- twin[twin$slice_id == "SR185", , drop = FALSE]
  expect_match(env$test_result, "JuliaCall 0.17.6", fixed = TRUE)
  expect_match(env$claim_boundary, "environment evidence", fixed = TRUE)

  gate <- twin[twin$slice_id == "SR187", , drop = FALSE]
  expect_match(gate$test_result, "143 assertions passed", fixed = TRUE)
  expect_match(
    gate$claim_boundary,
    "does not make a gated row supported",
    fixed = TRUE
  )

  acceptance <- twin[twin$slice_id == "SR190", , drop = FALSE]
  expect_match(acceptance$claim_boundary, "unpromoted", fixed = TRUE)
})

test_that("Ayumi closeout ledger keeps reply and commit gates blocked", {
  closeout <- structured_re_read_dashboard_tsv(
    "structured-re-ayumi-closeout-status.tsv"
  )

  expect_named(
    closeout,
    c(
      "gate_id",
      "slice_id",
      "gate",
      "requirement",
      "current_status",
      "evidence_class",
      "evidence_url",
      "status",
      "claim_boundary",
      "next_gate"
    )
  )
  expect_setequal(closeout$slice_id, paste0("SR", 191:200))

  blocked <- closeout[
    closeout$slice_id %in% paste0("SR", 191:198),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(blocked), 8L)
  expect_equal(blocked$status, rep("blocked", nrow(blocked)))
  structured_re_expect_all_match(blocked$claim_boundary, "No")

  checkpoint <- closeout[closeout$slice_id == "SR199", , drop = FALSE]
  expect_equal(checkpoint$status, "covered")
  expect_match(
    checkpoint$evidence_url,
    "2026-06-22-231209-codex-checkpoint",
    fixed = TRUE
  )

  handoff <- closeout[closeout$slice_id == "SR200", , drop = FALSE]
  expect_equal(handoff$status, "covered")
  expect_match(handoff$claim_boundary, "current issue text", fixed = TRUE)
})
