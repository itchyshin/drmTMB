native_sd_stage_two_validate_first_look_manifest <- function(manifest) {
  required <- c("index", "a", "replicate", "seed", "groups", "repeats",
                "beta0", "beta1", "alpha0", "design_mode", "master_seed")
  if (!is.data.frame(manifest) || nrow(manifest) != 3000L ||
      !all(required %in% names(manifest))) {
    stop("First-look manifest has an invalid schema or row count", call. = FALSE)
  }
  index <- suppressWarnings(as.integer(manifest$index))
  truth <- suppressWarnings(as.numeric(manifest$a))
  seed <- suppressWarnings(as.numeric(manifest$seed))
  mode <- unique(as.character(manifest$design_mode))
  master <- suppressWarnings(as.numeric(unique(manifest$master_seed)))
  if (!identical(index, seq_len(3000L)) || length(mode) != 1L ||
      length(master) != 1L || !is.finite(master) || any(!is.finite(truth)) ||
      any(!is.finite(seed)) || any(seed <= 0) || anyDuplicated(seed) ||
      !identical(truth, rep(c(-0.5, 0, 0.5), each = 1000L))) {
    stop("First-look manifest has invalid ordered truth or seed identity", call. = FALSE)
  }
  if (identical(mode, "clean_current")) {
    if (!all(c("look") %in% names(manifest)) || master != 2026101901 ||
        !identical(as.character(manifest$look), rep("look1", 3000L)) ||
        !identical(as.integer(manifest$replicate), rep(seq_len(1000L), 3L)) ||
        any(as.integer(manifest$groups) != 160L) ||
        any(as.integer(manifest$repeats) != 16L) ||
        any(as.numeric(manifest$beta0) != -0.3) ||
        any(as.numeric(manifest$beta1) != 0.6) ||
        any(abs(as.numeric(manifest$alpha0) - (-0.22314355131421)) > 1e-14) ||
        master %in% seed) {
      stop("Clean-current first-look manifest differs from its frozen design", call. = FALSE)
    }
  } else if (identical(mode, "production")) {
    if (master != 2026101703 || "look" %in% names(manifest)) {
      stop("Legacy first-look manifest differs from its frozen design", call. = FALSE)
    }
  } else {
    stop("First-look manifest names an unsupported design mode", call. = FALSE)
  }
  invisible(TRUE)
}

native_sd_stage_two_validate_profile_level <- function(attempts, expected = 0.95,
                                                       tolerance = 1e-12) {
  if (!is.data.frame(attempts) || nrow(attempts) < 1L ||
      !"profile_level" %in% names(attempts)) {
    stop("Profile attempts must record profile_level", call. = FALSE)
  }
  levels <- suppressWarnings(as.numeric(attempts$profile_level))
  if (length(levels) != nrow(attempts) || any(!is.finite(levels)) ||
      !is.numeric(expected) || length(expected) != 1L || !is.finite(expected) ||
      !is.numeric(tolerance) || length(tolerance) != 1L || !is.finite(tolerance) ||
      tolerance < 0 || any(abs(levels - expected) > tolerance)) {
    stop("Profile attempts must all use the required 95% interval level", call. = FALSE)
  }
  invisible(TRUE)
}

