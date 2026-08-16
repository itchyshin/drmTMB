#!/usr/bin/env Rscript
# Run one source-bound ordinary RE-SD slope profile gate.
#
# This runner is deliberately dormant until a later approved execution calls it
# without --dry-run.  Dry runs validate the exact seven-row registry only: they
# do not load drmTMB, require an adapter, fit a model, profile, or write files.

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x

ordinary_slope_profile_cells <- c(
  "mc-0007", "mc-0270", "mc-0271", "mc-0380", "mc-0402", "mc-0431", "mc-0511"
)

ordinary_slope_profile_file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
ordinary_slope_profile_default_script <- c(
  "tools/run-lane-b-ordinary-slope-profile-gate.R",
  "../../tools/run-lane-b-ordinary-slope-profile-gate.R"
)
ordinary_slope_profile_default_script <- ordinary_slope_profile_default_script[
  file.exists(ordinary_slope_profile_default_script)
][1L] %||% ordinary_slope_profile_default_script[[1L]]
ordinary_slope_profile_script <- normalizePath(
  if (length(ordinary_slope_profile_file_arg)) {
    sub("^--file=", "", ordinary_slope_profile_file_arg[[1L]])
  } else {
    ordinary_slope_profile_default_script
  },
  mustWork = FALSE
)
ordinary_slope_profile_tools_dir <- dirname(ordinary_slope_profile_script)
ordinary_slope_profile_root <- normalizePath(
  file.path(ordinary_slope_profile_tools_dir, ".."),
  mustWork = TRUE
)

ordinary_slope_profile_stop <- function(...) stop(..., call. = FALSE)

ordinary_slope_profile_sha256 <- function(path) {
  if (!file.exists(path)) ordinary_slope_profile_stop("Cannot hash missing file: ", path)
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  args <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  output <- suppressWarnings(system2(command, args, stdout = TRUE, stderr = TRUE))
  if (!length(output) || !grepl("^[0-9a-f]{64}\\s", output[[1L]])) {
    ordinary_slope_profile_stop("Could not calculate SHA-256 for ", path, ".")
  }
  sub("\\s.*$", "", output[[1L]])
}

ordinary_slope_profile_git <- function(args) {
  output <- suppressWarnings(system2(
    "git", c("-C", ordinary_slope_profile_root, args), stdout = TRUE, stderr = TRUE
  ))
  if ((attr(output, "status") %||% 0L) != 0L) return(NA_character_)
  paste(output, collapse = "\n")
}

ordinary_slope_profile_parse_args <- function(args) {
  out <- list(dry_run = FALSE)
  for (arg in args) {
    if (identical(arg, "--dry-run")) {
      if (isTRUE(out$dry_run)) ordinary_slope_profile_stop("Duplicate argument: --dry-run.")
      out$dry_run <- TRUE
      next
    }
    if (!grepl("^--[A-Za-z][A-Za-z-]*=.+$", arg)) {
      ordinary_slope_profile_stop("Arguments must use --name=value syntax (except --dry-run).")
    }
    key_value <- strsplit(substring(arg, 3L), "=", fixed = TRUE)[[1L]]
    key <- key_value[[1L]]
    if (!is.null(out[[key]])) ordinary_slope_profile_stop("Duplicate argument: --", key, ".")
    out[[key]] <- paste(key_value[-1L], collapse = "=")
  }
  required <- c("cell", "seed", "rung", "output-dir")
  missing <- required[vapply(required, function(x) {
    is.null(out[[x]]) || !nzchar(out[[x]])
  }, logical(1L))]
  if (length(missing)) {
    ordinary_slope_profile_stop("Missing required argument(s): --", paste(missing, collapse = ", --"), "=.")
  }
  extra <- setdiff(names(out), c(required, "dry_run", "registry"))
  if (length(extra)) ordinary_slope_profile_stop("Unsupported argument(s): --", paste(extra, collapse = ", --"), ".")
  out$seed <- suppressWarnings(as.integer(out$seed))
  if (length(out$seed) != 1L || is.na(out$seed) || out$seed < 1L) {
    ordinary_slope_profile_stop("--seed must be a positive integer.")
  }
  out
}

ordinary_slope_profile_binding_path <- function(registry = NULL) {
  path <- if (is.null(registry)) file.path(
    ordinary_slope_profile_root, "docs", "dev-log", "interval-campaign-bindings",
    "2026-07-28-ordinary-re-sd-slope-canonical-registry.tsv"
  ) else registry
  if (!grepl("^/", path)) path <- file.path(ordinary_slope_profile_root, path)
  normalizePath(path, mustWork = FALSE)
}

