## F7-twin-flag-semantics: per-cell twin flag disagreement and its cause.
## Inputs: f7_census_drmTMB.csv, f7_census_DRModels.csv (written by the two census scripts in this folder).
##   Rscript f7_compare.R > f7_compare.out 2>&1
R <- read.csv("f7_census_drmTMB.csv", stringsAsFactors = FALSE)
J <- read.csv("f7_census_DRModels.csv", stringsAsFactors = FALSE)
for (v in c("converged_raw", "nondegenerate", "is_converged", "check_ok", "vcov_posdef", "fit_warning",
            "r_pd", "r_se_finite", "r_inflated")) J[[v]] <- as.logical(J[[v]])
x <- merge(R, J, by = c("cell", "rep"), suffixes = c(".R", ".J"))
cells <- unique(R$cell)
x$cell <- factor(x$cell, levels = cells)
x$dis <- x$is_converged.R != x$is_converged.J
## drmTMB's 'degenerate' rule applied to the Julia fit (rank deficiency is a property of data + formula,
## so it is taken from the R side): J_Rsem = Julia is_converged AND NOT drmTMB-degenerate(Julia fit)
x$J_Rsem <- x$is_converged.J & x$r_pd & x$r_se_finite & !x$r_inflated & !x$rank_deficient
## and the converse: drmTMB's raw optimiser gate only (what DRModels.jl's flag mostly is)
x$R_raw <- x$optimizer_ok
x$Rreason <- with(x, ifelse(!optimizer_ok, "optimizer", ifelse(inference_degenerate, "pdHess/SE",
              ifelse(rank_deficient, "rank", ifelse(se_pathological, "inflatedSE", ifelse(at_boundary, "boundary", "ok"))))))
tab <- do.call(rbind, lapply(split(x, x$cell), function(d) {
  dd <- d[d$dis, ]
  data.frame(cell = d$cell[1], n = nrow(d), conv_R = sum(d$is_converged.R), conv_J = sum(d$is_converged.J),
    disagree = nrow(dd), R_F_J_T = sum(!dd$is_converged.R), R_T_J_F = sum(dd$is_converged.R),
    R_reason = if (nrow(dd)) paste(sprintf("%s %d", names(table(dd$Rreason)), table(dd$Rreason)), collapse = ", ") else "",
    J_raw_T = sum(dd$converged_raw), J_warned = sum(dd$fit_warning), J_check_ok = sum(dd$check_ok),
    max_abs_dLL = if (nrow(dd)) signif(max(abs(dd$logLik - dd$loglik)), 2) else NA,
    agree_J_Rsem = sum(d$is_converged.R == d$J_Rsem), agree_rawR_J = sum(d$R_raw == d$is_converged.J),
    agree_R_Jcheck = sum(d$is_converged.R == d$check_ok))
}))
options(width = 220)
cat("Twin is_converged() per cell (t4 grid cells 1-14, 50 datasets each; drmTMB ca3ddefa vs DRModels.jl f71b292)\n")
cat("disagree = R is_converged != J is_converged; R_reason = drmTMB predicate that set its flag on the disagreeing fits;\n",
    "J_raw_T / J_warned / J_check_ok = among disagreeing fits, Julia raw optimiser flag TRUE / any fit-time @warn / check_drm().ok;\n",
    "max_abs_dLL = max |logLik_R - logLik_J| over disagreeing fits;\n",
    "agree_J_Rsem = agreement if drmTMB's degenerate rule is applied to the Julia fit; agree_rawR_J = drmTMB raw optimiser gate vs Julia flag;\n",
    "agree_R_Jcheck = drmTMB is_converged vs Julia check_drm().ok\n\n")
print(tab, row.names = FALSE)
cat(sprintf("\nTOTAL: disagree %d of %d (R FALSE / J TRUE %d; R TRUE / J FALSE %d)\n", sum(x$dis), nrow(x),
            sum(x$dis & !x$is_converged.R), sum(x$dis & x$is_converged.R)))
cat(sprintf("agreement R is_converged vs J is_converged: %d/%d; vs J with drmTMB's degenerate rule: %d/%d; ",
            sum(!x$dis), nrow(x), sum(x$is_converged.R == x$J_Rsem), nrow(x)),
    sprintf("raw R gate vs J is_converged: %d/%d; R is_converged vs J check_drm().ok: %d/%d\n",
            sum(x$R_raw == x$is_converged.J), nrow(x), sum(x$is_converged.R == x$check_ok), nrow(x)))
## residual disagreement after harmonising the semantics both ways
res1 <- x[x$is_converged.R != x$J_Rsem, ]
cat("\nResidual disagreement with drmTMB semantics applied to Julia (cell: rep [R reason, J raw flag]):\n")
for (cc in cells) { d <- res1[res1$cell == cc, ]; if (nrow(d)) cat(sprintf("  %-18s %2d: %s\n", cc, nrow(d),
  paste(sprintf("r%02d[%s,Jraw=%s]", d$rep, d$Rreason, d$converged_raw), collapse = " "))) }
res2 <- x[x$R_raw != x$is_converged.J, ]
cat("\nResidual disagreement with Julia semantics applied to drmTMB (raw optimiser gate):\n")
for (cc in cells) { d <- res2[res2$cell == cc, ]; if (nrow(d)) cat(sprintf("  %-18s %2d: %s\n", cc, nrow(d),
  paste(sprintf("r%02d[Ropt=%d,Jraw=%s]", d$rep, d$opt_code, d$converged_raw), collapse = " "))) }
## cross-check against the lane's first run (if the copy is available)
run1 <- "/tmp/claude-0/-home-user/ed2098f2-a8dc-5fee-9d90-16689cc12c90/scratchpad/run1/results/cross_engine.csv"
if (file.exists(run1)) {
  ce <- read.csv(run1, stringsAsFactors = FALSE)
  ce$key <- paste(ce$cell, ce$rep); x$key <- paste(x$cell, x$rep)
  m <- merge(ce[, c("key", "converged.R", "converged.J")], x[, c("key", "is_converged.R", "is_converged.J")], by = "key")
  cat(sprintf("\nCross-check vs lane run1 cross_engine.csv: %d rows matched; R flag identical %d, J flag identical %d\n",
              nrow(m), sum(m$converged.R == m$is_converged.R), sum(m$converged.J == m$is_converged.J)))
}
