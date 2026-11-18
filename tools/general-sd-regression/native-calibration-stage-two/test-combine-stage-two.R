# No-fit regression test: the retained first-look fixture contains legacy
# 95% profile intervals and must not authorize a look-two combination under
# the frozen 95% fitted-profile protocol. This is integrity evidence, not calibration.

stopifnot(requireNamespace("digest", quietly = TRUE),
          requireNamespace("jsonlite", quietly = TRUE))
args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
stopifnot(length(script_arg) == 1L)
adapter <- normalizePath(dirname(sub("^--file=", "", script_arg)), mustWork = TRUE)
repo <- normalizePath(file.path(adapter, "../../.."), mustWork = TRUE)
evidence <- file.path(repo, "docs/dev-log/general-sd-regression/evidence/calibration-20261017")
first_fixture <- file.path(evidence, "first-look-v4")
source_manifest <- file.path(repo, "docs/dev-log/general-sd-regression/stage-two-manifest.csv")
stopifnot(file.exists(source_manifest),
          identical(digest::digest(source_manifest, algo = "sha256", file = TRUE),
            "8fd627ccb8a7f8689c56e629a5ff12e53405be1a508167216632bcf445652e96"))

tmp <- tempfile("combine-stage-two-subprocess-")
dir.create(tmp)
on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
root <- file.path(tmp, "prepared")
dir.create(root)
first <- file.path(tmp, "first-look")
dir.create(first)
batches <- file.path(root, paste0("batch-", 1:3))
invisible(lapply(batches, dir.create))
out <- file.path(tmp, "combined")
hash_file <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
write_json <- function(x, path) writeLines(jsonlite::toJSON(x, auto_unbox = TRUE,
  pretty = TRUE, null = "null", digits = NA), path)
source(file.path(adapter, "stage-two-rules.R"))
combine_source <- paste(readLines(file.path(adapter, "combine-stage-two.R"), warn = FALSE),
                        collapse = "\n")
stopifnot(grepl("native_sd_stage_two_validate_profile_level(rr, expected = 0.95)",
                combine_source, fixed = TRUE))

# Clean-current stage-two rows are transformed from the frozen 9,000-row
# look-two source. Exercise the exact production identity mapper without
# launching workers or fitting models.
combine_expressions <- parse(file.path(adapter, "combine-stage-two.R"))
identity_expr <- Filter(function(expr) is.call(expr) &&
  identical(expr[[1L]], as.name("<-")) &&
  identical(expr[[2L]], as.name("native_sd_stage_two_preserve_source_identity")),
  as.list(combine_expressions))
stopifnot(length(identity_expr) == 1L)
eval(identity_expr[[1L]], envir = environment())
clean_source <- file.path(repo,
  "docs/dev-log/general-sd-regression/evidence/calibration-20261019/clean-current-seed-design-v1/look2.csv")
stopifnot(file.exists(clean_source),
  identical(hash_file(clean_source),
    "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98"))
clean_rows <- read.csv(clean_source, stringsAsFactors = FALSE, check.names = FALSE)
for (batch_id in 1:3) {
  source_idx <- ((batch_id - 1L) * 3000L + 1L):(batch_id * 3000L)
  m <- clean_rows[source_idx, , drop = FALSE]
  m$stage_two_index <- m$index
  m$source_index <- m$index
  m$source_design_mode <- m$design_mode
  m$index <- seq_len(3000L)
  m$batch_id <- batch_id
  m$design_mode <- "clean_current_stage_two"
  attempts <- data.frame(look = 2L,
    attempt_index = batch_id * 3000L + seq_len(3000L),
    source_index = m$stage_two_index, truth = m$a, estimate = NA_real_,
    lower = NA_real_, upper = NA_real_, profile_level = NA_real_,
    valid = FALSE, status = "error")
  mapped <- native_sd_stage_two_preserve_source_identity(
    attempts, m, clean_source, batch_id)
  stopifnot(nrow(mapped) == 3000L,
    identical(as.integer(mapped$source_index), as.integer(source_idx)),
    identical(as.integer(mapped$stage_two_index), as.integer(source_idx)),
    identical(as.character(mapped$source_design_mode), rep("clean_current", 3000L)),
    identical(as.character(mapped$source_manifest_sha256),
      rep(hash_file(clean_source), 3000L)))
}
receipt_batch <- 2L
receipt_source_rows <- clean_rows[3001:6000, , drop = FALSE]
receipt_manifest <- receipt_source_rows
receipt_manifest$stage_two_index <- receipt_manifest$index
receipt_manifest$source_index <- receipt_manifest$index
receipt_manifest$source_design_mode <- receipt_manifest$design_mode
receipt_manifest$index <- seq_len(3000L)
receipt_manifest$batch_id <- receipt_batch
receipt_manifest$design_mode <- "clean_current_stage_two"
conversion <- list(batch_id = receipt_batch,
  source_manifest_sha256 = hash_file(clean_source), go_record_sha256 = "test-go-sha",
  source_row_start = 3001L, source_row_end = 6000L,
  local_index_start = 1L, local_index_end = 3000L,
  master_seed = 2026101902L, design_mode_source = "clean_current",
  design_mode_worker = "clean_current_stage_two", manifest_sha256 = "test-manifest-sha",
  status = "prepared_not_launched")
