#!/usr/bin/env Rscript
# Arc 4c DRAC/Fir dispatch planner.
#
# This is deliberately a pure-logic planning tool: it never calls sbatch, never
# loads drmTMB, and never runs a fit.  The campaign workers consume the manifest
# it writes only after the separate compute-approval gate has been crossed.

arc4c_cells <- data.frame(
  cell_id = c("mc-0464", "mc-0539", "mc-0575"),
  family = c("skew_normal", "tweedie", "zero_one_beta"),
  family_index = 1:3,
  stringsAsFactors = FALSE
)
arc4c_M <- c(8L, 16L, 32L, 64L)
arc4c_shards_per_cell <- 120L
arc4c_replicates_per_shard <- 10L
arc4c_max_concurrency <- 96L
arc4c_preflight_required_keys <- c(
  "merge_sha", "head_sha", "tree_sha", "git_status", "source_tree_sha256",
  "dll_sha256", "R_LIBS", "R_version", "gcc_version", "TMB_version",
  "module_list", "session_info", "module_list_sha256", "session_info_sha256"
)

arc4c_stop <- function(...) stop(..., call. = FALSE)

arc4c_assert_scalar_integer <- function(x, name, lower = 1L) {
  if (length(x) != 1L || is.na(x) || !is.finite(x) || x != as.integer(x) || x < lower) {
    arc4c_stop(name, " must be an integer >= ", lower, ".")
  }
  as.integer(x)
}

arc4c_validate_cell_m <- function(x, require_unique = TRUE) {
  required <- c("cell_id", "M")
  missing <- setdiff(required, names(x))
  if (length(missing)) arc4c_stop("Missing required column(s): ", paste(missing, collapse = ", "), ".")
  x$cell_id <- as.character(x$cell_id)
  x$M <- suppressWarnings(as.integer(x$M))
  if (anyNA(x$M) || any(!x$cell_id %in% arc4c_cells$cell_id) || any(!x$M %in% arc4c_M)) {
    arc4c_stop("cell_id/M entries must use the frozen Arc 4c grid.")
  }
  if (require_unique && anyDuplicated(x[c("cell_id", "M")])) {
    arc4c_stop("Each Arc 4c cell/M combination must occur exactly once.")
  }
  x
}

# Immutable across all smoke selections.  The dense array_index is intentionally
# separate, and is assigned only after selection, so Slurm can use 1..n while
# evidence IDs remain stable over retries and M=8 exclusions.
arc4c_logical_task_id <- function(cell_id, M, shard) {
  shard <- arc4c_assert_scalar_integer(shard, "shard", 1L)
  if (shard > arc4c_shards_per_cell) arc4c_stop("shard must be <= 120.")
  cell_row <- match(cell_id, arc4c_cells$cell_id)
  m_index <- match(as.integer(M), arc4c_M)
  if (is.na(cell_row) || is.na(m_index)) arc4c_stop("Unknown Arc 4c cell_id/M combination.")
  as.integer(((cell_row - 1L) * length(arc4c_M) + (m_index - 1L)) * arc4c_shards_per_cell + shard)
}

