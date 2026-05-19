# After Task: Slice 297 Ordinal Fixed-Effect ADEMP Sheet

## Goal

Create a one-page ADEMP design sheet for the admitted fixed-effect
`cumulative_logit()` Phase 18 lane before adding ordinal DGP helpers or broad
grids.

## Implemented

`docs/design/51-phase-18-ordinal-fixed-effect-ademp.md` now records the
fixed-effect ordinal simulation design in ADEMP order: aims, data-generating
mechanism, estimands, methods, performance measures, and a Williams-style
self-audit. The sheet defines the cumulative-logit category probabilities,
names cutpoint recovery and expected ordered-score summaries, and states that
the latent logistic scale remains fixed.

The Phase 18 blueprint and simulation README now link to the sheet. NEWS and
ROADMAP record Slice 297 as the fixed-effect ordinal ADEMP sheet.

## Mathematical Contract

No likelihood, formula grammar, simulation code, fitted model, extractor,
interval method, or test fixture changed. The sheet admits only fixed-effect
univariate `cumulative_logit()` location models. Ordinal random effects,
ordinal `sigma` or discrimination formulas, cutpoint-specific predictors,
known sampling covariance, bivariate ordinal models, and mixed-response
ordinal models remain failure-ledger rows.

## Files Changed

- `docs/design/51-phase-18-ordinal-fixed-effect-ademp.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-230415-codex-checkpoint.md`

## Checks Run

```sh
air format docs/design/51-phase-18-ordinal-fixed-effect-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
sed -n '1,280p' docs/design/51-phase-18-ordinal-fixed-effect-ademp.md
rg -n 'Ordinal Fixed-Effect ADEMP|cumulative_logit\(\)|cutpoint|expected ordered|expected-score|category probabilities|sigma|discrimination|random effects|mixed-response|500 replicates|Williams|Morris|Slice 297' docs/design/51-phase-18-ordinal-fixed-effect-ademp.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n 'ordinal random effects|scale/discrimination|cutpoint-specific|known sampling covariance|bivariate ordinal|mixed-response|DGP helper|fixed latent scale|sigma\(fit\)' docs/design/51-phase-18-ordinal-fixed-effect-ademp.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript tools/codex-checkpoint.R --goal "Slice 297 ordinal fixed-effect ADEMP sheet" --next "stage, commit, push, and open draft PR"
```

All checks passed.

## Tests Of The Tests

No executable tests changed. The design-contract scans check that the sheet
names `cumulative_logit()`, ordered cutpoints, expected ordered-score
summaries, fixed latent scale, malformed-input boundaries, and blocked ordinal
neighbours.

## Consistency Audit

The sheet follows the Slice 292 rule that admitted lanes get one-page ADEMP
sheets before new code. It agrees with the family registry and ordinal design
note: the implemented cumulative-logit path is univariate, fixed-effect,
location-only, and uses ordered cutpoints with a fixed latent logistic scale.

## What Did Not Go Smoothly

The broad scan for `sigma` necessarily returned many non-ordinal scale rows in
ROADMAP and NEWS. That was useful noise: the ordinal sheet now states directly
that `sigma(fit)` is a fixed unit vector here, not an estimated ordinal scale
surface.

## Team Learning

Ada kept the slice in the design lane. Pat checked that expected ordered scores
are described as model summaries rather than continuous measurements. Fisher
checked the Wald coverage and cutpoint-recovery scope. Curie checked that a new
ordinal DGP helper remains future work. Rose checked the blocked ordinal
neighbour list. Grace confirmed formatting, pkgdown, and whitespace checks. No
spawned subagents were used.

## Known Limitations

No simulation DGP helper, runner, result table, formal grid, or executable test
was added. The next implementation slice should add an explicit ordinal DGP
helper under `inst/sim/` before any broad ordinal report claims operating
characteristics.

## Next Actions

Continue the ADEMP sequence with bivariate Gaussian `rho12`, Student-t `nu`, or
structured-effect admitted subsets, or implement the ordinal DGP helper
described in this sheet.
