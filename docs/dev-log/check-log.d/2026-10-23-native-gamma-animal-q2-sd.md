# Native Gamma animal q2 SD regression verification

- Candidate branch: `codex/general-sd-regression`.
- Candidate HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`.
- Local ref relation at verification: candidate is 6 commits ahead and 245 behind `origin/main`.
- Command: `TMPDIR=/tmp/codex-gamma-q2-test Rscript -e "devtools::test(filter = 'gamma-animal-pedigree-sd-regression')"`.
- Result: 37 passed, 0 failed, 0 warnings, 0 skipped; 28.4 seconds. The filter matched the Gamma animal pedigree SD test.
- The independent synthetic fixture tests separate intercept and slope SD predictors, coefficient recovery, group-keyed predictions, simulation and save/reload, constant-SD equivalence, ambiguous/duplicate selector errors, and slope-scale identifiability refusals.
- The first run used the default R temporary directory and emitted five testthat formatting warnings after all assertions passed. The repeat with the isolated `TMPDIR` completed without warnings.
- SHA-256: `R/drmTMB.R` `2114394bb74528a003e5f699c515bfda12be1822401b4d066db6d19ef2f628cd`; `src/drmTMB.cpp` `bf4b30d9cb2774133b51b3f183d2b454933cbb9a47ae6450d187f8b08169fc19`; test `39667eca4dfe8b2745d5c89b7e3073f8cf60269f8debf33a4a76308980e15cca`.
- This is native candidate verification only. It does not establish current-main integration, cross-engine covariance-scale parity, package-wide checks, or uncertainty calibration, and it does not close a programme gate.
