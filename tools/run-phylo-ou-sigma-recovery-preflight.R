#!/usr/bin/env Rscript

# Fixed-seed local preflight for the joint independent OU intercept model.
# It is deliberately negative engineering evidence, not a recovery, coverage,
# or selection campaign: all attempts are retained, including weak and
# boundary outcomes.

args <- commandArgs(trailingOnly = TRUE)
check_only <- identical(args, "--check")
out <- file.path(
  "docs", "dev-log", "implementation-recovery", "2026-09-12-phylo-ou-sigma-preflight",
  "results.csv"
)
if (check_only) {
  if (!file.exists(out)) stop("No retained OU-sigma recovery preflight result exists.", call. = FALSE)
  result <- utils::read.csv(out, stringsAsFactors = FALSE)
  required <- c("informative", "weak_one_row")
  if (!all(required %in% result$condition) || nrow(result) != 4L ||
      !all(c("pdHess", "alpha_mu", "alpha_sigma") %in% names(result)) ||
      !any(!result$pdHess) ||
      !all(is.finite(result$alpha_mu)) || !all(is.finite(result$alpha_sigma))) {
    stop("Retained OU-sigma recovery preflight is incomplete.", call. = FALSE)
  }
  cat("PHYLO_OU_SIGMA_NEGATIVE_PREFLIGHT_PASS\n")
  quit(status = 0L)
}

if (!requireNamespace("ape", quietly = TRUE) || !requireNamespace("pkgload", quietly = TRUE)) {
  stop("This preflight needs ape and pkgload.", call. = FALSE)
}
pkgload::load_all(".", compile = TRUE, quiet = TRUE)
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)

simulate_condition <- function(seed, condition) {
  set.seed(seed)
  tree <- ape::rcoal(12)
  tree$tip.label <- paste0("sp", seq_len(12))
  n_each <- if (identical(condition, "informative")) 6L else 1L
  species <- rep(tree$tip.label, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = length(tree$tip.label))
  c_mu <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 0.7)
  c_sigma <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 1.3)
  u <- drop(t(chol(c_mu)) %*% stats::rnorm(length(tree$tip.label), sd = 0.45))
  v <- drop(t(chol(c_sigma)) %*% stats::rnorm(length(tree$tip.label), sd = 0.25))
  index <- match(species, tree$tip.label)
  sigma <- exp(-1 + 0.2 * x + v[index])
  dat <- data.frame(
    y = 0.1 + 0.3 * x + u[index] + stats::rnorm(length(species), sd = sigma),
    x, species
  )
  fit <- suppressWarnings(drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree, model = "ou"),
      sigma ~ x + phylo(1 | species, tree = tree, model = "ou")
    ),
    data = dat, family = gaussian(),
    control = drm_control(optimizer = list(eval.max = 1500, iter.max = 1500))
  ))
  data.frame(
    seed, condition, n_species = length(tree$tip.label), n_each, n = nrow(dat),
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    alpha_mu = unname(fit$decaypars$phylo[["decay_phylo"]]),
    alpha_sigma = unname(fit$decaypars$phylo[["decay_phylo:sigma"]]),
    logLik = as.numeric(stats::logLik(fit)),
    stringsAsFactors = FALSE
  )
}

result <- do.call(rbind, c(
  lapply(c(2026091216L, 2026091217L), simulate_condition, condition = "informative"),
  lapply(c(2026091218L, 2026091219L), simulate_condition, condition = "weak_one_row")
))
utils::write.csv(result, out, row.names = FALSE)
cat("PHYLO_OU_SIGMA_NEGATIVE_PREFLIGHT_PASS\n")
