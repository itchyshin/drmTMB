# S3 evidence: reduced block-diagonal q4 (phylo location block ⊥ phylo scale block),
# scale-side RANDOM phylo under REML. Question: does per-group REPLICATION rescue the
# scale-side collapse seen at 1 obs/species? (Shinichi's "random dispersion needs
# replication" doctrine; Model A+ escape uses FIXED sd_phylo instead.)
# Axes: n_each (replication) is the key one; n_tip and seed secondary.
suppressPackageStartupMessages({
  devtools::load_all(Sys.getenv("DRMTMB_PATH", "/Users/z3437171/Dropbox/Github Local/drmTMB"), quiet = TRUE)
  library(ape); library(parallel)
})
assignInNamespace("drm_validate_reml_spec_biv", function(spec) invisible(TRUE), ns = "drmTMB")
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

# truth: loc SDs .6/.5 cor .4 ; scale SDs .4/.3 cor .3 ; block-diagonal (loc ⊥ scale)
Gl <- chol(matrix(c(.6^2, .4 * .6 * .5, .4 * .6 * .5, .5^2), 2, 2))
Gs <- chol(matrix(c(.4^2, .3 * .4 * .3, .3 * .4 * .3, .3^2), 2, 2))
truth <- c(sd_mu1 = .6, sd_mu2 = .5, sd_s1 = .4, sd_s2 = .3, cor_mu = .4, cor_s = .3)

pick <- function(pr) {
  g <- function(rx) unname(pr$estimate[grep(rx, pr$parm)][1])
  c(sd_mu1 = g("sd:mu:mu1"), sd_mu2 = g("sd:mu:mu2"),
    sd_s1 = g("sd:mu:sigma1"), sd_s2 = g("sd:mu:sigma2"),
    cor_mu = g("cor\\(mu1"), cor_s = g("cor\\(sigma1"))
}

sim_fit <- function(n_tip, n_each, seed) {
  set.seed(seed * 7919L + n_tip * 13L + n_each)
  tree <- rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- vcv(tree, corr = TRUE); L <- t(chol(A))
  Am <- L %*% matrix(rnorm(n_tip * 2), n_tip, 2) %*% Gl
  As <- L %*% matrix(rnorm(n_tip * 2), n_tip, 2) %*% Gs
  tip <- rep(seq_len(n_tip), each = n_each); n <- n_tip * n_each
  s1 <- exp(log(.5) + As[tip, 1]); s2 <- exp(log(.6) + As[tip, 2])
  d <- data.frame(sp = factor(tree$tip.label[tip], levels = tree$tip.label),
                  y1 = 0.3 + Am[tip, 1] + rnorm(n, 0, s1),
                  y2 = 0.7 + Am[tip, 2] + rnorm(n, 0, s2))
  form <- bf(mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree),
             mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
             sigma1 = ~ 1 + phylo(1 | ps | sp, tree = tree),
             sigma2 = ~ 1 + phylo(1 | ps | sp, tree = tree), rho12 = ~ 1)
  f <- tryCatch(suppressWarnings(drmTMB(form, biv_gaussian(), d, REML = TRUE,
                control = drm_control(optimizer_preset = "robust"))), error = function(e) NULL)
  if (is.null(f)) return(NULL)
  est <- tryCatch(pick(summary(f)$parameters), error = function(e) NULL); if (is.null(est)) return(NULL)
  data.frame(n_tip = n_tip, n_each = n_each, seed = seed, param = names(truth), truth = truth,
             est = est[names(truth)], pd = isTRUE(f$sdr$pdHess), conv = f$opt$convergence, row.names = NULL)
}

n_tips  <- as.integer(strsplit(Sys.getenv("N_TIPS", "150,300"), ",")[[1]])
n_eachs <- as.integer(strsplit(Sys.getenv("N_EACHS", "1,3,5"), ",")[[1]])
n_seeds <- as.integer(Sys.getenv("N_SEEDS", "6"))
cores   <- as.integer(Sys.getenv("CORES", "10"))
grid <- expand.grid(seed = seq_len(n_seeds), n_each = n_eachs, n_tip = n_tips)
cat(sprintf("blockdiag replication ladder: n_tip{%s} x n_each{%s} x %d seeds on %d cores\n",
            paste(n_tips, collapse = ","), paste(n_eachs, collapse = ","), n_seeds, cores))
t0 <- Sys.time()
res <- mcmapply(sim_fit, grid$n_tip, grid$n_each, grid$seed, SIMPLIFY = FALSE, mc.cores = cores)
cat(sprintf("done %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
res <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
outdir <- Sys.getenv("OUTDIR", "/Users/z3437171/Dropbox/Github Local/drmTMB/scratchpad")
write.csv(res, file.path(outdir, "reml_blockdiag_replication.csv"), row.names = FALSE)

d1 <- res[res$param == "sd_mu1", ]
cat("\n=== pdHess rate + scale-cor collapse by (n_tip, n_each) [KEY: replication fixes the collapse] ===\n")
cat("  n_tip n_each  pdHess  conv0   mean|cor_s|  collapse(|cor_s|>.98)\n")
for (nt in n_tips) for (ne in n_eachs) {
  sub <- d1[d1$n_tip == nt & d1$n_each == ne, ]
  cs <- res[res$n_tip == nt & res$n_each == ne & res$param == "cor_s", "est"]
  cat(sprintf("%7d %6d  %.2f    %.2f    %+.3f      %.2f\n", nt, ne,
              mean(sub$pd, na.rm = TRUE), mean(sub$conv == 0, na.rm = TRUE),
              mean(cs, na.rm = TRUE), mean(abs(cs) > .98, na.rm = TRUE)))
}
m <- function(z) mean(z, na.rm = TRUE)
agg <- aggregate(est ~ n_each + param + truth, data = res, FUN = m)
agg$bias <- agg$est - agg$truth
cat("\n=== bias by n_each (pooled over n_tip) ===\n")
for (p in names(truth)) {
  sub <- agg[agg$param == p, ]; sub <- sub[order(sub$n_each), ]
  cat(sprintf("%-8s truth %+.2f : ", p, truth[p]))
  cat(paste(sprintf("n_each=%d bias %+.3f", sub$n_each, sub$bias), collapse = " | "), "\n")
}
cat("\nBLOCKDIAG REPLICATION LADDER DONE\n")
