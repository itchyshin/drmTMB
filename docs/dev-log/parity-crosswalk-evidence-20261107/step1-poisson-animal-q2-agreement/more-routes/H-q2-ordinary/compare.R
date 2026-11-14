.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); library(drmTMB)
O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-q2ord"
for (tag in c("both","slope")) {
  fit <- readRDS(file.path(O, paste0("r_fit_", tag, ".rds")))
  j <- read.csv(file.path(O, paste0("julia_coef_", tag, ".csv")))
  
  s <- summary(fit$sdreport, "fixed"); eta <- s[rownames(s)=="eta_cor_mu",,drop=FALSE]; s <- s[rownames(s)!="eta_cor_mu",,drop=FALSE]
  cat("\n=== ", tag, " REML:", fit$REML, " conv:", fit$opt$convergence, " rows julia", nrow(j), " R", nrow(s), "\n")
  print(rownames(s))
  j <- j[j$block!="recov",]; if (tag=="slope") s <- s[c(1,2,3,6,4,5),,drop=FALSE]  # R lists slope-SD betas before the constant intercept log_sd; Julia the reverse
  stopifnot(nrow(s)==nrow(j))
  j$par <- rownames(s); j$r_est <- s[,1]; j$r_se <- s[,2]
  j$diff <- j$est-j$r_est; j$d_se <- j$diff/j$r_se; j$se_ratio <- j$se/j$r_se
  print(j[,c("par","block","k","est","r_est","diff","d_se","se","r_se","se_ratio")], digits=6)
  cat(sprintf("max|diff|/SE_R: %.2e ; max|diff|: %.2e ; SE ratio %.6f-%.6f\n", max(abs(j$d_se)), max(abs(j$diff)), min(j$se_ratio), max(j$se_ratio)))
  jt <- read.csv(file.path(O, paste0("julia_coef_", tag, ".csv"))); jt <- jt[jt$block=="recov",]; th <- jt$est
  rj <- th/sqrt(1+th^2); rr <- unname(fit$corpars$mu); er <- eta[1,1]
  cat(sprintf("rho Julia %.8f R %.8f diff %.2e | R eta_cor %.6f atanh(rho_R) %.6f (eta=atanh? %s)
", rj, rr, rj-rr, er, atanh(rr), isTRUE(all.equal(er, atanh(rr), tolerance=1e-6))))
  se_rho_j <- jt$se/(1+th^2)^1.5; se_rho_r <- eta[1,2]*(1-rr^2)
  cat(sprintf("rho SE (delta) Julia %.6f R %.6f ratio %.6f ; rho diff in R-SE units %.2e ; Julia theta %.6f
", se_rho_j, se_rho_r, se_rho_j/se_rho_r, (rj-rr)/se_rho_r, th))
  lj <- scan(file.path(O, paste0("julia_ll_", tag, ".txt")), quiet=TRUE)[1]
  cat(sprintf("ll Julia %.8f R %.8f diff %.2e\n", lj, as.numeric(logLik(fit)), lj-as.numeric(logLik(fit))))
  write.csv(j, file.path(O, paste0("comparison_", tag, ".csv")), row.names=FALSE)
}
