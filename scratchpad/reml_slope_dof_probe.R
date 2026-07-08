# Why does scale-side REML debias the INTERCEPT SD but not the SLOPE SD?
# ---------------------------------------------------------------------------
# OBSERVATION (scratchpad/reml_provider_ladder.R, 40 paired seeds):
#   spatial g=8  sd_int : ML -0.0378 -> REML +0.0088  (REML>ML 40/40)
#   spatial g=8  sd_slp : ML -0.0704 -> REML -0.0765  (REML>ML  8/40)
#   spatial g=16 sd_slp : ML -0.0499 -> REML -0.0524  (REML>ML  2/40)
# The slope result STRENGTHENS with g => structural, not a small-g artifact.
#
# HYPOTHESIS (mechanical, not mystical):
#   REML corrects the DoF consumed by *fixed* effects on the same linear predictor.
#   The coverage runner fits `sigma ~ spatial(1 + x | site)` -- there is NO fixed `x`
#   on the sigma predictor, so `beta_sigma` is the INTERCEPT ALONE. REML recovers
#   exactly one DoF, and it lands on the intercept variance component. The random
#   slope has no fixed counterpart to restrict, so REML gives it nothing -- and,
#   because the two components share information, the slope SD gets squeezed down.
#
# PREDICTION (falsifiable):
#   Put a fixed `x` on the sigma predictor (`sigma ~ x + spatial(1 + x | site)`),
#   with a matching fixed slope in the DGP, and REML should debias the SLOPE SD too
#   (REML>ML should flip from ~8/40 to ~N/N).
#
# DESIGN: 2 arms, 40 paired seeds each, g = 8, n_each = 20.
#   ARM A (control, reproduces the anomaly):
#     DGP  eta_sigma = b0 + u_i + u_s * x            (NO fixed sigma slope)
#     FIT  sigma ~ spatial(1 + x | site)             (correct; beta_sigma = intercept)
#   ARM B (the test):
#     DGP  eta_sigma = b0 + bx * x + u_i + u_s * x   (fixed sigma slope bx = 0.30)
#     FIT  sigma ~ x + spatial(1 + x | site)         (correct; beta_sigma = int + x)
#
# If the hypothesis holds: A reproduces REML>ML ~8/40 on the slope; B flips to ~40/40.
# If B does NOT flip, the hypothesis is wrong and the slope anomaly needs Noether.
#
# Run: OPENBLAS_NUM_THREADS=1 NOT_CRAN=true R_PROFILE_USER=/dev/null \
#        Rscript --no-init-file scratchpad/reml_slope_dof_probe.R
# ---------------------------------------------------------------------------
suppressMessages(devtools::load_all(".", quiet = TRUE))

N_SEEDS <- as.integer(Sys.getenv("N_SEEDS", "40"))
N_EACH  <- 20L
G       <- 8L
B0      <- -0.90   # sigma intercept
BX      <-  0.30   # FIXED sigma slope, ARM B only
SD_I    <-  0.50
SD_S    <-  0.38

spatial_K <- function(n) {
  labels <- paste0("site_", seq_len(n)); theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(x = cos(theta) + seq_len(n) / (3 * n), y = sin(theta))
  rownames(coords) <- labels
  p <- drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "site")
  list(labels = labels, coords = coords, K = solve(as.matrix(p$precision)))
}
scaled_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`); colnames(out) <- names(sds); out
}
make_data <- function(arm, seed) {
  set.seed(seed)
  o <- spatial_K(G)
  eff <- scaled_effects(o$K, c(i = SD_I, s = SD_S)); rownames(eff) <- o$labels
  ep <- rep(o$labels, each = N_EACH)
  x  <- rep(seq(-1.2, 1.2, length.out = N_EACH), times = G)
  fixed_slope <- if (arm == "B") BX * x else 0
  eta <- B0 + fixed_slope + eff[ep, "i"] + eff[ep, "s"] * x
  y <- 0.40 + 0.25 * x + exp(eta) * stats::rnorm(length(x))
  list(data = data.frame(y = y, x = x, site = ep, stringsAsFactors = FALSE), coords = o$coords)
}
fit_one <- function(arm, sim, reml) {
  coords <- sim$coords
  form <- if (arm == "A") bf(y ~ x, sigma ~ spatial(1 + x | site, coords = coords))
          else            bf(y ~ x, sigma ~ x + spatial(1 + x | site, coords = coords))
  tryCatch(drmTMB(form, family = gaussian(), data = sim$data, REML = reml,
                  control = drm_control(optimizer = list(eval.max = 1400, iter.max = 1400))),
           error = function(e) e)
}
grab <- function(f) {
  if (inherits(f, "error")) return(c(int = NA, slp = NA, conv = NA))
  p <- tryCatch({ s <- summary(f)$parameters; stats::setNames(s$estimate, s$parm) },
                error = function(e) NULL)
  if (is.null(p)) return(c(int = NA, slp = NA, conv = NA))
  ii <- grep("^sd:sigma:.*\\(1 \\|", names(p)); ss <- grep("^sd:sigma:.*\\(0 \\+ x \\|", names(p))
  c(int = if (length(ii)) p[[ii[1]]] else NA,
    slp = if (length(ss)) p[[ss[1]]] else NA, conv = f$opt$convergence)
}

orig <- drmTMB:::drm_validate_reml_spec
assignInNamespace("drm_validate_reml_spec", function(spec) invisible(TRUE), ns = "drmTMB")

cat("ARM A: no fixed sigma slope  (beta_sigma = intercept only)  -> expect slope REML>ML LOW\n")
cat("ARM B: fixed sigma slope     (beta_sigma = intercept + x)   -> PREDICT slope REML>ML HIGH\n\n")
cat(sprintf("%-4s %-5s %9s %10s %9s %9s %9s\n",
            "arm","targ","ML_bias","REML_bias","ML_sd","REML_sd","REML>ML"))
cat(strrep("-", 62), "\n")
for (arm in c("A", "B")) {
  M <- R <- matrix(NA_real_, N_SEEDS, 3, dimnames = list(NULL, c("int","slp","conv")))
  for (s in seq_len(N_SEEDS)) {
    sim <- make_data(arm, 930000L + s)
    M[s, ] <- grab(fit_one(arm, sim, FALSE))
    R[s, ] <- grab(fit_one(arm, sim, TRUE))
  }
  for (tg in c("int","slp")) {
    tr <- if (tg == "int") SD_I else SD_S
    d <- R[, tg] - M[, tg]
    cat(sprintf("%-4s %-5s %+9.4f %+10.4f %9.4f %9.4f %5d/%-3d\n", arm, tg,
      mean(M[,tg],na.rm=TRUE) - tr, mean(R[,tg],na.rm=TRUE) - tr,
      mean(M[,tg],na.rm=TRUE), mean(R[,tg],na.rm=TRUE),
      sum(d > 0, na.rm = TRUE), sum(!is.na(d))))
  }
  cat(sprintf("     conv0: ML %d/%d  REML %d/%d\n\n",
              sum(M[,"conv"]==0,na.rm=TRUE), N_SEEDS, sum(R[,"conv"]==0,na.rm=TRUE), N_SEEDS))
}
assignInNamespace("drm_validate_reml_spec", orig, ns = "drmTMB")
cat("VERDICT RULE\n")
cat("  B slope REML>ML >= ~34/40 AND REML_sd > ML_sd  => hypothesis CONFIRMED:\n")
cat("     REML debiases a variance component only when its FIXED counterpart exists.\n")
cat("  B slope still ~8/40                            => hypothesis REFUTED; escalate to Noether.\n")
