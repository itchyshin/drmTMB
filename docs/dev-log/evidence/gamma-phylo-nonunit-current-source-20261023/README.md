# Current-source Gamma phylogenetic SD parity

This rerun exercises the existing non-unit-height Gamma phylogenetic SD bridge test against the current paired candidates. It passed 6 assertions with exit code 0 and one live Julia bridge test. The test compared the same synthetic data and tree through native TMB and Julia, including the coefficient and tip-level SD predictions.

Julia retained raw branch-length scaling and reported that the tree's maximum tip height was 6.404475. The check is one same-data fixture, not an interval-calibration study, a recovery study, or proof of general structured-effect parity. The current-source hashes and exact command are in `source-manifest.md`; the captured console is `test-console.log`.
