#!/usr/bin/env Rscript

# Mechanical verification for the Lane-B E0 no-compute readiness packet.
#
# This script neither schedules nor launches a campaign. It proves that the
# frozen cohort, partial binding inventory, retained smoke receipts, and packet
# writer still fail closed before any DRAC/Totoro approval is requested.

args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args) == 0L) getwd() else normalizePath(args[[1L]])
source(file.path(root, "inst", "sim", "R", "sim_interval_campaign_readiness.R"))

cells_path <- file.path(root, "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv")
evidence_path <- file.path(root, "docs", "dev-log", "dashboard", "capability-ledger", "evidence.tsv")
bindings_path <- file.path(root, "docs", "dev-log", "interval-campaign-bindings", "2026-07-27-b1-recovered-subset.tsv")
receipts_path <- file.path(root, "docs", "dev-log", "interval-campaign-bindings", "2026-07-27-b1-local-smoke-receipts.tsv")

manifest <- phase18_interval_campaign_manifest(cells_path)
contracts <- phase18_interval_campaign_contracts(manifest)
bindings <- phase18_read_interval_campaign_bindings(bindings_path, contracts, allow_partial = TRUE)
receipts <- phase18_read_interval_campaign_smoke_receipts(receipts_path, contracts, bindings)
inventory <- phase18_interval_campaign_binding_inventory(contracts, bindings)
summary <- phase18_interval_campaign_binding_recovery_summary(contracts, bindings)

stopifnot(
  nrow(manifest) == 159L,
  sum(manifest$source_order <= 676L) == 158L,
  all(manifest$axis == "model_surface"),
  sum(contracts$negative_control) == 1L,
  all(inventory$binding_status[inventory$cell_id == "mc-0260m"] == "partial_negative_control_binding"),
  all(!summary$pregrid_eligible),
  any(inventory$binding_status == "needs_exact_binding"),
  any(receipts$conf_status == "profile_failed"),
  all(is.na(receipts$lower[receipts$conf_status != "profile"]))
)

source_sha <- trimws(system2("git", c("-C", root, "rev-parse", "HEAD"), stdout = TRUE))
packet_dir <- tempfile("lane-b-e0-readiness-")
on.exit(unlink(packet_dir, recursive = TRUE, force = TRUE), add = TRUE)
packet <- phase18_write_interval_campaign_readiness_packet(
  contracts,
  evidence_path = evidence_path,
  output_dir = packet_dir,
  source_sha = source_sha,
  source_root = root,
  partial_bindings = bindings,
  smoke_receipts = receipts
)
stopifnot(
  !packet$pregrid_authorized,
  all(file.exists(unlist(packet[c(
    "manifest", "contracts", "binding_worklist", "binding_inventory",
    "binding_recovery_summary", "local_smoke_receipts", "runtime_receipt"
  )])))
)

cat(
  "Lane-B E0 readiness verified: ",
  length(unique(inventory$cell_id)), " target cells; ",
  sum(inventory$binding_status == "partial_exact_binding"), " recovered targets; ",
  sum(inventory$binding_status == "partial_negative_control_binding"), " retained negative targets; ",
  sum(inventory$binding_status == "needs_exact_binding"), " unresolved cells; pregrid_authorized=FALSE.\n",
  sep = ""
)
