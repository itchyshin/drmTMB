# 2026-10-20: Independent marginal-likelihood oracle runs

- `Rscript -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-tweedie-sd-marginal-oracle.R")'` passed all 3 checks. This run includes one simulated Tweedie random-intercept SD fit, groupwise scalar quadrature with the compound Tweedie density reference, and a reversed-group-SD mapping control.
- The same command pattern for `tests/testthat/test-cumulative-logit-sd-slope-integration.R` passed all 3 checks, including exact groupwise integration and a reversed-group-SD mapping control.
- The first direct `testthat::test_file()` attempt failed because `drmTMB()` was not attached. Loading the worktree package before the rerun made the test exercise the intended code path.
- Scope: two synthetic numerical oracle cases. These checks support likelihood and indexing behavior for these routes only. They do not establish interval coverage, broad recovery, or Julia parity.
