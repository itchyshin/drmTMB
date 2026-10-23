suppressMessages(devtools::load_all(".", quiet = TRUE))
files <- c(
  "test-check-drm.R",
  "test-coevolution-accessors.R", "test-coefficient-labels.R",
  "test-julia-bridge-coef-labels.R", "test-julia-bridge.R",
  "test-julia-conditional-prediction.R", "test-julia-diagnostics.R",
  "test-julia-inference.R", "test-julia-objective-at-bridge.R",
  "test-julia-phylo-q4-corpairs.R", "test-julia-structured-inference.R",
  "test-julia-sigma-phylo-reml.R", "test-profile-targets-julia.R",
  "test-xfam-bridge.R", "test-julia-bridge-summary.R", "test-julia-joint-methods.R"
)
tot_f <- 0L; tot_p <- 0L; tot_s <- 0L
for (f in files) {
  path <- file.path("tests/testthat", f)
  if (!file.exists(path)) { cat("MISSING", f, "\n"); next }
  r <- testthat::test_file(path, reporter = "silent")
  df <- as.data.frame(r)
  fl <- sum(df$failed); er <- sum(df$error); pa <- sum(df$passed); sk <- sum(df$skipped)
  tot_f <- tot_f + fl + er; tot_p <- tot_p + pa; tot_s <- tot_s + sk
  cat(sprintf("%-40s pass=%4d fail=%d error=%d skip=%d\n", f, pa, fl, er, sk))
}
cat(sprintf("TOTAL pass=%d failures+errors=%d skipped=%d\n", tot_p, tot_f, tot_s))
if (tot_f == 0L) cat("NEIGHBOURS_OK\n") else cat("NEIGHBOURS_FAILED\n")
