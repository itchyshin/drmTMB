.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); library(drmTMB)
O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-q34"
for (q in 3:4) {
  d <- read.csv(file.path(O, paste0("data", q, ".csv"))); d$id <- factor(d$id)
  f <- if (q == 3) y ~ x + z + (1 + x + z | id) else y ~ x + z + (1 + x + z + u | id)
  sds <- list(sd(id, coef = "(Intercept)") ~ w, sd(id, coef = "x") ~ w, sd(id, coef = "z") ~ w)
  if (q == 4) sds[[4]] <- sd(id, coef = "u") ~ w
  fm <- do.call(bf, c(list(f, sigma ~ 1), sds))
  t0 <- Sys.time(); fit <- drmTMB(fm, family = gaussian(), data = d)
  cat("q", q, "time", format(Sys.time() - t0), " ll", sprintf("%.8f", as.numeric(logLik(fit))), "\n")
  print(summary(fit)); print(fit$corpars$re_cov)
  saveRDS(fit, file.path(O, paste0("r_fit", q, ".rds")))
}
