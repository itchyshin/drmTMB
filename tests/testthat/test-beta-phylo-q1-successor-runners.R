successor_env <- new.env(parent = globalenv())
sys.source(
  testthat::test_path(
    "..",
    "..",
    "tools",
    "run-beta-phylo-q1-successor-recovery.R"
  ),
  envir = successor_env
)

diagnostic_env <- new.env(parent = globalenv())
sys.source(
  testthat::test_path(
    "..",
    "..",
    "tools",
    "run-beta-phylo-q1-is-diagnostic.R"
  ),
  envir = diagnostic_env
)

test_that("successor high-information design is frozen and disjoint", {
  repo_root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  certification <- successor_env$successor_seed_grid("certification")
  smoke <- successor_env$successor_seed_grid("smoke")

  expect_equal(nrow(certification), 800L)
  expect_equal(as.integer(table(certification$g)), c(400L, 400L))
  expect_equal(unique(certification$m), 4L)
  expect_equal(length(unique(certification$seed)), 800L)
  expect_length(intersect(certification$seed, smoke$seed), 0L)
  expect_invisible(
    successor_env$assert_frozen_successor_design(
      certification,
      successor_env$frozen_successor_design_path(repo_root)
    )
  )
  audit <- successor_env$successor_seed_audit(certification, repo_root)
  expect_true(all(audit$pass))
  expect_true(all(audit$observed[grepl("^overlap_", audit$check)] == 0L))
})

test_that("successor seed generation freezes and restores RNG state", {
  old_kind <- RNGkind()
  on.exit(do.call(RNGkind, as.list(old_kind)), add = TRUE)
  suppressWarnings(
    RNGkind("L'Ecuyer-CMRG", "Box-Muller", "Rounding")
  )
  caller_kind <- RNGkind()
  set.seed(99)
  caller_seed <- .Random.seed

  first <- suppressWarnings(successor_env$successor_seed_grid("certification"))
  second <- suppressWarnings(successor_env$successor_seed_grid("certification"))

  expect_equal(first, second)
  expect_equal(RNGkind(), caller_kind)
  expect_equal(.Random.seed, caller_seed)
})

test_that("log-tau recovery uses a Monte Carlo equivalence interval", {
  summary <- data.frame(
    g = c(512L, 1024L, 1024L),
    parameter = c("log_tau", "log_tau", "beta_mu_x"),
    bias = c(-0.08, -0.06, 0.01),
    mcse_bias = c(0.02, 0.01, 0.01)
  )
  gate <- successor_env$mc_interval_gate(summary)

  expect_false(gate$pass[gate$g == 512L])
  expect_true(gate$pass[gate$g == 1024L])
  expect_equal(
    gate$lower[gate$g == 1024L],
    -0.06 - stats::qnorm(0.975) * 0.01
  )
})

test_that("diagnostic design selects the first 24 frozen g256 m4 rows", {
  repo_root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  design <- diagnostic_env$diagnostic_seed_design(repo_root)

  expect_equal(nrow(design), 24L)
  expect_true(all(design$g == 256L))
  expect_true(all(design$m == 4L))
  expect_equal(design$replicate, 1:24)
  expect_equal(sum(design$diagnostic_role == "D0_screen"), 5L)
  expect_equal(
    design$seed[1:5],
    c(1834980414L, 348679578L, 1028561677L, 2023711313L, 2093308563L)
  )
  expect_invisible(diagnostic_env$assert_frozen_diagnostic_design(repo_root))
  audit <- diagnostic_env$diagnostic_seed_audit(design, repo_root)
  expect_true(all(audit$pass))
  expect_true(all(audit$observed[grepl("^overlap_", audit$check)] == 0L))
})

test_that("importance weights are normalized stably", {
  equal <- diagnostic_env$importance_weight_stats(rep(0, 2000L))
  concentrated <- diagnostic_env$importance_weight_stats(c(0, rep(100, 1999L)))

  expect_equal(unname(equal[["ess"]]), 1000, tolerance = 1e-8)
  expect_equal(unname(equal[["max_weight"]]), 1 / 1000, tolerance = 1e-12)
  expect_lt(unname(concentrated[["ess"]]), 1.01)
  expect_gt(unname(concentrated[["max_weight"]]), 0.99)
})

