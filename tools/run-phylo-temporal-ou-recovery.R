#!/usr/bin/env Rscript

# Retained deterministic point-recovery evidence for the paired stable
# phylogenetic intercept plus independent within-species OU model. This is not
# the later profile-calibration campaign.

if (length(commandArgs(trailingOnly = TRUE))) stop("This runner takes no arguments.", call. = FALSE)
root <- normalizePath('.', mustWork = TRUE)
if (!file.exists(file.path(root, 'DESCRIPTION'))) stop('Run from the drmTMB root.', call. = FALSE)
pkgload::load_all(root, quiet = TRUE)

out_dir <- Sys.getenv(
  'DRMTMB_PHYLO_TEMPORAL_OU_RECOVERY_OUT',
  unset = file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-09-phylo-temporal-ou-local-recovery-v6-high-information')
)
required <- c('raw-attempts.csv', 'recovery-estimates.csv', 'criteria.csv',
              'provenance.csv', 'recovery-results.rds', 'session-info.txt', 'RESULTS.md')
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
if (any(file.exists(file.path(out_dir, required)))) {
  stop('Retained recovery evidence already exists; do not overwrite it.', call. = FALSE)
}

truth <- c(`(Intercept)` = 0, between = 0.5, within = 0.5,
           sd_phylo = 0.6, sd_temporal = 0.8, sigma = 0.4)
