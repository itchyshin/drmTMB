# Synthetic contract test for the timing-only 95% Bernoulli capsule summary.
# Run with: Rscript test-summarize-timing-095.R
script_path <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[[1L]]))
summary_script <- file.path(dirname(script_path), "summarize-timing-095.R")
stopifnot(requireNamespace("digest", quietly = TRUE), requireNamespace("jsonlite", quietly = TRUE))

hash_file <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
write_json <- function(x, path) jsonlite::write_json(x, path, auto_unbox = TRUE, pretty = TRUE)

make_capsule <- function(root) {
  dir.create(root, recursive = TRUE)
  manifest <- data.frame(
    index = 1:45,
    a = rep(c(-0.5, 0, 0.5), each = 15),
    replicate = rep(4001:4015, times = 3),
    seed = 10001:10045,
    groups = 160L, repeats = 16L, beta0 = -0.3, beta1 = 0.6,
    alpha0 = log(0.8), design_mode = "timing_only",
    master_seed = 2026101903L, look = "timing",
    stringsAsFactors = FALSE
  )
  utils::write.csv(manifest, file.path(root, "manifest.csv"), row.names = FALSE)
  writeLines(c("design_mode=timing_only", "master_seed=2026101903",
               "planned_attempts=45", "profile_level=0.95"),
             file.path(root, "design-receipt.txt"))

  result <- data.frame(
    index = c(1L, 2L, 3L), a = c(-0.5, -0.5, -0.5),
    replicate = 4001:4003, seed = 10001:10003,
    state = c("completed", "completed", "completed"),
    estimate = c(-0.4, -0.3, NA), se = c(0.1, 0.1, NA),
    convergence = c(0L, 0L, NA_integer_), pdHess = c(TRUE, TRUE, FALSE),
    max_abs_gradient = c(1e-5, 2e-5, NA),
    clamp_at_optimum = c("ok", "ok", "not_checked"),
    lower = c(-0.7, -Inf, NA), upper = c(-0.1, 0.1, NA),
    profile_level = rep(0.95, 3),
    interval_status = c("profile", "profile", "profile_error"),
    profile_boundary = c(FALSE, TRUE, NA),
    profile_message = c("", "boundary hit", "failed before endpoints"),
    valid_interval = c(TRUE, FALSE, FALSE),
    laplace_oracle_error = c(0, 0, NA), oracle_pass = c(TRUE, TRUE, FALSE),
    oracle_tolerance = rep(1e-6, 3),
    warnings = c("", "profile warning", "fit warning"),
    error = c("", "", "synthetic fit failure"),
    elapsed = c(1.25, 2.5, 0.75), stringsAsFactors = FALSE
  )
  for (i in seq_len(nrow(result))) {
    utils::write.csv(result[i, ], file.path(root, sprintf("result-%04d.csv", result$index[i])),
                     row.names = FALSE, na = "")
  }
  statuses <- c("completed", "completed", "error", rep("not_started", 42))
  codes <- c(0L, 0L, 1L, rep(NA_integer_, 42))
  cases <- lapply(1:45, function(i) list(index = i, status = statuses[i], returncode = codes[i]))
  registry_path <- file.path(root, "source-hashes.csv")
  registry <- data.frame(path = c(summary_script, file.path(root, "manifest.csv")),
                         sha256 = c(hash_file(summary_script), hash_file(file.path(root, "manifest.csv"))))
  utils::write.csv(registry, registry_path, row.names = FALSE)
  registry_sha <- hash_file(registry_path)
  receipt <- list(
    planned_indices = as.list(1:45), design_mode = "timing_only",
    registry_sha256 = registry_sha, manifest_sha256 = hash_file(file.path(root, "manifest.csv")),
    finished_at = 1900000000, interrupted = FALSE, subset_complete = FALSE,
    campaign_complete = FALSE, cases = cases
  )
  write_json(receipt, file.path(root, "supervisor-receipt.json"))
  registry_sha
}

reseal_capsule <- function(root) {
  registry_path <- file.path(root, "source-hashes.csv")
  registry <- data.frame(path = c(summary_script, file.path(root, "manifest.csv")),
                         sha256 = c(hash_file(summary_script), hash_file(file.path(root, "manifest.csv"))))
  utils::write.csv(registry, registry_path, row.names = FALSE)
  registry_sha <- hash_file(registry_path)
  receipt <- jsonlite::fromJSON(file.path(root, "supervisor-receipt.json"), simplifyVector = FALSE)
  receipt$registry_sha256 <- registry_sha
  write_json(receipt, file.path(root, "supervisor-receipt.json"))
  registry_sha
}

