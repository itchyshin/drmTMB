#!/usr/bin/env Rscript
# Track A1 Phase-0 spike -- profile interval for qseries_spatial_q1_sigma_one_slope
#
# PROVENANCE: committed copy of the 2026-07-06 Phase-0 spike (originally run from
# a scratch dir). Captured output alongside: spike-output.txt. Verdict: PASS --
# profile route wired, both SD targets profile_ready, confint(method="profile")
# finite on all 3 seeds. See docs/dev-log/2026-07-06-next-arc-scoped-ultra-plan.md
# (Phase 0) for the interpretation and honest limits.
#
# Run from anywhere inside the repo:
#   R_PROFILE_USER=/dev/null Rscript --no-init-file \
#     docs/dev-log/simulation-artifacts/2026-07-06-a1-exemplar-spike/a1-spatial-sigma-slope-spike.R
#
# Cell (from release ledger):
#   formula_cell     = spatial(1 + x | site, coords = coords) in sigma
#   dimension_pattern= q1   (independent SDs, no rho)
#   slope_class      = independent_one_slope
#   next_gate blocker= spatial sigma:(Intercept) finite-Wald rate 0.9360 < 0.95

find_repo_root <- function(start = getwd()) {
  d <- normalizePath(start)
  while (!file.exists(file.path(d, "DESCRIPTION")) && dirname(d) != d) d <- dirname(d)
  d
}
REPO <- find_repo_root()
suppressWarnings(suppressMessages(devtools::load_all(REPO, quiet = TRUE)))
cat("drmTMB loaded via load_all from", REPO, "\n")
`%||%` <- function(x, y) if (is.null(x)) y else x

## --- covariance + DGP: copied verbatim from ------------------------------
## tools/run-structured-re-sigma-slope-coverage-grid.R (spatial branch) -----
TRUTH <- list(mu_intercept = 0.40, mu_x = 0.25, log_sigma_intercept = -0.90,
              sd_sigma_intercept = 0.50, sd_sigma_x = 0.38)

spatial_coords_and_K <- function(n = 8L) {
  labels <- paste0("site_", seq_len(n))
  theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(x = cos(theta) + seq_len(n) / (3 * n), y = sin(theta))
  rownames(coords) <- labels
  precision <- drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "site")
  K <- solve(as.matrix(precision$precision))
  list(labels = labels, coords = coords, K = K)
}

scaled_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`); colnames(out) <- names(sds); out
}

make_data <- function(seed, n_each = 20L) {
  set.seed(seed)
  sp <- spatial_coords_and_K(8L)
  labels <- sp$labels; K <- sp$K
  sds <- c(sigma_intercept = TRUTH$sd_sigma_intercept, sigma_x = TRUTH$sd_sigma_x)
  effects <- scaled_effects(K, sds); rownames(effects) <- labels
  endpoint <- rep(labels, each = n_each)
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = 8L)
  eta_mu <- TRUTH$mu_intercept + TRUTH$mu_x * x
  eta_sigma <- TRUTH$log_sigma_intercept +
    effects[endpoint, "sigma_intercept"] + effects[endpoint, "sigma_x"] * x
  y <- eta_mu + exp(eta_sigma) * stats::rnorm(length(x))
  dat <- data.frame(y = y, x = x, site = endpoint, stringsAsFactors = FALSE)
  list(data = dat, coords = sp$coords)
}

## target names (verbatim convention from the runner) ----------------------
tgt_slope     <- "sd:sigma:spatial(0 + x | site)"   # the one-slope SD
tgt_intercept <- "sd:sigma:spatial(1 | site)"       # the finite-Wald blocker

fit_one <- function(sim) {
  coords <- sim$coords   # spatial() NSE needs a bare symbol naming the object
  form <- bf(y ~ x, sigma ~ spatial(1 + x | site, coords = coords))
  drmTMB(form, family = gaussian(), data = sim$data,
         control = drm_control(optimizer = list(eval.max = 1400, iter.max = 1400)))
}

ci <- function(fit, parm, method, engine = NULL) {
  args <- list(fit, parm = parm, method = method, level = 0.95)
  if (!is.null(engine)) { args$profile_engine <- engine; args$trace <- FALSE
                          args$profile_endpoint_max_eval <- 90L }
  r <- tryCatch(withCallingHandlers(do.call(stats::confint, args),
                  warning = function(w) invokeRestart("muffleWarning")),
                error = function(e) e)
  if (inherits(r, "error")) return(list(lo = NA, hi = NA, ok = FALSE, msg = conditionMessage(r)))
  lo <- r$lower[[1]]; hi <- r$upper[[1]]
  list(lo = lo, hi = hi, ok = is.finite(lo) && is.finite(hi), msg = NA)
}

seeds <- c(740001L, 740002L, 740003L)
cat(sprintf("\nTruth: sigma-intercept SD=%.2f  sigma-slope SD=%.2f\n\n",
            TRUTH$sd_sigma_intercept, TRUTH$sd_sigma_x))

targets_printed <- FALSE
for (s in seeds) {
  cat(sprintf("==== seed %d ====\n", s))
  sim <- make_data(s)
  fit <- tryCatch(fit_one(sim), error = function(e) e)
  if (inherits(fit, "error")) { cat("  FIT ERROR:", conditionMessage(fit), "\n\n"); next }

  conv <- fit$opt$convergence; pdh <- isTRUE(fit$sdr$pdHess)
  cat(sprintf("  convergence=%s  pdHess=%s\n", conv, pdh))
  cat("  sdpars$sigma:\n"); print(fit$sdpars$sigma)

  # drm_profile_targets() -- does it list our SD targets?
  if (!targets_printed) {
    pt <- tryCatch(drmTMB:::drm_profile_targets(fit), error = function(e) e)
    cat("\n  drm_profile_targets(fit):\n")
    if (inherits(pt, "error")) {
      cat("    ERROR:", conditionMessage(pt), "\n")
    } else {
      print(pt)
      flat <- paste(unlist(lapply(pt, format)), collapse = " || ")
      cat(sprintf("    slope target listed?     %s\n", grepl("0 + x | site", flat, fixed = TRUE)))
      cat(sprintf("    intercept target listed? %s\n", grepl("(1 | site)", flat, fixed = TRUE)))
    }
    cat("\n  confint(fit, parm='variance_components'):\n")
    vc <- tryCatch(withCallingHandlers(
        stats::confint(fit, parm = "variance_components"),
        warning = function(w) invokeRestart("muffleWarning")),
      error = function(e) e)
    if (inherits(vc, "error")) cat("    ERROR:", conditionMessage(vc), "\n") else print(vc)
    cat("\n")
    targets_printed <- TRUE
  }

  for (tg in list(c("slope", tgt_slope), c("intercept", tgt_intercept))) {
    w <- ci(fit, tg[2], "wald")
    p <- ci(fit, tg[2], "profile", engine = "endpoint")
    cat(sprintf("  [%-9s] wald=[%s]%s  profile=[%s]%s\n", tg[1],
      if (w$ok) sprintf("%.3f, %.3f", w$lo, w$hi) else "non-finite", if (w$ok) "" else paste0(" (", w$msg %||% "NA", ")"),
      if (p$ok) sprintf("%.3f, %.3f", p$lo, p$hi) else "non-finite", if (p$ok) "" else paste0(" (", p$msg %||% "NA", ")")))
  }
  cat("\n")
}
cat("SPIKE DONE\n")
