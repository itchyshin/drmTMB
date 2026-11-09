# Gamma prior on a named random-intercept SD

## 1. Goal

Add a Gamma prior for one named Gaussian mean random-intercept SD, with an independent numerical oracle and a Julia bridge contract. Prepare an isolated, reviewable change without merging or releasing it.

## 2. Implemented

The native route resolves an exact group and intercept, applies the normalized Gamma penalty once on the natural SD scale, and records the data likelihood, prior contributions and penalized objective separately. Fixed-effect priors can be supplied alongside the SD prior. The bridge has a separate mixed-prior contract. Its validator checks the fixed and SD penalty components and their gradients independently; exact-head repository CI remains open.

## 3a. Decisions and Rejected Alternatives

The Gamma density is defined with respect to the SD. The optimizer works on the log SD without an additional Jacobian, so the reported mode is an SD-scale penalized-ML estimate. The existing phylogenetic penalty has a different target and is unchanged by the native SD-prior objective.

## 4. Files Touched

The R prior constructors, target resolver, fit workflow, TMB objective, result methods and bridge were changed with focused tests and help pages. The independent MIT-licensed oracle is recorded under `tools/ranef-sd-prior-oracle/`; frozen test inputs and their manifest also ship under `tests/testthat/fixtures/ranef-sd-prior-oracle/`.

## 5. Checks Run

The focused native run in `../r-native-boundary-verified-20261109.log` passed 30 frozen objective, gradient and Hessian comparisons across three datasets, five points and two Gamma parameter sets. Six fitted objectives and scores were compared; parameter comparisons required both oracle refinement success and numerical eligibility. Three refinements reported precision loss and were compared only on objective and score. The focused run skipped a live Julia test.

The committed-fixture test in the task evidence `r-packaged-oracle-test.log` passed with `DRM_SD_ORACLE` unset. The example in `r-packaged-sd-prior-example.log` previewed and fitted the SD prior. All 11 original oracle manifest entries and the fixture-copy manifest passed; the oracle self-test passed. A secondary comparison with glmmTMB 1.1.14 matched 30 oracle point evaluations and six fitted objectives; three successful, eligible oracle fits also supported parameter comparisons. Its reproduction and provenance are under `tools/ranef-sd-prior-oracle/glmmtmb-secondary/`.

R commit `95c621349b8ed91ae4afec0a07722346b6ed5a62` passed `R CMD check` on Totoro with an isolated TeX tree and the Times manual font. The test stage used the bounded CRAN allowlist: 3,521 passes, 18 warnings and 32 skips, including two live Julia skips. The full repository suite runs separately in CI. A paired rerun at that R commit and local Julia commit `0692e82e8e8b0dd6a930fa04f57cf4611b691f8a` passed seven live bridge tests on Julia 1.10.0. The task evidence files `r-check-95c621349.log` and `PAIRED-LIVE-FINAL.md` record the commands and limits; selected bridge and test hashes matched before and after the paired run.

## 6. Tests of the Tests

The independent oracle includes deliberately incorrect Jacobian, normalizer, shape/rate, targeting and penalty-count controls. An underflow regression failed before the native convergence guard was added. Earlier focused runs exposed changed fixed-prior error wording, which was corrected and rerun.

## 7a. Issue Ledger

The work remains in an isolated branch based on `bfa7acf5bb85e298fe675c5713c34fa208abd860`. Draft PR #1689 is open; repository CI, source reconciliation and final review remain open. No merge or release is authorized by this task.

## 8. Consistency Audit

Focused checks cover mixed priors, selector rejection, rescaling, update replay, separate objective components and selected prior-fit inference refusals. Independent native review checked the penalty and addressed a missing score assertion and numerical-underflow diagnostic. Those checks do not replace a full no-prior regression suite.

## 9. What Did Not Go Smoothly

Roxygen regeneration changed four unrelated help files. The attempted restoration was rejected by the automatic destructive-action guard; the generated diff and rejection are preserved in `../r-roxygen-collateral.diff` and `../r-roxygen-guard-rejection.txt`. Three oracle refinements reported precision loss, so their parameters are not counted as converged reference estimates.

## 10. Known Residuals

The R package check used a bounded test allowlist, and full repository CI remains outstanding. The live bridge rerun covers selected cases rather than every formula shape. Julia's native formula parser collapses repeated identical random terms before target resolution, whereas R rejects the written duplicate. A pinned fixed-only bridge comparison matched the numeric and other compared fields in four cases, but its strict comparison failed on compiler-generated `diagnostics.route` strings. The full Julia suite remains open, and a run expected to exceed three hours requires separate approval. A small score alone does not establish a well-conditioned interior optimum. No calibrated confidence intervals or posterior sampling are claimed.

## 11. Team Learning

An SD density and a log-SD density define different modes. The density measure, normalized objective and convergence diagnostics therefore need explicit tests. Oracle fixtures must also be available to package checks without a private local path.

## 12. Cross-Product Coverage

The implemented SD-prior slice targets complete-data, unit-weight Gaussian ML with exactly one unlabelled independent mean random intercept. It does NOT cover random slopes, multiple random-effect blocks, structured effects, correlation priors, other response families or REML. The Julia bridge refuses factor predictors in this mixed-model route. No-prior and fixed-only behavior require the remaining full regression checks; uncertainty and likelihood-comparison methods remain guarded for active prior fits.
