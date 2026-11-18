# Seed and manifest design for a fresh Bernoulli calibration campaign against
# one source-pinned current package build. Historical manifests and the
# interrupted v8 run are excluded rather than repaired or reused.

native_sd_historical_seed_streams <- function() {
  seed_stream <- function(master, n) {
    old_kind <- RNGkind()
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit({
      do.call(RNGkind, as.list(old_kind))
      if (had_seed) {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    }, add = TRUE)
    RNGkind("Mersenne-Twister", "Inversion", "Rejection")
    set.seed(master)
    sample.int(.Machine$integer.max, n)
  }

  c(
    seed_stream(2026101702L, 6L),
    seed_stream(2026101703L, 3000L),
    seed_stream(2026101704L, 3000L),
    # Exclude the entire old candidate stream, including selected stage-two
    # seeds and any timing-only use of those seeds.
    seed_stream(2026101705L, 10000L)
  )
}

native_sd_draw_disjoint_seeds <- function(master_seed, n, excluded) {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)

  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(as.integer(master_seed))
  selected <- integer()
  while (length(selected) < n) {
    remaining <- n - length(selected)
    candidates <- sample.int(.Machine$integer.max, remaining + 1000L)
    candidates <- candidates[!candidates %in% c(excluded, selected)]
    if (length(candidates)) selected <- c(selected, candidates)
  }
  selected[seq_len(n)]
}

native_sd_manifest_rows <- function(seed, a, replicate, design_mode,
                                    master_seed, look) {
  data.frame(
    index = seq_along(seed),
    a = as.numeric(a),
    replicate = as.integer(replicate),
    seed = as.integer(seed),
    groups = 160L,
    repeats = 16L,
    beta0 = -0.3,
    beta1 = 0.6,
    alpha0 = log(0.8),
    design_mode = design_mode,
    master_seed = as.integer(master_seed),
    look = look,
    stringsAsFactors = FALSE
  )
}

build_clean_bernoulli_manifests <- function(additional_excluded = integer()) {
  if (!is.numeric(additional_excluded) || any(!is.finite(additional_excluded)) ||
      any(additional_excluded != as.integer(additional_excluded))) {
    stop("additional_excluded must contain finite integer-valued seeds", call. = FALSE)
  }
  historical <- native_sd_historical_seed_streams()
  excluded <- unique(c(historical, as.integer(additional_excluded)))

  timing_seeds <- native_sd_draw_disjoint_seeds(2026101903L, 45L, excluded)
  timing <- native_sd_manifest_rows(
    seed = timing_seeds,
    a = rep(c(-0.5, 0, 0.5), each = 15L),
    replicate = rep(4001:4015, times = 3L),
    design_mode = "timing_only",
    master_seed = 2026101903L,
    look = "timing"
  )

  look1_seeds <- native_sd_draw_disjoint_seeds(
    2026101901L, 3000L, c(excluded, timing_seeds)
  )
  look1 <- native_sd_manifest_rows(
    seed = look1_seeds,
    a = rep(c(-0.5, 0, 0.5), each = 1000L),
    replicate = rep(seq_len(1000L), times = 3L),
    design_mode = "clean_current",
    master_seed = 2026101901L,
    look = "look1"
  )

  look2_seeds <- native_sd_draw_disjoint_seeds(
    2026101902L, 9000L, c(excluded, timing_seeds, look1_seeds)
  )
  look2 <- native_sd_manifest_rows(
    seed = look2_seeds,
    a = rep(c(-0.5, 0, 0.5), each = 3000L),
    replicate = rep(1001:4000, times = 3L),
    design_mode = "clean_current",
    master_seed = 2026101902L,
    look = "look2"
  )

  if (anyDuplicated(c(timing_seeds, look1_seeds, look2_seeds)) ||
      length(intersect(c(timing_seeds, look1_seeds, look2_seeds), historical))) {
    stop("Fresh Bernoulli seeds overlap a prior campaign or each other", call. = FALSE)
  }
  list(timing = timing, look1 = look1, look2 = look2)
}

clean_bernoulli_frozen_sha256 <- c(
  look1 = "5e4c567c21cdb3bdabc61119d453563751447fe2fc011faa09f8b795bbdf80cb",
  look2 = "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98",
  timing = "47461e810a80c8aa7f6618497f9fe963c586f4db63f83ade4efdefccc767c1c7",
  seed_design = "122477952ad03e6945bf6e6a29706933e75eade84e6dcf1aa791129352c17d35"
)

