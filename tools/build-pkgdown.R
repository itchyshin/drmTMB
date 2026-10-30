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

fail_on_install_warning <- function(warning) {
  message <- conditionMessage(warning)
  if (grepl("installation of package", message, fixed = TRUE) &&
      grepl("non-zero exit status", message, fixed = TRUE)) {
    stop("pkgdown package installation failed: ", message, call. = FALSE)
  }
}

withCallingHandlers(
  pkgdown::build_site(
    pkg = stage_dir,
    override = list(destination = site_dir),
    devel = FALSE,
    new_process = TRUE,
    install = TRUE,
    quiet = FALSE
  ),
  warning = fail_on_install_warning
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

# Configure MathJax before loading it; loading first overwrites its runtime
# when the inline config assigns window.MathJax and breaks lazy extensions.
repair_mathjax_order_text <- function(text) {
  pattern <- "(?s)<script\\b[^>]*>.*?</script\\s*>"
  count_marker <- function(pattern) {
    matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
    if (identical(matches[[1L]], -1L)) 0L else length(matches)
  }
  loader_markers <- count_marker("tex-mml-chtml\\.js")
  config_markers <- count_marker("window\\s*\\.\\s*MathJax\\s*=")
  positions <- gregexpr(pattern, text, perl = TRUE)[[1L]]
  if (identical(positions[[1L]], -1L)) {
    if (loader_markers || config_markers) {
      stop("Malformed MathJax loader/config markup; refusing to rewrite.", call. = FALSE)
    }
    return(text)
  }
  lengths <- attr(positions, "match.length")
  scripts <- regmatches(text, list(positions))[[1L]]
  loader <- which(grepl("(?i)<script\\b[^>]*\\bsrc=[\"'][^\"']*tex-mml-chtml\\.js(?:\\?[^\"']*)?[\"']", scripts, perl = TRUE))
  config <- which(grepl("window\\s*\\.\\s*MathJax\\s*=", scripts, perl = TRUE))
  if (loader_markers != length(loader) || config_markers != length(config)) {
    stop("Malformed MathJax loader/config markup; refusing to rewrite.", call. = FALSE)
  }
  if (!length(loader) && !length(config)) return(text)
  if (length(loader) != 1L || length(config) != 1L || loader == config) {
    stop("Ambiguous MathJax loader/config scripts; refusing to rewrite.", call. = FALSE)
  }
  if (grepl("(?i)<script\\b[^>]*\\bsrc\\s*=", scripts[[config]], perl = TRUE)) {
    stop("MathJax configuration is not an inline script.", call. = FALSE)
  }
  if (positions[[config]] < positions[[loader]]) return(text)
  loader_end <- positions[[loader]] + lengths[[loader]] - 1L
  gap <- substr(text, loader_end + 1L, positions[[config]] - 1L)
  if (nzchar(trimws(gap))) {
    stop("Unexpected content between MathJax loader and config; refusing to reorder.", call. = FALSE)
  }
  config_end <- positions[[config]] + lengths[[config]] - 1L
  paste0(substr(text, 1L, positions[[loader]] - 1L), scripts[[config]],
         substr(text, positions[[loader]], positions[[config]] - 1L),
         substr(text, config_end + 1L, nchar(text)))
}

repair_mathjax_order <- function(site_dir) {
  changed <- 0L
  for (path in list.files(site_dir, pattern = "[.]html$", recursive = TRUE,
                          full.names = TRUE)) {
    bytes <- readBin(path, "raw", n = file.info(path)$size)
    before <- rawToChar(bytes)
    after <- repair_mathjax_order_text(before)
    if (!identical(before, after)) {
      writeBin(charToRaw(after), path)
      changed <- changed + 1L
    }
  }
  invisible(changed)
}

repair_mathjax_order(site_dir)


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
