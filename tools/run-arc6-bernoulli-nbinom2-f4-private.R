#!/usr/bin/env Rscript

# Developer-only F4 preparation harness for the fixed-effect Bernoulli x
# ordinary-NB2 association candidate.  This file deliberately has no execution
# mode: a separately approved DRAC receipt must pin the post-F4b source SHA and
# add the scheduler-facing invocation before any outer refit can occur.

f4_private_engine_blobs <- c(
  "R/associate-pairs-sandwich.R" = "d090f67b74bf5dfee6baa4396a8f45a3c977d6fd",
  "tests/testthat/test-associate-pairs-staged-sandwich.R" = "d36b02b2ad470e641843d4f751ee1c998e6922bf"
)
f4_stages <- c("dgp_harness", "bernoulli_margin", "nb2_mean", "nb2_dispersion",
  "association", "rectangle", "sandwich", "delta", "interval")
f4_status_columns <- c(
  "source_sha", "private_engine_blob", "fixture_blob", "cell_id", "n", "b0",
  "sigma", "alpha_true", "replicate", "seed", "protocol_status",
  "terminal_stage", "terminal_status", "bernoulli_margin_status",
  "nb2_mean_status", "nb2_dispersion_status", "association_status",
  "rectangle_status", "sandwich_status", "delta_status", "interval_status",
  "alpha_hat", "alpha_godambe_se", "eta_delta_se", "alpha_lower",
  "alpha_upper", "point_available", "alpha_godambe_available",
  "eta_delta_available", "interval_available", "failure_reason"
)

f4_abort <- function(message) stop(message, call. = FALSE)

