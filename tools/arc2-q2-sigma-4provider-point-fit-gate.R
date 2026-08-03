#!/usr/bin/env Rscript

# Local point-fit gate for the four gaussian matched-q2 sigma cells
# (mc-0279 phylo, mc-0292 spatial, mc-0304 animal, mc-0316 relmat). Runs the
# provider-specific arc2_*_sigma_q2_fixture()/arc2_phylo_sigma_q2_nolabel_
# fixture() builders at 5 seeds, fits the auto-linked unlabelled q2 formula,
# reads the marginal SD estimates off profile_targets(), and checks the
# predeclared point-fit gate (mean relative error <= 0.35 per provider,
# reported per-seed). Never gates the auto-linked correlation target -- see
# each fixture file's header for why. Prints provider matrix condition
# numbers before any fit.
#
# Writes its results table to --outdir= (default: a directory OUTSIDE this
# repo, since this diagnostic script's own results are not part of the
# fixture deliverable this task's scope confines to tools/).

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
outdir_arg <- grep("^--outdir=", args, value = TRUE)
outdir <- if (length(outdir_arg)) sub("^--outdir=", "", outdir_arg[[1L]]) else NULL

root <- normalizePath(dirname(dirname(
  sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
)))
setwd(root)

seeds <- c(101L, 202L, 303L, 404L, 505L)

source(file.path(root, "tools/arc2-phylo-sigma-fixtures.R"))
source(file.path(root, "tools/arc2-spatial-sigma-q2-fixtures.R"))
source(file.path(root, "tools/arc2-animal-sigma-q2-fixtures.R"))
source(file.path(root, "tools/arc2-relmat-sigma-q2-fixtures.R"))

relerr <- function(est, truth) abs(est - truth) / truth

