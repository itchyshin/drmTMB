interval_campaign_readiness_script <- function() {
  testthat::test_path("..", "..", "inst", "sim", "R", "sim_interval_campaign_readiness.R")
}

interval_campaign_test_bindings <- function(contracts) {
  ids <- contracts$cell_id[contracts$lane_b_target]
  data.frame(
    cell_id = ids,
    target_id = paste(ids, paste0("sd:mu:group:", ids), sep = "::"),
    dgp_id = paste0("fixture-", ids),
    formula = "response ~ 1 + (1 | group)",
    true_parameter_scale = "natural_sd",
    profile_parameter = paste0("sd:mu:group:", ids),
    information_rung = "smoke",
    stringsAsFactors = FALSE
  )
}

test_that("Lane-B manifest freezes the approved 159-row cohort", {
  env <- new.env(parent = globalenv())
  sys.source(interval_campaign_readiness_script(), envir = env)
  manifest <- env$phase18_interval_campaign_manifest(
    testthat::test_path("..", "..", "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv")
  )

  expect_equal(nrow(manifest), 159L)
  expect_equal(sum(manifest$source_order <= 676L), 158L)
  expect_equal(manifest$source_order[manifest$cell_id == "mc-0260m"], 694L)
  expect_true(all(manifest$axis == "model_surface"))
  expect_match(attr(manifest, "source_md5"), "^[[:xdigit:]]{32}$")
  expect_match(attr(manifest, "manifest_md5"), "^[[:xdigit:]]{32}$")
  altered <- manifest
  altered$cell_id[[1L]] <- "mc-replaced"
  expect_error(env$phase18_assert_interval_campaign_census(altered), "frozen cohort")
})

test_that("contracts stratify targets and fail closed until exact bindings exist", {
  env <- new.env(parent = globalenv())
  sys.source(interval_campaign_readiness_script(), envir = env)
  manifest <- env$phase18_interval_campaign_manifest(
    testthat::test_path("..", "..", "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv")
  )
  contracts <- env$phase18_interval_campaign_contracts(manifest)

  expect_true(all(c("fixed_coefficient", "ordinary_re_sd_intercept", "ordinary_re_sd_slope") %in% contracts$estimand_stratum))
  expect_true(any(grepl("^structured_candidate:.*:component_unbound:", contracts$estimand_stratum)))
  expect_equal(sum(contracts$negative_control), 1L)
  expect_true(contracts$negative_control[contracts$cell_id == "mc-0260m"])
  expect_false(any(contracts$negative_control & contracts$q_gate == "q12"))
  expect_true(all(contracts$contract_status[contracts$lane_b_target] == "needs_exact_dgp_binding"))
  expect_true(all(contracts$contract_status[!contracts$lane_b_target] == "excluded_foreign_association"))
  expect_true(all(is.na(contracts$profile_parameter)))
})

test_that("binding worklist gives every Lane-B target an evidence source", {
  env <- new.env(parent = globalenv())
  sys.source(interval_campaign_readiness_script(), envir = env)
  root <- testthat::test_path("..", "..")
  manifest <- env$phase18_interval_campaign_manifest(
    file.path(root, "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv")
  )
  worklist <- env$phase18_interval_campaign_binding_worklist(
    env$phase18_interval_campaign_contracts(manifest),
    file.path(root, "docs", "dev-log", "dashboard", "capability-ledger", "evidence.tsv")
  )

  expect_equal(nrow(worklist), 158L)
  expect_false(anyNA(worklist$primary_evidence_path))
  expect_equal(sum(!is.na(worklist$formula_hint)), 46L)
  expect_true(all(worklist$required_dgp_id))
  expect_true(all(worklist$required_profile_parameter))
})

test_that("B1 source recovery is limited to the frozen E0 intersection", {
  root <- testthat::test_path("..", "..")
  source(file.path(root, "tools", "b1-breadth-contract.R"), local = TRUE)
  env <- new.env(parent = globalenv())
  sys.source(interval_campaign_readiness_script(), envir = env)
  manifest <- env$phase18_interval_campaign_manifest(
    file.path(root, "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv")
  )
  recovered <- b1_cells$cell_id[b1_cells$cell_id %in% manifest$cell_id]

  expect_setequal(
    recovered,
    c("mc-0005", "mc-0059", "mc-0251", "mc-0270", "mc-0388", "mc-0423", "mc-0438", "mc-0511")
  )
  expect_false(any(c("mc-0031", "mc-0074") %in% recovered))
})

