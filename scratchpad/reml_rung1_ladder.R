# Rung 1 sample-size ladder: biv Gaussian REML vs ML with phylo MEANS (loc-loc corr).
# Question (Shinichi): does recovery improve with n, is REML less downward-biased on the
# variance components, and are REML and ML standard errors SIMILAR? Gate overridden in-session.
suppressPackageStartupMessages({
  devtools::load_all(Sys.getenv("DRMTMB_PATH", "/Users/z3437171/Dropbox/Github Local/drmTMB"), quiet = TRUE)
  library(ape); library(parallel)
})
try(assignInNamespace("drm_validate_reml_spec_biv", function(spec) invisible(TRUE), ns = "drmTMB"), silent = TRUE)
options(drmTMB.openblas_threads = 1L); Sys.setenv(OPENBLAS_NUM_THREADS = "1")

truth <- c(sigma1 = 0.8, sigma2 = 0.9, rho12 = 0.3, sd_phylo1 = 0.6, sd_phylo2 = 0.5, cor_phylo = 0.4)
Gc <- chol(matrix(c(0.6^2, 0.4*0.6*0.5, 0.4*0.6*0.5, 0.5^2), 2, 2))
Rc <- chol(matrix(c(0.8^2, 0.3*0.8*0.9, 0.3*0.8*0.9, 0.9^2), 2, 2))
pick <- function(vv) c(
  sigma1 = unname(vv["sigma1"]), sigma2 = unname(vv["sigma2"]), rho12 = unname(vv["rho12"]),
  sd_phylo1 = unname(vv[grep("^sd:mu:mu1", names(vv))][1]),
  sd_phylo2 = unname(vv[grep("^sd:mu:mu2", names(vv))][1]),
  cor_phylo = unname(vv[grep("^cor:phylo", names(vv))][1]))

sim_fit <- function(n, seed) {
  set.seed(seed * 100003L + n)
  tree <- rcoal(n); tree$tip.label <- paste0("sp_", seq_len(n))
  A <- vcv(tree, corr = TRUE); L <- t(chol(A))
  M <- L %*% matrix(rnorm(n*2), n, 2) %*% Gc
  E <- matrix(rnorm(n*2), n, 2) %*% Rc
  x <- rnorm(n)
  d <- data.frame(sp = factor(tree$tip.label, levels = tree$tip.label), x = x,
                  y1 = 0.3 + 0.5*x + M[,1] + E[,1], y2 = 0.1 + 0.2*x + M[,2] + E[,2])
  form <- bf(mu1 = y1 ~ x + phylo(1|p|sp, tree = tree), mu2 = y2 ~ x + phylo(1|p|sp, tree = tree),
             sigma1 = ~1, sigma2 = ~1, rho12 = ~1)
  ctrl <- drm_control(optimizer_preset = "robust")
  out <- list()
  for (est in c("ML", "REML")) {
    f <- tryCatch(drmTMB(form, biv_gaussian(), d, REML = (est == "REML"), control = ctrl), error = function(e) e)
    if (inherits(f, "error")) return(NULL)
    pr <- tryCatch(summary(f)$parameters, error = function(e) NULL); if (is.null(pr)) return(NULL)
    out[[est]] <- list(est = pick(setNames(pr$estimate, pr$parm)),
                       se  = pick(setNames(pr$std_error, pr$parm)),
                       conv = f$opt$convergence, pd = tryCatch(isTRUE(f$sdr$pdHess), error = function(e) NA))
  }
  data.frame(n = n, seed = seed, param = names(truth), truth = truth,
             ml = out$ML$est, reml = out$REML$est, se_ml = out$ML$se, se_reml = out$REML$se,
             conv_ml = out$ML$conv, conv_reml = out$REML$conv,
             pd_ml = out$ML$pd, pd_reml = out$REML$pd, row.names = NULL)
}

n_levels <- as.integer(strsplit(Sys.getenv("N_LEVELS", "200,400"), ",")[[1]])
n_seeds  <- as.integer(Sys.getenv("N_SEEDS", "4"))
cores    <- as.integer(Sys.getenv("CORES", "4"))
grid <- expand.grid(seed = seq_len(n_seeds), n = n_levels)
cat(sprintf("ladder: n in {%s} x %d seeds on %d cores\n", paste(n_levels, collapse = ","), n_seeds, cores))
t0 <- Sys.time()
res <- mcmapply(sim_fit, grid$n, grid$seed, SIMPLIFY = FALSE, mc.cores = cores)
cat(sprintf("fits done in %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
res <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
outdir <- Sys.getenv("OUTDIR", "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/2bb06ced-ac15-4169-824d-8cc18d223c51/scratchpad")
write.csv(res, file.path(outdir, "reml_rung1_ladder.csv"), row.names = FALSE)

m <- function(z) mean(z, na.rm = TRUE)
agg <- aggregate(cbind(ml, reml, se_ml, se_reml) ~ n + param + truth, data = res, FUN = m)
agg$bias_ml <- agg$ml - agg$truth; agg$bias_reml <- agg$reml - agg$truth
cat(sprintf("\ncompleted reps per n: %s\n", paste(table(res$n[res$param=="sigma1"]), collapse = " ")))
cat("\n=== bias(ML) | bias(REML) | meanSE(ML) | meanSE(REML), by n ===\n")
for (p in c("sd_phylo1", "sd_phylo2", "cor_phylo", "sigma1", "sigma2", "rho12")) {
  cat(sprintf("\n%s (truth %.2f):\n     n   biasML  biasREML    seML   seREML\n", p, truth[p]))
  sub <- agg[agg$param == p, ]; sub <- sub[order(sub$n), ]
  for (i in seq_len(nrow(sub)))
    cat(sprintf("%6d  %+.3f    %+.3f    %.3f   %.3f\n",
        sub$n[i], sub$bias_ml[i], sub$bias_reml[i], sub$se_ml[i], sub$se_reml[i]))
}
cat("\nLADDER DONE\n")
