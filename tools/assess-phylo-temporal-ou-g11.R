# Pure contract and assessment helpers for the phylogenetic-temporal OU profile
# calibration campaign. These functions do not fit models or submit compute.

phylo_temporal_ou_g11_cells <- function() {
  data.frame(
    cell = c('P1', 'P2', 'P3', 'P4'),
    n_attempted = c(1000L, 1000L, 1000L, 500L),
    n_species = c(80L, 80L, 80L, 20L),
    occasions = c('6_irregular', '12_irregular', '4_to_12_irregular', '6_irregular'),
    sd_phylo = c(0.6, 1.0, 0.6, 1.0),
    sd_temporal = c(0.8, 0.8, 0.8, 0.8),
    sigma = c(0.4, 0.4, 0.4, 0.4),
    decay = c(0.40, 0.15, 0.70, 0.15),
    role = c('primary_short_series', 'primary_persistent_signal', 'primary_unbalanced', 'stress'),
    stringsAsFactors = FALSE
  )
}

phylo_temporal_ou_g11_manifest <- function() {
  cells <- phylo_temporal_ou_g11_cells()
  seeds <- c(P1 = 2026101000L, P2 = 2026103000L, P3 = 2026105000L, P4 = 2026107000L)
  rows <- lapply(seq_len(nrow(cells)), function(i) {
    cell <- cells[i, , drop = FALSE]
    data.frame(
      cell = cell$cell,
      replicate = seq_len(cell$n_attempted),
      seed = as.integer(seeds[[cell$cell]] + seq_len(cell$n_attempted)),
      n_species = cell$n_species,
      occasions = cell$occasions,
      sd_phylo = cell$sd_phylo,
      sd_temporal = cell$sd_temporal,
      sigma = cell$sigma,
      decay = cell$decay,
      role = cell$role,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out$task_id <- seq_len(nrow(out))
  out[, c('task_id', 'cell', 'replicate', 'seed', 'n_species', 'occasions',
          'sd_phylo', 'sd_temporal', 'sigma', 'decay', 'role')]
}

phylo_temporal_ou_g11_targets <- function() {
  out <- expand.grid(
    cell = c('P1', 'P2', 'P3', 'P4'),
    parm = paste0('fixef:mu:', c('(Intercept)', 'between', 'within')),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  out$primary <- out$cell %in% c('P1', 'P2', 'P3')
  out$truth <- rep(c(0, 0.5, 0.5), times = 4L)
  out <- out[order(out$cell, out$parm), , drop = FALSE]
  row.names(out) <- NULL
  out
}

phylo_temporal_ou_g11_validate_manifest <- function(manifest) {
  required <- c('task_id', 'cell', 'replicate', 'seed', 'n_species', 'occasions',
                'sd_phylo', 'sd_temporal', 'sigma', 'decay', 'role')
  if (!is.data.frame(manifest) || !all(required %in% names(manifest))) {
    stop('G11 manifest lacks required fields.', call. = FALSE)
  }
  expected <- phylo_temporal_ou_g11_manifest()
  if (!identical(manifest[, required], expected[, required])) {
    stop('G11 manifest does not match the frozen P1--P4 denominator.', call. = FALSE)
  }
  invisible(TRUE)
}

phylo_temporal_ou_g11_validate_provenance <- function(summary) {
  required <- c('source_commit', 'worker_md5')
  if (!all(required %in% names(summary)) ||
      any(!grepl('^[0-9a-f]{40}$', summary$source_commit)) ||
      any(!grepl('^[0-9a-f]{32}$', summary$worker_md5)) ||
      length(unique(summary$source_commit)) != 1L || length(unique(summary$worker_md5)) != 1L) {
    stop('Campaign provenance is malformed or forged.', call. = FALSE)
  }
  invisible(TRUE)
}

phylo_temporal_ou_g11_assess <- function(summary, level = 0.95) {
  required <- c(
    'cell', 'parm', 'n_attempted', 'n_available', 'availability', 'coverage_all',
    'coverage_conditional', 'coverage_mcse', 'lower_tail_all', 'upper_tail_all',
    'lower_tail_conditional', 'upper_tail_conditional', 'bias', 'empirical_sd',
    'mean_interval_width', 'source_commit', 'worker_md5'
  )
  if (!is.data.frame(summary) || !all(required %in% names(summary))) {
    stop('Campaign summary lacks fields required for G11 assessment.', call. = FALSE)
  }
  if (!is.numeric(level) || length(level) != 1L || !is.finite(level) || level <= 0 || level >= 1) {
    stop('`level` must be one finite number strictly between zero and one.', call. = FALSE)
  }
  targets <- phylo_temporal_ou_g11_targets()
  key <- paste(summary$cell, summary$parm)
  expected_key <- paste(targets$cell, targets$parm)
  if (nrow(summary) != nrow(targets) || anyDuplicated(key) || !setequal(key, expected_key)) {
    stop('Campaign summary has an incomplete cell-coefficient denominator.', call. = FALSE)
  }
  summary <- summary[match(expected_key, key), , drop = FALSE]
  if (!identical(as.integer(summary$n_attempted), as.integer(ifelse(targets$cell == 'P4', 500L, 1000L)))) {
    stop('Campaign summary has an incomplete all-attempt denominator.', call. = FALSE)
  }
  phylo_temporal_ou_g11_validate_provenance(summary)

  z <- stats::qnorm((1 + level) / 2)
  out <- summary
  out$primary <- targets$primary
  out$coverage_lower_mcse <- out$coverage_all - out$coverage_mcse
  out$coverage_upper_mcse <- out$coverage_all + out$coverage_mcse
  out$mean_profile_se_analogue <- out$mean_interval_width / (2 * z)
  out$profile_se_analogue_ratio <- out$mean_profile_se_analogue / out$empirical_sd
  finite <- function(...) Reduce(`&`, lapply(list(...), is.finite))
  out$criterion_availability <- finite(out$availability) & out$availability >= 0.99
  out$criterion_coverage <- finite(out$coverage_lower_mcse, out$coverage_upper_mcse) &
    out$coverage_lower_mcse >= 0.925 & out$coverage_upper_mcse <= 0.975
  out$criterion_bias <- finite(out$bias, out$empirical_sd) & abs(out$bias) <= 0.10 * out$empirical_sd
  out$criterion_profile_se <- finite(out$profile_se_analogue_ratio) &
    out$profile_se_analogue_ratio >= 0.90 & out$profile_se_analogue_ratio <= 1.10
  out$qualification <- ifelse(
    !out$primary, 'stress_report_only',
    ifelse(out$criterion_availability & out$criterion_coverage & out$criterion_bias & out$criterion_profile_se,
           'qualified_in_simulated_cell', 'unqualified_in_simulated_cell')
  )
  out
}
