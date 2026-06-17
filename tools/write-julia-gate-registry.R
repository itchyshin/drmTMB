#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
outputs <- if (length(args) >= 1L) {
  args
} else {
  c(
    file.path("docs", "dev-log", "dashboard", "julia-gates.tsv"),
    file.path("inst", "extdata", "julia-gates.tsv")
  )
}

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("pkgload is required to load the development package.", call. = FALSE)
}

pkgload::load_all(".", quiet = TRUE)
gates <- drmTMB:::drm_julia_intentional_gates()

for (output in outputs) {
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(
    gates,
    file = output,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )

  message("wrote ", nrow(gates), " Julia bridge gate rows to ", output)
}
