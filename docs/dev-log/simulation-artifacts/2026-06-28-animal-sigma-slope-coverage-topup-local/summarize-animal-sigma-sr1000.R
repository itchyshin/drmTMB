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

count_interval <- function(fit_ok, interval_rows, contains_col, lower_col, upper_col, truth_sd) {
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

summarize_endpoint <- function(endpoint_member, target_token, truth_sd) {
  is_intercept <- identical(endpoint_member, "sigma:(Intercept)")
  source_sr475 <- if (is_intercept) {
    file.path(
      "docs/dev-log/simulation-artifacts/2026-06-27-sigma-slope-coverage-grid-local",
      "05-animal-sigma_intercept-replicates.tsv"
    )
  } else {
    file.path(
      "docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/results/shard_8",
      "08-animal-sigma_x-replicates.tsv"
    )
  }
  source_topup <- if (is_intercept) {
    file.path(
      "docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/results/shard_5",
      "05-animal-sigma_intercept-replicates.tsv"
    )
  } else {
    file.path(
      "docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/results/shard_8",
      "08-animal-sigma_x-replicates.tsv"
    )
  }
  rows <- if (is_intercept) {
    rbind(read_tsv(source_sr475), read_tsv(source_topup))
  } else {
    read_tsv(source_sr475)
  }
  fit_ok <- rows[rows$attempt_status == "fit_ok", , drop = FALSE]

  wald <- fit_ok[finite_interval(fit_ok, "wald_lower", "wald_upper"), , drop = FALSE]
  profile <- fit_ok[finite_interval(fit_ok, "profile_lower", "profile_upper"), , drop = FALSE]
  wald_counts <- count_interval(
    fit_ok, wald, "wald_contains", "wald_lower", "wald_upper", truth_sd
  )
  profile_counts <- count_interval(
    fit_ok, profile, "profile_contains", "profile_lower", "profile_upper", truth_sd
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
    evidence_id = paste0("animal_sigma_sr1000_", if (is_intercept) "intercept" else "x"),
    linked_cell_id = "qseries_animal_q1_sigma_one_slope",
    provider = "animal",
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
      "Animal q1 sigma one-slope SR1000 retained-denominator evidence;",
      "raw Wald-z sigma channel measured for both endpoints;",
      "profile channel is not reliable unless profile finite rates are >=0.95;",
      "no inference_ready promotion;",
      "no pedigree/Ainv bridge, matched mu+sigma, q4/q8, REML, AI-REML,",
      "supported, bridge, or public support claim."
    ),
    stringsAsFactors = FALSE
  )
}

out_dir <- "docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local"
summary <- rbind(
  summarize_endpoint("sigma:(Intercept)", "sigma_intercept", 0.5),
  summarize_endpoint("sigma:x", "sigma_x", 0.38)
)
utils::write.table(
  summary,
  file.path(out_dir, "animal-sigma-sr1000-combined-summary.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
