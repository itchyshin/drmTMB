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

test_that("q1 parity fixture records three-route agreement without broad support", {
  source_structured_re_bridge_fixtures()

  native <- phase18_structured_re_reconstruct_fixture(
    phase18_structured_re_q1_payload_fixture(route = "native_tmb")
  )
  direct <- phase18_structured_re_reconstruct_fixture(
    phase18_structured_re_q1_payload_fixture(route = "direct_drmjl")
  )
  bridge <- phase18_structured_re_reconstruct_fixture(
    phase18_structured_re_q1_payload_fixture(route = "r_via_julia")
  )
  status <- phase18_structured_re_parity_status(native, direct, bridge)

  expect_equal(status$native_status, "available")
  expect_equal(status$direct_drmjl_status, "available")
  expect_equal(status$r_via_julia_status, "available")
  expect_equal(status$parity_status, "passed")
  expect_equal(status$max_abs_coef_delta, 0)
  expect_equal(status$abs_loglik_delta, 0)
  expect_equal(status$blocked_reason, "")
  expect_match(status$claim_boundary, "deterministic contract", fixed = TRUE)
})

test_that("one-slope structured mu fixtures record provider-specific agreement", {
  source_structured_re_bridge_fixtures()

  contract <- phase18_structured_re_mu_slope_parity_fixture_contract()
  implemented <- c("phylo", "spatial", "animal", "relmat")

  for (structured_type in implemented) {
    native <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_mu_slope_payload_fixture(
        structured_type = structured_type,
        route = "native_tmb"
      )
    )
    direct <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_mu_slope_payload_fixture(
        structured_type = structured_type,
        route = "direct_drmjl"
      )
    )
    bridge <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_mu_slope_payload_fixture(
        structured_type = structured_type,
        route = "r_via_julia"
      )
    )
    status <- phase18_structured_re_parity_status(native, direct, bridge)

    expect_equal(native$summary$dimension, "q1")
    expect_equal(native$summary$endpoint, "mu")
    expect_equal(
      native$coef$term,
      c(
        "mu:(Intercept)",
        "mu:x",
        "sd_mu:structured(Intercept)",
        "sd_mu:structured(x)"
      )
    )
    expect_equal(status$r_via_julia_status, "available")
    expect_equal(status$parity_status, "passed")
    expect_equal(status$max_abs_coef_delta, 0)
    expect_equal(status$abs_loglik_delta, 0)
  }

  expect_equal(nrow(contract), 4L)
  implemented_rows <- contract[
    contract$structured_type %in% implemented,
    ,
    drop = FALSE
  ]
  relmat <- contract[contract$structured_type == "relmat", , drop = FALSE]
  expect_equal(implemented_rows$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    implemented_rows$parity_status,
    rep("covered_same_target_fixture", 4L)
  )
  expect_equal(
    implemented_rows$r_via_julia_status,
    rep("fixture_available", 4L)
  )
  expect_match(
    implemented_rows$claim_boundary,
    "broad bridge support",
    fixed = TRUE
  )
  expect_equal(relmat$matrix_slot, "K")
  expect_match(relmat$claim_boundary, "K-matrix", fixed = TRUE)
  expect_match(relmat$claim_boundary, "K/Q same-target parity", fixed = TRUE)
  expect_match(relmat$next_gate, "K/Q same-target parity", fixed = TRUE)
  expect_match(
    contract$claim_boundary,
    "coverage",
    fixed = TRUE
  )
  relmat_payload <- phase18_structured_re_mu_slope_payload_fixture(
    structured_type = "relmat"
  )
  expect_match(relmat_payload$matrix$matrix_id, "relmat", fixed = TRUE)
  expect_error(
    phase18_structured_re_mu_slope_payload_fixture(estimator = "REML"),
    "unsupported value",
    fixed = TRUE
  )
})

test_that("one-slope structured sigma fixtures record provider-specific agreement", {
  source_structured_re_bridge_fixtures()

  contract <- phase18_structured_re_sigma_slope_parity_fixture_contract()
  implemented <- c("phylo", "spatial", "animal", "relmat")

  for (structured_type in implemented) {
    native <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_sigma_slope_payload_fixture(
        structured_type = structured_type,
        route = "native_tmb"
      )
    )
    direct <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_sigma_slope_payload_fixture(
        structured_type = structured_type,
        route = "direct_drmjl"
      )
    )
    bridge <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_sigma_slope_payload_fixture(
        structured_type = structured_type,
        route = "r_via_julia"
      )
    )
    status <- phase18_structured_re_parity_status(native, direct, bridge)

    expect_equal(native$summary$dimension, "q1")
    expect_equal(native$summary$endpoint, "sigma")
    expect_equal(
      native$coef$term,
      c(
        "sigma:(Intercept)",
        "sigma:x",
        "sd_sigma:structured(Intercept)",
        "sd_sigma:structured(x)"
      )
    )
    expect_equal(status$r_via_julia_status, "available")
    expect_equal(status$parity_status, "passed")
    expect_equal(status$max_abs_coef_delta, 0)
    expect_equal(status$abs_loglik_delta, 0)
  }

  expect_equal(nrow(contract), 4L)
  expect_setequal(contract$structured_type, implemented)
  expect_equal(contract$endpoint, rep("sigma", 4L))
  expect_equal(contract$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    contract$parity_status,
    rep("covered_same_target_fixture", 4L)
  )
  expect_equal(
    contract$coefficient_order,
    rep(
      "sigma:(Intercept);sigma:x;sd_sigma:structured(Intercept);sd_sigma:structured(x)",
      4L
    )
  )
  expect_equal(contract$matrix_slot, c("tree", "coords", "A", "K"))
  expect_match(contract$claim_boundary, "broad bridge support", fixed = TRUE)
  expect_match(contract$claim_boundary, "matched mu+sigma", fixed = TRUE)
  expect_match(contract$claim_boundary, "coverage", fixed = TRUE)
  expect_match(
    contract$claim_boundary[contract$structured_type == "spatial"],
    "fixed-covariance",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "animal"],
    "A-matrix",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "relmat"],
    "K-matrix",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_sigma_slope_payload_fixture(
      structured_type = "unknown"
    ),
    "unsupported value",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_sigma_slope_payload_fixture(estimator = "REML"),
    "unsupported value",
    fixed = TRUE
  )
})

