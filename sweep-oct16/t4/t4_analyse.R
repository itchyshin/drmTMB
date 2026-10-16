## sweep-oct16 / t4: classify every fit against the pass bar; cross-engine flag agreement.
## Pass bar: every fit either converged with finite logLik, SEs and a correct flag,
## or a clear error/warning; never converged=TRUE with a silent wrong answer;
## R and Julia agree on the flag.
args <- commandArgs(trailingOnly = TRUE)
res_dir <- if (length(args) >= 1) args[1] else "sweep-oct16/t4/results"
Rpath <- file.path(res_dir, "fits_drmTMB.csv")
Jpath <- file.path(res_dir, "fits_DRModels.csv")
stopifnot(file.exists(Rpath), file.exists(Jpath))

R <- read.csv(Rpath, stringsAsFactors = FALSE, na.strings = c("NA", ""))
J <- read.csv(Jpath, stringsAsFactors = FALSE, na.strings = c("NA", ""))
for (v in intersect(c("fitted", "timeout", "converged", "converged_raw", "converged_hess",
                      "pdHess", "check_ok", "vcov_all_finite", "check_vcov_posdef"), names(R))) {
  R[[v]] <- as.logical(R[[v]])
}
for (v in intersect(c("fitted", "timeout", "converged", "converged_raw", "check_ok",
                      "vcov_all_finite", "check_vcov_posdef"), names(J))) {
  J[[v]] <- as.logical(J[[v]])
}
blank <- function(x) {
  x[is.na(x)] <- ""
  x
}
R$error <- blank(R$error); R$warnings <- blank(R$warnings)
R$check_warn <- if ("check_warn" %in% names(R)) blank(R$check_warn) else ""
R$status <- if ("status" %in% names(R)) blank(R$status) else ""
J$error <- blank(J$error); J$warnings <- blank(J$warnings)
J$check_warnings <- if ("check_warnings" %in% names(J)) blank(J$check_warnings) else ""
J$check_variance_boundary <- if ("check_variance_boundary" %in% names(J)) blank(J$check_variance_boundary) else ""

## Expected regime from the cell name (not from the fit).
regime_of <- function(cell) {
  if (grepl("^bin_complete|^bin_quasi", cell)) "nonexistent"
  else if (cell == "collin_sigma_exact") "aliased"
  else if (cell %in% c("nb2_poisdata", "beta_phi1e4", "student_gaussdata", "re_sd1e-4")) "boundary"
  else if (cell == "pois_n8_lowmean") "maybe_nonexistent"
  else "interior"
}

SE_HUGE <- 50          # same order as check_standard_errors_inflated
TOL_LL <- 1e-3         # material logLik disagreement between engines (nats)

classify_one <- function(f, engine) {
  f$engine <- engine
  f$regime <- vapply(f$cell, regime_of, "")
  f$warned <- nzchar(f$warnings)
  f$errored <- !isTRUE(f$fitted) | nzchar(f$error)
  f$timeout <- isTRUE(f$timeout)
  f$se_ok <- !is.na(f$n_se_nonfinite) & f$n_se_nonfinite == 0 &
    (is.na(f$max_se) | f$max_se < SE_HUGE)
  f$diag_flag <- if (engine == "drmTMB") {
    nzchar(f$check_warn) | f$status %in% c("boundary", "degenerate") | isTRUE(f$timeout)
  } else {
    !isTRUE(f$check_ok) | nzchar(f$check_variance_boundary) | nzchar(f$check_warnings) |
      isTRUE(f$timeout)
  }
  f$signal <- f$errored | !isTRUE(f$converged) | f$warned | isTRUE(f$timeout)
  f$ll_finite <- is.finite(f$logLik)
  f$verdict <- NA_character_
  for (i in seq_len(nrow(f))) {
    x <- f[i, ]
    v <- NA_character_
    if (isTRUE(x$timeout)) {
      v <- "TIMEOUT"
    } else if (isTRUE(x$errored) && !isTRUE(x$fitted)) {
      v <- "ERROR"
    } else if (x$regime == "nonexistent") {
      v <- if (!isTRUE(x$converged) || x$warned || x$diag_flag) "PASS_flagged" else "SILENT_NONEXIST"
    } else if (x$regime == "aliased") {
      v <- if (!isTRUE(x$converged) || x$warned || x$diag_flag || !isTRUE(x$se_ok)) {
        if (isTRUE(x$converged) && !x$warned && !x$diag_flag) "SILENT_ALIAS" else "PASS_flagged"
      } else "SILENT_ALIAS"
    } else if (x$regime == "maybe_nonexistent") {
      ## Poisson n=8 low mean: some reps have no MLE (all-zero / extreme-x).
      ## Huge SEs or non-finite SEs with converged=TRUE and no warning = silent.
      if (!isTRUE(x$converged) || x$warned || x$diag_flag) {
        v <- "PASS_flagged"
      } else if (!isTRUE(x$se_ok) || (is.finite(x$max_se) && x$max_se >= SE_HUGE)) {
        v <- "SILENT_NONEXIST"
      } else {
        v <- "PASS"
      }
    } else if (isTRUE(x$converged)) {
      if (!isTRUE(x$ll_finite)) {
        v <- if (x$warned) "WARNED_WRONG" else "SILENT_WRONG"
      } else if (!isTRUE(x$se_ok) && !x$warned && !x$diag_flag) {
        v <- if (x$regime == "boundary") "SILENT_BOUNDARY_SE" else "SILENT_SE"
      } else if (x$regime == "boundary") {
        v <- if (x$warned) "PASS_boundary_warned" else if (x$diag_flag) "PASS_boundary_diag_only" else "SILENT_BOUNDARY"
      } else {
        v <- if (x$warned) "PASS_warned" else "PASS"
      }
    } else {
      v <- if (isTRUE(x$ll_finite) && x$regime == "interior" && isTRUE(x$se_ok)) "FALSE_ALARM" else "PASS_flagged"
    }
    ## collinear exact: se_ok false is the expected geometry; still a fail if silent.
    if (x$regime == "aliased" && isTRUE(x$converged) && !x$warned && !x$diag_flag) {
      v <- "SILENT_ALIAS"
    }
    f$verdict[i] <- v
  }
  f
}

