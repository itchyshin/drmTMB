args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript worker-0975.R CALIBRATION_DIRECTORY MANIFEST_INDEX")
out <- normalizePath(args[[1L]], mustWork = TRUE)
idx <- suppressWarnings(as.integer(args[[2L]]))
manifest <- read.csv(file.path(out, "manifest.csv"), stringsAsFactors = FALSE)
if (is.na(idx) || idx < 1L || idx > nrow(manifest) || manifest$index[[idx]] != idx) stop("Invalid manifest index")
planned_indices <- suppressWarnings(as.integer(strsplit(Sys.getenv("DRMTMB_SD_PLANNED_INDICES"), ",", fixed=TRUE)[[1L]]))
if (!length(planned_indices) || is.na(planned_indices[[1L]]) || !idx %in% planned_indices) stop("Worker index is not in the supervisor's planned subset")
design <- setNames(sub("^[^=]*=", "", readLines(file.path(out,"design-receipt.txt"))),
                   sub("=.*$", "", readLines(file.path(out,"design-receipt.txt"))))
sc <- manifest[idx, ]
if (!identical(as.character(sc$design_mode), unname(design["design_mode"])) ||
    as.integer(sc$master_seed) != as.integer(design["master_seed"])) stop("Manifest mode/master seed differs from frozen design")
if (!requireNamespace("digest", quietly = TRUE)) stop("digest is required to verify prepared artifacts")
hashes <- read.csv(file.path(out, "source-hashes.csv"), stringsAsFactors = FALSE)
registry_seal <- Sys.getenv("DRMTMB_SD_REGISTRY_SHA256")
if (!nzchar(registry_seal) || !identical(digest::digest(file.path(out, "source-hashes.csv"), algo="sha256", file=TRUE), registry_seal)) stop("External source registry seal mismatch")
manifest_pin <- hashes$sha256[basename(hashes$path) == "manifest.csv"]
if (length(manifest_pin) != 1L || !identical(digest::digest(file.path(out,"manifest.csv"),algo="sha256",file=TRUE),manifest_pin[[1L]])) stop("Local manifest differs from the pinned manifest")
for (j in seq_len(nrow(hashes))) {
  path <- hashes$path[[j]]
  if (!file.exists(path) || !identical(digest::digest(path, algo = "sha256", file = TRUE), hashes$sha256[[j]])) stop("Prepared artifact hash mismatch: ", path)
}
repo_root <- sub("/R/drmTMB\\.R$", "", hashes$path[grepl("/R/drmTMB\\.R$", hashes$path)][[1L]])
source(file.path(repo_root, "tools/general-sd-regression/native-calibration/generator.R"))
if (identical(design[["design_mode"]], "timing_only")) {
  source(file.path(repo_root, "tools/general-sd-regression/native-calibration/clean-manifests.R"))
  expected <- build_clean_bernoulli_manifests()$timing
  if (!identical(names(manifest), names(expected)) || nrow(manifest) != 45L ||
      !isTRUE(all.equal(manifest, expected, tolerance = 1e-14, check.attributes = FALSE)))
    stop("Timing worker requires the full ordered clean 45-row manifest")
  if (!identical(design[["master_seed"]], "2026101903") ||
      !identical(design[["planned_attempts"]], "45") ||
      !identical(design[["profile_level"]], "0.975") ||
      !identical(tolower(design[["calibration_claim"]]), "false") ||
      !identical(planned_indices, seq_len(45L)))
    stop("Timing worker receipt or planned indices violate the timing-only design")
}
result_path <- file.path(out, sprintf("result-%04d.csv", idx))
if (file.exists(result_path)) stop("Refusing to overwrite existing result: ", result_path)
library_path <- Sys.getenv("DRMTMB_SD_TEST_LIBRARY")
if (!nzchar(library_path)) stop("Set DRMTMB_SD_TEST_LIBRARY")
.libPaths(c(library_path, .libPaths()))
library(drmTMB)
expected_pkg <- dirname(dirname(hashes$path[endsWith(hashes$path, "/drmTMB.rdb")][[1L]]))
if (!identical(normalizePath(find.package("drmTMB"), mustWork = TRUE), normalizePath(expected_pkg, mustWork = TRUE))) stop("Loaded drmTMB library differs from the prepared package")
dll_info <- getLoadedDLLs()[["drmTMB"]]
if (is.null(dll_info)) stop("drmTMB DLL is not loaded")
loaded_dll <- dll_info[["path"]]
if (!normalizePath(loaded_dll, mustWork = TRUE) %in% normalizePath(hashes$path, mustWork = TRUE)) stop("Loaded drmTMB DLL is not the prepared artifact")
source(file.path(repo_root, "tests/testthat/helper-binomial-sd-regression.R"))
if (sc$design_mode != "production" && sc$design_mode != "qualification" &&
    sc$design_mode != "timing_only") stop("Unknown manifest design mode")
