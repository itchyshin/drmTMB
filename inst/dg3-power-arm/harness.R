# DG3 quantified power-arm harness (Curie, 2026-07-12; verification-spec.md
# Sec "DG3 -- behavioural recovery + honest power arm").
#
# Generic, family-agnostic machinery: given a "family spec" (an Arm-A
# correctly-specified DGP+fit, and >=2 named Arm-B mis-specifications, each a
# DGP + a correctly-specified fit + a mis-specified fit), this file runs a
# seed grid, computes a robust adequacy statistic from
# residuals(fit, type = "quantile"), and STREAMS one row per fit to a TSV
# (flush()ed immediately) plus a heartbeat line to a companion .log -- per the
# 2026-07-05 empty-60-min-run lesson: a stop/crash must leave partial
# evidence behind, never nothing.
#
# Statistic (Fisher's flag: the worm-plot cubic-R^2 is too noisy for a
# go/no-go call): combine two INDEPENDENT checks of "residuals ~ N(0,1)" via
# Fisher's combined-p method, both computed from the SAME
# residuals(type = "quantile") draw:
#   1. Kolmogorov-Smirnov (ks.test(r, "pnorm")) -- an EDF-distance check.
#   2. A PIT-histogram chi-square uniformity test (10 equal-width bins of
#      pnorm(r), the classic Dawid/Gneiting PIT diagnostic) -- a BINNED
#      density-shape check, independent of KS's construction, so the two
#      catch different departures.
# combined_stat = -2 * (log(p_ks) + log(p_chisq)); combined_stat ~ chi-sq(4)
# under both nulls independently uniform; combined_p = pchisq(..., 4,
# lower.tail = FALSE); reject when combined_p < alpha. This is the classical
# Fisher's method for combining independent p-values -- not novel, not tuned,
# and not the noisy regression-R^2 statistic Fisher flagged.
#
# Per-family specs live in families.R (sourced separately); this file has NO
# family-specific code, so the SAME harness runs any family that supplies a
# spec of the documented shape (see families.R's header comment for the
# exact contract).
#
# Gate: this file is NEVER sourced by the package itself and never runs
# under `R CMD check`/`devtools::test()` -- it is invoked explicitly via
# `Rscript` with NOT_CRAN=true, exactly like the existing
# docs/dev-log/simulation-artifacts/*/*.R streaming runners. run-toy-pass.R
# (the driver) enforces the NOT_CRAN=true gate explicitly.

# ---- adequacy statistic ----------------------------------------------------

#' Fisher-combined KS + PIT-chi-square adequacy statistic for one residual
#' vector. `r` is the output of residuals(fit, type = "quantile", ...);
#' non-finite entries (masked missing responses) are dropped first.
dg3_adequacy_stat <- function(r, nbin = 10L) {
  r <- r[is.finite(r)]
  n <- length(r)
  if (n < 20L) {
    return(list(
      n = n, ks_stat = NA_real_, ks_p = NA_real_,
      chisq_stat = NA_real_, chisq_p = NA_real_, combined_p = NA_real_
    ))
  }
  ks <- suppressWarnings(stats::ks.test(r, "pnorm"))
  u <- stats::pnorm(r)
  breaks <- seq(0, 1, length.out = nbin + 1L)
  bin <- findInterval(u, breaks, rightmost.closed = TRUE, all.inside = TRUE)
  counts <- tabulate(bin, nbins = nbin)
  chisq <- suppressWarnings(stats::chisq.test(counts, p = rep(1 / nbin, nbin)))
  ks_p <- ks$p.value
  chisq_p <- chisq$p.value
  # guard against exact-0 p-values (log(0) = -Inf) before Fisher's method
  ks_p_g <- max(ks_p, 1e-300)
  chisq_p_g <- max(chisq_p, 1e-300)
  combined_stat <- -2 * (log(ks_p_g) + log(chisq_p_g))
  combined_p <- stats::pchisq(combined_stat, df = 4, lower.tail = FALSE)
  list(
    n = n,
    ks_stat = unname(ks$statistic), ks_p = ks_p,
    chisq_stat = unname(chisq$statistic), chisq_p = chisq_p,
    combined_p = combined_p
  )
}

# ---- one fit + diagnose ----------------------------------------------------

# Fits `fit_fn(dat)`, computes residuals(type = "quantile") (fixed seed for
# discrete/atom-family Dunn-Smyth randomization), and the adequacy statistic.
# Never throws: fit or residual failures are captured as ok = FALSE rows so a
# family-level bug shows up as data, not a crashed run.
dg3_fit_and_diagnose <- function(dat, fit_fn, response = NULL, resid_seed = NULL) {
  t0 <- Sys.time()
  fit <- tryCatch(fit_fn(dat), error = function(e) e, warning = function(w) w)
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  if (inherits(fit, "condition")) {
    return(list(
      ok = FALSE, elapsed = el, error = conditionMessage(fit),
      n = NA_real_, ks_stat = NA_real_, ks_p = NA_real_,
      chisq_stat = NA_real_, chisq_p = NA_real_, combined_p = NA_real_
    ))
  }
  r <- tryCatch(
    residuals(fit, type = "quantile", seed = resid_seed, response = response),
    error = function(e) e
  )
  if (inherits(r, "condition")) {
    return(list(
      ok = FALSE, elapsed = el, error = paste("residuals:", conditionMessage(r)),
      n = NA_real_, ks_stat = NA_real_, ks_p = NA_real_,
      chisq_stat = NA_real_, chisq_p = NA_real_, combined_p = NA_real_
    ))
  }
  stat <- dg3_adequacy_stat(r)
  c(list(ok = TRUE, elapsed = el, error = NA_character_), stat)
}

# ---- streaming I/O ----------------------------------------------------------

