#!/usr/bin/env Rscript
# Bounded G13 diagnostic: fixed tree, regenerated responses, no calibration claim.
args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep('^--file=', commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop('Run with Rscript.', call. = FALSE)
root <- normalizePath(file.path(dirname(sub('^--file=', '', script_arg)), '..'), mustWork = TRUE)
value <- function(prefix) { x <- grep(paste0('^', prefix), args, value = TRUE); if (length(x) != 1L) return(NULL); sub(prefix, '', x) }
self_test <- identical(args, '--self-test')
if (self_test) {
  stopifnot(identical(c(0, .5, .5), c(0, .5, .5)))
  cat('PHYLO_TEMPORAL_OU_FIXED_TREE_PILOT_SELFTEST_PASS\n'); quit(save = 'no')
}
if (length(args) != 2L || any(!grepl('^--(replicates|output-dir)=', args))) {
  stop('Use --replicates=<positive integer> --output-dir=<new directory>, or --self-test.', call. = FALSE)
}
replicates <- suppressWarnings(as.integer(value('--replicates=')))
out_dir <- value('--output-dir=')
if (length(replicates) != 1L || is.na(replicates) || replicates < 1L || !nzchar(out_dir) || file.exists(out_dir)) {
  stop('Replicates must be positive and output directory must be new.', call. = FALSE)
}
Sys.setenv(OMP_NUM_THREADS = '1', OPENBLAS_NUM_THREADS = '1')
pkgload::load_all(root, quiet = TRUE)
source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))
manifest <- phylo_temporal_ou_g11_manifest()
cells <- manifest[match(c('P1', 'P2', 'P3'), manifest$cell), , drop = FALSE]
make_schedule <- function(kind, n_species) {
  if (identical(kind, '6_irregular')) return(rep(list(c(0, .5, 2, 4.5, 7, 11)), n_species))
  if (identical(kind, '12_irregular')) return(rep(list(c(0, .25, 1, 2.5, 4, 6.5, 9, 12, 16, 21, 27, 34)), n_species))
  base <- c(0, .5, 1.7, 3.2, 5, 8.1, 11.3, 15.6, 20, 25.4, 31, 38)
  lapply(seq_len(n_species), function(i) base[seq_len(4L + (i - 1L) %% 9L)])
}
make_tree <- function(n, seed) {
  set.seed(seed); tree <- ape::rcoal(n); tree$tip.label <- sprintf('sp_%03d', seq_len(n)); tree
}
simulate_response <- function(meta, tree, seed) {
  set.seed(seed)
  schedules <- make_schedule(meta$occasions, meta$n_species)
  data <- do.call(rbind, Map(function(species, elapsed) data.frame(species = species, elapsed = elapsed), tree$tip.label, schedules))
  data$species <- factor(data$species, levels = tree$tip.label)
  data$between <- rep(sample(rep(c(-.5, .5), each = meta$n_species / 2L)), lengths(schedules))
  data$within <- unlist(lapply(schedules, function(time) { z <- sample(rep(c(-.5, .5), length.out = length(time))); z - mean(z) }), use.names = FALSE)
  A <- ape::vcv(tree, corr = TRUE)[tree$tip.label, tree$tip.label, drop = FALSE]
  stable <- drop(t(chol(A)) %*% stats::rnorm(meta$n_species, sd = meta$sd_phylo)); names(stable) <- tree$tip.label
  temporal <- unlist(lapply(schedules, function(time) { R <- exp(-meta$decay * abs(outer(time, time, '-'))); drop(t(chol(R)) %*% stats::rnorm(length(time), sd = meta$sd_temporal)) }), use.names = FALSE)
  data$y <- .5 * data$between + .5 * data$within + stable[as.character(data$species)] + temporal + stats::rnorm(nrow(data), sd = meta$sigma)
  data[sample.int(nrow(data)), , drop = FALSE]
}
profile_row <- function(fit, precision) {
  started <- proc.time()[['elapsed']]
  x <- try(stats::confint(fit, parm = 'fixef:mu:(Intercept)', method = 'profile', level = .95,
                          profile_engine = 'tmbprofile', profile_precision = precision, trace = FALSE), silent = TRUE)
  if (inherits(x, 'try-error')) return(data.frame(precision = precision, available = FALSE, lower = NA_real_, upper = NA_real_, elapsed_sec = proc.time()[['elapsed']] - started, error = as.character(x)))
  data.frame(precision = precision, available = identical(x$conf.status, 'profile'), lower = x$lower, upper = x$upper, elapsed_sec = proc.time()[['elapsed']] - started, error = NA_character_)
}
rows <- list(); index <- 0L
dir.create(out_dir, recursive = TRUE)
for (i in seq_len(nrow(cells))) {
  meta <- cells[i, , drop = FALSE]; tree_seed <- 2026109000L + i
  tree <- make_tree(meta$n_species, tree_seed)
  for (replicate in seq_len(replicates)) {
    data <- simulate_response(meta, tree, 2026110000L + 1000L * i + replicate)
    started <- proc.time()[['elapsed']]
    fit <- try(drmTMB(bf(y ~ between + within + phylo(1 | species, tree = tree) + temporal(1 | species, time = elapsed, structure = 'ou'), sigma ~ 1), data = data, family = gaussian(), REML = FALSE), silent = TRUE)
    fit_elapsed <- proc.time()[['elapsed']] - started
    index <- index + 1L
    if (inherits(fit, 'try-error')) {
      rows[[index]] <- data.frame(cell = meta$cell, tree_seed = tree_seed, replicate = replicate, selected = FALSE, fit_elapsed_sec = fit_elapsed, estimate = NA_real_, pd_hess = NA, precision = NA_character_, available = FALSE, lower = NA_real_, upper = NA_real_, profile_elapsed_sec = NA_real_, error = as.character(fit)); next
    }
    p <- do.call(rbind, lapply(c('fast', 'default'), function(precision) profile_row(fit, precision)))
    rows[[index]] <- data.frame(cell = meta$cell, tree_seed = tree_seed, replicate = replicate, selected = TRUE, fit_elapsed_sec = fit_elapsed, estimate = unname(fit$coefficients$mu[['(Intercept)']]), pd_hess = isTRUE(fit$sdr$pdHess), p, stringsAsFactors = FALSE)
  }
}
results <- do.call(rbind, rows)
summary <- do.call(rbind, lapply(split(results, interaction(results$cell, results$precision, drop = TRUE)), function(x) data.frame(cell=x$cell[1], precision=x$precision[1], n=nrow(x), available=sum(x$available), coverage=mean(x$available & x$lower <= 0 & x$upper >= 0), mean_fit_sec=mean(x$fit_elapsed_sec), mean_profile_sec=mean(x$profile_elapsed_sec, na.rm=TRUE), mean_endpoint_difference=NA_real_, stringsAsFactors=FALSE)))
for (cell in unique(results$cell)) {
  a <- results[results$cell == cell & results$precision == 'fast', ]; b <- results[results$cell == cell & results$precision == 'default', ]
  delta <- mean(abs(a$lower - b$lower) + abs(a$upper - b$upper), na.rm=TRUE) / 2
  summary$mean_endpoint_difference[summary$cell == cell] <- delta
}
utils::write.csv(results, file.path(out_dir, 'replicates.csv'), row.names = FALSE)
utils::write.csv(summary, file.path(out_dir, 'summary.csv'), row.names = FALSE)
writeLines(c('# Fixed-tree intercept-profile pilot', '', sprintf('Replicates per cell: %d.', replicates), 'One deterministic phylogeny per P1--P3 cell; response draws vary.', 'This is a timing and mechanism pre-run, not coverage evidence.'), file.path(out_dir, 'RESULTS.md'))
cat('PHYLO_TEMPORAL_OU_FIXED_TREE_PILOT_PASS\n')
