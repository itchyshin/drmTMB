# (2) q4 dense sign-flip diagnostic.
# The reported sign-flip appears in BOTH ML and REML -> almost certainly a
# DGP<->endpoint-ordering mapping issue, not the estimator. Isolate it: build a dense
# q4 phylo block whose 4x4 correlation matrix has EXACTLY ONE nonzero entry
# (cor(mu1, sigma1) = +0.6). Then read which estimated correlation is nonzero, and
# with what sign. If cor(mu1,sigma1) ~ +0.6 -> mapping is correct (no bug).
# Latent draw order: (a_mu1, a_mu2, a_sig1, a_sig2). Replicated (n_each=5) so the
# dense q4 is identifiable (scale-side random phylo needs replication).
suppressPackageStartupMessages({devtools::load_all(".", quiet = TRUE); library(ape)})
Sys.setenv(OPENBLAS_NUM_THREADS = "1")
set.seed(101)
n_tip <- 150L; n_each <- 5L; n <- n_tip * n_each
tree <- rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
A <- vcv(tree, corr = TRUE); L <- t(chol(A))

sds <- c(mu1 = .5, mu2 = .5, sig1 = .4, sig2 = .4)
R <- diag(4); dimnames(R) <- list(names(sds), names(sds))
R["mu1", "sig1"] <- R["sig1", "mu1"] <- 0.6      # <<< the ONLY nonzero correlation
Sig <- diag(sds) %*% R %*% diag(sds)
cat("DGP correlation matrix (order mu1, mu2, sig1, sig2):\n"); print(R)

# a[i, ] ~ N(0, Sig), phylo-correlated across tips: A_chol %*% Z %*% chol(Sig)
a <- L %*% matrix(rnorm(n_tip * 4), n_tip, 4) %*% chol(Sig)
colnames(a) <- names(sds)
tip <- rep(seq_len(n_tip), each = n_each)
d <- data.frame(
  sp = factor(tree$tip.label[tip], levels = tree$tip.label),
  y1 = 0.3 + a[tip, "mu1"] + rnorm(n, 0, exp(log(0.5) + a[tip, "sig1"])),
  y2 = 0.6 + a[tip, "mu2"] + rnorm(n, 0, exp(log(0.6) + a[tip, "sig2"]))
)
form <- bf(mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree),
           mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
           sigma1 = ~ 1 + phylo(1 | p | sp, tree = tree),
           sigma2 = ~ 1 + phylo(1 | p | sp, tree = tree), rho12 = ~ 1)

f <- suppressWarnings(drmTMB(form, biv_gaussian(), d, REML = FALSE,
       control = drm_control(optimizer_preset = "robust")))
cat(sprintf("\nML fit: conv %d  pdHess %s\n", f$opt$convergence, isTRUE(f$sdr$pdHess)))
pr <- summary(f)$parameters
cc <- pr[grep("^cor", pr$parm), c("parm", "estimate")]
ss <- pr[grep("^sd:", pr$parm), c("parm", "estimate")]
cat("\n--- estimated SDs (truth mu1=.5 mu2=.5 sig1=.4 sig2=.4) ---\n"); print(ss, row.names = FALSE)
cat("\n--- estimated CORRELATIONS (truth: ONLY cor(mu1,sigma1)=+0.6, rest 0) ---\n")
print(cc, row.names = FALSE)
cat("\nVERDICT: the nonzero estimate should sit on the mu1<->sigma1 pair with sign +.\n")
cat("Q4 SIGNFLIP DIAGNOSTIC DONE\n")
