#!/usr/bin/env Rscript
# Gate orchestration only. The model and its behavioural tests are not implemented
# by this planning packet. Missing tests and missing build receipts fail closed.

temporal_cases <- list(
  G1 = c("marker_fields", "argument_errors", "admission_product"),
  G2 = c("ordering_and_gaps", "duplicates_and_bad_time", "missingness", "lag_design"),
  G3 = c("dynamic_phi", "normalisation", "all_model_defaults", "block_exclusivity", "both_starts_and_selection"),
  G4 = c("dense_marginal_identity", "gradient_two_steps"),
  G5 = c("phi_zero_total_variance", "singleton_prior", "unidentified_split"),
  G6 = c("regular_and_gapped_ou_correspondence", "negative_phi_boundary", "ou_fit_refused"),
  G7 = c("series_sum", "permutations", "gaps_not_ranks", "split_connected_series"),
  G8 = c("sd_phi_report_slots", "nodes_and_latent_states", "dense_conditional_modes", "fitted_mean"),
  G9 = c("fresh_process_simulation", "conditional_simulation", "rng_restore", "supported_points", "refused_entry_points"),
  G10 = c("four_oracle_mutations", "ordinary_regression", "phylo_regression", "spatial_regression", "relmat_regression"),
  G11 = c("timing_and_complete_output", "source_and_dgp_identity", "estimated_runtime_bound"),
  G12 = c("six_fixtures_twelve_attempts", "frozen_dgp_and_seeds", "winner_and_ties", "recovery_thresholds", "all_failures_retained"),
  G13 = c("exported_reader_workflow", "authored_generated_sync", "rendered_article", "scope_and_navigation")
)

validate_results <- function(result, expected) {
  needed <- c("test", "nb", "failed", "error", "skipped", "warning", "passed")
  if (!all(needed %in% names(result)) || !nrow(result)) {
    stop("No complete test-result table; empty execution cannot pass.")
  }
  if (anyDuplicated(result$test) || !setequal(result$test, expected)) {
    stop("Observed case IDs differ from the frozen gate contract.")
  }
  if (anyNA(result[needed]) || any(result$nb < 1L) || any(result$passed < 1L) ||
      any(result$failed != 0L) || any(result$error) || any(result$skipped) ||
      any(result$warning != 0L)) {
    stop("A case is empty, failing, errored, skipped or warning; gate is unmet.")
  }
  invisible(TRUE)
}

self_test <- function() {
  good <- data.frame(test = c("a", "b"), nb = 1L, failed = 0L, error = FALSE,
                     skipped = FALSE, warning = 0L, passed = 1L)
  validate_results(good, c("a", "b"))
  bad <- list(good[FALSE, ], good[1L, ], good[c(1L, 1L), ])
  for (field in c("failed", "error", "skipped", "warning")) {
    value <- good
    value[[field]][1L] <- 1L
    bad[[length(bad) + 1L]] <- value
  }
  for (field in c("nb", "passed")) {
    value <- good
    value[[field]][1L] <- 0L
    bad[[length(bad) + 1L]] <- value
  }
  value <- good
  value$passed[1L] <- NA_integer_
  bad[[length(bad) + 1L]] <- value
  for (value in bad) {
    if (!inherits(try(validate_results(value, c("a", "b")), silent = TRUE), "try-error")) {
      stop("A negative control passed.")
    }
  }
  cat("TEMPORAL_RUNNER_SELFTEST_PASS controls=10 positive=1\n")
}

native_fingerprint <- function() {
  paths <- c("DESCRIPTION", list.files("src", full.names = TRUE, recursive = TRUE))
  paths <- paths[!dir.exists(paths) & !grepl("\\.(o|so|dll|dylib)$", paths)]
  tools::md5sum(sort(paths))
}

evidence_fingerprint <- function() {
  paths <- system2("git", c("ls-files", "--cached", "--others", "--exclude-standard",
    "--", "R", "src", "tests", "inst/validation", "DESCRIPTION", "NAMESPACE",
    "vignettes", "man", "_pkgdown.yml", ".Rbuildignore", "docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy"),
    stdout = TRUE)
  if (!is.null(attr(paths, "status"))) stop("Cannot fingerprint source files.")
  paths <- unique(paths[file.exists(paths) & !dir.exists(paths)])
  tools::md5sum(sort(paths))
}

