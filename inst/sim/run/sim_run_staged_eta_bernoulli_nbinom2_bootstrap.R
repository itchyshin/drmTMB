#!/usr/bin/env Rscript
#
# Immutable full-refit bootstrap feasibility ladder for the staged Bernoulli x
# ordinary-NB2 association-link estimator. This developer-only runner has no
# public API consequence. It is deliberately disabled until a separately
# approved smoke, and the full grid belongs on DRAC rather than GitHub Actions.

if (!identical(Sys.getenv("RUN_STAGED_ETA_BOOTSTRAP"), "true")) {
  stop("Execution is disabled. Obtain smoke/compute approval, then set RUN_STAGED_ETA_BOOTSTRAP=true.")
}

suppressPackageStartupMessages(library(drmTMB))

SMOKE <- identical(Sys.getenv("SMOKE"), "true")
OUTER_ATTEMPTS <- if (SMOKE) 2L else 200L
BOOTSTRAP_ATTEMPTS <- if (SMOKE) 5L else 399L
MINIMUM_RESOLVED <- if (SMOKE) 3L else 380L
OUTDIR <- Sys.getenv("OUTDIR", unset = "")
if (!nzchar(OUTDIR)) stop("Set OUTDIR to an existing output directory.")
if (!dir.exists(OUTDIR)) stop("OUTDIR must already exist.")
OUTDIR <- normalizePath(OUTDIR, mustWork = TRUE)
CELL_ID <- Sys.getenv("STAGED_ETA_CELL_ID", unset = "")
OUTER_INDEX <- suppressWarnings(as.integer(Sys.getenv("STAGED_ETA_OUTER_INDEX", unset = "")))

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
if (nrow(design) != 24L) stop("The staged-eta design must have exactly 24 cells.")
if (SMOKE) {
  # A visible executable check, not an evidence cell: one regular slope cell,
  # two outer attempts, and five full refits per outer attempt.
  design <- design[design$cell_id == "staged_eta_17", , drop = FALSE]
}
if (nzchar(CELL_ID)) {
  design <- design[design$cell_id == CELL_ID, , drop = FALSE]
  if (nrow(design) != 1L) stop("STAGED_ETA_CELL_ID must select exactly one immutable design cell.")
}
if (!is.na(OUTER_INDEX) && (OUTER_INDEX < 1L || OUTER_INDEX > OUTER_ATTEMPTS)) {
  stop("STAGED_ETA_OUTER_INDEX must select one declared outer attempt.")
}

binomial_interval <- function(success, total) {
  if (!is.finite(success) || total < 1L) return(c(lower = NA_real_, upper = NA_real_))
  stats::binom.test(success, total)$conf.int
}

make_outer_data <- function(cell, seed) {
  set.seed(seed)
  x <- seq(-1.4, 1.4, length.out = cell$n)
  p <- stats::plogis(cell$binary_intercept + 0.3 * x)
  mu <- exp(0.7 + 0.2 * x)
  sigma <- rep(cell$nbinom2_sigma, cell$n)
  eta <- 0.999999 * tanh(cell$alpha0 + cell$alpha1 * x)
  draw <- drmTMB:::drm_pair_simulate_bernoulli_nbinom2(p, mu, sigma, eta)
  data.frame(x = x, binary = draw$bernoulli, count = draw$nbinom2)
}

