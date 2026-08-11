source_missing_response_g4g5 <- function(env = parent.frame()) {
  path <- system.file("sim/R/sim_missing_response_g4g5.R", package = "drmTMB")
  if (!nzchar(path)) path <- testthat::test_path("..", "..", "inst", "sim", "R", "sim_missing_response_g4g5.R")
  source(path, local = env)
}

test_that("every G4/G5 record is stamped with the design that produced it", {
  # #982: the frozen manifest hash cannot distinguish a centred from an uncentred
  # design (`truth` is identical either way), and a seed fixes the RNG stream, not
  # what is done with it. So the design must be recorded on the record itself.
  source_missing_response_g4g5()

  withr::local_options(drmTMB.mr_g4g5_centre_random_effects = TRUE)
  centred <- mr_g4_run_route("gaussian", information_multiplier = 1)
  expect_true("design_state" %in% names(centred))
  expect_identical(unique(centred$design_state), "centre_random_effects=TRUE")

  withr::local_options(drmTMB.mr_g4g5_centre_random_effects = FALSE)
  uncentred <- mr_g4_run_route("gaussian", information_multiplier = 1)
  expect_identical(unique(uncentred$design_state), "centre_random_effects=FALSE")

  # the stamp must actually track the design, not merely exist
  expect_false(identical(centred$design_state[1], uncentred$design_state[1]))
})

test_that("reconciliation refuses to merge, or to accept, unauthenticated designs", {
  # The guard is only worth having if it FAILS on purpose. Exercise both closures:
  # disagreeing designs, and records that predate stamping entirely.
  source_missing_response_g4g5()

  withr::local_options(drmTMB.mr_g4g5_centre_random_effects = TRUE)
  a <- mr_g4_run_route("gaussian", information_multiplier = 1)
  b <- a
  b$design_state <- "centre_random_effects=FALSE"

  expect_silent(mr_g4g5_check_design_agreement(a, "test"))
  expect_error(
    mr_g4g5_check_design_agreement(rbind(a, b), "test"),
    "mixes 2 designs"
  )

  # Missing provenance must NOT block access to already-computed evidence -- it
  # must taint it, so the caveat travels with the artifact instead of the data
  # becoming unreadable.
  legacy <- a
  legacy$design_state <- NULL
  expect_warning(mr_g4g5_check_design_agreement(legacy, "test"), "UNAUTHENTICATED")
  marked <- suppressWarnings(mr_g4g5_check_design_agreement(legacy, "test"))
  expect_identical(unique(marked$design_state), "UNAUTHENTICATED")
})

test_that("no route's response is frozen across seeds (#980)", {
  # skew_normal built its response from deterministic quantile grids, so it was
  # bit-identical across every seed and only the MCAR mask varied. Those cells
  # measured sensitivity to masking on one fixed realisation, not coverage.
  source_missing_response_g4g5()
  skip_on_cran()

  for (route in mr_g4g5_route_manifest()$route_id) {
    a <- mr_g4g5_route_fixture(route, information_multiplier = 1, seed = 20260810L)
    b <- mr_g4g5_route_fixture(route, information_multiplier = 1, seed = 88888888L)
    resp <- names(a$data)[vapply(a$data, function(z) any(is.na(z)), logical(1))][1]
    va <- a$data[[resp]]; vb <- b$data[[resp]]
    if (is.factor(va)) { va <- as.integer(va); vb <- as.integer(vb) }
    ok <- !is.na(va) & !is.na(vb)
    expect_gt(sum(va[ok] != vb[ok]), 0L)
  }
})

test_that("no DGP draws its response from a fixed quantile set (#980)", {
  # The residual-level cousin, which the check above CANNOT see. student used
  # `sample(qt((seq_len(n)-.5)/n, ...))` -- a permutation of a fixed multiset. The
  # response still varies (eta and sigma vary per observation), so a
  # does-it-change test passes; what is frozen is the STANDARDIZED-residual
  # multiset, which makes the profile likelihood in the scale and shape targets
  # permutation-invariant and those cells near-deterministic.
  #
  # Detecting that from data alone would require reconstructing eta and sigma per
  # route. It is far cheaper, and no less binding, to forbid the construction:
  # a response must come from an r* sampler, never from q*() over a fixed grid.
  runner <- readLines(
    if (nzchar(system.file("sim/R/sim_missing_response_g4g5.R", package = "drmTMB")))
      system.file("sim/R/sim_missing_response_g4g5.R", package = "drmTMB")
    else testthat::test_path("..", "..", "inst", "sim", "R", "sim_missing_response_g4g5.R")
  )
  body <- runner[!grepl("^\\s*#", runner)]          # ignore commentary

  # a quantile function fed a deterministic index grid
  grid_draw <- grepl("q(norm|t|gamma|beta|pois|nbinom|lnorm)\\s*\\(\\s*\\(?\\s*(seq_len|i\\b|\\(i)", body)
  expect_equal(
    which(grid_draw), integer(0),
    label = "DGP lines drawing a response from a deterministic quantile grid"
  )

  # a permutation of a quantile set, which is the same defect wearing randomness
  perm_draw <- grepl("sample\\s*\\(\\s*q(norm|t|gamma|beta|pois|nbinom|lnorm)\\s*\\(", body)
  expect_equal(
    which(perm_draw), integer(0),
    label = "DGP lines permuting a fixed quantile multiset"
  )
})

