#!/usr/bin/env Rscript

# Build the reader site from a disposable package copy. pkgdown renders every
# root Markdown file it sees; project instructions belong in the repository,
# but not in the public documentation site.

source_dir <- normalizePath(".", mustWork = TRUE)
required <- file.path(source_dir, c("DESCRIPTION", "_pkgdown.yml"))
if (!all(file.exists(required))) {
  stop("Run this script from the drmTMB repository root.", call. = FALSE)
}

private_root_files <- c(
  "AGENTS.md",
  "CLAUDE.md",
  "CONTRIBUTING.md",
  "ROADMAP.md"
)

stage_parent <- tempfile("drmtmb-pkgdown-")
stage_dir <- file.path(stage_parent, "drmTMB")
dir.create(stage_dir, recursive = TRUE)
on.exit(unlink(stage_parent, recursive = TRUE, force = TRUE), add = TRUE)

entries <- list.files(source_dir, all.files = TRUE, no.. = TRUE, full.names = TRUE)
excluded_entries <- c(private_root_files, ".git", ".Rproj.user", "pkgdown-site")
entries <- entries[!basename(entries) %in% excluded_entries]

copied <- file.copy(
  entries, stage_dir, recursive = TRUE, copy.mode = TRUE, copy.date = TRUE
)
if (!all(copied)) {
  stop("Could not create the temporary source copy for the pkgdown build.", call. = FALSE)
}
if (any(file.exists(file.path(stage_dir, private_root_files)))) {
  stop("A private root Markdown file leaked into the staged source.", call. = FALSE)
}

site_dir <- file.path(source_dir, "pkgdown-site")
if (dir.exists(site_dir)) unlink(site_dir, recursive = TRUE, force = TRUE)

pkgdown::build_site(
  pkg = stage_dir,
  override = list(destination = site_dir),
  devel = FALSE,
  new_process = TRUE,
  install = TRUE,
  quiet = FALSE
)