native_sd_stage_two_validate_clean_current_batch <- function(manifest, frozen_path,
                                                             batch_id) {
  expected_sha <- "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98"
  if (!requireNamespace("digest", quietly = TRUE) ||
      !is.data.frame(manifest) || length(batch_id) != 1L ||
      is.na(batch_id) || !batch_id %in% 1:3) {
    stop("Clean-current stage-two batch inputs are invalid", call. = FALSE)
  }
  if (!file.exists(frozen_path) ||
      digest::digest(frozen_path, algo = "sha256", file = TRUE) != expected_sha) {
    stop("Frozen clean-current look-two manifest has the wrong SHA-256", call. = FALSE)
  }
  source <- read.csv(frozen_path, stringsAsFactors = FALSE, check.names = FALSE)
  start <- (as.integer(batch_id) - 1L) * 3000L
  if (nrow(source) != 9000L || nrow(manifest) != 3000L ||
      !identical(as.integer(source$index), seq_len(9000L)) ||
      !identical(as.character(source$design_mode), rep("clean_current", 9000L))) {
    stop("Frozen clean-current look-two manifest has an invalid row contract", call. = FALSE)
  }
  expected <- source[start + seq_len(3000L), , drop = FALSE]
  expected$stage_two_index <- expected$index
  expected$source_index <- expected$index
  expected$source_design_mode <- expected$design_mode
  expected$index <- seq_len(3000L)
  expected$batch_id <- as.integer(batch_id)
  expected$design_mode <- "clean_current_stage_two"
  expected_names <- names(expected)
  if (length(names(manifest)) != length(expected_names) ||
      !setequal(names(manifest), expected_names)) {
    stop("Stage-two manifest has an invalid column schema", call. = FALSE)
  }
  expected <- expected[, names(manifest), drop = FALSE]
  if (!identical(names(manifest), names(expected)) ||
      !isTRUE(all.equal(manifest, expected, tolerance = 0,
                        check.attributes = FALSE))) {
    stop("Stage-two manifest differs from its frozen clean-current source mapping",
         call. = FALSE)
  }
  invisible(TRUE)
}

native_sd_stage_two_validate_worker_receipt <- function(receipt, manifest,
                                                        planned_indices) {
  required <- c(
    design_mode = "clean_current_stage_two",
    master_seed = "2026101902",
    profile_level = "0.95",
    planned_attempts = "3000",
    clean_current_seed_stream = "2026101902",
    stage_two_manifest_sha256 =
      "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98"
  )
  observed <- vapply(names(required), function(name) {
    value <- receipt[[name]]
    if (is.null(value) || length(value) != 1L || is.na(value)) "" else
      as.character(value)
  }, character(1L))
  if (!identical(unname(observed), unname(required)) ||
      !is.data.frame(manifest) || nrow(manifest) != 3000L ||
      length(planned_indices) < 1L || anyNA(planned_indices)) {
    stop("Clean-current stage-two receipt differs from the frozen 95% batch contract",
         call. = FALSE)
  }
  batch_id <- suppressWarnings(as.integer(receipt[["stage_two_batch_id"]]))
  if (length(batch_id) != 1L || is.na(batch_id) || !batch_id %in% 1:3 ||
      !"batch_id" %in% names(manifest) ||
      !all(as.integer(manifest$batch_id) == batch_id)) {
    stop("Clean-current stage-two receipt has an invalid batch identity",
         call. = FALSE)
  }

  adapter_flag <- receipt[["adapter_qualification_only"]]
  if (is.null(adapter_flag)) adapter_flag <- "false"
  adapter_flag <- tolower(as.character(adapter_flag))
  if (length(adapter_flag) != 1L || is.na(adapter_flag) ||
      !adapter_flag %in% c("true", "false")) {
    stop("Clean-current stage-two receipt has an invalid adapter-only flag",
         call. = FALSE)
  }
  qualification <- identical(adapter_flag, "true")
  calibration_claim <- tolower(as.character(receipt[["calibration_claim"]]))
  if (qualification) {
    local_index <- suppressWarnings(as.integer(receipt[["qualification_local_index"]]))
    source_index <- suppressWarnings(as.integer(receipt[["qualification_stage_two_index"]]))
    expected_source_index <- (batch_id - 1L) * 3000L + local_index
    expected_replicate <- 1000L + local_index
    if (!identical(calibration_claim, "false") ||
        !identical(as.character(receipt[["stage_two_status"]]),
                   "adapter_qualification_only_no_final_go") ||
        length(local_index) != 1L || is.na(local_index) ||
        length(source_index) != 1L || is.na(source_index) ||
        !identical(as.integer(planned_indices), local_index) ||
        local_index < 1L || local_index > nrow(manifest) ||
        source_index != expected_source_index ||
        as.integer(manifest$stage_two_index[[local_index]]) != source_index ||
        as.integer(manifest$replicate[[local_index]]) != expected_replicate) {
      stop("Adapter qualification receipt does not identify its one frozen probe",
           call. = FALSE)
    }
  } else if (!calibration_claim %in% c("true") ||
             !identical(as.character(receipt[["stage_two_status"]]),
                        "authorized_by_external_go_record") ||
             !identical(as.integer(planned_indices), seq_len(3000L))) {
    stop("Clean-current campaign receipt must cover the full batch and claim calibration",
         call. = FALSE)
  }
  invisible(TRUE)
}

