# After-task: Bernoulli/binomial response family first slice

## Task goal

Implement the first primary Bernoulli/binomial response route from
`drmTMB#569` without touching Claude-owned Ayumi, Gaussian density, penalty/MAP,
optimizer, or DRM.jl code. The supported model is:

```text
Y_i ~ Binomial(n_i, mu_i)
logit(mu_i) = X_mu[i, ] beta_mu
```

The first public claim is fixed-effect estimation plus `stats::glm()` parity
for overlapping logit likelihoods.

## Files created or changed

- `R/drmTMB.R`: accepts `stats::binomial(link = "logit")`, builds a fixed-effect
  binomial model spec, parses 0/1 and `cbind(successes, failures)` responses,
  stores trial metadata, and rejects unsupported neighbouring syntax.
- `src/drmTMB.cpp`: adds `model_type == 18` for the binomial logit likelihood
  with the binomial normalizing constant.
- `R/methods.R`: adds binomial behaviour for `simulate()`, `residuals()`,
  `sigma()`, `fitted()`, and link metadata.
- `tests/testthat/test-binomial-response.R`: adds deterministic GLM parity,
  method-surface, likelihood-constant, simulation, and malformed-neighbour
  tests.
- `DESCRIPTION`, `NAMESPACE`, and `R/drmTMB-package.R`: document the new family
  surface and import `stats::ave`, removing a package-check NOTE found during
  this pass.
- `README.md`, `NEWS.md`, `ROADMAP.md`, `docs/design/01-formula-grammar.md`,
  `docs/design/02-family-registry.md`, `docs/design/03-likelihoods.md`,
  `docs/design/06-distribution-roadmap.md`,
  `docs/design/19-family-link-contract.md`,
  `docs/design/24-denominator-response-syntax.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`,
  `docs/design/157-capability-completion-worklist.md`,
  `docs/design/168-r-julia-finish-capability-matrix.md`,
  `docs/dev-log/known-limitations.md`, and the source vignettes were updated so
  fitted/planned/unsupported claims agree.
- `docs/dev-log/dashboard/status.json`: updates the finish-board row for
  `drmTMB#569` from planned contract to active implementation evidence.

## Checks run

```sh
air format R/drmTMB.R R/methods.R tests/testthat/test-binomial-response.R
Rscript --vanilla -e 'devtools::document()'
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-binomial-response.R", reporter = "summary")'
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-family-link-contract.R", reporter = "summary")'
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R", reporter = "summary")'
python3 -m json.tool docs/dev-log/dashboard/status.json >/tmp/status-json-check-binomial.out
python3 tools/validate-mission-control.py
Rscript --vanilla -e 'devtools::test(reporter = "summary")'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
sh tools/start-mission-control.sh --background
npx playwright screenshot --full-page --viewport-size=1440,1200 http://127.0.0.1:8765/ /tmp/drmtmb-binomial-dashboard-desktop.png
npx playwright screenshot --full-page --viewport-size=390,1400 http://127.0.0.1:8765/ /tmp/drmtmb-binomial-dashboard-mobile.png
Rscript --vanilla -e 'devtools::check(error_on = "never")'
git diff --check
rg -n '^(<<<<<<<|=======|>>>>>>>)' . --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**'
rg -n 'planned `stats::binomial|planned plain|Planned Plain Binomial|Use the planned `stats::binomial|binomial response family \| planned|Not-yet-fitted.*binomial' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**'
```

Outcomes:

- `test-binomial-response.R`: passed.
- `test-family-link-contract.R`: passed.
- `test-julia-gate-vs-engine.R`: passed.
- Dashboard JSON parsed and validator passed:
  `mission_control_ok: 19/68 banked_or_verified, 3 active, 17 matrix rows, 10 finish rows, 15 Julia gate rows`.
- Full `devtools::test()` passed. It reported five existing Julia bridge or
  sigma-phylo skips and eight expected log-sigma-clamp warnings from the
  pathological scale-phylo test; no failures.
- `devtools::check(error_on = "never")` first reported one NOTE for missing
  `stats::ave`; the import was added, and the second run finished with
  `0 errors | 0 warnings | 0 notes` in 16m52s.
- `pkgdown::check_pkgdown()` is blocked by a Claude-owned penalty/MAP topic:
  `_pkgdown.yml` is missing `drm_phylo_penalty`. This branch deliberately did
  not touch that lane.
