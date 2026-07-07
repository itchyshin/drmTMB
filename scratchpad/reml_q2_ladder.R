# q2 recovery ladder: univariate MATCHED mean+scale phylo (2x2 block), ML vs REML.
# Re-tests the N=120 "REML degrades the mean" finding with ADEQUATE, well-conditioned data
# (the q-ladder doc's arbiter was at N=120, BELOW the N>=250 identifiability threshold).
# Question: does REML's mean-side (sd_mu) bias vanish as n grows, while it debiases sd_sigma?
suppressPackageStartupMessages({
  devtools::load_all(Sys.getenv("DRMTMB_PATH", "/Users/z3437171/Dropbox/Github Local/drmTMB"), quiet = TRUE)
  library(ape); library(parallel)
})
# in-session gate relax (matched mean+scale is rejected in source until this ladder validates it)
try(assignInNamespace("drm_validate_reml_spec", function(spec) invisible(TRUE), ns = "drmTMB"), silent = TRUE)
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

truth <- c(sd_mu = 0.6, sd_sigma = 0.5, rho = 0.5)                 # 2x2 phylo block, well inside
S2c <- chol(matrix(c(0.6^2, 0.5 * 0.6 * 0.5, 0.5 * 0.6 * 0.5, 0.5^2), 2, 2))
pick <- function(vv) c(
  sd_mu    = unname(vv[grep("^sd:mu", names(vv))][1]),
  sd_sigma = unname(vv[grep("^sd:sigma", names(vv))][1]),
  rho      = unname(vv[grep("^cor:phylo", names(vv))][1]))

sim_fit <- function(n, seed) {
  set.seed(seed * 7919L + n)
  tree <- rcoal(n); tree$tip.label <- paste0("sp_", seq_len(n))
  A <- vcv(tree, corr = TRUE); L <- t(chol(A))
  M <- L %*% matrix(rnorm(n * 2), n, 2) %*% S2c                    # a_mu, a_sigma ; Cov = S2 kron A
  x <- rnorm(n)
  sig_i <- exp(log(0.5) + M[, 2])                                  # phylo effect on log-sigma
  d <- data.frame(sp = factor(tree$tip.label, levels = tree$tip.label), x = x,
                  y = 0.3 + 0.7 * x + M[, 1] + rnorm(n, 0, sig_i))
  form <- bf(y ~ x + phylo(1 | p | sp, tree = tree), sigma ~ phylo(1 | p | sp, tree = tree))
  ctrl <- drm_control(optimizer_preset = "robust")
  out <- list()
  for (est in c("ML", "REML")) {
    f <- tryCatch(drmTMB(form, gaussian(), d, REML = (est == "REML"), control = ctrl), error = function(e) e)
    if (inherits(f, "error")) return(NULL)
    pr <- tryCatch(summary(f)$parameters, error = function(e) NULL); if (is.null(pr)) return(NULL)
    out[[est]] <- list(est = pick(setNames(pr$estimate, pr$parm)),
                       pd = tryCatch(isTRUE(f$sdr$pdHess), error = function(e) NA),
                       conv = f$opt$convergence)
  }
  data.frame(n = n, seed = seed, param = names(truth), truth = truth,
             ml = out$ML$est, reml = out$REML$est,
             pd_ml = out$ML$pd, pd_reml = out$REML$pd,
             conv_ml = out$ML$conv, conv_reml = out$REML$conv, row.names = NULL)
}

n_levels <- as.integer(strsplit(Sys.getenv("N_LEVELS", "250,500"), ",")[[1]])
n_seeds  <- as.integer(Sys.getenv("N_SEEDS", "6"))
cores    <- as.integer(Sys.getenv("CORES", "12"))
grid <- expand.grid(seed = seq_len(n_seeds), n = n_levels)
cat(sprintf("q2 ladder: n in {%s} x %d seeds on %d cores\n", paste(n_levels, collapse = ","), n_seeds, cores))
t0 <- Sys.time()
res <- mcmapply(sim_fit, grid$n, grid$seed, SIMPLIFY = FALSE, mc.cores = cores)
cat(sprintf("done %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
res <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
outdir <- Sys.getenv("OUTDIR", "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/2bb06ced-ac15-4169-824d-8cc18d223c51/scratchpad")
write.csv(res, file.path(outdir, "reml_q2_ladder.csv"), row.names = FALSE)
m <- function(z) mean(z, na.rm = TRUE)
agg <- aggregate(cbind(ml, reml) ~ n + param + truth, data = res, FUN = m)
agg$bias_ml <- agg$ml - agg$truth; agg$bias_reml <- agg$reml - agg$truth
cat("\n=== q2 bias(ML) | bias(REML) by n  [KEY: does REML mean-side bias vanish with n?] ===\n")
for (p in c("sd_mu", "sd_sigma", "rho")) {
  cat(sprintf("\n%s (truth %.2f):\n     n   biasML  biasREML\n", p, truth[p]))
  sub <- agg[agg$param == p, ]; sub <- sub[order(sub$n), ]
  for (i in seq_len(nrow(sub))) cat(sprintf("%6d  %+.3f    %+.3f\n", sub$n[i], sub$bias_ml[i], sub$bias_reml[i]))
}
d1 <- res[res$param == "sd_mu", ]
cat(sprintf("\ncompleted reps per n: %s\n", paste(table(d1$n), collapse = " ")))
cat(sprintf("pdHess: ML=%.2f REML=%.2f | P(REML PD | ML PD)=%.2f\n",
            m(as.logical(d1$pd_ml)), m(as.logical(d1$pd_reml)),
            m(as.logical(d1$pd_reml)[as.logical(d1$pd_ml)])))
cat("\nQ2 LADDER DONE\n")
