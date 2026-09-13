#!/usr/bin/env Rscript
out <- "docs/dev-log/evidence/ou-v1-r32"
mode <- commandArgs(trailingOnly = TRUE)
if (identical(mode, "--preflight")) {
  x <- utils::read.csv(file.path(out, "preflight.csv")); stopifnot(nrow(x) == 1L, isTRUE(x$within_three_hours), is.finite(x$projected_grid_seconds)); cat("OU_V1_R32_PREFLIGHT_PASS\n")
} else if (identical(mode, "--convergence")) {
  x <- utils::read.csv(file.path(out, "convergence.csv")); stopifnot(nrow(x) == 1L, all(is.finite(as.matrix(x[, 3:7])))); cat("OU_V1_R32_CONVERGENCE_PASS\n")
} else {
  x <- utils::read.csv(file.path(out, "comparison.csv")); nums <- c("alpha_mu", "alpha_sigma", "sd_mu", "sd_sigma", "mu", "logsigma", "laplace", "quadrature9", "laplace_minus_q9", "laplace_rank", "quadrature_rank")
  stopifnot(nrow(x) == 4L, identical(x$rate_id, rep(c("interior", "ridge"), each = 2L)), all(is.finite(as.matrix(x[, nums]))), all(is.finite(x$quadrature5)), all(is.finite(x$quadrature7)), all(is.finite(x$refinement_7_9)))
  cat("OU_V1_R32_PASS\n")
}
