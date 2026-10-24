#!/usr/bin/env Rscript
# Turn a fully reconciled S7 campaign into the small, generated coverage table
# consumed by later documentation. This is deliberately separate from the
# four-fixture point/profile classification summary: a 500-seed coverage
# estimate is not a generic point/SE parity receipt.

r071_s7_coverage_provenance_names <- function() {
  c(
    "drmtmb_commit", "drm_jl_commit", "campaign_metadata_sha256",
    "drmtmb_archive_sha256", "drm_jl_archive_sha256", "source_pins_sha256",
    "runtime_sha256", "source_tree_check_sha256", "collector_sha256", "contract_sha256"
  )
}

r071_s7_is_sha256 <- function(x) {
  is.character(x) && length(x) == 1L && grepl("^[0-9a-f]{64}$", x)
}

r071_s7_validate_coverage_provenance <- function(provenance) {
  required <- r071_s7_coverage_provenance_names()
  if (!is.list(provenance) || !identical(sort(names(provenance)), sort(required))) {
    stop("S7 coverage provenance schema drift", call. = FALSE)
  }
  commits <- c("drmtmb_commit", "drm_jl_commit")
  if (any(!vapply(provenance[commits], function(x) {
    is.character(x) && length(x) == 1L && grepl("^[0-9a-f]{40}$", x)
  }, logical(1L))) || any(!vapply(provenance[setdiff(required, commits)],
                                    r071_s7_is_sha256, logical(1L)))) {
    stop("S7 coverage provenance has invalid source identities", call. = FALSE)
  }
  invisible(provenance)
}

r071_s7_coverage_capability <- function(fixture) {
  ifelse(
    fixture %in% c("binomial_ri", "poisson_ri", "nb2_ri"),
    "ordinary_ri_scalar_laplace",
    ifelse(fixture == "nb2_coupled", "ordinary_nb2_coupled_laplace", NA_character_)
  )
}

