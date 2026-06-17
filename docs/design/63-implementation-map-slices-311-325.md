# Implementation Map Slices 311-325

This note turns the next implementation-map backlog into design gates. It does
not add likelihood code. The purpose is to make the next coding slices smaller,
more useful, and less likely to blur fitted and planned model surfaces.

## Active Roles

Ada coordinates the roadmap, docs, PR state, and validation. Boole watches
formula grammar and reference discoverability. Pat reads the map as an applied
PhD user who wants to know what to fit today. Darwin asks whether each future
surface answers a real ecological or evolutionary question. Fisher keeps
simulation admission behind evidence. Gauss and Noether keep q, covariance
blocks, and positive-definite constraints explicit. Grace watches pkgdown and
release hygiene. Rose records stale-claim risks and the team-learning loop.

No spawned subagents were running for this planning slice.

## Slice Table

| Slice | Lane | Status | User-facing result |
| --- | --- | --- | --- |
| 311 | Generic `sd*()` contract | Completed as plan | Future structured direct-SD syntax should use explicit level targeting, such as a future `level = "phylogenetic"` style, instead of adding parallel names for every structured layer. |
| 312 | Direct-SD ambiguity guard | Completed as plan | Ordinary `sd(group) ~ x` and future structured direct-SD routes must stay distinguishable in parsing, examples, and reference pages. |
| 313 | Direct-SD user migration | Completed as plan | Existing `sd_phylo*()` users should keep working; any generic spelling needs compatibility wording, examples, and stale-name scans before it is taught. |
| 314 | p8/q8 endpoint taxonomy | Completed as plan | The roadmap separates q2 slope-only, q4 location slope, q6 partial location-scale, and q8 all-endpoint slope covariance before any public syntax opens. |
| 315 | p8/q8 parameterization risk | Completed as plan | Full q8 unstructured covariance is high risk because it has eight SDs and 28 correlations; constrained or block-diagonal designs should be considered first. |
| 316 | p8/q8 diagnostics gate | Completed as plan | Any p8/q8 implementation needs profile-target labels, Hessian/boundary diagnostics, recovery tests, and tutorial warnings before user claims. |
| 317 | Structured q4 ordering | Completed as plan | Spatial q4 is the primary missing constant structured q4 parity lane; animal and `relmat()` q4 need continued diagnostics and simulation hardening rather than a new fitted claim. |
| 318 | q4 interval contract | Completed as plan | q4 rows remain estimates with explicit derived-unavailable interval status until a direct or derived-profile interval method is designed and tested. |
| 319 | Non-Gaussian candidate scoring | Completed as plan | Candidate non-Gaussian structured routes should be scored by family maturity, dependence layer, diagnostics, extractor impact, and user value before coding. |
| 320 | First candidate recommendation | Completed as plan | Start non-Gaussian structured dependence with one q1 `mu` structured intercept candidate, likely Poisson as an algebra smoke and NB2 as the practical count target, before slopes, zero inflation, or q4. |
| 321 | User-route examples | Completed as plan | The implementation map should tell users the nearest fitted route when their requested model is planned. |
| 322 | Implementation-map sync | Completed | The public implementation map now carries the 311-325 planning rows and user-route examples. |
| 323 | Roadmap, NEWS, and check-log | Completed | The public ledger records these as planning and documentation slices, not likelihood expansion. |
| 324 | After-task protocol | Completed | The after-task report records usefulness, standing roles, checks, and remaining boundaries. |
| 325 | Validation | Completed locally | pkgdown and stale-claim scans confirm the rendered map and guardrails. |

## Generic Direct-SD Contract

The current direct-SD surface is intentionally uneven:

- `sd(group) ~ x` models an ordinary group-level SD surface for unlabelled
  Gaussian `mu` random intercepts;
- `sd_phylo()`, `sd_phylo1()`, and `sd_phylo2()` are implemented phylogenetic
  direct-SD routes;
- spatial, animal, and `relmat()` direct-SD siblings remain planned.

The future generic route should not silently overload `sd(group) ~ x`. A safer
design is an explicit level-targeted grammar, for example a future spelling in
the spirit of:

```r
sd(species, level = "phylogenetic") ~ z
sd(site, level = "spatial") ~ z
sd(id, level = "animal") ~ z
sd(id, level = "relmat") ~ z
```