test_that("every truth constant sits on the scale its profile target reports (#981)", {
  # Two truth constants were on the wrong scale: tweedie's nu stated the response
  # -scale power 1.35 where the profiled parameter is eta_nu on the link scale,
  # and cumulative_logit's second cutpoint stated the cumulative value 0.75 where
  # the internal parameter is a log-increment. Neither is detectable by the
  # calibration policy, which never compares truth against the target's scale.
  source_missing_response_g4g5()

  manifests <- mr_g4g5_freeze_target_manifests()

  # tweedie: p = 1 + plogis(eta_nu)  =>  eta_nu = qlogis(p - 1)
  tw <- manifests[["tweedie"]]
  nu_truth <- tw$truth[tw$parm == "fixef:nu:(Intercept)"]
  expect_equal(nu_truth, stats::qlogis(0.35), tolerance = 1e-12)
  expect_true(nu_truth < 0)                       # a link-scale value, not a power
  expect_false(isTRUE(all.equal(nu_truth, 1.35)))  # the value it used to hold

  # cumulative_logit: c_1 = theta_1; c_j = c_{j-1} + exp(theta_j)
  cl <- manifests[["cumulative_logit"]]
  t1 <- cl$truth[cl$parm == "ordinal:theta_ord:low|medium"]
  t2 <- cl$truth[cl$parm == "ordinal:theta_ord:medium|high"]
  expect_equal(t1, -0.90, tolerance = 1e-12)      # first cutpoint is the raw value
  expect_equal(t2, log(1.65), tolerance = 1e-12)  # second is a log-increment
  # reconstructing the cutpoints must recover the DGP's own boundaries
  expect_equal(c(t1, t1 + exp(t2)), c(-0.90, 0.75), tolerance = 1e-12)

  # every truth must at least be finite and named
  for (route in names(manifests)) {
    m <- manifests[[route]]
    expect_true(all(is.finite(m$truth)), label = paste(route, "truth finite"))
    expect_true(all(nzchar(m$parm)), label = paste(route, "parm named"))
  }
})

test_that("every G3 route builds a fixture without the testthat helpers", {
  # The campaign scripts source this runner after a plain `library(drmTMB)`, so a
  # route that silently depends on a test helper cannot run in deployment even
  # though it passes here. Rebuild each fixture in an environment whose only
  # parent is the package namespace, which is what an installed run actually sees.
  deploy_env <- new.env(parent = asNamespace("drmTMB"))
  source_missing_response_g4g5(env = deploy_env)

  routes <- deploy_env$mr_g4g5_route_manifest()$route_id
  expect_length(routes, 18L)

  failures <- vapply(routes, function(route) {
    tryCatch(
      {
        deploy_env$mr_g4g5_route_fixture(route, information_multiplier = 1)
        NA_character_
      },
      error = function(e) conditionMessage(e)
    )
  }, character(1))

  expect_equal(unname(routes[!is.na(failures)]), character(0))
})

test_that("a retained failure binds to a successful attempt without costing the cell", {
  # The prospective policy requires failed fits to stay in the unconditional
  # 1,200-attempt denominator. A failure record is narrower than a success record,
  # so combining them must union-and-pad rather than rbind naively -- otherwise the
  # cell aborts on exactly the attempt the denominator is supposed to retain.
  source_missing_response_g4g5()

  manifests <- mr_g4g5_freeze_target_manifests()
  g4 <- mr_g4_run_route("gaussian", information_multiplier = 1)
  registry <- mr_g5_registry_from_g4(manifests, g4)
  cell <- registry$cells[1, , drop = FALSE]
  seed <- registry$seeds$seed[registry$seeds$cell_id == cell$cell_id][1]

  success <- mr_g5_run_attempt(cell, seed = seed, replicate = 1L, trace = TRUE)
  failure <- mr_g5_failure_record(cell, seed = seed, message = "forced", fit_status = "fit_failed")

  expect_false(identical(ncol(success), ncol(failure)))   # the shapes really do differ

  bound <- mr_g5_bind_records(success, failure)
  expect_equal(nrow(bound), 2L)
  expect_setequal(names(bound), union(names(success), names(failure)))
  expect_identical(bound$fit_status[2], "fit_failed")
  # fields only the success record has are padded, not dropped
  expect_true(all(is.na(bound[2, setdiff(names(success), names(failure))])))
})

