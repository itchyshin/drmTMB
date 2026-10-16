#!/usr/bin/env Rscript
# t7 offset log-2 shift: intercept must drop by log(2) exactly when the
# offset is increased by log(2). Hard timeout via callr so a hang is a finding.
#
# Usage: Rscript sweep-oct16/t7/harness_offset.R [tmb|julia|all]

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
out_csv <- file.path(root, sprintf("results_offset_%s.csv", which_engine))
log2 <- log(2)
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
    "[%s] %s re=%s dpar=%s syn=%s eng=%s -> %s %s\n",
    format(Sys.time(), "%H:%M:%S"),
    row$family, row$re, row$dpar, row$syntax, row$engine, row$status,
    if (nzchar(row$note)) paste0("| ", substr(row$note, 1, 120)) else ""
  ))
  flush.console()
}

read_dat <- function(family) {
  d <- utils::read.csv(file.path(root, sprintf("data_offset_%s.csv", family)), stringsAsFactors = FALSE)
  d$g <- factor(d$g)
  d
}

family_obj <- function(family) {
  switch(
    family,
    poisson = stats::poisson(link = "log"),
    nbinom2 = drmTMB::nbinom2(),
    gamma = stats::Gamma(link = "log"),
    stop(family)
  )
}

build_formula <- function(family, re, dpar, syntax) {
  re_term <- if (identical(re, "re")) " + (1 | g)" else ""
  if (identical(syntax, "offset_arg")) {
    if (identical(dpar, "mu")) {
      if (family == "poisson") {
        sprintf("bf(y ~ x%s)", re_term)
      } else {
        sprintf("bf(y ~ x%s, sigma ~ 1)", re_term)
      }
    } else {
      if (family == "poisson") {
        sprintf("bf(y ~ x%s, sigma ~ 1)", re_term)
      } else {
        sprintf("bf(y ~ x%s, sigma ~ 1)", re_term)
      }
    }
  } else {
    if (identical(dpar, "mu")) {
      if (family == "poisson") {
        sprintf("bf(y ~ x + offset(off)%s)", re_term)
      } else {
        sprintf("bf(y ~ x + offset(off)%s, sigma ~ 1)", re_term)
      }
    } else {
      if (family == "poisson") {
        sprintf("bf(y ~ x%s, sigma ~ offset(off))", re_term)
      } else {
        sprintf("bf(y ~ x%s, sigma ~ offset(off))", re_term)
      }
    }
  }
}

worker <- function(family, re, dpar, syntax, engine, csv_path, log2) {
  suppressPackageStartupMessages(library(drmTMB))
  Sys.setenv(
    DRMODELS_JL_PATH = "/home/ubuntu/DRModels.jl",
    DRM_JL_PATH = "/home/ubuntu/DRModels.jl",
    DRMTMB_JULIA_TESTS = "true",
    NOT_CRAN = "true"
  )
  d <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  d$g <- factor(d$g)
  d_shift <- d
  d_shift$off <- d$off + log2
  fam <- switch(
    family,
    poisson = stats::poisson(link = "log"),
    nbinom2 = drmTMB::nbinom2(),
    gamma = stats::Gamma(link = "log")
  )
  re_term <- if (identical(re, "re")) " + (1 | g)" else ""
  form_txt <- if (identical(syntax, "offset_arg")) {
    if (family == "poisson" && identical(dpar, "mu")) {
      sprintf("bf(y ~ x%s)", re_term)
    } else if (identical(dpar, "sigma")) {
      sprintf("bf(y ~ x%s, sigma ~ 1)", re_term)
    } else {
      sprintf("bf(y ~ x%s, sigma ~ 1)", re_term)
    }
  } else if (identical(dpar, "mu")) {
    if (family == "poisson") {
      sprintf("bf(y ~ x + offset(off)%s)", re_term)
    } else {
      sprintf("bf(y ~ x + offset(off)%s, sigma ~ 1)", re_term)
    }
  } else if (family == "poisson") {
    sprintf("bf(y ~ x%s, sigma ~ offset(off))", re_term)
  } else {
    sprintf("bf(y ~ x%s, sigma ~ offset(off))", re_term)
  }
  form <- eval(parse(text = form_txt))
  fit_one <- function(dat) {
    if (identical(syntax, "offset_arg")) {
      drmTMB(form, family = fam, data = dat, engine = engine, offset = dat$off)
    } else {
      drmTMB(form, family = fam, data = dat, engine = engine)
    }
  }
  t0 <- proc.time()[["elapsed"]]
  f1 <- fit_one(d)
  f2 <- fit_one(d_shift)
  elapsed <- proc.time()[["elapsed"]] - t0
  cf1 <- tryCatch(stats::coef(f1, "mu"), error = function(e) stats::coef(f1)$mu)
  cf2 <- tryCatch(stats::coef(f2, "mu"), error = function(e) stats::coef(f2)$mu)
  if (is.null(cf1)) cf1 <- stats::coef(f1)
  if (is.null(cf2)) cf2 <- stats::coef(f2)
  if (is.list(cf1)) cf1 <- cf1$mu
  if (is.list(cf2)) cf2 <- cf2$mu
  nms <- intersect(names(cf1), names(cf2))
  int_nm <- grep("Intercept", nms, value = TRUE)[1]
  if (is.na(int_nm) || !length(int_nm)) int_nm <- nms[1]
  slope_nms <- setdiff(nms, int_nm)
  int1 <- unname(cf1[[int_nm]])
  int2 <- unname(cf2[[int_nm]])
  delta <- int1 - int2
  slope_diff <- if (length(slope_nms)) max(abs(unname(cf1[slope_nms]) - unname(cf2[slope_nms]))) else 0
  ll1 <- as.numeric(stats::logLik(f1))
  ll2 <- as.numeric(stats::logLik(f2))
  coef_names <- paste(names(cf1), collapse = "|")
  has_offset_coef <- any(grepl("offset", names(cf1), ignore.case = TRUE))
  sig1 <- tryCatch({
    s <- stats::coef(f1, "sigma")
    unname(s[[grep("Intercept", names(s), value = TRUE)[1]]])
  }, error = function(e) NA_real_)
  sig2 <- tryCatch({
    s <- stats::coef(f2, "sigma")
    unname(s[[grep("Intercept", names(s), value = TRUE)[1]]])
  }, error = function(e) NA_real_)
  list(
    ok = TRUE,
    elapsed = elapsed,
    int1 = int1, int2 = int2, delta = delta,
    slope_diff = slope_diff,
    ll1 = ll1, ll2 = ll2, ll_delta = ll1 - ll2,
    coef_names = coef_names,
    has_offset_coef = has_offset_coef,
    sig1 = sig1, sig2 = sig2,
    sig_delta = if (is.finite(sig1) && is.finite(sig2)) sig1 - sig2 else NA_real_,
    conv1 = tryCatch(f1$opt$convergence, error = function(e) NA_integer_),
    conv2 = tryCatch(f2$opt$convergence, error = function(e) NA_integer_)
  )
}

