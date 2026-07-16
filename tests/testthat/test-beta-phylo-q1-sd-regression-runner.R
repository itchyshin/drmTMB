runner_path <- testthat::test_path(
  "..",
  "..",
  "tools",
  "run-beta-phylo-q1-sd-regression-recovery.R"
)

expect_true(file.exists(runner_path), info = "The frozen PR2 runner must exist")
runner_env <- new.env(parent = globalenv())
sys.source(runner_path, envir = runner_env)

pr2_repo_root <- function() {
  normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
}

make_pr2_recovery_fixture <- function(mode = c("certification", "smoke")) {
  mode <- match.arg(mode)
  raw <- runner_env$pr2_seed_grid(mode)
  raw$convergence <- 0L
  raw$pdHess <- TRUE
  raw$fixed_hessian_condition <- 10
  raw$warning_count <- 0L
  raw$warnings <- ""
  raw$error <- NA_character_
  truth <- c(
    beta_mu_intercept = 0,
    beta_mu_x = 0.35,
    beta_sigma_intercept = log(0.25),
    beta_sigma_x = 0.20,
    alpha_intercept = log(0.30),
    alpha_x = 0.25
  )
  for (parameter in names(truth)) {
    raw[[paste0("truth_", parameter)]] <- truth[[parameter]]
    raw[[paste0("estimate_", parameter)]] <- truth[[parameter]]
  }
  raw
}

test_that("PR2 recovery design freezes the declared 12-cell ladder", {
  cells <- runner_env$pr2_cells()
  certification <- runner_env$pr2_seed_grid("certification")
  smoke <- runner_env$pr2_seed_grid("smoke")
  one_fit <- runner_env$pr2_seed_grid("one_fit")

  expect_equal(nrow(cells), 12L)
  expect_equal(unique(cells$predictor_design), c("distinct", "shared"))
  expect_equal(as.integer(table(cells$g)), c(4L, 4L, 4L))
  expect_equal(as.integer(table(cells$m)), c(6L, 6L))
  expect_equal(nrow(certification), 4800L)
  expect_true(all(table(certification$cell_id) == 400L))
  expect_equal(nrow(smoke), 12L)
  expect_equal(nrow(one_fit), 1L)
  expect_equal(length(unique(certification$seed)), 4800L)
  expect_length(intersect(certification$seed, smoke$seed), 0L)
  expect_length(intersect(certification$seed, one_fit$seed), 0L)
  expect_length(intersect(smoke$seed, one_fit$seed), 0L)
})

test_that("PR2 seeds are authenticated against every tracked PR1 design", {
  repo_root <- pr2_repo_root()
  prior <- runner_env$pr2_prior_design_paths(repo_root)
  audit <- runner_env$pr2_seed_audit(
    runner_env$pr2_seed_grid("certification"),
    repo_root,
    "certification"
  )

  expect_gt(length(prior), 0L)
  expect_true(all(grepl("beta-phylo-q1-pr1", prior, fixed = TRUE)))
  expect_true(all(audit$pass))
  expect_true(all(audit$observed[grepl("^overlap_", audit$check)] == 0L))

  bad <- runner_env$pr2_seed_grid("certification")
  prior_seed <- utils::read.delim(prior[[1L]], stringsAsFactors = FALSE)$seed[[1L]]
  bad$seed[[1L]] <- prior_seed
  expect_error(
    runner_env$pr2_seed_audit(bad, repo_root, "certification"),
    "overlap_pr1"
  )

  bad$seed[[1L]] <- NA_integer_
  expect_error(
    runner_env$pr2_seed_audit(bad, repo_root, "certification"),
    "finite integers"
  )
})

test_that("PR2 RNG wrapper restores both kind and caller state", {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_seed <- if (had_seed) .Random.seed else NULL
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  suppressWarnings(RNGkind("Mersenne-Twister", "Box-Muller", "Rounding"))
  set.seed(99)
  caller_kind <- RNGkind()
  caller_seed <- .Random.seed

  first <- runner_env$with_pr2_rng(123L, stats::rnorm(8L))
  second <- runner_env$with_pr2_rng(123L, stats::rnorm(8L))

  expect_equal(first, second)
  expect_equal(RNGkind(), caller_kind)
  expect_equal(.Random.seed, caller_seed)
  expect_equal(
    runner_env$pr2_rng_kind(),
    c(kind = "L'Ecuyer-CMRG", normal.kind = "Inversion", sample.kind = "Rejection")
  )
})

