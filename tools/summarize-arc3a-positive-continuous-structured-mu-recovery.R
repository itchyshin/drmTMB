#!/usr/bin/env Rscript

# Fail-closed Arc 3a certification combiner and gate evaluator.
# Raw shard outputs remain local. This script emits compact, reviewable tables.

`%||%` <- function(x, y) if (is.null(x)) y else x

parse_args <- function(args) {
  out <- list(
    input_dir = NULL,
    output_dir = NULL,
    bootstrap_reps = 2000L,
    contract = "primary",
    primary_artifact_dir = NULL
  )
  for (arg in args) {
    if (startsWith(arg, "--input-dir=")) {
      out$input_dir <- sub("^--input-dir=", "", arg)
    } else if (startsWith(arg, "--output-dir=")) {
      out$output_dir <- sub("^--output-dir=", "", arg)
    } else if (startsWith(arg, "--bootstrap-reps=")) {
      out$bootstrap_reps <- as.integer(sub("^--bootstrap-reps=", "", arg))
    } else if (startsWith(arg, "--contract=")) {
      out$contract <- sub("^--contract=", "", arg)
    } else if (startsWith(arg, "--primary-artifact-dir=")) {
      out$primary_artifact_dir <- sub(
        "^--primary-artifact-dir=",
        "",
        arg
      )
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (is.null(out$input_dir) || is.null(out$output_dir)) {
    stop("--input-dir and --output-dir are required", call. = FALSE)
  }
  if (is.na(out$bootstrap_reps) || out$bootstrap_reps != 2000L) {
    stop(
      "Certification is frozen at exactly --bootstrap-reps=2000",
      call. = FALSE
    )
  }
  out$contract <- match.arg(out$contract, c("primary", "phylo_addendum"))
  if (
    identical(out$contract, "phylo_addendum") &&
      is.null(out$primary_artifact_dir)
  ) {
    stop(
      "--primary-artifact-dir is required for the phylo_addendum contract",
      call. = FALSE
    )
  }
  out
}

sha256_file <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  quoted_path <- shQuote(path)
  command_args <- if (identical(command, "shasum")) {
    c("-a", "256", quoted_path)
  } else {
    quoted_path
  }
  out <- system2(command, command_args, stdout = TRUE, stderr = TRUE)
  token <- strsplit(out[[1L]], "[[:space:]]+")[[1L]][[1L]]
  if (!grepl("^[0-9a-fA-F]{64}$", token)) {
    stop("Could not hash ", path, call. = FALSE)
  }
  tolower(token)
}

sha256_object <- function(x) {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(x, path, version = 3)
  sha256_file(path)
}

balanced_tree <- function(M) {
  edge <- matrix(integer(), ncol = 2L)
  edge_length <- numeric()
  next_node <- M + 1L
  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    half <- length(tips) / 2L
    left <- build(tips[seq_len(half)])
    right <- build(tips[seq.int(half + 1L, length(tips))])
    edge <<- rbind(edge, c(node, left), c(node, right))
    edge_length <<- c(edge_length, 1, 1)
    node
  }
  build(seq_len(M))
  structure(
    list(
      edge = edge,
      edge.length = edge_length,
      tip.label = sprintf("g%03d", seq_len(M)),
      Nnode = M - 1L
    ),
    class = "phylo"
  )
}

relatedness <- function(M) {
  labels <- sprintf("g%03d", seq_len(M))
  K <- outer(seq_len(M), seq_len(M), function(i, j) 0.5^abs(i - j))
  dimnames(K) <- list(labels, labels)
  K
}

balanced_tree_covariance <- function(tree) {
  n_tip <- length(tree$tip.label)
  n_total <- n_tip + tree$Nnode
  parent <- integer(n_total)
  parent[tree$edge[, 2L]] <- tree$edge[, 1L]
  depth <- numeric(n_total)
  root <- setdiff(unique(tree$edge[, 1L]), tree$edge[, 2L])[[1L]]
  stack <- root
  while (length(stack)) {
    node <- stack[[length(stack)]]
    stack <- stack[-length(stack)]
    child_edges <- which(tree$edge[, 1L] == node)
    for (edge_id in child_edges) {
      child <- tree$edge[edge_id, 2L]
      depth[[child]] <- depth[[node]] + tree$edge.length[[edge_id]]
      stack <- c(stack, child)
    }
  }
  ancestors <- lapply(seq_len(n_tip), function(node) {
    out <- node
    while (parent[[node]] > 0L) {
      node <- parent[[node]]
      out <- c(out, node)
    }
    out
  })
  covariance <- matrix(0, n_tip, n_tip)
  for (i in seq_len(n_tip)) {
    for (j in seq_len(i)) {
      shared <- intersect(ancestors[[i]], ancestors[[j]])
      covariance[i, j] <- covariance[j, i] <- max(depth[shared])
    }
  }
  covariance <- covariance / unique(depth[seq_len(n_tip)])
  dimnames(covariance) <- list(tree$tip.label, tree$tip.label)
  covariance
}

