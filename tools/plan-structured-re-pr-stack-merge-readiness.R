#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
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

args <- commandArgs(trailingOnly = TRUE)
mode_matches <- grep("^--mode=", args, value = TRUE)
mode_arg <- if (length(mode_matches)) {
  sub("^--mode=", "", mode_matches[[1L]])
} else {
  "dry-run"
}
if (!identical(mode_arg, "dry-run")) {
  stop(
    "Only --mode=dry-run is supported by this stack-readiness planner.",
    call. = FALSE
  )
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-25-pr-stack-merge-readiness"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

dashboard_path <- file.path(
  dashboard_dir,
  "structured-re-pr-stack-merge-readiness.tsv"
)
snapshot_path <- file.path(
  artifact_dir,
  "structured-re-pr-stack-merge-readiness-snapshot.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-pr-stack-merge-readiness-run-log.tsv"
)

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

observed_utc <- "2026-06-25T19:58:58Z"
platforms_success <- paste(
  "ubuntu-latest (release)",
  "macos-latest (release)",
  "windows-latest (release)",
  sep = ";"
)
dashboard_ref <- paste(
  "docs/dev-log/dashboard",
  "structured-re-pr-stack-merge-readiness.tsv",
  sep = "/"
)
snapshot_ref <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-25-pr-stack-merge-readiness",
  "structured-re-pr-stack-merge-readiness-snapshot.tsv",
  sep = "/"
)
run_log_ref <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-25-pr-stack-merge-readiness",
  "structured-re-pr-stack-merge-readiness-run-log.tsv",
  sep = "/"
)
evidence_ref <- paste(
  "docs/dev-log/after-task",
  "2026-06-25-pr-stack-merge-readiness-extension-656-663.md",
  sep = "/"
)

