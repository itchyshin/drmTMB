# After Task: Arc 6 Association Public Alpha Intervals

## 1. Goal

Release the already-implemented two-stage association uncertainty at its
evidence-backed scope: alpha-scale standard errors and Wald confidence
intervals for every admitted frozen-margin pair route, with the retained
Bernoulli x ordinary-NB2 intercept cell marked inference-ready with caveats and
the remaining routes marked interval-feasible. Preserve failed and positive
campaign evidence, expose limitations as warnings or informative errors, and
repair the reader path without starting new compute or widening to eta-scale
inference.

## 2. Implemented

- `associate_pairs()` now stores the general two-stage Godambe alpha covariance
  while the original margin fits remain available.
- `vcov.drm_pair_association()` returns the named alpha covariance block and
  `confint.drm_pair_association()` returns coefficient-wise alpha-scale Wald
  intervals when fit-specific diagnostics pass.
- Both methods have dedicated reference topics, and the `associate_pairs()` and
  `biv_associate()` examples execute `sqrt(diag(vcov(assoc)))` and
  `confint(assoc)` so the public uncertainty path is visible from the fit page.
- The public interval applies to the five admitted intercept pair classes:
  Gaussian x Bernoulli, Gaussian x ordinary-NB2, Bernoulli x Bernoulli,
  Bernoulli x ordinary-NB2, and ordinary-NB2 x ordinary-NB2.
- The Bernoulli x ordinary-NB2 route also returns the full covariance and
  coefficient intervals for its admitted intercept-bearing fixed-effect
  association formula, including multiple predictors, factors, interactions,
  and explicit transformations.
- Near-boundary, uncalibrated, and lower-information results remain callable
  with explicit warnings. Boundary-unresolved or invalid covariance results
  fail with their recorded diagnostic reason and no clamp or placeholder
  interval.
- Runtime metadata distinguishes the route-level `capability_tier` from the
  exact `validation_domain`; `n >= 480` alone is explicitly not treated as a
  rule that classifies a user data set inside the retained F4R domain.
- A separate six-cell `association` capability axis records five exact
  `interval_feasible` cells and one
  `inference_ready_with_caveats` Bernoulli x ordinary-NB2 intercept cell. It
  does not inflate the 687 direct model-surface cells.
- The generated capability surface and local Mission Control status now expose
  the association axis. The Mission Control vault update was landed separately
  as local-only commit `a7cc62d`.
- The pkgdown learning path now restores all 36 vignettes to explicit navbar
  routes. It restores the function map as Get started, rho12 and staged
  association guides, the location-scale-scale Part 2 tutorial, and the error
  guide; removes the false Julia label from the association article; labels the
  Julia bridge as future support; makes meta-analysis findable by name; and
  separates user diagnostics from contributor validation pages.

## 3a. Decisions and Rejected Alternatives

- Treated the retained F4R PASS as permission to release the Bernoulli x
  ordinary-NB2 intercept capability at
  `inference_ready_with_caveats`, rather than blocking the API because the
  calibration grid does not classify every future user data set.
- Released the four other intercept routes and the Bernoulli x ordinary-NB2
  association regression at `interval_feasible`, with coverage limitations in
  warnings and documentation. Rejected the prior blanket fail-closed public
  policy because it contradicted the positive method evidence.
- Kept intervals on the alpha coefficient scale. Rejected transforming Wald
  endpoints into eta intervals because the current evidence and contract do
  not validate that target.
- Kept fit-specific numerical failures fail-closed. Rejected probability
  clipping, covariance repair, numerical clamps, retries, and placeholder
  intervals.
- Added association as a separate capability axis. Rejected adding six staged
  post-fit routes to the direct model-surface census because they are not new
  joint likelihood cells.
- Repaired clear navbar regressions now, but rejected a full information-
  architecture redesign in this implementation PR. Stable article URLs remain
  unchanged.

## 3b. Mathematical Contract

For the full staged parameter

\[
q=(\theta_1^\top,\theta_2^\top,\boldsymbol\alpha^\top)^\top
\]

and per-row stacked estimating equation \(U_i(q)\), the stored covariance is

\[
H=-n^{-1}\sum_i \frac{\partial U_i}{\partial q^\top},\qquad
J=n^{-1}\sum_i U_iU_i^\top,\qquad
\widehat{\operatorname{Var}}(\widehat q)
=n^{-1}H^{-1}JH^{-\top}.
\]

