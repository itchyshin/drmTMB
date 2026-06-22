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

structured_re_expect_all_match <- function(x, pattern, fixed = TRUE) {
  expect_equal(grepl(pattern, x, fixed = fixed), rep(TRUE, length(x)))
}

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

  expect_equal(parity$r_via_julia_path, rep("planned", nrow(parity)))
  expect_equal(parity$bridge_status, rep("planned", nrow(parity)))
  structured_re_expect_all_match(parity$claim_boundary, "not banked")
  expect_equal(nchar(parity$next_gate) > 0, rep(TRUE, nrow(parity)))
  expect_match(parity$next_gate[[1L]], "R-via-Julia", fixed = TRUE)
  expect_match(parity$next_gate[[nrow(parity)]], "native fixture", fixed = TRUE)
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

  q2_ml <- targets[
    targets$dimension == "q2" & targets$estimator == "ML",
    ,
    drop = FALSE
  ]
  expect_equal(q2_ml$inference_status, rep("point_only", nrow(q2_ml)))
  structured_re_expect_all_match(q2_ml$separated_from, "q4")

  q2_plus <- targets[targets$dimension == "q2_plus_q2", , drop = FALSE]
  expect_equal(nrow(q2_plus), 1L)
  expect_match(q2_plus$claim_boundary, "not full q4", fixed = TRUE)

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

  expect_setequal(boundary$bridge_status, c("planned", "unsupported"))
  expect_equal(nchar(boundary$negative_evidence) > 0, rep(TRUE, nrow(boundary)))
  structured_re_expect_all_match(boundary$claim_boundary, "bridge")
})

test_that("q4 contracts keep smoke, extractor, and interval boundaries separate", {
  targets <- structured_re_read_dashboard_tsv(
    "structured-re-q4-target-contract.tsv"
  )
  extractor <- structured_re_read_dashboard_tsv(
    "structured-re-q4-extractor-parity.tsv"
  )
  boundary <- structured_re_read_dashboard_tsv(
    "structured-re-q4-bridge-boundary.tsv"
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

  derived <- boundary[
    boundary$boundary_id == "q4_derived_correlations_block_bridge",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(derived), 1L)
  expect_equal(derived$bridge_status, "unsupported")
  expect_match(derived$claim_boundary, "cannot be promoted", fixed = TRUE)

  smoke <- boundary[
    boundary$boundary_id == "q4_phylo_smoke_is_smoke",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(smoke), 1L)
  expect_match(smoke$claim_boundary, "remains smoke", fixed = TRUE)
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