run_provider <- function(cell_id, provider_label, fixture_fn, formula_fn,
                          mu_target, sigma_target, cor_target) {
  rows <- lapply(seeds, function(s) {
    fx <- fixture_fn(seed = s)
    dat <- fx$data
    form <- formula_fn(fx)
    fit <- tryCatch(
      drmTMB::drmTMB(form, family = stats::gaussian(), data = dat),
      error = function(e) e
    )
    if (inherits(fit, "error")) {
      return(data.frame(
        cell_id = cell_id, seed = s, conv = NA_integer_, pdHess = NA,
        est_mu = NA_real_, est_sigma = NA_real_, est_cor = NA_real_,
        relerr_mu = NA_real_, relerr_sigma = NA_real_,
        error = conditionMessage(fit), stringsAsFactors = FALSE
      ))
    }
    pt <- drmTMB::profile_targets(fit)
    mu_row <- subset(pt, parm == mu_target)
    sigma_row <- subset(pt, parm == sigma_target)
    cor_row <- subset(pt, parm == cor_target)
    data.frame(
      cell_id = cell_id, seed = s,
      conv = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
      est_mu = mu_row$estimate[[1L]], est_sigma = sigma_row$estimate[[1L]],
      est_cor = if (nrow(cor_row)) cor_row$estimate[[1L]] else NA_real_,
      relerr_mu = relerr(mu_row$estimate[[1L]], fx$true_sd_mu),
      relerr_sigma = relerr(sigma_row$estimate[[1L]], fx$true_log_sd_sigma),
      error = "", stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  cat(sprintf("\n=== %s (%s) ===\n", cell_id, provider_label))
  print(out, row.names = FALSE)
  cat(sprintf(
    "mean relerr_mu = %.3f, mean relerr_sigma = %.3f, gate (<=0.35 both) = %s\n",
    mean(out$relerr_mu, na.rm = TRUE), mean(out$relerr_sigma, na.rm = TRUE),
    ifelse(
      all(!is.na(out$relerr_mu)) && all(!is.na(out$relerr_sigma)) &&
        mean(out$relerr_mu) <= 0.35 && mean(out$relerr_sigma) <= 0.35 &&
        all(out$conv == 0L) && all(out$pdHess),
      "PASS", "FAIL"
    )
  ))
  out
}

cat("=== Condition numbers ===\n")
tree0 <- ape::rcoal(60L)
A_phylo <- ape::vcv(tree0, corr = TRUE)
cat("phylo A (correlation-scale vcv), n_tip=60, one fresh tree:", kappa(A_phylo), "\n")

n_side <- 9L
site_levels <- paste0("site_", seq_len(n_side^2))
coords <- data.frame(
  x = rep(seq_len(n_side), each = n_side), y = rep(seq_len(n_side), times = n_side),
  row.names = site_levels
)
precision <- drmTMB:::drm_spatial_coords_precision(coords, site = site_levels, group = "site")
cat("spatial precision matrix, 9x9 grid (81 sites):", kappa(as.matrix(precision$precision)), "\n")

fx_animal <- arc2_animal_sigma_q2_fixture(seed = 101L)
cat("animal A (40-individual, n_founders=4 pedigree):", kappa(fx_animal$A), "\n")

fx_relmat <- arc2_relmat_sigma_q2_fixture(seed = 101L)
cat("relmat K (n_id=80 AR1-Toeplitz):", kappa(fx_relmat$K), "\n")

results <- list()

results$phylo <- run_provider(
  "mc-0279", "phylo", arc2_phylo_sigma_q2_nolabel_fixture,
  function(fx) {
    tree <- fx$tree
    drmTMB::bf(y ~ drmTMB::phylo(1 | species, tree = tree), sigma ~ drmTMB::phylo(1 | species, tree = tree))
  },
  "sd:mu:mu:phylo(1 | species)", "sd:sigma:sigma:phylo(1 | species)",
  "cor:phylo:cor(mu:(Intercept),sigma:(Intercept) | phylo | species)"
)

results$spatial <- run_provider(
  "mc-0292", "spatial", arc2_spatial_sigma_q2_fixture,
  function(fx) {
    coords <- fx$coords
    drmTMB::bf(y ~ drmTMB::spatial(1 | site, coords = coords), sigma ~ drmTMB::spatial(1 | site, coords = coords))
  },
  "sd:mu:mu:spatial(1 | site)", "sd:sigma:sigma:spatial(1 | site)",
  "cor:spatial:cor(mu:(Intercept),sigma:(Intercept) | spatial | site)"
)

results$animal <- run_provider(
  "mc-0304", "animal", arc2_animal_sigma_q2_fixture,
  function(fx) {
    A <- fx$A
    drmTMB::bf(y ~ drmTMB::animal(1 | id, A = A), sigma ~ drmTMB::animal(1 | id, A = A))
  },
  "sd:mu:mu:animal(1 | id)", "sd:sigma:sigma:animal(1 | id)",
  "cor:animal:cor(mu:(Intercept),sigma:(Intercept) | animal | id)"
)

results$relmat <- run_provider(
  "mc-0316", "relmat", arc2_relmat_sigma_q2_fixture,
  function(fx) {
    K <- fx$K
    drmTMB::bf(y ~ drmTMB::relmat(1 | id, K = K), sigma ~ drmTMB::relmat(1 | id, K = K))
  },
  "sd:mu:mu:relmat(1 | id)", "sd:sigma:sigma:relmat(1 | id)",
  "cor:relmat:cor(mu:(Intercept),sigma:(Intercept) | relmat | id)"
)

out_dir <- if (!is.null(outdir)) outdir else file.path(tempdir(), "arc2-q2-sigma-4provider-point-fit-gate")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
all_out <- do.call(rbind, results)
write.table(
  all_out, file.path(out_dir, "point-fit-gate-results.tsv"),
  sep = "\t", quote = FALSE, row.names = FALSE
)
cat("\nWrote", file.path(out_dir, "point-fit-gate-results.tsv"), "\n")
