#!/usr/bin/env Rscript
# Bounded transport check; not a native optimizer or full public-method verdict.
args <- commandArgs(TRUE)
if (length(args) != 3L) stop("usage: run-julia-joint-transport.R JULIA_CHECKOUT FROZEN_JSON NEW_OUTPUT_PREFIX")
julia_root <- normalizePath(args[[1]], mustWork = TRUE)
fixture <- normalizePath(args[[2]], mustWork = TRUE)
prefix <- args[[3]]
if (any(file.exists(paste0(prefix, c(".json", ".rds"))))) stop("refusing stale output")
Sys.setenv(DRM_JL_PATH = julia_root, DRMTMB_JULIA_TESTS = "true",
           JULIA_NUM_THREADS = "1", OPENBLAS_NUM_THREADS = "1")
sha <- function(path) digest::digest(file = path, algo = "sha256")
root <- normalizePath(".", mustWork = TRUE)
used <- c("R/julia-joint-call.R", "R/julia-joint-missing.R", "R/julia-bridge.R",
          "R/drmTMB.R", "R/missing-data.R", "R/bf.R", "R/parse-formula.R")
source_manifest <- function() {
  jp <- sort(list.files(file.path(julia_root, "src"), recursive = TRUE, full.names = TRUE))
  rp <- file.path(root, used)
  paths <- c(rp, jp)
  as.list(setNames(vapply(paths, sha, ""), paths))
}
before <- source_manifest()
pkgload::load_all(root, quiet = TRUE, recompile = FALSE)
ref <- jsonlite::read_json(fixture, simplifyVector = TRUE)
out <- list(scope = "Primitive R to Julia transport for two frozen fixtures; public adapters and native parity separate",
  fixture_sha256 = sha(fixture), runner_sha256 = sha("tools/run-julia-joint-transport.R"),
  source_before = before, R_version = R.version.string, cases = list())
save_receipt <- function() jsonlite::write_json(out, paste0(prefix, ".json"),
  pretty = TRUE, auto_unbox = TRUE, digits = 17, na = "string", null = "null")
results <- list()
start <- proc.time()[["elapsed"]]
drmTMB:::drm_julia_setup()
JuliaCall::julia_command("using LinearAlgebra; BLAS.set_num_threads(1)")
out$runtime <- JuliaCall::julia_eval('Dict("julia"=>string(VERSION), "threads"=>Threads.nthreads(), "blas"=>BLAS.get_num_threads(), "source"=>pathof(DRM))')
stopifnot(out$runtime$threads == 1L, out$runtime$blas == 1L)
for (kind in c("gaussian", "bernoulli")) {
  out$cases[[kind]] <- tryCatch({
    f <- ref$cases[[kind]]$fixture
    decode <- function(x) suppressWarnings(as.numeric(x))
    dat <- data.frame(y = decode(f$y), x = decode(f$x), z = decode(f$z))
    stopifnot(nrow(dat) == 160L, sum(is.na(dat$y)) == 4L, sum(is.na(dat$x)) == 10L)
    if (kind == "bernoulli") dat$x <- factor(dat$x, levels = c(0, 1))
    impute <- if (kind == "gaussian") list(x = x ~ z) else
      list(x = impute_model(x ~ z, family = binomial()))
    formula <- bf(y ~ z + mi(x), sigma ~ 1)
    prepared <- drmTMB:::drm_julia_joint_prepare(formula, gaussian(), dat,
      impute = impute, missing = miss_control(response = "include", predictor = "model"))
    tick <- proc.time()[["elapsed"]]
    result <- drmTMB:::drm_julia_call_joint(prepared$payload)
    seconds <- proc.time()[["elapsed"]] - tick
    stopifnot(identical(result$schema, "joint_missing_result_v1"), isTRUE(result$converged),
      length(result$coefficients) == if (kind == "gaussian") 7L else 6L,
      all(result$original_row == seq_len(160)), length(result$imputation$estimate) == 160L)
    results[[kind]] <- list(result = result, prepared = prepared, data = dat,
                           formula = formula, family = gaussian())
    list(status = "PASS", elapsed = seconds, coefficients = result$coefficients,
      blocks = result$coefficient_blocks, terms = result$coefficient_terms,
      loglik = result$loglik, covariance = result$vcov, imputation = result$imputation)
  }, error = function(e) list(status = "ERROR", message = conditionMessage(e)))
  save_receipt()
  cat(kind, out$cases[[kind]]$status, "\n")
}
out$elapsed <- proc.time()[["elapsed"]] - start
out$source_after <- source_manifest()
out$source_unchanged <- identical(out$source_before, out$source_after)
out$status <- if (out$source_unchanged && all(vapply(out$cases, function(x) identical(x$status, "PASS"), TRUE))) "PASS" else "FAIL"
save_receipt()
saveRDS(results, paste0(prefix, ".rds"))
cat("JOINT_TRANSPORT_", out$status, "\n", sep = "")
if (out$status != "PASS") quit(status = 1L)
