#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args
sync_dashboard <- "--sync-dashboard=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")
out_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-sigma-profile-route-review.tsv"
)

if (file.exists(out_path) && !overwrite) {
  stop("Output exists; pass --overwrite=true to replace it.", call. = FALSE)
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = ""
  )
}

truthy <- function(x) {
  if (is.logical(x)) {
    return(x %in% TRUE)
  }
  tolower(as.character(x)) %in% c("true", "t", "1", "yes")
}

fmt_n <- function(num, den) paste0(as.integer(num), "/", as.integer(den))
fmt4 <- function(x) ifelse(is.na(x), "NA", sprintf("%.4f", x))
fmt6 <- function(x) ifelse(is.na(x), "NA", sprintf("%.6f", x))
path_dashboard <- function(file) file.path(dashboard_dir, file)

pregrid_path <- path_dashboard(
  "structured-re-gaussian-lowq-sigma-intercept-pregrid-results.tsv"
)
pregrid_replicate_path <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-intercept-pregrid-nibi",
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke-replicates.tsv"
)
adaptive_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-adaptive-profile-smoke-local"
)
boundary_patch_replay_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-replay-local"
)
boundary_patch_sr150_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr150-local"
)
boundary_patch_sr1000_dirs <- c(
  boundary_patch_sr150_dir,
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr600-local-shard151-300"
  ),
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr600-local-shard301-450"
  ),
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr600-local-shard451-600"
  ),
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard601-650"
  ),
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard651-700"
  ),
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard701-750"
  ),
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard751-800"
  ),
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard801-850"
  ),
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard851-900"
  ),
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard901-950"
  ),
  file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard951-1000"
  )
)
tmbprofile_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-tmbprofile-smoke-local"
)
adaptive_summary_path <- file.path(
  adaptive_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv"
)
adaptive_replicate_path <- file.path(
  adaptive_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke-replicates.tsv"
)
boundary_patch_replay_summary_path <- file.path(
  boundary_patch_replay_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv"
)
boundary_patch_replay_replicate_path <- file.path(
  boundary_patch_replay_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke-replicates.tsv"
)
boundary_patch_sr150_summary_path <- file.path(
  boundary_patch_sr150_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv"
)
boundary_patch_sr150_replicate_path <- file.path(
  boundary_patch_sr150_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke-replicates.tsv"
)
boundary_patch_sr1000_replicate_paths <- file.path(
  boundary_patch_sr1000_dirs,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke-replicates.tsv"
)
tmbprofile_summary_path <- file.path(
  tmbprofile_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv"
)
tmbprofile_replicate_path <- file.path(
  tmbprofile_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke-replicates.tsv"
)

required_inputs <- c(
  pregrid_path,
  pregrid_replicate_path,
  adaptive_summary_path,
  adaptive_replicate_path,
  boundary_patch_replay_summary_path,
  boundary_patch_replay_replicate_path,
  boundary_patch_sr150_summary_path,
  boundary_patch_sr150_replicate_path,
  boundary_patch_sr1000_replicate_paths,
  tmbprofile_summary_path,
  tmbprofile_replicate_path
)
missing_inputs <- required_inputs[!file.exists(required_inputs)]
if (length(missing_inputs) > 0L) {
  stop(
    "Missing required input(s): ",
    paste(missing_inputs, collapse = ", "),
    call. = FALSE
  )
}

pregrid <- read_tsv(pregrid_path)
pregrid_replicates <- read_tsv(pregrid_replicate_path)
adaptive_summary <- read_tsv(adaptive_summary_path)
adaptive_replicates <- read_tsv(adaptive_replicate_path)
boundary_patch_replay_summary <- read_tsv(boundary_patch_replay_summary_path)
boundary_patch_replay_replicates <- read_tsv(
  boundary_patch_replay_replicate_path
)
boundary_patch_sr150_summary <- read_tsv(boundary_patch_sr150_summary_path)
boundary_patch_sr150_replicates <- read_tsv(boundary_patch_sr150_replicate_path)
boundary_patch_sr1000_replicates <- do.call(
  rbind,
  lapply(boundary_patch_sr1000_replicate_paths, read_tsv)
)
tmbprofile_summary <- read_tsv(tmbprofile_summary_path)
tmbprofile_replicates <- read_tsv(tmbprofile_replicate_path)

