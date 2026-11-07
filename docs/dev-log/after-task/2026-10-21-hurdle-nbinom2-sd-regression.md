# After Task: Hurdle NB2 location SD regression

## 1. Goal

Add one bounded native hurdle NB2 route for a count-side location random
intercept whose SD may depend on fixed group-level predictors. Interval
coverage remains deferred under the approved implementation goal.

## 2. Implemented

For complete responses, a hurdle NB2 model may contain one ordinary `mu`
random intercept and, optionally, a matching `sd(group) ~ predictors` model.
The latent intercept contributes to the positive-count NB2 density and its
zero-truncation normalizer. `hu` remains a separate fixed-effect structural-zero
probability. The slice rejects random slopes, unsupported structured hurdle
terms, random effects on `hu` or `sigma`, and missing responses.

## 3a. Decisions and Rejected Alternatives

The new route reuses the ordinary truncated NB2 location-intercept and SD
machinery. It does not add a second hurdle-specific formula interface or change
the constant-SD parameterization. Random effects on the hurdle probability,
random slopes and structured effects stay out of this slice.

For group `g`, `u_g ~ Normal(0, tau_g^2)` and
`log(tau_g) = W_g alpha`. The count mean is
`log(mu_ig) = X_ig beta + u_g`; the hurdle-zero probability is determined by
the separate `hu` predictor. The random effect therefore enters only the
positive-count density and its zero-truncation normalizer.

## 4. Files Touched

- `R/drmTMB.R` and `src/drmTMB.cpp`: hurdle builder, parameter mapping,
  TMB data, latent-effect likelihood and extraction.
- `tests/testthat/test-hurdle-nbinom2-sd-regression.R` and
  `tests/testthat/test-hurdle-nbinom2.R`: seeded recovery, output/workflow
  checks and corrected boundary expectations.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
  `docs/design/18-random-effect-scale-models.md`,
  `docs/dev-log/internal-roadmap.md`, and
  `docs/dev-log/known-limitations.md`: current syntax and scope.
- `vignettes/count-nbinom2.Rmd`, `vignettes/formula-grammar.Rmd`, and
  `vignettes/implementation-map.Rmd`: examples and capability boundaries.
- `NEWS.md`, `docs/dev-log/check-log.md`,
  `LOOP/lanes/general-sd-regression/arcs.md`, and
  `LOOP/lanes/general-sd-regression/checkpoint.md`: development and progress
  records.

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "hurdle-nbinom2-sd-regression")'`:
  31 expectations passed.
- `Rscript -e 'devtools::test(filter = "hurdle-nbinom2")'`: 90 expectations
  passed across the hurdle NB2 tests.
- The count, formula-grammar, and implementation-map vignettes rendered from
  the current worktree. Pandoc reported its existing deprecated `--mathjax`
  option warning.
- `pkgdown::check_pkgdown()` reported no problems; it emitted existing Pandoc
  `--mathml` deprecation warnings.
- R source and the focused test file parsed successfully. The final diff check
  found an unrelated blank line at EOF in
  `tests/testthat/test-binomial-sd-integration.R`; that file was not edited.
- The read-only GitHub issue query could not connect to `api.github.com`; the
  issue tracker was left unchanged.
- Graft rebuilt its local graph successfully: 29,674 nodes and 58,252 edges.
- An independent read-only review found no blocking code issues.
- The structural after-task check passed. The full close-out compiler stopped
  during acceptance re-verification because the broader programme remains
  open; I did not bypass that gate or report programme completion.
- The focused `git diff --check` passed. The full dirty-worktree check also
  reports an unrelated trailing blank line in
  `tests/testthat/test-binomial-sd-integration.R`, which this task did not edit.

## 6. Tests of the Tests

The new focused test failed before the source change at the explicit hurdle
random-effect rejection. Its seeded data-generating model has known SD-regression
coefficients. The retained checks cover parameter recovery, constant-SD
equivalence, group-level SD prediction, conditional and marginal simulation,
save/reload prediction, and rejection of within-group-varying SD predictors.
The neighboring hurdle tests retain unsupported-input checks.

## 7a. Issue Ledger

No issue was changed. The read-only `gh issue list` query failed because the
GitHub API was unreachable, so issue matching remains unchecked.

## 8. Consistency Audit

The likelihood, formula grammar, capability table and examples now state that
the random intercept affects only the positive-count component. The current
formula grammar, known-limitations entry and internal roadmap distinguish this
route from diagnostic-only structured `hu` effects and unsupported broader
hurdle random-effect models. The goal remains open; this row does not establish
general family or Julia coverage.

Exact status scan:

```sh
rg -n -i 'hurdle.*(random|sd)|random.*hurdle' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/18-random-effect-scale-models.md vignettes/formula-grammar.Rmd vignettes/implementation-map.Rmd
```

## 9. What Did Not Go Smoothly

The first combined hurdle run exposed two old tests that expected all hurdle
count-side random effects to be rejected. Those expectations conflicted with
the newly supported intercept-only slice and were updated while unsupported
random slopes and other boundaries were retained. The route lookup had no
LOAD-FIRST manifest for this worktree or repository; package design docs and
repository instructions supplied the technical contract.

## 10. Known Residuals

This is one native TMB family/effect cell. It does not establish interval
coverage, Julia parity, structured effects, random slopes, random effects on
`hu` or `sigma`, incomplete-response support, or broader family support. No
production simulation campaign was run. The general-SD acceptance ledger still
has a live lease and remains open. The repository lane goal defers interval
coverage, but the active Codex app goal still lists calibrated uncertainty in
its finish line and says planning is read-only. The available goal tool only
supports complete or blocked status, so I did not falsely close or replace this
active goal.

## 11. Team Learning

When a hurdle route shares its family with a zero-truncated likelihood, state
which component contains the latent effect in both the likelihood notes and the
formula table. A generic “hurdle random effects” label hides the distinction
between count-side location effects and effects on the hurdle probability.

Memory receipt: the `shinichi-brain` search for the prior random-effect SD
design and the repository instructions informed the boundary. The route helper
found no LOAD-FIRST manifest for this worktree, so package design documents
remained the technical source. Golden Set: not run; the seeded recovery and
negative-input controls exercise this new hurdle path rather than a known
mistake fixture.

## 12. Cross-Product Coverage

This slice covers the native TMB fit, SD regression, group-SD prediction,
conditional and marginal simulation, coefficient extraction, save/reload, and
one complete-response ordinary hurdle NB2 `mu` intercept route. It does NOT cover
Julia parity, interval calibration, random slopes, structured effects, random
effects on `hu` or `sigma`, incomplete responses, or other families and
providers. The full programme remains open.