empty_row <- function(family, re, dpar, syntax, engine) {
  list(
    family = family, re = re, dpar = dpar, syntax = syntax, engine = engine,
    status = "ERROR", intercept_base = NA_real_, intercept_shift = NA_real_,
    intercept_delta = NA_real_, expected = log2, abs_err = NA_real_,
    slope_max_diff = NA_real_, loglik_base = NA_real_, loglik_shift = NA_real_,
    loglik_delta = NA_real_, sigma_intercept_delta = NA_real_,
    has_offset_coef = NA, elapsed_s = NA_real_, note = ""
  )
}

run_case <- function(family, re, dpar, syntax, engine) {
  row <- empty_row(family, re, dpar, syntax, engine)
  csv_path <- normalizePath(file.path(root, sprintf("data_offset_%s.csv", family)))
  t0 <- proc.time()[["elapsed"]]
  res <- tryCatch(
    callr::r(
      worker,
      args = list(
        family = family, re = re, dpar = dpar, syntax = syntax,
        engine = engine, csv_path = csv_path, log2 = log2
      ),
      timeout = timeout_s,
      libpath = .libPaths(),
      user_profile = TRUE
    ),
    error = function(e) e
  )
  elapsed <- proc.time()[["elapsed"]] - t0
  row$elapsed_s <- elapsed
  if (inherits(res, "error")) {
    msg <- conditionMessage(res)
    row$note <- msg
    if (grepl("time limit|killed|timed out|Timeout", msg, ignore.case = TRUE)) {
      row$status <- "TIMEOUT"
    } else if (
      grepl("offset", msg, ignore.case = TRUE) ||
        grepl("Unused argument", msg) ||
        grepl("does not use extra arguments", msg) ||
        grepl("unsupported term", msg, ignore.case = TRUE) ||
        grepl("sigma formula", msg, ignore.case = TRUE)
    ) {
      row$status <- "REFUSED"
    } else {
      row$status <- "ERROR"
    }
    append_row(row)
    return(invisible(row))
  }
  row$intercept_base <- res$int1
  row$intercept_shift <- res$int2
  row$intercept_delta <- res$delta
  row$abs_err <- abs(res$delta - log2)
  row$slope_max_diff <- res$slope_diff
  row$loglik_base <- res$ll1
  row$loglik_shift <- res$ll2
  row$loglik_delta <- res$ll_delta
  row$sigma_intercept_delta <- res$sig_delta
  row$has_offset_coef <- isTRUE(res$has_offset_coef)
  row$note <- paste0("coefs=", res$coef_names)
  target_delta <- if (identical(dpar, "sigma")) {
    res$sig_delta
  } else {
    res$delta
  }
  err <- abs(target_delta - log2)
  # Pass bar: intercept (or sigma intercept) drops by log(2) within 1e-8,
  # other mu slopes and logLik unchanged.
  slopes_ok <- isTRUE(res$slope_diff < pass_bar) || identical(dpar, "sigma")
  ll_ok <- isTRUE(abs(res$ll_delta) < 1e-6)
  shift_ok <- isTRUE(err < pass_bar)
  if (isTRUE(res$has_offset_coef)) {
    row$status <- "FAIL"
    row$note <- paste(row$note, "SILENT_OFFSET_COEF")
  } else if (shift_ok && (identical(dpar, "sigma") || (slopes_ok && ll_ok))) {
    row$status <- "PASS"
  } else if (shift_ok && identical(dpar, "mu") && slopes_ok) {
    # logLik mismatch with exact intercept shift: still a finding
    row$status <- "FAIL"
    row$note <- paste(row$note, "LOGLIK_CHANGED")
  } else {
    row$status <- "FAIL"
  }
  append_row(row)
  invisible(row)
}

families <- c("poisson", "nbinom2", "gamma")
res <- c("fe", "re")
dpars <- c("mu", "sigma")
syntaxes <- c("formula", "offset_arg")
engines <- if (identical(which_engine, "all")) c("tmb", "julia") else which_engine

if (file.exists(out_csv)) file.remove(out_csv)

for (eng in engines) {
  for (fam in families) {
    for (re in res) {
      for (dp in dpars) {
        for (syn in syntaxes) {
          run_case(fam, re, dp, syn, eng)
        }
      }
    }
  }
}

cat("wrote", out_csv, "\n")
print(utils::read.csv(out_csv, stringsAsFactors = FALSE)[, c("family", "re", "dpar", "syntax", "engine", "status", "abs_err")])
