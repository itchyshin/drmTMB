#!/usr/bin/env Rscript
# Execute the article's actual R expressions against an isolated installed build.
# This is example validation, not a full parity or interval-coverage campaign.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 3L)
lib <- normalizePath(args[[1L]], mustWork = TRUE)
julia_root <- normalizePath(args[[2L]], mustWork = TRUE)
output <- args[[3L]]
.libPaths(c(lib, .libPaths()))
stopifnot(startsWith(normalizePath(find.package("drmTMB")), paste0(lib, "/")))
Sys.setenv(DRM_JL_PATH = julia_root, DRMTMB_JULIA_TESTS = "true")
article <- "vignettes/julia-engine.Rmd"
stopifnot(file.exists(article))
valid_intervals <- function(x) {
  is.data.frame(x) && nrow(x) > 0L && all(c("lower", "upper", "conf.status") %in% names(x)) &&
    is.numeric(x$lower) && is.numeric(x$upper) &&
    all(is.finite(x$lower)) && all(is.finite(x$upper)) && all(x$lower < x$upper) &&
    all(x$conf.status %in% c("wald", "profile"))
}
# Negative controls ensure completed calls with unusable bounds cannot pass.
stopifnot(valid_intervals(data.frame(lower = 0, upper = 1, conf.status = "profile")),
          !valid_intervals(data.frame(lower = 1, upper = 1, conf.status = "profile")),
          !valid_intervals(data.frame(lower = NA_real_, upper = 1, conf.status = "profile")),
          !valid_intervals(data.frame(lower = 0, upper = 1, conf.status = "failed")))