test_that("recovered binding subsets are machine-readable but cannot schedule", {
  env <- new.env(parent = globalenv())
  sys.source(interval_campaign_readiness_script(), envir = env)
  root <- testthat::test_path("..", "..")
  manifest <- env$phase18_interval_campaign_manifest(
    file.path(root, "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv")
  )
  contracts <- env$phase18_interval_campaign_contracts(manifest)
  subset_path <- file.path(
    root, "docs", "dev-log", "interval-campaign-bindings",
    "2026-07-27-b1-recovered-subset.tsv"
  )
  recovered <- env$phase18_read_interval_campaign_bindings(
    subset_path, contracts, allow_partial = TRUE
  )

  expect_equal(nrow(recovered), 39L)
  expect_setequal(
    recovered$cell_id,
    c("mc-0005", "mc-0007", "mc-0059", "mc-0184", "mc-0185", "mc-0208", "mc-0209", "mc-0212", "mc-0213", "mc-0225", "mc-0251", "mc-0260m", "mc-0265", "mc-0267", "mc-0270", "mc-0271", "mc-0380", "mc-0388", "mc-0401", "mc-0402", "mc-0403", "mc-0410", "mc-0411", "mc-0412", "mc-0413", "mc-0423", "mc-0429", "mc-0431", "mc-0434", "mc-0435", "mc-0438", "mc-0441", "mc-0448", "mc-0452", "mc-0463", "mc-0511", "mc-0538", "mc-0567")
  )
  expect_equal(sum(recovered$cell_id == "mc-0260m"), 2L)
  expect_error(
    env$phase18_read_interval_campaign_bindings(subset_path, contracts),
    "covering every Lane-B cell"
  )
  expect_error(
    env$phase18_bind_interval_campaign_contracts(contracts, recovered),
    "cover every and only Lane-B target candidate"
  )
})

test_that("binding inventory retains every Lane-B cell while exposing recovery state", {
  env <- new.env(parent = globalenv())
  sys.source(interval_campaign_readiness_script(), envir = env)
  root <- testthat::test_path("..", "..")
  manifest <- env$phase18_interval_campaign_manifest(
    file.path(root, "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv")
  )
  contracts <- env$phase18_interval_campaign_contracts(manifest)
  partial <- env$phase18_read_interval_campaign_bindings(
    file.path(root, "docs", "dev-log", "interval-campaign-bindings", "2026-07-27-b1-recovered-subset.tsv"),
    contracts, allow_partial = TRUE
  )
  inventory <- env$phase18_interval_campaign_binding_inventory(contracts, partial)

  expect_equal(length(unique(inventory$cell_id)), 158L)
  expect_equal(sum(inventory$binding_status == "partial_exact_binding"), 37L)
  expect_equal(sum(inventory$binding_status == "partial_negative_control_binding"), 2L)
  expect_equal(sum(inventory$binding_status == "needs_exact_binding"), 120L)
  expect_true(all(inventory$binding_status[inventory$cell_id == "mc-0260m"] == "partial_negative_control_binding"))
})

test_that("all-attempt reducer retains unavailable and not-run attempts", {
  env <- new.env(parent = globalenv())
  sys.source(interval_campaign_readiness_script(), envir = env)
  schedule <- data.frame(
    cell_id = rep("mc-0005", 3),
    target_id = rep("mc-0005::sd:mu:group", 3),
    information_rung = rep("smoke", 3),
    negative_control = rep(FALSE, 3),
    replicate = 1:3,
    seed = 101:103,
    manifest_md5 = rep("manifest-md5", 3),
    contract_md5 = rep("contract-md5", 3)
  )
  attempts <- data.frame(
    cell_id = rep("mc-0005", 2),
    target_id = rep("mc-0005::sd:mu:group", 2),
    information_rung = rep("smoke", 2),
    replicate = 1:2,
    seed = 101:102,
    manifest_md5 = rep("manifest-md5", 2),
    contract_md5 = rep("contract-md5", 2),
    profile_status = c("profile", "clamp_limited"),
    covered = c(TRUE, FALSE)
  )
  out <- env$phase18_reduce_interval_campaign_attempts(schedule, attempts)

  expect_equal(out$all_attempts, 3L)
  expect_equal(out$completed_attempts, 2L)
  expect_equal(out$available_attempts, 1L)
  expect_equal(out$covered_attempts, 1L)
  expect_equal(out$noncovering_attempts, 2L)
  expect_equal(out$coverage_all_attempts, 1 / 3)
})

