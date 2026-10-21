# Fail-closed R/TMB driver for the approved CMR v7 pre-run and pilot stages.
# Each invocation handles one frozen cell and retains every attempt in JSONL.

CMR_V7_MANIFEST_SHA256 <- "b31d915064cddde3a2bd82202072c7451a453b0fefe8ab84f0bd1f82a3f366f8"

cmr_v7_sha256 <- function(path) {
  if (!file.exists(path)) stop("file does not exist: ", path, call. = FALSE)
  if (nzchar(Sys.which("sha256sum"))) {
    output <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = TRUE)
  } else if (nzchar(Sys.which("shasum"))) {
    output <- system2("shasum", c("-a", "256", shQuote(path)), stdout = TRUE, stderr = TRUE)
  } else {
    stop("SHA-256 verification requires sha256sum or shasum.", call. = FALSE)
  }
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) stop("could not hash ", path, call. = FALSE)
  hash <- strsplit(trimws(output[[1L]]), "[[:space:]]+")[[1L]][[1L]]
  if (!grepl("^[0-9a-f]{64}$", hash)) stop("malformed SHA-256 for ", path, call. = FALSE)
  hash
}

cmr_v7_load_manifest <- function(path) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("jsonlite is required.", call. = FALSE)
  path <- normalizePath(path, mustWork = TRUE)
  digest <- cmr_v7_sha256(path)
  if (!identical(digest, CMR_V7_MANIFEST_SHA256)) {
    stop("CMR v7 manifest hash mismatch; refuse to use an unreviewed design.", call. = FALSE)
  }
  manifest <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  if (!identical(as.integer(manifest$schema_version), 7L)) stop("manifest is not schema v7.", call. = FALSE)
  list(manifest = manifest, path = path, sha256 = digest)
}

cmr_v7_cell <- function(manifest, cell_name) {
  rows <- manifest$primary_cells
  matches <- Filter(function(row) identical(as.character(row$cell), cell_name), rows)
  if (length(matches) != 1L) stop("cell must be a registered primary cell.", call. = FALSE)
  matches[[1L]]
}

cmr_v7_expected_seed <- function(manifest, stage, cell_name, replicate) {
  stages <- manifest$generator$stage_indices
  stage_index <- stages[[stage]]
  cell <- cmr_v7_cell(manifest, cell_name)
  if (is.null(stage_index)) stop("stage is not registered in the frozen generator.", call. = FALSE)
  as.integer(20261007 + 10000000 * as.integer(stage_index) +
    100000 * as.integer(cell$index) + as.integer(replicate))
}

cmr_v7_plan <- function(manifest, stage, cell_name, replicates = NULL) {
  if (!stage %in% c("pre_run", "pilot")) {
    stop("this runner admits only pre_run and pilot; screen/qualification use the reviewed paired gate.",
         call. = FALSE)
  }
  cell <- cmr_v7_cell(manifest, cell_name)
  if (stage == "pre_run") {
    maximum <- as.integer(manifest$stages$pre_run$replicates)
    allowed <- seq_len(maximum)
  } else {
    admission <- manifest$pilot_admission
    if (!cell_name %in% unlist(admission$cells, use.names = FALSE) ||
        !identical(as.character(admission$stage), "pilot") ||
        !identical(as.integer(admission$manifest_version), 7L)) {
      stop("pilot cell is outside the frozen v7 admission.", call. = FALSE)
    }
    allowed <- seq.int(as.integer(admission$replicate_range[[1L]]),
                       as.integer(admission$replicate_range[[2L]]))
  }
  if (is.null(replicates)) return(allowed)
  if (!is.numeric(replicates) || !length(replicates) || anyNA(replicates) ||
      any(!is.finite(replicates)) || any(replicates != as.integer(replicates)) ||
      anyDuplicated(replicates) || !all(as.integer(replicates) %in% allowed)) {
    stop("requested replicates exceed the authorized range.", call. = FALSE)
  }
  as.integer(replicates)
}

