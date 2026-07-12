# After Task: MR-T1 Missing-Response Legacy Six

## Goal

Promote the six already admitted missing-response routes—univariate and
bivariate Gaussian, binomial, Poisson, NB2, and beta—from G1 to G3 using one
shared masking contract and route-specific recovery evidence.

## Implemented

The univariate residual methods now return `NA` for masked beta, binomial,
Poisson, and NB2 responses, matching the existing Gaussian contract. Beta
random-effect starts use observed responses without dropping the grouping
design. A shared test helper rebuilds the TMB objective with two family-valid
sentinels, checks objective and gradient agreement at `1e-8`, then optimizes
both retaped variants and checks parameters and log-likelihood at `1e-6`.

Each route has a fixed-seed recovery test with exactly 25% MCAR response
missingness. Gaussian, bivariate Gaussian, Poisson, NB2, and beta exercise an
already supported random-effect route; binomial remains fixed-effect because
binomial response random effects are not implemented. The tests recover every
fitted distributional parameter within the declared absolute tolerance.

## Mathematical Contract

For observed indicator \(r_i\), a univariate masked row contributes
\(r_i\ell_i(y_i;\theta)\). Changing the stored value of \(y_i\) when
\(r_i=0\) must therefore leave the taped objective, gradient, optimum, and
log-likelihood unchanged. A partial bivariate Gaussian row contributes the
appropriate univariate marginal; a row with both responses missing contributes
zero response likelihood.

## Files Changed

- `R/drmTMB.R` and `R/methods.R`: observed-response starts and residual masks.
- `tests/testthat/helper-missing-response.R`: direct retape and optimization
  contract.
- `tests/testthat/test-missing-response-*.R`: parity, accounting, boundaries,
  exact-MCAR recovery, and neighbouring rejections.
- `docs/dev-log/dashboard/capability-ledger/`: separate G2/G3 evidence and
  append-only transitions for the six routes.
- `tools/capability_ledger.py`: mechanical G2/G3 evidence gates.
- `NEWS.md`, `ROADMAP.md`, `docs/dev-log/known-limitations.md`, and generated
  capability/pkgdown artifacts: synchronized scope.

## Checks Run

- `devtools::test(filter = "missing-response")`: passed after the final
  repairs, including the new all-missing, invalid-support, and `cbind()`
  binomial cases.
- `devtools::test(filter = "missing")`: passed; two pre-existing
  beta-binomial missing-predictor optimization warnings and two unavailable
  Julia skips remained.
- `python3 tools/capability_ledger.py --check`: passed for 29 generated outputs.
- `python3 -m unittest tools.tests.test_capability_ledger`: 6/6 passed,
  including rejection of evidence-free G3 promotion.
- `Rscript --no-init-file tools/check-capability-runtime.R`: passed with 18
  routes, 6 verified and 12 at G0.
- `devtools::test()` with `NOT_CRAN=true`: passed the full post-MR-T1 package
  suite with no failures; 24 unavailable Julia routes skipped and 62 existing
  diagnostic, deprecation, and optimizer warnings were reported.
- `devtools::document()`: passed on the rebased head.
- `pkgdown::build_article("missing-data", new_process = FALSE)`: rendered the
  affected article from the live source package.

## Tests Of The Tests

The first independent review returned NOT DONE. It detected four recovery
designs that claimed 25% MCAR but used 20–22.2%, an evidence-free G3 loophole,
and missing response-boundary tests. Group sizes now permit exact 25% masking
and each test asserts the realized rate. The validator requires same-cell
passing G2 contract and G3 recovery records cited by the latest transition; a
negative unit test proves evidence-free promotion fails. New tests cover every
route's all-missing rejection, invalid observed beta/count/binomial responses,
and the admitted `cbind(success, failure)` binomial row contract.

## Consistency Audit

The audit searches were:

```sh
rg -n "response = \"include\"|missing non-Gaussian responses|only non-Gaussian response|Gaussian response masks|G1|none is verified" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/149-missing-data-design.md vignettes/missing-data.Rmd docs/dev-log/dashboard/capability-ledger
rg -n "G4|G5|coverage|inference_ready|supported|REML" NEWS.md ROADMAP.md docs/dev-log/known-limitations.md docs/dev-log/dashboard/capability-ledger vignettes/includes/capability-ledger-missing-response.md
```

The current public claims stop at G3. No formula grammar, likelihood
parameterization, interval, coverage, REML, missing-predictor, or structured
effect support claim changed.

## GitHub Issue Maintenance

Parent issue #761 already covers the whole MR-T0–MR-T7 arc. MR-T1 will update
that issue and its own PR rather than opening a duplicate.

## What Did Not Go Smoothly

The first recovery helper silently rounded the requested missing fraction down
within groups. The initial ledger validator also linked primary evidence but
did not enforce the evidence classes behind a G3 tick. Both defects were found
before the PR through adversarial review. A first standalone
`pkgdown::build_article()` subprocess loaded the older installed package and
failed on a now-supported NB2 predictor example; rendering in the live
`devtools::load_all()` process passed.

## Team Learning

Simulation helpers must assert the realized design, not only accept a requested
fraction. Capability validators must encode the evidentiary meaning of a gate;
state consistency alone cannot prove a scientific claim.

## Known Limitations

G3 is one fixed-seed recovery check per route, not replicated coverage.
Intervals and coverage remain G4/G5 and outside this arc. Dense known sampling
covariance with partial bivariate responses, response plus `mi()`, MNAR,
non-Gaussian REML, and new formula grammar remain unsupported.

## Next Actions

Land MR-T1 after its Ubuntu R-CMD-check, synchronize `main`, then begin MR-T2
continuous routes.
