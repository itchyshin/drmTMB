# After Task: DHGLM Bernoulli Random-Effect Variance Prior-Art Review

## 1. Goal

Correct the methods map for predictor-dependent random-effect SDs after verifying whether published software supports fixed predictors of random-effect variance for binomial responses.

## 2. Implemented

Added the official `dhglm` 2.0 reference manual and the Lee and Noh (2012) article to the source ledger. Updated the research synthesis and family-wave plan to record the Bernoulli/binomial variance-regression precedent, its variance-to-SD coefficient conversion, and its estimator boundary. No package model code changed.

## 3. Mathematical Contract

The `dhglm` manual documents a log link for random-effect variance. If `log(lambda_g) = W_g gamma` and `lambda_g = tau_g^2`, then `log(tau_g) = W_g (gamma / 2)`. The fixed-predictor design is shared; the variance-model coefficients are twice the corresponding log-SD coefficients.

## 3a. Decisions and Rejected Alternatives

Record the precedent as prior art, while leaving drmTMB's family/effect/backend support claims tied to its own tests. Do not claim that the historical model is new, and do not treat h-likelihood or adjusted-profile output as an independent marginal-likelihood oracle without reconciling the estimand and objective.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/research.md`
- `docs/dev-log/general-sd-regression/research-sources.tsv`
- `docs/dev-log/general-sd-regression/native-family-wave-plan.md`
- `docs/dev-log/check-log.md`
- This report

## 5. Checks Run

- `notebooklm auth check --test --json`: passed for `itchyshin@gmail.com`; `token_fetch` was true.
- Added the official CRAN reference manual to the existing methods notebook and waited for its source row; status was `ready`. A targeted NotebookLM query returned non-empty references to the binomial and variance-predictor documentation.
- Checked the same claims directly against the [official CRAN reference manual](https://cran.r-project.org/web/packages/dhglm/refman/dhglm.html), including response families, `LinPredRandVariance`, link choices, and fitting methods. Checked the Lee and Noh publisher record and related primary pages.
- Current no-fit calibration-adapter checks passed: Python 57/57; R stage-two rules; prior-seed negatives for three streams; first-look registry; clean-current combiner with 12,000 attempts and no fits.
- `check-after-task.R` passed the report-structure check, then exited nonzero because the programme acceptance ledger still reports 12 unmet gates. This matches the open full-goal status; those gates were not closed or relabelled here.
- `gh issue list --state open --search 'random effect SD regression'` found only broader simulation/reporting and release-readiness issues. No feature issue matched; no issue was changed.
- No Totoro or DRAC fits or calibration campaigns were launched from this review. Totoro's existing profile and a separate 48-worker campaign were still active during preflight.

## 6. Tests of the Tests

No package test was added. The NotebookLM citations point to the exact CRAN manual passages, and those claims were independently checked against the official manual. The adapter checks exercise manifest rules and combination logic only; they are not model-fit or calibration evidence.

## 7a. Issue Ledger

`gh issue list --state open --search 'random effect SD regression'` returned no directly matching feature issue. Issues #59 and #61 are broader simulation/reporting and release-readiness work; neither was changed.

## 8. Consistency Audit

The research note now separates prior art from drmTMB implementation evidence. The wave plan does not promote any family/backend capability. The formula grammar, public documentation, NEWS, and pkgdown navigation were not changed because this review changes no package behavior. Earlier NotebookLM queries with empty references remain documented as such; this later query is recorded separately with its citations.

## 9. What Did Not Go Smoothly

The first exact-source NotebookLM query returned no references, so it could only guide searches. Adding the official CRAN manual yielded a cited follow-up. The methods notebook still contains two blocked `Just a moment...` sources; they were not used.

## 10. Known Residuals

The DHGLM manual establishes documented software support, not a general identifiability theorem or interval-calibration result. Its h-likelihood and adjusted-profile procedures are not a drop-in numerical oracle for drmTMB. The Lee and Noh publisher page supplied an abstract/metadata record, not a full-paper review. No independent likelihood comparison was made.

## 11. Team Learning

For SD-regression literature, search and record variance-model terminology as well as standard-deviation terminology. Convert the coefficient scale explicitly before comparing model formulas or output.

## 12. Cross-Product Coverage

This literature review does NOT cover drmTMB/DRM.jl fitting, recovery, profile or bootstrap interval calibration, or engine parity. After the current Totoro profile releases its lane, complete the fresh bounded source-bound adapter qualification. Keep the Bernoulli calibration gate open until the staged inference criteria pass. Continue the full family, effect-type, endpoint, and Julia parity ledger without treating this literature correction as implementation progress.
