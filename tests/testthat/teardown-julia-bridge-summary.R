# Issue #1081 option 1: print the Julia-bridge boundary once the whole test
# run has finished, so a green run states its own limits instead of a mock-
# only pass looking identical to a bridge-exercised pass. testthat sources
# teardown-*.R files after all test-*.R files, in the same test_env() as the
# helper- and setup- files, so the counters populated by drm_skip_live_julia()
# are visible here regardless of which reporter or entry point (devtools::
# test(), R CMD check, test_check()) drove the run.
message(drm_julia_bridge_summary_line())
