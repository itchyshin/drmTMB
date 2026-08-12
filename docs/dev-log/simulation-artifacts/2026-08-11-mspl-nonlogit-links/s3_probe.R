# S3 — separation-depth calibration probe for G1.
#
# Authority and limits: PREREGISTRATION.md §4. This probe may set ONLY the eta_d
# GRID VALUES for probit, cloglog-standard and cloglog-mirrored (and which two of
# each are the "deepest" used by the adversarial corner). It may not touch the
# DGP forms, G, n_per, sigmas, betas, the NUMBER of grid points (5), the
# link/orientation set, replicates, seeds, endpoints, thresholds, or the control
# rule.
#
# Why it exists: F1's eta_d grid {0,-2,-4,-6,-10} was tuned so LOGIT reaches
# ML |SE| > 1e3 or failure. Those values do not transfer -- plogis(-10)=4.5e-5
# but pnorm(-10)=7.6e-24, so a probit cell at eta_d=-10 is enormously more
# extreme, while cloglog is asymmetric and its two orientations need checking
# separately. Reusing F1's numbers unchecked risks a VACUOUS pass (MSPL finite
# where ML would also have been finite), which is prereg §3(d)/(e).
#
# Control condition, taken verbatim from F1 §6 and prereg §7:
#   ML shows |SE| > 1e3 OR the fit fails, in >= 50% of the calibration batch.
#
# Usage: Rscript --no-init-file s3_probe.R --src <pkg dir> [--reps 20] [--out <tsv>]

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
SRC  <- getarg("--src", ".")
REPS <- as.integer(getarg("--reps", "20"))
OUT  <- getarg("--out", "s3_probe_raw.tsv")

suppressMessages(pkgload::load_all(SRC, quiet = TRUE))
if (!"estimator" %in% names(formals(drmTMB::drmTMB))) {
  stop("STALE BUILD: drmTMB() has no `estimator` formal.")
}

CONDITIONS <- c("probit", "cloglog_standard", "cloglog_mirrored")
link_of <- function(cond) if (identical(cond, "probit")) "probit" else "cloglog"
mirrored <- function(cond) identical(cond, "cloglog_mirrored")

linkinv <- function(eta, link) stats::binomial(link = link)$linkinv(eta)

# q1 DGP, verbatim from F1 §4 / prereg §5.1, extended by link + orientation.
simulate_q1 <- function(cond, eta_d, G, seed, n_per = 10L) {
  set.seed(seed)
  block <- factor(rep(seq_len(G), each = n_per))
  N <- length(block)
  trt <- rep(c(0, 1), length.out = N)
  u <- rnorm(G, sd = 0.7)
  p <- linkinv(eta_d + 1.0 * trt + u[block], link_of(cond))
  y <- rbinom(N, 1, p)
  if (mirrored(cond)) y <- 1L - y            # prereg §5.1: y* = m - y, same link
  data.frame(y = y, trt = trt, block = block)
}

# Exported API only (prereg §8.2): drmTMB(), coef(), vcov(). Never drmTMB:::.
ml_one <- function(cond, eta_d, G, seed) {
  d <- simulate_q1(cond, eta_d, G, seed)
  ev <- mean(d$y)
  out <- tryCatch({
    f <- drmTMB(bf(y ~ trt + (1 | block)),
                family = binomial(link = link_of(cond)),
                data = d, estimator = "ml")
    v <- suppressWarnings(sqrt(diag(vcov(f))))
    se <- if ("mu:trt" %in% names(v)) v[["mu:trt"]] else NA_real_
    list(se = se, failed = FALSE)
  }, error = function(e) list(se = NA_real_, failed = TRUE))
  # Divergence: |SE| > 1e3, a failed fit, or a non-finite/absent SE.
  diverged <- isTRUE(out$failed) || !is.finite(out$se) || abs(out$se) > 1e3
  data.frame(cond = cond, eta_d = eta_d, G = G, seed = seed,
             se = out$se, failed = out$failed, diverged = diverged,
             event_rate = ev)
}

# Candidate ladders. Deliberately generous at the deep end; the probe SELECTS
# from these, it does not assume any of them.
LADDER <- list(
  probit           = c(0, -0.5, -1, -1.5, -2, -2.5, -3, -3.5, -4, -5),
  cloglog_standard = c(0, -1, -2, -3, -4, -5, -6, -8, -10, -12),
  cloglog_mirrored = c(0, -1, -2, -3, -4, -5, -6, -8, -10, -12)
)

G_PROBE <- 12L   # the smaller main-grid G: hardest to separate, so conservative
rows <- list()
for (cond in CONDITIONS) {
  for (e in LADDER[[cond]]) {
    for (r in seq_len(REPS)) {
      # Probe seeds are deliberately OUTSIDE the frozen G1 seed stream
      # (20260811 + 1e5*cell + rep) so no probe draw can reappear as a graded
      # G1 replicate.
      seed <- 77000000L + 100000L * match(cond, CONDITIONS) +
        1000L * match(e, LADDER[[cond]]) + r
      rows[[length(rows) + 1L]] <- ml_one(cond, e, G_PROBE, seed)
    }
  }
}
raw <- do.call(rbind, rows)
write.table(raw, OUT, sep = "\t", row.names = FALSE, quote = FALSE)

agg <- aggregate(cbind(diverged, event_rate) ~ cond + eta_d, data = raw, FUN = mean)
agg <- agg[order(agg$cond, -agg$eta_d), ]
cat("\n--- ML divergence fraction by condition and eta_d (n =", REPS, "each) ---\n")
print(agg, row.names = FALSE, digits = 4)

# Selection rule, fixed BEFORE seeing output:
#   eta_star = the SHALLOWEST (largest) eta_d whose divergence fraction >= 0.50.
#   grid     = {0, 0.4*eta_star, 0.7*eta_star, eta_star, 1.4*eta_star}
# so the two deepest (eta_star, 1.4*eta_star) both satisfy the control condition
# -- which is what prereg §5.3 hands to the adversarial corner.
cat("\n--- SELECTED GRIDS (rule fixed before output was seen) ---\n")
sel <- list()
for (cond in CONDITIONS) {
  a <- agg[agg$cond == cond, ]
  a <- a[order(-a$eta_d), ]
  hit <- a$eta_d[a$diverged >= 0.5]
  if (!length(hit)) {
    cat(sprintf("%-18s NO eta_d REACHED 50%% ML DIVERGENCE -- report as a finding (prereg §4 closing).\n", cond))
    sel[[cond]] <- NA
    next
  }
  eta_star <- max(hit)                      # shallowest qualifying depth
  grid <- round(c(0, 0.4, 0.7, 1.0, 1.4) * eta_star, 2)
  sel[[cond]] <- grid
  cat(sprintf("%-18s eta_star=%-6s grid = {%s}\n", cond, eta_star,
              paste(sprintf("%g", grid), collapse = ", ")))
}
saveRDS(list(agg = agg, selected = sel), sub("\\.tsv$", "_selected.rds", OUT))
cat("\nlogit-control grid is NOT set here: prereg §5.2 reuses F1's {0,-2,-4,-6,-10} verbatim.\n")
