# Resolve package-root files (R/, man/, ...) under devtools::test, R CMD check,
# and win-builder layouts. Mirrors drm_src_candidates / drm_src_path in
# test-guard-branch-continuity.R, but paths are relative to the package root
# (e.g. "R/drmTMB.R"), not src/.

drm_pkg_candidates <- function(rel, start_dir = getwd()) {
  rel <- as.character(rel)[[1L]]
  start_dir <- normalizePath(start_dir, winslash = "/", mustWork = FALSE)

  out <- c(
    file.path(start_dir, "..", "..", rel),
    file.path(start_dir, "..", "..", "00_pkg_src", "drmTMB", rel),
    file.path(start_dir, "..", rel),
    file.path(start_dir, "..", "00_pkg_src", "drmTMB", rel),
    file.path(start_dir, "..", "..", "drmTMB", rel),
    file.path(start_dir, "..", "..", "..", "drmTMB", rel)
  )

  dir <- start_dir
  for (i in seq_len(6L)) {
    out <- c(
      out,
      file.path(dir, rel),
      file.path(dir, "00_pkg_src", "drmTMB", rel)
    )
    parent <- dirname(dir)
    if (!identical(parent, dir) && dir.exists(parent)) {
      sibs <- list.files(parent, full.names = TRUE)
      sibs <- sibs[basename(sibs) == "drmTMB" | startsWith(basename(sibs), "drmTMB_")]
      sibs <- sibs[!grepl("\\.Rcheck$", sibs)]
      out <- c(out, file.path(sibs, rel))
    }
    if (identical(parent, dir)) {
      break
    }
    dir <- parent
  }

  out <- c(
    out,
    testthat::test_path("..", "..", rel),
    testthat::test_path("..", "..", "00_pkg_src", "drmTMB", rel),
    testthat::test_path("..", "00_pkg_src", "drmTMB", rel),
    testthat::test_path("..", "..", "drmTMB", rel)
  )

  unique(out)
}

drm_pkg_path <- function(rel, start_dir = getwd()) {
  candidates <- drm_pkg_candidates(rel, start_dir = start_dir)
  exists <- file.exists(candidates)
  hit <- candidates[exists]
  if (length(hit) == 0L) {
    stop(
      "Cannot locate package file '", rel, "'. Tried:\n  ",
      paste(candidates, collapse = "\n  "),
      call. = FALSE
    )
  }
  normalizePath(hit[[1L]], winslash = "/", mustWork = TRUE)
}
