# Implementation Map Slices 341-355

These slices turn the pre-code specifications from Slices 326-340 into
implementation-ready issue templates and acceptance gates. They still do not
add likelihood code. Their purpose is to make the next code slices small enough
that a contributor can open one issue, implement one route, and know exactly
which tests, docs, diagnostics, and user-facing boundaries must move with it.

Applied users should benefit indirectly: every planned row should point toward
the nearest fitted route today, while every implementation issue should state
what evidence is required before the planned route becomes a fitted claim.

## Slice 341: Generic Direct-SD Issue Template

Create one issue template for future structured direct-SD syntax. The issue
must name the target level, the public formula grammar, the current compatibility
route, and the first supported endpoint.

Template fields:

- target layer: `phylo`, `spatial`, `animal`, or `relmat`;
- current fitted fallback: existing fitted structured SD, profile, or
  `sd_phylo*()` route where available;
- proposed syntax, including whether it is level-targeted or coefficient
  targeted;
- unsupported examples that should error before fitting;
- extractor rows that must appear in `profile_targets()`,
  `predict_parameters()`, `marginal_parameters()`, and reference docs;
- stale-name migration wording for users who already know `sd_phylo*()`.

Usefulness check: a user should never have to guess whether `sd(group)` means an
ordinary group-level SD or a structured direct-SD surface.

## Slice 342: Generic Direct-SD Acceptance Checklist

Before any generic direct-SD issue can close, the implementation must include:

- parser coverage for supported and rejected syntax;
- fit-time tests for the first supported endpoint;
- prediction/profile rows with stable labels;
- reference examples that identify the dependence layer;
- a rendered pkgdown scan for discoverability;
- stale-claim scans that keep `sd_phylo*()` compatibility and future generic
  syntax honest.

Usefulness check: a contributor can tell the difference between parser support,
fitted likelihood support, and documented user support.

## Slice 343: Direct-SD Migration And Stale-Scan Recipe

Record the migration path before implementation:

- keep current `sd_phylo()`, `sd_phylo1()`, and `sd_phylo2()` examples working
  unless a separate deprecation decision is made;
- introduce generic direct-SD examples only for fitted layers;
- keep ordinary `sd(group)` examples separate from structured direct-SD examples;
- scan README, `model-map`, `implementation-map`, reference topics, NEWS, and
  generated pkgdown pages for wording that says generic `sd*()` is already
  implemented before the first route lands.

Usefulness check: existing phylogenetic users keep a stable path, while new
users get one naming system only when it is real.

## Slice 344: p8/q8 Issue Template

Create a future issue template for all-endpoint location-scale slope covariance.
The issue must begin with a smaller endpoint class and justify why that class
comes before full q8.

Template fields:

- endpoint class: q2 slope-only, q4 location slope, q6 partial
  location-scale, or q8 all-endpoint;
- family and response scope, limited to one-response or two-response models;
- covariance structure: independent, block-diagonal, constrained, or full
  unstructured;
- parameter labels for SDs and correlations;
- direct versus derived interval policy;
- sample-size, group-count, covariate-spread, and boundary diagnostics;
- nearest fitted alternative for users today.

Usefulness check: a user asking for p8/q8 should learn which smaller fitted or
planned model answers the closest scientific question.

## Slice 345: p8/q8 Acceptance Checklist

Before p8/q8-related code is treated as fitted, it must have:

- recovery tests for each advertised endpoint;
- malformed-input tests for endpoint mismatches;
- `corpairs()` and `summary()$covariance` rows where correlations are fitted or
  derived;
- `profile_targets()` rows for direct SDs and explicit unavailable status for
  derived correlations without interval evidence;
- Hessian, boundary, and SD-ratio diagnostics in `check_drm()`;
- a short tutorial warning that full q8 covariance is data-hungry.

Usefulness check: fitted output should help users diagnose weak information
instead of hiding q8 fragility behind a large covariance table.

## Slice 346: Spatial q4 Issue Template

Create a spatial q4 parity issue template for constant location-scale spatial
intercepts. The issue must stay separate from mesh/SPDE work, spatial slopes,
and spatial direct-SD regression.

Template fields:

- required formulas for matching labelled `spatial()` terms in `mu1`, `mu2`,
  `sigma1`, and `sigma2`;
- coordinate validation and row matching;
- SD and derived-correlation names;
- `ranef("spatial_mu")`, `corpairs(level = "spatial")`, and
  `summary()$covariance` expectations;
- direct/derived interval status;
- smoke simulation and malformed-input cases;
- tutorial wording that points users to fitted q2 spatial or fitted q4
  phylo/animal/relmat alternatives today.

Usefulness check: spatial users get a clear q4 route without confusing it with
mesh models or non-Gaussian spatial dependence.

## Slice 347: Spatial q4 Acceptance Checklist

Spatial q4 can be advertised only when:

- the likelihood, parser, extractor, and diagnostic paths all agree on the same
  four endpoints;
- `corpairs()` reports six spatial latent-correlation rows with explicit
  interval provenance;
- `check_drm()` reports replication, boundary, and Hessian evidence;
- profile-target labels are direct for SDs and honest for derived correlations;
- pkgdown examples show a small fitted model and name what remains planned.

Usefulness check: the q4 row should answer a location-scale spatial question,
not merely add another covariance block to the output.