test_that("matched mu+sigma one-slope fixtures record provider-specific agreement", {
  source_structured_re_bridge_fixtures()

  contract <- phase18_structured_re_mu_sigma_slope_parity_fixture_contract()
  implemented <- c("phylo", "spatial", "animal", "relmat")

  for (structured_type in implemented) {
    native <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_mu_sigma_slope_payload_fixture(
        structured_type = structured_type,
        route = "native_tmb"
      )
    )
    direct <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_mu_sigma_slope_payload_fixture(
        structured_type = structured_type,
        route = "direct_drmjl"
      )
    )
    bridge <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_mu_sigma_slope_payload_fixture(
        structured_type = structured_type,
        route = "r_via_julia"
      )
    )
    status <- phase18_structured_re_parity_status(native, direct, bridge)

    expect_equal(native$summary$dimension, "q1_plus_q1")
    expect_equal(native$summary$endpoint, "mu+sigma")
    expect_equal(
      native$coef$term,
      c(
        "mu:(Intercept)",
        "mu:x",
        "sigma:(Intercept)",
        "sigma:x",
        "sd_mu:structured(Intercept)",
        "sd_mu:structured(x)",
        "sd_sigma:structured(Intercept)",
        "sd_sigma:structured(x)"
      )
    )
    expect_equal(status$r_via_julia_status, "available")
    expect_equal(status$parity_status, "passed")
    expect_equal(status$max_abs_coef_delta, 0)
    expect_equal(status$abs_loglik_delta, 0)
  }

  expect_equal(nrow(contract), 4L)
  expect_setequal(contract$structured_type, implemented)
  expect_equal(contract$endpoint, rep("mu+sigma", 4L))
  expect_equal(contract$dimension, rep("q1_plus_q1", 4L))
  expect_equal(contract$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    contract$parity_status,
    rep("covered_same_target_fixture", 4L)
  )
  expect_equal(
    contract$coefficient_order,
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
  expect_equal(contract$matrix_slot, c("tree", "coords", "A", "K"))
  expect_match(contract$claim_boundary, "broad bridge support", fixed = TRUE)
  expect_match(contract$claim_boundary, "coverage", fixed = TRUE)
  expect_match(contract$claim_boundary, "REML", fixed = TRUE)
  expect_match(contract$claim_boundary, "AI-REML", fixed = TRUE)
  expect_match(
    contract$claim_boundary[contract$structured_type == "spatial"],
    "fixed-covariance",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "animal"],
    "A-matrix",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "relmat"],
    "K-matrix",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "relmat"],
    "Q bridge",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_mu_sigma_slope_payload_fixture(
      structured_type = "unknown"
    ),
    "unsupported value",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_mu_sigma_slope_payload_fixture(estimator = "REML"),
    "unsupported value",
    fixed = TRUE
  )
})

test_that("q2 slope-only fixtures record provider-specific agreement", {
  source_structured_re_bridge_fixtures()

  contract <- phase18_structured_re_q2_slope_parity_fixture_contract()
  implemented <- c("phylo", "spatial", "animal", "relmat")

  for (structured_type in implemented) {
    native <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_q2_slope_payload_fixture(
        structured_type = structured_type,
        route = "native_tmb"
      )
    )
    direct <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_q2_slope_payload_fixture(
        structured_type = structured_type,
        route = "direct_drmjl"
      )
    )
    bridge <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_q2_slope_payload_fixture(
        structured_type = structured_type,
        route = "r_via_julia"
      )
    )
    status <- phase18_structured_re_parity_status(native, direct, bridge)

    expect_equal(native$summary$dimension, "q2")
    expect_equal(native$summary$endpoint, "mu1+mu2")
    expect_equal(
      native$coef$term,
      c(
        "mu1:x",
        "mu2:x",
        "sd_mu1:structured(x)",
        "sd_mu2:structured(x)",
        "cor_mu1_mu2:structured(x)"
      )
    )
    expect_equal(status$r_via_julia_status, "available")
    expect_equal(status$parity_status, "passed")
    expect_equal(status$max_abs_coef_delta, 0)
    expect_equal(status$abs_loglik_delta, 0)
  }

  expect_equal(nrow(contract), 4L)
  expect_setequal(contract$structured_type, implemented)
  expect_equal(contract$endpoint, rep("mu1+mu2", 4L))
  expect_equal(contract$dimension, rep("q2", 4L))
  expect_equal(contract$slope_class, rep("labelled_slope_covariance", 4L))
  expect_equal(contract$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    contract$parity_status,
    rep("covered_same_target_fixture", 4L)
  )
  expect_equal(
    contract$coefficient_order,
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
  expect_equal(contract$matrix_slot, c("tree", "coords", "A", "K"))
  expect_match(contract$claim_boundary, "slope-only q2", fixed = TRUE)
  expect_match(contract$claim_boundary, "broad bridge support", fixed = TRUE)
  expect_match(contract$claim_boundary, "q4/q8", fixed = TRUE)
  expect_match(contract$claim_boundary, "coverage", fixed = TRUE)
  expect_match(contract$claim_boundary, "REML", fixed = TRUE)
  expect_match(contract$claim_boundary, "AI-REML", fixed = TRUE)
  expect_match(
    contract$claim_boundary[contract$structured_type == "spatial"],
    "fixed-covariance",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "animal"],
    "A-matrix",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "relmat"],
    "K-matrix",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "relmat"],
    "Q bridge",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_q2_slope_payload_fixture(
      structured_type = "unknown"
    ),
    "unsupported value",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_q2_slope_payload_fixture(estimator = "REML"),
    "unsupported value",
    fixed = TRUE
  )
})