conversion_path <- file.path(tmp, "clean-current-conversion-receipt.json")
write_json(conversion, conversion_path)
root_for_conversion <- list(source_manifest_sha256 = hash_file(clean_source),
  batches = data.frame(batch_id = receipt_batch,
    conversion_receipt_sha256 = hash_file(conversion_path)))
stopifnot(isTRUE(native_sd_stage_two_validate_clean_current_receipt(
  conversion, receipt_manifest, hash_file(conversion_path), "test-manifest-sha",
  root_for_conversion, "test-go-sha")))
bad_conversion <- conversion
bad_conversion$source_row_end <- 6001L
bad <- try(native_sd_stage_two_validate_clean_current_receipt(
  bad_conversion, receipt_manifest, hash_file(conversion_path), "test-manifest-sha",
  root_for_conversion, "test-go-sha"), silent = TRUE)
stopifnot(inherits(bad, "try-error"))

# Run the production combiner's batch reader over all three sealed clean-current
# batches. Their attempts are terminal errors, so no model is fitted.
clean_batch_paths <- vector("list", 3L)
clean_registry_shas <- clean_attempt_shas <- stats::setNames(vector("list", 3L),
  as.character(1:3))
clean_batch_receipts <- vector("list", 3L)
for (batch_id in 1:3) {
  clean_batch <- file.path(tmp, paste0("clean-current-batch-", batch_id))
  dir.create(clean_batch)
  clean_batch_paths[[batch_id]] <- clean_batch
  source_idx <- ((batch_id - 1L) * 3000L + 1L):(batch_id * 3000L)
  m <- clean_rows[source_idx, , drop = FALSE]
  m$stage_two_index <- m$index
  m$source_index <- m$index
  m$source_design_mode <- m$design_mode
  m$index <- seq_len(3000L)
  m$batch_id <- batch_id
  m$design_mode <- "clean_current_stage_two"
  clean_manifest_path <- file.path(clean_batch, "manifest.csv")
  write.csv(m, clean_manifest_path, row.names = FALSE)
  conversion <- list(batch_id = batch_id,
    source_manifest_sha256 = hash_file(clean_source), go_record_sha256 = "test-go-sha",
    source_row_start = min(source_idx), source_row_end = max(source_idx),
    local_index_start = 1L, local_index_end = 3000L, master_seed = 2026101902L,
    design_mode_source = "clean_current", design_mode_worker = "clean_current_stage_two",
    manifest_sha256 = hash_file(clean_manifest_path), status = "prepared_not_launched")
  clean_conversion_path <- file.path(clean_batch, "conversion-receipt.json")
  write_json(conversion, clean_conversion_path)
  clean_registry_path <- file.path(clean_batch, "source-hashes.csv")
  clean_registry <- data.frame(path = c(clean_manifest_path, clean_source,
    clean_conversion_path), sha256 = vapply(c(clean_manifest_path, clean_source,
    clean_conversion_path), hash_file, character(1L)))
  write.csv(clean_registry, clean_registry_path, row.names = FALSE)
  clean_registry_sha <- hash_file(clean_registry_path)
  clean_registry_shas[[as.character(batch_id)]] <- clean_registry_sha
  clean_cases <- data.frame(index = 1:3000, status = "error", returncode = 1L)
  clean_sup <- list(registry_sha256 = clean_registry_sha,
    manifest_sha256 = hash_file(clean_manifest_path), planned_indices = as.list(1:3000),
    campaign_complete = TRUE, interrupted = FALSE, subset_complete = TRUE,
    cases = clean_cases)
  write_json(clean_sup, file.path(clean_batch, "supervisor-receipt.json"))
  clean_attempt_sha <- native_sd_stage_two_attempt_digest(clean_batch,
    expected_indices = integer(), allowed_indices = 1:3000)
  clean_attempt_shas[[as.character(batch_id)]] <- clean_attempt_sha
  clean_batch_receipts[[batch_id]] <- list(batch_id = batch_id,
    conversion_receipt_sha256 = hash_file(clean_conversion_path))
}
root_for_conversion <- list(source_manifest_sha256 = hash_file(clean_source),
  batches = do.call(rbind, lapply(clean_batch_receipts, as.data.frame)))