test_that("the runner's skew-normal fallback matches the tested helper", {
  # The runner carries its own copy of skew_normal_public_to_native() because the
  # canonical one is a testthat helper and cannot be reached from an installed
  # package. This is the guard against the two definitions drifting apart.
  deploy_env <- new.env(parent = asNamespace("drmTMB"))
  source_missing_response_g4g5(env = deploy_env)

  mu <- c(-1.5, 0, 0.4, 2.2)
  sigma <- c(0.3, 1, 1.7, 0.8)
  nu <- c(-2.5, 0, 1.4, 3.1)

  expect_equal(
    deploy_env$.mr_skew_normal_public_to_native(mu = mu, sigma = sigma, nu = nu),
    skew_normal_public_to_native(mu = mu, sigma = sigma, nu = nu)
  )
  expect_error(
    deploy_env$.mr_skew_normal_public_to_native(mu = 0, sigma = 0, nu = 1),
    "sigma must be finite and positive"
  )
})

test_that("the missing-response manifest freezes all 18 G3 routes", {
  source_missing_response_g4g5()
  manifest <- mr_g4g5_route_manifest()
  expect_silent(mr_g4g5_validate_manifest(manifest))
  expect_equal(nrow(manifest), 18L)
  expect_true("biv_gaussian" %in% manifest$route_id)
  expect_identical(manifest$mask_design[manifest$route_id == "biv_gaussian"], "paired_within_group")
  expect_true(all(grepl("^test-missing-response-", manifest$g3_source)))
  expect_true(all(nzchar(manifest$base_information)))
})

test_that("Gaussian G3 fixture retains its MCAR and target contract at all rungs", {
  source_missing_response_g4g5()
  for (rung in c(0.5, 1, 2)) {
    case <- mr_g4g5_gaussian_g3_dgp(rung)
    expect_equal(mean(is.na(case$data$y)), 0.25)
    expect_equal(nlevels(case$data$id), mr_g4g5_group_count(36L, 12L, rung))
    expect_identical(names(case$truth), c(
      "fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)",
      "fixef:sigma:z", "sd:mu:(1 | id)"
    ))
  }
})

test_that("T1 random-intercept fixtures preserve route-specific G3 shapes", {
  source_missing_response_g4g5()
  for (route in c("poisson", "nbinom2", "beta")) {
    case <- mr_g4g5_t1_ri_dgp(route, information_multiplier = 0.5)
    response <- if (route == "beta") "prop" else "count"
    expect_equal(mean(is.na(case$data[[response]])), 0.25, info = route)
    expect_equal(nlevels(case$data$id), mr_g4g5_group_count(48L, 12L, .5), info = route)
    expect_true("sd:mu:(1 | id)" %in% names(case$truth), info = route)
    expect_identical("fixef:sigma:z" %in% names(case$truth), route != "poisson", info = route)
  }
})

test_that("bivariate Gaussian fixture preserves independent partial-response masks", {
  source_missing_response_g4g5()
  case <- mr_g4g5_biv_gaussian_g3_dgp(0.5)
  expect_equal(mean(is.na(case$data$y1)), 0.25)
  expect_equal(mean(is.na(case$data$y2)), 0.25)
  expect_gt(sum(!is.na(case$data$y1) & is.na(case$data$y2)), 0L)
  expect_gt(sum(is.na(case$data$y1) & !is.na(case$data$y2)), 0L)
  expect_true(all(c("rho12", "sd:mu:mu1:(1 | p | id)") %in% names(case$truth)))
})

test_that("T2 fixtures retain their route-specific target and MCAR contracts", {
  source_missing_response_g4g5()
  for (route in c("student", "lognormal", "gamma", "skew_normal")) {
    case <- mr_g4g5_t2_dgp(route, 0.5)
    expect_equal(mean(is.na(case$data$y)), 0.25, info = route)
    expect_true("fixef:mu:x" %in% names(case$truth), info = route)
  }
})

test_that("T3 boundary fixtures retain all distributional target families", {
  source_missing_response_g4g5()
  for (route in c("tweedie", "zero_one_beta")) {
    case <- mr_g4g5_t3_dgp(route, .5)
    expect_equal(mean(is.na(case$data$y)), .25, info = route)
    expect_true("fixef:sigma:z" %in% names(case$truth), info = route)
  }
})

test_that("T4 fixtures retain encoded-response masks and ordinal cutpoints", {
  source_missing_response_g4g5()
  bb <- mr_g4g5_t4_dgp("beta_binomial", .5)
  expect_identical(is.na(bb$data$success), is.na(bb$data$failure))
  expect_equal(mean(is.na(bb$data$success)), .25)
  ord <- mr_g4g5_t4_dgp("cumulative_logit", .5)
  expect_equal(mean(is.na(ord$data$score)), .25)
  expect_true(all(c("ordinal:theta_ord:low|medium", "ordinal:theta_ord:medium|high") %in% names(ord$truth)))
})