f4_grid <- function() {
  out <- expand.grid(
    n = c(120L, 240L, 480L), b0 = c(-1.4, -0.2), sigma = c(0.25, 0.65),
    alpha_true = c(0, 0.22), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  out <- out[order(out$n, out$b0, out$sigma, out$alpha_true), , drop = FALSE]
  out$cell_id <- sprintf("f4-c%02d", seq_len(nrow(out)))
  out[, c("cell_id", "n", "b0", "sigma", "alpha_true")]
}

f4_seed_manifest <- function(grid = f4_grid(), n_replicate = 1000L) {
  if (!identical(as.integer(n_replicate), 1000L)) {
    f4_abort("F4 fixes exactly 1,000 outer attempts per cell.")
  }
  if (nrow(grid) != 24L || !identical(grid$cell_id, sprintf("f4-c%02d", 1:24))) {
    f4_abort("F4 grid must be the frozen 24-cell lexicographic grid.")
  }
  out <- grid[rep(seq_len(nrow(grid)), each = n_replicate), , drop = FALSE]
  out$replicate <- rep(seq_len(n_replicate), times = nrow(grid))
  cell_number <- rep(seq_len(nrow(grid)), each = n_replicate)
  out$seed <- 2026072000L + 100000L * cell_number + out$replicate
  rownames(out) <- NULL
  out
}

f4_validate_seed_manifest <- function(manifest) {
  required <- c("cell_id", "n", "b0", "sigma", "alpha_true", "replicate", "seed")
  if (!identical(names(manifest), required)) f4_abort("F4 seed manifest has the wrong columns.")
  expected <- f4_seed_manifest()
  if (!identical(manifest, expected)) f4_abort("F4 seed manifest does not match the frozen 24,000-attempt schedule.")
  invisible(manifest)
}

f4_status_template <- function(row, source_sha, blobs = f4_private_engine_blobs) {
  if (length(source_sha) != 1L || !grepl("^[0-9a-f]{40}$", source_sha)) {
    f4_abort("F4 source SHA must be a full lowercase 40-character Git SHA.")
  }
  if (!identical(blobs, f4_private_engine_blobs)) f4_abort("F4 private-engine blob mismatch.")
  if (!all(c("cell_id", "n", "b0", "sigma", "alpha_true", "replicate", "seed") %in% names(row))) {
    f4_abort("F4 status row needs one seed-manifest row.")
  }
  values <- list(
    source_sha, unname(blobs[[1L]]), unname(blobs[[2L]]), as.character(row$cell_id),
    as.integer(row$n), as.numeric(row$b0), as.numeric(row$sigma), as.numeric(row$alpha_true),
    as.integer(row$replicate), as.integer(row$seed), "valid", "dgp_harness", "not_attempted",
    "not_attempted", "not_attempted", "not_attempted", "not_attempted", "not_attempted", "not_attempted", "not_attempted", "not_attempted",
    NA_real_, NA_real_, NA_real_, NA_real_, NA_real_, FALSE, FALSE, FALSE, FALSE, NA_character_
  )
  out <- as.data.frame(stats::setNames(values, f4_status_columns), stringsAsFactors = FALSE)
  out
}

f4_stage_status_columns <- stats::setNames(
  paste0(f4_stages, "_status"), f4_stages
)

f4_terminalize <- function(status) {
  if (!identical(names(status), f4_status_columns)) f4_abort("F4 status row has the wrong columns.")
  if (!identical(status$protocol_status, "valid")) {
    status$terminal_stage <- "dgp_harness"; status$terminal_status <- "protocol_quarantine"
    status$failure_reason <- "protocol_quarantine"
    return(status)
  }
  # Protocol is the dgp_harness stage and was handled above.  The retained
  # all-attempt row has no second, mutable dgp_harness status column.
  for (stage in f4_stages[-1L]) {
    column <- f4_stage_status_columns[[stage]]
    value <- status[[column]]
    if (identical(value, "not_attempted")) {
      status$terminal_stage <- stage; status$terminal_status <- "not_attempted"
      status$failure_reason <- "not_attempted"
      return(status)
    }
    if (!identical(value, "ok") && !(identical(stage, "association") && identical(value, "interior")) && !(identical(stage, "interval") && identical(value, "available"))) {
      status$terminal_stage <- stage; status$terminal_status <- value
      status$failure_reason <- value
      return(status)
    }
  }
  status$terminal_stage <- "complete"; status$terminal_status <- "success"
  status$failure_reason <- NA_character_
  status
}

f4_alpha_extract <- function(association_fit, sandwich) {
  unavailable <- list(
    alpha_hat = NA_real_, alpha_godambe_se = NA_real_, eta_delta_se = NA_real_,
    alpha_lower = NA_real_, alpha_upper = NA_real_, point_available = FALSE,
    alpha_godambe_available = FALSE, eta_delta_available = FALSE,
    interval_available = FALSE
  )
  point_ok <- identical(association_fit$status, "interior") &&
    isTRUE(association_fit$rectangle_ok) && length(association_fit$alpha) == 1L &&
    is.finite(association_fit$alpha)
  if (!point_ok) return(unavailable)
  out <- unavailable; out$alpha_hat <- unname(association_fit$alpha); out$point_available <- TRUE
  covariance <- sandwich$alpha_covariance
  se <- sandwich$alpha_se
  godambe_ok <- identical(sandwich$status, "ok") && is.matrix(covariance) &&
    identical(dim(covariance), c(1L, 1L)) && is.finite(covariance[[1L]]) &&
    length(se) == 1L && is.finite(se[[1L]]) && se[[1L]] > 0
  if (!godambe_ok) return(out)
  out$alpha_godambe_se <- unname(se[[1L]]); out$alpha_godambe_available <- TRUE
  eta_ok <- length(sandwich$eta_se) == 1L && is.finite(sandwich$eta_se[[1L]]) && sandwich$eta_se[[1L]] > 0
  out$eta_delta_se <- if (eta_ok) unname(sandwich$eta_se[[1L]]) else NA_real_
  out$eta_delta_available <- eta_ok
  endpoints <- out$alpha_hat + stats::qnorm(c(0.025, 0.975)) * out$alpha_godambe_se
  if (all(is.finite(endpoints))) {
    out$alpha_lower <- endpoints[[1L]]; out$alpha_upper <- endpoints[[2L]]
    out$interval_available <- TRUE
  }
  out
}

f4_apply_alpha_extract <- function(status, association_fit, sandwich) {
  extracted <- f4_alpha_extract(association_fit, sandwich)
  for (name in names(extracted)) status[[name]] <- extracted[[name]]
  status$association_status <- if (identical(association_fit$status, "interior")) "interior" else as.character(association_fit$status)
  status$rectangle_status <- if (isTRUE(association_fit$rectangle_ok)) "ok" else "rectangle_failure"
  reason <- if (is.null(sandwich$reason)) "sandwich_failure" else as.character(sandwich$reason)
  if (identical(sandwich$status, "ok")) {
    status$sandwich_status <- "ok"
  } else if (reason %in% c("association_nonfinite_derivative", "association_step_unstable")) {
    status$rectangle_status <- reason
  } else if (identical(reason, "eta_delta_unstable")) {
    status$sandwich_status <- "ok"
    status$delta_status <- reason
  } else {
    status$sandwich_status <- reason
  }
  if (identical(status$delta_status, "not_attempted")) {
    status$delta_status <- if (isTRUE(extracted$eta_delta_available)) "ok" else "eta_delta_unavailable"
  }
  status$interval_status <- if (isTRUE(extracted$interval_available)) "available" else "interval_unavailable"
  f4_terminalize(status)
}

f4_with_rng <- function(expr, seed) {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", .GlobalEnv)
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) assign(".Random.seed", old_seed, .GlobalEnv) else if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(seed)
  force(expr)
}