test_that("q4 location one-slope fixtures record provider-specific agreement", {
  source_structured_re_bridge_fixtures()

  contract <- phase18_structured_re_q4_location_slope_parity_fixture_contract()
  implemented <- c("phylo", "spatial", "animal", "relmat")
  endpoint_members <- paste0(
    rep(c("mu1", "mu2"), each = 2L),
    ":",
    rep(c("(Intercept)", "x"), times = 2L)
  )

  for (structured_type in implemented) {
    native <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_q4_location_slope_payload_fixture(
        structured_type = structured_type,
        route = "native_tmb"
      )
    )
    direct <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_q4_location_slope_payload_fixture(
        structured_type = structured_type,
        route = "direct_drmjl"
      )
    )
    bridge <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_q4_location_slope_payload_fixture(
        structured_type = structured_type,
        route = "r_via_julia"
      )
    )
    status <- phase18_structured_re_parity_status(native, direct, bridge)

    expect_equal(native$summary$dimension, "q4")
    expect_equal(native$summary$endpoint, "mu1+mu2")
    expect_equal(
      native$coef$term[seq_along(endpoint_members)],
      endpoint_members
    )
    expect_equal(nrow(native$coef), 14L)
    expect_equal(length(grep("^sd_", native$coef$term)), 4L)
    expect_equal(length(grep("^cor_", native$coef$term)), 6L)
    expect_equal(status$r_via_julia_status, "available")
    expect_equal(status$parity_status, "passed")
    expect_equal(status$max_abs_coef_delta, 0)
    expect_equal(status$abs_loglik_delta, 0)
  }

  expect_equal(nrow(contract), 4L)
  expect_setequal(contract$structured_type, implemented)
  expect_equal(contract$endpoint, rep("mu1+mu2", 4L))
  expect_equal(contract$dimension, rep("q4", 4L))
  expect_equal(contract$slope_class, rep("labelled_slope_covariance", 4L))
  expect_equal(contract$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    contract$parity_status,
    rep("covered_same_target_fixture", 4L)
  )
  expect_equal(contract$matrix_slot, c("tree", "coords", "A", "K"))
  expect_match(contract$claim_boundary, "q4 location one-slope", fixed = TRUE)
  expect_match(contract$claim_boundary, "four-member q4 location", fixed = TRUE)
  expect_match(contract$claim_boundary, "broad bridge support", fixed = TRUE)
  expect_match(contract$claim_boundary, "partial location-scale", fixed = TRUE)
  expect_match(contract$claim_boundary, "coverage", fixed = TRUE)
  expect_match(contract$claim_boundary, "q4 REML", fixed = TRUE)
  expect_match(contract$claim_boundary, "AI-REML", fixed = TRUE)
  expect_match(
    contract$claim_boundary[contract$structured_type == "spatial"],
    "fixed-covariance",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "animal"],
    "A-matrix",
    fixed = TRUE
  )
  relmat_boundary <- contract$claim_boundary[
    contract$structured_type == "relmat"
  ]
  expect_match(relmat_boundary, "K-matrix", fixed = TRUE)
  expect_match(relmat_boundary, "Q precision", fixed = TRUE)
  expect_false(grepl("K/Q same-target parity", relmat_boundary, fixed = TRUE))
  expect_error(
    phase18_structured_re_q4_location_slope_payload_fixture(
      structured_type = "unknown"
    ),
    "unsupported value",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_q4_location_slope_payload_fixture(estimator = "REML"),
    "unsupported value",
    fixed = TRUE
  )
})