combiner_env <- new.env(parent = environment())
combiner_env$hash_file <- hash_file
combiner_env$verify_registry <- native_sd_stage_two_verify_registry
combiner_env$attempt_digest <- native_sd_stage_two_attempt_digest
combiner_env$root_receipt <- root_for_conversion
combiner_env$seals <- list(go_record_sha256 = "test-go-sha",
  batch_registry_sha256 = clean_registry_shas,
  batch_attempt_sha256 = clean_attempt_shas)
read_attempts_expr <- Filter(function(expr) is.call(expr) &&
  identical(expr[[1L]], as.name("<-")) &&
  identical(expr[[2L]], as.name("read_attempts")), as.list(combine_expressions))
stopifnot(length(read_attempts_expr) == 1L)
read_attempts_fn <- eval(read_attempts_expr[[1L]], envir = combiner_env)
for (batch_id in 1:3) {
  source_idx <- ((batch_id - 1L) * 3000L + 1L):(batch_id * 3000L)
  combined_clean <- read_attempts_fn(clean_batch_paths[[batch_id]], offset = batch_id * 3000L)
  stopifnot(nrow(combined_clean) == 3000L,
    identical(as.integer(combined_clean$source_index), as.integer(source_idx)),
    identical(as.integer(combined_clean$stage_two_index), as.integer(source_idx)),
    identical(as.character(combined_clean$source_design_mode), rep("clean_current", 3000L)),
    identical(as.character(combined_clean$source_manifest_sha256),
      rep(hash_file(clean_source), 3000L)))
}

# Build a self-contained legacy-shaped first-look capsule. The result rows are
# metadata-only test stubs that intentionally omit profile_level; they are not
# calibration attempts. Stage-two attempts are synthetic terminal errors, so
# no model fits occur.
invisible(file.symlink(file.path(first_fixture, "manifest.csv"), file.path(first, "manifest.csv")))
first_manifest <- read.csv(file.path(first_fixture, "manifest.csv"),
  stringsAsFactors = FALSE)
for (i in seq_len(3000L)) {
  row <- first_manifest[i, , drop = FALSE]
  legacy_result <- data.frame(
    index = row$index, a = row$a, replicate = row$replicate, seed = row$seed,
    state = "completed", calibration_claim = TRUE,
    estimate = row$a, se = 0.1, convergence = 0L, pdHess = TRUE,
    max_abs_gradient = 0, clamp_at_optimum = "ok",
    lower = row$a - 0.2, upper = row$a + 0.2,
    interval_status = "profile", profile_boundary = FALSE,
    profile_message = "", valid_interval = TRUE,
    laplace_oracle_error = 0, oracle_pass = TRUE, oracle_tolerance = 1e-6,
    warnings = "", error = "", elapsed = 1,
    stringsAsFactors = FALSE
  )
  write.csv(legacy_result,
    file.path(first, sprintf("result-%04d.csv", i)), row.names = FALSE)
}
result_files <- list.files(first, pattern = "^result-[0-9]{4}\\.csv$",
  full.names = TRUE)
stopifnot(length(result_files) == 3000L, all(file.exists(result_files)))
invisible(file.symlink(file.path(first_fixture, "staged-decision.rds"),
  file.path(first, "staged-decision.rds")))
