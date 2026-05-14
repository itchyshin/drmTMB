# After Task: 35-Map Slice 11 Corpair Decision

## Goal

Decide whether the 35-slice route should move directly from reserved
`corpair()` syntax to predictor-dependent ordinary latent-correlation fitting.

## Implemented

The route now explicitly defers fitted predictor-dependent ordinary
`corpair()` models. The parser and `drmTMB()` clear-error boundary remain in
place, but slices 12 and 13 are not the next implementation target.

## Mathematical Contract

The design note records the unresolved q=4 ambiguity. In an ordinary q=4 block,
`class = "location-scale"` refers to four endpoint pairs:
`mu1`-`sigma1`, `mu1`-`sigma2`, `mu2`-`sigma1`, and `mu2`-`sigma2`. A fitted
predictor formula therefore needs either a class-wide shared-correlation model
or endpoint-specific syntax before the likelihood has a clear meaning.

## Files Changed

- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-14-map-slice-11-corpair-decision.md`

## Checks Run

- `air format docs/design/20-coscale-correlation-pairs.md docs/design/01-formula-grammar.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "package-skeleton|corpairs|biv-gaussian", reporter = "summary")'`:
  passed.
- `rg -n 'Route Decision: Predictor-Dependent|endpoint-selection contract|class-wide shared|endpoint-specific|q=4 block, `class = "location-scale"`' docs/design/20-coscale-correlation-pairs.md docs/design/01-formula-grammar.md`:
  confirmed the decision text.
- `git diff --check`: passed.

## Tests Of The Tests

No tests were added. The targeted test run keeps the current parser rejection,
`corpairs()` extraction, and ordinary bivariate q=4 behaviour green while the
design note records why fitted `corpair()` remains deferred.

## Consistency Audit

The changed design notes now agree with `R/drmTMB.R`, which still rejects
`corpair()` formulas and tells users that predictor-dependent latent
random-effect correlations come after constant ordinary q4 diagnostics are
stable.

## What Did Not Go Smoothly

The main risk was numbering drift between the branch-local check-log slices and
the user's 35-slice route. This report uses the 35-map slice number explicitly.

## Team Learning

Boole's syntax question matters before Gauss's likelihood work here. A formula
that names a class but not an endpoint can be readable as a reservation, but it
is too ambiguous to fit without another design decision.

## Known Limitations

Predictor-dependent ordinary `corpair()` models remain planned. The next active
route item is phylogenetic q=4 design against the tree precision.

## Next Actions

Proceed to 35-map Slice 14 and define the constant phylogenetic q=4 likelihood
contract before changing the TMB parameterization.