test_that("q4 all-four one-slope fixtures record provider-specific agreement", {
  source_structured_re_bridge_fixtures()

  contract <- phase18_structured_re_q4_slope_parity_fixture_contract()
  implemented <- c("phylo", "spatial", "animal", "relmat")
  endpoint_members <- paste0(
    rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 2L),
    ":",
    rep(c("(Intercept)", "x"), times = 4L)
  )

  for (structured_type in implemented) {
    native <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_q4_slope_payload_fixture(
        structured_type = structured_type,
        route = "native_tmb"
      )
    )
    direct <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_q4_slope_payload_fixture(
        structured_type = structured_type,
        route = "direct_drmjl"
      )
    )
    bridge <- phase18_structured_re_reconstruct_fixture(
      phase18_structured_re_q4_slope_payload_fixture(
        structured_type = structured_type,
        route = "r_via_julia"
      )
    )
    status <- phase18_structured_re_parity_status(native, direct, bridge)

    expect_equal(native$summary$dimension, "q8")
    expect_equal(native$summary$endpoint, "mu1+mu2+sigma1+sigma2")
    expect_equal(
      native$coef$term[seq_along(endpoint_members)],
      endpoint_members
    )
    expect_equal(nrow(native$coef), 44L)
    expect_equal(length(grep("^sd_", native$coef$term)), 8L)
    expect_equal(length(grep("^cor_", native$coef$term)), 28L)
    expect_equal(status$r_via_julia_status, "available")
    expect_equal(status$parity_status, "passed")
    expect_equal(status$max_abs_coef_delta, 0)
    expect_equal(status$abs_loglik_delta, 0)
  }

  expect_equal(nrow(contract), 4L)
  expect_setequal(contract$structured_type, implemented)
  expect_equal(contract$endpoint, rep("mu1+mu2+sigma1+sigma2", 4L))
  expect_equal(contract$dimension, rep("q8", 4L))
  expect_equal(contract$slope_class, rep("labelled_slope_covariance", 4L))
  expect_equal(contract$bridge_status, rep("fixture_parity", 4L))
  expect_equal(
    contract$parity_status,
    rep("covered_same_target_fixture", 4L)
  )
  expect_equal(contract$matrix_slot, c("tree", "coords", "A", "K"))
  expect_match(contract$claim_boundary, "q4 all-four one-slope", fixed = TRUE)
  expect_match(contract$claim_boundary, "eight-member q8", fixed = TRUE)
  expect_match(contract$claim_boundary, "broad bridge support", fixed = TRUE)
  expect_match(contract$claim_boundary, "coverage", fixed = TRUE)
  expect_match(contract$claim_boundary, "q4 REML", fixed = TRUE)
  expect_match(contract$claim_boundary, "AI-REML", fixed = TRUE)
  expect_match(
    contract$claim_boundary[contract$structured_type == "spatial"],
    "fixed-covariance",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "animal"],
    "A-matrix",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "relmat"],
    "K-matrix",
    fixed = TRUE
  )
  expect_match(
    contract$claim_boundary[contract$structured_type == "relmat"],
    "Q bridge",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_q4_slope_payload_fixture(
      structured_type = "unknown"
    ),
    "unsupported value",
    fixed = TRUE
  )
  expect_error(
    phase18_structured_re_q4_slope_payload_fixture(estimator = "REML"),
    "unsupported value",
    fixed = TRUE
  )
})