make_screen_fixture <- function(pass = TRUE) {
  rows <- data.frame(
    replicate = rep(1:5, each = 4L),
    row = rep(1:4, times = 5L)
  )
  grid <- do.call(rbind, lapply(1:5, diagnostic_env$diagnostic_mc_grid))
  rows$n <- grid$n
  rows$batch <- grid$batch
  rows$mc_seed <- grid$mc_seed
  rows$total_draws <- 2L * grid$n
  rows$corrected_nll <- 1
  rows$ess <- 2000
  rows$max_weight <- 0.001
  rows$log_tau_score <- -0.2
  rows$implied_log_tau_shift <- 0.12
  rows$all_score_finite <- TRUE
  rows$hessian_pd <- TRUE
  rows$hessian_condition <- 20
  rows$convergence <- 0L
  rows$pdHess <- TRUE
  if (!pass) {
    rows$ess[rows$replicate == 3L & rows$n == 32768L] <- 10
  }
  rows
}

test_that("diagnostic screen gates fail closed on weight collapse", {
  passing <- diagnostic_env$diagnostic_screen_gates(make_screen_fixture())
  failing <- diagnostic_env$diagnostic_screen_gates(make_screen_fixture(FALSE))

  expect_equal(passing$decision$status, "PASS_TO_D1")
  expect_true(all(passing$gates$pass))
  expect_equal(failing$decision$status, "INCONCLUSIVE")
  expect_false(failing$gates$pass[failing$gates$replicate == 3L])
})

test_that("D1 authorization recomputes and authenticates the exact D0 screen", {
  repo_root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  design <- diagnostic_env$diagnostic_seed_design(repo_root)
  screen_design <- design[design$diagnostic_role == "D0_screen", , drop = FALSE]
  raw <- make_screen_fixture()
  raw$dgp_seed <- rep(screen_design$seed, each = 4L)
  gates <- diagnostic_env$diagnostic_screen_gates(raw)
  preflight <- data.frame(
    check = "candidate",
    observed = "ok",
    expected = "ok",
    pass = TRUE
  )
  out <- tempfile("authenticated-screen-")
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  dir.create(file.path(out, "attempts"), recursive = TRUE)
  successor_env$write_tsv(design, file.path(out, "design.tsv"))
  successor_env$write_tsv(
    diagnostic_env$diagnostic_seed_audit(design, repo_root),
    file.path(out, "seed-audit.tsv")
  )
  successor_env$write_tsv(preflight, file.path(out, "preflight-manifest.tsv"))
  successor_env$write_tsv(
    data.frame(status = "COMPLETE", git_head = "abc"),
    file.path(out, "run-provenance.tsv")
  )
  successor_env$write_tsv(raw, file.path(out, "importance-screen.tsv"))
  successor_env$write_tsv(gates$gates, file.path(out, "screen-gates.tsv"))
  successor_env$write_tsv(gates$decision, file.path(out, "screen-decision.tsv"))
  for (i in seq_len(nrow(screen_design))) {
    row <- screen_design[i, , drop = FALSE]
    path <- file.path(
      out,
      "attempts",
      sprintf("screen-r%04d-s%d.tsv", row$replicate, row$seed)
    )
    successor_env$write_tsv(
      raw[raw$replicate == row$replicate, , drop = FALSE],
      path
    )
  }
  expect_invisible(diagnostic_env$assert_screen_pass(
    out,
    "abc",
    preflight,
    design,
    repo_root
  ))

  tampered <- gates$decision
  tampered$status <- "INCONCLUSIVE"
  successor_env$write_tsv(tampered, file.path(out, "screen-decision.tsv"))
  expect_error(
    diagnostic_env$assert_screen_pass(out, "abc", preflight, design, repo_root),
    "did not authorize"
  )
})

make_recovery_fixture <- function(reps = 10L) {
  cells <- data.frame(
    cell_id = c("g0512_m04", "g1024_m04"),
    cell_number = 1:2,
    g = c(512L, 1024L),
    m = 4L
  )
  raw <- cells[rep(1:2, each = reps), , drop = FALSE]
  raw$replicate <- rep(seq_len(reps), 2L)
  raw$seed <- seq_len(nrow(raw)) + 1000L
  raw$convergence <- 0L
  raw$pdHess <- TRUE
  raw$boundary <- FALSE
  parameters <- c(
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_x",
    "log_tau"
  )
  truth <- c(0, 0.35, log(0.25), 0.20, log(0.30))
  for (i in seq_along(parameters)) {
    raw[[paste0("truth_", parameters[[i]])]] <- truth[[i]]
    raw[[paste0("estimate_", parameters[[i]])]] <- truth[[i]]
  }
  raw
}

