#!/usr/bin/env Rscript
# No-fit G13 mechanism diagnostic: exact-covariance GLS for the fixed-tree pilot.
args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep('^--file=', commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop('Run with Rscript.', call. = FALSE)
root <- normalizePath(file.path(dirname(sub('^--file=', '', script_arg)), '..'), mustWork = TRUE)
value <- function(prefix) {
  x <- grep(paste0('^', prefix), args, value = TRUE)
  if (length(x) != 1L) return(NULL)
  sub(prefix, '', x)
}
self_test <- identical(args, '--self-test')
make_schedule <- function(kind, n_species) {
  if (identical(kind, '6_irregular')) return(rep(list(c(0, .5, 2, 4.5, 7, 11)), n_species))
  if (identical(kind, '12_irregular')) return(rep(list(c(0, .25, 1, 2.5, 4, 6.5, 9, 12, 16, 21, 27, 34)), n_species))
  base <- c(0, .5, 1.7, 3.2, 5, 8.1, 11.3, 15.6, 20, 25.4, 31, 38)
  lapply(seq_len(n_species), function(i) base[seq_len(4L + (i - 1L) %% 9L)])
}
make_tree <- function(n, seed) {
  set.seed(seed)
  tree <- ape::rcoal(n)
  tree$tip.label <- sprintf('sp_%03d', seq_len(n))
  tree
}
simulate_response <- function(meta, tree, seed) {
  set.seed(seed)
  schedules <- make_schedule(meta$occasions, meta$n_species)
  data <- do.call(rbind, Map(function(species, elapsed) data.frame(species = species, elapsed = elapsed), tree$tip.label, schedules))
  data$species <- factor(data$species, levels = tree$tip.label)
  data$between <- rep(sample(rep(c(-.5, .5), each = meta$n_species / 2L)), lengths(schedules))
  data$within <- unlist(lapply(schedules, function(time) {
    z <- sample(rep(c(-.5, .5), length.out = length(time)))
    z - mean(z)
  }), use.names = FALSE)
  A <- ape::vcv(tree, corr = TRUE)[tree$tip.label, tree$tip.label, drop = FALSE]
  stable <- drop(t(chol(A)) %*% stats::rnorm(meta$n_species, sd = meta$sd_phylo))
  names(stable) <- tree$tip.label
  temporal <- unlist(lapply(schedules, function(time) {
    R <- exp(-meta$decay * abs(outer(time, time, '-')))
    drop(t(chol(R)) %*% stats::rnorm(length(time), sd = meta$sd_temporal))
  }), use.names = FALSE)
  data$y <- .5 * data$between + .5 * data$within + stable[as.character(data$species)] + temporal + stats::rnorm(nrow(data), sd = meta$sigma)
  data[sample.int(nrow(data)), , drop = FALSE]
}
truth_covariance <- function(data, tree, meta) {
  species <- as.character(data$species)
  elapsed <- data$elapsed
  A <- ape::vcv(tree, corr = TRUE)[tree$tip.label, tree$tip.label, drop = FALSE]
  stable <- meta$sd_phylo^2 * A[species, species, drop = FALSE]
  same_species <- outer(species, species, `==`)
  temporal <- meta$sd_temporal^2 * same_species * exp(-meta$decay * abs(outer(elapsed, elapsed, '-')))
  stable + temporal + diag(meta$sigma^2, nrow(data))
}
truth_gls <- function(y, X, V, level = .95) {
  root <- chol(V)
  yw <- forwardsolve(t(root), y)
  Xw <- forwardsolve(t(root), X)
  covariance <- solve(crossprod(Xw))
  estimate <- drop(covariance %*% crossprod(Xw, yw))
  se <- sqrt(diag(covariance))
  critical <- stats::qnorm((1 + level) / 2)
  list(estimate = estimate, se = se, lower = estimate - critical * se, upper = estimate + critical * se)
}
if (self_test) {
  V <- diag(c(1, 4, 9))
  X <- cbind(1, c(-1, 0, 1))
  y <- c(1, 2, 4)
  out <- truth_gls(y, X, V)
  expect <- solve(crossprod(X, solve(V, X)), crossprod(X, solve(V, y)))
  stopifnot(isTRUE(all.equal(unname(out$estimate), as.vector(expect), tolerance = 1e-12)))
  stopifnot(isTRUE(all.equal(out$lower[[1L]], out$estimate[[1L]] - stats::qnorm(.975) * out$se[[1L]], tolerance = 1e-12)))
  cat('PHYLO_TEMPORAL_OU_FIXED_TREE_TRUTH_GLS_SELFTEST_PASS\n')
  quit(save = 'no')
}
if (length(args) != 3L || any(!grepl('^--(replicates|pilot-results|output-dir)=', args))) {
  stop('Use --replicates=<positive integer> --pilot-results=<replicates.csv> --output-dir=<new directory>, or --self-test.', call. = FALSE)
}
replicates <- suppressWarnings(as.integer(value('--replicates=')))
pilot_path <- value('--pilot-results=')
out_dir <- value('--output-dir=')
if (length(replicates) != 1L || is.na(replicates) || replicates < 1L ||
    !nzchar(pilot_path) || !file.exists(pilot_path) || !nzchar(out_dir) || file.exists(out_dir)) {
  stop('Replicates must be positive, pilot results must exist, and output directory must be new.', call. = FALSE)
}
Sys.setenv(OMP_NUM_THREADS = '1', OPENBLAS_NUM_THREADS = '1')
source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))
manifest <- phylo_temporal_ou_g11_manifest()
cells <- manifest[match(c('P1', 'P2', 'P3'), manifest$cell), , drop = FALSE]
pilot <- utils::read.csv(pilot_path, stringsAsFactors = FALSE)
required <- c('cell', 'tree_seed', 'replicate', 'precision', 'estimate', 'lower', 'upper', 'available')
if (!all(required %in% names(pilot))) stop('Pilot results lack required columns.', call. = FALSE)
pilot <- pilot[pilot$precision == 'default', required, drop = FALSE]
expected <- expand.grid(cell = c('P1', 'P2', 'P3'), replicate = seq_len(replicates), stringsAsFactors = FALSE)
key <- paste(expected$cell, expected$replicate)
pilot_key <- paste(pilot$cell, pilot$replicate)
if (nrow(pilot) != nrow(expected) || anyDuplicated(pilot_key) || !setequal(pilot_key, key) || !all(pilot$available)) {
  stop('Pilot default-profile denominator is incomplete or unavailable.', call. = FALSE)
}
pilot <- pilot[match(key, pilot_key), , drop = FALSE]
dir.create(out_dir, recursive = TRUE)
rows <- list(); index <- 0L
for (i in seq_len(nrow(cells))) {
  meta <- cells[i, , drop = FALSE]
  tree_seed <- 2026109000L + i
  tree <- make_tree(meta$n_species, tree_seed)
  for (replicate in seq_len(replicates)) {
    data <- simulate_response(meta, tree, 2026110000L + 1000L * i + replicate)
    X <- stats::model.matrix(~ between + within, data)
    gls <- truth_gls(data$y, X, truth_covariance(data, tree, meta))
    row <- pilot[pilot$cell == meta$cell & pilot$replicate == replicate, , drop = FALSE]
    if (!identical(as.integer(row$tree_seed), tree_seed)) stop('Pilot tree seed disagrees with frozen generator.', call. = FALSE)
    index <- index + 1L
    rows[[index]] <- data.frame(
      cell = meta$cell, tree_seed = tree_seed, replicate = replicate,
      truth_gls_estimate = gls$estimate[[1L]], truth_gls_se = gls$se[[1L]],
      truth_gls_lower = gls$lower[[1L]], truth_gls_upper = gls$upper[[1L]],
      truth_gls_covers = gls$lower[[1L]] <= 0 && gls$upper[[1L]] >= 0,
      profile_estimate = row$estimate, profile_lower = row$lower, profile_upper = row$upper,
      profile_covers = row$lower <= 0 && row$upper >= 0,
      stringsAsFactors = FALSE
    )
  }
}
results <- do.call(rbind, rows)
summary <- do.call(rbind, lapply(split(results, results$cell), function(x) data.frame(
  cell = x$cell[[1L]], n = nrow(x), truth_gls_coverage = mean(x$truth_gls_covers),
  profile_coverage = mean(x$profile_covers), mean_truth_gls_width = mean(x$truth_gls_upper - x$truth_gls_lower),
  mean_profile_width = mean(x$profile_upper - x$profile_lower),
  stringsAsFactors = FALSE
)))
utils::write.csv(results, file.path(out_dir, 'replicates.csv'), row.names = FALSE)
utils::write.csv(summary, file.path(out_dir, 'summary.csv'), row.names = FALSE)
writeLines(c('# Fixed-tree true-covariance GLS comparison', '', sprintf('Replicates per cell: %d.', replicates), 'This independently regenerates the frozen fixed-tree datasets and computes exact Gaussian GLS intervals using the generating covariance matrix.', 'It launches no drmTMB fit and is a mechanism diagnostic, not calibration evidence.'), file.path(out_dir, 'RESULTS.md'))
cat('PHYLO_TEMPORAL_OU_FIXED_TREE_TRUTH_GLS_PASS\n')
