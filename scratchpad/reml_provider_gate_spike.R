# Spike: is the non-phylo REML rejection a CONSERVATIVE GATE or a real limitation?
# ---------------------------------------------------------------------------
# R/drmTMB.R:2002-2007 rejects spatial/animal/relmat structured effects under REML
# with the reason "not validated yet". `drm_apply_estimator_spec()` is
# provider-agnostic (it appends `beta_sigma` to tmb_random_names without ever
# inspecting the K matrix), and the validator's return value is DISCARDED at
# R/drmTMB.R:824 -- so stubbing it out is a source-free bypass.
#
# If REML then fits AND debiases for spatial/animal/relmat the way it does for
# phylo (g=8 bias -0.092 -> -0.029), the gate is conservative and relaxing it
# (behind a recovery ladder) unlocks 36 Gaussian cells.
#
# THIS IS A DIAGNOSTIC SPIKE, NOT AN ADMISSION. Nothing is promoted on it.
#
# Run: OPENBLAS_NUM_THREADS=1 NOT_CRAN=true R_PROFILE_USER=/dev/null \
#        Rscript --no-init-file scratchpad/reml_provider_gate_spike.R
# ---------------------------------------------------------------------------
suppressMessages(devtools::load_all(".", quiet = TRUE))

N_SEEDS <- as.integer(Sys.getenv("N_SEEDS", "30"))
N_EACH  <- 20L
N_GROUP <- 8L
TRUTH <- list(mu_intercept = 0.40, mu_x = 0.25, log_sigma_intercept = -0.90,
              sd_sigma_intercept = 0.50, sd_sigma_x = 0.38)

spatial_coords_and_K <- function(n = 8L) {
  labels <- paste0("site_", seq_len(n))
  theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(x = cos(theta) + seq_len(n) / (3 * n), y = sin(theta))
  rownames(coords) <- labels
  precision <- drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "site")
  list(labels = labels, coords = coords, K = solve(as.matrix(precision$precision)))
}
relmat_K <- function(n = 8L) {
  labels <- paste0("id", seq_len(n))
  K <- outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(labels, labels); K
}
scaled_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`); colnames(out) <- names(sds); out
}

make_data <- function(provider, seed) {
  set.seed(seed)
  if (provider == "spatial") { o <- spatial_coords_and_K(N_GROUP); grp <- "site" }
  else                       { K <- relmat_K(N_GROUP); o <- list(labels = rownames(K), K = K); grp <- "id" }
  eff <- scaled_effects(o$K, c(i = TRUTH$sd_sigma_intercept, s = TRUTH$sd_sigma_x))
  rownames(eff) <- o$labels
  ep <- rep(o$labels, each = N_EACH)
  x  <- rep(seq(-1.2, 1.2, length.out = N_EACH), times = N_GROUP)
  eta_s <- TRUTH$log_sigma_intercept + eff[ep, "i"] + eff[ep, "s"] * x
  y <- TRUTH$mu_intercept + TRUTH$mu_x * x + exp(eta_s) * stats::rnorm(length(x))
  d <- data.frame(y = y, x = x, stringsAsFactors = FALSE); d[[grp]] <- ep
  list(data = d, coords = o$coords, K = o$K)
}

fit_one <- function(provider, sim, reml) {
  if (provider == "spatial") {
    coords <- sim$coords
    form <- bf(y ~ x, sigma ~ spatial(1 + x | site, coords = coords))
  } else {
    K <- sim$K
    form <- bf(y ~ x, sigma ~ relmat(1 + x | id, K = K))
  }
  tryCatch(drmTMB(form, family = gaussian(), data = sim$data, REML = reml,
                  control = drm_control(optimizer = list(eval.max = 1400, iter.max = 1400))),
           error = function(e) e)
}

collect <- function(provider, reml) {
  ints <- slps <- convs <- pdh <- rep(NA_real_, N_SEEDS)
  errs <- character(0)
  for (s in seq_len(N_SEEDS)) {
    f <- fit_one(provider, make_data(provider, 910000L + s), reml)
    if (inherits(f, "error")) { errs <- c(errs, conditionMessage(f)); next }
    p <- tryCatch({ x <- summary(f)$parameters; stats::setNames(x$estimate, x$parm) },
                  error = function(e) NULL)
    if (is.null(p)) next
    ii <- grep("^sd:sigma:.*\\(1 \\|", names(p)); ss <- grep("^sd:sigma:.*\\(0 \\+ x \\|", names(p))
    if (length(ii)) ints[s] <- p[[ii[1]]]
    if (length(ss)) slps[s] <- p[[ss[1]]]
    convs[s] <- f$opt$convergence
    pdh[s] <- isTRUE(f$sdr$pdHess)
  }
  list(int = ints, slp = slps, conv = convs, pdh = pdh, errs = errs)
}

cat("### Stubbing drm_validate_reml_spec (return value is discarded at R/drmTMB.R:824)\n")
orig <- drmTMB:::drm_validate_reml_spec
assignInNamespace("drm_validate_reml_spec", function(spec) invisible(TRUE), ns = "drmTMB")

for (prov in c("spatial", "relmat")) {
  cat("\n================ provider:", prov, " (g=8, n_each=20,", N_SEEDS, "seeds) ================\n")
  ml <- collect(prov, FALSE); rl <- collect(prov, TRUE)
  if (length(rl$errs)) { cat("  REML STILL ERRORS (gate is not the only obstacle):\n    ",
                            substr(rl$errs[1], 1, 160), "\n"); next }
  for (tg in c("int", "slp")) {
    tr <- if (tg == "int") TRUTH$sd_sigma_intercept else TRUTH$sd_sigma_x
    m <- mean(ml[[tg]], na.rm = TRUE); r <- mean(rl[[tg]], na.rm = TRUE)
    paired <- sum(rl[[tg]] > ml[[tg]], na.rm = TRUE); np <- sum(!is.na(rl[[tg]] - ml[[tg]]))
    cat(sprintf("  sd_%-4s truth %.2f | ML %.4f (bias %+.4f) | REML %.4f (bias %+.4f) | REML>ML %d/%d\n",
                tg, tr, m, m - tr, r, r - tr, paired, np))
  }
  cat(sprintf("  conv0: ML %d/%d  REML %d/%d   pdHess: ML %d  REML %d\n",
              sum(ml$conv == 0, na.rm = TRUE), N_SEEDS, sum(rl$conv == 0, na.rm = TRUE), N_SEEDS,
              sum(ml$pdh, na.rm = TRUE), sum(rl$pdh, na.rm = TRUE)))
}
assignInNamespace("drm_validate_reml_spec", orig, ns = "drmTMB")
cat("\n### validator restored\n")