arc4c_make_full_manifest <- function(approved) {
  approved <- arc4c_validate_cell_m(approved)
  if (nrow(approved) < 1L) arc4c_stop("At least one smoke-approved cell/M combination is required.")
  approved <- approved[order(match(approved$cell_id, arc4c_cells$cell_id), match(approved$M, arc4c_M)), , drop = FALSE]
  rows <- lapply(seq_len(nrow(approved)), function(i) {
    shard <- seq_len(arc4c_shards_per_cell)
    data.frame(
      logical_task_id = vapply(shard, function(k) arc4c_logical_task_id(approved$cell_id[[i]], approved$M[[i]], k), integer(1)),
      cell_id = approved$cell_id[[i]],
      family = arc4c_cells$family[match(approved$cell_id[[i]], arc4c_cells$cell_id)],
      M = approved$M[[i]],
      shard = shard,
      replicate_start = (shard - 1L) * arc4c_replicates_per_shard + 1L,
      replicate_end = shard * arc4c_replicates_per_shard,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out <- out[order(out$logical_task_id), , drop = FALSE]
  out$array_index <- seq_len(nrow(out))
  out <- out[c("array_index", "logical_task_id", "cell_id", "family", "M", "shard", "replicate_start", "replicate_end")]
  rownames(out) <- NULL
  if (anyDuplicated(out$logical_task_id) || anyDuplicated(out$array_index) ||
      any(out$replicate_end - out$replicate_start != arc4c_replicates_per_shard - 1L)) {
    arc4c_stop("Arc 4c full manifest failed its bijection invariant.")
  }
  out
}

arc4c_make_smoke_manifest <- function() {
  grid <- expand.grid(cell_id = arc4c_cells$cell_id, M = arc4c_M, stringsAsFactors = FALSE)
  grid <- grid[order(match(grid$cell_id, arc4c_cells$cell_id), match(grid$M, arc4c_M)), , drop = FALSE]
  grid$family <- arc4c_cells$family[match(grid$cell_id, arc4c_cells$cell_id)]
  grid$logical_task_id <- seq_len(nrow(grid))
  grid$array_index <- seq_len(nrow(grid))
  grid$shard <- 0L
  grid$replicate_start <- 1L
  grid$replicate_end <- 1L
  grid[c("array_index", "logical_task_id", "cell_id", "family", "M", "shard", "replicate_start", "replicate_end")]
}

arc4c_select_smoke <- function(smoke) {
  smoke <- arc4c_validate_cell_m(smoke)
  if (!"smoke_pass" %in% names(smoke)) arc4c_stop("Smoke results require a smoke_pass column.")
  if (nrow(smoke) != nrow(arc4c_make_smoke_manifest())) arc4c_stop("Smoke results must contain all 12 frozen family/M cells.")
  expected <- arc4c_make_smoke_manifest()[c("cell_id", "M")]
  if (!identical(smoke[order(match(smoke$cell_id, arc4c_cells$cell_id), match(smoke$M, arc4c_M)), c("cell_id", "M")], expected)) {
    arc4c_stop("Smoke results do not match the frozen 12-cell grid.")
  }
  smoke$smoke_pass <- as.logical(smoke$smoke_pass)
  if (anyNA(smoke$smoke_pass)) arc4c_stop("Smoke result smoke_pass values must be TRUE or FALSE.")
  out <- lapply(seq_len(nrow(arc4c_cells)), function(i) {
    cell <- arc4c_cells$cell_id[[i]]
    x <- smoke[smoke$cell_id == cell, , drop = FALSE]
    nonexploratory_ok <- all(x$smoke_pass[x$M >= 16L])
    data.frame(
      cell_id = cell,
      family = arc4c_cells$family[[i]],
      M8_smoke_pass = x$smoke_pass[x$M == 8L],
      nonexploratory_smoke_pass = nonexploratory_ok,
      family_status = if (nonexploratory_ok) "eligible_for_full_array" else "halted_nonexploratory_smoke_failure",
      stringsAsFactors = FALSE
    )
  })
  family <- do.call(rbind, out)
  approved <- merge(smoke[smoke$smoke_pass, c("cell_id", "M")], family[c("cell_id", "nonexploratory_smoke_pass")], by = "cell_id", sort = FALSE)
  approved <- approved[approved$nonexploratory_smoke_pass, c("cell_id", "M"), drop = FALSE]
  approved <- approved[order(match(approved$cell_id, arc4c_cells$cell_id), match(approved$M, arc4c_M)), , drop = FALSE]
  list(family = family, approved = approved)
}

arc4c_partition_manifest <- function(manifest, max_array_size, concurrency = arc4c_max_concurrency) {
  manifest <- manifest[order(manifest$array_index), , drop = FALSE]
  max_array_size <- arc4c_assert_scalar_integer(max_array_size, "max_array_size")
  concurrency <- arc4c_assert_scalar_integer(concurrency, "concurrency")
  if (concurrency > arc4c_max_concurrency) arc4c_stop("Global Arc 4c concurrency cannot exceed 96.")
  n_partitions <- ceiling(nrow(manifest) / max_array_size)
  if (n_partitions > arc4c_max_concurrency) arc4c_stop("BLOCKED_RESOURCE_LAYOUT: more than 96 Slurm array partitions would be required.")
  partition_id <- rep(seq_len(n_partitions), each = max_array_size, length.out = nrow(manifest))
  parts <- split(manifest, partition_id)
  caps <- rep(floor(concurrency / n_partitions), n_partitions)
  caps[seq_len(concurrency %% n_partitions)] <- caps[seq_len(concurrency %% n_partitions)] + 1L
  plan <- do.call(rbind, lapply(seq_along(parts), function(i) {
    x <- parts[[i]]
    data.frame(
      partition_id = i,
      array_start = 1L,
      array_end = nrow(x),
      n_tasks = nrow(x),
      concurrency_cap = caps[[i]],
      logical_task_min = min(x$logical_task_id),
      logical_task_max = max(x$logical_task_id),
      stringsAsFactors = FALSE
    )
  }))
  if (sum(plan$concurrency_cap) > arc4c_max_concurrency || any(plan$n_tasks > max_array_size)) {
    arc4c_stop("Arc 4c partition plan violated a scheduler resource invariant.")
  }
  list(partitions = parts, plan = plan)
}

arc4c_size_resources <- function(max_smoke_minutes, max_smoke_rss_gb) {
  if (length(max_smoke_minutes) != 1L || !is.finite(max_smoke_minutes) || max_smoke_minutes <= 0 ||
      length(max_smoke_rss_gb) != 1L || !is.finite(max_smoke_rss_gb) || max_smoke_rss_gb <= 0) {
    arc4c_stop("Smoke duration and RSS must be positive finite scalars.")
  }
  wall_minutes <- max(30, ceiling((5 * max_smoke_minutes * arc4c_replicates_per_shard) / 15) * 15)
  memory_gb <- max(4, ceiling(2 * max_smoke_rss_gb))
  if (wall_minutes > 12 * 60) arc4c_stop("BLOCKED_RESOURCE_SIZING: computed walltime exceeds 12 hours.")
  if (memory_gb > 32) arc4c_stop("BLOCKED_RESOURCE_SIZING: computed memory exceeds 32 GB.")
  data.frame(wall_minutes = wall_minutes, memory_gb = memory_gb, stringsAsFactors = FALSE)
}

# Pure validator for the receipt that the separate compute-node preflight writes.
# The shell workers additionally verify the receipt checksum and current source.
arc4c_validate_preflight_receipt <- function(receipt, expected_merge_sha = NULL) {
  if (!all(c("key", "value") %in% names(receipt))) arc4c_stop("Preflight receipt requires key and value columns.")
  if (anyDuplicated(receipt$key)) arc4c_stop("Preflight receipt keys must be unique.")
  missing <- setdiff(arc4c_preflight_required_keys, receipt$key)
  if (length(missing)) arc4c_stop("Preflight receipt is incomplete: ", paste(missing, collapse = ", "), ".")
  get <- stats::setNames(receipt$value, receipt$key)
  if (!identical(get[["git_status"]], "clean")) arc4c_stop("Preflight receipt does not certify a clean source clone.")
  if (!is.null(expected_merge_sha) && !identical(get[["merge_sha"]], expected_merge_sha)) {
    arc4c_stop("Preflight receipt merge SHA does not match the required PR-A merge SHA.")
  }
  invisible(get)
}

arc4c_write_partitioned_manifest <- function(manifest, out_dir, max_array_size, concurrency = arc4c_max_concurrency) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- arc4c_partition_manifest(manifest, max_array_size, concurrency)
  utils::write.table(manifest, file.path(out_dir, "arc4c-full-manifest.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  utils::write.table(plan$plan, file.path(out_dir, "arc4c-array-partitions.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  for (i in seq_along(plan$partitions)) {
    x <- plan$partitions[[i]]
    x$array_index <- seq_len(nrow(x))
    utils::write.table(x, file.path(out_dir, sprintf("arc4c-full-manifest-partition-%03d.tsv", i)), sep = "\t", row.names = FALSE, quote = FALSE)
  }
  invisible(plan)
}

arc4c_parse_args <- function(args) {
  out <- list()
  for (arg in args) {
    if (!grepl("^--[A-Za-z][A-Za-z-]*=.+$", arg)) arc4c_stop("Arguments must use nonempty --name=value syntax.")
    pair <- strsplit(substring(arg, 3L), "=", fixed = TRUE)[[1L]]
    if (!is.null(out[[pair[[1L]]]])) arc4c_stop("Duplicate argument: --", pair[[1L]], ".")
    out[[pair[[1L]]]] <- paste(pair[-1L], collapse = "=")
  }
  out
}
arc4c_need <- function(args, name) if (is.null(args[[name]]) || !nzchar(args[[name]])) arc4c_stop("Missing --", name, "= argument.") else args[[name]]

arc4c_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  a <- arc4c_parse_args(args)
  mode <- arc4c_need(a, "mode")
  allowed <- switch(mode,
    "smoke-manifest" = c("mode", "out"),
    "select-smoke" = c("mode", "smoke", "family-out", "approved-out"),
    "full-manifest" = c("mode", "approved", "out-dir", "max-array-size", "concurrency"),
    "resource-plan" = c("mode", "max-smoke-minutes", "max-smoke-rss-gb", "out"),
    NULL
  )
  if (is.null(allowed)) arc4c_stop("Unsupported --mode: ", mode)
  extra <- setdiff(names(a), allowed)
  if (length(extra)) arc4c_stop("Unsupported argument(s) for ", mode, ": --", paste(extra, collapse = ", --"), ".")
  if (identical(mode, "smoke-manifest")) {
    utils::write.table(arc4c_make_smoke_manifest(), arc4c_need(a, "out"), sep = "\t", row.names = FALSE, quote = FALSE)
  } else if (identical(mode, "select-smoke")) {
    result <- arc4c_select_smoke(utils::read.delim(arc4c_need(a, "smoke"), check.names = FALSE))
    utils::write.table(result$family, arc4c_need(a, "family-out"), sep = "\t", row.names = FALSE, quote = FALSE)
    utils::write.table(result$approved, arc4c_need(a, "approved-out"), sep = "\t", row.names = FALSE, quote = FALSE)
  } else if (identical(mode, "full-manifest")) {
    approved <- utils::read.delim(arc4c_need(a, "approved"), check.names = FALSE)
    manifest <- arc4c_make_full_manifest(approved)
    arc4c_write_partitioned_manifest(manifest, arc4c_need(a, "out-dir"), as.integer(arc4c_need(a, "max-array-size")),
                                     if (is.null(a$concurrency)) arc4c_max_concurrency else as.integer(a$concurrency))
  } else if (identical(mode, "resource-plan")) {
    result <- arc4c_size_resources(as.numeric(arc4c_need(a, "max-smoke-minutes")), as.numeric(arc4c_need(a, "max-smoke-rss-gb")))
    utils::write.table(result, arc4c_need(a, "out"), sep = "\t", row.names = FALSE, quote = FALSE)
  }
}

if (sys.nframe() == 0L) arc4c_main()