stack <- data.frame(
  merge_order = seq_len(25),
  pr_number = 639:663,
  title = c(
    "[codex] Bank structured q-series completion slices",
    "[codex] Plan q4 location bootstrap dispatch",
    "[codex] Add q4 location bootstrap runner contract",
    "[codex] Bank relmat q1 scale fixture parity",
    "[codex] Bank q1 scale provider fixture parity",
    "[codex] Bank q4 intercept provider fixture parity",
    "[codex] Bank q4 intercept interval diagnostic plan",
    "[codex] Bank q4 intercept direct-SD interval smoke",
    "[codex] Bank q4 intercept denominator precheck",
    "Bank q4 intercept Hessian bootstrap diagnostic",
    "Bank relmat Q bridge-boundary audit",
    "Bank relmat q4 K/Q native parity",
    "Bank relmat Q payload marshalling gate",
    "Bank sigma slope coverage dispatch review",
    "Bank sigma slope coverage runner contract",
    "Bank q-series PR stack merge-readiness",
    "Bank q2-plus-q2 sigma rejection contract",
    "Bank relmat K/Q one-slope native parity ledger",
    "Admit count structured mu one-slope cells",
    "Split phylo interaction count q1 support cells",
    "Bank count slope fixture recovery contract",
    "Bank count slope native fixture status",
    "Bank count slope recovery runner contract",
    "Bank count slope recovery dispatch review",
    "Bank count slope recovery shard pack contract"
  ),
  base_ref = c(
    "main",
    "codex/structured-relmat-kq-mu-slope-fixture",
    "codex/q4-location-bootstrap-dispatch-plan",
    "codex/q4-location-bootstrap-runner-contract",
    "codex/relmat-q1-intercept-fixture-parity",
    "codex/q1-scale-provider-fixture-parity",
    "codex/q4-intercept-provider-fixture-parity",
    "codex/q4-intercept-interval-contract",
    "codex/q4-intercept-direct-sd-smoke-status",
    "codex/q4-intercept-stability-denominator-precheck",
    "codex/q4-intercept-hessian-bootstrap-diagnostic",
    "codex/relmat-q-bridge-boundary-audit",
    "codex/relmat-q4-location-kq-native-parity",
    "codex/relmat-q-payload-marshalling-gate",
    "codex/sigma-slope-coverage-dispatch-review",
    "codex/sigma-slope-runner-contract",
    "codex/q-series-pr-stack-merge-readiness",
    "codex/q2-plus-q2-sigma-rejection-contract",
    "codex/relmat-kq-one-slope-fixtures",
    "codex/count-structured-mu-one-slope",
    "codex/phylo-interaction-nb2-count-cell",
    "codex/count-slope-fixture-recovery-contract",
    "codex/count-slope-native-fixture-status",
    "codex/count-slope-recovery-runner-contract",
    "codex/count-slope-recovery-dispatch-review"
  ),
  head_ref = c(
    "codex/structured-relmat-kq-mu-slope-fixture",
    "codex/q4-location-bootstrap-dispatch-plan",
    "codex/q4-location-bootstrap-runner-contract",
    "codex/relmat-q1-intercept-fixture-parity",
    "codex/q1-scale-provider-fixture-parity",
    "codex/q4-intercept-provider-fixture-parity",
    "codex/q4-intercept-interval-contract",
    "codex/q4-intercept-direct-sd-smoke-status",
    "codex/q4-intercept-stability-denominator-precheck",
    "codex/q4-intercept-hessian-bootstrap-diagnostic",
    "codex/relmat-q-bridge-boundary-audit",
    "codex/relmat-q4-location-kq-native-parity",
    "codex/relmat-q-payload-marshalling-gate",
    "codex/sigma-slope-coverage-dispatch-review",
    "codex/sigma-slope-runner-contract",
    "codex/q-series-pr-stack-merge-readiness",
    "codex/q2-plus-q2-sigma-rejection-contract",
    "codex/relmat-kq-one-slope-fixtures",
    "codex/count-structured-mu-one-slope",
    "codex/phylo-interaction-nb2-count-cell",
    "codex/count-slope-fixture-recovery-contract",
    "codex/count-slope-native-fixture-status",
    "codex/count-slope-recovery-runner-contract",
    "codex/count-slope-recovery-dispatch-review",
    "codex/count-slope-recovery-shard-pack-contract"
  ),
  head_sha = c(
    "d6b951fe9f3b6fabd1a9d4246bf3346d4ca86e8e",
    "822d5aeb6c0a9d6aa74bf666367d4fa597d9967b",
    "d25ee3d710670a6793f1f9d2b675e32495f66d25",
    "56f41ae35712fa10839cf3aa0af3d0fd36fbbf8f",
    "ed2a2767227324724176481f07997f8f4d89d9bf",
    "cff9b0e02ab3afcb6decc1027cfd8968d4e6530e",
    "7c0618373c397120a1b532faa220d3c96a16bfa0",
    "6730599f621376e743ec614fa234d615d2b016d0",
    "dc20a0507a3d8450d870ebe5b3e842fb8b805580",
    "a38c0338b43ffef90a22eae579a4089df4a3a988",
    "a29cc71a4e52885ce55887eea9096089c9b230df",
    "ac4f05047d7e91f8b0cecc46719b392807fc7b40",
    "6861e0134827a66fc16f60c9081097c077b1fe2a",
    "4ac0e200032ad333920ad6eef6e69901f16890fc",
    "fdb7f78510d24f107f293e7339f4925bf6e3923d",
    "f540fc711f558aeb2829f2d739d50401931ebcf0",
    "691bad99956bf593732395be88bc1269c76f37fc",
    "fd2950e15257c4f0dffab288827394af8e9e261d",
    "a35e5e10a90263290641ddc39b264eac5e6c16ba",
    "95cce5ceb91bc836007745fa20184d3be9f7c3e6",
    "6ce0efa63cd29122823d4de34855e44cae3a56f4",
    "36dba36573d7e5859b7795e91b054e2c87490f9a",
    "3d26dca7b7018dde8268d9ce84d98ae47db07401",
    "3cdd294401af42d5ba93ab2ee18a262a5f47517b",
    "4334213acff3e47fdae849f7d7f787a0748e9ce4"
  ),
  r_cmd_check_run_id = c(
    "28138055013",
    "28139671019",
    "28142464934",
    "28144362238",
    "28145638566",
    "28147092175",
    "28148455870",
    "28150204549",
    "28151981414",
    "28154482855",
    "28156818733",
    "28159429237",
    "28161964711",
    "28164197137",
    "28166541285",
    "28168795112",
    "28170403815",
    "28175177624",
    "28180855796",
    "28183541915",
    "28186188654",
    "28188540878",
    "28190850945",
    "28192932086",
    "28195628489"
  ),
  stringsAsFactors = FALSE
)

