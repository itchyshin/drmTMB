SP <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad"
.libPaths(c(file.path(SP, "agree-poisson-q2/lib"), .libPaths())); suppressMessages({library(drmTMB); library(ape)})
O <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[1] else getwd()
rows <- list()
for (p in c("phylo", "spatial")) {
  nm <- paste0("gaussian_", p, "_sigma")
  d <- read.csv(file.path(O, paste0("data_", nm, ".csv"))); d$id <- factor(d$id)
  if (p == "phylo") {
    tree <- read.tree(text = readLines(file.path(O, paste0("tree_", nm, ".nwk")), warn = FALSE))
    fit <- drmTMB(bf(y ~ x, sigma ~ 1 + phylo(1 | id, tree = tree), sd(id, level = "phylogenetic", dpar = "sigma") ~ z),
                  family = gaussian(), data = d)
  } else {
    cc <- read.csv(file.path(O, paste0("coords_", nm, ".csv"))); coords <- as.matrix(cc[, c("cx", "cy")]); rownames(coords) <- cc$id
    fit <- drmTMB(bf(y ~ x, sigma ~ 1 + spatial(1 | id, coords = coords), sd(id, level = "spatial", dpar = "sigma") ~ z),
                  family = gaussian(), data = d)
  }
  est <- fit$opt$par; se <- sqrt(diag(fit$sdr$cov.fixed))
  j <- read.csv(file.path(O, paste0("jcoef_", nm, ".csv"))); jll <- as.numeric(readLines(file.path(O, paste0("jll_", nm, ".txt")), warn = FALSE))
  stopifnot(length(est) == nrow(j)); rll <- as.numeric(logLik(fit))
  cat(nm, ": par", names(est), "\n")
  rows[[nm]] <- data.frame(case = nm, n_par = length(est), r_conv = fit$opt$convergence,
    max_abs_diff = max(abs(est - j$est)), max_diff_in_se = max(abs(est - j$est) / se),
    max_se_rel_diff = max(abs(se - j$se) / se), r_loglik = sprintf("%.10f", rll), j_loglik = sprintf("%.10f", jll),
    loglik_diff = signif(jll - rll, 3))
}
tab <- do.call(rbind, rows); print(tab, row.names = FALSE)
write.csv(tab, file.path(O, "comparison_structured.csv"), row.names = FALSE)