test_that("T5 fixture preserves positive observed responses and its random SD target", {
  source_missing_response_g4g5(); case <- mr_g4g5_t5_dgp(.5)
  expect_equal(mean(is.na(case$data$count)), .25)
  expect_true(all(case$data$count[!is.na(case$data$count)] > 0))
  expect_true("sd:mu:(1 | id)" %in% names(case$truth))
})

test_that("T6 mixture fixtures retain all mixture-side target formulas", {
  source_missing_response_g4g5()
  for (route in c("zi_poisson","zi_nbinom2","hurdle_nbinom2")) {
    case<-mr_g4g5_t6_dgp(route,.5); expect_equal(mean(is.na(case$data$count)),.25,info=route)
    dpar<-if(route=="hurdle_nbinom2")"hu" else "zi";expect_true(any(grepl(paste0("fixef:",dpar),names(case$truth))),info=route)
  }
})

test_that("route dispatcher resolves all 18 frozen G3 designs", {
  source_missing_response_g4g5(); routes<-mr_g4g5_route_manifest()$route_id
  cases<-lapply(routes,mr_g4g5_route_fixture,information_multiplier=.5)
  expect_equal(length(cases),18L);expect_true(all(vapply(cases,function(x)is.data.frame(x$data)&&length(x$truth)>0,logical(1))))
})

test_that("Gaussian target manifest materializes from canonical profile targets", {
  source_missing_response_g4g5(); out<-mr_g4g5_materialise_target_manifest("gaussian",.5)
  expect_silent(mr_g4_validate_target_manifest(out$manifest));expect_equal(nrow(out$manifest),5L)
})

test_that("every G3 route materializes an exact canonical target manifest", {
  source_missing_response_g4g5(); routes<-mr_g4g5_route_manifest()$route_id
  manifests<-lapply(routes,function(r) mr_g4g5_materialise_target_manifest(r,.5)$manifest)
  expect_equal(length(manifests),18L);expect_true(all(vapply(manifests,function(x){mr_g4_validate_target_manifest(x);TRUE},logical(1))))
})

test_that("route-level G4 run retains a record for every Gaussian target", {
  source_missing_response_g4g5(); out<-mr_g4_run_route("gaussian",.5,trace=FALSE)
  expect_equal(nrow(out),5L);expect_true(all(out$information_rung=="0.5x"));expect_true(all(out$mask_fraction==.25))
  expect_true(all(!out$g4_interval_usable))
})

test_that("bivariate G4 receipts retain every partial-response count", {
  source_missing_response_g4g5(); out <- mr_g4_run_route("biv_gaussian", .5, trace = FALSE)
  counts <- c("mask_complete_pairs", "mask_y1_only_missing", "mask_y2_only_missing", "mask_both_missing")
  expect_true(all(counts %in% names(out)))
  expect_equal(sum(out[1L, counts]), nrow(mr_g4g5_route_fixture("biv_gaussian", .5)$data))
})

test_that("G4 artifact writer round-trips retained records", {
  source_missing_response_g4g5(); p<-file.path(tempdir(),"mr-g4-records.rds")
  x<-data.frame(route_id="gaussian",parm="fixef:mu:x",g4_pass=TRUE)
  expect_true(file.exists(mr_g4_write_records(x,p)));expect_equal(readRDS(p),x)
})

test_that("G4 retains failed, clamped, and truth-missing profile attempts", {
  source_missing_response_g4g5()
  ok <- mr_g4_validate_record(data.frame(conf.low = 0.1, conf.high = 0.4, conf.status = "profile", profile.boundary = FALSE, truth = 0.2))
  clamp <- mr_g4_validate_record(data.frame(conf.low = NA_real_, conf.high = NA_real_, conf.status = "clamp_limited", profile.boundary = TRUE, truth = 0.2))
  miss <- mr_g4_validate_record(data.frame(conf.low = 0.1, conf.high = 0.4, conf.status = "profile", profile.boundary = FALSE, truth = 0.8))
  expect_true(ok$g4_feasible)
  expect_false(clamp$g4_interval_usable)
  expect_true(miss$g4_feasible)
  expect_false(miss$g4_truth_contained)
})

test_that("a profiled G4 pass requires requested trace retention", {
  source_missing_response_g4g5()
  no_trace <- mr_g4_validate_record(data.frame(
    conf.low = 0.1, conf.high = 0.4, conf.status = "profile", profile.boundary = FALSE,
    truth = 0.2, interval_method = "profile", trace_requested = FALSE
  ))
  traced <- mr_g4_validate_record(data.frame(
    conf.low = 0.1, conf.high = 0.4, conf.status = "profile", profile.boundary = FALSE,
    truth = 0.2, interval_method = "profile", trace_requested = TRUE
  ))
  expect_false(no_trace$g4_feasible)
  expect_true(traced$g4_feasible)
})