test_that("PR2 DGP is deterministic and predictors are species-level", {
  distinct <- runner_env$beta_phylo_sd_regression_dgp(8L, 4L, "distinct", 123L)
  repeated <- runner_env$beta_phylo_sd_regression_dgp(8L, 4L, "distinct", 123L)
  shared <- runner_env$beta_phylo_sd_regression_dgp(8L, 2L, "shared", 124L)

  expect_equal(distinct$tree$edge, repeated$tree$edge)
  expect_equal(distinct$tree$edge.length, repeated$tree$edge.length)
  expect_equal(distinct$data, repeated$data)
  expect_true(all(distinct$data$y > 0 & distinct$data$y < 1))
  for (variable in c("x_mu", "x_sigma", "x_tau")) {
    expect_true(all(vapply(
      split(distinct$data[[variable]], distinct$data$spp_id),
      function(x) length(unique(x)) == 1L,
      logical(1L)
    )))
  }
  expect_false(isTRUE(all.equal(distinct$data$x_mu, distinct$data$x_sigma)))
  expect_equal(shared$data$x_mu, shared$data$x_sigma)
  expect_equal(shared$data$x_mu, shared$data$x_tau)
})

test_that("PR2 all-attempt gates pass only both exact g1024 m4 arms", {
  raw <- make_pr2_recovery_fixture("certification")
  passing <- runner_env$pr2_recovery_gates(
    raw,
    expected_reps = 400L,
    certification = TRUE
  )

  expect_equal(passing$decision$status, "PASS_EXACT_TWO_G1024_M4")
  expect_true(passing$decision$distinct_g1024_m4)
  expect_true(passing$decision$shared_g1024_m4)
  expect_true(all(passing$quality$quality_pass))
  expect_true(all(passing$summary$parameter_pass))

  held <- raw
  target <- held$predictor_design == "shared" & held$g == 1024L & held$m == 4L
  held$estimate_alpha_x[target] <- held$truth_alpha_x[target] + 0.20
  decision <- runner_env$pr2_recovery_gates(
    held,
    expected_reps = 400L,
    certification = TRUE
  )
  expect_equal(decision$decision$status, "HOLD_NO_PR2_PROMOTION")
  expect_true(decision$decision$distinct_g1024_m4)
  expect_false(decision$decision$shared_g1024_m4)
})

test_that("PR2 gates retain every attempt and fail closed on drift", {
  raw <- make_pr2_recovery_fixture("certification")
  missing <- raw[-1L, , drop = FALSE]
  duplicate <- raw
  duplicate[2L, c("cell_id", "replicate", "seed")] <-
    duplicate[1L, c("cell_id", "replicate", "seed")]
  reordered <- raw[c(2L, 1L, 3:nrow(raw)), , drop = FALSE]

  expect_error(
    runner_env$pr2_recovery_gates(missing, 400L, TRUE),
    "complete frozen design"
  )
  expect_error(
    runner_env$pr2_recovery_gates(duplicate, 400L, TRUE),
    "complete frozen design"
  )
  expect_error(
    runner_env$pr2_recovery_gates(reordered, 400L, TRUE),
    "complete frozen design"
  )
})

test_that("PR2 smoke cannot promote and Hessian summaries fail closed", {
  raw <- make_pr2_recovery_fixture("smoke")
  raw$fixed_hessian_condition <- NA_real_
  gates <- runner_env$pr2_recovery_gates(raw, 1L, FALSE)

  expect_equal(gates$decision$status, "SMOKE_ONLY_NO_PROMOTION")
  expect_false(gates$decision$distinct_g1024_m4)
  expect_false(gates$decision$shared_g1024_m4)
  expect_true(all(is.na(gates$quality$hessian_condition_median)))
  expect_true(all(is.na(gates$quality$hessian_condition_q95)))
  expect_true(is.na(runner_env$pr2_finite_summary(NA_real_, stats::median)))
})

test_that("frozen PR2 design matches the generated grid and pinned hash", {
  repo_root <- pr2_repo_root()
  path <- runner_env$pr2_design_path(repo_root)
  expect_true(file.exists(path))

  observed <- utils::read.delim(path, stringsAsFactors = FALSE)
  expect_identical(observed, runner_env$pr2_seed_grid("certification"))
  expect_equal(
    runner_env$pr2_sha256(path),
    runner_env$pr2_frozen_design_sha256()
  )
})

