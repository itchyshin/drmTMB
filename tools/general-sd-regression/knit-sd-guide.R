# Run with one isolated native library and a bounded outer supervisor.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) stop("Supply LIBRARY INPUT_RMD NEW_OUTPUT_MD")
if (file.exists(args[[3L]])) stop("Refusing to overwrite knitted guide")
.libPaths(c(normalizePath(args[[1L]], mustWork = TRUE), .libPaths()))
library(drmTMB)
if (!identical(normalizePath(find.package("drmTMB")),
               normalizePath(file.path(args[[1L]], "drmTMB")))) {
  stop("Loaded a different drmTMB library")
}
knitr::knit(args[[2L]], output = args[[3L]], envir = new.env(), quiet = FALSE)
cat("SD_GUIDE_KNIT_PASS\n")
