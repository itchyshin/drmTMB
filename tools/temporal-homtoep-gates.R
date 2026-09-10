#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || args[[1L]] != "T3-2") {
  stop("Only `T3-2` is implemented in this runner. Other gates remain pending.", call. = FALSE)
}

source("tools/temporal-homtoep-map-study.R")
result <- homtoep_map_study()
if (result$draws != 480L ||
    result$minimum_eigenvalue <= 1e-13 ||
    result$derivative_difference >= 1e-4 ||
    result$lagwise_counterexample_minimum_eigenvalue >= 0 ||
    result$generic_cholesky_toeplitz_deviation <= 1e-3) {
  stop("T3-2 map study did not satisfy its prespecified acceptance criteria.", call. = FALSE)
}

eta <- c(-1.3, 0.2, 1.1, -0.7, 0.4)
rho <- homtoep_reflection_rho(eta)
if (max(abs(homtoep_eta_from_rho(rho) - eta)) >= 1e-10 ||
    max(abs(homtoep_reflection_cor(eta) - homtoep_dense_from_lags(rho))) >= 1e-13 ||
    max(abs(homtoep_reflection_cor(eta) - stats::toeplitz(rho))) >= 1e-13) {
  stop("T3-2 reconstruction or dense-reference check failed.", call. = FALSE)
}

cat("TEMPORAL_HOMTOEP_T3_2_PASS\n")
