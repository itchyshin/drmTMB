# After Task: Bernoulli coefficient-specific SDs on a shared group

## Goal

Allow native Bernoulli models to give separate predictor-dependent SD formulas
to distinct independent random-effect coefficients that share one grouping
factor.

## Implemented

Coefficient selectors now admit separate independent q=1 intercept and slope
terms on one group. A bare `sd(group)` remains ambiguous when multiple
coefficients share that group. Correlated terms remain outside this route.

## Mathematical Contract

For the admitted independent terms,

```text
b_0g ~ Normal(0, exp(W_0g alpha_0)^2)
b_1g ~ Normal(0, exp(W_1g alpha_1)^2)
eta_ig = X_ig beta + b_0g + x_ig b_1g
```

The two effects are independent. Each SD predictor must be constant within its
group. This slice does not change the likelihood or admit predictor-dependent
correlation.

## Files Changed

- `R/random-effect-targets.R`: optional same-group admission, enabled only by
  the native binomial adapter and limited to distinct independent q=1 terms.
- `tests/testthat/test-binomial-sd-target-selectors.R` and
  `tests/testthat/test-binomial-sd-integration.R`: identity/mapping checks,
  recovery, output checks, and a two-dimensional independent Laplace oracle.
- `docs/design/01-formula-grammar.md`,
  `docs/design/18-random-effect-scale-models.md`,
  `docs/dev-log/internal-roadmap.md`,
  `docs/dev-log/known-limitations.md`, `NEWS.md`,
  `vignettes/formula-grammar.Rmd`, and
  `vignettes/location-scale-scale.Rmd`: syntax and engine boundary.

## Checks Run

- `devtools::test(filter = "binomial-sd-target-selectors")`: 55 passed, no
  failures, warnings, or skips.
- `devtools::test(filter = "binomial-sd-integration")`: 381 passed, no
  failures, warnings, or skips, in 267.8 seconds.
- `rmarkdown::render()` of `vignettes/location-scale-scale.Rmd`: passed; Pandoc
  printed a non-fatal deprecated `--mathjax` option warning.
- `rmarkdown::render()` of `vignettes/formula-grammar.Rmd` with code evaluation
  disabled: passed; Pandoc printed the same deprecation warning.
- `pkgdown::check_pkgdown()`: no problems found. A full `pkgdown::build_site()`
  reached external dependency setup, then could not download Headroom from
  cdnjs because DNS was unavailable. The retry used a writable temporary R
  cache; no complete site was produced.
- `git diff --check`: passed.

## Tests Of The Tests

The new selector test failed before the resolver change with the expected
same-group rejection. The final integration test compares the fitted Laplace
objective with an independent two-dimensional clusterwise calculation and
checks recovery signs and coefficient-specific group SD predictions. A
negative test keeps correlated-block SD targets rejected.

## Consistency Audit

Checked Bernoulli SD wording in `README.md`,
`docs/dev-log/internal-roadmap.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`docs/design/18-random-effect-scale-models.md`,
`vignettes/formula-grammar.Rmd`, `vignettes/location-scale-scale.Rmd`, and
`_pkgdown.yml`. The site navigation needs no change. Docs identify the new
shape as native TMB only and retain the Julia one-term boundary.

Exact stale-wording search:

```sh
rg -n -i "Bernoulli.*one independent|multiple coefficients on one group|multiple coefficient SD|Bernoulli.*random-effect term|ordinary scalar native binomial intercept|independent intercept and slope|coefficient.selected SD" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md vignettes/formula-grammar.Rmd vignettes/location-scale-scale.Rmd _pkgdown.yml
```

## GitHub Issue Maintenance

Searched open `itchyshin/drmTMB` issues for `sd(group)` and random-slope SD
work. No issue specifically tracks coefficient-selected SD formulas for
separate independent terms on one group. No issue was created or changed.

## What Did Not Go Smoothly

The first selector run failed at the expected resolver fence. The required lane
preflight script is absent from this managed worktree, and the repository route
script has no manifest for it; no ownership was inferred from those failures.
The full site build needs an external asset that this environment could not
resolve.

## Team Learning

The compiled Bernoulli route already selects a scale row per latent coefficient
for independent terms, so this slice needed a guarded R target-admission change
and integration evidence rather than a new likelihood branch. Julia uses a
single-effect AGHQ implementation and needs its own multi-effect design.

## Known Limitations

Julia still requires one random-effect term and one SD formula. Predictor-
dependent SDs for correlated blocks, structured providers, other endpoints, and
interval calibration remain open. The full general SD-regression goal remains
active.

## Next Actions

Extend the Julia Bernoulli public route to coefficient-selected independent
terms sharing a group, with an independent numerical oracle, then continue the
family/effect/backend ledger and resolve the staged calibration protocol.

## Prose Assessment

Style: 2/10, medium confidence. Genre/coverage: short technical after-task
record, read in full. Evidence/repair: the phrases “native Bernoulli models”
and “one group” state scope directly; no repair needed. Gates: science = pass
against the tested independent-term likelihood; facts = pass against the check
outputs and Julia source boundary; references = not applicable. Provenance:
self-review of this report, version 1, 2026-10-18; related tests and design
notes were already seen.
