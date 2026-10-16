#!/usr/bin/env Rscript
# t7 contrasts: contr.treatment / sum / helmert / poly on an ordered factor.
# Fitted values must be invariant across codings to 1e-8.
# Coefficients must equal lm/glm with the same coding (Gaussian / Poisson).
#
# Usage: Rscript sweep-oct16/t7/harness_contrasts.R [tmb|julia|all]

args <- commandArgs(trailingOnly = TRUE)
which_engine <- if (length(args) < 1L) "tmb" else args[[1L]]

suppressPackageStartupMessages({
  library(callr)
  library(drmTMB)
})

Sys.setenv(
  DRMODELS_JL_PATH = "/home/ubuntu/DRModels.jl",
  DRM_JL_PATH = "/home/ubuntu/DRModels.jl",
  DRMTMB_JULIA_TESTS = "true",
  NOT_CRAN = "true"
)

root <- "sweep-oct16/t7"
out_csv <- file.path(root, sprintf("results_contrasts_%s.csv", which_engine))
pass_bar <- 1e-8
timeout_s <- if (identical(which_engine, "julia")) 180 else 90

append_row <- function(row) {
  df <- as.data.frame(row, stringsAsFactors = FALSE)
  exists <- file.exists(out_csv)
  utils::write.table(
    df, out_csv, sep = ",", row.names = FALSE, col.names = !exists,
    append = exists, qmethod = "double"
  )
  cat(sprintf(
    "[%s] %s %s %s -> %s %s\n",
    format(Sys.time(), "%H:%M:%S"),
    row$family, row$coding, row$engine, row$status,
    if (nzchar(row$note)) paste0("| ", substr(row$note, 1, 140)) else ""
  ))
  flush.console()
}

contrast_funs <- list(
  treatment = function(n) stats::contr.treatment(n),
  sum = function(n) stats::contr.sum(n),
  helmert = function(n) stats::contr.helmert(n),
  poly = function(n) stats::contr.poly(n)
)

worker <- function(family, coding, engine, csv_path) {
  suppressPackageStartupMessages(library(drmTMB))
  Sys.setenv(
    DRMODELS_JL_PATH = "/home/ubuntu/DRModels.jl",
    DRM_JL_PATH = "/home/ubuntu/DRModels.jl",
    DRMTMB_JULIA_TESTS = "true",
    NOT_CRAN = "true"
  )
  d <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  d$g <- ordered(d$g, levels = c("a", "b", "c", "d"))
  cm <- switch(
    coding,
    treatment = stats::contr.treatment(4),
    sum = stats::contr.sum(4),
    helmert = stats::contr.helmert(4),
    poly = stats::contr.poly(4)
  )
  stats::contrasts(d$g) <- cm
  ycol <- if (identical(family, "gaussian")) "yg" else "yp"
  d$y <- d[[ycol]]
  t0 <- proc.time()[["elapsed"]]
  if (identical(family, "gaussian")) {
    fit <- drmTMB(bf(y ~ x + g, sigma ~ 1), family = stats::gaussian(), data = d, engine = engine)
    oracle <- stats::lm(y ~ x + g, data = d)
  } else {
    fit <- drmTMB(bf(y ~ x + g), family = stats::poisson(link = "log"), data = d, engine = engine)
    oracle <- stats::glm(y ~ x + g, family = stats::poisson(link = "log"), data = d)
  }
  elapsed <- proc.time()[["elapsed"]] - t0
  cf <- tryCatch(stats::coef(fit, "mu"), error = function(e) {
    c0 <- stats::coef(fit)
    if (is.list(c0)) c0$mu else c0
  })
  if (is.list(cf)) cf <- cf$mu
  oc <- stats::coef(oracle)
  fv <- as.numeric(stats::fitted(fit))
  ov <- as.numeric(stats::fitted(oracle))
  # Design column names actually used
  X <- tryCatch(colnames(stats::model.matrix(~ x + g, d)), error = function(e) character())
  list(
    ok = TRUE,
    elapsed = elapsed,
    coef_drm = as.numeric(cf),
    coef_names_drm = paste(names(cf), collapse = "|"),
    coef_oracle = as.numeric(oc),
    coef_names_oracle = paste(names(oc), collapse = "|"),
    max_coef_diff = if (length(cf) == length(oc) && identical(names(cf), names(oc))) {
      max(abs(as.numeric(cf) - as.numeric(oc)))
    } else {
      NA_real_
    },
    names_match = identical(names(cf), names(oc)),
    fitted_drm = fv,
    fitted_oracle = ov,
    max_fitted_vs_oracle = max(abs(fv - ov)),
    design_names = paste(X, collapse = "|")
  )
}