f4_rectangle_available <- function(association_fit) {
  rows <- tryCatch(association_fit$diagnostics$count_interval$row_numerics, error = function(...) NULL)
  is.data.frame(rows) && "status" %in% names(rows) && nrow(rows) > 0L && all(rows$status == "ok")
}

f4_mark_failure <- function(status, stage, reason) {
  if (identical(stage, "dgp_harness")) {
    status$protocol_status <- "quarantined"
  } else {
    status[[f4_stage_status_columns[[stage]]]] <- reason
  }
  f4_terminalize(status)
}

# This function is intentionally not reached by the F4b CLI.  It is the sole
# future full-refit path: fresh margins, then the private sandwich, with no
# conditional association curvature or public inference method.
f4_run_attempt <- function(manifest_row, source_sha, namespace) {
  status <- f4_status_template(manifest_row, source_sha)
  get_local <- function(name) get(name, envir = namespace, inherits = FALSE)
  f4_with_rng({
    n <- status$n; x <- seq(-1.4, 1.4, length.out = n)
    p <- stats::plogis(status$b0 + 0.3 * x)
    mu <- exp(0.7 + 0.2 * x)
    z_binary <- stats::rnorm(n)
    eta <- 0.999999 * tanh(status$alpha_true)
    z_count <- eta * z_binary + sqrt(1 - eta^2) * stats::rnorm(n)
    quantile_nb2 <- get_local("drm_pair_nbinom2_quantile_from_normal")
    dat <- data.frame(
      x = x,
      binary = as.integer(z_binary > stats::qnorm(p, lower.tail = FALSE)),
      count = quantile_nb2(z_count, mu, rep(status$sigma, n))
    )
    fit <- get_local("drmTMB"); bf_local <- get_local("bf"); nbinom2_local <- get_local("nbinom2")
    binary_fit <- tryCatch(fit(bf_local(mu = binary ~ x), stats::binomial(), dat), error = identity)
    if (inherits(binary_fit, "error")) return(f4_mark_failure(status, "bernoulli_margin", "bernoulli_margin_failure"))
    status$bernoulli_margin_status <- "ok"
    nb2_fit <- tryCatch(fit(bf_local(mu = count ~ x, sigma = ~1), nbinom2_local(), dat), error = identity)
    if (inherits(nb2_fit, "error")) return(f4_mark_failure(status, "nb2_mean", "nb2_mean_failure"))
    status$nb2_mean_status <- "ok"
    sigma_ok <- tryCatch({ value <- get_local("fixef")(nb2_fit)$sigma; length(value) == 1L && is.finite(value) }, error = function(...) FALSE)
    if (!isTRUE(sigma_ok)) return(f4_mark_failure(status, "nb2_dispersion", "nb2_dispersion_failure"))
    status$nb2_dispersion_status <- "ok"
    association_fit <- tryCatch(get_local("associate_pairs")(binary_fit, nb2_fit, kernel = get_local("latent_normal")(), association = ~1), error = identity)
    if (inherits(association_fit, "error")) return(f4_mark_failure(status, "association", "association_failure"))
    if (!identical(association_fit$status, "interior")) {
      status$association_status <- as.character(association_fit$status)
      return(f4_terminalize(status))
    }
    status$association_status <- "interior"
    association_fit$rectangle_ok <- f4_rectangle_available(association_fit)
    if (!isTRUE(association_fit$rectangle_ok)) return(f4_mark_failure(status, "rectangle", "rectangle_failure"))
    status$rectangle_status <- "ok"
    sandwich <- tryCatch(get_local("drm_pair_general_eta_sandwich")(binary_fit, nb2_fit, association_fit), error = identity)
    if (inherits(sandwich, "error")) return(f4_mark_failure(status, "sandwich", "sandwich_failure"))
    f4_apply_alpha_extract(status, association_fit, sandwich)
  }, seed = status$seed)
}

