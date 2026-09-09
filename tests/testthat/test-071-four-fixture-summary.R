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
