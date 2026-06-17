# Phase 5 recovery sim: coupled-q4 "Model E" with KNOWN truth, to test whether
# the correlation penalty (a) reaches a positive-definite Hessian, (b) recovers
# the true phylo correlations or follows the prior, and (c) improves with
# within-species replication. Small fixed tree => fast fits => can sweep cor_sd.
#
# Run: Rscript inst/sim/run/phylo_penalty_q4_recovery.R
suppressMessages({
  devtools::load_all(".", quiet = TRUE)
  library(ape)
})
set.seed(20260616)

# --- true coupled-q4 parameters (axis order: mu1, mu2, sigma1, sigma2) ---
true_sd <- c(mu1 = 0.35, mu2 = 0.45, sigma1 = 0.45, sigma2 = 0.55)
true_Rax <- matrix(c(
  1.0, 0.3, 0.2, 0.0,
  0.3, 1.0, 0.0, 0.6, # cor(mu2, sigma2) = 0.6 (the strong mean-scale, as on real data)
  0.2, 0.0, 1.0, 0.3,
  0.0, 0.6, 0.3, 1.0
), 4, 4, byrow = TRUE)
stopifnot(all(eigen(true_Rax, only.values = TRUE)$values > 0)) # PD check
true_b <- c(mu1 = 0, mu2 = 0, lsig1 = log(0.40), lsig2 = log(0.50))
true_rho12 <- 0.3
C_axis <- diag(true_sd) %*% true_Rax %*% diag(true_sd)

simulate_q4 <- function(n_tip, n_each = 1L, seed = 1L) {
  set.seed(seed)
  tree <- rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  R_phylo <- vcv.phylo(tree, corr = TRUE)
  # latent field: vec(A) ~ MVN(0, C_axis (x) R_phylo); A is n_tip x 4
  L <- t(chol(kronecker(C_axis, R_phylo)))
  A <- matrix(as.vector(L %*% rnorm(4L * n_tip)), nrow = n_tip, ncol = 4L)
  mu1 <- true_b[["mu1"]] + A[, 1]
  mu2 <- true_b[["mu2"]] + A[, 2]
  sig1 <- exp(true_b[["lsig1"]] + A[, 3])
  sig2 <- exp(true_b[["lsig2"]] + A[, 4])
  Lr <- chol(matrix(c(1, true_rho12, true_rho12, 1), 2, 2))
  rows <- lapply(seq_len(n_tip), function(i) {
    E <- matrix(rnorm(2L * n_each), ncol = 2L) %*% Lr
    data.frame(
      y1 = mu1[i] + sig1[i] * E[, 1],
      y2 = mu2[i] + sig2[i] * E[, 2],
      tree_tip = tree$tip.label[i]
    )
  })
  list(data = do.call(rbind, rows), tree = tree)
}

fit_label <- function(dat, tree, pen, label) {
  t0 <- proc.time()[["elapsed"]]
  model_E <- bf(
    mu1 = y1 ~ 1 + phylo(1 | p | tree_tip, tree = tree),
    mu2 = y2 ~ 1 + phylo(1 | p | tree_tip, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | tree_tip, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | tree_tip, tree = tree),
    rho12 = ~1
  )
  fit <- tryCatch(
    drmTMB(model_E,
      family = biv_gaussian(), data = dat, penalty = pen,
      control = drm_control(optimizer_preset = "robust")
    ),
    error = function(e) {
      cat(sprintf("[%s] ERROR: %s\n", label, conditionMessage(e)))
      NULL
    }
  )
  if (is.null(fit)) return(invisible(NULL))
  cat(sprintf(
    "[%s] conv=%s pdHess=%s grad=%.3g %.0fs\n",
    label, fit$opt$convergence, isTRUE(fit$sdr$pdHess),
    max(abs(fit$obj$gr(fit$opt$par))), proc.time()[["elapsed"]] - t0
  ))
  cors <- fit$corpars$phylo
  names(cors) <- sub(":\\(Intercept\\)", "", sub(" \\| p \\| tree_tip", "", names(cors)))
  print(round(cors, 3))
  invisible(fit)
}

cat("TRUTH: cor(mu1,mu2)=0.30 cor(mu1,sigma1)=0.20 cor(mu1,sigma2)=0.00 cor(mu2,sigma1)=0.00 cor(mu2,sigma2)=0.60 cor(sigma1,sigma2)=0.30\n")
cat("TRUTH SDs: mu1=0.35 mu2=0.45 sigma1=0.45 sigma2=0.55 ; rho12=0.30\n\n")
cat("===== VALIDATION: n_tip=100, 1 obs/tip, penalize-off =====\n")
v <- simulate_q4(100L, 1L, seed = 11L)
fit_label(v$data, v$tree, NULL, "validate n100 off")

cat("\n===== GRID: n_tip=300, 1 obs/tip =====\n")
g <- simulate_q4(300L, 1L, seed = 21L)
fit_label(g$data, g$tree, NULL, "n300 off")
fit_label(g$data, g$tree, drm_phylo_penalty(1, 0.05, cor_sd = 1.0), "n300 cor1.0")
fit_label(g$data, g$tree, drm_phylo_penalty(1, 0.05, cor_sd = 0.5), "n300 cor0.5")
fit_label(g$data, g$tree, drm_phylo_penalty(1, 0.05, cor_sd = 0.25), "n300 cor0.25")

cat("\n===== REPLICATION: n_tip=300, 3 obs/tip =====\n")
r <- simulate_q4(300L, 3L, seed = 31L)
fit_label(r$data, r$tree, NULL, "n300x3 off")
fit_label(r$data, r$tree, drm_phylo_penalty(1, 0.05, cor_sd = 0.5), "n300x3 cor0.5")

cat("\nDONE\n")
