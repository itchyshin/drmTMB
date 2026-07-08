# Recovery ladder: scale-side REML for NON-phylo structured providers
# ---------------------------------------------------------------------------
# Gates the relaxation of R/drmTMB.R:2002-2007 / 2076-2081, which reject
# spatial/animal/relmat structured effects under REML with the reason
# "not validated yet".
#
# Standing rule: never condemn (or admit) an estimator on one small-g cell.
# Run the g-ladder. Three signals for a healthy ML-vs-REML panel:
#   (1) bias -> 0 with g for BOTH estimators
#   (2) REML's variance component >= ML's (the debiasing direction)
#       *** CAVEAT (2026-07-08, Shinichi): signal (2) is NOT a theorem. ***
#       REML > ML is guaranteed only for (a) the residual variance of a linear model
#       (REML = ML * n/(n-p)) and (b) balanced one-way random effects
#       (sigma2_a,ML = sigma2_a,REML - MSA/(a*n)). With MULTIPLE variance components,
#       unbalanced data, boundary truncation at 0, or a non-linear variance function
#       (this model: sigma^2 = exp(2*eta_sigma), approximate Laplace/adjusted-profile
#       REML), NO ordering theorem exists. Expect (2) only for the component whose
#       FIXED counterpart REML actually restricts. Empirically here: it holds for the
#       intercept SD (40/40 every cell) and REVERSES for the slope SD (2/40) --
#       because `sigma ~ spatial(1 + x | site)` has no fixed `x`, so `beta_sigma` is
#       the intercept alone. Do not treat a reversal as an implementation bug.
#   (3) paired REML>ML overwhelming for the target being admitted
#
# NOTE ON PRECISION: at N_SEEDS=40 the MCSE of a bias estimate is ~0.02, so absolute
# biases are good to about +/-0.04 (95%). Only the PAIRED counts (40/40, 2/40) are
# sharp. Do not certify a cell on the unpaired bias column of this table.
#
# Prior (30 seeds, g=8): REML debiases the INTERCEPT SD (30/30 both providers)
# and slightly WORSENS the SLOPE SD (8/30, 5/30). This ladder tests whether that
# split persists across g -- i.e. whether it is a small-g artifact or structural.
#
# `animal` uses a FIXED 8-animal pedigree, so it does not sweep g (runner note,
# tools/run-structured-re-sigma-slope-coverage-grid.R:340-341).
#
# Run: OPENBLAS_NUM_THREADS=1 NOT_CRAN=true R_PROFILE_USER=/dev/null \
#        Rscript --no-init-file scratchpad/reml_provider_ladder.R
# ---------------------------------------------------------------------------
suppressMessages(devtools::load_all(".", quiet = TRUE))

N_SEEDS <- as.integer(Sys.getenv("N_SEEDS", "40"))
N_EACH  <- 20L
TRUTH <- list(mu_intercept = .40, mu_x = .25, log_sigma_intercept = -.90,
              sd_sigma_intercept = .50, sd_sigma_x = .38)