invisible(file.symlink(file.path(first_fixture, "totoro-standardized.csv"),
  file.path(root, "first-look-standardized.csv")))
invisible(file.symlink(file.path(first_fixture, "staged-decision.rds"),
  file.path(tmp, "first-decision.rds")))
first_decision_path <- file.path(tmp, "first-look-decision.txt")
writeLines("look2_required", first_decision_path)

first_registry_path <- file.path(first, "source-hashes.csv")
# Registry validation pins the copied manifest and every listed source; the
# complete result set is independently pinned by the attempt digest.
first_registry <- data.frame(path = file.path(first, "manifest.csv"),
  sha256 = hash_file(file.path(first, "manifest.csv")))
write.csv(first_registry, first_registry_path, row.names = FALSE)
first_registry_hash <- hash_file(first_registry_path)
first_sup <- list(registry_sha256 = first_registry_hash,
  manifest_sha256 = hash_file(file.path(first, "manifest.csv")),
  planned_indices = as.list(1:3000), campaign_complete = TRUE,
  interrupted = FALSE, subset_complete = TRUE,
  cases = data.frame(index = 1:3000, status = "completed", returncode = 0L))
write_json(first_sup, file.path(first, "supervisor-receipt.json"))
first_attempt_hash <- native_sd_stage_two_attempt_digest(first, expected_results = 3000L)

source_rows <- read.csv(source_manifest, stringsAsFactors = FALSE)
manifest_copy <- file.path(tmp, "stage-two-manifest.csv")
invisible(file.copy(source_manifest, manifest_copy))
batch_registry <- stats::setNames(vector("list", 3L), as.character(1:3))
batch_attempts <- stats::setNames(vector("list", 3L), as.character(1:3))
for (i in 1:3) {
  d <- batches[[i]]
  idx <- ((i - 1L) * 3000L + 1L):(i * 3000L)
  src <- source_rows[idx, , drop = FALSE]
  m <- src
  m$stage_two_index <- src$index
  m$batch_id <- i
  m$index <- 1:3000
  m$master_seed <- 2026101705L
  m$design_mode <- "production"
  write.csv(m, file.path(d, "manifest.csv"), row.names = FALSE)
  reg <- data.frame(path = c(file.path(d, "manifest.csv"), manifest_copy),
    sha256 = c(hash_file(file.path(d, "manifest.csv")), hash_file(manifest_copy)))
  write.csv(reg, file.path(d, "source-hashes.csv"), row.names = FALSE)
  batch_registry[[as.character(i)]] <- hash_file(file.path(d, "source-hashes.csv"))
  write_json(list(registry_sha256 = batch_registry[[as.character(i)]],
    manifest_sha256 = hash_file(file.path(d, "manifest.csv")),
    planned_indices = as.list(1:3000), campaign_complete = TRUE,
    interrupted = FALSE, subset_complete = TRUE,
    cases = data.frame(index = 1:3000, status = "error", returncode = 1L)),
    file.path(d, "supervisor-receipt.json"))
  batch_attempts[[as.character(i)]] <- native_sd_stage_two_attempt_digest(
    d, expected_indices = integer(), allowed_indices = 1:3000)
}

go_path <- file.path(tmp, "go-record.json")
now <- as.numeric(Sys.time())
run_path <- file.path(root, "stage-two-run-receipt.json")
auth_hash <- "test-only-authorization-seal"
go <- list(decision = "look2_required",
  first_look_registry_sha256 = first_registry_hash,
  first_look_decision_sha256 = hash_file(first_decision_path))
write_json(go, go_path)
for (i in 1:3) {
  idx <- ((i - 1L) * 3000L + 1L):(i * 3000L)
  write_json(list(batch_id = i, source_row_start = min(idx), source_row_end = max(idx),
    manifest_sha256 = hash_file(file.path(batches[[i]], "manifest.csv")),
    go_record_sha256 = hash_file(go_path)),
    file.path(batches[[i]], "conversion-receipt.json"))
}
run <- list(status = "all_batches_terminal", no_retries = TRUE,
  started_epoch = now - 1, deadline_epoch = now + 10000,
  external_seals_sha256 = auth_hash, go_record_sha256 = hash_file(go_path),
  batches = data.frame(batch_id = 1:3,
    attempts_sha256 = unname(unlist(batch_attempts))))
write_json(run, run_path)

