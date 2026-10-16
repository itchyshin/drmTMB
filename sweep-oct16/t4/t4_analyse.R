## sweep-oct16 / t4: classify every fit against the pass bar; cross-engine flag agreement.
## Inputs: results/reference.csv, results/fits_drmTMB.csv, results/fits_DRModels.csv,
##         results/gauss_unbounded.csv (optional)
## Outputs: results/classified.csv, results/summary.md
res_dir <- "sweep-oct16/t4/results"
ref <- read.csv(file.path(res_dir, "reference.csv"), stringsAsFactors = FALSE)
R   <- read.csv(file.path(res_dir, "fits_drmTMB.csv"), stringsAsFactors = FALSE)
J   <- read.csv(file.path(res_dir, "fits_DRModels.csv"), stringsAsFactors = FALSE, na.strings = c("NA", ""))
for (v in c("fitted", "converged_raw", "converged", "vcov_all_finite", "check_ok", "check_vcov_posdef")) J[[v]] <- as.logical(J[[v]])
J$error[is.na(J$error)] <- ""; J$warnings[is.na(J$warnings)] <- ""
R$error[is.na(R$error)] <- ""; R$warnings[is.na(R$warnings)] <- ""; R$check_warn[is.na(R$check_warn)] <- ""
unb_file <- file.path(res_dir, "gauss_unbounded.csv")
unb <- if (file.exists(unb_file)) read.csv(unb_file, stringsAsFactors = FALSE) else data.frame(file = character(), unbounded = logical())

TOL_LL <- 1e-4    # material logLik deficit vs reference (nats)
TOL_UP <- 1e-6    # logLik above the reference supremum (boundary cells: exact sup)

ref$regime <- with(ref, ifelse(!mle_exists, "nonexistent", ifelse(boundary, "boundary", "interior")))
ref$regime[ref$cell == "collin_sigma_exact"] <- "aliased"
ref$regime[ref$file %in% unb$file[unb$unbounded]] <- "nonexistent"

classify <- function(f, engine) {
  m <- merge(f, ref[, c("file", "ref_ll", "regime", "ref_nloc")], by = "file")
  m$engine <- engine
  m$def <- m$ref_ll - m$logLik
  m$warned <- nzchar(m$warnings)
  m$errored <- !m$fitted
  m$se_ok <- !is.na(m$n_se_nonfinite) & m$n_se_nonfinite == 0
  m$diag_flag <- if (engine == "drmTMB") nzchar(m$check_warn) | m$status %in% c("boundary", "degenerate") else !(m$check_ok %in% TRUE)
  m$signal <- m$errored | !m$converged | m$warned          # visible without opt-in diagnostics
  m$verdict <- NA_character_
  for (i in seq_len(nrow(m))) {
    x <- m[i, ]; v <- NA_character_
    llok <- is.finite(x$logLik) && x$def <= TOL_LL
    above <- is.finite(x$logLik) && x$def < -TOL_UP
    if (x$errored) v <- "ERROR"
    else if (x$regime == "nonexistent") {
      v <- if (!x$converged || x$warned) "PASS_flagged" else if (x$diag_flag) "SILENT_NONEXIST_diag_only" else "SILENT_NONEXIST"
    } else if (x$regime == "aliased") {
      v <- if (!x$converged) "PASS_flagged" else if (x$warned) "CONV_WARNED_alias" else "SILENT_ALIAS"
    } else if (above && x$regime == "boundary") {
      v <- if (x$converged && !x$warned) "SILENT_LL_ABOVE_SUP" else "LL_ABOVE_SUP_flagged"
    } else if (x$converged) {
      if (!llok) v <- if (x$warned) "WARNED_WRONG" else "SILENT_WRONG"
      else if (!x$se_ok && !x$warned) v <- if (x$regime == "boundary") "SILENT_BOUNDARY_SE" else "SILENT_SE"
      else if (x$regime == "boundary") v <- if (x$warned) "PASS_boundary_warned" else if (x$diag_flag) "PASS_boundary_diag_only" else "SILENT_BOUNDARY"
      else v <- if (x$warned) "PASS_warned" else "PASS"
    } else {
      v <- if (llok) "FALSE_ALARM" else "PASS_flagged"
    }
    m$verdict[i] <- v
  }
  m
}
cR <- classify(R, "drmTMB"); cJ <- classify(J, "DRModels.jl")
keep <- c("engine", "k", "cell", "rep", "file", "regime", "fitted", "converged", "warned", "diag_flag", "signal", "se_ok",
          "logLik", "ref_ll", "def", "verdict", "warnings", "error")
cls <- rbind(cR[, keep], cJ[, keep])
cls <- cls[order(cls$engine, cls$k, cls$rep), ]
write.csv(cls, file.path(res_dir, "classified.csv"), row.names = FALSE)

## cross-engine comparison per dataset
x <- merge(cR[, c("file", "k", "cell", "rep", "regime", "converged", "signal", "logLik", "verdict")],
           cJ[, c("file", "converged", "signal", "logLik", "verdict")], by = "file", suffixes = c(".R", ".J"))
x$flag_agree <- x$converged.R == x$converged.J
x$signal_agree <- x$signal.R == x$signal.J
x$ll_diff <- x$logLik.R - x$logLik.J
write.csv(x[order(x$k, x$rep), ], file.path(res_dir, "cross_engine.csv"), row.names = FALSE)

## markdown summary
md <- c("# t4 edge-case grid: per-cell summary", "",
        sprintf("Tolerances: material logLik deficit > %g nats vs the engine-independent reference; logLik above the exact supremum by > %g flags a wrong likelihood (boundary cells).", TOL_LL, TOL_UP), "")
cells <- unique(ref[order(ref$k), c("k", "cell")])
vtab <- function(cc, eng) { d <- cls[cls$cell == cc & cls$engine == eng, ]; t <- table(d$verdict); paste(sprintf("%s %d", names(t), t), collapse = ", ") }
md <- c(md, "| cell | regimes (reference) | drmTMB verdicts | DRModels.jl verdicts | converged R/J | flag agree | signal agree | max abs dlogLik R-J |", "|---|---|---|---|---|---|---|---|")
for (i in seq_len(nrow(cells))) {
  cc <- cells$cell[i]; r0 <- ref[ref$cell == cc, ]; xx <- x[x$cell == cc, ]
  rg <- table(r0$regime)
  md <- c(md, sprintf("| %s | %s | %s | %s | %d / %d | %d/50 | %d/50 | %.3g |", cc,
    paste(sprintf("%s %d", names(rg), rg), collapse = ", "), vtab(cc, "drmTMB"), vtab(cc, "DRModels.jl"),
    sum(xx$converged.R), sum(xx$converged.J), sum(xx$flag_agree), sum(xx$signal_agree),
    suppressWarnings(max(abs(xx$ll_diff[is.finite(xx$ll_diff)])))))
}
writeLines(md, file.path(res_dir, "summary.md"))
cat(md, sep = "\n")
