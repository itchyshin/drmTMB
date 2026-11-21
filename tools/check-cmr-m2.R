#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
gate <- if (length(args) == 2L && identical(args[[1L]], "--gate")) args[[2L]] else
  if (length(args) == 1L && startsWith(args[[1L]], "--gate=")) sub("^--gate=", "", args[[1L]]) else
    stop("usage: Rscript tools/check-cmr-m2.R --gate prediction|simulation|wald|profile|bootstrap|recovery|integration|documentation", call. = FALSE)
gates <- c("prediction", "simulation", "wald", "profile", "bootstrap", "recovery", "integration", "documentation")
if (!gate %in% gates) stop("CMR_M2_GATE_UNAVAILABLE: unsupported gate; no success marker emitted", call. = FALSE)

if (!requireNamespace("devtools", quietly = TRUE)) stop("devtools is required to load drmTMB and its TMB DLL.", call. = FALSE)
devtools::load_all(".", quiet = TRUE)

run_test <- function(file) {
  if (!file.exists(file)) stop("CMR_M2_GATE_ERROR: missing test file: ", file, call. = FALSE)
  results <- testthat::test_file(file, package = "drmTMB", reporter = "summary",
                                 stop_on_failure = TRUE)
  expectations <- unlist(lapply(results, function(test) test$results), recursive = FALSE)
  if (!length(expectations)) stop("CMR_M2_GATE_ERROR: test file executed no expectations: ", file, call. = FALSE)
  failed <- vapply(expectations, function(x) inherits(x, c("expectation_failure", "expectation_error")), logical(1))
  if (any(failed)) stop("CMR_M2_GATE_ERROR: failed expectations in ", file, call. = FALSE)
}

if (gate == "documentation") {
  registrations <- readLines("NAMESPACE", warn = FALSE)
  methods <- c("coef", "confint", "predict", "simulate", "vcov")
  for (method in methods) {
    if (!paste0("S3method(", method, ",drm_cjs)") %in% registrations)
      stop("CMR_M2_GATE_ERROR: missing S3 registration for ", method, ".", call. = FALSE)
    if (!file.exists(file.path("man", paste0(method, ".drm_cjs.Rd"))))
      stop("CMR_M2_GATE_ERROR: missing help page for ", method, ".drm_cjs.", call. = FALSE)
  }
  if (!file.exists("vignettes/cjs-first-capture.Rmd"))
    stop("CMR_M2_GATE_ERROR: matched CJS vignette is missing.", call. = FALSE)
  vignette_source <- readLines("vignettes/cjs-first-capture.Rmd", warn = FALSE)
  if (!any(grepl('title: "First-capture-conditional capture-recapture"', vignette_source,
                 fixed = TRUE)))
    stop("CMR_M2_GATE_ERROR: CJS vignette title metadata is missing.", call. = FALSE)
  cat("CMR_M2_DOCUMENTATION_OK\n")
  quit(status = 0L)
}

if (gate == "recovery") {
  source("tools/cmr_m2_recovery.R")
  run_cmr_m2_recovery_smoke()
  cat("CMR_M2_RECOVERY_OK\n")
  quit(status = 0L)
}

invisible(capture.output(run_test("tests/testthat/test-cmr-methods.R")))
if (gate == "integration") {
  for (file in c("tests/testthat/test-cmr-data.R", "tests/testthat/test-cmr-exact.R",
                 "tests/testthat/test-cmr-contract.R", "tests/testthat/test-cmr-derivatives.R"))
    invisible(capture.output(run_test(file)))
  invisible(capture.output(source("tools/check-cmr-parity.R")))
  registrations <- readLines("NAMESPACE", warn = FALSE)
  for (method in c("coef", "confint", "predict", "simulate", "vcov")) {
    if (!paste0("S3method(", method, ",drm_cjs)") %in% registrations ||
        !file.exists(file.path("man", paste0(method, ".drm_cjs.Rd"))))
      stop("CMR_M2_GATE_ERROR: CJS registration/help is incomplete for ", method, ".", call. = FALSE)
  }
  if (!file.exists("vignettes/cjs-first-capture.Rmd"))
    stop("CMR_M2_GATE_ERROR: matched CJS vignette is missing.", call. = FALSE)
}

marker <- switch(gate,
  prediction = "CMR_M2_PREDICTION_OK",
  simulation = "CMR_M2_SIMULATION_OK",
  wald = "CMR_M2_WALD_OK",
  profile = "CMR_M2_PROFILE_OK",
  bootstrap = "CMR_M2_BOOTSTRAP_OK",
  documentation = "CMR_M2_DOCUMENTATION_OK",
  integration = "CMR_M2_INTEGRATION_OK")
cat(marker, "\n", sep = "")