That is a design target, not accepted syntax. Before implementation, the team
must decide how bivariate endpoints are named, how old `sd_phylo*()` formulas
are documented, and how the reference index makes both ordinary and structured
SD models discoverable.

## p8/q8 Endpoint Taxonomy

The p8/q8 endpoint should not be treated as one obvious model. The roadmap
should distinguish:

| Endpoint class | Meaning | Status |
| --- | --- | --- |
| q2 slope-only | Two response-specific location slopes, such as `mu1:x` and `mu2:x` | Fitted for ordinary bivariate Gaussian `mu1`/`mu2` |
| q4 location slope | Intercepts and slopes for `mu1` and `mu2` | Source-tested ordinary group route with the `biv_gaussian_q4_location` smoke artifact lane |
| q6 partial location-scale | Selected location and scale slope endpoints, excluding some weakly identified pairs | Design-only |
| q8 all-endpoint slope | Intercepts and slopes across `mu1`, `mu2`, `sigma1`, and `sigma2` | First ordinary Gaussian slice is fitted with diagnostic smoke/recovery/staged-start artifacts; coverage, power, and interval calibration remain high-risk follow-up |

A full q8 unstructured block has eight SDs and 28 correlations. That can be
biologically interesting, but it is unlikely to be the first useful public
route without strong constraints, simulation evidence, and diagnostics.

## Structured q4 and Interval Contract

The safest structured q4 order is:

1. keep fitted phylogenetic, animal, and `relmat()` constant q4 status honest;
2. close the spatial constant q4 parity gap separately;
3. harden q4 diagnostics and simulation summaries before teaching q4 as a
   routine model;
4. leave q4 interval rows as derived-unavailable unless an interval method is
   explicit.

For users, the rule is simple: q4 `corpairs()` rows can be useful estimates,
but intervals are real only when `conf.status` and `interval_source` say they
are real.

## Non-Gaussian Structured Candidate Scoring

Before adding non-Gaussian structural dependence, score each candidate:

| Candidate | User value | Implementation risk | Suggested status |
| --- | --- | --- | --- |
| Poisson `mu` q1 structured intercept | Moderate; useful as a clean algebra smoke | Lower than NB2, but sensitive to overdispersion misspecification | First smoke candidate |
| NB2 `mu` q1 structured intercept | High for applied count data | Higher because overdispersion and structured SD can trade off | First practical candidate after Poisson smoke |
| Zero-inflated `mu` or `zi` structured effects | Sometimes useful, but easy to misidentify | High because count intensity and zero process can trade off | Defer |
| Hurdle `mu` or `hu` structured effects | Sometimes useful, but requires two-process interpretation | High | Defer |
| Ordinal structured effects | Useful, but cutpoints and latent scale need a separate contract | High | Defer |
| Bounded-response structured effects | Useful, but boundary mass and denominator issues matter | High | Defer |

The recommendation is to start with one q1 `mu` structured intercept, not
structured slopes, q4, zero inflation, hurdle probability, or cross-parameter
covariance. Poisson can be the algebra smoke; NB2 is the first practical count
target once the smoke route is stable.

## User-Route Examples

| If a user wants... | Fit now | Do not claim yet |
| --- | --- | --- |
| zero-inflated counts with covariates in the zero process | fixed-effect `zi ~ predictors` in the supported count family | random effects or structured dependence in `zi` |
| hurdle counts with a modelled hurdle probability | fixed-effect `hu ~ predictors` in hurdle NB2 | random effects or structured dependence in `hu` |
| phylogenetic or spatial count dependence | ordinary Poisson/NB2 `mu` random effects if a plain group is enough; otherwise treat structural count dependence as planned | `phylo()`, `spatial()`, `animal()`, or `relmat()` inside non-Gaussian likelihoods |
| full individual-difference location-scale slopes | the fitted q2 slope-only `mu1`/`mu2` route or smaller univariate pieces | p8/q8 location-scale slope covariance |
| structured direct-SD surfaces outside phylogeny | fitted structured intercept/slope SDs and `profile_targets()` where available | generic spatial, animal, or `relmat()` direct-SD regression |

This keeps the roadmap useful without turning planned syntax into accidental
public support.