native_sd_stage_two_validate_clean_current_receipt <- function(receipt, manifest,
                                                               receipt_sha256,
                                                               manifest_sha256,
                                                               root_receipt,
                                                               go_record_sha256) {
  batch_id <- unique(as.integer(manifest$batch_id))
  if (length(batch_id) != 1L || is.na(batch_id) || !batch_id %in% 1:3 ||
      !is.list(receipt) || !is.list(root_receipt)) {
    stop("Clean-current conversion receipt inputs are invalid", call. = FALSE)
  }
  root_batches <- as.data.frame(root_receipt$batches, stringsAsFactors = FALSE)
  expected <- root_batches[root_batches$batch_id == batch_id, , drop = FALSE]
  required <- c("batch_id", "source_manifest_sha256", "go_record_sha256",
                "source_row_start", "source_row_end", "local_index_start",
                "local_index_end", "master_seed", "design_mode_source",
                "design_mode_worker", "manifest_sha256", "status")
  if (nrow(expected) != 1L || !"conversion_receipt_sha256" %in% names(expected) ||
      !identical(as.character(expected$conversion_receipt_sha256), receipt_sha256) ||
      !all(required %in% names(receipt))) {
    stop("Clean-current conversion receipt is not bound by the prepared root", call. = FALSE)
  }
  starts <- c(source_row_start = (batch_id - 1L) * 3000L + 1L,
              source_row_end = batch_id * 3000L,
              local_index_start = 1L, local_index_end = 3000L)
  actual <- vapply(names(starts), function(nm) as.integer(receipt[[nm]]), integer(1L))
  if (as.integer(receipt$batch_id) != batch_id ||
      !identical(unname(actual), unname(starts)) ||
      as.character(receipt$source_manifest_sha256) != root_receipt$source_manifest_sha256 ||
      as.character(receipt$go_record_sha256) != go_record_sha256 ||
      as.integer(receipt$master_seed) != 2026101902L ||
      as.character(receipt$design_mode_source) != "clean_current" ||
      as.character(receipt$design_mode_worker) != "clean_current_stage_two" ||
      as.character(receipt$manifest_sha256) != manifest_sha256 ||
      as.character(receipt$status) != "prepared_not_launched") {
    stop("Clean-current conversion receipt fields differ from the frozen batch contract",
         call. = FALSE)
  }
  invisible(TRUE)
}

native_sd_stage_two_attempt_digest <- function(directory, expected_results = NULL,
                                               expected_indices = NULL,
                                               allowed_indices = NULL) {
  candidates <- sort(list.files(directory, pattern = "^result-.*[.]csv$", full.names = TRUE))
  malformed <- candidates[!grepl("^result-[0-9]{4}[.]csv$", basename(candidates))]
  if (length(malformed)) {
    stop("Result filenames must use exactly four digits: ",
         paste(basename(malformed), collapse = ", "), call. = FALSE)
  }
  results <- candidates
  if (!is.null(expected_results) && (!is.null(expected_indices) || !is.null(allowed_indices))) {
    stop("expected_results cannot be combined with index constraints", call. = FALSE)
  }
  if (!is.null(expected_results)) {
    expected_names <- sprintf("result-%04d.csv", seq_len(expected_results))
    if (!identical(basename(results), expected_names)) {
      stop("attempt capsule must contain exactly the expected results 1..", expected_results,
           call. = FALSE)
    }
  }
  if (!is.null(expected_indices)) {
    expected_indices <- as.integer(expected_indices)
    if (anyNA(expected_indices) || any(expected_indices < 1L) || anyDuplicated(expected_indices)) {
      stop("expected completed indices must be unique positive integers", call. = FALSE)
    }
    observed_indices <- as.integer(sub("^result-([0-9]{4})\\.csv$", "\\1", basename(results)))
    if (any(!expected_indices %in% observed_indices)) {
      stop("attempt capsule lacks a result for an expected completed index", call. = FALSE)
    }
  }
  if (!is.null(allowed_indices)) {
    allowed_indices <- as.integer(allowed_indices)
    if (anyNA(allowed_indices) || any(allowed_indices < 1L) || anyDuplicated(allowed_indices)) {
      stop("allowed indices must be unique positive integers", call. = FALSE)
    }
  } else if (!is.null(expected_indices)) {
    allowed_indices <- expected_indices
  }
  if (!is.null(allowed_indices)) {
    observed_indices <- as.integer(sub("^result-([0-9]{4})\\.csv$", "\\1", basename(results)))
    if (any(!observed_indices %in% allowed_indices)) {
      stop("attempt capsule contains a result outside the planned index set", call. = FALSE)
    }
  }
  files <- c(file.path(directory, "manifest.csv"),
             file.path(directory, "supervisor-receipt.json"), results)
  if (any(!file.exists(files[1:2]))) stop("Attempt capsule lacks manifest or supervisor receipt", call. = FALSE)
  hash_file <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
  payload <- paste(vapply(files, function(path) paste0(basename(path), "|", hash_file(path)), character(1L)),
                   collapse = "\n")
  digest::digest(charToRaw(payload), algo = "sha256", serialize = FALSE)
}

