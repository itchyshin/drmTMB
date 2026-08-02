# After Task: C17-C2 Zero-One-Beta `coi` Random Slope

## 1. Goal

Implement and independently adjudicate only `mc-0578`: the complete-response
ML-Laplace zero-one-beta model

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ x + (0 + x | id))
```

The earned ceiling is `implemented / verified / point_fit_recovery`. This task
does not claim profiles, intervals, coverage, inference readiness, supported
status, transformed or mismatched slopes, joint atom effects, structured
effects, q2-plus, missing responses, REML, or AGHQ.

## 2. Implemented

The existing C17-C1 `coi` carrier now admits either one unlabelled random
intercept or one unlabelled slope-only term. The slope gate requires the fixed
and random effects to use the same untransformed raw symbol. Start/map
machinery, TMB routing, `sdpars()`, `ranef()`, prediction, and the explicit
profile block all reuse the independent `u_coi` and `log_sd_coi` carrier.

The parser rejects mismatched or transformed symbols, labels, correlated
intercept-plus-slope terms, multiple or simultaneous atom random components,
structured providers, and missing responses. The canonical ledger promotes
only `mc-0578`, producing exactly 330 implemented, 340 rejected-by-design, and
17 not-implemented model-surface cells after integrating foreign Lane B PRs
#889 and #892.

## 3. Mathematical Contract

The admitted predictor is

\[
\operatorname{logit}(coi_i)=X_{coi,i}\beta_{coi}
+x_i\exp(\ell_{coi})u_{coi,g(i)},
\qquad u_{coi,g}\sim N(0,1).
\]

For `y = 0`, the boundary contribution is
`log(zoi) + log(1 - coi)`; for `y = 1`, it is
`log(zoi) + log(coi)`. Interior beta likelihood terms do not depend on `coi`.
The independent R oracle checks the full mixture, normalized Gaussian prior,
objective, and finite-difference gradient at perturbed parameters. A separate
boundary-only `lme4::glmer()` fit compares the common `coi` intercept, slope,
and random-slope SD without claiming equality of the full objectives.

## 3a. Decisions and Rejected Alternatives

The implementation reuses the independent C17-C1 `coi` carrier because its
non-centred TMB parameterization already matches the required slope model; a
second carrier or covariance block would add an unsupported surface. The one
boundary-spread diagnostic is retained as a warning because direct population
recovery, the likelihood oracle, and the external comparator passed. Treating
that diagnostic as proof of profile, interval, or coverage behavior was
rejected. Formula-grammar, likelihood-design, and shared check-log edits were
also rejected for this lane because the approved scope explicitly locks them.

## 4. Files Touched

Implementation and focused tests touch `R/drmTMB.R`, `R/family.R`,
`tests/testthat/test-zero-one-beta.R`, and the C17-C2 recovery runner. Family
documentation, README, NEWS, ROADMAP, family/source/implementation maps,
readiness and validation-debt documents, known limitations, the symbolic
alignment, and retained local/Totoro evidence describe the exact point-fit
scope and its sample-information warning.

`docs/dev-log/check-log.md` remains untouched because PR #869 is still open,
as explicitly requested. Formula-grammar and likelihood-parameterization
documents also remain untouched under the locked C17 boundary; their stale
sentences are recorded below rather than silently widening this task.

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  'devtools::document()'`: pass; `man/zero_one_beta.Rd` regenerated.
- Focused zero-one-beta tests: pass.
- Full `devtools::test(reporter = "summary")`: completed with one
  line-number-pinned estimator-conformance failure caused by inserted C17-C2
  code. The evidence pointer was refreshed and the focused conformance test
  passed.