providers <- c("animal", "relmat")
cells <- c(
  animal = "qseries_animal_q1_sigma_intercept",
  relmat = "qseries_relmat_q1_sigma_intercept"
)

if (!identical(pregrid$provider, providers)) {
  stop("Pregrid result rows must be animal then relmat.", call. = FALSE)
}
if (!identical(adaptive_summary$provider, providers)) {
  stop(
    "Adaptive endpoint replay rows must be animal then relmat.",
    call. = FALSE
  )
}
if (!identical(boundary_patch_replay_summary$provider, providers)) {
  stop(
    "Boundary-patch endpoint replay rows must be animal then relmat.",
    call. = FALSE
  )
}
if (!identical(boundary_patch_sr150_summary$provider, providers)) {
  stop(
    "Boundary-patch SR150 rows must be animal then relmat.",
    call. = FALSE
  )
}
if (!identical(tmbprofile_summary$provider, providers)) {
  stop("tmbprofile replay rows must be animal then relmat.", call. = FALSE)
}

mcse_proportion <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  p <- mean(x)
  sqrt(p * (1 - p) / length(x))
}

profile_interval_covered <- function(x) {
  truth <- as.numeric(x$truth_value)
  lower <- as.numeric(x$profile.low)
  upper <- as.numeric(x$profile.high)
  ok <- truthy(x$profile_ok) & is.finite(lower) & is.finite(upper)
  out <- rep(NA, nrow(x))
  out[ok] <- lower[ok] <= truth[ok] & truth[ok] <= upper[ok]
  out
}

profile_interval_lower_miss <- function(x) {
  truth <- as.numeric(x$truth_value)
  lower <- as.numeric(x$profile.low)
  ok <- truthy(x$profile_ok) & is.finite(lower)
  out <- rep(NA, nrow(x))
  out[ok] <- truth[ok] < lower[ok]
  out
}

profile_interval_upper_miss <- function(x) {
  truth <- as.numeric(x$truth_value)
  upper <- as.numeric(x$profile.high)
  ok <- truthy(x$profile_ok) & is.finite(upper)
  out <- rep(NA, nrow(x))
  out[ok] <- truth[ok] > upper[ok]
  out
}

summarise_profile_channel <- function(x) {
  ok <- truthy(x$profile_ok)
  covered <- profile_interval_covered(x)
  lower_miss <- profile_interval_lower_miss(x)
  upper_miss <- profile_interval_upper_miss(x)
  covered_ok <- covered[ok]
  data.frame(
    n_rep = nrow(x),
    profile_finite = fmt_n(sum(truthy(x$profile_finite)), nrow(x)),
    profile_ok = fmt_n(sum(ok), nrow(x)),
    profile_covered = fmt_n(sum(covered_ok, na.rm = TRUE), length(covered_ok)),
    profile_coverage = fmt4(mean(covered_ok, na.rm = TRUE)),
    profile_coverage_mcse = fmt6(mcse_proportion(covered_ok)),
    profile_lower_miss = sum(lower_miss, na.rm = TRUE),
    profile_upper_miss = sum(upper_miss, na.rm = TRUE),
    near_boundary = fmt_n(
      sum(x$profile_message == "near_sd_boundary", na.rm = TRUE),
      nrow(x)
    ),
    stringsAsFactors = FALSE
  )
}

