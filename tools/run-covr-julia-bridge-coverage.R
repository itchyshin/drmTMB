# Julia-bridge coverage producer for .github/workflows/test-coverage.yaml
# (julia-bridge-coverage job). Mirrors gllvmTMB tools/run-covr-coverage.R:
# refuse FAIL > 0, PASS == 0, or excessive skips before writing cobertura.xml.

fail <- function(...) stop(sprintf(...), call. = FALSE)

install_path <- file.path(
  normalizePath(Sys.getenv("RUNNER_TEMP"), winslash = "/"),
  "package"
)
pkg_root <- normalizePath(Sys.getenv("GITHUB_WORKSPACE", "."), winslash = "/", mustWork = TRUE)
skip_frac_max <- as.numeric(Sys.getenv("DRMTMB_COVERAGE_SKIP_FRAC_MAX", "0.10"))
if (!is.finite(skip_frac_max) || skip_frac_max < 0 || skip_frac_max > 1) {
  fail("DRMTMB_COVERAGE_SKIP_FRAC_MAX must be a fraction in [0, 1]")
}

drmodels_sha <- Sys.getenv("DRMODELS_JL_SHA", "")
if (!nzchar(drmodels_sha)) {
  fail("DRMODELS_JL_SHA must name the resolved DRModels.jl commit")
}
cat(sprintf("drmodels_jl_sha=%s\n", drmodels_sha))

checkout_sha <- system2("git", c("-C", shQuote(pkg_root), "rev-parse", "HEAD"), stdout = TRUE)
cat(sprintf("coverage_commit=%s\n", checkout_sha))
cat(sprintf("lane=julia-bridge\n"))

layout_rc <- system2(
  "bash",
  c("tools/covr-source-tree-layout.sh", install_path, pkg_root)
)
if (!identical(layout_rc, 0L)) fail("failed to plant 00_pkg_src for covr tests")

# CI-only: swap the sharded tests/testthat.R for the Julia allowlist driver
# before covr installs. covr copies tests/ from the source tree; we restore on
# exit so the workspace checkout is unchanged for later steps.
driver <- file.path(pkg_root, "tools", "covr-julia-bridge-testthat.R")
main_testthat <- file.path(pkg_root, "tests", "testthat.R")
bak_testthat <- file.path(pkg_root, "tests", ".testthat.R.covr-julia-bak")
if (!file.exists(driver)) fail("missing Julia covr driver: %s", driver)
if (!file.exists(main_testthat)) fail("missing %s", main_testthat)
if (!file.exists(bak_testthat)) {
  if (!file.copy(main_testthat, bak_testthat)) {
    fail("could not back up %s", main_testthat)
  }
}
if (!file.copy(driver, main_testthat, overwrite = TRUE)) {
  fail("could not plant Julia covr driver over %s", main_testthat)
}
on.exit(
  {
    if (file.exists(bak_testthat)) {
      file.copy(bak_testthat, main_testthat, overwrite = TRUE)
      unlink(bak_testthat)
    }
  },
  add = TRUE
)

cov <- tryCatch(
  covr::package_coverage(
    quiet = FALSE,
    clean = FALSE,
    type = "tests",
    install_path = install_path
  ),
  error = function(e) {
    cat(sprintf("covr_package_coverage_error=%s\n", conditionMessage(e)))
    NULL
  }
)

routs <- list.files(
  install_path,
  pattern = "^testthat\\.Rout",
  recursive = TRUE,
  full.names = TRUE
)
if (length(routs) == 0L) fail("no testthat.Rout* under %s", install_path)

summary_re <- "^\\[ FAIL ([0-9]+) \\| WARN ([0-9]+) \\| SKIP ([0-9]+) \\| PASS ([0-9]+) \\]$"
counts <- c(FAIL = 0L, WARN = 0L, SKIP = 0L, PASS = 0L)
for (rout in sort(routs)) {
  lines <- readLines(rout, warn = FALSE)
  hits <- grep(summary_re, lines, value = TRUE)
  for (line in hits) {
    m <- regexec(summary_re, line)[[1L]]
    if (length(m) != 5L) next
    part <- as.integer(regmatches(line, list(m))[[1L]])[-1L]
    names(part) <- c("FAIL", "WARN", "SKIP", "PASS")
    counts <- counts + part
  }
}
total <- sum(counts)
cat(sprintf(
  "julia_bridge_test_summary=FAIL %d | WARN %d | SKIP %d | PASS %d (total %d)\n",
  counts[["FAIL"]], counts[["WARN"]], counts[["SKIP"]], counts[["PASS"]], total
))
writeLines(
  sprintf(
    "[ FAIL %d | WARN %d | SKIP %d | PASS %d ]",
    counts[["FAIL"]], counts[["WARN"]], counts[["SKIP"]], counts[["PASS"]]
  ),
  "coverage-tests.txt"
)

if (counts[["FAIL"]] > 0L) fail("testthat reported %d failures", counts[["FAIL"]])
if (counts[["PASS"]] == 0L) fail("testthat reported zero passing expectations")
if (total > 0L && counts[["SKIP"]] / total > skip_frac_max) {
  fail(
    "testthat skip rate %.1f%% exceeds DRMTMB_COVERAGE_SKIP_FRAC_MAX=%.0f%% (%d SKIP of %d)",
    100 * counts[["SKIP"]] / total,
    100 * skip_frac_max,
    counts[["SKIP"]],
    total
  )
}

if (is.null(cov)) fail("covr::package_coverage did not return a coverage object")

print(cov)
pct <- covr::percent_coverage(cov)
if (!is.finite(pct) || pct <= 0) fail("covr reported non-positive coverage: %s", pct)
cat(sprintf(
  "julia_bridge_percent_coverage=%.4f (julia-bridge lane; Codecov flag julia-bridge)\n",
  pct
))
writeLines(sprintf("julia_bridge_percent_coverage=%.4f", pct), "coverage-percent.txt")
covr::to_cobertura(cov, filename = "cobertura.xml")
if (!file.exists("cobertura.xml")) fail("cobertura.xml was not written")
