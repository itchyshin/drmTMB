#!/usr/bin/env Rscript

# Developer-only F3R one-attempt provenance runner.  This file is sourceable;
# only direct Rscript invocation calls f3r_main().

f3r_f1m_sha <- "e0af91fc610a751880dba22a1b342cfb50cb757b"
f3r_blobs <- c(
  "R/associate-pairs-sandwich.R" = "d090f67b74bf5dfee6baa4396a8f45a3c977d6fd",
  "tests/testthat/test-associate-pairs-staged-sandwich.R" = "d36b02b2ad470e641843d4f751ee1c998e6922bf"
)
f3r_status_columns <- c("source_sha", "seed", "dataset_sha256", "terminal_stage",
  "terminal_status", "bernoulli_margin_id", "nb2_mean_margin_id",
  "nb2_dispersion_margin_id", "association_id", "private_result_available",
  "alpha_godambe_available", "eta_delta_available", "interval_status")
f3r_stages <- c("dgp_harness", "bernoulli_margin", "nb2_mean", "nb2_dispersion",
  "association", "rectangle", "sandwich", "delta", "interval")
f3r_terminal_statuses <- list(
  dgp_harness = c("dgp_harness_failure", "provenance_mismatch", "sha256_preflight_failure"),
  bernoulli_margin = "bernoulli_margin_failure", nb2_mean = "nb2_mean_failure",
  nb2_dispersion = "nb2_dispersion_failure",
  association = c("association_unresolved", "association_boundary", "association_failure"),
  rectangle = c("association_nonfinite_derivative", "association_step_unstable", "rectangle_failure"),
  sandwich = c("bread_or_meat_unstable", "bread_solve_failure", "covariance_unstable", "sandwich_failure"),
  delta = c("eta_delta_unstable", "delta_failure"), interval = "not_attempted", complete = "success"
)