`vcov()` returns the alpha block. `confint()` reports

\[
\widehat\alpha_j \pm z_{1-\gamma/2}
\operatorname{SE}(\widehat\alpha_j).
\]

These are intervals for the unbounded association-link coefficients `alpha`,
not the bounded latent association `eta = 0.999999 * tanh(X_A alpha)`. The two
margin fits remain frozen; this is not a joint maximum-likelihood fit and the
conditional stage-2 Hessian is not substituted for the Godambe covariance.

## 4. Files Touched

- Public implementation and methods: `R/associate-pairs.R`,
  `R/associate-pairs-sandwich.R`, generated association help pages, focused
  tests, and snapshots.
- Evidence and design alignment: `NEWS.md`,
  `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
  `docs/design/236-arc6-6-bernoulli-nbinom2-contract.md`, the F4/F4R receipts,
  and `docs/dev-log/known-limitations.md`.
- Capability surface: the ledger schema, cells, evidence, transitions,
  generator, generator tests, README, and generated Markdown/HTML surface.
- User guidance and navigation: `_pkgdown.yml`,
  `vignettes/capability-and-limits.Rmd`, `vignettes/cross-family.Rmd`,
  `vignettes/bivariate-nongaussian.Rmd`,
  `vignettes/function-map-cheatsheet.Rmd`, `vignettes/convergence.Rmd`,
  `vignettes/drmTMB.Rmd`, and `vignettes/model-workflow.Rmd`.

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "associate-pairs", reporter = "summary", stop_on_failure = FALSE)'`
  passed the complete association test family with `DONE` and exit status 0.
- `python3 -m unittest tools.tests.test_capability_ledger` passed 46 tests.
- `python3 tools/capability_ledger.py --check` passed for all 30 generated
  outputs.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgdown::build_site(new_process = FALSE)'`
  completed successfully after the final navigation and article corrections.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgdown::check_pkgdown()'`
  returned `No problems found`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::document()'`
  completed without warnings, and `pkgdown::build_reference()` rendered and
  executed both new SE/CI examples plus the dedicated `vcov()` topic.
- `git diff --check` passed.
- A direct navigation inventory found 36 vignette sources, 36 unique navbar
  article targets, no missing vignette, and no target without a source.
- Rendered searches confirmed the restored Part 2, rho12, staged-association,
  error, implementation-status, meta-analysis, and future-Julia labels and
  found no stale current association denial or one-slope-only wording.
- Fisher passed the final inference-scope review. Pat and Rose passed the final
  rebuilt reader/navigation review with no remaining blocker.

## 6. Tests of the Tests

- The public-method tests call the real five-class sandwich router rather than
  injecting a covariance fixture.
- Positive tests check covariance dimensions, coefficient names, finite
  positive standard errors, subset selection, and agreement of Wald endpoints
  with the stored alpha covariance.
- Negative tests retain boundary-unresolved, malformed covariance, unsupported
  eta/profile targets, and pre-public-object failures; they assert that no
  downstream placeholder interval is produced.
- Route tests were updated from historical expected errors to real `vcov()` and
  `confint()` calls, so the new surface is exercised instead of inferred from
  S3 registration.
- Capability-ledger tests assert the independent association axis, six-row
  count, exact tier split, and non-inflation of the direct model-surface census.

## 7a. Issue Ledger

Open-issue searches for `association pair`, `cross-family`, `rho12`,
`associate_pairs`, pkgdown navigation, and vignettes found no open issue that
matched this combined public-interval and navigation closeout. The issue
tracker was therefore left unchanged rather than opening a duplicate. The pull
request will carry the implementation, evidence, and navigation summary.

## 8. Consistency Audit

