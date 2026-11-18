# After Task: Bernoulli local route verification

## 1. Goal

Re-run bounded local tests that exercise the Bernoulli predictor-dependent random-effect SD route, including the ordinary-plus-phylogenetic combination, independent likelihood comparison, and simulation outputs.

## 2. Implemented

Completed a verification checkpoint on the current dirty `codex/general-sd-regression` worktree. No implementation files were changed in this checkpoint.

## 3a. Decisions and Rejected Alternatives

The ordinary-plus-phylogenetic Bernoulli combination remains in scope for this route. The tests intentionally fit it with and without SD formulas and compare constant-SD likelihoods with the existing constant-scale fit. The integration filter also ran the adjacent beta-binomial SD test, so its result is recorded separately from the Bernoulli claim.

## 4. Files Touched

- Added `docs/dev-log/check-log.d/2026-10-20-bernoulli-local-route-verification.md`.
- Added this verification report and its separate naturalness assessment record.
- No source, test, or public documentation file was edited.

## 5. Checks Run

- `devtools::test(filter = "binomial-ordinary-phylo-sd")`: 18 passed, 0 failed, 0 warnings; 35.9 seconds.
- `devtools::test(filter = "binomial-sd-simulation")`: 15 passed, 0 failed, 0 warnings; 3.5 seconds.
- `devtools::test(filter = "binomial-sd-integration")`: 381 passed across Bernoulli and beta-binomial contexts, 0 failed, 0 warnings; 301.7 seconds.
- `devtools::test(filter = "binomial-phylo-sd-simulation")`: 11 passed, 0 failed, 0 warnings; 1.8 seconds.
- `DRM_JL_PATH=<paired Julia worktree> DRMTMB_JULIA_TESTS=true devtools::test(filter = "julia-binomial-phylo-sd")`: 31 passed, 0 failed, 0 test warnings; 34.9 seconds. One live Julia test ran through JuliaCall against the paired `codex/general-sd-regression` checkout at `70dbf564e`. The output included the expected raw branch-length scale notice for `sd_phylo` on a tree with maximum tip height 2.5.
- All commands pinned numerical thread counts to one. The Julia result is a focused bridge smoke test, not full cross-engine parity.

## 6. Tests of the Tests

The Bernoulli integration test compares the fitted objective with an independent scalar-cluster Laplace calculation and verifies that a deliberately wrong SD-slope sign changes the oracle result. The structured simulation test compares fitted covariance and simulated latent contributions with independently assembled reference values. These are meaningful numerical checks beyond checking only that fits return.

## 7a. Issue Ledger

No issue was changed. This checkpoint verifies an already implemented route and does not create a new product claim. The broader SD-regression feature issue remains attached to the existing implementation lane.

## 8. Consistency Audit

The tests cover ordinary Bernoulli effects, predictor-dependent SDs, and a phylogenetic SD target. They establish fitting, point recovery in synthetic fixtures, simulation, profiling smoke behavior, and stored-fit behavior for these selected routes. The bootstrap test uses only two refits and is not evidence of interval coverage.

## 9. What Did Not Go Smoothly

The first anchored `devtools::test()` filter matched no contexts because the filter targets context names. The unanchored `binomial-sd-integration` filter selected both Bernoulli and beta-binomial contexts; both completed successfully. The combined run took 301.7 seconds, slightly beyond the five-minute estimate.

## 10. Known Residuals

This is local smoke and oracle evidence. It does not establish calibrated uncertainty, 1,000-replicate recovery, every structured or crossed effect, all distribution families, full Julia runtime parity, or an all-platform package check.

## 11. Team Learning

For targeted `devtools::test()` calls, filter by test context name rather than anchoring to a test filename. Record neighboring contexts selected by a substring filter so denominators remain clear.

## 12. Cross-Product Coverage

This checkpoint covers one live Julia Bernoulli phylogenetic bridge test. It does NOT cover DRAC or Totoro campaigns, the full family-by-effect capability inventory, broad cross-engine parity, or calibrated coverage for SD coefficients and SD contrasts. Those remain required for the approved feature goal.
