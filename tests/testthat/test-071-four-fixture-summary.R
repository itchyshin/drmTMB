test_that("four-fixture summary fails closed when a fixture receipt is absent", {
  tool <- testthat::test_path("..", "..", "docs", "dev-log", "evidence",
                              "julia-r-parity", "071-ordinary-laplace",
                              "reconcile-four-fixture-summary.R")
  expect_true(file.exists(tool))
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)
  expect_true(is.function(env$r071_reconcile_all))
  empty <- tempfile("071-empty-receipt-")
  dir.create(empty)
  expect_error(
    env$r071_reconcile_all(root = normalizePath(testthat::test_path("..", "..")),
                            drmjl_path = normalizePath(testthat::test_path("..", "..")),
                            out = empty),
    "missing binomial_ri profile receipt"
  )
})

test_that("the scoreboard has a distinct ordinary-Laplace classification path", {
  tool <- testthat::test_path("..", "..", "tools", "write-parity-scoreboard.R")
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)
  expect_true(is.function(env$sb_ordinary_laplace_summary))
})

test_that("ordinary-Laplace summary accepts a documentation-only successor commit", {
  root <- normalizePath(testthat::test_path("..", ".."))
  tool <- file.path(root, "tools", "write-parity-scoreboard.R")
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)
  summary <- utils::read.delim(file.path(
    root, "docs", "dev-log", "evidence", "julia-r-parity",
    "071-ordinary-laplace", "reconciled-summary.tsv"
  ), stringsAsFactors = FALSE, check.names = FALSE)
  current_sha <- system2("git", c("-C", root, "rev-parse", "HEAD"), stdout = TRUE)
  tab <- tryCatch(env$sb_ordinary_laplace_summary(
    root = root,
    ctx = list(pin = summary$drm_jl_commit[[1L]]),
    drmtmb_sha = current_sha
  ), error = identity)
  expect_false(inherits(tab, "error"))
  if (!inherits(tab, "error")) {
    expect_equal(tab$capability_id, c(
      "ordinary_ri_scalar_laplace",
      "ordinary_nb2_coupled_laplace"
    ))
  }
})

test_that("ordinary-Laplace source-drift guard rejects semantic input changes", {
  tool <- testthat::test_path("..", "..", "tools", "write-parity-scoreboard.R")
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)
  root <- tempfile("071-source-drift-")
  dir.create(root)
  dir.create(file.path(root, "R"))
  dir.create(file.path(root, "docs"))
  dir.create(file.path(root, "tools"))
  run_git <- function(...) system2("git", c("-C", root, ...), stdout = TRUE)
  run_git("init", "-q")
  run_git("config", "user.email", "test@example.invalid")
  run_git("config", "user.name", "drmTMB test")
  writeLines("base", file.path(root, "README.md"))
  run_git("add", ".")
  run_git("commit", "-qm", "base")
  base <- run_git("rev-parse", "HEAD")
  writeLines("documentation-only", file.path(root, "docs", "note.md"))
  run_git("add", ".")
  run_git("commit", "-qm", "docs")
  docs_only <- run_git("rev-parse", "HEAD")
  writeLines("presentation-only", file.path(root, "tools", "write-parity-scoreboard.R"))
  run_git("add", ".")
  run_git("commit", "-qm", "scoreboard-compiler")
  scoreboard_change <- run_git("rev-parse", "HEAD")
  writeLines("semantic-input", file.path(root, "R", "model.R"))
  run_git("add", ".")
  run_git("commit", "-qm", "source")
  source_change <- run_git("rev-parse", "HEAD")
  expect_false(env$sb_ordinary_laplace_source_drift(root, base, docs_only))
  expect_false(env$sb_ordinary_laplace_source_drift(root, base, scoreboard_change))
  expect_true(env$sb_ordinary_laplace_source_drift(root, base, source_change))
})

