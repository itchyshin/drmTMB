# After Task: NotebookLM methods review for latent SD regression

## 1. Goal

Review primary methods and software sources relevant to predictor-dependent random-effect SDs, with Bernoulli as the first delivery, and record what they establish versus what the project must validate itself.

## 2. Implemented

Completed a bounded, source-checked research synthesis. Feature implementation and calibration remain open.

## 3a. Decisions and Rejected Alternatives

For a latent random effect with `log(tau_g) = W_g alpha`, the reviewed literature provides software precedent but no direct proof of identifiability or interval calibration for the requested Bernoulli SD slope. A Bernoulli model has no free residual SD. Structured covariance continues to follow the existing kernel scale, so `tau_g` is a multiplier when `K_gg != 1` and the marginal SD is `tau_g * sqrt(K_gg)`.

## 4. Files Touched

- Added `docs/dev-log/general-sd-regression/notebooklm-methods-review-20261020.md`.
- Added this report and `docs/dev-log/check-log.d/2026-10-20-notebooklm-methods-review.md`.
- NotebookLM note created: “Methods review: latent SD regression, integration, and uncertainty (2026-10-20),” note ID `b8f1ac10-4a35-43b0-b07b-c8fedd915f70`.

## 5. Checks Run

- NotebookLM CLI auth check passed for the personal account, with `token_fetch=true`.
- Inspected the existing notebook's 15-source list and queried a source-limited synthesis.
- Verified the claims used in the report against the Joe (2008) publisher abstract, Stringer (2024) preprint, CRAN `dhglm` manual, and `glmmTMB` covariance vignette.
- No fitting, simulation, package tests, or full status-inventory checks were run because this research slice made no source or public behavior change.

## 6. Tests of the Tests

Not applicable. No test code was added or changed.

## 8. Consistency Audit

The report distinguishes latent random-effect variance predictors from observation-level dispersion and retains the project's distinction between an SD multiplier and a structured-kernel marginal SD. It corrects the inference that lack of a closed form in the logit model implies identifiability for an intercept-only, one-observation-per-group design.

## 7a. Issue Ledger

No issue was modified. This research checkpoint does not change package behavior; related feature work remains in its existing project lane.

## 9. What Did Not Go Smoothly

NotebookLM returned citation numbers without structured citation references. Earlier notebook summaries also included numerical coverage claims that could not be checked against the accessible primary abstracts. The final report excludes those claims and records the capture limits.

## 11. Team Learning

For literature reviews, a NotebookLM answer is a source-finding aid. Verify each load-bearing claim against the source itself, and do not treat inline numbers as citations when the tool returns an empty reference list.

## 10. Known Residuals

The `dhglm` manual establishes an interface precedent. Its estimator, assumptions, and finite-sample inference have not been shown to transfer to `drmTMB`. The Joe full article was access restricted. No reviewed source establishes identifiability, recovery, or interval calibration for continuous predictor-dependent log-SD slopes.

## 12. Cross-Product Coverage

This methods-review slice does NOT cover implementation, likelihood code, tests, engine parity, or package documentation. Continue the implementation in its owned lane. Prioritize an independent Bernoulli integration oracle, structural-confounding negative controls, coefficient and SD-ratio recovery, and direct interval calibration. Keep the current shared R/TMB source ownership boundary in force until a named owner releases it.