root_receipt_path <- file.path(root, "root-preparation-receipt.json")
replay_receipt_path <- file.path(root, "first-look-replay-receipt.json")
writeLines("test-only replay receipt", replay_receipt_path)
root_receipt <- list(status = "prepared_not_launched", no_fits_launched = TRUE,
  first_look_seal_sha256 = "test-only-first-look-seal",
  first_look_standardized_sha256 = hash_file(file.path(root, "first-look-standardized.csv")),
  first_look_replay_receipt_sha256 = hash_file(replay_receipt_path),
  go_record_sha256 = hash_file(go_path), harness_archive_sha256 = "test-only-harness",
  first_look_registry_sha256 = first_registry_hash,
  first_look_decision_sha256 = hash_file(first_decision_path),
  batches = data.frame(batch_id = 1:3,
    registry_sha256 = unname(unlist(batch_registry))))
write_json(root_receipt, root_receipt_path)

# The analyzer path and reconstruction sources are externally hash-sealed.
staged <- file.path(tmp, "staged-analyzer.R")
writeLines(c(
  "native_sd_staged_decision <- function(attempts, manifest_count, look, completed_campaign) {",
  "  if (look == 1L) return(readRDS(Sys.getenv('TEST_FIRST_DECISION_RDS'))) ",
  "  list(decision = 'integrity_failure', reason = 'test-only injected impossible state', metrics = data.frame(), gates = data.frame(), status_counts = data.frame())",
  "}"
), staged)
source_names <- c("stage_two.py", "reconstruct-first-look.py", "stage-two-rules.R",
  "verify-first-look.R", "combine-stage-two.R")
source_hashes <- stats::setNames(vapply(source_names, function(nm)
  hash_file(file.path(adapter, nm)), character(1L)), source_names)
seals <- list(staged_decision_path = staged, staged_decision_sha256 = hash_file(staged),
  adapter_rules_path = file.path(adapter, "stage-two-rules.R"),
  adapter_rules_sha256 = hash_file(file.path(adapter, "stage-two-rules.R")),
  first_look_reconstruction_source_sha256 = as.list(source_hashes),
  first_look_registry_sha256 = first_registry_hash,
  first_look_attempts_sha256 = first_attempt_hash,
  root_preparation_receipt_sha256 = hash_file(root_receipt_path),
  first_look_seal_sha256 = root_receipt$first_look_seal_sha256,
  go_record_sha256 = hash_file(go_path), harness_archive_sha256 = root_receipt$harness_archive_sha256,
  first_look_decision_sha256 = hash_file(first_decision_path),
  batch_registry_sha256 = batch_registry,
  stage_two_run_receipt_sha256 = hash_file(run_path),
  run_authorization_seals_sha256 = auth_hash,
  batch_attempt_sha256 = batch_attempts,
  first_look_decision_path = first_decision_path, go_record_path = go_path)
seals_path <- file.path(tmp, "external-seals.json")
write_json(seals, seals_path)

# The retained first-look fixture uses the 95% profile worker but its result
# rows lack explicit profile_level metadata. Current replay must reject it
# before creating any look-two decision or output.
script <- file.path(adapter, "combine-stage-two.R")
rs <- file.path(R.home("bin"), "Rscript")
cmd <- system2(rs, shQuote(c(script, first, batches, seals_path, hash_file(seals_path), out)),
  env = paste0("TEST_FIRST_DECISION_RDS=", file.path(tmp, "first-decision.rds")),
  stdout = TRUE, stderr = TRUE)
status <- attr(cmd, "status")
if (is.null(status)) status <- 0L
receipt_path <- file.path(out, "decision-receipt.json")
receipt <- if (file.exists(receipt_path)) jsonlite::fromJSON(receipt_path) else NULL
checks <- c(status != 0L,
  any(grepl("Profile attempts must record profile_level", cmd, fixed = TRUE)),
  !dir.exists(out), is.null(receipt))
if (!all(checks)) stop("Subprocess assertions failed (status=", status,
  "; output=", paste(cmd, collapse = " | "), ")")
cat("STAGE_TWO_LEGACY_REPLAY_REJECT_PASS no_fits=TRUE status=", status, "\n", sep = "")