f4_preflight <- function(expected_sha, root = getwd(), runner = system2) {
  if (!file.exists(file.path(root, "DESCRIPTION")) || !dir.exists(file.path(root, "R"))) {
    f4_abort("F4 must run from the drmTMB package root.")
  }
  if (length(expected_sha) != 1L || !grepl("^[0-9a-f]{40}$", expected_sha)) {
    f4_abort("--expected-sha must be a full lowercase 40-character Git SHA.")
  }
  command <- function(args) {
    out <- tryCatch(runner("git", args = args, stdout = TRUE, stderr = TRUE), error = identity)
    if (inherits(out, "error") || (!is.null(attr(out, "status")) && attr(out, "status") != 0L)) f4_abort("F4 Git preflight failed.")
    paste(out, collapse = "\n")
  }
  if (nzchar(command(c("status", "--porcelain")))) f4_abort("F4 requires a clean Git worktree.")
  if (!identical(command(c("rev-parse", "HEAD")), expected_sha)) f4_abort("Current HEAD does not equal --expected-sha.")
  blobs <- vapply(names(f4_private_engine_blobs), function(path) command(c("rev-parse", paste0("HEAD:", path))), character(1L))
  if (!identical(unname(blobs), unname(f4_private_engine_blobs))) f4_abort("F4 private-engine or fixture blob mismatch.")
  list(source_sha = expected_sha, source_blobs = blobs, seed_manifest = f4_seed_manifest())
}

f4_parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) != 3L || !identical(args[[1L]], "--mode=prepare") ||
      !startsWith(args[[2L]], "--expected-sha=") || !startsWith(args[[3L]], "--out-dir=")) {
    f4_abort("Usage: Rscript --vanilla tools/run-arc6-bernoulli-nbinom2-f4-private.R --mode=prepare --expected-sha=<full-SHA> --out-dir=<absent-directory>")
  }
  expected_sha <- sub("^--expected-sha=", "", args[[2L]]); out_dir <- sub("^--out-dir=", "", args[[3L]])
  if (!grepl("^[0-9a-f]{40}$", expected_sha)) f4_abort("--expected-sha must be a full lowercase 40-character Git SHA.")
  if (!nzchar(out_dir)) f4_abort("--out-dir must be nonempty.")
  list(expected_sha = expected_sha, out_dir = out_dir)
}

f4_prepare <- function(opts, root = getwd()) {
  gate <- f4_preflight(opts$expected_sha, root = root)
  out_dir <- normalizePath(opts$out_dir, mustWork = FALSE)
  if (file.exists(out_dir)) f4_abort("F4 prepare refuses to overwrite an existing --out-dir.")
  if (!dir.create(out_dir, recursive = TRUE)) f4_abort("F4 prepare could not create --out-dir.")
  utils::write.table(gate$seed_manifest, file.path(out_dir, "seed-manifest.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  utils::write.table(data.frame(path = names(gate$source_blobs), blob = unname(gate$source_blobs)), file.path(out_dir, "source-blobs.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  utils::writeLines(c("F4 preparation only", "No outer refits were run.", "DRAC execution requires a later approval."), file.path(out_dir, "README.txt"))
  invisible(gate)
}

f4_main <- function(args = commandArgs(trailingOnly = TRUE)) f4_prepare(f4_parse_args(args))

if (sys.nframe() == 0L) f4_main()