calibration_claim <- !identical(as.character(sc$design_mode), "timing_only")
row <- data.frame(index = idx, a = sc$a, replicate = sc$replicate, seed = sc$seed,
  state = "started", calibration_claim = calibration_claim,
  estimate = NA_real_, se = NA_real_, convergence = NA_integer_,
  pdHess = FALSE, max_abs_gradient = NA_real_, clamp_at_optimum = "not_checked",
  lower = NA_real_, upper = NA_real_, profile_level = 0.975,
  interval_status = "not_attempted",
  profile_boundary = NA, profile_message = "", valid_interval = FALSE,
  laplace_oracle_error = NA_real_, oracle_pass = FALSE,
  oracle_tolerance = 1e-6, warnings = "", error = "", elapsed = NA_real_,
  stringsAsFactors = FALSE)
atomic_csv <- function(x) {
  tmp <- tempfile("result-", tmpdir = out, fileext = ".csv")
  write.csv(x, tmp, row.names = FALSE)
  if (!file.rename(tmp, result_path)) stop("Could not atomically publish worker state")
}
atomic_csv(row)
warns <- character()
t0 <- proc.time()[["elapsed"]]
tryCatch(withCallingHandlers({
  generated <- sd_regression_generate(sc)
  dat <- generated$data
  fit <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w), binomial(), dat)
  row$estimate <- unname(coef(fit, "sd(id)")[["w"]])
  row$se <- sqrt(vcov(fit)["sd(id):w", "sd(id):w"])
  row$convergence <- fit$opt$convergence
  row$pdHess <- isTRUE(fit$sdr$pdHess)
  row$max_abs_gradient <- max(abs(fit$obj$gr(fit$opt$par)))
  health <- check_drm(fit)
  saveRDS(health, file.path(out, sprintf("health-%04d.rds", idx)))
  row$clamp_at_optimum <- health$status[health$check == "logsigma_clamp_active"][[1L]]
  row$laplace_oracle_error <- -as.numeric(logLik(fit)) -
    binomial_sd_laplace_oracle(dat, coef(fit, "mu"), coef(fit, "sd(id)"))
  row$oracle_pass <- is.finite(row$laplace_oracle_error) && abs(row$laplace_oracle_error) < row$oracle_tolerance
  row$state <- "profiling"; row$interval_status <- "profile_error"
  atomic_csv(row)
  ci <- confint(fit, parm = "fixef:sd(id):w", method = "profile", level = 0.975)
  returned_level <- suppressWarnings(as.numeric(ci$level))
  row$profile_level <- if (length(returned_level) == 1L) returned_level else NA_real_
  if (length(returned_level) != 1L || !is.finite(returned_level) ||
      abs(returned_level - 0.975) > 1e-12) {
    stop("Profile interval did not return the requested 97.5% confidence level")
  }
  saveRDS(ci, file.path(out, sprintf("interval-%04d.rds", idx)))
  row$lower <- ci$lower[[1L]]; row$upper <- ci$upper[[1L]]
  row$interval_status <- ci$conf.status[[1L]]
  row$profile_boundary <- ci$profile.boundary[[1L]]
  row$profile_message <- ci$profile.message[[1L]]
  row$valid_interval <- isTRUE(row$convergence == 0L) && isTRUE(row$pdHess) &&
    isTRUE(row$max_abs_gradient < 1e-3) && identical(row$clamp_at_optimum, "ok") &&
    identical(row$interval_status, "profile") && identical(row$profile_boundary, FALSE) &&
    all(is.finite(c(row$lower, row$upper))) && row$lower < row$upper && isTRUE(row$oracle_pass)
}, warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") }),
error = function(e) row$error <<- conditionMessage(e))
row$warnings <- paste(unique(warns), collapse = " | ")
row$elapsed <- proc.time()[["elapsed"]] - t0
row$state <- "completed"
atomic_csv(row)
cat(sprintf("WORKER_RESULT index=%d state=completed valid_interval=%s\n", idx, row$valid_interval))
if (nzchar(row$error)) quit(save = "no", status = 1L)
