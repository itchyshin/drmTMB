# Check log: Native Binomial correlated q3 SD under probit and cloglog

- Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-correlated-q3-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'`.
- Result: exit 0; 18 expectations passed, 0 failures, 0 warnings, 0 skips.
- Two fixed-seed synthetic fits checked convergence, finite q3 correlations, broad recovery bounds for all three SD slopes, group-level prediction consistency, and binary simulation.
- Source hashes and the console transcript are in `docs/dev-log/general-sd-regression/evidence/native-binomial-correlated-q3-nonlogit-20261028/`.
- Evidence reconciliation passed: 155 linked / 19,678 candidate rows / 175 receipt records. The six probit/cloglog q3 target rows link to the receipt and remain unreviewed.
- `Rscript ~/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-10-28-native-binomial-correlated-q3-nonlogit-sd.md`: structure check passed; aggregate acceptance gate is UNKNOWN because its runner is unavailable.
- `python3 ~/shinichi-brain/tools/slop_check.py` on the after-task report: 0 findings.
- Python trailing-whitespace scan over the test, evidence files, ledger, summary, report, and check log: passed.
- No full R suite, Julia parity run, package check, or interval-coverage run was performed.