test_that("successor recovery decision algebra is exact and RMSE is descriptive", {
  raw <- make_recovery_fixture()
  both <- successor_env$successor_recovery_gates(raw, expected_reps = 10L)
  expect_equal(both$decision$status, "PASS_EXACT_G512_G1024")
  expect_true(all(both$rmse$role == "descriptive_only"))

  h1_hold <- raw
  h1_hold$estimate_log_tau[h1_hold$g == 512L] <-
    h1_hold$truth_log_tau[h1_hold$g == 512L] - 0.20
  one <- successor_env$successor_recovery_gates(h1_hold, expected_reps = 10L)
  expect_equal(one$decision$status, "PASS_EXACT_G1024_ONLY")

  h2_hold <- raw
  h2_hold$estimate_log_tau[h2_hold$g == 1024L] <-
    h2_hold$truth_log_tau[h2_hold$g == 1024L] - 0.20
  none <- successor_env$successor_recovery_gates(h2_hold, expected_reps = 10L)
  expect_equal(none$decision$status, "HOLD_NO_PR1")
})

test_that("successor recovery counts failures and nonfinite estimates", {
  raw <- make_recovery_fixture()
  raw$convergence[which(raw$g == 1024L)[[1L]]] <- NA_integer_
  failed <- successor_env$successor_recovery_gates(raw, expected_reps = 10L)
  expect_equal(failed$quality$convergence_rate[failed$quality$g == 1024L], 0.9)
  expect_equal(failed$decision$status, "HOLD_NO_PR1")

  raw <- make_recovery_fixture()
  raw$estimate_log_tau[which(raw$g == 1024L)[[1L]]] <- NA_real_
  nonfinite <- successor_env$successor_recovery_gates(raw, expected_reps = 10L)
  expect_false(nonfinite$quality$all_estimates_finite[
    nonfinite$quality$g == 1024L
  ])
  expect_equal(nonfinite$decision$status, "HOLD_NO_PR1")

  duplicate <- make_recovery_fixture()
  duplicate$seed[[2L]] <- duplicate$seed[[1L]]
  duplicate$replicate[[2L]] <- duplicate$replicate[[1L]]
  expect_error(
    successor_env$successor_recovery_gates(duplicate, expected_reps = 10L),
    "attempt keys"
  )
})

test_that("corrected-refit batch specification is frozen", {
  spec <- diagnostic_env$diagnostic_profile_spec(3L)
  expect_equal(spec$n, c(8192L, 8192L))
  expect_equal(spec$mc_seed, c(2026073950L, 2026074950L))
  expect_equal(spec$batch, c("A", "B"))
})

test_that("D1 jointly optimizes all corrected fixed parameters", {
  start <- c(
    beta_mu = 0,
    beta_mu = 0,
    beta_sigma = 0,
    beta_sigma = 0,
    log_sd_phylo = -1.2
  )
  target <- c(0.1, -0.2, 0.3, -0.4, -1.0)
  fake_env <- new.env(parent = emptyenv())
  fake_env$last.par <- start
  fake_env$par0_seen <- list()
  fake_env$lfixed <- function() rep(TRUE, length(start))
  fake_env$MC <- function(
    par,
    par0,
    n,
    seed,
    antithetic,
    keep = FALSE,
    order = 0
  ) {
    fake_env$par0_seen[[length(fake_env$par0_seen) + 1L]] <- par0
    if (order == 1L) {
      return(2 * (par - target))
    }
    value <- sum((par - target)^2)
    if (keep) {
      attr(value, "nlratio") <- rep(0, 2L * n)
    }
    value
  }
  fake_obj <- list(
    env = fake_env,
    fn = function(parameter) {
      fake_env$last.par <- parameter
      sum((parameter - target)^2)
    }
  )
  fake_fit <- list(obj = fake_obj, opt = list(par = start))
  fake_base <- list(with_repair_rng = function(code) force(code))
  spec <- data.frame(batch = "A", n = 1024L, mc_seed = 1L)

  observed <- diagnostic_env$corrected_refit_batch(
    fake_fit,
    spec,
    fake_base
  )

  corrected_columns <- setdiff(
    grep("^corrected_", names(observed), value = TRUE),
    "corrected_nll"
  )
  expect_equal(
    as.numeric(observed[1L, corrected_columns]),
    target,
    tolerance = 1e-5
  )
  expect_equal(observed$optimizer_convergence, 0L)
  expect_lte(observed$max_abs_score, 1e-5)
  expect_true(length(fake_env$par0_seen) > 2L)
  expect_true(all(vapply(
    fake_env$par0_seen,
    identical,
    logical(1),
    start
  )))
})

