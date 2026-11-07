# Gaussian random-intercept fixed-coefficient priors

## 1. Goal

Extend existing normal and ridge fixed-coefficient priors to Gaussian ML with one independent mean random intercept. Closes #1680 after outstanding hosted CI adjudication and final review gates. No merge or release is authorized.

## 2. Implemented

The admitted route keeps the existing prior contribution in the joint TMB objective exactly once, outside random-effect integration. Data likelihood, prior contribution and penalized objective remain separate. Updated route admission, selectors, bridge coordinates, reporting, updates and active-prior inference refusals together. The group SD remains unpenalized. No C++ likelihood changed.

## 3a. Decisions and Rejected Alternatives

Use the exact marginal Gaussian contract, including the separate zero-group-variance boundary evaluation. Adding another marginal prior term would double count. Native R numerical qualification uses the existing public multi_start=5 uniformly across all twelve fixtures, with caller seed777 and internal perturbation seed20260616. Production optimizer defaults were unchanged. The retained single-start ri_10 result is a genuine inferior local boundary minimum, independently diagnosed; it is excluded from configured-pass claims, without changing references or thresholds.

## 4. Files Touched

R/fixed-priors-workflow.R, R/fixed-effect-priors.R, R/drmTMB.R, R/julia-bridge.R, R/profile.R, R/methods.R and R/heritability.R; focused tests; generated help; the prior article; NEWS and check-log fragments; native/bridge adapters; independent-oracle and receipt directories. Current capability receipt metadata and a new reference-host receipt were added to clear source staleness. Historical raw receipt files were preserved.

## 5. Checks Run

The independent oracle was frozen before package fits. Repaired code pins R5d0f1596 and Juliaff10a2f9 passed all36 comparisons at the original limits; the root independently reran their raw results. Native derivatives cover nine positive-SD points per engine, with values only at three exact-zero points. Bridge arbitrary-point derivatives are unavailable. Guarded R focused tests passed87 expectations, including one actual bridge test. The new variance-ratio guard passed24 expectations and62 existing heritability checks.

Final R build passed in225seconds. R CMD check exited0 in3813seconds with42125 passing expectations,0 failures,117 warnings,696 skips and one report-only spelling-output NOTE. The source manifest passed; source-tree tests passed26516 expectations with0 failures,14 warnings and6 skips in126seconds. The raw test log retains a parallel shutdown message; that message is separate from the spelling NOTE. Full-suite configuration exercised no live Julia bridge; the separate guarded live receipt supplies that evidence.

Julia1.10.12 completed all eight original shards on repaired source, covering561 ordinary files exactly once, with each JET gate2/2. The slowest shard took8367seconds. Three fresh source reviews and an independent runtime reviewer qualified the bounded local evidence. See ../gaussian-ri-priors-20261106/guarded-numerical-evidence/, guarded-focused-live/, guarded-R-full/ and guarded-julia-full/.

## 6. Tests of the Tests

Admission and profile-readiness tests failed before their corresponding fixes. A later independent inventory exposed variance-ratio intervals escaping the inference guard; six public R cases failed before the shared repair. Oracle mutation controls reject omitted, duplicated, misindexed and altered-constant priors. Exact-zero variance is evaluated directly rather than through log(0).

## 7a. Issue Ledger

The isolated branch is codex/gaussian-ri-priors-20261106. Draft PR #1681 links companion DRModels.jl PR #1258. Both remain unmerged. Hosted checks and final evidence reconciliation remain open, so this report does not close the issue or claim overall completion.

## 8. Consistency Audit

No-prior and zero-ridge identities, selector mappings, separate data likelihood, prior retention under update and inference refusals passed. Conditional latent modes/covariances and penalized curvature retain their limited interpretation. Current-source capability recertification reproduced all three stored summaries exactly on their Mac reference host, with12/12 attempts passing. Ledger/equivalence checks and97 tests passed; prior historical raw hashes were preserved. The current pointer file also appears in PR1651, whose branch and protected head remain separate.

## 9. What Did Not Go Smoothly

The initial full package check failed two skip-census assertions for one newly added live-bridge skip site. Regenerating its single missing census row fixed those assertions; no skip condition or test gate was relaxed. Initial Mac JuliaCall setup lacked ForwardDiff, so live bridge qualification used an isolated Totoro environment. Raw-factor bridge formulas remain refused; explicitly numeric indicator transport was validated with exact design matching. Native R single-start optimization reached an inferior minimum in one fixture. The initial inference audit missed shared variance-ratio accessors; its superseding review and repair are retained. Totoro capability recertification differed from the Mac reference by at most3.23e-11 and was correctly rejected at tolerance zero; that attempt is preserved, and the Mac run reproduced the reference exactly.

## 10. Known Residuals

Hosted CI remains under investigation. Julia1.13.3 shard3 failed an existing unpenalized binomial SD convergence assertion. Baseline and candidate each passed the unchanged test locally under three diagnostic configurations, including its preceding shard/JET prefix; those passes do not establish a hosted baseline defect. A hosted baseline comparison is running. Current-head R cross-platform checks are also running. No interval coverage, sampling calibration, global optimization guarantee or general engine parity is established.

## 11. Team Learning

An SD boundary requires a separate likelihood limit and honest diagnostics. Prior metadata alone does not prove objective wiring, and source audits must trace shared derived-inference dispatch. Exact receipt reproduction can depend on the recorded reference host. Memory receipt: the approved plan, canonical contract and compute routing governed the slice. No Golden Set or hub guard changed.

## 12. Cross-Product Coverage

Covers complete-data, unit-weight, dense-design Gaussian ML with one independent mean random intercept and priors on selected mu/log-residual-SD coefficients. Slopes, multiple groups, structured effects, random-effect SD/correlation priors, REML, other mixed families and calibrated interval inference remain deferred. The revised R article example rendered on the earlier candidate; its code did not change in the later inference-guard repair. Final package examples and vignette rebuilding passed. Julia's current PR documentation built and its PR preview was published; production-site deployment was skipped. No merge, version bump or release occurred.