native_sd_stage_two_verify_registry <- function(directory, expected_sha256 = NULL) {
  registry <- file.path(directory, "source-hashes.csv")
  if (!file.exists(registry)) stop("Registry is missing", call. = FALSE)
  hash_file <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
  registry_sha <- hash_file(registry)
  if (!is.null(expected_sha256) && !identical(registry_sha, expected_sha256)) {
    stop("External registry seal mismatch", call. = FALSE)
  }
  h <- read.csv(registry, stringsAsFactors = FALSE)
  if (!all(c("path", "sha256") %in% names(h)) || anyDuplicated(h$path)) {
    stop("Invalid registry", call. = FALSE)
  }
  manifest_row <- which(basename(h$path) == "manifest.csv")
  if (length(manifest_row) != 1L) stop("Registry must pin exactly one manifest", call. = FALSE)
  copied_manifest <- file.path(directory, "manifest.csv")
  if (!file.exists(copied_manifest) || hash_file(copied_manifest) != h$sha256[[manifest_row]]) {
    stop("Copied manifest differs from its pinned registry artifact", call. = FALSE)
  }
  for (i in seq_len(nrow(h))) {
    if (!file.exists(h$path[[i]]) || hash_file(h$path[[i]]) != h$sha256[[i]]) {
      stop("Artifact hash mismatch: ", h$path[[i]], call. = FALSE)
    }
  }
  invisible(TRUE)
}

native_sd_stage_two_validate_reconstruction_sources <- function(adapter_directory,
                                                               expected_hashes) {
  expected_hashes <- unlist(expected_hashes, use.names = TRUE)
  source_names <- c("stage_two.py", "reconstruct-first-look.py", "stage-two-rules.R",
                    "verify-first-look.R", "combine-stage-two.R")
  if (is.null(names(expected_hashes)) || !setequal(names(expected_hashes), source_names)) {
    stop("Reconstruction source seal is incomplete", call. = FALSE)
  }
  hash_file <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
  for (name in source_names) {
    path <- file.path(adapter_directory, name)
    if (!file.exists(path) || hash_file(path) != expected_hashes[[name]]) {
      stop("Reconstruction source differs from its seal: ", name, call. = FALSE)
    }
  }
  invisible(TRUE)
}

native_sd_stage_two_batch_id <- function(offset) {
  allowed <- c(3000L, 6000L, 9000L)
  if (length(offset) != 1L || is.na(offset) || !offset %in% allowed) {
    stop("stage-two offset must be 3000, 6000, or 9000", call. = FALSE)
  }
  as.integer(offset %/% 3000L)
}

native_sd_stage_two_registry_for_offset <- function(offset, registry_seals) {
  batch <- native_sd_stage_two_batch_id(offset)
  key <- as.character(batch)
  if (is.null(names(registry_seals)) || !key %in% names(registry_seals) ||
      !nzchar(registry_seals[[key]])) {
    stop("missing distinct external seal for stage-two batch ", batch,
         call. = FALSE)
  }
  unname(registry_seals[[key]])
}

