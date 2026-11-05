# General SD regression: first native checkpoint

This checkpoint records implementation and verification of the first native
Bernoulli/binomial ordinary-intercept SD slice. The approved programme remains
active. Both-engine integration, breadth and calibrated uncertainty are open.

## 1. Goal

Implement predictor-dependent latent random-effect SDs across the frozen
supported-family and latent-mechanism universe, beginning with an independent
synthetic Bernoulli example. This report covers the first native checkpoint.

## 2. Implemented

The native Bernoulli/binomial builder accepts an SD formula for a unique
ordinary location random intercept. It reuses group-level fixed-effect coding,
parameter maps and target metadata. TMB applies its positive group scales to
latent intercepts; extractors, profiles and marginal simulation use the same
identity. This remains the first slice of the approved broader programme.

## 3a. Decisions and Rejected Alternatives

Keep SD regression separate from response dispersion, preserve constant-SD
models and existing kernel normalization, and retain all failed attempts.
Use an actual fitted SD registry for output and diagnostics. Preserve the
residual-only detector default for residual accessors. Reject broad claims
from shared-engine agreement, a finite profile interval or generated research.

## 4. Files Touched

Native assembly and parameter maps in `R/drmTMB.R`, the binomial likelihood in
`src/drmTMB.cpp`, prediction/simulation in `R/methods.R`, and clamp diagnostics
in `R/check.R` changed. Six new R test files and an independent generator and
Laplace calculation accompany them. `tools/general-sd-regression/` contains
isolated test runners, source inventory and the feasibility-pilot runner.
The design/reference/grammar, NEWS, roadmap and limitations reflect this slice.
The programme plan, source pins, research, reviews and checkpoint are retained
under `LOOP/lanes/general-sd-regression/` and this report's neighbouring directory.

## 5. Checks Run

The separate native package library was rebuilt successfully with CLT SDK
selection, two build jobs and BLAS threads capped at one. New compiled tests
exercise assembly, likelihood, extraction, three response links, prediction,
storage, profiles, simulation, bootstrap refits and clamp diagnostics.
Bound assembly, compiled native and independent-oracle gates B1/B2/B3 pass.
The six new compiled files pass 117 assertions. The feasibility pilot retained
seven attempts for six unique seeds: five fits completed before the original
300-second cap; a separate retry completed the interrupted seed in 78.54 seconds.
All six completed fits had valid recorded intervals and scalar Laplace objective
differences below 1e-6. This is not calibration evidence. Existing
binomial response/link and Gaussian SD tests passed. The legacy simulation
file passes under pkgload; its installed-runner invocation failed because a
local mock requires pkgload, and that runner limitation is retained in logs.
Five Python inventory tests pass, including a missing-registry negative control.

## 8. Consistency Audit

The symbolic model, formula and native code use a group-constant log-SD design:
`b_g = exp(W_g alpha) u_g`, with `u_g ~ N(0,1)`. Bernoulli responses keep
fixed trial dispersion and receive no free residual `sigma`. Distinct target
indices preserve unrelated effects. Soft-clamp values agree in C++, prediction
and marginal simulation. Residual and latent clamp diagnostics remain distinct.
The broader programme's 54 endpoint rows across 20 family routes include
missing base plumbing; they are not claims of current SD support.

## 6. Tests of the Tests

The initial SD assembly tests failed at the previous explicit binomial refusal.
Prediction tests then failed at the Gaussian-only target/link lookup. An
independent scalar Laplace calculation checks the native likelihood and a
wrong-sign control changes its answer. Simulation checks use independent
normal draws, group-specific variance ratios and unrelated-term fallback.
An existing empty-report clamp test caught a regression in the new detector;
the missing-field return was repaired and the test passes. New compiled tests
do not silently skip missing binomial SD reports.

## 9. What Did Not Go Smoothly

System Git is an Xcode licence stub; the CLT Git executable is used explicitly.
The desktop worktree tool could not locate Git, so isolated manual worktrees
were used. Native compilation required an explicit CLT SDK; no global setting
or permission configuration was changed. The initial gate-check invocation
used the ledger directory, failed to find its runner, and was rebound to the
worktree root. That failure is verification plumbing, not a passing receipt.
NotebookLM CLI/MCP sessions remained signed out after reconnection; the
personal-account Chrome session worked. Generated research overstated claims
and invented thresholds. Its report was renamed as rejected; reviewed limits
and the corrected query are retained separately.

## 11. Team Learning

Use the fitted SD target registry for output recognition, rather than family
whitelists. Verify downstream simulation, refits and health reports as soon as
fitting works. Keep a Laplace-implementation oracle separate from exact
marginal-integration checks. Keep failed fits and failed intervals in the
all-attempt denominator. A successful research artifact generation does not
validate its content.

## Design-doc updates

The formula grammar and likelihood notes describe the ordinary native SD slice,
its log-SD interpretation, standard model-matrix coding and constant-SD
reduction. Explicit selectors, slopes and structured SD machinery remain
programme work. The exact kernel/projection contract is under separate review.

## Pkgdown/documentation updates

The SD formula reference source and generated Rd topic changed, alongside the
formula vignette, NEWS, roadmap and limitations. Roxygen completed; its unrelated
format changes to 38 help files were removed from this isolated lane. The generated Rd topic passes `tools::checkRd()` and HTML conversion;
`pkgdown::check_pkgdown()` reports no problems, with Pandoc deprecation
messages retained. The full site has
not been built or published. Exact status scans used:
`sd\(group\)|sd\(id\)|random-effect scale|random.effect scale` over README,
roadmap, limitations and pkgdown configuration, plus targeted grammar/likelihood
and reference-source reads. Historical reports were preserved.

## 7a. Issue Ledger

No issue, PR, comment or email was sent. Source/PR overlap was inspected during
lane preflight. This checkpoint creates no public support or release claim.
Julia shared-dispatcher ownership is awaiting the user's decision; the new
private module and an unapplied wiring patch remain isolated.

## 10. Known Residuals

No repeated-sampling coverage claim follows from these tests or the small
pilot. Julia's private module passes 25 assertions, but public dispatch,
SD prediction/bridge metadata and calibrated inference remain open. Full
R/Julia checks, the complete mechanism universe, all family/effect admissions,
Totoro/DRAC recovery, documentation rendering and independent programme closeout
remain required. Native-slice documentation review B4 passes. The retained expectation-count
receipt reconciles 117 passing assertions in the detailed runner log.
Next: commit this local checkpoint and repeat the qualified workload on Totoro before production scheduling.

## 12. Cross-Product Coverage

This checkpoint covers native ML ordinary scalar-intercept SD regression for
Bernoulli/binomial responses. It exercises logit, probit and complementary
log-log links, known count denominators, target extraction/prediction/storage,
profile mapping, marginal simulation and two bootstrap refits. It does NOT cover interval calibration, Julia public dispatch/bridge, random slopes,
correlated or labelled SD targets, other response families/endpoints/providers,
missing-response/predictor combinations, penalties, new REML/AI-REML domains,
full R/Julia checks or package release. Existing Gaussian SD and binomial
response/link regressions passed; that evidence does not promote new cells.

Prose self-assessment: 3/10 perceived AI-like style, medium confidence.
The exact-draft assessment record is retained beside the native evidence. This
editorial rating does not certify programme closure.
