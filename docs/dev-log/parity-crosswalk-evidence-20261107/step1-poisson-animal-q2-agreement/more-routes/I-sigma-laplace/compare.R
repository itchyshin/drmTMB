O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-sigma"
.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); library(drmTMB)
for (nm in c("6a_slope","6a_int","6a_big","6a_bigint","6b_animal","6b_relmat")) {
  fit <- readRDS(file.path(O, paste0("rfit_", nm, ".rds")))
  j <- read.csv(file.path(O, paste0("jcoef_", nm, ".csv")))
  s <- summary(fit$sdreport, "fixed")
  cat("\n=== ", nm, " nJ=", nrow(j), " nR=", nrow(s), "\n")
  if (nrow(s) != nrow(j)) { print(rownames(s)); next }
  j$par <- rownames(s); j$r_est <- s[,1]; j$r_se <- s[,2]
  j$diff <- j$est - j$r_est; j$d_se <- j$diff/j$r_se; j$se_ratio <- j$se/j$r_se
  print(j[,c("par","est","r_est","diff","d_se","se","r_se","se_ratio")], digits=5)
  ll <- scan(file.path(O, paste0("jll_", nm, ".txt")), quiet=TRUE); lr <- as.numeric(logLik(fit))
  cat(sprintf("max|diff|/SE_R %.3e ; ll J %.6f R %.6f diff %.3e\n", max(abs(j$d_se), na.rm=TRUE), ll, lr, ll-lr))
}
