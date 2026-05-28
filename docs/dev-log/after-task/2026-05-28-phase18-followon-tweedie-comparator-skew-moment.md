# After Task: Phase 18 Follow-On Tweedie Comparator And Skew-Normal Moment Decision

## Goal

Start the two-team follow-on after PR #347 merged. Team A hardens the fitted
Tweedie fixed-effect route with an optional `glmmTMB` comparator. Team B closes
the first skew-normal parameterization decision without adding
`skew_normal()`.

## Implemented

Team A added
`docs/design/126-phase-18-tweedie-comparator-contract-slices-1619-1628.md`
and an optional `glmmTMB` comparator test in
`tests/testthat/test-tweedie-location-scale.R`. The comparator contract is:

```text
beta_mu(drmTMB)         ~= beta_cond(glmmTMB)
2 * beta_sigma(drmTMB) ~= beta_disp(glmmTMB)
nu(drmTMB)             ~= power(glmmTMB)
logLik(drmTMB)         ~= logLik(glmmTMB)
```

This proves the first fixed-effect Tweedie route agrees with `glmmTMB` on the
overlapping model when public `sigma` is squared before comparing with
dispersion `phi`. It does not open predictor-dependent `nu`, random effects,
structured effects, bivariate Tweedie, zero-inflation aliases, or hurdle
aliases.

Team B added
`docs/design/127-phase-18-skew-normal-parameterization-decision-slices-1669-1672.md`.
The decision is to use public moment parameters for the first fitted
skew-normal lane:

```text
mu = E[y]
sigma = SD[y]
nu = alpha
```

The future likelihood may transform internally to native skew-normal `xi`,
`omega`, and `alpha`, but `fitted()` and `sigma()` should stay on the public
response scale. The design sync updated `docs/design/02-family-registry.md`,
`docs/design/03-likelihoods.md`,
`docs/design/06-distribution-roadmap.md`,
`docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md`,
`docs/design/41-phase-18-simulation-programme.md`, and `ROADMAP.md`.

## Checks Run

```sh
air format tests/testthat/test-tweedie-location-scale.R docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/06-distribution-roadmap.md docs/design/41-phase-18-simulation-programme.md docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md docs/design/126-phase-18-tweedie-comparator-contract-slices-1619-1628.md docs/design/127-phase-18-skew-normal-parameterization-decision-slices-1669-1672.md ROADMAP.md
git diff --check
Rscript --vanilla -e "devtools::test(filter = '^tweedie-location-scale$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(tweedie-location-scale|skew-normal-boundary|family-link-contract)$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n "current local design chooses the native|native location rather than the arithmetic|mu is native|native skew-normal location parameter|response-mean/response-SD parameterization is chosen|If that choice changes" docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md ROADMAP.md
rg -n "1619-1628|1669-1672|moment contract|glmmTMB::tweedie|2 \\* coef|sigma = SD|mu = E\\[y\\]" docs/design/126-phase-18-tweedie-comparator-contract-slices-1619-1628.md docs/design/127-phase-18-skew-normal-parameterization-decision-slices-1669-1672.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md
```

Results:

- Formatting completed and `git diff --check` was clean.
- `test-tweedie-location-scale` passed, including the optional `glmmTMB`
  comparator on this machine.
- The combined focused gate passed for Tweedie location-scale,
  skew-normal-boundary, and family-link-contract tests.
- `pkgdown::check_pkgdown()` reported no problems.
- The stale native-contract scan found no remaining old wording in the main
  skew-normal design files.
- The positive-evidence scan found the new slice IDs, moment-contract wording,
  and Tweedie comparator mapping in the design ledgers.

## Review

Ada kept the work on a clean branch from merged PR #347. Boole checked that
the public skew-normal syntax remains `mu`, `sigma`, and `nu`. Gauss and
Noether checked the Tweedie scale comparison and the skew-normal
moment-to-native transform. Curie kept the comparator test optional. Fisher
kept comparator agreement separate from simulation coverage claims. Grace ran
the focused validation. Rose checked that skew-normal remains design-only.

No spawned subagents were running.

## Next Action

Team A can extend the Tweedie comparator to low-zero and high-zero cells only
after this first optional comparator remains green in CI. Team B should next
draft the skew-normal density, normal-limit, sign-convention, and false-positive
test plan without adding C++ code.
