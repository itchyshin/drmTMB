# Check log: Binomial correlated q=4 non-logit SD regression

- Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-correlated-q4-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'`
- Corrected captured run: exit 0; 32 expectations passed across probit and cloglog.
- Initial failed run: probit fit converged but Hessian was not positive definite; harness then errored on unsupported `expect_length(info=)`.
- Second failed run: harness errored on unsupported `expect_type(info=)`.
- Signature check: testthat 3.3.2 supports `info` for `expect_identical`, `expect_true`, and `expect_equal`, but not for `expect_type`, `expect_length`, or `expect_lt`.
- Source manifest: five files hashed before the corrected run; all matched afterward.
- Evidence reconciliation: passed at 139 linked rows / 19,678 candidate rows / 161 evidence records. Four rows are linked for q=4 probit/cloglog, each remaining unreviewed.
- After-task structure, prose, and targeted whitespace checks were completed. The acceptance gate remains UNKNOWN because its runner is unavailable.
- No full suite, pkgdown build, live Julia engine, bootstrap, profile, or interval calibration was run.
