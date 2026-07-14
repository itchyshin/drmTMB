#!/usr/bin/env Rscript

# Fail-closed Arc 3a certification combiner and gate evaluator.
# Raw shard outputs remain local. This script emits compact, reviewable tables.

`%||%` <- function(x, y) if (is.null(x)) y else x

parse_args <- function(args) {
  out <- list(input_dir = NULL, output_dir = NULL, bootstrap_reps = 2000L)
  for (arg in args) {
    if (startsWith(arg, "--input-dir=")) {
      out$input_dir <- sub("^--input-dir=", "", arg)
    } else if (startsWith(arg, "--output-dir=")) {
      out$output_dir <- sub("^--output-dir=", "", arg)
    } else if (startsWith(arg, "--bootstrap-reps=")) {
      out$bootstrap_reps <- as.integer(sub("^--bootstrap-reps=", "", arg))
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (is.null(out$input_dir) || is.null(out$output_dir)) {
    stop("--input-dir and --output-dir are required", call. = FALSE)
  }
  if (is.na(out$bootstrap_reps) || out$bootstrap_reps < 200L) {
    stop("--bootstrap-reps must be at least 200", call. = FALSE)
  }
  out
}

sha256_file <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  command_args <- if (identical(command, "shasum")) c("-a", "256", path) else path
  out <- system2(command, command_args, stdout = TRUE, stderr = TRUE)
  token <- strsplit(out[[1L]], "[[:space:]]+")[[1L]][[1L]]
  if (!grepl("^[0-9a-fA-F]{64}$", token)) stop("Could not hash ", path, call. = FALSE)
  tolower(token)
}

write_tsv <- function(x, path) {
  utils::write.table(
    x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA"
  )
}

safe_rate <- function(x, denominator) sum(x %in% TRUE, na.rm = TRUE) / denominator
truth_for <- c(
  estimate_beta0 = 0.20,
  estimate_beta_x = 0.35,
  estimate_beta_sigma = log(0.35),
  estimate_tau = 0.50
)

args <- parse_args(commandArgs(trailingOnly = TRUE))
input_dir <- normalizePath(args$input_dir, mustWork = TRUE)
output_dir <- normalizePath(args$output_dir, mustWork = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
if (length(list.files(output_dir, all.files = TRUE, no.. = TRUE))) {
  stop("Refusing to write into non-empty output directory: ", output_dir, call. = FALSE)
}

raw_files <- sort(list.files(
  input_dir, pattern = "^raw-shard-[0-9]+\\.tsv$", full.names = TRUE
))
if (!length(raw_files)) stop("No raw-shard-N.tsv inputs found", call. = FALSE)
shards <- lapply(raw_files, utils::read.delim, stringsAsFactors = FALSE, check.names = FALSE)
raw <- do.call(rbind, shards)

required <- c(
  "campaign_id", "source_commit_sha", "source_dirty", "host", "phase",
  "shard_index", "shard_count", "global_fit_index", "fit_route", "dgp_cell",
  "family", "provider", "representation", "M", "replicate", "dgp_seed",
  "fit_key", "attempted", "fit_success", "analysis_success", "failure_stage",
  "convergence_code", "pdHess", "boundary", "gross_sigma", "objective",
  names(truth_for), "prediction_identity_max_abs_error",
  "conditional_field_rmse", "conditional_field_correlation",
  "field_level_names", "estimate_field_values", "session_manifest_hash"
)
missing <- setdiff(required, names(raw))
if (length(missing)) stop("Raw inputs lack columns: ", paste(missing, collapse = ", "), call. = FALSE)

expected_routes <- c(
  "gamma_phylo", "lognormal_phylo", "lognormal_relmat_K",
  "lognormal_relmat_Q", "gamma_relmat_K"
)
expected_M <- c(16L, 32L, 64L)
expected_rows <- length(expected_routes) * length(expected_M) * 400L
assert <- function(ok, message) if (!isTRUE(ok)) stop(message, call. = FALSE)
assert(nrow(raw) == expected_rows, paste("Expected", expected_rows, "rows; got", nrow(raw)))
assert(!anyDuplicated(raw$fit_key), "Duplicate immutable fit keys")
assert(!anyDuplicated(raw$global_fit_index), "Duplicate global fit indices")
assert(identical(sort(as.integer(raw$global_fit_index)), seq_len(expected_rows)), "Missing global fit indices")
assert(all(raw$attempted %in% TRUE), "At least one scheduled attempt is missing")
assert(identical(sort(unique(raw$fit_route)), sort(expected_routes)), "Route set differs from frozen manifest")
assert(identical(sort(unique(as.integer(raw$M))), expected_M), "M ladder differs from frozen manifest")
assert(all(raw$replicate %in% seq_len(400L)), "Replicate index outside 1:400")
assert(all(raw$phase == "certification"), "Non-certification rows entered the combiner")
assert(length(unique(raw$source_commit_sha)) == 1L, "Multiple source commits in raw inputs")
assert(!any(raw$source_dirty %in% TRUE), "A dirty source checkout entered certification")
assert(length(unique(raw$shard_count)) == 1L, "Shard-count mismatch")
shard_count <- unique(raw$shard_count)[[1L]]
assert(identical(sort(unique(as.integer(raw$shard_index))), seq_len(shard_count)), "Missing shard index")
assert(all(is.finite(raw$prediction_identity_max_abs_error[raw$analysis_success %in% TRUE])), "Nonfinite scale identity")
assert(all(raw$prediction_identity_max_abs_error[raw$analysis_success %in% TRUE] <= 1e-8), "Scale identity tolerance failure")

raw <- raw[order(raw$global_fit_index), , drop = FALSE]
combined_raw <- file.path(output_dir, "arc3a-certification-combined-raw.tsv")
write_tsv(raw, combined_raw)

route_summary <- do.call(rbind, lapply(expected_routes, function(route) {
  do.call(rbind, lapply(expected_M, function(M) {
    z <- raw[raw$fit_route == route & raw$M == M, , drop = FALSE]
    data.frame(
      fit_route = route,
      M = M,
      attempted = nrow(z),
      fit_success = sum(z$fit_success %in% TRUE),
      analysis_success = sum(z$analysis_success %in% TRUE),
      convergence_zero = sum(z$convergence_code == 0L, na.rm = TRUE),
      pdHess = sum(z$pdHess %in% TRUE),
      boundary = sum(z$boundary %in% TRUE),
      gross_sigma = sum(z$gross_sigma %in% TRUE),
      field_correlation_median = stats::median(z$conditional_field_correlation[z$analysis_success %in% TRUE], na.rm = TRUE),
      field_rmse_median = stats::median(z$conditional_field_rmse[z$analysis_success %in% TRUE], na.rm = TRUE),
      fit_gate = sum(z$fit_success %in% TRUE) >= 380L,
      pdHess_gate = sum(z$pdHess %in% TRUE) >= 380L,
      boundary_gate = sum(z$boundary %in% TRUE) <= 8L,
      gross_sigma_gate = sum(z$gross_sigma %in% TRUE) <= 8L,
      field_gate = stats::median(z$conditional_field_correlation[z$analysis_success %in% TRUE], na.rm = TRUE) >= 0.80 &&
        stats::median(z$conditional_field_rmse[z$analysis_success %in% TRUE], na.rm = TRUE) <= 0.25,
      stringsAsFactors = FALSE
    )
  }))
}))

summary_seed <- 2026071417L
target_summary <- do.call(rbind, lapply(expected_routes, function(route) {
  do.call(rbind, lapply(expected_M, function(M) {
    z <- raw[raw$fit_route == route & raw$M == M, , drop = FALSE]
    do.call(rbind, lapply(names(truth_for), function(target) {
      estimates <- z[[target]][z$analysis_success %in% TRUE & is.finite(z[[target]])]
      truth <- unname(truth_for[[target]])
      errors <- estimates - truth
      set.seed(summary_seed + match(route, expected_routes) * 100L + M + match(target, names(truth_for)))
      boot_rmse <- replicate(
        args$bootstrap_reps,
        sqrt(mean(sample(errors, length(errors), replace = TRUE)^2))
      )
      data.frame(
        fit_route = route,
        M = M,
        target = sub("^estimate_", "", target),
        truth = truth,
        attempts = nrow(z),
        conditional_n = length(estimates),
        bias = mean(errors),
        bias_mcse = stats::sd(errors) / sqrt(length(errors)),
        rmse = sqrt(mean(errors^2)),
        rmse_mcse_bootstrap = stats::sd(boot_rmse),
        stringsAsFactors = FALSE
      )
    }))
  }))
}))

split_values <- function(x) as.numeric(strsplit(x, ";", fixed = TRUE)[[1L]])
parity_rows <- do.call(rbind, lapply(expected_M, function(M) {
  K <- raw[raw$fit_route == "lognormal_relmat_K" & raw$M == M, , drop = FALSE]
  Q <- raw[raw$fit_route == "lognormal_relmat_Q" & raw$M == M, , drop = FALSE]
  pair <- merge(K, Q, by = c("M", "replicate", "dgp_seed"), suffixes = c("_K", "_Q"), sort = TRUE)
  assert(nrow(pair) == 400L, paste("K/Q pairing incomplete at M=", M))
  joint <- pair$analysis_success_K %in% TRUE & pair$analysis_success_Q %in% TRUE
  mismatch <- xor(pair$analysis_success_K %in% TRUE, pair$analysis_success_Q %in% TRUE)
  objective_delta <- abs(pair$objective_K - pair$objective_Q)
  fixed_delta <- pmax(
    abs(pair$estimate_beta0_K - pair$estimate_beta0_Q),
    abs(pair$estimate_beta_x_K - pair$estimate_beta_x_Q),
    abs(pair$estimate_beta_sigma_K - pair$estimate_beta_sigma_Q)
  )
  tau_delta <- abs(pair$estimate_tau_K - pair$estimate_tau_Q)
  field_delta <- rep(NA_real_, nrow(pair))
  for (i in which(joint)) {
    k_names <- strsplit(pair$field_level_names_K[[i]], ";", fixed = TRUE)[[1L]]
    q_names <- strsplit(pair$field_level_names_Q[[i]], ";", fixed = TRUE)[[1L]]
    k <- stats::setNames(split_values(pair$estimate_field_values_K[[i]]), k_names)
    q <- stats::setNames(split_values(pair$estimate_field_values_Q[[i]]), q_names)
    assert(identical(sort(names(k)), sort(names(q))), "K/Q conditional-field level mismatch")
    field_delta[[i]] <- max(abs(k[sort(names(k))] - q[sort(names(q))]))
  }
  failures <- joint & (
    objective_delta > 1e-6 | fixed_delta > 1e-5 |
      tau_delta > 1e-5 | field_delta > 1e-4
  )
  data.frame(
    M = M,
    attempts = nrow(pair),
    jointly_analysis_successful = sum(joint),
    success_status_mismatch = sum(mismatch),
    objective_delta_max = max(objective_delta[joint], na.rm = TRUE),
    fixed_delta_max = max(fixed_delta[joint], na.rm = TRUE),
    tau_delta_max = max(tau_delta[joint], na.rm = TRUE),
    field_delta_max = max(field_delta[joint], na.rm = TRUE),
    tolerance_failures = sum(failures, na.rm = TRUE),
    availability_gate = sum(joint) >= 380L && sum(mismatch) <= 4L,
    numerical_gate = sum(failures, na.rm = TRUE) == 0L,
    stringsAsFactors = FALSE
  )
}))

route_decision <- do.call(rbind, lapply(expected_routes, function(route) {
  rs <- route_summary[route_summary$fit_route == route, , drop = FALSE]
  ts <- target_summary[target_summary$fit_route == route, , drop = FALSE]
  final <- ts[ts$M == 64L, , drop = FALSE]
  early <- ts[ts$M == 16L, c("target", "rmse"), drop = FALSE]
  names(early)[[2L]] <- "rmse_M16"
  final <- merge(final, early, by = "target", all.x = TRUE, sort = FALSE)
  fixed <- final$target != "tau"
  bias_gate <- all(abs(final$bias[fixed]) <= 0.05) && all(abs(final$bias[!fixed]) <= 0.075)
  rmse_gate <- all(final$rmse[fixed] <= 0.12) && all(final$rmse[!fixed] <= 0.125)
  information_gate <- all(final$rmse[fixed] <= final$rmse_M16[fixed]) &&
    all(final$rmse[!fixed] <= 0.85 * final$rmse_M16[!fixed])
  mcse_gate <- all(final$bias_mcse <= 0.025) && all(final$rmse_mcse_bootstrap <= 0.025)
  nonparity_gate <- all(rs$fit_gate & rs$pdHess_gate & rs$boundary_gate & rs$gross_sigma_gate & rs$field_gate) &&
    bias_gate && rmse_gate && information_gate && mcse_gate
  data.frame(
    fit_route = route,
    rung_gates = all(rs$fit_gate & rs$pdHess_gate & rs$boundary_gate & rs$gross_sigma_gate & rs$field_gate),
    final_bias_gate = bias_gate,
    final_rmse_gate = rmse_gate,
    information_response_gate = information_gate,
    mcse_gate = mcse_gate,
    nonparity_pass = nonparity_gate,
    stringsAsFactors = FALSE
  )
}))

route_pass <- stats::setNames(route_decision$nonparity_pass, route_decision$fit_route)
parity_pass <- all(parity_rows$availability_gate & parity_rows$numerical_gate)
cell_decision <- data.frame(
  cell = c("gamma_phylo", "lognormal_phylo", "lognormal_relmat", "gamma_relmat_comparator"),
  prior_state = c("implemented", "implemented", "implemented", "point_fit_recovery"),
  certification_pass = c(
    route_pass[["gamma_phylo"]],
    route_pass[["lognormal_phylo"]],
    route_pass[["lognormal_relmat_K"]] && route_pass[["lognormal_relmat_Q"]] && parity_pass,
    route_pass[["gamma_relmat_K"]]
  ),
  resulting_state = NA_character_,
  stringsAsFactors = FALSE
)
cell_decision$resulting_state <- ifelse(
  cell_decision$certification_pass,
  "point_fit_recovery",
  cell_decision$prior_state
)

failure_stage <- as.data.frame(table(raw$fit_route, raw$M, raw$failure_stage), stringsAsFactors = FALSE)
names(failure_stage) <- c("fit_route", "M", "failure_stage", "count")
failure_stage <- failure_stage[failure_stage$count > 0L, , drop = FALSE]

paths <- c(
  route_summary = file.path(output_dir, "route-rung-summary.tsv"),
  target_summary = file.path(output_dir, "target-recovery-summary.tsv"),
  parity_summary = file.path(output_dir, "kq-parity-summary.tsv"),
  route_decision = file.path(output_dir, "route-decisions.tsv"),
  cell_decision = file.path(output_dir, "cell-decisions.tsv"),
  failure_stage = file.path(output_dir, "failure-stage-counts.tsv")
)
write_tsv(route_summary, paths[["route_summary"]])
write_tsv(target_summary, paths[["target_summary"]])
write_tsv(parity_rows, paths[["parity_summary"]])
write_tsv(route_decision, paths[["route_decision"]])
write_tsv(cell_decision, paths[["cell_decision"]])
write_tsv(failure_stage, paths[["failure_stage"]])

manifest_path <- file.path(output_dir, "summary-manifest.txt")
manifest <- c(
  "campaign_id=arc3a_positive_continuous_structured_mu_20260714",
  paste0("source_commit_sha=", unique(raw$source_commit_sha)),
  paste0("hosts=", paste(sort(unique(raw$host)), collapse = ",")),
  paste0("worker_count=", shard_count),
  paste0("attempted_rows=", nrow(raw)),
  paste0("fit_success=", sum(raw$fit_success %in% TRUE)),
  paste0("analysis_success=", sum(raw$analysis_success %in% TRUE)),
  paste0("summary_seed=", summary_seed),
  paste0("bootstrap_reps=", args$bootstrap_reps),
  paste0("combined_raw_sha256=", sha256_file(combined_raw)),
  vapply(names(paths), function(name) paste0(name, "_sha256=", sha256_file(paths[[name]])), character(1)),
  paste0("all_new_cells_pass=", all(cell_decision$certification_pass[cell_decision$cell != "gamma_relmat_comparator"])),
  paste0("comparator_pass=", cell_decision$certification_pass[cell_decision$cell == "gamma_relmat_comparator"]),
  paste0("kq_parity_pass=", parity_pass),
  capture.output(sessionInfo())
)
writeLines(manifest, manifest_path)

message("combined_raw=", combined_raw)
message("combined_raw_sha256=", sha256_file(combined_raw))
message("summary_manifest=", manifest_path)
message("cell_decisions:")
print(cell_decision, row.names = FALSE)
