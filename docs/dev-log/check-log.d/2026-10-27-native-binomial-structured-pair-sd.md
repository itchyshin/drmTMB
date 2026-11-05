# Native Binomial structured-pair SD regression

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-spatial-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0. The focused test file passed 60 expectations, including
logit/probit/cloglog fits for the phylogenetic-spatial pair and a logit fit for
the animal-relatedness and animal-spatial pairs. No failures or warnings.
The exact output is retained in
`docs/dev-log/general-sd-regression/evidence/native-binomial-structured-pair-sd-20261027/focused-tests.log`.

The hash-checked evidence reconciliation passed with 19,678 candidate rows, 95
linked rows, 19,583 unlinked rows, and 117 evidence records. The denominator
includes the newly implemented animal plus coordinate-spatial candidate pair,
expanded across the finite family, link, endpoint, and engine table. The
universe generator unit suite (`python3 tools/general-sd-regression/tests/test_universe.py`) passed all 21 tests. Scoped `git diff --check` passed for the slice. The workspace-wide diff check reports a trailing blank line at `tests/testthat/test-binomial-sd-integration.R:225`; that file contains other ongoing edits and was left untouched. The report structure check passed; its warning says the aggregate acceptance ledger is unknown because its runner dependencies are unavailable. This run supports
point recovery and target-output checks for these exact native q1 provider
pairs. It does not support interval calibration, Julia parity, or broader
family claims.

An adjacent animal/relatedness regression filter was not clean: three Julia
bridge tests skipped because no Julia engine path was configured, and an
existing live Julia fit in `test-binomial-relmat-sd.R` errored when no
`DRMODELS_JL_PATH` was available. Some native expectations ran before the
error. No Julia parity claim is made from that command.

- Current-source rerun after the later Binomial validation change: exit 0, 60 expectations passed; console `docs/dev-log/general-sd-regression/evidence/native-binomial-structured-pair-sd-20261027/current-source-rerun.log`. Refreshed source manifest binds current R, TMB, and test hashes.
- Corrected the existing probit and cloglog evidence records to their matching required-row keys; no evidence IDs were appended.