ordinary_slope_profile_validate_contract <- function(cell_id, rung, registry = NULL) {
  custom_registry <- !is.null(registry)
  binding_path <- ordinary_slope_profile_binding_path(registry)
  if (!file.exists(binding_path)) {
    ordinary_slope_profile_stop("Missing ordinary RE-SD slope canonical registry: ", binding_path)
  }
  registry <- utils::read.delim(binding_path, check.names = FALSE, stringsAsFactors = FALSE)
  required <- c(
    "cell_id", "target_id", "dgp_id", "dgp_version", "formula",
    "true_parameter_scale", "profile_parameter", "binding_information_rung",
    "execution_information_rung", "binding_source", "source_sha", "target_cardinality",
    "review_state"
  )
  missing <- setdiff(required, names(registry))
  if (length(missing)) {
    ordinary_slope_profile_stop("Canonical registry is missing: ", paste(missing, collapse = ", "), ".")
  }
  is_high_extension <- custom_registry && basename(binding_path) == "2026-07-28-ordinary-re-sd-slope-high-rung-registry.tsv"
  if (is_high_extension) {
    if (nrow(registry) != 1L || anyDuplicated(registry$cell_id) || !identical(registry$cell_id[[1L]], "mc-0271")) {
      ordinary_slope_profile_stop("High-rung registry must contain only mc-0271 once.")
    }
  } else if (nrow(registry) != length(ordinary_slope_profile_cells) || anyDuplicated(registry$cell_id) ||
             !setequal(registry$cell_id, ordinary_slope_profile_cells)) {
    ordinary_slope_profile_stop("Canonical registry must contain exactly the seven approved ordinary-slope cells once each.")
  }
  row <- registry[registry$cell_id == cell_id, , drop = FALSE]
  if (nrow(row) != 1L) {
    ordinary_slope_profile_stop("--cell must be one of: ", paste(ordinary_slope_profile_cells, collapse = ", "), ".")
  }
  if (!identical(as.character(row$execution_information_rung[[1L]]), as.character(rung))) {
    ordinary_slope_profile_stop(
      "--rung must exactly match this cell's frozen execution rung: ",
      row$execution_information_rung[[1L]], "."
    )
  }
  if ((!is_high_extension && !identical(as.character(row$execution_information_rung[[1L]]), "low")) ||
      (is_high_extension && !identical(as.character(row$execution_information_rung[[1L]]), "high")) ||
      !identical(as.character(row$review_state[[1L]]), "canonical_review_passed") ||
      !identical(as.integer(row$target_cardinality[[1L]]), 1L) ||
      !identical(as.character(row$target_id[[1L]]), paste(cell_id, row$profile_parameter[[1L]], sep = "::"))) {
    ordinary_slope_profile_stop("Canonical registry row is not a one-target reviewed execution contract.")
  }
  list(binding = row, registry_path = binding_path, execution_rung = rung)
}

ordinary_slope_profile_paths <- function(output_dir, cell_id, seed, rung) {
  stem <- sprintf("lane-b-ordinary-slope-profile-%s-%s-seed-%d", cell_id, rung, seed)
  list(
    trace = file.path(output_dir, paste0(stem, "-trace.tsv")),
    interval = file.path(output_dir, paste0(stem, "-interval.tsv")),
    receipt = file.path(output_dir, paste0(stem, "-receipt.tsv"))
  )
}

ordinary_slope_profile_atomic_write <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile("lane-b-ordinary-slope-", tmpdir = dirname(path), fileext = ".tsv")
  on.exit(unlink(temporary), add = TRUE)
  utils::write.table(x, temporary, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
  if (!file.rename(temporary, path)) ordinary_slope_profile_stop("Could not atomically write ", path, ".")
  invisible(path)
}

ordinary_slope_profile_require_fresh_paths <- function(paths) {
  present <- unlist(paths[file.exists(unlist(paths))], use.names = FALSE)
  if (length(present)) {
    ordinary_slope_profile_stop("Refusing to replace retained profile artifact(s): ", paste(present, collapse = ", "), ".")
  }
}

ordinary_slope_profile_adapter_path <- function() {
  file.path(ordinary_slope_profile_tools_dir, "lane-b-ordinary-slope-adapters.R")
}

