# Known-truth recovery for the LOCATION-SCALE-SCALE model (docs/design/222).
# ---------------------------------------------------------------------------
#   (z1, z2) ~ N(0, R (x) C),  R = [[1, rho], [rho, 1]],  C = Q^-1 (tip correlation)
#   s_i = exp(w_i' beta_s)            # sd_phylo(id) ~ climate
#   mu_i     = x_i' beta_mu + s_i * z1_i
#   log sig_i= beta_sigma0  +  tau * z2_i
#   y_i ~ N(mu_i, sig_i^2)
#
# THE HAZARD THIS TEST EXISTS FOR: before this change the C++ multiplied EVERY
# endpoint's field by the mu per-group SD surface, i.e. it pinned tau == s_i. That
# model fits cleanly and returns plausible numbers. If the bug were still present,
# `tau` could not recover independently of the sd_phylo surface -- which is exactly
# what arm A below checks. Arm B is a null control (tau = 0). Arm C checks that the
# q_phylo == 1 path is unchanged.
#
# Run: OPENBLAS_NUM_THREADS=1 NOT_CRAN=true R_PROFILE_USER=/dev/null \
#        Rscript --no-init-file scratchpad/location_scale_scale_recovery.R
# ---------------------------------------------------------------------------
suppressMessages(devtools::load_all(".", quiet = TRUE))
stopifnot(requireNamespace("ape", quietly = TRUE))

N_SEEDS <- as.integer(Sys.getenv("N_SEEDS", "30"))
N_TIP   <- as.integer(Sys.getenv("N_TIP", "150"))

BETA_MU  <- c(0.30, 0.50)   # intercept, x
BETA_S   <- c(-0.70, 0.60)  # sd_phylo(id) ~ climate : intercept, slope
BETA_SIG <- -0.90           # sigma ~ 1
TAU      <- 0.45            # phylo SD of the residual-scale effect
RHO      <- 0.50            # mu <-> sigma phylogenetic correlation

simulate_lss <- function(seed, tau = TAU, rho = RHO, n_tip = N_TIP) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  sp <- tree$tip.label
  C <- drmTMB:::drm_phylo_tip_covariance(tree)
  L <- t(chol(C + diag(1e-8, n_tip)))
  # correlated standardized fields: (z1, z2) with corr rho, each ~ N(0, C)
  e1 <- stats::rnorm(n_tip)
  e2 <- rho * e1 + sqrt(1 - rho^2) * stats::rnorm(n_tip)
  z1 <- as.vector(L %*% e1)
  z2 <- as.vector(L %*% e2)

  climate <- stats::rnorm(n_tip)
  s <- exp(BETA_S[[1L]] + BETA_S[[2L]] * climate)   # species-specific location SD
  x <- stats::rnorm(n_tip)
  mu <- BETA_MU[[1L]] + BETA_MU[[2L]] * x + s * z1
  log_sig <- BETA_SIG + tau * z2
  y <- stats::rnorm(n_tip, mu, exp(log_sig))
  list(tree = tree,
       data = data.frame(species = sp, x = x, climate = climate, y = y,
                         stringsAsFactors = FALSE))
}

fit_lss <- function(sim, reml = FALSE) {
  tree <- sim$tree                       # bare symbol: bf() uses NSE
  tryCatch(suppressWarnings(drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree),
       sigma ~ 1 + phylo(1 | species, tree = tree),
       sd_phylo(species) ~ climate),
    family = gaussian(), data = sim$data, REML = reml,
    control = drm_control(optimizer = list(eval.max = 2000, iter.max = 2000))
  )), error = function(e) e)
}

