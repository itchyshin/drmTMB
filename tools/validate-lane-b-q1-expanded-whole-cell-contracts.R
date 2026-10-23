#!/usr/bin/env Rscript

# Static, fail-closed contract gate for the expanded structured-q1 whole-cell
# set. It only joins immutable source bindings and the source map; it never
# loads drmTMB, fixture code, runners, profiles, or campaign results.

lane_b_q1_expanded_stop <- function(...) stop(..., call. = FALSE)

lane_b_q1_expanded_root <- function() {
  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  supplied <- if (length(script_arg)) sub("^--file=", "", script_arg[[1L]]) else character()
  candidates <- c(
    supplied[basename(supplied) == "validate-lane-b-q1-expanded-whole-cell-contracts.R"],
    "tools/validate-lane-b-q1-expanded-whole-cell-contracts.R",
    "../../tools/validate-lane-b-q1-expanded-whole-cell-contracts.R"
  )
  script <- candidates[file.exists(candidates)][1L]
  if (is.na(script)) lane_b_q1_expanded_stop("Cannot locate expanded q1 whole-cell contract validator.")
  normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
}

lane_b_q1_expanded_sha256 <- function(path) {
  if (!file.exists(path)) lane_b_q1_expanded_stop("Missing contract source: ", path)
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  args <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  output <- suppressWarnings(system2(command, args, stdout = TRUE, stderr = TRUE))
  if (!length(output) || !grepl("^[0-9a-f]{64}\\s", output[[1L]])) {
    lane_b_q1_expanded_stop("Could not calculate SHA-256 for ", path, ".")
  }
  sub("\\s.*$", "", output[[1L]])
}

lane_b_q1_expanded_paths <- function(root = lane_b_q1_expanded_root()) {
  list(
    registry = file.path(root, "docs/dev-log/interval-campaign-bindings/2026-07-28-q1-expanded-whole-cell-canonical-contracts.tsv"),
    bindings = file.path(root, "docs/dev-log/interval-campaign-bindings/2026-07-27-b1-recovered-subset.tsv"),
    source_map = file.path(root, "docs/dev-log/interval-feasibility/2026-07-31-structured-q1-target-map.tsv")
  )
}

lane_b_q1_expanded_expected <- function() {
  data.frame(
    cell_id = c("mc-0012", "mc-0248", "mc-0248", "mc-0386", "mc-0423", "mc-0434", "mc-0438", "mc-0440", "mc-0447", "mc-0451", "mc-0494", "mc-0494"),
    target_id = c(
      "mc-0012::sd:mu:animal(1 | id)", "mc-0248::sd:mu:relmat(1 | id)",
      "mc-0248::sd:mu:relmat(0 + x | id)", "mc-0386::sd:mu:phylo(1 | id)",
      "mc-0423::sd:sigma:animal(0 + x | id)", "mc-0434::sd:mu:phylo(1 | species)",
      "mc-0438::sd:mu:phylo_interaction(1 | plant:pollinator)", "mc-0440::sd:mu:spatial(1 | site)",
      "mc-0447::sd:mu:animal(1 | id)", "mc-0451::sd:mu:relmat(1 | id)",
      "mc-0494::sd:mu:spatial(1 | id)", "mc-0494::sd:mu:spatial(0 + x | id)"
    ),
    dgp_id = c(
      "beta_animal_mu_intercept_fixture", "arc3a_gamma_relmat_mu", "gamma_relmat_mu_one_slope_fixture",
      "arc3a_lognormal_phylo_mu", "b1_nbinom2_sigma_animal", "poisson_phylo_mu_intercept_fixture",
      "b1_phylo_interaction_poisson", "count_spatial_poisson_q1_mu_intercept",
      "count_animal_poisson_q1_mu_intercept", "count_relmat_poisson_q1_mu_intercept",
      "student_spatial_mu_one_slope_fixture", "student_spatial_mu_one_slope_fixture"
    ),
    whole_cell_component_cardinality = c(1L, 2L, 2L, 1L, 2L, 1L, 1L, 1L, 1L, 1L, 2L, 2L),
    stringsAsFactors = FALSE
  )
}

