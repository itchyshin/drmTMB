# Gaussian random-intercept coefficient priors: interim report

## 1. Goal

Closes #1680 when the outstanding validation and review gates are met. Extend existing coefficient priors to the approved single Gaussian mean random-intercept model.

## 2. Implemented

Admitted the narrow Gaussian route, retained the existing latent-independent TMB prior contribution and likelihood accounting, corrected public profile readiness for active-prior fits, and added focused tests, help and an article example. No C++ likelihood was copied or changed.

## 3a. Decisions and Rejected Alternatives

Prior terms already in the joint objective factor outside the random-effect integral; adding another marginal penalty would double count. The tau-zero likelihood uses a separate fixed-only Gaussian evaluation because log(tau) cannot represent zero. Assumptions: none beyond the approved plan.

## 4. Files Touched

R/fixed-priors-workflow.R, R/fixed-effect-priors.R, R/drmTMB.R, R/profile.R, R/methods.R; tests/testthat/test-fixed-priors-gaussian-ranef.R and test-fixed-priors-workflow.R; man/drmTMB.Rd, man/drm_priors.Rd, man/drm_resolve_priors.Rd; vignettes/articles/fixed-effect-priors.Rmd; news/gaussian-ri-fixed-priors.md; tools/gaussian-ri-prior-adapters/r-native.R and r-bridge.R; this report and check-log entry. Oracle files are owned and recorded separately.

## 5. Checks Run

Local focused tests: 49 and 44 expectations passed; article render and Rd example passed. The new file passed 55 expectations including one live Julia bridge test on Totoro with an isolated library and recorded Julia-bundled libunwind preload. Root independently reports all four preflight fixtures passed against the oracle for native R, native Julia and the bridge, with six verifier mutations rejected. Two bridge fixtures used exactly matched numeric indicator transport; their raw factor formulas remain refused. The final configured 12-fixture grid passed all 36 route checks against the frozen independent oracle. Native R used the existing public multi_start=5 setting, with caller seed 777 and internal perturbation seed 20260616; see ../gaussian-ri-priors-20261106/R-MULTISTART-POLICY.md. Native Julia and the bridge retained their original configurations. The default run passed 35/36 checks and failed native R ri_10 at an inferior local boundary minimum; that result remains in the evidence. Full R build passed; R CMD check and source-tree tests remain pending. The independent final source review passed at R251d103b and Juliaf60eb88e. pkgdown has not been completed for this source.

## 6. Tests of the Tests

The intended admission test failed before the route change; eight readiness expectations failed before the readiness correction. The independent oracle includes omitted, doubled, misindexed and altered-normal-constant controls; see its separate evidence.

## 7a. Issue Ledger

Closes #1680 after pending gates; this interim entry is not a completion or merge claim.

## 8. Consistency Audit

Prior constructors and selectors remain unchanged. Data log likelihood and prior contribution are separate. Active-prior profile readiness is false; no-prior and zero-ridge readiness agree in focused tests. Conditional latent modes and covariances, when available, are plug-in conditional quantities, not a full posterior. Existing local penalized-Hessian curvature is not calibrated inference.

## 9. What Did Not Go Smoothly

Mac JuliaCall started using a disposable project but the selected Julia environment lacked ForwardDiff; bridge preflight moved to Totoro without modifying the global environment. Factor-indicator formula metadata was corrected and reverified independently before candidate comparisons. The final grid also exposed a genuine inferior local minimum in native R. Independent variance-direction and free-Hessian checks confirmed that branch; the existing multiple-start control reached the lower optimum without oracle-derived starts. Every fixture was then rerun under the same recorded configuration, preserving the default failure.

## 10. Known Residuals

Full suites remain pending. The final revised R article rendered successfully, including its worked examples. Numerical qualification passed under the recorded configurations, and independent source review passed. Single-start fitting remains susceptible to local minima. The bridge has no arbitrary-point Hessian interface; native engine pointwise Hessians do not establish a bridge Hessian test. No interval coverage or sampling calibration is established.

## 11. Team Learning

A log-SD parameterization cannot represent the exact zero boundary; evaluate the zero-variance limit separately and report the distinction. Memory receipt: drmTMB LOAD-FIRST and compute routing were consulted. Golden Set was not run; source checks and independent oracle are the task-specific evidence.

## 12. Cross-Product Coverage

Focused native R tests cover active coefficient priors, selectors, Gaussian mean random intercept, prior updates, zero-ridge ML and existing inference guards. This does NOT cover random slopes, multiple groups, random-effect SD priors, structured effects, non-Gaussian mixed models, REML, sampling or interval coverage. The configured full grid covers all twelve fixtures on native R, native Julia and the bridge. It does not establish global optimization reliability or raw-factor bridge support. No release or merge occurred.

The later persistent live test file passed 63 expectations on Totoro, including zero-ridge bridge equivalence to unpenalized ML. This supplements the earlier 55-expectation live run. The frozen grid subsequently passed under the recorded configurations; full suites remain pending.
