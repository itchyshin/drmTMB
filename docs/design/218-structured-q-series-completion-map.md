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
  and K-matrix `relmat()`. These are exact `mu1:x+mu2:x` cells only; they do
  not promote intercept-plus-slope q4/q8, interval reliability, coverage,
  REML, AI-REML, range-estimating spatial support, pedigree/Ainv bridge
  marshalling, or relmat Q bridge marshalling.
- Q2 bridge fixture evidence is banked only for complete-response
  exact-Gaussian ML fixtures: phylo, fixed-covariance spatial, animal A-matrix,
  and relmat K-matrix.
- Phylo q4 point parity and extractor evidence exist, but q4 interval
  reliability, q4 interval coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,
  HSquared AI-REML, and non-Gaussian AI-REML remain outside support.
- Ordinary q6/q8 diagnostic routes do not imply structured q6/q8 support.
- Poisson and NB2 q1 structured `mu` intercept rows are first non-Gaussian
  point-fit slices. They do not imply non-Gaussian structured slopes, q2/q4,
  REML, or interval support.
- Direct SD target visibility does not create derived-correlation interval
  support. Direct SD profile feasibility and derived correlation interval
  reliability are separate cells.

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
All eight provider-variant fits converged, but all eight returned
`pdHess = FALSE`, so Wald and profile intervals were not attempted. This
confirms that the current q4 all-four one-slope interval lane remains
Hessian-blocked before any denominator or coverage work; it does not promote
interval reliability, coverage, q4 REML, AI-REML, broad bridge support, public
support, or broader q8 support.

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
all-four one-slope q8-shaped cells. The q1, q2, matched, and q8-shaped rows
may cite runtime K/Q same-target native evidence where it has been banked, but
the q4 location row stays `planned_not_banked` for native Q evidence and every
row leaves `bridge_q_status`, `direct_drmjl_q_status`, and
`r_via_julia_q_status` at `unsupported`. This sidecar is bridge-boundary
evidence only; it does not implement Q precision marshalling, broad bridge
support, interval reliability, coverage, q4 REML, AI-REML, public support, or
broader q8 support.

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
   in this slice: compare lower-side warm/reset/capped/fixed starts and show
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
22. Leave two-slope structured q6/q8 cells planned until the one-slope cells,
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
