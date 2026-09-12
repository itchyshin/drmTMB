#!/usr/bin/env Rscript

# Short diagnostic preflight for the admitted OU location field.  It contrasts
# a replicated clean design with a one-observation-per-species weak design.
# It is intentionally not a coverage or general recovery campaign.
#
# Usage:
#   Rscript tools/phylo-ou-recovery-preflight.R /output/path

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("Usage: Rscript tools/phylo-ou-recovery-preflight.R <output-dir>", call. = FALSE)
}
output_dir <- args[[1L]]
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
if (!requireNamespace("ape", quietly = TRUE) || !requireNamespace("pkgload", quietly = TRUE)) {
  stop("This preflight needs ape and pkgload.", call. = FALSE)
}
pkgload::load_all(".", compile = TRUE, quiet = TRUE)

simulate_fit <- function(seed, condition) {
  set.seed(seed)
  clean <- identical(condition, "clean")
  n_species <- if (clean) 24L else 12L
  n_each <- if (clean) 8L else 1L
  alpha_truth <- if (clean) 0.8 else 0.05
  tree <- ape::rcoal(n_species)
  tree$tip.label <- paste0("sp", seq_len(n_species))
  species <- rep(tree$tip.label, each = n_each)
  temp_species <- setNames(as.numeric(scale(stats::rnorm(n_species))), tree$tip.label)
  temperature <- unname(temp_species[species])
  precipitation <- stats::rnorm(length(species))
  covariance <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = alpha_truth)
  field <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_species))
  gamma <- exp(-0.5 + 0.25 * temperature)
  sigma <- exp(-1 + 0.10 * precipitation)
  y <- 0.15 + 0.3 * temperature + gamma * field[match(species, tree$tip.label)] +
    stats::rnorm(length(species), sd = sigma)
  started <- Sys.time()
  fit <- tryCatch(
    drmTMB(
      bf(
        y ~ temperature + phylo(1 | species, tree = tree, model = "ou"),
        sigma ~ precipitation,
        sd(species, level = "phylogenetic") ~ temperature
      ),
      family = gaussian(), data = data.frame(y, temperature, precipitation, species),
      REML = FALSE, control = drm_control(optimizer = list(eval.max = 1000, iter.max = 1000))
    ),
    error = identity
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(fit, "error")) {
    return(data.frame(condition, seed, n_species, n_each, alpha_truth, elapsed,
      fit_ok = FALSE, convergence = NA_integer_, pdHess = NA, max_gradient = NA_real_,
      alpha_estimate = NA_real_, error = conditionMessage(fit)))
  }
  data.frame(condition, seed, n_species, n_each, alpha_truth, elapsed,
    fit_ok = TRUE, convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = max(abs(fit$obj$gr(fit$opt$par))),
    alpha_estimate = unname(fit$decaypars$phylo[["decay_phylo"]]), error = NA_character_)
}

seeds <- 2026091201:2026091206
results <- do.call(rbind, lapply(c("clean", "weak"), function(condition) {
  do.call(rbind, lapply(seeds, simulate_fit, condition = condition))
}))
write.csv(results, file.path(output_dir, "recovery-preflight.csv"), row.names = FALSE)
writeLines(c(
  "Claim boundary: this short preflight is not a recovery, coverage, or interval-calibration result.",
  "The weak condition is deliberately expected to expose non-identifiability."
), file.path(output_dir, "README.txt"))
cat(sprintf("PHYLO_OU_RECOVERY_PREFLIGHT_PASS fits=%d output=%s\n",
  nrow(results), normalizePath(output_dir)
))
