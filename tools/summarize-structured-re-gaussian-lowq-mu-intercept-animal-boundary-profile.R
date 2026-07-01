#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args
sync_dashboard <- "--sync-dashboard=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")
artifact_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts",
  "2026-06-30-gaussian-lowq-mu-intercept-animal-boundary-profile-local"
)
summary_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile.tsv"
)
artifact_summary_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile.tsv"
)
replicate_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile-replicates.tsv"
)
seed_manifest_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile-seed-manifest.tsv"
)

if ((file.exists(summary_path) || dir.exists(artifact_dir)) && !overwrite) {
  stop(
    "Output exists; pass --overwrite=true to replace the local profile review.",
    call. = FALSE
  )
}
if (dir.exists(artifact_dir) && overwrite) {
  unlink(artifact_dir, recursive = TRUE)
}
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
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
    na = "NA"
  )
}

fmt <- function(x, digits = 7L) {
  ifelse(is.na(x), "NA", sprintf(paste0("%.", digits, "f"), x))
}

load_drmTMB_for_review <- function(path) {
  if (requireNamespace("devtools", quietly = TRUE)) {
    suppressPackageStartupMessages(devtools::load_all(path, quiet = TRUE))
    return(invisible("devtools_load_all"))
  }
  if (requireNamespace("drmTMB", quietly = TRUE)) {
    suppressPackageStartupMessages(library(drmTMB))
    return(invisible("library_drmTMB"))
  }
  stop("Cannot load drmTMB for the local profile review.", call. = FALSE)
}

load_drmTMB_for_review(root)
source(file.path(root, "inst/sim/R/sim_registry.R"))
source(file.path(root, "inst/sim/R/sim_utils.R"))
source(file.path(root, "inst/sim/dgp/sim_dgp_animal_mu_slope.R"))

make_animal_intercept <- function(seed) {
  phase18_with_seed(seed, function() {
    n_group <- 8L
    n_each <- 7L
    beta_mu_intercept <- 0.25
    sigma <- 0.22
    sd_intercept <- 0.55
    id_levels <- paste0("id_", seq_len(n_group))
    pedigree <- phase18_animal_mu_slope_pedigree(id_levels)
    A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
    animal_intercept <- as.vector(
      t(chol(A)) %*% stats::rnorm(n_group, sd = sd_intercept)
    )
    names(animal_intercept) <- id_levels
    id <- rep(id_levels, each = n_each)
    mu <- unname(beta_mu_intercept + animal_intercept[id])
    y <- stats::rnorm(length(id), mean = mu, sd = sigma)
    dat <- data.frame(y = y, id = id, stringsAsFactors = FALSE)
    attr(dat, "truth") <- list(
      A = A,
      truth_sd = sd_intercept,
      n_group = n_group,
      n_each = n_each,
      beta_mu_intercept = beta_mu_intercept,
      sigma = sigma
    )
    dat
  })
}

