.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); library(drmTMB)
O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-sigma"
for (nm in c("slope","int","big","bigint")) {
  d <- read.csv(file.path(O, paste0("data_6a_", nm, ".csv"))); d$id <- factor(d$id); d$site <- factor(d$site)
  sl <- nm %in% c("slope","big")
  fm <- if (sl) bf(y ~ x + (1|id), sigma ~ 1 + (0 + z | site), sd(id) ~ w, sd(site, dpar="sigma", coef="z") ~ v)
        else bf(y ~ x + (1|id), sigma ~ 1 + (1 | site), sd(id) ~ w, sd(site, dpar="sigma") ~ v)
  t0 <- Sys.time(); fit <- drmTMB(fm, family = gaussian(), data = d)
  cat("\n##", nm, "time", format(Sys.time()-t0), "ll", sprintf("%.8f", as.numeric(logLik(fit))), "conv", fit$opt$convergence, "REML", fit$REML, "\n")
  saveRDS(fit, file.path(O, paste0("rfit_6a_", nm, ".rds")))
}
for (kind in c("animal","relmat")) {
  d <- read.csv(file.path(O, paste0("data_6b_", kind, ".csv"))); d$id <- factor(d$id)
  K <- as.matrix(read.csv(file.path(O, paste0("K_", kind, ".csv")), header=FALSE)); ids <- levels(d$id); dimnames(K) <- list(ids, ids)
  fm <- if (kind=="animal") bf(y ~ x, sigma ~ 1 + animal(1|id, A = K), sd(id, level="animal", dpar="sigma") ~ z)
        else bf(y ~ x, sigma ~ 1 + relmat(1|id, K = K), sd(id, level="relmat", dpar="sigma") ~ z)
  t0 <- Sys.time(); fit <- drmTMB(fm, family = gaussian(), data = d)
  cat("\n##", kind, "time", format(Sys.time()-t0), "ll", sprintf("%.8f", as.numeric(logLik(fit))), "conv", fit$opt$convergence, "REML", fit$REML, "\n")
  saveRDS(fit, file.path(O, paste0("rfit_6b_", kind, ".rds")))
}
