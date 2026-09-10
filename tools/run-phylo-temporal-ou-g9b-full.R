#!/usr/bin/env Rscript
# Approved full G9b recovery study.  This is a new retained evidence stream and
# deliberately does not reinterpret the failed original G9 recovery gate.
if (length(commandArgs(trailingOnly = TRUE))) stop('This runner takes no arguments.', call. = FALSE)
script_arg <- grep('^--file=', commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop('Run this script through Rscript.', call. = FALSE)
script_path <- normalizePath(sub('^--file=', '', script_arg))
root <- normalizePath('.', mustWork = TRUE)
if (!file.exists(file.path(root, 'DESCRIPTION'))) stop('Run from the drmTMB root.', call. = FALSE)
pkgload::load_all(root, quiet = TRUE)

out_dir <- Sys.getenv('DRMTMB_PHYLO_TEMPORAL_OU_G9B_FULL_OUT', unset = file.path(
  root, 'docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g9b-full-v4'
))
required <- c(
  'manifest.csv', 'contrast-estimates.csv', 'contrast-attempts.csv', 'contrast-summary.csv',
  'ensemble-estimates.csv', 'ensemble-attempts.csv', 'ensemble-summary.csv', 'criteria.csv',
  'provenance.csv', 'g9b-full-results.rds', 'session-info.txt', 'RESULTS.md'
)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
if (any(file.exists(file.path(out_dir, required)))) {
  stop('G9b full-study evidence already exists; do not overwrite it.', call. = FALSE)
}

truth <- c(intercept = 0, between = 0.5, within = 0.5,
           sd_temporal = 0.8, sigma = 0.4)

make_times <- function(n_species, layout) {
  if (identical(layout, 'balanced')) return(rep(list(c(0, 1, 3, 5, 9, 12)), n_species))
  lapply(seq_len(n_species), function(i) {
    switch(as.character((i - 1L) %% 3L + 1L),
           '1' = c(0, 0.5, 2, 6, 11),
           '2' = c(0, 1, 4, 7),
           '3' = c(0, 2, 3, 8, 12, 15))
  })
}

within_values <- function(schedules) {
  unlist(lapply(schedules, function(time) {
    value <- sample(rep(c(-0.5, 0.5), length.out = length(time)))
    value - mean(value)
  }), use.names = FALSE)
}

simulate_fixture <- function(seed, sd_phylo, decay, layout, n_species = 50L) {
  set.seed(seed)
  tree <- ape::rcoal(n_species)
  tree$tip.label <- sprintf('sp_%03d', seq_len(n_species))
  schedules <- make_times(n_species, layout)
  data <- do.call(rbind, Map(function(species, elapsed) {
    data.frame(species = species, elapsed = elapsed)
  }, tree$tip.label, schedules))
  data$species <- factor(data$species, levels = tree$tip.label)
  between <- sample(rep(c(-0.5, 0.5), each = n_species / 2L))
  data$between <- rep(between, lengths(schedules))
  data$within <- within_values(schedules)
  A <- ape::vcv(tree, corr = TRUE)[tree$tip.label, tree$tip.label, drop = FALSE]
  stable <- drop(t(chol(A)) %*% stats::rnorm(n_species, sd = sd_phylo))
  names(stable) <- tree$tip.label
  temporal <- unlist(lapply(schedules, function(time) {
    R <- exp(-decay * abs(outer(time, time, '-')))
    drop(t(chol(R)) %*% stats::rnorm(length(time), sd = truth[['sd_temporal']]))
  }), use.names = FALSE)
  data$y <- truth[['intercept']] + truth[['between']] * data$between +
    truth[['within']] * data$within + stable[as.character(data$species)] + temporal +
    stats::rnorm(nrow(data), sd = truth[['sigma']])
  list(data = data[sample.int(nrow(data)), , drop = FALSE], tree = tree)
}

fit_fixture <- function(generated) {
  started <- proc.time()[['elapsed']]
  answer <- tryCatch({
    fit <- drmTMB(
      bf(y ~ between + within + phylo(1 | species, tree = generated$tree) +
           temporal(1 | species, time = elapsed, structure = 'ou'), sigma ~ 1),
      data = generated$data, family = gaussian(), REML = FALSE
    )
    list(fit = fit, error = NA_character_)
  }, error = function(e) list(fit = NULL, error = conditionMessage(e)))
  answer$elapsed_sec <- proc.time()[['elapsed']] - started
  answer
}

extract_fit <- function(result, meta) {
  base <- cbind(meta, elapsed_sec = result$elapsed_sec, stringsAsFactors = FALSE)
  if (is.null(result$fit)) {
    selected <- transform(base, selected = FALSE, objective = NA_real_, error = result$error,
                          beta_intercept = NA_real_, beta_between = NA_real_, beta_within = NA_real_,
                          sd_phylo = NA_real_, sd_temporal = NA_real_, sigma = NA_real_, decay = NA_real_)
    attempts <- data.frame(id = meta$id, start = NA_character_, decay_start = NA_real_,
                           status = 'error', convergence = NA_integer_, objective = NA_real_,
                           elapsed_sec = result$elapsed_sec, selected = FALSE, error = result$error)
    return(list(selected = selected, attempts = attempts))
  }
  fit <- result$fit
  temporal <- fit$model$structured$temporal_mu
  phylo <- fit$model$structured$phylo_mu
  phylo_label <- phylo_mu_sd_labels(phylo, fit$model$model_type)
  selected <- transform(base, selected = TRUE, objective = -as.numeric(stats::logLik(fit)), error = NA_character_,
    beta_intercept = unname(fit$coefficients$mu[['(Intercept)']]),
    beta_between = unname(fit$coefficients$mu[['between']]),
    beta_within = unname(fit$coefficients$mu[['within']]),
    sd_phylo = unname(fit$sdpars$mu[[phylo_label]]),
    sd_temporal = unname(fit$sdpars$mu[[temporal_mu_sd_label(temporal)]]),
    sigma = exp(unname(fit$coefficients$sigma[['(Intercept)']])),
    decay = unname(fit$decaypars$temporal[[temporal_mu_decay_label(temporal)]])
  )
  attempts <- fit$temporal_start_attempts
  attempts$id <- meta$id
  attempts$error <- NA_character_
  attempts <- attempts[, c('id', 'start', 'decay_start', 'status', 'convergence',
                           'objective', 'elapsed_sec', 'selected', 'error')]
  list(selected = selected, attempts = attempts)
}

conditions <- expand.grid(sd_phylo_truth = c(0.3, 0.6, 1.0), decay_truth = c(0.15, 0.4, 0.7),
                          KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
conditions <- rbind(conditions, data.frame(sd_phylo_truth = c(0.3, 0.6, 1.0),
                                            decay_truth = c(0.7, 0.4, 0.15)))
conditions$condition <- sprintf('C%02d', seq_len(nrow(conditions)))
contrast_manifest <- do.call(rbind, lapply(c('balanced', 'unbalanced'), function(layout) {
  ans <- conditions
  ans$id <- paste(layout, ans$condition, sep = '_')
  ans$stream <- 'contrast'
  ans$layout <- layout
  ans$seed <- 2026091500L + seq_len(nrow(ans)) + if (identical(layout, 'unbalanced')) 100L else 0L
  ans$replicate <- NA_integer_
  ans[, c('stream', 'id', 'condition', 'layout', 'replicate', 'seed', 'sd_phylo_truth', 'decay_truth')]
}))
ensemble_manifest <- do.call(rbind, lapply(c(0.3, 0.6, 1.0), function(sd_phylo) {
  replicate <- seq_len(100L)
  data.frame(stream = 'ensemble', id = sprintf('E_sd%s_%03d', format(sd_phylo, trim = TRUE), replicate),
             condition = sprintf('sd_phylo_%s', format(sd_phylo, trim = TRUE)),
             layout = ifelse(replicate %% 2L, 'balanced', 'unbalanced'), replicate = replicate,
             seed = as.integer(2026092000L + match(sd_phylo, c(0.3, 0.6, 1.0)) * 1000L + replicate),
             sd_phylo_truth = sd_phylo,
             decay_truth = rep(c(0.15, 0.4, 0.7), length.out = 100L),
             stringsAsFactors = FALSE)
}))
manifest <- rbind(contrast_manifest, ensemble_manifest)
utils::write.csv(manifest, file.path(out_dir, 'manifest.csv'), row.names = FALSE)

run_manifest <- function(manifest) {
  rows <- lapply(seq_len(nrow(manifest)), function(i) {
    meta <- manifest[i, , drop = FALSE]
    generated <- simulate_fixture(meta$seed, meta$sd_phylo_truth, meta$decay_truth, meta$layout)
    extract_fit(fit_fixture(generated), meta)
  })
  list(selected = do.call(rbind, lapply(rows, `[[`, 'selected')),
       attempts = do.call(rbind, lapply(rows, `[[`, 'attempts')))
}

contrast <- run_manifest(contrast_manifest)
ensemble <- run_manifest(ensemble_manifest)
contrast_selected <- contrast$selected
ensemble_selected <- ensemble$selected
finite_contrast <- contrast_selected$selected & is.finite(contrast_selected$objective)
finite_ensemble <- ensemble_selected$selected & is.finite(ensemble_selected$objective)

contrast_summary <- do.call(rbind, lapply(split(contrast_selected[finite_contrast, , drop = FALSE],
                                                list(contrast_selected$layout[finite_contrast], contrast_selected$sd_phylo_truth[finite_contrast]),
                                                drop = TRUE), function(z) {
  data.frame(layout = z$layout[[1L]], sd_phylo_truth = z$sd_phylo_truth[[1L]], n = nrow(z),
             signed_between_error = mean(z$beta_between - truth[['between']]),
             mae_between = mean(abs(z$beta_between - truth[['between']])),
             signed_within_error = mean(z$beta_within - truth[['within']]),
             mae_within = mean(abs(z$beta_within - truth[['within']])))
}))
ensemble_summary <- do.call(rbind, lapply(split(ensemble_selected[finite_ensemble, , drop = FALSE],
                                                ensemble_selected$sd_phylo_truth[finite_ensemble]), function(z) {
  error <- z$beta_intercept - truth[['intercept']]
  data.frame(sd_phylo_truth = z$sd_phylo_truth[[1L]], n_finite = nrow(z),
             signed_bias = mean(error), empirical_sd = stats::sd(error), mae = mean(abs(error)),
             median_absolute_error = stats::median(abs(error)),
             standardized_signed_bias = abs(mean(error)) / stats::sd(error),
             convergence_ok = sum(is.finite(z$objective)),
             median_abs_log_sd_error = stats::median(c(abs(log(z$sd_phylo / z$sd_phylo_truth)),
                                                        abs(log(z$sd_temporal / truth[['sd_temporal']])),
                                                        abs(log(z$sigma / truth[['sigma']])))),
             median_abs_log_decay_error = stats::median(abs(log(z$decay / z$decay_truth))))
}))
if (is.null(contrast_summary)) contrast_summary <- data.frame(layout = character(), sd_phylo_truth = numeric(), n = integer(), signed_between_error = numeric(), mae_between = numeric(), signed_within_error = numeric(), mae_within = numeric())
if (is.null(ensemble_summary)) ensemble_summary <- data.frame(sd_phylo_truth = numeric(), n_finite = integer(), signed_bias = numeric(), empirical_sd = numeric(), mae = numeric(), median_absolute_error = numeric(), standardized_signed_bias = numeric(), convergence_ok = integer(), median_abs_log_sd_error = numeric(), median_abs_log_decay_error = numeric())

contrast_sd_error <- unlist(lapply(c('phylo', 'temporal', 'sigma'), function(name) {
  estimate <- contrast_selected[[paste0('sd_', name)]]
  expected <- switch(name, phylo = contrast_selected$sd_phylo_truth, temporal = truth[['sd_temporal']], sigma = truth[['sigma']])
  abs(log(estimate / expected))
}))
contrast_decay_error <- abs(log(contrast_selected$decay / contrast_selected$decay_truth))
finite_ensemble_counts <- table(factor(ensemble_selected$sd_phylo_truth[finite_ensemble], levels = c(0.3, 0.6, 1.0)))
ensemble_attempt_counts <- table(factor(ensemble$attempts$id, levels = ensemble_manifest$id))
standardized_bias <- setNames(rep(NA_real_, 3L), c('0.3', '0.6', '1'))
if (nrow(ensemble_summary) > 0L) standardized_bias[names(setNames(ensemble_summary$standardized_signed_bias, ensemble_summary$sd_phylo_truth))] <- ensemble_summary$standardized_signed_bias
criteria <- data.frame(
  criterion = c('G9b-A at least 22 finite selected fits',
                'G9b-A exactly 48 retained starts, two per fixture',
                'G9b-A between contrast MAE <= 0.15',
                'G9b-A within contrast MAE <= 0.15',
                'G9b-A median absolute log-SD error <= 0.25',
                'G9b-A median absolute log-decay error <= 0.35',
                'G9b-B 100 finite fits for sd_phylo 0.3',
                'G9b-B 100 finite fits for sd_phylo 0.6',
                'G9b-B 100 finite fits for sd_phylo 1.0',
                'G9b-B signed intercept bias / empirical SD <= 0.10 for sd_phylo 0.3',
                'G9b-B signed intercept bias / empirical SD <= 0.10 for sd_phylo 0.6',
                'G9b-B signed intercept bias / empirical SD <= 0.10 for sd_phylo 1.0'),
  observed = c(sum(finite_contrast), nrow(contrast$attempts),
               mean(abs(contrast_selected$beta_between - truth[['between']]), na.rm = TRUE),
               mean(abs(contrast_selected$beta_within - truth[['within']]), na.rm = TRUE),
               stats::median(contrast_sd_error, na.rm = TRUE), stats::median(contrast_decay_error, na.rm = TRUE),
               unname(finite_ensemble_counts), unname(standardized_bias[c('0.3', '0.6', '1')])),
  threshold = c('>= 22', '48 and exactly two per fixture', '<= 0.15', '<= 0.15', '<= 0.25', '<= 0.35',
                '100', '100', '100', '<= 0.10', '<= 0.10', '<= 0.10'),
  pass = c(sum(finite_contrast) >= 22L,
           nrow(contrast$attempts) == 48L && all(table(contrast$attempts$id) == 2L),
           is.finite(mean(abs(contrast_selected$beta_between - truth[['between']]), na.rm = TRUE)) && mean(abs(contrast_selected$beta_between - truth[['between']]), na.rm = TRUE) <= 0.15,
           is.finite(mean(abs(contrast_selected$beta_within - truth[['within']]), na.rm = TRUE)) && mean(abs(contrast_selected$beta_within - truth[['within']]), na.rm = TRUE) <= 0.15,
           is.finite(stats::median(contrast_sd_error, na.rm = TRUE)) && stats::median(contrast_sd_error, na.rm = TRUE) <= 0.25,
           is.finite(stats::median(contrast_decay_error, na.rm = TRUE)) && stats::median(contrast_decay_error, na.rm = TRUE) <= 0.35,
           unname(finite_ensemble_counts) == 100L,
           is.finite(unname(standardized_bias[c('0.3', '0.6', '1')])) & unname(standardized_bias[c('0.3', '0.6', '1')]) <= 0.10),
  stringsAsFactors = FALSE
)

provenance <- data.frame(
  key = c('source_commit', 'runner_md5', 'run_utc', 'contrast_fixtures', 'contrast_attempts',
          'ensemble_replicates', 'ensemble_attempts', 'n_species', 'command'),
  value = c(system2('git', c('rev-parse', 'HEAD'), stdout = TRUE),
            unname(tools::md5sum(script_path)), format(Sys.time(), tz = 'UTC', usetz = TRUE),
            nrow(contrast_selected), nrow(contrast$attempts), nrow(ensemble_selected), nrow(ensemble$attempts),
            50L, paste(commandArgs(), collapse = ' ')), stringsAsFactors = FALSE
)
utils::write.csv(contrast_selected, file.path(out_dir, 'contrast-estimates.csv'), row.names = FALSE)
utils::write.csv(contrast$attempts, file.path(out_dir, 'contrast-attempts.csv'), row.names = FALSE)
utils::write.csv(contrast_summary, file.path(out_dir, 'contrast-summary.csv'), row.names = FALSE)
utils::write.csv(ensemble_selected, file.path(out_dir, 'ensemble-estimates.csv'), row.names = FALSE)
utils::write.csv(ensemble$attempts, file.path(out_dir, 'ensemble-attempts.csv'), row.names = FALSE)
utils::write.csv(ensemble_summary, file.path(out_dir, 'ensemble-summary.csv'), row.names = FALSE)
utils::write.csv(criteria, file.path(out_dir, 'criteria.csv'), row.names = FALSE)
utils::write.csv(provenance, file.path(out_dir, 'provenance.csv'), row.names = FALSE)
saveRDS(list(truth = truth, manifest = manifest, contrast = contrast, ensemble = ensemble,
             contrast_summary = contrast_summary, ensemble_summary = ensemble_summary,
             criteria = criteria, provenance = provenance), file.path(out_dir, 'g9b-full-results.rds'))
capture.output(sessionInfo(), file = file.path(out_dir, 'session-info.txt'))
writeLines(c(
  '# G9b full recovery study', '',
  sprintf('Contrast stream: %d fixtures and %d retained starts.', nrow(contrast_selected), nrow(contrast$attempts)),
  sprintf('Ensemble stream: %d independent tree-and-response replicates and %d retained starts.', nrow(ensemble_selected), nrow(ensemble$attempts)),
  'The ensemble uses 100 independently generated trees per phylogenetic SD, alternating balanced and unbalanced established timing schedules.',
  '', 'This is point-recovery evidence only. It does not qualify interval coverage, forecasting, newdata prediction, or P2 Toeplitz.'
), file.path(out_dir, 'RESULTS.md'))
if (!all(criteria$pass)) stop('G9b full-study criteria failed; immutable artifacts were retained for diagnosis.', call. = FALSE)
cat('PHYLO_TEMPORAL_OU_G9B_FULL_PASS\n')