test_that("frozen-proposal corrected score matches objective differences", {
  start <- c(beta_mu = 0, log_sd_phylo = -1.2)
  target <- c(0.2, -0.9)
  fake_env <- new.env(parent = emptyenv())
  fake_env$last.par <- start
  fake_env$lfixed <- function() rep(TRUE, length(start))
  fake_env$MC <- function(
    par,
    par0,
    n,
    seed,
    antithetic,
    keep = FALSE,
    order = 0
  ) {
    expect_identical(par0, start)
    if (order == 1L) {
      return(2 * (par - target))
    }
    value <- sum((par - target)^2)
    if (keep) {
      attr(value, "nlratio") <- rep(0, 2L * n)
    }
    value
  }
  fake_fit <- list(
    obj = list(env = fake_env),
    opt = list(par = start)
  )
  fake_base <- list(with_repair_rng = function(code) force(code))
  spec <- data.frame(batch = "A", n = 1024L, mc_seed = 1L)
  evaluate <- function(parameter) {
    diagnostic_env$corrected_evaluation(
      fake_fit,
      parameter,
      start,
      spec,
      fake_base
    )
  }
  at <- c(beta_mu = 0.1, log_sd_phylo = -1.0)
  epsilon <- 1e-6
  finite_difference <- vapply(
    seq_along(at),
    function(i) {
      upper <- lower <- at
      upper[[i]] <- upper[[i]] + epsilon
      lower[[i]] <- lower[[i]] - epsilon
      (evaluate(upper)$value - evaluate(lower)$value) / (2 * epsilon)
    },
    numeric(1)
  )

  expect_equal(evaluate(at)$score, finite_difference, tolerance = 1e-6)
})

make_profile_summary <- function(delta = 0.02, corrected_error = -0.20) {
  data.frame(
    replicate = 1:24,
    profile_pass = TRUE,
    delta = rep(delta, 24L),
    corrected_error = rep(corrected_error, 24L)
  )
}

test_that("D1 mechanism decision is fail-closed and uncertainty-based", {
  residual <- diagnostic_env$diagnostic_profile_decision(make_profile_summary())
  expect_equal(residual$status, "LAPLACE_SHIFT_EQUIVALENT_RESIDUAL_BIAS")
  expect_false(residual$estimator_arc_required)

  material <- diagnostic_env$diagnostic_profile_decision(
    make_profile_summary(delta = 0.15, corrected_error = -0.05)
  )
  expect_equal(material$status, "LAPLACE_MATERIALLY_IMPLICATED")
  expect_true(material$estimator_arc_required)

  wide <- make_profile_summary()
  wide$delta <- rep(c(-0.20, 0.20), 12L)
  expect_equal(
    diagnostic_env$diagnostic_profile_decision(wide)$status,
    "MIXED_OR_INCONCLUSIVE"
  )

  incomplete <- make_profile_summary()
  incomplete$profile_pass[[1L]] <- FALSE
  expect_equal(
    diagnostic_env$diagnostic_profile_decision(incomplete)$status,
    "INCONCLUSIVE"
  )
})

test_that("preflight host and resumable output guards fail closed", {
  expect_true(successor_env$allowed_compute_host("totoro.biology.ualberta.ca"))
  expect_false(successor_env$allowed_compute_host(
    "nibi",
    slurm_job_id = "",
    cluster = "nibi"
  ))
  expect_true(successor_env$allowed_compute_host(
    "cn12345",
    slurm_job_id = "123",
    cluster = "nibi"
  ))
  expect_false(successor_env$allowed_compute_host("local-mac"))

  out <- tempfile("successor-resume-")
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  grid <- data.frame(cell_id = "x", replicate = 1L, seed = 2L)
  audit <- data.frame(check = "x", observed = 1L, expected = 1L, pass = TRUE)
  preflight <- data.frame(
    check = "x",
    observed = "a",
    expected = "a",
    pass = TRUE
  )
  expect_true(dir.exists(dirname(successor_env$prepare_resumable_output(
    out,
    grid,
    audit,
    preflight
  ))))
  expect_silent(successor_env$prepare_resumable_output(
    out,
    grid,
    audit,
    preflight,
    resume = TRUE
  ))
  altered <- preflight
  altered$observed <- "b"
  expect_error(
    successor_env$prepare_resumable_output(
      out,
      grid,
      audit,
      altered,
      resume = TRUE
    ),
    "does not match"
  )
})

test_that("pair-level importance diagnostics reject malformed shapes", {
  malformed <- diagnostic_env$importance_weight_stats(c(0, 0, 0))
  nonfinite <- diagnostic_env$importance_weight_stats(c(0, Inf))
  expect_true(all(is.na(malformed)))
  expect_true(all(is.na(nonfinite)))
})