# Positive no-fit CLI integration for clean-current batches. The first look is
# synthetic and all second-look worker cases are terminal errors, so the real
# combiner validates the complete seals and source mapping without fitting.
positive_root <- file.path(tmp, "positive-prepared")
dir.create(positive_root)
positive_first <- file.path(tmp, "positive-first-look")
dir.create(positive_first)
positive_out <- file.path(tmp, "positive-combined")
positive_decision_path <- file.path(tmp, "positive-first-look-decision.txt")
writeLines("look2_required", positive_decision_path)
first_a <- rep(c(-0.5, 0, 0.5), each = 1000L)
first_manifest_positive <- data.frame(index = 1:3000, a = first_a,
  replicate = 1001:4000, seed = 700000L + 1:3000,
  master_seed = 2026101703L, design_mode = "production")
write.csv(first_manifest_positive, file.path(positive_first, "manifest.csv"),
  row.names = FALSE)
positive_result <- data.frame(index = 1:3000,
  seed = first_manifest_positive$seed, a = first_manifest_positive$a,
  replicate = first_manifest_positive$replicate, state = "completed",
  estimate = 0, se = 1, convergence = 1L, pdHess = FALSE,
  max_abs_gradient = NA_real_, clamp_at_optimum = "not_available",
  lower = -1, upper = 1, profile_level = 0.95,
  interval_status = "profile", profile_boundary = FALSE,
  valid_interval = FALSE, laplace_oracle_error = NA_real_,
  oracle_pass = FALSE, error = "")
for (i in 1:3000) {
  write.csv(positive_result[i, , drop = FALSE],
    file.path(positive_first, sprintf("result-%04d.csv", i)), row.names = FALSE)
}
positive_first_sup <- list(registry_sha256 = "pending",
  manifest_sha256 = hash_file(file.path(positive_first, "manifest.csv")),
  planned_indices = as.list(1:3000), campaign_complete = TRUE,
  interrupted = FALSE, subset_complete = TRUE,
  cases = data.frame(index = 1:3000, status = "completed", returncode = 0L))
write_json(positive_first_sup,
  file.path(positive_first, "supervisor-receipt.json"))
positive_first_registry <- data.frame(
  path = c(file.path(positive_first, "manifest.csv"), clean_source),
  sha256 = c(hash_file(file.path(positive_first, "manifest.csv")), hash_file(clean_source)))
write.csv(positive_first_registry, file.path(positive_first, "source-hashes.csv"),
  row.names = FALSE)
positive_first_registry_sha <- hash_file(file.path(positive_first, "source-hashes.csv"))
positive_first_sup$registry_sha256 <- positive_first_registry_sha
write_json(positive_first_sup,
  file.path(positive_first, "supervisor-receipt.json"))
positive_first_attempts_sha <- native_sd_stage_two_attempt_digest(
  positive_first, expected_results = 3000L)
positive_first_standardized <- data.frame(look = 1L, attempt_index = 1:3000,
  source_index = 1:3000, truth = first_a, estimate = 0, lower = -1, upper = 1,
  profile_level = 0.95, valid = FALSE, status = "completed")
write.csv(positive_first_standardized,
  file.path(positive_root, "first-look-standardized.csv"), row.names = FALSE)
writeLines("synthetic replay receipt\n",
  file.path(positive_root, "first-look-replay-receipt.json"))
positive_first_seal_path <- file.path(tmp, "positive-first-look-seal.json")
write_json(list(registry_sha256 = positive_first_registry_sha,
  decision_sha256 = hash_file(positive_decision_path),
  attempts_sha256 = positive_first_attempts_sha,
  harness_archive_sha256 = "harness-synthetic",
  matched_original_native_artifacts = list("synthetic-runtime")),
  positive_first_seal_path)
positive_go_path <- file.path(tmp, "positive-go.json")
write_json(list(decision = "look2_required",
  first_look_registry_sha256 = positive_first_registry_sha,
  first_look_decision_sha256 = hash_file(positive_decision_path)), positive_go_path)
positive_go_sha <- hash_file(positive_go_path)

positive_batch_registry <- positive_batch_attempts <- stats::setNames(
  vector("list", 3L), as.character(1:3))
