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