stack$stack_row_id <- paste0("structured_re_pr_stack_merge_", stack$pr_number)
stack$pr_url <- paste0(
  "https://github.com/itchyshin/drmTMB/pull/",
  stack$pr_number
)
stack$observed_utc <- observed_utc
stack$draft_status <- "draft"
stack$merge_state_status <- "CLEAN"
stack$pr_rollup_status <- ifelse(
  stack$pr_number == 639,
  "attached_pr_checks_green_on_main_base",
  "commit_checks_green_pr_rollup_empty_on_stacked_base"
)
stack$commit_check_status <- "three_platform_success"
stack$platform_success_count <- "3"
stack$platform_successes <- platforms_success
stack$merge_gate <- "human_approval_required"
stack$retarget_requirement <- ifelse(
  stack$pr_number == 639,
  "none_first_pr_targets_main",
  "retarget_to_main_after_previous_merge"
)
stack$normal_pr_check_requirement <- ifelse(
  stack$pr_number == 639,
  "already_attached_to_main_base",
  "rerun_after_retarget_to_main"
)
stack$merge_action <- ifelse(
  stack$pr_number == 639,
  "merge_first_after_approval",
  paste0("merge_after_pr_", stack$pr_number - 1L, "_lands_and_checks_refresh")
)
stack$compute_status <- "not_executed"
stack$drac_status <- "not_submitted"
stack$totoro_status <- "not_submitted"
stack$coverage_claim_status <- "not_evaluated"
stack$interval_claim_status <- "not_promoted"
stack$reml_claim_status <- "not_promoted"
stack$public_support_status <- "not_promoted"
stack$stack_status <- "merge_readiness_snapshot"
stack$dashboard_snapshot <- dashboard_ref
stack$artifact_snapshot <- snapshot_ref
stack$run_log <- run_log_ref
stack$evidence_url <- evidence_ref
stack$claim_boundary <- clean_text(paste(
  "merge-readiness snapshot only; PRs remain draft, no PR was undrafted,",
  "no PR was merged, no Totoro job submitted, no DRAC job submitted,",
  "no coverage-evaluable denominator evidence, no MCSE-calibrated coverage,",
  "no interval reliability, no q4 REML, no native-TMB q4 REML,",
  "no q4 AI-REML, no HSquared AI-REML, no non-Gaussian REML,",
  "no AI-REML, no broad bridge support, no public support,",
  "and no SR150 readiness promoted."
))
stack$next_gate <- clean_text(paste(
  "Ask Shinichi for explicit merge approval; merge from PR #639 upward;",
  "after each merge retarget the next PR to main, rerun normal PR checks,",
  "rerun mission-control validation, and only then return to sigma-slope",
  "or relmat runtime slices."
))

stack <- stack[
  c(
    "stack_row_id",
    "merge_order",
    "pr_number",
    "title",
    "base_ref",
    "head_ref",
    "head_sha",
    "pr_url",
    "observed_utc",
    "draft_status",
    "merge_state_status",
    "pr_rollup_status",
    "commit_check_status",
    "r_cmd_check_run_id",
    "platform_success_count",
    "platform_successes",
    "merge_gate",
    "retarget_requirement",
    "normal_pr_check_requirement",
    "merge_action",
    "compute_status",
    "drac_status",
    "totoro_status",
    "coverage_claim_status",
    "interval_claim_status",
    "reml_claim_status",
    "public_support_status",
    "stack_status",
    "dashboard_snapshot",
    "artifact_snapshot",
    "run_log",
    "evidence_url",
    "claim_boundary",
    "next_gate"
  )
]

run_log <- data.frame(
  run_id = "structured_re_pr_stack_merge_readiness_snapshot",
  mode = mode_arg,
  observed_utc = observed_utc,
  stack_rows = nrow(stack),
  first_pr = "639",
  last_pr = as.character(max(stack$pr_number)),
  draft_rows = sum(stack$draft_status == "draft"),
  clean_rows = sum(stack$merge_state_status == "CLEAN"),
  commit_check_success_rows = sum(
    stack$commit_check_status == "three_platform_success"
  ),
  attached_pr_rollup_rows = sum(
    stack$pr_rollup_status == "attached_pr_checks_green_on_main_base"
  ),
  stacked_pr_rollup_empty_rows = sum(
    stack$pr_rollup_status ==
      "commit_checks_green_pr_rollup_empty_on_stacked_base"
  ),
  dashboard_snapshot = dashboard_ref,
  artifact_snapshot = snapshot_ref,
  source_live_commands = clean_text(paste(
    "gh pr list --repo itchyshin/drmTMB --state open --json",
    "number,title,isDraft,headRefName,baseRefName,mergeStateStatus,",
    "headRefOid,url,statusCheckRollup; gh api",
    "repos/itchyshin/drmTMB/commits/<sha>/check-runs;",
    "gh run view 28168795112 --repo itchyshin/drmTMB --json",
    "status,conclusion,jobs; gh run view 28170403815 --repo",
    "itchyshin/drmTMB --json status,conclusion,jobs;",
    "for run in 28175177624 28180855796 28183541915 28186188654",
    "28188540878 28190850945 28192932086 28195628489; do gh run view $run",
    "--repo itchyshin/drmTMB --json status,conclusion,jobs; done"
  )),
  execution_status = "validated_snapshot_not_executed",
  merge_status = "not_merged",
  compute_status = "not_executed",
  drac_status = "not_submitted",
  totoro_status = "not_submitted",
  status = "covered",
  claim_boundary = unique(stack$claim_boundary),
  next_gate = unique(stack$next_gate),
  stringsAsFactors = FALSE
)

write_tsv <- function(x, path) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
}

write_tsv(stack, dashboard_path)
write_tsv(stack, snapshot_path)
write_tsv(run_log, run_log_path)

message("wrote ", nrow(stack), " PR stack merge-readiness rows")
message("wrote ", snapshot_path)
message("wrote ", run_log_path)
