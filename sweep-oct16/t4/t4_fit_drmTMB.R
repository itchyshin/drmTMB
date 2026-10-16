## sweep-oct16 / t4: drmTMB fitter. One row per dataset -> results/fits_drmTMB.csv (+ .rds)
## Usage: Rscript t4_fit_drmTMB.R [data_dir] [out_prefix]
suppressPackageStartupMessages(library(drmTMB))
args <- commandArgs(trailingOnly = TRUE)
ddir <- if (length(args) >= 1) args[1] else "sweep-oct16/t4/data"
outp <- if (length(args) >= 2) args[2] else "sweep-oct16/t4/results/fits_drmTMB"
idx <- read.csv(file.path(ddir, "index.csv"), stringsAsFactors = FALSE)

t4_call <- function(cell, d) {
  switch(sub("_n[0-9]+(_lowmean)?$", "", cell),
    gauss = drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d),
    pois  = drmTMB(bf(y ~ x), family = poisson(), data = d),
    bin_complete = , bin_quasi = drmTMB(bf(y ~ x), family = binomial(), data = d),
    nb2_poisdata = drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d),
    beta_phi1e4  = drmTMB(bf(y ~ x, sigma ~ 1), family = beta_family(), data = d),
    student_gaussdata = drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = d),
    "re_sd1e-4" = drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = d),
    collin_sigma_exact = , collin_sigma_near = drmTMB(bf(y ~ x, sigma ~ x + z), family = gaussian(), data = d),
    stop("unknown cell ", cell))
}

fit_capture <- function(expr) {
  warns <- character(); msgs <- character(); err <- NA_character_
  t0 <- proc.time()[["elapsed"]]
  fit <- withCallingHandlers(
    tryCatch(expr, error = function(e) { err <<- conditionMessage(e); NULL }),
    warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") },
    message = function(m) { msgs <<- c(msgs, conditionMessage(m)); invokeRestart("muffleMessage") })
  list(fit = fit, warnings = warns, messages = msgs, error = err, secs = proc.time()[["elapsed"]] - t0)
}
collapse <- function(x, digits = 10) if (is.null(x) || !length(x)) "" else
  paste(paste0(names(x), "=", formatC(unname(x), digits = digits, format = "g")), collapse = ";")

drm_extract <- function(cap) {
  fit <- cap$fit
  base <- list(fitted = !is.null(fit), error = cap$error, secs = cap$secs,
               warnings = paste(unique(cap$warnings), collapse = " || "),
               messages = paste(unique(cap$messages), collapse = " || "))
  if (is.null(fit)) return(base)
  safe <- function(expr, default = NA) tryCatch(expr, error = function(e) default)
  cf <- unlist(lapply(names(fixef(fit)), function(dp) { v <- fixef(fit)[[dp]]; setNames(v, paste0(dp, ":", names(v))) }))
  vc_err <- NA_character_
  V <- tryCatch(stats::vcov(fit), error = function(e) { vc_err <<- conditionMessage(e); NULL })
  se <- if (is.null(V)) setNames(rep(NA_real_, length(cf)), names(cf)) else { s <- suppressWarnings(sqrt(diag(V))); s[names(cf)] }
  pars <- safe(summary(fit)$parameters, NULL)
  re <- if (!is.null(pars) && "component" %in% names(pars)) pars[pars$component == "random-effect-sd", , drop = FALSE] else NULL
  chk <- safe(check_drm(fit), NULL)
  flags <- function(st) if (is.null(chk)) NA_character_ else {
    b <- chk[chk$status %in% st, , drop = FALSE]; if (nrow(b)) paste0(b$check, "=", b$status, collapse = "; ") else "" }
  c(base, list(
    converged = isTRUE(is_converged(fit)),
    converged_hess = isTRUE(safe(is_converged(fit, include_hessian = TRUE), NA)),
    status = safe(convergence_status(fit), NA_character_),
    opt_code = as.integer(fit$opt$convergence), opt_message = fit$opt$message,
    preset = safe(as.character(fit$optimizer_used$optimizer_preset), NA_character_),
    logLik = as.numeric(stats::logLik(fit)), df = attr(stats::logLik(fit), "df"),
    coef = collapse(cf), se = collapse(se, 6),
    n_se = length(se), n_se_nonfinite = sum(!is.finite(se)), max_se = suppressWarnings(max(se[is.finite(se)])),
    vcov_error = vc_err, pdHess = isTRUE(fit$sdr$pdHess),
    max_grad = safe(max(abs(fit$gradient))),
    re_sd = if (!is.null(re) && nrow(re)) re$estimate[1] else NA_real_,
    re_sd_se = if (!is.null(re) && nrow(re)) re$std_error[1] else NA_real_,
    check_ok = if (is.null(chk)) NA else isTRUE(attr(chk, "ok")),
    check_warn = flags(c("warning", "error")), check_note = flags("note")))
}

rows <- vector("list", nrow(idx))
for (i in seq_len(nrow(idx))) {
  row <- idx[i, ]
  d <- read.csv(file.path(ddir, row$file))
  if ("g" %in% names(d)) d$g <- factor(d$g)
  cap <- fit_capture(t4_call(row$cell, d))
  ex <- drm_extract(cap)
  ex <- lapply(ex, function(v) if (is.null(v) || length(v) == 0) NA else v)
  rows[[i]] <- data.frame(row[, c("k", "cell", "rep", "nominal_seed", "r_seed", "file", "n")], ex,
                          stringsAsFactors = FALSE, check.names = FALSE)
  if (i %% 50 == 0) cat(format(Sys.time()), i, "of", nrow(idx), "\n")
}
all_names <- unique(unlist(lapply(rows, names)))
rows <- lapply(rows, function(r) { for (nm in setdiff(all_names, names(r))) r[[nm]] <- NA; r[all_names] })
res <- do.call(rbind, rows)
dir.create(dirname(outp), recursive = TRUE, showWarnings = FALSE)
write.csv(res, paste0(outp, ".csv"), row.names = FALSE)
saveRDS(res, paste0(outp, ".rds"))
writeLines(capture.output(sessionInfo()), paste0(outp, "_sessionInfo.txt"))
cat("wrote", nrow(res), "rows\n")
