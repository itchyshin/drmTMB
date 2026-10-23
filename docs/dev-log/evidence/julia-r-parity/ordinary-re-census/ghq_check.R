# Same-model, different-integrator check for the sigma-side random intercept
# (parity leaf A5, G2 follow-through on the PARITY_FAIL cell).
#
# DRM.jl integrates b_g in log sigma_i = x_i' beta_sigma + b_g by 32-node
# Gauss-Hermite quadrature (src/gaussian_ranef.jl, _fit_sigma_ranef_gaussian);
# drmTMB's TMB engine uses the Laplace approximation. This script re-implements
# DRM.jl's GHQ marginal in R (same nodes, Golub-Welsch), evaluates it at the
# Julia estimate, and asks: does it reproduce Julia's logLik? It also records
# both engines' convergence evidence and the GHQ marginal at K = 64 so the
# K = 32 value is shown converged in K. Output: ghq-check.tsv + stdout.
# Usage: OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<pin> Rscript ghq_check.R <outdir>
suppressMessages(devtools::load_all(".", quiet = TRUE))
args <- commandArgs(trailingOnly = TRUE)
outdir <- if (length(args) >= 1L) args[[1]] else dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(outdir, "make_data.R"))
d <- make_data("gaussian_sigma_random_intercept")
f <- bf(y ~ x, sigma ~ (1 | g))
ft <- drmTMB(f, family = gaussian(), data = d, engine = "tmb", REML = FALSE)
fj <- suppressWarnings(drmTMB(f, family = gaussian(), data = d, engine = "julia", REML = FALSE))
fj_tight <- suppressWarnings(drmTMB(f, family = gaussian(), data = d, engine = "julia", REML = FALSE,
                                     control = drm_control(optimizer = list(g_tol = 1e-10))))

gauss_hermite <- function(K) {
  b <- sqrt(seq_len(K - 1) / 2)
  J <- matrix(0, K, K); J[cbind(1:(K - 1), 2:K)] <- b; J[cbind(2:K, 1:(K - 1))] <- b
  E <- eigen(J, symmetric = TRUE)
  ord <- order(E$values)
  list(z = E$values[ord], w = sqrt(pi) * E$vectors[1, ord]^2)
}
# DRM.jl's nll, transcribed: per group A_g = sum eta0_i, B_g = sum r_i^2 e^{-2 eta0_i};
# log-lik_g = -0.5 log(pi) - 0.5 m_g log(2 pi) - A_g + logsumexp_k(log w_k - m_g delta_k - 0.5 e^{-2 delta_k} B_g),
# delta_k = sqrt(2) sigma_b z_k.
ghq_loglik <- function(beta_mu, beta_sigma, sigma_b, K) {
  gh <- gauss_hermite(K)
  Xmu <- model.matrix(~ x, d); Xs <- model.matrix(~ 1, d)
  eta0 <- drop(Xs %*% beta_sigma); r <- d$y - drop(Xmu %*% beta_mu)
  re <- r^2 * exp(-2 * eta0)
  ll <- 0
  for (g in levels(d$g)) {
    idx <- which(d$g == g); mg <- length(idx)
    Ag <- sum(eta0[idx]); Bg <- sum(re[idx])
    delta <- sqrt(2) * sigma_b * gh$z
    terms <- log(gh$w) - mg * delta - 0.5 * exp(-2 * delta) * Bg
    mx <- max(terms)
    ll <- ll + (-0.5 * log(pi) - 0.5 * mg * log(2 * pi) - Ag + mx + log(sum(exp(terms - mx))))
  }
  ll
}
bj <- fixef(fj); bt <- fixef(ft)
sb_j <- unname(fj$sdpars$sigma[[1]]); sb_t <- unname(ft$sdpars$sigma[[1]])
ll_j <- as.numeric(logLik(fj)); ll_t <- as.numeric(logLik(ft))
ghq32_at_j <- ghq_loglik(bj$mu, bj$sigma, sb_j, 32)
ghq64_at_j <- ghq_loglik(bj$mu, bj$sigma, sb_j, 64)
ghq32_at_t <- ghq_loglik(bt$mu, bt$sigma, sb_t, 32)
grad_t <- ft$obj$gr(ft$opt$par)
out <- data.frame(
  quantity = c("logLik_tmb_laplace", "logLik_julia_ghq32", "ghq32_R_at_julia_estimate", "ghq64_R_at_julia_estimate",
               "ghq32_R_at_tmb_estimate", "abs_diff_julia_vs_R_ghq32", "abs_diff_ghq32_vs_ghq64_at_julia",
               "tmb_max_abs_outer_gradient", "julia_converged", "julia_logLik_g_tol_1e-10", "julia_sigma_b", "tmb_sigma_b",
               "julia_estim_method"),
  value = c(format(ll_t, digits = 15), format(ll_j, digits = 15), format(ghq32_at_j, digits = 15), format(ghq64_at_j, digits = 15),
            format(ghq32_at_t, digits = 15), format(abs(ll_j - ghq32_at_j), digits = 3), format(abs(ghq32_at_j - ghq64_at_j), digits = 3),
            format(max(abs(grad_t)), digits = 3), as.character(isTRUE(fj$bridge$converged)), format(as.numeric(logLik(fj_tight)), digits = 15),
            format(sb_j, digits = 10), format(sb_t, digits = 10), as.character(fj$bridge$estim_method)),
  stringsAsFactors = FALSE
)
print(out, right = FALSE)
write.table(out, file.path(outdir, "ghq-check.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