cmr_v7_validate_source_manifest <- function(root, manifest_path) {
  root <- normalizePath(root, mustWork = TRUE)
  pins <- jsonlite::fromJSON(manifest_path, simplifyVector = TRUE)
  if ((!is.character(pins) && !is.list(pins)) || !length(pins) || is.null(names(pins)) ||
      any(!vapply(pins, function(value) is.character(value) && length(value) == 1L, logical(1)))) {
    stop("source manifest must be a nonempty path-to-SHA256 object.", call. = FALSE)
  }
  mismatches <- character()
  for (relative in names(pins)) {
    path <- normalizePath(file.path(root, relative), mustWork = FALSE)
    root_prefix <- paste0(root, .Platform$file.sep)
    if (grepl("^(?:/|[A-Za-z]:[/\\\\]|\\\\\\\\)", relative, perl = TRUE) ||
        !startsWith(path, root_prefix)) {
      stop("source manifest path escapes source root: ", relative, call. = FALSE)
    }
    if (!file.exists(path)) {
      mismatches <- c(mismatches, paste0("missing:", relative))
    } else if (!identical(cmr_v7_sha256(path), as.character(pins[[relative]]))) {
      mismatches <- c(mismatches, paste0("hash:", relative))
    }
  }
  if (length(mismatches)) stop("source manifest mismatch: ", paste(mismatches, collapse = ", "), call. = FALSE)
  list(root = root, sha256 = cmr_v7_sha256(manifest_path), files = length(pins))
}

cmr_v7_runtime_identity <- function(source_manifest_sha256, package_library) {
  suppressPackageStartupMessages(library(drmTMB, lib.loc = package_library, character.only = FALSE))
  dll <- getLoadedDLLs()[["drmTMB"]][["path"]]
  list(package = "drmTMB", package_version = as.character(utils::packageVersion("drmTMB")),
       runtime = "R", runtime_version = R.version.string,
       source_manifest_sha256 = source_manifest_sha256,
       dll_sha256 = cmr_v7_sha256(dll), package_path = normalizePath(find.package("drmTMB")),
       dll_path = normalizePath(dll), r_libs_user = Sys.getenv("R_LIBS_USER"),
       worker_threads = "1", thread_environment = paste0(
         "OPENBLAS=", Sys.getenv("OPENBLAS_NUM_THREADS"), ";OMP=", Sys.getenv("OMP_NUM_THREADS"),
         ";MKL=", Sys.getenv("MKL_NUM_THREADS"), ";JULIA=", Sys.getenv("JULIA_NUM_THREADS")))
}

cmr_v7_write_jsonl <- function(path, value) {
  line <- jsonlite::toJSON(value, auto_unbox = TRUE, null = "null", na = "null", digits = 17)
  cat(as.character(line), "\n", file = path, append = TRUE)
  invisible(NULL)
}