validate_clean_bernoulli_seed_bundle <- function(seed_dir) {
  required <- file.path(seed_dir, c("look1.csv", "look2.csv", "timing.csv", "seed-design.txt"))
  if (!all(file.exists(required))) {
    stop("Frozen clean-current seed bundle is incomplete", call. = FALSE)
  }
  actual_sha <- vapply(required, digest::digest, character(1L),
                       algo = "sha256", file = TRUE)
  names(actual_sha) <- names(clean_bernoulli_frozen_sha256)
  if (!identical(actual_sha, clean_bernoulli_frozen_sha256)) {
    stop("Frozen clean-current seed bundle SHA-256 mismatch", call. = FALSE)
  }
  generated <- build_clean_bernoulli_manifests()
  for (nm in names(generated)) {
    frozen <- read.csv(file.path(seed_dir, paste0(nm, ".csv")),
                       stringsAsFactors = FALSE, check.names = FALSE)
    if (!isTRUE(all.equal(frozen, generated[[nm]], tolerance = 1e-14,
                          check.attributes = FALSE))) {
      stop("Frozen clean-current ", nm,
           " manifest differs from its deterministic producer", call. = FALSE)
    }
  }
  invisible(generated)
}

validate_clean_current_receipt <- function(design, look2_path) {
  required <- c(
    design_mode = "clean_current",
    master_seed = "2026101901",
    profile_level = "0.95",
    planned_attempts = "3000",
    calibration_claim = "true",
    clean_current_seed_stream = "2026101901",
    excluded_historical_streams =
      "2026101702:6,2026101703:3000,2026101704:3000,2026101705:10000",
    stage_two_status =
      "clean_current_manifest_frozen_adapter_reconciliation_outstanding_not_authorized"
  )
  observed <- vapply(names(required), function(name) {
    value <- design[[name]]
    if (is.null(value) || length(value) != 1L || is.na(value)) "" else as.character(value)
  }, character(1L))
  if (!identical(unname(observed), unname(required))) {
    stop("Clean-current design receipt does not match the frozen analysis contract", call. = FALSE)
  }
  if (length(look2_path) != 1L || !file.exists(look2_path) ||
      !identical(as.character(design[["stage_two_manifest_sha256"]]),
                 digest::digest(look2_path, algo = "sha256", file = TRUE))) {
    stop("Clean-current look-two seed seal differs from the frozen receipt", call. = FALSE)
  }
  invisible(TRUE)
}

write_clean_bernoulli_manifests <- function(output_dir,
                                           additional_excluded = integer()) {
  if (length(output_dir) != 1L || is.na(output_dir) || !nzchar(output_dir)) {
    stop("output_dir must be one non-empty path", call. = FALSE)
  }
  if (file.exists(output_dir)) {
    stop("Refusing to overwrite existing clean-manifest directory: ", output_dir,
         call. = FALSE)
  }
  parent <- normalizePath(dirname(output_dir), mustWork = TRUE)
  target <- file.path(parent, basename(output_dir))
  manifests <- build_clean_bernoulli_manifests(additional_excluded)
  temporary <- tempfile(
    pattern = paste0(".", basename(target), ".tmp-"),
    tmpdir = parent
  )
  if (!dir.create(temporary)) {
    stop("Could not create temporary manifest directory", call. = FALSE)
  }
  published <- FALSE
  on.exit(if (!published) unlink(temporary, recursive = TRUE), add = TRUE)

  old_digits <- getOption("digits")
  options(digits = 17L)
  on.exit(options(digits = old_digits), add = TRUE)
  for (name in names(manifests)) {
    utils::write.csv(
      manifests[[name]],
      file.path(temporary, paste0(name, ".csv")),
      row.names = FALSE,
      na = "",
      fileEncoding = "UTF-8"
    )
  }
  writeLines(c(
    "campaign_id=native-bernoulli-sd-clean-current-v1",
    "status=manifests_frozen_no_fits_launched",
    paste0("R_version=", getRversion()),
    paste0("RNGkind=", paste(RNGkind(), collapse = ",")),
    "timing_master_seed=2026101903",
    "look1_master_seed=2026101901",
    "look2_master_seed=2026101902",
    "historical_streams_excluded=2026101702:6,2026101703:3000,2026101704:3000,2026101705:10000",
    "timing_seed_count=45",
    "look1_attempts=3000",
    "look2_attempts=9000",
    "look2_is_cumulative_with_look1=true",
    "DGP=160 groups x 16 rows; log_sd_intercept=log(0.8)+a*w; a=-0.5,0,0.5",
    "existing_v8_attempts_reused=false"
  ), file.path(temporary, "seed-design.txt"), useBytes = TRUE)

  if (file.exists(target)) {
    stop("Refusing to overwrite existing clean-manifest directory: ", target,
         call. = FALSE)
  }
  if (!file.rename(temporary, target)) {
    stop("Could not atomically publish clean-manifest directory", call. = FALSE)
  }
  published <- TRUE
  normalizePath(target, mustWork = TRUE)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 1L) {
    stop("Usage: Rscript clean-manifests.R NEW_OUTPUT_DIRECTORY", call. = FALSE)
  }
  output <- write_clean_bernoulli_manifests(args[[1L]])
  cat("CLEAN_MANIFESTS_FROZEN no fits launched: ", output, "\n", sep = "")
}
