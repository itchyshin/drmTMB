# Run one unmodified paired public-method test expression, then append the
# independent references inside that expression to reuse its fitted objects.
# Usage: Rscript run.R --dry-run  OR  Rscript run.R --live
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, args %in% c("--dry-run", "--live"))
repo <- normalizePath(getwd(), mustWork = TRUE)
test_file <- file.path(repo, "tests/testthat/test-julia-binomial-sd.R")
helper_file <- file.path(repo, "tests/testthat/helper-binomial-sd-regression.R")
julia_helper_file <- file.path(repo, "tests/testthat/helper-julia-bridge-path.R")
ref_file <- file.path(repo, "tools/general-sd-regression/bernoulli-q1-evidence/reference.R")
expected_test_sha <- "721658fe990bd3147fd030572320fc7d60bbe78bed4c87f21b928f8d6e60d23f"
expected_helper_sha <- "acd2153d99bc46d4094cbf5d9a1abd05febd00cb9e9e2a3619d3325925df9018"
sha256 <- function(path) {
  result <- suppressWarnings(system2("shasum", c("-a", "256", shQuote(path)),
                                      stdout = TRUE, stderr = TRUE))
  if (length(result) != 1L || !is.null(attr(result, "status"))) {
    stop("SHA-256 failed for ", path)
  }
  strsplit(result, " +")[[1L]][[1L]]
}
stopifnot(identical(sha256(test_file), expected_test_sha))
stopifnot(identical(sha256(helper_file), expected_helper_sha))
stopifnot(file.exists(ref_file), file.exists(julia_helper_file))

test_ast <- parse(test_file, keep.source = FALSE)
matches <- which(vapply(test_ast, function(expr) {
  is.call(expr) && identical(expr[[1L]], as.name("test_that")) &&
    identical(expr[[2L]], "public Julia Bernoulli SD outputs match the fitted target")
}, logical(1L)))
stopifnot(length(matches) == 1L)
target <- test_ast[[matches]]
stopifnot(identical(target[[3L]][[1L]], as.name("{")))
original_body <- target[[3L]]
target[[3L]][[length(target[[3L]]) + 1L]] <-
  quote(source(getOption("drm.q1.reference.file"), local = TRUE))
stopifnot(identical(as.list(target[[3L]])[-length(target[[3L]])],
                    as.list(original_body)))
cat("Q1 selected test SHA256:", sha256(test_file), "\n")
cat("Q1 fixture/Laplace helper SHA256:", sha256(helper_file), "\n")
cat("Q1 original AST statements:", length(original_body) - 1L, "\n")
cat("Q1 appended expression: independent reference source only\n")
if (identical(args, "--dry-run")) quit(save = "no", status = 0L)

stopifnot(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"))
stopifnot(dir.exists(Sys.getenv("DRM_JL_PATH")))
stopifnot(identical(Sys.getenv("OPENBLAS_NUM_THREADS"), "1"),
          identical(Sys.getenv("OMP_NUM_THREADS"), "1"),
          identical(Sys.getenv("JULIA_NUM_THREADS"), "1"))
options(drmTMB.DRModels.jl.path = Sys.getenv("DRM_JL_PATH"),
        drmTMB.DRM.jl.path = Sys.getenv("DRM_JL_PATH"),
        drm.q1.reference.file = ref_file)

library(testthat)
pkgload::load_all(repo, quiet = TRUE, compile = FALSE)
dll <- getLoadedDLLs()[["drmTMB"]]
stopifnot(!is.null(dll), file.exists(dll[["path"]]))
cat("Q1 loaded DLL:", dll[["path"]], "\n")
cat("Q1 loaded DLL SHA256:", sha256(dll[["path"]]), "\n")
source(helper_file, local = .GlobalEnv)
source(julia_helper_file, local = .GlobalEnv)
scratch <- Sys.getenv("Q1_SCRATCH", tempdir())
dir.create(scratch, recursive = TRUE, showWarnings = FALSE)
extracted <- file.path(scratch, "test-bernoulli-q1-extracted.R")
writeLines(paste(deparse(target, width.cutoff = 500L), collapse = "\n"),
           extracted)
cat("Q1 extracted test:", extracted, "\n")
results <- testthat::test_file(extracted, reporter = "summary",
                               stop_on_failure = TRUE, stop_on_warning = FALSE,
                               load_helpers = FALSE, load_package = "none")
all_expectations <- unlist(lapply(results, `[[`, "results"), recursive = FALSE)
skip_count <- sum(vapply(all_expectations, inherits, logical(1L), "expectation_skip"))
failure_count <- sum(vapply(all_expectations, function(x)
  inherits(x, "expectation_failure") || inherits(x, "expectation_error"), logical(1L)))
cat("Q1 live test cases:", length(results), " expectations:", length(all_expectations),
    " skips:", skip_count, " failures:", failure_count, "\n")
stopifnot(length(results) == 1L, skip_count == 0L, failure_count == 0L)
