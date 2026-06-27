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
- Poisson and NB2 q1 structured `mu` intercept and unlabelled one-slope rows
  are first non-Gaussian point-fit slices. They do not imply pure, multiple, or
  labelled non-Gaussian structured slopes, zero-inflated structure, structured
  count scale routes, q2/q4, REML, AI-REML, interval support, or coverage.
- The ordinary count one-slope rows now have an explicit fixture/recovery
  contract sidecar. It records existing native TMB ML/Laplace point-fit and
  extractor evidence, while native deterministic fixture status is now
  `native_fixture_banked` and calibrated recovery remains `designed_not_run`.
  Native fixture status is not bridge parity. The follow-up recovery-runner
  contract is also now banked as a dry-run manifest and run log only; no
  recovery simulation, Totoro job, DRAC job, coverage-evaluable denominator,
  interval reliability, coverage, or public support has moved. A dispatch
  preflight sidecar now names provider/family shard boundaries and
  race-safety rules, but it is not human approval and no job has been
  submitted. The first local Codex micro-shards have now executed the exact
  `phylo()` plus `poisson()`, `phylo()` plus `nbinom2()`,
  fixed-covariance `spatial()` plus `poisson()`, and fixed-covariance
  `spatial()` plus `nbinom2()` q1 `mu` one-slope cells for four seeds each,
  with four converged `pdHess = TRUE` point fits per cell. The NB2 rows keep
  `sigma` as fixed-effect overdispersion only, and the spatial rows keep
  range-estimating spatial support closed. These rows are local smoke evidence
  only: they do not create a coverage-evaluable denominator, MCSE-calibrated
  recovery evidence, interval reliability, bridge parity, Totoro/DRAC execution
  evidence, REML, AI-REML, public support, structured count `sigma`, labelled
  or multiple count slopes, zero-inflated structure, or neighbouring count
  support.
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

**Therefore the validated completion path is the PROFILE channel at adequate g.**
The g-sweep capstone and interval-reliability rung show the slope/sigma/q2/
q4-location "walls" are small-sample artifacts: profile coverage reaches
certified-nominal (0.948-0.958, MCSE ~0.01) and q4-location pdHess fragility
evaporates (phylo 48.6% -> 5.0%, relmat 22.9% -> 0.0%) by g=32, with the eight
certified cells passing the interval-reliability rung via the profile channel.

**What is left is a maintainer DESIGN DECISION, not code.** No cell earns
`supported` this cycle: `supported` requires deployment-g nominal coverage, which
needs either the future scale-side REML derivation (large; partly upstream
DRM.jl) or accepting larger-g (g>=32) as the deployment recommendation. The
maximal honest machine move is promoting the g=32-certified phylo+relmat cells to
`interval_feasible` — a ~185-guard coordinated edit the standing HOLD panel gated
behind maintainer + Pat/`user_tester` + Darwin/`audience_reviewer` sign-off.
Until that decision is made, every cell keeps `interval_status = planned` and
`coverage_status = planned`, and the honest public recommendation is: **use the
profile channel and an adequate group count (g>=32); the Wald-t opt-in narrows
the small-g gap but does not by itself reach nominal at the deployment default.**

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
the exact pre-optimization rejection contract for structured-effect routes that
the engine already rejects across non-Gaussian families and endpoints. It
covers `student()`/`spatial`, `beta()`/`animal`, `Gamma()`/`relmat`, and
`cumulative_logit()`/`phylo` on `mu`; `beta()`/`animal` on `sigma`;
`student()`/`phylo` on `nu`; `poisson()`/`spatial` on `zi`; and
`truncated_nbinom2()`/`relmat` on `hu`. Each intercept-only `q1` cell is
rejected at the formula gate (`Structured non-Gaussian paths`), so each linked
`qseries_*_rejected` cell stays `unsupported`. These rows complete the
exact-cell boundary coverage: structured support for one family, endpoint, or
provider never implies it for another. The rows are rejection evidence only and
do not promote parser-ready, point-fit, bridge, interval, coverage, REML,
AI-REML, public-support, or q4/q8 status; each stays `unsupported` until a
supported route is designed, implemented, and tested for the exact
provider/endpoint/family cell.

`structured-re-count-structured-mu-rejection-contract.tsv` records the exact
pre-optimization rejection contract for structured count `mu` routes the engine
rejects beyond the banked one-slope cells: a non-canonical (slope-only)
coefficient, a labelled `q=2` covariance, a structured term combined with an
ordinary random effect, a zero-inflated structured term (Poisson and NB2), and
two simultaneous structured effect types. Each cell is rejected at the formula
gate with its own message (for example `cannot be combined` or `Only one
structured`), backed by `tests/testthat/test-count-structured-mu.R`, so each
linked `qseries_count_mu_*_rejected` cell stays `unsupported`. These rows answer
the count `mu` half-cell question: the banked count `mu` one-slope cells do not
imply multiple, labelled, combined, zero-inflated, or multi-type structured count
`mu` support. The rows are rejection evidence only and do not promote
parser-ready, point-fit, bridge, interval, coverage, REML, AI-REML, public
support, or q4/q8 status. The contracts anchor on engine message substrings; see
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
    contract that documents structured-effect routes the engine already rejects
    across non-Gaussian families and endpoints. The eight intercept-only `q1`
    cells cover `student()`/`spatial`, `beta()`/`animal`, `Gamma()`/`relmat`,
    and `cumulative_logit()`/`phylo` on `mu`; `beta()`/`animal` on `sigma`;
    `student()`/`phylo` on `nu`; `poisson()`/`spatial` on `zi`; and
    `truncated_nbinom2()`/`relmat` on `hu`. Each is rejected at the
    pre-optimization formula gate (`Structured non-Gaussian paths`), so the
    linked `qseries_*_rejected` cells stay `unsupported`. This completes the
    exact-cell boundary coverage: structured support for one family, endpoint,
    or provider never implies it for another. It is rejection evidence only and
    does not promote parser-ready, point-fit, bridge, interval, coverage, REML,
    AI-REML, public-support, or q4/q8 status.
40. Leave two-slope structured q6/q8 cells planned until the one-slope cells,
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