f3r_abort <- function(message) stop(message, call. = FALSE)
f3r_expected_out_dir <- function(root, sha) file.path(normalizePath(root), "docs", "dev-log", "smoke", paste0("2026-07-26-arc6-f3-", substr(sha, 1L, 12L)), "attempt-001")
f3r_canonical_out_dir <- function(out_dir, root) {
  if (!startsWith(out_dir, "/")) out_dir <- file.path(normalizePath(root), out_dir)
  normalizePath(out_dir, mustWork = FALSE)
}
f3r_check_out_dir <- function(out_dir, root, sha) {
  if (!identical(f3r_canonical_out_dir(out_dir, root), f3r_expected_out_dir(root, sha))) f3r_abort("--out-dir must be the frozen F3R attempt-001 path for --expected-sha.")
  invisible(out_dir)
}
f3r_parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) != 2L || !startsWith(args[[1L]], "--expected-sha=") || !startsWith(args[[2L]], "--out-dir=")) f3r_abort("Usage: Rscript --vanilla tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R --expected-sha=<full-SHA> --out-dir=<absent-attempt-001-directory>")
  expected_sha <- sub("^--expected-sha=", "", args[[1L]]); out_dir <- sub("^--out-dir=", "", args[[2L]])
  if (!grepl("^[0-9a-f]{40}$", expected_sha)) f3r_abort("--expected-sha must be a full lowercase 40-character Git SHA.")
  if (!nzchar(out_dir)) f3r_abort("--out-dir must name an absent directory.")
  list(expected_sha = expected_sha, out_dir = out_dir)
}
f3r_command <- function(command, args, runner = system2) {
  out <- tryCatch(runner(command, args = args, stdout = TRUE, stderr = TRUE), error = identity)
  if (inherits(out, "error")) f3r_abort(conditionMessage(out))
  if (!is.null(attr(out, "status")) && attr(out, "status") != 0L) f3r_abort(paste(out, collapse = "\n"))
  paste(out, collapse = "\n")
}
f3r_sha256_command <- function(sys_which = Sys.which) {
  if (nzchar(sys_which("shasum")[[1L]])) return(c("shasum", "-a", "256"))
  if (nzchar(sys_which("sha256sum")[[1L]])) return("sha256sum")
  f3r_abort("F3R requires shasum -a 256 or sha256sum before fitting.")
}
f3r_preflight <- function(expected_sha, out_dir, root = getwd(), runner = system2, sys_which = Sys.which) {
  if (!file.exists(file.path(root, "DESCRIPTION")) || !dir.exists(file.path(root, "R"))) f3r_abort("F3R must run from the drmTMB package root.")
  f3r_check_out_dir(out_dir, root, expected_sha)
  if (file.exists(out_dir)) f3r_abort("Refusing to clobber a nonempty or existing --out-dir.")
  if (nzchar(f3r_command("git", c("status", "--porcelain"), runner))) f3r_abort("F3R requires a clean Git worktree.")
  sha <- f3r_command("git", c("rev-parse", "HEAD"), runner)
  if (!identical(sha, expected_sha)) f3r_abort("Current HEAD does not equal --expected-sha.")
  blobs <- vapply(names(f3r_blobs), function(path) f3r_command("git", c("rev-parse", paste0("HEAD:", path)), runner), character(1L))
  if (!identical(unname(blobs), unname(f3r_blobs))) f3r_abort("F1M critical source blob mismatch.")
  list(source_sha = sha, source_blobs = blobs, sha256_command = f3r_sha256_command(sys_which), root = normalizePath(root))
}
f3r_status <- function(source_sha, terminal_stage = "dgp_harness", terminal_status = "dgp_harness_failure", dataset_sha256 = NA_character_, bernoulli_margin_id = NA_character_, nb2_mean_margin_id = NA_character_, nb2_dispersion_margin_id = NA_character_, association_id = NA_character_, private_result_available = FALSE, alpha_godambe_available = FALSE, eta_delta_available = FALSE) {
  if (!terminal_stage %in% names(f3r_terminal_statuses)) f3r_abort("Unknown F3R terminal stage.")
  if (!terminal_status %in% f3r_terminal_statuses[[terminal_stage]]) f3r_abort("Terminal status is not permitted for this F3R terminal stage.")
  as.data.frame(stats::setNames(list(source_sha, 2026072603L, dataset_sha256, terminal_stage, terminal_status, bernoulli_margin_id, nb2_mean_margin_id, nb2_dispersion_margin_id, association_id, isTRUE(private_result_available), isTRUE(alpha_godambe_available), isTRUE(eta_delta_available), "not_attempted"), f3r_status_columns), stringsAsFactors = FALSE)
}
f3r_write_status <- function(status, path, replace = FALSE) {
  if (file.exists(path) && !isTRUE(replace)) f3r_abort("Refusing to overwrite status.csv.")
  utils::write.csv(status[, f3r_status_columns], path, row.names = FALSE, na = "")
  invisible(path)
}
f3r_with_rng <- function(expr, seed = 2026072603L) {
  old_kind <- RNGkind(); had_seed <- exists(".Random.seed", .GlobalEnv, inherits = FALSE); if (had_seed) old_seed <- get(".Random.seed", .GlobalEnv)
  on.exit({ do.call(RNGkind, as.list(old_kind)); if (had_seed) assign(".Random.seed", old_seed, .GlobalEnv) else if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv) }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection"); set.seed(seed); force(expr)
}
f3r_stage_ledger <- function(terminal_stage = NA_character_, reason = NA_character_) {
  out <- data.frame(stage = f3r_stages, status = "not_attempted", reason = NA_character_, stringsAsFactors = FALSE)
  if (is.na(terminal_stage)) return(out)
  if (identical(terminal_stage, "complete")) {
    out$status[match(c("dgp_harness", "bernoulli_margin", "nb2_mean", "nb2_dispersion", "association", "rectangle", "sandwich", "delta"), out$stage)] <- "ok"
    return(out)
  }
  index <- match(terminal_stage, out$stage)
  if (is.na(index)) f3r_abort("Unknown terminal stage for F3R ledger.")
  if (index > 1L) out$status[seq_len(index - 1L)] <- "ok"
  out$status[index] <- "failed"; out$reason[index] <- reason
  out
}
f3r_write_stage_ledger <- function(ledger, path, replace = FALSE) {
  if (file.exists(path) && !isTRUE(replace)) f3r_abort("Refusing to overwrite stage-status.csv.")
  utils::write.csv(ledger, path, row.names = FALSE, na = "")
  invisible(path)
}
f3r_load_local_namespace <- function(root, loader = pkgload::load_all, namespace_getter = asNamespace) {
  loader(path = root, quiet = TRUE, export_all = FALSE)
  ns <- namespace_getter("drmTMB")
  path <- tryCatch(getNamespaceInfo(ns, "path"), error = function(...) "")
  if (!nzchar(path) || !identical(normalizePath(path), normalizePath(root))) f3r_abort("Loaded drmTMB namespace is not the preflighted local package source.")
  list(namespace = ns, path = path)
}
f3r_required_private_helpers <- c("drm_pair_nbinom2_quantile_from_normal", "drm_pair_general_eta_sandwich")
f3r_require_private_helpers <- function(namespace) {
  missing <- f3r_required_private_helpers[!vapply(f3r_required_private_helpers, exists, logical(1L), envir = namespace, inherits = FALSE)]
  if (length(missing)) f3r_abort(paste("Required private helper(s) unavailable from the loaded local namespace:", paste(missing, collapse = ", ")))
  invisible(namespace)
}
f3r_layout <- function(out_dir) { dirs <- file.path(out_dir, c("input", "fit", "private", "metadata", "logs")); dir.create(out_dir); vapply(dirs, dir.create, logical(1L)); invisible(dirs) }
f3r_hash_file <- function(path, command, runner = system2) { out <- f3r_command(command[[1L]], c(command[-1L], path), runner); strsplit(out, "[[:space:]]+")[[1L]][1L] }
f3r_fit_id <- function(fit, namespace) get("drm_pair_fingerprint", envir = namespace)(fit)
f3r_rectangle_available <- function(association_fit) {
  rows <- tryCatch(association_fit$diagnostics$count_interval$row_numerics, error = function(...) NULL)
  is.data.frame(rows) && "status" %in% names(rows) && nrow(rows) > 0L && all(rows$status == "ok")
}
f3r_fit_diagnostic <- function(label, fit) data.frame(
  fit = label,
  convergence = tryCatch(fit$opt$convergence, error = function(...) NA_integer_),
  pdHess = tryCatch(fit$sdr$pdHess, error = function(...) NA),
  objective = tryCatch(fit$opt$objective, error = function(...) NA_real_),
  logLik = tryCatch(as.numeric(stats::logLik(fit)), error = function(...) NA_real_),
  stringsAsFactors = FALSE
)
f3r_write_fit_diagnostics <- function(path, bernoulli, nb2) {
  out <- rbind(f3r_fit_diagnostic("bernoulli_margin", bernoulli), f3r_fit_diagnostic("nb2_margin", nb2))
  utils::write.csv(out, path, row.names = FALSE)
}
f3r_write_association_diagnostics <- function(path, association) {
  out <- data.frame(
    status = tryCatch(association$status, error = function(...) NA_character_),
    logLik = tryCatch(as.numeric(stats::logLik(association)), error = function(...) NA_real_),
    stringsAsFactors = FALSE
  )
  utils::write.csv(out, path, row.names = FALSE)
}
f3r_sandwich_terminal <- function(result) {
  reason <- if (is.null(result$reason)) "sandwich_failure" else result$reason
  if (reason %in% c("association_nonfinite_derivative", "association_step_unstable")) return(c("rectangle", reason))
  if (identical(reason, "eta_delta_unstable")) return(c("delta", reason))
  if (reason %in% c("bread_or_meat_unstable", "bread_solve_failure", "covariance_unstable")) return(c("sandwich", reason))
  c("sandwich", "sandwich_failure")
}
f3r_write_metadata <- function(out_dir, gate, opts, status, namespace_path = NA_character_) {
  utils::write.table(data.frame(source_sha = gate$source_sha, f1m_sha = f3r_f1m_sha,
    cli = paste(commandArgs(trailingOnly = TRUE), collapse = " "), runner_path = "tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R",
    requested_out_dir = opts$out_dir, r_version = R.version.string,
    package_version = as.character(utils::packageVersion("drmTMB")),
    bernoulli_margin_id = status$bernoulli_margin_id, nb2_mean_margin_id = status$nb2_mean_margin_id,
    nb2_dispersion_margin_id = status$nb2_dispersion_margin_id, association_id = status$association_id, namespace_path = namespace_path),
    file.path(out_dir, "metadata", "provenance.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  utils::write.table(data.frame(path = names(gate$source_blobs), blob = unname(gate$source_blobs)), file.path(out_dir, "metadata", "source-blobs.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  writeLines(paste(gate$sha256_command, collapse = " "), file.path(out_dir, "metadata", "sha256-command.txt"))
  writeLines(capture.output(sessionInfo()), file.path(out_dir, "metadata", "session-info.txt"))
  if (!file.exists(file.path(out_dir, "logs", "stdout.txt"))) file.create(file.path(out_dir, "logs", "stdout.txt"))
  if (!file.exists(file.path(out_dir, "logs", "stderr.txt"))) file.create(file.path(out_dir, "logs", "stderr.txt"))
  paths <- list.files(out_dir, recursive = TRUE, full.names = TRUE)
  paths <- paths[!grepl("artifact-sha256\\.tsv$", paths)]
  hashes <- vapply(paths, f3r_hash_file, character(1L), command = gate$sha256_command)
  utils::write.table(data.frame(path = sub(paste0("^", out_dir, "/"), "", paths), sha256 = hashes), file.path(out_dir, "metadata", "artifact-sha256.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
}
f3r_finalize_receipt <- function(result, active_stage, active_status, gate, opts, namespace_path, status_writer = f3r_write_status, ledger_writer = f3r_write_stage_ledger, metadata_writer = f3r_write_metadata) {
  if (is.null(result)) result <- f3r_status(gate$source_sha, active_stage, active_status)
  ledger <- f3r_stage_ledger(result$terminal_stage, result$terminal_status)
  write_error <- tryCatch({
    status_writer(result, file.path(opts$out_dir, "status.csv"))
    ledger_writer(ledger, file.path(opts$out_dir, "stage-status.csv"))
    metadata_writer(opts$out_dir, gate, opts, result, namespace_path)
    NULL
  }, error = identity)
  if (!inherits(write_error, "error")) return(invisible(result))
  failed <- f3r_status(gate$source_sha, "dgp_harness", "provenance_mismatch", dataset_sha256 = result$dataset_sha256)
  failed_ledger <- f3r_stage_ledger("dgp_harness", "provenance_mismatch")
  status_writer(failed, file.path(opts$out_dir, "status.csv"), replace = TRUE)
  ledger_writer(failed_ledger, file.path(opts$out_dir, "stage-status.csv"), replace = TRUE)
  f3r_abort(paste("F3R receipt finalization failed:", conditionMessage(write_error)))
}
f3r_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  opts <- f3r_parse_args(args); gate <- f3r_preflight(opts$expected_sha, opts$out_dir)
  local_package <- f3r_load_local_namespace(gate$root); ns <- local_package$namespace
  f3r_require_private_helpers(ns)
  f3r_layout(opts$out_dir)
  stdout_connection <- file(file.path(opts$out_dir, "logs", "stdout.txt"), open = "wt")
  stderr_connection <- file(file.path(opts$out_dir, "logs", "stderr.txt"), open = "wt")
  old_warn <- getOption("warn")
  sink(stdout_connection); sink(stderr_connection, type = "message"); options(warn = 1L)
  on.exit({ options(warn = old_warn); sink(type = "message"); sink(); close(stderr_connection); close(stdout_connection) }, add = TRUE)
  result <- NULL
  ledger <- f3r_stage_ledger("dgp_harness", "dgp_harness_failure")
  active_stage <- "dgp_harness"
  active_status <- "dgp_harness_failure"
  namespace_path <- NA_character_
  on.exit(f3r_finalize_receipt(result, active_stage, active_status, gate, opts, namespace_path), add = TRUE)
  namespace_path <- local_package$path
  drm_fit <- get("drmTMB", envir = ns); bf <- get("bf", envir = ns)
  nb2 <- get("nbinom2", envir = ns); associate <- get("associate_pairs", envir = ns)
  latent <- get("latent_normal", envir = ns); nb2_quantile <- get("drm_pair_nbinom2_quantile_from_normal", envir = ns)
  sandwich <- get("drm_pair_general_eta_sandwich", envir = ns)
  # All fixed DGP/refit work is below the complete preflight.  No test calls it.
  result <- f3r_with_rng({
    writeLines(capture.output(RNGkind(), dput(.Random.seed)), file.path(opts$out_dir, "metadata", "rng.tsv"))
    n <- 120L; x <- seq(-1, 1, length.out = n); p <- stats::plogis(-0.15 + .25 * x); mu <- exp(.35 + .15 * x); sigma <- rep(.6, n); alpha <- .22; eta <- .999999 * tanh(alpha)
    zb <- stats::rnorm(n); zc <- eta * zb + sqrt(1 - eta^2) * stats::rnorm(n)
    dat <- data.frame(x = x, binary = as.integer(zb > stats::qnorm(p, lower.tail = FALSE)), count = nb2_quantile(zc, mu, sigma))
    utils::write.table(data.frame(n, alpha, eta, seed = 2026072603L), file.path(opts$out_dir, "input", "dgp.tsv"), sep = "\t", row.names = FALSE, quote = FALSE); utils::write.csv(dat, file.path(opts$out_dir, "input", "dataset.csv"), row.names = FALSE); saveRDS(dat, file.path(opts$out_dir, "input", "dataset.rds"))
    active_status <- "sha256_preflight_failure"; h <- f3r_hash_file(file.path(opts$out_dir, "input", "dataset.rds"), gate$sha256_command); writeLines(h, file.path(opts$out_dir, "input", "dataset.sha256"))
    active_stage <- "bernoulli_margin"; active_status <- "bernoulli_margin_failure"; b <- tryCatch(drm_fit(bf(mu = binary ~ x), stats::binomial(), dat), error = identity); if (inherits(b, "error")) return(f3r_status(gate$source_sha, "bernoulli_margin", "bernoulli_margin_failure", h)); saveRDS(b, file.path(opts$out_dir, "fit", "bernoulli-margin.rds"))
    active_stage <- "nb2_mean"; active_status <- "nb2_mean_failure"; nb <- tryCatch(drm_fit(bf(mu = count ~ x, sigma = ~1), nb2(), dat), error = identity); if (inherits(nb, "error")) return(f3r_status(gate$source_sha, "nb2_mean", "nb2_mean_failure", h, f3r_fit_id(b, ns))); saveRDS(nb, file.path(opts$out_dir, "fit", "nb2-mean-margin.rds")); saveRDS(nb, file.path(opts$out_dir, "fit", "nb2-dispersion-margin.rds")); f3r_write_fit_diagnostics(file.path(opts$out_dir, "fit", "fit-diagnostics.csv"), b, nb)
    active_stage <- "nb2_dispersion"; active_status <- "nb2_dispersion_failure"; sigma_ok <- tryCatch({ sigma_hat <- get("fixef", envir = ns)(nb)$sigma; length(sigma_hat) == 1L && is.finite(sigma_hat) }, error = function(...) FALSE); if (!isTRUE(sigma_ok)) return(f3r_status(gate$source_sha, "nb2_dispersion", "nb2_dispersion_failure", h, f3r_fit_id(b, ns), f3r_fit_id(nb, ns)))
    active_stage <- "association"; active_status <- "association_failure"; a <- tryCatch(associate(b, nb, kernel = latent(), association = ~1), error = identity); if (inherits(a, "error")) return(f3r_status(gate$source_sha, "association", "association_failure", h, f3r_fit_id(b, ns), f3r_fit_id(nb, ns), f3r_fit_id(nb, ns))); if (!a$status %in% c("interior", "near_boundary")) { association_status <- if (identical(a$status, "boundary")) "association_boundary" else "association_unresolved"; return(f3r_status(gate$source_sha, "association", association_status, h, f3r_fit_id(b, ns), f3r_fit_id(nb, ns), f3r_fit_id(nb, ns))) }; saveRDS(a, file.path(opts$out_dir, "fit", "association.rds")); f3r_write_association_diagnostics(file.path(opts$out_dir, "fit", "association-diagnostics.csv"), a); active_stage <- "rectangle"; active_status <- "rectangle_failure"; if (!f3r_rectangle_available(a)) return(f3r_status(gate$source_sha, "rectangle", "rectangle_failure", h, f3r_fit_id(b, ns), f3r_fit_id(nb, ns), f3r_fit_id(nb, ns), f3r_fit_id(a, ns)))
    active_stage <- "sandwich"; active_status <- "sandwich_failure"; s <- sandwich(b, nb, a); if (!identical(s$status, "ok")) { terminal <- f3r_sandwich_terminal(s); return(f3r_status(gate$source_sha, terminal[[1L]], terminal[[2L]], h, f3r_fit_id(b, ns), f3r_fit_id(nb, ns), f3r_fit_id(nb, ns), f3r_fit_id(a, ns))) }; saveRDS(s, file.path(opts$out_dir, "private", "sandwich.rds")); f3r_status(gate$source_sha, "complete", "success", h, f3r_fit_id(b, ns), f3r_fit_id(nb, ns), f3r_fit_id(nb, ns), f3r_fit_id(a, ns), TRUE, TRUE, TRUE)
  })
  ledger <- f3r_stage_ledger(result$terminal_stage, result$terminal_status); invisible(result)
}
if (sys.nframe() == 0L) f3r_main()
