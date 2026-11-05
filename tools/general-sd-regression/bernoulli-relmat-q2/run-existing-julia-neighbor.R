# Execute only the existing q1 probit/cloglog relmat test block. The original
# test source is parsed, selected by its exact title, and left untouched.
pkgload::load_all(".", quiet = TRUE)
source_file <- "tests/testthat/test-binomial-relmat-sd.R"
expressions <- parse(source_file)
title <- "Binomial relmat SD regression supports probit and cloglog links"
selected <- Filter(function(expr) {
  is.call(expr) && identical(as.character(expr[[1L]]), "test_that") &&
    identical(as.character(expr[[2L]]), title)
}, as.list(expressions))
stopifnot(length(selected) == 1L)
fixture <- expressions[[1L]]
stopifnot(is.call(fixture), identical(as.character(fixture[[2L]]),
                                   "binomial_relmat_sd_fixture"))
test_source <- file.path(
  "tools/general-sd-regression/bernoulli-relmat-q2",
  "selected-existing-julia-neighbor.R"
)
writeLines(c(deparse(fixture, width.cutoff = 500L), "",
             deparse(selected[[1L]], width.cutoff = 500L)), test_source)
cat("Selected source:", source_file, "\n")
cat("Selected title:", title, "\n")
cat("Julia source:", normalizePath(Sys.getenv("DRMODELS_JL_PATH")), "\n")
print(tools::md5sum(c(
  "src/drmTMB.so",
  getLoadedDLLs()[["drmTMB"]][["path"]]
)))
testthat::test_file(test_source, reporter = "summary")
