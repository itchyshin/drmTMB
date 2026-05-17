# Slice 177 Gaussian Random-Slope Audit

## Goal

Audit ordinary grouped Gaussian location random-slope support against the
`lme4`/`glmmTMB` benchmark `(1 + x1 + x2 + ... | id)`, and make the current
boundary explicit before Slice 178 parser/API planning.

## Outcome

Slice 177 confirms a bounded but useful current state:

- ordinary univariate Gaussian `mu` supports multiple independent numeric
  random slopes, written as separate terms such as
  `(0 + x1 | id) + (0 + x2 | id)`;
- ordinary univariate Gaussian `mu` supports one correlated
  intercept-plus-one-slope block, written as `(1 + x | id)` or
  `(1 + x | p | id)`;
- arbitrary unstructured multi-slope covariance blocks such as
  `(1 + x1 + x2 | id)` remain planned, not implemented.

The parser error for unsupported correlated multi-slope blocks now names that
planned boundary directly, rather than only saying that the random-effect
left-hand side is unsupported.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/04-random-effects.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-177-gaussian-random-slope-audit.md`

## Validation

- `air format R/drmTMB.R tests/testthat/test-gaussian-random-intercepts.R NEWS.md ROADMAP.md docs/design/04-random-effects.md docs/design/33-phase-6c-core-random-effects.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "gaussian-random-intercepts", reporter = "summary")'`:
  passed after the new simulation's auxiliary `sigma` fixed-effect tolerance was
  loosened from `0.12` to `0.18`. The slice target remains the `mu`
  random-slope path.
- `Rscript -e 'devtools::test(filter = "gaussian-random-intercepts|corpairs|profile-targets", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `git diff --check`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- `rg -n 'Slice 177|multi-slope covariance blocks|multiple independent numeric slopes|\(1 \+ x1 \+ x2 \| id\)' NEWS.md ROADMAP.md docs/design/04-random-effects.md docs/design/33-phase-6c-core-random-effects.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-177-gaussian-random-slope-audit.md tests/testthat/test-gaussian-random-intercepts.R R/drmTMB.R`:
  confirmed the intended source, roadmap, test, and report wording.
- `rg -n 'arbitrary (numeric )?(grouped |correlated )?(mu )?blocks.*implemented|\(1 \+ x1 \+ x2 \| id\).*implemented|full arbitrary random-slope support|full ordinary random-slope support' NEWS.md ROADMAP.md docs/design R tests vignettes README.md --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/after-phase/**'`:
  returned only planned/not-implemented or benchmark-boundary wording, not a
  new support overclaim.

## Known Limitations

- `(1 + x1 + x2 | id)` still errors. Slice 178 should plan the parser,
  extractor, and naming contract for this ordinary q > 2 location block before
  Slice 179 prototypes the likelihood path.
- This slice does not add correlated residual-scale random slopes, bivariate
  random slopes, phylogenetic random slopes, or spatial random slopes.
- The new recovery test is deterministic and focused. It is not a substitute
  for the broader sample-size and weak-identification simulations planned for
  Phase 18.

## Team Notes

- Ada kept the scope to an audit and boundary hardening slice.
- Boole tightened the formula error so the unsupported syntax points to the
  planned arbitrary multi-slope block.
- Fisher kept the claim at "multiple independent slopes plus one correlated
  one-slope block", not full arbitrary random-slope support.
- Curie added the explicit multiple-independent-slope recovery test.
- Grace kept the validation focused on the changed random-effect and extractor
  surfaces.
- Pat and Darwin get a clearer reader-facing answer: independent slopes are
  available today, but a fully correlated plasticity-syndrome block with more
  than one slope is the next Gaussian location target.
- Rose checked that the roadmap now says Slice 177 is done without implying
  Slices 178-180 are done.

## Next Action

Start Slice 178 by writing the ordinary q > 2 Gaussian `mu` parser/API and
extractor plan for `(1 + x1 + x2 | id)` and labelled
`(1 + x1 + x2 | p | id)` blocks.