native_sd_stage_two_hash_maps_equal <- function(left, right) {
  left <- unlist(left, recursive = TRUE, use.names = TRUE)
  right <- unlist(right, recursive = TRUE, use.names = TRUE)
  if (length(left) == 0L || length(right) == 0L ||
      is.null(names(left)) || is.null(names(right)) ||
      anyNA(names(left)) || anyNA(names(right)) ||
      any(!nzchar(names(left))) || any(!nzchar(names(right))) ||
      anyDuplicated(names(left)) || anyDuplicated(names(right))) {
    return(FALSE)
  }
  keys <- sort(names(left))
  if (!identical(keys, sort(names(right)))) return(FALSE)
  left <- as.character(left[keys])
  right <- as.character(right[keys])
  !anyNA(left) && !anyNA(right) && all(nzchar(left)) && all(nzchar(right)) &&
    identical(unname(left), unname(right))
}

native_sd_stage_two_metrics_equal <- function(recomputed, saved, tolerance = 1e-12) {
  isTRUE(all.equal(recomputed, saved, tolerance = tolerance,
                   check.attributes = TRUE))
}

native_sd_stage_two_attempts_equal <- function(recomputed, saved, tolerance = 1e-12) {
  keys <- c("look", "attempt_index", "source_index", "valid", "status")
  numeric <- c("truth", "estimate", "lower", "upper", "profile_level")
  if (!is.data.frame(recomputed) || !is.data.frame(saved) ||
      !all(c(keys, numeric) %in% names(recomputed)) ||
      !all(c(keys, numeric) %in% names(saved)) ||
      nrow(recomputed) != nrow(saved)) return(FALSE)
  if (!all(vapply(keys, function(nm) identical(recomputed[[nm]], saved[[nm]]), logical(1L)))) return(FALSE)
  all(vapply(numeric, function(nm) {
    isTRUE(all.equal(recomputed[[nm]], saved[[nm]], tolerance = tolerance,
                     check.attributes = FALSE))
  }, logical(1L)))
}

native_sd_stage_two_deadline_ok <- function(started_epoch, deadline_epoch, now_epoch,
                                            maximum_seconds = 10500) {
  values <- c(started_epoch, deadline_epoch, now_epoch, maximum_seconds)
  length(values) == 4L && all(is.finite(values)) && maximum_seconds > 0 &&
    deadline_epoch > started_epoch && deadline_epoch - started_epoch <= maximum_seconds &&
    now_epoch >= started_epoch && now_epoch < deadline_epoch
}

native_sd_stage_two_completion_result <- function(decision) {
  if (length(decision) == 1L && !is.na(decision) &&
      decision %in% c("accept", "fail", "inconclusive")) {
    return(list(status = 0L,
                marker = paste("STAGE_TWO_COMBINE_COMPLETE", decision)))
  }
  label <- if (length(decision) == 1L && !is.na(decision)) {
    as.character(decision)
  } else {
    "invalid_decision"
  }
  list(status = 2L,
       marker = paste("STAGE_TWO_COMBINE_NONQUALIFYING", label))
}

native_sd_stage_two_emit_completion <- function(decision) {
  result <- native_sd_stage_two_completion_result(decision)
  cat(result$marker, "\n", sep = "")
  if (result$status != 0L) {
    stop("Staged decision is nonqualifying: ", result$marker, call. = FALSE)
  }
  invisible(result$status)
}

native_sd_stage_two_terminal_receipt <- function(receipt) {
  terminal <- c("completed", "error", "timeout")
  cases <- as.data.frame(receipt$cases, stringsAsFactors = FALSE)
  if (!all(c("index", "status", "returncode") %in% names(cases))) return(FALSE)
  isTRUE(receipt$campaign_complete) && isTRUE(receipt$subset_complete) &&
    identical(receipt$interrupted, FALSE) && nrow(cases) == 3000L &&
    !anyDuplicated(as.integer(cases$index)) && setequal(as.integer(cases$index),1:3000) &&
    all(cases$status %in% terminal) &&
    all(cases$returncode[cases$status == "completed"] == 0L) &&
    all(cases$returncode[cases$status %in% c("error", "timeout")] != 0L)
}