spatial_K <- function(n) {
  labels <- paste0("site_", seq_len(n)); theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(x = cos(theta) + seq_len(n) / (3 * n), y = sin(theta))
  rownames(coords) <- labels
  p <- drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "site")
  list(labels = labels, coords = coords, K = solve(as.matrix(p$precision)))
}
relmat_K <- function(n) {
  labels <- paste0("id", seq_len(n))
  K <- outer(seq_len(n), seq_len(n), function(i, j) .35^abs(i - j))
  diag(K) <- diag(K) + .15; dimnames(K) <- list(labels, labels)
  list(labels = labels, K = K)
}
animal_K <- function() {
  ped <- data.frame(id = paste0("id", 1:8),
                    dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
                    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
                    stringsAsFactors = FALSE)
  K <- drmTMB:::drm_pedigree_additive_relationship(ped)
  list(labels = rownames(K), K = K)
}
scaled_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`); colnames(out) <- names(sds); out
}

make_data <- function(provider, g, seed) {
  set.seed(seed)
  o <- switch(provider, spatial = spatial_K(g), relmat = relmat_K(g), animal = animal_K())
  grp <- if (provider == "spatial") "site" else "id"
  eff <- scaled_effects(o$K, c(i = TRUTH$sd_sigma_intercept, s = TRUTH$sd_sigma_x))
  rownames(eff) <- o$labels
  ep <- rep(o$labels, each = N_EACH)
  x <- rep(seq(-1.2, 1.2, length.out = N_EACH), times = length(o$labels))
  eta <- TRUTH$log_sigma_intercept + eff[ep, "i"] + eff[ep, "s"] * x
  y <- TRUTH$mu_intercept + TRUTH$mu_x * x + exp(eta) * stats::rnorm(length(x))
  d <- data.frame(y = y, x = x, stringsAsFactors = FALSE); d[[grp]] <- ep
  list(data = d, coords = o$coords, K = o$K)
}
fit_one <- function(provider, sim, reml) {
  form <- switch(provider,
    spatial = { coords <- sim$coords; bf(y ~ x, sigma ~ spatial(1 + x | site, coords = coords)) },
    relmat  = { K <- sim$K;           bf(y ~ x, sigma ~ relmat(1 + x | id, K = K)) },
    animal  = { A <- sim$K;           bf(y ~ x, sigma ~ animal(1 + x | id, A = A)) })
  tryCatch(drmTMB(form, family = gaussian(), data = sim$data, REML = reml,
                  control = drm_control(optimizer = list(eval.max = 1400, iter.max = 1400))),
           error = function(e) e)
}
grab <- function(f) {
  if (inherits(f, "error")) return(c(int = NA, slp = NA, conv = NA, pdh = NA))
  p <- tryCatch({ s <- summary(f)$parameters; stats::setNames(s$estimate, s$parm) },
                error = function(e) NULL)
  if (is.null(p)) return(c(int = NA, slp = NA, conv = NA, pdh = NA))
  ii <- grep("^sd:sigma:.*\\(1 \\|", names(p)); ss <- grep("^sd:sigma:.*\\(0 \\+ x \\|", names(p))
  c(int = if (length(ii)) p[[ii[1]]] else NA,
    slp = if (length(ss)) p[[ss[1]]] else NA,
    conv = f$opt$convergence, pdh = isTRUE(f$sdr$pdHess))
}

orig <- drmTMB:::drm_validate_reml_spec
assignInNamespace("drm_validate_reml_spec", function(spec) invisible(TRUE), ns = "drmTMB")

cells <- rbind(
  expand.grid(provider = "spatial", g = c(8L, 16L, 32L), stringsAsFactors = FALSE),
  expand.grid(provider = "relmat",  g = c(8L, 16L, 32L), stringsAsFactors = FALSE),
  expand.grid(provider = "animal",  g = 8L,              stringsAsFactors = FALSE)
)

cat(sprintf("%-8s %-3s %-5s %8s %8s %8s %8s %9s %7s %7s\n",
            "provider","g","targ","ML_bias","REML_bias","ML_sd","REML_sd","REML>ML","MLconv","RMconv"))
cat(strrep("-", 92), "\n")
out <- list()
for (r in seq_len(nrow(cells))) {
  prov <- cells$provider[r]; g <- cells$g[r]
  M <- R <- matrix(NA_real_, N_SEEDS, 4, dimnames = list(NULL, c("int","slp","conv","pdh")))
  for (s in seq_len(N_SEEDS)) {
    sim <- make_data(prov, g, 920000L + 1000L * r + s)
    M[s, ] <- grab(fit_one(prov, sim, FALSE))
    R[s, ] <- grab(fit_one(prov, sim, TRUE))
  }
  for (tg in c("int","slp")) {
    tr <- if (tg == "int") TRUTH$sd_sigma_intercept else TRUTH$sd_sigma_x
    mb <- mean(M[, tg], na.rm = TRUE) - tr; rb <- mean(R[, tg], na.rm = TRUE) - tr
    d <- R[, tg] - M[, tg]
    cat(sprintf("%-8s %-3d %-5s %+8.4f %+8.4f %8.4f %8.4f %5d/%-3d %7d %7d\n",
      prov, g, tg, mb, rb, mean(M[,tg],na.rm=TRUE), mean(R[,tg],na.rm=TRUE),
      sum(d > 0, na.rm = TRUE), sum(!is.na(d)),
      sum(M[,"conv"] == 0, na.rm=TRUE), sum(R[,"conv"] == 0, na.rm=TRUE)))
  }
  out[[r]] <- list(prov = prov, g = g, M = M, R = R)
}
assignInNamespace("drm_validate_reml_spec", orig, ns = "drmTMB")
saveRDS(out, "scratchpad/reml_provider_ladder.rds")
cat("\nSIGNALS TO CHECK\n")
cat("  (1) both biases -> 0 as g grows           (estimator is fine, needed data)\n")
cat("  (2) REML_sd >= ML_sd                      (debiasing direction)\n")
cat("  (3) REML>ML near N/N for the admitted target\n")
cat("\nwrote scratchpad/reml_provider_ladder.rds\n")