run_summary <- function(root, registry_sha) {
  status <- suppressWarnings(system2("Rscript", c("--vanilla", shQuote(summary_script), shQuote(root), shQuote(registry_sha)),
                    stdout = TRUE, stderr = TRUE))
  list(status = attr(status, "status") %||% 0L, output = paste(status, collapse = "\n"))
}
`%||%` <- function(x, y) if (is.null(x)) y else x

scratch <- tempfile("timing-summary-contract-")
dir.create(scratch)

# RED/GREEN contract: a valid but incomplete supervisor receipt retains all 45
# manifest rows and emits timing-only outputs without inferential metrics.
capsule <- file.path(scratch, "capsule")
registry_sha <- make_capsule(capsule)
run <- run_summary(capsule, registry_sha)
if (run$status != 0L) cat(run$output, "\n")
stopifnot(run$status == 0L)
attempt_path <- file.path(capsule, "timing-attempts.csv")
summary_path <- file.path(capsule, "timing-summary.csv")
stopifnot(file.exists(attempt_path), file.exists(summary_path))
attempts <- utils::read.csv(attempt_path, stringsAsFactors = FALSE)
summary <- utils::read.csv(summary_path, stringsAsFactors = FALSE)
stopifnot(nrow(attempts) == 45L, identical(attempts$index, 1:45))
stopifnot(sum(attempts$result_present) == 3L, sum(attempts$valid_profile) == 1L)
stopifnot(sum(attempts$profile_boundary) == 1L, sum(attempts$warning_present) == 2L)
stopifnot(all(summary$calibration_claim == FALSE), all(summary$status == "incomplete"))
truth_row <- summary[summary$group == "truth_-0.5", ]
stopifnot(nrow(truth_row) == 1L, truth_row$planned == 15L, truth_row$completed == 2L,
          truth_row$valid_profiles == 1L, truth_row$mean_elapsed == 1.5)
stopifnot(all(c("mean_elapsed", "median_elapsed", "planned", "completed", "valid_profiles") %in% names(summary)))
stopifnot(!any(grepl("coverage|bias|false_positive|qualified", names(summary), ignore.case = TRUE)))

# Integrity and identity mismatches fail closed.
corrupt <- file.path(scratch, "corrupt")
dir.create(corrupt)
invisible(file.copy(list.files(capsule, full.names = TRUE), corrupt, recursive = TRUE))
corrupt_sha <- reseal_capsule(corrupt)
writeLines("tampered", file.path(corrupt, "result-0001.csv"))
stopifnot(run_summary(corrupt, corrupt_sha)$status != 0L)

# A terminal supervisor with no valid timing profile is still explicitly
# nonqualifying, with all planned rows retained.
no_valid <- file.path(scratch, "no-valid")
dir.create(no_valid)
invisible(file.copy(list.files(capsule, full.names = TRUE), no_valid, recursive = TRUE))
r1 <- utils::read.csv(file.path(no_valid, "result-0001.csv"), stringsAsFactors = FALSE)
r1$valid_interval <- FALSE
r1$interval_status <- "profile_error"
utils::write.csv(r1, file.path(no_valid, "result-0001.csv"), row.names = FALSE, na = "")
receipt <- jsonlite::fromJSON(file.path(no_valid, "supervisor-receipt.json"), simplifyVector = FALSE)
for (i in 4:45) {
  receipt$cases[[i]]$status <- "error"
  receipt$cases[[i]]$returncode <- 1L
}
receipt$subset_complete <- TRUE
write_json(receipt, file.path(no_valid, "supervisor-receipt.json"))
no_valid_sha <- reseal_capsule(no_valid)
no_valid_run <- run_summary(no_valid, no_valid_sha)
if (no_valid_run$status != 0L) cat(no_valid_run$output, "\n")
stopifnot(no_valid_run$status == 0L)
no_valid_summary <- utils::read.csv(file.path(no_valid, "timing-summary.csv"), stringsAsFactors = FALSE)
stopifnot(all(no_valid_summary$status == "nonqualifying_no_valid_profiles"),
          sum(no_valid_summary$valid_profiles[no_valid_summary$group != "overall"]) == 0L,
          nrow(utils::read.csv(file.path(no_valid, "timing-attempts.csv"))) == 45L)

unlink(scratch, recursive = TRUE)
cat("PASS: timing-only summary preserves all 45 attempts and fails closed on tampering\n")
