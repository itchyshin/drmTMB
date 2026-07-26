.libPaths(c("/private/tmp/drmtmb-arc-b-lib", .libPaths()))
setwd("/private/tmp/drmtmb-d1"); pkgload::load_all(".", quiet = TRUE)

# mc-0017-shaped fixture: beta phylo q1 with a DIRECT-SD REGRESSION
#   sd(spp_id, level = "phylogenetic") ~ x_tau
# Ledger truths: alpha_intercept = log(0.30), alpha_x = 0.25.
set.seed(20260726)
g <- 120L; m <- 4L
tree <- ape::rcoal(g); tree$tip.label <- paste0("sp", seq_len(g))
Vphy <- ape::vcv(tree); Vphy <- Vphy / max(Vphy)
L <- chol(Vphy + diag(1e-8, g))

x_tau <- rnorm(g)
alpha0 <- log(0.30); alpha1 <- 0.25
sd_sp  <- exp(alpha0 + alpha1 * x_tau)          # per-species latent SD
u      <- as.numeric(crossprod(L, rnorm(g))) * sd_sp

spp <- rep(seq_len(g), each = m)
x_mu <- rnorm(g * m); x_sigma <- rnorm(g * m)
eta  <- 0.2 + 0.4 * x_mu + u[spp]
mu   <- 1 / (1 + exp(-eta)); phi <- exp(1.2 + 0.3 * x_sigma)
y    <- rbeta(g * m, mu * phi, (1 - mu) * phi)
y    <- pmin(pmax(y, 1e-6), 1 - 1e-6)
dat  <- data.frame(y = y, x_mu = x_mu, x_sigma = x_sigma,
                   spp_id = factor(paste0("sp", spp), levels = tree$tip.label),
                   x_tau = x_tau[spp])

fit <- drmTMB(bf(y ~ x_mu + phylo(1 | spp_id, tree = tree), sigma ~ x_sigma,
                 sd(spp_id, level = "phylogenetic") ~ x_tau),
              family = beta(), data = dat,
              control = drm_control(optimizer_preset = "robust", se_group_sd = FALSE))
cat("converged:", fit$opt$convergence, "\n")

rp <- fit$obj$report()
lsd <- rp[["log_sd_phylo_group"]]
cat(sprintf("AT THE OPTIMUM: predicted log-SD range [%.3f, %.3f]\n", min(lsd), max(lsd)))
cat(sprintf("  default clamp band c(-12,12), margin 3 -> saturates at +/-15\n"))
cat(sprintf("  margin to nearest bound: %.2f\n", 12 - max(abs(lsd))))

for (tgt in c("fixef:sd_phylo(spp_id):(Intercept)", "fixef:sd_phylo(spp_id):x_tau")) {
  ci <- try(confint(fit, parm = tgt, method = "profile",
                    profile_engine = "tmbprofile", profile_precision = "fast"), silent = TRUE)
  if (inherits(ci, "try-error")) { cat(tgt, "-> profile ERROR\n"); next }
  cat(sprintf("%-42s profile [%8.4f, %8.4f] status=%s\n", tgt,
              ci$lower[[1]], ci$upper[[1]], ci$conf.status[[1]]))
}

# THE DECISIVE CHECK: the soft clamp is EXACTLY identity inside [lo, hi]. So if
# the predicted log-SD never leaves the band anywhere the profile explores, a
# clamp cannot move mc-0017's endpoints -- bit-for-bit.
cat("\n=== log-SD excursion over the PROFILE, not just the optimum ===\n")
p <- fit$obj$env$last.par.best
idx <- which(names(p) == "beta_sd_mu")
cat("beta_sd_mu indices:", idx, " at optimum:", round(p[idx], 4), "\n")
xt <- fit$obj$env$data$X_sd_phylo
if (is.null(xt)) xt <- fit$obj$env$data$X_sd_mu
worst <- 0
for (a0 in c(-1.1012, -0.1104)) for (a1 in c(0.2151, 0.6009)) {
  pp <- p; pp[idx] <- c(a0, a1)[seq_along(idx)]
  rr <- fit$obj$report(pp)
  ls2 <- rr[["log_sd_phylo_group"]]
  if (!is.null(ls2)) worst <- max(worst, max(abs(ls2)))
  cat(sprintf("  corner a0=%7.4f a1=%7.4f -> |log-SD| max %.4f\n", a0, a1, max(abs(ls2))))
}
cat(sprintf("\nWORST |log-SD| anywhere on the profile box: %.4f\n", worst))
cat(sprintf("Clamp band |12|; margin remaining: %.4f\n", 12 - worst))
cat(if (worst < 12) "=> A c(-12,12) CLAMP IS EXACT IDENTITY HERE. mc-0017 endpoints are UNCHANGED.\n"
    else "=> the clamp WOULD bind; mc-0017's certified coverage is at risk.\n")
