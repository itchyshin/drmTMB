# Remove internal-only pages from the built pkgdown site before deploy.
#
# pkgdown renders every root-level *.md file (pkgdown:::package_mds()) except a
# small hardcoded skip-list, so internal coordination files such as AGENTS.md
# and CLAUDE.md are published as public pages. They must stay at the repository
# root for the tools that read them (Codex -> AGENTS.md, Claude Code ->
# CLAUDE.md), so the rendered HTML is stripped here instead of moving or
# renaming the sources. .Rbuildignore does not help, because pkgdown globs the
# source tree directly rather than the built tarball.

site_dir <- commandArgs(trailingOnly = TRUE)
site_dir <- if (length(site_dir) == 0L) "pkgdown-site" else site_dir[[1L]]

if (!dir.exists(site_dir)) {
  stop("pkgdown site directory does not exist: ", site_dir, call. = FALSE)
}

internal_pages <- c("AGENTS.html", "CLAUDE.html")

# 1. Delete the rendered HTML pages.
for (page in internal_pages) {
  path <- file.path(site_dir, page)
  if (file.exists(path)) {
    unlink(path)
    message("removed ", path)
  }
}

# 2. Drop the pages from sitemap.xml so search engines stop indexing them.
sitemap <- file.path(site_dir, "sitemap.xml")
if (file.exists(sitemap)) {
  xml <- paste(readLines(sitemap, warn = FALSE, encoding = "UTF-8"),
               collapse = "\n")
  for (page in internal_pages) {
    pattern <- paste0("<url>\\s*<loc>[^<]*/", page, "</loc>\\s*</url>")
    xml <- gsub(pattern, "", xml, perl = TRUE)
  }
  writeLines(xml, sitemap, useBytes = TRUE)
  message("cleaned ", sitemap)
}

# 3. Drop the pages from the site search index. Only touch the expected
# array-of-entries shape; leave anything else untouched rather than risk
# corrupting the index.
search <- file.path(site_dir, "search.json")
if (file.exists(search)) {
  index <- jsonlite::fromJSON(search, simplifyVector = FALSE)
  if (is.list(index) && is.null(names(index))) {
    keep <- Filter(function(entry) {
      url <- entry[["path"]]
      if (is.null(url) || length(url) != 1L || is.na(url)) {
        return(TRUE)
      }
      url <- sub("[#?].*$", "", url)
      !any(endsWith(url, internal_pages))
    }, index)
    jsonlite::write_json(keep, search, auto_unbox = TRUE, null = "null")
    message("cleaned ", search, " (", length(index) - length(keep),
            " entries removed)")
  } else {
    message("search.json shape unexpected; left unchanged")
  }
}
