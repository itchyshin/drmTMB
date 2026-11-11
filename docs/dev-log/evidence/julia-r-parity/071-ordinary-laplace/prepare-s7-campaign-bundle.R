#!/usr/bin/env Rscript
# Materialise the immutable S7 denominator before any scheduler worker starts.
# This deliberately stays pure: it neither loads drmTMB nor invokes Julia or
# Slurm.  The compute preflight adds runtime and source-bundle provenance.

r071_ordinary_laplace_script <- function(frame, name) {
  value <- tryCatch(get(name, envir = frame, inherits = FALSE), error = function(e) NULL)
  if (is.character(value) && length(value) == 1L && !is.na(value) && nzchar(value)) {
    return(chartr("\\", "/", value))
  }
  NULL
}

# source() records the script in ofile. sys.source() records it in file and
# never sets ofile. Real callers use sys.source(), so both names are accepted.
# DRMTMB_ROOT is the next resort; a cwd-relative path is only the last one.
r071_ordinary_laplace_dir <- function() {
  n <- sys.nframe()
  if (n > 0L) {
    for (fr in rev(seq_len(n))) {
      frame <- sys.frames()[[fr]]
      for (name in c("ofile", "file")) {
        path <- r071_ordinary_laplace_script(frame, name)
        if (is.null(path) || !grepl("071-ordinary-laplace/[^/]+$", path)) next
        hit <- tryCatch(dirname(normalizePath(path, mustWork = TRUE)), error = function(e) NULL)
        if (!is.null(hit)) return(hit)
      }
    }
  }
  rel <- "docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace"
  root <- Sys.getenv("DRMTMB_ROOT", unset = "")
  candidates <- if (nzchar(root)) c(file.path(root, rel), rel) else rel
  for (candidate in candidates) {
    if (dir.exists(candidate)) return(normalizePath(candidate, mustWork = TRUE))
  }
  stop("cannot locate 071 ordinary-Laplace evidence directory", call. = FALSE)
}

if (!exists("r071_s7_sha256", mode = "function", inherits = FALSE)) {
  laplace_dir <- r071_ordinary_laplace_dir()
  helper <- file.path(laplace_dir, "r071-file-sha256.R")
  if (!file.exists(helper)) {
    stop("missing 071 SHA-256 helper: ", helper, call. = FALSE)
  }
  load_env <- environment()
  if (!requireNamespace("drmTMB", quietly = TRUE) &&
      !nzchar(Sys.getenv("DRMTMB_ROOT", unset = ""))) {
    Sys.setenv(DRMTMB_ROOT = normalizePath(
      file.path(laplace_dir, "..", "..", "..", "..", ".."),
      mustWork = TRUE
    ))
  }
  sys.source(helper, envir = load_env, keep.source = FALSE)
}

r071_s7_atomic_write <- function(path, write_fun) {
  if (file.exists(path)) {
    stop("refusing to overwrite immutable S7 campaign artifact: ", path, call. = FALSE)
  }
  tmp <- tempfile(paste0(".", basename(path), "-"), tmpdir = dirname(path))
  on.exit(unlink(tmp), add = TRUE)
  write_fun(tmp)
  if (!file.rename(tmp, path)) {
    stop("could not publish S7 campaign artifact: ", path, call. = FALSE)
  }
  invisible(path)
}

r071_s7_campaign_metadata <- function(manifest_sha256, profile_plan_sha256) {
  paste0(
    "{\n",
    "  \"schema_version\": 1,\n",
    "  \"manifest\": {\"file\": \"s7-manifest.tsv\", \"rows\": 2000, \"sha256\": \"", manifest_sha256, "\"},\n",
    "  \"profile_plan\": {\"file\": \"s7-profile-plan.tsv\", \"rows\": 34, \"sha256\": \"", profile_plan_sha256, "\"}\n",
    "}\n"
  )
}

r071_s7_campaign_metadata_hashes <- function(path) {
  lines <- paste(readLines(path, warn = FALSE), collapse = "\n")
  hashes <- regmatches(lines, gregexpr("[0-9a-f]{64}", lines, perl = TRUE))[[1L]]
  if (length(hashes) != 2L) {
    stop("S7 campaign metadata does not carry exactly two SHA-256 identities", call. = FALSE)
  }
  stats::setNames(hashes, c("manifest_sha256", "profile_plan_sha256"))
}

r071_s7_write_campaign_bundle <- function(path) {
  if (!exists("r071_s7_manifest", mode = "function", inherits = TRUE) ||
      !exists("r071_s7_profile_plan", mode = "function", inherits = TRUE)) {
    stop("source prepare-s7-campaign-manifest.R before materialising an S7 campaign bundle", call. = FALSE)
  }
  path <- normalizePath(path, mustWork = TRUE)
  manifest <- r071_s7_manifest()
  profile_plan <- r071_s7_profile_plan()
  manifest_path <- file.path(path, "s7-manifest.tsv")
  plan_path <- file.path(path, "s7-profile-plan.tsv")
  metadata_path <- file.path(path, "campaign.json")
  r071_s7_atomic_write(manifest_path, function(file) {
    utils::write.table(manifest, file, sep = "\t", quote = FALSE, row.names = FALSE)
  })
  r071_s7_atomic_write(plan_path, function(file) {
    utils::write.table(profile_plan, file, sep = "\t", quote = FALSE, row.names = FALSE)
  })
  manifest_sha256 <- r071_s7_sha256(manifest_path)
  profile_plan_sha256 <- r071_s7_sha256(plan_path)
  r071_s7_atomic_write(metadata_path, function(file) {
    writeLines(r071_s7_campaign_metadata(manifest_sha256, profile_plan_sha256), file)
  })
  list(
    manifest_rows = nrow(manifest),
    profile_plan_rows = nrow(profile_plan),
    manifest_sha256 = manifest_sha256,
    profile_plan_sha256 = profile_plan_sha256,
    campaign_sha256 = r071_s7_sha256(metadata_path)
  )
}

r071_s7_read_campaign_bundle <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  manifest_path <- file.path(path, "s7-manifest.tsv")
  plan_path <- file.path(path, "s7-profile-plan.tsv")
  metadata_path <- file.path(path, "campaign.json")
  if (!all(file.exists(c(manifest_path, plan_path, metadata_path)))) {
    stop("S7 campaign bundle is incomplete", call. = FALSE)
  }
  manifest <- utils::read.delim(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  profile_plan <- utils::read.delim(plan_path, stringsAsFactors = FALSE, check.names = FALSE)
  r071_s7_validate_manifest(manifest)
  r071_s7_validate_profile_plan(profile_plan)
  expected_hashes <- r071_s7_campaign_metadata_hashes(metadata_path)
  observed_hashes <- c(
    manifest_sha256 = r071_s7_sha256(manifest_path),
    profile_plan_sha256 = r071_s7_sha256(plan_path)
  )
  if (!identical(unname(observed_hashes), unname(expected_hashes))) {
    stop("S7 campaign bundle checksum drift", call. = FALSE)
  }
  list(manifest = manifest, profile_plan = profile_plan, metadata_sha256 = r071_s7_sha256(metadata_path))
}
