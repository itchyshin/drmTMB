#!/usr/bin/env Rscript

site_dir <- commandArgs(trailingOnly = TRUE)
site_dir <- if (length(site_dir) == 0L) "pkgdown-site" else site_dir[[1L]]

if (!dir.exists(site_dir)) {
  stop("pkgdown site directory does not exist: ", site_dir, call. = FALSE)
}

reference_alt <- c(
  "plot_corpairs-1.png" = paste(
    "Confidence Eye plot of fitted correlation-pair summaries.",
    "Rows show residual, group, phylogenetic, and scale-block correlations;",
    "pale regions are finite 95 percent profile intervals and hollow circles",
    "are point estimates."
  ),
  "plot_parameter_surface-1.png" = paste(
    "Faceted fitted distributional-parameter surfaces for mu and sigma.",
    "Lines show response-scale estimates over x and ribbons show finite Wald",
    "confidence intervals from the prediction table."
  )
)

escape_regex <- function(x) {
  gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)
}

replace_reference_alt <- function(html, src, alt) {
  pattern <- paste0(
    "(<img[^>]*src=\"",
    escape_regex(src),
    "\"[^>]*alt=\")(\"[^>]*>)"
  )
  gsub(pattern, paste0("\\1", alt, "\\2"), html)
}

html_files <- list.files(
  site_dir,
  pattern = "[.]html$",
  recursive = TRUE,
  full.names = TRUE
)
found_alt <- setNames(
  logical(length(reference_alt)),
  names(reference_alt)
)

for (html_file in html_files) {
  html <- readLines(html_file, warn = FALSE, encoding = "UTF-8")
  fixed <- html
  for (src in names(reference_alt)) {
    fixed <- replace_reference_alt(fixed, src, reference_alt[[src]])
    expected <- paste0(
      "src=\"",
      escape_regex(src),
      "\"[^>]*alt=\"",
      escape_regex(reference_alt[[src]]),
      "\""
    )
    found_alt[[src]] <- found_alt[[src]] || any(grepl(expected, fixed))
  }
  if (!identical(html, fixed)) {
    writeLines(fixed, html_file, useBytes = TRUE)
  }
}

missing <- names(found_alt)[!found_alt]
if (length(missing) > 0L) {
  stop(
    "No reference image alt text found for: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}
