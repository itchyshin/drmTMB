SP <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad"
.libPaths(c(file.path(SP, "agree-poisson-q2/lib"), .libPaths())); suppressMessages(library(drmTMB))
O <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[1] else getwd()
d <- read.csv(file.path(O, "data_gaussian_corr_same.csv")); d$id <- factor(d$id)
fit <- drmTMB(bf(y ~ x + (1 | p | id), sigma ~ 1 + (1 | p | id)), family = gaussian(), data = d)
est <- fit$opt$par; se <- sqrt(diag(fit$sdr$cov.fixed)); print(est)
j <- read.csv(file.path(O, "jcoef_gaussian_corr_same.csv"))
# Julia order mu(2), sigma, resd(log sd mu, log sd sigma), cor(eta); R order beta_mu x2, beta_sigma, log_sd_mu, eta_cor, log_sd_sigma
jj <- j[c(1, 2, 3, 4, 6, 5), ]
jll <- as.numeric(readLines(file.path(O, "jll_gaussian_corr_same.txt"), warn = FALSE)); rll <- as.numeric(logLik(fit))
tab <- data.frame(case = "gaussian_corr_same", n_par = length(est), r_conv = fit$opt$convergence,
  max_abs_diff = max(abs(est - jj$est)), max_diff_in_se = max(abs(est - jj$est) / se),
  max_se_rel_diff = max(abs(se - jj$se) / se), r_loglik = sprintf("%.10f", rll), j_loglik = sprintf("%.10f", jll),
  loglik_diff = signif(jll - rll, 3), r_rho = unname(fit$corpars$mu_sigma), j_rho = tanh(jj$est[5]))
print(tab, row.names = FALSE); write.csv(tab, file.path(O, "comparison_corr.csv"), row.names = FALSE)