profile_seed <- function(seed, replicate_index) {
  dat <- make_animal_intercept(seed)
  truth <- attr(dat, "truth", exact = TRUE)
  A <- truth$A
  fit <- drmTMB(
    bf(y ~ animal(1 | id, A = A), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  target <- "sd:mu:animal(1 | id)"
  wald <- suppressWarnings(confint(fit, parm = target))
  endpoint <- suppressWarnings(confint(
    fit,
    parm = target,
    method = "profile",
    profile_engine = "endpoint",
    profile_endpoint_max_eval = 96
  ))
  tmbprofile <- suppressWarnings(confint(
    fit,
    parm = target,
    method = "profile",
    profile_engine = "tmbprofile",
    profile_precision = "fast"
  ))
  estimate <- unname(fit$sdpars$mu[["animal(1 | id)"]])
  endpoint_covers <- identical(endpoint$conf.status[[1L]], "profile") &&
    endpoint$lower[[1L]] <= truth$truth_sd &&
    truth$truth_sd <= endpoint$upper[[1L]]
  tmbprofile_covers <- identical(tmbprofile$conf.status[[1L]], "profile") &&
    tmbprofile$lower[[1L]] <= truth$truth_sd &&
    truth$truth_sd <= tmbprofile$upper[[1L]]
  data.frame(
    profile_review_id = paste0(
      "gaussian_lowq_mu_intercept_animal_boundary_profile_seed",
      seed
    ),
    cell_id = "qseries_animal_q1_mu_intercept",
    provider = "animal",
    formula_cell = "animal(1 | id, A = A) in mu",
    replicate_index = replicate_index,
    seed = seed,
    target_parameter = target,
    truth_sd_mu_intercept = truth$truth_sd,
    estimate = estimate,
    fit_ok = TRUE,
    converged = isTRUE(fit$opt$convergence == 0),
    pdHess = isTRUE(fit$sdr$pdHess),
    wald_status = wald$conf.status[[1L]],
    wald_lower = wald$lower[[1L]],
    wald_upper = wald$upper[[1L]],
    endpoint_status = endpoint$conf.status[[1L]],
    endpoint_lower = endpoint$lower[[1L]],
    endpoint_upper = endpoint$upper[[1L]],
    endpoint_boundary = endpoint$profile.boundary[[1L]],
    endpoint_message = endpoint$profile.message[[1L]],
    endpoint_covered = endpoint_covers,
    tmbprofile_status = tmbprofile$conf.status[[1L]],
    tmbprofile_lower = tmbprofile$lower[[1L]],
    tmbprofile_upper = tmbprofile$upper[[1L]],
    tmbprofile_message = tmbprofile$profile.message[[1L]],
    tmbprofile_covered = tmbprofile_covers,
    stringsAsFactors = FALSE
  )
}

seeds <- c(812407L, 812444L)
replicates <- do.call(rbind, Map(profile_seed, seeds, c(407L, 444L)))
row.names(replicates) <- NULL

endpoint_finite <- is.finite(replicates$endpoint_lower) &
  is.finite(replicates$endpoint_upper) &
  replicates$endpoint_status == "profile"
tmbprofile_finite <- is.finite(replicates$tmbprofile_lower) &
  is.finite(replicates$tmbprofile_upper) &
  replicates$tmbprofile_status == "profile"
endpoint_upper_miss <- endpoint_finite &
  replicates$truth_sd_mu_intercept > replicates$endpoint_upper

summary <- data.frame(
  review_id = "gaussian_lowq_mu_intercept_animal_boundary_profile_review",
  cell_id = "qseries_animal_q1_mu_intercept",
  provider = "animal",
  source_sr475 = "docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv",
  source_sr475_replicates = "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/structured-re-gaussian-lowq-mu-intercept-sr475-results-replicates.tsv",
  artifact_dir = "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-animal-boundary-profile-local",
  replicate_artifact = "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-animal-boundary-profile-local/structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile-replicates.tsv",
  replay_seed_range = "812407;812444",
  replay_n_rep = nrow(replicates),
  sr475_usable_intervals = "473/475",
  sr475_coverage = "0.9747",
  sr475_coverage_mcse = "0.007200",
  sr475_misses = "lower=6;upper=4",
  wald_boundary_seeds = paste(seeds, collapse = ";"),
  wald_statuses = paste(replicates$wald_status, collapse = ";"),
  wald_estimates = paste(fmt(replicates$estimate), collapse = ";"),
  endpoint_profile_finite = paste0(sum(endpoint_finite), "/", nrow(replicates)),
  endpoint_profile_intervals = paste0(
    "[",
    paste(fmt(replicates$endpoint_lower), fmt(replicates$endpoint_upper), sep = ","),
    "]",
    collapse = ";"
  ),
  endpoint_profile_coverage = fmt(mean(replicates$endpoint_covered), 4L),
  endpoint_profile_misses = paste0(
    "lower=0;upper=",
    sum(endpoint_upper_miss)
  ),
  endpoint_profile_messages = paste(unique(replicates$endpoint_message), collapse = ";"),
  tmbprofile_profile_finite = paste0(sum(tmbprofile_finite), "/", nrow(replicates)),
  tmbprofile_decision = "negative_fallback_nonfinite_interval",
  route_status = "animal_mu_boundary_profile_hard_seed_blocked",
  review_decision = "fisher_gauss_rose_boundary_profile_blocked_no_topup",
  promotion_decision = "do_not_promote",
  linked_fit_status = "point_fit",
  linked_interval_status = "planned",
  linked_coverage_status = "planned",
  evidence_url = "docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile.tsv",
  claim_boundary = paste(
    "This promotes exactly no Q-Series row; animal q1 mu intercept remains",
    "point_fit/planned/planned. Nibi SR475 retained-denominator evidence has",
    "473/475 usable Wald intervals and retained wald_at_boundary seeds 812407",
    "and 812444. Local hard-seed replay shows endpoint profile intervals are",
    "finite 2/2 but both are upper misses against truth 0.55, while tmbprofile",
    "is 0/2 finite with nonfinite_interval. This is boundary/profile interval",
    "shape blocker evidence, not an MCSE problem and not a top-up candidate;",
    "no interval_status, coverage_status, inference_ready, supported, q1 sigma,",
    "matched mu+sigma, q2, q4/q8, non-Gaussian interval, REML, AI-REML, bridge",
    "support, mixed-host denominator, or public support claim."
  ),
  next_gate = paste(
    "Do not top up animal q1 mu on Totoro, FIIA, Nibi, Rorqual, Trillium,",
    "or DRAC from this route. Fisher/Gauss/Rose must design a new animal q1",
    "mu interval route or write an explicit blocker decision before any",
    "support-cell status edit."
  ),
  stringsAsFactors = FALSE
)

seed_manifest <- data.frame(
  provider = "animal",
  replicate_index = c(407L, 444L),
  seed = seeds,
  seed_role = "animal_q1_mu_boundary_profile_hard_seed_replay",
  execution_status = "executed",
  source_sr475 = summary$source_sr475[[1L]],
  host_class = "local_boundary_profile_replay",
  host_name = unname(Sys.info()[["nodename"]]),
  stringsAsFactors = FALSE
)

write_tsv(summary, summary_path)
write_tsv(summary, artifact_summary_path)
write_tsv(replicates, replicate_path)
write_tsv(seed_manifest, seed_manifest_path)
writeLines(capture.output(sessionInfo()), file.path(artifact_dir, "sessionInfo.txt"))
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) paste("git-sha-unavailable:", conditionMessage(e))
)
writeLines(git_sha, file.path(artifact_dir, "git-sha.txt"))

