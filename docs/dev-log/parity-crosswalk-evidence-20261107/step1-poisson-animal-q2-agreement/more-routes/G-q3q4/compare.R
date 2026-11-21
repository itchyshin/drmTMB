.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); library(drmTMB)
O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-q34"
for (q in 3:4) {
  fit <- readRDS(file.path(O, paste0("r_fit", q, ".rds")))
  j <- read.csv(file.path(O, paste0("julia_coef", q, ".csv")))
  s <- summary(fit$sdreport, "fixed")
  stopifnot(nrow(s) == nrow(j))
  j$r_est <- s[,1]; j$r_se <- s[,2]; j$par <- rownames(s)
  j$diff <- j$est - j$r_est; j$d_se <- j$diff / j$r_se; j$se_ratio <- j$se / j$r_se
  cat("\n=== q", q, " REML:", fit$REML, " optimizer conv:", fit$opt$convergence, "\n"); print(j[,c("par","block","k","est","r_est","diff","d_se","se","r_se","se_ratio")], digits=5)
  cat(sprintf("max|diff|/SE_R all: %.2e ; max|diff|: %.2e ; SE ratio range %.4f-%.4f\n", max(abs(j$d_se)), max(abs(j$diff)), min(j$se_ratio), max(j$se_ratio)))
  # correlations
  Rj <- as.matrix(read.csv(file.path(O, paste0("julia_R", q, ".csv")), header=FALSE))
  th <- fit$opt$par[names(fit$opt$par)=="theta_re_cov"]; L <- diag(q); k<-0
  for (i in 1:q) for (jj in seq_len(i-1)) { k<-k+1; L[i,jj]<-th[k] }
  S0 <- L %*% t(L); Rr <- cov2cor(S0)
  cat("max|R_julia - R_from_Rtheta|:", max(abs(Rj-Rr)), "\n")
  rc <- fit$corpars$re_cov; iu <- which(lower.tri(Rj), arr.ind=TRUE); iu <- iu[order(iu[,2],iu[,1]),]
  cat("R reported cor (names order) vs Julia R lower tri in same order (col-major):\n"); print(cbind(R_reported=unname(rc), Julia=Rj[iu], diff=unname(rc)-Rj[iu]), digits=6)
  ll <- scan(file.path(O, paste0("julia_ll", q, ".txt")), quiet=TRUE)
  cat(sprintf("ll Julia %.8f R %.8f diff %.2e\n", ll, as.numeric(logLik(fit)), ll-as.numeric(logLik(fit))))
  write.csv(j, file.path(O, paste0("comparison", q, ".csv")), row.names=FALSE)
}
