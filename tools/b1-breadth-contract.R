# B1 breadth-validation contract.
#
# Pure helpers for the DRAC breadth campaign.  This file intentionally does
# not load drmTMB or submit work: it freezes the selected cells, their adapter
# status, deterministic task identities, and the all-attempts manifest that
# workers and the aggregator must agree on.

b1_stop <- function(...) stop(..., call. = FALSE)

b1_cells <- data.frame(
  cell_id = c(
    "mc-0005", "mc-0031", "mc-0059", "mc-0074", "mc-0229", "mc-0251",
    "mc-0270", "mc-0364", "mc-0388", "mc-0423", "mc-0438", "mc-0460",
    "mc-0495", "mc-0511", "mc-0641", "mc-0667"
  ),
  family = c(
    "beta", "beta_binomial", "binomial", "biv_gaussian", "cumulative_logit", "gamma",
    "gaussian", "hurdle_nbinom2", "lognormal", "nbinom2", "poisson", "skew_normal",
    "student", "truncated_nbinom2", "zi_nbinom2", "zi_poisson"
  ),
  dpar = c("mu", "mu", "mu", "sigma1", "mu", "mu", "sigma", "hu", "mu", "sigma", "mu", "nu", "nu", "mu", "mu", "zi"),
  effect = c(
    "ordinary_re_intercept", "ordinary_re_slope", "ordinary_re_intercept", "ordinary_re_slope",
    "structured_phylo_q1", "structured_phylo_q1", "ordinary_re_slope", "structured_relmat_q1",
    "structured_relmat_q1", "structured_animal_q1_slope", "structured_phylo_interaction_q1", "fixed",
    "structured_phylo_q1", "ordinary_re_slope", "structured_spatial_q1", "structured_spatial_q1"
  ),
  adapter = c(
    "fixture_beta_mu_intercept", "fixture_nongaussian_mu_slope", "fixture_binomial_mu_intercept",
    "phase18_biv_mu_sigma_slope", "fixture_cumlogit_phylo", "arc3a_positive_continuous",
    "phase18_gaussian_sigma_slope", "fixture_hurdle_relmat", "arc3a_positive_continuous",
    "new_nbinom2_sigma_animal", "count_phylo_interaction", "fixture_skew_normal_nu",
    "new_student_nu_phylo", "fixture_nongaussian_mu_slope", "new_zi_nbinom2_spatial",
    "fixture_zi_poisson_spatial"
  ),
  adapter_status = c(
    rep("fixture_lift", 3L), "direct", "fixture_lift", "direct", "direct", "fixture_lift",
    "direct", "adapter_build", "direct", "fixture_lift", "fixture_lift", "fixture_lift",
    "fixture_lift", "fixture_lift"
  ),
  target = c(
    "sd:mu:(1 | id)", "sd:mu:(0 + x | id)", "sd:mu:(1 | id)",
    "sd:sigma:sigma1:(0 + x | p | id)", "sd:mu:phylo(1 | species)", "sd:mu:phylo(1 | id)",
    "sd:sigma:(0 + w | id)", "sd:hu:relmat(1 | id)", "sd:mu:relmat(1 | id)",
    "sd:sigma:animal(0 + x | id)", "sd:mu:phylo_interaction(1 | plant:pollinator)", "fixef:nu:(Intercept)",
    "sd:nu:phylo(1 | id)", "sd:mu:(0 + x | id)", "sd:mu:spatial(1 | site)", "sd:zi:spatial(1 | id)"
  ),
  stringsAsFactors = FALSE
)

# Three information rungs are used for every selected cell.  Their concrete
# sample-size mapping is owned by the cell adapter, rather than pretending that
# group count means the same thing for all likelihoods.
b1_information_rungs <- c("low", "medium", "high")
b1_replicates_per_rung <- 200L
b1_default_replicates_per_shard <- 10L
b1_seed_base <- 2026072600L

b1_required_task_columns <- c(
  "array_index", "logical_task_id", "cell_id", "family", "dpar", "effect", "adapter",
  "adapter_status", "target", "information_rung", "shard", "replicate_start", "replicate_end",
  "seed_start", "seed_end"
)

b1_validate_cells <- function(cells = b1_cells) {
  needed <- c("cell_id", "family", "dpar", "effect", "adapter", "adapter_status", "target")
  missing <- setdiff(needed, names(cells))
  if (length(missing)) b1_stop("B1 cells missing column(s): ", paste(missing, collapse = ", "), ".")
  if (nrow(cells) != 16L || anyDuplicated(cells$cell_id) || any(!grepl("^mc-[0-9]{4}$", cells$cell_id))) {
    b1_stop("B1 requires exactly sixteen unique model-surface cell IDs.")
  }
  if (!all(cells$adapter_status %in% c("direct", "fixture_lift", "adapter_build"))) {
    b1_stop("B1 adapter_status values must be direct, fixture_lift, or adapter_build.")
  }
  invisible(cells)
}

