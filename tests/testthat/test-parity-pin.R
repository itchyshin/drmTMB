# The pin check (tools/parity-pin.R, S1b, 2026-09-24): a DRModels checkout
# whose HEAD is not the programme pin must be refused, naming both shas. No
# DRModels clone is needed to test this -- a throwaway one-commit git repo
# stands in for "a checkout", and the expected sha is injected as a plain
# argument so `pp_verify_pin()` never has to read source-pins.json here.

pp_test_tool_path <- function() {
  # Only reachable from a source checkout (tools/ is .Rbuildignore'd), the
  # same guard test-parity-matrix.R and test-parity-honesty.R use.
  path <- testthat::test_path("..", "..", "tools", "parity-pin.R")
  if (file.exists(path)) normalizePath(path) else ""
}

pp_test_source_tool <- function(path) {
  env <- new.env(parent = globalenv())
  sys.source(path, envir = env)
  env
}

# A throwaway git repo with exactly one commit, so its HEAD sha is known and
# nothing about it depends on this repo or a DRModels clone existing.
pp_test_one_commit_repo <- function() {
  dir <- tempfile("parity-pin-test-")
  dir.create(dir)
  run <- function(...) {
    res <- system2("git", c("-C", shQuote(dir), ...), stdout = TRUE, stderr = TRUE)
    status <- attr(res, "status")
    if (!is.null(status) && status != 0L) {
      stop("git ", paste(c(...), collapse = " "), " failed: ", paste(res, collapse = "\n"), call. = FALSE)
    }
    res
  }
  run("init", "--quiet")
  run("config", "user.email", "pin-test@example.com")
  run("config", "user.name", "pin-test")
  writeLines("x", file.path(dir, "f.txt"))
  run("add", "f.txt")
  # A one-word message: system2() pastes args with a bare space (no
  # auto-quoting), so a message containing a space would be split into
  # extra positional pathspec arguments by the shell.
  run("commit", "--quiet", "-m", "onecommit")
  dir
}

test_that("pp_verify_pin refuses a checkout whose HEAD is not the expected pin", {
  tool <- pp_test_tool_path()
  skip_if(!nzchar(tool), "tools/parity-pin.R is not reachable (installed package)")
  env <- pp_test_source_tool(tool)
  repo <- pp_test_one_commit_repo()
  on.exit(unlink(repo, recursive = TRUE, force = TRUE), add = TRUE)

  wrong_pin <- paste(rep("0", 40L), collapse = "")
  actual_head <- env$pp_git_rev_parse(repo)
  expect_false(identical(actual_head, wrong_pin))

  err <- tryCatch({
    env$pp_verify_pin(repo, expected = wrong_pin)
    NULL
  }, error = function(e) conditionMessage(e))
  expect_true(!is.null(err))
  # The refusal names BOTH shas: the checkout's actual HEAD and the pin it
  # was checked against.
  expect_true(grepl(actual_head, err, fixed = TRUE))
  expect_true(grepl(wrong_pin, err, fixed = TRUE))
})

test_that("pp_verify_pin accepts a checkout whose HEAD equals the expected pin", {
  tool <- pp_test_tool_path()
  skip_if(!nzchar(tool), "tools/parity-pin.R is not reachable (installed package)")
  env <- pp_test_source_tool(tool)
  repo <- pp_test_one_commit_repo()
  on.exit(unlink(repo, recursive = TRUE, force = TRUE), add = TRUE)

  actual_head <- env$pp_git_rev_parse(repo)
  result <- env$pp_verify_pin(repo, expected = actual_head)
  expect_identical(result, actual_head)
})

cat("PARITY_PIN_CONTRACT_PASS\n")