ordinary_slope_profile_load_adapter <- function(cell_id, seed, rung) {
  path <- ordinary_slope_profile_adapter_path()
  if (!file.exists(path)) {
    ordinary_slope_profile_stop(
      "Production adapter file is required for execution but is not present: ", path,
      ". Use --dry-run until a later approved lane supplies it."
    )
  }
  adapter_env <- new.env(parent = globalenv())
  sys.source(path, envir = adapter_env)
  factory <- adapter_env$lane_b_ordinary_slope_adapter_fixture
  if (!is.function(factory)) {
    ordinary_slope_profile_stop("Adapter file must define lane_b_ordinary_slope_adapter_fixture(cell, seed, rung).")
  }
  adapter <- factory(cell = cell_id, seed = seed, rung = rung)
  if (!is.list(adapter) || !identical(sort(names(adapter)), sort(c("data", "truth", "fit"))) ||
      !is.data.frame(adapter$data) || !is.list(adapter$truth) || !is.function(adapter$fit) ||
      !is.character(adapter$truth$profile_parameter) || length(adapter$truth$profile_parameter) != 1L) {
    ordinary_slope_profile_stop("Adapter must be a list(data = data.frame, truth = list(profile_parameter = ...), fit = function(data) ...).")
  }
  adapter
}

ordinary_slope_profile_readiness_env <- function() {
  readiness_path <- file.path(
    ordinary_slope_profile_root, "inst", "sim", "R", "sim_interval_campaign_readiness.R"
  )
  if (!file.exists(readiness_path)) ordinary_slope_profile_stop("Missing interval readiness helper: ", readiness_path)
  readiness <- new.env(parent = baseenv())
  sys.source(readiness_path, envir = readiness)
  readiness
}

ordinary_slope_profile_validate_receipt <- function(receipt, contract) {
  readiness <- ordinary_slope_profile_readiness_env()
  binding <- contract$binding
  smoke_receipt <- receipt[, c(
    "cell_id", "target_id", "dgp_id", "seed", "conf_status", "lower", "upper",
    "convergence", "pdHess", "profile_boundary", "trace_complete", "failure_reason", "source"
  ), drop = FALSE]
  smoke_binding <- data.frame(
    cell_id = binding$cell_id,
    target_id = binding$target_id,
    dgp_id = binding$dgp_id,
    binding_source = binding$binding_source,
    stringsAsFactors = FALSE
  )
  manifest_path <- file.path(
    ordinary_slope_profile_root, "docs", "dev-log", "dashboard", "capability-ledger", "cells.tsv"
  )
  contracts <- readiness$phase18_interval_campaign_contracts(
    readiness$phase18_interval_campaign_manifest(manifest_path)
  )
  readiness$phase18_validate_interval_campaign_smoke_receipts(
    smoke_receipt, contracts, smoke_binding
  )
  if (!identical(as.character(receipt$profile_engine[[1L]]), "tmbprofile")) {
    ordinary_slope_profile_stop("Receipt must retain the tmbprofile engine.")
  }
  if (!identical(as.character(receipt$conf_status[[1L]]), "profile")) return(invisible(receipt))
  if (
      !is.finite(receipt$estimate[[1L]]) || !is.finite(receipt$lower[[1L]]) ||
      !is.finite(receipt$upper[[1L]]) || receipt$lower[[1L]] >= receipt$upper[[1L]] ||
      receipt$estimate[[1L]] < receipt$lower[[1L]] || receipt$estimate[[1L]] > receipt$upper[[1L]] ||
      receipt$convergence[[1L]] != 0L || !isTRUE(receipt$pdHess[[1L]]) ||
      !isFALSE(receipt$profile_boundary[[1L]]) || !isFALSE(receipt$clamp_limited[[1L]]) ||
      (!is.na(receipt$clamp_reason[[1L]]) && nzchar(receipt$clamp_reason[[1L]]))) {
    ordinary_slope_profile_stop("Successful receipt must retain tmbprofile, finite interior endpoints, convergence 0, pdHess TRUE, and no clamp contact.")
  }
  invisible(receipt)
}

