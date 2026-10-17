# Run R-only assembly checks against this source, without substituting an
# installed package's model builders or claiming compiled likelihood evidence.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Supply one test file")
library(testthat)
library(drmTMB)
test_env <- new.env(parent = asNamespace("drmTMB"))
for (path in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  sys.source(path, envir = test_env)
}
sys.source("tests/testthat/helper-binomial-sd-regression.R", envir = test_env)
testthat::test_file(args[[1L]], reporter = "summary", env = test_env,
                    stop_on_failure = TRUE)
cat("SOURCE_ASSEMBLY_PASS\n")
