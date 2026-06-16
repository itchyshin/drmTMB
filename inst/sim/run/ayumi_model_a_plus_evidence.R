#!/usr/bin/env Rscript
# Ayumi Model A+ evidence (Phase 2): reproducible bivariate location-scale
# phylogenetic fit on the real ~10,440-tip bird data, plus the no-phylo null,
# to compute the mean-side phylogenetic likelihood-ratio with banked numbers.
#
# DATA PROVENANCE (NOT in the repo): birds_tarsus_beak_10440.rds -- an RDS list:
#   $data : 10,440 x 7 data.frame with Tarsus_Length_z, Beak_Length_Culmen_z,
#           mean_tavg_combined_z, mean_prec_combined_z, log_mass_z, tree_tip
#   $tree : a 10,440-tip phylo (clootl Aves)
#   One record per species. Set DRMTMB_AYUMI_DATA to its path.
#
# Run (from this worktree, after the package compiles):
#   DRMTMB_AYUMI_DATA=/path/to/birds_tarsus_beak_10440.rds \
#     Rscript inst/sim/run/ayumi_model_a_plus_evidence.R
#
# Model A+ = phylo on BOTH means with a cross-trait phylo correlation
#            (phylo(1 | p | tree_tip)), fixed-effect sigma ~ climate (no phylo
#            on the scale), constant rho12.  This is the identified core.
# Null     = identical fixed effects, NO phylo on the means.
# LRT      = 2*(ll_full - ll_null); df = (sd_phylo[mu1], sd_phylo[mu2], their
#            phylo correlation) = 3.  This is a BOUNDARY test (the two SDs are 0
#            and the correlation is unidentified under H0): the naive chi^2_3
#            p-value is conservative (Self & Liang 1987; Stram & Lee 1994).  The
#            LR is reported for the mean-phylo signal only -- it says nothing
#            about the (weakly identified) scale-phylo block.

suppressMessages(devtools::load_all(".", quiet = TRUE))

data_path <- Sys.getenv(
  "DRMTMB_AYUMI_DATA",
  "/private/tmp/ayumi-for-test/birds_tarsus_beak_10440.rds"
)
if (!file.exists(data_path)) {
  stop("Ayumi data not found at: ", data_path,
       "\nSet DRMTMB_AYUMI_DATA to the birds_tarsus_beak_10440.rds path.")
}
p <- readRDS(data_path)
dat <- p$data
tree <- p$tree
cat(sprintf("Data: %d rows, %d tips\n", nrow(dat), length(tree$tip.label)))

model_Aplus <- bf(
  mu1 = Tarsus_Length_z ~ mean_tavg_combined_z + mean_prec_combined_z +
    mean_tavg_combined_z:mean_prec_combined_z + log_mass_z +
    phylo(1 | p | tree_tip, tree = tree),
  mu2 = Beak_Length_Culmen_z ~ mean_tavg_combined_z + mean_prec_combined_z +
    mean_tavg_combined_z:mean_prec_combined_z + log_mass_z +
    phylo(1 | p | tree_tip, tree = tree),
  sigma1 = ~ mean_tavg_combined_z + mean_prec_combined_z +
    mean_tavg_combined_z:mean_prec_combined_z + log_mass_z,
  sigma2 = ~ mean_tavg_combined_z + mean_prec_combined_z +
    mean_tavg_combined_z:mean_prec_combined_z + log_mass_z,
  rho12 = ~1
)
model_null <- bf(
  mu1 = Tarsus_Length_z ~ mean_tavg_combined_z + mean_prec_combined_z +
    mean_tavg_combined_z:mean_prec_combined_z + log_mass_z,
  mu2 = Beak_Length_Culmen_z ~ mean_tavg_combined_z + mean_prec_combined_z +
    mean_tavg_combined_z:mean_prec_combined_z + log_mass_z,
  sigma1 = ~ mean_tavg_combined_z + mean_prec_combined_z +
    mean_tavg_combined_z:mean_prec_combined_z + log_mass_z,
  sigma2 = ~ mean_tavg_combined_z + mean_prec_combined_z +
    mean_tavg_combined_z:mean_prec_combined_z + log_mass_z,
  rho12 = ~1
)

fit_one <- function(form, label) {
  t0 <- proc.time()[["elapsed"]]
  fit <- drmTMB(form,
    family = biv_gaussian(), data = dat,
    control = drm_control(optimizer_preset = "robust")
  )
  elapsed <- proc.time()[["elapsed"]] - t0
  ll <- -as.numeric(fit$opt$objective)
  k <- length(fit$opt$par)
  maxgrad <- tryCatch(max(abs(fit$obj$gr(fit$opt$par))),
    error = function(e) NA_real_
  )
  cat(sprintf(
    "[%s] conv=%s pdHess=%s logLik=%.4f k=%d max|grad|=%.4g  %.1fs\n",
    label, fit$opt$convergence, isTRUE(fit$sdr$pdHess), ll, k, maxgrad, elapsed
  ))
  list(
    label = label, convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess), logLik = ll, k = k,
    max_abs_grad = maxgrad, elapsed_sec = elapsed,
    sdr_fixed = tryCatch(summary(fit$sdr, "fixed"), error = function(e) NULL),
    sdr_report = tryCatch(summary(fit$sdr, "report"), error = function(e) NULL),
    corpars = tryCatch(fit$corpars, error = function(e) NULL)
  )
}

res_full <- fit_one(model_Aplus, "ModelA+")
res_null <- fit_one(model_null, "null(no mean-phylo)")

LR <- 2 * (res_full$logLik - res_null$logLik)
df <- res_full$k - res_null$k
p_naive <- pchisq(LR, df = df, lower.tail = FALSE)
cat(sprintf(
  "\nLRT mean-phylo: LR=%.2f df=%d naive_p=%.3g (boundary; conservative)\n",
  LR, df, p_naive
))

out <- list(
  data_path = data_path,
  n_rows = nrow(dat), n_tips = length(tree$tip.label),
  full = res_full, null = res_null,
  LR = LR, df = df, p_naive = p_naive
)
out_path <- file.path(
  Sys.getenv("DRMTMB_AYUMI_OUT", "/tmp"), "ayumi-model-a-plus-results.rds"
)
saveRDS(out, out_path)
cat("Saved results RDS to ", out_path, "\n", sep = "")
