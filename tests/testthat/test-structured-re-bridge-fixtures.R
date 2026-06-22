source_structured_re_bridge_fixtures <- function(env = parent.frame()) {
  source(
    system.file(
      "sim/R/sim_structured_re_bridge_fixtures.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("q1 bridge payload fixture carries matrix and provenance fields", {
  source_structured_re_bridge_fixtures()

  payload <- phase18_structured_re_q1_payload_fixture(
    endpoint = "mu_sigma",
    structured_type = "phylo",
    estimator = "REML"
  )

  expect_equal(payload$payload_version, "structured_re_bridge_payload_v1")
  expect_equal(payload$target$dimension, "q1")
  expect_equal(payload$target$endpoint, "mu_sigma")
  expect_equal(payload$target$estimator, "REML")
  expect_match(payload$matrix$matrix_digest, "3x3:", fixed = TRUE)
  expect_equal(nrow(payload$provenance), 1L)
  expect_equal(payload$provenance$fixture_status, "deterministic_fixture")
  expect_equal(names(payload$matrix), c("matrix_id", "matrix_digest", "value"))
  expect_equal(
    all(c("coef", "vcov", "logLik") %in% names(payload$estimates)),
    TRUE
  )
  expect_error(
    phase18_structured_re_q1_payload_fixture(endpoint = "rho12"),
    "unsupported value"
  )
})

test_that("q1 reconstruction makes unavailable inference explicit", {
  source_structured_re_bridge_fixtures()

  payload <- phase18_structured_re_q1_payload_fixture()
  reconstructed <- phase18_structured_re_reconstruct_fixture(payload)

  expect_equal(
    reconstructed$summary$reconstruction_status,
    "reconstructed_from_fixture"
  )
  expect_equal(reconstructed$coef$term, names(payload$estimates$coef))
  expect_equal(
    dim(reconstructed$vcov),
    c(length(payload$estimates$coef), length(payload$estimates$coef))
  )
  expect_equal(
    reconstructed$unavailable$extractor,
    c("profile", "bootstrap", "coverage", "corpair")
  )
  expect_equal(
    reconstructed$unavailable$status,
    c("not_evaluated", "not_evaluated", "not_evaluated", "not_applicable")
  )
  expect_match(
    reconstructed$unavailable$unavailable_reason[[3L]],
    "coverage grid",
    fixed = TRUE
  )
})

test_that("q1 parity fixture banks a blocker rather than bridge support", {
  source_structured_re_bridge_fixtures()

  native <- phase18_structured_re_reconstruct_fixture(
    phase18_structured_re_q1_payload_fixture(route = "native_tmb")
  )
  direct <- phase18_structured_re_reconstruct_fixture(
    phase18_structured_re_q1_payload_fixture(route = "direct_drmjl")
  )
  status <- phase18_structured_re_parity_status(native, direct)

  expect_equal(status$native_status, "available")
  expect_equal(status$direct_drmjl_status, "available")
  expect_equal(status$r_via_julia_status, "blocked")
  expect_equal(status$parity_status, "blocked")
  expect_equal(status$max_abs_coef_delta, 0)
  expect_equal(status$abs_loglik_delta, 0)
  expect_match(
    status$blocked_reason,
    "route_a_all_node_loglik_bug",
    fixed = TRUE
  )
  expect_match(status$claim_boundary, "does not promote", fixed = TRUE)
})

test_that("q2 fixture contract separates q2 from q2-plus-q2 and q4", {
  source_structured_re_bridge_fixtures()

  contract <- phase18_structured_re_q2_fixture_contract()

  expect_equal(nrow(contract), 3L)
  same_target <- contract[contract$fixture_id == "q2_phylo_same_target_ml", ]
  expect_equal(same_target$dimension, "q2")
  expect_equal(same_target$estimator, "ML")
  expect_match(same_target$separated_from, "q2_plus_q2", fixed = TRUE)
  expect_match(same_target$separated_from, "q4", fixed = TRUE)
  expect_equal(same_target$bridge_status, "planned")

  q2_plus <- contract[contract$fixture_id == "q2_plus_q2_not_q4", ]
  expect_equal(q2_plus$dimension, "q2_plus_q2")
  expect_match(q2_plus$claim_boundary, "not full q4", fixed = TRUE)

  reml <- contract[contract$estimator == "REML", ]
  expect_equal(reml$bridge_status, "unsupported")
  expect_match(reml$claim_boundary, "not HSquared AI-REML", fixed = TRUE)
})

test_that("q4 fixture contract separates direct SD and derived correlations", {
  source_structured_re_bridge_fixtures()

  contract <- phase18_structured_re_q4_fixture_contract()

  expect_equal(nrow(contract), 3L)
  expect_equal(contract$dimension, rep("q4", 3L))
  expect_equal(
    contract$direct_sd_targets,
    rep("sd_mu1;sd_mu2;sd_sigma1;sd_sigma2", 3L)
  )
  expect_equal(
    contract$derived_correlation_targets,
    rep("six cross-axis correlations", 3L)
  )

  derived <- contract[
    contract$fixture_id == "q4_derived_correlation_boundary",
    ,
    drop = FALSE
  ]
  expect_equal(derived$bridge_status, "unsupported")
  expect_match(derived$claim_boundary, "not direct SD targets", fixed = TRUE)

  intervals <- contract[
    contract$fixture_id == "q4_interval_unavailable_boundary",
    ,
    drop = FALSE
  ]
  expect_equal(intervals$interval_status, "unavailable")
  expect_match(intervals$claim_boundary, "no interval", fixed = TRUE)
})
