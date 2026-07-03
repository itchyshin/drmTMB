#!/usr/bin/env Rscript
#
# Tranche 24 q2-plus replicate-108 raw-geometry diagnostic.
#
# This runner executes exactly one host-separated reconstruction for the
# Rorqual SR150 q2-plus replicate-108 blocker. It records raw fit geometry only:
# fit state, gradient, sdreport covariance spectrum, optimizer attempts, and
# target identity. It is not denominator, top-up, coverage, or promotion
# evidence.

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-q2-retained-denominator-tranche24-rep108-geometry.R [options]",
      "",
      "Options:",
      "  --replicate-index=108     Required replicate index; only 108 is allowed.",
      "  --seed-base=823000        Seed base; seed = seed_base + replicate_index.",
      "  --n-each=50               Observations per phylo tip.",
      "  --host-class=CLASS        Host/provenance class stamped into artifacts.",
      "  --host-name=NAME          Host name stamped into artifacts.",
      "  --output-dir=PATH         Artifact directory.",
      "  --overwrite=true          Replace an existing artifact directory.",
      "",
      "Requires DRMTMB_Q2_TRANCHE24_GEOMETRY_RECONSTRUCTION_APPROVED=",
      "fisher_rose_noether_gauss_grace_approved.",
      "",
      sep = "\n"
    )
  )
  quit(status = 0L)
}

arg_value <- function(name, default = NULL) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (!length(hit)) {
    return(default)
  }
  sub(prefix, "", hit[[length(hit)]], fixed = TRUE)
}

arg_flag <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
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
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
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

format_num <- function(x, digits = 8L) {
  x <- suppressWarnings(as.numeric(x))
  if (!length(x) || !is.finite(x[[1L]])) {
    return("NA")
  }
  formatC(x[[1L]], digits = digits, format = "fg", flag = "#")
}

format_vector <- function(x, digits = 8L) {
  x <- suppressWarnings(as.numeric(x))
  x <- x[is.finite(x)]
  if (!length(x)) {
    return("NA")
  }
  paste(vapply(x, format_num, character(1L), digits = digits), collapse = ";")
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

approval <- Sys.getenv("DRMTMB_Q2_TRANCHE24_GEOMETRY_RECONSTRUCTION_APPROVED", "")
if (!identical(approval, "fisher_rose_noether_gauss_grace_approved")) {
  stop(
    "Tranche 24 geometry reconstruction requires ",
    "DRMTMB_Q2_TRANCHE24_GEOMETRY_RECONSTRUCTION_APPROVED=",
    "fisher_rose_noether_gauss_grace_approved.",
    call. = FALSE
  )
}

replicate_index <- as.integer(arg_value("replicate-index", "108"))
seed_base <- as.integer(arg_value("seed-base", "823000"))
n_each <- as.integer(arg_value("n-each", "50"))
if (!identical(replicate_index, 108L)) {
  stop("Tranche 24 only permits --replicate-index=108.", call. = FALSE)
}
if (!identical(seed_base, 823000L)) {
  stop("Tranche 24 only permits --seed-base=823000.", call. = FALSE)
}
if (!is.finite(n_each) || n_each < 1L) {
  stop("`--n-each` must be a positive integer.", call. = FALSE)
}
seed <- seed_base + replicate_index
host_class <- arg_value("host-class", "local_codex_geometry_reconstruction")
host_name <- arg_value("host-name", unname(Sys.info()[["nodename"]]))
overwrite <- arg_flag("overwrite", FALSE)
default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-07-01-q2-tranche24-rep108-geometry-local"
)
artifact_dir <- normalizePath(
  arg_value("output-dir", default_artifact_dir),
  mustWork = FALSE
)
if (dir.exists(artifact_dir) && !overwrite) {
  stop(
    "`output-dir` already exists. Use --overwrite=true to replace it: ",
    artifact_dir,
    call. = FALSE
  )
}
if (dir.exists(artifact_dir) && overwrite) {
  unlink(artifact_dir, recursive = TRUE)
}
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
tranche23_contract_path <- file.path(
  dashboard_dir,
  "structured-re-q2-retained-denominator-tranche23-rep108-geometry-contract.tsv"
)
tranche22_review_path <- file.path(
  dashboard_dir,
  "structured-re-q2-retained-denominator-tranche22-rep108-artifact-review.tsv"
)
q2_plus_contract_path <- file.path(
  dashboard_dir,
  "structured-re-q2-plus-q2-intercept-contract.tsv"
)
source_sr150_replicates <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-30-q2-retained-denominator-sr150-pregrid-rorqual",
  "shard_5_q2-plus-q2-phylo-ready-targets",
  "artifacts",
  "structured-re-q2-plus-q2-intercept-local-smoke-replicates.tsv"
)
source_seed_manifest <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-30-q2-retained-denominator-sr150-pregrid-rorqual",
  "shard_5_q2-plus-q2-phylo-ready-targets",
  "artifacts",
  "structured-re-q2-plus-q2-intercept-local-smoke-seed-manifest.tsv"
)
source_metadata <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-30-q2-retained-denominator-sr150-pregrid-rorqual",
  "_rorqual-metadata",
  "shard_5"
)
for (path in c(
  tranche23_contract_path,
  tranche22_review_path,
  q2_plus_contract_path,
  source_sr150_replicates,
  source_seed_manifest,
  source_metadata
)) {
  if (!file.exists(path)) {
    stop("Required Tranche 24 source path is missing: ", path, call. = FALSE)
  }
}