positive_batch_root_receipts <- vector("list", 3L)
for (batch_id in 1:3) {
  d <- file.path(positive_root, paste0("batch-", batch_id))
  dir.create(d)
  source_idx <- ((batch_id - 1L) * 3000L + 1L):(batch_id * 3000L)
  m <- clean_rows[source_idx, , drop = FALSE]
  m$stage_two_index <- m$index
  m$source_index <- m$index
  m$source_design_mode <- m$design_mode
  m$index <- seq_len(3000L)
  m$batch_id <- batch_id
  m$design_mode <- "clean_current_stage_two"
  write.csv(m, file.path(d, "manifest.csv"), row.names = FALSE)
  conversion <- list(batch_id = batch_id,
    source_manifest_sha256 = hash_file(clean_source), go_record_sha256 = positive_go_sha,
    source_row_start = min(source_idx), source_row_end = max(source_idx),
    local_index_start = 1L, local_index_end = 3000L,
    master_seed = 2026101902L, design_mode_source = "clean_current",
    design_mode_worker = "clean_current_stage_two",
    manifest_sha256 = hash_file(file.path(d, "manifest.csv")),
    status = "prepared_not_launched")
  write_json(conversion, file.path(d, "conversion-receipt.json"))
  registry <- data.frame(path = c(file.path(d, "manifest.csv"), clean_source,
    file.path(d, "conversion-receipt.json")),
    sha256 = vapply(c(file.path(d, "manifest.csv"), clean_source,
      file.path(d, "conversion-receipt.json")), hash_file, character(1L)))
  write.csv(registry, file.path(d, "source-hashes.csv"), row.names = FALSE)
  registry_sha <- hash_file(file.path(d, "source-hashes.csv"))
  cases <- data.frame(index = 1:3000, status = "error", returncode = 1L)
  write_json(list(registry_sha256 = registry_sha,
    manifest_sha256 = hash_file(file.path(d, "manifest.csv")),
    planned_indices = as.list(1:3000), campaign_complete = TRUE,
    interrupted = FALSE, subset_complete = TRUE, cases = cases),
    file.path(d, "supervisor-receipt.json"))
  attempt_sha <- native_sd_stage_two_attempt_digest(d,
    expected_indices = integer(), allowed_indices = 1:3000)
  positive_batch_registry[[as.character(batch_id)]] <- registry_sha
  positive_batch_attempts[[as.character(batch_id)]] <- attempt_sha
  positive_batch_root_receipts[[batch_id]] <- list(batch_id = batch_id,
    registry_sha256 = registry_sha,
    conversion_receipt_sha256 = hash_file(file.path(d, "conversion-receipt.json")))
}
positive_root_receipt <- list(status = "prepared_not_launched", no_fits_launched = TRUE,
  source_manifest_sha256 = hash_file(clean_source),
  source_design_mode = "clean_current", worker_design_mode = "clean_current_stage_two",
  go_record_sha256 = positive_go_sha,
  first_look_registry_sha256 = positive_first_registry_sha,
  first_look_decision_sha256 = hash_file(positive_decision_path),
  first_look_seal_sha256 = hash_file(positive_first_seal_path),
  first_look_standardized_sha256 = hash_file(file.path(positive_root,
    "first-look-standardized.csv")),
  first_look_replay_receipt_sha256 = hash_file(file.path(positive_root,
    "first-look-replay-receipt.json")),
  harness_archive_sha256 = "harness-synthetic",
  matched_original_native_artifacts = list("synthetic-runtime"),
  batches = do.call(rbind, lapply(positive_batch_root_receipts, as.data.frame)))
positive_root_receipt_path <- file.path(positive_root, "root-preparation-receipt.json")
write_json(positive_root_receipt, positive_root_receipt_path)
positive_run_auth_path <- file.path(tmp, "positive-run-authorization.json")
write_json(list(go_record_sha256 = positive_go_sha), positive_run_auth_path)
positive_run_auth_sha <- hash_file(positive_run_auth_path)
positive_now <- as.numeric(Sys.time())
positive_run_path <- file.path(positive_root, "stage-two-run-receipt.json")
write_json(list(status = "all_batches_terminal", no_retries = TRUE,
  started_epoch = positive_now - 1, deadline_epoch = positive_now + 10000,
  external_seals_sha256 = positive_run_auth_sha, go_record_sha256 = positive_go_sha,
  batches = data.frame(batch_id = 1:3,
    attempts_sha256 = unname(unlist(positive_batch_attempts)))), positive_run_path)