if (sync_dashboard) {
  support_path <- file.path(dashboard_dir, "structured-re-q-series-support-cells.tsv")
  lowq_path <- file.path(dashboard_dir, "structured-re-gaussian-lowq-status-audit.tsv")
  row_selection_path <- file.path(dashboard_dir, "structured-re-gaussian-lowq-row-selection.tsv")
  queue_path <- file.path(dashboard_dir, "structured-re-q-series-next-campaign-queue.tsv")
  closure_path <- file.path(dashboard_dir, "structured-re-q-series-closure-triage.tsv")

  support <- read_tsv(support_path)
  lowq <- read_tsv(lowq_path)
  row_selection <- read_tsv(row_selection_path)
  queue <- read_tsv(queue_path)
  closure <- read_tsv(closure_path)

  support_hit <- support$cell_id == summary$cell_id[[1L]]
  support$evidence_url[support_hit] <- summary$evidence_url[[1L]]
  support$claim_boundary[support_hit] <- summary$claim_boundary[[1L]]
  support$denominator_policy[support_hit] <-
    "sr475_retained_denominator_plus_hard_seed_profile_blocked"
  support$next_gate[support_hit] <- summary$next_gate[[1L]]

  lowq_hit <- lowq$cell_id == summary$cell_id[[1L]]
  lowq$evidence_basis[lowq_hit] <- paste(
    "Imported Nibi SR475 retained-denominator aggregate plus local hard-seed",
    "profile replay; seeds 812407 and 812444 are retained wald_at_boundary",
    "Wald rows with conf.low=0 and conf.high=Inf."
  )
  lowq$stability_signal[lowq_hit] <- paste(
    "SR475 has 475/475 fit, convergence, pdHess, and confint; local hard-seed",
    "endpoint profiles are finite 2/2 but both land on near-SD-boundary",
    "intervals that upper-miss the truth."
  )
  lowq$inference_signal[lowq_hit] <- paste(
    "Boundary/profile blocker: endpoint profile finite 2/2 but upper misses",
    "2/2; tmbprofile finite 0/2; interval_status and coverage_status remain",
    "planned."
  )
  lowq$evidence_url[lowq_hit] <- summary$evidence_url[[1L]]
  lowq$claim_boundary[lowq_hit] <- summary$claim_boundary[[1L]]
  lowq$next_gate[lowq_hit] <- summary$next_gate[[1L]]

  row_hit <- row_selection$cell_id == summary$cell_id[[1L]]
  row_selection$selection_status[row_hit] <-
    "animal_mu_boundary_profile_hard_seed_blocked"
  row_selection$run_mode[row_hit] <- "boundary_profile_blocker_no_topup"
  row_selection$allowed_hosts[row_hit] <-
    "local replay only for artifact inspection; no host top-up from this route"
  row_selection$blocked_hosts[row_hit] <- paste(
    "Totoro/FIIA/Nibi/Rorqual/Trillium/DRAC top-up is blocked for the current",
    "animal q1 mu Wald/profile route because hard seeds already show",
    "boundary/profile upper misses."
  )
  row_selection$required_preconditions[row_hit] <- paste(
    "Use structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile.tsv;",
    "SR475 retained-denominator evidence plus hard-seed profile replay is",
    "complete for this route; design a new animal q1 mu interval route before",
    "more compute."
  )
  row_selection$evidence_url[row_hit] <- summary$evidence_url[[1L]]
  row_selection$claim_boundary[row_hit] <- summary$claim_boundary[[1L]]
  row_selection$next_gate[row_hit] <- summary$next_gate[[1L]]

  queue_hit <- queue$queue_id == "qseries_queue_gaussian_lowq_interval_design"
  queue$primary_evidence[queue_hit] <- summary$evidence_url[[1L]]
  queue$readiness_state[queue_hit] <- paste(
    "Nibi SR475 q1 mu-intercept evidence promoted phylo/spatial/relmat to",
    "inference_ready with caveats; animal q1 mu is boundary/profile blocked",
    "after hard-seed replay. Animal/relmat q1 sigma also has endpoint",
    "zero-boundary profile SR1000 upper-tail blocker evidence. Q2 retained",
    "denominator repair remains route-design first."
  )
  queue$required_preconditions[queue_hit] <- paste(
    "For animal q1 mu, design a new interval route or write a blocker decision",
    "before any Totoro/DRAC top-up or status edit. For q1 sigma, choose a new",
    "interval route or blocker decision. For q2 retained-denominator rows,",
    "write the named interval-repair route first and rerun only small",
    "host-separated smokes after review."
  )
  queue$stop_rule[queue_hit] <- paste(
    "Stop if animal q1 mu hard-seed boundary/profile upper misses are ignored,",
    "if q1 sigma or q2 blockers are top-up escalated without a new route, or",
    "if any low-q row is promoted from point stability or host reachability."
  )
  queue$next_action[queue_hit] <- paste(
    "For animal q1 mu, do not top up this route; Fisher/Gauss/Rose must choose",
    "a new interval route or record a blocker decision. Then choose the next",
    "exact Tranche 2 cell."
  )

  closure_hit <- closure$triage_id == "qseries_closure_gaussian_lowq_gate_required"
  closure$status_meaning[closure_hit] <- paste(
    "Gaussian low-q gate rows include animal q1 mu boundary/profile hard-seed",
    "blocker evidence, q1 sigma upper-tail profile-route blocker evidence, q2",
    "retained-denominator route-repair rows, and other point/fixture rows;",
    "support cells remain point_fit/planned/planned unless separately promoted."
  )
  closure$next_action[closure_hit] <- paste(
    "Do not top up animal q1 mu or q1 sigma blocked routes; keep q2 repair,",
    "q1 sigma route design, and animal q1 mu interval-route design separate."
  )
  closure$promotion_boundary[closure_hit] <- paste(
    "Animal q1 mu hard-seed replay is not interval_status, coverage_status,",
    "inference_ready, supported, q1 sigma, q2, q4/q8, non-Gaussian interval,",
    "REML, AI-REML, bridge, or public support."
  )

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

  version_path <- file.path(dashboard_dir, "version.txt")
  version <- trimws(readLines(version_path, warn = FALSE)[1L])
  version_num <- suppressWarnings(as.integer(sub("^r", "", version)))
  if (is.finite(version_num)) {
    writeLines(paste0("r", version_num + 1L), version_path)
  }
}

message("Wrote animal q1 mu boundary-profile review to ", summary_path)
if (sync_dashboard) {
  message("Synchronized animal q1 mu boundary-profile blocker across dashboard TSVs.")
}
