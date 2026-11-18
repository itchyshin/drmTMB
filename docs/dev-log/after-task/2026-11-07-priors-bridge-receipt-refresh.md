# After task: phylogenetic bridge receipt refresh

## Goal and scope

Refresh the current-source receipt for one existing Gaussian phylogenetic location-scale-scale fixture after `R/methods.R` changed. The model equations, API, examples and package behavior did not change.

## Evidence and checks

On Totoro, R source `623eed27b37d53dab4af56564f1e87624929d40e` and Julia source `f940fc4042ee2832c3343f7d334e830a96942f1b` passed all eight fixture checks. The receipt checker accepted the result and rejected 12 altered receipts. Labels, data, permutation, tree and group covariate matched the historical fixture. The runner recorded unchanged source hashes and the loaded native DLL hash. Logs and checksums are in `docs/dev-log/priors-receipt-refresh-20261107/`.

The local CI-equivalent receipt check passed for 66 R files and the runner. It reported 115 Julia entries unverified because `DRM_JL_PATH` was unset locally; the Totoro checker used the pinned Julia checkout. A direct local checker invocation failed because the recorded Totoro source path does not exist on the Mac. The original receipt is preserved byte-for-byte as `current-before-20261107.json`, and the historical checksum manifest passes with that filename.

## Limitations and next action

The first incremental Git bundle transfer failed before any fit; the full bundle succeeded. This fixture is not evidence of broad parity or interval calibration. No package-wide test, release check or public deployment was performed. Review this evidence and the current main source before integration; refresh again if either source changes. No GitHub issue was changed because this is a receipt refresh for an existing CI failure.
