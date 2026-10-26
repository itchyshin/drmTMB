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

# pkgdown can add a synthetic /NA src to the inline MathJax configuration
# while making 404-page URLs absolute. Keep that configuration inline.
repair_404_mathjax <- function(site_dir) {
  path <- file.path(site_dir, "404.html")
  if (!file.exists(path)) return(invisible(0L))
  page <- xml2::read_html(path)
  scripts <- xml2::xml_find_all(page, ".//script[@src]")
  bad <- grepl("(^|/)NA$", xml2::xml_attr(scripts, "src")) &
    grepl("window.MathJax", xml2::xml_text(scripts), fixed = TRUE)
  if (any(bad)) {
    xml2::xml_attr(scripts[bad], "src") <- NULL
    xml2::write_html(page, path)
  }
  invisible(sum(bad))
}

repair_404_mathjax(site_dir)

# pkgdown can give numbered arguments the same anchor after stripping digits.
# Keep the first target for incoming links and give later arguments unique IDs.
repair_duplicate_argument_anchors <- function(site_dir) {
  changed <- 0L
  for (path in list.files(site_dir, pattern = "[.]html$", recursive = TRUE,
                          full.names = TRUE)) {
    page <- xml2::read_html(path)
    nodes <- xml2::xml_find_all(page, ".//dt[starts-with(@id,'arg-')]")
    ids <- xml2::xml_attr(nodes, "id")
    repeated <- which(duplicated(ids))
    if (!length(repeated)) next
    used <- xml2::xml_attr(xml2::xml_find_all(page, "//*[@id]"), "id")
    for (i in repeated) {
      old <- ids[[i]]
      suffix <- 2L
      candidate <- paste0(old, suffix)
      while (candidate %in% used) {
        suffix <- suffix + 1L
        candidate <- paste0(old, suffix)
      }
      xml2::xml_attr(nodes[[i]], "id") <- candidate
      anchors <- xml2::xml_find_all(nodes[[i]], ".//a[@href]")
      self <- xml2::xml_attr(anchors, "href") == paste0("#", old)
      xml2::xml_attr(anchors[self], "href") <- paste0("#", candidate)
      used <- c(used, candidate)
      changed <- changed + 1L
    }
    xml2::write_html(page, path)
  }
  invisible(changed)
}

repair_duplicate_argument_anchors(site_dir)
