# Deterministic engine-equivalence probe (Phase 1, step 0)
# ---------------------------------------------------------------------------
# QUESTION: the A1 exemplar's sigma-intercept SD under-covers (0.853/0.895) with
# right-tail-dominant misses (21:1, 43:7). Two causes predict that SAME signature:
#   (A) ML centre-bias  -> interval sits below truth
#   (B) truncated upper-endpoint search (`profile_endpoint_max_eval = 90L`, imposed
#       by tools/run-structured-re-sigma-slope-coverage-grid.R:515; the package
#       default is NULL = uncapped) -> upper bound returned too small
#
# This probe is NOT a coverage simulation. It is a deterministic identity check:
#   *Two correct solvers on the same profile likelihood must return the same
#    interval.* Any systematic disagreement is a solver defect, not statistics.
#
# Arms, per fit: engine {endpoint@90, endpoint@uncapped, tmbprofile} x estimator {ML, REML}
# Output: per-seed bounds + the endpoint-vs-tmbprofile discrepancy.
#
# Run:  OPENBLAS_NUM_THREADS=1 NOT_CRAN=true R_PROFILE_USER=/dev/null \
#         Rscript --no-init-file scratchpad/engine_equivalence_probe.R
# ---------------------------------------------------------------------------

suppressMessages(devtools::load_all(".", quiet = TRUE))

N_SEEDS <- as.integer(Sys.getenv("N_SEEDS", "12"))
N_EACH  <- 20L
N_GROUP <- 8L

# Truth, verbatim from tools/run-structured-re-sigma-slope-coverage-grid.R:257
TRUTH <- list(
  mu_intercept = 0.40, mu_x = 0.25, log_sigma_intercept = -0.90,
  sd_sigma_intercept = 0.50, sd_sigma_x = 0.38
)

