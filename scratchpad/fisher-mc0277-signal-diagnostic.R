#!/usr/bin/env Rscript
# Fisher scratch diagnostic (NOT part of the package): does the sd:sigma:phylo
# profile behave with GENUINE sigma-phylo signal and adequate replication?
#
# Design rationale: scale-side variance components need within-tip
# replication to be identified (standing drmTMB caveat). n_tip = 60 (double
# the manifest's 30) and n_each = 12 (4x the manifest's 3) give n = 720 obs,
# with 12 residuals per tip available to estimate each tip's own dispersion
# and hence separate tip-level sigma variation from residual noise.

R_PROFILE_USER <- Sys.setenv(R_PROFILE_USER = "/dev/null")
suppressMessages({
  library(drmTMB)
  library(ape)
})

sim_sigma_phylo_fixture <- function(n_tip = 60L, n_each = 12L, seed = 101L,
                                     true_log_sd_phylo = 0.7, log_sigma0 = log(0.5)) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  # phylo effect on log(sigma), scaled to true_log_sd_phylo
  v <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip)) * true_log_sd_phylo
  tip <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  x <- stats::rnorm(n)
  sigma_tip <- exp(log_sigma0 + v[tip])
  y <- 0.4 + 0.7 * x + stats::rnorm(n, 0, sigma_tip)
  list(
    data = data.frame(
      y = y, x = x,
      species = factor(tree$tip.label[tip], levels = tree$tip.label)
    ),
    tree = tree, true_log_sd_phylo = true_log_sd_phylo
  )
}

fx <- sim_sigma_phylo_fixture()
tree <- fx$tree

fit <- drmTMB(
  bf(y ~ x, sigma ~ drmTMB::phylo(1 | species, tree = tree)),
  data = fx$data,
  REML = TRUE
)

cat("estimator:", fit$estimator, "\n")
cat("convergence:", fit$opt$convergence, "\n")
cat("pdHess:", isTRUE(fit$sdr$pdHess), "\n")

targets <- profile_targets(fit)
print(targets[targets$parm == "sd:sigma:phylo(1 | species)", ])

prof <- tryCatch(
  stats::profile(fit, parm = "sd:sigma:phylo(1 | species)", trace = FALSE),
  error = function(e) e
)

if (inherits(prof, "error")) {
  cat("PROFILE ERRORED:", conditionMessage(prof), "\n")
} else {
  trace <- as.data.frame(prof)
  cat("n trace rows:", nrow(trace), "\n")
  print(utils::head(trace, 3))
  print(utils::tail(trace, 3))
  field <- function(nm) unique(trace[[nm]])
  cat("level:", field("level"), "\n")
  cat("conf.low:", field("conf.low"), "\n")
  cat("conf.high:", field("conf.high"), "\n")
  cat("conf.status:", field("conf.status"), "\n")
  cat("profile.message:", field("profile.message"), "\n")
  est <- targets$estimate[targets$parm == "sd:sigma:phylo(1 | species)"]
  cat("estimate:", est, "\n")
  cat("true log_sd_phylo used in sim:", fx$true_log_sd_phylo, "\n")
  finite_ordered <- all(is.finite(c(field("conf.low"), est, field("conf.high")))) &&
    field("conf.low") < est && est < field("conf.high")
  cat("FINITE & ORDERED TWO-SIDED:", finite_ordered, "\n")
}