## Slice 348: Poisson Structured q1 Issue Template

Create the first non-Gaussian structured-dependence issue template for a q1
Poisson `mu` structured intercept. It is an algebra smoke target, not the whole
count-dependence story.

Template fields:

- one dependence layer only: `phylo()`, `spatial()`, `animal()`, or `relmat()`;
- non-zero-inflated Poisson family only;
- q1 `mu` intercept only, with no slopes, q2/q4 covariance, `zi`, `hu`, or
  cross-parameter covariance;
- log-link likelihood contract and conditional-mode interpretation;
- `sdpars$mu`, `ranef()`, `profile_targets()`, and `check_drm()` expectations;
- simulation recovery and boundary cases.

Usefulness check: count users get the first structural-dependence proof point
without the package implying that all count structural models are ready.

## Slice 349: Poisson Structured q1 Acceptance Checklist

The Poisson q1 issue can close only when:

- implementation and tests cover one named dependence layer;
- ordinary Poisson `mu` random effects remain separate from structured effects;
- zero-inflated, hurdle, slope, and q2/q4 requests error with helpful messages;
- simulation recovery checks estimate the structured SD under multiple group or
  site counts;
- docs and map rows call it a first slice.

Usefulness check: a user can run the exact supported model and see why nearby
models still belong to the roadmap.

## Slice 350: NB2 Structured q1 Issue Template

Create the practical count-dependence issue template for NB2 q1 `mu` structured
intercepts. This should follow the Poisson smoke or explicitly justify why it is
safe to implement first.

Template fields:

- one dependence layer only;
- NB2 `mu` structured intercept with fixed-effect `sigma`;
- overdispersion grid and SD-ratio diagnostics;
- separation from NB2 `sigma` random effects and zero-inflated NB2 random
  effects;
- extractor, profile-target, and `check_drm()` expectations;
- comparison to ordinary NB2 `mu` random effects as the nearest fitted route.

Usefulness check: NB2 users get a realistic ecological count model, but the
map still prevents a jump to structured slopes or zero-inflation layers.

## Slice 351: NB2 Structured q1 Acceptance Checklist

NB2 q1 structured dependence can be advertised only when:

- structured SD recovery remains stable across mild and strong overdispersion;
- ordinary group-level NB2 random effects and structured effects have distinct
  labels;
- `sigma` estimates and structured SD estimates are reported on their correct
  scales;
- zero-inflation and hurdle variants remain guarded;
- user docs give the ordinary NB2 fallback when a structured layer is too
  ambitious.

Usefulness check: applied users can decide whether the structured layer answers
their question better than a plain grouped count model.

## Slice 352: Non-Gaussian Structured ADEMP Gate

Before either Poisson or NB2 structured q1 enters Phase 18, write an ADEMP sheet
that records:

- aim: first structural-dependence count recovery, not full count parity;
- data-generating process: one family, one layer, q1 `mu` intercept;
- estimands: fixed effects, structured SD, response mean, and diagnostics;
- methods: fitted route plus nearest ordinary random-effect comparator;
- performance measures: bias, RMSE, coverage where intervals are available,
  convergence, Hessian status, warning/error ledger, and runtime;
- reporting: simulation artefacts, figure grammar, and failure-ledger rows.

Usefulness check: simulation should answer whether the first route is reliable,
not merely whether the optimizer returns a number.

## Slice 353: User Documentation Checklist

Every implementation issue from this set should update the user-facing map when
it changes fitted status:

- `vignettes/implementation-map.Rmd`;
- `vignettes/model-map.Rmd` when the family/component status changes;
- relevant tutorial or reference topic;
- README only when the feature becomes a stable or important first slice;
- ROADMAP, NEWS, check-log, and after-task report.

Usefulness check: users should find the same fitted-versus-planned answer from
the pkgdown article, README, roadmap, and function documentation.

## Slice 354: Review And Issue-Maintenance Checklist

Before closing a future implementation issue, run a role-specific review:

- Ada checks that code, tests, docs, pkgdown, roadmap, NEWS, and git tell one
  story;
- Boole checks formula grammar and parser errors;
- Gauss and Noether check likelihood and mathematical consistency;
- Fisher and Curie check recovery tests, diagnostics, and interval status;
- Emmy checks extractor labels, fitted-object structure, and S3/post-fit
  surfaces such as `corpairs()`, `summary()$covariance`, `profile_targets()`,
  `check_drm()`, `ranef()`, `sdpars`, and `corpars`;
- Pat and Darwin check the applied-user route and biological interpretation;
- Grace checks pkgdown, CI, and platform risk;
- Rose checks stale claims and after-task learning.

Usefulness check: the role names should expose review coverage, not decorate the
report.

## Slice 355: Validation And Handoff Gate

Close the issue-template set only after:

- pkgdown builds the implementation map and roadmap pages;
- rendered scans find the new slice rows and issue-template wording;
- stale-support scans find no false claims that generic `sd*()`, p8/q8, spatial
  q4, Poisson structured q1, NB2 structured q1, or broad non-Gaussian
  structured dependence are fitted;
- the after-task report records checks, issue-maintenance status, user value,
  known limitations, and the next code issue to open.

Usefulness check: the handoff should be enough for the next contributor to start
one implementation issue without rediscovering the whole roadmap.
