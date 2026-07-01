#!/usr/bin/env Rscript
# Engine coverage validation for the opt-in bias-corrected + t interval at g=8.
#
# Confirms that the ENGINE path (confint(method="wald", small_sample_df="group",
# bias_correct="group")) -- not the post-hoc recompute -- reaches nominal coverage
# at the deployment default g=8, for the four certified q2 mu-slope SD cells
# (phylo + relmat, mu1:x + mu2:x). SR475 (475 reps -> MCSE ~ 0.01 at p=0.95).
#
# Reuses the runner's DGP/fit by sourcing only its function definitions.

root <- "/Users/z3437171/Dropbox/Github Local/drmTMB"
setwd(root)
Sys.setenv(GSWEEP_N_GROUPS = "8")            # deployment default g=8

# --- source runner function defs (everything before the `args <- parse_args` main)
runner <- file.path(root, "tools/run-structured-re-q2-slope-coverage-grid.R")
src <- readLines(runner)
main_line <- grep("^args\\s*<-\\s*parse_args", src)[1L]
tmp <- tempfile(fileext = ".R"); writeLines(src[seq_len(main_line - 1L)], tmp); source(tmp)

suppressMessages(pkgload::load_all(root, quiet = TRUE))   # picks up bias_correct

cells <- expand.grid(
  provider = c("phylo", "relmat"),
  target   = c("mu1:x", "mu2:x"),
  stringsAsFactors = FALSE
)
n_rep <- 475L; seed0 <- 730001L
z <- qnorm(0.975)

covers <- function(truth, lo, hi) if (is.finite(lo) && is.finite(hi)) (truth >= lo && truth <= hi) else NA

rows <- list()
for (k in seq_len(nrow(cells))) {
  prov <- cells$provider[k]; tgt <- cells$target[k]
  parm <- parm_name_for(prov, tgt); truth <- truth_for(tgt)
  cat(sprintf("[%s] %s %s  parm=%s truth=%.3f\n", format(Sys.time(), "%H:%M:%S"), prov, tgt, parm, truth))
  for (i in seq_len(n_rep)) {
    seed <- seed0 + i - 1L
    res <- tryCatch({
      sim <- make_q2_slope_data(prov, seed, 20L)
      fit <- fit_q2_slope(prov, sim)
      ci_z  <- suppressWarnings(stats::confint(fit, parm = parm, method = "wald", level = 0.95))
      ci_bc <- suppressWarnings(stats::confint(fit, parm = parm, method = "wald", level = 0.95,
                                               small_sample_df = "group", bias_correct = "group"))
      list(zl = ci_z$lower[[1L]], zu = ci_z$upper[[1L]],
           bl = ci_bc$lower[[1L]], bu = ci_bc$upper[[1L]], ok = TRUE)
    }, error = function(e) list(ok = FALSE, msg = conditionMessage(e)))
    if (isTRUE(res$ok)) {
      rows[[length(rows) + 1L]] <- data.frame(
        provider = prov, target = tgt, seed = seed, truth = truth,
        wald_lower = res$zl, wald_upper = res$zu,
        bc_lower = res$bl, bc_upper = res$bu,
        wald_contains = covers(truth, res$zl, res$zu),
        bc_contains   = covers(truth, res$bl, res$bu),
        stringsAsFactors = FALSE)
    }
  }
}
out <- do.call(rbind, rows)
outdir <- file.path(root, "docs/dev-log/simulation-artifacts/2026-06-27-bias-corrected-engine-coverage-g8")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
write.table(out, file.path(outdir, "replicates.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)

mcse <- function(p, n) if (n > 0) sqrt(p * (1 - p) / n) else NA_real_
cat("\n=== ENGINE bias-corrected+t coverage at g=8 (SR475) ===\n")
cat(sprintf("%-16s %5s %8s %8s %8s\n", "cell", "n", "wald_z", "bc+t", "mcse_bc"))
agg <- list()
for (k in seq_len(nrow(cells))) {
  sub <- out[out$provider == cells$provider[k] & out$target == cells$target[k], ]
  nz <- sum(!is.na(sub$wald_contains)); cz <- mean(sub$wald_contains, na.rm = TRUE)
  nb <- sum(!is.na(sub$bc_contains));   cb <- mean(sub$bc_contains, na.rm = TRUE)
  agg[[k]] <- c(n = nb, z = cz * nz, b = cb * nb, nz = nz)
  cat(sprintf("%-16s %5d %8.3f %8.3f %8.4f\n",
              paste(cells$provider[k], cells$target[k]), nb, cz, cb, mcse(cb, nb)))
}
A <- do.call(rbind, agg)
cat(sprintf("\nPOOLED  n=%d  wald_z=%.3f  bc+t=%.3f  (mcse %.4f)\n",
            sum(A[, "n"]), sum(A[, "z"]) / sum(A[, "nz"]),
            sum(A[, "b"]) / sum(A[, "n"]), mcse(sum(A[, "b"]) / sum(A[, "n"]), sum(A[, "n"]))))
cat("DONE\n")