b1_seed <- function(cell_index, rung_index, replicate) {
  cell_index <- as.integer(cell_index); rung_index <- as.integer(rung_index); replicate <- as.integer(replicate)
  if (length(cell_index) != 1L || length(rung_index) != 1L || length(replicate) != 1L ||
      anyNA(c(cell_index, rung_index, replicate)) || cell_index < 1L || cell_index > nrow(b1_cells) ||
      rung_index < 1L || rung_index > length(b1_information_rungs) || replicate < 1L || replicate > b1_replicates_per_rung) {
    b1_stop("B1 seed coordinates are outside the frozen campaign grid.")
  }
  as.integer(b1_seed_base + ((cell_index - 1L) * length(b1_information_rungs) + (rung_index - 1L)) *
    b1_replicates_per_rung + replicate)
}

b1_make_smoke_manifest <- function(cells = b1_cells) {
  b1_validate_cells(cells)
  out <- cells
  out$information_rung <- "smoke"
  out$shard <- 0L
  out$replicate_start <- 1L
  out$replicate_end <- 1L
  out$seed_start <- vapply(seq_len(nrow(out)), function(i) b1_seed(i, 1L, 1L), integer(1L))
  out$seed_end <- out$seed_start
  out$logical_task_id <- seq_len(nrow(out))
  out$array_index <- seq_len(nrow(out))
  out <- out[b1_required_task_columns]
  rownames(out) <- NULL
  out
}

b1_make_full_manifest <- function(replicates_per_shard = b1_default_replicates_per_shard, cells = b1_cells) {
  b1_validate_cells(cells)
  replicates_per_shard <- as.integer(replicates_per_shard)
  if (length(replicates_per_shard) != 1L || is.na(replicates_per_shard) || replicates_per_shard < 1L ||
      b1_replicates_per_rung %% replicates_per_shard != 0L) {
    b1_stop("replicates_per_shard must divide the frozen 200-replicate rung.")
  }
  shards <- seq_len(b1_replicates_per_rung / replicates_per_shard)
  rows <- vector("list", nrow(cells) * length(b1_information_rungs) * length(shards))
  k <- 0L
  for (cell_i in seq_len(nrow(cells))) for (rung_i in seq_along(b1_information_rungs)) for (shard in shards) {
    k <- k + 1L
    start <- (shard - 1L) * replicates_per_shard + 1L
    end <- shard * replicates_per_shard
    x <- cells[cell_i, , drop = FALSE]
    x$information_rung <- b1_information_rungs[[rung_i]]
    x$shard <- shard
    x$replicate_start <- start
    x$replicate_end <- end
    x$seed_start <- b1_seed(cell_i, rung_i, start)
    x$seed_end <- b1_seed(cell_i, rung_i, end)
    x$logical_task_id <- k
    rows[[k]] <- x
  }
  out <- do.call(rbind, rows)
  out$array_index <- seq_len(nrow(out))
  out <- out[b1_required_task_columns]
  rownames(out) <- NULL
  b1_validate_task_manifest(out, replicates_per_shard)
  out
}

b1_validate_task_manifest <- function(manifest, replicates_per_shard = b1_default_replicates_per_shard) {
  missing <- setdiff(b1_required_task_columns, names(manifest))
  if (length(missing)) b1_stop("B1 task manifest missing column(s): ", paste(missing, collapse = ", "), ".")
  if (!identical(as.integer(manifest$array_index), seq_len(nrow(manifest))) ||
      anyDuplicated(manifest$logical_task_id) || anyDuplicated(manifest$array_index)) {
    b1_stop("B1 task manifest must have dense, unique array and logical task IDs.")
  }
  if (any(manifest$replicate_end - manifest$replicate_start + 1L != as.integer(replicates_per_shard))) {
    b1_stop("Each B1 task must own exactly one canonical shard.")
  }
  if (any(manifest$seed_end - manifest$seed_start != manifest$replicate_end - manifest$replicate_start)) {
    b1_stop("B1 task seed ranges must match replicate ranges exactly.")
  }
  if (anyDuplicated(unlist(Map(seq.int, manifest$seed_start, manifest$seed_end)))) {
    b1_stop("B1 task manifest has non-unique seeds.")
  }
  invisible(manifest)
}

b1_full_attempt_count <- function(cells = b1_cells) {
  b1_validate_cells(cells)
  nrow(cells) * length(b1_information_rungs) * b1_replicates_per_rung
}