test_that("seed schedules are deterministic and cover every frozen candidate", {
  env <- new.env(parent = globalenv())
  sys.source(testthat::test_path("..", "..", "inst", "sim", "R", "sim_registry.R"), envir = env)
  sys.source(interval_campaign_readiness_script(), envir = env)
  manifest <- env$phase18_interval_campaign_manifest(
    testthat::test_path("..", "..", "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv")
  )
  contracts <- env$phase18_interval_campaign_contracts(manifest)
  expect_error(
    env$phase18_interval_campaign_seed_schedule(contracts, n_rep = 2L, master_seed = 17L),
    "integrity-checked binding"
  )
  bound <- env$phase18_bind_interval_campaign_contracts(
    contracts,
    interval_campaign_test_bindings(contracts)
  )
  first <- env$phase18_interval_campaign_seed_schedule(bound, n_rep = 2L, master_seed = 17L)
  second <- env$phase18_interval_campaign_seed_schedule(bound, n_rep = 2L, master_seed = 17L)

  expect_equal(nrow(first), 316L)
  expect_equal(first, second)
  expect_setequal(unique(first$cell_id), bound$cell_id[bound$lane_b_target])
  tampered <- bound
  tampered$dgp_id[which(tampered$lane_b_target)[[1L]]] <- NA_character_
  expect_error(
    env$phase18_interval_campaign_seed_schedule(tampered, n_rep = 1L),
    "integrity-checked binding"
  )
})

test_that("bindings retain multiple direct targets for one route-level cell", {
  env <- new.env(parent = globalenv())
  sys.source(testthat::test_path("..", "..", "inst", "sim", "R", "sim_registry.R"), envir = env)
  sys.source(interval_campaign_readiness_script(), envir = env)
  manifest <- env$phase18_interval_campaign_manifest(
    testthat::test_path("..", "..", "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv")
  )
  contracts <- env$phase18_interval_campaign_contracts(manifest)
  bindings <- interval_campaign_test_bindings(contracts)
  extra <- bindings[1L, , drop = FALSE]
  extra$target_id <- paste(extra$cell_id, "fixef:mu:x", sep = "::")
  extra$profile_parameter <- "fixef:mu:x"
  target_contracts <- env$phase18_bind_interval_campaign_contracts(
    contracts,
    rbind(bindings, extra)
  )
  schedule <- env$phase18_interval_campaign_seed_schedule(
    target_contracts, n_rep = 1L, master_seed = 17L
  )

  expect_equal(nrow(target_contracts), 159L)
  expect_equal(sum(target_contracts$cell_id == extra$cell_id), 2L)
  expect_equal(nrow(schedule), 159L)
  expect_equal(length(unique(schedule$target_id)), 159L)
})

test_that("a finite K=12 profile is a fail-closed reducer error", {
  env <- new.env(parent = globalenv())
  sys.source(interval_campaign_readiness_script(), envir = env)
  schedule <- data.frame(
    cell_id = "mc-k12",
    target_id = "mc-k12::sd:mu:phylo",
    information_rung = "smoke",
    negative_control = TRUE,
    replicate = 1L,
    seed = 101L,
    manifest_md5 = "manifest-md5",
    contract_md5 = "contract-md5"
  )
  attempts <- data.frame(
    cell_id = "mc-k12",
    target_id = "mc-k12::sd:mu:phylo",
    information_rung = "smoke",
    replicate = 1L,
    seed = 101L,
    manifest_md5 = "manifest-md5",
    contract_md5 = "contract-md5",
    profile_status = "profile",
    covered = TRUE
  )
  expect_error(
    env$phase18_reduce_interval_campaign_attempts(schedule, attempts),
    "negative-control"
  )
})

test_that("readiness packets preserve the manifest and cannot authorize compute", {
  env <- new.env(parent = globalenv())
  sys.source(interval_campaign_readiness_script(), envir = env)
  manifest <- env$phase18_interval_campaign_manifest(
    testthat::test_path("..", "..", "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv")
  )
  repo_root <- testthat::test_path("..", "..")
  source_sha <- trimws(system2("git", c("-C", repo_root, "rev-parse", "HEAD"), stdout = TRUE))
  packet <- env$phase18_write_interval_campaign_readiness_packet(
    env$phase18_interval_campaign_contracts(manifest),
    evidence_path = file.path(repo_root, "docs", "dev-log", "dashboard", "capability-ledger", "evidence.tsv"),
    output_dir = tempfile("lane-b-readiness-"),
    source_sha = source_sha,
    source_root = repo_root
  )

  expect_true(file.exists(packet$manifest))
  expect_true(file.exists(packet$contracts))
  expect_true(file.exists(packet$binding_worklist))
  expect_true(file.exists(packet$binding_inventory))
  expect_true(file.exists(packet$runtime_receipt))
  expect_equal(nrow(utils::read.delim(packet$manifest)), 159L)
  expect_equal(nrow(utils::read.delim(packet$binding_inventory)), 158L)
  expect_identical(readRDS(packet$runtime_receipt)$source_sha, source_sha)
  expect_false(packet$pregrid_authorized)
})
