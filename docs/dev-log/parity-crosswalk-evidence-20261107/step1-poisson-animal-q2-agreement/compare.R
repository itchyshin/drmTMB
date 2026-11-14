.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); library(drmTMB)
fit <- readRDS("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/r_fit.rds"); ct <- summary(fit)$coefficients
print(ct); write.csv(ct, "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/r_coef.csv", row.names=FALSE)
j <- read.csv("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/julia_coef.csv")
fe <- fixef(fit); rv <- c(fe[[1]], fe[[2]], fe[[3]])
# SEs: take R rows in order
se_r <- ct[[grep("Std|se", names(ct), ignore.case=TRUE)[1]]]
cat("R SE col rows:", nrow(ct), "\n")
j$r_est <- rv; j$r_se <- se_r[seq_len(6)]
j$diff <- j$est - j$r_est; j$diff_in_se_julia <- j$diff/j$se
j$se_ratio <- j$se/j$r_se
print(j, digits=6)
cat("max|diff| fixed:", max(abs(j$diff[1:2])), " (SE units", max(abs(j$diff_in_se_julia[1:2])), ")\n")
cat("max|diff| SD-reg:", max(abs(j$diff[3:6])), " (SE units", max(abs(j$diff_in_se_julia[3:6])), ")\n")
llj <- scan("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/julia_ll.txt", quiet=TRUE); cat(sprintf("ll Julia %.8f R %.8f diff %.2e\n", llj, as.numeric(logLik(fit)), llj-as.numeric(logLik(fit))))
write.csv(j, "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/comparison.csv", row.names=FALSE)
