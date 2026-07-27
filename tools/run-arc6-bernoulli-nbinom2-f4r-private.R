#!/usr/bin/env Rscript

# Developer-only F4R preparation harness.  F4R is a fresh, high-information
# alpha Godambe-Wald screen; this adapter deliberately reuses F4's private
# full-refit implementation while freezing a distinct manifest and seed stream.

f4r_runner_path <- file.path(getwd(), "tools", "run-arc6-bernoulli-nbinom2-f4-private.R")
if (!file.exists(f4r_runner_path)) {
  stop("F4R must be sourced from the drmTMB package root.", call. = FALSE)
}
source(f4r_runner_path, local = .GlobalEnv)

f4r_grid <- function() {
  out <- expand.grid(
    n = c(480L, 960L), b0 = c(-1.4, -0.2), sigma = c(0.25, 0.65),
    alpha_true = c(0, 0.22), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  out <- out[order(out$n, out$b0, out$sigma, out$alpha_true), , drop = FALSE]
  out$cell_id <- sprintf("f4r-c%02d", seq_len(nrow(out)))
  out[, c("cell_id", "n", "b0", "sigma", "alpha_true")]
}

f4r_seed_manifest <- function(grid = f4r_grid(), n_replicate = 1000L) {
  if (!identical(as.integer(n_replicate), 1000L)) {
    f4_abort("F4R fixes exactly 1,000 outer attempts per cell.")
  }
  if (nrow(grid) != 16L || !identical(grid$cell_id, sprintf("f4r-c%02d", 1:16))) {
    f4_abort("F4R grid must be the frozen 16-cell lexicographic grid.")
  }
  out <- grid[rep(seq_len(nrow(grid)), each = n_replicate), , drop = FALSE]
  out$replicate <- rep(seq_len(n_replicate), times = nrow(grid))
  cell_number <- rep(seq_len(nrow(grid)), each = n_replicate)
  out$seed <- 2026480000L + 1000L * cell_number + out$replicate
  rownames(out) <- NULL
  out
}

f4r_validate_seed_manifest <- function(manifest) {
  required <- c("cell_id", "n", "b0", "sigma", "alpha_true", "replicate", "seed")
  if (!identical(names(manifest), required)) f4_abort("F4R seed manifest has the wrong columns.")
  expected <- f4r_seed_manifest()
  if (!identical(manifest, expected)) f4_abort("F4R seed manifest does not match the frozen 16,000-attempt schedule.")
  invisible(manifest)
}

f4r_preflight <- function(expected_sha, root = getwd(), runner = system2) {
  # F4's preflight authenticates the unchanged private sandwich and fixture
  # blobs.  Only its old seed manifest is discarded.
  gate <- f4_preflight(expected_sha, root = root, runner = runner)
  gate$seed_manifest <- f4r_seed_manifest()
  gate
}

f4r_parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) != 3L || !identical(args[[1L]], "--mode=prepare") ||
      !startsWith(args[[2L]], "--expected-sha=") || !startsWith(args[[3L]], "--out-dir=")) {
    f4_abort("Usage: Rscript --vanilla tools/run-arc6-bernoulli-nbinom2-f4r-private.R --mode=prepare --expected-sha=<full-SHA> --out-dir=<absent-directory>")
  }
  expected_sha <- sub("^--expected-sha=", "", args[[2L]])
  out_dir <- sub("^--out-dir=", "", args[[3L]])
  if (!grepl("^[0-9a-f]{40}$", expected_sha)) f4_abort("--expected-sha must be a full lowercase 40-character Git SHA.")
  if (!nzchar(out_dir)) f4_abort("--out-dir must be nonempty.")
  list(expected_sha = expected_sha, out_dir = out_dir)
}

f4r_prepare <- function(opts, root = getwd()) {
  gate <- f4r_preflight(opts$expected_sha, root = root)
  out_dir <- normalizePath(opts$out_dir, mustWork = FALSE)
  if (file.exists(out_dir)) f4_abort("F4R prepare refuses to overwrite an existing --out-dir.")
  if (!dir.create(out_dir, recursive = TRUE)) f4_abort("F4R prepare could not create --out-dir.")
  utils::write.table(gate$seed_manifest, file.path(out_dir, "seed-manifest.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  utils::write.table(data.frame(path = names(gate$source_blobs), blob = unname(gate$source_blobs)), file.path(out_dir, "source-blobs.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  utils::writeLines(c("F4R preparation only", "No outer refits were run.", "DRAC execution requires a separately authorized receipt."), file.path(out_dir, "README.txt"))
  invisible(gate)
}

f4r_main <- function(args = commandArgs(trailingOnly = TRUE)) f4r_prepare(f4r_parse_args(args))

if (sys.nframe() == 0L) f4r_main()
