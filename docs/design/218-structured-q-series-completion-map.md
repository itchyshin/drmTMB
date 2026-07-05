# Structured Q-Series Completion Map

## Purpose

The structured random-effect q-series needs a single unit of truth. Earlier
work advanced through high-value cells: Ayumi q4 phylo point fits, q2 bridge
fixtures, q8 ordinary diagnostics, q1 bridge parity, and the first count q1
routes. That produced useful evidence, but the evidence landed in different
places: formula grammar, helper tables, dashboard sidecars, design notes, PR
text, and bridge tests.

The completion rule from this point is:

1. add or update the support-cell row first;
2. code only the exact formula/provider/endpoint/route described by that row;
3. test the row at the matching evidence tier;
4. update dashboard, docs, and PR wording against the same row;
5. promote public wording only when the row reaches `supported`.

The validator-owned source table is:

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`

This table complements, but does not replace,
`docs/dev-log/dashboard/structured-re-balance-matrix.tsv`. The older matrix is
the coarse structured random-effect status board. The q-series table is the
finer completion map that names exact formula cells, endpoint sets, slope
classes, routes, estimator labels, interval status, coverage status, and claim
boundaries.

## Support-Cell Schema

Every row must include these fields:

- `cell_id`
- `formula_cell`
- `family_class`
- `family`
- `structure_provider`
- `dimension_pattern`
- `endpoint_set`
- `slope_class`
- `covariance_layout`
- `route`
- `estimator_requested`
- `estimator_effective`
- `fit_status`
- `extractor_status`
- `bridge_status`
- `interval_status`
- `coverage_status`
- `authority_status`
- `evidence_url`
- `claim_boundary`
- `denominator_policy`
- `next_gate`

The extra `next_gate` field is not a capability claim. It is the work queue for
the next evidence transition. It exists so a row does not hide why it is still
planned, diagnostic-only, or blocked.

Allowed evidence tiers are:

`planned/unsupported` -> `parser-ready` -> `point-fit` ->
`extractor-ready` -> `fixture-parity` -> `interval-feasible` ->
`inference-ready` -> `supported`

The TSV uses underscore spellings for machine checks:

`planned`, `unsupported`, `parser_ready`, `point_fit`, `extractor_ready`,
`fixture_parity`, `interval_feasible`, `inference_ready`, `supported`.

Two local guard statuses are also allowed:

- `diagnostic_only`: the route can be inspected but does not support interval
  reliability, coverage, or power wording.
- `blocked`: the row has a named blocker and must not be promoted by adjacent
  evidence.

## Current Evidence Boundary

The current table records these broad facts without promoting beyond them:

- Gaussian structured intercept support is present across `phylo()`,
  `spatial()`, `animal()`, and `relmat()` for univariate `mu`, univariate
  `sigma`, matched `mu+sigma`, bivariate `mu1+mu2`, and constant all-four q4
  point/status cells.
- The spatial, animal, and relmat q1 `sigma` and matched `mu+sigma` intercept
  cells now have provider-scoped deterministic fixture-parity contracts plus
  separate native point-fit evidence. This does not promote range-estimating
  spatial support, pedigree/Ainv or Q precision bridge marshalling, intervals,
  coverage, REML, AI-REML, or labelled covariance support.
- One independent Gaussian structured `mu` slope has point-fit and
  deterministic same-target fixture evidence across `phylo()`, `spatial()`,
  `animal()`, and `relmat()`.
- The first independent structured residual-scale slope cells are open for
  `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and `relmat()`
  as native point-fit/extractor cells with deterministic same-target fixtures;
  the `relmat()` row also has runtime K/Q target parity. Matched `mu+sigma`
  one-slope location-scale cells are now native point-fit/extractor cells for
  the same four providers with deterministic same-target fixture evidence;
  intervals, coverage, REML, AI-REML, and broad bridge promotion remain
  planned.
- Bivariate Gaussian structured slope-only q=2 `mu1`/`mu2` covariance cells
  now have native point-fit/extractor evidence plus deterministic same-target
  fixtures across `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`,
  and K-matrix `relmat()`. The exact phylo and relmat q2 slope rows have also
  reached `inference_ready` for interval and coverage status through the
  default small-sample `confint()` correction. The spatial and animal q2 rows
  remain future row-level arcs; the pooled all-provider g=8 engine coverage is
  not a promotion of those rows. These are exact `mu1:x+mu2:x` cells only; they
  do not promote intercept-plus-slope q4/q8, `supported`, REML, AI-REML,
  range-estimating spatial support, pedigree/Ainv bridge marshalling, or relmat
  Q bridge marshalling.
- Q2 bridge fixture evidence is banked only for complete-response
  exact-Gaussian ML fixtures: phylo, fixed-covariance spatial, animal A-matrix,
  and relmat K-matrix.
- Phylo q4 point parity and extractor evidence exist, but q4 interval
  reliability, q4 interval coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,
  HSquared AI-REML, and non-Gaussian AI-REML remain outside support.
- The animal all-four one-slope row is q8-shaped in the implementation: the
  shared labelled block has eight endpoints and 28 `theta_phylo` coordinates.
  Existing bounded, one-theta, MAP/penalty, and ridge-continuation diagnostics
  localize the free-correlation blocker, and the local partial-Cholesky
  coordinate diagnostic attempted the three hard seeds but produced zero clean
  all-free admission passes. These diagnostics do not supply a production
  transform. The next gate is the lower-level TMB/C++ parameterization design in
  `docs/design/220-structured-q4-animal-production-transform-gate.md`, followed
  by objective/report equivalence tests and a new local hard-seed admission
  runner before any Totoro, Nibi/Rorqual, or DRAC work.
- Ordinary q6/q8 diagnostic routes do not imply structured q6/q8 support.
- Poisson and NB2 q1 structured `mu` intercept and unlabelled one-slope rows
  are first non-Gaussian point-fit slices. They do not imply pure, multiple, or
  labelled non-Gaussian structured slopes, zero-inflated structure, structured
  count scale routes, q2/q4, REML, AI-REML, interval support, or coverage.
- The ordinary count one-slope rows now have an explicit fixture/recovery
  contract sidecar. It records existing native TMB ML/Laplace point-fit and
  extractor evidence, while native deterministic fixture status is
  `native_fixture_banked`; native fixture status is not bridge parity. The
  earlier recovery-runner contract, dispatch preflight, and shard-pack sidecars
  bank the execution contract only. The first local Codex micro-shards executed
  the exact
  `phylo()` plus `poisson()`, `phylo()` plus `nbinom2()`,
  fixed-covariance `spatial()` plus `poisson()`, and fixed-covariance
  `spatial()` plus `nbinom2()` q1 `mu` one-slope cells for four seeds each,
  with four converged `pdHess = TRUE` point fits per cell. The later local
  80-rep recovery grid covers all eight ordinary Poisson/NB2 provider rows:
  it records convergence, finite estimates, SD bias/RMSE, and recovery-only
  status. The fixed-covariance spatial NB2 row has 80/80 fit_ok and finite
  estimates but 2/80 `pdHess = FALSE`, so it carries a Hessian caveat rather
  than a clean-Hessian claim. The NB2 rows keep `sigma` as fixed-effect
  overdispersion only, and the spatial rows keep range-estimating spatial
  support closed. These rows are recovery evidence only: they do not create a
  coverage-evaluable denominator, interval reliability, coverage, bridge
  parity, Totoro/DRAC execution evidence, REML, AI-REML, public support,
  structured count `sigma`, labelled or multiple count slopes,
  zero-inflated structure, or neighbouring count support.
- `phylo_interaction()` count cells are kept as separate Poisson and NB2 q1
  `mu` intercept rows. They are not covered by the ordinary-provider one-slope
  count rows, and they do not imply bridge support, q2/q4 endpoint covariance,
  slopes, additive partner-main effects, binary incidence, structured count
  scale routes, public support, REML, AI-REML, intervals, or coverage.
- Direct SD target visibility does not create derived-correlation interval
  support. Direct SD profile feasibility and derived correlation interval
  reliability are separate cells.

## 2026-06-27 — Interval-Method Levers Exhausted; the Finish Line Is a Design Decision

Two adversarially-checked scoping workflows this cycle settle what remains
between the current evidence and a `supported` promotion. The answer is **not
more engine work**.

