#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
outputs <- if (length(args) >= 1L) {
  args
} else {
  c(
    file.path("docs", "dev-log", "dashboard", "julia-capabilities.tsv"),
    file.path("inst", "extdata", "julia-capabilities.tsv")
  )
}

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("pkgload is required to load the development package.", call. = FALSE)
}

pkgload::load_all(".", quiet = TRUE)
capabilities <- drmTMB:::drm_julia_capability_comparison()

for (output in outputs) {
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(
    capabilities,
    file = output,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )

  message(
    "wrote ",
    nrow(capabilities),
    " Julia capability rows to ",
    output
  )
}