test_that("target manifests require every canonical target and choose the gate method", {
  source_missing_response_g4g5()
  targets <- data.frame(
    parm = c("fixef:mu:x", "cutpoint:1"), target_class = c("fixed", "cutpoint"),
    dpar = "mu", scale = "response", profile_ready = c(TRUE, FALSE)
  )
  manifest <- mr_g4_target_manifest(
    "cumulative_logit", targets,
    c("fixef:mu:x" = 0.8, "cutpoint:1" = -0.9)
  )
  expect_silent(mr_g4_validate_target_manifest(manifest))
  expect_identical(manifest$interval_method, c("profile", "wald"))
  expect_error(
    mr_g4_target_manifest("cumulative_logit", targets, c("fixef:mu:x" = 0.8)),
    "every canonical target"
  )
})

test_that("G5 coverage retains all planned attempts in its denominator", {
  source_missing_response_g4g5()
  records <- data.frame(route_id = "gaussian", parm = "fixef:mu:x",
    information_rung = "1x", g4_interval_usable = c(TRUE, FALSE, TRUE, FALSE),
    g4_truth_contained = c(TRUE, NA, FALSE, NA))
  out <- mr_g5_summarise_attempts(records, planned = 4L)
  expect_equal(out$n_attempt, 4L)
  expect_equal(out$n_interval_usable, 2L)
  expect_equal(out$coverage, 0.25)
  expect_error(mr_g5_summarise_attempts(records, planned = 5L), "planned")
})

test_that("route-specific G5 cohorts retain only frozen eligible cells and seeds", {
  source_missing_response_g4g5()
  registry <- list(
    cells = data.frame(cell_id = c("a", "b"), route_id = c("poisson", "gamma")),
    seeds = data.frame(cell_id = c("a", "a", "b"), seed = 1:3)
  )
  out <- mr_g5_select_routes(registry, "poisson")
  expect_identical(out$cells$cell_id, "a")
  expect_true(all(out$seeds$cell_id == "a"))
  expect_error(mr_g5_select_routes(registry, "not_a_route"), "absent")
})

test_that("G5 calibration gate rejects systematic overcoverage without promotion", {
  source_missing_response_g4g5()
  summary <- data.frame(route_id = "gaussian", parm = "fixef:mu:(Intercept)",
    information_rung = c("0.5x", "1x", "2x"), n_planned = 1200L,
    n_attempt = 1200L, n_interval_usable = 1200L, coverage = 1,
    coverage_mcse = 0, stringsAsFactors = FALSE)
  calibration <- mr_g5_calibration_gate(summary)
  expect_silent(mr_g5_validate_calibration(calibration))
  expect_false(any(calibration$calibration_pass))
  expect_true(all(calibration$calibration_reason == "coverage_outside_policy_band"))
  summary$coverage <- .95
  summary$coverage_mcse <- sqrt(.95 * .05 / 1200)
  expect_true(all(mr_g5_calibration_gate(summary)$calibration_pass))
})

test_that("G5 calibration v2 gates on an interval-availability RATE, not the old all-1200 rule", {
  # docs/dev-log/interval-availability/2026-08-11-availability-threshold-evidence.md
  # the 0.99 floor: cells at or above it pass on their coverage merits alone;
  # below it, availability itself becomes the (separately labelled) reason.
  source_missing_response_g4g5()
  base <- list(route_id = "gaussian", parm = "fixef:mu:(Intercept)",
    information_rung = "1x", n_planned = 1200L, n_attempt = 1200L,
    coverage = .95, coverage_mcse = sqrt(.95 * .05 / 1200))

  # 1. exactly 1.0 availability: full parity with the old rule, must pass.
  full <- do.call(data.frame, c(base, list(n_interval_usable = 1200L, stringsAsFactors = FALSE)))
  cal_full <- mr_g5_calibration_gate(full)
  expect_silent(mr_g5_validate_calibration(cal_full))
  expect_equal(cal_full$interval_availability, 1)
  expect_true(cal_full$calibration_available)   # old-rule indicator, still TRUE here
  expect_true(cal_full$calibration_availability_ok)
  expect_false(cal_full$coverage_is_conditional)
  expect_true(cal_full$calibration_pass)
  expect_identical(cal_full$calibration_reason, "pass")

  # 2. exactly at the 0.99 boundary: must PASS.
  at_floor <- do.call(data.frame, c(base, list(n_interval_usable = 1188L, stringsAsFactors = FALSE)))
  cal_at_floor <- mr_g5_calibration_gate(at_floor)
  expect_silent(mr_g5_validate_calibration(cal_at_floor))
  expect_equal(cal_at_floor$interval_availability, 0.99)
  expect_false(cal_at_floor$calibration_available)  # old rule would have failed this cell
  expect_true(cal_at_floor$calibration_availability_ok)
  expect_true(cal_at_floor$coverage_is_conditional)
  expect_true(cal_at_floor$calibration_pass)
  expect_identical(cal_at_floor$calibration_reason, "pass")

  # 3. just below the 0.99 boundary: must FAIL, and on an AVAILABILITY reason,
  #    not a coverage reason -- coverage itself is still in-band here.
  below_floor <- do.call(data.frame, c(base, list(n_interval_usable = 1187L, stringsAsFactors = FALSE)))
  cal_below_floor <- mr_g5_calibration_gate(below_floor)
  expect_silent(mr_g5_validate_calibration(cal_below_floor))
  expect_true(cal_below_floor$calibration_in_band)
  expect_false(cal_below_floor$calibration_availability_ok)
  expect_false(cal_below_floor$calibration_pass)
  expect_identical(cal_below_floor$calibration_reason, "availability_below_policy_floor")

  # 4. in-band coverage but only 0.5 availability: must FAIL on availability.
  half <- do.call(data.frame, c(base, list(n_interval_usable = 600L, stringsAsFactors = FALSE)))
  cal_half <- mr_g5_calibration_gate(half)
  expect_silent(mr_g5_validate_calibration(cal_half))
  expect_equal(cal_half$interval_availability, 0.5)
  expect_true(cal_half$calibration_in_band)
  expect_false(cal_half$calibration_pass)
  expect_identical(cal_half$calibration_reason, "availability_below_policy_floor")

  # 5. out-of-band coverage with full availability: must FAIL on COVERAGE,
  #    unaffected by the availability rule (this is the old rule's own case).
  bad_coverage <- do.call(data.frame, c(
    list(route_id = "gaussian", parm = "fixef:mu:(Intercept)", information_rung = "1x",
      n_planned = 1200L, n_attempt = 1200L, n_interval_usable = 1200L,
      coverage = 1, coverage_mcse = 0), stringsAsFactors = FALSE))
  cal_bad_coverage <- mr_g5_calibration_gate(bad_coverage)
  expect_silent(mr_g5_validate_calibration(cal_bad_coverage))
  expect_true(cal_bad_coverage$calibration_availability_ok)
  expect_false(cal_bad_coverage$calibration_pass)
  expect_identical(cal_bad_coverage$calibration_reason, "coverage_outside_policy_band")

  # The policy identifier changed with the predicate.
  expect_identical(cal_full$calibration_policy, "mr-g5-calibration-v2")
})

