# S10 coverage campaign — mc-0227 cumulative_logit mu random-slope RE-SD via the O3
# estimator (AGHQ nodes=25 + Cox-Reid), per the frozen gate-spec
# (scratchpad/o3-cumlogit-coverage-gate-spec.md, rev 2 S8-ratified). Profile-CI coverage
# of true sigma=0.5, iid-uncentered slope DGP, one-sided finite-profile scoring (gate §4.1),
# directional counts (§4.5), per-M point bias (§2). Totoro: OPENBLAS_NUM_THREADS=1, <=90 cores,
# from-source load_all off fresh main. NEVER GitHub Actions (D-50).
#
# Env: NSIM (1200) MS ("40,80,160,320") NEACH (15) SEED_BASE (20260718) NCORES (90)
#      NODES (25) OUTDIR (docs/dev-log/simulation-artifacts/...) SMOKE (false)
suppressWarnings(Sys.setenv(OPENBLAS_NUM_THREADS = "1"))
# The O3 estimator (R/aghq-coxreid.R) is PURE R -- no TMB/DLL -- so we source it directly
# rather than compile the whole package. Deployable to Totoro with just this driver + that
# one file. Override the path with O3_SRC if needed.
source(Sys.getenv("O3_SRC", "R/aghq-coxreid.R"))
library(parallel)

envd  <- function(k, d) { v <- Sys.getenv(k); if (nzchar(v)) v else d }
NSIM  <- as.integer(envd("NSIM", "1200"))
MS    <- as.integer(strsplit(envd("MS", "40,80,160,320"), ",")[[1]])
NEACH <- as.integer(envd("NEACH", "15"))
SEEDB <- as.integer(envd("SEED_BASE", "20260718"))
NCORES<- as.integer(envd("NCORES", "90"))
NODES <- as.integer(envd("NODES", "25"))
SMOKE <- tolower(envd("SMOKE", "false")) %in% c("true", "1", "yes")
TRUTH <- 0.5
if (SMOKE) NSIM <- 1L
OUTDIR <- envd("OUTDIR", file.path("docs/dev-log/simulation-artifacts",
                                   "2026-07-18-o3-cumlogit-slope-coverage"))
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

sim_cell <- function(M, ne, seed) {
  set.seed(seed)
  id <- rep(seq_len(M), each = ne); n <- length(id)
  x  <- rnorm(n); u <- rnorm(M, 0, TRUTH)
  eta <- 0.7 * x + x * u[id]; cut <- c(-1, 0, 1.2)
  y <- vapply(eta, function(e) sample.int(4L, 1L, prob = diff(c(0, plogis(c(cut - e, Inf))))), integer(1))
  list(y = y, X = cbind(x), z = x, g = id)
}

# One replicate -> a raw row. One-sided finite-profile scoring (gate §4.1).
one_rep <- function(M, seed) {
  d <- sim_cell(M, NEACH, seed)
  fit <- tryCatch(drm_o3_fit(d$y, d$X, d$z, d$g, "cumulative_logit", nodes = NODES,
                             estimator = "aghq_cr", n_categories = 4L),
                  error = function(e) NULL)
  if (is.null(fit)) return(data.frame(M = M, seed = seed, sd = NA, lower = NA, upper = NA,
                                      scored = FALSE, hit = NA, one_sided = NA, above = NA, below = NA, fail = TRUE))
  ci <- tryCatch(drm_o3_profile_ci(fit), error = function(e) NULL)
  lo <- if (is.null(ci)) NA else ci$lower; up <- if (is.null(ci)) NA else ci$upper
  both_na <- is.na(lo) && is.na(up)
  loB <- if (is.na(lo)) 0 else lo; hiB <- if (is.na(up)) Inf else up
  scored <- !both_na
  hit <- if (scored) (TRUTH >= loB && TRUTH <= hiB) else NA
  data.frame(M = M, seed = seed, sd = fit$sd, lower = lo, upper = up,
             scored = scored, hit = hit, one_sided = is.na(lo) || is.na(up),
             above = if (scored) TRUTH > hiB else NA, below = if (scored) TRUTH < loB else NA,
             fail = both_na)
}