pull <- function(f) {
  if (inherits(f, "error")) return(NULL)
  p <- tryCatch({ s <- summary(f)$parameters; stats::setNames(s$estimate, s$parm) },
                error = function(e) NULL)
  cf <- tryCatch({ s <- summary(f)$coefficients; stats::setNames(s$estimate, s$parm) },
                 error = function(e) NULL)
  all <- c(p, cf)
  grab <- function(rx) { i <- grep(rx, names(all)); if (length(i)) unname(all[[i[[1L]]]]) else NA_real_ }
  c(beta_s_int   = grab("sd_phylo.*Intercept"),
    beta_s_slope = grab("sd_phylo.*climate"),
    tau          = grab("^sd:sigma:phylo"),
    rho          = grab("^(cor|rho).*phylo"),
    beta_mu_x    = grab("^fixef:mu:x|^mu:x$|^x$"),
    conv         = f$opt$convergence)
}

run_arm <- function(label, tau, rho, n_seeds = N_SEEDS) {
  cat("\n===", label, " (tau =", tau, ", rho =", rho, ", n_tip =", N_TIP, ",", n_seeds, "seeds) ===\n")
  M <- matrix(NA_real_, n_seeds, 6,
              dimnames = list(NULL, c("beta_s_int","beta_s_slope","tau","rho","beta_mu_x","conv")))
  errs <- character(0)
  for (s in seq_len(n_seeds)) {
    f <- fit_lss(simulate_lss(940000L + s, tau = tau, rho = rho))
    if (inherits(f, "error")) { errs <- c(errs, conditionMessage(f)); next }
    v <- pull(f); if (!is.null(v)) M[s, ] <- v
  }
  if (length(errs)) { cat("  FIT ERRORS:", length(errs), "->", substr(errs[[1L]], 1, 90), "\n") }
  truth <- c(beta_s_int = BETA_S[[1L]], beta_s_slope = BETA_S[[2L]],
             tau = tau, rho = rho, beta_mu_x = BETA_MU[[2L]])
  cat(sprintf("  %-13s %9s %9s %9s %6s\n", "param", "truth", "mean", "bias", "n"))
  for (nm in names(truth)) {
    v <- M[, nm]
    cat(sprintf("  %-13s %9.3f %9.3f %+9.3f %6d\n",
                nm, truth[[nm]], mean(v, na.rm = TRUE),
                mean(v, na.rm = TRUE) - truth[[nm]], sum(!is.na(v))))
  }
  cat(sprintf("  conv0: %d/%d\n", sum(M[, "conv"] == 0, na.rm = TRUE), n_seeds))
  invisible(M)
}

cat("############ ARM A: recovery (the hazard test) ############\n")
cat("If the C++ still pinned tau == s_i, `tau` could not recover to", TAU, "\n")
A <- run_arm("A: full location-scale-scale", TAU, RHO)

cat("\n############ ARM B: null control (tau = 0) ############\n")
cat("The sd_phylo surface must still recover while tau collapses toward 0.\n")
B <- run_arm("B: null residual-scale phylo", 0, 0, n_seeds = max(10L, N_SEEDS %/% 2L))

cat("\n############ ARM C: byte-identity of the q_phylo == 1 path ############\n")
sim <- simulate_lss(999001L)
tree <- sim$tree
f1 <- suppressWarnings(drmTMB(
  bf(y ~ x + phylo(1 | species, tree = tree), sd_phylo(species) ~ climate),
  family = gaussian(), data = sim$data,
  control = drm_control(optimizer = list(eval.max = 2000, iter.max = 2000))))
cat("  q_phylo == 1 (no sigma phylo): conv =", f1$opt$convergence,
    " logLik =", sprintf("%.10f", as.numeric(stats::logLik(f1))), "\n")
cat("  (compare against the value recorded before the C++ change)\n")

cat("\nVERDICT RULE\n")
cat("  ARM A: |bias| small for beta_s_slope AND tau AND rho  => the endpoints are separated.\n")
cat("  ARM B: tau -> ~0 while beta_s_slope still recovers    => no leakage from the surface.\n")
cat("  ARM C: logLik unchanged vs pre-change                 => q_phylo == 1 is untouched.\n")
