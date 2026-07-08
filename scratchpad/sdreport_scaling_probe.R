# Does `sdreport()` memory scale as O(n_tips^2), and is REML worse than ML?
# ---------------------------------------------------------------------------
# Ayumi (issue #3, 2026-07-08): bivariate REML with two direct-SD surfaces
# (`sd_phylo1`/`sd_phylo2`) at N = 10,440 tips blows a 48 GB ceiling inside
# `TMB::sdreport()`. The same model at ~400 species is fine. Full-N ML works.
#
# DIAGNOSIS UNDER TEST (was inference, now measured):
#   `ADREPORT(sd_phylo_group)` has one entry per group (src/drmTMB.cpp:1008,
#   length = X_sd_phylo.rows()). Bivariate ADREPORTs sd_phylo AND sd_phylo2.
#   TMB's default `getReportCovariance = TRUE` forms the FULL covariance of that
#   report vector -> O(R^2) with R ~ 2 * n_tips.
#
# THE HOLE IN THAT STORY: the ADREPORT vector is the same size under ML, and her
# ML fit succeeds. So O(R^2) alone cannot explain the ML/REML asymmetry. Under
# REML, beta_mu*/beta_sigma* move into the Laplace `random` block, so the delta
# method must push the report Jacobian through the joint sparse solve. THAT is
# the claimed extra factor -- and it is exactly what this probe measures.
#
# PREDICTIONS
#   P1  report_cov=TRUE  memory ~ O(n^2);  report_cov=FALSE memory ~ O(n).
#   P2  REML(TRUE) / ML(TRUE) ratio GROWS with n   => explains the asymmetry.
#   P3  REML(FALSE) stays cheap                    => the flag is the fix.
# If P2 fails (ratio flat), my explanation of the ML/REML gap is WRONG, and the
# new control flag is merely a useful knob that does not solve Ayumi's problem.
#
# Run: OPENBLAS_NUM_THREADS=1 NOT_CRAN=true R_PROFILE_USER=/dev/null \
#        Rscript --no-init-file scratchpad/sdreport_scaling_probe.R
# ---------------------------------------------------------------------------
suppressMessages(devtools::load_all(".", quiet = TRUE))
stopifnot(requireNamespace("ape", quietly = TRUE))

NS <- as.integer(strsplit(Sys.getenv("NTIPS", "100,200,400"), ",")[[1]])

sim_biv_phylo <- function(n_tip, seed = 7L) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  sp <- tree$tip.label
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  L <- t(chol(K + diag(1e-8, n_tip)))
  z_species <- stats::rnorm(n_tip)
  u1 <- as.vector(L %*% stats::rnorm(n_tip)) * 0.6
  u2 <- as.vector(L %*% stats::rnorm(n_tip)) * 0.6
  x <- stats::rnorm(n_tip)
  y1 <- 0.3 + 0.5 * x + u1 + stats::rnorm(n_tip, sd = 0.4)
  y2 <- -0.2 + 0.3 * x + u2 + stats::rnorm(n_tip, sd = 0.4)
  list(tree = tree,
       data = data.frame(species = sp, x = x, z_species = z_species,
                         y1 = y1, y2 = y2, stringsAsFactors = FALSE))
}

fit_no_sdreport <- function(sim, reml) {
  tree <- sim$tree
  tryCatch(
    drmTMB(
      bf(mu1 = y1 ~ x + phylo(1 | species, tree = tree),
         mu2 = y2 ~ x + phylo(1 | species, tree = tree),
         sigma1 = ~1, sigma2 = ~1, rho12 = ~1,
         sd_phylo1(species) ~ z_species,
         sd_phylo2(species) ~ z_species),
      family = biv_gaussian(), data = sim$data, REML = reml,
      control = drm_control(se = FALSE, keep_tmb_object = TRUE,
                            optimizer = list(eval.max = 800, iter.max = 800))
    ), error = function(e) e)
}

# Peak allocation during ONE sdreport call, isolated by gc(reset = TRUE).
timed_sdreport <- function(obj, par, report_cov, skip_delta = FALSE) {
  invisible(gc(reset = TRUE, full = TRUE))
  t0 <- proc.time()[["elapsed"]]
  sdr <- tryCatch(
    TMB::sdreport(obj, par.fixed = par,
                  getReportCovariance = report_cov,
                  skip.delta.method = skip_delta),
    error = function(e) e)
  el <- proc.time()[["elapsed"]] - t0
  g <- gc(full = TRUE)
  peak_mb <- g[["Vcells", "max used"]] * 8 / 1e6
  if (inherits(sdr, "error")) {
    return(list(ok = FALSE, secs = el, mb = peak_mb, nrep = NA_integer_,
                msg = substr(conditionMessage(sdr), 1, 60)))
  }
  list(ok = TRUE, secs = el, mb = peak_mb, nrep = length(sdr$value), msg = "")
}

cat(sprintf("%-6s %-5s %-11s %8s %10s %8s %s\n",
            "n_tip","est","report_cov","secs","peakVcellMB","n_ADREP","status"))
cat(strrep("-", 78), "\n")
res <- list()
for (n in NS) {
  sim <- sim_biv_phylo(n)
  for (reml in c(FALSE, TRUE)) {
    f <- fit_no_sdreport(sim, reml)
    est <- if (reml) "REML" else "ML"
    if (inherits(f, "error")) {
      cat(sprintf("%-6d %-5s %-11s %8s %10s %8s FIT ERROR: %s\n",
                  n, est, "-", "-", "-", "-", substr(conditionMessage(f), 1, 40)))
      next
    }
    for (rc in c(TRUE, FALSE)) {
      r <- timed_sdreport(f$obj, f$opt$par, rc)
      cat(sprintf("%-6d %-5s %-11s %8.2f %10.1f %8s %s\n", n, est, rc,
                  r$secs, r$mb, ifelse(is.na(r$nrep), "-", r$nrep),
                  if (r$ok) "ok" else paste("FAILED:", r$msg)))
      res[[length(res) + 1L]] <- data.frame(n = n, est = est, report_cov = rc,
                                            secs = r$secs, mb = r$mb, ok = r$ok)
    }
  }
}
d <- do.call(rbind, res)
saveRDS(d, "scratchpad/sdreport_scaling_probe.rds")

cat("\n=== SCALING (memory ratio between consecutive n; 4.0 = quadratic, 2.0 = linear) ===\n")
for (e in unique(d$est)) for (rc in c(TRUE, FALSE)) {
  s <- d[d$est == e & d$report_cov == rc, ]
  s <- s[order(s$n), ]
  if (nrow(s) < 2) next
  ratios <- round(s$mb[-1] / s$mb[-nrow(s)], 2)
  cat(sprintf("  %-4s report_cov=%-5s  MB: %s   ratios: %s\n", e, rc,
              paste(round(s$mb, 1), collapse = " -> "), paste(ratios, collapse = ", ")))
}
cat("\n=== P2: does REML/ML cost ratio GROW with n? (if flat, my ML/REML story is wrong) ===\n")
for (n in NS) {
  a <- d[d$n == n & d$est == "REML" & d$report_cov, ]
  b <- d[d$n == n & d$est == "ML"   & d$report_cov, ]
  if (nrow(a) && nrow(b)) cat(sprintf("  n=%-5d REML/ML  mem %.2fx  time %.2fx\n",
                                      n, a$mb / b$mb, a$secs / max(b$secs, 1e-6)))
}
cat("\nwrote scratchpad/sdreport_scaling_probe.rds\n")
