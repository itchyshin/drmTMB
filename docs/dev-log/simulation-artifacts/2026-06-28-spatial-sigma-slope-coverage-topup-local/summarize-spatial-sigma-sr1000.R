read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

cover_bool <- function(x) {
  toupper(as.character(x)) == "TRUE"
}

finite_interval <- function(rows, lower, upper) {
  !is.na(rows[[lower]]) &
    !is.na(rows[[upper]]) &
    is.finite(rows[[lower]]) &
    is.finite(rows[[upper]])
}

summarize_endpoint <- function(endpoint_member, target_token, truth_sd) {
  source_sr475 <- file.path(
    "docs/dev-log/simulation-artifacts/2026-06-27-sigma-slope-coverage-grid-local",
    sprintf("%s-spatial-%s-replicates.tsv",
      if (identical(endpoint_member, "sigma:(Intercept)")) "03" else "04",
      target_token
    )
  )
  source_topup <- file.path(
    "docs/dev-log/simulation-artifacts/2026-06-28-spatial-sigma-slope-coverage-topup-local/results",
    if (identical(endpoint_member, "sigma:(Intercept)")) "shard_3" else "shard_4",
    sprintf("%s-spatial-%s-replicates.tsv",
      if (identical(endpoint_member, "sigma:(Intercept)")) "03" else "04",
      target_token
    )
  )
  rows <- rbind(read_tsv(source_sr475), read_tsv(source_topup))
  fit_ok <- rows[rows$attempt_status == "fit_ok", , drop = FALSE]

  wald <- fit_ok[finite_interval(fit_ok, "wald_lower", "wald_upper"), , drop = FALSE]
  profile <- fit_ok[finite_interval(fit_ok, "profile_lower", "profile_upper"), , drop = FALSE]

  count_interval <- function(interval_rows, contains_col, lower_col, upper_col) {
    n_finite <- nrow(interval_rows)
    n_covered <- sum(cover_bool(interval_rows[[contains_col]]), na.rm = TRUE)
    coverage <- if (n_finite > 0L) n_covered / n_finite else NA_real_
    mcse <- if (!is.na(coverage) && n_finite > 0L) {
      sqrt(coverage * (1 - coverage) / n_finite)
    } else {
      NA_real_
    }
    lower_miss <- sum(interval_rows[[upper_col]] < truth_sd, na.rm = TRUE)
    upper_miss <- sum(interval_rows[[lower_col]] > truth_sd, na.rm = TRUE)
    data.frame(
      n_finite = n_finite,
      finite_rate = n_finite / nrow(fit_ok),
      n_covered = n_covered,
      coverage = coverage,
      mcse = mcse,
      lower_miss = lower_miss,
      upper_miss = upper_miss,
      upper_lower_miss_ratio = upper_miss / max(lower_miss, 1L)
    )
  }

  wald_counts <- count_interval(wald, "wald_contains", "wald_lower", "wald_upper")
  profile_counts <- count_interval(
    profile,
    "profile_contains",
    "profile_lower",
    "profile_upper"
  )

  finite_rate_gate <- if (wald_counts$finite_rate >= 0.95) {
    "pass"
  } else {
    "fail"
  }
  mcse_gate <- if (!is.na(wald_counts$mcse) && wald_counts$mcse <= 0.01) {
    "pass"
  } else {
    "fail"
  }

  data.frame(
    evidence_id = paste0(
      "spatial_sigma_sr1000_",
      if (identical(endpoint_member, "sigma:(Intercept)")) "intercept" else "x"
    ),
    linked_cell_id = "qseries_spatial_q1_sigma_one_slope",
    provider = "spatial",
    endpoint_member = endpoint_member,
    target_parm = unique(fit_ok$target_parm)[[1L]],
    source_sr475_replicates = source_sr475,
    source_topup_replicates = source_topup,
    seed_start = min(rows$seed, na.rm = TRUE),
    seed_end = max(rows$seed, na.rm = TRUE),
    planned_reps = 1000L,
    n_fit_ok = nrow(fit_ok),
    n_fit_error = sum(rows$attempt_status == "fit_error", na.rm = TRUE),
    n_converged = sum(fit_ok$convergence == 0L, na.rm = TRUE),
    n_pdhess = sum(cover_bool(fit_ok$pdHess), na.rm = TRUE),
    n_boundary = sum(cover_bool(fit_ok$is_boundary), na.rm = TRUE),
    n_wald_finite = wald_counts$n_finite,
    wald_finite_rate = round(wald_counts$finite_rate, 4L),
    n_wald_covered = wald_counts$n_covered,
    wald_coverage = round(wald_counts$coverage, 4L),
    wald_mcse = round(wald_counts$mcse, 4L),
    wald_lower_miss = wald_counts$lower_miss,
    wald_upper_miss = wald_counts$upper_miss,
    wald_upper_lower_miss_ratio = round(wald_counts$upper_lower_miss_ratio, 4L),
    n_profile_finite = profile_counts$n_finite,
    profile_finite_rate = round(profile_counts$finite_rate, 4L),
    n_profile_covered = profile_counts$n_covered,
    profile_coverage = round(profile_counts$coverage, 4L),
    profile_mcse = round(profile_counts$mcse, 4L),
    profile_lower_miss = profile_counts$lower_miss,
    profile_upper_miss = profile_counts$upper_miss,
    profile_upper_lower_miss_ratio = round(profile_counts$upper_lower_miss_ratio, 4L),
    mean_est_sd = round(mean(fit_ok$estimate_sd, na.rm = TRUE), 4L),
    bias_mean_est = round(mean(fit_ok$estimate_sd, na.rm = TRUE) - truth_sd, 4L),
    finite_rate_gate = finite_rate_gate,
    mcse_gate = mcse_gate,
    promotion_status = if (finite_rate_gate == "pass" && mcse_gate == "pass") {
      "candidate_not_promoted"
    } else {
      "blocked_not_promoted"
    },
    claim_boundary = paste(
      "Spatial q1 sigma one-slope SR1000 retained-denominator evidence;",
      "raw Wald-z sigma channel only;",
      "no inference_ready promotion unless both endpoint finite-Wald rates are >=0.95;",
      "no range-estimating spatial, profile-channel reliability, matched mu+sigma,",
      "q4/q8, REML, AI-REML, supported, bridge, or public support claim."
    ),
    stringsAsFactors = FALSE
  )
}

out_dir <- "docs/dev-log/simulation-artifacts/2026-06-28-spatial-sigma-slope-coverage-topup-local"
summary <- rbind(
  summarize_endpoint("sigma:(Intercept)", "sigma_intercept", 0.5),
  summarize_endpoint("sigma:x", "sigma_x", 0.38)
)
utils::write.table(
  summary,
  file.path(out_dir, "spatial-sigma-sr1000-combined-summary.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