make_row <- function(provider) {
  cell_id <- unname(cells[[provider]])
  pregrid_row <- pregrid[pregrid$provider == provider, , drop = FALSE]
  adaptive_row <- adaptive_summary[
    adaptive_summary$provider == provider,
    ,
    drop = FALSE
  ]
  tmbprofile_row <- tmbprofile_summary[
    tmbprofile_summary$provider == provider,
    ,
    drop = FALSE
  ]
  original_provider <- pregrid_replicates[
    pregrid_replicates$provider == provider,
    ,
    drop = FALSE
  ]
  adaptive_provider <- adaptive_replicates[
    adaptive_replicates$provider == provider,
    ,
    drop = FALSE
  ]
  boundary_patch_replay_provider <- boundary_patch_replay_replicates[
    boundary_patch_replay_replicates$provider == provider,
    ,
    drop = FALSE
  ]
  boundary_patch_sr150_provider <- boundary_patch_sr150_replicates[
    boundary_patch_sr150_replicates$provider == provider,
    ,
    drop = FALSE
  ]
  boundary_patch_sr1000_provider <- boundary_patch_sr1000_replicates[
    boundary_patch_sr1000_replicates$provider == provider,
    ,
    drop = FALSE
  ]
  tmbprofile_provider <- tmbprofile_replicates[
    tmbprofile_replicates$provider == provider,
    ,
    drop = FALSE
  ]

  replay_seeds <- sort(unique(adaptive_provider$seed))
  original_replay <- original_provider[
    original_provider$seed %in% replay_seeds,
    ,
    drop = FALSE
  ]
  original_replay <- original_replay[
    order(original_replay$seed),
    ,
    drop = FALSE
  ]
  adaptive_provider <- adaptive_provider[
    order(adaptive_provider$seed),
    ,
    drop = FALSE
  ]
  tmbprofile_provider <- tmbprofile_provider[
    order(tmbprofile_provider$seed),
    ,
    drop = FALSE
  ]
  boundary_patch_replay_provider <- boundary_patch_replay_provider[
    order(boundary_patch_replay_provider$seed),
    ,
    drop = FALSE
  ]
  boundary_patch_sr150_provider <- boundary_patch_sr150_provider[
    order(boundary_patch_sr150_provider$seed),
    ,
    drop = FALSE
  ]
  boundary_patch_sr1000_provider <- boundary_patch_sr1000_provider[
    order(boundary_patch_sr1000_provider$seed),
    ,
    drop = FALSE
  ]
  if (
    !identical(original_replay$seed, replay_seeds) ||
      !identical(adaptive_provider$seed, replay_seeds) ||
      !identical(tmbprofile_provider$seed, replay_seeds)
  ) {
    stop(provider, " replay seed sets do not match.", call. = FALSE)
  }
  if (!identical(boundary_patch_replay_provider$seed, replay_seeds)) {
    stop(
      provider,
      " boundary-patch replay seed set does not match.",
      call. = FALSE
    )
  }
  expected_sr1000_seeds <- 914000L + seq_len(1000L)
  if (
    !all(
      as.integer(boundary_patch_sr1000_provider$seed) == expected_sr1000_seeds
    )
  ) {
    stop(
      provider,
      " boundary-patch SR1000 seed set is not 914001-915000.",
      call. = FALSE
    )
  }

  original_profile_finite <- truthy(original_provider$profile_finite)
  original_replay_finite <- truthy(original_replay$profile_finite)
  adaptive_profile_finite <- truthy(adaptive_provider$profile_finite)
  boundary_patch_replay_profile_finite <- truthy(
    boundary_patch_replay_provider$profile_finite
  )
  tmbprofile_profile_finite <- truthy(tmbprofile_provider$profile_finite)
  original_replay_failed <- !original_replay_finite
  adaptive_rescued <- original_replay_failed & adaptive_profile_finite
  boundary_patch_rescued <- original_replay_failed &
    boundary_patch_replay_profile_finite
  remaining_adaptive_failures <- adaptive_provider[
    !adaptive_profile_finite,
    ,
    drop = FALSE
  ]
  boundary_patch_replay_profile_summary <- summarise_profile_channel(
    boundary_patch_replay_provider
  )
  boundary_patch_sr150_profile_summary <- summarise_profile_channel(
    boundary_patch_sr150_provider
  )
  boundary_patch_sr1000_profile_summary <- summarise_profile_channel(
    boundary_patch_sr1000_provider
  )

  remaining_seed <- paste(remaining_adaptive_failures$seed, collapse = ";")
  remaining_message <- paste(
    remaining_adaptive_failures$profile_message,
    collapse = " | "
  )
  data.frame(
    review_id = paste0(
      "gaussian_lowq_sigma_profile_route_review_",
      provider
    ),
    cell_id = cell_id,
    provider = provider,
    source_pregrid = "docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-intercept-pregrid-results.tsv",
    source_pregrid_replicates = "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-intercept-pregrid-nibi/structured-re-gaussian-lowq-sigma-intercept-local-smoke-replicates.tsv",
    source_adaptive_endpoint_smoke = "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-adaptive-profile-smoke-local",
    source_boundary_endpoint_patch_smoke = "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-replay-local",
    source_boundary_endpoint_patch_sr150 = "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr150-local",
    source_boundary_endpoint_patch_sr1000_shards = paste(
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr150-local",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr600-local-shard151-300",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr600-local-shard301-450",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr600-local-shard451-600",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard601-650",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard651-700",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard701-750",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard751-800",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard801-850",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard851-900",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard901-950",
      "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-sr1000-local-shard951-1000",
      sep = ";"
    ),
    source_tmbprofile_smoke = "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-tmbprofile-smoke-local",
    replay_seed_range = paste0(min(replay_seeds), "-", max(replay_seeds)),
    replay_n_rep = length(replay_seeds),
    original_endpoint_budget = unique(
      original_replay$profile_endpoint_max_eval
    ),
    adaptive_endpoint_budget = unique(
      adaptive_provider$profile_endpoint_max_eval
    ),
    original_sr150_wald_usable = fmt_n(
      pregrid_row$n_usable_intervals,
      pregrid_row$n_rep
    ),
    original_sr150_profile_finite = fmt_n(
      sum(original_profile_finite),
      nrow(original_provider)
    ),
    replay_original_profile_finite = fmt_n(
      sum(original_replay_finite),
      length(replay_seeds)
    ),
    adaptive_profile_finite = fmt_n(
      sum(adaptive_profile_finite),
      length(replay_seeds)
    ),
    adaptive_profile_rescued = fmt_n(
      sum(adaptive_rescued),
      sum(original_replay_failed)
    ),
    adaptive_remaining_failure_seed = remaining_seed,
    adaptive_remaining_failure_message = remaining_message,
    boundary_patch_replay_profile_finite = fmt_n(
      sum(boundary_patch_replay_profile_finite),
      length(replay_seeds)
    ),
    boundary_patch_replay_profile_rescued = fmt_n(
      sum(boundary_patch_rescued),
      sum(original_replay_failed)
    ),
    boundary_patch_replay_profile_coverage = boundary_patch_replay_profile_summary$profile_coverage,
    boundary_patch_sr150_profile_finite = boundary_patch_sr150_profile_summary$profile_finite,
    boundary_patch_sr150_profile_coverage = boundary_patch_sr150_profile_summary$profile_coverage,
    boundary_patch_sr150_profile_mcse = boundary_patch_sr150_profile_summary$profile_coverage_mcse,
    boundary_patch_sr150_profile_misses = paste0(
      "lower=",
      boundary_patch_sr150_profile_summary$profile_lower_miss,
      ";upper=",
      boundary_patch_sr150_profile_summary$profile_upper_miss
    ),
    boundary_patch_sr150_near_boundary = boundary_patch_sr150_profile_summary$near_boundary,
    boundary_patch_sr1000_profile_finite = boundary_patch_sr1000_profile_summary$profile_finite,
    boundary_patch_sr1000_profile_coverage = boundary_patch_sr1000_profile_summary$profile_coverage,
    boundary_patch_sr1000_profile_mcse = boundary_patch_sr1000_profile_summary$profile_coverage_mcse,
    boundary_patch_sr1000_profile_misses = paste0(
      "lower=",
      boundary_patch_sr1000_profile_summary$profile_lower_miss,
      ";upper=",
      boundary_patch_sr1000_profile_summary$profile_upper_miss
    ),
    boundary_patch_sr1000_near_boundary = boundary_patch_sr1000_profile_summary$near_boundary,
    tmbprofile_profile_finite = fmt_n(
      sum(tmbprofile_profile_finite),
      length(replay_seeds)
    ),
    tmbprofile_decision = "negative_fallback_not_smoke_ready",
    route_status = "endpoint_zero_boundary_patch_sr1000_upper_tail_blocked",
    review_decision = "fisher_gauss_rose_profile_channel_blocked_no_promotion",
    promotion_decision = "do_not_promote",
    linked_fit_status = "point_fit",
    linked_interval_status = "planned",
    linked_coverage_status = "planned",
    evidence_url = "docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-profile-route-review.tsv",
    claim_boundary = paste(
      "This promotes exactly no Q-Series row;",
      "animal/relmat q1 sigma profile-route replay is route-diagnostic blocker evidence only;",
      "endpoint budget 48 originally rescued 2/3 (two of three) selected endpoint-profile",
      "failures per provider; the endpoint zero-boundary patch then resolved",
      "the selected root-error seed 914011 and produced SR1000 profile-channel evidence;",
      paste0(
        "SR1000 profile coverage=",
        boundary_patch_sr1000_profile_summary$profile_coverage,
        ", MCSE=",
        boundary_patch_sr1000_profile_summary$profile_coverage_mcse,
        ", misses=",
        boundary_patch_sr1000_profile_summary$profile_lower_miss,
        " lower/",
        boundary_patch_sr1000_profile_summary$profile_upper_miss,
        " upper;"
      ),
      "this is an upper-tail interval-shape blocker, not an MCSE problem;",
      "tmbprofile remains a 0/5 finite-profile negative fallback;",
      "linked support cells remain point_fit/planned/planned; no interval_status,",
      "coverage_status, inference_ready, supported, q1 mu, matched mu+sigma, q2,",
      "q4/q8, non-Gaussian interval, REML, AI-REML, bridge support, host-denominator,",
      "or public support claim."
    ),
    next_gate = paste(
      "Do not top up the endpoint zero-boundary profile route for q1 sigma",
      "animal/relmat; Fisher/Gauss/Rose block promotion because SR1000 already",
      "shows upper-tail miss imbalance under a finite local denominator. Design",
      "a new q1 sigma interval route or write a blocker decision before any",
      "Totoro/Nibi/Rorqual/Trillium/DRAC confirmation or support-cell status edit."
    ),
    stringsAsFactors = FALSE
  )
}

