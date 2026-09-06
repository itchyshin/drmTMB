# G2 RED CONTROL. Measures the SAME mocked fit -- a bridge fit whose
# covariance came back wholly non-finite -- through origin/main's
# check_drm.drmTMB_julia() and through this branch's, and restores
# R/julia-diagnostics.R byte-identically (sha256 asserted).
path <- "R/julia-diagnostics.R"
sha <- function(p) {
  as.character(tools::md5sum(p))
}
keep <- readBin(path, "raw", file.size(path))
before_md5 <- sha(path)
restore <- function() {
  writeBin(keep, path)
}
on.exit(restore(), add = TRUE)
main_version <- system2(
  "git", c("show", "origin/main:R/julia-diagnostics.R"), stdout = TRUE
)
writeLines(main_version, path)
out_before <- system2(
  "Rscript", c("tools-scratch/red-covariance-probe.R", "BEFORE"),
  stdout = TRUE, stderr = FALSE
)
restore()
stopifnot(identical(sha(path), before_md5))
out_after <- system2(
  "Rscript", c("tools-scratch/red-covariance-probe.R", "AFTER"),
  stdout = TRUE, stderr = FALSE
)
cat(grep("^BEFORE ", out_before, value = TRUE), sep = "\n")
cat(grep("^AFTER ", out_after, value = TRUE), sep = "\n")
cat("RESTORED_IDENTICAL md5=", sha(path), "\n", sep = "")
