site_dir <- commandArgs(trailingOnly = TRUE)
site_dir <- if (length(site_dir) == 0L) "pkgdown-site" else site_dir[[1L]]

if (!dir.exists(site_dir)) {
  stop("pkgdown site directory does not exist: ", site_dir, call. = FALSE)
}

html_files <- list.files(site_dir, pattern = "[.]html$", recursive = TRUE,
                         full.names = TRUE)
for (html_file in html_files) {
  html <- readLines(html_file, warn = FALSE, encoding = "UTF-8")
  fixed <- gsub('type="”image/svg+xml”"', 'type="image/svg+xml"', html,
                fixed = TRUE)
  if (!identical(html, fixed)) {
    writeLines(fixed, html_file, useBytes = TRUE)
  }
}
