# After Task: Zero-truncated NB2 selected-slope SD bridge

## 1. Goal

Admit the existing zero-truncated NB2 independent-slope SD fitter through the R-to-Julia bridge for complete positive counts, and check one same-data synthetic fit against native TMB.

## 2. Implemented

The bridge now admits one ordinary `mu` random intercept or one independent numeric `mu` slope when the SD formula selects the same group and coefficient and `sigma ~ 1`. Offsets and structured terms remain refused. The bridge sends the family-specific direct-SD coefficient labels under Julia's canonical `sd` block. Hurdle NB2 remains a separate route that requires `hu`.

## 3a. Decisions and Rejected Alternatives

The route is limited to complete positive counts, fixed `sigma`, one ordinary
`mu` intercept or selected numeric slope, and no offset or structured effect.
The test covers the selected slope. I did not claim group-SD numerical parity
or interval calibration because the bridge fit uses different integration
approximations and this receipt does not test either claim.

## 4. Files Touched

**Mathematical Contract**

For the tested slope,

```text
b_g ~ Normal(0, tau_g^2),  log(tau_g) = alpha_0 + alpha_1 z_g,
mu_ig = exp(beta_0 + beta_1 x_ig + b_g x_ig),
Y_i | Y_i > 0 ~ NB2(mu_ig, size = 1 / sigma^2).
```

The formula is `count ~ x + (0 + x | id)`, `sigma ~ 1`, and `sd(id, coef = "x") ~ z`. The fixed intercept in the formula matches the data-generating equation. The selected SD slope is `alpha_1 = 0.55`; the synthetic response contains only positive integer counts.

- `R/julia-bridge.R`: exact zero-truncated route predicate, offset refusal, fixed-effect fence exception, and canonical `sd` output-block label.
- `tests/testthat/test-julia-truncated-nbinom2-sd-bridge.R`: route and refusal tests plus one same-data TMB/Julia fit.
- `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/design/02-family-registry.md`, `docs/design/45-cross-dpar-correlation-gate.md`, `docs/dev-log/general-sd-regression/inventory.md`, `docs/dev-log/known-limitations.md`, `vignettes/formula-grammar.Rmd`, `vignettes/julia-engine.Rmd`, `vignettes/model-map.Rmd`, and `vignettes/predictor-dependent-random-sd.Rmd`: record the candidate route and its evidence boundary. The model-map and cross-dpar edits also correct the separate Hurdle NB2 wording found by review.
- `docs/dev-log/general-sd-regression/evidence/truncated-nbinom2-sd-julia-bridge-20261025/`: test console, source manifest, and result receipt.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and its generated summary: link one focused-test receipt to the existing Julia slope candidate row. The row remains `required` with `direct_sd_claim=none`.
- This report, the check log, and the active loop progress notes.

## 5. Checks Run

The source-bound bridge command used Julia 1.10.0 and the paired development checkout. It passed 22 expectations with zero failures or skips; one live Julia bridge test ran. The checks cover route admission and refusals, convergence, coefficient target labels, positive fitted SD-trend recovery within fixture-specific bounds, and finite positive group-SD outputs in each engine. The exact console output and hashes are recorded in the evidence directory above.

`pkgdown::check_pkgdown()` returned `No problems found`. Pandoc emitted its existing `--mathml` deprecation warnings. The evidence reconciler returned `EVIDENCE_RECONCILIATION_PASS` with 19,118 candidate rows, 60 linked rows, 19,058 unlinked rows, and 77 evidence records. This receipt links evidence only; it does not promote the candidate row.

The exact-draft prose linter reported zero findings for this report. A targeted
`git diff --check` passed for the touched implementation and documentation
paths. The current inventory's evidence counts were reconciled to the same
hash-checking output.

A broader native NB2 regression and quadrature filter was estimated at 30 to 60 seconds and stopped after it exceeded one minute while running the existing independent-slope recovery/quadrature test. That interrupted run is not counted as passing. The bridge test itself completed separately with the live Julia backend.

## 6. Tests of the Tests

Before the route predicate was added, the matching-slope check failed at the Julia fixed-effect-only fence. Review then caught an offset shape that the direct Julia fitter does not implement and a mismatch between the DGP intercept and fitted formula. The predicate now refuses offsets, the test asserts that refusal, and the formula includes the intercept used to generate the response. Negative checks also cover an unmatched SD group, a factor-valued slope, and separation from the Hurdle NB2 route.

## 7a. Issue Ledger

The merged fixed-effect bridge issue #1173 documents the older fixed-effect-only scope; this change adds a narrow SD route. The broad test-sweep issue #1463 is unrelated. No issue was opened, edited, or closed.

## 8. Consistency Audit

The mathematical equation, simulator, formula, and bridge admission checks use the same fixed intercept, numeric slope, group, and SD predictor. The Julia output model includes `mu`, `sd`, and `sigma`; the selected SD coefficient is exposed under its matching `sd()` target.

The exact status searches included:

```sh
rg -n -i 'truncated_nbinom2.{0,120}(fixed effects only|fixed-effect-only|no random.effect|random effects.*not|random.effect.*not)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/37-worked-example-inventory.md docs/design/41-phase-18-simulation-programme.md vignettes/formula-grammar.Rmd vignettes/julia-engine.Rmd vignettes/model-map.Rmd vignettes/predictor-dependent-random-sd.Rmd
rg -n 'truncated_nbinom2|zero-truncated NB2' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

The first search found no unqualified fixed-effect-only claim in those current status files. The second search confirmed the formula grammar and package inventory contain the narrow direct-SD route. Historical release notes remain dated records of earlier states.

## 9. What Did Not Go Smoothly

The standard lane preflight stalled while scanning refs and did not provide an ownership verdict. The focused diff and an independent read-only review were used to check the bridge section before continuing. The first live test exposed two incorrect test assumptions about the existing Hurdle route and Julia's `model$dpars`; both assertions were corrected. The native quadrature filter exceeded its stated time estimate and was stopped, so its result remains unverified in this run.

## 10. Known Residuals

The evidence is one complete-response synthetic independent-slope fixture. It does not establish numerical group-SD parity between Laplace and adaptive quadrature, interval calibration, profile/bootstrap integrity, or general zero-truncated NB2 support through Julia. The route admits an ordinary intercept shape in code, but this receipt covers the selected slope only. Correlated and structured effects, offsets, missing responses, predictor-dependent `sigma`, and broader Hurdle NB2 forms remain outside this slice. Both worktrees are dirty development candidates, not release builds.

## 11. Team Learning

For bridge routes that reuse a family fitter, test the family-specific no-extra-dpar rule and the generic fence separately. Review the DGP and fixed-effect formula side by side before setting recovery tolerances. Record a negative offset test whenever the receiving engine cannot carry fixed-coefficient offsets.

## 12. Cross-Product Coverage

This slice changes the R-to-Julia bridge and its family/output documentation.
It does NOT cover other zero-truncated NB2 coefficients or providers, native
TMB likelihood changes, missing responses, random `sigma`, profile/bootstrap
integrity, interval-coverage calibration, or full package/release checks. The
candidate evidence row remains unpromoted and all programme gates outside the
existing Bernoulli vertical slice remain open.

## Next Actions

Continue with the next unreceipted required capability row after checking ownership and source scope. Keep this Julia row unpromoted, interval coverage deferred, and all remaining programme gates open.
