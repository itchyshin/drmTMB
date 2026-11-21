.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); library(drmTMB)
O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-q2ord"
d <- read.csv(file.path(O,"data.csv")); d$id <- factor(d$id)
sI <- sd(id, coef = "(Intercept)") ~ w0; sX <- sd(id, coef = "x") ~ w1
for (tag in c("both","slope")) {
  fm <- if (tag=="both") bf(y ~ x + (1 + x | id), sigma ~ 1, sI, sX) else bf(y ~ x + (1 + x | id), sigma ~ 1, sX)
  t0 <- Sys.time(); fit <- drmTMB(fm, family = gaussian(), data = d)
  cat(tag, "time", format(Sys.time()-t0), " ll", sprintf("%.8f", as.numeric(logLik(fit))), "\n")
  print(summary(fit)); print(fit$corpars)
  saveRDS(fit, file.path(O, paste0("r_fit_", tag, ".rds")))
}
