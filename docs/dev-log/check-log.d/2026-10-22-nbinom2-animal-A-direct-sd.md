# Check log: NB2 animal supplied-covariance SD regression

The focused NB2 animal SD regression file passed, including a new comparison of a supplied covariance matrix with the equivalent pedigree input. The comparison checks convergence, coefficient agreement, likelihood agreement, and group-name-keyed SD predictions.

Command:

```sh
NOT_CRAN=true Rscript -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-nbinom2-animal-sd-regression.R")'
```

Result: `FAIL 0 | WARN 0 | SKIP 0 | PASS 16`. This is one synthetic NB2 location animal-intercept fixture and a provider-equivalence check. It is not a cross-engine comparison, interval-calibration result, or evidence for other NB2 random-effect shapes.

Source binding at completion:

| Item | Value |
|---|---|
| Native candidate HEAD | `425bee81572c625a634b2b083050c5c57c1dc1f1` |
| Julia candidate HEAD | `70dbf564eb670144c63c08f61ea099084d95add2` |
| `tests/testthat/test-nbinom2-animal-sd-regression.R` SHA-256 | `c46077ecd868e4c7161802914001a28693c5c8d5795043187aa676c9138faf71` |
| `R/drmTMB.R` SHA-256 | `25a1b4bf188c1c0d453599bdceccd91714d19f890342521be6c8cff6537513c5` |
| `src/drmTMB.cpp` SHA-256 | `3e2f5f7a970f13e2241db38259166b130b71f751b09cfc5a92b15014f537c821` |

Both candidate worktrees contain unrelated uncommitted changes. The test ran against the shared native worktree; source hashes identify the relevant test and production files, but this receipt does not replace a full candidate-source manifest.
