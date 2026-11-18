# After Task: Native Gamma sigma-endpoint SD regression

## Goal

Add and verify a general predictor-dependent SD for a Gamma random effect,
beginning with the identifiable ordinary `sigma` random-intercept case.

## Implemented

The native Gamma builder now resolves `sd(group, dpar = "sigma")`, builds its
group-level fixed-effect design, initializes and maps the `beta_sd_sigma`
parameters, and passes those scales to the existing Gamma likelihood. Public
coefficient extraction and group/conditional prediction use the shared
sigma-endpoint methods. The route is intentionally bounded to complete data,
fixed-effect `mu`, one independent unlabelled `sigma` random intercept, and an
SD predictor constant within group.

## Mathematical contract

For observation `i` in group `g`,

```text
Y_ig | b_g ~ Gamma(shape = sigma_ig^(-2), scale = mu_ig * sigma_ig^2)
log(sigma_ig) = X_sigma,i beta_sigma + b_g
b_g | W_g ~ Normal(0, tau_g^2)
log(tau_g) = W_g alpha
```

Gamma `sigma` is the response coefficient of variation. `sd(group,
dpar = "sigma")` models the SD of the latent random intercept added to
`log(sigma)`. It does not model the response-level CV directly or add a free
residual scale. The synthetic recovery test draws this hierarchy independently
with `shape = 1 / sigma^2` and `scale = mu * sigma^2`.

## Files changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-gamma-sigma-sd-regression.R`
- `docs/dev-log/general-sd-regression/gamma-sigma-contract.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/internal-roadmap.md`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `NEWS.md`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-21-gamma-sigma-sd-regression.md`
- this report

## Checks run

The focused Gamma recovery/output test passed. The adjacent
`gamma-(location-scale|sigma-sd-regression)|lognormal-sigma-sd-regression`
filter passed. The current-source predictor-SD vignette rendered to
`/private/tmp/predictor-dependent-random-sd-gamma-sigma-current.html`; Pandoc
reported only the existing deprecated `--mathjax` option. `git diff --check`
passed for the reviewed changes. No live Julia engine ran.

## Tests of the tests

The positive recovery test first failed at the Gamma formula guard before the
implementation was connected. After implementation it recovers the seeded
SD intercept and slope, checks finite covariance and public outputs, and
compares the constant-SD formula with the legacy Gamma sigma-intercept fit.
The negative test changes the predictor within group and requires an explicit
`constant within` error. These checks exercise both fitted behavior and the
design restriction.

## Consistency audit

The symbolic contract, R formula, C++ scale use, extraction, and prediction all
refer to the SD of the latent log-CV random intercept. Formula grammar,
likelihood design, random-effect-scale design, known limitations, NEWS,
roadmap, and the predictor-SD vignette now state the same narrow native
boundary. The full predictor-SD vignette rendered after the accidental shared
Gaussian-builder hunk was restored. The inventory scan found no target-specific
README, formula-grammar vignette, or pkgdown-navigation entry requiring a
change.

## GitHub issue maintenance

Open issue #1551 was reviewed. It concerns a separate Julia bridge failure for
ordinary Gamma/Poisson mean random intercepts, not predictor-dependent SDs on
the Gamma sigma endpoint. No comment, issue, or closure was appropriate.

## What did not go smoothly

An early broad patch matched the Gaussian builder instead of Gamma and
temporarily disrupted structured-SD parsing. The full vignette render exposed
it. I restored the unintended Gaussian and sparse-design edits, preserved the
pre-existing animal selector, reran the current-source render successfully,
and then reran the neighboring Gamma/LogNormal tests. Anchor repeated-code
patches on the family builder and inspect the complete diff immediately.

## Team learning

The Gamma log-CV likelihood accepts the shared group-row SD design without a
new density branch: the existing log-sigma random-effect contribution already
uses the per-group scale. Reusing that path keeps the likelihood and output
semantics aligned. The next improvement is to use family-scoped patch context
for repeated builders and to keep native and Julia endpoint status separate.

## Design-doc updates

The Gamma `sigma` endpoint interpretation and supported boundary were added to
the formula grammar, likelihood design, random-effect-scale design, known
limitations, internal roadmap, and the local symbolic contract. Coverage and
Julia support remain explicitly unverified.

## Documentation and pkgdown

The predictor-dependent-SD vignette now includes an independent synthetic
Gamma example and rendered successfully from current source. NEWS records the
new native slice. No navigation change was needed. `pkgdown::check_pkgdown()`
passed with no problems; its output contained existing deprecated `--mathml`
warnings. A full site build was not run in this slice.

## Known limitations and next actions

This verifies one native TMB Gamma sigma-intercept SD-regression cell. It does
not establish Julia parity, other Gamma sigma random-effect forms,
mu/sigma-crossed random effects, bootstrap-refit integrity, or interval
coverage. Continue with the next uncovered family/effect/backend row; the
general programme and its gates remain open.