test_that("scoreboard renders ordinary-Laplace source provenance separately", {
  drmjl <- Sys.getenv("DRM_JL_PATH", unset = "")
  skip_if(!nzchar(drmjl) || !dir.exists(drmjl), "DRM_JL_PATH is not set to a DRM.jl clone")
  root <- normalizePath(testthat::test_path("..", ".."))
  tool <- file.path(root, "tools", "write-parity-scoreboard.R")
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)
  out <- tempfile(fileext = ".md")
  suppressMessages(env$sb_write(root, drmjl, out))
  rendered <- readLines(out, warn = FALSE)
  expect_true(any(grepl("ordinary-Laplace reconciliation source pin", rendered, fixed = TRUE)))
})

test_that("S7 manifest freezes all four 500-seed fixture denominators", {
  tool <- testthat::test_path("..", "..", "docs", "dev-log", "evidence",
                              "julia-r-parity", "071-ordinary-laplace",
                              "prepare-s7-campaign-manifest.R")
  expect_true(file.exists(tool))
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)
  manifest <- env$r071_s7_manifest()
  expect_identical(nrow(manifest), 2000L)
  expect_identical(manifest$array_index, seq_len(2000L))
  expect_identical(manifest$logical_task_id, seq_len(2000L))
  expect_identical(names(table(manifest$fixture)), c(
    "binomial_ri", "nb2_coupled", "nb2_ri", "poisson_ri"
  ))
  expect_true(all(as.integer(table(manifest$fixture)) == 500L))
  expect_true(all(vapply(split(manifest$dgp_seed, manifest$fixture),
                         function(x) length(unique(x)) == 500L, logical(1))))
  fixture_info <- env$r071_s7_fixture_table()
  for (i in seq_len(nrow(fixture_info))) {
    rows <- manifest[manifest$fixture == fixture_info$fixture[[i]], , drop = FALSE]
    expect_identical(rows$fixture_index, rep.int(fixture_info$fixture_index[[i]], 500L))
    expect_identical(rows$dgp_seed, fixture_info$seed_base[[i]] + seq_len(500L))
  }
  expect_identical(env$r071_s7_task(manifest, 1L), manifest[1L, , drop = FALSE])
  expect_error(env$r071_s7_task(manifest, 2001L), "outside the frozen 1..2000 array")
})

test_that("S7 profile plan freezes all target truths on their profile scales", {
  tool <- testthat::test_path("..", "..", "docs", "dev-log", "evidence",
                              "julia-r-parity", "071-ordinary-laplace",
                              "prepare-s7-campaign-manifest.R")
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)
  plan <- env$r071_s7_profile_plan()
  expect_identical(nrow(plan), 34L)
  expect_identical(as.integer(table(plan$fixture)), c(6L, 14L, 8L, 6L))
  expect_identical(anyDuplicated(plan[c("fixture", "engine", "parm")]), 0L)
  expect_true(all(is.finite(plan$truth)))
  coupled <- plan[plan$fixture == "nb2_coupled" & plan$engine == "tmb", , drop = FALSE]
  expect_identical(coupled$parm, c(
    "fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)",
    "fixef:sigma:z", "cholesky:recov:L11", "cholesky:recov:L22",
    "cholesky:recov:L21"
  ))
  expect_equal(coupled$truth, c(0.2, 0.35, 0.15, -0.1,
                                 log(0.45), log(0.125), -0.10125))
})

test_that("S7 campaign fixture factory is deterministic and preserves scalar-RI shapes", {
  tool <- testthat::test_path("..", "..", "docs", "dev-log", "evidence",
                              "julia-r-parity", "071-ordinary-laplace",
                              "s7-campaign-fixture.R")
  expect_true(file.exists(tool))
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)
  manifest_tool <- testthat::test_path("..", "..", "docs", "dev-log", "evidence",
                                       "julia-r-parity", "071-ordinary-laplace",
                                       "prepare-s7-campaign-manifest.R")
  manifest_env <- new.env(parent = globalenv())
  sys.source(manifest_tool, envir = manifest_env)
  profile_plan <- manifest_env$r071_s7_profile_plan()
  for (fixture in manifest_env$r071_s7_fixture_table()$fixture) {
    one <- env$r071_s7_make_fixture(fixture, 71011001L)
    again <- env$r071_s7_make_fixture(fixture, 71011001L)
    expect_identical(one$data, again$data, info = fixture)
    expect_identical(one$formula, again$formula, info = fixture)
    expected_truths <- profile_plan[profile_plan$fixture == fixture & profile_plan$engine == "tmb",
                                   c("parm", "target_class", "truth"), drop = FALSE]
    row.names(expected_truths) <- NULL
    expect_identical(one$target_truths, expected_truths, info = fixture)
  }
  expect_false(identical(
    env$r071_s7_make_fixture("poisson_ri", 71011001L)$data,
    env$r071_s7_make_fixture("poisson_ri", 71011002L)$data
  ))
})