r071_s7_coverage_table <- function(attempts, profile_plan, provenance) {
  r071_s7_validate_coverage_provenance(provenance)
  required_plan <- c("fixture", "engine", "parm", "target_class", "truth")
  if (!is.data.frame(profile_plan) || !all(required_plan %in% names(profile_plan)) ||
      nrow(profile_plan) != 34L || anyDuplicated(profile_plan[c("fixture", "engine", "parm")])) {
    stop("S7 coverage writer needs the exact frozen 34-target profile plan", call. = FALSE)
  }
  summary <- r071_s7_coverage_summary(attempts)
  key <- function(x) paste(x$fixture, x$engine, x$parm, sep = "\r")
  plan_key <- key(profile_plan)
  summary_key <- key(summary)
  if (nrow(summary) != nrow(profile_plan) || anyDuplicated(summary_key) ||
      !setequal(summary_key, plan_key) || any(summary$attempt_count != 500L)) {
    stop("S7 coverage writer requires exactly 500 attempts for every frozen target", call. = FALSE)
  }
  plan <- profile_plan[match(summary_key, plan_key), required_plan, drop = FALSE]
  if (!isTRUE(all.equal(as.numeric(summary$truth), as.numeric(plan$truth), tolerance = 1e-12))) {
    stop("S7 coverage writer sees a truth mismatch against the frozen profile plan", call. = FALSE)
  }
  capability_id <- r071_s7_coverage_capability(summary$fixture)
  if (anyNA(capability_id) || !identical(sort(unique(capability_id)), c(
    "ordinary_nb2_coupled_laplace", "ordinary_ri_scalar_laplace"
  ))) {
    stop("S7 coverage writer cannot classify the frozen fixture set", call. = FALSE)
  }
  out <- data.frame(
    capability_id = capability_id,
    fixture = summary$fixture,
    engine = summary$engine,
    parm = summary$parm,
    target_class = plan$target_class,
    truth = summary$truth,
    summary[, setdiff(names(summary), c("fixture", "engine", "parm", "truth")), drop = FALSE],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  for (name in r071_s7_coverage_provenance_names()) out[[name]] <- provenance[[name]]
  row.names(out) <- NULL
  out[order(out$fixture, out$engine, out$parm), , drop = FALSE]
}

r071_s7_read_source_pins <- function(path) {
  required <- c("component", "git_commit", "sha256", "storage_route")
  if (!file.exists(path)) stop("S7 coverage writer cannot find source-pin receipt", call. = FALSE)
  tab <- utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  expected <- c("drmTMB", "DRM.jl", "s7-manifest", "s7-profile-plan", "s7-campaign")
  if (!identical(names(tab), required) || nrow(tab) != length(expected) ||
      anyDuplicated(tab$component) || !setequal(tab$component, expected) ||
      any(!vapply(tab$sha256, r071_s7_is_sha256, logical(1L))) ||
      any(!grepl("^(?:[0-9a-f]{40}|frozen)$", tab$git_commit))) {
    stop("S7 coverage source-pin receipt schema drift", call. = FALSE)
  }
  tab[match(expected, tab$component), , drop = FALSE]
}

r071_s7_file_sha256 <- function(path) {
  if (!file.exists(path)) stop("S7 coverage writer cannot hash absent file: ", path, call. = FALSE)
  if (exists("r071_s7_sha256", mode = "function", inherits = TRUE)) return(r071_s7_sha256(path))
  unname(tools::sha256sum(path)[[1L]])
}

r071_s7_read_source_tree_check <- function(path, source_root, drmjl_source_root,
                                            drmtmb_archive_sha256, drmjl_archive_sha256) {
  if (!file.exists(path)) stop("S7 coverage writer needs a source-tree archive comparison", call. = FALSE)
  lines <- readLines(path, warn = FALSE)
  keys <- c("source_tree_archive_compare", "source_subset_commit_proof",
            "drmtmb_source", "drmjl_source", "drmtmb_archive_sha256",
            "drmjl_archive_sha256")
  fields <- strsplit(lines, "=", fixed = TRUE)
  observed_keys <- vapply(fields, function(x) if (length(x) == 2L) x[[1L]] else NA_character_, character(1L))
  values <- vapply(fields, function(x) if (length(x) == 2L) x[[2L]] else NA_character_, character(1L))
  if (!identical(observed_keys, keys) || anyNA(values) ||
      !identical(values[[1L]], "PASS") ||
      !identical(values[[2L]], "PASS") ||
      !identical(normalizePath(values[[3L]], mustWork = TRUE), normalizePath(source_root, mustWork = TRUE)) ||
      !identical(normalizePath(values[[4L]], mustWork = TRUE), normalizePath(drmjl_source_root, mustWork = TRUE)) ||
      !identical(values[[5L]], drmtmb_archive_sha256) ||
      !identical(values[[6L]], drmjl_archive_sha256)) {
    stop("S7 coverage source-subset commit proof is invalid", call. = FALSE)
  }
  invisible(path)
}

r071_s7_campaign_provenance <- function(campaign_root, source_root, drmjl_source_root, collector_path, source_tree_check) {
  pins_path <- file.path(campaign_root, "source-staging", "source-pins-final.tsv")
  pins <- r071_s7_read_source_pins(pins_path)
  pick <- function(component, column) pins[[column]][match(component, pins$component)]
  archive_path <- function(component, stem) {
    commit <- pick(component, "git_commit")
    hits <- list.files(file.path(campaign_root, "source-staging"),
                       pattern = paste0("^", stem, "-", substr(commit, 1L, 8L), ".*\\.tar\\.gz$"),
                       full.names = TRUE)
    if (length(hits) != 1L) stop("S7 coverage writer cannot identify frozen ", component, " archive", call. = FALSE)
    hits[[1L]]
  }
  drmtmb_archive <- archive_path("drmTMB", "drmTMB")
  drmjl_archive <- archive_path("DRM.jl", "DRMjl")
  if (!identical(r071_s7_file_sha256(drmtmb_archive), pick("drmTMB", "sha256")) ||
      !identical(r071_s7_file_sha256(drmjl_archive), pick("DRM.jl", "sha256"))) {
    stop("S7 coverage writer source archive checksum mismatch", call. = FALSE)
  }
  bundle <- file.path(campaign_root, "bundle")
  if (!identical(r071_s7_file_sha256(file.path(bundle, "s7-manifest.tsv")), pick("s7-manifest", "sha256")) ||
      !identical(r071_s7_file_sha256(file.path(bundle, "s7-profile-plan.tsv")), pick("s7-profile-plan", "sha256")) ||
      !identical(r071_s7_file_sha256(file.path(bundle, "campaign.json")), pick("s7-campaign", "sha256"))) {
    stop("S7 coverage writer campaign bundle checksum mismatch", call. = FALSE)
  }
  runtime <- list.files(file.path(campaign_root, "preflight"), pattern = "^runtime-[0-9]+\\.txt$", full.names = TRUE)
  if (length(runtime) != 1L) stop("S7 coverage writer needs exactly one preflight runtime receipt", call. = FALSE)
  r071_s7_read_source_tree_check(source_tree_check, source_root, drmjl_source_root,
                                 pick("drmTMB", "sha256"), pick("DRM.jl", "sha256"))
  contract <- file.path(source_root, "docs", "dev-log", "evidence", "julia-r-parity", "071-ordinary-laplace", "s7-attempt-contract.R")
  list(
    drmtmb_commit = pick("drmTMB", "git_commit"),
    drm_jl_commit = pick("DRM.jl", "git_commit"),
    campaign_metadata_sha256 = pick("s7-campaign", "sha256"),
    drmtmb_archive_sha256 = pick("drmTMB", "sha256"),
    drm_jl_archive_sha256 = pick("DRM.jl", "sha256"),
    source_pins_sha256 = r071_s7_file_sha256(pins_path),
    runtime_sha256 = r071_s7_file_sha256(runtime[[1L]]),
    source_tree_check_sha256 = r071_s7_file_sha256(source_tree_check),
    collector_sha256 = r071_s7_file_sha256(collector_path),
    contract_sha256 = r071_s7_file_sha256(contract)
  )
}

r071_s7_write_coverage_summary <- function(campaign_root, source_root, drmjl_source_root, out, collector_path, source_tree_check) {
  campaign_root <- normalizePath(campaign_root, mustWork = TRUE)
  source_root <- normalizePath(source_root, mustWork = TRUE)
  drmjl_source_root <- normalizePath(drmjl_source_root, mustWork = TRUE)
  helper_dir <- file.path(source_root, "docs", "dev-log", "evidence", "julia-r-parity", "071-ordinary-laplace")
  for (file in c("prepare-s7-campaign-manifest.R", "prepare-s7-campaign-bundle.R",
                 "s7-attempt-contract.R", "s7-run-task.R", "s7-reconcile-campaign.R")) {
    path <- file.path(helper_dir, file)
    if (!file.exists(path)) stop("S7 coverage writer is missing helper: ", path, call. = FALSE)
    sys.source(path, envir = environment())
  }
  collected <- r071_s7_collect_campaign(campaign_root)
  bundle <- r071_s7_read_campaign_bundle(file.path(campaign_root, "bundle"))
  tab <- r071_s7_coverage_table(
    attempts = collected$attempts, profile_plan = bundle$profile_plan,
    provenance = r071_s7_campaign_provenance(campaign_root, source_root, drmjl_source_root,
                                               collector_path, source_tree_check)
  )
  sidecar <- paste0(out, ".sha256")
  if (file.exists(out) || file.exists(sidecar)) {
    stop("refusing to overwrite immutable S7 coverage summary or checksum", call. = FALSE)
  }
  dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
  r071_s7_atomic_write(out, function(path) {
    utils::write.table(tab, path, sep = "\t", quote = FALSE, row.names = FALSE)
  })
  r071_s7_atomic_write(sidecar, function(path) {
    writeLines(paste(r071_s7_file_sha256(out), basename(out), sep = "  "), path)
  })
  invisible(tab)
}

r071_s7_coverage_args <- function(args) {
  if (any(!grepl("^--[a-z-]+=.+$", args))) stop("S7 coverage writer arguments must use --name=value", call. = FALSE)
  key <- sub("^--([^=]+)=.*$", "\\1", args)
  out <- stats::setNames(sub("^--[^=]+=", "", args), key)
  required <- c("campaign-root", "source-root", "drmjl-source-root", "out", "source-tree-check")
  if (anyDuplicated(key) || !identical(sort(names(out)), sort(required))) {
    stop("S7 coverage writer needs exactly --campaign-root, --source-root, --drmjl-source-root, --out, and --source-tree-check", call. = FALSE)
  }
  out
}

if (sys.nframe() == 0L) {
  args <- r071_s7_coverage_args(commandArgs(trailingOnly = TRUE))
  script <- sub("^--file=", "", commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))][[1L]])
  r071_s7_write_coverage_summary(args[["campaign-root"]], args[["source-root"]], args[["drmjl-source-root"]],
                                 args[["out"]], normalizePath(script, mustWork = TRUE),
                                 args[["source-tree-check"]])
  cat("S7_COVERAGE_SUMMARY_WRITTEN\n")
}