# DGP helpers, verbatim from the same runner (lines 288-333, 338-388)
spatial_coords_and_K <- function(n = 8L) {
  labels <- paste0("site_", seq_len(n))
  theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(x = cos(theta) + seq_len(n) / (3 * n), y = sin(theta))
  rownames(coords) <- labels
  precision <- drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "site")
  list(labels = labels, coords = coords, K = solve(as.matrix(precision$precision)))
}
scaled_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`); colnames(out) <- names(sds); out
}
make_data <- function(seed, n_each = N_EACH) {
  set.seed(seed)
  sp <- spatial_coords_and_K(N_GROUP)
  effects <- scaled_effects(sp$K, c(sigma_intercept = TRUTH$sd_sigma_intercept,
                                    sigma_x = TRUTH$sd_sigma_x))
  rownames(effects) <- sp$labels
  ep <- rep(sp$labels, each = n_each)
  x  <- rep(seq(-1.2, 1.2, length.out = n_each), times = N_GROUP)
  eta_sigma <- TRUTH$log_sigma_intercept + effects[ep, "sigma_intercept"] +
    effects[ep, "sigma_x"] * x
  y <- TRUTH$mu_intercept + TRUTH$mu_x * x + exp(eta_sigma) * stats::rnorm(length(x))
  dat <- data.frame(y = y, x = x, site = ep, stringsAsFactors = FALSE)
  list(data = dat, coords = sp$coords)
}

PARM_INT <- "sd:sigma:spatial(1 | site)"
PARM_SLP <- "sd:sigma:spatial(0 + x | site)"

fit_one <- function(sim, reml) {
  coords <- sim$coords                      # bare symbol: bf() uses NSE
  form <- bf(y ~ x, sigma ~ spatial(1 + x | site, coords = coords))
  tryCatch(
    drmTMB(form, family = gaussian(), data = sim$data, REML = reml,
           control = drm_control(optimizer = list(eval.max = 1400, iter.max = 1400))),
    error = function(e) e
  )
}

ci <- function(fit, parm, engine, max_eval = NULL) {
  args <- list(fit, parm = parm, method = "profile", level = 0.95,
               profile_engine = engine, trace = FALSE)
  if (identical(engine, "endpoint") && !is.null(max_eval)) {
    args$profile_endpoint_max_eval <- max_eval
  }
  r <- tryCatch(
    suppressWarnings(do.call(stats::confint, args)),
    error = function(e) e
  )
  if (inherits(r, "error")) return(c(lo = NA_real_, hi = NA_real_))
  c(lo = r$lower[[1L]], hi = r$upper[[1L]])
}

rows <- list()
for (s in seq_len(N_SEEDS)) {
  seed <- 900000L + s
  sim <- make_data(seed)
  for (reml in c(FALSE, TRUE)) {
    fit <- fit_one(sim, reml)
    est <- if (inherits(fit, "error")) NA_real_ else NA_real_
    if (inherits(fit, "error")) {
      rows[[length(rows) + 1L]] <- data.frame(
        seed = seed, estimator = if (reml) "REML" else "ML", parm = NA,
        arm = "FIT_ERROR", lo = NA, hi = NA, est = NA,
        msg = conditionMessage(fit), stringsAsFactors = FALSE)
      next
    }
    # Point estimates: the pattern used by tests/testthat/test-reml-ordinary-sigma.R
    pars <- tryCatch({
      s <- summary(fit)$parameters
      stats::setNames(s$estimate, s$parm)
    }, error = function(e) stats::setNames(numeric(0), character(0)))
    for (parm in c(PARM_INT, PARM_SLP)) {
      est <- if (parm %in% names(pars)) unname(pars[[parm]]) else NA_real_
      arms <- list(
        `endpoint@90`   = ci(fit, parm, "endpoint", 90L),
        `endpoint@uncap`= ci(fit, parm, "endpoint", NULL),
        `tmbprofile`    = ci(fit, parm, "tmbprofile")
      )
      for (nm in names(arms)) {
        rows[[length(rows) + 1L]] <- data.frame(
          seed = seed, estimator = if (reml) "REML" else "ML", parm = parm,
          arm = nm, lo = arms[[nm]][["lo"]], hi = arms[[nm]][["hi"]], est = est,
          msg = NA_character_, stringsAsFactors = FALSE)
      }
    }
  }
  cat("seed", seed, "done\n")
}

res <- do.call(rbind, rows)
out <- "scratchpad/engine_equivalence_probe.tsv"
write.table(res, out, sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote", out, "\n\n")

# ---- The identity check ----------------------------------------------------
truth_of <- function(p) if (identical(p, PARM_INT)) TRUTH$sd_sigma_intercept else TRUTH$sd_sigma_x

cat("=== Endpoint vs tmbprofile: two solvers, one likelihood. They must agree. ===\n")
ok <- res[!is.na(res$lo) & !is.na(res$hi) & res$arm != "FIT_ERROR", ]
for (e in unique(ok$estimator)) for (p in unique(ok$parm)) {
  sub <- ok[ok$estimator == e & ok$parm == p, ]
  w <- reshape(sub[, c("seed", "arm", "hi")], idvar = "seed", timevar = "arm", direction = "wide")
  wl <- reshape(sub[, c("seed", "arm", "lo")], idvar = "seed", timevar = "arm", direction = "wide")
  if (!all(c("hi.tmbprofile", "hi.endpoint@90") %in% names(w))) next
  d90 <- w$`hi.endpoint@90` - w$hi.tmbprofile
  dun <- w$`hi.endpoint@uncap` - w$hi.tmbprofile
  dlo <- wl$`lo.endpoint@90` - wl$lo.tmbprofile
  cat(sprintf("\n%s | %s  (truth %.2f, n=%d)\n", e, p, truth_of(p), nrow(w)))
  cat(sprintf("  UPPER  endpoint@90    - tmbprofile : median %+.4f   (n<0: %d/%d)\n",
              median(d90, na.rm = TRUE), sum(d90 < -1e-6, na.rm = TRUE), sum(!is.na(d90))))
  cat(sprintf("  UPPER  endpoint@uncap - tmbprofile : median %+.4f   (n<0: %d/%d)\n",
              median(dun, na.rm = TRUE), sum(dun < -1e-6, na.rm = TRUE), sum(!is.na(dun))))
  cat(sprintf("  LOWER  endpoint@90    - tmbprofile : median %+.4f\n", median(dlo, na.rm = TRUE)))
  cat(sprintf("  mean est %.4f (bias %+.4f)\n", mean(sub$est, na.rm = TRUE),
              mean(sub$est, na.rm = TRUE) - truth_of(p)))
  for (a in unique(sub$arm)) {
    sa <- sub[sub$arm == a, ]
    tr <- truth_of(p)
    cat(sprintf("    %-16s cover %2d/%2d  missHI %2d  missLO %2d  medwidth %.3f\n",
                a, sum(sa$lo <= tr & sa$hi >= tr), nrow(sa),
                sum(sa$hi < tr), sum(sa$lo > tr), median(sa$hi - sa$lo)))
  }
}
cat("\nINTERPRETATION\n")
cat("  endpoint@90 upper systematically BELOW tmbprofile upper  => (B) truncation.\n")
cat("  endpoint@uncap == tmbprofile, both still miss high       => (A) centre bias.\n")
cat("  REML shifts est toward truth and rebalances misses       => REML fixes the centre.\n")
