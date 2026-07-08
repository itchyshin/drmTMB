# F3 coverage recheck: does the bias-t correction help the sigma-intercept SD?
# ---------------------------------------------------------------------------
# design 219 withholds the small-sample correction from the dispersion axis on
# the premise "dispersion SDs already over-cover". Fisher measured Wald-z coverage
# of sd:sigma:(Intercept) at g=8 as 0.939/0.942/0.963 -- it UNDER-covers. This
# pilot asks whether the `"group"` correction (which DOES reach the dispersion
# axis) lifts coverage and rebalances the misses for that target.
#
# PILOT, not certification: modest reps, one seed stream, one provider (phylo).
# Report raw-z vs group-corrected coverage + miss split. Truth SD 0.60.
#
# Run: OPENBLAS_NUM_THREADS=1 NOT_CRAN=true R_PROFILE_USER=/dev/null \
#        Rscript --no-init-file scratchpad/f3_sigma_intercept_correction_pilot.R
# ---------------------------------------------------------------------------
suppressMessages(devtools::load_all(".", quiet = TRUE))
stopifnot(requireNamespace("ape", quietly = TRUE))

N_REPS <- as.integer(Sys.getenv("N_REPS", "120"))
G      <- as.integer(Sys.getenv("G", "8"))
N_EACH <- as.integer(Sys.getenv("N_EACH", "10"))
TRUTH_SD  <- 0.60
LOG_SIG0  <- -0.90
PARM <- "sd:sigma:phylo(1 | species)"

sim <- function(seed) {
  set.seed(seed)
  tree <- ape::rcoal(G)
  sp <- tree$tip.label
  C <- drmTMB:::drm_phylo_tip_covariance(tree)
  u <- as.vector(t(chol(C + diag(1e-8, G))) %*% stats::rnorm(G)) * TRUTH_SD
  ep <- rep(sp, each = N_EACH)
  x  <- stats::rnorm(G * N_EACH)
  log_sig <- LOG_SIG0 + u[match(ep, sp)]
  y <- stats::rnorm(length(x), 0.3 + 0.5 * x, exp(log_sig))
  list(tree = tree, data = data.frame(species = ep, x = x, y = y, stringsAsFactors = FALSE))
}

ci <- function(fit, ssd, bc) {
  r <- tryCatch(suppressWarnings(stats::confint(
    fit, parm = PARM, method = "wald",
    small_sample_df = ssd, bias_correct = bc)), error = function(e) e)
  if (inherits(r, "error")) return(c(lo = NA, hi = NA))
  c(lo = r$lower[[1L]], hi = r$upper[[1L]])
}

raw <- matrix(NA_real_, N_REPS, 2); cor <- matrix(NA_real_, N_REPS, 2)
for (i in seq_len(N_REPS)) {
  s <- sim(950000L + i)
  tree <- s$tree
  f <- tryCatch(suppressWarnings(drmTMB(
    bf(y ~ x, sigma ~ phylo(1 | species, tree = tree)),
    family = gaussian(), data = s$data,
    control = drm_control(optimizer = list(eval.max = 1400, iter.max = 1400)))),
    error = function(e) e)
  if (inherits(f, "error")) next
  raw[i, ] <- ci(f, "none", "none")
  cor[i, ] <- ci(f, "group", "group")
}

report <- function(lbl, M) {
  ok <- is.finite(M[, 1]) & is.finite(M[, 2])
  cov <- mean(M[ok, 1] <= TRUTH_SD & M[ok, 2] >= TRUTH_SD)
  hi <- sum(ok & M[, 2] < TRUTH_SD); lo <- sum(ok & M[, 1] > TRUTH_SD)
  mcse <- sqrt(cov * (1 - cov) / sum(ok))
  cat(sprintf("  %-16s finite %3d/%3d  coverage %.3f (MCSE %.3f)  miss %d high : %d low  medwidth %.3f\n",
              lbl, sum(ok), nrow(M), cov, mcse, hi, lo, median(M[ok, 2] - M[ok, 1])))
}

cat(sprintf("=== F3 pilot: sd:sigma:(Intercept), phylo, g=%d, n_each=%d, %d reps, truth %.2f ===\n",
            G, N_EACH, N_REPS, TRUTH_SD))
report("raw z", raw)
report("group-corrected", cor)
cat("\nREADING: if group-corrected lifts coverage toward 0.95 AND cuts the high:low ratio,\n")
cat("the correction helps the sigma intercept and design 219's exclusion is wrong to keep.\n")
cat("If it over-shoots (>0.97) or worsens balance, the sigma intercept needs the skew-aware/REML route.\n")