dg3_tsv_cols <- c(
  "family", "arm", "role", "seed", "n", "ok", "n_resid",
  "ks_stat", "ks_p", "chisq_stat", "chisq_p", "combined_p", "reject",
  "elapsed_s", "error"
)

dg3_write_header <- function(tsv) {
  if (!file.exists(tsv)) {
    cat(paste(dg3_tsv_cols, collapse = "\t"), "\n", file = tsv)
  }
}

dg3_stream_row <- function(tsv, family, arm, role, seed, n, res, alpha = 0.05) {
  reject <- if (isTRUE(res$ok) && is.finite(res$combined_p)) {
    res$combined_p < alpha
  } else {
    NA
  }
  row <- c(
    family, arm, role, seed, n, res$ok, res$n,
    round(res$ks_stat, 4), signif(res$ks_p, 4),
    round(res$chisq_stat, 4), signif(res$chisq_p, 4), signif(res$combined_p, 4),
    reject, round(res$elapsed, 3),
    if (is.na(res$error)) "" else gsub("[\t\n]", " ", res$error)
  )
  cat(paste(row, collapse = "\t"), "\n", file = tsv, append = TRUE)
  flush(stdout())
  invisible(NULL)
}

dg3_heartbeat <- function(log_file, fmt, ...) {
  msg <- sprintf(fmt, ...)
  cat(msg, file = log_file, append = TRUE)
  cat(msg)
  flush(stdout())
  invisible(NULL)
}

# ---- per-family runner ------------------------------------------------------

#' Run one family's Arm A + Arm B mis-specs over a seed grid, streaming every
#' fit's result immediately.
#'
#' `spec` contract (see families.R for worked examples):
#'   spec$name        -- character, used as the output file stem.
#'   spec$n           -- design sample size.
#'   spec$arm_a       -- list(dgp = function(seed, n), fit = function(dat),
#'                        response = NULL | 1L | 2L).
#'   spec$mis_specs   -- list of list(name = , dgp = function(seed, n),
#'                        fit_true = function(dat) | NULL,
#'                        fit_wrong = function(dat), response = ).
#'                        fit_true = NULL is allowed when no matching
#'                        "correctly specified" alternative exists in the
#'                        package for that mis-spec (documented per-case in
#'                        families.R); only fit_wrong's rejection rate is
#'                        then reported (a single-arm power number).
dg3_run_family <- function(spec, seeds, out_dir, alpha = 0.05) {
  tsv <- file.path(out_dir, paste0(spec$name, ".tsv"))
  log_file <- file.path(out_dir, paste0(spec$name, ".log"))
  dg3_write_header(tsv)
  dg3_heartbeat(log_file, "=== %s: start %s (n=%d, %d seeds) ===\n",
    spec$name, format(Sys.time()), spec$n, length(seeds))

  for (seed in seeds) {
    dat_a <- spec$arm_a$dgp(seed, spec$n)
    res_a <- dg3_fit_and_diagnose(
      dat_a, spec$arm_a$fit,
      response = spec$arm_a$response, resid_seed = seed
    )
    dg3_stream_row(tsv, spec$name, "A", "true", seed, spec$n, res_a, alpha)
    dg3_heartbeat(
      log_file, "[%s] armA seed=%d ok=%s combined_p=%s (%.2fs)\n",
      spec$name, seed, res_a$ok,
      if (is.finite(res_a$combined_p)) sprintf("%.3f", res_a$combined_p) else "NA",
      res_a$elapsed
    )

    for (ms in spec$mis_specs) {
      dat_m <- ms$dgp(seed, spec$n)
      if (!is.null(ms$fit_true)) {
        res_true <- dg3_fit_and_diagnose(
          dat_m, ms$fit_true,
          response = ms$response, resid_seed = seed
        )
        dg3_stream_row(tsv, spec$name, ms$name, "true", seed, spec$n, res_true, alpha)
      }
      res_wrong <- dg3_fit_and_diagnose(
        dat_m, ms$fit_wrong,
        response = ms$response, resid_seed = seed
      )
      dg3_stream_row(tsv, spec$name, ms$name, "wrong", seed, spec$n, res_wrong, alpha)
      dg3_heartbeat(
        log_file, "[%s] %s seed=%d wrong: ok=%s combined_p=%s (%.2fs)\n",
        spec$name, ms$name, seed, res_wrong$ok,
        if (is.finite(res_wrong$combined_p)) sprintf("%.3f", res_wrong$combined_p) else "NA",
        res_wrong$elapsed
      )
    }
  }
  dg3_heartbeat(log_file, "=== %s: done %s ===\n", spec$name, format(Sys.time()))
  invisible(tsv)
}

# ---- summary ----------------------------------------------------------------

#' Type-I rate (Arm A, role = "true") and power (each mis-spec, role =
#' "wrong") from one family's streamed TSV. `ok == FALSE` rows (fit/residual
#' failures) are reported separately as a failure rate, not silently dropped
#' from the denominator or silently counted as non-rejections.
dg3_summarize <- function(tsv) {
  d <- utils::read.delim(tsv, stringsAsFactors = FALSE)
  d$reject <- as.logical(d$reject)
  d$ok <- as.logical(d$ok)
  by_arm <- split(d, paste(d$arm, d$role))
  out <- do.call(rbind, lapply(names(by_arm), function(k) {
    g <- by_arm[[k]]
    data.frame(
      family = g$family[1], arm = g$arm[1], role = g$role[1],
      n_seed = nrow(g), n_ok = sum(g$ok, na.rm = TRUE),
      n_fail = sum(!g$ok, na.rm = TRUE),
      rejection_rate = mean(g$reject, na.rm = TRUE)
    )
  }))
  out[order(out$arm, out$role), , drop = FALSE]
}
