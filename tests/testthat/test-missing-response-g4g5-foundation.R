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
    expect_equal(nlevels(case$data$id), 36L * rung)
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
    expect_equal(nlevels(case$data$id), 24L, info = route)
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

test_that("G4 retains failed, clamped, and truth-missing profile attempts", {
  source_missing_response_g4g5()
  ok <- mr_g4_validate_record(data.frame(conf.low = 0.1, conf.high = 0.4, conf.status = "profile", profile.boundary = FALSE, truth = 0.2))
  clamp <- mr_g4_validate_record(data.frame(conf.low = NA_real_, conf.high = NA_real_, conf.status = "clamp_limited", profile.boundary = TRUE, truth = 0.2))
  miss <- mr_g4_validate_record(data.frame(conf.low = 0.1, conf.high = 0.4, conf.status = "profile", profile.boundary = FALSE, truth = 0.8))
  expect_true(ok$g4_pass)
  expect_false(clamp$g4_interval_usable)
  expect_false(miss$g4_pass)
  expect_false(miss$g4_truth_contained)
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
  expect_true(wald$g4_pass)
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

test_that("G5 registry is gated by G4-passing targets and fixes 1,200 attempts", {
  source_missing_response_g4g5()
  routes <- mr_g4g5_route_manifest()$route_id
  target_manifests <- setNames(lapply(routes, function(route) {
    data.frame(route_id = route, parm = "fixef:mu:x", truth = 0.2,
      target_class = "fixed-effect", dpar = "mu", scale = "link",
      profile_ready = TRUE, interval_method = "profile", conf.level = 0.95)
  }), routes)
  g4 <- data.frame(route_id = routes, parm = "fixef:mu:x", g4_pass = FALSE)
  g4$g4_pass[c(1L, 2L)] <- TRUE
  registry <- mr_g5_registry_from_g4(target_manifests, g4)
  expect_equal(nrow(registry$cells), 2L * 3L)
  expect_equal(nrow(registry$seeds), 2L * 3L * 1200L)
  expect_true(all(registry$seeds$replicate <= 1200L))
  expect_error(mr_g5_registry_from_g4(target_manifests, transform(g4, g4_pass = FALSE)), "No G4-passing")
})