review_rows <- do.call(rbind, lapply(providers, make_row))
row.names(review_rows) <- NULL
write_tsv(review_rows, out_path)

if (sync_dashboard) {
  out_rel <- "docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-profile-route-review.tsv"
  support_path <- path_dashboard("structured-re-q-series-support-cells.tsv")
  lowq_path <- path_dashboard("structured-re-gaussian-lowq-status-audit.tsv")
  row_selection_path <- path_dashboard(
    "structured-re-gaussian-lowq-row-selection.tsv"
  )
  queue_path <- path_dashboard("structured-re-q-series-next-campaign-queue.tsv")
  closure_path <- path_dashboard("structured-re-q-series-closure-triage.tsv")
  support <- read_tsv(support_path)
  lowq <- read_tsv(lowq_path)
  row_selection <- read_tsv(row_selection_path)
  queue <- read_tsv(queue_path)
  closure <- read_tsv(closure_path)

  support_idx <- match(review_rows$cell_id, support$cell_id)
  lowq_idx <- match(review_rows$cell_id, lowq$cell_id)
  selection_idx <- match(review_rows$cell_id, row_selection$cell_id)
  if (anyNA(support_idx) || anyNA(lowq_idx) || anyNA(selection_idx)) {
    stop(
      "Dashboard sync could not find all q1 sigma animal/relmat rows.",
      call. = FALSE
    )
  }

  for (i in seq_along(support_idx)) {
    provider <- review_rows$provider[[i]]
    support$evidence_url[[support_idx[[i]]]] <- out_rel
    support$denominator_policy[[support_idx[[
      i
    ]]]] <- "endpoint_zero_boundary_profile_sr1000_upper_tail_blocked"
    support$claim_boundary[[support_idx[[i]]]] <- paste(
      "Gaussian low-q q1 sigma-intercept endpoint zero-boundary profile route",
      "has SR1000 profile-channel blocker evidence;",
      provider,
      "endpoint budget 48 selected replay rescued 2/3 (two of three) selected failures before",
      "the 914011 root-error seed was resolved by the endpoint zero-boundary patch;",
      paste0(
        "profile coverage=",
        review_rows$boundary_patch_sr1000_profile_coverage[[i]],
        ", MCSE=",
        review_rows$boundary_patch_sr1000_profile_mcse[[i]],
        ", misses=",
        review_rows$boundary_patch_sr1000_profile_misses[[i]],
        ";"
      ),
      "this is an upper-tail interval-shape blocker, not an MCSE problem;",
      "tmbprofile remains a 0/5 finite-profile negative fallback. This promotes",
      "exactly no Q-Series row and does not claim interval_status, coverage_status,",
      "inference_ready, supported, q1 mu, matched mu+sigma, q2, q4/q8,",
      "non-Gaussian, REML, AI-REML, bridge support, denominator pass, or public support.",
      "The linked status remains point_fit/planned/planned."
    )
    support$next_gate[[support_idx[[i]]]] <- paste(
      "Do not top up this endpoint zero-boundary profile route on Totoro,",
      "Nibi, Rorqual, Trillium, or other DRAC hosts. Fisher/Gauss/Rose must",
      "choose a new q1 sigma interval route or record a blocker decision before",
      "any interval_status, coverage_status, inference_ready, supported, or",
      "public-support edit."
    )
  }

  for (i in seq_along(lowq_idx)) {
    provider <- review_rows$provider[[i]]
    lowq$evidence_url[[lowq_idx[[i]]]] <- out_rel
    lowq$evidence_basis[[lowq_idx[[i]]]] <- paste(
      "native point/extractor evidence plus imported Nibi SR150 q1 sigma-intercept",
      "pregrid and local profile-route replay;",
      provider,
      "SR150 retained 150/150 fit/convergence/pdHess/confint attempts but only",
      "115/150 usable raw-Wald intervals and 118/150 warning replicates;"
    )
    lowq$stability_signal[[lowq_idx[[i]]]] <- paste(
      "fit/convergence/pdHess are stable in SR1000 and the endpoint zero-boundary",
      "profile route returned 1000/1000 finite profile intervals; tmbprofile is",
      "still a negative fallback."
    )
    lowq$inference_signal[[lowq_idx[[i]]]] <- paste(
      "SR1000 endpoint zero-boundary profile coverage is",
      review_rows$boundary_patch_sr1000_profile_coverage[[i]],
      "with MCSE",
      review_rows$boundary_patch_sr1000_profile_mcse[[i]],
      "and misses",
      review_rows$boundary_patch_sr1000_profile_misses[[i]],
      "after endpoint budget 48 selected replay rescued 2/3 (two of three) selected failures",
      "before the 914011 root-error seed was resolved; Fisher/Gauss/Rose review is",
      "now blocks top-up/promotion from this route, and linked support status remains",
      "point_fit/planned/planned."
    )
    lowq$claim_boundary[[lowq_idx[[i]]]] <- paste(
      "Gaussian low-q q1 sigma row has point/fixture evidence only plus diagnostic",
      "SR150/profile-route blocker evidence only; the SR1000 finite profile",
      "denominator shows upper-tail miss imbalance, so this route is not",
      "interval+coverage",
      "inference_ready, supported, REML, AI-REML, broad bridge support, high-q",
      "support, non-Gaussian support, denominator-pass evidence, or public support."
    )
    lowq$next_gate[[lowq_idx[[i]]]] <- paste(
      "Do not top up this endpoint zero-boundary profile route. Fisher/Gauss/Rose",
      "must choose a new q1 sigma interval route or record a blocker decision",
      "before any TSV promotion, inference_ready, supported, or public-support",
      "claim; Totoro/Nibi/Rorqual/Trillium/DRAC confirmation is only useful",
      "after a new route is accepted."
    )
  }

  for (i in seq_along(selection_idx)) {
    row_selection$selection_status[[selection_idx[[
      i
    ]]]] <- "sigma_profile_channel_upper_tail_blocked"
    row_selection$run_mode[[selection_idx[[
      i
    ]]]] <- "profile_channel_blocker_no_topup"
    row_selection$allowed_hosts[[selection_idx[[i]]]] <- paste(
      "local route replay only for artifact inspection; Totoro/FIIA/Nibi/Rorqual",
      "Trillium/DRAC confirmation only after Fisher/Gauss/Rose accept a new",
      "q1 sigma interval route"
    )
    row_selection$blocked_hosts[[selection_idx[[i]]]] <- paste(
      "Totoro/FIIA/Nibi/Rorqual/Trillium/DRAC top-up is blocked for the current",
      "endpoint zero-boundary profile route because SR1000 already shows upper-tail",
      "miss imbalance; all future host evidence must stay host-separated."
    )
    row_selection$required_preconditions[[selection_idx[[i]]]] <- paste(
      "Use structured-re-gaussian-lowq-sigma-profile-route-review.tsv;",
      "endpoint budget 48 selected replay plus endpoint zero-boundary profile",
      "SR1000 evidence is complete locally and blocks this route; tmbprofile",
      "remains 0/5 finite; design a new interval route before more compute."
    )
    row_selection$evidence_url[[selection_idx[[i]]]] <- out_rel
    row_selection$claim_boundary[[selection_idx[[i]]]] <- paste(
      "Gaussian low-q row-selection contract only; this promotes exactly no",
      "Q-Series row. The q1 sigma endpoint zero-boundary profile route is a",
      "hard blocker for promotion because SR1000 has 12 lower/45 upper misses",
      "despite 1000/1000 finite profile intervals, not evidence that the animal",
      "or relmat model cells are unsupported. Support cells",
      "remain point_fit/planned/planned; not interval_status, coverage_status,",
      "inference_ready, supported, q2, q4/q8, non-Gaussian, REML, AI-REML,",
      "bridge support, or public support."
    )
    row_selection$next_gate[[selection_idx[[i]]]] <- paste(
      "Do not top up this route. Fisher/Gauss/Rose must choose a new q1 sigma",
      "interval route or record a blocker decision before Totoro/DRAC confirmation",
      "or any status edit."
    )
  }

  queue_idx <- match(
    "qseries_queue_gaussian_lowq_interval_design",
    queue$queue_id
  )
  if (!is.na(queue_idx)) {
    queue$readiness_state[[queue_idx]] <- paste(
      "Nibi SR475 q1 mu-intercept retained-denominator aggregate promoted",
      "phylo/spatial/relmat to inference_ready with caveats after Rose/Fisher/Grace",
      "review; animal q1 mu remains blocked. Animal/relmat q1 sigma now has",
      "endpoint zero-boundary profile SR1000 upper-tail blocker evidence with",
      "finite profiles and no top-up authorization. Q2 retained",
      "denominator repair remains route-design first."
    )
    queue$next_action[[queue_idx]] <- paste(
      "For q1 sigma animal/relmat, do not top up the endpoint zero-boundary",
      "profile route on Totoro, Nibi, Rorqual, Trillium, or DRAC. Fisher/Gauss/Rose",
      "must choose a new q1 sigma interval route or record a blocker decision;",
      "support cells stay point_fit/planned/planned."
    )
  }

  closure_idx <- match(
    "qseries_closure_gaussian_lowq_gate_required",
    closure$triage_id
  )
  if (!is.na(closure_idx)) {
    closure$status_meaning[[closure_idx]] <- paste(
      "Gaussian low-q gate rows include q1 sigma animal/relmat upper-tail",
      "profile-route blocker evidence, q2 retained-denominator route-repair rows, and",
      "other point/fixture rows; support cells remain point_fit/planned/planned",
      "unless separately promoted."
    )
    closure$next_action[[closure_idx]] <- paste(
      "Do not top up the q1 sigma endpoint zero-boundary profile route; keep q2",
      "repair and q1 sigma route design separate. Totoro and Trillium can be",
      "confirmation hosts only after source/provenance checks and Fisher/Gauss/Rose",
      "accept a new route."
    )
  }

  write_tsv(support, support_path)
  write_tsv(lowq, lowq_path)
  write_tsv(row_selection, row_selection_path)
  write_tsv(
    row_selection,
    file.path(
      root,
      "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local",
      "structured-re-gaussian-lowq-row-selection.tsv"
    )
  )
  write_tsv(queue, queue_path)
  write_tsv(closure, closure_path)

  version_path <- path_dashboard("version.txt")
  version <- trimws(readLines(version_path, warn = FALSE)[1L])
  version_num <- suppressWarnings(as.integer(sub("^r", "", version)))
  if (is.finite(version_num)) {
    writeLines(paste0("r", version_num + 1L), version_path)
  }
}

message(
  "Wrote ",
  nrow(review_rows),
  " q1 sigma profile-route review rows to ",
  out_path
)
if (sync_dashboard) {
  message("Synchronized q1 sigma route blockers across mission-control TSVs.")
}