write_tsv <- function(x, path) {
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

truth_for <- c(
  estimate_beta0 = 0.20,
  estimate_beta_x = 0.35,
  estimate_beta_sigma = log(0.35),
  estimate_tau = 0.50
)
truth_columns <- c(
  truth_beta0 = 0.20,
  truth_beta_x = 0.35,
  truth_beta_sigma = log(0.35),
  truth_tau = 0.50
)
args <- parse_args(commandArgs(trailingOnly = TRUE))
is_phylo_addendum <- identical(args$contract, "phylo_addendum")
campaign_id <- if (is_phylo_addendum) {
  "arc3a_phylo_recovery_addendum_20260714"
} else {
  "arc3a_positive_continuous_structured_mu_20260714"
}
master_seed <- if (is_phylo_addendum) 2026071431L else 2026071403L
summary_seed <- if (is_phylo_addendum) 2026071437L else 2026071417L
expected_mode <- if (is_phylo_addendum) {
  "phylo_certification"
} else {
  "certification"
}
expected_routes <- if (is_phylo_addendum) {
  c("gamma_phylo", "lognormal_phylo")
} else {
  c(
    "gamma_phylo",
    "lognormal_phylo",
    "lognormal_relmat_K",
    "lognormal_relmat_Q",
    "gamma_relmat_K"
  )
}
expected_M <- c(16L, 32L, 64L)
primary_route_contract <- data.frame(
  fit_route = c(
    "gamma_phylo",
    "lognormal_phylo",
    "lognormal_relmat_K",
    "lognormal_relmat_Q",
    "gamma_relmat_K"
  ),
  dgp_cell = c(
    "gamma_phylo",
    "lognormal_phylo",
    "lognormal_relmat",
    "lognormal_relmat",
    "gamma_relmat"
  ),
  family = c("gamma", "lognormal", "lognormal", "lognormal", "gamma"),
  provider = c("phylo", "phylo", "relmat", "relmat", "relmat"),
  representation = c("tree", "tree", "K", "Q", "K"),
  role = c("new", "new", "new", "new_parity", "comparator"),
  stringsAsFactors = FALSE
)
route_contract <- primary_route_contract[
  match(expected_routes, primary_route_contract$fit_route),
  ,
  drop = FALSE
]
geometry_contract <- do.call(
  rbind,
  lapply(expected_M, function(M) {
    tree <- balanced_tree(M)
    K <- relatedness(M)
    Q <- solve(K)
    data.frame(
      M = M,
      tree_hash = sha256_object(tree),
      K_hash = sha256_object(K),
      Q_hash = sha256_object(Q),
      stringsAsFactors = FALSE
    )
  })
)
assert <- function(ok, message) if (!isTRUE(ok)) stop(message, call. = FALSE)

manifest_value <- function(lines, key) {
  hit <- grep(paste0("^", key, "="), lines, value = TRUE)
  assert(length(hit) == 1L, paste("Session manifest lacks unique key", key))
  sub(paste0("^", key, "="), "", hit[[1L]])
}
split_values <- function(x) as.numeric(strsplit(x, ";", fixed = TRUE)[[1L]])

input_dir <- normalizePath(args$input_dir, mustWork = TRUE)
output_dir <- normalizePath(args$output_dir, mustWork = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
if (length(list.files(output_dir, all.files = TRUE, no.. = TRUE))) {
  stop(
    "Refusing to write into non-empty output directory: ",
    output_dir,
    call. = FALSE
  )
}

primary_authentication <- NULL
if (is_phylo_addendum) {
  primary_dir <- normalizePath(args$primary_artifact_dir, mustWork = TRUE)
  primary_expected_hashes <- c(
    "arc3a-certification-combined-raw.tsv" = "b303aab6781770e14be096b69c95b5da0e803f703cf3321baa91750a6465dcd3",
    "route-decisions.tsv" = "b801eb545ad43ea852ef3242ab076f8da4c96e3ae342253ab4f311a5e0d9528e",
    "cell-decisions.tsv" = "db6e7b0da4e4cd97d00664885b2b231794e9f9f3412112138ea60d8ad3f25076",
    "kq-parity-summary.tsv" = "aea481c2a564663c1b10371ece780aeeefa431f0c47abf2d90d9e67b42c5e935"
  )
  primary_paths <- file.path(primary_dir, names(primary_expected_hashes))
  names(primary_paths) <- names(primary_expected_hashes)
  missing_primary <- names(primary_paths)[!file.exists(primary_paths)]
  assert(
    !length(missing_primary),
    paste(
      "Missing primary artifact(s):",
      paste(missing_primary, collapse = ", ")
    )
  )
  primary_observed_hashes <- vapply(
    primary_paths,
    sha256_file,
    character(1),
    USE.NAMES = FALSE
  )
  names(primary_observed_hashes) <- names(primary_expected_hashes)
  assert(
    identical(primary_observed_hashes, primary_expected_hashes),
    "Primary artifact hash mismatch"
  )
  primary_route_decision <- utils::read.delim(
    primary_paths[["route-decisions.tsv"]],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  primary_cell_decision <- utils::read.delim(
    primary_paths[["cell-decisions.tsv"]],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  primary_parity <- utils::read.delim(
    primary_paths[["kq-parity-summary.tsv"]],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  comparator_pass <-
    nrow(primary_route_decision[
      primary_route_decision$fit_route == "gamma_relmat_K" &
        primary_route_decision$nonparity_pass %in% TRUE,
      ,
      drop = FALSE
    ]) ==
      1L &&
    nrow(primary_cell_decision[
      primary_cell_decision$cell == "gamma_relmat_comparator" &
        primary_cell_decision$certification_pass %in% TRUE,
      ,
      drop = FALSE
    ]) ==
      1L
  parity_pass <- nrow(primary_parity) == 3L &&
    all(
      primary_parity$availability_gate %in%
        TRUE &
        primary_parity$numerical_gate %in% TRUE
    )
  shared_gate_pass <- comparator_pass && parity_pass
  assert(comparator_pass, "Authenticated primary comparator gate is not PASS")
  assert(parity_pass, "Authenticated primary K/Q parity gate is not PASS")
  assert(shared_gate_pass, "Authenticated primary shared gate is not PASS")
  primary_authentication <- list(
    observed_hashes = primary_observed_hashes,
    comparator_pass = comparator_pass,
    parity_pass = parity_pass,
    shared_gate_pass = shared_gate_pass
  )
}

raw_files <- sort(list.files(
  input_dir,
  pattern = "^raw-shard-[0-9]+\\.tsv$",
  full.names = TRUE
))
if (!length(raw_files)) {
  stop("No raw-shard-N.tsv inputs found", call. = FALSE)
}
shards <- lapply(
  raw_files,
  utils::read.delim,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
raw <- do.call(rbind, shards)

required <- c(
  "campaign_id",
  "source_commit_sha",
  "source_dirty",
  "host",
  "phase",
  "shard_index",
  "shard_count",
  "global_fit_index",
  "fit_route",
  "dgp_cell",
  "family",
  "provider",
  "representation",
  "role",
  "M",
  "n_per_level",
  "N",
  "replicate",
  "dgp_seed",
  "fit_key",
  "attempted",
  "fit_success",
  "analysis_success",
  "failure_stage",
  "elapsed_seconds",
  "convergence_code",
  "hessian_covariance_values",
  "hessian_diagnostic_finite",
  "pdHess",
  "boundary",
  "gross_sigma",
  "objective",
  "extractor_beta_mu_names",
  "extractor_beta_sigma_names",
  "extractor_sd_name",
  "extractor_random_block",
  names(truth_for),
  names(truth_columns),
  "prediction_identity_max_abs_error",
  "conditional_field_rmse",
  "conditional_field_correlation",
  "field_level_names",
  "truth_field_values",
  "estimate_field_values",
  "tree_hash",
  "K_hash",
  "Q_hash",
  "provider_object_hash",
  "session_manifest_hash"
)
missing <- setdiff(required, names(raw))
if (length(missing)) {
  stop(
    "Raw inputs lack columns: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

expected_rows <- length(expected_routes) * length(expected_M) * 400L
canonical_cells <- unique(route_contract$dgp_cell)
seed_manifest <- expand.grid(
  dgp_cell = canonical_cells,
  M = expected_M,
  replicate = seq_len(400L),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
seed_manifest <- seed_manifest[
  order(
    match(seed_manifest$dgp_cell, canonical_cells),
    seed_manifest$M,
    seed_manifest$replicate
  ),
  ,
  drop = FALSE
]
set.seed(master_seed)
seed_manifest$dgp_seed <- sample.int(
  .Machine$integer.max,
  nrow(seed_manifest),
  replace = FALSE
)
seed_manifest$master_seed <- master_seed

expected_schedule <- merge(
  route_contract,
  seed_manifest,
  by = "dgp_cell",
  all.x = TRUE,
  sort = FALSE
)
expected_schedule <- expected_schedule[
  order(
    match(expected_schedule$fit_route, expected_routes),
    expected_schedule$M,
    expected_schedule$replicate
  ),
  ,
  drop = FALSE
]
expected_schedule$global_fit_index <- seq_len(nrow(expected_schedule))
expected_schedule$fit_key <- paste(
  expected_schedule$fit_route,
  expected_schedule$M,
  expected_schedule$replicate,
  sep = ":"
)

assert(
  nrow(raw) == expected_rows,
  paste("Expected", expected_rows, "rows; got", nrow(raw))
)
assert(!anyDuplicated(raw$fit_key), "Duplicate immutable fit keys")
assert(!anyDuplicated(raw$global_fit_index), "Duplicate global fit indices")
assert(
  identical(sort(as.integer(raw$global_fit_index)), seq_len(expected_rows)),
  "Missing global fit indices"
)
assert(
  all(raw$attempted %in% TRUE),
  "At least one scheduled attempt is missing"
)
assert(
  identical(sort(unique(raw$fit_route)), sort(expected_routes)),
  "Route set differs from frozen manifest"
)
assert(
  identical(sort(unique(as.integer(raw$M))), expected_M),
  "M ladder differs from frozen manifest"
)
assert(all(raw$replicate %in% seq_len(400L)), "Replicate index outside 1:400")
assert(
  all(raw$phase == expected_mode),
  "Rows differ from the selected certification contract"
)
assert(
  all(raw$campaign_id == campaign_id),
  "Campaign ID differs from frozen manifest"
)
assert(
  length(unique(raw$source_commit_sha)) == 1L,
  "Multiple source commits in raw inputs"
)
assert(
  all(!is.na(raw$source_dirty) & raw$source_dirty == FALSE),
  "Every certification row must declare source_dirty=FALSE"
)
assert(
  grepl("^[0-9a-f]{40}$", unique(raw$source_commit_sha)),
  "Source commit is not one exact 40-character Git SHA"
)
assert(
  length(unique(raw$host)) == 1L &&
    !is.na(unique(raw$host)) &&
    nzchar(unique(raw$host)),
  "Certification rows lack one exact host"
)
assert(all(raw$n_per_level == 20L), "n_per_level differs from frozen value 20")
assert(all(raw$N == raw$M * 20L), "N is inconsistent with M * n_per_level")
for (name in names(truth_columns)) {
  assert(
    all(abs(raw[[name]] - truth_columns[[name]]) <= 1e-14),
    paste("Truth column differs from frozen manifest:", name)
  )
}
assert(length(unique(raw$shard_count)) == 1L, "Shard-count mismatch")
shard_count <- unique(raw$shard_count)[[1L]]
assert(
  identical(sort(unique(as.integer(raw$shard_index))), seq_len(shard_count)),
  "Missing shard index"
)
assert(
  length(raw_files) == shard_count,
  "Raw shard-file count differs from shard_count"
)

for (j in seq_along(raw_files)) {
  shard_id <- as.integer(sub(
    "^raw-shard-([0-9]+)\\.tsv$",
    "\\1",
    basename(raw_files[[j]])
  ))
  shard <- shards[[j]]
  assert(!is.na(shard_id), paste("Cannot parse shard ID from", raw_files[[j]]))
  assert(
    all(shard$shard_index == shard_id),
    paste("Raw file/shard_index mismatch for", shard_id)
  )
  assert(
    all(shard$shard_count == shard_count),
    paste("Raw shard_count mismatch for", shard_id)
  )
  expected_indices <- expected_schedule$global_fit_index[
    ((expected_schedule$global_fit_index - 1L) %% shard_count) + 1L == shard_id
  ]
  assert(
    identical(sort(as.integer(shard$global_fit_index)), expected_indices),
    paste("Deterministic index partition mismatch for shard", shard_id)
  )

  session_path <- file.path(
    input_dir,
    sprintf("session-shard-%d.txt", shard_id)
  )
  seed_path <- file.path(input_dir, sprintf("seeds-shard-%d.tsv", shard_id))
  assert(
    file.exists(session_path),
    paste("Missing session manifest for shard", shard_id)
  )
  assert(
    file.exists(seed_path),
    paste("Missing seed manifest for shard", shard_id)
  )
  session_lines <- readLines(session_path, warn = FALSE)
  session_hash <- sha256_file(session_path)
  assert(
    identical(unique(shard$session_manifest_hash), session_hash),
    paste("Session-manifest hash mismatch for shard", shard_id)
  )
  expected_session <- c(
    campaign_id = campaign_id,
    source_commit_sha = unique(raw$source_commit_sha),
    source_dirty = "FALSE",
    source_dirty_paths = "",
    host = unique(raw$host),
    mode = expected_mode,
    load = "installed",
    master_seed = as.character(master_seed),
    M = "16,32,64",
    n_per_level = "20",
    reps = "400",
    routes = paste(expected_routes, collapse = ","),
    shard_index = as.character(shard_id),
    shard_count = as.character(shard_count),
    OPENBLAS_NUM_THREADS = "1",
    OMP_NUM_THREADS = "1",
    MKL_NUM_THREADS = "1",
    TMB_NTHREADS = "1"
  )
  if (is_phylo_addendum) {
    expected_session <- c(
      expected_session,
      r_tree_sha = "84e4d7111a3514f119e5386d9299044aa78a36b7",
      src_tree_sha = "5e385ee36b910f907c807c5d5c3767b34e22a373"
    )
  }
  for (key in names(expected_session)) {
    assert(
      identical(manifest_value(session_lines, key), expected_session[[key]]),
      paste("Session manifest value mismatch for shard", shard_id, "key", key)
    )
  }
  session_command <- manifest_value(session_lines, "command")
  command_tokens <- c(
    "arc3a-positive-continuous-structured-mu-recovery.R",
    paste0("--mode=", expected_mode),
    "--load=installed",
    sprintf("--shard-index=%d", shard_id),
    sprintf("--shard-count=%d", shard_count),
    sprintf(
      "--output=%s",
      file.path(input_dir, sprintf("raw-shard-%d.tsv", shard_id))
    ),
    sprintf(
      "--seed-output=%s",
      file.path(input_dir, sprintf("seeds-shard-%d.tsv", shard_id))
    ),
    sprintf(
      "--session-output=%s",
      file.path(input_dir, sprintf("session-shard-%d.txt", shard_id))
    )
  )
  if (is_phylo_addendum) {
    command_tokens <- c(
      command_tokens,
      "--routes=gamma_phylo,lognormal_phylo"
    )
  }
  assert(
    all(vapply(
      command_tokens,
      grepl,
      logical(1),
      x = session_command,
      fixed = TRUE
    )),
    paste(
      "Session command does not authenticate installed certification execution for shard",
      shard_id
    )
  )
  shard_seeds <- utils::read.delim(
    seed_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  assert(
    isTRUE(all.equal(shard_seeds, seed_manifest, check.attributes = FALSE)),
    paste(
      "Seed manifest differs from canonical seed stream for shard",
      shard_id
    )
  )
}

raw_by_index <- raw[order(raw$global_fit_index), , drop = FALSE]
tuple_columns <- c(
  "global_fit_index",
  "fit_key",
  "fit_route",
  "dgp_cell",
  "family",
  "provider",
  "representation",
  "role",
  "M",
  "replicate",
  "dgp_seed"
)
assert(
  isTRUE(all.equal(
    raw_by_index[, tuple_columns],
    expected_schedule[, tuple_columns],
    check.attributes = FALSE
  )),
  "Raw Cartesian tuples or canonical global-index mapping differ from the frozen schedule"
)
assert(
  all(raw$fit_key == paste(raw$fit_route, raw$M, raw$replicate, sep = ":")),
  "fit_key is not canonical"
)

success_numeric <- c(
  "elapsed_seconds",
  "objective",
  names(truth_for),
  "prediction_identity_max_abs_error",
  "conditional_field_rmse",
  "conditional_field_correlation"
)
finite_success_values <- apply(
  raw[, success_numeric, drop = FALSE],
  1L,
  function(x) all(is.finite(as.numeric(x)))
)
expected_fit_success <-
  !is.na(raw$convergence_code) &
  raw$convergence_code == 0L &
  finite_success_values &
  raw$prediction_identity_max_abs_error <= 1e-8 &
  raw$extractor_beta_mu_names == "(Intercept);x" &
  raw$extractor_beta_sigma_names == "(Intercept)" &
  raw$extractor_sd_name == paste0(raw$provider, "(1 | id)") &
  raw$extractor_random_block == paste0(raw$provider, "_mu") &
  !is.na(raw$estimate_field_values) &
  nzchar(raw$estimate_field_values)
expected_fit_success[is.na(expected_fit_success)] <- FALSE
assert(
  identical(as.logical(raw$fit_success), expected_fit_success),
  "fit_success does not exactly reconstruct from convergence, targets, scale identity, and extractors"
)
expected_hessian_finite <- vapply(
  raw$hessian_covariance_values,
  function(x) {
    if (is.na(x) || !nzchar(x)) {
      return(FALSE)
    }
    values <- split_values(x)
    length(values) > 0L && all(is.finite(values))
  },
  logical(1),
  USE.NAMES = FALSE
)
assert(
  identical(as.logical(raw$hessian_diagnostic_finite), expected_hessian_finite),
  "hessian_diagnostic_finite does not reconstruct from retained covariance values"
)
expected_analysis_success <- expected_fit_success & expected_hessian_finite
assert(
  identical(as.logical(raw$analysis_success), expected_analysis_success),
  "analysis_success does not exactly equal fit_success plus a finite Hessian diagnostic"
)
fit_rows <- raw$fit_success %in% TRUE
assert(
  all(raw$convergence_code[fit_rows] == 0L) &&
    all(is.finite(as.matrix(raw[
      fit_rows,
      c("objective", names(truth_for)),
      drop = FALSE
    ]))),
  "A fit-success row has nonzero convergence or nonfinite targets"
)
assert(
  all(
    raw$boundary[fit_rows] ==
      (raw$estimate_tau[fit_rows] <= 0.05 | raw$estimate_tau[fit_rows] >= 2.00)
  ),
  "Boundary flag does not reconstruct from estimate_tau"
)
sigma_hat <- exp(raw$estimate_beta_sigma[fit_rows])
assert(
  all(raw$gross_sigma[fit_rows] == (sigma_hat < 0.0875 | sigma_hat > 1.40)),
  "Gross-sigma flag does not reconstruct from estimate_beta_sigma"
)
expected_failure_stage <- rep("nonfinite", nrow(raw))
expected_failure_stage[
  is.na(raw$provider_object_hash) &
    is.na(raw$field_level_names) &
    is.na(raw$truth_field_values) &
    is.na(raw$elapsed_seconds)
] <- "dgp"
expected_failure_stage[
  !is.na(raw$provider_object_hash) &
    !is.na(raw$field_level_names) &
    !is.na(raw$truth_field_values) &
    is.na(raw$elapsed_seconds)
] <- "provider_build"
expected_failure_stage[
  !is.na(raw$elapsed_seconds) & is.na(raw$convergence_code)
] <- "fit_error"
expected_failure_stage[
  !is.na(raw$convergence_code) & raw$convergence_code != 0L
] <- "optimizer"
expected_failure_stage[
  !is.na(raw$convergence_code) &
    raw$convergence_code == 0L &
    is.na(raw$extractor_beta_mu_names)
] <- "extractor"
expected_failure_stage[
  expected_fit_success & !expected_analysis_success
] <- "hessian"
expected_failure_stage[expected_analysis_success] <- "none"
assert(
  identical(as.character(raw$failure_stage), expected_failure_stage),
  "failure_stage does not exactly reconstruct from retained row state"
)
assert(
  all(is.finite(raw$prediction_identity_max_abs_error[
    raw$analysis_success %in% TRUE
  ])),
  "Nonfinite scale identity"
)
assert(
  all(
    raw$prediction_identity_max_abs_error[raw$analysis_success %in% TRUE] <=
      1e-8
  ),
  "Scale identity tolerance failure"
)
assert(
  all(nchar(raw$provider_object_hash) == 64L),
  "Missing or malformed provider-object hash"
)
assert(
  all(
    raw$provider_object_hash[raw$representation == "tree"] ==
      raw$tree_hash[raw$representation == "tree"]
  ) &&
    all(
      raw$provider_object_hash[raw$representation == "K"] ==
        raw$K_hash[raw$representation == "K"]
    ) &&
    all(
      raw$provider_object_hash[raw$representation == "Q"] ==
        raw$Q_hash[raw$representation == "Q"]
    ),
  "Provider-object hash does not match the selected representation"
)
for (M in expected_M) {
  expected_geometry <- geometry_contract[
    geometry_contract$M == M,
    ,
    drop = FALSE
  ]
  phylo_rows <- raw$M == M & raw$provider == "phylo"
  relmat_rows <- raw$M == M & raw$provider == "relmat"
  assert(
    all(raw$tree_hash[phylo_rows] == expected_geometry$tree_hash),
    paste("Balanced-tree hash differs from the frozen geometry at M=", M)
  )
  assert(
    all(raw$K_hash[relmat_rows] == expected_geometry$K_hash) &&
      all(raw$Q_hash[relmat_rows] == expected_geometry$Q_hash),
    paste("K/Q hashes differ from the frozen AR(1) geometry at M=", M)
  )
}

chol_contract <- list()
gls_contract <- list()
for (M in expected_M) {
  phylo_covariance <- balanced_tree_covariance(balanced_tree(M))
  chol_contract[[paste("phylo", M, sep = "_")]] <- chol(phylo_covariance)
  chol_contract[[paste("relmat", M, sep = "_")]] <- chol(relatedness(M))
  gls_contract[[as.character(M)]] <- list(
    covariance = phylo_covariance,
    middle_inverse = solve(
      solve(phylo_covariance) /
        truth_columns[["truth_tau"]]^2 +
        diag(20 / exp(truth_columns[["truth_beta_sigma"]])^2, M)
    )
  )
}
raw$design_oracle_variance <- NA_real_
raw$structured_intercept_projection <- NA_real_
raw$arithmetic_field_mean <- NA_real_
for (i in seq_len(nrow(raw))) {
  labels <- strsplit(raw$field_level_names[[i]], ";", fixed = TRUE)[[1L]]
  expected_labels <- sprintf("g%03d", seq_len(raw$M[[i]]))
  assert(
    identical(labels, expected_labels),
    paste("Field-level names differ at", raw$fit_key[[i]])
  )
  set.seed(raw$dgp_seed[[i]])
  expected_field <- as.vector(
    t(chol_contract[[paste(raw$provider[[i]], raw$M[[i]], sep = "_")]]) %*%
      stats::rnorm(raw$M[[i]])
  ) *
    truth_columns[["truth_tau"]]
  expected_x <- stats::rnorm(raw$N[[i]])
  observed_truth <- split_values(raw$truth_field_values[[i]])
  assert(
    length(observed_truth) == raw$M[[i]] &&
      max(abs(observed_truth - expected_field)) <= 1e-12,
    paste(
      "Truth field differs from seed and frozen geometry at",
      raw$fit_key[[i]]
    )
  )
  if (identical(raw$provider[[i]], "phylo")) {
    M <- raw$M[[i]]
    n_per_level <- raw$n_per_level[[i]]
    sigma2 <- exp(truth_columns[["truth_beta_sigma"]])^2
    group_index <- rep(seq_len(M), each = n_per_level)
    group_x_sum <- as.numeric(rowsum(expected_x, group_index, reorder = FALSE))
    ZtX <- cbind(rep(n_per_level, M), group_x_sum)
    XtX <- crossprod(cbind(1, expected_x))
    middle_inverse <- gls_contract[[as.character(M)]]$middle_inverse
    XtVinvX <- XtX / sigma2 - crossprod(ZtX, middle_inverse %*% ZtX) / sigma2^2
    XtVinvZb <- crossprod(ZtX, expected_field) /
      sigma2 -
      crossprod(
        ZtX,
        middle_inverse %*% (n_per_level * expected_field)
      ) /
        sigma2^2
    raw$design_oracle_variance[[i]] <- solve(XtVinvX)[1L, 1L]
    raw$structured_intercept_projection[[i]] <-
      solve(XtVinvX, XtVinvZb)[[1L]]
    raw$arithmetic_field_mean[[i]] <- mean(expected_field)
  }
  if (raw$analysis_success[[i]] %in% TRUE) {
    estimate_field <- split_values(raw$estimate_field_values[[i]])
    assert(
      length(estimate_field) == raw$M[[i]],
      paste("Estimated field length mismatch at", raw$fit_key[[i]])
    )
    field_rmse <- sqrt(mean((estimate_field - observed_truth)^2))
    field_correlation <- stats::cor(estimate_field, observed_truth)
    assert(
      isTRUE(all.equal(
        field_rmse,
        raw$conditional_field_rmse[[i]],
        tolerance = 1e-12
      )) &&
        isTRUE(all.equal(
          field_correlation,
          raw$conditional_field_correlation[[i]],
          tolerance = 1e-12
        )),
      paste(
        "Recorded field recovery metrics do not reconstruct at",
        raw$fit_key[[i]]
      )
    )
  }
}

raw_by_index <- raw[order(raw$global_fit_index), , drop = FALSE]
raw <- raw_by_index
raw$beta0_error_minus_structured_projection <-
  raw$estimate_beta0 -
  truth_for[["estimate_beta0"]] -
  raw$structured_intercept_projection
combined_raw <- file.path(
  output_dir,
  if (is_phylo_addendum) {
    "arc3a-phylo-addendum-combined-raw.tsv"
  } else {
    "arc3a-certification-combined-raw.tsv"
  }
)
write_tsv(raw, combined_raw)

safe_quantile <- function(x, probability) {
  x <- x[is.finite(x)]
  if (!length(x)) {
    return(NA_real_)
  }
  unname(stats::quantile(x, probability, names = FALSE))
}
safe_median <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) {
    return(NA_real_)
  }
  stats::median(x)
}

route_summary <- do.call(
  rbind,
  lapply(expected_routes, function(route) {
    do.call(
      rbind,
      lapply(expected_M, function(M) {
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
          field_correlation_median = safe_median(z$conditional_field_correlation[
            z$analysis_success %in% TRUE
          ]),
          field_correlation_q10 = safe_quantile(
            z$conditional_field_correlation[z$analysis_success %in% TRUE],
            0.10
          ),
          field_correlation_q90 = safe_quantile(
            z$conditional_field_correlation[z$analysis_success %in% TRUE],
            0.90
          ),
          field_rmse_median = safe_median(z$conditional_field_rmse[
            z$analysis_success %in% TRUE
          ]),
          field_rmse_q10 = safe_quantile(
            z$conditional_field_rmse[z$analysis_success %in% TRUE],
            0.10
          ),
          field_rmse_q90 = safe_quantile(
            z$conditional_field_rmse[z$analysis_success %in% TRUE],
            0.90
          ),
          elapsed_seconds_median = safe_median(z$elapsed_seconds),
          elapsed_seconds_q10 = safe_quantile(z$elapsed_seconds, 0.10),
          elapsed_seconds_q90 = safe_quantile(z$elapsed_seconds, 0.90),
          fit_gate = sum(z$fit_success %in% TRUE) >= 380L,
          pdHess_gate = sum(z$pdHess %in% TRUE) >= 380L,
          boundary_gate = sum(z$boundary %in% TRUE) <= 8L,
          gross_sigma_gate = sum(z$gross_sigma %in% TRUE) <= 8L,
          field_gate = isTRUE(
            safe_median(z$conditional_field_correlation[
              z$analysis_success %in% TRUE
            ]) >=
              0.80 &&
              safe_median(z$conditional_field_rmse[
                z$analysis_success %in% TRUE
              ]) <=
                0.25
          ),
          stringsAsFactors = FALSE
        )
      })
    )
  })
)

target_summary <- do.call(
  rbind,
  lapply(expected_routes, function(route) {
    do.call(
      rbind,
      lapply(expected_M, function(M) {
        z <- raw[raw$fit_route == route & raw$M == M, , drop = FALSE]
        do.call(
          rbind,
          lapply(names(truth_for), function(target) {
            estimates <- z[[target]][
              z$analysis_success %in% TRUE & is.finite(z[[target]])
            ]
            truth <- unname(truth_for[[target]])
            errors <- estimates - truth
            assert(
              length(estimates) > 0L,
              paste("No analysis-success estimates for", route, M, target)
            )
            set.seed(
              summary_seed +
                match(route, expected_routes) * 100L +
                M +
                match(target, names(truth_for))
            )
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
              mean_estimate = mean(estimates),
              bias = mean(errors),
              median_error = stats::median(errors),
              error_q05 = unname(stats::quantile(errors, 0.05, names = FALSE)),
              error_q95 = unname(stats::quantile(errors, 0.95, names = FALSE)),
              bias_mcse = stats::sd(errors) / sqrt(length(errors)),
              rmse = sqrt(mean(errors^2)),
              rmse_mcse_bootstrap = stats::sd(boot_rmse),
              stringsAsFactors = FALSE
            )
          })
        )
      })
    )
  })
)

parity_rows <- if (is_phylo_addendum) {
  data.frame(
    M = integer(),
    attempts = integer(),
    jointly_analysis_successful = integer(),
    success_status_mismatch = integer(),
    objective_delta_max = numeric(),
    fixed_delta_max = numeric(),
    tau_delta_max = numeric(),
    field_delta_max = numeric(),
    tolerance_failures = integer(),
    availability_gate = logical(),
    numerical_gate = logical()
  )
} else {
  do.call(
    rbind,
    lapply(expected_M, function(M) {
      K <- raw[
        raw$fit_route == "lognormal_relmat_K" & raw$M == M,
        ,
        drop = FALSE
      ]
      Q <- raw[
        raw$fit_route == "lognormal_relmat_Q" & raw$M == M,
        ,
        drop = FALSE
      ]
      pair <- merge(
        K,
        Q,
        by = c("M", "replicate", "dgp_seed"),
        suffixes = c("_K", "_Q"),
        sort = TRUE
      )
      assert(nrow(pair) == 400L, paste("K/Q pairing incomplete at M=", M))
      joint <- pair$analysis_success_K %in%
        TRUE &
        pair$analysis_success_Q %in% TRUE
      mismatch <- xor(
        pair$analysis_success_K %in% TRUE,
        pair$analysis_success_Q %in% TRUE
      )
      objective_delta <- abs(pair$objective_K - pair$objective_Q)
      fixed_delta <- pmax(
        abs(pair$estimate_beta0_K - pair$estimate_beta0_Q),
        abs(pair$estimate_beta_x_K - pair$estimate_beta_x_Q),
        abs(pair$estimate_beta_sigma_K - pair$estimate_beta_sigma_Q)
      )
      tau_delta <- abs(pair$estimate_tau_K - pair$estimate_tau_Q)
      field_delta <- rep(NA_real_, nrow(pair))
      for (i in which(joint)) {
        k_names <- strsplit(pair$field_level_names_K[[i]], ";", fixed = TRUE)[[
          1L
        ]]
        q_names <- strsplit(pair$field_level_names_Q[[i]], ";", fixed = TRUE)[[
          1L
        ]]
        k <- stats::setNames(
          split_values(pair$estimate_field_values_K[[i]]),
          k_names
        )
        q <- stats::setNames(
          split_values(pair$estimate_field_values_Q[[i]]),
          q_names
        )
        assert(
          identical(sort(names(k)), sort(names(q))),
          "K/Q conditional-field level mismatch"
        )
        field_delta[[i]] <- max(abs(k[sort(names(k))] - q[sort(names(q))]))
      }
      failures <- joint &
        (objective_delta > 1e-6 |
          fixed_delta > 1e-5 |
          tau_delta > 1e-5 |
          field_delta > 1e-4)
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
    })
  )
}

route_decision <- do.call(
  rbind,
  lapply(expected_routes, function(route) {
    rs <- route_summary[route_summary$fit_route == route, , drop = FALSE]
    ts <- target_summary[target_summary$fit_route == route, , drop = FALSE]
    final <- ts[ts$M == 64L, , drop = FALSE]
    early <- ts[ts$M == 16L, c("target", "rmse"), drop = FALSE]
    names(early)[[2L]] <- "rmse_M16"
    final <- merge(final, early, by = "target", all.x = TRUE, sort = FALSE)
    fixed <- final$target != "tau"
    if (is_phylo_addendum) {
      beta0 <- ts[ts$target == "beta0", , drop = FALSE]
      beta0$oracle_rmse <- vapply(
        beta0$M,
        function(M) {
          z <- raw[
            raw$fit_route == route &
              raw$M == M &
              raw$analysis_success %in% TRUE,
            ,
            drop = FALSE
          ]
          sqrt(mean(z$design_oracle_variance))
        },
        numeric(1),
        USE.NAMES = FALSE
      )
      beta0$oracle_ratio <- beta0$rmse / beta0$oracle_rmse
      decomp <- do.call(
        rbind,
        lapply(expected_M, function(M) {
          z <- raw[
            raw$fit_route == route &
              raw$M == M &
              raw$analysis_success %in% TRUE,
            ,
            drop = FALSE
          ]
          data.frame(
            M = M,
            structured_projection_correlation = stats::cor(
              z$estimate_beta0 - truth_for[["estimate_beta0"]],
              z$structured_intercept_projection
            ),
            residual_rmse = sqrt(mean(
              z$beta0_error_minus_structured_projection^2
            ))
          )
        })
      )
      beta0_final <- final$target == "beta0"
      other_fixed <- fixed & !beta0_final
      bias_gate <-
        abs(final$bias[beta0_final]) <= 0.05 &&
        all(abs(final$bias[other_fixed]) <= 0.05) &&
        all(abs(final$bias[!fixed]) <= 0.075)
      oracle_gate <- all(
        beta0$oracle_ratio >= 0.80 & beta0$oracle_ratio <= 1.20
      )
      decomposition_gate <- all(
        decomp$structured_projection_correlation >= 0.95 &
          decomp$residual_rmse <= 0.05
      )
      rmse_gate <-
        oracle_gate &&
        decomposition_gate &&
        all(final$rmse[other_fixed] <= 0.12) &&
        all(final$rmse[!fixed] <= 0.125)
      information_gate <-
        beta0$rmse[beta0$M == 64L] <= beta0$rmse[beta0$M == 16L] &&
        all(final$rmse[other_fixed] <= final$rmse_M16[other_fixed]) &&
        all(final$rmse[!fixed] <= 0.85 * final$rmse_M16[!fixed])
    } else {
      oracle_gate <- NA
      decomposition_gate <- NA
      bias_gate <- all(abs(final$bias[fixed]) <= 0.05) &&
        all(abs(final$bias[!fixed]) <= 0.075)
      rmse_gate <- all(final$rmse[fixed] <= 0.12) &&
        all(final$rmse[!fixed] <= 0.125)
      information_gate <- all(final$rmse[fixed] <= final$rmse_M16[fixed]) &&
        all(final$rmse[!fixed] <= 0.85 * final$rmse_M16[!fixed])
    }
    mcse_gate <- all(final$bias_mcse <= 0.025) &&
      all(final$rmse_mcse_bootstrap <= 0.025)
    nonparity_gate <- all(
      rs$fit_gate &
        rs$pdHess_gate &
        rs$boundary_gate &
        rs$gross_sigma_gate &
        rs$field_gate
    ) &&
      bias_gate &&
      rmse_gate &&
      information_gate &&
      mcse_gate
    data.frame(
      fit_route = route,
      rung_gates = all(
        rs$fit_gate &
          rs$pdHess_gate &
          rs$boundary_gate &
          rs$gross_sigma_gate &
          rs$field_gate
      ),
      final_bias_gate = bias_gate,
      final_rmse_gate = rmse_gate,
      intercept_oracle_gate = oracle_gate,
      structured_projection_decomposition_gate = decomposition_gate,
      information_response_gate = information_gate,
      mcse_gate = mcse_gate,
      nonparity_pass = nonparity_gate,
      stringsAsFactors = FALSE
    )
  })
)

route_pass <- stats::setNames(
  route_decision$nonparity_pass,
  route_decision$fit_route
)
if (is_phylo_addendum) {
  parity_pass <- primary_authentication$parity_pass
  comparator_pass <- primary_authentication$comparator_pass
  shared_gate_pass <- primary_authentication$shared_gate_pass
  cell_decision <- data.frame(
    cell = c("gamma_phylo", "lognormal_phylo"),
    prior_state = c("implemented", "implemented"),
    certification_pass = c(
      route_pass[["gamma_phylo"]] && shared_gate_pass,
      route_pass[["lognormal_phylo"]] && shared_gate_pass
    ),
    shared_gate_pass = shared_gate_pass,
    resulting_state = NA_character_,
    stringsAsFactors = FALSE
  )
} else {
  parity_pass <- all(parity_rows$availability_gate & parity_rows$numerical_gate)
  comparator_pass <- isTRUE(route_pass[["gamma_relmat_K"]])
  shared_gate_pass <- parity_pass && comparator_pass
  cell_decision <- data.frame(
    cell = c(
      "gamma_phylo",
      "lognormal_phylo",
      "lognormal_relmat",
      "gamma_relmat_comparator"
    ),
    prior_state = c(
      "implemented",
      "implemented",
      "implemented",
      "point_fit_recovery"
    ),
    certification_pass = c(
      route_pass[["gamma_phylo"]] && shared_gate_pass,
      route_pass[["lognormal_phylo"]] && shared_gate_pass,
      route_pass[["lognormal_relmat_K"]] &&
        route_pass[["lognormal_relmat_Q"]] &&
        shared_gate_pass,
      comparator_pass
    ),
    shared_gate_pass = c(rep(shared_gate_pass, 3L), comparator_pass),
    resulting_state = NA_character_,
    stringsAsFactors = FALSE
  )
}
cell_decision$resulting_state <- ifelse(
  cell_decision$certification_pass,
  "point_fit_recovery",
  cell_decision$prior_state
)

failure_stage <- as.data.frame(
  table(raw$fit_route, raw$M, raw$failure_stage),
  stringsAsFactors = FALSE
)
names(failure_stage) <- c("fit_route", "M", "failure_stage", "count")
failure_stage <- failure_stage[failure_stage$count > 0L, , drop = FALSE]

oracle_diagnostics <- if (is_phylo_addendum) {
  do.call(
    rbind,
    lapply(expected_routes, function(route) {
      do.call(
        rbind,
        lapply(expected_M, function(M) {
          target <- target_summary[
            target_summary$fit_route == route &
              target_summary$M == M &
              target_summary$target == "beta0",
            ,
            drop = FALSE
          ]
          z <- raw[
            raw$fit_route == route &
              raw$M == M &
              raw$analysis_success %in% TRUE,
            ,
            drop = FALSE
          ]
          closed_form_oracle_rmse <- sqrt(
            0.50^2 * (1 - 1 / M) / log2(M) + 0.35^2 / (20 * M)
          )
          design_adjusted_oracle_rmse <- sqrt(mean(z$design_oracle_variance))
          data.frame(
            fit_route = route,
            M = M,
            attempted = sum(raw$fit_route == route & raw$M == M),
            conditional_n = nrow(z),
            closed_form_oracle_rmse = closed_form_oracle_rmse,
            design_adjusted_oracle_rmse = design_adjusted_oracle_rmse,
            observed_rmse = target$rmse,
            observed_oracle_ratio = target$rmse / design_adjusted_oracle_rmse,
            rmse_mcse_bootstrap = target$rmse_mcse_bootstrap,
            beta0_bias = target$bias,
            beta0_bias_mcse = target$bias_mcse,
            structured_projection_correlation = stats::cor(
              z$estimate_beta0 - truth_for[["estimate_beta0"]],
              z$structured_intercept_projection
            ),
            residual_rmse_after_structured_projection = sqrt(
              mean(z$beta0_error_minus_structured_projection^2)
            ),
            arithmetic_field_mean_correlation = stats::cor(
              z$estimate_beta0 - truth_for[["estimate_beta0"]],
              z$arithmetic_field_mean
            ),
            oracle_ratio_gate = target$rmse / design_adjusted_oracle_rmse >=
              0.80 &&
              target$rmse / design_adjusted_oracle_rmse <= 1.20,
            decomposition_gate = stats::cor(
              z$estimate_beta0 - truth_for[["estimate_beta0"]],
              z$structured_intercept_projection
            ) >=
              0.95 &&
              sqrt(mean(z$beta0_error_minus_structured_projection^2)) <= 0.05,
            stringsAsFactors = FALSE
          )
        })
      )
    })
  )
} else {
  NULL
}

paths <- c(
  route_summary = file.path(output_dir, "route-rung-summary.tsv"),
  target_summary = file.path(output_dir, "target-recovery-summary.tsv"),
  parity_summary = file.path(output_dir, "kq-parity-summary.tsv"),
  route_decision = file.path(output_dir, "route-decisions.tsv"),
  cell_decision = file.path(output_dir, "cell-decisions.tsv"),
  failure_stage = file.path(output_dir, "failure-stage-counts.tsv")
)
if (is_phylo_addendum) {
  paths <- c(
    paths,
    oracle_diagnostics = file.path(
      output_dir,
      "intercept-oracle-diagnostics.tsv"
    )
  )
}
write_tsv(route_summary, paths[["route_summary"]])
write_tsv(target_summary, paths[["target_summary"]])
write_tsv(parity_rows, paths[["parity_summary"]])
write_tsv(route_decision, paths[["route_decision"]])
write_tsv(cell_decision, paths[["cell_decision"]])
write_tsv(failure_stage, paths[["failure_stage"]])
if (is_phylo_addendum) {
  write_tsv(oracle_diagnostics, paths[["oracle_diagnostics"]])
}

manifest_path <- file.path(output_dir, "summary-manifest.txt")
manifest <- c(
  paste0("campaign_id=", campaign_id),
  paste0("contract=", args$contract),
  paste0("source_commit_sha=", unique(raw$source_commit_sha)),
  paste0("hosts=", paste(sort(unique(raw$host)), collapse = ",")),
  paste0("worker_count=", shard_count),
  paste0("attempted_rows=", nrow(raw)),
  paste0("fit_success=", sum(raw$fit_success %in% TRUE)),
  paste0("analysis_success=", sum(raw$analysis_success %in% TRUE)),
  paste0("summary_seed=", summary_seed),
  paste0("bootstrap_reps=", args$bootstrap_reps),
  paste0("combined_raw_sha256=", sha256_file(combined_raw)),
  vapply(
    names(paths),
    function(name) paste0(name, "_sha256=", sha256_file(paths[[name]])),
    character(1)
  ),
  paste0(
    "all_new_cells_pass=",
    all(cell_decision$certification_pass[
      cell_decision$cell != "gamma_relmat_comparator"
    ])
  ),
  paste0("comparator_pass=", comparator_pass),
  paste0("kq_parity_pass=", parity_pass),
  paste0("shared_gate_pass=", shared_gate_pass),
  if (is_phylo_addendum) {
    c(
      paste0(
        "primary_combined_raw_sha256=",
        primary_authentication$observed_hashes[[
          "arc3a-certification-combined-raw.tsv"
        ]]
      ),
      paste0(
        "primary_cell_decision_sha256=",
        primary_authentication$observed_hashes[["cell-decisions.tsv"]]
      ),
      paste0(
        "primary_route_decision_sha256=",
        primary_authentication$observed_hashes[["route-decisions.tsv"]]
      ),
      paste0(
        "primary_parity_summary_sha256=",
        primary_authentication$observed_hashes[["kq-parity-summary.tsv"]]
      ),
      paste0(
        "primary_comparator_pass=",
        primary_authentication$comparator_pass
      ),
      paste0("primary_kq_parity_pass=", primary_authentication$parity_pass),
      paste0(
        "primary_shared_gate_pass=",
        primary_authentication$shared_gate_pass
      )
    )
  },
  capture.output(sessionInfo())
)
writeLines(manifest, manifest_path)

message("combined_raw=", combined_raw)
message("combined_raw_sha256=", sha256_file(combined_raw))
message("summary_manifest=", manifest_path)
message("cell_decisions:")
print(cell_decision, row.names = FALSE)
