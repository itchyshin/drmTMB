#' Build provenance of the installed drmTMB package
#'
#' `packageVersion("drmTMB")` identifies a release, not a build: two builds
#' can report the same version string while differing by commits under
#' `R/`, `src/`, or `NAMESPACE`. `drm_provenance()` returns a stable,
#' machine-readable record that identifies the BUILD instead.
#'
#' An installed package has no `.git` directory to consult, so the git
#' commit SHA and working-tree dirty flag are never read at call time.
#' Instead they are captured once, at build time, by
#' `tools/drmtmb_provenance.R` (invoked from `configure`/`configure.win`
#' before `inst/` is copied into the installed package) and baked into
#' `inst/build-provenance.dcf`. `drm_provenance()` only reads that baked
#' file. When it is missing -- for example under `devtools::load_all()`, or
#' a build whose `configure` step did not run -- the git fields are `NA`
#' with `source = "unavailable"` and a stated `reason`, rather than a guess.
#' When `configure` ran but git information itself was unavailable at build
#' time (no git executable, or the tree was not a git checkout, as happens
#' when installing from a released tarball with `.git` excluded via
#' `.Rbuildignore`), `source` is `"baked-without-git"`.
#'
#' @return A list with components:
#'   \describe{
#'     \item{package_version}{Character, `packageVersion("drmTMB")`.}
#'     \item{git_sha}{Character SHA-1 baked at build time, or `NA_character_`.}
#'     \item{git_dirty}{Logical: was the source tree dirty at build time? `NA` if unknown.}
#'     \item{build_time}{Character ISO-8601 UTC timestamp of the bake, or `NA_character_`.}
#'     \item{source}{Character: `"baked"`, `"baked-without-git"`, or `"unavailable"`.}
#'     \item{reason}{Character explanation when `source != "baked"`, else `NA_character_`.}
#'     \item{queried_at}{Character ISO-8601 UTC timestamp of this call.}
#'   }
#' @export
#' @examples
#' drm_provenance()
drm_provenance <- function() {
  queried_at <- format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")
  package_version <- as.character(utils::packageVersion("drmTMB"))

  unavailable <- function(reason) {
    list(
      package_version = package_version,
      git_sha = NA_character_,
      git_dirty = NA,
      build_time = NA_character_,
      source = "unavailable",
      reason = reason,
      queried_at = queried_at
    )
  }

  baked_path <- tryCatch(
    system.file("build-provenance.dcf", package = "drmTMB"),
    error = function(e) ""
  )
  if (is.null(baked_path) || !nzchar(baked_path) || !file.exists(baked_path)) {
    return(unavailable(paste(
      "no baked inst/build-provenance.dcf found;",
      "the installed build was not stamped by tools/drmtmb_provenance.R",
      "(e.g. devtools::load_all(), or a configure step that did not run)"
    )))
  }

  fields <- tryCatch(as.data.frame(read.dcf(baked_path), stringsAsFactors = FALSE), error = function(e) NULL)
  if (is.null(fields) || nrow(fields) == 0L) {
    return(unavailable("inst/build-provenance.dcf found but unreadable or empty"))
  }

  get_field <- function(name) {
    if (name %in% names(fields)) {
      val <- as.character(fields[[name]][1L])
      if (is.na(val) || identical(val, "NA") || !nzchar(val)) NA_character_ else val
    } else {
      NA_character_
    }
  }

  git_sha <- get_field("GitSHA")
  git_dirty_chr <- get_field("GitDirty")
  git_dirty <- if (identical(git_dirty_chr, "TRUE")) {
    TRUE
  } else if (identical(git_dirty_chr, "FALSE")) {
    FALSE
  } else {
    NA
  }
  git_reason <- get_field("GitReason")
  build_time <- get_field("BuildTimeUTC")

  list(
    package_version = package_version,
    git_sha = git_sha,
    git_dirty = git_dirty,
    build_time = build_time,
    source = if (is.na(git_sha)) "baked-without-git" else "baked",
    reason = if (is.na(git_sha)) git_reason else NA_character_,
    queried_at = queried_at
  )
}