test_that("q2 fixture contract separates q2 from q2-plus-q2 and q4", {
  source_structured_re_bridge_fixtures()

  contract <- phase18_structured_re_q2_fixture_contract()

  expect_equal(nrow(contract), 6L)
  same_target <- contract[grepl("_same_target_ml$", contract$fixture_id), ]
  expect_equal(nrow(same_target), 4L)
  expect_setequal(
    same_target$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(same_target$dimension, rep("q2", 4L))
  expect_equal(same_target$estimator, rep("ML", 4L))
  expect_match(same_target$separated_from, "q2_plus_q2", fixed = TRUE)
  expect_match(same_target$separated_from, "q4", fixed = TRUE)
  expect_equal(same_target$bridge_status, rep("experimental", 4L))
  expect_equal(same_target$r_via_julia_status, rep("fixture_available", 4L))
  expect_match(
    same_target$claim_boundary[same_target$structured_type == "spatial"],
    "fixed-covariance",
    fixed = TRUE
  )

  q2_plus <- contract[contract$fixture_id == "q2_plus_q2_not_q4", ]
  expect_equal(q2_plus$dimension, "q2_plus_q2")
  expect_match(q2_plus$claim_boundary, "not full q4", fixed = TRUE)

  reml <- contract[contract$estimator == "REML", ]
  expect_equal(reml$bridge_status, "unsupported")
  expect_match(reml$claim_boundary, "not HSquared AI-REML", fixed = TRUE)
})

test_that("q2 payload fixture records ordering and narrow phylo bridge status", {
  source_structured_re_bridge_fixtures()

  native <- phase18_structured_re_reconstruct_fixture(
    phase18_structured_re_q2_payload_fixture(
      structured_type = "phylo",
      route = "native_tmb"
    )
  )
  direct <- phase18_structured_re_reconstruct_fixture(
    phase18_structured_re_q2_payload_fixture(
      structured_type = "phylo",
      route = "direct_drmjl"
    )
  )
  status <- phase18_structured_re_parity_status(
    native,
    direct,
    bridge = NULL,
    blocked_reason = "q2_bridge_payload_not_implemented"
  )

  expect_equal(native$summary$dimension, "q2")
  expect_equal(native$summary$endpoint, "mu1_mu2")
  expect_equal(
    native$coef$term,
    c(
      "mu1:(Intercept)",
      "mu1:x",
      "mu2:(Intercept)",
      "mu2:x",
      "sd_mu1:structured(group)",
      "sd_mu2:structured(group)",
      "cor_mu1_mu2:structured(group)"
    )
  )
  expect_equal(status$r_via_julia_status, "blocked")
  expect_equal(status$parity_status, "blocked")
  expect_equal(status$blocked_reason, "q2_bridge_payload_not_implemented")
  expect_match(
    status$claim_boundary,
    "does not promote R-via-Julia",
    fixed = TRUE
  )

  payload <- phase18_structured_re_q2_payload_fixture(
    structured_type = "relmat"
  )
  expect_match(payload$matrix$matrix_digest, "4x4:", fixed = TRUE)
  expect_equal(
    payload$inference$status[payload$inference$extractor == "r_via_julia"],
    "unavailable"
  )
  expect_error(
    phase18_structured_re_q2_payload_fixture(estimator = "REML"),
    "not HSquared AI-REML",
    fixed = TRUE
  )
  bridge <- phase18_structured_re_q2_payload_fixture(route = "r_via_julia")
  expect_equal(
    bridge$inference$status[bridge$inference$extractor == "r_via_julia"],
    "available"
  )
  expect_match(
    bridge$inference$unavailable_reason[
      bridge$inference$extractor == "r_via_julia"
    ],
    "q2 phylo",
    fixed = TRUE
  )
  relmat_bridge <- phase18_structured_re_q2_payload_fixture(
    structured_type = "relmat",
    route = "r_via_julia"
  )
  expect_equal(
    relmat_bridge$inference$status[
      relmat_bridge$inference$extractor == "r_via_julia"
    ],
    "available"
  )
  expect_match(
    relmat_bridge$inference$unavailable_reason[
      relmat_bridge$inference$extractor == "r_via_julia"
    ],
    "relmat K-matrix",
    fixed = TRUE
  )
})

test_that("q2 coefficient order map follows the payload fixture", {
  source_structured_re_bridge_fixtures()

  coef_map <- phase18_structured_re_q2_coefficient_order_map()
  payload <- phase18_structured_re_q2_payload_fixture(structured_type = "phylo")
  expected_order <- paste(names(payload$estimates$coef), collapse = ";")

  expect_equal(nrow(coef_map), 4L)
  expect_setequal(
    coef_map$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(coef_map$coefficient_order, rep(expected_order, 4L))
  expect_equal(
    coef_map$fixed_effect_terms,
    rep("mu1:(Intercept);mu1:x;mu2:(Intercept);mu2:x", 4L)
  )
  expect_equal(
    coef_map$structured_terms,
    rep("sd_mu1:structured(group);sd_mu2:structured(group)", 4L)
  )
  expect_equal(
    coef_map$correlation_terms,
    rep("cor_mu1_mu2:structured(group)", 4L)
  )
  expect_equal(
    coef_map$bridge_status,
    rep("experimental", 4L)
  )
  expect_match(
    coef_map$claim_boundary,
    "q2",
    fixed = TRUE
  )
  expect_match(
    coef_map$claim_boundary[coef_map$structured_type == "spatial"],
    "fixed-covariance",
    fixed = TRUE
  )
})

test_that("q2 payload provenance keeps matrix and version evidence row-shaped", {
  source_structured_re_bridge_fixtures()

  provenance <- phase18_structured_re_q2_payload_provenance()
  payload <- phase18_structured_re_q2_payload_fixture(structured_type = "phylo")

  expect_equal(nrow(provenance), 4L)
  expect_setequal(
    provenance$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(provenance$dimension, rep("q2", 4L))
  expect_equal(provenance$route, rep("q2_bridge", 4L))
  expect_equal(provenance$estimator, rep("ML", 4L))
  expect_equal(provenance$payload_version, rep(payload$payload_version, 4L))
  expect_match(provenance$source_repo, "DRM.jl", fixed = TRUE)
  expect_match(
    provenance$source_branch,
    "codex/ai-reml-gaussian-mme-pilot",
    fixed = TRUE
  )
  expect_match(provenance$source_head, "e016fc15b4fb", fixed = TRUE)
  expect_match(provenance$matrix_digest, "4x4:", fixed = TRUE)
  expect_equal(
    provenance$matrix_slot,
    c("tree", "coords", "A", "K")
  )
  expect_equal(
    provenance$input_scale,
    c(
      "ultrametric_tree_branch_lengths",
      "coordinates_to_fixed_covariance_K",
      "additive_covariance",
      "user_covariance"
    )
  )
  expect_equal(
    provenance$missing_level_policy,
    c(
      "error_if_observed_species_absent_from_tree;extra_tree_tips_allowed",
      paste0(
        "error_if_coords_missing_observed_group_or_vary_within_group;",
        "extra_coordinate_rows_not_supported"
      ),
      "error_if_observed_id_absent_from_matrix;extra_matrix_levels_allowed",
      "error_if_observed_id_absent_from_matrix;extra_matrix_levels_allowed"
    )
  )
  expect_match(
    provenance$bridge_marshalling[provenance$structured_type == "spatial"],
    "range_estimating_spatial_not_promoted",
    fixed = TRUE
  )
  expect_match(
    provenance$bridge_marshalling[provenance$structured_type == "animal"],
    "pedigree_Ainv_not_marshaled",
    fixed = TRUE
  )
  expect_match(
    provenance$bridge_marshalling[provenance$structured_type == "relmat"],
    "Q_precision_not_marshaled",
    fixed = TRUE
  )
  expect_match(provenance$required_levels, "matrix_row_names", fixed = TRUE)
  expect_match(provenance$version_fields, "payload_version", fixed = TRUE)
  expect_match(
    provenance$dirty_state_policy,
    "not_public_support",
    fixed = TRUE
  )
  expect_equal(
    provenance$bridge_status,
    rep("experimental", 4L)
  )
  expect_match(
    provenance$claim_boundary,
    "q2",
    fixed = TRUE
  )
  expect_match(
    provenance$claim_boundary[provenance$structured_type == "spatial"],
    "fixed-covariance",
    fixed = TRUE
  )
  expect_match(
    provenance$claim_boundary[provenance$structured_type == "animal"],
    "A-matrix",
    fixed = TRUE
  )
})

test_that("q2 acceptance gate banks route-specific fixture rows", {
  source_structured_re_bridge_fixtures()

  gate <- phase18_structured_re_q2_acceptance_gate()

  expect_equal(nrow(gate), 4L)
  expect_setequal(
    gate$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )
  expect_equal(gate$dimension, rep("q2", 4L))
  expect_equal(gate$estimator, rep("ML", 4L))
  expect_equal(gate$native_status, rep("available_point_fixture", 4L))
  phylo <- gate[gate$structured_type == "phylo", , drop = FALSE]
  non_phylo <- gate[gate$structured_type != "phylo", , drop = FALSE]
  expect_equal(
    phylo$direct_drmjl_status,
    "available_residual_correlation_point_export"
  )
  expect_equal(
    phylo$r_via_julia_status,
    "available_q2_phylo_formula_bridge_fixture"
  )
  expect_equal(phylo$acceptance_status, "banked_phylo_fixture")
  expect_equal(phylo$status, "covered")
  expect_equal(phylo$bridge_status, "experimental")
  expect_equal(phylo$missing_evidence, "none_for_phylo_fixture")
  expect_match(phylo$tolerance_policy, "same_target_fixture", fixed = TRUE)
  expect_equal(
    phylo$required_before_acceptance,
    "none_for_phylo_fixture"
  )
  expect_equal(
    non_phylo$r_via_julia_status[non_phylo$structured_type == "spatial"],
    "available_q2_fixed_covariance_spatial_formula_bridge_fixture"
  )
  expect_equal(
    non_phylo$r_via_julia_status[
      non_phylo$structured_type %in% c("animal", "relmat")
    ],
    rep("available_q2_known_covariance_formula_bridge_fixture", 2L)
  )
  expect_equal(
    non_phylo$direct_drmjl_status[non_phylo$structured_type == "spatial"],
    "available_fixed_covariance_residual_correlation_fixture"
  )
  expect_equal(
    non_phylo$direct_drmjl_status[
      non_phylo$structured_type %in% c("animal", "relmat")
    ],
    rep("available_known_covariance_residual_correlation_point_export", 2L)
  )
  expect_equal(
    non_phylo$acceptance_status[non_phylo$structured_type == "spatial"],
    "banked_fixed_covariance_spatial_fixture"
  )
  expect_equal(
    non_phylo$acceptance_status[
      non_phylo$structured_type %in% c("animal", "relmat")
    ],
    rep("banked_known_covariance_fixture", 2L)
  )
  expect_equal(non_phylo$status, rep("covered", 3L))
  expect_equal(non_phylo$bridge_status, rep("experimental", 3L))
  expect_match(non_phylo$missing_evidence, "^none_for_", perl = TRUE)
  expect_false(any(grepl(
    "direct_q2_fit",
    non_phylo$missing_evidence,
    fixed = TRUE
  )))
  expect_match(non_phylo$tolerance_policy, "same_target_fixture", fixed = TRUE)
  expect_equal(
    gate$bridge_status,
    rep("experimental", 4L)
  )
  expect_match(gate$claim_boundary, "q2", fixed = TRUE)
  expect_match(
    gate$claim_boundary[gate$structured_type == "spatial"],
    "not a range-estimating spatial route",
    fixed = TRUE
  )
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

test_that("q4 phylogenetic covariance target map names SDs and correlations", {
  source_structured_re_bridge_fixtures()

  target_map <- phase18_structured_re_q4_phylocov_target_map()
  sd_rows <- target_map[target_map$target_kind == "direct_sd", , drop = FALSE]
  cor_rows <- target_map[
    target_map$target_kind == "derived_correlation",
    ,
    drop = FALSE
  ]

  expect_equal(nrow(target_map), 10L)
  expect_equal(nrow(sd_rows), 4L)
  expect_equal(nrow(cor_rows), 6L)
  expect_equal(
    sd_rows$direct_sd_target,
    c("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2")
  )
  expect_equal(sd_rows$interval_status, rep("not_evaluated", 4L))
  expect_equal(cor_rows$direct_sd_target, rep("not_direct", 6L))
  expect_equal(cor_rows$extractor, rep("corpairs", 6L))
  expect_match(cor_rows$correlation_target, "cor_", fixed = TRUE)
  expect_equal(cor_rows$interval_status, rep("not_available", 6L))
  expect_match(target_map$claim_boundary, "no q4", fixed = TRUE)
  expect_match(target_map$claim_boundary, "interval coverage", fixed = TRUE)
})

test_that("q4 corpairs parity gate covers calibrated point parity only", {
  source_structured_re_bridge_fixtures()

  gate <- phase18_structured_re_q4_corpairs_parity_gate()

  expect_equal(nrow(gate), 1L)
  expect_equal(gate$target, "gaussian_q4_phylo")
  expect_equal(gate$extractor, "corpairs")
  expect_equal(gate$native_status, "covered_calibrated_native_corpairs")
  expect_equal(
    gate$direct_drmjl_status,
    "covered_point_export_matches_wrapper_corpairs"
  )
  expect_equal(gate$r_via_julia_status, "covered_calibrated_corpairs")
  expect_equal(gate$parity_status, "covered_point_corpairs")
  expect_equal(gate$status, "covered")
  expect_match(gate$missing_evidence, "interval_reliability", fixed = TRUE)
  expect_match(
    gate$required_before_acceptance,
    "interval reliability",
    fixed = TRUE
  )
  expect_match(gate$claim_boundary, "no broad q4 bridge support", fixed = TRUE)
  expect_match(gate$claim_boundary, "interval coverage", fixed = TRUE)
})

test_that("q4 profile target bridge map separates target names from intervals", {
  source_structured_re_bridge_fixtures()

  target_map <- phase18_structured_re_q4_profile_target_bridge_map()

  expect_equal(nrow(target_map), 4L)
  expect_equal(
    target_map$axis,
    c("mu1", "mu2", "sigma1", "sigma2")
  )
  expect_equal(
    target_map$native_profile_target,
    c(
      "sd:mu:mu1:phylo(1 | p | species)",
      "sd:mu:mu2:phylo(1 | p | species)",
      "sd:mu:sigma1:phylo(1 | p | species)",
      "sd:mu:sigma2:phylo(1 | p | species)"
    )
  )
  expect_equal(
    target_map$bridge_profile_target,
    c(
      "sd:mu1:phylo(1 | species)",
      "sd:mu2:phylo(1 | species)",
      "sd:sigma1:phylo(1 | species)",
      "sd:sigma2:phylo(1 | species)"
    )
  )
  expect_equal(
    target_map$direct_sd_target,
    c("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2")
  )
  expect_equal(target_map$native_tmb_parameter, rep("log_sd_phylo", 4L))
  expect_equal(target_map$native_profile_ready, rep("true", 4L))
  expect_equal(
    target_map$bridge_profile_ready,
    rep("target_inventory_only", 4L)
  )
  expect_equal(target_map$interval_status, rep("not_evaluated", 4L))
  expect_match(
    target_map$negative_evidence,
    "no_same_fixture_native_direct_bridge_profile_comparison",
    fixed = TRUE
  )
  expect_match(target_map$claim_boundary, "no q4 parity", fixed = TRUE)
  expect_match(target_map$claim_boundary, "interval coverage", fixed = TRUE)
})

test_that("q4 scale-axis interval failure ledger keeps sigma gaps visible", {
  source_structured_re_bridge_fixtures()

  failures <- phase18_structured_re_q4_scale_axis_interval_failure_ledger()

  expect_equal(nrow(failures), 2L)
  expect_equal(failures$axis, c("sigma1", "sigma2"))
  expect_equal(failures$direct_sd_target, c("sd_sigma1", "sd_sigma2"))
  expect_equal(
    failures$native_tmb_status,
    rep("30tip_plumbing;100tip_refit_failures", 2L)
  )
  expect_equal(
    failures$direct_drmjl_status,
    rep("known_scale_axis_undercoverage", 2L)
  )
  expect_equal(
    failures$r_via_julia_status,
    rep("target_inventory_only", 2L)
  )
  expect_match(
    failures$failure_class,
    "scale_axis_undercoverage_known",
    fixed = TRUE
  )
  expect_match(
    failures$failure_class,
    "native_refit_failures_visible",
    fixed = TRUE
  )
  expect_equal(failures$interval_claim_status, rep("blocked", 2L))
  expect_equal(failures$status, rep("covered", 2L))
  expect_match(
    failures$claim_boundary,
    "no q4 interval reliability",
    fixed = TRUE
  )
  expect_match(failures$claim_boundary, "interval coverage", fixed = TRUE)
})

test_that("q4 direct DRM.jl export status names four point SD targets", {
  source_structured_re_bridge_fixtures()

  exports <- phase18_structured_re_q4_direct_drmjl_export_status()

  expect_equal(nrow(exports), 4L)
  expect_equal(exports$axis, c("mu1", "mu2", "sigma1", "sigma2"))
  expect_equal(
    exports$target,
    c(
      "gaussian_q4_phylo_sd_mu1",
      "gaussian_q4_phylo_sd_mu2",
      "gaussian_q4_phylo_sd_sigma1",
      "gaussian_q4_phylo_sd_sigma2"
    )
  )
  expect_equal(
    exports$direct_sd_target,
    c("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2")
  )
  expect_equal(exports$sigma_a_source, rep("fit.ranef.Sigma_a", 4L))
  expect_equal(exports$direct_status, rep("available_point_target", 4L))
  expect_equal(exports$bridge_status, rep("experimental", 4L))
  expect_equal(exports$inference_status, rep("point_target_only", 4L))
  expect_match(
    exports$claim_boundary,
    "no R-via-Julia q4 bridge parity",
    fixed = TRUE
  )
  expect_match(exports$claim_boundary, "interval coverage", fixed = TRUE)
})

test_that("q4 deterministic fixture provides known truth without parity claims", {
  source_structured_re_bridge_fixtures()

  fixture <- phase18_structured_re_q4_deterministic_fixture()
  status <- phase18_structured_re_q4_deterministic_fixture_status()

  expect_type(fixture, "list")
  expect_equal(nrow(fixture$data), 16L)
  expect_equal(length(unique(fixture$data$species)), 8L)
  expect_setequal(
    names(fixture$data),
    c(
      "species",
      "replicate",
      "x",
      "y1",
      "y2",
      "sigma1_truth",
      "sigma2_truth"
    )
  )
  expect_true(grepl("sp01", fixture$tree_newick, fixed = TRUE))
  expect_equal(fixture$truth$axes, c("mu1", "mu2", "sigma1", "sigma2"))
  expect_equal(dim(fixture$truth$sigma_a), c(4L, 4L))
  expect_silent(chol(fixture$truth$sigma_a))
  expect_equal(nrow(fixture$latent), 8L)
  expect_equal(nrow(status), 1L)
  expect_equal(status$fixture_id, "q4_deterministic_balanced8")
  expect_equal(status$n_species, 8L)
  expect_equal(status$n_obs, 16L)
  expect_equal(status$fit_status, "not_fit_in_fixture_contract")
  expect_equal(status$bridge_status, "planned")
  expect_match(status$claim_boundary, "no q4 parity", fixed = TRUE)
  expect_match(status$claim_boundary, "interval coverage", fixed = TRUE)
})

test_that("q4 tolerance policy is declared before parity acceptance", {
  source_structured_re_bridge_fixtures()

  policy <- phase18_structured_re_q4_tolerance_policy()

  expect_equal(nrow(policy), 4L)
  expect_equal(
    policy$quantity,
    c(
      "logLik",
      "fixed_coefficients",
      "direct_sd_targets",
      "derived_correlations"
    )
  )
  expect_true(all(nzchar(policy$tolerance)))
  expect_equal(
    policy$comparator_routes,
    rep("native_tmb;direct_drmjl;r_via_julia", 4L)
  )
  expect_equal(
    policy$required_fixture,
    rep("q4_deterministic_balanced8", 4L)
  )
  expect_equal(policy$acceptance_use, rep("predeclared_policy_only", 4L))
  expect_equal(policy$status, rep("covered", 4L))
  expect_equal(policy$bridge_status, rep("planned", 4L))
  expect_match(policy$claim_boundary, "no q4 parity", fixed = TRUE)
  expect_match(policy$claim_boundary, "interval coverage", fixed = TRUE)
})

test_that("q4 same-fixture parity probe records negative evidence only", {
  source_structured_re_bridge_fixtures()

  probe <- phase18_structured_re_q4_same_fixture_parity_probe()

  expect_equal(nrow(probe), 1L)
  expect_equal(probe$target, "gaussian_q4_phylo")
  expect_equal(probe$fixture_id, "q4_30tip_m3_seed42_live_probe")
  expect_match(probe$comparator_routes, "native_tmb", fixed = TRUE)
  expect_match(probe$comparator_routes, "r_via_julia", fixed = TRUE)
  expect_match(
    probe$comparator_routes,
    "direct_drmjl_not_compared",
    fixed = TRUE
  )
  expect_equal(
    probe$native_tmb_status,
    "nonconverged_false_convergence_code1"
  )
  expect_equal(
    probe$direct_drmjl_status,
    "point_matrix_export_available_not_compared"
  )
  expect_equal(probe$r_via_julia_status, "converged_point_extractor")
  expect_equal(
    probe$acceptance_status,
    "negative_probe_superseded_by_calibrated_probe"
  )
  expect_equal(probe$status, "covered")
  expect_equal(probe$bridge_status, "experimental")
  expect_gt(as.numeric(probe$max_abs_cor_delta), 0.05)
  expect_lt(as.numeric(probe$loglik_delta), 1e-3)
  expect_match(
    probe$tolerance_result,
    "negative_probe_superseded",
    fixed = TRUE
  )
  expect_match(probe$tolerance_result, "native_nonconverged", fixed = TRUE)
  expect_match(probe$tolerance_result, "gt_0.05", fixed = TRUE)
  expect_match(probe$claim_boundary, "retained negative evidence", fixed = TRUE)
  expect_match(probe$claim_boundary, "AI-REML", fixed = TRUE)
  expect_match(probe$claim_boundary, "interval coverage", fixed = TRUE)
})

test_that("q4 calibrated parity probe separates reconstruction from acceptance", {
  source_structured_re_bridge_fixtures()

  probe <- phase18_structured_re_q4_calibrated_parity_probe()

  expect_equal(nrow(probe), 2L)
  expect_equal(probe$target, rep("gaussian_q4_phylo", 2L))
  expect_equal(probe$n_tip, rep(32L, 2L))
  expect_setequal(
    probe$fixture_id,
    c("q4_balanced32_seed20260802_n4", "q4_balanced32_seed31_n8")
  )
  expect_equal(
    probe$comparator_routes,
    rep("native_tmb;direct_drmjl;r_via_julia", 2L)
  )
  expect_equal(
    probe$native_tmb_status,
    rep("converged_relative_convergence_code0", 2L)
  )
  expect_equal(
    probe$direct_drmjl_status,
    rep("converged_point_matrix_export_matches_wrapper", 2L)
  )
  expect_equal(
    probe$r_via_julia_status,
    rep("converged_point_reconstruction", 2L)
  )
  expect_equal(all(as.numeric(probe$loglik_delta_direct_bridge) < 1e-12), TRUE)
  expect_equal(all(as.numeric(probe$max_abs_sd_direct_bridge) < 1e-12), TRUE)
  expect_equal(all(as.numeric(probe$max_abs_cor_direct_bridge) < 1e-12), TRUE)
  expect_equal(all(as.numeric(probe$loglik_delta_native_bridge) < 1e-3), TRUE)
  expect_equal(all(as.numeric(probe$max_abs_fixef_native_bridge) < 5e-3), TRUE)
  expect_equal(all(as.numeric(probe$max_abs_sd_native_bridge) < 0.02), TRUE)
  expect_equal(all(as.numeric(probe$max_abs_cor_native_bridge) < 0.05), TRUE)
  expect_equal(probe$reconstruction_status, rep("covered", 2L))
  expect_equal(probe$status, rep("covered", 2L))
  expect_equal(probe$bridge_status, rep("experimental", 2L))
  expect_match(probe$tolerance_result, "direct_wrapper_match", fixed = TRUE)
  expect_match(probe$tolerance_result, "within_1e-3", fixed = TRUE)
  expect_match(probe$claim_boundary, "no broad q4 bridge support", fixed = TRUE)
  expect_match(probe$claim_boundary, "AI-REML", fixed = TRUE)
  expect_match(probe$claim_boundary, "interval coverage", fixed = TRUE)
})

test_that("q4 parity acceptance gate covers calibrated point parity only", {
  source_structured_re_bridge_fixtures()

  gate <- phase18_structured_re_q4_parity_acceptance_gate()

  expect_equal(nrow(gate), 1L)
  expect_equal(gate$gate_id, "q4_parity_acceptance_gate")
  expect_equal(gate$required_fixture, "q4_calibrated_balanced32_pair")
  expect_match(gate$required_quantities, "direct_sd_targets", fixed = TRUE)
  expect_equal(gate$direct_drmjl_status, "covered_point_export_matches_wrapper")
  expect_equal(gate$r_via_julia_status, "covered_calibrated_point_parity")
  expect_equal(gate$tolerance_policy, "predeclared")
  expect_equal(gate$acceptance_status, "covered_point_parity_no_interval_claim")
  expect_equal(gate$status, "covered")
  expect_match(gate$missing_evidence, "interval_reliability", fixed = TRUE)
  expect_match(gate$missing_evidence, "interval_coverage", fixed = TRUE)
  expect_equal(gate$bridge_status, "experimental")
  expect_match(gate$claim_boundary, "no broad q4 bridge support", fixed = TRUE)
  expect_match(gate$claim_boundary, "interval coverage", fixed = TRUE)
})