n_species <- as.integer(Sys.getenv('DRMTMB_PHYLO_TEMPORAL_OU_RECOVERY_SPECIES', unset = '50'))
if (!is.finite(n_species) || n_species < 6L || n_species %% 2L) {
  stop('DRMTMB_PHYLO_TEMPORAL_OU_RECOVERY_SPECIES must be an even integer at least 6.', call. = FALSE)
}
conditions <- expand.grid(sd_phylo = c(0.3, 0.6, 1.0), decay = c(0.15, 0.4, 0.7),
                          KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
conditions <- rbind(
  conditions,
  data.frame(sd_phylo = c(0.3, 0.6, 1.0), decay = c(0.7, 0.4, 0.15))
)
conditions$condition <- sprintf('C%02d', seq_len(nrow(conditions)))
conditions$seed <- 2026091200L + seq_len(nrow(conditions))

make_times <- function(n_species, layout) {
  if (identical(layout, 'balanced')) return(rep(list(c(0, 1, 3, 5, 9, 12)), n_species))
  lapply(seq_len(n_species), function(i) {
    switch(as.character((i - 1L) %% 3L + 1L),
           '1' = c(0, 0.5, 2, 6, 11),
           '2' = c(0, 1, 4, 7),
           '3' = c(0, 2, 3, 8, 12, 15))
  })
}

simulate_fixture <- function(condition, layout) {
  set.seed(condition$seed + if (identical(layout, 'unbalanced')) 100L else 0L)
  tree <- ape::rcoal(n_species)
  tree$tip.label <- sprintf('sp_%03d', seq_len(n_species))
  schedules <- make_times(n_species, layout)
  data <- do.call(rbind, Map(function(species, elapsed) {
    data.frame(species = species, elapsed = elapsed)
  }, tree$tip.label, schedules))
  data$species <- factor(data$species, levels = tree$tip.label)
  between_species <- sample(rep(c(-0.5, 0.5), each = n_species / 2L))
  data$between <- rep(between_species, lengths(schedules))
  data$within <- unlist(
    lapply(schedules, function(time) {
      sample(rep(c(-0.5, 0.5), length.out = length(time)))
    }),
    use.names = FALSE
  )
  A <- ape::vcv(tree, corr = TRUE)[tree$tip.label, tree$tip.label, drop = FALSE]
  stable <- as.vector(t(chol(A)) %*% stats::rnorm(n_species, sd = condition$sd_phylo))
  names(stable) <- tree$tip.label
  temporal <- unlist(Map(function(time) {
    R <- exp(-condition$decay * abs(outer(time, time, '-')))
    as.vector(t(chol(R)) %*% stats::rnorm(length(time), sd = truth[['sd_temporal']]))
  }, schedules), use.names = FALSE)
  data$y <- truth[['(Intercept)']] + truth[['between']] * data$between +
    truth[['within']] * data$within + stable[as.character(data$species)] + temporal +
    stats::rnorm(nrow(data), sd = truth[['sigma']])
  list(data = data[sample.int(nrow(data)), , drop = FALSE], tree = tree)
}

safe_fit <- function(generated) {
  started <- proc.time()[['elapsed']]
  out <- tryCatch({
    tree <- generated$tree
    fit <- drmTMB(
      bf(y ~ between + within + phylo(1 | species, tree = tree) +
           temporal(1 | species, time = elapsed, structure = 'ou'), sigma ~ 1),
      data = generated$data, family = gaussian(), REML = FALSE
    )
    list(fit = fit, error = NA_character_)
  }, error = function(e) list(fit = NULL, error = conditionMessage(e)))
  out$elapsed_sec <- proc.time()[['elapsed']] - started
  out
}

extract_rows <- function(result, fixture, condition, layout) {
  base <- data.frame(fixture = fixture, condition = condition$condition, layout = layout,
                     seed = condition$seed, sd_phylo_truth = condition$sd_phylo,
                     sd_temporal_truth = truth[['sd_temporal']], sigma_truth = truth[['sigma']],
                     decay_truth = condition$decay, beta_intercept_truth = truth[['(Intercept)']],
                     beta_between_truth = truth[['between']], beta_within_truth = truth[['within']],
                     stringsAsFactors = FALSE)
  if (is.null(result$fit)) {
    selected <- transform(base, selected = FALSE, error = result$error, elapsed_sec = result$elapsed_sec,
                          objective = NA_real_, beta_intercept_estimate = NA_real_, beta_between_estimate = NA_real_,
                          beta_within_estimate = NA_real_, sd_phylo_estimate = NA_real_,
                          sd_temporal_estimate = NA_real_, sigma_estimate = NA_real_, decay_estimate = NA_real_)
    attempts <- transform(base, start = NA_character_, decay_start = NA_real_, status = 'error',
                          convergence = NA_integer_, objective = NA_real_, elapsed_sec = result$elapsed_sec,
                          selected = FALSE, error = result$error)
    return(list(selected = selected, attempts = attempts))
  }
  fit <- result$fit
  temporal <- fit$model$structured$temporal_mu
  phylo_label <- phylo_mu_sd_labels(fit$model$structured$phylo_mu, fit$model$model_type)
  selected <- transform(base, selected = TRUE, error = NA_character_, elapsed_sec = result$elapsed_sec,
    objective = -as.numeric(stats::logLik(fit)),
    beta_intercept_estimate = unname(fit$coefficients$mu[['(Intercept)']]),
    beta_between_estimate = unname(fit$coefficients$mu[['between']]),
    beta_within_estimate = unname(fit$coefficients$mu[['within']]),
    sd_phylo_estimate = unname(fit$sdpars$mu[[phylo_label]]),
    sd_temporal_estimate = unname(fit$sdpars$mu[[temporal_mu_sd_label(temporal)]]),
    sigma_estimate = exp(unname(fit$coefficients$sigma[['(Intercept)']])),
    decay_estimate = unname(fit$decaypars$temporal[[temporal$label]])
  )
  attempts <- fit$temporal_start_attempts
  attempts$fixture <- fixture
  attempts$condition <- condition$condition
  attempts$layout <- layout
  attempts$seed <- condition$seed
  attempts$error <- NA_character_
  attempts <- attempts[, c('fixture', 'condition', 'layout', 'seed', 'start', 'decay_start',
                            'status', 'convergence', 'objective', 'elapsed_sec', 'selected', 'error')]
  list(selected = selected, attempts = attempts)
}

out <- lapply(c('balanced', 'unbalanced'), function(layout) {
  lapply(seq_len(nrow(conditions)), function(i) {
    condition <- conditions[i, , drop = FALSE]
    extract_rows(safe_fit(simulate_fixture(condition, layout)),
                 paste(layout, condition$condition, sep = '_'), condition, layout)
  })
})
rows <- unlist(out, recursive = FALSE)
selected <- do.call(rbind, lapply(rows, `[[`, 'selected'))
attempts <- do.call(rbind, lapply(rows, `[[`, 'attempts'))
finite <- selected$selected & is.finite(selected$objective)
beta_error <- unlist(lapply(c('intercept', 'between', 'within'), function(name) {
  abs(selected[[paste0('beta_', name, '_estimate')]] - selected[[paste0('beta_', name, '_truth')]])
}))
sd_error <- unlist(lapply(c('phylo', 'temporal', 'sigma'), function(name) {
  abs(log(selected[[paste0('sd_', name, '_estimate')]] / selected[[paste0('sd_', name, '_truth')]]))
}))
decay_error <- abs(log(selected$decay_estimate / selected$decay_truth))
criteria <- data.frame(
  criterion = c('at least 22 finite selected fits', 'exactly 48 retained start attempts',
                'mean absolute fixed-effect error <= 0.15', 'median absolute log-SD error <= 0.25',
                'median absolute log-decay error <= 0.35'),
  observed = c(sum(finite), nrow(attempts), mean(beta_error, na.rm = TRUE),
               stats::median(sd_error, na.rm = TRUE), stats::median(decay_error, na.rm = TRUE)),
  threshold = c('>= 22', '48 and two per fixture', '<= 0.15', '<= 0.25', '<= 0.35'),
  pass = c(sum(finite) >= 22L,
           nrow(attempts) == 48L && all(table(attempts$fixture) == 2L) &&
             all(tapply(attempts$selected, attempts$fixture, sum) == 1L),
           is.finite(mean(beta_error, na.rm = TRUE)) && mean(beta_error, na.rm = TRUE) <= .15,
           is.finite(stats::median(sd_error, na.rm = TRUE)) && stats::median(sd_error, na.rm = TRUE) <= .25,
           is.finite(stats::median(decay_error, na.rm = TRUE)) && stats::median(decay_error, na.rm = TRUE) <= .35),
  stringsAsFactors = FALSE
)
provenance <- data.frame(key = c('source_commit', 'runner_md5', 'run_utc', 'n_species', 'n_fixtures', 'n_attempts'),
  value = c(system2('git', c('rev-parse', 'HEAD'), stdout = TRUE),
            unname(tools::md5sum(file.path(root, 'tools/run-phylo-temporal-ou-recovery.R'))),
            format(Sys.time(), tz = 'UTC', usetz = TRUE), n_species, nrow(selected), nrow(attempts)),
  stringsAsFactors = FALSE)
utils::write.csv(attempts, file.path(out_dir, 'raw-attempts.csv'), row.names = FALSE)
utils::write.csv(selected, file.path(out_dir, 'recovery-estimates.csv'), row.names = FALSE)
utils::write.csv(criteria, file.path(out_dir, 'criteria.csv'), row.names = FALSE)
utils::write.csv(provenance, file.path(out_dir, 'provenance.csv'), row.names = FALSE)
saveRDS(list(conditions = conditions, truth = truth, attempts = attempts, selected = selected,
             criteria = criteria, provenance = provenance), file.path(out_dir, 'recovery-results.rds'))
capture.output(sessionInfo(), file = file.path(out_dir, 'session-info.txt'))
writeLines(c('# Phylogenetic stable + independent OU point recovery', '',
             sprintf('Fixtures: %d; retained starts: %d.', nrow(selected), nrow(attempts)),
             sprintf('Finite selected fits: %d.', sum(finite)), '',
             'This is point-recovery evidence only. It does not qualify profile coverage or interval claims.'),
           file.path(out_dir, 'RESULTS.md'))
if (!all(criteria$pass)) stop('Phylogenetic-temporal OU recovery criteria failed; artifacts were retained for diagnosis.', call. = FALSE)
cat('PHYLO_TEMPORAL_OU_G9_RECOVERY_PASS\n')