cR <- classify_one(R, "drmTMB")
cJ <- classify_one(J, "DRModels.jl")

keep <- c("engine", "k", "cell", "rep", "file", "regime", "fitted", "timeout",
          "converged", "warned", "diag_flag", "signal", "se_ok", "logLik",
          "max_se", "verdict", "warnings", "error")
keepR <- intersect(keep, names(cR)); keepJ <- intersect(keep, names(cJ))
cls <- rbind(cR[, keepR], cJ[, keepJ])
cls <- cls[order(cls$engine, cls$k, cls$rep), ]
write.csv(cls, file.path(res_dir, "classified.csv"), row.names = FALSE)

x <- merge(
  cR[, c("file", "k", "cell", "rep", "regime", "converged", "signal", "logLik", "verdict", "max_se", "se_ok")],
  cJ[, c("file", "converged", "signal", "logLik", "verdict", "max_se", "se_ok")],
  by = "file", suffixes = c(".R", ".J")
)
x$flag_agree <- x$converged.R == x$converged.J | (is.na(x$converged.R) & is.na(x$converged.J))
x$signal_agree <- x$signal.R == x$signal.J
x$ll_diff <- x$logLik.R - x$logLik.J
write.csv(x[order(x$k, x$rep), ], file.path(res_dir, "cross_engine.csv"), row.names = FALSE)

silent_v <- function(v) grepl("^SILENT_", v)
cells <- unique(cls[order(cls$k), c("k", "cell")])
md <- c(
  "# t4 edge-case grid: per-cell summary",
  "",
  "Pass bar: every fit either converged with finite logLik, SEs and a correct flag, or a clear error/warning; never `converged=TRUE` with a silent wrong answer; R and Julia agree on the flag.",
  ""
)
md <- c(md, "| cell | drmTMB verdicts | DRModels.jl verdicts | conv R/J | flag agree | signal agree | max |dlogLik| |",
        "|---|---|---|---|---|---|---|")
vtab <- function(cc, eng) {
  d <- cls[cls$cell == cc & cls$engine == eng, ]
  t <- table(d$verdict)
  paste(sprintf("%s %d", names(t), t), collapse = ", ")
}
for (i in seq_len(nrow(cells))) {
  cc <- cells$cell[i]; xx <- x[x$cell == cc, ]
  md <- c(md, sprintf(
    "| %s | %s | %s | %d / %d | %d/%d | %d/%d | %.3g |",
    cc, vtab(cc, "drmTMB"), vtab(cc, "DRModels.jl"),
    sum(xx$converged.R, na.rm = TRUE), sum(xx$converged.J, na.rm = TRUE),
    sum(xx$flag_agree, na.rm = TRUE), nrow(xx),
    sum(xx$signal_agree, na.rm = TRUE), nrow(xx),
    suppressWarnings(max(abs(xx$ll_diff[is.finite(xx$ll_diff)])))
  ))
}

md <- c(md, "", "## Pass bar per cell and engine", "",
        "| cell | engine | n | silent | false alarm | timeout/error | verdict | flag agree R/J |",
        "|---|---|---|---|---|---|---|---|")
for (i in seq_len(nrow(cells))) for (eng in c("drmTMB", "DRModels.jl")) {
  cc <- cells$cell[i]
  d <- cls[cls$cell == cc & cls$engine == eng, ]
  n <- nrow(d)
  silent <- sum(silent_v(d$verdict))
  fa <- sum(d$verdict == "FALSE_ALARM")
  te <- sum(d$verdict %in% c("TIMEOUT", "ERROR"))
  cell_verdict <- if (silent > 0) "FAIL (silent wrong)" else if (fa > 0) "flag disagrees with geometry" else if (te > 0) "timeout/error (flagged)" else "pass"
  md <- c(md, sprintf(
    "| %s | %s | %d | %d | %d | %d | %s | %s |",
    cc, eng, n, silent, fa, te, cell_verdict,
    if (eng == "drmTMB") sprintf("%d/%d", sum(x$flag_agree[x$cell == cc], na.rm = TRUE), sum(x$cell == cc)) else ""
  ))
}

## Cross-engine flag disagreements
disagree <- x[!x$flag_agree & !is.na(x$flag_agree), ]
md <- c(md, "", sprintf("## Flag disagreements: %d of %d datasets", nrow(disagree), nrow(x)), "")
if (nrow(disagree)) {
  tab <- table(disagree$cell)
  md <- c(md, paste(sprintf("- %s: %d", names(tab), tab), collapse = "\n"), "")
}

writeLines(md, file.path(res_dir, "summary.md"))
cat(md, sep = "\n")
cat("\nwrote", file.path(res_dir, "classified.csv"), "and summary.md\n")