empty_row <- function(family, coding, engine) {
  list(
    family = family, coding = coding, engine = engine,
    status = "ERROR", names_match = NA, max_coef_diff = NA_real_,
    max_fitted_vs_oracle = NA_real_, coef_names_drm = "",
    coef_names_oracle = "", design_names = "", elapsed_s = NA_real_, note = ""
  )
}

run_case <- function(family, coding, engine) {
  row <- empty_row(family, coding, engine)
  csv_path <- normalizePath(file.path(root, "data_contrasts.csv"))
  t0 <- proc.time()[["elapsed"]]
  res <- tryCatch(
    callr::r(
      worker,
      args = list(family = family, coding = coding, engine = engine, csv_path = csv_path),
      timeout = timeout_s,
      libpath = .libPaths(),
      user_profile = TRUE
    ),
    error = function(e) e
  )
  row$elapsed_s <- proc.time()[["elapsed"]] - t0
  if (inherits(res, "error")) {
    msg <- conditionMessage(res)
    row$note <- msg
    if (grepl("time limit|killed|timed out|Timeout", msg, ignore.case = TRUE)) {
      row$status <- "TIMEOUT"
    } else if (grepl("contrast|treatment", msg, ignore.case = TRUE)) {
      row$status <- "REFUSED"
    } else {
      row$status <- "ERROR"
    }
    append_row(row)
    return(res)
  }
  row$names_match <- res$names_match
  row$max_coef_diff <- res$max_coef_diff
  row$max_fitted_vs_oracle <- res$max_fitted_vs_oracle
  row$coef_names_drm <- res$coef_names_drm
  row$coef_names_oracle <- res$coef_names_oracle
  row$design_names <- res$design_names
  coef_ok <- isTRUE(res$names_match) && isTRUE(res$max_coef_diff < 1e-6)
  fitted_ok <- isTRUE(res$max_fitted_vs_oracle < pass_bar)
  if (coef_ok && fitted_ok) {
    row$status <- "PASS"
  } else {
    row$status <- "FAIL"
    bits <- character()
    if (!isTRUE(res$names_match)) bits <- c(bits, "COEF_NAMES")
    if (!isTRUE(res$max_coef_diff < 1e-6)) bits <- c(bits, sprintf("COEF_DIFF=%g", res$max_coef_diff))
    if (!fitted_ok) bits <- c(bits, sprintf("FITTED_VS_ORACLE=%g", res$max_fitted_vs_oracle))
    row$note <- paste(bits, collapse = "; ")
  }
  # stash fitted for invariance check
  attr(row, "fitted") <- res$fitted_drm
  append_row(row)
  invisible(row)
}

if (file.exists(out_csv)) file.remove(out_csv)

families <- c("gaussian", "poisson")
codings <- c("treatment", "sum", "helmert", "poly")
engines <- if (identical(which_engine, "all")) c("tmb", "julia") else which_engine

fitted_store <- list()

for (eng in engines) {
  for (fam in families) {
    for (cod in codings) {
      row <- run_case(fam, cod, eng)
      if (!inherits(row, "error") && !is.null(attr(row, "fitted"))) {
        fitted_store[[paste(eng, fam, cod, sep = "/")]] <- attr(row, "fitted")
      }
    }
    # fitted invariance across the four encodings that actually fitted
    keys <- grep(paste0("^", eng, "/", fam, "/"), names(fitted_store), value = TRUE)
    if (length(keys) >= 2L) {
      ref <- fitted_store[[keys[[1L]]]]
      mx <- 0
      for (k in keys[-1L]) mx <- max(mx, max(abs(fitted_store[[k]] - ref)))
      inv <- empty_row(fam, "INVARIANCE", eng)
      inv$max_fitted_vs_oracle <- mx
      inv$status <- if (isTRUE(mx < pass_bar)) "PASS" else "FAIL"
      inv$note <- sprintf("max_|fitted_i - fitted_treatment-or-first| = %g over %s", mx, paste(keys, collapse = ","))
      inv$elapsed_s <- 0
      append_row(inv)
    }
  }
}

cat("wrote", out_csv, "\n")
print(utils::read.csv(out_csv, stringsAsFactors = FALSE)[, c("family", "coding", "engine", "status", "max_coef_diff", "max_fitted_vs_oracle")])
