## F2 minimal repro (drmTMB main ca3ddefa). Run from this directory: Rscript f2_minimal.R > f2_minimal.out 2>&1
library(drmTMB)
cat("drmTMB", as.character(packageVersion("drmTMB")), "TMB", as.character(packageVersion("TMB")), "\n")
d <- read.csv("../../data/beta_phi1e4_r15.csv")   # cell beta_phi1e4, rep 15, R seed 933664482
fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = beta_family(), data = d)
print(fit$provenance$git_sha)
print(fit$optimizer_attempts[, c("optimizer_preset", "convergence", "message", "objective")], digits = 13)
cat("opt:", fit$opt$message, "| is_converged:", is_converged(fit), "| status:", convergence_status(fit),
    "| pdHess:", fit$sdr$pdHess, "| max|grad|:", format(max(abs(fit$gradient)), digits = 3), "\n")
mu_phi_nll <- function(p) { mu <- plogis(p[1] + p[2] * d$x); phi <- exp(-2 * p[3])
  -sum(dbeta(d$y, mu * phi, (1 - mu) * phi, log = TRUE)) }
ref <- optim(fit$opt$par, mu_phi_nll, method = "BFGS", control = list(reltol = 1e-15))
cat(sprintf("logLik(fit) = %.10f ; dbeta() optimum = %.10f ; diff = %.2e\n", as.numeric(logLik(fit)), -ref$value, as.numeric(logLik(fit)) + ref$value))
## same data, CppAD tape optimisation switched off for the drmTMB DLL
invisible(TMB::config(optimize.instantly = 0, DLL = "drmTMB"))
fit0 <- drmTMB(bf(y ~ x, sigma ~ 1), family = beta_family(), data = d)
cat("optimize.instantly = 0 -> opt:", fit0$opt$message, "| is_converged:", is_converged(fit0), "\n")
sessionInfo()
