#!/usr/bin/env Rscript
suppressMessages({ library(drmTMB); library(ape) })

sim_sigma_phylo_fixture <- function(n_tip = 60L, n_each = 12L, seed = 101L,
                                     true_log_sd_phylo = 0.7, log_sigma0 = log(0.5)) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  v <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip)) * true_log_sd_phylo
  tip <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  x <- stats::rnorm(n)
  sigma_tip <- exp(log_sigma0 + v[tip])
  y <- 0.4 + 0.7 * x + stats::rnorm(n, 0, sigma_tip)
  list(
    data = data.frame(y = y, x = x, species = factor(tree$tip.label[tip], levels = tree$tip.label)),
    tree = tree, true_log_sd_phylo = true_log_sd_phylo
  )
}

for (sd in c(202L, 303L)) {
  fx <- sim_sigma_phylo_fixture(seed = sd)
  tree <- fx$tree
  fit <- drmTMB(bf(y ~ x, sigma ~ drmTMB::phylo(1 | species, tree = tree)), data = fx$data, REML = TRUE)
  targets <- profile_targets(fit)
  est <- targets$estimate[targets$parm == "sd:sigma:phylo(1 | species)"]
  prof <- tryCatch(stats::profile(fit, parm = "sd:sigma:phylo(1 | species)", trace = FALSE), error = function(e) e)
  cat("seed=", sd, " conv=", fit$opt$convergence, " pdHess=", isTRUE(fit$sdr$pdHess),
      " est=", est, sep = "")
  if (inherits(prof, "error")) {
    cat(" PROFILE ERROR: ", conditionMessage(prof), "\n")
  } else {
    tr <- as.data.frame(prof)
    cat(" lower=", unique(tr$conf.low), " upper=", unique(tr$conf.high),
        " status=", unique(tr$conf.status), "\n")
  }
}