gate_dependencies <- list(G1 = character(), G2 = character(), G3 = c("G1", "G2"),
  G4 = "G3", G5 = "G3", G6 = "G3", G7 = "G3", G8 = paste0("G", 3:7),
  G9 = "G8", G10 = "G8", G11 = paste0("G", 8:10), G12 = "G11",
  G13 = paste0("G", 8:10), G14 = paste0("G", 1:13))

require_approval <- function() {
  file <- ".unlazy/temporal-ar1/GATES.md"
  if (!file.exists(file)) stop("No G0 ledger; stage the pending scope first.")
  lines <- readLines(file, warn = FALSE)
  gate <- grep("^- \\[x\\] G0:", lines)
  evidence <- grep("^[[:space:]]+EVIDENCE: [^[:space:]]", lines, value = TRUE)
  if (length(gate) != 1L || length(evidence) != 1L ||
      grepl("EVIDENCE: pending[[:space:]]*$", evidence)) {
    stop("G0 approval/ownership is not recorded. No model check or build may run.")
  }
}

require_dependencies <- function(id) {
  require_approval()
  if (!id %in% names(gate_dependencies)) stop("Unknown dependency target.")
  for (dep in gate_dependencies[[id]]) {
    file <- file.path(".unlazy/temporal-ar1/receipts", paste0(dep, ".rds"))
    if (!file.exists(file)) stop("Missing prerequisite receipt: ", dep)
    receipt <- readRDS(file)
    if (!identical(receipt$gate, dep) || !identical(receipt$input_hashes, evidence_fingerprint())) {
      stop("Stale prerequisite source/test/reference fingerprint; reverify ", dep)
    }
    validate_results(receipt$results, paste(dep, temporal_cases[[dep]], sep = ":"))
    if (length(receipt$output_hashes) &&
        !identical(receipt$output_hashes, tools::md5sum(names(receipt$output_hashes)))) {
      stop("Prerequisite output changed; reverify ", dep)
    }
  }
}

check_native_build <- function() {
  file <- ".unlazy/temporal-ar1/native-build.rds"
  if (!file.exists(file)) stop("No native-build receipt; run the reviewed --build command first.")
  stamp <- readRDS(file)
  if (!identical(stamp$source, native_fingerprint()) ||
      !file.exists(stamp$dll) || !identical(stamp$dll_hash, tools::md5sum(stamp$dll))) {
    stop("Native source or DLL changed since the forced build; rebuild before native gates.")
  }
  pkgload::load_all(".", compile = FALSE, helpers = FALSE, quiet = TRUE)
  loaded <- getLoadedDLLs()[["drmTMB"]][["path"]]
  if (!identical(normalizePath(loaded), normalizePath(stamp$dll))) {
    stop("Loaded DLL is not this worktree's recorded build.")
  }
}

