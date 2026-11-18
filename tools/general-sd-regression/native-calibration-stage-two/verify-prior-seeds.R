verify_native_sd_prior_manifest <- function(path, expected_n, master_seed, mode) {
  manifest <- read.csv(path, stringsAsFactors = FALSE)
  expected_seeds <- function(seed, n) {
    set.seed(as.integer(seed))
    sample.int(.Machine$integer.max, n)
  }
  if (nrow(manifest) != expected_n || !all(c("a", "seed") %in% names(manifest))) {
    stop("prior manifest has missing rows or required truth/seed columns")
  }
  key <- if ("index" %in% names(manifest)) "index" else if ("manifest_row" %in% names(manifest)) "manifest_row" else NA_character_
  legacy_pilot <- is.na(key) && mode == "pilot" && expected_n == 6L &&
    master_seed == 2026101702L
  if (legacy_pilot) {
    # This exact retained pilot predates row IDs. Its deterministic seed and
    # truth checks below establish the frozen row order.
  } else if (is.na(key) || !identical(as.integer(manifest[[key]]), seq_len(expected_n))) {
    stop("prior manifest row identity is missing or out of order")
  }
  if (!identical(as.integer(manifest$seed), expected_seeds(master_seed, expected_n))) {
    stop("prior manifest seeds differ from the exact deterministic stream")
  }
  if ("master_seed" %in% names(manifest) &&
      !identical(as.integer(manifest$master_seed), rep(as.integer(master_seed), expected_n))) {
    stop("prior manifest master seed differs from its stream")
  }
  # The frozen pilot is produced by expand.grid(a = ..., pilot = 1:2), where
  # the first factor varies fastest and the second labels contiguous blocks.
  expected_truth <- if (mode == "pilot") rep(c(-0.5, 0, 0.5), times = 2L) else
    rep(c(-0.5, 0, 0.5), each = expected_n / 3L)
  if (!identical(as.numeric(manifest$a), expected_truth)) {
    stop("prior manifest truth allocation differs from its frozen design")
  }
  if (mode == "pilot") {
    if ("pilot" %in% names(manifest) &&
        !identical(as.integer(manifest$pilot), rep(1:2, each = 3L))) {
      stop("pilot replicate labels differ from the frozen design")
    }
    if ("replicate" %in% names(manifest) &&
        !identical(as.integer(manifest$replicate), rep(1:2, each = 3L))) {
      stop("pilot replicate labels differ from the frozen design")
    }
  } else {
    design_mode <- if (mode == "production") "production" else "qualification"
    required <- c("replicate", "groups", "repeats", "beta0", "beta1", "alpha0", "design_mode")
    if (!all(required %in% names(manifest))) stop("prior manifest lacks frozen design columns")
    if (!identical(as.integer(manifest$replicate), rep(seq_len(expected_n / 3L), 3L)) ||
        any(manifest$groups != 160L) || any(manifest$repeats != 16L) ||
        any(manifest$beta0 != -0.3) || any(manifest$beta1 != 0.6) ||
        any(abs(manifest$alpha0 - log(0.8)) > 1e-12) ||
        any(manifest$design_mode != design_mode)) {
      stop("prior manifest replicate or design fields differ from the frozen stream")
    }
  }
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 4L) stop("Usage: Rscript verify-prior-seeds.R MANIFEST N MASTER_SEED MODE")
  verify_native_sd_prior_manifest(args[[1L]], as.integer(args[[2L]]),
                                  as.integer(args[[3L]]), args[[4L]])
  cat("PRIOR_STREAM_VERIFIED", args[[4L]], args[[2L]], "rows\n")
}