1. **The t-quantile lever is shipped and bounded.** `confint(..., method =
   "wald", small_sample_df = "group")` (commit `34cece73`) references a
   t-quantile with `df = g-1` for structured-RE SD targets. A paired g=8/16/32
   recompute (`docs/dev-log/simulation-artifacts/2026-06-27-t-interval-recompute/`)
   shows it lifts the under-covering q2 `mu`-slope SD lane (0.885 -> 0.931 at
   g=8) and converges back to z by g=32. It is opt-in and scoped: the dispersion
   (`sigma`) SDs already over-cover under z, so t over-inflates them — a blanket
   default would harm them (flagged cross-team as gllvmTMB#565). The t-quantile
   corrects the *reference distribution*, not the biased *centre*; a residual
   ~0.93-at-g=8 gap remains on the q2 lane.

2. **REML is NOT the fix for that residual, and is not a drmTMB-only deliverable.**
   An adversarial scoping pass
   (`docs/dev-log/simulation-artifacts/2026-06-27-reml-unblock-scoping/`) found:
   (a) drmTMB native REML is exact restricted ML that marginalises only the mean
   *fixed* effects (`R/drmTMB.R:825-833`) — location-only by construction;
   (b) the g=8 bias lives on the structured location-*scale* SD (`sigma`/`rho`
   submodels), where the restricted likelihood is a *different, underived*
   objective (`docs/design/199:50-60`), and the scope-gate rows fence
   `sigma`/q2/q4 REML as `unsupported_until_derived`; (c) the only relevant
   correction (q4 Patterson-Thompson) lives in DRM.jl, not drmTMB; (d) the sole
   banked REML un-shrinkage evidence is for an *ordinary* intercept (location-only,
   n=18) — the wrong cell — and there is **no in-repo evidence REML moves the
   structured-SD centre at g=8.** Treating "unblock REML" as the g=8 coverage fix
   is unsupported optimism. (Unblocking biv structured-RE REML as a *separate*
   estimation capability is tractable but large, gated on deriving the
   structured-mean bivariate restricted likelihood first, and even then reaches
   only the mean axis, not the `sigma`/`rho` axis where the bias sits.)

3. **The bootstrap channel does not rescue it either.** drmTMB's
   `method = "bootstrap"` is a *parametric percentile* bootstrap
   (`drm_bootstrap_confint` -> `bootstrap_percentile_interval`,
   `probs = c(.025, .975)`): it simulates from the already-shrunk fitted model
   and takes percentiles, so its interval is centred on the same biased estimate
   and inherits the small-g shrinkage — it will under-cover at g=8 just like the
   others. A coverage-correcting bootstrap (BCa / studentized bootstrap-t) is not
   implemented. So **all four available interval methods — Wald, Wald-t, profile,
   and percentile-bootstrap — are centred on the shrunk variance-component
   estimate.** No interval method fixes a biased *centre*; that is the wall.

**Therefore reaching nominal coverage at the deployment default g=8 needs a NEW
estimator-side capability** (a bias-corrected variance-component estimator, a
BCa/bootstrap-t interval, or scale-side REML) — each a real engine/research arc to
commission, not a setting to flip. **The validated completion path today is the
PROFILE channel at adequate g.**

4. **The centre fix is identified and bounded — bias-correction reaches nominal.**
   An oracle recompute
   (`docs/dev-log/simulation-artifacts/2026-06-27-oracle-bias-correction/`)
   debiased each banked g=8 q2 replicate's log-scale centre by the *measured* mean
   log-shrinkage (~ -0.12 to -0.14) and rebuilt the interval with a t(df=7) width.
   Pooled coverage (n=3800) rises **0.887 (Wald-z) -> 0.932 (Wald-t) -> 0.956
   (bias-corrected + t)** — correcting the centre reaches nominal. So of the three
   arcs, the **bias-corrected variance-component estimator is the validated path**;
   the only open question is whether a *usable* bias estimate (parametric bootstrap,
   analytic, or REML) recovers the ~ -0.12 the oracle uses. This converts
   `supported` at the deployment default from "undefined research" into a
   **specific, in-principle-validated engine deliverable** — a parametric-bootstrap
   bias prototype is the immediate next test.

5. **The cheap practical bias estimator does NOT work — which narrows the arc.**
   The parametric-bootstrap bias prototype
   (`docs/dev-log/simulation-artifacts/2026-06-27-bootstrap-bias-prototype/`; phylo
   mu1:x, g=8, 16 seeds x 100 refits, 100% refit success) estimates a log-bias of
   only **~ -0.01** — one-tenth of the oracle's -0.13 — so a bootstrap-bias-corrected
   centre is essentially the raw ML centre. This is principled, not a bug: the
   single-level parametric bootstrap measures the estimator's bias *at* `theta_hat`,
   where the log-SD ML estimator is nearly median-unbiased; the oracle's -0.13 is the
   bias *at the true parameter*, which a truth-free bootstrap cannot see (shallow
   local bias gradient near `theta_hat`). So Wald-t, percentile bootstrap, AND
   single-level parametric-bootstrap bias correction all fail to deliver the centre
   fix. The remaining candidates that *could* — a closed-form analytic/REML
   small-sample log-SD bias correction, or a double/iterated bootstrap — are genuine
   derivation/research arcs (the scale-side restricted likelihood is underived; see
   `199:50-60`). **Net: `supported` at deployment-g is reachable in principle (the
   centre fix reaches nominal) but requires a research-grade bias-correction
   derivation — a maintainer commission, not an autonomous engineering task this
   cycle.**

6. **The default correction is accepted for a narrower row-level claim.** The
   measured log-shrinkage tracks **`log(g/(g-1))`** (a *simulation-calibrated*
   shift — REML-motivated but ~2x the leading-order REML SD term
   `0.5*log(g/(g-1))`, because the structured/bivariate model's effective df is
   well below `g-1`; see doc 219). The truth-free correction
   `sigma_corrected = sigma_ML * g/(g-1)` plus the t(df=g-1) width reached nominal
   coverage in the oracle/analytic sweep
   (`docs/dev-log/simulation-artifacts/2026-06-27-oracle-bias-correction/analytic-correction-cross-g.R`):
   g=8 **0.887 -> 0.955**, g=16 0.908 -> 0.949, g=32 0.944 -> 0.963. Fresh
   engine validation then accepted the correction as the default for
   location-axis structured SD targets only. It does not create a broad
   `supported` claim: the later engine grids still measured right-tail miss
   asymmetry and g-dependence. The sigma/dispersion SDs already over-cover, so
   the centre shift is not applied to them by default.

The g-sweep capstone and interval-reliability rung show that some
slope/sigma/q2/q4-location numerical walls relax at larger g: profile coverage
reaches certified-nominal (0.948-0.958, MCSE ~0.01) and q4-location pdHess
fragility is much lower by g=32 in the diagnostic runs. This is not a q4/q8
promotion. q4 remains diagnostic-only until denominator admission, finite
direct-SD intervals, derived-correlation interval machinery, and retained
coverage denominators pass row-specific gates; q8 remains stability-first.

### Decision executed (2026-06-27): four cells promoted to `interval_feasible`

The maintainer signed off (after Fisher/Rose/Emmy and then Pat/`user_tester` +
Darwin/`audience_reviewer` SIGN_OFF_WITH_CHANGES). Four cells —
`qseries_phylo_q1_sigma_one_slope`, `qseries_phylo_q2_mu1_mu2_one_slope`,
`qseries_relmat_q1_sigma_one_slope`, `qseries_relmat_q2_mu1_mu2_one_slope` —
moved from `interval_status = planned` to `interval_feasible`. That 2026-06-27
move did not promote coverage or `supported`.

### Decision executed (2026-06-28): q2 phylo/relmat to `inference_ready`

After the default correction shipped and a fresh engine-validated g=8 grid ran,
the q-series TSV contains 104 rows. Two q2 structured rows are
`inference_ready` for both interval and coverage status:

- `qseries_phylo_q2_mu1_mu2_one_slope`
- `qseries_relmat_q2_mu1_mu2_one_slope`

No structured row is `supported`. The pooled all-provider g=8 engine result is
evidence for the default correction, not a claim that all four providers are
`inference_ready`: fixed-covariance spatial q2, animal q2, q4/q8, count, and
non-Gaussian rows remain separate future arcs.

`supported` is withheld because two measured defects remain: a roughly 6:1
right-tail miss asymmetry at SD about 0.9, and g-dependent under-correction
(relmat g=12 about 0.93). Those are sampling-shape and effective-df problems,
not stale label work. q2 `supported` needs a skew-aware interval or a derived,
tested bivariate structured-location REML route.

### Decision executed (2026-06-28): q1 sigma phylo/animal/relmat to `inference_ready`

The first follow-on sigma arc promoted exactly three q1 sigma one-slope rows:

- `qseries_phylo_q1_sigma_one_slope`
- `qseries_animal_q1_sigma_one_slope`
- `qseries_relmat_q1_sigma_one_slope`

This is an uncorrected raw Wald-z claim on the log-SD scale, not a use of the
location-axis bias+t correction. At deployment g=8, the Nibi top-up, banked
SR475 slope grid, and local animal SR1000 reconciliation show 100% fit and
pdHess pass rates, Wald finite rates at or above 0.953, and Wald MCSE at or
below 0.01. The caveat is explicit: one-sided misses are asymmetric (phylo
intercept 5 lower vs 56 upper; animal intercept 26 lower vs 10 upper; relmat
intercept 5 lower vs 53 upper), while the sigma:x SDs over-cover or are
conservative. Profile intervals stay diagnostic-only at g=8 because low-finite
sigma targets remain visible, including animal `sigma:x` at 0.726. Spatial
sigma, matched `mu+sigma`, q4/q8, count, non-Gaussian rows, REML, AI-REML,
bridge support, and `supported` remain future gates.

## Why the Older Work Drifted

The first q-series waves were productive because they chose valuable cells
instead of waiting for a perfect architecture. The drift came from not treating
the cell as the shared evidence unit. A q-dimension, endpoint set, provider,
estimator, bridge route, extractor status, interval status, coverage status,
and public claim could be updated in different places at different times.

That made q-neighbour inference tempting:

- q4 worked, so q2 or q1 might be assumed;
- q1 `mu` plus q1 `sigma` might be treated like labelled q2;
- an ordinary q8 diagnostic route might be read as structured q8 planning;
- a direct SD profile row might be read as derived correlation interval
  support.

Ayumi exposed the same issue from another direction: a univariate phylo
location-scale model with random effects in both `mu` and `sigma` can work
while the half-cell without a scale random effect can still fail or be
unproven. Balanced or larger cells therefore never license unsupported
half-cells.

## Authority Rule

Dashboard sidecars are the source of truth for structured random-effect status.
README, NEWS, design notes, check-log entries, PR text, and narrative
summaries are derived. If narrative text disagrees with a validator-owned
dashboard sidecar, use the stricter and newer dashboard row until the prose is
reconciled.

For this q-series map, `structured-re-q-series-support-cells.tsv` is the
first row-level authority for completion planning. A public support statement
must name the exact row components: formula cell, provider, endpoint set,
route, estimator, interval status, and coverage status.

`structured-re-mu-slope-fixture-audit.tsv` records the current one-slope
Gaussian structured `mu` artifact evidence for `phylo()`, `spatial()`,
`animal()`, and `relmat()`. These rows bank source-tested DGP, smoke-summary,
and grid-writer evidence plus extractor identity. They do not promote bridge
fixture parity, residual-scale slopes, broader labelled structured slope covariance,
interval reliability, or coverage.

`structured-re-q1-parity-fixture-contract.tsv` records q1 deterministic
fixture-parity contracts. The spatial, animal, and relmat scale-side rows are
intentionally narrow: they use provider-scoped payload fixtures and cite
separate native point-fit/extractor evidence, but they keep range-estimating
spatial support, pedigree/Ainv or Q precision bridge marshalling, intervals,
coverage, REML, AI-REML, and public support unpromoted.

`structured-re-mu-slope-parity-fixture.tsv` records the next gate for those
one-slope Gaussian structured `mu` cells. It banks deterministic same-target
native/direct/R-via-Julia fixture contracts for `phylo()`, fixed-covariance
`spatial()`, A-matrix `animal()`, and K-matrix `relmat()` cells. The `relmat()`
row is paired with runtime K/Q same-target parity evidence. The sidecar is
fixture evidence only: it does not promote broad bridge support, residual-scale
slopes, broader labelled structured slope covariance, interval reliability, or
coverage.

`structured-re-sigma-slope-parity-fixture.tsv` records the corresponding
sigma-only one-slope fixture gate for `phylo()`, fixed-covariance `spatial()`,
A-matrix `animal()`, and K-matrix `relmat()` cells. These rows bank
deterministic same-target native/direct/R-via-Julia fixture contracts after the
native point-fit and extractor cells were opened. They do not promote broad
bridge support, range-estimating spatial support, pedigree/Ainv bridge
marshalling, relmat Q bridge marshalling, matched `mu+sigma` structured slope
cells, broader labelled structured slope covariance, interval reliability, or
coverage.

`structured-re-sigma-slope-interval-diagnostic-plan.tsv` and
`structured-re-sigma-slope-interval-diagnostic-status.tsv` record the first
sigma-only one-slope interval smoke. This sidecar deliberately does not reuse
the matched `mu+sigma` profile target names: the sigma-only target registry
uses `sd:sigma:provider(...)`, while matched `mu+sigma` uses
`sd:sigma:sigma:provider(...)`. The smoke run found all eight direct SD
targets. Seven targets had finite Wald/profile/bootstrap intervals; animal
`sigma:x` had finite Wald/bootstrap but endpoint-profile failure. These rows
keep the support cells at planned interval and coverage status.

`structured-re-sigma-slope-interval-stability-probe.tsv` records the
follow-up sigma-only stability diagnostic. It uses two stronger deterministic
fixture variants, records Wald and endpoint-profile intervals, and keeps the
same diagnostic-only boundary. All 16 variant-target combinations had finite
Wald/profile intervals, including animal `sigma:x`. This resolves the first
smoke-run profile failure as a stability target for the next diagnostic, not
as interval reliability or coverage evidence.

`structured-re-sigma-slope-denominator-admission.tsv` records the next
diagnostic gate for sigma-only one-slope cells. It admits the seven direct SD
targets whose smoke rows had finite Wald/profile/bootstrap intervals and whose
stability rows had finite Wald/profile intervals. Animal `sigma:x` remains a
visible profile-failure holdout. The ledger still records
`coverage_status = not_evaluated` and does not change the linked q-series
support-cell interval or coverage status.

`structured-re-sigma-slope-replicated-denominator-rule.tsv` records the
retention rule that would govern a later sigma-only coverage pre-grid. Seven
targets are eligible for a dry-run manifest with failed profiles,
nonconverged fits, nonfinite intervals, and bootstrap refit attempts retained.
Animal `sigma:x` remains a visible holdout.

`structured-re-sigma-slope-coverage-pregrid-dry-run.tsv` records the dry-run
manifest for that future grid. It contains 150 seeds and 1050 not-executed
target-replicate cells for the seven eligible targets. SR150 is explicitly not
enough for the 0.01 MCSE threshold, so this dry-run does not create coverage
evidence or coverage wording.

`structured-re-sigma-slope-coverage-dispatch-review.tsv` records the
compute-dispatch review for that same dry-run. It keeps the seven eligible
targets, excludes the animal `sigma:x` holdout, names provider shards for
Totoro or reviewed DRAC execution, and adds scheduler-exit retention. The rows
remain `not_executed` and `coverage_evaluable = FALSE`; they do not move the
support cells beyond planned interval and coverage status.

`structured-re-sigma-slope-coverage-runner-contract.tsv` records the
fail-closed runner contract for that dispatch review. It links each selected
runner row back to the exact dispatch row and pre-grid seed/cell manifests,
writes shard-specific provider manifests and run logs, and refuses execution
modes other than dry-run. This is race-safety and recovery evidence only: it
does not submit Totoro or DRAC jobs, create coverage-evaluable denominator
evidence, satisfy the MCSE threshold, or move interval, coverage, REML,
AI-REML, q4/q8, bridge, public-support, or SR150 readiness claims.

`structured-re-pr-stack-merge-readiness.tsv` is the stack-control ledger for
the q-series completion lane. It records PR #639 through #663 in merge order,
their draft status, merge-clean state, head SHAs, and commit-level R-CMD-check
run IDs. The ledger deliberately separates those commit-level checks from
ordinary PR-attached checks: only the first PR targets `main`, and each stacked
successor must retarget to `main` and refresh normal PR checks after the prior
layer lands. The ledger is not an implementation, inference, or compute gate;
it only prevents the project from treating a long green stack as a merged or
public-support state.

`structured-re-q2-plus-q2-sigma-rejection-contract.tsv` records the exact
pre-optimization rejection contract for scale-only structured `sigma1+sigma2`
q2-plus-q2 sibling cells in fixed-covariance `spatial()`, A-matrix `animal()`,
and `relmat()`. These rows answer the Ayumi-style half-cell question directly:
balanced q4, q2 location fixtures, and larger all-four cells do not imply that
the scale-only sibling is parser-ready or fit-ready. The rows remain
`unsupported` until a supported scale-side route is designed, implemented, and
tested for the exact provider/formula cell.

`structured-re-q2-retained-denominator-tranche9-repair-route-review.tsv`
records the Tranche 9 q2 retained-denominator route decision. The earlier
repair contract and Totoro smoke review required a named interval-repair route
before any top-up. Tranche 9 names the existing
`bounded_tmbprofile_direct_correlation_sidecar` candidate, but rejects it as a
complete cell-level route because the four q2 intercept rows also retain
endpoint direct-SD undercoverage or finiteness blockers. The phylo q2-plus-q2
row stays held because its `pdHess`, endpoint-SD, direct `mu1`/`mu2`
correlation, and held `sigma1`/`sigma2` correlation blockers are not repaired
by the q2 intercept sidecar. This banks a no-compute decision only: no smoke,
host top-up, SR475/SR1000 grid, interval status, coverage status,
`inference_ready`, `supported`, REML, AI-REML, q4/q8, bridge, or public-support
claim moves. The next q2 step is a combined endpoint-SD plus direct-correlation
route or a target-split decision reviewed by Fisher, Rose, Noether, and Grace.

`structured-re-q2-retained-denominator-tranche10-target-split-design.tsv`
records that target-split design as a new no-compute tranche. For the four q2
intercept cells, the direct `cor_mu1_mu2_intercept` component is separated from
the endpoint direct-SD `sd_mu2_intercept` blocker so neither component can
inherit evidence from the other. The q2-plus-q2 phylo row remains outside that
split because it needs a separate route for the `pdHess`, endpoint-SD, direct
`mu1`/`mu2` correlation, and held `sigma1`/`sigma2` correlation blockers. This
banks a design ledger only: no smoke, host submission, SR475/SR1000 top-up,
interval status, coverage status, `inference_ready`, `supported`, REML,
AI-REML, q4/q8, bridge, or public-support claim moves. The next q2 movement is
a Tranche 11 executable small-smoke contract or route design with
Fisher/Rose/Noether/Grace approval before any compute.

`structured-re-q2-retained-denominator-tranche11-direct-correlation-smoke-contract.tsv`
records that Tranche 11 command contract without executing it. It chooses only
the q2 intercept direct `cor_mu1_mu2_intercept` component for the existing
bounded `tmbprofile` direct-correlation repair sidecar, with one exact
32-replicate seed range per provider and a fail-closed helper requiring
`DRMTMB_Q2_TRANCHE11_EXECUTION_APPROVED=rose_fisher_noether_grace`. The endpoint
direct-SD component stays held because no endpoint-SD interval-shape route has
been named, and the phylo q2-plus-q2 cell stays held because its `pdHess`,
endpoint-SD, direct `mu1`/`mu2` correlation, and held `sigma1`/`sigma2`
correlation blockers need a separate route. This banks commands only: no
smoke, host submission, SR475/SR1000 top-up, interval status, coverage status,
`inference_ready`, `supported`, REML, AI-REML, q4/q8, bridge, or public-support
claim moves.

`structured-re-q2-retained-denominator-tranche12-endpoint-sd-route-design.tsv`
records the endpoint-SD route-design follow-up without executing anything. It
keeps the four q2 intercept `sd_mu2_intercept` targets together as endpoint
direct-SD blockers, treats the runner's `endpoint_zero_boundary_profile_channel`
label as a non-executable interval-shape problem class, and names the required
next gate: add or review an endpoint-SD repair channel before any smoke. The
Tranche 11 direct-correlation commands remain component-only and cannot repair
endpoint-SD blockers, while the phylo q2-plus-q2 cell remains separate because
its `pdHess`, endpoint-SD, direct `mu1`/`mu2` correlation, and held
`sigma1`/`sigma2` correlation blockers need their own route. Tranche 12 is
therefore a design ledger only: no endpoint-SD smoke, host submission,
SR475/SR1000 top-up, interval status, coverage status, `inference_ready`,
`supported`, REML, AI-REML, q4/q8, bridge, or public-support claim moves.

`structured-re-q2-retained-denominator-tranche13-endpoint-sd-blocker-decision.tsv`
banks the next no-compute decision for that endpoint-SD lane. The existing
phylo `sd_mu2_intercept` Totoro `n = 32` endpoint-zero-boundary profile smoke
is accepted as diagnostic blocker evidence: fit, convergence, `pdHess`, Wald
finiteness, and profile finiteness were all `32/32`, but profile coverage was
`0.8750` with four upper-tail misses, so the route is blocked for top-up and
should not be repeated across providers until a replacement interval-shape
route is designed. The DDF sidecar lead parked in
`https://github.com/itchyshin/drmTMB/issues/687` remains a lead only; primary
sources and row-specific retained-denominator simulation evidence are required
before it can become a Q-Series gate. Direct-correlation Tranche 11 and q2-plus
remain separate. Tranche 13 therefore moves no interval status, coverage
status, `inference_ready`, `supported`, REML, AI-REML, q4/q8, bridge,
DDF-implementation, or public-support claim.

`structured-re-q2-retained-denominator-tranche14-endpoint-sd-replacement-route-screen.tsv`
banks a no-compute candidate screen for the next endpoint-SD movement. It
records Satterthwaite-style DDF, Kenward-Roger-style DDF analogues, parametric
bootstrap intervals, boundary-likelihood diagnostics, and Cox-Reid
adjusted-profile or orthogonalization ideas as primary-source leads only. Those
links are not derivations or implementations; no route is selected as
executable, and no DDF, bootstrap, or adjusted-profile implementation claim is
made. Direct-correlation Tranche 11 and q2-plus stay separate. Tranche 14
therefore moves no interval status, coverage status, `inference_ready`,
`supported`, REML, AI-REML, q4/q8, bridge, endpoint-SD smoke, host submission,
top-up, or public-support claim.

`structured-re-q2-retained-denominator-tranche15-endpoint-sd-bootstrap-smoke-contract.tsv`
selects the bootstrap candidate only for a future executable micro-smoke,
because `tools/run-structured-re-q2-intercept-smoke.R` already exposes
bootstrap intervals for the exact `sd_mu2_intercept` estimand. This is not a
coverage design: `bootstrap_R = 2` and `n_rep = 8` per provider can only test
whether the bootstrap path, retained-denominator accounting, seed manifest, and
host provenance are viable. The fail-closed helper refuses execution without
`DRMTMB_Q2_TRANCHE15_EXECUTION_APPROVED=rose_fisher_noether_grace`. Tranche 15
therefore moves no interval status, coverage status, `inference_ready`,
`supported`, REML, AI-REML, q4/q8, bridge, bootstrap reliability claim,
endpoint-SD smoke result, host submission, top-up, or public-support claim.
Direct-correlation Tranche 11 and q2-plus remain separate.

`structured-re-q2-retained-denominator-tranche16-q2-plus-route-decomposition.tsv`
banks the q2-plus follow-up as a no-compute route-decomposition ledger. It
uses the existing Rorqual SR150 review and Nibi n=5 substitute-host smoke to
split the phylo q2-plus-q2 blocker into five SR150 within-block targets, the
held `cor_sigma1_sigma2_intercept` target, true-q4 cross-block blockers, and
the separated Tranche 11/15 q2-intercept dependencies. The SR150 signal remains
blocker evidence: `pdHess = 745/750`, the worst within-block Wald/profile
coverage is `0.8867`, and the Nibi sigma1/sigma2 correlation smoke retained
profile finiteness `4/5`. Tranche 16 therefore authorizes no q2-plus compute,
host submission, top-up, coverage, `inference_ready`, support-cell status edit,
q2-intercept inheritance, q4 inheritance, or public-support claim. The next
gate is a target-specific q2-plus repair route for `pdHess`, interval shape,
and the held sigma1/sigma2 correlation, or a separate true-q4 route for
cross-block correlations.

`structured-re-q2-retained-denominator-tranche17-q2-plus-repair-route-screen.tsv`
banks that next gate as a route screen, not as implementation. It separates
four candidate q2-plus repair leads from the true-q4 cross-block route and from
the neighboring Tranche 11/15 q2-intercept contracts. The candidate leads are
`pdHess` failure taxonomy, a sigma-correlation bounded-profile sidecar, a
parametric-bootstrap micro-smoke screen, and sigma-side interval-shape
calibration. None is selected as executable in Tranche 17. The summary row
requires one derived and reviewed route contract before any smoke, host spend,
top-up, coverage, interval-status movement, `inference_ready`, `supported`,
q2-intercept inheritance, q4/q8, REML, AI-REML, bridge, or public-support
claim.

`structured-re-q2-retained-denominator-tranche18-q2-plus-failure-taxonomy.tsv`
turns the Tranche 17 screen into the first selected repair route: existing-
artifact failure taxonomy before any new smoke. It classifies the five Rorqual
SR150 within-block targets, the held Nibi sigma1/sigma2 correlation, and a
summary route-gate row. The shared SR150 `pdHess` loss occurs on replicate 108;
the direct-correlation and `sd_sigma2_intercept` profile failures include
missing-`rlang` artifact-dependency rows on replicates 53 and 29; sigma-side
direct-SD targets show upper-tail profile miss patterns; and the held Nibi
correlation failed profile root solving on replicate 3. Tranche 18 is evidence
triage, not interval repair. It moves no compute, host spend, top-up, coverage,
interval status, `inference_ready`, `supported`, q2-intercept inheritance,
q4/q8, REML, AI-REML, bridge, or public-support claim. The next gate is one
post-taxonomy fail-closed contract for exactly one target/failure class, only
after Fisher/Rose/Noether/Gauss/Grace choose it.

`structured-re-q2-retained-denominator-tranche19-q2-plus-held-correlation-profile-contract.tsv`
implements that next gate as a banked contract, not as execution. The selected
target is only `cor_sigma1_sigma2_intercept` from the held Nibi
sigma1/sigma2 correlation failure, the replay seed is only 823003, and the
route is only a bounded `tmbprofile` direct-correlation sidecar to diagnose the
profile-root geometry. The helper is fail-closed: it requires the exact
Fisher/Rose/Noether/Gauss/Grace approval environment variable, locks
`n_rep = 1`, `seed_start = 3`, `seed_base = 823000`, and `bootstrap = 0`, and
blocks DRAC, Nibi, Rorqual, and Trillium denominator execution. Tranche 19
therefore authorizes no new denominator, top-up, coverage, interval-status
movement, `inference_ready`, `supported`, q2-plus promotion, q4/q8 claim,
REML, AI-REML, bridge, or public-support claim.

`structured-re-q2-retained-denominator-tranche20-held-correlation-profile-diagnostic.tsv`
records the executed diagnostic from that contract. The replay stayed local
(`host_class = tranche19_local_profile_contract`, `host_name = local_codex`),
used only replicate 3 / seed 823003, and targeted only
`cor_sigma1_sigma2_intercept`. The fit succeeded and `pdHess` was `TRUE`, but
the estimate was effectively at the correlation boundary, the ordinary profile
remained nonfinite, the bounded `tmbprofile` sidecar remained nonfinite, and
the runner summary was `local_smoke_failed`. This closes the selected
held-correlation profile route as diagnostic failure evidence. It creates no
denominator, authorizes no top-up or coverage, moves no support-cell status,
and makes no q2-plus, q4/q8, REML, AI-REML, bridge, or public-support claim.

`structured-re-q2-retained-denominator-tranche21-route-hold-decision.tsv`
records the reviewed hold after that failed route. It closes the bounded
`tmbprofile` held-correlation route, rejects another immediate profile rerun,
and keeps the remaining q2-plus choices as no-compute candidates only:
boundary-aware held-correlation derivation, artifact-dependency cleanup,
sigma-side interval-shape review, or raw replicate-108 Hessian review. Every
row remains `no_compute_in_tranche21`, `coverage_not_authorized`, and
`do_not_promote`; the q2-plus support cell remains `point_fit/planned/planned`.
The next tranche must choose exactly one new fail-closed contract or explicitly
park q2-plus before any Totoro, DRAC, Nibi, Rorqual, or Trillium command.

`structured-re-q2-retained-denominator-tranche22-rep108-artifact-review.tsv`
banks that next movement as an existing-artifact review, not as compute. It
reviews Rorqual SR150 replicate 108 / seed 823108 for the five q2-plus
within-block targets. Each target row has `fit_ok`, convergence 0,
`pdHess = FALSE`, `NaNs produced`, and nonfinite Wald status. The profile rows
are finite, but finite profiles are not admission when `pdHess` and Wald
finiteness fail; `sd_sigma2_intercept` also has a near-boundary profile warning
and does not contain the truth. Because the TSV does not include raw Hessian
eigenstructure or gradients, the next gate is either a fail-closed raw-fit
geometry reconstruction contract or an explicit q2-plus park decision. Tranche
22 authorizes no compute, denominator, top-up, coverage, status movement,
q2-plus promotion, q4/q8, REML, AI-REML, bridge, or public-support claim.

`structured-re-q2-retained-denominator-tranche23-rep108-geometry-contract.tsv`
chooses the fail-closed raw-fit geometry path while still stopping before
execution. The contract is scoped to one source replicate, Rorqual SR150
replicate 108 / seed 823108, and the same five q2-plus within-block targets.
It requires a raw fit object or replay bundle, Hessian eigenstructure, gradient
norms, optimizer trace, boundary flags, source SHA, host label, and output path
before any geometry interpretation. Tranche 23 records no reconstructed raw
geometry and runs no local, Totoro, Nibi, Rorqual, Trillium, or DRAC command.
The only next choices are one approved host-separated raw-geometry
reconstruction or an explicit q2-plus park decision. It authorizes no
denominator, top-up, coverage, status movement, q2-plus promotion, q4/q8,
REML, AI-REML, bridge, or public-support claim.

`structured-re-q2-retained-denominator-tranche24-rep108-geometry-result.tsv`
records the approved local reconstruction from that contract. The replay used
`local_codex_geometry_reconstruction` provenance and the same replicate 108 /
seed 823108. It matched the target estimates closely, including the
near-boundary `sd_sigma2_intercept`, but it did not reproduce the source
Hessian failure: the local replay had `pdHess = TRUE`, positive `cov.fixed`
eigenvalues, and a small maximum gradient, whereas the Rorqual SR150 source
artifact had `pdHess = FALSE` with nonfinite Wald intervals. This is
source/host drift evidence, not admission. Tranche 24 authorizes no
denominator, top-up, coverage, status movement, q2-plus promotion, q4/q8,
REML, AI-REML, bridge, or public-support claim. The next gate is either a
source-matched Rorqual/DRAC geometry reconstruction or an explicit q2-plus park
decision.

`structured-re-q2-retained-denominator-tranche25-source-match-decision.tsv`
turns that fork into a fail-closed no-compute decision contract. A source-
matched geometry replay is allowed only if the Rorqual dirty source state, R
session, package library, runner inputs, exact command, host label, and output
path can be proven or recreated on DRAC with an explicit source-diff manifest.
Local Codex, Totoro, unsynced DRAC, and other host repeats are excluded because
they would repeat the wrong question after Tranche 24. If source matching
cannot be proven, q2-plus is parked rather than topped up. Tranche 25 records
no execution, denominator, top-up, coverage, status movement, q2-plus
promotion, q4/q8, REML, AI-REML, bridge, or public-support claim.

`structured-re-q2-retained-denominator-tranche26-source-snapshot-proof.tsv`
banks the no-compute source-snapshot proof for that fork. The preserved Rorqual
`/project` run root contains the copied source tree, shard-5 R library, package
cache, metadata, and q2-plus result artifacts; the copied source is not a live
Git repository, and the critical manifest entries are listed while full
manifest hashing is deferred to the replay job rather than performed on a login
node. This proof makes one future source-matched Rorqual replay contract
possible, but it does not execute that replay and does not create a denominator,
top-up, coverage, status movement, q2-plus promotion, q4/q8, REML, AI-REML,
bridge, or public-support claim. If the next checkpoint cannot keep source
matching and job-internal manifest verification clean, q2-plus is parked.

`structured-re-q2-retained-denominator-tranche27-source-matched-replay-contract.tsv`
turns that proof into a fail-closed, non-submitted Rorqual job pack. The paired
`tools/slurm/q2-plus-rep108-source-replay-rorqual.sbatch` accepts only Rorqual
SLURM array task 108, checks the approval token, verifies the preserved source
sha256 manifest inside the job, then calls the preserved q2-plus runner for
replicate 108 / seed 823108 and the five retained q2-plus target IDs. It does
not run in Tranche 27. Local Codex, Totoro, Nibi, Trillium, Fir, unsynced DRAC,
login-node, and source-unverified routes remain excluded. Tranche 27 records no
execution, denominator, top-up, coverage, status movement, q2-plus promotion,
q4/q8, REML, AI-REML, bridge, or public-support claim; the next gate is exactly
one approved Rorqual submission and artifact review, or q2-plus parking.

`structured-re-q2-retained-denominator-tranche28-source-replay-submission.tsv`
records that the approved source-matched replay was submitted as Rorqual job
15027970, array task 108, and was still pending for priority at the first
scheduler probe. The submission ledger keeps the remote sbatch, stdout, and
result-root paths under the preserved Rorqual `/project` run root. It imports no
artifacts and performs no result review, so it creates no denominator, top-up,
coverage, status movement, q2-plus promotion, q4/q8, REML, AI-REML, bridge, or
public-support claim. The next gate is terminal-job monitoring and a separate
result-review tranche, or q2-plus parking if the job or manifest gate fails.

`structured-re-q2-retained-denominator-tranche29-source-replay-terminal-review.tsv`
records the terminal review of that submission. Rorqual job 15027970 reached
`FAILED` with exit `1:0` after 00:01:37 on node `rc32610`. The full sha256
manifest failed before R execution at `./tools/run-structured-re-q2-intercept-smoke.R`.
That failed file is outside the five q2-plus target replay, and the critical
q2-plus manifest entries were recorded, but the q2-plus runner did not start and
no smoke result TSVs were created. Tranche 29 therefore produces no denominator,
top-up, coverage, status movement, q2-plus promotion, q4/q8, REML, AI-REML,
bridge, or public-support claim. The next gate is a checkpointed Tranche 30
decision: either bank a narrower critical-manifest replay contract or park
q2-plus.

`structured-re-q2-retained-denominator-tranche30-critical-manifest-replay-contract.tsv`
banks the narrower critical-manifest option, not execution. The paired
`tools/slurm/q2-plus-rep108-critical-manifest-replay-rorqual.sbatch` accepts
only Rorqual SLURM array task 108, checks a new Tranche 30 approval token,
verifies only listed critical source entries before R, and then would call the
preserved q2-plus runner for replicate 108 / seed 823108 and the five retained
q2-plus target IDs. It explicitly records the excluded full-manifest drift at
`./tools/run-structured-re-q2-intercept-smoke.R` and does not resubmit job
15027970. Tranche 30 produces no denominator, top-up, coverage, status movement,
q2-plus promotion, q4/q8, REML, AI-REML, bridge, or public-support claim. The
next gate is checkpointed submission plus terminal artifact review, or parking
q2-plus if the critical-manifest gate fails.

`structured-re-q2-retained-denominator-tranche31-critical-manifest-replay-submission.tsv`
records the checkpointed submission of that job pack. Rorqual job 15029153
array task 108 was submitted with the Tranche 30 approval token, and the first
probe found `PENDING` priority state with no result root or replay artifacts.
Tranche 31 is a submission ledger only; it does not create a denominator,
coverage result, status movement, q2-plus promotion, q4/q8, REML, AI-REML,
bridge, or public-support claim. The next gate is a terminal artifact-review
tranche, or q2-plus parking if the job or critical-manifest gate fails.

`structured-re-q2-retained-denominator-tranche32-critical-manifest-replay-terminal-review.tsv`
records that terminal review. Job 15029153 completed on Rorqual node `rc32504`
with exit `0:0`, and the critical manifest entries checked OK. The imported
artifacts show a failed admission gate: `pdHess = FALSE` and nonfinite Wald
intervals for all five retained q2-plus targets; profiles are finite, but the
sigma2 profile misses the truth near the SD boundary. Tranche 32 therefore
creates no admission denominator, coverage result, status movement, q2-plus
promotion, q4/q8, REML, AI-REML, bridge, or public-support claim. The next gate
is parking q2-plus or writing a separately reviewed geometry-explanation design;
no top-up or coverage is authorized from this result.

`structured-re-q2-retained-denominator-tranche33-q2-plus-parking-decision.tsv`
executes the conservative branch of that gate. It parks the q2-plus route
without changing the support cell: the row remains `point_fit/planned/planned`
with `denominator_policy = repair_contract_ready_not_coverage`. Tranche 33
authorizes no new q2-plus compute, top-up, coverage, status edit, promotion,
q4/q8 claim, REML, AI-REML, bridge, or public-support wording. A future q2-plus
return must be a new geometry-explanation design, reviewed by
Rose/Fisher/Gauss/Noether/Grace and checkpointed before compute. The campaign
queue should move to the next non-parked Q-Series tranche.

`structured-re-count-slope-sigma-one-slope-rejection-contract.tsv` records the
exact pre-optimization rejection contract for count NB2 `sigma` one-slope
structured-scale cells in `phylo()`, fixed-covariance `spatial()`, A-matrix
`animal()`, and K/Q `relmat()`. The engine rejects structured count scale
routes at the formula gate (`Structured non-Gaussian paths`), so each
`qseries_*_nbinom2_q1_sigma_one_slope_rejected` cell stays `unsupported`. These
rows answer the count half-cell question: the banked count `mu` one-slope cells
do not imply count `sigma` one-slope support. Poisson has no `sigma` parameter,
so it has no structured count scale cell. The rows do not promote parser-ready,
point-fit, bridge, interval, coverage, REML, AI-REML, public-support, or
q4/q8 status.

`structured-re-nongaussian-structured-family-rejection-contract.tsv` records
the active pre-optimization rejection contract for the remaining
structured-family routes the engine still rejects at the formula gate:
`cumulative_logit()`/`phylo` on `mu` and
`truncated_nbinom2()`/`relmat` on `hu`. Earlier beta, Gamma, Student `mu`,
Student `nu`, Poisson `zi`, beta `sigma`, and NB2 `sigma` one-slope rows now
live in the support cells and local first-four smoke as local fit-only recovery
rows. The moved rows do not promote bridge, interval, coverage, REML, AI-REML,
public-support, q4/q8, or broad structured non-Gaussian support.

`structured-re-count-structured-mu-rejection-contract.tsv` records the exact
pre-optimization rejection contract for structured count `mu` routes the engine
still rejects beyond the banked one-slope cells: a labelled `q=2` covariance, a
zero-inflated NB2 structured `mu` route, and simultaneous structured effect
types. The Poisson structured `mu` route with a fixed `zi ~ 1` formula, the
Poisson spatial structured `mu` plus ordinary `mu` random-effect route, and the
Poisson fixed-covariance spatial slope-only structured `mu` route now live in
the support cells and local first-four smoke as local fit-only rows. Each
remaining rejection cell is rejected at the formula gate with its own message
(for example `Only one
structured`), backed by `tests/testthat/test-count-structured-mu.R`, so each
linked unsupported `qseries_count_mu_*_rejected` cell stays `unsupported`.
These rows answer the count `mu` half-cell question: the banked count `mu`
one-slope and local slope-only cells do not imply labelled q2 covariance,
structured-zero-inflation, NB2 zero-inflation, multiple slopes, or multi-type
structured count `mu` support. The rows are rejection or local fit-only evidence
only and do not promote parser-ready, broad point-fit, bridge, interval,
coverage, REML, AI-REML, public support, or q4/q8 status. The
contracts anchor on engine message substrings; see
`docs/dev-log/2026-06-27-rejection-contract-anchor-robustness-memo.md` for the
recommendation to re-anchor on a condition class.

`structured-re-q2-slope-parity-fixture.tsv` records the slope-only q=2
`mu1`/`mu2` same-target fixture gate for `phylo()`, fixed-covariance
`spatial()`, A-matrix `animal()`, and K-matrix `relmat()`. It moves only the
exact `0 + x | p | ...` support cells to deterministic fixture parity. The
table is not evidence for intercept-plus-slope q4/q8, range-estimating
spatial support, pedigree/Ainv bridge marshalling, relmat Q bridge marshalling,
interval reliability, coverage, REML, AI-REML, or broad bridge support.

`structured-re-q2-slope-interval-diagnostic-plan.tsv` records the planned
target-level interval diagnostics for those exact slope-only q=2 cells:
`sd_mu1_x`, `sd_mu2_x`, and `cor_mu1_mu2_x` for each provider. This plan does
not change the q-series interval or coverage statuses; it only names the
targets and denominator fields that must be observed before any interval or
coverage wording can move.

`structured-re-q2-slope-interval-diagnostic-status.tsv` records the first
deterministic interval-smoke status for those 12 exact slope-only q=2 targets.
The method-level artifact records 36 rows: Wald, endpoint-profile, and
bootstrap with two refits for each target. After the q2 slope-design runtime
fix, 10 targets have finite Wald/profile/bootstrap intervals and two
correlation targets have finite Wald/bootstrap with endpoint-profile failure;
all fits converged with `pdHess = TRUE`. This is diagnostic-only status; the
q-series support cells still do not promote interval reliability, coverage,
REML, AI-REML, q4/q8, or broad bridge support.

`structured-re-q2-slope-interval-stability-probe.tsv` records the next
deterministic stability probe for the same slope-only q=2 target set. It uses
two stronger slope-signal fixtures and records Wald plus endpoint-profile
interval rows. After the q2 slope-design runtime fix, all 24 variant-target
rows have finite Wald/profile status and `pdHess = TRUE`. This keeps q2 slope
interval work in diagnostic mode; it is not coverage-grid readiness.

`structured-re-q2-slope-denominator-admission.tsv` records the denominator
admission status implied by the post-fix q2 slope interval-smoke and stability
sidecars. Ten targets are diagnostic denominator candidates because the smoke
run had finite Wald/profile/bootstrap intervals and both stability variants
had finite Wald/profile diagnostics with `pdHess = TRUE`. The animal and
relmat correlation targets are not admitted because the smoke run still had
endpoint-profile failure. This ledger is denominator triage only; it leaves the
support cells at `interval_status = planned` and `coverage_status = planned`
and does not claim coverage-grid readiness.

`structured-re-q2-slope-denominator-extension.tsv` records the next small
denominator-extension diagnostic for the same target set. It uses two
additional deterministic fixture variants and runs Wald plus endpoint-profile
intervals. All 24 extension rows are finite with `pdHess = TRUE`. The 20 rows
whose targets were admitted by the previous sidecar are marked
`extension_candidate`; the animal and relmat correlation rows remain
`not_admitted_from_smoke` until the earlier smoke profile failure is diagnosed.
This is still not coverage-evaluable denominator evidence and leaves support
cell interval and coverage statuses planned.

`structured-re-q2-slope-replicated-denominator-rule.tsv` records the next
policy layer before any q2 slope coverage pre-grid. It keeps the exact 12
target rows as the unit of truth, admits only the 10 rows with finite smoke
profiles and two finite extension variants as
`eligible_for_pregrid_with_retention`, and keeps the animal/relmat correlation
rows visible as holdouts until their smoke endpoint-profile failures are
reconciled. A future coverage run must use a predeclared 150-replicate seed
manifest, retain failed profiles, retain nonconverged fits, retain nonfinite
intervals, record bootstrap-refit attempts, and satisfy MCSE <= 0.01 before
coverage wording can move. The rule itself keeps `coverage_evaluable = FALSE`;
it is not coverage evidence and it does not move q2 interval, coverage, REML,
AI-REML, q4/q8, or public support status.

`structured-re-q2-slope-spatial-animal-admission-audit.tsv` and
`structured-re-q2-slope-bias-t-coverage-evidence.tsv` record the row-specific
spatial/animal q2 blocker state after the default bias+t correction. Spatial
has measured SR475 bias+t SD-endpoint evidence, but `mu2:x` remains below
nominal at 0.9411 with MCSE 0.0108 and 24 upper-tail misses, and the
endpoint-only sidecar does not promote the correlation target. Animal has
measured SR475 bias+t SD-endpoint evidence, but `mu2:x` remains borderline at
0.9474 with MCSE 0.0102 and the correlation target has no coverage-grid row
after the denominator holdout. These rows stay `planned` for interval and
coverage status; no range-estimating spatial, pedigree/Ainv bridge
marshalling, q4/q8, REML, AI-REML, bridge, `supported`, or public-support
claim moves.

`structured-re-q2-slope-coverage-pregrid-dry-run.tsv` records the next
execution-planning layer without running any coverage fits. It writes a
150-row seed manifest and a 1500-row target-by-seed cell manifest for the 10
currently eligible q2 slope targets, while keeping the animal and relmat
correlation targets visible as zero-cell holdouts. The dry run records that
SR150 is not enough for a 0.01 MCSE threshold at nominal 0.95 coverage:
`nominal_mcse_at_150 = 0.017795`, and `replicates_for_mcse_threshold = 475`.
This artifact fixes the manifest shape and denominator retention policy only;
it keeps `execution_status = not_executed`, `coverage_evaluable = FALSE`, and
support-cell coverage status planned.

`structured-re-mu-sigma-slope-readiness.tsv` records the matched
`mu+sigma` one-slope identity gate after native point-fit/extractor support was
opened. The required endpoint-member set is
`mu:(Intercept);mu:x;sigma:(Intercept);sigma:x`; this is not equivalent to a
two-member q2 block or to independent `mu` and `sigma` successes recorded in
separate rows. The sidecar links the four provider rows to the separate
`mu`-slope and `sigma`-slope fixture ledgers and provider tests. The readiness
gate itself did not promote bridge support, intervals, coverage, REML, or
AI-REML.

`structured-re-q4-intercept-parity-fixture.tsv` records deterministic
same-target native/direct/R-via-Julia fixture evidence for exact all-four
intercept q4 cells. Spatial, animal, and relmat now have the same fixture-parity
ledger shape as phylo, while the phylo support cell still points to the older
q4 parity acceptance gate. This closes the provider q4 intercept fixture gap
without promoting interval reliability, interval coverage, q4 REML,
native-TMB q4 REML, q4 AI-REML, broad bridge support, public support,
range-estimating spatial support, pedigree/Ainv animal bridge marshalling, or
relmat Q bridge marshalling.

`structured-re-q4-intercept-interval-diagnostic-plan.tsv` records the
provider-scoped interval diagnostic plan for those exact all-four intercept q4
cells. It contains four direct-SD targets and six derived-correlation targets
per provider. The direct-SD rows are future deterministic target-smoke targets,
while the derived-correlation rows stay blocked until interval reconstruction is
designed and validated. The sidecar does not admit coverage denominators,
interval reliability, coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,
HSquared AI-REML, broad bridge support, public support, range-estimating
spatial support, pedigree/Ainv animal bridge marshalling, or relmat Q bridge
marshalling.

`structured-re-q4-intercept-interval-diagnostic-status.tsv` records the first
deterministic direct-SD interval smoke for those exact all-four intercept q4
cells. It covers the 16 direct-SD rows from the plan and writes the method-level
artifact under
`docs/dev-log/simulation-artifacts/2026-06-25-q4-intercept-interval-smoke/`.
Phylo, fixed-covariance spatial, and K-matrix relmat are Hessian-blocked in this
smoke. The A-matrix animal cell reaches finite Wald/profile direct-SD intervals
but not finite bootstrap intervals. This moves only the smoke-status artifact
forward; it does not admit denominators, interval reliability, interval
coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad
bridge support, public support, range-estimating spatial support,
pedigree/Ainv bridge marshalling, or relmat Q bridge marshalling.

`structured-re-q4-intercept-denominator-precheck.tsv` records the target-level
denominator precheck implied by that smoke. The 12 phylo, fixed-covariance
spatial, and K-matrix relmat direct-SD targets are marked
`not_admitted_pdhess_false`. The four A-matrix animal direct-SD targets are
marked `not_admitted_bootstrap_nonfinite`. This sidecar prevents the support
cell from treating finite point fits, finite profile targets, or finite
Wald/profile rows as coverage-evaluable denominators.

`structured-re-q4-intercept-hessian-bootstrap-diagnostic.tsv` records the next
provider-level diagnostic. It refits the deterministic q4 all-four intercept
fixture and separates the blockers: phylo, fixed-covariance spatial, and
K-matrix relmat have `pdHess = FALSE` with `finite_indefinite`
fixed-effect covariance diagnostics, while the A-matrix animal row has
`pdHess = TRUE`, `finite_positive` fixed-effect covariance, and nonfinite
bootstrap rows for all four direct-SD targets. This is still diagnostic-only
evidence; it does not move q4 interval reliability, q4 interval coverage,
q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad bridge
support, public support, DRAC/Totoro execution, or denominator admission.

`structured-re-q4-slope-identity-preflight.tsv` records the q8-shaped identity
contract for all-four one-slope bivariate Gaussian cells. The required
endpoint-member set is
`mu1:(Intercept);mu1:x;mu2:(Intercept);mu2:x;sigma1:(Intercept);sigma1:x;sigma2:(Intercept);sigma2:x`.
The phylo, fixed-covariance spatial, A-matrix animal, and K/Q relmat rows now
have native point-fit/extractor evidence for their exact shared-label cells.
This sidecar remains the runtime/extractor identity ledger.

`structured-re-q4-slope-parity-fixture.tsv` records deterministic same-target
native/direct/R-via-Julia fixture evidence for those same four exact q8-shaped
cells. It moves only the exact all-four one-slope phylo, fixed-covariance
spatial, A-matrix animal, and K-matrix relmat cells to fixture parity. Broad
bridge support, intervals, coverage, q4 REML, AI-REML, public support,
pedigree/Ainv animal bridge marshalling, relmat Q bridge marshalling,
range-estimating spatial support, partial labelled layouts, and broader q8
variants remain separate gates.

`structured-re-q4-slope-interval-diagnostic-plan.tsv` records the target-level
interval diagnostic plan for those same exact q8-shaped cells. It contains
8 direct-SD targets and 28 derived-correlation targets per provider. The
direct-SD rows are future smoke-test targets only, while the derived-correlation
rows stay blocked until derived interval reconstruction is designed and
validated. The sidecar does not admit coverage denominators, interval
reliability, coverage, q4 REML, AI-REML, broad bridge support, public support,
or broader q8 support.

`structured-re-q4-slope-interval-diagnostic-status.tsv` records the first
deterministic direct-SD interval smoke for those exact provider cells. It covers
only the 32 direct-SD rows from the plan. All four q8-shaped fits converged, but
all four returned `pdHess = FALSE`, so Wald, profile, and bootstrap rows are
recorded as `not_run_pdhess_false` with zero finite intervals. This is
diagnostic negative evidence: derived-correlation interval reconstruction,
denominator admission, interval reliability, coverage, q4 REML, AI-REML, broad
bridge support, public support, and broader q8 support remain unpromoted.

`structured-re-q4-slope-interval-stability-probe.tsv` records the follow-up
Hessian-stability probe for those same direct-SD targets. It runs two
deterministic variants, `strong` and `more_levels`, across `phylo()`,
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`.
The current-source refresh keeps the `phylo()`, fixed-covariance `spatial()`,
and K-matrix `relmat()` variants Hessian-blocked, while A-matrix `animal()`
now reaches `pdHess = TRUE` with finite Wald intervals and a mixed profile
signal. Across the 16 animal direct-SD endpoints, 9 are Wald/profile finite
and 7 are Wald-finite/profile-nonfinite. This is still diagnostic-only
admission evidence: it does not promote interval reliability, coverage, q4
REML, AI-REML, broad bridge support, public support, or broader q8 support.

`structured-re-q4-slope-hessian-geometry.tsv` records the follow-up
Hessian-geometry audit for those same provider-variant fits. It keeps one row
per `strong` / `more_levels` variant crossed with `phylo()`, fixed-covariance
`spatial()`, A-matrix `animal()`, and K-matrix `relmat()`. All eight rows have
converged fits with `pdHess = FALSE`, nonfinite `sdr$cov.fixed`, unavailable
raw TMB Hessian extraction for random-effect models, and all four sigma-endpoint
direct SD estimates at the lower bound; seven rows selected the fallback
optimizer. This localizes the q4 all-four one-slope interval blocker to
sigma-endpoint lower-bound geometry plus covariance/Hessian failure, not to any
accepted interval, denominator, coverage, q4 REML, AI-REML, public support, or
broader q8 support claim.

`structured-re-q4-slope-sigma-axis-differential.tsv` records the first
reduced-axis contrast for those same provider-variant cells. The all-four
baseline rows reproduce the lower-bound sigma-SD and nonfinite-covariance
geometry. The `mu1+mu2` intercept-plus-slope partial-axis rows now fit for
`phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()` with four direct SD targets, `pdHess = TRUE`, and finite positive
`sdr$cov.fixed`; the support-cell ledger records these as exact diagnostic
native point-fit/extractor q4 location cells. The `sigma1+sigma2` partial-axis
rows still do not fit: the partial location-scale guard currently requires
matching labelled intercepts in `mu1`, `mu2`, `sigma1`, and `sigma2`. This
confirms that q4/q8 neighbours cannot be inferred from the all-four q8-shaped
cell. It is diagnostic runtime evidence only, not bridge parity, partial
location-scale support, interval reliability, coverage, q4 REML, AI-REML, broad
bridge support, public support, or broader q8 support.

`structured-re-q4-location-slope-parity-fixture.tsv` records deterministic
same-target native/direct/R-via-Julia fixture evidence for those exact
`mu1+mu2` q4 location cells. It moves only the four-member q4 location endpoint
map for `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and
K-matrix `relmat()` to fixture parity. The `relmat()` row is a K-matrix
contract only; Q precision marshalling remains separate and the row does not
claim K/Q same-target parity. Partial location-scale support, interval
reliability, coverage, q4 REML, AI-REML, broad bridge support, public support,
and broader q8 support remain unpromoted.

`structured-re-relmat-q-bridge-boundary.tsv` is the cross-cell guard for that
same distinction. It covers the relmat q1 `mu` slope, q1 `sigma` slope,
matched `mu+sigma` slope, q2 `mu1+mu2` slope-only, q4 location slope, and
all-four one-slope q8-shaped cells. All six rows now cite runtime K/Q
same-target native evidence where it has been banked. The q4 location row points
at `structured-re-relmat-q4-location-kq-native-parity.tsv`, which records native
R/TMB evidence only for the exact `mu1+mu2` q4 location cell. Every row leaves
`bridge_q_status`, `direct_drmjl_q_status`, and `r_via_julia_q_status` at
`unsupported`. This sidecar is bridge-boundary evidence only; it does not
implement Q precision marshalling, broad bridge support, interval reliability,
coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML,
non-Gaussian REML, public support, or broader q8 support.

`structured-re-relmat-kq-one-slope-native-parity.tsv` is the generated native
runtime companion for that bridge-boundary ledger. It records six exact relmat
K/Q one-slope parity cells: q1 `mu`, q1 `sigma`, matched q1 `mu+sigma`, q2
`mu1+mu2` slope-only, q4 location one-slope, and the q8-shaped all-four
one-slope row. The sidecar is not a Q bridge payload contract and does not move
direct DRM.jl Q export, R-via-Julia Q transport, broad bridge support, interval
reliability, coverage, REML, AI-REML, public support, or broader q8 support.

`structured-re-relmat-q-payload-marshalling-gate.tsv` records the acceptance
gate for future relmat `Q` precision payload work. It covers the same six
relmat `K/Q` rows as the bridge-boundary sidecar and now points to the reviewed
payload contract sidecar for `matrix_id`, `matrix_digest`, input scale, `Q`
precision source, level alignment, missing-level policy, coefficient order, and
provenance before direct DRM.jl or R-via-Julia bridge status can move. This
gate keeps native `Q` runtime parity and the reviewed payload contract separate
from bridge implementation and does not promote broad bridge support, intervals,
coverage, REML, AI-REML, public support, or broader q8 support.

`structured-re-relmat-q-payload-contract-review.tsv` is the reviewed contract
sidecar for those six cells. It fixes the expected Q-specific payload identity,
matrix digest, explicit precision input scale, source provenance, observed-level
alignment, fail-closed missing-level policy, endpoint/member coefficient order,
and no-implicit-conversion boundary. The sidecar is not runtime or bridge
implementation evidence; direct DRM.jl `Q`, R-via-Julia `Q`, R bridge `Q`,
interval reliability, coverage, REML, AI-REML, public support, and broader q8
support remain separate gates.

`structured-re-relmat-q-drmjl-provider-readiness.tsv` records the narrow
dependency snapshot between that R payload contract and the active DRM.jl
precision-provider stack. It has three rows: DRM.jl #299 q2 known-precision
bridge primitive, DRM.jl #300 q2 known-precision provider contract, and the
R-side relmat `Q` transport gate after drmTMB #665. The two upstream rows are
draft-green, not merged, and not six-cell drmTMB relmat `Q` bridge support.
The R-side row keeps exact `Q` precision transport at
`contract_only_not_implemented` until the upstream stack is accepted and the
reviewed payload contract is matched in code. This row does not promote broad
bridge support, interval reliability, coverage, REML, AI-REML, public support,
or broader q8 support.

`structured-re-relmat-q-drmjl-stack-review.tsv` records the exact-head review
decision after DRM.jl #297, #298, #299, and #300 were inspected with focused
local tests and remote/manual green evidence. It keeps those upstream draft PRs
and drmTMB #666 as five separate dependency rows. The sidecar says the stack is
reviewed enough to plan the merge/retarget order, but not enough to implement
or claim relmat `Q` payload transport while the upstream PRs remain draft and
unmerged. It does not promote direct DRM.jl `Q`, R-via-Julia `Q`, broad bridge
support, interval reliability, coverage, q4 REML, native-TMB q4 REML, q4
AI-REML, HSquared AI-REML, non-Gaussian REML, public support, or broader q8
support.

`structured-re-q4-location-slope-interval-diagnostic-plan.tsv` records the
target-level interval diagnostic plan for those same exact q4 location cells.
It names 16 direct-SD targets and 24 derived-correlation targets across
`phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()`. The direct-SD rows are future Wald/profile/bootstrap smoke targets.
The derived-correlation rows stay blocked until derived interval reconstruction
is designed. This sidecar does not admit coverage denominators, interval
reliability, interval coverage, q4 REML, AI-REML, broad bridge support, public
support, partial location-scale support, Q precision marshalling, K/Q
same-target parity, or broader q8 support.

`structured-re-q4-location-slope-interval-diagnostic-status.tsv` records the
first bounded direct-SD smoke for those q4 location cells. The strong fixture
has `pdHess=TRUE` for all four providers and finite Wald/profile intervals for
all 16 direct-SD targets. Bootstrap is not treated as passed; it is recorded as
`not_run_smoke_budget` so the next gate remains a bounded bootstrap denominator
smoke before any coverage-grid design. The evidence is diagnostic only and does
not admit derived-correlation intervals, interval reliability, interval
coverage, q4 REML, AI-REML, broad bridge support, public support, partial
location-scale support, Q precision marshalling, K/Q same-target parity, or
broader q8 support.

`structured-re-q4-location-slope-bootstrap-budget-probe.tsv` records the first
representative bootstrap budget probe for the same cells. It runs the `phylo()`
`mu1:(Intercept)` direct-SD target with two bootstrap refits, records
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()` as
not run after the local phylo/spatial runtime boundary, and points any complete
direct-SD bootstrap denominator runner to Totoro or a reviewed DRAC/totoro
dispatch plan. This is diagnostic budget evidence only: it does not admit
all-target bootstrap denominators, derived-correlation intervals, interval
reliability, interval coverage, q4 REML, AI-REML, broad bridge support, public
support, partial location-scale support, Q precision marshalling, K/Q
same-target parity, or broader q8 support.

`structured-re-q4-location-slope-bootstrap-dispatch-plan.tsv` records the
reviewable dry-run dispatch manifest for the next q4 location bootstrap gate.
It keeps all 16 direct-SD provider/target cells visible, assigns
provider-rotating shards, and records `dry_run_not_submitted` plus
`not_executed` for every row. The representative budget source remains
explicitly `mu1:(Intercept)`, so the manifest cannot be read as target-level
bootstrap evidence. This sidecar is not a denominator result, interval
reliability result, coverage result, q4 REML result, AI-REML result, broad
bridge result, public-support result, partial location-scale result, Q
precision result, K/Q parity result, or broader q8 result.

`structured-re-q4-location-slope-bootstrap-runner-contract.tsv` records the
next dry-run gate for those same 16 direct-SD provider/target cells. The runner
validates the dispatch manifest, writes a selected target manifest plus run
log, and fails closed for non-dry-run modes. It is runner-contract evidence
only: no bootstrap refits are executed, no Totoro or DRAC job is submitted, no
all-target denominator is admitted, and interval reliability, coverage, q4
REML, AI-REML, broad bridge support, public support, partial location-scale
support, Q precision marshalling, K/Q parity, and broader q8 support remain
unpromoted. The runner now writes provider-filtered dry-run artifacts with
shard-specific manifest and run-log filenames while leaving the default
dashboard contract unchanged. That hardens the next Totoro/DRAC review gate
against accidental overwrite, but it is still not denominator or coverage
evidence.

`structured-re-mu-sigma-slope-parity-fixture.tsv` records the next exact gate:
deterministic same-target native/direct/R-via-Julia fixtures for matched
`mu+sigma` one-slope cells in `phylo()`, fixed-covariance `spatial()`,
A-matrix `animal()`, and K-matrix `relmat()`. It moves only those four support
cells to fixture parity. Labelled structured slope covariance, interval
reliability, coverage, REML, AI-REML, broad bridge support, and relmat Q bridge
marshalling remain unpromoted.

`structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv` records the next
target-level diagnostic plan for those matched cells. It names the 16 direct SD
targets formed by four providers and four endpoint members, plus the Wald,
profile, bootstrap, denominator, and MCSE fields required before any calibrated
coverage wording. The sidecar is plan-only: it does not assert finite intervals,
interval reliability, interval coverage, REML, AI-REML, broad bridge support,
range-estimating spatial support, pedigree/Ainv bridge marshalling, or relmat Q
bridge marshalling.

`structured-re-mu-sigma-slope-interval-diagnostic-status.tsv` records the first
deterministic interval-smoke status for those same 16 direct SD targets. The
method-level artifact records 48 rows: Wald, endpoint-profile, and bootstrap
with two refits for each target. Five targets had finite Wald/profile/bootstrap
intervals, one had finite Wald/bootstrap with profile failure, and ten were
bootstrap-only finite with Wald boundary or profile failure. This is
diagnostic-only status; the q-series support cells still do not promote
interval reliability, coverage, REML, AI-REML, or broad bridge support.

`structured-re-mu-sigma-slope-interval-stability-probe.tsv` records a
follow-up deterministic stability probe for the same matched cells. It uses two
stronger fixture variants, records Wald and endpoint-profile interval rows, and
keeps the same diagnostic-only boundary. The probe resolves most earlier
boundary/profile failures under stronger signal settings: 28 of 32
variant-target combinations had finite Wald/profile intervals. The persistent
exceptions were the fixed-covariance `spatial()` `mu:(Intercept)` and `mu:x`
targets in both variants, so spatial `mu` boundary/profile behavior remains a
blocker before coverage-grid design.

`structured-re-spatial-mu-boundary-diagnostic.tsv` records a focused
fixed-covariance spatial `mu` diagnostic for that blocker. It compares the
original finite smoke seed, the boundary-producing stronger seed, two
alternate strong seeds, a higher-replication version of the boundary seed, and
a `mu`-dominant/low-`sigma` version of the boundary seed. Eight of 12 target
rows had finite Wald/profile intervals, two had finite Wald but failed
endpoint profile, and two stayed at the Wald/profile boundary. The conclusion
is seed/design sensitivity with a fragile `mu:x` endpoint-profile path, not
interval reliability or coverage readiness.

`structured-re-spatial-mu-profile-geometry.tsv` records the follow-up geometry
diagnostic for that fragile `mu:x` path. It evaluates lower and upper
endpoint-profile crossings separately for the six spatial diagnostic designs.
All six upper crossings succeeded. Three lower crossings succeeded, while the
three seed-202 lower crossings failed with constrained-optimizer `NA/NaN`
gradient evaluation. The geometry problem is therefore lower-side endpoint
profiling under seed/design-sensitive spatial `mu:x` fits, not target
discovery: the target remains direct and `profile_ready`.

`structured-re-spatial-mu-profile-strategy.tsv` records the follow-up strategy
diagnostic for the same spatial `mu:x` path. It compares endpoint, `auto`, and
`tmbprofile` engines for the finite `smoke_seed102` control and the three
seed-202 lower-side problem designs. The smoke control stays finite for all
three requested engines. The problematic rows remain nonfinite under endpoint
profiling and under the existing `auto`/`tmbprofile` fallback, so fallback alone
does not turn these spatial `mu:x` rows into interval-denominator candidates.
The sidecar is diagnostic-only and does not add runtime support, interval
reliability, coverage readiness, range-estimating spatial support, or public
support.

`structured-re-spatial-mu-lower-start-diagnostic.tsv` records the next
diagnostic: whether lower-side constrained-endpoint starts can rescue the same
problem rows without changing runtime behavior. It compares the current warm
curvature start against reset curvature, reset capped-step, and reset
fixed-step variants. The finite control remains finite across all variants,
but all three seed-202 problem designs still fail with `NA/NaN gradient
evaluation`. This narrows the next runtime question: the blocker is not only
the starting vector or initial step size, and the rows remain outside interval
denominators.

`structured-re-spatial-mu-domain-guard-diagnostic.tsv` separates target-domain
finiteness from constrained-optimizer path behavior for the same spatial
`mu:x` lower-side problem. Holding nuisance parameters at the fitted values,
the objective and gradient are finite at all nine lower target offsets for the
finite control and the three seed-202 problem designs. Guarded lower-side
prototypes that penalize nonfinite objective evaluations, with and without a
zero-gradient fallback, still rescue only the smoke control. The blocker is
therefore not immediate fixed-nuisance target-domain non-finiteness. The next
runtime decision is whether to implement explicit constrained-profile boundary
handling or to keep these seed/design regimes out of interval denominators.
This evidence remains diagnostic-only and does not change interval, coverage,
REML, AI-REML, broad bridge, or public-support status.

## Implementation Order

The efficient completion order is:

1. Keep this support-cell table and validator contract green.
2. Banked in this slice: add neutral structured metadata wrappers and
   endpoint/member/coefficient identity in `structured_effects()` before adding
   new runtime model cells. The extractor now records provider, matrix
   slot/source/role, compact precision fingerprint, endpoint set, coefficient
   set, covariance layout, member levels, endpoint blocks, and endpoint
   covariance labels for `phylo()`, `spatial()`, `animal()`, `relmat()`, and
   `phylo_interaction()` rows.
3. Banked in this slice: add provider contract tests for `phylo()`,
   `spatial()`, `animal()`, `relmat()`, and `phylo_interaction()`: matrix
   digest, level alignment, input scale, precision/covariance source,
   missing-level policy, and provenance.
4. Banked in this slice at extractor and artifact level: verify Gaussian one
   independent structured `mu` slope identity and source-tested DGP,
   smoke-summary, and grid-writer artifacts across `phylo()`, `spatial()`,
   `animal()`, and `relmat()`. Runtime status stays at the exact point-fit
   cells already recorded in the support-cell table; bridge fixture parity,
   intervals, and coverage remain separate gates.
5. Banked in this tranche for `phylo()`, fixed-covariance `spatial()`,
   A-matrix `animal()`, and K-matrix `relmat()`: add same-target
   native/direct/R-via-Julia bridge fixtures for one independent structured
   `mu` slope. The `relmat()` row also has runtime K/Q same-target parity
   evidence.
6. Banked in this tranche for `phylo()`, fixed-covariance `spatial()`,
   A-matrix `animal()`, and K/Q `relmat()`: open sigma-only one independent
   structured slope point-fit/extractor cells and add same-target
   native/direct/R-via-Julia fixtures. The fixture bridge contract uses the
   provider-safe source for each row: tree branch lengths, fixed covariance
   from coordinates, an A matrix, or a K matrix.
7. Banked in this tranche: open matched `mu+sigma` one-slope native
   point-fit/extractor cells for `phylo()`, fixed-covariance `spatial()`,
   A-matrix `animal()`, and K/Q `relmat()` by requiring four endpoint members,
   then add deterministic same-target native/direct/R-via-Julia fixtures for
   the same four cells. Banked in this slice: add a target-level interval
   diagnostic plan for the 16 direct SD targets and run the first deterministic
   Wald/profile/bootstrap interval smoke. Banked in this slice: run a
   stronger-fixture Wald/profile stability probe that leaves only
   fixed-covariance spatial `mu` intercept/slope targets as persistent
   boundary/profile failures. Banked in this slice: run a focused spatial
   `mu` boundary diagnostic showing seed/design sensitivity, with the
   boundary-producing seed rescued by higher replication or lower `sigma`
   competition for Wald intervals but not fully for the `mu:x` endpoint
   profile. Banked in this slice: run a side-specific endpoint-profile geometry
   diagnostic showing that the `mu:x` failures are lower-side constrained
   optimizer failures while all upper crossings succeed. Banked in this slice:
   compare endpoint, `auto`, and `tmbprofile` engines and show that the existing
   fallback does not rescue the three seed-202 lower-side problem rows. Banked
   in this slice: record the exact pre-optimization rejection contract for the
   three scale-only structured `sigma1+sigma2` q2-plus-q2 sibling cells in
   fixed-covariance `spatial()`, A-matrix `animal()`, and `relmat()`, without
   promoting parser-ready, point-fit, bridge, interval, coverage, REML,
   AI-REML, public-support, q4, or q8 wording. Banked in this slice: compare
   lower-side warm/reset/capped/fixed starts and show
   that these start variants also do not rescue the three seed-202 lower-side
   problem rows. Next work should investigate constrained optimizer domain
   guards or keep those regimes out of coverage denominators before any
   coverage or public support promotion.
8. Banked in this slice: add bivariate Gaussian structured slope-only q=2
   `mu1`/`mu2` covariance cells for `phylo()`, fixed-covariance `spatial()`,
   A/Ainv `animal()`, and K/Q `relmat()`. These are exact `0 + x` cells with
   endpoint members `mu1:x+mu2:x`; they are native point-fit/extractor evidence
   only, not bridge parity, interval reliability, coverage, REML, or AI-REML.
9. Banked in this slice: add the q4 all-four one-slope identity preflight for
   `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
   `relmat()`. This names the exact eight endpoint members and 28 labelled
   covariance pairs expected from q8-shaped all-four one-slope runtime cells.
   Phylo, fixed-covariance spatial, A-matrix animal, and K/Q relmat now have
   runtime point-fit/extractor evidence for their exact shared-label all-four
   cells; bridge parity, intervals, coverage, q4 REML, AI-REML, and public
   support remain planned for all four providers.
10. Banked in this slice: open the exact shared-label phylo all-four
   one-slope runtime point-fit/extractor cell for
   `phylo(1 + x | p | species, tree = tree)` in `mu1`, `mu2`, `sigma1`, and
   `sigma2`. This moves only the phylo row; bridge parity, intervals,
   coverage, q4 REML, AI-REML, and public support remain planned.
11. Banked in this slice: open the exact shared-label fixed-covariance spatial
   all-four one-slope runtime point-fit/extractor cell for
   `spatial(1 + x | p | site, coords = coords)` in `mu1`, `mu2`, `sigma1`,
   and `sigma2`. This moves only the fixed-covariance spatial row;
   range-estimating spatial support, bridge parity, intervals, coverage,
   q4 REML, AI-REML, and public support remain planned.
12. Banked in this slice: add deterministic same-target fixture evidence for
   the exact q4 all-four one-slope runtime cells in `phylo()`,
   fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`.
   Keep pedigree/Ainv animal marshalling, relmat Q bridge marshalling,
   range-estimating spatial support, partial labelled endpoint layouts,
   intervals, coverage, q4 REML, AI-REML, public support, and broader q8
   variants in separate rows.
12a. Banked in this slice: add the q4 all-four intercept interval diagnostic
   plan for the same exact provider cells. This creates 40 planned target rows:
   16 direct-SD future smoke targets and 24 derived-correlation rows blocked on
   interval reconstruction. It does not promote interval reliability, coverage,
   q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad bridge
   support, public support, coverage denominators, range-estimating spatial
   support, pedigree/Ainv animal bridge marshalling, or relmat Q bridge
   marshalling.
12b. Banked in this slice: add the q4 all-four intercept direct-SD denominator
   precheck for those same provider cells. It records 16 direct-SD targets:
   phylo, fixed-covariance spatial, and K-matrix relmat are blocked by
   `pdHess = FALSE`; A-matrix animal has finite Wald/profile intervals but
   nonfinite bootstrap intervals. The precheck keeps all 16 targets out of
   denominator admission and coverage-grid design. It does not promote interval
   reliability, coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared
   AI-REML, broad bridge support, public support, DRAC/Totoro execution,
   coverage denominators, range-estimating spatial support, pedigree/Ainv
   animal bridge marshalling, or relmat Q bridge marshalling.
13. Banked in this slice: add the q4 all-four one-slope interval diagnostic
   plan for the same four exact provider cells. This creates 144 planned target
   rows: 32 direct-SD future smoke targets and 112 derived-correlation rows
   blocked on interval reconstruction. It does not promote interval
   reliability, coverage, q4 REML, AI-REML, broad bridge support, public
   support, coverage denominators, or broader q8 support.
14. Banked in this slice: add the q4 all-four one-slope direct-SD interval
   smoke status for the same four exact provider cells. It covers the 32
   direct-SD targets, corrects the sigma-axis profile-target identity to
   `sd:mu:sigma*` for the shared q8 structured block, and records all targets
   as Hessian-blocked (`pdHess = FALSE`, zero finite intervals). It does not
   admit denominators or promote interval reliability, coverage, q4 REML,
   AI-REML, broad bridge support, public support, or broader q8 support.
15. Banked in this slice: add endpoint-aware q>2 structured contribution
   routing and open exact labelled `mu1+mu2` intercept-plus-one-slope q4
   location cells for `phylo()`, fixed-covariance `spatial()`, A-matrix
   `animal()`, and K-matrix `relmat()`. These are diagnostic native
   point-fit/extractor cells only; bridge parity, partial location-scale
   support, intervals, coverage, q4 REML, AI-REML, public support, and broader
   q8 support remain separate gates.
16. Banked in this slice: add deterministic same-target fixture parity for the
   exact four-member q4 location `mu1+mu2` endpoint map across `phylo()`,
   fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`.
   The relmat row stays K-matrix only; Q precision marshalling, partial
   location-scale support, interval reliability, coverage, q4 REML, AI-REML,
   public support, and broader q8 support remain separate gates.
17. Banked in this slice: add the q4 location one-slope interval diagnostic
   plan for the same four exact provider cells. This creates 40 planned target
   rows: 16 direct-SD future smoke targets and 24 derived-correlation rows
   blocked on interval reconstruction. It does not promote interval
   reliability, coverage, q4 REML, AI-REML, broad bridge support, public
   support, partial location-scale support, Q precision marshalling, K/Q
   same-target parity, or broader q8 support.
18. Banked in this slice: add bounded direct-SD interval smoke for those q4
   location provider cells. All 16 direct-SD targets have finite Wald/profile
   intervals on the strong fixture and bootstrap remains
   `not_run_smoke_budget`; derived-correlation intervals, denominators,
   coverage, q4 REML, AI-REML, public support, partial location-scale support,
   Q precision marshalling, K/Q same-target parity, and broader q8 support
   remain separate gates.
19. Banked in this slice: add a representative q4 location direct-SD bootstrap
   budget probe. The `phylo()` `mu1:(Intercept)` target returns a finite
   two-refit bootstrap interval, while `spatial()`, `animal()`, and `relmat()`
   are explicitly not run in this local budget sidecar. The next denominator
   work should use Totoro or a reviewed DRAC/totoro dispatch plan and must
   retain all provider/target outcomes before any coverage-grid design.
20. Banked in the stacked follow-up slice: add the q4 location direct-SD
   bootstrap dispatch plan. It names all 16 provider/target cells, assigns
   provider-rotating shards, links the representative `mu1:(Intercept)` budget
   source, and keeps every row at `dry_run_not_submitted` and `not_executed`.
   This is reviewable execution planning only; no Totoro or DRAC job has been
   submitted and no denominator, interval-reliability, coverage, REML,
   AI-REML, bridge, public-support, Q precision, K/Q parity, partial
   location-scale, or broader q8 status moves.
21. Banked in the stacked follow-up slice: add the q4 location direct-SD
   bootstrap runner contract. It validates the 16-row dispatch manifest,
   writes a selected target manifest and run log, and refuses execution modes
   other than dry-run. This is runner-contract evidence only; no Totoro or
   DRAC job has been submitted and no denominator, interval-reliability,
   coverage, REML, AI-REML, bridge, public-support, Q precision, K/Q parity,
   partial location-scale, or broader q8 status moves. Banked in the same draft
   PR before compute review: shard-safe provider dry-runs write private
   manifest/log filenames and leave the 16-row dashboard contract unchanged.
21a. Banked in the Tranche 3 q4-admission slice: add the no-promotion
   q4 admission-denominator contract, the 14-row admission-review synthesis,
   and the exact 16-row q4 location target-admission map. The target map links
   each direct-SD provider/endpoint member to its `profile_targets()` name,
   dispatch-plan row, interval-diagnostic row, and SR475 retained-denominator
   source row. All q4 location targets remain
   `not_admitted_cell_pdhess_below_threshold`; all rows remain
   `coverage_not_authorized` and `do_not_promote`. This records admission
   blockers only; no Totoro, DRAC, Fir, Nibi, or Rorqual job has been launched
   and no denominator, interval-reliability, coverage, `inference_ready`,
   `supported`, REML, AI-REML, q8 inference, derived-correlation interval,
   bridge, public-support, Q precision, K/Q parity, partial location-scale, or
   broader q8 status moves.
21b. Closed in the Tranche 3 q4-admission slice: add the seven-row
   source-linked q4 admission closure audit. It rechecks the clean Tranche 2
   support-cell invariants, records high-q no-promotion orientation, freezes
   the q4 denominator contract and admission review, links the exact target map,
   and records the compute policy that Totoro and DRAC remain available but do
   not replace failed admission gates. The closure admits exactly zero q4 rows
   and authorizes exactly zero coverage jobs; no denominator,
   interval-reliability, coverage, `inference_ready`, `supported`, REML,
   AI-REML, q8 inference, derived-correlation interval, bridge, public-support,
   Q precision, K/Q parity, partial location-scale, or broader q8 status moves.
21c. Started in the Tranche 4 q4-location admission-runner slice: add the
   16-row retained-denominator admission-runner design for the exact q4 location
   direct-SD targets. The design maps one-to-one to the Tranche 3 target map,
   sets the first smoke to `n_rep_planned = 5`, and requires host provenance,
   single-threaded workers, separated Totoro/DRAC denominators, retained fit
   errors, nonconvergence, `pdHess = FALSE`, gradient/profile warnings,
   boundary estimates, finite direct-SD Wald/profile intervals, and
   derived-correlation unavailable status before any q4 coverage design. This
   is design-only; no runner has executed, no denominator result has been
   banked, and no coverage, `inference_ready`, `supported`, REML, AI-REML, q8
   inference, derived-correlation interval, bridge, public-support, Q
   precision, K/Q parity, partial location-scale, or broader q8 status moves.
21d. Banked in the Tranche 4 q4-location admission-runner slice: execute the
   local `n = 5` retained-denominator q4 location admission smoke for the exact
   16 direct-SD targets. The raw artifact has 80 retained target rows under
   `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-admission-smoke/`.
   Phylo, spatial, and animal fail the first smoke gate on retained
   `pdHess`/Wald-finite rates (2/5, 3/5, and 4/5 respectively for each
   provider target); relmat is the only provider with 5/5 `pdHess`,
   Wald-finite, and profile-finite rows in this tiny local smoke and remains
   `local_smoke_gate_passed_review_required_no_admission`. The smoke keeps
   host provenance as `local`, keeps derived-correlation intervals
   unavailable, and promotes zero q4 rows. No coverage, interval reliability,
   `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
   derived-correlation interval, bridge, public-support, Q precision, K/Q
   parity, partial location-scale, or broader q8 status moves.
21e. Banked in the Tranche 5 q4-location admission-decision slice: add the
   21-row admission-review decision ledger
   `structured-re-q4-location-admission-tranche5-review.tsv`. The ledger reads
   the Tranche 4 local smoke as review input only: all 16 target rows retain
   `coverage_not_authorized` and `do_not_promote`; phylo and spatial remain
   diagnostic holds, animal requires cheap failure taxonomy before any top-up,
   and relmat is only a host-separated repeat candidate after Rose, Fisher,
   Gauss, Noether, and Grace review. The row-level admission gate remains
   retained-denominator `pdHess`, Wald-finite, and profile-finite direct-SD
   rates of at least 0.95. Kim's rule for the tranche is least compute needed
   for an honest next decision. The member-board discussion rows record all
   standing reviewers, with Rose/Fisher/Gauss/Noether/Grace blocking for any
   admission or compute escalation. This is review-governance evidence only:
   zero q4 rows are admitted, zero q4 coverage jobs are authorized, and no
   interval reliability, `inference_ready`, `supported`, q4 REML, REML,
   AI-REML, q8 inference, derived-correlation interval, bridge, public-support,
   Q precision, K/Q parity, partial location-scale, or broader q8 status moves.
21f. Banked in the Tranche 5 relmat-repeat follow-up: run one host-separated
   Totoro `n = 5` retained-denominator repeat for the exact relmat q4 location
   direct-SD targets and record it in
   `structured-re-q4-location-admission-tranche5-relmat-repeat.tsv`. The repeat
   source is `56add7f0` with dirty working-tree provenance, host label
   `totoro_q4_t5_relmat_repeat`, and copied raw artifacts under
   `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche5-relmat-repeat-totoro/`.
   All four relmat direct-SD targets have 5/5 `pdHess`, Wald-finite, and
   profile-finite rows, while the gradient/profile diagnostics remain retained.
   The result is repeat evidence only: it does not pool with the local smoke,
   does not admit q4, does not authorize coverage, and moves no interval
   reliability, `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8
   inference, derived-correlation interval, bridge, public-support, Q precision,
   K/Q parity, partial location-scale, or broader q8 status.
21g. Banked in the Tranche 6 relmat admission-review slice: add
   `structured-re-q4-location-admission-tranche6-relmat-review.tsv`, a
   Rose/Fisher/Grace post-repeat review ledger for the exact relmat q4 location
   direct-SD targets. It links each target to the Tranche 4 local smoke and the
   Tranche 5 Totoro repeat without pooling denominators. Both evidence streams
   meet 5/5 retained `pdHess`, Wald-finite, and profile-finite direct-SD gates,
   so relmat is admitted only for coverage-design discussion. This does not
   authorize coverage execution, does not move the q4 support-cell status, and
   moves no interval reliability, `inference_ready`, `supported`, q4 REML,
   REML, AI-REML, q8 inference, derived-correlation interval, bridge,
   public-support, Q precision, K/Q parity, partial location-scale, or broader
   q8 status. The next gate is a separate relmat-only q4 location coverage
   pregrid design contract.
21h. Banked in the Tranche 7 relmat pregrid-design slice: add
   `structured-re-q4-location-tranche7-relmat-coverage-pregrid-contract.tsv`,
   a six-row Rose/Fisher/Grace-gated coverage-pregrid contract for the exact
   relmat q4 location direct-SD targets. The four target rows map to existing
   coverage-grid shards 13-16, each at planned SR150 with `bootstrap = 0`;
   Totoro/control-master is the primary host route and DRAC is fallback only
   after submission-pack review. SR150 is an economical screen, not a coverage
   claim, and the MCSE threshold remains reserved for SR475 or a reviewed
   top-up. The contract requires source SHA, dirty-state, host-label,
   seed-manifest, exact-command, run-log, and Mission Control provenance before
   execution because host denominators must stay separated. This banks design
   only: no coverage job is authorized, no result is imported, no q4
   support-cell status moves, and no interval reliability, `inference_ready`,
   `supported`, q4 REML, REML, AI-REML, q8 inference, derived-correlation
   interval, denominator pooling, bridge, public-support, Q precision, K/Q
   parity, partial location-scale, or broader q8 status moves. The next gate is
   Rose/Fisher/Grace approval of the host submission pack before any run.
21i. Banked in the Tranche 8 relmat host-pack slice: add
   `structured-re-q4-location-tranche8-relmat-host-submission-pack.tsv`, the
   fail-closed host submission pack for the same relmat q4 location direct-SD
   pregrid. It records exact Totoro/control-master commands, a relmat-only DRAC
   fallback command, source SHA and dirty-state capture, host-label policy,
   expected output/log paths, and two helper scripts:
   `tools/run-q4-location-relmat-pregrid-totoro.sh` and
   `tools/slurm/q4-location-relmat-pregrid.sbatch`. Both helpers require
   `DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace` before they run. This is
   submission-pack evidence only: no Totoro command is executed, no DRAC job is
   submitted, no result is imported, no q4 support-cell status moves, and no
   interval reliability, `inference_ready`, `supported`, q4 REML, REML,
   AI-REML, q8 inference, derived-correlation interval, denominator pooling,
   bridge, public-support, Q precision, K/Q parity, partial location-scale, or
   broader q8 status moves. The next gate is a fresh checkpoint plus explicit
   Rose/Fisher/Grace execution approval before spending Totoro or DRAC time.
21j. Banked in the Tranche 34 relmat host-preflight slice: add
   `structured-re-q4-location-tranche34-relmat-host-preflight.tsv`, the
   fresh host-source check before q4 relmat SR150 execution. Totoro is
   reachable through the ControlMaster route and has `Rscript` 4.5.3, but
   `/home/snakagaw/codex/drmTMB` is not a normal source checkout for this run:
   git resolves the top level to `/home/snakagaw`, `HEAD` is unavailable, the
   Tranche 8 Totoro wrapper is missing, and the relmat-only DRAC fallback script
   is missing there. Grace therefore blocks execution before any fitting. This
   is preflight evidence only: no Totoro command is executed, no DRAC job is
   submitted, no result is imported, no coverage-evaluable denominator is
   created, no q4 support-cell status moves, and no interval reliability,
   `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
   derived-correlation interval, denominator pooling, bridge, public-support, Q
   precision, K/Q parity, partial location-scale, or broader q8 status moves.
   The next gate is a synchronized Totoro run source or verified DRAC fallback
   checkout, followed by a repeated host preflight and checkpoint before any
   q4 relmat pregrid execution.
21k. Banked in the Tranche 35 relmat source-snapshot preflight slice: add
   `structured-re-q4-location-tranche35-relmat-source-snapshot-preflight.tsv`.
   A new isolated Totoro source snapshot was staged at
   `/home/snakagaw/codex/drmTMB-q4loc-tranche35-source-56add7f0-20260702T002713Z`
   with source provenance and a 3,057-file SHA-256 manifest. The local q4
   wrapper, q4 coverage runner, and relmat-only DRAC fallback hashes match the
   remote manifest; the Totoro wrapper dry-ran all four relmat q4 location
   shards, and the execution path failed closed with exit 2 when approval was
   absent. This is still preflight evidence only: the snapshot is dirty, no fit
   is run, no DRAC job is submitted, no coverage-evaluable denominator is
   created, no q4 support-cell status moves, and no interval reliability,
   `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
   derived-correlation interval, denominator pooling, bridge, public-support,
   Q precision, K/Q parity, partial location-scale, or broader q8 status
   moves. The next gate is Rose/Fisher/Grace review of dirty snapshot versus
   clean committed source, then a fresh checkpoint before at most shard 13 can
   run.
21l. Banked in the Tranche 36 relmat shard-13 execution-decision slice: add
   `structured-re-q4-location-tranche36-relmat-shard13-execution-decision.tsv`.
   Rose/Fisher/Grace accept the exact dirty, manifested Totoro snapshot for one
   diagnostic SR150 pregrid shard only: shard 13 for `mu1:(Intercept)`, with
   source manifest hash
   `ea168bf85286f7ac81d622105efd2b566f737384ab8f0d33c48c30994133ccf8`.
   This is an execution-decision gate, not result evidence: no four-shard
   execution, DRAC submission, coverage grid, result import, q4 support-cell
   status move, interval reliability, `inference_ready`, `supported`, q4 REML,
   REML, AI-REML, q8 inference, derived-correlation interval, denominator
   pooling, bridge, public-support, Q precision, K/Q parity, partial
   location-scale, or broader q8 status moves. A terminal review must import
   retained attempts before any denominator can count, and another review is
   required before any further shard.
21m. Banked in the Tranche 37 relmat shard-13 terminal-review slice: add
   `structured-re-q4-location-tranche37-relmat-shard13-terminal-review.tsv`
   and import the Totoro artifacts under
   `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche37-relmat-shard13-totoro-load-blocker/`.
   The approved shard reached the q4 runner and wrote 150 retained replicate
   rows, but every row is `not_attempted` because `drmTMB` was not loadable and
   `--attempt-temp-install` was not requested. This creates no coverage-
   evaluable denominator and authorizes no retry, four-shard execution, DRAC
   submission, coverage grid, result import beyond terminal review, q4
   support-cell status movement, interval reliability, `inference_ready`,
   `supported`, q4 REML, REML, AI-REML, q8 inference, derived-correlation
   interval, denominator pooling, bridge, public-support, Q precision, K/Q
   parity, partial location-scale, or broader q8 status movement. The next gate
   is a reviewed loadable-source route, then a new source snapshot, dry-run,
   checkpoint, and Rose/Fisher/Grace approval before retry.
21n. Banked in the Tranche 38 relmat temp-install route-contract slice: add
   `structured-re-q4-location-tranche38-relmat-temp-install-route-contract.tsv`
   and update `tools/run-q4-location-relmat-pregrid-totoro.sh` so the Totoro
   wrapper exposes `--attempt-temp-install` and
   `DRMTMB_Q4LOC_ATTEMPT_TEMP_INSTALL=true`, forwarding the existing q4 runner
   temp-install route during dry-run. This is route plumbing only: no Totoro
   fit execution, shard-13 retry, shards 14-16, DRAC submission, coverage grid,
   coverage result, coverage-evaluable denominator, q4 support-cell status
   movement, interval reliability, `inference_ready`, `supported`, q4 REML,
   REML, AI-REML, q8 inference, derived-correlation interval, denominator
   pooling, bridge, public support, Q precision, K/Q parity, partial
   location-scale, or broader q8 status moves. The old Tranche 35-36 helper
   hash is superseded for future execution planning. The next gate is a fresh
   Totoro source snapshot with the new wrapper hash, a Totoro dry-run for shard
   13 with `--attempt-temp-install`, a checkpoint, and Rose/Fisher/Grace
   approval before any retry.
21o. Banked in the Tranche 39 relmat source-snapshot dry-run slice: add
   `structured-re-q4-location-tranche39-relmat-source-snapshot-dryrun.tsv`
   and import the Totoro dry-run artifacts under
   `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche39-relmat-temp-install-dryrun-totoro/`.
   The fresh snapshot at
   `/home/snakagaw/codex/drmTMB-q4loc-tranche39-source-56add7f0-20260702T012433Z`
   records source provenance, a 3,770-line SHA-256 manifest, host/session
   evidence, wrapper hash
   `9133474766f6968f4344871e48c8b8a92cfdedc2bfff15e94a6fcc4b3afa9b8c`, and a
   shard-13 dry-run transcript that forwards `--attempt-temp-install`. This is
   snapshot and dry-run proof only: no package temp install, Totoro fit
   execution, shard-13 retry, shards 14-16, DRAC submission, coverage grid,
   coverage result, coverage-evaluable denominator, q4 support-cell status
   movement, interval reliability, `inference_ready`, `supported`, q4 REML,
   REML, AI-REML, q8 inference, derived-correlation interval, denominator
   pooling, bridge, public support, Q precision, K/Q parity, partial
   location-scale, or broader q8 status moves. The next gate is a checkpoint
   and Rose/Fisher/Grace approval before exactly one shard-13 retry from this
   snapshot.
21p. Banked in the Tranche 40 relmat shard-13 execution-gate slice: add
   `structured-re-q4-location-tranche40-relmat-shard13-execution-gate.tsv`
   and the remote-snapshot probe note under
   `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche40-relmat-shard13-execution-gate-totoro/`.
   Totoro still has the Tranche 39 source snapshot, the wrapper is executable,
   and the manifest, provenance, wrapper, coverage-runner, and DRAC sbatch
   hashes match the Tranche 39 proof. This is approval only for exactly one
   shard-13 temp-install retry after checkpoint: no package temp install,
   Totoro fit execution, retained denominator, shards 14-16, DRAC submission,
   coverage grid, coverage result, q4 support-cell status movement, interval
   reliability, `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8
   inference, derived-correlation interval, denominator pooling, bridge, public
   support, Q precision, K/Q parity, partial location-scale, or broader q8
   status moves. The next gate is a Tranche 41 terminal review before any
   denominator or status discussion.
21q. Banked in the Tranche 41 relmat shard-13 terminal-review slice: import the
   Totoro run root under
   `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche41-relmat-shard13-temp-install-terminal-totoro/`
   and add
   `structured-re-q4-location-tranche41-relmat-shard13-terminal-review.tsv`.
   The single approved shard requested `--attempt-temp-install` and exited 1
   before fitting because `TMB` and `RcppEigen` were unavailable for the
   temporary `drmTMB` install. The imported shard has 150 `not_attempted`
   replicate rows, zero fits, zero `pdHess`, zero finite Wald intervals, and
   zero finite profile intervals. This is terminal blocker evidence only: no
   retained denominator, retry, shards 14-16, DRAC submission, coverage grid,
   coverage result, q4 support-cell status movement, interval reliability,
   `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
   derived-correlation interval, denominator pooling, bridge, public support,
   Q precision, K/Q parity, partial location-scale, or broader q8 status
   moves. The next gate is a reviewed dependency route for `TMB` and
   `RcppEigen` on Totoro or a source-and-dependency-provenanced DRAC fallback.
21r. Banked in the Tranche 42 relmat dependency-route preflight slice: add
   `structured-re-q4-location-tranche42-relmat-dependency-route-preflight.tsv`
   and the Totoro probe transcript under
   `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche42-relmat-dependency-route-preflight-totoro/`.
   Totoro has R 4.5.3, a writable user library at `/home/snakagaw/R/lib`,
   installed `Rcpp` and `Matrix`, reachable CRAN metadata for `TMB` 1.9.21 and
   `RcppEigen` 0.3.4.0.2, and a usable gcc/g++ toolchain; `TMB` and
   `RcppEigen` are not installed yet. This is dependency-route evidence only:
   no dependency install, q4 retry, shard execution, shards 14-16, DRAC
   submission, package load proof, retained denominator, coverage grid,
   coverage result, q4 support-cell status movement, interval reliability,
   `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
   derived-correlation interval, denominator pooling, bridge, public support,
   Q precision, K/Q parity, partial location-scale, or broader q8 status
   moves. The next gate is a checkpointed Totoro-only install of `TMB` and
   `RcppEigen` into `/home/snakagaw/R/lib`, with install logs and dependency
   provenance banked before any q4 retry or denominator discussion.
21s. Banked in the Tranche 43 relmat dependency-install terminal-review slice:
   add
   `structured-re-q4-location-tranche43-relmat-dependency-install-terminal-review.tsv`
   and the Totoro install artifacts under
   `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche43-relmat-dependency-install-totoro/`.
   The first script attempt failed before installation because
   `download.packages()` output was parsed as if it had column names. The second
   attempt installed `RcppEigen` 0.3.4.0.2 and `TMB` 1.9.21 from CRAN source
   tarballs into `/home/snakagaw/R/lib`, recorded SHA-256 hashes
   `ecad7ba2129fd48b7ebb825558d38492ed1f3a8934959e27fcd6688175e542bb`
   for `RcppEigen` and
   `b07fff7186b3025507038cd69cdee99c7efb9269947cb80f3f55ea376d45e53a`
   for `TMB`, and verified `requireNamespace()` for both packages. This is
   dependency-install evidence only: no `drmTMB` load, q4 fit, q4 retry, shard
   execution, shards 14-16, DRAC submission, retained denominator, coverage
   grid, coverage result, q4 support-cell status movement, interval
   reliability, `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8
   inference, derived-correlation interval, denominator pooling, bridge, public
   support, Q precision, K/Q parity, partial location-scale, or broader q8
   status moves. The next gate is a checkpoint and Rose/Fisher/Grace approval
   before exactly one relmat q4 shard-13 temp-install retry from the Tranche 39
   source snapshot, followed by a Tranche 44 terminal review before any
   denominator or status discussion.
21t. Banked in the Tranche 44 relmat shard-13 after-dependency-install
   terminal-review slice: add
   `structured-re-q4-location-tranche44-relmat-shard13-after-deps-terminal-review.tsv`
   and the Totoro retry artifacts under
   `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche44-relmat-shard13-after-deps-terminal-totoro/`.
   The single approved shard ran from the Tranche 39 source snapshot with
   `DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace` and
   `--attempt-temp-install`; remote preflight verified the source and wrapper
   hashes, `TMB` and `RcppEigen` were available in `/home/snakagaw/R/lib`,
   `drmTMB` loaded, and R exited 0. All 150 replicates fit and converged, but
   retained-denominator admission failed: `pdHess` and Wald-finite rates were
   both 112/150 = 0.7467, below the 0.95 gate, with 38 boundary rows; profile
   finite rate was 149/150 = 0.9933, including one `profile_failed` row with
   `NA/NaN gradient evaluation`. This is terminal review evidence only: no
   denominator admission, coverage authorization, coverage result, shards
   14-16, DRAC submission, top-up, q4 support-cell status movement, interval
   reliability, `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8
   inference, derived-correlation interval, denominator pooling, bridge,
   public support, Q precision, K/Q parity, partial location-scale, or broader
   q8 status moves. The next gate is a checkpointed relmat q4 route-hold and
   failure-taxonomy decision, reviewed by Rose/Fisher/Grace, before any retry,
   top-up, shards 14-16, DRAC, coverage, denominator admission, or status
   discussion.
21u. Banked in the Tranche 45 relmat after-dependency-install route-hold and
   failure-taxonomy slice: add
   `structured-re-q4-location-tranche45-relmat-after-deps-route-hold-failure-taxonomy.tsv`.
   This slice reviews the existing Tranche 44 Totoro shard-13 artifacts without
   running any new replicate. It classifies the admission blocker as
   boundary-coupled `pdHess` and Wald nonfiniteness: 150/150 fits succeeded,
   but `pdHess` and Wald-finite rates were both 112/150 = 0.7467, below the
   0.95 retained-denominator gate, with 38 boundary rows. The profile-finite
   rate was 149/150 = 0.9933, including one `profile_failed` row with `NA/NaN
   gradient evaluation`, but this does not rescue the failed admission gate.
   All standing reviewers are represented on SC389; Rose, Fisher, Gauss,
   Noether, and Grace are blocking for admission or compute decisions. This is
   route-hold taxonomy only: no new compute, denominator admission, coverage
   authorization, shards 14-16, DRAC submission, Totoro top-up, q4 support-cell
   status movement, interval reliability, `inference_ready`, `supported`, q4
   REML, REML, AI-REML, q8 inference, derived-correlation interval,
   denominator pooling, bridge, public support, Q precision, K/Q parity,
   partial location-scale, or broader q8 status moves. The next gate is exactly
   one reviewed no-compute failure-class contract or an explicit relmat q4
   parking decision.
21v. Banked in the Tranche 46 relmat boundary-Hessian inspection-contract
   slice: add
   `structured-re-q4-location-tranche46-relmat-boundary-hessian-inspection-contract.tsv`.
   This selects the boundary/pdHess geometry route from Tranche 45 but still
   does not run an inspection, model refit, host command, replay, or remote file
   fetch. The seven-row contract names the artifact-only checks required for
   the next tranche: inventory the 38 boundary rows, test whether `pdHess =
   FALSE` is exactly coupled to Wald nonfiniteness, classify fallback optimizer
   and `NaN` messages, inspect replicate 119 / seed 980118 as the single
   profile exception, inventory whether raw Hessian/eigenstructure artifacts
   exist locally, screen direct-SD scale patterns, and summarize the stop
   rules. This is contract evidence only: no artifact-inspection result,
   compute, denominator admission, coverage authorization, shards 14-16, DRAC
   submission, Totoro top-up, q4 support-cell status movement, interval
   reliability, `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8
	   inference, derived-correlation interval, denominator pooling, bridge,
	   public support, Q precision, K/Q parity, partial location-scale, or broader
	   q8 status moves. The next gate is an artifact-only inspection from existing
	   files or an explicit relmat q4 parking decision.
21w. Banked in the Tranche 47 relmat boundary-Hessian inspection-result slice:
   add
   `structured-re-q4-location-tranche47-relmat-boundary-hessian-inspection-result.tsv`.
   This executes the Tranche 46 artifact-only inspection using existing Tranche
   44 Totoro shard-13 files only. The eight-row result shows that all 38 boundary
   rows are exactly the 38 `pdHess = FALSE` rows and exactly the 38 Wald-nonfinite
   rows; the only profile failure is replicate 119 / seed 980118; fallback
   optimizer and `NaN` messages are diagnostic; direct-SD estimate ranges overlap
   between boundary and non-boundary rows; and the imported artifact tree lacks
   raw Hessian/eigenstructure files. The admission gate remains failed because
   `pdHess` and Wald-finite rates are 112/150 = 0.7467, below 0.95. This is an
   inspection result only: no new compute, denominator admission, coverage
   authorization, shards 14-16, DRAC submission, Totoro command, top-up, route
   execution, raw Hessian claim, q4 support-cell status movement,
   `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
   derived-correlation interval, denominator pooling, bridge, public support, Q
   precision, K/Q parity, partial location-scale, or broader q8 status moves. The
   next gate is to park relmat q4 or write a separate reviewed
   design/instrumentation contract before any compute.
21x. Banked in the Tranche 48 relmat q4 parking-decision slice: add
   `structured-re-q4-location-tranche48-relmat-parking-decision.tsv`. This parks
   the failed relmat q4 `mu1` direct-SD admission route after the Tranche 47
   artifact-only inspection. The route stays parked because `pdHess` and
   Wald-finite rates are 112/150 = 0.7467, the 38 boundary rows are exactly the
   38 `pdHess = FALSE` and Wald-nonfinite rows, profile finite 149/150 does not
   rescue the failed retained-denominator gate, and the imported artifact tree
   lacks raw Hessian/eigenstructure evidence. The underlying support cell is not
   changed: it remains `point_fit`, `extractor_ready`, `fixture_parity`,
   `diagnostic_only`, `planned`, and `source`. This is parking only: no new
   compute, denominator admission, coverage authorization, shards 14-16, DRAC
   submission, Totoro command, remote fetch, top-up, route execution, q4
   support-cell status movement, `inference_ready`, `supported`, q4 REML, REML,
   AI-REML, q8 inference, derived-correlation interval, denominator pooling,
   bridge, public support, Q precision, K/Q parity, partial location-scale, or
   broader q8 status moves. The route may reopen only through a separate
   reviewed design or instrumentation contract approved by
   Rose/Fisher/Gauss/Noether/Grace and checkpointed before compute. The next
   gate is to return to the Q-Series campaign queue and select the next
   non-parked tranche.
21y. Banked in the Tranche 49 q1 sigma-intercept blocker-decision slice: add
   `structured-re-gaussian-lowq-tranche49-q1-sigma-intercept-blocker-decision.tsv`.
   This returns from the parked relmat q4 route to the first live low-q queue
   item and blocks the current animal/relmat q1 `sigma` intercept endpoint
   zero-boundary profile route. The decision is based on existing evidence:
   the Nibi SR150 raw-Wald pregrid retained 150/150 fits but only 115/150
   usable Wald intervals with 118/150 warning replicates, while the local
   SR1000 endpoint-profile replay is finite 1000/1000 but covers 0.9430 with
   MCSE 0.007332, 12 lower misses, 45 upper misses, and 757/1000 profiles on
   the lower SD boundary. The `tmbprofile` fallback remains 0/5 finite. This
   is a blocker decision only: no new compute, Totoro command, Nibi/Rorqual or
   DRAC top-up, denominator admission, coverage authorization, support-cell
   status movement, `interval_status`, `coverage_status`, `inference_ready`,
   `supported`, q1 `mu`, matched `mu+sigma`, q2, q4/q8, non-Gaussian interval,
   REML, AI-REML, bridge, or public-support claim moves. The animal and relmat
   q1 `sigma` intercept support cells remain `point_fit`, `extractor_ready`,
   `fixture_parity`, `planned`, `planned`, and `source`. The route can reopen
   only through a new reviewed q1 `sigma` interval design; the next gate is to
   return to the Q-Series campaign queue and select a new route or another
   non-parked bucket.
21z. Banked in the Tranche 50 animal q1 `mu` intercept blocker-decision slice:
   add
   `structured-re-gaussian-lowq-tranche50-animal-q1-mu-intercept-blocker-decision.tsv`.
   This turns the earlier animal q1 `mu` boundary/profile review into an
   explicit no-compute decision. The source evidence is mixed only as labelled
   provenance, not as a pooled denominator: Nibi SR475 has 475/475 fits,
   convergence, `pdHess`, and `confint`, with 473/475 usable Wald intervals and
   retained `wald_at_boundary` seeds 812407 and 812444; the local hard-seed
   endpoint-profile replay is finite 2/2 but both intervals upper-miss truth
   0.55, while `tmbprofile` is 0/2 finite with `nonfinite_interval`. This is a
   boundary/profile interval-shape blocker, not an MCSE or top-up problem. It
   authorizes no new compute, Totoro/FIIA command, Nibi/Rorqual/Trillium or
   DRAC top-up, denominator admission, coverage authorization, support-cell
   status movement, `interval_status`, `coverage_status`, `inference_ready`,
   `supported`, q1 `sigma`, matched `mu+sigma`, q2, q4/q8, non-Gaussian
   interval, REML, AI-REML, bridge, or public-support claim moves. The animal
   q1 `mu` intercept support cell remains `point_fit`, `extractor_ready`,
   `fixture_parity`, `planned`, `planned`, and `source`. The route can reopen
   only through a new reviewed animal q1 `mu` interval design; the next gate is
   to return to the Q-Series campaign queue and select a new route or another
   non-parked bucket.
21aa. Banked in the Tranche 51 animal q1 `mu` interval-route design slice:
   add
   `structured-re-gaussian-lowq-tranche51-animal-q1-mu-interval-route-design.tsv`.
   This eight-row sidecar records the reviewed route choice after the Tranche
   50 blocker. The current Wald route remains blocked by the SR475 retained
   `wald_at_boundary` rows, the endpoint-profile and `tmbprofile` routes remain
   blocked by the hard-seed replay, and split-calibration or adjusted-profile
   ideas are parked until there is a principled derivation. The only selected
   next candidate is a parametric-bootstrap direct-SD hard-seed micro-smoke,
   but it is not executable yet because the q1 `mu` runner lacks a bootstrap
   flag and refit-attempt accounting. This tranche authorizes no runner patch,
   bootstrap refits, Totoro/FIIA command, Nibi/Rorqual/Trillium or DRAC
   command, denominator admission, coverage result, support-cell status
   movement, `interval_status`, `coverage_status`, `inference_ready`,
   `supported`, q1 `sigma`, matched `mu+sigma`, q2, q4/q8, non-Gaussian
   interval, REML, AI-REML, bridge, or public-support claim moves. The animal
   q1 `mu` intercept support cell remains `point_fit`, `extractor_ready`,
   `fixture_parity`, `planned`, `planned`, and `source`. The next gate is a
   Tranche 52 executable bootstrap micro-smoke contract for only hard seeds
   812407 and 812444, or an explicit reviewer rejection of the bootstrap route
   before any host command.
21ab. Banked in the Tranche 52 animal q1 `mu` bootstrap-smoke contract slice:
   add
   `structured-re-gaussian-lowq-tranche52-animal-q1-mu-bootstrap-smoke-contract.tsv`
   plus the internal guarded wrapper
   `tools/run-gaussian-lowq-tranche52-animal-q1-mu-bootstrap-smoke.sh` and the
   `bootstrap_smoke` mode in
   `tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R`. This closes
   the Tranche 51 runner gap but does not execute the candidate. The exact
   command is approval-gated by
   `DRMTMB_Q1_MU_TRANCHE52_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace`,
   targets only animal hard seeds 812407 and 812444 with `bootstrap_R = 2`,
   writes artifacts only with `--write-dashboard=false`, and records
   hard-seed, host, source-contract, Wald, and bootstrap-status fields for
   reviewer import. This tranche authorizes no bootstrap refits, Totoro/FIIA
   command, Nibi/Rorqual/Trillium or DRAC command, denominator admission,
   coverage result, bootstrap reliability claim, support-cell status movement,
   `interval_status`, `coverage_status`, `inference_ready`, `supported`, q1
   `sigma`, matched `mu+sigma`, q2, q4/q8, non-Gaussian interval, REML,
   AI-REML, bridge, or public-support claim moves. The animal q1 `mu`
   intercept support cell remains `point_fit`, `extractor_ready`,
   `fixture_parity`, `planned`, `planned`, and `source`. The next gate is
   explicit Rose/Fisher/Gauss/Noether/Grace approval for the exact two-seed
   smoke, or return to another non-compute low-q route.
21ac. Banked in the Tranche 53 animal/relmat q1 `sigma` interval-route design
   slice: add
   `structured-re-gaussian-lowq-tranche53-q1-sigma-interval-route-design.tsv`.
   This fourteen-row sidecar records the reviewed route choice after the
   Tranche 49 endpoint-zero-boundary profile blocker. The current raw Wald,
   endpoint-profile, `tmbprofile`, and split-tail calibration routes remain
   blocked or parked, and the only selected next candidate is a
   parametric-bootstrap direct-`sigma`-SD boundary-seed micro-smoke. The q1
   `sigma` runner is not executable for this route yet because it lacks a
   bootstrap flag, exact seed-list mode, and refit accounting. This tranche
   authorizes no runner patch, bootstrap refits, Totoro/FIIA command,
   Nibi/Rorqual/Trillium or DRAC command, denominator admission, coverage
   result, support-cell status movement, `interval_status`,
   `coverage_status`, `inference_ready`, `supported`, q1 `mu`, matched
   `mu+sigma`, q2, q4/q8, non-Gaussian interval, REML, AI-REML, bridge, or
   public-support claim moves. The animal and relmat q1 `sigma` support cells
   remain `point_fit`, `extractor_ready`, `fixture_parity`, `planned`,
   `planned`, and `source`. The next gate is a Tranche 54 executable
   bootstrap micro-smoke contract with an exact retained boundary/failure seed
   manifest, or an explicit reviewer rejection of the bootstrap route before
   any host command.
21ad. Banked in the Tranche 54 animal/relmat q1 `sigma` bootstrap-smoke
   contract slice: add
   `structured-re-gaussian-lowq-tranche54-q1-sigma-bootstrap-smoke-contract.tsv`
   plus the internal wrapper
   `tools/run-gaussian-lowq-tranche54-q1-sigma-bootstrap-smoke.sh`.
   The q1 `sigma` runner now has `bootstrap_smoke` mode, exact
   `--seed-list` handling for retained seeds 914008 and 914011, bootstrap
   refit accounting, and a sidecar command-row check. The wrapper refuses
   without
   `DRMTMB_Q1_SIGMA_TRANCHE54_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace`
   and pins `bootstrap_R = 2`, `--profile=false`, and
   `--write-dashboard=false`. This tranche authorizes no bootstrap refits,
   Totoro/FIIA command, Nibi/Rorqual/Trillium or DRAC command, denominator
   admission, coverage result, support-cell status movement,
   `interval_status`, `coverage_status`, `inference_ready`, `supported`, q1
   `mu`, matched `mu+sigma`, q2, q4/q8, non-Gaussian interval, REML,
   AI-REML, bridge, or public-support claim moves. The animal and relmat q1
   `sigma` support cells remain `point_fit`, `extractor_ready`,
   `fixture_parity`, `planned`, `planned`, and `source`. The next gate is
   explicit Rose/Fisher/Gauss/Noether/Grace approval for the exact
   artifact-only four-row bootstrap plumbing smoke, followed by a reviewed
   Tranche 55 terminal-review sidecar before any route expansion, top-up,
   coverage, or status edit.
21ae. Banked in the Tranche 55 q1 `mu` one-slope interval-rule hold slice:
   add
   `structured-re-gaussian-mu-slope-tranche55-interval-rule-hold-decision.tsv`
   as a no-compute decision layer over the existing review-decision,
   interval-shape, rule-screen, and split-calibration evidence. This slice
   rejects the current hybrid rule, large ad hoc widening multipliers, and
   split calibration as executable support routes; it selects no new interval
   rule, runs no retained replay, and authorizes no Totoro/FIIA command,
   Nibi/Rorqual/Trillium or DRAC command, top-up, coverage result,
   support-cell status movement, `interval_status`, `coverage_status`,
   `inference_ready`, `supported`, q1 `sigma`, matched `mu+sigma`, q2,
   q4/q8, non-Gaussian interval, REML, AI-REML, bridge, or public-support
   claim moves. The phylo, spatial, animal, and relmat q1 `mu` one-slope
   support cells remain `point_fit`, `extractor_ready`, `fixture_parity`,
   `planned`, `planned`, and `source`. This is distinct from the future q1
   `sigma` bootstrap terminal-review artifact import referenced by Tranche
   54, which remains locked until explicit Rose/Fisher/Gauss/Noether/Grace
   approval. The next gate for q1 `mu` one-slope is a symbolic skew-aware or
   boundary-aware direct-SD interval rule, local retained-artifact replay, and
   Rose/Fisher/Noether/Grace review plus checkpoint before any host smoke,
   top-up, coverage, or status edit.
21af. Banked in the Tranche 56 q1 `mu` one-slope symbolic interval-rule
   contract slice: add
   `structured-re-gaussian-mu-slope-tranche56-symbolic-interval-rule-contract.tsv`
   as the symbolic/replay gate before any replay code or host work exists.
   The contract separates q1 `mu` intercept and slope direct-SD targets,
   preserves the retained truth/endpoint/recovery mapping, names
   likelihood-shape and boundary-bootstrap families as candidate families only,
   rejects post hoc multiplier screens and failed split-calibration constants
   as executable rules, and defines the retained-replay schema required before
   any smoke. This tranche selects no executable interval rule, runs no
   retained replay, and authorizes no Totoro/FIIA command, Nibi/Rorqual/
   Trillium or DRAC command, top-up, coverage result, support-cell status
   movement, `interval_status`, `coverage_status`, `inference_ready`,
   `supported`, q1 `sigma`, matched `mu+sigma`, q2, q4/q8, non-Gaussian
   interval, REML, AI-REML, bridge, or public-support claim moves. The next
   gate is a Tranche 57 local retained-artifact replay builder with detail and
   summary outputs only; support-cell status and host work remain blocked
   until replay results pass Rose/Fisher/Noether/Grace review plus checkpoint.
21ag. Banked in the Tranche 57 q1 `mu` one-slope retained replay slice: add
   `tools/run-gaussian-mu-slope-tranche57-retained-replay-builder.R`,
   generate
   `structured-re-gaussian-mu-slope-tranche57-retained-replay-summary.tsv`,
   and mirror the source index, 3,303-row detail table, summary, and run log
   under
   `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche57-retained-replay-local/`.
   This is a deterministic local join of retained artifacts only: no fit, no
   simulation, no executable interval rule, no Totoro/FIIA command,
   Nibi/Rorqual/Trillium or DRAC command, top-up, coverage result,
   support-cell status movement, `interval_status`, `coverage_status`,
   `inference_ready`, `supported`, q1 `sigma`, matched `mu+sigma`, q2, q4/q8,
   non-Gaussian interval, REML, AI-REML, bridge, or public-support claim moves.
   Spatial intercept and slope pass diagnostic-only current-hybrid replay
   gates, but phylo, animal, relmat, and the tranche summary remain blocked.
   The next gate is Rose/Fisher/Noether/Grace review before any
   candidate-rule equation, runner contract, host smoke, top-up, coverage, or
   support-cell status edit.
21ah. Banked in the Tranche 58 q1 `mu` one-slope retained replay review
   slice: add
   `structured-re-gaussian-mu-slope-tranche58-retained-replay-review.tsv` and
   companion `member-discussions.tsv` rows. This tranche is a review ledger
   over T57 evidence, not new compute. It lets spatial intercept and slope feed
   only a later spatial-only candidate-rule equation or runner contract with
   execution disabled by default. Phylo, animal, and relmat remain in
   rule-design hold; no all-provider q1 `mu` one-slope rule is selected. Every
   T58 row keeps `no_compute_in_tranche58`, `coverage_not_authorized`, and
   `do_not_promote`, and no support-cell status, `interval_status`,
   `coverage_status`, `inference_ready`, `supported`, q1 `sigma`, matched
   `mu+sigma`, q2, q4/q8, non-Gaussian interval, REML, AI-REML, bridge, or
   public-support claim moves. The next gate is at most a Tranche 59
   spatial-only candidate contract; host smoke, top-up, coverage, and status
   edits remain blocked until Rose/Fisher/Noether/Grace review plus checkpoint.
21ai. Banked in the Tranche 59 q1 `mu` one-slope spatial-only candidate
   contract slice: add
   `structured-re-gaussian-mu-slope-tranche59-spatial-candidate-contract.tsv`
   and companion `member-discussions.tsv` rows. This tranche documents the
   spatial direct-SD target identities, candidate current-hybrid endpoint
   equation, retained-replay input boundary, future host-runner contract
   requirements, admission gate, review gate, and unchanged status boundary.
   It is a disabled contract, not execution permission: every row keeps
   `disabled_by_default`, `no_compute_in_tranche59`,
   `coverage_not_authorized`, and `do_not_promote`. Phylo, animal, and relmat
   stay in rule-design hold. No host command, Totoro/FIIA command,
   Nibi/Rorqual/Trillium or DRAC command, top-up, coverage result,
   support-cell status movement, `interval_status`, `coverage_status`,
   `inference_ready`, `supported`, q1 `sigma`, matched `mu+sigma`, q2, q4/q8,
   non-Gaussian interval, REML, AI-REML, bridge, or public-support claim moves.
   The next gate is Rose/Fisher/Noether/Grace review plus checkpoint before at
   most a Tranche 60 spatial-only host-smoke contract with execution disabled
   by default.
21aj. Banked in the Tranche 60 q1 `mu` one-slope spatial-only host-smoke
   contract slice: add
   `structured-re-gaussian-mu-slope-tranche60-spatial-host-smoke-contract.tsv`
   and companion `member-discussions.tsv` rows. This tranche documents the
   future spatial `n = 5` host-smoke shape, planned seed manifest, retained-
   denominator rule, host-provenance artifacts, command gate, terminal-review
   import boundary, and unchanged status boundary. It is still a disabled
   contract, not a runner and not execution permission: every row keeps
   `planned_runner = not_written_in_tranche60`,
   `disabled_by_default`, `no_compute_in_tranche60`,
   `coverage_not_authorized`, and `do_not_promote`. Totoro/FIIA is only a
   future primary host after review; DRAC is only a fallback after separate
   run-root/source-checkout review; host denominators must not pool. No host
   command, Totoro/FIIA command, DRAC command, top-up, coverage result,
   host-denominator evidence, support-cell status movement, `interval_status`,
   `coverage_status`, `inference_ready`, `supported`, q1 `sigma`, matched
   `mu+sigma`, q2, q4/q8, non-Gaussian interval, REML, AI-REML, bridge, or
   public-support claim moves. The next gate is Rose/Fisher/Noether/Grace
   review plus checkpoint before at most a Tranche 61 spatial-only runner or
   execution packet with execution disabled by default.
21ak. Banked in the Tranche 61 q1 `mu` one-slope spatial-only execution-packet
   slice: add
   `structured-re-gaussian-mu-slope-tranche61-spatial-execution-packet.tsv`
   and companion `member-discussions.tsv` rows. This tranche documents future
   command templates, Totoro/FIIA and DRAC host packet boundaries, the planned
   `n = 5` seed manifest, artifact and checksum requirements, retained-
   denominator rules, approval-token requirements, and unchanged support-cell
   status boundary. It is still a disabled packet, not a runner file, not a
   host command, not a host result, and not execution permission: every row
   keeps `runner_status = not_written_packet_only`,
   `disabled_by_default`, `packet_banked_not_executed`,
   `no_compute_in_tranche61`, `coverage_not_authorized`, and
   `do_not_promote`. Totoro/FIIA remains only a future primary host after
   review; DRAC remains only a fallback after separate run-root/source-checkout
   review; host denominators must not pool. No runner file, host command,
   Totoro/FIIA command, DRAC command, local debug run, new denominator, top-up,
   coverage result, support-cell status movement, `interval_status`,
   `coverage_status`, `inference_ready`, `supported`, q1 `sigma`, matched
   `mu+sigma`, q2, q4/q8, non-Gaussian interval, REML, AI-REML, bridge, or
   public-support claim moves. The next gate is Rose/Fisher/Noether/Grace
   review plus checkpoint before at most a Tranche 62 spatial-only runner or
   dispatch gate with execution disabled by default.
21al. Banked in the Tranche 62 q1 `mu` one-slope spatial-only dry-run runner
   gate slice: add
   `structured-re-gaussian-mu-slope-tranche62-spatial-runner-gate.tsv`, the
   dry-run-only runner
   `tools/run-gaussian-mu-slope-tranche62-spatial-host-smoke.R`, and companion
   `member-discussions.tsv` rows. This tranche validates the future runner
   shape only: spatial provider, direct-SD q1 `mu` intercept and slope targets,
   fixed `n = 5` seed manifest `861001`-`861005`, stdout TSV manifest, and
   execute-path refusal. It is not a host command, not a host result, not a
   denominator, not coverage evidence, and not execution permission: every row
   keeps `runner_mode = dry_run_only`, `disabled_by_default`,
   `dry_run_validated_not_executed`,
   `execute_path_refuses_in_tranche62`, `no_compute_in_tranche62`,
   `coverage_not_authorized`, and `do_not_promote`. No fit, host command,
   Totoro/FIIA command, DRAC command, local-debug denominator, dashboard-result
   write, top-up, coverage result, support-cell status movement,
   `interval_status`, `coverage_status`, `inference_ready`, `supported`, q1
   `sigma`, matched `mu+sigma`, q2, q4/q8, non-Gaussian interval, REML,
   AI-REML, bridge, or public-support claim moves. The next gate is
   Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche 63
   host preflight or dispatch approval; no host command, top-up, denominator
   claim, coverage, or support-cell status edit is allowed before that gate.
21am. Banked in the Tranche 63 q1 `mu` one-slope spatial-only host-preflight
   slice: add
   `structured-re-gaussian-mu-slope-tranche63-spatial-host-preflight.tsv` and
   companion `member-discussions.tsv` rows. This tranche reviews the T62
   runner gate and approves only the future host-packet boundary: any later
   packet must carry source SHA, run root, host label, output path,
   sessionInfo, and host-separated denominator policy. T63 does not run a
   host command, submit Totoro/FIIA or DRAC work, fit a model, create a new
   denominator, authorize top-up, or move support-cell status. Every row keeps
   `preflight_approved_no_host_command`,
   `local_source_snapshot_recorded_no_remote_checkout_claim`,
   `run_root_required_not_created_in_tranche63`,
   `command_packet_approved_not_executed`, `no_compute_in_tranche63`,
   `coverage_not_authorized`, and `do_not_promote`. The next gate is
   Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche 64
   host command packet or host dry-run dispatch approval; no fit, top-up,
   denominator claim, coverage, or support-cell status edit is allowed before
   that gate.
21an. Banked in the Tranche 64 q1 `mu` one-slope spatial-only command-packet
   slice: add
   `structured-re-gaussian-mu-slope-tranche64-spatial-command-packet.tsv` and
   companion `member-discussions.tsv` rows. This tranche turns the T63
   host-preflight boundary into packet text only: command templates,
   source-SHA requirements, run-root placeholders, host-label requirements,
   output manifest/stderr/sessionInfo paths, and host-separated denominator
   policy are recorded for review. T64 does not run a host command, submit
   Totoro/FIIA or DRAC work, fit a model, create a new denominator, authorize
   top-up, or move support-cell status. Every row keeps
   `host_command_packet`, `packet_banked_not_executed`,
   `no_compute_in_tranche64`, `coverage_not_authorized`, and
   `do_not_promote`. The next gate is Rose/Fisher/Noether/Grace review plus
   checkpoint before at most a Tranche 65 host dry-run dispatch or
   source/run-root reachability probe; no fit, top-up, denominator claim,
   coverage, or support-cell status edit is allowed before that gate.
21ao. Banked in the Tranche 65 q1 `mu` one-slope spatial-only host-dispatch
   gate slice: add
   `structured-re-gaussian-mu-slope-tranche65-spatial-host-dispatch-gate.tsv`
   and companion `member-discussions.tsv` rows. This tranche turns the T64
   command packet into a reviewed dispatch/reachability-probe gate only:
   source SHA, run root, host label, output path, sessionInfo, dry-run
   dispatch, and host-separated denominator requirements are recorded for the
   next probe. T65 does not run a host command, run a reachability command,
   verify a source checkout, create a run root, submit Totoro/FIIA or DRAC
   work, fit a model, create a new denominator, authorize top-up, or move
   support-cell status. Every row keeps `not_executed_in_tranche65`,
   `dry_run_dispatch_planned_not_executed`, `fit_execution_refused`,
   `no_compute_in_tranche65`, `coverage_not_authorized`, and
   `do_not_promote`. The next gate is Rose/Fisher/Noether/Grace review plus
   checkpoint before at most a Tranche 66 host reachability/source-run-root
   dry-run probe; no fit, top-up, denominator claim, coverage, or support-cell
   status edit is allowed before that gate.
21ap. Banked in the Tranche 66 q1 `mu` one-slope spatial-only host
   reachability/source-run-root probe slice: add
   `structured-re-gaussian-mu-slope-tranche66-spatial-host-reachability-probe.tsv`
   and companion `member-discussions.tsv` rows. This tranche records only
   safe read-only host facts after the T65 dispatch gate: plain Totoro SSH
   auth failed, the existing Totoro ControlMaster socket reached
   `totoro.biology.ualberta.ca`, the qseries run root and candidate source
   paths existed, candidate source paths did not prove a current source
   checkout because git resolved to `/home/snakagaw` with no usable HEAD,
   Rscript reported 4.5.3, the FIIA alias was unresolved, and DRAC was
   deferred for separate review. T66 does not run a model command, run a
   smoke, fit a model, create a new denominator, authorize top-up, record a
   coverage result, prove source checkout, claim run-root readiness, or move
   support-cell status. Every row keeps
   `host_probe_only_no_model_compute_in_tranche66`,
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is
   Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche
   67 Totoro source-snapshot and qseries run-root staging contract; no fit,
   top-up, denominator claim, coverage, or support-cell status edit is allowed
   before that gate.
21aq. Banked in the Tranche 67 q1 `mu` one-slope spatial-only Totoro
   source-snapshot and qseries run-root staging contract slice: add
   `structured-re-gaussian-mu-slope-tranche67-spatial-source-staging-contract.tsv`
   and companion `member-discussions.tsv` rows. This tranche records only
   future staging requirements after the T66 reachability probe: local source
   SHA `56add7f04fab7bec57a42e56eaeb090dff491863`, dirty-state manifest
   requirement, future Totoro source-snapshot path, future qseries run-root
   path, stdout/stderr/manifest/sessionInfo paths, single-thread caps,
   host-label policy, and host-separated denominator policy. T67 does not run
   a host command, copy source, create a run root, run a model command, run a
   smoke, fit a model, create a new denominator, authorize top-up, record a
   coverage result, prove source checkout, claim run-root readiness, or move
   support-cell status. Every row keeps
   `staging_contract_only_no_host_command_in_tranche67`,
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is
   Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche
   68 Totoro source-snapshot and qseries run-root staging dry-run proof; no
   model command, fit, top-up, denominator claim, coverage, or support-cell
   status edit is allowed before that gate.
21ar. Banked in the Tranche 68 q1 `mu` one-slope spatial-only Totoro
   source-snapshot and qseries run-root staging proof slice: add
   `structured-re-gaussian-mu-slope-tranche68-spatial-source-staging-proof.tsv`,
   companion `member-discussions.tsv` rows, and imported proof artifacts under
   `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche68-spatial-source-staging-totoro/`.
   This tranche turns the T67 contract into host-labeled staging proof only:
   source SHA `56add7f04fab7bec57a42e56eaeb090dff491863` with dirty source
   state was staged to the Totoro snapshot path, the qseries run root was
   created, `SOURCE-MANIFEST` recorded 6,207 files, source/host/session
   provenance was imported, and a no-model-command proof was banked. T68 runs
   no model command, smoke, fit, top-up, coverage grid, or
   denominator-creating replicate, and it moves no support-cell status. Every
   row keeps `source_runroot_staging_proof_only_no_model_compute_in_tranche68`,
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is
   Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche
   69 spatial-only n=5 host-smoke execution decision from the exact T68
   snapshot and run root; no fit command, top-up, denominator claim, coverage,
   or support-cell status edit is allowed before explicit approval.
21as. Banked in the Tranche 69 q1 `mu` one-slope spatial-only host-smoke
   execution-readiness decision slice: add
   `structured-re-gaussian-mu-slope-tranche69-spatial-host-smoke-execution-decision.tsv`,
   companion `member-discussions.tsv` rows, and local refusal-proof artifacts
   under
   `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche69-spatial-execution-readiness-local/`.
   This tranche accepts the exact T68 Totoro snapshot and run root as the only
   future provenance path, but blocks execution because the current T62 runner
   is dry-run-only and refuses `--execution-approved=true`. T69 runs no model
   command, smoke, fit, top-up, coverage grid, or denominator-creating
   replicate, and it moves no support-cell status. Every row keeps
   `do_not_execute_existing_t62_runner_write_t70_executable_runner_contract`,
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is a Tranche 70
   executable-runner contract or fail-closed runner patch from the exact T68
   snapshot and run root; no Totoro command, denominator claim, coverage, or
   support-cell status edit is allowed before Rose/Fisher/Noether/Grace and
   validator review.
21at. Banked in the Tranche 70 q1 `mu` one-slope spatial-only fail-closed
   executable-runner contract slice: add
   `structured-re-gaussian-mu-slope-tranche70-spatial-runner-contract.tsv`,
   `tools/run-gaussian-mu-slope-tranche70-spatial-host-smoke.R`,
   `tools/run-gaussian-mu-slope-tranche70-spatial-host-smoke.sh`, companion
   `member-discussions.tsv` rows, and local runner-contract artifacts under
   `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche70-spatial-runner-contract-local/`.
   This tranche turns the T69 execution-readiness decision into a banked
   executable-runner contract only: dry-run emits a 10-row manifest, execute
   mode refuses without
   `DRMTMB_Q1MU_SLOPE_T70_EXECUTION_APPROVED=rose_fisher_noether_grace`, the
   shell wrapper refuses without the same token, future execution must load
   model code from the exact T68 Totoro snapshot and write artifacts under the
   exact T68 qseries run root, and `write-dashboard=false` is mandatory. T70
   runs no Totoro command, model command, smoke, fit, top-up, coverage grid, or
   denominator-creating replicate, and it moves no support-cell status. Every
   row keeps `fail_closed_executable_runner_contract_banked_no_execution`,
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is
   Rose/Fisher/Noether/Grace plus validator review and checkpoint before at
   most one Tranche 71 Totoro n5 command through the T70 wrapper; no
   denominator claim, coverage, inference-ready claim, supported claim, public
   support, or support-cell status edit is allowed before that review.
21au. Banked in the Tranche 71 q1 `mu` one-slope spatial-only Totoro
   load-blocker review slice: add
   `structured-re-gaussian-mu-slope-tranche71-spatial-host-smoke-load-blocker.tsv`,
   companion `member-discussions.tsv` rows, and imported Totoro artifacts under
   `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche71-spatial-host-smoke-totoro/`.
   This tranche records exactly one T70-wrapper Totoro command attempt using
   the exact T68 source snapshot and qseries run root. The command exited 1
   because `devtools::load_all()` failed before any fit with an invalid ELF
   header for `drmTMB.so`; the 10 result rows are planned seed-target manifest
   rows, not attempted replicates. T71 records no pdHess, Wald interval,
   profile interval, coverage, retained denominator, top-up, or support-cell
   status evidence, and it moves no support-cell status. Every row keeps
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is a Tranche 72
   load-blocker review/fix contract that inspects the exact T68 source snapshot
   compiled-object state and runner transport before any rerun; no denominator
   claim, coverage, inference-ready claim, supported claim, public support, or
   support-cell status edit is allowed before Rose/Fisher/Gauss/Noether/Grace
   plus validator review and checkpoint.
21av. Banked in the Tranche 72 q1 `mu` one-slope spatial-only load-route
   review slice: add
   `structured-re-gaussian-mu-slope-tranche72-spatial-load-route-review.tsv`,
   companion `member-discussions.tsv` rows, and metadata-only Totoro audit
   artifacts under
   `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche72-spatial-load-route-review-totoro/`.
   This tranche explains the T71 invalid-ELF blocker without running another
   fit. The exact T68 source snapshot contains macOS arm64 Mach-O compiled
   objects at `src/drmTMB.so`, `src/drmTMB.o`, and `src/init.o` on Totoro
   Linux; the T70 runner payloads are present with hashes, but AppleDouble
   `._*` transport noise is also present. T72 records no R load, model command,
   fit attempt, pdHess, Wald interval, profile interval, coverage, retained
   denominator, top-up, or support-cell status evidence, and it moves no
   support-cell status. Every row keeps `coverage_not_authorized`,
   `do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate
   is a Tranche 73 clean-source restaging contract/proof before any rerun:
   exclude or remove compiled artifacts, prevent AppleDouble/extended-header
   transport noise, keep host-separated provenance, and require
   Rose/Fisher/Gauss/Noether/Grace plus validator review and checkpoint.
21aw. Banked in the Tranche 73 q1 `mu` one-slope spatial-only clean-source
   restaging proof slice: add
   `structured-re-gaussian-mu-slope-tranche73-spatial-clean-source-restaging-proof.tsv`,
   companion `member-discussions.tsv` rows, and imported Totoro proof artifacts
   under
   `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche73-spatial-clean-source-restaging-totoro/`.
   This tranche spends no model compute. It stages a new Totoro source snapshot
   and qseries run root from source SHA
   `56add7f04fab7bec57a42e56eaeb090dff491863`, records 16,889 manifest rows,
   SOURCE-MANIFEST hash
   `b4a9c159bca67ed748c4004d0aa6385eb701f28aa38c623d696feacaf75fe52c`,
   SOURCE-PROVENANCE hash
   `7350b797aeddfb31fe0b9c0e9216625be9d233805375a289b72c6c832a78bd21`,
   `compiled_artifact_count=0`, and `appledouble_count=0`. T73 records no R
   package load, `devtools::load_all()`, model command, fit attempt, pdHess,
   Wald interval, profile interval, retained denominator, coverage, top-up, or
   support-cell status evidence, and it moves no support-cell status. Every row
   keeps `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is a Tranche 74
   runner-path update or reviewed rerun gate before any smoke, because the
   existing T70 wrapper still refuses source/run-root paths other than the exact
   T68 paths.
21ax. Banked in the Tranche 74 q1 `mu` one-slope spatial-only runner-path gate:
   add
   `structured-re-gaussian-mu-slope-tranche74-spatial-runner-path-gate.tsv`,
   companion `member-discussions.tsv` rows, local dry-run/refusal artifacts
   under
   `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche74-spatial-runner-path-gate-local/`,
   and the fail-closed T74 R runner plus shell wrapper. This tranche updates
   the exact source/run-root contract from the T68 paths to the T73
   clean-source snapshot and qseries run root. It emits a dry-run manifest for
   the 10 planned seed-target rows only, proves direct execute and wrapper
   refusal without
   `DRMTMB_Q1MU_SLOPE_T74_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace`,
   and records hashes for the runner, wrapper, manifest, and refusal stderr
   files. T74 records no R package load, `devtools::load_all()`, model command,
   fit attempt, pdHess, Wald interval, profile interval, retained denominator,
   coverage, top-up, or support-cell status evidence, and it moves no
   support-cell status. Every row keeps `coverage_not_authorized`,
   `do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate
   is Tranche 75: at most one Totoro n=5 smoke through the T74 wrapper, only
   after Rose/Fisher/Gauss/Noether/Grace plus validator review and checkpoint.
21ay. Banked in the Tranche 75 q1 `mu` one-slope spatial-only Totoro
   host-smoke terminal review: add
   `structured-re-gaussian-mu-slope-tranche75-spatial-host-smoke-terminal-review.tsv`,
   companion SC415 `member-discussions.tsv` rows, and imported Totoro artifacts
   under
   `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche75-spatial-host-smoke-totoro/`.
   Exactly one T74-wrapper Totoro n=5 command was dispatched against the exact
   T73 clean-source snapshot and qseries run root. The remote runner loaded the
   source snapshot and wrote results, summary, run-log, host-provenance, and
   hash artifacts, but all 10 target rows failed before fitting because
   `phase18_assert_one_row_data_frame` was not available to the sourced runner
   environment. T75 records 0 fit_ok, 0 `pdHess`, 0 finite intervals, no
   admission pass, no retained denominator, no coverage result, and no
   support-cell status edit. Every row keeps `coverage_not_authorized`,
   `do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate
   is Tranche 76: source-map/runner-source review of why
   `inst/sim/R/sim_runner.R` was not sourced, before any rerun.
21az. Banked in the Tranche 76 q1 `mu` one-slope spatial-only runner-source
   map review: add
   `structured-re-gaussian-mu-slope-tranche76-spatial-runner-source-map-review.tsv`
   and companion SC416 `member-discussions.tsv` rows. This no-compute review
   confirms that `phase18_assert_one_row_data_frame` exists in
   `inst/sim/R/sim_runner.R`, while the T74 runner source list loaded
   registry/utils/spatial DGP/summarise/run files without sourcing
   `inst/sim/R/sim_runner.R`. T76 records no model command, fit attempt,
   `pdHess`, Wald/profile interval evidence, retained denominator, admission
   pass, coverage result, top-up authorization, or support-cell status edit.
   Every row keeps `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 77: write a
   reviewed fail-closed runner-source patch gate that sources
   `inst/sim/R/sim_runner.R` before dependent spatial DGP/run files, preserves
   exact T73 paths and T75 provenance, and stops for
   Rose/Fisher/Gauss/Noether/Grace plus validator review and checkpoint before
   any rerun.
21ba. Banked in the Tranche 77 q1 `mu` one-slope spatial-only runner-source
   patch gate: add
   `structured-re-gaussian-mu-slope-tranche77-spatial-runner-source-patch-gate.tsv`
   and companion SC417 `member-discussions.tsv` rows. T77 banks the new runner
   and shell wrapper for the exact T73 Totoro clean-source snapshot and qseries
   run root, sources `inst/sim/R/sim_runner.R` before dependent spatial DGP/run
   files, emits only a 10-row dry-run manifest, and records direct-execute and
   wrapper refusal probes behind
   `DRMTMB_Q1MU_SLOPE_T77_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace`.
   T77 records no R package load, no `devtools::load_all()`, no model command,
   no fit attempt, no `pdHess`, no Wald/profile interval evidence, no retained
   denominator, no admission pass, no coverage result, no top-up authorization,
   and no support-cell status edit. Every row keeps `coverage_not_authorized`,
   `do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is
   Tranche 78: write a reviewed smoke-approval gate for at most one Totoro
   `n = 5` smoke through the T77 wrapper, after
   Rose/Fisher/Gauss/Noether/Grace plus validator review and checkpoint.
21bb. Banked in the Tranche 78 q1 `mu` one-slope spatial-only smoke-approval
   gate: add
   `structured-re-gaussian-mu-slope-tranche78-spatial-smoke-approval-gate.tsv`
   and companion SC418 `member-discussions.tsv` rows. T78 imports the T77
   fail-closed runner-source patch gate, names the exact T73 source snapshot
   and qseries run root, preserves the T75 provenance boundary, fixes the T78
   host label and seeds, and authorizes at most one future Totoro `n = 5`
   smoke through the T77 wrapper after this sidecar validates and a recovery
   checkpoint is written. T78 itself records no host command, R package load,
   `devtools::load_all()`, model command, fit attempt, `pdHess`,
   Wald/profile interval evidence, retained denominator, admission pass,
   coverage result, top-up authorization, or support-cell status edit. Every
   row keeps `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 79: dispatch
   exactly one Totoro `n = 5` smoke through the T77 wrapper, or write a
   separate DRAC source-checkout/run-root fallback gate before any DRAC
   command.
21bc. Banked in the Tranche 79 q1 `mu` one-slope spatial-only Totoro auth
   blocker: add
   `structured-re-gaussian-mu-slope-tranche79-spatial-totoro-auth-blocker.tsv`
   and companion SC419 `member-discussions.tsv` rows. The authorized T79
   Totoro route returned SSH exit 255 with
   `Permission denied (publickey,password)` before a remote shell was reached,
   so the T77 wrapper did not dispatch and no source checkout proof, run-root
   proof, R package load, `devtools::load_all()`, model command, fit attempt,
   `pdHess`, Wald/profile interval evidence, retained denominator, admission
   pass, coverage result, top-up authorization, or support-cell status edit
   exists. Every row keeps `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 80: write a
   separate DRAC source-checkout/run-root fallback gate before any DRAC
   command, or restore Totoro auth and write a fresh Totoro reachability gate
   before another Totoro smoke attempt.
21bd. Banked in the Tranche 80 q1 `mu` one-slope spatial-only DRAC fallback
   gate: add
   `structured-re-gaussian-mu-slope-tranche80-spatial-drac-fallback-gate.tsv`
   and companion SC420 `member-discussions.tsv` rows. The gate fixes Rorqual
   as the candidate DRAC route and records the required source checkout path,
   run root, output path, host label, module/R/TMB provenance, copied T77
   runner/wrapper hashes, approval token, `write-dashboard=false`, and
   host-separated denominator policy. T80 runs no DRAC command and records no
   source checkout proof, run-root proof, package load, `devtools::load_all()`,
   model command, fit attempt, `pdHess`, Wald/profile interval evidence,
   retained denominator, admission pass, coverage result, top-up authorization,
   or support-cell status edit. Every row keeps `coverage_not_authorized`,
   `do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate
   is Tranche 81: only a no-model DRAC Rorqual reachability/source-checkout/
   run-root proof after T80 validates and checkpoints; any DRAC smoke needs a
   later smoke-approval gate.
21be. Banked in the Tranche 81 q1 `mu` one-slope spatial-only DRAC Rorqual
   provenance proof: add
   `structured-re-gaussian-mu-slope-tranche81-spatial-drac-rorqual-provenance-proof.tsv`
   and companion SC421 `member-discussions.tsv` rows. BatchMode SSH reached
   `rorqual2` as `snakagaw` with exit code 0, but the required source checkout
   path, run root, output directory, copied T77 runner, and copied T77 wrapper
   are missing. T81 records no module load, R package load,
   `devtools::load_all()`, model command, fit attempt, `pdHess`, Wald/profile
   interval evidence, retained denominator, admission pass, coverage result,
   top-up authorization, or support-cell status edit. Every row keeps
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 82: write a
   DRAC Rorqual source/run-root staging contract before any source copy,
   run-root creation, or smoke command.
21bf. Banked in the Tranche 82 q1 `mu` one-slope spatial-only DRAC Rorqual
   staging contract: add
   `structured-re-gaussian-mu-slope-tranche82-spatial-drac-staging-contract.tsv`
   and companion SC422 `member-discussions.tsv` rows. The contract imports the
   T81 proof that Rorqual is reachable but staging is missing, fixes source SHA
   `56add7f04fab7bec57a42e56eaeb090dff491863`, the required source checkout,
   run-root, and T83 output paths, the T77 runner/wrapper hashes, the DRAC
   host label, `write-dashboard=false`, and the host-separated denominator
   policy. T82 runs no source copy, `mkdir`, remote command, module load, R
   package load, `devtools::load_all()`, model command, fit attempt, `pdHess`,
   Wald/profile interval evidence, retained denominator, admission pass,
   coverage result, top-up authorization, or support-cell status edit. Every
   row keeps `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 83 only: a
   DRAC Rorqual mkdir/source-copy staging proof that records host provenance,
   source manifest, source provenance, remote runner/wrapper hashes, and
   no-model-command proof, then stops before any smoke, module load, R command,
   fit, retained denominator, coverage, or status movement.
21bg. Banked in the Tranche 83 q1 `mu` one-slope spatial-only DRAC Rorqual
   staging proof: add
   `structured-re-gaussian-mu-slope-tranche83-spatial-drac-staging-proof.tsv`
   and companion SC423 `member-discussions.tsv` rows. BatchMode SSH reached
   `rorqual2` as `snakagaw`; `rsync` copied the source snapshot for SHA
   `56add7f04fab7bec57a42e56eaeb090dff491863` to the required `/project`
   source checkout, created or confirmed the run root and output directory,
   imported a 16,986-entry `SOURCE-MANIFEST`, recorded source provenance, host
   provenance, remote T77 runner/wrapper hashes, and no-model-command proof.
   T83 runs no module load, R command, `Rscript`, `devtools::load_all()`,
   smoke command, model fit, `pdHess`, Wald/profile interval evidence,
   retained denominator, admission pass, coverage result, top-up
   authorization, or support-cell status edit. Every row keeps
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 84 only: a
   post-staging smoke-approval gate, not smoke execution.
21bh. Banked in the Tranche 84 q1 `mu` one-slope spatial-only DRAC
   smoke-approval review: add
   `structured-re-gaussian-mu-slope-tranche84-spatial-drac-smoke-approval-gate.tsv`
   and companion SC424 `member-discussions.tsv` rows. The review accepts the
   T83 Rorqual staging proof as source/run-root/provenance evidence, but
   withholds DRAC smoke authorization because the current T77 runner and
   wrapper still require the exact T73 Totoro source and run-root paths and
   refuse the T83 DRAC paths. T84 runs no host command, module load, R command,
   `Rscript`, `devtools::load_all()`, smoke command, model fit, `pdHess`,
   Wald/profile interval evidence, retained denominator, admission pass,
   coverage result, top-up authorization, or support-cell status edit. Every
   row keeps `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 85 only: a
   fail-closed DRAC runner-path patch gate that proves dry-run/refusal behavior
   before any later smoke-approval gate can authorize execution.
21bi. Banked in the Tranche 85 q1 `mu` one-slope spatial-only DRAC
   runner-path patch gate: add
   `structured-re-gaussian-mu-slope-tranche85-spatial-drac-runner-path-gate.tsv`,
   companion SC425 `member-discussions.tsv` rows, and
   `tools/run-gaussian-mu-slope-tranche85-spatial-drac-host-smoke.R` plus
   `.sh`. The T85 runner and wrapper accept the exact T83 DRAC source path and
   run root, preserve the T77 helper-source order with
   `inst/sim/R/sim_runner.R` before dependent spatial helper files, keep the
   DRAC Rorqual host label, fixed seeds `861001`-`861005`, preserved approval
   token, `write-dashboard=false`, and host-separated denominator policy. The
   local proof is shell-only: manifest mode emits 10 seed-target rows, execute
   mode refuses before `Rscript` without the preserved approval token, and
   hashes plus a no-Rscript proof are banked. T85 runs no SSH, DRAC command,
   module load, R command, `Rscript`, `devtools::load_all()`, smoke command,
   model fit, `pdHess`, Wald/profile interval evidence, retained denominator,
   admission pass, coverage result, top-up authorization, or support-cell
   status edit. Every row keeps `coverage_not_authorized`, `do_not_promote`,
   and `unchanged_point_fit_planned_planned`. The next gate is Tranche 86 only:
   a post-patch DRAC smoke-approval review that may authorize at most one
   future host-separated n5 smoke through the T85 wrapper or keep the route
   held.
21bj. Banked in the Tranche 86 q1 `mu` one-slope spatial-only DRAC
   smoke-approval gate: add
   `structured-re-gaussian-mu-slope-tranche86-spatial-drac-smoke-approval-gate.tsv`
   and companion SC426 `member-discussions.tsv` rows. The gate reviews the T85
   runner/wrapper hashes, shell manifest proof, execute-refusal proof,
   no-Rscript proof, exact T83 DRAC source and run-root paths, helper-source
   order, host label, fixed seeds, approval token, `write-dashboard=false`, and
   host-separated denominator policy. T86 authorizes at most one future DRAC
   Rorqual n5 smoke through the T85 wrapper after validator, after-task,
   served-widget probe, and checkpoint pass; it does not execute that smoke.
   T86 runs no SSH, DRAC command, module load, R command, `Rscript`,
   `devtools::load_all()`, smoke command, model fit, `pdHess`, Wald/profile
   interval evidence, retained denominator, admission pass, coverage result,
   top-up authorization, or support-cell status edit. Every row keeps
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 87 only: a
   single-command DRAC Rorqual n5 smoke execution/terminal-review tranche that
   imports host-separated evidence and stops before coverage or status movement.
21bk. Banked in the Tranche 87 q1 `mu` one-slope spatial-only DRAC
   SLURM-packet blocker: add
   `structured-re-gaussian-mu-slope-tranche87-spatial-drac-slurm-packet.tsv`
   and companion SC427 `member-discussions.tsv` rows. The review converts the
   T86 future-smoke approval into a login-node-safe packet before any compute:
   Rorqual is reachable through ControlMaster and the exact T83 source/run-root
   paths exist, but the remote T85 runner and wrapper are missing. The local
   sbatch packet refuses outside a Rorqual SLURM job, checks the exact
   runner/wrapper hashes, preserves the T77 approval token, and writes only
   packet/provenance evidence. T87 runs no `sbatch`, remote copy, module load,
   R command, `Rscript`, `devtools::load_all()`, smoke command, model fit,
   `pdHess`, Wald/profile interval evidence, retained denominator, admission
   pass, coverage result, top-up authorization, or support-cell status edit.
   Every row keeps `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 88 only: a
   remote staging proof for the exact T85 runner, T85 wrapper, and T87 sbatch
   packet, with remote hashes and a manifest-only no-R proof before any later
   sbatch submission is considered.
21bl. Banked in the Tranche 88 q1 `mu` one-slope spatial-only DRAC remote
   staging proof: add
   `structured-re-gaussian-mu-slope-tranche88-spatial-drac-remote-staging-proof.tsv`
   and companion SC428 `member-discussions.tsv` rows. T88 stages the exact T85
   runner, T85 wrapper, and T87 sbatch packet on Rorqual under the exact T83
   source/run-root paths, verifies remote SHA-256 hashes, chmods wrapper and
   sbatch packets, runs shell syntax checks, and runs wrapper manifest mode
   only. The manifest has 10 planned seed-target rows and is not a fit
   denominator. T88 submits no `sbatch`, loads no module, runs no R command,
   runs no `Rscript`, fits no model, records no `pdHess`, Wald/profile interval
   evidence, retained denominator, admission pass, coverage result, top-up
   authorization, or support-cell status edit. Every row keeps
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 89 only: a
   separate Rose/Fisher/Gauss/Noether/Grace-reviewed Rorqual sbatch submission
   and terminal-review tranche after checkpoint.
21bm. Banked in the Tranche 89 q1 `mu` one-slope spatial-only DRAC sbatch
   terminal review: add
   `structured-re-gaussian-mu-slope-tranche89-spatial-drac-sbatch-terminal-review.tsv`
   and companion SC429 `member-discussions.tsv` rows. T89 submits exactly one
   Rorqual job, `15084376`, through the staged packet and imports terminal
   Slurm/provenance artifacts. The job reaches node `rc31728` and fails before
   model fitting because the runner path guard sees the existing run root
   normalized under `/lustre09/project/6098264/...` while the not-yet-created
   output directory remains under `/project/def-snakagaw/...`. No result
   directory is created. T89 is failure-taxonomy evidence only: it records no
   retained denominator, `pdHess`, Wald/profile interval evidence, admission
   pass, coverage result, top-up authorization, or support-cell status edit.
   Every row keeps `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 90 only: a
   no-compute path-alignment patch/review gate before any repeat sbatch.
21bn. Banked in the Tranche 90 q1 `mu` one-slope spatial-only DRAC
   path-alignment patch review: add
   `structured-re-gaussian-mu-slope-tranche90-spatial-drac-path-alignment-patch-review.tsv`
   and companion SC430 `member-discussions.tsv` rows. T90 patches the local T85
   R runner so missing output paths are normalized through their nearest
   existing parent before comparison with the exact T83 DRAC run root. It also
   refreshes the local T87 sbatch packet's expected runner hash to the patched
   runner, while leaving the shell wrapper's raw exact-run-root prefix guard in
   place. T90 is no-compute packet evidence only: it runs local R parse, shell
   syntax, wrapper manifest, and execute-refusal checks, but no SSH, remote
   copy, `sbatch`, module load, R package load, `devtools::load_all()`, smoke
   command, model fit, retained denominator, admission pass, coverage result,
   top-up authorization, or support-cell status edit. Every row keeps
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 91 only: a
   no-compute remote restaging proof for the patched T85 runner and T87 sbatch
   packet before any repeat sbatch is considered.
21bo. Banked in the Tranche 91 q1 `mu` one-slope spatial-only DRAC remote
   restaging proof: add
   `structured-re-gaussian-mu-slope-tranche91-spatial-drac-remote-restaging-proof.tsv`
   and companion SC431 `member-discussions.tsv` rows. T91 restages the
   T90-patched T85 R runner, unchanged shell wrapper, and refreshed T87 sbatch
   packet on Rorqual, then records remote hashes, executable bits, remote bash
   syntax checks, and wrapper manifest-only no-R proof. The remote runner hash
   is `6a4fa7e8c77d20172929368ce17852073439c69400ea8221255f08b51dd3411e`,
   the wrapper hash is
   `b18885eaca8501e996d56ea8a2e7082c53b862b350ed7aacca6778973e4017ad`,
   and both source-tree and run-root sbatch hashes are
   `bc8709d528248caa91af5b281c09c61d6f05d3a53052b39427c1c40bee3dd1a8`.
   T91 is no-compute remote provenance evidence only: it runs no `sbatch`, no
   module load, no R command, no `Rscript`, no package load, no smoke command,
   no model fit, no retained denominator, no admission pass, no coverage
   result, no top-up authorization, and no support-cell status edit. Every row
   keeps `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 92 only: a
   separate sbatch authorization gate after checkpoint before any repeat Rorqual
   job is considered.
21bp. Banked in the Tranche 92 q1 `mu` one-slope spatial-only DRAC sbatch
   authorization gate: add
   `structured-re-gaussian-mu-slope-tranche92-spatial-drac-sbatch-authorization-gate.tsv`
   and companion SC432 `member-discussions.tsv` rows. T92 reviews the T91
   remote restaging proof, the exact runner hash
   `6a4fa7e8c77d20172929368ce17852073439c69400ea8221255f08b51dd3411e`,
   wrapper hash
   `b18885eaca8501e996d56ea8a2e7082c53b862b350ed7aacca6778973e4017ad`,
   and source/run-root sbatch hash
   `bc8709d528248caa91af5b281c09c61d6f05d3a53052b39427c1c40bee3dd1a8`,
   plus the T91 manifest-only no-R proof. T92 is no-compute authorization
   evidence only: it authorizes at most one future Rorqual sbatch after
   checkpoint, but submits no `sbatch`, loads no module, runs no R command or
   `Rscript`, fits no model, creates no retained denominator, passes no
   admission or coverage gate, and edits no support-cell status. Every row keeps
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 93 only: a
   single Rorqual sbatch submission and terminal-review tranche using the
   T91-restaged packet, with no coverage, top-up, support-cell status,
   `inference_ready`, `supported`, public support, REML, AI-REML, or denominator
   pooling claim.
21bq. Banked in the Tranche 93 q1 `mu` one-slope spatial-only DRAC sbatch
   terminal review: add
   `structured-re-gaussian-mu-slope-tranche93-spatial-drac-sbatch-terminal-review.tsv`
   and companion SC433 `member-discussions.tsv` rows. T93 submitted exactly one
   Rorqual sbatch job, `15087685`, through the T91-restaged run-root packet. The
   job reached node `rc32114` and failed with Slurm state `FAILED`, exit code
   `1:0`, and elapsed time `00:00:13`. The failure happened before package load
   and before model fit: `wrapper.stderr` says `drmTMB` could not be loaded from
   the exact T83 DRAC source path, and the run log records
   `devtools_load_all_failed` because the Tranche 85 runner requires `devtools`
   for `load_all()`. The 10 emitted result rows are manifest rows only, not fit
   rows; T93 creates zero retained denominator, no admission pass, no coverage
   result, no top-up authorization, and no support-cell status edit. Every row
   keeps `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 94 only: a
   no-compute dependency/load-route review before any repeat sbatch.
21br. Banked in the Tranche 94 q1 `mu` one-slope spatial-only DRAC
   dependency/load-route review: add
   `structured-re-gaussian-mu-slope-tranche94-spatial-drac-dependency-load-route-review.tsv`,
   a compact T94 dependency review artifact, and companion SC434
   `member-discussions.tsv` rows. T94 imports the T93 job `15087685` terminal
   evidence, runner source route, wrapper stderr, remote-metadata tarball
   `sessionInfo.txt`, manifest rows, and run log. It records the current
   blocker as a dependency/load route: the T85 runner requires
   `devtools::load_all()` from the exact T83 DRAC source path, while the T93 R
   session shows R 4.4.0 on AlmaLinux 9.8 with only base packages and
   `compiler` loaded. T94 runs no ssh, `sbatch`, module load, R command,
   `Rscript`, package load, `load_all()`, or model fit. Every row keeps
   `no_new_denominator`, `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`; the support cell remains
   `point_fit/planned/planned`. The next gate is Tranche 95 only: a no-compute
   dependency-staging/load-route contract before any repeat Rorqual sbatch or
   model command.
21bs. Banked in the Tranche 95 q1 `mu` one-slope spatial-only DRAC
   dependency-staging contract: add
   `structured-re-gaussian-mu-slope-tranche95-spatial-drac-dependency-staging-contract.tsv`,
   a compact T95 route-contract artifact, and companion SC435
   `member-discussions.tsv` rows. T95 rejects broad `devtools` staging for this
   tranche because `DESCRIPTION` does not declare it and the route would add a
   development stack before the smallest load proof. T95 selects a base-R
   staged-library `R CMD INSTALL` plus `library(drmTMB)` route for the future
   T96 no-model proof, while holding `pkgload` and manual-source fallbacks
   until that proof or explicit review needs them. T95 runs no ssh, `sbatch`,
   module load, R command, `Rscript`, package install, package load,
   `devtools::load_all()`, `pkgload::load_all()`, or model fit. Every row keeps
   `no_new_denominator`, `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`; the support cell remains
   `point_fit/planned/planned`. The next gate is Tranche 96 only: a
   no-model/no-sbatch dependency proof of the base-R staged-library route
   before any repeat Rorqual sbatch or model command.
21bt. Banked in the Tranche 96 q1 `mu` one-slope spatial-only DRAC dependency
   proof: add
   `structured-re-gaussian-mu-slope-tranche96-spatial-drac-dependency-proof.tsv`,
   a compact T96 terminal-review artifact, and companion SC436
   `member-discussions.tsv` rows. T96 reached Rorqual as `snakagaw`, loaded
   `StdEnv/2023`, `gcc/12.3`, and `r/4.4.0`, confirmed the exact T83 source
   and run root exist, and attempted only a base-R `R CMD INSTALL` into a
   run-local library. The proof failed closed because `cli`, `TMB`, and
   `RcppEigen` were missing; `library(drmTMB)` was not attempted after the
   install failure. T96 runs no `sbatch`, smoke runner, simulation, model
   formula, or model fit. Every row keeps `no_new_denominator`,
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`; the support cell remains
   `point_fit/planned/planned`. The next gate is Tranche 97 only: a
   no-model/no-sbatch dependency-install/staging contract for `cli`, `TMB`,
   and `RcppEigen`, or an existing DRAC module/library route, before any
   repeat Rorqual sbatch or model command.
21bu. Banked in the Tranche 97 q1 `mu` one-slope spatial-only DRAC
   dependency-install staging contract: add
   `structured-re-gaussian-mu-slope-tranche97-spatial-drac-dependency-install-staging-contract.tsv`,
   a compact T97 staging-contract artifact, and companion SC437
   `member-discussions.tsv` rows. T97 imports the T96 missing-dependency
   blocker, limits the dependency scope to `cli`, `TMB`, and `RcppEigen`, and
   selects a T98-only proof route: probe default/project libraries first, then
   install exactly `cli`, `RcppEigen`, and `TMB` into `Rlib-tranche98` only if
   the host policy is login-node safe. T97 runs no ssh, remote command, module
   load, R command, `Rscript`, package install, package load, `R CMD INSTALL`,
   `library(drmTMB)`, `sbatch`, smoke runner, simulation, model formula, or
   model fit. Every row keeps `no_new_denominator`,
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`; the support cell remains
   `point_fit/planned/planned`. The next gate is Tranche 98 only: a
   no-model/no-sbatch dependency-install proof that either proves the
   run-local dependency route and package load or stops with an allocation
   contract.
21bv. Banked in the Tranche 98 q1 `mu` one-slope spatial-only DRAC
   dependency-install proof: add
   `structured-re-gaussian-mu-slope-tranche98-spatial-drac-dependency-install-proof.tsv`,
   fetched Rorqual probe artifacts, a compact T98 terminal-review artifact, and
   companion SC438 `member-discussions.tsv` rows. T98 reached Rorqual as
   `snakagaw`, loaded `StdEnv/2023`, `gcc/12.3`, and `r/4.4.0`, probed
   `.libPaths()` and package availability, and confirmed the exact T83 source
   and run root exist. The probe found only the R 4.4.0 module library and
   confirmed `cli`, `TMB`, and `RcppEigen` are missing. T98 stops before package
   install, `R CMD INSTALL`, `library(drmTMB)`, `sbatch`, smoke runner,
   simulation, model formula, or model fit because login-node compilation is not
   policy-safe. Every row keeps `no_new_denominator`,
   `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`; the support cell remains
   `point_fit/planned/planned`. The next gate is Tranche 99 only: an
   allocation-safe no-model dependency install/load proof through `sbatch` or
   `salloc`, still before any repeat model job, coverage, top-up, or status
   movement.
21bw. Banked in the Tranche 99 q1 `mu` one-slope spatial-only DRAC allocation
   install/load proof: add
   `structured-re-gaussian-mu-slope-tranche99-spatial-drac-allocation-install-load-proof.tsv`,
   fetched Rorqual Slurm artifacts, a compact T99 terminal-review artifact, and
   companion SC439 `member-discussions.tsv` rows. T99 submitted one allocation
   job (`15094722`), which allocated on `rc32431` and failed before module load
   because sourcing the DRAC CVMFS profile under `set -u` hit unset
   `SKIP_CC_CVMFS`. No Rscript, package install, `R CMD INSTALL`,
   `library(drmTMB)`, smoke runner, simulation, model formula, or model fit
   ran. The support cell remains `point_fit/planned/planned`; every row keeps
   `no_new_denominator`, `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 100 only: a
   no-compute shell-profile guard/packet review before any repeat allocation.
21bx. Banked in the Tranche 100 q1 `mu` one-slope spatial-only DRAC
   shell-profile guard packet review: add
   `structured-re-gaussian-mu-slope-tranche100-spatial-drac-shell-profile-guard-packet-review.tsv`,
   the T101 candidate packet, failed/candidate packet hashes, a `bash -n`
   syntax artifact, a local guard patch diff, a compact T100 review artifact,
   and companion SC440 `member-discussions.tsv` rows. T100 is no-compute: no
   ssh, remote copy, `sbatch`, `salloc`, module load, Rscript, package install,
   `R CMD INSTALL`, `library(drmTMB)`, smoke runner, simulation, model formula,
   or model fit ran. The T101 candidate packet defines `SKIP_CC_CVMFS` before
   sourcing the DRAC CVMFS profile and moves `set -u` after profile source. The
   support cell remains `point_fit/planned/planned`; every row keeps
   `no_new_denominator`, `coverage_not_authorized`, `do_not_promote`, and
   `unchanged_point_fit_planned_planned`. The next gate is Tranche 101 only:
   checkpoint first, then at most one allocation-safe no-model dependency
   install/load proof with the T100 candidate packet.
22. Banked in this stacked follow-up slice: add native R/TMB K/Q same-target
   parity for the exact relmat q4 location one-slope `mu1+mu2` cell. This
   moves only the native Q evidence boundary from `planned_not_banked` to
   runtime parity; Q precision payload marshalling, direct DRM.jl Q export,
   R-via-Julia Q transport, broad bridge support, interval reliability,
   coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML,
   non-Gaussian REML, public support, and broader q8 support remain separate
   gates.
23. Banked in this stacked follow-up slice: add the generated six-row native
   R/TMB relmat K/Q same-target parity ledger for exact one-slope cells. This
   consolidates q1 `mu`, q1 `sigma`, matched q1 `mu+sigma`, q2 `mu1+mu2`
   slope-only, q4 location one-slope, and q8-shaped all-four one-slope runtime
   evidence without moving relmat Q bridge marshalling, direct DRM.jl Q export,
   R-via-Julia Q transport, intervals, coverage, REML, AI-REML, public support,
   or broader q8 support.
23a. Banked in this stacked follow-up slice: add the reviewed relmat `Q`
   payload contract for those same six exact cells. This fixes payload id,
   matrix digest, precision-source, level-alignment, missing-level, coefficient
   order, provenance, and no-implicit-conversion policies before runtime bridge
   work. It does not implement relmat Q payload transport, direct DRM.jl Q
   export, R-via-Julia Q transport, broad bridge support, intervals, coverage,
   REML, AI-REML, public support, or broader q8 support.
23b. Banked in this stacked follow-up slice: add the relmat `Q` DRM.jl
   provider-readiness snapshot. It records DRM.jl #299, DRM.jl #300, and the
   R-side transport gate as three dependency rows, keeping the draft-green q2
   known-precision upstream evidence separate from exact drmTMB relmat `Q`
   payload transport. This does not implement relmat Q bridge support,
   direct DRM.jl Q export from drmTMB, R-via-Julia Q transport, intervals,
   coverage, REML, AI-REML, public support, or broader q8 support.
23c. Banked in this stacked follow-up slice: add the relmat `Q` DRM.jl stack
   review ledger. It records exact-head review evidence for DRM.jl #297, #298,
   #299, and #300, plus the drmTMB #666 readiness decision. This makes the next
   merge/retarget order explicit while keeping exact `Q` transport blocked
   until the upstream stack is accepted and the R payload contract is matched
   in code. This does not implement relmat Q bridge support, direct DRM.jl Q
   export from drmTMB, R-via-Julia Q transport, intervals, coverage, REML,
   AI-REML, public support, or broader q8 support.
24. Banked in this stacked follow-up slice: add the eight-row ordinary count
   one-slope fixture/recovery contract for Poisson and NB2 `mu` cells across
   `phylo()`, fixed-covariance `spatial()`, `animal()`, and `relmat()`. This
   names the exact same-target fixture and calibrated recovery gates after
   existing native TMB ML/Laplace point-fit and extractor evidence; bridge
   parity, calibrated recovery, broad bridge support, intervals, coverage,
   q2/q4 count covariance, REML, AI-REML, public support, labelled or multiple
   count slopes, structured count scale routes, and zero-inflated structure
   remain unpromoted.
25. Banked in this stacked follow-up slice: add the eight-row native-only
   deterministic fixture-status sidecar for those same ordinary count
   one-slope cells. This moves only the native fixture status to
   `native_fixture_banked`; it does not move bridge parity, calibrated
   recovery, intervals, coverage, q2/q4 count covariance, REML, AI-REML,
   public support, labelled or multiple count slopes, structured count scale
   routes, or zero-inflated structure.
26. Banked in this stacked follow-up slice: add the eight-row dry-run recovery
   runner contract plus selected manifest and run log for the ordinary
   Poisson/NB2 q1 structured `mu` one-slope cells. This names the provider and
   family shards, fixed seed range, recovery targets, retention policy, and
   Totoro/DRAC review gate, but no recovery simulation has been executed and no
   coverage-evaluable denominator, interval reliability, coverage, bridge
   parity, REML, AI-REML, q2/q4 count covariance, or public support has moved.
27. Banked in this stacked follow-up slice: add the eight-row recovery
   dispatch preflight for those count one-slope runner rows. This records
   provider/family shard scope, output namespaces, no-overwrite rules, seed
   partition locking, resume policy, retained failure accounting, and the
   Totoro/DRAC human-review gate; it is not human approval, no job is
   submitted, and no recovery, coverage, interval, bridge, REML, AI-REML,
   q2/q4 count covariance, public support, or broad bridge support status
   moves.
28. Banked in this stacked follow-up slice: add the count one-slope recovery
    shard-pack contract. This turns the dispatch preflight into concrete
    provider/family manifest and run-log filenames, one per shard, with private
   write paths and append-only resume expectations. It is still dry-run
   evidence only: no human execution approval has been recorded, no Totoro or
    DRAC job has been submitted, and no recovery, denominator, coverage,
    interval, bridge, REML, AI-REML, q2/q4 count covariance, public support, or
    broad bridge status moves.
29. Banked in this stacked follow-up slice: extend the PR stack merge-readiness
    ledger from PR #655 through PR #663 after verifying green three-platform
    R-CMD-check runs for PR #656, #657, #658, #659, #660, #661, #662, and
    #663. This is stack-control evidence only; no PR is undrafted or merged, no Totoro or
    DRAC job is submitted, and no recovery, denominator, coverage, interval,
    bridge, REML, AI-REML, public-support, or SR150 status moves.
30. Banked in this stacked follow-up slice: execute the first local
    micro-shard for the ordinary count one-slope recovery lane:
    `phylo(1 + x | species, tree = tree)` in `mu` with `poisson()`, four seeds,
    four converged point fits, and four `pdHess = TRUE` rows. This is local
    diagnostic smoke evidence only. It does not move denominator, coverage,
    interval, bridge, REML, AI-REML, public-support, Totoro/DRAC, q2/q4 count
    covariance, NB2, spatial, animal, relmat, structured count scale, labelled
    slope, or multiple-slope status.
31. Banked in this stacked follow-up slice: execute the exact NB2 sibling local
    micro-shard for `phylo(1 + x | species, tree = tree)` in `mu` with
    `nbinom2()`, fixed-effect `sigma`, four seeds, four converged point fits,
    and four `pdHess = TRUE` rows. This is local diagnostic smoke evidence
    only. It does not move denominator, coverage, interval, bridge, REML,
    AI-REML, public-support, Totoro/DRAC, q2/q4 count covariance, structured
    count scale, zero-inflated structure, spatial, animal, relmat, labelled
    slope, or multiple-slope status.
32. Banked in this stacked follow-up slice: execute the exact
    fixed-covariance spatial Poisson local micro-shard for
    `spatial(1 + x | site, coords = coords)` in `mu`, four seeds, four
    converged point fits, and four `pdHess = TRUE` rows. This is local
    diagnostic smoke evidence only. It does not move denominator, coverage,
    interval, bridge, REML, AI-REML, public-support, Totoro/DRAC,
    range-estimating spatial support, q2/q4 count covariance, structured
    count scale, zero-inflated structure, phylo, NB2, animal, relmat,
    labelled slope, or multiple-slope status.
33. Banked in this stacked follow-up slice: execute the exact
    fixed-covariance spatial NB2 local micro-shard for
    `spatial(1 + x | site, coords = coords)` in `mu`, fixed-effect `sigma`,
    four seeds, four converged point fits, and four `pdHess = TRUE` rows. This
    is local diagnostic smoke evidence only. It does not move denominator,
    coverage, interval, bridge, REML, AI-REML, public-support, Totoro/DRAC,
    range-estimating spatial support, q2/q4 count covariance, structured count
    scale, zero-inflated structure, phylo, Poisson, animal, relmat, labelled
    slope, or multiple-slope status.
34. Banked in this stacked follow-up slice: execute the exact animal A/Ainv
    Poisson local micro-shard for `animal(1 + x | id, Ainv = Q)` in `mu`, four
    seeds, four converged point fits, and four `pdHess = TRUE` rows. This is
    local diagnostic smoke evidence only. It does not move denominator,
    coverage, interval, bridge, pedigree/Ainv bridge marshalling, REML,
    AI-REML, public-support, Totoro/DRAC, q2/q4 count covariance, structured
    count scale, zero-inflated structure, phylo, spatial, NB2, relmat,
    labelled slope, or multiple-slope status.
35. Banked in this stacked follow-up slice: execute the exact animal A/Ainv
    NB2 local micro-shard for `animal(1 + x | id, Ainv = Q)` in `mu`,
    fixed-effect `sigma`, four seeds, four converged point fits, and four
    `pdHess = TRUE` rows. This is local diagnostic smoke evidence only. It
    does not move denominator, coverage, interval, bridge, pedigree/Ainv bridge
    marshalling, REML, AI-REML, public-support, Totoro/DRAC, q2/q4 count
    covariance, structured count scale, zero-inflated structure, phylo,
    spatial, Poisson, relmat, labelled slope, or multiple-slope status.
36. Banked in this stacked follow-up slice: execute the exact relmat K/Q
    Poisson local micro-shard for `relmat(1 + x | id, Q = Q)` in `mu`, four
    seeds, four converged point fits, and four `pdHess = TRUE` rows. This is
    local diagnostic smoke evidence only. It does not move denominator,
    coverage, interval, bridge, Q bridge marshalling, REML, AI-REML,
    public-support, Totoro/DRAC, q2/q4 count covariance, structured count
    scale, zero-inflated structure, phylo, spatial, animal, NB2, labelled
    slope, or multiple-slope status.
37. Banked in this stacked follow-up slice: execute the exact relmat K/Q NB2
    local micro-shard for `relmat(1 + x | id, Q = Q)` in `mu`, fixed-effect
    `sigma`, four seeds, four converged point fits, and four
    `pdHess = TRUE` rows. This is local diagnostic smoke evidence only. It
    does not move denominator, coverage, interval, bridge, Q bridge
    marshalling, REML, AI-REML, public-support, Totoro/DRAC, q2/q4 count
    covariance, structured count scale, zero-inflated structure, phylo,
    spatial, animal, Poisson, labelled slope, or multiple-slope status.
38. Banked in this slice: record the count NB2 `sigma` one-slope
    structured-scale rejection contract for `phylo()`, fixed-covariance
    `spatial()`, A-matrix `animal()`, and K/Q `relmat()`. The engine rejects
    structured count scale routes at the pre-optimization formula gate
    (`Structured non-Gaussian paths`), so the
    `qseries_*_nbinom2_q1_sigma_one_slope_rejected` cells stay `unsupported`.
    This answers the half-cell question directly: banked count `mu` one-slope
    coverage does not imply count `sigma` one-slope support, and Poisson has no
    `sigma` parameter, so it has no structured count scale cell. It does not
    promote parser-ready, point-fit, bridge, interval, coverage, REML, AI-REML,
    public-support, structured count sigma, or q4/q8 status.
39. Banked in this slice: record the non-Gaussian structured-family rejection
    contract that documented structured-effect routes the engine rejected
    across non-Gaussian families and endpoints. Later slices moved beta animal
    `mu`, Gamma relmat `mu`, Student spatial `mu`, beta animal `sigma`,
    Student phylo `nu`, Poisson spatial `zi`, and NB2 `sigma` one-slope rows
    into local fit-only recovery. The active rejection contract now contains
    only cumulative-logit phylo `mu` and truncated-NB2 relmat `hu` rows; those
    rows remain rejection evidence only and do not promote parser-ready,
    point-fit, bridge, interval, coverage, REML, AI-REML, public-support, or
    q4/q8 status.
40. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 101 allocation/install-load terminal review. One Rorqual `sbatch`
    job (`15097440`) allocated on `rc32607` and completed with `0:0`, but
    `R` and `Rscript` were command-not-found after module load, and the packet
    status file drifted by recording install/load passes despite
    command-not-found stderr. This is terminal-review evidence only. It is not
    dependency-install success evidence, not package-load success evidence, not
    fit evidence, and not retained-denominator evidence. It does not move
    denominator, interval, coverage, support-cell, public-support, REML, or
    AI-REML status. The next gate is Tranche 102 only: checkpoint first, then a
    no-compute packet/module-executable status guard review that checks
    `command -v R` and `command -v Rscript` after module load and makes status
    writes reflect real command exits before any repeat allocation.
41. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 102 packet/module-executable status guard review. This is a local
    no-compute review: no `ssh`, remote copy, `sbatch`, `salloc`, module load,
    R command, Rscript, package install, `R CMD INSTALL`, `library(drmTMB)`,
    smoke runner, simulation, model formula, or model fit ran. The T103
    candidate packet records `command -v R` and `command -v Rscript` after
    module load, module list/availability, executable paths, and status writes
    from real command exits; it exits fail-closed if either executable is
    missing. T102 is not dependency-install success evidence, not package-load
    success evidence, not fit evidence, and not retained-denominator evidence.
    It does not move denominator, interval, coverage, support-cell,
    public-support, REML, or AI-REML status. The next gate is Tranche 103 only:
    checkpoint first, then at most one allocation-safe no-model Rorqual
    dependency install/load proof with the T102 candidate packet.
42. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 103 allocation/install-load terminal review. One Rorqual `sbatch`
    job (`15102377`) allocated on `rc32422` and failed closed with `127:0`.
    Module load exited 0, but `command -v R` and `command -v Rscript` both
    exited 1, so package install, `R CMD INSTALL`, `library(drmTMB)`, smoke
    runner, model formula, model fit, retained denominator, coverage, top-up,
    and support-cell status movement did not occur. This is terminal-review
    evidence only. It is not dependency-install success evidence, not
    package-load success evidence, not fit evidence, and not
    retained-denominator evidence. It does not move denominator, interval,
    coverage, support-cell, public-support, REML, or AI-REML status. The next
    gate is Tranche 104 only: checkpoint first, then a no-compute
    module-route/executable resolution review from T103 artifacts before any
    repeat allocation.
43. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 104 module-route/executable resolution review. This is local
    no-compute review only: no `ssh`, `sbatch`, `salloc`, module load, R
    command, Rscript, package install, `R CMD INSTALL`, `library(drmTMB)`,
    smoke runner, model formula, or model fit ran. T104 reviews the T103
    artifacts and records the failure taxonomy as module-resolution ambiguity:
    the T103 module load exited 0, the loaded module list lacked `r/4.4.0`,
    `module avail r` listed `r/4.4.0`, and both executable probes remained
    `NA`. It is not dependency-install success evidence, not package-load
    success evidence, not fit evidence, and not retained-denominator evidence.
    It does not move denominator, interval, coverage, support-cell,
    public-support, REML, or AI-REML status. The next gate is Tranche 105
    only: checkpoint first, then a no-compute module-route packet
    patch/contract before any repeat allocation.
44. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 105 module-route packet contract. This is still local no-compute:
    no `ssh`, `sbatch`, `salloc`, module load, R command, Rscript, package
    install, `R CMD INSTALL`, `library(drmTMB)`, smoke runner, model formula,
    model fit, retained denominator, coverage, top-up, or support-cell status
    edit ran. T105 encodes the reviewed T104 route so a future packet must
    load `StdEnv/2023` then `r/4.4.0`, record the loaded modules, require
    `r/4.4.0` in that loaded-module list, require `command -v R` and `command
    -v Rscript` before package install, and fail closed before install/load/
    model if either guard fails. It is not dependency-install success
    evidence, not package-load success evidence, not fit evidence, and not
    retained-denominator evidence. It does not move denominator, interval,
    coverage, support-cell, public-support, REML, or AI-REML status. The next
    gate is Tranche 106 only: checkpoint first, then at most one allocation-safe
    no-model Rorqual module-route/install-load proof if Rose, Fisher, Gauss,
    Noether, and Grace approve.
45. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 106 module-route/install-load submission-pending state. T106 used
    the T105 packet and submitted exactly one allocation-safe no-model Rorqual
    `sbatch` job (`15103184`) after checkpoint. Remote preflight passed, the
    packet hash matched, and remote `bash -n` passed, but the job was still
    `PENDING` with scheduler reason `Priority` at the time of the T106
    submission-pending sidecar. T106 pending rows are not terminal proof, not
    module-load success, not R/Rscript success, not dependency-install success,
    not package-load success, not fit evidence, and not retained-denominator
    evidence. They do not move denominator, interval, coverage, support-cell,
    public-support, REML, or AI-REML status.
46. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 107 terminal review for the same job. Job `15103184` allocated on
    `rc32522` and failed `127:0` after `00:00:02`. The module-load command
    exited 0, but the loaded-module guard failed because
    `module-list-after-r-load.txt` did not contain `r/4.4.0` and instead
    reported no loaded modules matching `-t`. No R/Rscript probe, package
    install, `R CMD INSTALL`, `library(drmTMB)`, smoke runner, model formula,
    model fit, retained denominator, coverage, top-up, or support-cell status
    edit occurred. T107 is terminal failure evidence only; it is not loaded
    `r/4.4.0` proof, not dependency-install success evidence, not package-load
    success evidence, not fit evidence, and not retained-denominator evidence.
    The next gate is Tranche 108 only: a no-compute module-list syntax/route
    review from the T107 artifacts before any repeat allocation.
47. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 108 module-list syntax/route review. T108 runs no new host command,
    `sbatch`, `salloc`, module load, R command, Rscript, package install,
    `R CMD INSTALL`, `library(drmTMB)`, smoke runner, model formula, model fit,
    retained denominator, coverage, top-up, or support-cell status edit. It
    reviews only the T107 artifacts and classifies the immediate failure as a
    module-list syntax/route issue: `module list -t` was interpreted as
    matching `-t`, while existing Slurm packets use plain `module list`
    capture. T108 is not module-load success, not R/Rscript proof, not
    dependency-install success evidence, not package-load success evidence, not
    fit evidence, not retained-denominator evidence, not admission evidence,
    and not coverage evidence. The next gate is Tranche 109 only: a no-compute
    packet patch/contract that replaces `module list -t` with plain
    `module list` capture, requires `r/4.4.0` in that captured list before
    `command -v R` and `command -v Rscript`, and fails closed before
    install/load/model.
48. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 109 module-list packet contract. T109 is local no-compute packet
    work only: no new host command, `sbatch`, `salloc`, module load, R command,
    Rscript, package install, `R CMD INSTALL`, `library(drmTMB)`, smoke runner,
    model formula, model fit, retained denominator, coverage, top-up, or
    support-cell status edit ran. The contract replaces `module list -t` with
    plain `module list` capture, records the raw loaded-module list, requires
    `r/4.4.0` in that captured list before `command -v R` and `command -v
    Rscript`, and fails closed before install/load/model if either guard fails.
    T109 is not module-load success, not R/Rscript proof, not dependency-install
    success evidence, not package-load success evidence, not fit evidence, not
    retained-denominator evidence, not admission evidence, and not coverage
    evidence. The next gate is Tranche 110 only: checkpoint first, then at most
    one allocation-safe no-model Rorqual module-list/executable proof from this
    T109 contract if Rose, Fisher, Gauss, Noether, and Grace approve.
49. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 110 module-list/executable terminal proof. T110 submitted one
    Rorqual Slurm job (`15104831`), allocated `rc32601`, completed with exit
    `0:0`, proved the raw plain module list contains `r/4.4.0`, proved
    `command -v R` and `command -v Rscript` resolve to R 4.4.0 CVMFS paths,
    and stopped before package install, `R CMD INSTALL`, `library(drmTMB)`,
    smoke runner, model formula, model fit, retained denominator, coverage,
    top-up, or support-cell status edit. T110 is not dependency-install
    success, not package-load success, not fit evidence, not admission evidence,
    and not coverage evidence. The next gate is Tranche 111 only: no-compute
    terminal decision review from existing T110 artifacts before any
    package-install/load proof is considered.
50. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 111 package-load decision review. T111 runs no host command and
    reviews only existing T110 artifacts: job `15104831`, allocation host
    `rc32601`, Slurm exit `0:0`, raw `module list` containing `r/4.4.0`, and
    `R`/`Rscript` resolving to R 4.4.0 CVMFS paths. T111 is not
    package-install success, not `R CMD INSTALL` success, not package-load
    success, not fit evidence, not retained-denominator evidence, not admission
    evidence, and not coverage evidence. The next gate is Tranche 112 only:
    checkpoint first, then at most one allocation-safe no-model Rorqual
    package-install/load proof.
51. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 112 package-install/load terminal review. T112 submitted one
    allocation-safe no-model Rorqual job, `15105466`, on `rc32301`; the
    `r/4.4.0` module guard and `R`/`Rscript` executable guard passed, then
    dependency installation failed before `R CMD INSTALL` because the allocation
    could not access the CRAN `PACKAGES` index and the installer error branch
    called `conditionMessage()` on a logical value. T112 is not package-install
    success, not package-load success, not fit evidence, not retained-denominator
    evidence, not admission evidence, and not coverage evidence. The next gate is
    Tranche 113 only: no-compute dependency/provenance review before any repeat
    allocation, model command, coverage, top-up, or status edit.
52. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 113 dependency/provenance review. T113 runs no host command and
    reviews only existing T112 artifacts. It classifies the T112 allocation as a
    dependency-route hold because CRAN `PACKAGES` was unreachable, an
    installer-status hold because the error branch called `conditionMessage()`
    on a logical value, a dependency-library hold because `Rlib-tranche112` plus
    `Rlib-tranche98` did not make `cli` available, and a source-provenance hold
    because host provenance reported `source_sha` as `NA`. T113 is not
    package-install success, not package-load success, not fit evidence, not
    retained-denominator evidence, not admission evidence, and not coverage
    evidence. The next gate is Tranche 114 only: no-compute dependency-route
    packet/contract before any repeat allocation, model command, coverage,
    top-up, or status edit.
53. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 114 dependency-route packet contract. T114 runs no host command and
    writes only local contract artifacts: a patched installer-status script, an
    offline/pre-staged dependency-source route, a source-SHA contract for
    `56add7f04fab7bec57a42e56eaeb090dff491863`, a terminal-status contract, and
    an unsubmitted candidate T115 sbatch packet. T114 is not package-install
    success, not package-load success, not fit evidence, not
    retained-denominator evidence, not admission evidence, and not coverage
    evidence. The next gate is Tranche 115 only: checkpoint first, then at most
    one allocation-safe no-model Rorqual dependency-route proof if
    Rose/Fisher/Gauss/Noether/Grace approve.
54. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 115 dependency-route submission-pending snapshot. T115 staged a
    file-backed dependency repository, source-SHA provenance for
    `56add7f04fab7bec57a42e56eaeb090dff491863`, the patched installer script,
    and exactly one Rorqual sbatch job (`15106737`). At capture time the job was
    pending, so T115 is not package-install success, not package-load success,
    not fit evidence, not retained-denominator evidence, not admission evidence,
    and not coverage evidence.
55. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 116 dependency-route terminal review. Existing job `15106737`
    completed on allocation host `rc32501` with exit `0:0`, loaded `r/4.4.0`,
    matched the required source SHA, and made `cli`, `Matrix`, `RcppEigen`, and
    `TMB` available through the staged dependency route. T116 deliberately
    stops before `R CMD INSTALL`, `library(drmTMB)`, any smoke runner, model
    formula, model fit, retained denominator, coverage, top-up, or support-cell
    status edit. The next gate is Tranche 117 only: no-compute
    package-install/load route packet review before any further allocation.
56. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 117 package-install/load packet review. T117 runs no host command
    and writes only local packet artifacts: source-SHA and library-path
    contracts, a fail-closed R install/load script contract, an unsubmitted
    candidate T118 sbatch packet, a terminal-status contract, and a local hash
    manifest. T117 imports the T116 dependency-route success for `cli`,
    `Matrix`, `RcppEigen`, and `TMB`, but it is not package-install success, not
    `R CMD INSTALL` success, not `library(drmTMB)` success, not fit evidence,
    not retained-denominator evidence, not admission evidence, and not coverage
    evidence. The next gate is Tranche 118 only: checkpoint first, then at most
    one allocation-safe no-model Rorqual package-install/load proof if
    Rose/Fisher/Gauss/Noether/Grace approve.
57. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 118 package-install/load terminal review. T118 submitted exactly
    one allocation-safe no-model Rorqual job (`15108138`) from `rorqual2`; the
    job allocated on `rc32123` and failed with exit `128:0` after five seconds
    at the source-SHA guard because the packet used `git rev-parse` inside a
    staged source snapshot that is not a git checkout. T118 failed before
    `R CMD INSTALL`, `library(drmTMB)`, any smoke runner, model formula, model
    fit, retained denominator, coverage, top-up, or support-cell status edit.
    It is not package-install success, not package-load success, not fit
    evidence, not retained-denominator evidence, not admission evidence, and
    not coverage evidence. The next gate is Tranche 119 only: a no-compute
    source-provenance fallback packet review that reads `SOURCE-PROVENANCE.tsv`
    when git metadata are absent, before any repeat allocation.
58. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 119 source-provenance fallback packet review. T119 runs no host
    command and submits no job. It reviews a future T120 candidate packet that
    tries git provenance first, falls back to `SOURCE-PROVENANCE.tsv`
    `source_sha_full` when git metadata are absent, writes
    `t120-terminal-status.tsv` before source-SHA guard exits, preserves source
    SHA `56add7f04fab7bec57a42e56eaeb090dff491863`, and keeps the T116
    file-backed dependency route plus `Rlib-tranche115/Rlib-tranche98`
    evidence. T119 is not package-install success, not package-load success,
    not fit evidence, not retained-denominator evidence, not admission
    evidence, and not coverage evidence. The next gate is Tranche 120 only:
    checkpoint first, then at most one allocation-safe no-model Rorqual
    package-install/load proof if Rose/Fisher/Gauss/Noether/Grace approve.
59. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 120 package-install/load terminal review. T120 submitted exactly
    one allocation-safe no-model Rorqual job (`15109947`) from `rorqual2`; the
    job allocated on `rc32218` and completed with exit `0:0` after `00:09:17`.
    The packet matched source SHA `56add7f04fab7bec57a42e56eaeb090dff491863`
    through `SOURCE-PROVENANCE.tsv`, passed the dependency probe, passed
    `R CMD INSTALL`, loaded `drmTMB` 0.1.4, then wrote the model boundary
    `no_smoke_runner_no_formula_no_fit_no_denominator_no_coverage`. T120 is
    package-install/load readiness evidence only: it is not fit evidence, not
    retained-denominator evidence, not admission evidence, not coverage
    evidence, not `inference_ready`, not `supported`, and not public support.
    The q1 `mu` one-slope spatial support cell remains
    `point_fit/planned/planned`. The next gate is Tranche 121 only: a
    no-compute model-smoke readiness and admission-boundary review before any
    smoke runner or denominator.
60. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 121 model-smoke readiness review. T121 runs no host command and
    submits no job. It reviews fetched T120 install/load artifacts only and
    records that they can support a future fail-closed T122 packet/contract, not
    a model result. T121 is not fit evidence, not retained-denominator evidence,
    not admission evidence, not coverage evidence, not `inference_ready`, not
    `supported`, and not public support. The q1 `mu` one-slope spatial support
    cell remains `point_fit/planned/planned`. The next gate is Tranche 122 only:
    a no-compute fail-closed model-smoke packet/contract before any smoke runner,
    model formula, model fit, denominator, coverage, top-up, or status edit.
61. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 122 model-smoke packet contract. T122 runs no host command and
    submits no job. It writes the fail-closed contract from T120 install/load
    artifacts and the T121 review, locks source SHA
    `56add7f04fab7bec57a42e56eaeb090dff491863`, T120 job `15109947` on
    `rc32218`, the packet hash, SOURCE-PROVENANCE hash, terminal-status hash,
    direct-SD target identity `sd_mu_intercept;sd_mu_x`, and the future stop
    rules. T122 is not fit evidence, not retained-denominator evidence, not
    admission evidence, not coverage evidence, not `inference_ready`, not
    `supported`, and not public support. The q1 `mu` one-slope spatial support
    cell remains `point_fit/planned/planned`. The next gate is Tranche 123 only:
    a no-compute execution-approval/checkpoint review before any `sbatch`, host
    command, smoke runner, model formula, model fit, denominator, coverage,
    top-up, or status edit.
62. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 123 model-smoke execution-approval checkpoint. T123 runs no host
    command and submits no job. It reviews the T122 packet, T120 source SHA
    `56add7f04fab7bec57a42e56eaeb090dff491863`, T120 job `15109947` on
    `rc32218`, direct-SD target identity `sd_mu_intercept;sd_mu_x`, and
    host-separated denominator policy, then authorizes at most one future
    host-separated DRAC Rorqual `n = 5` model-smoke execution in Tranche 124
    after checkpoint. T123 is not fit evidence, not retained-denominator
    evidence, not admission evidence, not coverage evidence, not
    `inference_ready`, not `supported`, and not public support. The q1 `mu`
    one-slope spatial support cell remains `point_fit/planned/planned`.
63. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 124 model-smoke execution terminal review. T124 submitted exactly
    one Rorqual job, `15112750`, on `rc31704`. The source SHA
    `56add7f04fab7bec57a42e56eaeb090dff491863` and `library(drmTMB)` guards
    passed, but `devtools_available = FALSE` stopped the job before the runner,
    model formula, model fit, `pdHess`, Wald interval, profile interval, output
    rows, retained denominator, admission pass, coverage result, top-up, or
    support-cell status movement. T124 is not fit evidence, not
    retained-denominator evidence, not admission evidence, not coverage evidence,
    not `inference_ready`, not `supported`, and not public support. The q1 `mu`
    one-slope spatial support cell remains `point_fit/planned/planned`. The next
    gate is Tranche 125 only: a no-compute dependency-route review before any
    repeat execution.
64. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 125 dependency-route review. T125 imports the T124 failure taxonomy,
    rejects broad `devtools` prestaging as the first repeat route, and selects
    the narrower internal `--load-source=false` runner path so a future packet
    can use the installed `drmTMB` route that T124 proved before the `devtools`
    stop. T125 runs no SSH command, remote copy, `sbatch`, allocation, module
    load, model formula, model fit, `pdHess`, Wald interval, profile interval,
    output rows, retained denominator, admission pass, coverage result, top-up,
    or support-cell status movement. T125 is not fit evidence, not
    retained-denominator evidence, not admission evidence, not coverage evidence,
    not `inference_ready`, not `supported`, and not public support. The q1 `mu`
    one-slope spatial support cell remains `point_fit/planned/planned`. The next
    gate is Tranche 126 only: a no-compute patched-runner packet checkpoint
    before any repeat host-separated Rorqual execution.
65. Banked in this slice: record the q1 `mu` one-slope spatial-only DRAC
    Tranche 126 patched-runner packet checkpoint. T126 freezes the T85 runner
    hash `84a335abddbd04f74c30daeb448af37e8d713471f71b2656c2ab41c4e85558b9`,
    wrapper hash
    `ea63c6fe0a4423296f48f2a11ec75232ce2e3ff37eb0b52bc3f48db5287bc5a2`,
    source SHA `56add7f04fab7bec57a42e56eaeb090dff491863`, host label
    `drac_rorqual_q1mu_slope_spatial_t120_t122_packet_n5`,
    `--load-source=false`, the installed-package `library(drmTMB)` route, a
    local dry-run hash, and a future T127 sbatch packet hash. T126 runs no SSH
    command, remote copy, `sbatch`, allocation, module load, package install,
    smoke runner, model formula, model fit, `pdHess`, Wald interval, profile
    interval, output rows, retained denominator, admission pass, coverage
    result, top-up, or support-cell status movement. T126 is not fit evidence,
    not retained-denominator evidence, not admission evidence, not coverage
    evidence, not `inference_ready`, not `supported`, and not public support.
    The q1 `mu` one-slope spatial support cell remains
    `point_fit/planned/planned`. The next gate is Tranche 127 only: at most one
    host-separated Rorqual model-smoke execution after checkpoint and
    Rose/Fisher/Gauss/Noether/Grace approval.
66. Banked in this slice: record the q2 spatial Tranche 128 replacement-rule
    route design. Because Tranche 127 remains compute-gated, T128 moves a
    separate q2 row-blocker lane without running compute: it reviews the
    spatial/animal q2 row-gate synthesis, SR1000 bias+t endpoint blockers, and
    local g=32 profile/Wald smoke, then selects only a future spatial-first
    g=32 retained-denominator profile/Wald/bias+t comparison contract for
    Tranche 129. Animal fixed-8 q2 remains held on a separate calibration route
    and does not inherit spatial g=32 evidence. T128 runs no SSH command, remote
    copy, `sbatch`, allocation, module load, R runner, model formula, model fit,
    `pdHess`, Wald interval, profile interval, output rows, retained
    denominator, admission pass, coverage result, top-up, or support-cell status
    movement. It is not fit evidence, not retained-denominator evidence, not
    admission evidence, not coverage evidence, not `inference_ready`, not
    `supported`, and not public support. The spatial and animal q2 one-slope
    support cells remain `point_fit/planned/planned`. The next gate is Tranche
    129 only: write a fail-closed spatial-only g=32 `n = 20` executable-contract
    ledger, checkpoint it, and require Rose/Fisher/Gauss/Noether/Grace approval
    before any command.
67. Banked in this slice: record the q2 spatial Tranche 129 g=32 executable
    contract. T129 writes the exact future command, source SHA
    `56add7f04fab7bec57a42e56eaeb090dff491863`, runner hash, wrapper hash,
    three spatial targets, shard-specific seed ranges, artifact roots, host
    label requirement, and fail-closed stop rules for a possible later
    `n = 20` profile/Wald versus existing bias+t comparison. It does not execute
    the command, contact Totoro or DRAC, run a model, create a retained
    denominator, admit the spatial q2 row, authorize a coverage grid, top up any
    provider, edit support-cell status, or claim `inference_ready`, `supported`,
    REML, AI-REML, q4/q8, bridge support, or public support. The next compute
    move, if still desired, is a separate checkpointed T130
    execution-approval/terminal-review gate with Rose/Fisher/Gauss/Noether/Grace
    blocking approval.
68. Banked in this slice: record the v1.0 readiness reset. The reset keeps the
    current Mission Control invariants at 104 Q-Series cells, 67 Gaussian rows,
    37 non-Gaussian rows, eight exact `inference_ready` rows, and zero
    structured `supported` rows, but changes the campaign priority: v1.0 can
    focus on honest implemented/basic-working Gaussian routes and basic
    distribution recovery while full `inference_ready` and `supported`
    validation continues after v1.0. This reset does not lower the support bar,
    authorize coverage, promote neighbouring rows, create REML or AI-REML
    wording, or turn recovery-only non-Gaussian rows into interval evidence. It
    also adds `tools/qseries-tranche-scaffold.py` as the first speedup for future
    no-compute tranche drafting.
69. Banked in this slice: add the generated v1.0 release ledger. The ledger is
    derived from the 104 support-cell rows and assigns every cell a row-level
    v1 role: Gaussian inference anchor, Gaussian basic-working row,
    basic-distribution recovery row, or post-v1.0 validation/design row. This
    is a release-planning speedup and audit surface only; it does not change
    support-cell status, authorize coverage, promote `inference_ready` or
    `supported`, introduce REML or AI-REML wording, expand q4/q8, or create
    public-support claims.
70. Banked in this slice: add the generated 90% practical-surface review
    packet. `tools/qseries_v1_release_check.py --write-candidates` now writes
    `docs/dev-log/release-audits/q-series-v1-90pct-review-packet.tsv`, which
    expands the current `rows_to_90=7` counter into the exact next seven rows
    requiring Rose/Fisher/Grace review before any design, code, compute, or
    support-cell edit. The packet is no-compute release-prep evidence only; it
    authorizes no coverage, `inference_ready`, `supported`, q4/q8, REML,
    AI-REML, bridge, or public-support claim.
71. Leave two-slope structured q6/q8 cells planned until the one-slope cells,
    metadata wrappers, provider contracts, bridge parity, interval diagnostics,
    and coverage denominators are stable.

Bridge parity, REML language, intervals, coverage, and public support move only
after the exact cell passes the evidence ladder. No row in this note promotes
DRAC execution, broad R bridge support, public optimizer controls, q4 interval
coverage, q4 REML, HSquared AI-REML, or non-Gaussian AI-REML.

## Future Lesson

For every future structured random-effect feature, write the support-cell row
first. Then code, tests, dashboard, docs, check-log entries, after-task notes,
and PR wording all update against that row. That keeps useful evidence from
accumulating faster than the public truth can track it.
