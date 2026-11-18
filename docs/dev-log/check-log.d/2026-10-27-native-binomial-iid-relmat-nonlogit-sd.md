# Check log: Native Binomial iid plus relmat SD regression

- Initial package-level reproduction: `devtools::test(filter = "binomial-iid-relmat-kernel-equivalence-nonlogit-sd", reporter = "summary")` reproduced the validation error rejecting ordinary effects alongside `relmat()`.
- Focused post-change run: same command; exit 0, 21 expectations passed, 0 failures, 0 warnings, 0 skips.
- Scope: probit and cloglog; same synthetic outcomes fitted with covariance K and precision Q. Checks convergence, broad recovery for both SD slopes, likelihood and coefficient equivalence, and named group/population SD predictions.
- Evidence: `docs/dev-log/general-sd-regression/evidence/native-binomial-iid-relmat-kernel-nonlogit-20261027/`.
- Reconciliation: passed at 143 linked / 19,678 candidate rows / 165 evidence records. Four new rows remain unreviewed.
- Not run: full R suite, live Julia bridge, full pkgdown build, coverage calibration.