test_that("S7 attempt receipts are keyed, terminal, and truth-matched", {
  tool <- testthat::test_path("..", "..", "docs", "dev-log", "evidence",
                              "julia-r-parity", "071-ordinary-laplace",
                              "s7-attempt-contract.R")
  expect_true(file.exists(tool))
  env <- new.env(parent = globalenv())
  manifest_tool <- testthat::test_path("..", "..", "docs", "dev-log", "evidence",
                                       "julia-r-parity", "071-ordinary-laplace",
                                       "prepare-s7-campaign-manifest.R")
  sys.source(manifest_tool, envir = env)
  sys.source(tool, envir = env)
  row <- data.frame(
    logical_task_id = 1501L, fixture = "nb2_coupled", dgp_seed = 71014001L,
    engine = "julia", parm = "cholesky:recov:L22", truth = log(0.125),
    fit_status = "returned", profile_status = "nonfinite_endpoint",
    stringsAsFactors = FALSE
  )
  expect_identical(env$r071_s7_attempt_key(row),
                   "1501-nb2_coupled-71014001-julia-cholesky_recov_L22")
  expect_silent(env$r071_s7_validate_attempt(row))
  row$truth <- 0.125
  expect_error(env$r071_s7_validate_attempt(row), "truth does not match frozen profile plan")
  row$truth <- log(0.125)
  row$profile_status <- "started"
  expect_error(env$r071_s7_validate_attempt(row), "terminal")
})

test_that("S7 reconciliation requires all 17000 planned terminal attempts", {
  base <- testthat::test_path("..", "..", "docs", "dev-log", "evidence",
                              "julia-r-parity", "071-ordinary-laplace")
  env <- new.env(parent = globalenv())
  sys.source(file.path(base, "prepare-s7-campaign-manifest.R"), envir = env)
  sys.source(file.path(base, "s7-attempt-contract.R"), envir = env)
  expected <- env$r071_s7_expected_attempts(env$r071_s7_manifest(), env$r071_s7_profile_plan())
  expect_identical(nrow(expected), 17000L)
  attempts <- transform(expected, fit_status = "returned", profile_status = "profile")
  reconciled <- env$r071_s7_reconcile_attempts(env$r071_s7_manifest(), env$r071_s7_profile_plan(), attempts)
  expect_identical(reconciled$attempt_count, 17000L)
  expect_identical(reconciled$profile_count, 17000L)
  expect_error(
    env$r071_s7_reconcile_attempts(env$r071_s7_manifest(), env$r071_s7_profile_plan(), attempts[-1L, ]),
    "missing or duplicate"
  )
})

test_that("S7 worker specification resolves a task against the frozen plan", {
  base <- testthat::test_path("..", "..", "docs", "dev-log", "evidence",
                              "julia-r-parity", "071-ordinary-laplace")
  env <- new.env(parent = globalenv())
  sys.source(file.path(base, "prepare-s7-campaign-manifest.R"), envir = env)
  sys.source(file.path(base, "s7-attempt-contract.R"), envir = env)
  sys.source(file.path(base, "s7-run-attempt.R"), envir = env)
  spec <- env$r071_s7_worker_spec(
    manifest = env$r071_s7_manifest(), profile_plan = env$r071_s7_profile_plan(),
    task = 1501L, engine = "julia", parm = "cholesky:recov:L22"
  )
  expect_identical(spec$fixture, "nb2_coupled")
  expect_identical(spec$dgp_seed, 71014001L)
  expect_equal(spec$truth, log(0.125))
  expect_error(
    env$r071_s7_worker_spec(env$r071_s7_manifest(), env$r071_s7_profile_plan(),
                             task = 1L, engine = "tmb", parm = "cholesky:recov:L22"),
    "absent from the frozen profile plan"
  )
})
