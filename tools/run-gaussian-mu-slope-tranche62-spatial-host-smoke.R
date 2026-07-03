#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || is.na(x)) y else x
}

print_help <- function() {
  cat(
    paste(
      "Usage: Rscript tools/run-gaussian-mu-slope-tranche62-spatial-host-smoke.R [options]",
      "",
      "Tranche 62 dry-run gate for the q1 mu one-slope spatial host smoke.",
      "This script validates the future n=5 retained-denominator smoke packet",
      "and prints a manifest. It does not fit models, run host commands, write",
      "dashboard results, or create denominator evidence.",
      "",
      "Options:",
      "  --mode=dry-run              Only dry-run is allowed in Tranche 62.",
      "  --provider=spatial          Only spatial is allowed.",
      "  --target=both|mu_intercept|mu_x",
      "                              Direct-SD target set; default: both.",
      "  --n-rep=5                   Required retained-denominator smoke size.",
      "  --seeds=861001,...,861005   Required seed manifest.",
      "  --host-label=LABEL          Host label for future provenance.",
      "  --write-dashboard=false     Dashboard writes are forbidden.",
      "  --execution-approved=false  Execution is forbidden in Tranche 62.",
      "  --help, -h                  Print this help.",
      "",
      "Boundary: dry-run only, no host command, no fit, no new denominator,",
      "no coverage, no promotion, and no support-cell status edit.",
      sep = "\n"
    ),
    "\n"
  )
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  print_help()
  quit(status = 0)
}

arg_value <- function(name, default = NULL) {
  eq_prefix <- paste0("--", name, "=")
  eq_hit <- grep(paste0("^", eq_prefix), args, value = TRUE)
  if (length(eq_hit) > 0L) {
    return(sub(eq_prefix, "", eq_hit[[length(eq_hit)]], fixed = TRUE))
  }
  key <- paste0("--", name)
  key_index <- which(args == key)
  if (length(key_index) == 0L) {
    return(default)
  }
  value_index <- key_index[[length(key_index)]] + 1L
  if (value_index > length(args) || startsWith(args[[value_index]], "--")) {
    return(default)
  }
  args[[value_index]]
}

arg_bool <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
}

clean_ascii <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_stdout_tsv <- function(x) {
  char_cols <- vapply(x, is.character, logical(1L))
  x[char_cols] <- lapply(x[char_cols], clean_ascii)
  utils::write.table(
    x,
    file = stdout(),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

mode <- gsub("_", "-", tolower(arg_value("mode", "dry-run")), fixed = TRUE)
provider <- tolower(arg_value("provider", "spatial"))
target <- tolower(arg_value("target", "both"))
n_rep <- as.integer(arg_value("n-rep", "5"))
seeds <- as.integer(strsplit(arg_value(
  "seeds",
  "861001,861002,861003,861004,861005"
), ",", fixed = TRUE)[[1L]])
host_label <- clean_ascii(arg_value("host-label", "local_dry_run_only"))
write_dashboard <- arg_bool("write-dashboard", FALSE)
execution_approved <- arg_bool("execution-approved", FALSE)

expected_seeds <- 861001:861005
if (!identical(provider, "spatial")) {
  stop("Tranche 62 is spatial-only; use --provider=spatial.", call. = FALSE)
}
if (!target %in% c("both", "mu_intercept", "mu_x")) {
  stop("`--target` must be both, mu_intercept, or mu_x.", call. = FALSE)
}
if (!identical(n_rep, 5L)) {
  stop("Tranche 62 is fixed at --n-rep=5.", call. = FALSE)
}
if (!identical(seeds, expected_seeds)) {
  stop(
    "Tranche 62 seed manifest must be 861001,861002,861003,861004,861005.",
    call. = FALSE
  )
}
if (isTRUE(write_dashboard)) {
  stop(
    "Tranche 62 dry-run gate cannot write dashboard results; use --write-dashboard=false.",
    call. = FALSE
  )
}
if (!identical(mode, "dry-run")) {
  stop("Tranche 62 allows dry-run only; host execution is not implemented.", call. = FALSE)
}
if (isTRUE(execution_approved)) {
  stop(
    "Tranche 62 refuses execution even with an approval flag; review and checkpoint first.",
    call. = FALSE
  )
}
if (nzchar(Sys.getenv("DRMTMB_QSERIES_T62_EXECUTE", unset = ""))) {
  stop(
    "DRMTMB_QSERIES_T62_EXECUTE is not accepted in Tranche 62; dry-run only.",
    call. = FALSE
  )
}

targets <- switch(
  target,
  both = c("mu_intercept", "mu_x"),
  mu_intercept = "mu_intercept",
  mu_x = "mu_x"
)
target_members <- c(mu_intercept = "mu:(Intercept)", mu_x = "mu:x")
direct_sd_targets <- c(mu_intercept = "sd_mu_intercept", mu_x = "sd_mu_x")

manifest <- do.call(
  rbind,
  lapply(targets, function(target_id) {
    data.frame(
      dry_run_id = paste0(
        "tranche62_spatial_",
        target_id,
        "_seed_",
        expected_seeds
      ),
      provider = "spatial",
      target = target_id,
      endpoint_member = target_members[[target_id]],
      direct_sd_target = direct_sd_targets[[target_id]],
      replicate_index = seq_along(expected_seeds),
      seed = expected_seeds,
      host_label = host_label,
      execution_status = "dry_run_only_no_fit_no_host_command",
      denominator_status = "no_new_denominator",
      coverage_decision = "coverage_not_authorized",
      promotion_decision = "do_not_promote",
      support_cell_decision = "unchanged_point_fit_planned_planned",
      claim_boundary = paste(
        "Tranche 62 dry-run manifest only; no fit; no host command;",
        "no new denominator; no coverage; no inference_ready; no supported."
      ),
      stringsAsFactors = FALSE
    )
  })
)

write_stdout_tsv(manifest)
