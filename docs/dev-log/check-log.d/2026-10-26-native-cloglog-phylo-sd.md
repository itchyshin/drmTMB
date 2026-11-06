# Native cloglog phylogenetic SD recovery smoke, 2026-10-26

Added `tests/testthat/test-binomial-cloglog-phylo-sd-regression.R`. The focused test passed 14 expectations in three recorded runs. The retained run exited 0; hashes for the test, R builder, TMB likelihood, and DESCRIPTION matched before and after. It checks prediction after shuffling requested new-data tip rows.

Evidence: `docs/dev-log/general-sd-regression/evidence/native-cloglog-phylo-sd-20261026/`.
Report: `docs/dev-log/after-task/2026-10-26-native-cloglog-phylo-sd.md`.

The test checks a single seeded native TMB Bernoulli cloglog phylogenetic random-intercept SD fit, fitted-row and shuffled new-data predictions, and constant-SD equivalence. Its recovery tolerance is broad. No coverage or Julia-parity claim follows from this run.