lane_b_q1_expanded_validate <- function(registry, bindings, source_map, binding_sha256, source_map_sha256) {
  required <- c(
    "cell_id", "target_id", "dgp_id", "formula", "true_parameter_scale", "profile_parameter",
    "information_rung", "binding_source", "binding_source_sha256", "source_map_path", "source_map_sha256",
    "family", "dpar", "structure_provider", "q", "target_cardinality",
    "whole_cell_component_inventory", "whole_cell_component_cardinality", "contract_state", "execution_authority"
  )
  missing <- setdiff(required, names(registry))
  if (length(missing)) lane_b_q1_expanded_stop("Registry missing column(s): ", paste(missing, collapse = ", "), ".")
  expected <- lane_b_q1_expanded_expected()
  identity <- c("cell_id", "target_id", "dgp_id")
  if (nrow(registry) != nrow(expected) || anyDuplicated(registry$target_id) ||
      !all(vapply(identity, function(field) identical(as.character(registry[[field]]), as.character(expected[[field]])), logical(1L)))) {
    lane_b_q1_expanded_stop("Registry must retain exactly the 12 ordered cell::target::DGP contracts.")
  }
  required_text <- c("target_id", "dgp_id", "formula", "true_parameter_scale", "profile_parameter", "information_rung", "binding_source")
  if (any(vapply(required_text, function(field) anyNA(registry[[field]]) || any(!nzchar(registry[[field]])), logical(1L))) ||
      any(registry$target_cardinality != 1L) || any(registry$q != 1L) ||
      any(registry$target_id != paste(registry$cell_id, registry$profile_parameter, sep = "::")) ||
      !identical(as.integer(registry$whole_cell_component_cardinality), expected$whole_cell_component_cardinality)) {
    lane_b_q1_expanded_stop("Every q1 contract requires a direct target, DGP, truth, rung, and exact whole-cell component cardinality.")
  }
  authorized_targets <- c(
    "mc-0012::sd:mu:animal(1 | id)", "mc-0248::sd:mu:relmat(1 | id)", "mc-0386::sd:mu:phylo(1 | id)", "mc-0423::sd:sigma:animal(0 + x | id)", "mc-0434::sd:mu:phylo(1 | species)",
    "mc-0438::sd:mu:phylo_interaction(1 | plant:pollinator)",
    "mc-0440::sd:mu:spatial(1 | site)", "mc-0447::sd:mu:animal(1 | id)",
    "mc-0451::sd:mu:relmat(1 | id)"
  )
  expected_authority <- registry$target_id %in% authorized_targets
  if (any(registry$contract_state != "whole_cell_canonical_contract") ||
      !identical(as.logical(registry$execution_authority), expected_authority)) {
    lane_b_q1_expanded_stop("Only reviewed single-target q1 contracts may carry execution authority; all siblings remain fail-closed.")
  }
  if (!all(registry$binding_source_sha256 == binding_sha256) || !all(registry$source_map_sha256 == source_map_sha256) ||
      any(registry$source_map_path != "docs/dev-log/interval-feasibility/2026-07-31-structured-q1-target-map.tsv")) {
    lane_b_q1_expanded_stop("Registry source hashes or source-map path do not match the immutable inputs.")
  }
  binding_required <- c("cell_id", "target_id", "dgp_id", "formula", "true_parameter_scale", "profile_parameter", "information_rung", "binding_source")
  missing_binding <- setdiff(binding_required, names(bindings))
  if (length(missing_binding)) lane_b_q1_expanded_stop("Recovered binding file missing column(s): ", paste(missing_binding, collapse = ", "), ".")
  keys <- paste(registry$cell_id, registry$target_id, registry$dgp_id, sep = "\r")
  source_keys <- paste(bindings$cell_id, bindings$target_id, bindings$dgp_id, sep = "\r")
  rows <- bindings[match(keys, source_keys), binding_required, drop = FALSE]
  if (anyNA(rows$cell_id) || anyDuplicated(source_keys[source_keys %in% keys]) ||
      !all(vapply(binding_required, function(field) identical(as.character(rows[[field]]), as.character(registry[[field]])), logical(1L)))) {
    lane_b_q1_expanded_stop("Expanded registry differs from the immutable recovered source fixtures.")
  }
  map_required <- c("cell_id", "candidate_target_or_unknown", "component_class", "source_state", "source_path", "missing_contract_field", "next_gate")
  missing_map <- setdiff(map_required, names(source_map))
  if (length(missing_map)) lane_b_q1_expanded_stop("Structured q1 source map missing column(s): ", paste(missing_map, collapse = ", "), ".")
  cells <- unique(expected$cell_id)
  map_rows <- source_map[match(cells, source_map$cell_id), map_required, drop = FALSE]
  if (anyNA(map_rows$cell_id) || anyDuplicated(source_map$cell_id[source_map$cell_id %in% cells]) ||
      any(map_rows$component_class != "multicomponent") || any(map_rows$source_state != "exact_partial_source_binding") ||
      any(map_rows$source_path != "docs/dev-log/interval-campaign-bindings/2026-07-27-b1-recovered-subset.tsv")) {
    lane_b_q1_expanded_stop("Structured q1 source map must retain one exact partial-source binding record for each canonical cell.")
  }
  map_targets <- setNames(map_rows$candidate_target_or_unknown, map_rows$cell_id)
  expected_targets <- split(expected$target_id, expected$cell_id)
  if (!all(vapply(names(expected_targets), function(cell) {
    mapped <- gsub(") | mc-", ")\rmc-", map_targets[[cell]], fixed = TRUE)
    mapped_targets <- trimws(strsplit(mapped, "\r", fixed = TRUE)[[1L]])
    length(mapped_targets) == length(expected_targets[[cell]]) && setequal(mapped_targets, expected_targets[[cell]])
  }, logical(1L)))) {
    lane_b_q1_expanded_stop("Structured q1 source map target inventory does not match the canonical whole-cell contract.")
  }
  invisible(registry)
}

lane_b_q1_expanded_read_validate <- function(root = lane_b_q1_expanded_root()) {
  paths <- lane_b_q1_expanded_paths(root)
  registry <- utils::read.delim(paths$registry, check.names = FALSE, stringsAsFactors = FALSE)
  bindings <- utils::read.delim(paths$bindings, check.names = FALSE, stringsAsFactors = FALSE)
  source_map <- utils::read.delim(paths$source_map, check.names = FALSE, stringsAsFactors = FALSE)
  lane_b_q1_expanded_validate(registry, bindings, source_map, lane_b_q1_expanded_sha256(paths$bindings), lane_b_q1_expanded_sha256(paths$source_map))
  registry
}

if (sys.nframe() == 0L) {
  lane_b_q1_expanded_read_validate()
  message("Validated 12 static expanded structured-q1 whole-cell contracts with nine reviewed execution-authorized target rows.")
}
