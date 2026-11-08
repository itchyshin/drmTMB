.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); suppressMessages(library(drmTMB))
O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-gamma/out"
rows <- list()
for (tag in list.files(O)) {
  dir <- file.path(O, tag); fit <- readRDS(file.path(dir, "r_fit.rds"))
  s <- summary(fit$sdreport, "fixed"); j <- read.csv(file.path(dir, "julia_coef.csv"))
  stopifnot(nrow(s) == nrow(j))
  j$r_par <- rownames(s); j$r_est <- s[, 1]; j$r_se <- s[, 2]
  j$diff <- j$est - j$r_est; j$diff_se <- j$diff / j$r_se; j$se_ratio <- j$se / j$r_se
  write.csv(j, file.path(dir, "comparison.csv"), row.names = FALSE)
  jl <- readLines(file.path(dir, "julia_ll.txt"))
  llj <- as.numeric(jl[1]); llr <- as.numeric(logLik(fit))
  rows[[tag]] <- data.frame(shape = tag, n_par = nrow(j), r_conv = fit$opt$convergence, julia_conv = jl[2],
    max_abs_diff = max(abs(j$diff)), max_diff_se = max(abs(j$diff_se)),
    se_ratio_min = min(j$se_ratio), se_ratio_max = max(j$se_ratio),
    ll_julia = sprintf("%.10f", llj), ll_r = sprintf("%.10f", llr), ll_diff = llj - llr)
}
tab <- do.call(rbind, rows); rownames(tab) <- NULL
print(tab, digits = 3); write.csv(tab, file.path(O, "..", "summary.csv"), row.names = FALSE)
