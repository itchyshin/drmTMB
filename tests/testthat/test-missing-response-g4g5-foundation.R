source_missing_response_g4g5 <- function(env = parent.frame()) {
  path <- system.file("sim/R/sim_missing_response_g4g5.R", package = "drmTMB")
  if (!nzchar(path)) path <- testthat::test_path("..", "..", "inst", "sim", "R", "sim_missing_response_g4g5.R")
  source(path, local = env)
}

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
    "truth_contained", "boundary_or_clamp") %in% names(out)))
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
    g4_interval_usable = TRUE, stringsAsFactors = FALSE
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
