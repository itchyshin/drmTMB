SP <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad"
.libPaths(c(file.path(SP, "agree-poisson-q2/lib"), .libPaths())); suppressMessages(library(drmTMB))
f <- readRDS(file.path(SP, "agree-sigma/rfit_6a_bigint.rds")); ob <- f$obj; r <- ob$env$random
thR <- f$opt$par
thJ <- c(0.2738656512543831, 0.5008374254739447, -0.7035612147782503, -0.5033351874652356, 0.42031546043062795, -1.1041288073041713, 0.41887983471924795)
ev <- function(th, lab) { ob$env$last.par.best[r] <- 0; v0 <- ob$fn(th); cat(sprintf("%s: R Laplace from zero start = %.6f (ll %.6f)\n", lab, v0, -v0)) }
ev(thR, "thetaR"); ev(thJ, "thetaJ")
ob$env$last.par.best[r] <- 0; v <- ob$fn(thR); g <- ob$gr(thR); cat("grad at thetaR (zero-start branch):", signif(g, 3), "\n")
