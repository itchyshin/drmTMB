# After Phase: Poisson scalar labels and synthetic SD guide

Status: verified local checkpoint. The general SD-regression programme remains active.

## 1. Goal

Give one ordinary Poisson random intercept a stable block identity, and provide a
runnable explanation of predictor-dependent latent SDs for binary and count data.
This is a bounded implementation and documentation checkpoint, not programme closure.

## 2. Implemented

The complete-data ordinary Poisson route admits a unique `(1 | p | id)` intercept
and selects it through `sd(id, block = "p")` or the unique-target shorthand.
The label adds no correlation parameter. The latent SD remains
`exp(W_g alpha)` multiplying a standard-normal group effect on the log-mean scale.
NB2 labels, labelled ordinary slopes, structured partners and missing-response
combinations retain their current fences.

The new guide generates independent synthetic Bernoulli and Poisson responses,
fits both models, checks diagnostics and predicts group SDs. It distinguishes
link-scale group variation from response variation and confidence intervals from
credible intervals. Its fixed-seed ratios are shown alongside their known truth.

## 3a. Decisions and Rejected Alternatives

Keep scalar labels separate from correlated blocks. Do not infer covariance
between an ordinary field and a spatial field from a repeated label. Reject those
untested combinations before fitting. Keep the guide's imperfect small-sample
estimates visible rather than choosing a more favourable seed.

## 4. Files Touched

The change covers `R/drmTMB.R`, Poisson assembly/integration tests, the formula and
likelihood guides, NEWS, the new vignette and its pkgdown registration. Contracts,
review, exact capsule manifests and logs are under
`docs/dev-log/general-sd-regression/`; the bounded build and guide wrappers are in
`tools/general-sd-regression/`.

## 5. Checks Run

The final source assembly passed 39 expectations. A fresh Totoro installation from
capsule `6ad295b3bed294db34bc32fd3dc59028942e5b38c1cb202576be55e994aa58d6`
passed 154 compiled expectations: Poisson 43, binomial selectors 22 and Gaussian
SD regression 89. Installation and tests took 60 seconds under a 240-second cap.
The recorded R-source SHA is
`d88ff6046bffa9f57aa258c0e19e1adf4ee46c7c8e05cfcf297420a27d7efe46`.

The guide's two fits ran on the preceding isolated label build, whose unlabelled
model path is unchanged by the subsequent admission fence. Both diagnostic tables
had no warnings or errors, with the existing interval-scope note retained. Knitting
completed under 60 seconds; local HTML rendering passed with one Pandoc deprecation
warning. Chrome inspection confirmed rendered equations, readable compact diagnostic
tables and the true-versus-estimated SD ratios. This was a single-article render,
not a full pkgdown deployment or platform check.

## 6. Tests of the Tests

The first label test failed at the original unsupported-term gate. Independent
review then found an overly broad ordinary/spatial admission. Running the two new
boundary assertions against the frozen pre-fence builder produced exactly two
failures because it did not reject those models. The repaired builder passes.
All failure logs and the reproducible negative-control runner are retained.

## 7a. Issue Ledger

No external issue, pull request, email or release action was taken. Local commits
are review checkpoints only; nothing was pushed or merged.

## 8. Consistency Audit

The grammar and validator hints now distinguish scalar ordinary labels from
labelled correlated and structured routes. The source-pinned ordinary-base audit
has 224 rows, separate from candidate support. The 19,118 required programme rows
remain intact. All programme gates G0 through G8 remain open.

## 9. What Did Not Go Smoothly

The initial label admission also permitted structured partners and missing-response
mode. Independent review caught this; the new flag defaults to false and the
Poisson builder enables it only for the reviewed ordinary route. Totoro lacked
Pandoc, so the guide was knitted there and rendered locally. The first guide output
printed excessively wide diagnostic messages; the repaired display retains the
full objects and shows only check names and statuses.

## 10. Known Residuals

The first 3,000-attempt Bernoulli calibration is still running on its immutable
source/library pair. It provides no result for this checkpoint. Public Julia
integration awaits the shared-file ownership decision. Slope SD regression,
correlated blocks, remaining families and structured providers remain programme work.
The optional package-check cleanup rejected by the deletion guard remains untouched.

## 11. Team Learning

An admission-only edit can expose an untested combined route even when it changes
no likelihood code. Check surrounding provider and missing-data gates as well as
the intended single-field fit. Execute documentation before judging its readability.

## Design-Document Updates

The formula grammar and Poisson likelihood section describe the exact scalar label
scope. The separate label contract pairs equations, synthetic generation and outputs.

## Pkgdown and Documentation Updates

The synthetic guide is registered in both the tutorial menu and article group.
Its source, executed Markdown, HTML and exact-draft assessments are retained.

## 12. Cross-Product Coverage

This checkpoint does NOT cover broad family/effect/provider/endpoint admission,
Julia public fitting, calibrated uncertainty, a complete package/site check, or a
release. The first Bernoulli study is one predeclared inference domain only.
