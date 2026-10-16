#!/usr/bin/env Rscript
# t7 engine="julia" offset + contrasts in ONE R process so JuliaCall setup
# runs once. Whole-script hard timeout is applied by `timeout(1)`.

suppressPackageStartupMessages(library(drmTMB))
Sys.setenv(
  DRMODELS_JL_PATH = "/home/ubuntu/DRModels.jl",
  DRM_JL_PATH = "/home/ubuntu/DRModels.jl",
  DRMTMB_JULIA_TESTS = "true",
  NOT_CRAN = "true"
)
options(drmTMB.DRModels.jl.path = "/home/ubuntu/DRModels.jl")

root <- "sweep-oct16/t7"
log2 <- log(2)
pass_bar <- 1e-8
per_fit_s <- 90

fit_with_time <- function(expr) {
  setTimeLimit(elapsed = per_fit_s, transient = TRUE)
  on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
  force(expr)
}

capture_err <- function(expr) {
  tryCatch(
    list(ok = TRUE, value = fit_with_time(expr)),
    error = function(e) list(ok = FALSE, error = conditionMessage(e), class = class(e))
  )
}

classify_err <- function(msg) {
  if (grepl("time limit|elapsed time limit", msg, ignore.case = TRUE)) return("TIMEOUT")
  if (grepl("offset|Unused argument|unsupported term|treatment contrasts|contrasts attribute|ordered factor",
            msg, ignore.case = TRUE)) {
    return("REFUSED")
  }
  "ERROR"
}

# ---- offset ----
off_csv <- file.path(root, "results_offset_julia.csv")
if (file.exists(off_csv)) file.remove(off_csv)
write_off <- function(row) {
  df <- as.data.frame(row, stringsAsFactors = FALSE)
  exists <- file.exists(off_csv)
  utils::write.table(df, off_csv, sep = ",", row.names = FALSE, col.names = !exists,
                     append = exists, qmethod = "double")
  cat(sprintf("[offset] %s re=%s dpar=%s syn=%s -> %s\n",
              row$family, row$re, row$dpar, row$syntax, row$status))
  flush.console()
}

run_offset <- function(family, re, dpar, syntax) {
  d <- utils::read.csv(file.path(root, sprintf("data_offset_%s.csv", family)), stringsAsFactors = FALSE)
  d$g <- factor(d$g)
  d2 <- d
  d2$off <- d$off + log2
  fam <- switch(family,
    poisson = stats::poisson(link = "log"),
    nbinom2 = drmTMB::nbinom2(),
    gamma = stats::Gamma(link = "log")
  )
  re_term <- if (identical(re, "re")) " + (1 | g)" else ""
  form_txt <- if (identical(syntax, "offset_arg")) {
    if (family == "poisson" && identical(dpar, "mu")) sprintf("bf(y ~ x%s)", re_term)
    else sprintf("bf(y ~ x%s, sigma ~ 1)", re_term)
  } else if (identical(dpar, "mu")) {
    if (family == "poisson") sprintf("bf(y ~ x + offset(off)%s)", re_term)
    else sprintf("bf(y ~ x + offset(off)%s, sigma ~ 1)", re_term)
  } else {
    sprintf("bf(y ~ x%s, sigma ~ offset(off))", re_term)
  }
  form <- eval(parse(text = form_txt))
  fit_one <- function(dat) {
    if (identical(syntax, "offset_arg")) {
      drmTMB(form, family = fam, data = dat, engine = "julia", offset = dat$off)
    } else {
      drmTMB(form, family = fam, data = dat, engine = "julia")
    }
  }
  t0 <- proc.time()[["elapsed"]]
  r1 <- capture_err(fit_one(d))
  elapsed <- proc.time()[["elapsed"]] - t0
  row <- list(
    family = family, re = re, dpar = dpar, syntax = syntax, engine = "julia",
    status = "ERROR", intercept_base = NA_real_, intercept_shift = NA_real_,
    intercept_delta = NA_real_, expected = log2, abs_err = NA_real_,
    slope_max_diff = NA_real_, loglik_base = NA_real_, loglik_shift = NA_real_,
    loglik_delta = NA_real_, has_offset_coef = NA, elapsed_s = elapsed, note = ""
  )
  if (!r1$ok) {
    row$status <- classify_err(r1$error)
    row$note <- r1$error
    write_off(row)
    return(invisible(row))
  }
  r2 <- capture_err(fit_one(d2))
  row$elapsed_s <- proc.time()[["elapsed"]] - t0
  if (!r2$ok) {
    row$status <- classify_err(r2$error)
    row$note <- paste("shift-fit:", r2$error)
    write_off(row)
    return(invisible(row))
  }
  cf1 <- tryCatch(stats::coef(r1$value, "mu"), error = function(e) stats::coef(r1$value))
  cf2 <- tryCatch(stats::coef(r2$value, "mu"), error = function(e) stats::coef(r2$value))
  if (is.list(cf1)) cf1 <- cf1$mu
  if (is.list(cf2)) cf2 <- cf2$mu
  nms <- intersect(names(cf1), names(cf2))
  int_nm <- grep("Intercept", nms, value = TRUE)[1]
  if (is.na(int_nm) || !length(int_nm)) int_nm <- nms[1]
  slope_nms <- setdiff(nms, int_nm)
  row$intercept_base <- unname(cf1[[int_nm]])
  row$intercept_shift <- unname(cf2[[int_nm]])
  row$intercept_delta <- row$intercept_base - row$intercept_shift
  row$abs_err <- abs(row$intercept_delta - log2)
  row$slope_max_diff <- if (length(slope_nms)) max(abs(unname(cf1[slope_nms]) - unname(cf2[slope_nms]))) else 0
  row$loglik_base <- as.numeric(stats::logLik(r1$value))
  row$loglik_shift <- as.numeric(stats::logLik(r2$value))
  row$loglik_delta <- row$loglik_base - row$loglik_shift
  row$has_offset_coef <- any(grepl("offset", names(cf1), ignore.case = TRUE))
  row$note <- paste("coefs=", paste(names(cf1), collapse = "|"))
  if (isTRUE(row$has_offset_coef)) {
    row$status <- "FAIL"
    row$note <- paste(row$note, "SILENT_OFFSET_COEF")
  } else if (isTRUE(row$abs_err < pass_bar) && isTRUE(abs(row$loglik_delta) < 1e-6)) {
    row$status <- "PASS"
  } else {
    row$status <- "FAIL"
  }
  write_off(row)
  invisible(row)
}