tranche23 <- read_tsv(tranche23_contract_path)
if (!all(tranche23$execution_decision == "contract_banked_not_executed")) {
  stop("Tranche 23 contract must still be banked, not executed.", call. = FALSE)
}
if (!all(tranche23$coverage_decision == "coverage_not_authorized")) {
  stop("Tranche 23 contract must not authorize coverage.", call. = FALSE)
}
if (!all(tranche23$promotion_decision == "do_not_promote")) {
  stop("Tranche 23 contract must not promote support cells.", call. = FALSE)
}

tranche22 <- read_tsv(tranche22_review_path)
tranche22_targets <- tranche22[tranche22$review_scope == "target_review", , drop = FALSE]
q2_plus_contract <- read_tsv(q2_plus_contract_path)
q2_plus_contract_direct <- q2_plus_contract[
  q2_plus_contract$target_kind %in% c("direct_sd", "direct_correlation"),
  ,
  drop = FALSE
]
expected_estimands <- c(
  "sd_mu1_intercept",
  "sd_mu2_intercept",
  "cor_mu1_mu2_intercept",
  "sd_sigma1_intercept",
  "sd_sigma2_intercept"
)
if (!setequal(tranche22_targets$estimand, expected_estimands)) {
  stop("Tranche 22 source review must retain the five q2-plus target rows.", call. = FALSE)
}
if (!all(tranche22_targets$pdHess == "FALSE")) {
  stop("Tranche 22 source target rows must keep pdHess FALSE.", call. = FALSE)
}
if (!all(tranche22_targets$wald_status == "nonfinite")) {
  stop("Tranche 22 source target rows must keep Wald nonfinite.", call. = FALSE)
}
if (!all(expected_estimands %in% q2_plus_contract_direct$estimand)) {
  stop("q2-plus contract is missing one or more Tranche 24 target identities.", call. = FALSE)
}

load_result <- tryCatch(
  {
    suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))
    list(ok = TRUE, status = "devtools_load_all", detail = "loaded current source")
  },
  error = function(e) {
    list(ok = FALSE, status = "devtools_load_all_failed", detail = conditionMessage(e))
  }
)
if (!isTRUE(load_result$ok)) {
  stop(load_result$detail, call. = FALSE)
}