test_that("frozen PR1 manifest authenticates the exact tracked design set", {
  repo_root <- pr2_repo_root()
  manifest_path <- runner_env$pr2_prior_manifest_path(repo_root)
  paths <- runner_env$pr2_prior_design_paths(repo_root)

  expect_equal(length(paths), 11L)
  expect_equal(
    runner_env$pr2_sha256(manifest_path),
    runner_env$pr2_frozen_prior_manifest_sha256()
  )
  expect_equal(
    runner_env$pr2_sha256(runner_env$pr2_seed_audit_path(repo_root)),
    runner_env$pr2_frozen_seed_audit_sha256()
  )
})

make_pr2_identity <- function(dll = paste(rep("d", 64L), collapse = "")) {
  values <- c(
    source_git_head = paste(rep("a", 40L), collapse = ""),
    source_git_tree = paste(rep("b", 40L), collapse = ""),
    runner_sha256 = paste(rep("c", 64L), collapse = ""),
    design_sha256 = paste(rep("e", 64L), collapse = ""),
    prior_manifest_sha256 = paste(rep("f", 64L), collapse = ""),
    tracked_seed_audit_sha256 = paste0("a", paste(rep("1", 63L), collapse = "")),
    dll_sha256 = dll
  )
  as.data.frame(as.list(values), stringsAsFactors = FALSE)
}

make_pr2_shard_fixture <- function(identity = make_pr2_identity()) {
  row <- make_pr2_recovery_fixture("smoke")[1L, , drop = FALSE]
  row$elapsed <- 1
  row$fit_success <- TRUE
  row$max_gradient <- 0.001
  row$min_tau <- 0.2
  row$max_tau <- 0.4
  row <- cbind(row, identity)
  row[runner_env$pr2_attempt_columns()]
}

test_that("sealed shards reject estimate, schema, key, and identity tampering", {
  identity <- make_pr2_identity()
  value <- make_pr2_shard_fixture(identity)
  key <- runner_env$pr2_seed_grid("smoke")[1L, , drop = FALSE]
  out <- tempfile("pr2-shard-")
  on.exit(unlink(c(out, runner_env$pr2_shard_seal_path(out))), add = TRUE)

  expect_equal(
    runner_env$write_pr2_shard(value, out, key, identity),
    value
  )
  altered <- value
  altered$estimate_alpha_x <- altered$estimate_alpha_x + 1
  runner_env$write_pr2_tsv(altered, out)
  expect_error(
    runner_env$validate_pr2_shard(out, key, identity),
    "hash authentication"
  )

  runner_env$write_pr2_shard(value, out, key, identity)
  bad_identity <- identity
  bad_identity$dll_sha256 <- paste(rep("2", 64L), collapse = "")
  expect_error(
    runner_env$validate_pr2_shard(out, key, bad_identity),
    "source identity"
  )
})

test_that("exclusive output locks expose their owner and reject a second runner", {
  out <- tempfile("pr2-lock-")
  first <- runner_env$acquire_pr2_lock(out)
  on.exit(runner_env$release_pr2_lock(first), add = TRUE)

  expect_true(file.exists(file.path(first, "owner.tsv")))
  expect_error(runner_env$acquire_pr2_lock(out), "already exists")
  expect_true(runner_env$release_pr2_lock(first))
  second <- runner_env$acquire_pr2_lock(out)
  expect_true(runner_env$release_pr2_lock(second))
})

write_authenticated_pr2_fixture <- function(out, identity, mode) {
  dir.create(out, recursive = TRUE)
  attempts <- if (mode == "smoke") 12L else 1L
  provenance <- cbind(
    data.frame(status = "COMPLETE", mode = mode, attempts = attempts),
    identity
  )
  runner_env$write_pr2_tsv(provenance, file.path(out, "run-provenance.tsv"))
  if (mode == "one_fit") {
    raw <- make_pr2_shard_fixture(identity)
  } else {
    raw <- make_pr2_recovery_fixture("smoke")
    gates <- runner_env$pr2_recovery_gates(raw, 1L, FALSE)
    runner_env$write_pr2_tsv(
      gates$quality,
      file.path(out, "quality-gates.tsv")
    )
    runner_env$write_pr2_tsv(
      gates$decision,
      file.path(out, "promotion-decision.tsv")
    )
  }
  runner_env$write_pr2_tsv(raw, file.path(out, "raw-attempts.tsv"))
  runner_env$write_pr2_output_manifest(out)
  invisible(provenance)
}