one_outer_attempt <- function(cell, outer_index, seed) {
  data <- make_outer_data(cell, seed)
  bootstrap_seed <- seed + 100000000L
  result <- drmTMB:::drm_pair_full_refit_bootstrap(
    data = data, binary_response = "binary", nbinom2_response = "count",
    binary_formula = bf(mu = binary ~ x),
    nbinom2_formula = bf(mu = count ~ x, sigma = ~1),
    association = ~x, attempts = BOOTSTRAP_ATTEMPTS,
    minimum_resolved = MINIMUM_RESOLVED, seed = bootstrap_seed
  )
  outer <- data.frame(
    cell_id = cell$cell_id, outer_index = outer_index, seed = seed,
    bootstrap_seed = bootstrap_seed, outer_status = result$outer_status,
    interval_available = FALSE, resolved_bootstrap = 0L,
    bootstrap_attempts = BOOTSTRAP_ATTEMPTS,
    alpha0_estimate = NA_real_, alpha1_estimate = NA_real_,
    alpha0_lower = NA_real_, alpha0_upper = NA_real_,
    alpha1_lower = NA_real_, alpha1_upper = NA_real_,
    eta_m1_estimate = NA_real_, eta_m1_lower = NA_real_, eta_m1_upper = NA_real_,
    eta_0_estimate = NA_real_, eta_0_lower = NA_real_, eta_0_upper = NA_real_,
    eta_1_estimate = NA_real_, eta_1_lower = NA_real_, eta_1_upper = NA_real_,
    message = result$outer_message, stringsAsFactors = FALSE
  )
  if (!identical(result$outer_status, "interior") && !identical(result$outer_status, "near_boundary")) {
    return(list(outer = outer, bootstrap = result$attempts, diagnostics = result$diagnostics))
  }
  alpha <- result$outer$association_coefficients
  outer$alpha0_estimate <- alpha[["(Intercept)"]]
  outer$alpha1_estimate <- alpha[["x"]]
  eta_at <- function(coefficients, x) 0.999999 * tanh(coefficients[[1L]] + coefficients[[2L]] * x)
  outer$eta_m1_estimate <- eta_at(alpha, -1)
  outer$eta_0_estimate <- eta_at(alpha, 0)
  outer$eta_1_estimate <- eta_at(alpha, 1)
  resolved <- result$attempts$resolved
  outer$resolved_bootstrap <- sum(resolved)
  outer$interval_available <- identical(result$interval_available, TRUE)
  if (outer$interval_available) {
    draws <- result$attempts[resolved, c("alpha_X.Intercept.", "alpha_x"), drop = FALSE]
    names(draws) <- c("alpha0", "alpha1")
    alpha_quantiles <- lapply(draws, stats::quantile, probs = c(0.025, 0.975), names = FALSE)
    outer$alpha0_lower <- alpha_quantiles$alpha0[[1L]]
    outer$alpha0_upper <- alpha_quantiles$alpha0[[2L]]
    outer$alpha1_lower <- alpha_quantiles$alpha1[[1L]]
    outer$alpha1_upper <- alpha_quantiles$alpha1[[2L]]
    for (x in c(-1, 0, 1)) {
      eta_draw <- 0.999999 * tanh(draws$alpha0 + draws$alpha1 * x)
      interval <- stats::quantile(eta_draw, probs = c(0.025, 0.975), names = FALSE)
      prefix <- if (x == -1) "eta_m1" else if (x == 0) "eta_0" else "eta_1"
      outer[[paste0(prefix, "_lower")]] <- interval[[1L]]
      outer[[paste0(prefix, "_upper")]] <- interval[[2L]]
    }
  }
  list(outer = outer, bootstrap = result$attempts, diagnostics = result$diagnostics)
}

task_grid <- do.call(rbind, lapply(seq_len(nrow(design)), function(i) {
  cell <- design[i, ]
  data.frame(cell_id = cell$cell_id, outer_index = seq_len(OUTER_ATTEMPTS),
    seed = 2026072400L + 100000L * cell$design_index + seq_len(OUTER_ATTEMPTS))
}))
if (!is.na(OUTER_INDEX)) {
  task_grid <- task_grid[task_grid$outer_index == OUTER_INDEX, , drop = FALSE]
  if (nrow(task_grid) != 1L) stop("The selected cell and outer attempt do not define one task.")
}
results <- lapply(seq_len(nrow(task_grid)), function(i) {
  cell <- design[match(task_grid$cell_id[[i]], design$cell_id), ]
  one_outer_attempt(cell, task_grid$outer_index[[i]], task_grid$seed[[i]])
})
outer_attempts <- do.call(rbind, lapply(results, `[[`, "outer"))
bootstrap_attempts <- do.call(rbind, lapply(results, `[[`, "bootstrap"))
diagnostics <- lapply(results, `[[`, "diagnostics")
utils::write.csv(outer_attempts, file.path(OUTDIR, "staged-eta-outer-attempts.csv"), row.names = FALSE)
utils::write.csv(bootstrap_attempts, file.path(OUTDIR, "staged-eta-bootstrap-attempts.csv"), row.names = FALSE)
saveRDS(diagnostics, file.path(OUTDIR, "staged-eta-bootstrap-diagnostics.rds"), version = 3)

truth <- c(alpha0 = 0, alpha1 = 0, eta_m1 = 0, eta_0 = 0, eta_1 = 0)
summaries <- do.call(rbind, lapply(seq_len(nrow(design)), function(i) {
  cell <- design[i, ]
  truth[c("alpha0", "alpha1")] <- c(cell$alpha0, cell$alpha1)
  truth[c("eta_m1", "eta_0", "eta_1")] <- 0.999999 * tanh(cell$alpha0 + cell$alpha1 * c(-1, 0, 1))
  summary <- drmTMB:::drm_pair_staged_eta_coverage_summary(
    outer_attempts[outer_attempts$cell_id == cell$cell_id, ], truth,
    minimum_resolved = MINIMUM_RESOLVED
  )
  cbind(cell[rep(1L, nrow(summary)), ], summary)
}))
summaries$availability_ci_lower <- NA_real_
summaries$availability_ci_upper <- NA_real_
summaries$coverage_all_ci_lower <- NA_real_
summaries$coverage_all_ci_upper <- NA_real_
summaries$smoke <- SMOKE
for (i in seq_len(nrow(summaries))) {
  availability <- binomial_interval(summaries$n_available[[i]], summaries$n_outer[[i]])
  all_covered <- round(summaries$coverage_all_attempt[[i]] * summaries$n_outer[[i]])
  all_coverage <- binomial_interval(all_covered, summaries$n_outer[[i]])
  summaries[i, c("availability_ci_lower", "availability_ci_upper")] <- availability
  summaries[i, c("coverage_all_ci_lower", "coverage_all_ci_upper")] <- all_coverage
}
utils::write.csv(summaries, file.path(OUTDIR, "staged-eta-summary.csv"), row.names = FALSE)