TRUTH <- list(
  mu1_intercept = 0.25,
  mu2_intercept = -0.10,
  sigma1_intercept = -1.00,
  sigma2_intercept = -0.90,
  rho12 = 0.00,
  sd_mu1_intercept = 0.55,
  sd_mu2_intercept = 0.45,
  cor_mu1_mu2_intercept = 0.20,
  sd_sigma1_intercept = 0.45,
  sd_sigma2_intercept = 0.40,
  cor_sigma1_sigma2_intercept = 0.15
)

balanced_tree <- function(n_tip = 8L) {
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }
  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

correlated_intercept_effects <- function(K, sd1, sd2, cor12) {
  endpoint_cov <- matrix(
    c(sd1^2, cor12 * sd1 * sd2, cor12 * sd1 * sd2, sd2^2),
    nrow = 2L
  )
  base <- t(chol(K)) %*% matrix(stats::rnorm(nrow(K) * 2L), nrow(K), 2L)
  out <- base %*% chol(endpoint_cov)
  colnames(out) <- c("axis1", "axis2")
  out
}

make_q2_plus_q2_intercept_data <- function(seed) {
  set.seed(seed)
  tree <- balanced_tree(8L)
  labels <- tree$tip.label
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  location_effects <- correlated_intercept_effects(
    K,
    sd1 = TRUTH$sd_mu1_intercept,
    sd2 = TRUTH$sd_mu2_intercept,
    cor12 = TRUTH$cor_mu1_mu2_intercept
  )
  scale_effects <- correlated_intercept_effects(
    K,
    sd1 = TRUTH$sd_sigma1_intercept,
    sd2 = TRUTH$sd_sigma2_intercept,
    cor12 = TRUTH$cor_sigma1_sigma2_intercept
  )
  row.names(location_effects) <- labels
  row.names(scale_effects) <- labels
  species <- rep(labels, each = n_each)
  eta1 <- TRUTH$mu1_intercept + location_effects[species, "axis1"]
  eta2 <- TRUTH$mu2_intercept + location_effects[species, "axis2"]
  log_sigma1 <- TRUTH$sigma1_intercept + scale_effects[species, "axis1"]
  log_sigma2 <- TRUTH$sigma2_intercept + scale_effects[species, "axis2"]
  data <- data.frame(
    y1 = stats::rnorm(length(species), eta1, exp(log_sigma1)),
    y2 = stats::rnorm(length(species), eta2, exp(log_sigma2)),
    species = species,
    stringsAsFactors = FALSE
  )
  list(data = data, tree = tree)
}

fit_q2_plus_q2_intercept <- function(sim) {
  tree <- sim$tree
  drmTMB(
    bf(
      mu1 = y1 ~ phylo(1 | pl | species, tree = tree),
      mu2 = y2 ~ phylo(1 | pl | species, tree = tree),
      sigma1 = ~ phylo(1 | ps | species, tree = tree),
      sigma2 = ~ phylo(1 | ps | species, tree = tree),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 2500, iter.max = 2500))
  )
}

safe_eigenvalues <- function(x) {
  if (is.null(x) || !length(x) || !all(is.finite(x))) {
    return(NULL)
  }
  mat <- tryCatch(as.matrix(x), error = function(e) NULL)
  if (is.null(mat) || length(dim(mat)) != 2L || nrow(mat) != ncol(mat)) {
    return(NULL)
  }
  tryCatch(eigen((mat + t(mat)) / 2, symmetric = TRUE, only.values = TRUE)$values, error = function(e) NULL)
}

log10_condition <- function(values) {
  values <- suppressWarnings(as.numeric(values))
  values <- abs(values)
  values <- values[is.finite(values) & values > 0]
  if (!length(values)) {
    return(NA_real_)
  }
  log10(max(values) / min(values))
}