positive_staged_path <- file.path(tmp, "positive-staged-analyzer.R")
writeLines(c(
  "native_sd_staged_decision <- function(attempts, manifest_count, look, completed_campaign) {",
  "  decision <- if (look == 1L) 'look2_required' else 'inconclusive'",
  "  list(decision = decision, metrics = data.frame(), gates = data.frame(), status_counts = data.frame())",
  "}"), positive_staged_path)
saveRDS(list(decision = "look2_required", metrics = data.frame(),
  gates = data.frame(), status_counts = data.frame()),
  file.path(positive_first, "staged-decision.rds"))
reconstruction_names <- c("stage_two.py", "reconstruct-first-look.py",
  "stage-two-rules.R", "verify-first-look.R", "combine-stage-two.R")
reconstruction_hashes <- stats::setNames(vapply(reconstruction_names, function(name)
  hash_file(file.path(adapter, name)), character(1L)), reconstruction_names)
positive_seals <- list(staged_decision_path = positive_staged_path,
  staged_decision_sha256 = hash_file(positive_staged_path),
  adapter_rules_path = file.path(adapter, "stage-two-rules.R"),
  adapter_rules_sha256 = hash_file(file.path(adapter, "stage-two-rules.R")),
  first_look_reconstruction_source_sha256 = as.list(reconstruction_hashes),
  first_look_registry_sha256 = positive_first_registry_sha,
  first_look_attempts_sha256 = positive_first_attempts_sha,
  root_preparation_receipt_sha256 = hash_file(positive_root_receipt_path),
  first_look_seal_sha256 = hash_file(positive_first_seal_path),
  go_record_sha256 = positive_go_sha, harness_archive_sha256 = "harness-synthetic",
  first_look_decision_sha256 = hash_file(positive_decision_path),
  batch_registry_sha256 = positive_batch_registry,
  stage_two_run_receipt_sha256 = hash_file(positive_run_path),
  run_authorization_seals_sha256 = positive_run_auth_sha,
  batch_attempt_sha256 = positive_batch_attempts,
  first_look_decision_path = positive_decision_path,
  go_record_path = positive_go_path)
positive_seals_path <- file.path(tmp, "positive-combination-seals.json")
write_json(positive_seals, positive_seals_path)
positive_cmd <- system2(rs, shQuote(c(script, positive_first,
  file.path(positive_root, paste0("batch-", 1:3)), positive_seals_path,
  hash_file(positive_seals_path), positive_out)), stdout = TRUE, stderr = TRUE)
positive_status <- attr(positive_cmd, "status")
if (is.null(positive_status)) positive_status <- 0L
if (positive_status != 0L) {
  stop("Positive clean-current combiner failed: ", paste(positive_cmd, collapse = " | "))
}
positive_receipt_path <- file.path(positive_out, "decision-receipt.json")
positive_receipt <- if (file.exists(positive_receipt_path))
  jsonlite::fromJSON(positive_receipt_path, simplifyVector = TRUE) else NULL
positive_attempts <- if (file.exists(file.path(positive_out, "all-attempts.csv")))
  read.csv(file.path(positive_out, "all-attempts.csv"), stringsAsFactors = FALSE) else NULL
stopifnot(positive_status == 0L,
  any(grepl("STAGE_TWO_COMBINE_COMPLETE inconclusive", positive_cmd, fixed = TRUE)),
  is.list(positive_receipt), positive_receipt$decision == "inconclusive",
  is.data.frame(positive_attempts), nrow(positive_attempts) == 12000L,
  all(is.na(positive_attempts$stage_two_index[1:3000])),
  all(is.na(positive_attempts$source_manifest_sha256[1:3000])),
  identical(as.integer(positive_attempts$source_index[3001:12000]), 1:9000),
  identical(as.integer(positive_attempts$stage_two_index[3001:12000]), 1:9000),
  identical(as.character(positive_attempts$source_design_mode[3001:12000]),
    rep("clean_current", 9000L)),
  identical(as.character(positive_attempts$source_manifest_sha256[3001:12000]),
    rep(hash_file(clean_source), 9000L)))
cat("STAGE_TWO_CLEAN_CURRENT_FULL_COMBINE_PASS no_fits=TRUE attempts=12000\n")