test_that("G5 provenance receipt hashes runner, inputs, and all receipts", {
  source_missing_response_g4g5()
  paths <- vapply(seq_len(4L), function(i) {
    path <- tempfile(fileext = ".rds")
    saveRDS(i, path)
    path
  }, character(1))
  receipt <- mr_g5_provenance_receipt(paths[[1L]], paths[[2L]], paths[[3L]], paths[[4L]],
    command = "Rscript tools/mr-g5-reconcile.R")
  expect_silent(mr_g5_validate_provenance(receipt))
  expect_equal(nrow(receipt$input_md5), 3L)
  receipt$input_md5 <- receipt$input_md5[0, , drop = FALSE]
  expect_error(mr_g5_validate_provenance(receipt), "incomplete")
})

test_that("Wald fallback is usable only for a target marked profile-unavailable", {
  source_missing_response_g4g5()
  wald <- mr_g4_validate_record(data.frame(
    conf.low = 0.1, conf.high = 0.4, conf.status = "wald", profile.boundary = NA,
    truth = 0.2, interval_method = "wald"
  ))
  wrong <- mr_g4_validate_record(data.frame(
    conf.low = 0.1, conf.high = 0.4, conf.status = "wald", profile.boundary = NA,
    truth = 0.2, interval_method = "profile"
  ))
  expect_true(wald$g4_feasible)
  expect_false(wrong$g4_interval_usable)
})

test_that("G4 runner writes one retained record per canonical Gaussian target", {
  source_missing_response_g4g5()
  set.seed(7304)
  dat <- data.frame(x = rnorm(120))
  dat$y <- 0.3 + 0.4 * dat$x + rnorm(120, sd = 0.7)
  dat$y[sample.int(nrow(dat), 30L)] <- NA_real_
  fit <- drmTMB(
    bf(y ~ x), family = gaussian(), data = dat,
    missing = miss_control(response = "include")
  )
  targets <- profile_targets(fit)
  truth <- c(
    "fixef:mu:(Intercept)" = 0.3, "fixef:mu:x" = 0.4,
    "fixef:sigma:(Intercept)" = log(0.7), "sigma" = 0.7
  )
  manifest <- mr_g4_target_manifest("gaussian", targets, truth)
  out <- mr_g4_run_target_manifest(fit, manifest, trace = FALSE)
  expect_equal(nrow(out), nrow(targets))
  expect_setequal(out$parm, targets$parm)
  expect_true(all(out$interval_method == "profile"))
  expect_true(all(out$conf.status %in% c("profile", "profile_failed", "clamp_limited")))
})

test_that("route runner retains one failure record per frozen target", {
  source_missing_response_g4g5()
  target_manifest <- data.frame(
    route_id = "not-a-route", parm = c("fixef:mu:(Intercept)", "fixef:mu:x"),
    truth = c(0, 1), target_class = "fixed-effect", dpar = "mu", scale = "link",
    profile_ready = TRUE, interval_method = "profile", conf.level = .95
  )
  out <- mr_g4_run_route("not-a-route", .5, target_manifest = target_manifest)
  expect_equal(nrow(out), 2L)
  expect_true(all(out$conf.status == "fixture_failed"))
  expect_true(all(!out$g4_feasible))
})