geometry_status <- function(fit_ok, pdhess, max_gradient, cov_eigen, min_direct_sd) {
  n_nonpositive <- if (is.null(cov_eigen)) NA_integer_ else sum(cov_eigen <= 0)
  if (!isTRUE(fit_ok)) {
    return("fit_not_ok")
  }
  if (isTRUE(pdhess)) {
    return("local_replay_pdhess_true_source_drift_check_required")
  }
  if (is.finite(min_direct_sd) && min_direct_sd < 0.05) {
    if (!is.null(cov_eigen) && n_nonpositive > 0L) {
      return("pdhess_false_covfixed_nonpositive_sigma2_boundary")
    }
    return("pdhess_false_sigma2_boundary")
  }
  if (!is.null(cov_eigen) && n_nonpositive > 0L && is.finite(max_gradient) && max_gradient > 1e-3) {
    return("pdhess_false_covfixed_nonpositive_gradient_watch")
  }
  if (!is.null(cov_eigen) && n_nonpositive > 0L) {
    return("pdhess_false_covfixed_nonpositive")
  }
  "pdhess_false_unclassified_geometry"
}

rel_path <- function(path) {
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"), "", normalizePath(path, mustWork = FALSE))
}

source_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) paste("git rev-parse failed:", conditionMessage(e))
)
dirty_status <- tryCatch(
  system2("git", c("status", "--porcelain"), stdout = TRUE, stderr = TRUE),
  error = function(e) paste("git status failed:", conditionMessage(e))
)
source_dirty <- length(dirty_status) > 0L
source_rorqual_sha_path <- file.path(source_metadata, "git-sha.txt")
source_rorqual_sha <- if (file.exists(source_rorqual_sha_path)) {
  readLines(source_rorqual_sha_path, warn = FALSE)[1L]
} else {
  "NA"
}

