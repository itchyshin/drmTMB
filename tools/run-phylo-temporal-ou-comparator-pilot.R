#!/usr/bin/env Rscript
# Bounded paired-comparator pilot; does not qualify a temporal OU interval.
args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep('^--file=', commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop('Run with Rscript.', call. = FALSE)
root <- normalizePath(file.path(dirname(sub('^--file=', '', script_arg)), '..'), mustWork = TRUE)
arg_value <- function(prefix) {
  value <- grep(paste0('^', prefix), args, value = TRUE)
  if (length(value) != 1L) return(NULL)
  sub(prefix, '', value)
}
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
    value <- sample(rep(c(-.5, .5), length.out = length(time)))
    value - mean(value)
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
if (identical(args, '--self-test')) {
  stopifnot(identical(make_schedule('6_irregular', 1L)[[1L]], c(0, .5, 2, 4.5, 7, 11)))
  stopifnot(identical(c(0, .5, .5), c(0, .5, .5)))
  cat('PHYLO_TEMPORAL_OU_COMPARATOR_PILOT_SELFTEST_PASS\n')
  quit(save = 'no')
}
if (length(args) != 2L || any(!grepl('^--(replicates|output-dir)=', args))) {
  stop('Use --replicates=<positive integer> --output-dir=<new directory>, or --self-test.', call. = FALSE)
}
replicates <- suppressWarnings(as.integer(arg_value('--replicates=')))
out_dir <- arg_value('--output-dir=')
if (length(replicates) != 1L || is.na(replicates) || replicates < 1L || !nzchar(out_dir) || file.exists(out_dir)) {
  stop('Replicates must be positive and output directory must be new.', call. = FALSE)
}
if (!requireNamespace('glmmTMB', quietly = TRUE)) stop('glmmTMB is required for the comparator pilot.', call. = FALSE)
Sys.setenv(OMP_NUM_THREADS = '1', OPENBLAS_NUM_THREADS = '1')
pkgload::load_all(root, quiet = TRUE)
source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))
manifest <- phylo_temporal_ou_g11_manifest()
cells <- manifest[match(c('P1', 'P2', 'P3'), manifest$cell), , drop = FALSE]
profile_drm <- function(fit) {
  out <- stats::confint(fit, parm = 'fixef:mu:(Intercept)', method = 'profile', level = .95, profile_engine = 'tmbprofile', profile_precision = 'fast', trace = FALSE)
  list(estimate = unname(fit$coefficients$mu[['(Intercept)']]), lower = out$lower, upper = out$upper)
}
profile_glmm <- function(fit) {
  out <- stats::confint(fit, parm = 1L, component = 'cond', method = 'profile', level = .95, ncpus = 1L)
  list(estimate = unname(glmmTMB::fixef(fit)$cond[['(Intercept)']]), lower = out[1L, 1L], upper = out[1L, 2L])
}
fit_engine <- function(engine, data, tree) {
  started <- proc.time()[['elapsed']]
  answer <- try({
    if (identical(engine, 'drmTMB')) {
      fit <- drmTMB::drmTMB(bf(y ~ between + within + phylo(1 | species, tree = tree) + temporal(1 | species, time = elapsed, structure = 'ou'), sigma ~ 1), data = data, family = gaussian(), REML = FALSE)
      profile <- profile_drm(fit)
      pd_hess <- isTRUE(fit$sdr$pdHess)
    } else {
      data$dummy <- factor(1)
      data$time_factor <- glmmTMB::numFactor(data$elapsed)
      A <- ape::vcv(tree, corr = TRUE)[tree$tip.label, tree$tip.label, drop = FALSE]
      fit <- glmmTMB::glmmTMB(y ~ between + within + propto(0 + species | dummy, A) + ou(time_factor + 0 | species), data = data, family = gaussian(), REML = FALSE)
      profile <- profile_glmm(fit)
      pd_hess <- isTRUE(fit$sdr$pdHess)
    }
    data.frame(engine = engine, selected = TRUE, pd_hess = pd_hess, estimate = profile$estimate, lower = profile$lower, upper = profile$upper, elapsed_sec = proc.time()[['elapsed']] - started, error = NA_character_)
  }, silent = TRUE)
  if (inherits(answer, 'try-error')) data.frame(engine = engine, selected = FALSE, pd_hess = NA, estimate = NA_real_, lower = NA_real_, upper = NA_real_, elapsed_sec = proc.time()[['elapsed']] - started, error = as.character(answer)) else answer
}
dir.create(out_dir, recursive = TRUE)
rows <- list(); index <- 0L
for (i in seq_len(nrow(cells))) {
  meta <- cells[i, , drop = FALSE]
  tree <- make_tree(meta$n_species, 2026109000L + i)
  for (replicate in seq_len(replicates)) {
    data <- simulate_response(meta, tree, 2026110000L + 1000L * i + replicate)
    for (engine in c('drmTMB', 'glmmTMB')) {
      index <- index + 1L
      rows[[index]] <- cbind(data.frame(cell = meta$cell, replicate = replicate, tree_seed = 2026109000L + i), fit_engine(engine, data, tree))
    }
  }
}
results <- do.call(rbind, rows)
results$covers <- results$selected & results$lower <= 0 & results$upper >= 0
summary <- do.call(rbind, lapply(split(results, interaction(results$cell, results$engine, drop = TRUE)), function(x) data.frame(cell = x$cell[[1L]], engine = x$engine[[1L]], n = nrow(x), n_selected = sum(x$selected), n_pd_hess = sum(x$pd_hess %in% TRUE), n_profile = sum(is.finite(x$lower) & is.finite(x$upper)), coverage = mean(x$covers), mean_elapsed_sec = mean(x$elapsed_sec), stringsAsFactors = FALSE)))
utils::write.csv(results, file.path(out_dir, 'replicates.csv'), row.names = FALSE)
utils::write.csv(summary, file.path(out_dir, 'summary.csv'), row.names = FALSE)
writeLines(c('# Paired phylogenetic-OU comparator pilot', '', sprintf('Replicates per cell: %d.', replicates), 'Each row regenerates one frozen G11 P1--P3 dataset and compares profile intervals from drmTMB and glmmTMB.', 'This pre-run measures feasibility and pairwise behaviour only; it does not qualify coverage or change G13.'), file.path(out_dir, 'RESULTS.md'))
cat('PHYLO_TEMPORAL_OU_COMPARATOR_PILOT_PASS\n')