source(file.path(julia_root, "tools", "drmtmb_provenance_lib.R"))
# purl omits eval=FALSE chunks, which are precisely the examples to exercise.
# Extract literal R fences without changing their code or running package installs.
lines <- readLines(article, warn = FALSE)
code <- character()
in_r_chunk <- FALSE
for (line in lines) {
  if (!in_r_chunk && grepl("^```\\{r([ ,}]|$)", line)) {
    in_r_chunk <- TRUE
  } else if (in_r_chunk && grepl("^```[[:space:]]*$", line)) {
    in_r_chunk <- FALSE
    code <- c(code, "")
  } else if (in_r_chunk) {
    code <- c(code, line)
  }
}
stopifnot(!in_r_chunk, length(code) > 0L)
expressions <- parse(text = code)
scope <- new.env(parent = globalenv())
receipt <- list(
  kind = "article-execution-v1", time_utc = format(Sys.time(), tz = "UTC"),
  article_sha256 = digest::digest(file = article, algo = "sha256"),
  comparator = drmtmb_provenance(),
  loaded_dll_sha256 = digest::digest(file = file.path(find.package("drmTMB"), "libs", "drmTMB.so"), algo = "sha256"),
  julia_root = julia_root, julia_threads_requested = Sys.getenv("JULIA_NUM_THREADS"),
  blas_threads_requested = Sys.getenv("OPENBLAS_NUM_THREADS"),
  R = R.version.string, expressions = list(), fits = list(), checks = list()
)
save_receipt <- function() {
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(receipt, output, pretty = TRUE, auto_unbox = TRUE, null = "null", digits = 16)
}
failure <- FALSE
for (i in seq_along(expressions)) {
  expr <- expressions[[i]]
  text <- paste(deparse(expr), collapse = "\n")
  # Installation is verified separately; retain the source example's setup intent
  # without downloading packages or substituting its placeholder checkout path.
  setup_only <- is.call(expr) && (
    identical(expr[[1L]], as.name("install.packages")) ||
      (identical(expr[[1L]], as.name("Sys.setenv")) && "DRM_JL_PATH" %in% names(expr))
  )
  if (setup_only) {
    receipt$expressions[[length(receipt$expressions) + 1L]] <- list(index = i, code = text, status = "SETUP_PROVIDED")
    next
  }
  warnings <- character()
  start <- proc.time()[["elapsed"]]
  error <- NULL
  value <- tryCatch(withCallingHandlers(eval(expr, envir = scope), warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")
  }), error = function(e) { error <<- conditionMessage(e); NULL })
  if (is.null(error) && is.call(expr) && identical(expr[[1L]], as.name("confint"))) {
    valid <- valid_intervals(value)
    targets <- if (identical(expr[["method"]], "profile")) "fixef:mu:x" else
      c("fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)", "fixef:sigma:x")
    valid <- valid && identical(as.character(value$parm), targets) &&
      all(value$conf.status == expr[["method"]])
    receipt$checks[[paste0("interval_expression_", i)]] <- list(
      passed = valid, bounds = value[c("parm", "lower", "upper", "conf.status")])
    failure <- failure || !valid
  }
  if (is.null(error) && is.call(expr) && identical(expr[[1L]], as.name("predict"))) {
    valid <- is.numeric(value) && length(value) == nrow(scope$dat) && all(is.finite(value))
    if (identical(expr[["dpar"]], "sigma")) valid <- valid && all(value > 0)
    receipt$checks[[paste0("prediction_expression_", i)]] <- list(passed = valid, values = value)
    failure <- failure || !valid
  }
  if (is.null(error) && is.call(expr) && identical(expr[[1L]], as.name("vcov"))) {
    valid <- is.matrix(value) && identical(dim(value), c(4L, 4L)) && all(is.finite(value))
    receipt$checks[[paste0("covariance_expression_", i)]] <- list(passed = valid, values = value)
    failure <- failure || !valid
  }
  receipt$expressions[[length(receipt$expressions) + 1L]] <- list(
    index = i, code = text, elapsed_seconds = proc.time()[["elapsed"]] - start,
    status = if (is.null(error)) "EXECUTED" else "ERROR", error = error,
    warnings = warnings, result_class = class(value),
    result_preview = if (is.call(expr) && identical(expr[[1L]], as.name("confint"))) capture.output(print(value)) else NULL
  )
  save_receipt()
  cat(sprintf("ARTICLE_EXPRESSION %d %s\n", i, if (is.null(error)) "EXECUTED" else "ERROR"))
  flush.console()
  if (!is.null(error)) { failure <- TRUE; break }
}
expected_fits <- c("fit_r", "fit_julia", "fit_lss", "fit_phylo_lss", "fit_missing")
for (name in expected_fits) {
  if (!exists(name, envir = scope, inherits = FALSE)) {
    receipt$fits[[name]] <- list(status = "MISSING"); failure <- TRUE; next
  }
  fit <- get(name, envir = scope)
  ll <- as.numeric(logLik(fit))
  convergence <- fit$opt$convergence
  finite <- length(ll) == 1L && is.finite(ll)
  coefficients <- unlist(coef(fit), use.names = TRUE)
  ordinary <- name %in% c("fit_r", "fit_julia")
  expected_estimator <- if (ordinary) "ML" else "REML"
  expected_ncoef <- if (ordinary) 4L else 6L
  ok <- finite && isTRUE(convergence == 0L) && identical(fit$estimator, expected_estimator) &&
    is.numeric(coefficients) && length(coefficients) == expected_ncoef && all(is.finite(coefficients))
  receipt$fits[[name]] <- list(status = if (ok) "PASS" else "FAIL", logLik = ll,
                              convergence = convergence, estimator = fit$estimator,
                              coefficients = coef(fit), uncertainty = fit$uncertainty)
  failure <- failure || !ok
}
if (exists("fit_julia", envir = scope, inherits = FALSE)) {
  runtime_error <- NULL
  receipt$julia_runtime <- tryCatch(list(
    version = JuliaCall::julia_eval("string(VERSION)"),
    loaded_module = JuliaCall::julia_eval("pathof(DRM)"),
    threads = JuliaCall::julia_eval("Threads.nthreads()"),
    blas_threads = JuliaCall::julia_eval("DRM.LinearAlgebra.BLAS.get_num_threads()"),
    git_revision = system2("git", c("-C", shQuote(julia_root), "rev-parse", "HEAD"), stdout = TRUE),
    dirty_source = system2("git", c("-C", shQuote(julia_root), "status", "--porcelain", "--", "src"), stdout = TRUE)
  ), error = function(e) { runtime_error <<- conditionMessage(e); NULL })
  paths <- list.files(file.path(julia_root, "src"), pattern = "\\.jl$", recursive = TRUE, full.names = TRUE)
  receipt$julia_source_sha256 <- as.list(setNames(vapply(paths, function(p) digest::digest(file = p, algo = "sha256"), character(1)),
                                                substring(paths, nchar(julia_root) + 2L)))
  runtime_ok <- is.null(runtime_error) &&
    identical(normalizePath(receipt$julia_runtime$loaded_module), normalizePath(file.path(julia_root, "src", "DRM.jl"))) &&
    isTRUE(receipt$julia_runtime$threads == 1L) && isTRUE(receipt$julia_runtime$blas_threads == 1L)
  receipt$checks$runtime <- list(passed = runtime_ok, error = runtime_error)
  failure <- failure || !runtime_ok
}
if (all(vapply(c("fit_r", "fit_julia"), exists, logical(1), envir = scope, inherits = FALSE))) {
  difference <- abs(as.numeric(logLik(scope$fit_r)) - as.numeric(logLik(scope$fit_julia)))
  ok <- is.finite(difference) && difference <= 1e-6
  receipt$checks$ordinary_ml_loglik <- list(actual_absolute_difference = difference,
                                            absolute_tolerance = 1e-6, passed = ok)
  failure <- failure || !ok
}
receipt$status <- if (failure) "ARTICLE_CHECK_FAILED" else "ARTICLE_EXECUTION_PASS"
save_receipt()
cat(receipt$status, "\n")
quit(status = if (failure) 1L else 0L)