warnings_fit <- character()
t_elapsed <- system.time({
  fit_result <- withCallingHandlers(
    tryCatch({
      sim <- make_q2_plus_q2_intercept_data(seed)
      fit_q2_plus_q2_intercept(sim)
    }, error = function(e) e),
    warning = function(w) {
      warnings_fit <<- c(warnings_fit, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
})
fit_error <- inherits(fit_result, "error")
fit <- if (fit_error) NULL else fit_result
convergence <- if (fit_error) NA_integer_ else fit$opt$convergence
fit_ok <- !fit_error && identical(convergence, 0L)
pdhess <- !fit_error && isTRUE(fit$sdr$pdHess)
fit_message <- if (fit_error) {
  conditionMessage(fit_result)
} else {
  paste(unique(warnings_fit), collapse = "; ")
}

gradient <- if (fit_error) {
  numeric()
} else {
  fit$sdr$gradient.fixed %||%
    tryCatch(fit$obj$gr(fit$opt$par), error = function(e) numeric())
}
max_gradient <- if (length(gradient)) max(abs(gradient), na.rm = TRUE) else NA_real_
rms_gradient <- if (length(gradient)) sqrt(mean(gradient^2, na.rm = TRUE)) else NA_real_
scaled_gradient <- if (is.finite(max_gradient)) max_gradient / max(1, sqrt(length(gradient))) else NA_real_
max_gradient_index <- if (length(gradient)) which.max(abs(gradient)) else NA_integer_
max_gradient_parameter <- if (length(gradient) && length(names(gradient))) {
  names(gradient)[[max_gradient_index]]
} else {
  "NA"
}

raw_hessian <- if (fit_error) {
  structure(list(message = "fit_error"), class = "error")
} else {
  tryCatch(fit$obj$he(fit$opt$par), error = function(e) e)
}
raw_hessian_error <- inherits(raw_hessian, "error")
raw_hessian_eigen <- if (raw_hessian_error) NULL else safe_eigenvalues(raw_hessian)
cov_fixed <- if (fit_error) NULL else fit$sdr$cov.fixed
cov_fixed_eigen <- safe_eigenvalues(cov_fixed)

targets <- if (fit_error) {
  data.frame()
} else {
  tryCatch(profile_targets(fit), error = function(e) data.frame())
}
target_rows <- lapply(expected_estimands, function(estimand) {
  source_row <- tranche22_targets[
    tranche22_targets$estimand == estimand,
    ,
    drop = FALSE
  ]
  contract_row <- q2_plus_contract_direct[
    q2_plus_contract_direct$estimand == estimand,
    ,
    drop = FALSE
  ]
  target_parm <- if (nrow(contract_row)) contract_row$profile_target[[1L]] else "NA"
  matched <- if (nrow(targets) && "parm" %in% names(targets)) {
    targets[targets$parm == target_parm, , drop = FALSE]
  } else {
    data.frame()
  }
  estimate <- if (nrow(matched) && "estimate" %in% names(matched)) {
    matched$estimate[[1L]]
  } else {
    NA_real_
  }
  target_kind <- if (nrow(source_row)) source_row$target_kind[[1L]] else "NA"
  boundary_flag <- if (identical(target_kind, "direct_sd")) {
    is.finite(estimate) && estimate < 0.05
  } else if (identical(target_kind, "direct_correlation")) {
    is.finite(estimate) && abs(estimate) > 0.98
  } else {
    NA
  }
  data.frame(
    target_id = paste0("tranche24_q2_plus_rep108_", estimand),
    cell_id = "qseries_phylo_q2_plus_q2_intercept",
    provider = "phylo",
    replicate_index = replicate_index,
    seed = seed,
    estimand = estimand,
    endpoint_member = if (nrow(source_row)) source_row$endpoint_member[[1L]] else "NA",
    target_parm = target_parm,
    target_kind = target_kind,
    truth_value = if (nrow(source_row)) source_row$truth_value[[1L]] else format_num(TRUTH[[estimand]]),
    source_tranche22_estimate = if (nrow(source_row)) source_row$estimate[[1L]] else "NA",
    replay_estimate = format_num(estimate, digits = 14L),
    source_profile_status = if (nrow(source_row)) source_row$profile_status[[1L]] else "NA",
    source_profile_contains = if (nrow(source_row)) source_row$profile_contains[[1L]] else "NA",
    boundary_flag = boundary_flag,
    geometry_role = if (identical(estimand, "sd_sigma2_intercept")) {
      "near_boundary_source_target"
    } else {
      "source_target_identity"
    },
    claim_boundary = paste(
      "Tranche 24 target identity geometry only; no interval_status,",
      "coverage_status, inference_ready, supported, denominator, top-up,",
      "q2-plus promotion, q4/q8, REML, AI-REML, bridge, or public-support claim."
    ),
    stringsAsFactors = FALSE
  )
})
target_out <- do.call(rbind, target_rows)

min_direct_sd <- suppressWarnings(min(
  as.numeric(target_out$replay_estimate[target_out$target_kind == "direct_sd"]),
  na.rm = TRUE
))
if (!is.finite(min_direct_sd)) {
  min_direct_sd <- NA_real_
}
status <- geometry_status(fit_ok, pdhess, max_gradient, cov_fixed_eigen, min_direct_sd)

cov_fixed_dim <- if (is.null(cov_fixed)) "NA" else paste(dim(cov_fixed), collapse = "x")
raw_hessian_dim <- if (raw_hessian_error || is.null(raw_hessian)) {
  "NA"
} else {
  paste(dim(raw_hessian), collapse = "x")
}
optimizer_attempts <- if (fit_error) data.frame() else fit$optimizer_attempts
optimizer_used <- if (fit_error) list() else fit$optimizer_used

summary_out <- data.frame(
  result_id = "tranche24_q2_plus_rep108_geometry_summary",
  result_scope = "raw_geometry_reconstruction",
  cell_id = "qseries_phylo_q2_plus_q2_intercept",
  provider = "phylo",
  source_tranche23_contract = rel_path(tranche23_contract_path),
  source_tranche22_review = rel_path(tranche22_review_path),
  source_sr150_replicates = rel_path(source_sr150_replicates),
  source_seed_manifest = rel_path(source_seed_manifest),
  source_metadata = rel_path(source_metadata),
  source_rorqual_sha = source_rorqual_sha,
  host_class = host_class,
  host_name = host_name,
  source_sha = source_sha[[1L]],
  source_dirty = source_dirty,
  output_path = rel_path(artifact_dir),
  replicate_index = replicate_index,
  seed = seed,
  n_each = n_each,
  approval_token = approval,
  reconstruction_status = "executed_one_host_geometry_only",
  fit_ok = fit_ok,
  attempt_status = if (fit_error) "fit_error" else "fit_ok",
  convergence = convergence,
  pdHess = pdhess,
  fit_message = clean_text(fit_message),
  elapsed_sec = format_num(unname(t_elapsed[["elapsed"]]), digits = 8L),
  objective = format_num(if (fit_error) NA_real_ else fit$opt$objective, digits = 12L),
  optimizer_selected = optimizer_used$optimizer %||% "NA",
  optimizer_selected_preset = optimizer_used$optimizer_preset %||% "NA",
  optimizer_attempt_count = if (is.data.frame(optimizer_attempts)) nrow(optimizer_attempts) else 0L,
  max_abs_gradient = format_num(max_gradient, digits = 10L),
  rms_gradient = format_num(rms_gradient, digits = 10L),
  scaled_gradient = format_num(scaled_gradient, digits = 10L),
  max_gradient_parameter = max_gradient_parameter,
  raw_hessian_status = if (raw_hessian_error) {
    paste0("error:", clean_text(conditionMessage(raw_hessian)))
  } else if (is.null(raw_hessian_eigen)) {
    "finite_matrix_eigen_unavailable"
  } else {
    "finite_matrix_eigen_ok"
  },
  raw_hessian_dim = raw_hessian_dim,
  raw_hessian_eigen_min = format_num(if (is.null(raw_hessian_eigen)) NA_real_ else min(raw_hessian_eigen), digits = 10L),
  raw_hessian_eigen_max = format_num(if (is.null(raw_hessian_eigen)) NA_real_ else max(raw_hessian_eigen), digits = 10L),
  raw_hessian_n_nonpositive = if (is.null(raw_hessian_eigen)) NA_integer_ else sum(raw_hessian_eigen <= 0),
  raw_hessian_log10_condition = format_num(log10_condition(raw_hessian_eigen), digits = 8L),
  cov_fixed_status = if (is.null(cov_fixed_eigen)) "eigen_unavailable" else "eigen_ok",
  cov_fixed_dim = cov_fixed_dim,
  cov_fixed_finite_count = if (is.null(cov_fixed)) 0L else sum(is.finite(cov_fixed)),
  cov_fixed_total = if (is.null(cov_fixed)) 0L else length(cov_fixed),
  cov_fixed_eigen_min = format_num(if (is.null(cov_fixed_eigen)) NA_real_ else min(cov_fixed_eigen), digits = 10L),
  cov_fixed_eigen_max = format_num(if (is.null(cov_fixed_eigen)) NA_real_ else max(cov_fixed_eigen), digits = 10L),
  cov_fixed_n_nonpositive = if (is.null(cov_fixed_eigen)) NA_integer_ else sum(cov_fixed_eigen <= 0),
  cov_fixed_log10_condition = format_num(log10_condition(cov_fixed_eigen), digits = 8L),
  diag_cov_random_min = format_num(
    if (!fit_error && length(fit$sdr$diag.cov.random)) min(fit$sdr$diag.cov.random, na.rm = TRUE) else NA_real_,
    digits = 10L
  ),
  diag_cov_random_max = format_num(
    if (!fit_error && length(fit$sdr$diag.cov.random)) max(fit$sdr$diag.cov.random, na.rm = TRUE) else NA_real_,
    digits = 10L
  ),
  diag_cov_random_n_nonpositive = if (!fit_error && length(fit$sdr$diag.cov.random)) {
    sum(fit$sdr$diag.cov.random <= 0, na.rm = TRUE)
  } else {
    NA_integer_
  },
  target_count = nrow(target_out),
  min_direct_sd_replay_estimate = format_num(min_direct_sd, digits = 10L),
  n_direct_sd_boundary_lt_0_05 = sum(
    target_out$target_kind == "direct_sd" &
      suppressWarnings(as.numeric(target_out$replay_estimate)) < 0.05,
    na.rm = TRUE
  ),
  geometry_status = status,
  coverage_decision = "coverage_not_authorized",
  promotion_decision = "do_not_promote",
  claim_boundary = paste(
    "Tranche 24 q2-plus replicate-108 raw-geometry reconstruction only;",
    "one local host-separated replay was executed; this is diagnostic geometry",
    "evidence, not denominator, top-up, coverage, interval_status,",
    "coverage_status, inference_ready, supported, q2-plus promotion, q4/q8,",
    "REML, AI-REML, bridge, or public-support evidence; do not pool with",
    "Rorqual, Totoro, Nibi, Trillium, DRAC, or any other host denominator."
  ),
  next_gate = paste(
    "Review the Tranche 24 geometry result with Fisher/Rose/Noether/Gauss/Grace;",
    "then choose a repair route or explicitly park q2-plus before any further",
    "compute."
  ),
  stringsAsFactors = FALSE
)

attempt_out <- if (is.data.frame(optimizer_attempts) && nrow(optimizer_attempts)) {
  data.frame(
    result_id = paste0("tranche24_q2_plus_rep108_optimizer_attempt_", seq_len(nrow(optimizer_attempts))),
    replicate_index = replicate_index,
    seed = seed,
    attempt = optimizer_attempts$attempt,
    optimizer = optimizer_attempts$optimizer,
    optimizer_preset = optimizer_attempts$optimizer_preset,
    status = optimizer_attempts$status,
    convergence = optimizer_attempts$convergence,
    message = optimizer_attempts$message,
    objective = vapply(optimizer_attempts$objective, format_num, character(1L), digits = 12L),
    elapsed_sec = vapply(optimizer_attempts$elapsed_sec, format_num, character(1L), digits = 8L),
    selected = optimizer_attempts$selected,
    host_class = host_class,
    host_name = host_name,
    stringsAsFactors = FALSE
  )
} else {
  data.frame(
    result_id = "tranche24_q2_plus_rep108_optimizer_attempt_unavailable",
    replicate_index = replicate_index,
    seed = seed,
    attempt = NA_integer_,
    optimizer = "NA",
    optimizer_preset = "NA",
    status = "unavailable",
    convergence = NA_integer_,
    message = "optimizer_attempts_unavailable",
    objective = "NA",
    elapsed_sec = "NA",
    selected = NA,
    host_class = host_class,
    host_name = host_name,
    stringsAsFactors = FALSE
  )
}

summary_path <- file.path(
  artifact_dir,
  "structured-re-q2-plus-rep108-geometry-summary.tsv"
)
target_path <- file.path(
  artifact_dir,
  "structured-re-q2-plus-rep108-geometry-targets.tsv"
)
attempt_path <- file.path(
  artifact_dir,
  "structured-re-q2-plus-rep108-geometry-optimizer-attempts.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")
exact_command_path <- file.path(artifact_dir, "exact-command.txt")

write_tsv(summary_out, summary_path)
write_tsv(target_out, target_path)
write_tsv(attempt_out, attempt_path)
writeLines(utils::capture.output(sessionInfo()), session_info_path)
writeLines(source_sha, git_sha_path)
writeLines(paste(commandArgs(FALSE), collapse = " "), exact_command_path)

message("wrote Tranche 24 q2-plus replicate-108 geometry artifacts to ", rel_path(artifact_dir))
