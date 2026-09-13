#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "--all"
valid_modes <- c("--contract", "--oracle", "--smoke", "--artifacts", "--preflight", "--campaign-spec", "--docs", "--all")
if (!mode %in% valid_modes) {
  stop(sprintf("Unknown verification mode %s.", mode), call. = FALSE)
}

out_dir <- file.path("docs", "dev-log", "implementation-recovery", "2026-09-12-phylo-ou-sigma-r1")
runner <- file.path("tools", "run-phylo-ou-sigma-recovery-calibration.R")
design <- file.path("docs", "design", "263-phylo-ou-sigma-recovery-calibration.md")
fail <- function(message) stop(message, call. = FALSE)
pass <- function(marker) cat(marker, "\n", sep = "")

read_required <- function(path) {
  if (!file.exists(path)) fail(sprintf("Missing required artifact: %s", path))
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

check_contract <- function() {
  text <- paste(readLines(design, warn = FALSE), collapse = "\n")
  script <- paste(readLines(runner, warn = FALSE), collapse = "\n")
  required_design <- c(
    "sixteen cells", "negative controls", "rank-deficient", "root distance exactly one",
    "three **fixed natural-scale starts**", "25 minutes", "30 minutes",
    "correlation", "temporal", "REML", "direct-SD", "bivariate", "non-Gaussian"
  )
  if (!all(vapply(required_design, grepl, logical(1L), x = text, fixed = TRUE))) {
    fail("The R1 calibration contract is incomplete.")
  }
  if (grepl("y ~ x|sigma ~ x", script)) fail("The R1 runner retains the rank-deficient covariate design.")
  pass("PHYLO_OU_SIGMA_R1_CONTRACT_PASS")
}

check_oracle <- function() {
  if (!requireNamespace("ape", quietly = TRUE)) fail("ape is required for the independent OU oracle.")
  tree <- ape::read.tree(text = "((a:0.7,b:0.7):0.3,(c:0.4,d:0.4):0.6);")
  distance <- ape::cophenetic.phylo(tree)
  expected_distance <- matrix(2, 4, 4, dimnames = list(tree$tip.label, tree$tip.label))
  diag(expected_distance) <- 0
  expected_distance["a", "b"] <- expected_distance["b", "a"] <- 1.4
  expected_distance["c", "d"] <- expected_distance["d", "c"] <- 0.8
  if (max(abs(distance - expected_distance)) > 1e-12) fail("Hand fixture patristic distances disagree.")
  root_edge_loadings <- function(alpha) {
    nodes <- sort(unique(c(tree$edge)))
    root <- setdiff(tree$edge[, 1L], tree$edge[, 2L])
    loading <- matrix(NA_real_, nrow = max(nodes), ncol = nrow(tree$edge) + 1L)
    loading[root, ] <- c(1, rep(0, nrow(tree$edge)))
    pending <- seq_len(nrow(tree$edge))
    while (length(pending)) {
      ready <- pending[!is.na(loading[tree$edge[pending, 1L], 1L])]
      if (!length(ready)) fail("The hand fixture edge order is not rooted.")
      for (edge_id in ready) {
        parent <- tree$edge[edge_id, 1L]
        child <- tree$edge[edge_id, 2L]
        rho <- exp(-alpha * tree$edge.length[edge_id])
        loading[child, ] <- rho * loading[parent, ]
        loading[child, edge_id + 1L] <- loading[child, edge_id + 1L] + sqrt(-expm1(-2 * alpha * tree$edge.length[edge_id]))
      }
      pending <- setdiff(pending, ready)
    }
    loading[seq_along(tree$tip.label), , drop = FALSE]
  }
  for (alpha in c(0.05, 0.7, 1.3, 5)) {
    expected <- exp(-alpha * distance)
    actual <- tcrossprod(root_edge_loadings(alpha))
    if (max(abs(actual - expected)) > 1e-12 * max(1, max(abs(expected)))) {
      fail("Root-edge basis oracle disagrees with stationary OU covariance.")
    }
  }
  c_mu <- exp(-0.7 * distance) * 0.45^2
  c_sigma <- exp(-1.3 * distance) * 0.25^2
  if (max(abs(t(chol(c_mu)) %*% chol(c_mu) - c_mu)) > 1e-12) fail("Location simulator factor is invalid.")
  if (max(abs(t(chol(c_sigma)) %*% chol(c_sigma) - c_sigma)) > 1e-12) fail("Scale simulator factor is invalid.")
  if (isTRUE(all.equal(c_mu, c_sigma))) fail("The two OU fields incorrectly share a covariance.")
  wrong_root <- root_edge_loadings(0.7)[, -1L, drop = FALSE]
  if (max(abs(tcrossprod(wrong_root) - exp(-0.7 * distance))) < 1e-4) fail("Oracle mutation did not detect omitted root density.")
  pass("PHYLO_OU_SIGMA_R1_ORACLE_PASS")
}

run_runner <- function(which) {
  status <- system2("Rscript", c(runner, which), stdout = TRUE, stderr = TRUE)
  if (!identical(attr(status, "status"), NULL) && attr(status, "status") != 0L) {
    fail(paste(status, collapse = "\n"))
  }
  status
}

check_smoke <- function() {
  run_runner("--smoke")
  first <- read_required(file.path(out_dir, "smoke-attempts.csv"))
  run_runner("--smoke")
  second <- read_required(file.path(out_dir, "smoke-attempts.csv"))
  invariant <- setdiff(names(first), "elapsed_seconds")
  if (!identical(first[invariant], second[invariant])) fail("The smoke manifest does not replay deterministically.")
  if (nrow(first) != 6L || !all(c("ordinary", "negative_control") %in% first$design_class)) {
    fail("The smoke did not retain one ordinary and one negative control across three starts.")
  }
  pass("PHYLO_OU_SIGMA_R1_SMOKE_PASS")
}

check_artifacts <- function() {
  conditions <- read_required(file.path(out_dir, "conditions.csv"))
  attempt_paths <- file.path(out_dir, c("smoke-attempts.csv", "preflight-attempts.csv"))
  required <- c(
    "convergence", "pdHess", "max_gradient", "min_fixed_covariance_eigen",
    "alpha_mu", "alpha_sigma", "sd_mu", "sd_sigma", "mu_intercept",
    "logsigma_intercept", "objective", "convergence_message", "fn_evals",
    "gr_evals", "cpu_seconds", "internal_parameters", "warnings", "boundary",
    "boundary_mu", "boundary_sigma", "elapsed_seconds", "start_id", "task_id", "tree_id"
  )
  required_conditions <- c("task_id", "tree_id", "tree_seed", "design_class")
  if (nrow(conditions) != 18L || sum(conditions$design_class == "ordinary") != 16L ||
      sum(conditions$design_class == "negative_control") != 2L ||
      !all(required_conditions %in% names(conditions)) || anyDuplicated(conditions$task_id) ||
      !all(vapply(attempt_paths, file.exists, logical(1L)))) {
    fail("The retained calibration artifacts do not preserve the declared denominator and diagnostics.")
  }
  for (path in attempt_paths) {
    attempts <- read_required(path)
    if (!all(required %in% names(attempts)) || anyDuplicated(attempts[c("task_id", "start_id")])) {
      fail(sprintf("The local-readiness attempt schema is incomplete: %s", path))
    }
  }
  manifest_paths <- file.path(out_dir, c("smoke-manifest.csv", "preflight-manifest.csv"))
  for (path in manifest_paths) {
    manifest <- read_required(path)
    if (nrow(manifest) != 1L || !all(c("runner_md5", "contract_md5", "source_commit") %in% names(manifest)) ||
        !identical(unname(tools::md5sum(runner)), manifest$runner_md5) ||
        !identical(unname(tools::md5sum(design)), manifest$contract_md5)) {
      fail(sprintf("The local-readiness provenance is stale or incomplete: %s", path))
    }
  }
  pass("PHYLO_OU_SIGMA_R1_ARTIFACTS_PASS")
}

check_preflight <- function() {
  run_runner("--preflight")
  receipt <- read_required(file.path(out_dir, "preflight-summary.csv"))
  manifest <- read_required(file.path(out_dir, "preflight-manifest.csv"))
  manifest_fields <- c("source_commit", "source_dirty", "runner_md5", "contract_md5", "command", "r_version", "drmTMB_dll_md5")
  if (nrow(receipt) != 1L || receipt$preflight_fits != 12L || receipt$calibration_fits != 54L ||
      !is.finite(receipt$projected_calibration_seconds) || isTRUE(receipt$campaign_launch)) {
    fail("The preflight receipt is incomplete or launched a campaign.")
  }
  if (!all(manifest_fields %in% names(manifest)) || nrow(manifest) != 1L ||
      !nzchar(manifest$source_commit) || !nzchar(manifest$runner_md5) || !nzchar(manifest$contract_md5)) {
    fail("The preflight provenance receipt is incomplete.")
  }
  if (!identical(unname(tools::md5sum(runner)), manifest$runner_md5) ||
      !identical(unname(tools::md5sum(design)), manifest$contract_md5)) {
    fail("The preflight provenance hashes do not match the source-current runner and contract.")
  }
  recorded_commit <- system2("git", c("rev-parse", manifest$source_commit), stdout = TRUE, stderr = TRUE)
  if (length(recorded_commit) != 1L || !identical(recorded_commit, manifest$source_commit)) {
    fail("The preflight source commit cannot be resolved locally.")
  }
  pass("PHYLO_OU_SIGMA_R1_PREFLIGHT_PASS")
}

check_campaign_spec <- function() {
  text <- paste(readLines(design, warn = FALSE), collapse = "\n")
  required <- c("SOURCE-PROVENANCE.tsv", "SHA-256", "exactly three start rows", "one fixed seed per task", "30 minutes")
  # The contract's task-level manifest is intentionally the campaign handoff,
  # not permission to submit it.
  if (!all(vapply(required, grepl, logical(1L), x = text, fixed = TRUE)) ||
      !file.exists(file.path(out_dir, "preflight-summary.csv"))) {
    fail("The campaign handoff specification is incomplete.")
  }
  pass("PHYLO_OU_SIGMA_R1_CAMPAIGN_SPEC_PASS")
}

check_docs <- function() {
  text <- paste(readLines(design, warn = FALSE), collapse = "\n")
  if (!grepl("no-claim calibration", text, fixed = TRUE) || !grepl("explicitly defers", text, fixed = TRUE)) {
    fail("Documentation does not state the evidence boundary.")
  }
  pass("PHYLO_OU_SIGMA_R1_DOCS_PASS")
}

if (identical(mode, "--contract")) check_contract()
if (identical(mode, "--oracle")) check_oracle()
if (identical(mode, "--smoke")) check_smoke()
if (identical(mode, "--artifacts")) check_artifacts()
if (identical(mode, "--preflight")) check_preflight()
if (identical(mode, "--campaign-spec")) check_campaign_spec()
if (identical(mode, "--docs")) check_docs()
if (identical(mode, "--all")) {
  check_contract()
  check_oracle()
  check_artifacts()
  check_preflight()
  check_campaign_spec()
  check_docs()
  pass("PHYLO_OU_SIGMA_R1_ALL_PASS")
}
