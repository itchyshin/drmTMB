## sweep-oct16 / t4: drmTMB fitter with a hard per-fit timeout.
## Usage: Rscript t4_fit_drmTMB.R [data_dir] [out_prefix] [cell_or_all] [timeout_sec]
## A hang becomes a TIMEOUT row (never stalls the cell). Incremental CSV so a
## kill loses at most the in-flight row. Resume: already-written files are skipped.
suppressPackageStartupMessages(library(drmTMB))
options(mc.cores = 1L)
Sys.setenv(OMP_NUM_THREADS = "1", MKL_NUM_THREADS = "1")

args <- commandArgs(trailingOnly = TRUE)
ddir <- if (length(args) >= 1) args[1] else "sweep-oct16/t4/data"
outp <- if (length(args) >= 2) args[2] else "sweep-oct16/t4/results/fits_drmTMB"
want <- if (length(args) >= 3) args[3] else "all"
timeout_sec <- if (length(args) >= 4) as.numeric(args[4]) else 60

idx <- read.csv(file.path(ddir, "index.csv"), stringsAsFactors = FALSE)
if (!identical(want, "all")) idx <- idx[idx$cell == want, , drop = FALSE]
stopifnot(nrow(idx) > 0)

t4_call <- function(cell, d) {
  switch(sub("_n[0-9]+(_lowmean)?$", "", cell),
    gauss = drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d),
    pois  = drmTMB(bf(y ~ x), family = poisson(), data = d),
    bin_complete = , bin_quasi = drmTMB(bf(y ~ x), family = binomial(), data = d),
    nb2_poisdata = drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d),
    beta_phi1e4  = drmTMB(bf(y ~ x, sigma ~ 1), family = beta_family(), data = d),
    student_gaussdata = drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = d),
    "re_sd1e-4" = drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = d),
    collin_sigma_exact = , collin_sigma_near =
      drmTMB(bf(y ~ x, sigma ~ x + z), family = gaussian(), data = d),
    stop("unknown cell ", cell))
}