test_that("output manifests authenticate exact files and reject mutation", {
  out <- tempfile("pr2-output-")
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  identity <- make_pr2_identity()
  expected <- write_authenticated_pr2_fixture(out, identity, "one_fit")

  observed <- runner_env$authenticate_pr2_output(out)
  expect_true(runner_env$pr2_same_source(observed, expected, include_dll = TRUE))
  expect_equal(observed$status, "COMPLETE")
  write("tamper", file.path(out, "raw-attempts.tsv"), append = TRUE)
  expect_error(
    runner_env$authenticate_pr2_output(out),
    "hash or size"
  )
})

test_that("smoke and certification require authenticated same-source stages", {
  root <- tempfile("pr2-stage-")
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  one_fit_dir <- file.path(root, "one-fit")
  smoke_dir <- file.path(root, "smoke")
  identity <- make_pr2_identity()
  write_authenticated_pr2_fixture(one_fit_dir, identity, "one_fit")
  write_authenticated_pr2_fixture(smoke_dir, identity, "smoke")
  context <- list(repo_root = root)

  expect_invisible(runner_env$authorize_pr2_stage(
    list(mode = "smoke", one_fit = one_fit_dir),
    context,
    identity
  ))
  expect_invisible(runner_env$authorize_pr2_stage(
    list(mode = "certification", one_fit = one_fit_dir, smoke = smoke_dir),
    context,
    identity
  ))

  changed_dll <- make_pr2_identity(paste(rep("9", 64L), collapse = ""))
  expect_error(
    runner_env$authorize_pr2_stage(
      list(mode = "certification", one_fit = one_fit_dir, smoke = smoke_dir),
      context,
      changed_dll
    ),
    "compiled DLL"
  )
})

test_that("any retained warning is visible and holds promotion", {
  raw <- make_pr2_recovery_fixture("certification")
  target <- raw$predictor_design == "shared" & raw$g == 1024L & raw$m == 4L
  first <- which(target)[[1L]]
  raw$warning_count[[first]] <- 1L
  raw$warnings[[first]] <- "review this warning"
  gates <- runner_env$pr2_recovery_gates(raw, 400L, TRUE)
  row <- gates$quality$predictor_design == "shared" &
    gates$quality$g == 1024L & gates$quality$m == 4L

  expect_equal(gates$quality$warning_attempts[row], 1L)
  expect_equal(gates$quality$warning_count_total[row], 1L)
  expect_false(gates$quality$quality_pass[row])
  expect_equal(gates$decision$status, "HOLD_NO_PR2_PROMOTION")
})

test_that("all supported BLAS thread controls must be pinned to one", {
  variables <- runner_env$pr2_thread_variables()
  environment <- stats::setNames(rep("1", length(variables)), variables)
  passing <- runner_env$pr2_thread_guard(environment)
  environment[["OMP_NUM_THREADS"]] <- ""
  failing <- runner_env$pr2_thread_guard(environment)

  expect_true(all(passing$pass))
  expect_false(failing$pass[failing$variable == "OMP_NUM_THREADS"])
  expect_equal(
    failing$variable[!failing$pass],
    "OMP_NUM_THREADS"
  )
})

test_that("resume preserves original provenance and rejects identity drift", {
  identity <- make_pr2_identity()
  provenance <- cbind(
    data.frame(
      status = "COMPLETE",
      mode = "smoke",
      attempts = "12",
      started_at = "2026-07-16 12:00:00 UTC",
      completed_at = "2026-07-16 12:05:00 UTC",
      host = "totoro"
    ),
    identity
  )
  resumed <- runner_env$resume_pr2_provenance(
    provenance,
    "smoke",
    12L,
    identity
  )

  expect_equal(resumed$status, "PRE_DISPATCH")
  expect_true(is.na(resumed$completed_at))
  expect_equal(resumed$started_at, provenance$started_at)
  expect_equal(resumed$host, provenance$host)

  changed <- identity
  changed$source_git_head <- paste(rep("9", 40L), collapse = "")
  expect_error(
    runner_env$resume_pr2_provenance(provenance, "smoke", 12L, changed),
    "does not authenticate"
  )
})
