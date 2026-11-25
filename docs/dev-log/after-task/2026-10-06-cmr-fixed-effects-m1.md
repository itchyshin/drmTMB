# CMR M1 milestone receipt, 2026-10-06

## 1. Goal

Deliver exact native fixed-effects first-capture-conditional CJS models in both packages. The full approved M0-M6 programme remains active.

## 2. Implemented

R exposes cmr_data() and drm_cjs(); Julia exposes CMRData, cjs() and CJSFit. Each has keyed process designs, explicit survey masks, administrative follow-up, unit-labelled intervals, offsets, ML fitting and terminal-identification guards. Kernels sum discrete states exactly. Runnable fit examples live under docs/dev-log/cmr/examples.

## 3a. Decisions and Rejected Alternatives

Use separate CJS interfaces and native kernels, with generated fixtures as the cross-language contract. Retain final-first histories. Survival is unit-time probability raised to the interval length. No ordinary-binomial independence approximation or first-capture emission enters the objective.

## 4. Files Touched

The CMR source, four test files per package, route check runners, fixtures, new help/docstrings and scoped evidence reports are local on codex/cmr-cjs. The accepted goal and plan remain hash-locked. Original checkouts and unrelated managed configuration edits are protected.

## 5. Checks Run

Both final M1 unlazy ledgers reverified three gates: exact, derivatives and parity. There are 719 independent probability fixtures. Julia also has 31 independent contract assertions and R has 35. R and Julia aggregate fixed-parameter likelihoods differ by 1.7763568394002505e-15. Both match marked 1.2.8 with zero likelihood difference on the pinned constant-parameter fixture. Ordinary Gaussian neighbour checks pass, 42 R assertions and four Julia assertions; these are not full regression suites.

## 6. Tests of the Tests

Wrong-binomial, first-emission and omitted-suffix controls fail. R's injected derivative assertion produces a nonzero exit and no success marker. Negative schema tests exposed six R defects; repaired source passes them. Future model gates fail explicitly.

## 7a. Issue Ledger

Per-package M1 ledgers: three met, zero unmet, zero abandoned. Full programme ledgers: four met, ten unmet, zero abandoned. M0 and M1 are accepted. M2-M6 remain owed. No public issues or PRs have been created.

## 8. Consistency Audit

The contract, data indexing, intervals, masks, factor coding and terminal constraints agree with the exercised native paths. CJS dispatch precedes ordinary TMB fields; Julia includes are additive. No GPL R implementation source was copied into Julia. Version and comparator hashes remain retained.

## 9. What Did Not Go Smoothly

The enforced CLI rejected Luna despite the catalogue listing it; native model/effort dispatch is disclosed, with failed CLI receipts retained. Notebook browser fallback produced cited syntheses but media artifacts remain pending. R initially selected no tests, used numeric units, lost contrast metadata and accepted malformed designs/keys. Each accepted repair has real production checks. The fixture worker omitted its report; the parent supplied it. Report structure validation passes, but programme-wide closeout remains unmet.

## 10. Known Residuals

No qualification campaign, broad regression suite, calibrated inference, publication or release is claimed. M2 prediction/simulation work is still a parked draft. Notebook report/audio/video delivery and vault filing remain pending.

## 11. Team Learning

Keep log complements at extreme links and train schemas on observed contributing rows. Test the model builder before kernel parity. Memory receipt: frozen contract and primary-source research retained in each repo; new vault filing is pending. GoldenSet: independent enumeration, deliberate wrong likelihoods and failure-injected runners provide the retained fences.

## 12. Cross-Product Coverage

M1 covers data, fixed-effects exact likelihoods, ML fit preparation, diagnostics and fixed-parameter parity. It does NOT cover prediction, simulation, profile/Wald/bootstrap calibration, shared or persistent heterogeneity, SD predictors, reference selection, bridge admission, full regression, docs builds or publication. Full population modelling remains deferred by the approved plan.