main <- function(args) {
  if (identical(args, "--self-test")) return(self_test())
  if (length(args) == 2L && identical(args[[1L]], "--ready")) {
    require_dependencies(args[[2L]])
    cat("TEMPORAL_PREREQUISITES_PASS\n")
    return(invisible(NULL))
  }
  if (length(args) != 1L || !file.exists("DESCRIPTION")) {
    stop("Use from the package root: check-tests.R G1..G14, --build, or --self-test.")
  }
  require_approval()
  dir.create(".unlazy/temporal-ar1/receipts", recursive = TRUE, showWarnings = FALSE)
  if (identical(args, "--build")) {
    pkgbuild::compile_dll(".", force = TRUE, quiet = FALSE)
    dll <- paste0("src/drmTMB", .Platform$dynlib.ext)
    if (!file.exists(dll)) stop("Build returned without the expected DLL.")
    saveRDS(list(source = native_fingerprint(), input_hashes = evidence_fingerprint(), dll = dll,
                 dll_hash = tools::md5sum(dll)), ".unlazy/temporal-ar1/native-build.rds")
    cat("TEMPORAL_NATIVE_BUILD_PASS\n")
    return(invisible(NULL))
  }
  id <- args[[1L]]
  require_dependencies(id)
  if (identical(id, "G14")) {
    if (!"^\\.unlazy$" %in% readLines(".Rbuildignore", warn = FALSE)) {
      stop("Add the explicit .unlazy exclusion to .Rbuildignore before package check.")
    }
    check_native_build()
    inputs <- evidence_fingerprint()
    result <- rcmdcheck::rcmdcheck(path = ".", args = "--no-manual",
                                  error_on = "never", check_dir = ".unlazy/temporal-ar1/package-check")
    if (length(result$errors) || length(result$warnings) || length(result$notes)) {
      stop("Package check contains errors, warnings or notes; review before changing this contract.")
    }
    if (!identical(inputs, evidence_fingerprint())) stop("Source changed during package check.")
    logs <- list.files(".unlazy/temporal-ar1/package-check", recursive = TRUE,
                       full.names = TRUE, pattern = "00check\\.log$")
    if (!length(logs)) stop("Package check returned without a retained 00check.log.")
    build <- readRDS(".unlazy/temporal-ar1/native-build.rds")
    if (!identical(build$dll_hash, tools::md5sum(build$dll))) {
      stop("Worktree DLL changed during package check; rebuild and reverify native gates.")
    }
    saveRDS(list(gate = id, input_hashes = inputs, dll = build$dll,
      dll_hash = build$dll_hash, output_hashes = tools::md5sum(logs),
      source_head = system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
      errors = length(result$errors), warnings = length(result$warnings),
      notes = length(result$notes)), ".unlazy/temporal-ar1/receipts/G14.rds")
    cat("TEMPORAL_G14_PASS\n")
    return(invisible(NULL))
  }
  if (!id %in% names(temporal_cases)) stop("Unknown gate ID.")
  file <- file.path("tests/testthat", paste0("test-temporal-", tolower(id), ".R"))
  if (!file.exists(file)) stop("Required behavioural test file does not exist: ", file)
  if (!id %in% c("G1", "G2", "G6", "G11", "G12", "G13")) check_native_build()
  pure <- id %in% c("G1", "G2", "G6")
  if (pure) {
    if ("drmTMB" %in% names(getLoadedDLLs())) stop("Pure gate has a loaded drmTMB DLL.")
    trace("dyn.load", where = baseenv(), print = FALSE, tracer = quote({
      if (grepl("drmTMB", basename(x), fixed = TRUE)) stop("Pure gate tried to load drmTMB native code.")
    }))
    on.exit(untrace("dyn.load", where = baseenv()), add = TRUE)
  }
  inputs <- evidence_fingerprint()
  result <- testthat::test_dir("tests/testthat", filter = paste0("^temporal-", tolower(id), "$"),
    load_package = "none", load_helpers = FALSE, stop_on_failure = TRUE,
    stop_on_warning = TRUE, reporter = "summary")
  validate_results(as.data.frame(result), paste(id, temporal_cases[[id]], sep = ":"))
  if (pure && "drmTMB" %in% names(getLoadedDLLs())) stop("Pure gate loaded a drmTMB DLL.")
  if (!identical(inputs, evidence_fingerprint())) stop("Source inputs changed during the check.")
  outputs <- if (id %in% c("G11", "G12")) list.files(file.path(
    ".unlazy/temporal-ar1/recovery", if (id == "G11") "pre-run" else "bounded"),
    recursive = TRUE, full.names = TRUE) else character()
  outputs <- outputs[!dir.exists(outputs)]
  if (id %in% c("G11", "G12") && !length(outputs)) stop("No recovery outputs to bind.")
  stamp <- list(gate = id, results = as.data.frame(result), output_hashes = tools::md5sum(outputs),
    source_head = system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
    scoped_diff = system2("git", c("status", "--porcelain"), stdout = TRUE),
    native_source = native_fingerprint(), input_hashes = inputs, test_hash = tools::md5sum(file))
  saveRDS(stamp, file.path(".unlazy/temporal-ar1/receipts", paste0(id, ".rds")))
  cat(paste0("TEMPORAL_", id, "_PASS\n"))
}

if (sys.nframe() == 0L) main(commandArgs(trailingOnly = TRUE))
