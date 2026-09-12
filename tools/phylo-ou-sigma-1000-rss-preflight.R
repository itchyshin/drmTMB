#!/usr/bin/env Rscript

# Sparse resource preflight for the admitted joint OU intercept model. This
# deliberately never constructs an all-tip dense covariance matrix.

if (!requireNamespace("ape", quietly = TRUE) || !requireNamespace("pkgload", quietly = TRUE)) {
  stop("This preflight needs ape and pkgload.", call. = FALSE)
}
pkgload::load_all(".", compile = TRUE, quiet = TRUE)
set.seed(2026091220)
n_tip <- 1000L
tree <- ape::rcoal(n_tip)
tree$tip.label <- paste0("sp", seq_len(n_tip))
species <- rep(tree$tip.label, each = 2L)
x <- rep(c(-0.5, 0.5), times = n_tip)
dat <- data.frame(
  y = 0.2 + 0.15 * x + stats::rnorm(length(species), sd = exp(-1 + 0.1 * x)),
  x, species
)
elapsed <- system.time({
  fit <- suppressWarnings(drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree, model = "ou"),
      sigma ~ x + phylo(1 | species, tree = tree, model = "ou")
    ),
    data = dat, family = gaussian(),
    control = drm_control(optimizer = list(eval.max = 400, iter.max = 400))
  ))
})
phylo <- fit$model$structured$phylo_mu
if (!identical(phylo$precision$n_re, 2L * n_tip - 1L) ||
    length(fit$model$start$u_phylo) != 2L * phylo$precision$n_re ||
    !inherits(fit$model$tmb_data$Q_phylo, "sparseMatrix") ||
    !identical(dim(fit$model$tmb_data$Q_phylo), rep(phylo$precision$n_re, 2L))) {
  stop("Sparse OU preflight did not retain the expected all-node layout.", call. = FALSE)
}
cat(sprintf(
  "PHYLO_OU_SIGMA_1000_PREFLIGHT_PASS tips=%d rows=%d nodes=%d latent=%d elapsed_seconds=%.3f convergence=%d pdHess=%s\n",
  n_tip, nrow(dat), phylo$precision$n_re, length(fit$model$start$u_phylo),
  elapsed[["elapsed"]], fit$opt$convergence, isTRUE(fit$sdr$pdHess)
))
