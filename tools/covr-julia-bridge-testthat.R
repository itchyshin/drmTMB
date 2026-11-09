library(testthat)
library(drmTMB)

# Julia bridge coverage lane: explicit allowlist (tools/covr-julia-bridge-include.txt).
# Parity-paused: no *-parity.R, no dual-engine estimate comparison files, and no
# *-bridge.R that fits native TMB for comparison. Repository CI plants this driver
# over the installed tests/testthat.R.

not_cran <- isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false")))
if (!not_cran) {
  stop("Julia bridge coverage requires NOT_CRAN=true", call. = FALSE)
}
if (!identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true")) {
  stop("Julia bridge coverage requires DRMTMB_JULIA_TESTS=true", call. = FALSE)
}

include_path <- Sys.getenv(
  "DRMTMB_COVERAGE_JULIA_INCLUDE",
  "tools/covr-julia-bridge-include.txt"
)
if (!file.exists(include_path)) {
  stop("Julia bridge include list missing: ", include_path, call. = FALSE)
}
raw <- readLines(include_path, warn = FALSE)
stems <- raw[!grepl("^\\s*#", raw) & nzchar(trimws(raw))]
stems <- trimws(stems)
if (length(stems) < 1L) {
  stop("Julia bridge include list is empty: ", include_path, call. = FALSE)
}

escape_filter_stem <- function(x) {
  gsub("([^A-Za-z0-9_])", "\\\\\\1", x, perl = TRUE)
}
julia_filter <- paste0(
  "^(",
  paste(vapply(stems, escape_filter_stem, character(1L)), collapse = "|"),
  ")$"
)
cat(sprintf("julia_bridge_include_count=%d\n", length(stems)))
cat(sprintf("julia_bridge_filter=%s\n", julia_filter))

test_check("drmTMB", filter = julia_filter)