ordinary_slope_profile_write_failure_receipt <- function(
    contract, cell_id, seed, rung, paths, stage, error) {
  binding <- contract$binding
  source_sha <- ordinary_slope_profile_git(c("rev-parse", "HEAD"))
  receipt <- data.frame(
    cell_id = cell_id, target_id = binding$target_id[[1L]], dgp_id = binding$dgp_id[[1L]],
    dgp_version = binding$dgp_version[[1L]], formula = binding$formula[[1L]],
    true_parameter_scale = binding$true_parameter_scale[[1L]],
    profile_parameter = binding$profile_parameter[[1L]], seed = as.integer(seed),
    binding_information_rung = binding$binding_information_rung[[1L]],
    execution_information_rung = rung, binding_source = binding$binding_source[[1L]],
    source = contract$registry_path, source_sha = source_sha,
    recorded_at = format(Sys.time(), tz = "UTC", usetz = TRUE), execution_stage = stage,
    conf_status = "profile_failed", profile_engine = "tmbprofile", estimate = NA_real_,
    lower = NA_real_, upper = NA_real_, convergence = NA_integer_, pdHess = NA,
    profile_boundary = NA, clamp_limited = NA, clamp_reason = NA_character_,
    trace_complete = FALSE, failure_reason = paste0(stage, ": ", conditionMessage(error)),
    promotion_eligible = FALSE, promotion_status = "prohibited_no_ledger_promotion",
    runner_sha256 = ordinary_slope_profile_sha256(ordinary_slope_profile_script),
    adapter_sha256 = if (file.exists(ordinary_slope_profile_adapter_path())) {
      ordinary_slope_profile_sha256(ordinary_slope_profile_adapter_path())
    } else {
      NA_character_
    },
    binding_sha256 = ordinary_slope_profile_sha256(contract$registry_path),
    trace_path = normalizePath(paths$trace, mustWork = FALSE),
    interval_path = normalizePath(paths$interval, mustWork = FALSE),
    trace_sha256 = if (file.exists(paths$trace)) ordinary_slope_profile_sha256(paths$trace) else NA_character_,
    interval_sha256 = if (file.exists(paths$interval)) ordinary_slope_profile_sha256(paths$interval) else NA_character_,
    stringsAsFactors = FALSE
  )
  ordinary_slope_profile_atomic_write(receipt, paths$receipt)
  invisible(paths$receipt)
}

