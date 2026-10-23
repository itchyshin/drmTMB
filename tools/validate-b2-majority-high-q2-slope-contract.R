b2_majority_high_q2_stop <- function(...) stop(..., call. = FALSE)

b2_majority_high_q2_contract_path <- function(root = ".") {
  file.path(root, "docs", "dev-log", "interval-campaign-bindings", "2026-07-30-b2-majority-high-q2-slope-8-contract.tsv")
}

b2_majority_high_q2_read_validate <- function(root = ".") {
  source(file.path(root, "tools", "validate-b2-majority-40-fixture-contract.R"))
  x <- utils::read.delim(b2_majority_high_q2_contract_path(root), check.names = FALSE, stringsAsFactors = FALSE)
  required <- c("cell_id", "target_id", "dgp_id", "truth_scale", "target_truth", "seed", "information_rung", "fixture_module", "provider", "n_groups", "observations_per_group", "whole_cell_component_inventory", "execution_authorized", "profile_execution", "canonical_ledger_change", "claim_ceiling")
  expected_cells <- c("mc-0280", "mc-0281", "mc-0293", "mc-0294", "mc-0305", "mc-0306", "mc-0317", "mc-0318")
  if (!identical(names(x), required) || !identical(x$cell_id, expected_cells) || anyDuplicated(x$target_id)) b2_majority_high_q2_stop("High-rung q2 slope contract must name exactly the eight ordered targets.")
  if (!all(x$information_rung == "high") || !all(x$fixture_module == "b2_gaussian_q2") || !all(x$n_groups == 72L) || !all(x$observations_per_group == 20L)) b2_majority_high_q2_stop("High-rung q2 slope contract must use the exact 72 x 20 q2 fixture.")
  if (!all(x$truth_scale == "latent_sd") || !identical(as.numeric(x$target_truth), ifelse(grepl("::sd:mu:mu:", x$target_id, fixed = TRUE), .45, .30))) b2_majority_high_q2_stop("High-rung q2 slope contract must retain one source-addressed latent-SD truth per direct target.")
  if (!all(x$whole_cell_component_inventory == "mu_intercept,mu_slope,sigma_intercept,sigma_slope") || !all(x$execution_authorized == "FALSE") || !all(x$profile_execution == "NOT_AUTHORIZED") || !all(x$canonical_ledger_change == "NOT_AUTHORIZED") || !all(x$claim_ceiling == "interval_feasible")) b2_majority_high_q2_stop("High-rung q2 slope contract must remain whole-cell and non-authorising.")
  low <- b2_majority40_read_validate(root)
  low <- low[match(x$cell_id, low$cell_id), , drop = FALSE]
  for (field in c("target_id", "dgp_id", "seed", "fixture_module")) if (!identical(as.character(x[[field]]), as.character(low[[field]]))) b2_majority_high_q2_stop("High-rung q2 slope contract differs from the source-addressed registry: ", field, ".")
  providers <- sub("^.*:(phylo|spatial|animal|relmat)\\(.*$", "\\1", sub("^[^:]+::", "", x$target_id))
  if (!identical(x$provider, providers)) b2_majority_high_q2_stop("High-rung q2 slope providers do not match their target identities.")
  invisible(x)
}

if (sys.nframe() == 0L) {
  b2_majority_high_q2_read_validate(normalizePath(".", mustWork = TRUE))
  message("Validated non-authorising B2 high-rung q2-slope contract.")
}