message(sprintf("O3 coverage: NSIM=%d MS=%s NEACH=%d NODES=%d NCORES=%d SMOKE=%s",
                NSIM, paste(MS, collapse = ","), NEACH, NODES, NCORES, SMOKE))
raw_all <- list(); summ <- list()
for (M in MS) {
  seeds <- SEEDB + seq_len(NSIM)
  t0 <- Sys.time()
  rows <- mclapply(seeds, function(s) one_rep(M, s), mc.cores = min(NCORES, NSIM))
  raw <- do.call(rbind, rows); raw_all[[as.character(M)]] <- raw
  sc <- raw[raw$scored, ]
  nsc <- nrow(sc); nhit <- sum(sc$hit)
  cov <- if (nsc > 0) nhit / nsc else NA
  ci <- if (nsc > 0) binom.test(nhit, nsc)$conf.int else c(NA, NA)
  mcse <- if (nsc > 0) sqrt(cov * (1 - cov) / nsc) else NA
  fin_rate <- mean(!raw$fail)
  summ[[as.character(M)]] <- data.frame(
    M = M, n = nrow(raw), n_scored = nsc, n_fail = sum(raw$fail),
    profile_finite_rate = fin_rate, one_sided = sum(sc$one_sided),
    one_sided_hit = sum(sc$one_sided & sc$hit),   # gate-spec S4.1 pre-registered audit quantity
    coverage = cov, ci_lo = ci[1], ci_hi = ci[2], mcse = mcse,
    truth_above = sum(sc$above), truth_below = sum(sc$below),
    mean_sd = mean(raw$sd, na.rm = TRUE), rel_bias = mean(raw$sd, na.rm = TRUE) / TRUTH - 1,
    secs = as.numeric(Sys.time() - t0, units = "secs"))
  s <- summ[[as.character(M)]]
  message(sprintf("  M=%d: cov=%.4f [%.4f,%.4f] fin=%.3f 1sided=%d above=%d below=%d relbias=%+.1f%% (%.0fs)",
                  M, s$coverage, s$ci_lo, s$ci_hi, s$profile_finite_rate, s$one_sided,
                  s$truth_above, s$truth_below, 100 * s$rel_bias, s$secs))
  if (SMOKE && s$profile_finite_rate < 1) message("  SMOKE HALT: non-finite at M=", M)
}
RAW <- do.call(rbind, raw_all); SUMM <- do.call(rbind, summ)
tag <- if (SMOKE) "smoke" else "iid"
write.table(RAW,  file.path(OUTDIR, sprintf("coverage-%s-raw.tsv", tag)),     sep = "\t", row.names = FALSE, quote = FALSE)
write.table(SUMM, file.path(OUTDIR, sprintf("coverage-%s-summary.tsv", tag)), sep = "\t", row.names = FALSE, quote = FALSE)
man <- data.frame(
  key = c("git_sha", "pkg_version", "host", "openblas_threads", "ncores", "nsim", "ms", "neach",
          "nodes", "truth_sigma", "seed_base", "estimator"),
  value = c(tryCatch(system("git rev-parse HEAD", intern = TRUE), error = function(e) NA),
            tryCatch(as.character(utils::packageVersion("drmTMB")), error = function(e) "source(aghq-coxreid.R)"),
            Sys.info()[["nodename"]],
            Sys.getenv("OPENBLAS_NUM_THREADS"), NCORES, NSIM, paste(MS, collapse = ","), NEACH,
            NODES, TRUTH, SEEDB, "aghq_cr(AGHQ+CoxReid)"))
write.table(man, file.path(OUTDIR, sprintf("coverage-%s-manifest.tsv", tag)), sep = "\t", row.names = FALSE, quote = FALSE)
message("Wrote ", OUTDIR)
print(SUMM[, c("M", "coverage", "ci_lo", "ci_hi", "profile_finite_rate", "truth_above", "truth_below", "rel_bias")])