cmr_v7_run_cell <- function(manifest_path, source_root, source_manifest_path,
                            generator_path, package_library, stage, cell_name,
                            output_dir, replicates = NULL, attempt_fn = NULL,
                            python = Sys.which("python3")) {
  loaded <- cmr_v7_load_manifest(manifest_path)
  manifest <- loaded$manifest
  reps <- cmr_v7_plan(manifest, stage, cell_name, replicates)
  source_identity <- cmr_v7_validate_source_manifest(source_root, source_manifest_path)
  if (dir.exists(output_dir) || file.exists(output_dir)) {
    stop("output directory already exists; refusing to reuse campaign output.", call. = FALSE)
  }
  if (!dir.create(output_dir, recursive = TRUE)) stop("could not create output directory.", call. = FALSE)
  cell <- cmr_v7_cell(manifest, cell_name)
  if (!is.null(cell$sd_phi) || !is.null(cell$sd_p)) {
    extractor_path <- file.path(source_root, "tools", "cmr_sd_recovery_extract.R")
    if (!file.exists(extractor_path)) {
      stop("SD recovery needs tools/cmr_sd_recovery_extract.R in the pinned source bundle.",
           call. = FALSE)
    }
    source(extractor_path, local = TRUE)
  }
  if (is.null(attempt_fn)) {
    source(file.path(source_root, "tools", "cmr_recovery_adapter.R"), local = TRUE)
    attempt_fn <- function(directory, cell, seed, stage, replicate) {
      cmr_recovery_attempt_from_generator(generator_path, directory, cell,
        manifest$common_design, seed = seed, stage = stage, replicate = replicate,
        python = python, manifest = loaded$path)
    }
  }
  identity <- cmr_v7_runtime_identity(source_identity$sha256, package_library)
  cmr_v7_write_jsonl(file.path(output_dir, "attempts.jsonl"), list(
    event = "runtime", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), identity = identity,
    manifest_sha256 = loaded$sha256, source_file_count = source_identity$files))
  attempts <- vector("list", length(reps))
  for (i in seq_along(reps)) {
    replicate <- reps[[i]]
    seed <- cmr_v7_expected_seed(manifest, stage, cell_name, replicate)
    dataset_dir <- file.path(output_dir, sprintf("dataset-%04d", replicate))
    started <- format(Sys.time(), tz = "UTC", usetz = TRUE)
    attempt <- tryCatch(attempt_fn(dataset_dir, cell, seed, stage, replicate),
      error = function(condition) condition)
    if (inherits(attempt, "error")) {
      row <- list(language = "R", stage = stage, cell = cell_name, route = cell$route,
        replicate = replicate, seed = seed, manifest_sha256 = loaded$sha256,
        status = "error", usable = FALSE, fit_attempted = FALSE,
        failure_stage = "pre_fit_admission", failure_code = "runner_or_generation_error",
        failure_message = conditionMessage(attempt), started_utc = started,
        ended_utc = format(Sys.time(), tz = "UTC", usetz = TRUE), elapsed_seconds = 0)
    } else {
      metadata <- attempt$generator_metadata
      row <- list(language = "R", stage = stage, cell = cell_name, route = cell$route,
        replicate = replicate, seed = seed, manifest_sha256 = loaded$sha256,
        generated_sha256 = metadata$sha256, generator_rows = metadata$rows,
        status = attempt$status, usable = isTRUE(attempt$usable),
        fit_attempted = isTRUE(attempt$fit_attempted), converged = attempt$converged,
        gradient_norm = attempt$gradient_norm, inner_mode_status = attempt$inner_mode_status,
        hessian_status = attempt$hessian_status, quadrature_order = attempt$quadrature_order,
        refinement_status = attempt$refinement_status, boundary_status = attempt$boundary_status,
        interval_status = attempt$interval_status, loglik = attempt$loglik,
        estimates = attempt$estimates, failure_stage = attempt$failure_stage,
        failure_code = attempt$failure_code, failure_message = attempt$failure_message,
        started_utc = attempt$started_utc, ended_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
        elapsed_seconds = attempt$elapsed_seconds)
    }
    attempts[[i]] <- row
    cmr_v7_write_jsonl(file.path(output_dir, "attempts.jsonl"), row)
  }
  summary <- list(schema_version = 1L, stage = stage, cell = cell_name,
    manifest_sha256 = loaded$sha256, source_manifest_sha256 = source_identity$sha256,
    runtime_identity = identity, scheduled = length(reps),
    attempted = sum(vapply(attempts, function(x) isTRUE(x$fit_attempted), logical(1))),
    usable = sum(vapply(attempts, function(x) isTRUE(x$usable), logical(1))),
    failures = sum(vapply(attempts, function(x) !isTRUE(x$usable), logical(1))),
    intervals_requested = FALSE, qualification = FALSE, attempts = attempts)
  writeLines(as.character(jsonlite::toJSON(summary, auto_unbox = TRUE, null = "null",
    na = "null", digits = 17, pretty = TRUE)), file.path(output_dir, "summary.json"))
  invisible(summary)
}

cmr_v7_parse_args <- function(args) {
  if (length(args) %% 2L != 0L) stop("arguments must be --key value pairs.", call. = FALSE)
  keys <- args[seq.int(1L, length(args), by = 2L)]
  values <- args[seq.int(2L, length(args), by = 2L)]
  if (any(!grepl("^--[a-z-]+$", keys)) || anyDuplicated(keys)) stop("invalid or duplicate option.", call. = FALSE)
  stats::setNames(as.list(values), sub("^--", "", keys))
}

cmr_v7_cli <- function(args = commandArgs(trailingOnly = TRUE)) {
  opts <- cmr_v7_parse_args(args)
  required <- c("manifest", "source-root", "source-manifest", "generator", "library",
                "stage", "cell", "output")
  if (!all(required %in% names(opts))) stop("missing required options: ",
    paste(setdiff(required, names(opts)), collapse = ", "), call. = FALSE)
  reps <- if (is.null(opts$replicates)) NULL else as.integer(strsplit(opts$replicates, ",", fixed = TRUE)[[1L]])
  cmr_v7_run_cell(opts$manifest, opts$`source-root`, opts$`source-manifest`, opts$generator,
    opts$library, opts$stage, opts$cell, opts$output, reps)
}

if (sys.nframe() == 0L) cmr_v7_cli()
