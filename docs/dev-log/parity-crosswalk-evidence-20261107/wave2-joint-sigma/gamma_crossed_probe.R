# Probe of the gamma_crossed disagreement: evaluate R's Laplace objective at
# Julia's optimum and refit R from Julia's optimum.
SP <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad"
.libPaths(c(file.path(SP, "agree-poisson-q2/lib"), .libPaths())); suppressMessages(library(drmTMB))
O <- commandArgs(TRUE)[1]
d <- read.csv(file.path(O, "data_gamma_crossed.csv")); d$id <- factor(d$id); d$g <- factor(d$g)
fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g), sd(id) ~ w, sd(g, dpar = "sigma") ~ z),
              family = Gamma(link = "log"), data = d)
j <- read.csv(file.path(O, "jcoef_gamma_crossed.csv"))
ob <- fit$obj; r <- ob$env$random
cat("R opt: ll", -fit$opt$objective, " conv", fit$opt$convergence, " max|grad|", max(abs(ob$gr(fit$opt$par))), "\n")
cat("R est :", signif(fit$opt$par, 6), "\n")
cat("J est :", signif(j$est, 6), "\n")
ob$env$last.par.best[r] <- 0; vj <- ob$fn(j$est); gj <- ob$gr(j$est)
cat(sprintf("R objective at Julia estimate (zero inner start): ll %.10f", -vj), " max|grad|", max(abs(gj)), "\n")
op2 <- nlminb(j$est, ob$fn, ob$gr, control = list(rel.tol = 1e-12, iter.max = 500))
cat(sprintf("R nlminb restarted at Julia estimate: ll %.10f conv %d\n", -op2$objective, op2$convergence))
ob$env$last.par.best[r] <- 0; invisible(ob$fn(op2$par)); se2 <- sqrt(diag(solve(optimHess(op2$par, ob$fn, ob$gr))))
cat(sprintf("  vs Julia: max|diff| %.3g, max|diff|/SE %.3g, SE rel diff max %.3g\n", max(abs(op2$par - j$est)), max(abs(op2$par - j$est) / se2), max(abs(se2 - j$se) / se2)))
cat("   est:", signif(op2$par, 6), "\n")
ob$env$last.par.best[r] <- 0; v0 <- ob$fn(fit$opt$par)
cat("R objective at R estimate (zero inner start): ll", -v0, "\n")