cat("=== engine=julia offsets ===\n")
for (fam in c("poisson", "nbinom2", "gamma")) {
  for (re in c("fe", "re")) {
    for (dp in c("mu", "sigma")) {
      for (syn in c("formula", "offset_arg")) {
        run_offset(fam, re, dp, syn)
      }
    }
  }
}

# ---- contrasts ----
con_csv <- file.path(root, "results_contrasts_julia.csv")
if (file.exists(con_csv)) file.remove(con_csv)
write_con <- function(row) {
  df <- as.data.frame(row, stringsAsFactors = FALSE)
  exists <- file.exists(con_csv)
  utils::write.table(df, con_csv, sep = ",", row.names = FALSE, col.names = !exists,
                     append = exists, qmethod = "double")
  cat(sprintf("[contrasts] %s %s -> %s\n", row$family, row$coding, row$status))
  flush.console()
}

dcon <- utils::read.csv(file.path(root, "data_contrasts.csv"), stringsAsFactors = FALSE)
dcon$g <- ordered(dcon$g, levels = c("a", "b", "c", "d"))

run_con <- function(family, coding) {
  d <- dcon
  cm <- switch(coding,
    treatment = stats::contr.treatment(4),
    sum = stats::contr.sum(4),
    helmert = stats::contr.helmert(4),
    poly = stats::contr.poly(4)
  )
  stats::contrasts(d$g) <- cm
  d$y <- if (identical(family, "gaussian")) d$yg else d$yp
  t0 <- proc.time()[["elapsed"]]
  r <- if (identical(family, "gaussian")) {
    capture_err(drmTMB(bf(y ~ x + g, sigma ~ 1), family = stats::gaussian(), data = d, engine = "julia"))
  } else {
    capture_err(drmTMB(bf(y ~ x + g), family = stats::poisson(link = "log"), data = d, engine = "julia"))
  }
  elapsed <- proc.time()[["elapsed"]] - t0
  row <- list(
    family = family, coding = coding, engine = "julia", status = "ERROR",
    names_match = NA, max_coef_diff = NA_real_, max_fitted_vs_oracle = NA_real_,
    coef_names_drm = "", coef_names_oracle = "", elapsed_s = elapsed, note = ""
  )
  if (!r$ok) {
    row$status <- classify_err(r$error)
    row$note <- r$error
    write_con(row)
    return(invisible(row))
  }
  oracle <- if (identical(family, "gaussian")) stats::lm(y ~ x + g, data = d) else
    stats::glm(y ~ x + g, family = stats::poisson(link = "log"), data = d)
  cf <- tryCatch(stats::coef(r$value, "mu"), error = function(e) {
    c0 <- stats::coef(r$value); if (is.list(c0)) c0$mu else c0
  })
  if (is.list(cf)) cf <- cf$mu
  oc <- stats::coef(oracle)
  row$coef_names_drm <- paste(names(cf), collapse = "|")
  row$coef_names_oracle <- paste(names(oc), collapse = "|")
  row$names_match <- identical(names(cf), names(oc))
  row$max_coef_diff <- if (isTRUE(row$names_match)) max(abs(as.numeric(cf) - as.numeric(oc))) else NA_real_
  fv <- as.numeric(stats::fitted(r$value))
  ov <- as.numeric(stats::fitted(oracle))
  row$max_fitted_vs_oracle <- max(abs(fv - ov))
  coef_ok <- isTRUE(row$names_match) && isTRUE(row$max_coef_diff < 1e-6)
  fitted_ok <- isTRUE(row$max_fitted_vs_oracle < pass_bar)
  row$status <- if (coef_ok && fitted_ok) "PASS" else "FAIL"
  write_con(row)
  invisible(row)
}

cat("=== engine=julia contrasts ===\n")
for (fam in c("gaussian", "poisson")) {
  for (cod in c("treatment", "sum", "helmert", "poly")) {
    run_con(fam, cod)
  }
}

cat("done\n")
print(utils::read.csv(off_csv, stringsAsFactors = FALSE)[, c("family", "re", "dpar", "syntax", "status")])
print(utils::read.csv(con_csv, stringsAsFactors = FALSE)[, c("family", "coding", "status")])