- Dashboard screenshots were captured at
  `/tmp/drmtmb-binomial-dashboard-desktop.png` and
  `/tmp/drmtmb-binomial-dashboard-mobile.png`.
- `git diff --check`: clean.
- Conflict-marker scan: clean.
- Stale binomial-planned scan: clean except for intentional unsupported
  boundary text such as `weights = trials` and `successes / trials`.

## Consistency audit

The implementation keeps the first slice narrow:

- accepted responses are explicit 0/1 event indicators and
  `cbind(successes, failures)`;
- `weights` remain row likelihood weights, not trial denominators;
- non-logit links, factor responses, proportions plus weights,
  `successes / trials`, `sigma`, `nu`, `rho12`, `zi`, `zoi`, `coi`, random
  effects, structured effects, bivariate or mixed responses, and
  `engine = "julia"` are rejected or documented as unsupported;
- beta-binomial, beta, zero-one beta, and binary missing-predictor evidence are
  not used to promote this row.

The touched docs describe the fitted first slice while keeping interval
calibration, random effects, structured effects, the Julia bridge, and speed
claims out of the public claim.

## Tests of the tests

The binomial test file checks both numerical and parser behaviour:

- coefficient, covariance, `logLik()`, AIC, and BIC parity with `stats::glm()`;
- independent `dbinom()` log-likelihood agreement for count responses;
- `predict()`, `fitted()`, `summary()`, `vcov()`, `confint()`, `sigma()`,
  `simulate()`, and `residuals()` surfaces;
- deterministic malformed-neighbour errors for proportions plus weights,
  factor responses, negative counts, non-logit links, `sigma` formulas, random
  effects, `mvbind()`, and `engine = "julia"`.

## What did not go smoothly

Local roxygen 7.3.2 regenerated unrelated manual-page drift
(`base::beta()` link target, package-author block, `stats::BIC()` link, and
`rho_latent()` examples). Those generated changes were backed out manually so
the branch only carries binomial documentation and the `stats::ave` import.

`pkgdown::check_pkgdown()` is not green yet because the current package exports
`drm_phylo_penalty` without a `_pkgdown.yml` reference entry. That belongs to
the Claude penalty/MAP lane and should be resolved there or in a separate docs
slice.

## Team learning and process improvements

Boole's contract decision held: base `stats::binomial(link = "logit")` is enough
for the first public route, and a future `bernoulli()` alias is unnecessary for
this slice. Gauss's likelihood decision held: including the binomial
normalizing constant makes `logLik()`, AIC, and BIC agree with `stats::glm()`.
Fisher's boundary held: the first claim is parity and fixed-effect estimation,
not interval calibration. Rose's dashboard rule helped catch stale planned
language before closeout.

## Design-doc updates

The family registry, likelihood registry, formula grammar, family-link
contract, denominator syntax note, pre-simulation matrix, completion worklist,
and R-Julia capability matrix now record plain binomial as implemented only for
the fixed-effect `mu` slice.

## pkgdown/documentation updates

Roxygen manuals were regenerated for `drmTMB()`, `simulate()`, `residuals()`,
and `sigma()`. The distribution-family guide, model map, formula grammar
article source, README, ROADMAP, NEWS, known-limitations ledger, and source map
now distinguish plain binomial from beta-binomial, beta/zero-one beta, and
binary missing-predictor imputation.

The pkgdown check remains blocked by the unrelated `drm_phylo_penalty` index
gap described above.

## GitHub issue maintenance

The consensus contract for `drmTMB#569` was already posted before code in the
finish-board/contract slice. This implementation branch opened draft PR
`#585`: <https://github.com/itchyshin/drmTMB/pull/585>. The implementation
ledger comment was posted to `drmTMB#569`:
<https://github.com/itchyshin/drmTMB/issues/569#issuecomment-4721271792>.

## Known limitations and next actions

- No binomial random effects.
- No binomial structured effects.
- No bivariate or mixed-response binomial.
- No Julia bridge promotion.
- No speed claim.
- No interval-calibration claim beyond the existing fixed-effect Wald method
  surface.
- Optional next evidence lane: Phase 18 `binomial_fixed_effect` artifacts with
  MCSE, convergence, `pdHess`, boundary, warning, failure, version, SHA, and
  elapsed-time fields.