The current status inventory was inspected in `README.md`, `ROADMAP.md`,
`NEWS.md`, `docs/dev-log/known-limitations.md`,
`docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
`vignettes/formula-grammar.Rmd`, the association/bivariate vignettes,
`_pkgdown.yml`, and the rebuilt site. Historical receipts were retained and
given explicit supersession notes rather than rewritten.

Exact current-surface searches included:

```sh
rg -n -i "does not provide interval|one numeric association|single numeric association|Cross-family bivariate \\(Julia\\)|Running models with the Julia engine|Improving convergence|multiple association.*unsupported|new-data association prediction.*unsupported" _pkgdown.yml vignettes NEWS.md R man docs/design docs/dev-log/known-limitations.md
rg -n "Errors, warnings, and convergence|Association between outcome pairs|Residual correlation with rho12|Joint and staged bivariate models|location-scale-scale" _pkgdown.yml vignettes pkgdown-site
rg -n -i "association.*point.*only|associate_pairs.*unavailable|no standard errors|no intervals|vcov.*unavailable" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md vignettes man _pkgdown.yml pkgdown-site
```

Remaining matches were historical NEWS statements or valid boundaries such as
point-only eta/new-data association prediction, not stale denials of the new
coefficient-level interval surface.

## 9. What Did Not Go Smoothly

- The first public wording was too restrictive because it treated positive F4R
  evidence as insufficient to release a scoped capability. The owner taxonomy
  corrected this: positive scoped evidence enables the capability at that
  scope, with caveats and warnings attached.
- The first article pass exposed stale negative claims and an obsolete
  one-numeric-slope description even though the code already admitted a full
  fixed-effect model matrix. Pat and Rose caught both before closeout.
- The first rendered review failed because source files were newer than the
  pkgdown HTML. A full rebuild, not a selected-page build, was required because
  navbar configuration is embedded in every page.
- The navigation audit showed that a prior reorganization had preserved files
  but made several important guides hard to find or misleadingly labelled.
  The repair was kept to clear, reversible reader-path corrections; a deeper
  information-architecture redesign remains separate.

## 10. Known Residuals

- Association intervals are coefficient-level alpha Wald intervals. Eta-scale
  intervals, profile intervals, and simultaneous/new-data association bands
  remain unavailable.
- Only the retained Bernoulli x ordinary-NB2 intercept grid has coverage-backed
  `inference_ready_with_caveats` evidence. Other pair classes and the broader
  Bernoulli x ordinary-NB2 association regression are interval-feasible and
  warn that coverage is uncalibrated.
- The F4R grid does not create an observable universal rule for prevalence,
  dispersion, association strength, or sample size. The lower-information F4
  failures remain retained and visible.
- Random effects, missing pairs, weights, offsets, REML, and generic family-pair
  association formulas remain outside the public interval contract.
- The broader pkgdown information architecture, article lengths, duplicated
  teaching material, and consistent page-title policy still warrant a separate
  whole-site audit.

## 11. Team Learning

- Capability tier and user-data classification are different objects. Store
  the route-level tier and exact validation domain, and let runtime warnings
  explain that a simple observable such as sample size does not prove domain
  membership.
- A callable interval method is enough for `interval_feasible`; coverage
  calibration promotes it. Uncalibrated coverage belongs in warnings and docs,
  not in a blanket API block.
- Navbar changes require a full rendered-site inspection because every page
  embeds the same menu. Source-only review cannot close a navigation repair.
- Article inventories should compare source vignettes, explicit navbar targets,
  and rendered files. This caught the location-scale-scale orphan directly.

## 12. Cross-Product Coverage

This arc covers fixed-effect, complete-pair, ML frozen-margin association
objects for the five admitted pair classes, their alpha coefficient covariance,
their alpha Wald intervals, documented warnings, capability-ledger rows, and
the corresponding reference/article surface. For Bernoulli x ordinary-NB2 it
also covers the admitted intercept-bearing fixed-effect association model
matrix and coefficient block.

It does NOT cover eta-scale intervals, profile likelihood, simultaneous or
new-data association bands, random or structured effects, missing response
pairs, missing association predictors, weights, offsets, aggregation, REML,
penalized/MAP estimation, Julia fitting, direct `rho12` implementation changes,
generic family-pair admission, or coverage promotion outside the exact retained
F4R grid. It changes no margin likelihood, TMB template, optimizer, simulator,
or direct bivariate covariance provider.

## 13. Next Actions

1. Open the focused Arc 6 public-interval and navigation pull request, wait for
   package/docs CI, and address any real failures before merge.
2. In a later dedicated documentation arc, audit the full pkgdown learning
   architecture and consolidate the three bivariate pages into an explicit
   ordered reader path without changing their stable URLs.
3. Calibrate additional pair routes and association-regression cells; promote
   each exact cell from interval-feasible only when its retained evidence
   supports the next tier.
