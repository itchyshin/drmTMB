## 1. Goal

Close two review gaps: (1) slope-only structured SD for Poisson and NB2 with missing responses, and (2) fixtures that use unit-diagonal K and so cannot detect an accidental K-to-correlation conversion.

## 2. Implemented

Test-only. New file `tests/testthat/test-structured-sd-nonunit-k-and-missing.R`. No source change and no patch file, because the probe showed no source change is needed for gap (1).

Gap 1 finding: under `miss_control(response = "include")`, slope-only structured SD is already refused for both families on all seven routes probed (animal with A, Ainv and pedigree; relmat with K and Q; phylo; spatial). Poisson fails with "requires a non-inflated model with complete responses"; NB2 fails with "requires complete data". So there is no included-NA fit to compare with a complete-case fit. The tests pin these refusals. They also check that the default drop policy gives the same log-likelihood and `nobs` as removing the missing rows by hand (relmat K, both families).

Gap 2: non-unit-diagonal K checks with a dense oracle built from the unconverted K.
- NB2 relmat intercept, K and Q, with 1.7 times a Toeplitz kernel (diag 1.7, odd/even row interleave): Laplace oracle.
- Gaussian relmat intercept, K and Q, same kernel: exact marginal oracle.
- Binomial animal, A and Ainv, same kernel: Laplace oracle.
- Binomial animal pedigree with inbreeding (eight families, three offspring of a full-sib mating each, F = 0.25): the diagonal 1.25 and one off-diagonal 0.75 are pinned by hand, then a Laplace oracle.
Each fit is also compared with the same oracle built from cov2cor(K); the two must differ by more than 0.05, which shows the check can fail under a correlation conversion.

## 3. Decisions

Tolerances fixed before the first run: Laplace oracle 1e-4 absolute; Gaussian exact oracle 1e-6 absolute; K vs Q and A vs Ainv 1e-4 relative; correlation sensitivity gap above 0.05; drop vs manual complete-case 1e-8 relative. None changed after running. All tests passed on the first run, so there was no red phase and no tolerance was touched.

## 4. Files Touched

- `tests/testthat/test-structured-sd-nonunit-k-and-missing.R` (new)
- this note (new)

## 5. Checks Run

`NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1`, `pkgload::load_all()` then `testthat::test_file()` on the new file: 6 tests, 53 expectations, 0 failures, 0 skips, about 12 s.

## 6. Not Claimed

Oracles are evaluated at the fitted parameters, so they check the likelihood surface and not that the optimiser found the maximum. The pedigree oracle uses `drm_pedigree_additive_relationship`, the helper under test, with only its inbreeding entries pinned by hand. No recovery, coverage, calibration or Julia parity claim. Not covered: non-unit K for slope terms, phylo or spatial providers, Poisson, Gamma or other families, Q or Ainv for the inbred pedigree, and `se = TRUE` inference. Missing responses are only shown to be refused for slope-only routes; intercept routes and other families were not probed. Nothing committed; ledger not touched.