## Hard timeout: fork the fit, SIGKILL if it exceeds timeout_sec.
## TMB C++ will not honour setTimeLimit(); an OS kill is the hang detector.
fit_with_timeout <- function(cell, d, timeout_sec) {
  warns <- character(); msgs <- character(); err <- NA_character_
  timed_out <- FALSE
  t0 <- proc.time()[["elapsed"]]
  job <- parallel::mcparallel({
    withCallingHandlers(
      t4_call(cell, d),
      warning = function(w) {
        warns <<- c(warns, conditionMessage(w))
        invokeRestart("muffleWarning")
      },
      message = function(m) {
        msgs <<- c(msgs, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    )
  }, silent = TRUE)
  fit <- NULL
  repeat {
    res <- parallel::mccollect(job, wait = FALSE)
    if (!is.null(res)) {
      val <- res[[1]]
      if (inherits(val, "try-error")) {
        err <- as.character(val)
      } else if (is.null(val)) {
        err <- "fit returned NULL"
      } else {
        fit <- val
      }
      break
    }
    if (proc.time()[["elapsed"]] - t0 > timeout_sec) {
      timed_out <- TRUE
      err <- sprintf("TIMEOUT after %.0fs", timeout_sec)
      try(tools::pskill(job$pid, tools::SIGKILL), silent = TRUE)
      Sys.sleep(0.05)
      parallel::mccollect(job, wait = FALSE)
      break
    }
    Sys.sleep(0.05)
  }
  list(fit = fit, warnings = unique(warns), messages = unique(msgs),
       error = err, secs = proc.time()[["elapsed"]] - t0, timeout = timed_out)
}

collapse <- function(x, digits = 10) {
  if (is.null(x) || !length(x)) "" else
    paste(paste0(names(x), "=", formatC(unname(x), digits = digits, format = "g")),
          collapse = ";")
}

drm_extract <- function(cap) {
  fit <- cap$fit
  base <- list(
    fitted = !is.null(fit),
    timeout = isTRUE(cap$timeout),
    error = if (is.na(cap$error)) "" else cap$error,
    secs = cap$secs,
    warnings = paste(cap$warnings, collapse = " || "),
    messages = paste(cap$messages, collapse = " || ")
  )
  na_row <- function() {
    c(base, list(
      converged = NA, converged_hess = NA, status = NA_character_,
      opt_code = NA_integer_, opt_message = NA_character_,
      preset = NA_character_, logLik = NA_real_, df = NA_real_,
      coef = "", se = "", n_se = NA_integer_, n_se_nonfinite = NA_integer_,
      max_se = NA_real_, vcov_error = NA_character_, pdHess = NA,
      max_grad = NA_real_, re_sd = NA_real_, re_sd_se = NA_real_,
      check_ok = NA, check_warn = "", check_note = ""
    ))
  }
  if (is.null(fit)) return(na_row())
  safe <- function(expr, default = NA) tryCatch(expr, error = function(e) default)
  cf <- tryCatch({
    fe <- fixef(fit)
    unlist(lapply(names(fe), function(dp) {
      v <- fe[[dp]]; setNames(v, paste0(dp, ":", names(v)))
    }))
  }, error = function(e) numeric())
  vc_err <- NA_character_
  V <- tryCatch(stats::vcov(fit), error = function(e) {
    vc_err <<- conditionMessage(e); NULL
  })
  se <- if (is.null(V) || !length(cf)) {
    setNames(rep(NA_real_, length(cf)), names(cf))
  } else {
    s <- suppressWarnings(sqrt(diag(V)))
    s[names(cf)]
  }
  pars <- safe(summary(fit)$parameters, NULL)
  re <- if (!is.null(pars) && is.data.frame(pars) && "component" %in% names(pars)) {
    pars[pars$component == "random-effect-sd", , drop = FALSE]
  } else NULL
  chk <- safe(check_drm(fit), NULL)
  flags <- function(st) {
    if (is.null(chk) || !is.data.frame(chk)) "" else {
      b <- chk[chk$status %in% st, , drop = FALSE]
      if (nrow(b)) paste0(b$check, "=", b$status, collapse = "; ") else ""
    }
  }
  ll <- safe(as.numeric(stats::logLik(fit)), NA_real_)
  c(base, list(
    converged = isTRUE(safe(is_converged(fit), FALSE)),
    converged_hess = isTRUE(safe(is_converged(fit, include_hessian = TRUE), FALSE)),
    status = safe(as.character(convergence_status(fit)), NA_character_),
    opt_code = safe(as.integer(fit$opt$convergence), NA_integer_),
    opt_message = safe(as.character(fit$opt$message), NA_character_),
    preset = safe(as.character(fit$optimizer_used$optimizer_preset), NA_character_),
    logLik = ll,
    df = safe(as.numeric(attr(stats::logLik(fit), "df")), NA_real_),
    coef = collapse(cf),
    se = collapse(se, 6),
    n_se = length(se),
    n_se_nonfinite = sum(!is.finite(se)),
    max_se = if (any(is.finite(se))) max(se[is.finite(se)]) else NA_real_,
    vcov_error = vc_err,
    pdHess = isTRUE(fit$sdr$pdHess),
    max_grad = safe(max(abs(fit$gradient)), NA_real_),
    re_sd = if (!is.null(re) && nrow(re)) re$estimate[1] else NA_real_,
    re_sd_se = if (!is.null(re) && nrow(re)) re$std_error[1] else NA_real_,
    check_ok = if (is.null(chk)) NA else isTRUE(attr(chk, "ok")),
    check_warn = flags(c("warning", "error")),
    check_note = flags("note")
  ))
}

dir.create(dirname(outp), recursive = TRUE, showWarnings = FALSE)
csv_path <- paste0(outp, ".csv")
done_files <- character()
if (file.exists(csv_path)) {
  old <- tryCatch(read.csv(csv_path, stringsAsFactors = FALSE), error = function(e) NULL)
  if (!is.null(old) && "file" %in% names(old)) done_files <- as.character(old$file)
}

n_todo <- sum(!idx$file %in% done_files)
cat(format(Sys.time()), "drmTMB fitter: ", n_todo, " of ", nrow(idx),
    " remaining (timeout=", timeout_sec, "s)\n", sep = "")

header_written <- file.exists(csv_path) && length(done_files) > 0
for (i in seq_len(nrow(idx))) {
  row <- idx[i, ]
  if (row$file %in% done_files) next
  d <- read.csv(file.path(ddir, row$file), stringsAsFactors = FALSE)
  if ("g" %in% names(d)) d$g <- factor(d$g)
  cap <- tryCatch(
    fit_with_timeout(row$cell, d, timeout_sec),
    error = function(e) {
      list(fit = NULL, warnings = character(), messages = character(),
           error = conditionMessage(e), secs = NA_real_, timeout = FALSE)
    }
  )
  ex <- drm_extract(cap)
  ex <- lapply(ex, function(v) {
    if (is.null(v) || length(v) == 0) NA else v
  })
  out <- data.frame(row[, c("k", "cell", "rep", "nominal_seed", "r_seed", "file", "n")],
                    ex, stringsAsFactors = FALSE, check.names = FALSE)
  write.table(out, csv_path, sep = ",", row.names = FALSE, col.names = !header_written,
              append = header_written, qmethod = "double")
  header_written <- TRUE
  if (i %% 10 == 0 || isTRUE(ex$timeout) || (is.character(ex$error) && nzchar(ex$error) && !is.na(ex$error))) {
    cat(format(Sys.time()), " ", row$cell, " r", row$rep,
        " conv=", ex$converged, " timeout=", ex$timeout,
        " secs=", round(as.numeric(ex$secs), 2), "\n", sep = "")
  }
}

si <- paste0(outp, "_sessionInfo.txt")
writeLines(capture.output(sessionInfo()), si)
cat("wrote", csv_path, "\n")
