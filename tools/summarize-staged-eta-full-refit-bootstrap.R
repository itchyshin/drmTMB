#!/usr/bin/env Rscript
# Fail-closed aggregation for the immutable staged-eta DRAC array.  A missing
# outer shard becomes an explicit unavailable interval in the all-attempt
# denominator; this script never silently drops it.

args <- commandArgs(trailingOnly = TRUE)
run_root_flag <- "--run-root="
run_root_arg <- args[startsWith(args, run_root_flag)]
if (length(run_root_arg) != 1L) stop("Supply exactly one --run-root=/project/... argument.")
run_root <- normalizePath(sub(run_root_flag, "", run_root_arg), mustWork = TRUE)

suppressPackageStartupMessages(library(drmTMB))

design <- expand.grid(
  n = c(120L, 240L, 480L),
  binary_intercept = c(-1.4, -0.2),
  nbinom2_sigma = c(0.25, 0.65),
  alpha_setting = c("null", "slope"),
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
)
design$alpha0 <- ifelse(design$alpha_setting == "null", 0, -0.15)
design$alpha1 <- ifelse(design$alpha_setting == "null", 0, 0.65)
design$cell_id <- sprintf("staged_eta_%02d", seq_len(nrow(design)))
design$design_index <- seq_len(nrow(design))

missing_outer <- function(cell, outer_index) {
  data.frame(
    cell_id = cell$cell_id, outer_index = outer_index,
    seed = 2026072400L + 100000L * cell$design_index + outer_index,
    bootstrap_seed = NA_integer_, outer_status = "missing_shard",
    interval_available = FALSE, resolved_bootstrap = 0L,
    bootstrap_attempts = 399L,
    alpha0_estimate = NA_real_, alpha1_estimate = NA_real_,
    alpha0_lower = NA_real_, alpha0_upper = NA_real_,
    alpha1_lower = NA_real_, alpha1_upper = NA_real_,
    eta_m1_estimate = NA_real_, eta_m1_lower = NA_real_, eta_m1_upper = NA_real_,
    eta_0_estimate = NA_real_, eta_0_lower = NA_real_, eta_0_upper = NA_real_,
    eta_1_estimate = NA_real_, eta_1_lower = NA_real_, eta_1_upper = NA_real_,
    message = "No completed outer-shard ledger was found.", stringsAsFactors = FALSE
  )
}

outer_rows <- list()
bootstrap_rows <- list()
diagnostics_index <- list()
index <- 0L
for (i in seq_len(nrow(design))) {
  cell <- design[i, ]
  for (outer_index in seq_len(200L)) {
    index <- index + 1L
    shard <- file.path(run_root, "results", cell$cell_id, sprintf("outer_%03d", outer_index))
    outer_path <- file.path(shard, "staged-eta-outer-attempts.csv")
    bootstrap_path <- file.path(shard, "staged-eta-bootstrap-attempts.csv")
    diagnostic_path <- file.path(shard, "staged-eta-bootstrap-diagnostics.rds")
    if (file.exists(outer_path)) {
      outer <- utils::read.csv(outer_path, stringsAsFactors = FALSE, check.names = FALSE)
      if (nrow(outer) != 1L || !identical(outer$cell_id[[1L]], cell$cell_id) ||
          !identical(as.integer(outer$outer_index[[1L]]), outer_index)) {
        stop("Malformed or mismatched outer ledger: ", outer_path)
      }
      outer_rows[[index]] <- outer
    } else {
      outer_rows[[index]] <- missing_outer(cell, outer_index)
    }
    if (file.exists(bootstrap_path)) {
      bootstrap <- utils::read.csv(bootstrap_path, stringsAsFactors = FALSE, check.names = FALSE)
      bootstrap$cell_id <- cell$cell_id
      bootstrap$outer_index <- outer_index
      bootstrap_rows[[index]] <- bootstrap
    }
    diagnostics_index[[index]] <- data.frame(
      cell_id = cell$cell_id, outer_index = outer_index,
      diagnostic_path = diagnostic_path, present = file.exists(diagnostic_path),
      stringsAsFactors = FALSE
    )
  }
}

outer_attempts <- do.call(rbind, outer_rows)
bootstrap_attempts <- do.call(rbind, Filter(Negate(is.null), bootstrap_rows))
diagnostics_index <- do.call(rbind, diagnostics_index)
truth <- c(alpha0 = 0, alpha1 = 0, eta_m1 = 0, eta_0 = 0, eta_1 = 0)
summaries <- do.call(rbind, lapply(seq_len(nrow(design)), function(i) {
  cell <- design[i, ]
  truth[c("alpha0", "alpha1")] <- c(cell$alpha0, cell$alpha1)
  truth[c("eta_m1", "eta_0", "eta_1")] <- 0.999999 * tanh(cell$alpha0 + cell$alpha1 * c(-1, 0, 1))
  cbind(cell[rep(1L, 5L), ],
    drmTMB:::drm_pair_staged_eta_coverage_summary(
      outer_attempts[outer_attempts$cell_id == cell$cell_id, ], truth,
      minimum_resolved = 380L
    ))
}))

aggregate_dir <- file.path(run_root, "aggregate")
dir.create(aggregate_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(outer_attempts, file.path(aggregate_dir, "staged-eta-outer-attempts.csv"), row.names = FALSE)
utils::write.csv(bootstrap_attempts, file.path(aggregate_dir, "staged-eta-bootstrap-attempts.csv"), row.names = FALSE)
utils::write.csv(diagnostics_index, file.path(aggregate_dir, "staged-eta-bootstrap-diagnostics-index.csv"), row.names = FALSE)
utils::write.csv(summaries, file.path(aggregate_dir, "staged-eta-summary.csv"), row.names = FALSE)

if (nrow(outer_attempts) != 4800L) stop("Aggregation must retain exactly 4,800 all-attempt outer rows.")
