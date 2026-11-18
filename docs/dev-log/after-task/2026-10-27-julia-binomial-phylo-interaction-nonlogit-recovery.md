# After Task: Julia Binomial Phylogenetic-interaction Non-logit Recovery

## 1. Goal

Strengthen the Julia Binomial phylogenetic-interaction intercept test for probit and complementary log-log, then admit only the tested rows in the finite capability universe.

## 2. Implemented

The existing interaction-intercept test now generates link-matched probit and complementary log-log responses from the same synthetic latent predictor. For each link it checks convergence, finite likelihood and coefficients, positive and approximately recovered SD slope, pair-level predicted SDs, and binary simulation. The capability universe admits the two exact Julia rows after the focused test passed.

## 3. Mathematical Contract

For the pair-level latent effect, the log SD follows the SD-formula design: `log(sigma_pair) = Z_pair * alpha`. The fit keeps the existing Kronecker phylogenetic-interaction precision and smooth SD clamp. This test verifies the predictor-dependent scale and output mapping for two link-specific synthetic fits; it does not independently verify the Kronecker covariance algebra.

## 3a. Decisions and Rejected Alternatives

Admit only probit and cloglog for this exact Julia interaction-intercept route. Do not promote the family-level link registry or imply that other structured interactions have equivalent evidence. No covariance reparameterization was made.

## 4. Files Touched

- `../general-sd-julia/test/test_binomial_phylo_interaction_sd.jl`
- `tools/general-sd-regression/universe.py`
- `tools/general-sd-regression/tests/test_universe.py`
- `docs/dev-log/general-sd-regression/required-rows.tsv`
- `docs/dev-log/general-sd-regression/required-universe.md`
- `docs/dev-log/evidence/general-sd-regression/julia-binomial-phylo-interaction-nonlogit-totoro-20261027/`
- `docs/dev-log/check-log.d/2026-10-27-julia-binomial-phylo-interaction-nonlogit-recovery.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/after-task/2026-10-27-julia-binomial-phylo-interaction-nonlogit-recovery.md`

## 5. Checks Run

- Totoro, Julia 1.10.12, one thread: `test/test_binomial_phylo_interaction_sd.jl` passed 47/47 in 21.87 seconds; 107 SHA-256 entries matched the tested snapshot.
- `python3 tools/general-sd-regression/universe.py` regenerated 19,230 rows.
- `python3 -m unittest discover -s tools/general-sd-regression/tests -p 'test_universe.py'` passed 19/19.
- The universe now has 4,553 required, 3,389 blocked-base-plumbing, 11,198 unresolved, and 90 structurally inapplicable rows.
- `Rscript tools/check-after-task.R ...` passed report structure. The acceptance-ledger gate remains UNKNOWN because its runner is unavailable.
- `slop_check.py` found zero prose issues; scoped `git diff --check` passed.

## 6. Tests of the Tests

The probit and cloglog cases now use Bernoulli outcomes generated from their matching link probabilities. The checks assert signed slope recovery, pair-ordered SD predictions, and valid marginal simulation. The test does not compare the fitted objective or covariance to an independent dense oracle.

## 7a. Issue Ledger

Searched open issues with `gh issue list --state open --search 'phylogenetic interaction SD'` and `gh issue list --state open --search 'random effect SD regression'`. Results contained no focused issue for this exact route; no issue was changed.

## 8. Consistency Audit

The two newly admitted rows are Julia Binomial phylogenetic-interaction intercepts with `tree_pair`, q=1, member `I`, and probit or cloglog. Other providers and members remain unchanged. The finite universe remains 19,230 rows and does not claim broad link admission. In the Julia repository, `rg -n 'phylo_interaction|phylogenetic interaction|probit|cloglog' docs/src/families.md NEWS.md` found that the family guide documents an interaction slope (lines 904–907) but not the intercept recovery, while `NEWS.md:12` says structured and crossed-Laplace routes remain logit-only. That NEWS file has nine divergent refs, so this lane did not edit it. Both findings were sent to the active Julia documentation-audit lane. The broader drmTMB inventory paths are in the sibling R package and were not part of this Julia file check.

## 9. What Did Not Go Smoothly

The source-hash verification produced expected macOS extended-header warnings while extracting the archive on Totoro; all 107 SHA-256 checks passed and the Julia test completed successfully.

## 11. Team Learning

A finite universe can lag behind an implementation that already runs. Reconcile every newly exercised link-specific route after strengthening its recovery test, and keep the admission predicate restricted to the exact provider, layout, and coefficient member.

## 10. Known Residuals

This is Julia-only evidence for one phylogenetic-interaction intercept. It does not establish native TMB parity, interval coverage, or the independent correctness of the Kronecker covariance calculation. The active documentation-audit lane owns `docs/src/families.md`; it has been sent the exact scope for inclusion. Other Bernoulli providers and all remaining response families are still in scope.

## 12. Cross-Product Coverage

Covers the Julia Binomial q1 phylogenetic-interaction intercept for probit and cloglog with link-matched synthetic point recovery, pair SD prediction, and marginal simulation. Does not cover native TMB parity, interval calibration, or an independent dense covariance oracle.

## Next Actions

Continue with an unresolved Bernoulli structured row after checking its source route, existing tests, and lane ownership. Keep interval calibration deferred and the full goal active.