- `devtools::check(args = "--no-manual", error_on = "never")`: pass after
  21 minutes; 0 errors, 0 warnings, and 0 reportable notes.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  'pkgdown::check_pkgdown()'`: pass (`No problems found`).
- `git diff --check`: pass on the pushed implementation/evidence candidate.
- `python3 tools/capability_ledger.py --check-c14-receipt-equivalence`: pass;
  the immutable C14 receipt/fingerprint remains unchanged and the C17-C2
  bridge authenticates the exact current fingerprint and source blobs.
- `python3 -m unittest tools.tests.test_capability_ledger
  tools.tests.test_b4_ci_c1 tools.tests.test_b4_ci_c2
  tools.tests.test_b4_ci_c3 tools.tests.test_b4_ci_c4`: 64 tests pass after
  integrating PR #892.
- `python3 tools/capability_ledger.py --check`: pass, 30 generated outputs.
- Filtered model-surface census: `687 = 330 / 340 / 17`.
- Post-integration focused zero-one-beta and estimator-conformance tests: pass.
- Fresh Fisher, Noether, and Rose D-43 review returned 3/3 GO on integrated
  candidate `b9a2798bdd431155871aafcb8b26792bb718ef25`. CI and post-merge
  Mission Control read-back remain landing gates.

## 6. Tests of the Tests

The focused suite contains an independent full-likelihood objective and
numerical-gradient oracle, verifies that `log_sd_coi` changes the objective,
checks `sdpars()`, `ranef()`, prediction and the direct-profile block, and
rejects transformed or mismatched slopes, labels, covariance, simultaneous
atom effects, structured providers, and missing responses. The recovery
campaign also uses an independently fitted boundary-only binomial mixed-model
comparator.

## 8. Consistency Audit

The exact stale-wording searches were:

```sh
rg -n 'coi.*(intercept[- ]only|random intercept only)|coi random effects are not|random effects in `coi`.*not|other zero-one-beta random effects|other zero-one beta random effects|other atom random effects|coi.*not implemented' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R man --glob '!docs/design/01-formula-grammar.md' --glob '!docs/design/03-likelihoods.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/handover/**' --glob '!*.html'
rg -n 'coi.*(profile|interval|coverage|inference_ready|supported)|point-fit-only.*coi|coi.*point-fit-only' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R man --glob '!*.html'
rg -n 'coi.*random|random.*coi' docs/design/01-formula-grammar.md docs/design/03-likelihoods.md vignettes/formula-grammar.Rmd
```

Current reader surfaces name the exact same-raw-symbol `coi` slope and keep
profiles, intervals, coverage, joint atom effects, transformed/mismatched
slopes, and structured effects unavailable. Historical notes remain
historical. The locked current documents with stale blanket wording are
`docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, and
`docs/design/03-likelihoods.md`; this arc explicitly forbids changing formula
grammar or likelihood-parameterization documents.

The generated capability maps were rebuilt from the authoritative ledger after
PR #889 merged at `f41dfc01a812af1294ee86790dc3e8d39e412c50` and PR #892
merged at `a0f93b0bd9e1d2c3ea751f59902c9f59ab34fe6c`. A direct
cell-ledger diff against the latter canonical base changes only `mc-0578`;
Lane B's merged C1--C4 classifications remain unchanged.

## 7a. Issue Ledger

A live search for open issues matching zero-one-beta `coi` returned no issue.
No issue was opened or closed because this feature is being landed through its
focused branch and forthcoming PR. PR #869 remains the owner of the shared
check log. PRs #889 and #892 merged before C17-C2 ledger integration,
resolving their generated-file overlaps without changing Lane B
classifications.

## 9. What Did Not Go Smoothly

One M=64 seed (`2026081781`) had minimum within-group boundary-row predictor SD
0.403 rather than the prospective 0.5 diagnostic. The fit directly
contradicted a blanket block: mode correlation was 0.660, absolute `coi` slope
error 0.0215, and relative random-slope SD error 0.0856. The retained campaign
therefore treats boundary-row spread as a conditional-mode sample-information
warning while preserving the exact population-level point-recovery claim.

The first full in-tree test run also exposed one mechanically stale source-line
pointer. Refreshing that pointer fixed the conformance test without changing
estimator behavior. Ledger integration waited for green PRs #889 and #892
rather than publishing competing generated files. The #892 integration
required source-level reconciliation of the frozen point-fit guard: C4 moves
eleven prior point-fit cells to interval-feasible, while C17-C2 adds one exact
point-fit cell, yielding 81 frozen and 82 total point-fit-recovery cells. The
combined 64-test suite and generator validate that reconciliation.

## 11. Team Learning

Predictor-spread thresholds diagnose conditional group-mode information; they
should not automatically erase strong population-level recovery when the
declared fixed effect, random-effect SD, likelihood oracle, and external
comparator all pass. Retain the diagnostic and describe its interpretation.

Line-number-pinned evidence remains useful because it fails visibly when a
shared source file gains code above the cited route, but every scoped source
change must include a focused pointer-refresh check.

## 10. Known Residuals

The recovery claim covers four retained M=64 attempts with 50 observations per
group at one frozen DGP. Sparse observed boundary outcomes or little predictor
spread among boundary rows can weaken conditional random-slope modes. No
profile, interval, coverage, robustness, inference-ready, supported, or broad
family-level claim follows.

Formula-grammar and likelihood-design wording is intentionally deferred. The
shared check log remains deferred until PR #869 lands or closes.

## 12. Cross-Product Coverage

This task changes only drmTMB's complete-response zero-one-beta ML-Laplace
surface. It does NOT cover DRM.jl, gllvmTMB, another family, a multivariate
route, a structured-effect provider, REML, AGHQ, missing responses, profiles,
intervals, coverage, aggregation, or any inference-ready/support tier. Mission
Control will read the drmTMB canonical ledger after landing; no separate
product mirror is changed here.

## 13. Next Actions

1. Open the focused C17-C2 PR from the PR #892-integrated candidate.
2. Require both CI jobs green on one unchanged head SHA,
   then request fresh merge authorization.
3. After merge, verify detached canonical main and Mission Control runtime at
   the merge SHA with no overlay.
