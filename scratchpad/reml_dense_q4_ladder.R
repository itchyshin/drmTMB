# (2) DENSE q4 phylo location-scale under ML vs REML, at ADEQUATE INFORMATION.
# The q4_signflip_diagnostic showed: (a) the endpoint mapping is CORRECT (no sign-flip
# bug -- the single nonzero DGP correlation lands on the right pair with the right
# sign); (b) the earlier "collapse / sign-flip" was an UNDER-POWERED fit (n_each=1..5).
# With replication (n_each=10) and n_tip>=200 the dense q4 converges (pdHess TRUE) and
# recovers. Question here: does REML also converge + recover (and debias vs ML)?
# Truth: SDs .5/.5/.4/.4 ; cor(mu1,sigma1)=+0.6 ; all other correlations 0.
suppressPackageStartupMessages({devtools::load_all(".", quiet = TRUE); library(ape); library(parallel)})
assignInNamespace("drm_validate_reml_spec_biv", function(spec) invisible(TRUE), ns = "drmTMB")
Sys.setenv(OPENBLAS_NUM_THREADS = "1")
sds <- c(.5, .5, .4, .4); R <- diag(4); R[1, 3] <- R[3, 1] <- 0.6
Sig <- diag(sds) %*% R %*% diag(sds)

sim <- function(n_tip, n_each, seed) {
  set.seed(seed * 5077L + n_tip); n <- n_tip * n_each
  tree <- rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- vcv(tree, corr = TRUE); L <- t(chol(A))
  a <- L %*% matrix(rnorm(n_tip * 4), n_tip, 4) %*% chol(Sig)
  tip <- rep(seq_len(n_tip), each = n_each)
  d <- data.frame(sp = factor(tree$tip.label[tip], levels = tree$tip.label),
    y1 = .3 + a[tip, 1] + rnorm(n, 0, exp(log(.5) + a[tip, 3])),
    y2 = .6 + a[tip, 2] + rnorm(n, 0, exp(log(.6) + a[tip, 4])))
  form <- bf(mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree), mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
             sigma1 = ~ 1 + phylo(1 | p | sp, tree = tree), sigma2 = ~ 1 + phylo(1 | p | sp, tree = tree),
             rho12 = ~ 1)
  o <- list()
  for (est in c("ML", "REML")) {
    f <- tryCatch(suppressWarnings(drmTMB(form, biv_gaussian(), d, REML = (est == "REML"),
           control = drm_control(optimizer_preset = "robust"))), error = function(e) NULL)
    if (is.null(f)) return(NULL)
    pr <- summary(f)$parameters
    sd <- pr$estimate[grep("^sd:", pr$parm)]; cc <- pr$estimate[grep("^cor", pr$parm)]
    if (length(sd) < 4L || length(cc) < 6L) return(NULL)
    o[[est]] <- list(sd = sd[1:4], target = cc[2], maxother = max(abs(cc[-2])),
                     pd = isTRUE(f$sdr$pdHess), conv = f$opt$convergence)
  }
  data.frame(n_tip = n_tip, n_each = n_each, seed = seed,
    sd_ml = I(list(o$ML$sd)), sd_reml = I(list(o$REML$sd)),
    tgt_ml = o$ML$target, tgt_reml = o$REML$target,
    oth_ml = o$ML$maxother, oth_reml = o$REML$maxother,
    pd_ml = o$ML$pd, pd_reml = o$REML$pd, conv_ml = o$ML$conv, conv_reml = o$REML$conv)
}

g <- expand.grid(seed = 1:4, n_each = 10L, n_tip = c(200L, 300L))
res <- do.call(rbind, mcmapply(sim, g$n_tip, g$n_each, g$seed, SIMPLIFY = FALSE, mc.cores = 8))
m <- function(z) mean(z, na.rm = TRUE)
cat("=== DENSE q4 ML vs REML (n_each=10, 4 seeds) | truth cor(mu1,sig1)=+0.60, other cors 0 ===\n")
for (nt in c(200L, 300L)) {
  s <- res[res$n_tip == nt, ]
  sdml <- colMeans(do.call(rbind, s$sd_ml)); sdrl <- colMeans(do.call(rbind, s$sd_reml))
  cat(sprintf("n_tip=%d  pdHess ML=%.2f REML=%.2f | conv0 ML=%.2f REML=%.2f\n",
      nt, m(s$pd_ml), m(s$pd_reml), m(s$conv_ml == 0), m(s$conv_reml == 0)))
  cat(sprintf("   SDs   ML %s | REML %s   (truth 0.50/0.50/0.40/0.40)\n",
      paste(sprintf("%.2f", sdml), collapse = "/"), paste(sprintf("%.2f", sdrl), collapse = "/")))
  cat(sprintf("   target cor  ML %+.3f  REML %+.3f | max|other cor| ML %.2f REML %.2f\n",
      m(s$tgt_ml), m(s$tgt_reml), m(s$oth_ml), m(s$oth_reml)))
}
cat("\nDENSE Q4 LADDER DONE\n")
