# Source the current package helpers and assembly test, then replace only the
# builder file with the exact R/drmTMB.R bytes recovered from the frozen capsule.
library(testthat)
library(drmTMB)
test_env <- new.env(parent = asNamespace("drmTMB"))
for (path in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  sys.source(path, envir = test_env)
}
sys.source("tests/testthat/helper-binomial-sd-regression.R", envir = test_env)
sys.source("tests/testthat/helper-poisson-sd-regression.R", envir = test_env)
sys.source("docs/dev-log/general-sd-regression/evidence/poisson-label-20261017/fence-negative-control/old-source/R/drmTMB.R",
           envir = test_env)
testthat::test_file("tests/testthat/test-poisson-sd-assembly.R",
                    reporter = "summary", env = test_env,
                    stop_on_failure = FALSE)
