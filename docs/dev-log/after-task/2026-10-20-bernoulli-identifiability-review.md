# After Task: Bernoulli One-Observation Identifiability Review

## 1. Goal

Correct the research record on what one Bernoulli observation per group does
and does not establish about random-intercept SD regression.

## 2. Implemented

Added a dated evidence note. It separates recovery of an individual group's
latent effect from identification of population parameters and limits claims
to what the cited sources establish.

## 3a. Decisions and Rejected Alternatives

Do not classify every one-observation-per-group Bernoulli model as
non-identifiable. For an intercept-only logit model with one common design
row, the observed distribution gives one marginal success probability and
cannot identify both the fixed intercept and random-intercept SD. Varied
group-level predictors change that marginal design, but the reviewed sources
do not give general identification conditions for the predictor-dependent
SD model. The exact probit intercept-only scale-confounding result remains a
special case.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/research.md`
- `docs/dev-log/check-log.d/2026-10-20-bernoulli-identifiability-review.md`
- This after-task report.

## 5. Checks Run

- Read the NotebookLM methods review and follow-up in the authenticated
  personal-account browser.
- Checked Stringer v2 Sections 2.1–2.2 and 4.3.1 in the primary manuscript:
  <https://arxiv.org/html/2310.01589>.
- Checked Joe (2008), Abstract and Sections 1 and 4, in the publisher record:
  <https://www.sciencedirect.com/science/article/abs/pii/S0167947308002533>.
- `git diff --check` passed. No model fit or package test was needed for this
  research-record update.

## 6. Tests of the Tests

Not applicable. No test was added or changed.

## 7a. Issue Ledger

Searched open issues for random-effect SD, Bernoulli variance regression, and
related inference work. Issue #932 concerns a separate Laplace-bias sweep for
the VA/EVA track; issue #1301 concerns non-Gaussian repeatability quantities.
Neither tracks this identifiability correction, so no issue was changed.

## 8. Consistency Audit

The general-SD inventory continues to treat one-observation Bernoulli cells as
obligations, not structural exclusions. No public support claim or software
behavior changed. The earlier NotebookLM overstatement is marked as superseded
in the research note and remains visible in notebook history.

## 9. What Did Not Go Smoothly

NotebookLM's first methods review overstated non-identifiability. Its later
challenge response corrected the claim, so both outputs had to be checked
before recording the source boundary.

## 10. Known Residuals

The sources do not give necessary and sufficient conditions for identifying
predictor-dependent logit SD coefficients. This note establishes no coverage
or parameter-recovery result. Shared implementation files remain under an
active direct-to-main lane; no code was changed in this slice.

## 11. Team Learning

Review the claim against its exact parameter target and design. Failure to
recover one group's latent effect from one response is not the same claim as
population variance non-identifiability across many groups.

## 12. Cross-Product Coverage

This is a research-record correction only. It does NOT cover model
implementation, family or random-effect support, parameter recovery, interval
calibration, Julia parity, or public documentation.