ordinary_slope_profile_execute <- function(contract, cell_id, seed, rung, output_dir) {
  paths <- ordinary_slope_profile_paths(output_dir, cell_id, seed, rung)
  ordinary_slope_profile_require_fresh_paths(paths)
  stage <- "adapter"
  tryCatch({
    adapter <- ordinary_slope_profile_load_adapter(cell_id, seed, rung)
    binding <- contract$binding
    if (!identical(adapter$truth$profile_parameter, binding$profile_parameter[[1L]])) {
      ordinary_slope_profile_stop("Adapter truth profile_parameter differs from the frozen canonical registry.")
    }
    stage <- "source_load"
    if (!requireNamespace("pkgload", quietly = TRUE)) {
      ordinary_slope_profile_stop("pkgload is required to load the exact source checkout for execution.")
    }
    pkgload::load_all(ordinary_slope_profile_root, quiet = TRUE, export_all = FALSE)
    stage <- "fit"
    fit <- adapter$fit(adapter$data)
    stage <- "profile_target"
    targets <- drmTMB::profile_targets(fit)
    target_row <- targets[
      targets$parm == binding$profile_parameter[[1L]] & targets$profile_ready %in% TRUE,
      , drop = FALSE
    ]
    if (nrow(target_row) != 1L) {
      ordinary_slope_profile_stop(
        "Frozen profile parameter is not uniquely profile-ready in this fit: ",
        binding$profile_parameter[[1L]], "."
      )
    }
    stage <- "profile"
    profile <- stats::profile(fit, parm = binding$profile_parameter[[1L]], trace = TRUE)
  trace <- as.data.frame(profile, stringsAsFactors = FALSE)
  if (!nrow(trace)) ordinary_slope_profile_stop("tmbprofile returned an empty trace.")
  conf_status <- unique(as.character(trace$conf.status))
  profile_message <- unique(as.character(trace$profile.message))
  lower <- unique(as.numeric(trace$conf.low))
  upper <- unique(as.numeric(trace$conf.high))
  estimate <- unique(as.numeric(trace$estimate))
  if (length(conf_status) != 1L || length(profile_message) != 1L || length(lower) != 1L ||
      length(upper) != 1L || length(estimate) != 1L) {
    ordinary_slope_profile_stop("tmbprofile trace must retain one status, message, estimate, and endpoint pair.")
  }
  diagnostics <- drmTMB:::profile_interval_diagnostics(
    c(lower, upper), transformation = unique(trace$transformation)[[1L]], estimate = estimate
  )
  profile_boundary <- isTRUE(diagnostics$boundary)
  clamp_limited <- identical(conf_status, "clamp_limited")
  trace_complete <- identical(conf_status, "profile") && identical(profile_message, "ok")
  successful_profile <- trace_complete && !profile_boundary && !clamp_limited
  receipt_status <- if (successful_profile) {
    "profile"
  } else if (clamp_limited) {
    "clamp_limited"
  } else if (trace_complete) {
    "profile_failed"
  } else {
    "trace_incomplete"
  }
  failure_reason <- if (successful_profile) {
    NA_character_
  } else if (clamp_limited) {
    profile_message
  } else if (profile_boundary) {
    diagnostics$message
  } else {
    profile_message
  }
  trace$cell_id <- cell_id
  trace$target_id <- binding$target_id[[1L]]
  trace$seed <- as.integer(seed)
  trace$execution_information_rung <- rung
  interval <- data.frame(
    cell_id = cell_id, target_id = binding$target_id[[1L]], seed = as.integer(seed),
    execution_information_rung = rung, profile_parameter = binding$profile_parameter[[1L]],
    level = 0.95, lower = lower, upper = upper, profile_engine = "tmbprofile",
    stringsAsFactors = FALSE
  )
    stage <- "trace_write"
    ordinary_slope_profile_atomic_write(trace, paths$trace)
    ordinary_slope_profile_atomic_write(interval, paths$interval)
    source_sha <- ordinary_slope_profile_git(c("rev-parse", "HEAD"))
    receipt <- data.frame(
    cell_id = cell_id, target_id = binding$target_id[[1L]], dgp_id = binding$dgp_id[[1L]],
    dgp_version = binding$dgp_version[[1L]], formula = binding$formula[[1L]],
    true_parameter_scale = binding$true_parameter_scale[[1L]],
    profile_parameter = binding$profile_parameter[[1L]], seed = as.integer(seed),
    binding_information_rung = binding$binding_information_rung[[1L]],
    execution_information_rung = rung, binding_source = binding$binding_source[[1L]],
    source = normalizePath(paths$trace, mustWork = TRUE), source_sha = source_sha,
    recorded_at = format(Sys.time(), tz = "UTC", usetz = TRUE), conf_status = receipt_status,
    profile_engine = "tmbprofile", estimate = estimate, lower = lower, upper = upper,
    convergence = as.integer(fit$opt$convergence), pdHess = isTRUE(fit$sdr$pdHess),
    profile_boundary = profile_boundary, clamp_limited = clamp_limited,
    clamp_reason = if (clamp_limited) profile_message else NA_character_,
    trace_complete = trace_complete, failure_reason = failure_reason,
    promotion_eligible = FALSE, promotion_status = "prohibited_no_ledger_promotion",
    runner_sha256 = ordinary_slope_profile_sha256(ordinary_slope_profile_script),
    adapter_sha256 = ordinary_slope_profile_sha256(ordinary_slope_profile_adapter_path()),
    binding_sha256 = ordinary_slope_profile_sha256(contract$registry_path),
    trace_path = normalizePath(paths$trace, mustWork = TRUE),
    interval_path = normalizePath(paths$interval, mustWork = TRUE),
    trace_sha256 = ordinary_slope_profile_sha256(paths$trace),
    interval_sha256 = ordinary_slope_profile_sha256(paths$interval),
      stringsAsFactors = FALSE
    )
    if (!successful_profile) {
      receipt$lower <- NA_real_
      receipt$upper <- NA_real_
    }
    stage <- "receipt_gate"
    ordinary_slope_profile_validate_receipt(receipt, contract)
    stage <- "receipt_write"
    ordinary_slope_profile_atomic_write(receipt, paths$receipt)
    invisible(paths)
  }, error = function(error) {
    ordinary_slope_profile_write_failure_receipt(
      contract, cell_id, seed, rung, paths, stage = stage, error = error
    )
    stop(error)
  })
}

ordinary_slope_profile_runner_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- ordinary_slope_profile_parse_args(args)
  contract <- ordinary_slope_profile_validate_contract(parsed$cell, parsed$rung, parsed$registry %||% NULL)
  if (isTRUE(parsed$dry_run)) {
    message("Lane-B ordinary slope profile gate dry-run validated: ", parsed$cell, " / ", parsed$rung, "; no adapter, fit, profile, or output created.")
    return(invisible(contract))
  }
  ordinary_slope_profile_execute(contract, parsed$cell, parsed$seed, parsed$rung, parsed[["output-dir"]])
}

if (sys.nframe() == 0L) ordinary_slope_profile_runner_main()
