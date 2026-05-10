# After Task: Next-Five Release Readiness Batch

## Goal

Complete five bounded tasks that move `drmTMB` toward Phase 9 closure and the
`0.1.0` public-preview gate without starting a large new likelihood feature.

## Implemented

| Task | Phase | Result |
| --- | --- | --- |
| O'Dea/Nakagawa Gaussian replication harness | Phase 7/8 validation, feeding Phase 17 | Added `tools/replicate-location-scale-gaussian.R` with fixed-effect and random-intercept Gaussian location-scale comparisons against `glmmTMB`. |
| Landing-page mobile/desktop audit | Phase 17 | Rebuilt pkgdown, added `pkgdown/extra.css`, and confirmed the mobile home page has no horizontal page overflow at 390 px. |
| Beta-binomial denominator syntax note | Phase 9 | Added `docs/design/24-denominator-response-syntax.md`; `cbind(successes, failures)` remains canonical until a helper alias is designed and tested. |
| Ordinal scale/discrimination note | Phase 9 | Added `docs/design/25-ordinal-scale-discrimination.md`; the preferred first extension is `sigma ~ ...` with `zeta = 1 / sigma` as a derived discrimination summary. |
| `0.1.0` release checklist artifact | Phase 17 | Added `docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md` as an issue-ready checklist. |

## Mathematical Contract

The comparator harness keeps `sigma` as the public fitted scale parameter. When
a paper-facing result needs residual variance or predictability, the derived
summary should use `sigma^2` rather than changing the model grammar.

For ordinal scale, the planned first extension is:

```text
Pr(y_i <= k) = logit^{-1}((theta_k - mu_i) / sigma_i)
log(sigma_i) = X_sigma[i, ] beta_sigma
zeta_i = 1 / sigma_i
```

For beta-binomial responses, the implemented likelihood uses successes and
failures, with `n_i = successes_i + failures_i`. A trials helper must be
equivalent to `cbind(successes, trials - successes)` after validation before it
becomes public grammar.

## Files Changed

- `README.md`
- `ROADMAP.md`
- `pkgdown/extra.css`
- `tools/replicate-location-scale-gaussian.R`
- `docs/design/02-family-registry.md`
- `docs/design/19-family-link-contract.md`
- `docs/design/24-denominator-response-syntax.md`
- `docs/design/25-ordinal-scale-discrimination.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md`

## Checks Run

- `air format tools/replicate-location-scale-gaussian.R`: passed.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- Chrome/Playwright visual audit of `pkgdown-site/index.html`: desktop
  screenshot checked; mobile viewport reported `innerWidth = 390`,
  `scrollWidth = 390`, and `bodyScrollWidth = 390`.
- `Rscript tools/replicate-location-scale-gaussian.R`: passed with all
  drmTMB/glmmTMB differences below `1e-4`.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

The replication harness fits independent `glmmTMB` models on the same simulated
data and checks fixed effects, residual-scale coefficients, random-intercept
standard deviation where present, and log-likelihood. The mobile audit used a
real browser viewport rather than the plain headless-Chrome screenshot path,
because plain headless Chrome laid out the page at a 500 px minimum width.

## Consistency Audit

The family registry, family-link contract, roadmap, README, and rendered
pkgdown home page now agree that public `sigma` remains the scale grammar,
paper-facing variance summaries are derived as `sigma^2`, `rho12` is the
residual bivariate correlation, and full O'Dea-style double-hierarchical
covariance remains planned rather than implemented.

## What Did Not Go Smoothly

The first mobile screenshot was misleading because plain Chrome headless used a
500 px layout viewport and cropped it to 390 px. Playwright with an explicit
390 px mobile viewport fixed the audit. One ad hoc R grep command also failed
because of string escaping; it was replaced with an `rg` scan.

After the first push, GitHub `R-CMD-check` failed on Ubuntu and Windows because
the beta-binomial boundary-pattern test expected optimizer convergence code
`0` for a deliberately near-separated dataset. The test intent was finite
boundary behaviour, not platform-identical optimizer status, so the follow-up
fix checks finite likelihood, coefficients, predictions, probabilities, and
`sigma()` instead. This is a process lesson: convergence-code assertions belong
in ordinary recovery or comparator tests, not in pathological boundary tests
unless convergence diagnostics are the target.

## Team Learning

Pat's landing-page concern produced a concrete accessibility fix: avoid dense
tables on the home page, and check actual mobile scroll width after rendering.
Boole's guardrail is that denominator-aware syntax needs one canonical meaning.
Fisher and Gauss now have a small executable comparator harness for the
Gaussian overlap with `glmmTMB`.

## Known Limitations

The harness is simulated replication scaffolding, not a full real-data
reproduction of every O'Dea/Nakagawa model. The denominator helper and ordinal
scale formula remain design notes until their parser, likelihood, tests,
documentation, and after-task report are implemented.

## Next Actions

Open the `0.1.0` checklist as a GitHub issue when the user wants release work
tracked publicly. For O'Dea/Nakagawa replication, the next step is to pin the
paper/tutorial datasets and translate each model into a table that records
whether the current `drmTMB` likelihood can fit it, whether only a derived
`sigma^2` summary is needed, or whether a future covariance block is required.
