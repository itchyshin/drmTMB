#!/usr/bin/env Rscript

# Frozen local point-recovery panel for the first phylogenetic OU covariance
# provider. This is deliberately a small, high-information implementation
# check: it supports no interval, coverage, non-Gaussian, scale-side, or broad
# phylogenetic-Ou claim.

args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args) == 2L && identical(args[[1L]], "--out")) {
  args[[2L]]
} else if (length(args) == 0L) {
  "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/recovery"
} else {
  stop("Usage: Rscript --vanilla tools/run-phylo-ou-covariance-recovery.R [--out PATH]", call. = FALSE)
}

if (!requireNamespace("ape", quietly = TRUE)) stop("ape is required.", call. = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE)) stop("pkgload is required.", call. = FALSE)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
pkgload::load_all(".", compile = FALSE, quiet = TRUE)

truth <- list(beta0 = 0.2, beta_x = 0.5, sd_phylo = 0.8, sigma = 0.3)
design <- expand.grid(
  decay = c(0.2, 0.8, 2),
  layout = c("balanced", "unbalanced"),
  order = c("ordered", "shuffled"),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
design$fixture_id <- sprintf("F%02d", seq_len(nrow(design)))
design$seed <- 2026091200L + seq_len(nrow(design))

make_fixture <- function(row) {
  set.seed(row$seed)
  tree <- ape::rcoal(48L)
  tree$tip.label <- sprintf("sp%02d", seq_len(ape::Ntip(tree)))
  n_obs <- if (identical(row$layout, "balanced")) {
    rep.int(6L, ape::Ntip(tree))
  } else {
    rep(c(3L, 4L, 5L, 6L, 7L, 8L), length.out = ape::Ntip(tree))
  }
  species <- rep(tree$tip.label, times = n_obs)
  x <- rep(c(-0.75, -0.25, 0.25, 0.75, -0.4, 0.4), length.out = length(species))
  correlation <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = row$decay)
  effect <- drop(t(chol(correlation)) %*% stats::rnorm(ape::Ntip(tree), sd = truth$sd_phylo))
  data <- data.frame(
    y = truth$beta0 + truth$beta_x * x + effect[match(species, tree$tip.label)] +
      stats::rnorm(length(species), sd = truth$sigma),
    x = x,
    species = species,
    stringsAsFactors = FALSE
  )
  if (identical(row$order, "shuffled")) data <- data[sample.int(nrow(data)), , drop = FALSE]
  list(tree = tree, data = data)
}

fit_one <- function(row) {
  fixture <- make_fixture(row)
  tree <- fixture$tree
  elapsed <- system.time({
    fit <- tryCatch(
      suppressWarnings(drmTMB(
        bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
        data = fixture$data, family = gaussian(), REML = FALSE
      )),
      error = identity
    )
  })[["elapsed"]]
  if (inherits(fit, "error")) {
    return(data.frame(
      fixture_id = row$fixture_id, seed = row$seed, decay_truth = row$decay,
      layout = row$layout, order = row$order, n = nrow(fixture$data),
      elapsed_seconds = elapsed, status = "error", message = conditionMessage(fit),
      convergence = NA_integer_, pd_hess = NA, objective = NA_real_,
      beta0 = NA_real_, beta_x = NA_real_, sd_phylo = NA_real_, decay_phylo = NA_real_,
      stringsAsFactors = FALSE
    ))
  }
  saveRDS(fit, file.path(out, paste0(row$fixture_id, ".rds")))
  data.frame(
    fixture_id = row$fixture_id, seed = row$seed, decay_truth = row$decay,
    layout = row$layout, order = row$order, n = nrow(fixture$data),
    elapsed_seconds = elapsed, status = "fit", message = "",
    convergence = fit$opt$convergence, pd_hess = isTRUE(fit$sdr$pdHess),
    objective = fit$opt$objective,
    beta0 = unname(fit$coefficients$mu[["(Intercept)"]]),
    beta_x = unname(fit$coefficients$mu[["x"]]),
    sd_phylo = unname(fit$sdpars$mu[["phylo(1 | species)"]]),
    decay_phylo = unname(fit$decaypars$phylo[["decay_phylo"]]),
    stringsAsFactors = FALSE
  )
}

rows <- lapply(seq_len(nrow(design)), function(i) fit_one(design[i, , drop = FALSE]))
results <- do.call(rbind, rows)
results$beta0_error <- results$beta0 - truth$beta0
results$beta_x_error <- results$beta_x - truth$beta_x
results$log_sd_error <- log(results$sd_phylo / truth$sd_phylo)
results$log_decay_error <- log(results$decay_phylo / results$decay_truth)
utils::write.csv(results, file.path(out, "results.csv"), row.names = FALSE)
utils::write.csv(design, file.path(out, "design.csv"), row.names = FALSE)

complete <- with(results, status == "fit" & is.finite(objective) &
  is.finite(beta0) & is.finite(beta_x) & is.finite(sd_phylo) & is.finite(decay_phylo))
criteria <- c(
  all_fixtures_complete = all(complete),
  all_fixed_effect_errors_le_0_20 = all(abs(results$beta0_error[complete]) <= 0.20) &&
    all(abs(results$beta_x_error[complete]) <= 0.20),
  median_abs_log_sd_error_le_0_70 = median(abs(results$log_sd_error[complete])) <= 0.70,
  median_abs_log_decay_error_le_1_00 = median(abs(results$log_decay_error[complete])) <= 1.00
)
summary <- c(
  "# Phylogenetic OU covariance: local point-recovery fixtures",
  "",
  "This immutable 12-fixture local panel checks point recovery for the exact first Gaussian ML location-side provider. It does not establish uncertainty intervals, coverage, scale-side phylogenetic OU, temporal OU, spatial OU, a phylogeny-by-time field, non-Gaussian support, or any broader scientific claim.",
  "",
  "## Predeclared criteria",
  "",
  "- all 12 fixtures finish with finite fitted point estimates and objectives;",
  "- every intercept and x-coefficient absolute error is at most 0.20;",
  "- median absolute log SD error is at most 0.70;",
  "- median absolute log decay error is at most 1.00.",
  "",
  "## Results",
  "",
  sprintf("- completed fits: %d / %d", sum(complete), nrow(results)),
  sprintf("- median elapsed seconds: %.3f", stats::median(results$elapsed_seconds[complete])),
  sprintf("- median absolute log SD error: %.4f", stats::median(abs(results$log_sd_error[complete]))),
  sprintf("- median absolute log decay error: %.4f", stats::median(abs(results$log_decay_error[complete]))),
  "",
  "## Criterion status",
  "",
  paste0("- ", names(criteria), ": ", ifelse(criteria, "PASS", "FAIL")),
  "",
  "`results.csv` retains every fixture, fit error, point estimate, and timing. Each successful fit is retained as `Fxx.rds`."
)
writeLines(summary, file.path(out, "RESULTS.md"))
if (!all(criteria)) stop("PHYLO_OU_COVARIANCE_RECOVERY_FAIL", call. = FALSE)
cat("PHYLO_OU_COVARIANCE_RECOVERY_PASS\n")