test_that("G4 task registry requires all routes and fixes the three information rungs", {
  source_missing_response_g4g5()
  routes <- mr_g4g5_route_manifest()$route_id
  target_manifests <- setNames(lapply(routes, function(route) {
    data.frame(route_id = route, parm = "fixef:mu:x", truth = 0.2,
      target_class = "fixed-effect", dpar = "mu", scale = "link",
      profile_ready = TRUE, interval_method = "profile", conf.level = 0.95)
  }), routes)
  registry <- mr_g4g5_task_registry(target_manifests, n_rep = 2L)
  expect_equal(nrow(registry$cells), 18L * 3L)
  expect_equal(nrow(registry$seeds), 18L * 3L * 2L)
  expect_setequal(registry$cells$information_rung, c("0.5x", "1x", "2x"))
  expect_identical(registry$seeds$seed, mr_g4g5_task_registry(target_manifests, n_rep = 2L)$seeds$seed)
  expect_error(mr_g4g5_task_registry(target_manifests[-1L]), "18 routes")
})

test_that("G5 registry is gated by G4-feasible targets and fixes 1,200 attempts", {
  source_missing_response_g4g5()
  routes <- mr_g4g5_route_manifest()$route_id
  target_manifests <- setNames(lapply(routes, function(route) {
    data.frame(route_id = route, parm = "fixef:mu:x", truth = 0.2,
      target_class = "fixed-effect", dpar = "mu", scale = "link",
      profile_ready = TRUE, interval_method = "profile", conf.level = 0.95)
  }), routes)
  g4 <- expand.grid(route_id = routes, information_rung = c("0.5x", "1x", "2x"),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  g4$parm <- "fixef:mu:x"
  g4$g4_feasible <- FALSE
  g4$g4_feasible[g4$route_id %in% routes[c(1L, 2L)] & g4$information_rung == "1x"] <- TRUE
  registry <- mr_g5_registry_from_g4(target_manifests, g4)
  expect_equal(nrow(registry$cells), 2L)
  expect_equal(nrow(registry$seeds), 2L * 1200L)
  expect_true(all(registry$cells$information_rung == "1x"))
  expect_true(all(registry$seeds$replicate <= 1200L))
  expect_error(mr_g5_registry_from_g4(target_manifests, transform(g4, g4_feasible = FALSE)), "No G4-feasible")
})

test_that("G5 validator retains every deterministic attempt including failures", {
  source_missing_response_g4g5()
  target <- data.frame(
    route_id = "gaussian", parm = "fixef:mu:x", truth = .2,
    target_class = "fixed-effect", dpar = "mu", scale = "link",
    profile_ready = TRUE, interval_method = "profile", conf.level = .95,
    information_rung = "1x", information_multiplier = 1,
    stringsAsFactors = FALSE
  )
  registry <- list(
    cells = transform(target, cell_id = "mr_g5_0001"),
    seeds = data.frame(cell_id = "mr_g5_0001", cell_index = 1L,
      replicate = seq_len(1200L), seed = seq_len(1200L)),
    n_rep = 1200L, master_seed = 1L
  )
  records <- do.call(rbind, lapply(seq_len(1200L), function(i) {
    x <- mr_g5_failure_record(target, seed = i, message = "retained failure")
    x$replicate <- i
    x
  }))
  expect_silent(mr_g5_validate_campaign(records, registry))
  summary <- mr_g5_summarise_attempts(records)
  expect_equal(summary$n_attempt, 1200L)
  expect_equal(summary$n_interval_usable, 0L)
  expect_equal(summary$coverage, 0)
  records$attempt_seed[1L] <- 999L
  expect_error(mr_g5_validate_campaign(records, registry), "deterministic seed")
})

test_that("G5 reconciliation requires a complete, non-conflicting receipt set", {
  source_missing_response_g4g5()
  cell <- data.frame(
    route_id = "gaussian", parm = "fixef:mu:x", truth = .2,
    target_class = "fixed-effect", dpar = "mu", scale = "link",
    profile_ready = TRUE, interval_method = "profile", conf.level = .95,
    information_rung = "1x", information_multiplier = 1,
    cell_id = "mr_g5_0001", stringsAsFactors = FALSE
  )
  registry <- list(
    cells = cell,
    seeds = data.frame(cell_id = "mr_g5_0001", cell_index = 1L,
      replicate = seq_len(1200L), seed = seq_len(1200L)),
    n_rep = 1200L, master_seed = 1L
  )
  records <- do.call(rbind, lapply(seq_len(1200L), function(i) {
    out <- mr_g5_failure_record(cell, seed = i, message = "retained failure")
    out$replicate <- i
    out$mask_any_response_rows <- 0
    out
  }))
  first <- tempfile(fileext = ".rds")
  duplicate <- tempfile(fileext = ".rds")
  saveRDS(records, first)
  saveRDS(records, duplicate)
  reconciled <- mr_g5_reconcile_checkpoints(c(first, duplicate), registry)
  expect_equal(nrow(reconciled), 1200L)
  expect_true(all(grepl(";", reconciled$checkpoint_paths, fixed = TRUE)))
  conflicting <- records
  conflicting$receipt_note <- "different receipt payload"
  saveRDS(conflicting, duplicate)
  expect_error(mr_g5_reconcile_checkpoints(c(first, duplicate), registry), "Conflicting G5")
})

test_that("G5 runner retains a real masked Gaussian attempt", {
  source_missing_response_g4g5()
  manifest <- mr_g4g5_materialise_target_manifest("gaussian", .5)$manifest
  cell <- manifest[manifest$parm == "fixef:mu:x", , drop = FALSE]
  cell$information_rung <- "0.5x"
  cell$information_multiplier <- .5
  out <- mr_g5_run_attempt(cell, seed = 2026073003L, replicate = 1L, trace = FALSE)
  expect_equal(nrow(out), 1L)
  expect_equal(out$attempt_seed, 2026073003L)
  expect_true(all(c("fit_status", "fit_converged", "pdHess", "interval_usable",
    "truth_contained", "boundary_or_clamp", "mask_fraction", "mask_any_response_rows") %in% names(out)))
})

test_that("G5 campaign runner retains all planned mock failures", {
  source_missing_response_g4g5()
  cell <- data.frame(
    route_id = "gaussian", parm = "fixef:mu:x", truth = .2,
    target_class = "fixed-effect", dpar = "mu", scale = "link",
    profile_ready = TRUE, interval_method = "profile", conf.level = .95,
    information_rung = "1x", information_multiplier = 1,
    cell_id = "mr_g5_0001", stringsAsFactors = FALSE
  )
  registry <- list(
    cells = cell,
    seeds = data.frame(cell_id = "mr_g5_0001", cell_index = 1L,
      replicate = seq_len(1200L), seed = seq_len(1200L)),
    n_rep = 1200L, master_seed = 1L
  )
  runner <- function(cell, seed, replicate, trace) {
    out <- mr_g5_failure_record(cell, seed, "retained mock failure")
    out$replicate <- replicate
    out$mask_any_response_rows <- 0
    out
  }
  out <- mr_g5_run_campaign(registry, runner = runner)
  expect_equal(nrow(out), 1200L)
  expect_equal(sum(out$fit_status == "fit_failed"), 1200L)
})

test_that("G4 campaign validator requires every frozen route target and rung", {
  source_missing_response_g4g5()
  routes <- mr_g4g5_route_manifest()$route_id
  target_manifests <- setNames(lapply(routes, function(route) data.frame(
    route_id = route, parm = "fixef:mu:x", truth = .2, target_class = "fixed-effect",
    dpar = "mu", scale = "link", profile_ready = TRUE, interval_method = "profile",
    conf.level = .95
  )), routes)
  registry <- mr_g4g5_task_registry(target_manifests)
  records <- registry$cells[, c("route_id", "parm", "information_rung", "interval_method")]
  records$trace_requested <- TRUE
  records$conf.low <- 0
  records$conf.high <- 1
  records$g4_feasible <- TRUE
  expect_silent(mr_g4_validate_campaign(records, registry))
  expect_error(mr_g4_validate_campaign(records[-1L, ], registry), "every frozen target")
  records$trace_requested[1L] <- FALSE
  expect_error(mr_g4_validate_campaign(records, registry), "trace-request")
})

test_that("G4 checkpoint reconciliation retains provenance and rejects collisions", {
  source_missing_response_g4g5()
  one <- data.frame(
    route_id = "gaussian", parm = "fixef:mu:x", information_rung = "1x",
    g4_interval_usable = TRUE,
    # a real record carries its design (#982); a fixture that omits it is
    # reconciled as UNAUTHENTICATED, which is correct but not what this test is about
    design_state = "centre_random_effects=TRUE",
    stringsAsFactors = FALSE
  )
  duplicate <- tempfile(fileext = ".rds")
  original <- tempfile(fileext = ".rds")
  saveRDS(one, original)
  saveRDS(one, duplicate)
  out <- mr_g4_reconcile_checkpoints(c(original, duplicate))
  expect_equal(nrow(out), 1L)
  expect_true(out$g4_feasible)
  expect_match(out$checkpoint_paths, normalizePath(original), fixed = TRUE)
  expect_match(out$checkpoint_paths, normalizePath(duplicate), fixed = TRUE)

  conflict <- tempfile(fileext = ".rds")
  saveRDS(transform(one, g4_interval_usable = FALSE), conflict)
  expect_error(
    mr_g4_reconcile_checkpoints(c(original, conflict)),
    "Conflicting G4 checkpoint"
  )
})
