# After Task: Bivariate Meta-Analysis Known-Covariance Design

## Goal

Resolve the bivariate meta-analysis design issue: known within-study sampling
covariance and fitted residual or between-study correlation must be represented
as different model components.

## Implemented

- Added planned bivariate meta-analysis equations to
  `docs/design/08-meta-analysis.md`.
- Added the same likelihood contract to `docs/design/03-likelihoods.md`.
- Updated `docs/design/06-distribution-roadmap.md` with helper and sensitivity
  workflow targets.
- Updated `docs/design/05-testing-strategy.md` so future tests must distinguish
  known sampling correlation from fitted residual `rho12`.
- Added Mavridis and Salanti (2013) to `REFERENCES.bib`.
- Recorded this design decision in `docs/dev-log/check-log.md`.

## Mathematical Contract

For study or observation `i`:

```text
y_i = [y1_i, y2_i]'
mu_i = [mu1_i, mu2_i]'

y_i | mu_i, S_i, Omega_i ~ MVN(mu_i, S_i + Omega_i)

S_i =
  [v1_i,   c12_i;
   c12_i, v2_i]

Omega_i =
  [sigma1_i^2,                  rho12_i sigma1_i sigma2_i;
   rho12_i sigma1_i sigma2_i,   sigma2_i^2]
```

`S_i` is known sampling covariance from `meta_known_V(V = V)`. `Omega_i` is
unknown residual or between-study heterogeneity covariance. Therefore fitted
`rho12_i` is not the within-study sampling correlation.

The planned matrix stacking order is:

```text
y_stack = [y1_1, y2_1, y1_2, y2_2, ..., y1_n, y2_n]'
```

## Files Changed

- `REFERENCES.bib`
- `docs/design/03-likelihoods.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/08-meta-analysis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-bivariate-meta-known-covariance-design.md`

## Checks Run

- `rg -n "meta_known_V|known V|sampling covariance|bivariate|rho12" R docs/design vignettes tests README.md NEWS.md`
- `pdfinfo '/Users/z3437171/Downloads/mavridis-salanti-2012-a-practical-introduction-to-multivariate-meta-analysis.pdf'`
- `pdftotext '/Users/z3437171/Downloads/mavridis-salanti-2012-a-practical-introduction-to-multivariate-meta-analysis.pdf' - | rg -n -i "within-study|within study|correlation|covariance|bivariate|multivariate|known|variance" -C 2`
- `rg -n "Mavridis|Salanti|multivariate meta-analysis|Riley|Jackson" REFERENCES.bib docs/design/11-reference-programme.md vignettes docs`
- `rg -n "Planned Bivariate Meta|Mavridis|row-paired|meta_vcov_bivariate|S_i|Omega_i|within-study" docs/design REFERENCES.bib`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n 'meta_gaussian\\(\\)|tau ~|rho ~|Planned Bivariate Meta|row-paired|meta_vcov_bivariate|sampling correlation|residual' docs/design docs/dev-log REFERENCES.bib`

Results:

- `devtools::test()` passed: 572 tests, 0 failures.
- `pkgdown::check_pkgdown()` found no problems.
- `git diff --check` was clean.
- The final search found the new design terms and older intentional guardrails
  for rejected syntax.

## Tests Of The Tests

No tests were added because the likelihood was not implemented. The testing
strategy was updated so the future implementation must include simulation
tests where:

- within-study sampling covariance is supplied in `V`;
- residual or between-study covariance is generated separately through
  `sigma1`, `sigma2`, and `rho12`;
- fitted `rho12` is checked against the residual target, not the known
  sampling correlation.

## Consistency Audit

- The design keeps meta-analysis inside `family = gaussian()` or
  `family = c(gaussian(), gaussian())`.
- No `meta_gaussian()` family was introduced.
- No `tau ~` grammar was introduced.
- `V` remains the known sampling covariance input.
- `rho12` remains the canonical fitted bivariate residual correlation name.
- The planned helper `meta_vcov_bivariate()` is documented only as future
  helper syntax, not implemented behaviour.

## What Did Not Go Smoothly

The current formula grammar attaches `meta_known_V(V = V)` inside a location
formula, but in bivariate meta-analysis the marker is model-level rather than
specific to `mu1` or `mu2`. The design records the first workable syntax and
requires duplicate markers to be rejected. Boole should revisit whether a
cleaner model-level marker representation is needed before implementation.

## Team Learning

- Noether: the covariance equation must be fixed before parser work begins.
- Fisher: sampling correlation and residual correlation need separate recovery
  tests.
- Boole: model-level formula markers may need better internal representation
  for bivariate and later structured models.

## Known Limitations

- No bivariate known-covariance code was added.
- Missing outcome handling is deferred.
- Unknown within-study correlations should initially be handled through
  sensitivity analysis, not silent estimation.

## Next Actions

- Implement `meta_vcov_bivariate()` as a small helper after the syntax is
  approved.
- Add bivariate known-covariance likelihood support to the Gaussian bivariate
  TMB path.
- Add comparator checks against `metafor::rma.mv(...)` where parameterizations
  overlap.
- Add simulation recovery tests for known sampling correlation plus separate
  residual `rho12`.
