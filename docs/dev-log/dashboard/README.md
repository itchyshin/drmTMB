# drmTMB Mission-Control Dashboard

This directory stores the durable source for the local finish-plan dashboard.
The live copy is served from `/tmp/drm-dashboard` so agents can update JSON
status while the repository remains the source of truth.

Start or refresh the board with:

```sh
sh tools/start-mission-control.sh --background
```

The start script first runs:

```sh
python3 tools/validate-mission-control.py
```

The validator checks that `version.txt` matches the HTML build constant, phase
counts match slice statuses, metrics match the phase slices, canonical team
names are used, the finish-board rows have valid issue, owner, status, and
evidence fields, and the dashboard matrix has the same number of rows as
`docs/design/168-r-julia-finish-capability-matrix.md`. It also validates the
100-row finish-run ledger in `finish-100-slices.tsv`, validates the guarded q4
target and estimator inventory in `q4-target-inventory.tsv`, validates the
location/scale `phylo()` balance inventory in
`phylo-balance-inventory.tsv`, checks that README, ROADMAP, NEWS, pkgdown
navigation, this dashboard README, and any local
Documenter.jl sources link back to
`docs/design/168-r-julia-finish-capability-matrix.md`, and rejects
public-facing release-promotion wording or reserved Julia-control claims outside
the release gate.

Then open:

```text
http://127.0.0.1:8765/
```

The page reads `status.json` and `sweep.json` every eight seconds. Update those
JSON files as slices move from `queued` to `active`, `blocked`, `verified`,
`banked`, or `deferred`.

The `finish_board` rows are the issue-led twin ledger. Keep the six lanes
present: Critical Path, Issue Ledger, Twin Claim Board, Cross-Package Lessons,
Evidence Gates, and Release Readiness. Rows should separate native TMB support,
R-to-Julia bridge status, and direct DRM.jl status rather than collapsing them
into a single "supported" claim.

The Julia bridge tables are generated artifacts, not hand-edited ledgers.
Regenerate `julia-gates.tsv` from `drm_julia_intentional_gates()` with
`Rscript tools/write-julia-gate-registry.R`, and regenerate
`julia-capabilities.tsv` from `drm_julia_capability_comparison()` with
`Rscript tools/write-julia-capability-comparison.R`. Both scripts write a
dashboard copy and an `inst/extdata/` copy so tests can compare artifacts inside
`R CMD check`, where `docs/` is not installed.

The 100-slice finish-run ledger is hand-curated mission-control state, not a
generated package artifact. Keep it at exactly 100 rows. Rows 1-10 record the
truth-freeze wave; rows 11-100 stay `queued` until implementation, tests, docs,
issue evidence, and dashboard state catch up. A row marked `banked` or
`verified` must point to existing evidence.

`q4-target-inventory.tsv` is the guarded R-side q4 target and estimator
inventory. It separates native TMB ML evidence, unsupported native q4 REML,
experimental Julia bridge q4 REML, profile-target extraction, and bootstrap
smoke or negative evidence. The validator checks its schema, statuses, and
evidence paths so q4 target rows cannot drift into bridge, interval-coverage, or
AI-REML claims.

`phylo-balance-inventory.tsv` is the guarded location/scale `phylo()` inventory.
It separates native TMB ML, native TMB REML, and experimental R-to-Julia bridge
rows so univariate mean-side support, residual-scale support, matched
mean-scale support, and q4 diagnostics do not collapse into one balanced-support
claim.

`scale-phylo-diagnostics.tsv` records the scale-side phylogenetic diagnostic
surface. It separates clamp-active warnings from scale-side identifiability
notes and records that diagnostic rows are not interval-coverage evidence.

`phylo-profile-loglik-status.tsv` records finite log-likelihood and
profile-target readiness for selected phylogenetic Gaussian rows. It keeps
direct-ready SD targets separate from derived q4 correlation targets and treats
interval coverage as unevaluated unless a row explicitly proves otherwise.

`bootstrap-refit-accounting.tsv` records requested, successful, and failed
bootstrap refits plus failure-reason visibility. It is an accounting table, not
a coverage table.

`phylo-q2-q4-target-map.tsv` records the q2/q4 phylogenetic target split. It
keeps bivariate location-only q2 evidence, block-diagonal q2-plus-q2 evidence,
full four-axis q4 evidence, unsupported native REML rows, and experimental
Julia bridge rows separate so direct-ready lower-dimensional targets cannot be
read as q4 interval support.

`phylo-extractor-status.tsv` records q2 and q4 extractor status fields from
`corpairs()`, `summary(fit)$covariance`, and `profile_targets()`. It keeps
point-only extraction, profile/newdata requirements, derived interval
unavailability, and covariance status fields visible without promoting Wald or
coverage claims.

`bridge-payload-schema.tsv` records row-specific R-to-Julia bridge payload
fields. It names the data, formula, estimator, covariance, target, inference,
and unsupported-payload fields that each bridge route must carry before parity
or promotion language can be considered.

`bridge-provenance-fields.tsv` records provenance groups that must travel with
bridge payloads: requested and effective estimators, target identity, data-row
and missingness policy, formula grammar, matrix origin, runtime versions, dirty
flags, inference status, reconstruction maps, and intentional-error guard
metadata.

`loconly-bridge-draft.tsv` records the single gated exact-Gaussian
location-only phylogenetic REML diagnostic draft row. It marks direct DRM.jl
diagnostic evidence and mission-control schema/provenance coverage while
leaving native R, R-via-Julia, parity, and bridge support planned.

`bridge-serialization-status.tsv` records the internal serialization status for
bridge draft rows. The first covered row is a base-R TSV round-trip for the
location-only schema tuple; JSON remains planned and is not a public payload
surface.

`bridge-reconstruction-status.tsv` records internal R reconstruction status for
Julia bridge objects. The first covered row uses a synthetic bridge object and
keeps missing payload pieces, profile targets, corpairs, and inference promotion
explicit.

`julia-home-smoke.tsv` records the R-side Julia home helper smoke tests. It
checks `DRM_JL_JULIA_HOME` precedence, `JULIA_HOME` fallback, explicit child
setup, and caller-scoped restoration without invoking Julia or promoting a
bridge route.

`bridge-rejection-messages.tsv` records intentional R-to-Julia bridge rejection
message coverage. It mirrors the current gate registry so every `intentional_error`
row has a tested pre-JuliaCall error and route guidance.

`capability-regeneration-status.tsv` records the generated bridge artifacts,
their source functions, writer scripts, dashboard outputs, `inst/extdata/`
outputs, and row counts. It is regeneration evidence, not a support-promotion
table.

`bridge-parity-smoke-status.tsv` records row-specific native TMB versus
R-to-Julia bridge parity smoke evidence. It names the exact Gaussian cells,
parity targets, tolerances, and skipped/blocked rows instead of treating a
passing smoke test as broad bridge support.

`binomial-bridge-map.tsv` records the native TMB binomial first slice,
intentional non-phylo Julia bridge rejection, experimental Binomial phylo bridge
row, and direct DRM.jl alignment as separate rows.

`binomial-profile-status.tsv` records target-scoped profile feasibility for
fixed-effect binomial rows. It keeps direct `mu` profile targets, explicit
`parm` requirements, structured failure rows, and interval-promotion status
separate.

`ayumi-phylo-balance-100-slices.tsv` records the Ayumi phylo-balance arc as a
separate 100-slice ledger from the R/Julia finish run. Its first two waves
rehydrate issue access, tracker evidence, forbidden wording, route vocabulary,
and reply gates before any new Ayumi-facing prose is drafted.

`ayumi-phylo-balance-vocabulary.tsv` defines the balance terms used by the
Ayumi arc. It keeps univariate balance, q4 balance, partial native REML,
experimental bridge support, diagnostic point fits, MAP vocabulary, reply
gates, and issue-access limits as validator-owned rows.

`ayumi-phylo-balance-trackers.tsv` records the current issue/source map for the
Ayumi arc. It distinguishes the unreadable external Ayumi issue URL from the
internal drmTMB/DRM.jl trackers and from tracker evidence that a prior reply
exists but is not independently readable in this session.

`ayumi-inference-coverage-ledger.tsv` records Wald, profile, bootstrap, and
coverage status for the Ayumi balance cells. It is deliberately conservative:
direct-ready profile targets, bootstrap plumbing, known undercoverage, and
unevaluated coverage remain different statuses.

`ayumi-boundary-status-ledger.tsv` records the boundary and fit-status facts
that affect Ayumi interpretation: `pdHess = FALSE`, log-`sigma` clamps,
near-boundary residual `rho12`, q4 covariance warnings, profile failures, and
direct Julia collapsed-axis profiles.

`structured-re-balance-matrix.tsv` records q1, q2, q2-plus-q2, and q4
structured random-effect status across `phylo()`, `spatial()`, `animal()`,
`relmat()`, and the q1-only `phylo_interaction()` route. It separates fit
status, inference status, and bridge status so location-side support,
scale-side support, all-four q4 point fits, count-model q1 fits, and
unsupported interval or bridge claims cannot collapse into one balance claim.

`structured-re-q-series-support-cells.tsv` records the exact q-series
completion cells for structured random effects and ordinary comparators. It
names the formula cell, family, provider, dimension pattern, endpoint set,
slope class, covariance layout, route, requested/effective estimator, fit,
extractor, bridge, interval, coverage, authority, denominator, evidence, and
next-gate fields for each row. This file is the row-level source of truth for
q-series completion planning: a balanced `mu+sigma` row, a q2 fixture, a q4
point row, an ordinary q8 diagnostic route, or a direct-SD profile target
never promotes neighbouring half-cells, structured q6/q8, REML, intervals,
coverage, broad bridge support, or public optimizer controls unless the exact
cell row says so.

The mission-control widget renders this 104-row table near the top of the
page. The widget deliberately separates row state, fit/stability state,
inference readiness, interval status, and coverage status so a row that has
been tried or fit-stabilized is not confused with a row that is
`inference_ready`. `structured-re-q-series-closure-triage.tsv` is the compact
closure ledger shown above the detailed rows: its 16 buckets sum to all 104
support cells and separate evidence-complete inference rows, baseline
comparators, recovery-only non-Gaussian rows, intentional rejections,
point/fixture gates, q1 mu-slope pregrid and upper-tail blockers,
diagnostic-only rows, admission blockers, calibration blockers, high-q
planned/gated rows, and q8 stability blockers. It is a board triage table, not
a support promotion table. Promoted rows also join to
`structured-re-q-series-inference-evidence-summary.tsv`, a compact eight-row
evidence summary that names the interval channel, denominator, coverage, and
miss-balance caveat for the three q1 sigma, three q1 `mu:(Intercept)`, and two
q2 location-slope rows. The
widget also renders `structured-re-q-series-next-campaign-queue.tsv`, a
ten-row compute/hold queue whose row counts sum to the same 104 support cells.
That queue names which lanes are no-compute holds, recovery reproduction,
local/Totoro smoke candidates, or DRAC-held replacement-rule work. It is a
cluster-use guard only: it prevents connected hosts from becoming broad
unreviewed denominator campaigns and does not promote support status.

`structured-re-q-series-v1-readiness-reset.tsv` records the current v1.0
prioritization boundary. It keeps the 104 support cells, 67 Gaussian rows, 37
non-Gaussian rows, eight exact `inference_ready` rows, and zero structured
`supported` rows intact while separating implemented/basic-working v1.0 scope
from post-v1.0 `inference_ready` and `supported` validation. The row set is a
planning reset only: it authorizes no coverage job, support-cell promotion,
REML, AI-REML, q4/q8 expansion, or public-support claim. Future no-compute
tranche drafts can start from `tools/qseries-tranche-scaffold.py`, which prints
member-board and wiring scaffolds to stdout without mutating evidence.

`structured-re-q-series-v1-release-ledger.tsv` is the generated row-level view
of that reset. `tools/qseries_v1_release_ledger.py` derives it from the
104-row support-cell table, giving every cell a v1.0 role: Gaussian
inference anchor, Gaussian basic-working row, basic-distribution recovery row,
or post-v1.0 validation/design row. The ledger is release-planning evidence
only. It does not authorize coverage, change support-cell status, create
`inference_ready` or `supported` claims, or introduce REML, AI-REML, q4/q8, or
public-support wording.
The same generator writes
`docs/dev-log/release-audits/q-series-v1-release-status.md`, the
release-facing summary that `README.md`, `NEWS.md`, `ROADMAP.md`, and
`docs/dev-log/known-limitations.md` should cite while v1.0 wording is being
prepared. Its progress-accounting section reports row percentages for the
practical v1.0 surface, Gaussian core, basic-distribution recovery, exact
`inference_ready` anchors, `supported` authority, and post-v1.0 rows without
turning those percentages into package-release completion claims.
`tools/qseries_v1_claim_guard.py` checks the same generated status file and the
public/status files for inflated Q-Series v1.0 wording before release notes or
roadmap text are treated as synchronized.
For the routine v1.0 Q-Series preflight, run
`python3 tools/qseries_v1_release_check.py --summary --check-report
--check-candidates`; it checks the generated ledger/status, the claim guard,
Mission Control, the generated preflight report, and the generated
next-candidate review TSV plus the post-75% next-four review packet in one
command while still reporting the row-accounting percentages. The generated
report records how many additional practical surface rows would be needed to
reach 75%, 80%, 90%, and 100% row-accounting targets; the candidate TSV ranks
the 20 post-v1.0 rows into the next four rows after 75%, the next six to review
for 80%, and the later post-v1.0 queue; and
`docs/dev-log/release-audits/q-series-v1-75pct-review-packet.tsv` expands the
next four rows into a design/recovery checklist. The same candidate bundle
also writes
`docs/dev-log/release-audits/q-series-v1-first-candidate-design-contract.tsv`,
the first row-specific contract for the current first unresolved candidate, and
`docs/dev-log/release-audits/q-series-v1-first-candidate-debug-fixture-contract.tsv`,
the fail-closed local-debug fixture contract for that same first candidate.
The bundle also writes
`docs/dev-log/release-audits/q-series-v1-first-four-design-contracts.tsv` and
`docs/dev-log/release-audits/q-series-v1-first-four-debug-fixture-contracts.tsv`
for the next four post-75% practical-surface review rows:
ordinal/phylo `mu`, truncated-NB2 relmat `hu`, labelled spatial count `mu`,
and simultaneous-provider count `mu`. These artifacts are planning aids only
and do not authorize row movement, code changes, local fits, host compute,
denominator rows, coverage jobs, `inference_ready`, `supported`, or
public-release claims. Regenerate the report with
`--write-report --write-candidates` after intentional release-boundary changes.
For a quick planning snapshot, run
`python3 tools/qseries_v1_release_check.py --fast-status`; that mode reads the
checked-in release status and ledger only, skips ledger regeneration, the claim
guard, and Mission Control, and must not be used as evidence for status
movement or public wording.
For the current first-four candidate baseline, run
`R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file
tools/qseries-v1-first-four-rejection-smoke.R`; it now emits ten local
fit-only rows and four exact current-candidate rejection rows. The four
rejections check the structured non-Gaussian, unlabelled q=1, and
single-provider count gates without creating fit denominators, coverage
evidence, status movement, or public support.

`structured-re-q2-retained-denominator-design.tsv` is now historical Tranche 2
q2 design evidence, not a current run permission. The Rorqual SR150 pregrid was
imported as review-only evidence in
`structured-re-q2-retained-denominator-pregrid-results.tsv`, and the later
Totoro repair smoke was summarized in
`structured-re-q2-retained-denominator-repair-smoke-review.tsv`. That review
found that the smoke reran the existing interval route
(`interval_repair_channel = none`), promoted no row, and blocks SR475/SR1000 or
host top-up until Fisher/Rose/Grace accept a named interval-repair route and it
passes the small retained-denominator smoke. The q2 intercept and q2-plus-q2
cells remain `point_fit/planned/planned`; this evidence does not promote
interval status, coverage, `inference_ready`, `supported`, q2 slope, q4/q8,
non-Gaussian, REML, AI-REML, bridge, or public-support claims.

`structured-re-q2-retained-denominator-tranche9-repair-route-review.tsv`
records the next no-compute q2 repair-route review. It names the existing
`bounded_tmbprofile_direct_correlation_sidecar` as a direct-correlation
candidate, then blocks it as a whole-cell repair because the q2 intercept cells
also retain endpoint direct-SD undercoverage or finiteness blockers. The phylo
q2-plus-q2 row remains held because its `pdHess`, endpoint-SD, direct
`mu1`/`mu2` correlation, and held `sigma1`/`sigma2` correlation blockers are not
repaired by the q2 intercept sidecar. Tranche 9 therefore authorizes no small
smoke, no host top-up, no coverage, no `inference_ready`, and no support-cell
status edit. The next q2 move is a combined endpoint-SD plus direct-correlation
route or a target-split decision reviewed by Fisher, Rose, Noether, and Grace.

`structured-re-q2-retained-denominator-tranche10-target-split-design.tsv`
banks that target-split decision without opening compute. The four q2 intercept
rows separate the direct `cor_mu1_mu2_intercept` component from the endpoint
direct-SD `sd_mu2_intercept` blocker; the component summary rows keep those
estimands separate; and the phylo q2-plus-q2 row remains held outside the q2
intercept split because its `pdHess`, endpoint-SD, direct `mu1`/`mu2`
correlation, and held `sigma1`/`sigma2` correlation blockers need a separate
route. Tranche 10 does not authorize a smoke, host submission, SR475/SR1000
top-up, coverage, `inference_ready`, or support-cell status edit. The next q2
move is a Tranche 11 executable small-smoke contract or route design with
Fisher/Rose/Noether/Grace approval before any compute.

`structured-re-q2-retained-denominator-tranche11-direct-correlation-smoke-contract.tsv`
banks that next contract without executing it. The contract uses the existing
q2 intercept smoke runner only for the direct `cor_mu1_mu2_intercept`
component, passes
`interval_repair_channel = bounded_tmbprofile_direct_correlation_sidecar`, and
records one 32-replicate seed range per provider. The helper
`tools/run-q2-retained-denominator-tranche11-direct-correlation-smoke.sh`
refuses to run unless
`DRMTMB_Q2_TRANCHE11_EXECUTION_APPROVED=rose_fisher_noether_grace` is set. The
endpoint direct-SD component and the q2-plus-q2 cell remain held because they
need separate routes. Tranche 11 therefore banks exact future commands only:
no smoke was executed, no host job was submitted, no SR475/SR1000 top-up was
authorized, and no interval, coverage, `inference_ready`, support, q2-plus, or
public-support claim moved.

`structured-re-q2-retained-denominator-tranche12-endpoint-sd-route-design.tsv`
banks the matching endpoint-SD route review without opening compute. The four
q2 intercept cells keep `sd_mu2_intercept` as an endpoint direct-SD blocker, and
the existing `endpoint_zero_boundary_profile_channel` is recorded as a labelled
problem class rather than an executable repair channel. The Tranche 11
direct-correlation contract remains separate and cannot clear endpoint-SD
blockers; the phylo q2-plus-q2 row remains outside this route because its
`pdHess`, endpoint-SD, direct `mu1`/`mu2` correlation, and held
`sigma1`/`sigma2` correlation blockers need a separate route. Tranche 12
therefore authorizes no endpoint-SD smoke, host submission, SR475/SR1000
top-up, coverage, `inference_ready`, support-cell status edit, or
public-support claim.

`structured-re-q2-retained-denominator-tranche13-endpoint-sd-blocker-decision.tsv`
turns the existing endpoint-SD route evidence into a no-compute blocker
decision. The phylo `sd_mu2_intercept` Totoro `n = 32` smoke under
`endpoint_zero_boundary_profile_channel` had stable fits, `pdHess`, and finite
profiles for all 32 attempts, but profile coverage was `0.8750` with four
upper-tail misses. Fisher and Rose therefore block SR475/SR1000 top-up and
provider repeats for that route: the blocker is interval shape, not fit
stability. The DDF sidecar lead in
`https://github.com/itchyshin/drmTMB/issues/687` is recorded as a possible
future route only; it is not implementation authority and does not move any
status. Direct-correlation Tranche 11 and q2-plus remain separate. Tranche 13
authorizes no new endpoint-SD smoke, host submission, top-up, coverage,
`inference_ready`, support-cell status edit, DDF implementation claim, or
public-support claim.

`structured-re-q2-retained-denominator-tranche14-endpoint-sd-replacement-route-screen.tsv`
records the next no-compute endpoint-SD screen. It keeps five possible route
families as source-link leads only: Satterthwaite-style variance-component DDF,
Kenward-Roger-style DDF analogues, parametric bootstrap intervals,
boundary-likelihood diagnostics, and Cox-Reid adjusted-profile or
orthogonalization ideas. These links are not derivations, implementations, or
status evidence. No candidate route is executable yet, and the ledger forbids
turning DDF, bootstrap, or adjusted-profile names into implementation claims.
Direct-correlation Tranche 11 and q2-plus remain separate. Tranche 14
authorizes no endpoint-SD smoke, host submission, top-up, coverage,
`inference_ready`, support-cell status edit, or public-support claim.

`structured-re-q2-retained-denominator-tranche15-endpoint-sd-bootstrap-smoke-contract.tsv`
banks the first executable-looking q2 endpoint-SD replacement route, but only
as a micro-smoke contract. The selected candidate is parametric bootstrap for
`sd_mu2_intercept`, chosen because the existing q2 intercept runner already
supports `method = "bootstrap"` intervals for that exact direct-SD estimand.
The contract uses `bootstrap_R = 2` and `n_rep = 8` per provider, so it can only
probe finite bootstrap output and provenance; it cannot estimate coverage or
interval reliability. The helper
`tools/run-q2-retained-denominator-tranche15-endpoint-sd-bootstrap-smoke.sh`
refuses to run unless
`DRMTMB_Q2_TRANCHE15_EXECUTION_APPROVED=rose_fisher_noether_grace` is set. No
bootstrap refit, endpoint-SD smoke result, host submission, top-up, coverage,
`inference_ready`, support-cell status edit, bootstrap reliability claim, or
public-support claim is authorized. Direct-correlation Tranche 11 and q2-plus
remain separate.

`structured-re-q2-retained-denominator-tranche16-q2-plus-route-decomposition.tsv`
records the q2-plus follow-up without spending compute. It decomposes the phylo
q2-plus-q2 blocker into five Rorqual SR150 within-block targets, the held
`cor_sigma1_sigma2_intercept` target from the Nibi smoke, cross-block
correlations that require a true q4 route, and the separated q2-intercept
Tranche 11/15 contracts. The ledger keeps the SR150 signal as blocker evidence
only: `pdHess = 745/750`, worst Wald/profile coverage is `0.8867`, and the
held sigma1/sigma2 correlation had Nibi profile finiteness `4/5`. Tranche 16
authorizes no q2-plus compute, host submission, top-up, coverage,
`inference_ready`, support-cell status edit, q2-intercept inheritance, q4
inheritance, or public-support claim.

`structured-re-q2-retained-denominator-tranche17-q2-plus-repair-route-screen.tsv`
records the next no-compute q2-plus screen. It lists four candidate repair
leads, one true-q4 boundary row, one q2-intercept inheritance-rejection row,
and one summary row. The candidate leads are not executable contracts: they
require raw `pdHess`/profile failure taxonomy, sigma-correlation profile
geometry review, bootstrap failed-refit policy, or sigma-side interval-shape
review before any runner or host command can be written. Every row stays
`no_compute_in_tranche17`, `coverage_not_authorized`, and `do_not_promote`.
Tranche 17 authorizes no Totoro, Nibi, Rorqual, Trillium, or DRAC execution, no
SR475/SR1000 top-up, no interval/coverage status change, no q2-intercept
inheritance, no q4/q8 claim, and no public-support claim.

`structured-re-q2-retained-denominator-tranche18-q2-plus-failure-taxonomy.tsv`
selects the cheapest post-screen route: classify the existing failure evidence
before writing any runner. It reviews the Rorqual SR150 q2-plus replicate TSV
and the Nibi substitute-smoke replicate TSV. The taxonomy keeps the shared
SR150 `pdHess` loss on replicate 108 separate from missing-`rlang` artifact
failures on replicates 29 and 53, sigma-side upper-tail profile miss patterns,
direct-correlation undercoverage, and the Nibi held sigma1/sigma2 profile-root
error on replicate 3. This is triage evidence only. Tranche 18 authorizes no
new replicate, smoke contract, host execution, top-up, coverage,
`inference_ready`, support-cell promotion, q2-intercept inheritance, q4/q8
claim, or public-support claim.

`structured-re-q2-retained-denominator-tranche19-q2-plus-held-correlation-profile-contract.tsv`
banks the next fail-closed contract from that taxonomy. It names exactly one
held-correlation target, `cor_sigma1_sigma2_intercept`, exactly one failed
replicate/seed pair, replicate 3 / seed 823003, and exactly one diagnostic
route, the bounded `tmbprofile` direct-correlation sidecar. The accompanying
helper refuses to run without the Fisher/Rose/Noether/Gauss/Grace approval
environment variable and blocks DRAC, Nibi, Rorqual, and Trillium denominator
execution for this micro-contract. Tranche 19 is a contract only: it runs no
replicate, creates no denominator, authorizes no coverage or top-up, and moves
no interval, coverage, `inference_ready`, `supported`, q2-plus, q4/q8, bridge,
REML, AI-REML, or public-support claim.

`structured-re-q2-retained-denominator-tranche20-held-correlation-profile-diagnostic.tsv`
reviews the single diagnostic run allowed by the Tranche 19 contract. The run
used local host provenance only (`host_class =
tranche19_local_profile_contract`, `host_name = local_codex`), replayed only
replicate 3 / seed 823003 for `cor_sigma1_sigma2_intercept`, and produced
`fit_ok`, `pdHess = TRUE`, and a finite Wald interval at the boundary, but the
profile interval remained nonfinite and the bounded `tmbprofile` repair sidecar
also remained nonfinite. The runner summary is `local_smoke_failed`. Tranche 20
therefore closes this route as diagnostic failure evidence only: no denominator,
no host pooling, no top-up, no coverage, no status edit, no q2-plus promotion,
and no q4/q8, REML, AI-REML, bridge, or public-support claim.

`structured-re-q2-retained-denominator-tranche21-route-hold-decision.tsv`
records the follow-up route-hold decision from that failed diagnostic. It
closes the bounded `tmbprofile` held-correlation route, rejects another
immediate profile rerun or top-up, and lists only no-compute candidate
directions: a derived boundary-aware held-correlation route, artifact-dependency
cleanup, sigma-side interval-shape review, or raw replicate-108 Hessian review.
Every row remains `no_compute_in_tranche21`, `coverage_not_authorized`, and
`do_not_promote`. The linked q2-plus support cell stays
`point_fit/planned/planned`; Tranche 21 authorizes no denominator, coverage,
q2-plus promotion, q4/q8 claim, REML, AI-REML, bridge, or public-support claim.

`structured-re-q2-retained-denominator-tranche22-rep108-artifact-review.tsv`
reviews the existing Rorqual SR150 replicate-108 artifact rows for the five
q2-plus within-block targets. All five rows are `fit_ok` with convergence 0
and `pdHess = FALSE`, the fit message is `NaNs produced`, and Wald intervals
are nonfinite. Four targets have finite profiles that contain the truth, but
that does not overcome the shared Hessian failure; the `sd_sigma2_intercept`
profile is finite with a near-boundary warning and does not contain the truth.
The TSV does not contain raw Hessian eigenstructure, gradients, or optimizer
trace, so Tranche 22 is an artifact review only. It runs no replicate,
authorizes no top-up or coverage, and moves no q2-plus, q4/q8, REML, AI-REML,
bridge, or public-support claim.

`structured-re-q2-retained-denominator-tranche23-rep108-geometry-contract.tsv`
banks the next gate as a raw-geometry reconstruction contract, not as
execution. The contract keeps Rorqual SR150 replicate 108 / seed 823108 as
source evidence for the same five q2-plus within-block targets and requires a
raw fit object or replay bundle, Hessian eigenstructure, gradient norms,
optimizer trace, boundary flags, source SHA, host label, and output path before
any geometry claim. Tranche 23 records no raw geometry output and runs no local,
Totoro, Nibi, Rorqual, Trillium, or DRAC command. It authorizes no denominator,
top-up, coverage, status movement, q2-plus promotion, q4/q8, REML, AI-REML,
bridge, or public-support claim.

`structured-re-q2-retained-denominator-tranche24-rep108-geometry-result.tsv`
records the one approved host-separated diagnostic replay from that contract.
The replay ran locally under `local_codex_geometry_reconstruction` for
replicate 108 / seed 823108 and reproduced the five target estimates, including
the near-boundary `sd_sigma2_intercept` estimate. The local fit had
`pdHess = TRUE`, a positive `cov.fixed` spectrum, and a small maximum gradient,
while the Rorqual SR150 source artifact had `pdHess = FALSE` and nonfinite Wald
status. Tranche 24 therefore records source/host drift evidence, not admission
or repair. It authorizes no denominator, top-up, coverage, status movement,
q2-plus promotion, q4/q8, REML, AI-REML, bridge, or public-support claim; the
next gate is a source-matched Rorqual/DRAC reconstruction or an explicit
q2-plus park decision.

`structured-re-q2-retained-denominator-tranche25-source-match-decision.tsv`
banks that gate as a no-compute decision contract. It requires source snapshot
proof before any Rorqual or DRAC replay can be interpreted: the dirty source
state, R session, package library, runner inputs, exact command, host label,
and output path must be manifest enough to explain why the source Rorqual
artifact had `pdHess = FALSE` while the local replay had `pdHess = TRUE`.
Local Codex, Totoro, unsynced DRAC, and other host repeats are explicitly
excluded for this gate because they cannot answer the source-drift question.
If source matching cannot be proven, q2-plus is parked rather than topped up.
Tranche 25 authorizes no compute, denominator, top-up, coverage, status
movement, q2-plus promotion, q4/q8, REML, AI-REML, bridge, or public-support
claim.

`structured-re-q2-retained-denominator-tranche26-source-snapshot-proof.tsv`
banks the source-snapshot proof layer for that gate. A BatchMode Rorqual probe
confirmed that the `/project` run root still has the copied source tree, shard-5
R library, package cache, metadata, and result artifacts. The copied source is
not a live Git repository, so the critical source manifest entries are recorded
and the full manifest hash check is deferred to any replay job rather than run
on a login node. Tranche 26 executes no replay and creates no denominator. It
keeps the q2-plus support cell at `point_fit/planned/planned` and authorizes no
top-up, coverage, status movement, q2-plus promotion, q4/q8, REML, AI-REML,
bridge, or public-support claim. The next gate is a checkpointed one-replicate
source-matched Rorqual replay with job-internal manifest verification, or
q2-plus parking if that source-matched replay cannot be kept honest.

`structured-re-q2-retained-denominator-tranche27-source-matched-replay-contract.tsv`
and `tools/slurm/q2-plus-rep108-source-replay-rorqual.sbatch` bank that replay
as a fail-closed job pack, not a submitted job. The pack targets only Rorqual
SLURM array task 108, uses the preserved source runner
`tools/run-structured-re-q2-plus-q2-intercept-smoke.R`, verifies the preserved
source manifest inside the job before R starts, and passes exactly the five
retained q2-plus target IDs from the imported Rorqual artifact. It requires
`DRMTMB_Q2_TRANCHE27_SOURCE_REPLAY_APPROVED=fisher_rose_noether_gauss_grace_manifest_verified`
before execution and refuses login-node, local Codex, Totoro, Nibi, Trillium,
Fir, unsynced DRAC, or source-unverified runs. Tranche 27 creates no replay
result, denominator, top-up, coverage, status movement, q2-plus promotion,
q4/q8, REML, AI-REML, bridge, or public-support claim. The next gate is either
submit exactly that one Rorqual job after checkpointed approval and review the
artifacts, or park q2-plus if the manifest/source-runner gate fails.

`structured-re-q2-retained-denominator-tranche28-source-replay-submission.tsv`
records that the approved source-matched replay was submitted as Rorqual job
15027970, array task 108, and was still `PENDING` for priority at the first
scheduler probe. The remote sbatch and result-root paths stay under the
preserved Rorqual `/project` run root, but no replay artifacts were imported and
no result review has occurred. Tranche 28 therefore creates no denominator,
top-up, coverage, status movement, q2-plus promotion, q4/q8, REML, AI-REML,
bridge, or public-support claim. The next gate is to monitor job 15027970; when
it reaches a terminal state, inspect the manifest-verified artifacts and open a
result-review tranche, or park q2-plus if the job or manifest gate fails.

`structured-re-q2-retained-denominator-tranche29-source-replay-terminal-review.tsv`
records the terminal Rorqual review for job 15027970. `sacct` reported
`FAILED` with exit `1:0` after 00:01:37 on node `rc32610`. The full sha256
source-manifest check failed before R execution at
`./tools/run-structured-re-q2-intercept-smoke.R`; the critical q2-plus manifest
entries were recorded, but the q2-plus runner did not start and no smoke result
TSVs, seed manifest, exact command, `sessionInfo`, or replay stdout/stderr were
created. Tranche 29 is therefore a terminal-failure review, not a denominator or
failure-rate replicate. It authorizes no resubmission, denominator, top-up,
coverage, status movement, q2-plus promotion, q4/q8, REML, AI-REML, bridge, or
public-support claim. The next gate is a checkpointed Tranche 30 choice between
a narrower critical-manifest replay contract and parking q2-plus.

`structured-re-q2-retained-denominator-tranche30-critical-manifest-replay-contract.tsv`
and `tools/slurm/q2-plus-rep108-critical-manifest-replay-rorqual.sbatch` bank
that narrower replay as a fail-closed, non-submitted job pack. The pack still
targets only Rorqual SLURM array task 108, replicate 108 / seed 823108, and the
five retained q2-plus target IDs. It verifies only the listed critical manifest
entries before R, records the excluded full-manifest failure
`./tools/run-structured-re-q2-intercept-smoke.R`, and refuses execution without
`DRMTMB_Q2_TRANCHE30_CRITICAL_REPLAY_APPROVED=fisher_rose_noether_gauss_grace_critical_manifest_contract_verified`.
Tranche 30 does not resubmit job 15027970 and creates no replay execution,
denominator, top-up, coverage, status movement, q2-plus promotion, q4/q8, REML,
AI-REML, bridge, or public-support claim. The next gate is a checkpointed
submission of exactly this one Rorqual task, followed by a separate terminal
artifact review, or q2-plus parking if the critical-manifest gate fails.

`structured-re-q2-retained-denominator-tranche31-critical-manifest-replay-submission.tsv`
records that checkpointed submission. Job 15029153 array task 108 was submitted
to Rorqual with the Tranche 30 approval token and the reviewed sbatch staged
under the preserved `/project` run root. The first probe found scheduler state
`PENDING` for priority and no Tranche 30 result root or replay artifacts.
Tranche 31 is therefore a submission ledger only: it creates no denominator,
top-up, coverage, status movement, q2-plus promotion, q4/q8, REML, AI-REML,
bridge, or public-support claim. The next gate is terminal-job monitoring and a
new result-review tranche, or q2-plus parking if the job or critical-manifest
gate fails.

`structured-re-q2-retained-denominator-tranche32-critical-manifest-replay-terminal-review.tsv`
records the terminal review of job 15029153. The job completed on Rorqual
node `rc32504` with exit `0:0`, and the critical manifest entries all checked
OK. The replay artifacts were imported under
`docs/dev-log/simulation-artifacts/2026-07-01-q2-tranche32-critical-manifest-replay-rorqual/`.
The result still fails the q2-plus admission gate: all five retained targets
have `pdHess = FALSE`, all five Wald intervals are nonfinite, all five profiles
are finite, and the sigma2 profile misses the truth near the SD boundary.
Tranche 32 creates no admission denominator, top-up, coverage, status movement,
q2-plus promotion, q4/q8, REML, AI-REML, bridge, or public-support claim. The
next gate is q2-plus parking or a separately reviewed geometry-explanation
design; no coverage or top-up is authorized from this result.

`structured-re-q2-retained-denominator-tranche33-q2-plus-parking-decision.tsv`
parks the q2-plus retained-denominator route after the failed Tranche 32 gate.
The decision is deliberately non-computational: no top-up, coverage job,
admission retry, interval-status edit, coverage-status edit, `inference_ready`,
`supported`, q2-plus promotion, q4/q8, REML, AI-REML, bridge, or public-support
claim moves. The q2-plus support cell remains `point_fit/planned/planned` with
`denominator_policy = repair_contract_ready_not_coverage`. Reopening q2-plus
now requires a new reviewed geometry-explanation design approved by
Rose/Fisher/Gauss/Noether/Grace and checkpointed before compute. The campaign
should otherwise return to the next non-parked Q-Series tranche.

`tools/run-structured-re-q2-retained-denominator-pregrid.R` and
`tools/slurm/q2-retained-denominator-pregrid-nibi.sbatch` remain reproducibility
artifacts for the reviewed SR150 path. They are not a current invitation to run
more q2 denominator work. New q2 compute must start with a row-specific
repair-route design, host-separated source and seed provenance, and a small
no-promotion smoke before any cluster escalation.

The widget also joins count one-slope rows to the local
`structured-re-count-slope-recovery-results.tsv` sidecar and then to the
Rorqual `structured-re-count-slope-cluster-recovery-results.tsv` sidecar when
primary-cluster recovery evidence has been banked. The cluster sidecar is used
for the board state while keeping the local provenance visible. It joins q4/q6/q8 rows to
`structured-re-high-q-status-audit.tsv` so high-q diagnostic, q4 gate-required,
q8 stability-blocked, and high-q planned states are visible separately from
inference readiness. It also joins all non-Gaussian rows to
`structured-re-nongaussian-status-audit.tsv` so count recovery-only, rejected,
and planned family-design rows are visible separately from Gaussian interval
claims. It also joins the remaining
Gaussian low-q rows to `structured-re-gaussian-lowq-status-audit.tsv` so ordinary baselines,
point/fixture gates, diagnostic-only rows, and rejection-contract rows no
longer collapse into a generic tried bucket. Four Gaussian q1 `mu` one-slope
rows also join to `structured-re-gaussian-mu-slope-smoke-status.tsv`, which
records local one-rep smoke evidence for `phylo()`, fixed-covariance
`spatial()`, `animal()`, and `relmat()`.
`structured-re-q2-slope-row-gate-synthesis.tsv` is the compact board-facing
gate table for the two remaining spatial/animal q2 `mu1+mu2` one-slope rows:
it summarizes the SR1000 default bias+t SD endpoints, the retained tail
imbalance, the unresolved correlation target, and the missing g=32
profile/Wald comparison while keeping both linked q-series rows
`interval_status = planned` and `coverage_status = planned`.
`structured-re-q2-slope-tranche128-spatial-replacement-rule-design.tsv` records
the no-compute Tranche 128 route-design decision for that q2 row-blocker lane:
spatial is selected first for a future T129 g=32 retained-denominator
profile/Wald/bias+t comparison contract, while animal fixed-8 remains held on
a separate calibration route. T128 writes no command, runs no model, creates no
retained denominator, authorizes no coverage, edits no support-cell status, and
does not promote `inference_ready`, `supported`, REML, AI-REML, bridge support,
or public support.
`structured-re-q2-slope-g32-profile-wald-smoke.tsv` records the first local
g=32 profile/Wald smoke for the same rows: spatial `mu1:x`, `mu2:x`, and
`mu1:x+mu2:x` had one finite Wald/profile replicate. The animal rows in that
sidecar are zero-count guard rows: the earlier animal direct-SD g=32 artifacts
were invalidated because the animal design is a fixed 8-pedigree and the
pre-guard runner recycled labels when `GSWEEP_N_GROUPS=32`.
`structured-re-q2-animal-correlation-holdout-diagnostic.tsv` separately records
the clean fixed-8 animal correlation holdout smoke: 5/5 fits, 5/5 `pdHess`, and
5/5 finite Wald/profile intervals.
`structured-re-q2-animal-correlation-pregrid-results.tsv` records the next
fixed-8 retained-denominator pregrid for the same animal correlation target:
150/150 finite Wald/profile intervals, but Wald coverage 0.8800 and profile
coverage 0.8867 with upper-tail miss imbalance and one retained
boundary/convergence flag. These sidecars do not promote the spatial or animal
q2 rows. `structured-re-q2-animal-correlation-miss-diagnostic.tsv` derives the
miss-shape blocker from the SR150 replicate TSV: 19 miss-or-boundary rows, 13
shared upper-tail misses, 4 shared lower-tail misses, 1 Wald-only upper miss,
and retained boundary seed 733197. It keeps the animal q2 row
`planned/planned` while Fisher/Rose choose whether a skew-aware correlation
interval or other animal-specific calibration is worth testing.
`structured-re-spatial-sigma-boundary-diagnostic.tsv` records the Nibi
current-source spatial `sigma:(Intercept)` diagnostic for
`qseries_spatial_q1_sigma_one_slope`: 443/475 finite Wald intervals, 32
boundary-small estimates, and a `do_not_promote` decision. It explains why the
row remains `admission_blocked` and does not change its `planned/planned`
interval or coverage status. Ten
non-Gaussian q1 count
`mu`
intercept rows also join to
`structured-re-count-intercept-recovery-results.tsv`, which records the local
80-rep recovery grid for the ten exact count-intercept rows and flags the
phylo NB2 intercept pdHess caveat plus the phylo Poisson and spatial NB2
near-zero lower-tail caveats, while keeping interval and coverage claims
unsupported/planned. The three caveated count-intercept rows also join to
`structured-re-count-intercept-caveat-diagnostic.tsv`, which breaks the same
local 80-rep recovery grid down by condition: phylo Poisson is near-zero
caveated in all four formal-shard conditions, phylo NB2 keeps pdHess caveats
in all four formal-shard conditions, and spatial NB2 separates two weak-signal
near-zero caveats from two stronger-signal recovery-ok conditions. They also
join to `structured-re-count-intercept-denominator-diagnostic.tsv`, which
records a 30-rep stronger-denominator diagnostic where all 12 condition rows
cleared locally with 30/30 fits, zero `pdHess = FALSE`, and zero near-zero SD
estimates. The same three rows now join to
`structured-re-count-intercept-topup-recovery-results.tsv`, an 80-seed x
4-condition stronger-denominator recovery top-up with 320/320 fit success,
zero `pdHess = FALSE`, and zero near-zero SD estimates per row. The ten
count-intercept and `phylo_interaction()` count `mu` recovery rows also join to
`structured-re-count-intercept-cluster-recovery-results.tsv`, a Rorqual SLURM
job 14918220 reproduction sidecar. After the stronger-denominator top-up
supersedes the three original weak-denominator caveats, the Rorqual sidecar
confirms six count-intercept/`phylo_interaction()` rows as
cluster-confirmed recovery-only while retaining the original NB2
`phylo_interaction()` 5/80 boundary-warning caveat as provenance. The NB2
`phylo_interaction()` row now also joins to
`structured-re-count-intercept-phylo-interaction-nb2-topup-recovery-results.tsv`,
which combines the original job 14918220 seed block with Rorqual top-up job
14936834 for a clean 160-seed recovery-only denominator.
`structured-re-nongaussian-recovery-rollup.tsv` is the widget-facing recovery
grade table for the 18 non-Gaussian Poisson/NB2 count `mu` rows: all 18 are
cluster-confirmed recovery-only rows, with zero current recovery caveats. The
fixed-covariance spatial NB2 count-slope row is now
recovery-confirmed only after the Rorqual job 14936279 top-up is combined with
the original array 14916938; it still has no interval, coverage,
`inference_ready`, or `supported` claim. The earlier smoke rungs remain
available in
`structured-re-count-intercept-recovery-smoke-status.tsv`, which records local
recovery-smoke evidence for the exact spatial, animal, and relmat
Poisson/NB2 intercept formulas, and
`structured-re-phylo-count-intercept-recovery-smoke-status.tsv`, which records
the exact phylo Poisson/NB2 formal-runner smoke, and
`structured-re-phylo-interaction-count-recovery-smoke-status.tsv`, which
records the exact pair-level `phylo_interaction()` Poisson/NB2 smoke. The support-cell denominator policy remains
the route/status contract; the evidence summary is the reader-facing
denominator for rows already promoted to `inference_ready`, the count recovery
summary is reader-facing recovery evidence only, and the high-q, non-Gaussian,
non-Gaussian recovery rollup, count-intercept recovery, count-intercept caveat,
count-intercept denominator, count-intercept top-up,
count-intercept cluster recovery,
count-intercept top-up cluster dispatch,
count-intercept smoke, phylo count-intercept smoke, phylo-interaction count
smoke, Gaussian low-q, Gaussian q1 `mu` smoke/admission/pregrid, and Gaussian
q1 `mu` boundary-profile audits are blocker ledgers only.

`structured-re-high-q-status-audit.tsv` records one audit row for each of the
24 q4/q6/q8 support cells. It assigns eight q4 fixture rows to
`high_q_gate_required`, five q8 or q8-shaped rows to
`q8_stability_blocked`, three ordinary/direct-SD high-q comparator rows to
`high_q_diagnostic`, and eight broader q6/q8 future-design rows to
`high_q_planned`. The tried q4 location, q4 all-four intercept, and
q8-shaped all-four one-slope rows now expose `interval_status =
diagnostic_only` in the 104-row table because row-specific interval diagnostic
sidecars exist, but coverage stays `planned`; no high-q row is
`inference_ready`, and the audit does not promote q4/q6/q8 calibrated
intervals, coverage, REML, AI-REML, bridge support, `supported`, or public
support.

The animal q8-shaped all-four row now points to the retained hidden TMB
partial-correlation hard-seed smoke report as its current high-q blocker. That
smoke is artifact-only: all three hard-seed fits converged, zero of three had
`pdHess = TRUE`, and all 24 direct-SD Wald rows were retained as
`not_run_pdhess_false`. It does not overwrite the public q4 animal admission
sidecar and does not authorize Totoro/FIIA, Nibi/Rorqual, DRAC, coverage, or a
status promotion.

`structured-re-gaussian-lowq-status-audit.tsv` records the 32 remaining
Gaussian low-q Q-Series cells after the exact `inference_ready`, sigma/q2
admission, high-q, and non-Gaussian rows are accounted for. It assigns three
ordinary comparator rows to `gaussian_baseline_comparator`, twenty-four
point/fixture rows to `gaussian_lowq_gate_required`, two ordinary diagnostic
rows to `gaussian_lowq_diagnostic`, and three q2-plus-q2 sigma rejection rows
to `gaussian_lowq_rejected`. Every linked row keeps its current fit, interval,
and coverage statuses; this audit does not promote interval+coverage
readiness, REML, AI-REML, structured covariance support, bridge support,
`supported`, or public support.

`structured-re-gaussian-mu-slope-smoke-status.tsv` records the first local
smoke rung for the four Gaussian q1 `mu` one-slope provider rows:
`qseries_phylo_q1_mu_one_slope`, `qseries_spatial_q1_mu_one_slope`,
`qseries_animal_q1_mu_one_slope`, and `qseries_relmat_q1_mu_one_slope`. The
smoke artifacts under
`docs/dev-log/simulation-artifacts/2026-06-28-gaussian-mu-slope-smoke-local/`
show two condition-replicates per provider, zero failures, 10/10 converged
summary rows, 10/10 `pdHess` rows, and 10/10 finite estimates. This is a local
fit/recovery smoke only: linked support cells keep `interval_status = planned`
and `coverage_status = planned`, and the sidecar does not promote
`inference_ready`, REML, AI-REML, bridge support, `supported`, or public
support. A replicated interval/coverage denominator grid remains the next gate.

`structured-re-gaussian-mu-slope-admission-audit.tsv` records the next local
interval-probe rung for those same four Gaussian q1 `mu` one-slope rows. The
artifacts under
`docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-probe-local/`
show two small default-`confint()` probes per provider for the direct
location-axis structured-SD targets. Phylo, fixed-covariance spatial, and
relmat each have 4/4 finite default intervals with no boundary Wald statuses
and therefore move to `mu_slope_pregrid_planned` in the widget. Animal has
3/4 finite default intervals because the intercept SD hit one boundary Wald
status, so the row stays `admission_blocked` until that endpoint is diagnosed.
`structured-re-gaussian-mu-slope-coverage-pregrid-dry-run.tsv` records the
retained-outcome SR150 pregrid manifest: seven clean target endpoints are
pregrid targets and the animal intercept endpoint is a visible holdout. These
sidecars still do not promote interval+coverage readiness, REML, AI-REML,
bridge support, `supported`, or public support.

`structured-re-gaussian-mu-slope-coverage-pregrid-results.tsv` records the
executed local SR150 retained-outcome pregrid for those exact Gaussian q1
`mu` one-slope rows. The current artifact was rerun after fixing the structured
SD group-count matcher so decomposed slope targets from `provider(1 + x |
group)` receive the documented location-axis t-width and `log(g/(g-1))` centre
shift. It remains negative admission evidence, not a promotion: all four rows
display as `mu_slope_pregrid_blocked`. The target summaries show 1200 retained
target-replicate rows across the four providers. Animal has only 122/150 usable
intervals for the eligible slope SD target and keeps the intercept SD as a
visible holdout; phylo has 291/300 usable intervals, retained coverage
0.940-0.947, and 3 lower / 5 upper misses; relmat has 297/300 usable intervals,
retained coverage 0.953-0.973, and 2 lower / 6 upper misses; spatial has
297/300 usable intervals, retained coverage 0.947-0.960, and 6 lower / 5 upper
misses. Linked support cells still keep `interval_status = planned` and
`coverage_status = planned`; the sidecar does not promote `inference_ready`,
REML, AI-REML, bridge support, `supported`, or public support.

`structured-re-gaussian-mu-slope-boundary-profile-diagnostic.tsv` records the
endpoint-profile follow-up for all 42 SR150 boundary/non-Wald rows from that
pregrid. All 42 rows refit with convergence and `pdHess = TRUE`; the
zero-lower-boundary endpoint fix rescued finite lower endpoints for many rows,
but the profile channel is still blocked by upper misses and remaining profile
failures. Animal has 25/27 finite profile intervals, 10 covered, 15 upper
misses, and two profile failures; phylo has 8/9 finite, one covered, seven
upper misses, and one profile failure; relmat has 2/3 finite, zero covered, two
upper misses, and one profile failure; spatial has 3/3 finite, zero covered,
and three upper misses. The four linked support cells therefore remain
`mu_slope_pregrid_blocked` with `interval_status = planned` and
`coverage_status = planned`. This sidecar is negative interval-geometry
evidence only; it does not promote top-up readiness, `inference_ready`, REML,
AI-REML, bridge support, `supported`, or public support.

`structured-re-gaussian-mu-slope-hybrid-boundary-audit.tsv` overlays those
repaired endpoint-profile boundary rows back onto the original SR150 pregrid
denominator. This routing audit splits the four rows without promoting any of
them: animal remains `mu_slope_pregrid_blocked` because the eligible slope
target has 132/150 covered, coverage 0.880, 147/150 usable intervals, and 15
upper misses; phylo, relmat, and spatial move to `topup_required` because their
hybrid SR150 coverage remains near nominal but MCSE is still above 0.01. Phylo
has 284/300 covered, 299/300 usable, coverage 0.947, and lower/upper misses
3/12; relmat has 289/300 covered, 299/300 usable, coverage 0.963, and misses
2/8; spatial has 286/300 covered, 300/300 usable, coverage 0.953, and misses
6/8. These are top-up candidates only; the support-cell TSV still keeps all
four rows at `interval_status = planned` and `coverage_status = planned`.

The top-up runner is now executable for those three candidate rows without
touching the visible dashboard. `tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R`
accepts generated non-overlapping seed slices, provider selection, and
`--write-dashboard=false`; a one-replicate smoke under
`docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-smoke-local/`
used seed 791151 for phylo, relmat, and spatial only. The boundary-profile
diagnostic runner also accepts `--source-replicates`, so future top-up
replicates can be passed through the same endpoint-profile repair channel. This
is executable-contract evidence only, not a support-cell promotion.

`structured-re-gaussian-mu-slope-hybrid-sr475-audit.tsv` records the completed
SR475 hybrid audit for the three top-up candidates. The stronger denominator
meets the MCSE gate but does not promote the rows: phylo has 913/950 covered,
MCSE 0.006277, and lower/upper misses 5/31; relmat has 926/950 covered, MCSE
0.005091, and misses 3/20; spatial has 912/950 covered, MCSE 0.006358, and
misses 15/22. Each provider still has one profile-failed row after combining
the original SR150 boundary profiles and the top-up boundary profiles. The
widget therefore shows phylo, relmat, and spatial as
`mcse_met_upper_tail_blocked`; all linked support cells remain
`interval_status = planned` and `coverage_status = planned`.

`structured-re-gaussian-mu-slope-interval-shape-diagnostic.tsv` splits that
SR475 result to the target level for phylo, relmat, and spatial q1 `mu`
one-slope rows. All six target rows meet the MCSE gate, but every target has
more upper misses than lower misses; the slope targets also concentrate many
upper misses in endpoint-profile boundary rows. The sidecar is blocker
evidence only and keeps all linked support cells at `planned/planned` until
Fisher/Rose accept a new interval-shape or calibration rule.

`structured-re-gaussian-mu-slope-rule-screen.tsv` records the next local
retained-artifact replay for those same q1 `mu` blockers. It screens 13
candidate interval variants: the current hybrid Wald/profile channel plus
upper-endpoint, log-width, and profile-boundary upper multipliers at 1.25,
1.50, 2.00, and 3.00. The modest variants leave target-level upper-tail
blockers, while the 3x variants that remove upper misses are labelled
large-ad-hoc screens, not smoke-ready interval rules. The sidecar is a
no-promotion rule screen: it does not change `confint()`, does not launch
Totoro/FIIA/DRAC work, and keeps the linked support cells at `planned/planned`
until Fisher/Rose/Noether accept a principled skew-aware or boundary-aware
interval route.

`structured-re-gaussian-mu-slope-split-calibration.tsv` records the stricter
split-sample replay for the same retained artifacts. The SR150/base slice
learns one log-upper endpoint offset for `mu:(Intercept)` and one for `mu:x`;
the SR325/top-up holdout then tests those frozen offsets without provider-
specific constants. The intercept targets pass the local screen-only holdout,
but all three slope targets fail at least one gate, so the sidecar remains
non-promotional and blocks Totoro/FIIA/DRAC smoke until Fisher/Rose/Noether
accept a replacement interval rule.

`structured-re-gaussian-mu-slope-review-decision.tsv` is the compact
four-row review overlay for the Gaussian q1 `mu` one-slope bucket. It freezes
phylo, spatial, animal, and relmat at `point_fit/planned/planned`, names the
animal SR150 hard block and the phylo/spatial/relmat SR475 upper-tail blockers,
and records the host rule: local derivation and retained-artifact replay first,
then one Totoro/FIIA smoke only after Fisher/Rose/Noether accept a named
replacement interval rule. Totoro, Nibi, Rorqual, Trillium, and DRAC top-ups
remain blocked until that smoke passes.

`structured-re-gaussian-mu-slope-tranche55-interval-rule-hold-decision.tsv`
records the Tranche 55 no-compute decision layer over the same q1 `mu`
one-slope bucket. The sidecar rejects current hybrid, ad hoc widening, and
split-calibration diagnostics as executable support routes, keeps every row at
`coverage_not_authorized` and `do_not_promote`, and leaves all linked support
cells at `point_fit/extractor_ready/fixture_parity/planned/planned/source`.
The next gate is a symbolic skew-aware or boundary-aware direct-SD interval
rule, local retained-artifact replay, Rose/Fisher/Noether/Grace review, and a
checkpoint before any Totoro/FIIA smoke, host top-up, coverage, or status edit.

`structured-re-gaussian-mu-slope-tranche56-symbolic-interval-rule-contract.tsv`
records that symbolic/replay gate before any replay code exists. It separates
the q1 `mu` intercept and slope direct-SD identities, names likelihood-shape
and boundary-bootstrap families as candidate families only, rejects post hoc
multiplier and split-calibration constants as executable rules, and defines the
retained-replay schema for a later local builder. Every row remains
`no_compute_in_tranche56`, `coverage_not_authorized`, and `do_not_promote`;
the next allowed move is a Tranche 57 local retained-artifact replay builder
with detail and summary outputs, still without support-cell status edits.

`structured-re-gaussian-mu-slope-tranche57-retained-replay-summary.tsv`
records that local retained-artifact replay layer. The paired artifact
directory contains a source index, 3,303-row detail table, mirrored summary,
and run log built from existing local q1 `mu` one-slope evidence only. Spatial
intercept and slope pass diagnostic-only current-hybrid gates, while phylo,
animal, relmat, and the tranche summary remain blocked by finite-interval,
coverage, MCSE, tail-balance, or overcoverage failures. Every row remains
`no_compute_in_tranche57`, `coverage_not_authorized`, and `do_not_promote`;
the next allowed move is Rose/Fisher/Noether/Grace review before any
candidate-rule equation, runner contract, host smoke, top-up, coverage, or
support-cell status edit.

`structured-re-gaussian-mu-slope-tranche58-retained-replay-review.tsv`
records that Rose/Fisher/Noether/Grace review layer. It has eight
provider-target rows plus a tranche summary and next-contract gate. Spatial
intercept and slope may feed only a later spatial-only candidate-rule equation
or runner contract with execution disabled by default; phylo, animal, and
relmat remain in rule-design hold. Every row remains
`no_compute_in_tranche58`, `coverage_not_authorized`, and `do_not_promote`.
The companion member-board rows in `member-discussions.tsv` make
Rose/Fisher/Noether/Grace blocking for any admission, compute, coverage, or
status claim.

`structured-re-gaussian-mu-slope-tranche59-spatial-candidate-contract.tsv`
records the spatial-only candidate contract allowed by Tranche 58. It documents
the q1 `mu` one-slope spatial direct-SD target identities, candidate
current-hybrid endpoint equation, retained-replay input boundary, future
host-runner contract requirements, admission gate, review gate, and unchanged
status boundary. It is not execution permission: every row stays
`disabled_by_default`, `no_compute_in_tranche59`,
`coverage_not_authorized`, and `do_not_promote`. The next gate is
Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche 60
spatial-only host-smoke contract, still without host commands, top-ups,
coverage, or support-cell status edits.

`structured-re-gaussian-mu-slope-tranche60-spatial-host-smoke-contract.tsv`
records that disabled spatial-only host-smoke contract. It documents the
future q1 `mu` one-slope spatial `n = 5` smoke shape, seed manifest, retained-
denominator rules, host-provenance artifacts, command gate, terminal-review
import boundary, and unchanged status boundary. No runner is written in this
tranche and no command is authorized: every row stays `disabled_by_default`,
`no_compute_in_tranche60`, `coverage_not_authorized`, and `do_not_promote`.
The next gate is Rose/Fisher/Noether/Grace review plus checkpoint before at
most a Tranche 61 spatial-only runner or execution packet, still with execution
disabled by default and without top-ups, coverage, or support-cell status edits.

`structured-re-gaussian-mu-slope-tranche61-spatial-execution-packet.tsv`
records that disabled spatial-only execution packet. It documents future
command templates, host packet boundaries for Totoro/FIIA and DRAC, seed and
artifact manifests, retained-denominator rules, approval-token requirements,
and the unchanged status boundary. No runner file is written in this tranche
and no command is authorized: every row stays `not_written_packet_only`,
`disabled_by_default`, `packet_banked_not_executed`,
`no_compute_in_tranche61`, `coverage_not_authorized`, and `do_not_promote`.
The next gate is Rose/Fisher/Noether/Grace review plus checkpoint before at
most a Tranche 62 spatial-only runner or dispatch gate, still with execution
disabled by default and without top-ups, coverage, denominator claims, or
support-cell status edits.

`structured-re-gaussian-mu-slope-tranche62-spatial-runner-gate.tsv` records
that dry-run-only spatial runner gate. It links back to the Tranche 61 packet,
tracks the T62 runner file, validates the fixed `n = 5` seed and target
manifest, and records the execute-path refusal. The runner prints a stdout TSV
manifest only; it does not fit a model, write dashboard results, run a host
command, submit Totoro/FIIA or DRAC work, or create denominator evidence. Every
row stays `dry_run_only`, `disabled_by_default`,
`dry_run_validated_not_executed`, `execute_path_refuses_in_tranche62`,
`no_compute_in_tranche62`, `coverage_not_authorized`, and `do_not_promote`.
The next gate is Rose/Fisher/Noether/Grace review plus checkpoint before at
most a Tranche 63 host preflight or dispatch approval, still without host
commands, top-ups, coverage, denominator claims, or support-cell status edits.

`structured-re-gaussian-mu-slope-tranche63-spatial-host-preflight.tsv` records
the spatial-only host-preflight gate after the T62 dry-run runner. It approves
only the future packet boundary: source SHA, run root, host label, output path,
sessionInfo, and host-separated denominator policy must be present before any
later command packet. T63 itself runs no host command, submits no Totoro/FIIA or
DRAC work, fits no model, creates no denominator, and moves no support-cell
status. Every row stays `preflight_approved_no_host_command`,
`run_root_required_not_created_in_tranche63`,
`command_packet_approved_not_executed`, `no_compute_in_tranche63`,
`coverage_not_authorized`, and `do_not_promote`. The next gate is
Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche 64
host command packet or host dry-run dispatch approval.

`structured-re-gaussian-mu-slope-tranche64-spatial-command-packet.tsv` records
the spatial-only command-packet gate after the T63 host preflight. It banks
template text for a future dry-run dispatch, including source SHA, run root,
host label, output path, sessionInfo, manifest/stdout/stderr paths, and
host-separated denominator policy. T64 itself runs no host command, submits no
Totoro/FIIA or DRAC work, fits no model, creates no denominator, and moves no
support-cell status. Every row stays `host_command_packet`,
`packet_banked_not_executed`, `no_compute_in_tranche64`,
`coverage_not_authorized`, and `do_not_promote`. The next gate is
Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche 65
host dry-run dispatch or source/run-root reachability probe.

`structured-re-gaussian-mu-slope-tranche65-spatial-host-dispatch-gate.tsv`
records the spatial-only host-dispatch gate after the T64 command packet. It
banks the dry-run dispatch and source/run-root reachability-probe requirements
for source SHA, run root, host label, output path, sessionInfo, and
host-separated denominator policy. T65 itself runs no host command, runs no
reachability command, verifies no source checkout, creates no run root, submits
no Totoro/FIIA or DRAC work, fits no model, creates no denominator, and moves
no support-cell status. Every row stays `host_probe_status =
not_executed_in_tranche65`, `dry_run_dispatch_planned_not_executed`,
`fit_execution_refused`, `no_compute_in_tranche65`,
`coverage_not_authorized`, and `do_not_promote`. The next gate is
Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche 66
host reachability/source-run-root dry-run probe.

`structured-re-gaussian-mu-slope-tranche66-spatial-host-reachability-probe.tsv`
records the spatial-only host reachability/source-run-root probe after the T65
host-dispatch gate. It records the safe read-only probe results: plain Totoro
SSH failed with auth exit 255, the existing Totoro ControlMaster socket reached
`totoro.biology.ualberta.ca`, `/home/snakagaw/drmtmb-qseries` and candidate
source paths were present, the candidate source paths did not provide current
source-checkout proof because git resolved to `/home/snakagaw` with no usable
HEAD, Rscript reported 4.5.3, the FIIA alias was unresolved, and DRAC was
deferred. T66 runs no model command, runs no smoke, fits no model, creates no
denominator, authorizes no top-up, records no coverage result, and moves no
support-cell status. Every row stays
`host_probe_only_no_model_compute_in_tranche66`,
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is
Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche 67
Totoro source-snapshot and qseries run-root staging contract.

`structured-re-gaussian-mu-slope-tranche67-spatial-source-staging-contract.tsv`
records the spatial-only Totoro source-snapshot and qseries run-root staging
contract after the T66 reachability probe. It banks only contract text for a
future staging proof: local source SHA
`56add7f04fab7bec57a42e56eaeb090dff491863`, dirty-state manifest
requirement, future Totoro source-snapshot path, future qseries run-root path,
stdout/stderr/manifest/sessionInfo paths, single-thread caps, host-label
policy, and host-separated denominator policy. T67 runs no host command,
copies no source, creates no run root, runs no model command, runs no smoke,
fits no model, creates no denominator, authorizes no top-up, records no
coverage result, and moves no support-cell status. Every row stays
`staging_contract_only_no_host_command_in_tranche67`,
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is
Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche 68
Totoro source-snapshot and qseries run-root staging dry-run proof.

`structured-re-gaussian-mu-slope-tranche68-spatial-source-staging-proof.tsv`
records the spatial-only Totoro source-snapshot and qseries run-root staging
proof after the T67 contract. It stages source SHA
`56add7f04fab7bec57a42e56eaeb090dff491863` with dirty source state to
`/home/snakagaw/codex/drmTMB-q1mu-slope-tranche68-source-56add7f0-20260702T103739Z`,
creates the qseries run root
`/home/snakagaw/drmtmb-qseries/q1-mu-slope-spatial-tranche68-20260702T103739Z`,
and imports `SOURCE-MANIFEST`, `SOURCE-PROVENANCE`, host provenance,
`sessionInfo`, source hashes, staging proof, and no-model-command proof under
`docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche68-spatial-source-staging-totoro/`.
T68 runs host staging commands but no model command, no smoke, no fit, no
top-up, no coverage grid, and no denominator-creating replicate. Every row
stays `source_runroot_staging_proof_only_no_model_compute_in_tranche68`,
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is
Rose/Fisher/Noether/Grace review plus checkpoint before at most a Tranche 69
spatial-only n=5 host-smoke execution decision from the exact T68 snapshot and
run root.

`structured-re-gaussian-mu-slope-tranche69-spatial-host-smoke-execution-decision.tsv`
records the spatial-only host-smoke execution-readiness decision after the T68
staging proof. Rose/Fisher/Noether/Grace accept the exact T68 snapshot and run
root as the only future provenance path, but the existing T62 runner is
dry-run-only and refuses `--execution-approved=true`; the refusal proof is
banked under
`docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche69-spatial-execution-readiness-local/`.
T69 runs no model command, no smoke, no fit, no top-up, no coverage grid, and
no denominator-creating replicate. Every row keeps
`do_not_execute_existing_t62_runner_write_t70_executable_runner_contract`,
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is a Tranche 70
executable-runner contract or fail-closed runner patch from the exact T68
snapshot and run root, with no Totoro command before Rose/Fisher/Noether/Grace
and validator review.

`structured-re-gaussian-mu-slope-tranche70-spatial-runner-contract.tsv`
records the spatial-only fail-closed executable-runner contract after the T69
execution-readiness decision. It banks
`tools/run-gaussian-mu-slope-tranche70-spatial-host-smoke.R` plus the shell
wrapper `tools/run-gaussian-mu-slope-tranche70-spatial-host-smoke.sh`, a
10-row dry-run manifest, and local refusal probes under
`docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche70-spatial-runner-contract-local/`.
Execution remains disabled in T70: the runner and wrapper both require
`DRMTMB_Q1MU_SLOPE_T70_EXECUTION_APPROVED=rose_fisher_noether_grace`, future
execution must load source from the exact T68 Totoro snapshot and write
artifacts under the exact T68 qseries run root, and `write-dashboard=false` is
mandatory. Every row keeps `fail_closed_executable_runner_contract_banked_no_execution`,
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Rose/Fisher/Noether/Grace
plus validator review and checkpoint before at most one T71 Totoro n5 command;
no coverage, denominator pooling, inference-ready claim, supported claim, or
support-cell status edit is allowed before that review.

`structured-re-gaussian-mu-slope-tranche71-spatial-host-smoke-load-blocker.tsv`
records the single permitted T71 Totoro command outcome after the T70 runner
contract. The command used the T70 wrapper and exact T68 source/run-root paths,
but `devtools::load_all()` failed before any fitted replicate with an invalid
ELF header for `drmTMB.so`. The imported run log, planned-seed manifest,
host-provenance TSV, command stderr/stdout/exitcode, and remote SHA-256 listing
live under
`docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche71-spatial-host-smoke-totoro/`.
T71 records no pdHess, Wald, profile, coverage, retained denominator, top-up,
or support-cell status evidence. Every row keeps `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is a
Tranche 72 load-blocker review/fix contract before any rerun, with
Rose/Fisher/Gauss/Noether/Grace plus validator review and checkpoint.

`structured-re-gaussian-mu-slope-tranche72-spatial-load-route-review.tsv`
records the load-route review after the T71 invalid-ELF blocker. Metadata-only
Totoro probes show that the exact T68 source snapshot contains macOS arm64
compiled objects at `src/drmTMB.so`, `src/drmTMB.o`, and `src/init.o` on a
Linux x86_64 host. The T70 runner payload and shell wrapper are present with
hashes, but AppleDouble `._*` transport noise is also present and must be
prevented on the next transfer. T72 runs no R load, model command, fit attempt,
retained replicate, denominator, coverage, or support-cell status edit. Every
row keeps `coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is a Tranche 73
clean-source restaging contract/proof before any rerun: exclude or remove
compiled artifacts, prevent AppleDouble/extended-header transport noise, keep
Totoro provenance separate, and require Rose/Fisher/Gauss/Noether/Grace plus
validator review and checkpoint.

`structured-re-gaussian-mu-slope-tranche73-spatial-clean-source-restaging-proof.tsv`
records the clean-source restaging proof after the T72 load-route review. It
uses the remembered Totoro ControlMaster route and `rsync` exclusion policy to
stage
`/home/snakagaw/codex/drmTMB-q1mu-slope-tranche73-clean-source-56add7f0-20260702T123451Z`
and
`/home/snakagaw/drmtmb-qseries/q1-mu-slope-spatial-tranche73-clean-source-20260702T123451Z`
with 16,889 manifest rows, SOURCE-MANIFEST hash
`b4a9c159bca67ed748c4004d0aa6385eb701f28aa38c623d696feacaf75fe52c`,
SOURCE-PROVENANCE hash
`7350b797aeddfb31fe0b9c0e9216625be9d233805375a289b72c6c832a78bd21`,
`compiled_artifact_count=0`, and `appledouble_count=0`. T73 runs no R package
load, `devtools::load_all()`, model command, fit attempt, retained replicate,
denominator, coverage, or support-cell status edit. Every row keeps
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 74: update or
review the runner paths before any smoke, because the existing T70 wrapper
still refuses source/run-root paths other than the exact T68 paths.

`structured-re-gaussian-mu-slope-tranche74-spatial-runner-path-gate.tsv`
records the T73-path fail-closed runner and wrapper gate after the T73
clean-source proof. It banks
`tools/run-gaussian-mu-slope-tranche74-spatial-host-smoke.R` and
`tools/run-gaussian-mu-slope-tranche74-spatial-host-smoke.sh`, both pinned to
the exact T73 source snapshot and qseries run root. The local dry-run manifest
contains only the 10 planned seed-target rows for seeds 861001-861005; the
direct execute probe exits 1 without the approval token, and the wrapper exits
64 without the same token. T74 runs no R package load, `devtools::load_all()`,
model command, fit attempt, retained replicate, denominator, coverage, or
support-cell status edit. Every row keeps `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is
Tranche 75: at most one Totoro n=5 smoke through the T74 wrapper, only after
Rose/Fisher/Gauss/Noether/Grace plus validator review and checkpoint.

`structured-re-gaussian-mu-slope-tranche75-spatial-host-smoke-terminal-review.tsv`
records that single Totoro n=5 smoke attempt through the T74 wrapper. The
remote runner loaded the exact T73 source snapshot and wrote the results,
summary, run-log, host-provenance, and hash artifacts, but all 10 target rows
failed before fitting because `phase18_assert_one_row_data_frame` was not
available to the sourced runner environment. The local exit-code capture also
failed after the remote outputs were written because `status` is read-only in
zsh; the run must not be repeated merely to repair that local artifact. T75
records no successful fit, no `pdHess`, no finite interval, no admission pass,
no retained denominator, no coverage result, and no support-cell status edit.
Every row keeps `coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 76:
source-map/runner-source review of why `inst/sim/R/sim_runner.R` was not
sourced before any rerun.

`structured-re-gaussian-mu-slope-tranche76-spatial-runner-source-map-review.tsv`
records that no-compute source-map review. It confirms that
`phase18_assert_one_row_data_frame` exists in `inst/sim/R/sim_runner.R`, while
the T74 runner source list loaded registry/utils/spatial DGP/summarise/run
files without sourcing `inst/sim/R/sim_runner.R`. T76 records no model command,
fit attempt, `pdHess`, interval evidence, retained denominator, coverage
result, top-up authorization, or support-cell status edit. Every row keeps
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 77: write a
reviewed fail-closed runner-source patch gate that sources
`inst/sim/R/sim_runner.R` before dependent spatial DGP/run files, then stop for
Rose/Fisher/Gauss/Noether/Grace plus validator review and checkpoint before any
rerun.

`structured-re-gaussian-mu-slope-tranche77-spatial-runner-source-patch-gate.tsv`
records that reviewed fail-closed patch gate. It banks the T77 runner and
wrapper for the exact T73 Totoro clean-source snapshot and qseries run root,
adds `inst/sim/R/sim_runner.R` before dependent spatial DGP/run files, emits
only a 10-row dry-run manifest, and records both direct-execute and shell-wrapper
refusal probes behind
`DRMTMB_Q1MU_SLOPE_T77_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace`.
T77 records no R package load, no `devtools::load_all()`, no model command, no
fit attempt, no `pdHess`, no Wald/profile interval evidence, no retained
denominator, no admission pass, no coverage result, no top-up authorization, and
no support-cell status edit. Every row keeps `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is
Tranche 78: write a reviewed smoke-approval gate for at most one Totoro `n = 5`
smoke through the T77 wrapper after Rose/Fisher/Gauss/Noether/Grace plus
validator review and checkpoint.

`structured-re-gaussian-mu-slope-tranche78-spatial-smoke-approval-gate.tsv`
records that reviewed smoke-approval gate. It imports the T77 fail-closed
runner-source patch gate, names the exact T73 source snapshot and qseries run
root, preserves the T75 provenance boundary, fixes the T78 host label and seeds,
and authorizes at most one future Totoro `n = 5` smoke through the T77 wrapper
after this sidecar validates and a recovery checkpoint is written. T78 itself
records no host command, R package load, `devtools::load_all()`, model command,
fit attempt, `pdHess`, Wald/profile interval evidence, retained denominator,
admission pass, coverage result, top-up authorization, or support-cell status
edit. Every row keeps `coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 79: dispatch
exactly one Totoro `n = 5` smoke through the T77 wrapper, or write a separate
DRAC source-checkout/run-root fallback gate before any DRAC command.

`structured-re-gaussian-mu-slope-tranche79-spatial-totoro-auth-blocker.tsv`
records the attempted T79 Totoro route as a reachability blocker, not as model
evidence. The SSH probe returned exit 255 with
`Permission denied (publickey,password)` before a remote shell was reached, so
the T77 wrapper did not dispatch and no source checkout proof, run-root proof,
R package load, `devtools::load_all()`, model command, fit attempt, `pdHess`,
Wald/profile interval evidence, retained denominator, admission pass, coverage
result, top-up authorization, or support-cell status edit exists. Every row
keeps `coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 80: write a
separate DRAC source-checkout/run-root fallback gate before any DRAC command,
or restore Totoro auth and write a fresh Totoro reachability gate before
another Totoro smoke attempt.

`structured-re-gaussian-mu-slope-tranche80-spatial-drac-fallback-gate.tsv`
banks that DRAC fallback gate without running a DRAC command. It fixes Rorqual
as the candidate DRAC route, names the required source checkout path, run root,
output path, host label, module/R/TMB provenance, copied T77 runner/wrapper
hashes, approval token, `write-dashboard=false`, and host-separated denominator
policy. T80 records no source checkout proof, run-root proof, package load,
`devtools::load_all()`, model command, fit attempt, `pdHess`, Wald/profile
interval evidence, retained denominator, admission pass, coverage result,
top-up authorization, or support-cell status edit. Every row keeps
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 81: only a
no-model DRAC Rorqual reachability/source-checkout/run-root proof after T80
validates and checkpoints; any DRAC smoke needs a later smoke-approval gate.

`structured-re-gaussian-mu-slope-tranche81-spatial-drac-rorqual-provenance-proof.tsv`
records that no-model DRAC proof. BatchMode SSH reached `rorqual2` as
`snakagaw` with exit code 0, but the required source checkout path, run root,
output directory, copied T77 runner, and copied T77 wrapper are missing. T81
therefore records reachability and missing-staging evidence only: no module
load, R package load, `devtools::load_all()`, model command, fit attempt,
`pdHess`, Wald/profile interval evidence, retained denominator, admission pass,
coverage result, top-up authorization, or support-cell status edit exists.
Every row keeps `coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 82: write a
DRAC Rorqual source/run-root staging contract before any source copy, run-root
creation, or smoke command.

`structured-re-gaussian-mu-slope-tranche82-spatial-drac-staging-contract.tsv`
banks that DRAC Rorqual source/run-root staging contract without running any
source copy, `mkdir`, remote command, module load, R package load,
`devtools::load_all()`, model command, fit attempt, `pdHess`, Wald/profile
interval, retained-denominator action, coverage, top-up, or support-cell status
edit. It fixes the source SHA
`56add7f04fab7bec57a42e56eaeb090dff491863`, the required `/project`
source/run-root/output paths, the T77 runner and wrapper hashes, the DRAC host
label, `write-dashboard=false`, and the host-separated denominator policy. Every
row keeps `coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 83 only: a
mkdir/source-copy staging proof that records host provenance, source manifest,
source provenance, remote runner/wrapper hashes, and no-model-command proof,
then stops before any smoke, module load, R command, fit, coverage, or status
movement.

`structured-re-gaussian-mu-slope-tranche83-spatial-drac-staging-proof.tsv`
banks that DRAC Rorqual staging proof. BatchMode SSH reached `rorqual2` as
`snakagaw`; `rsync` copied the source snapshot for SHA
`56add7f04fab7bec57a42e56eaeb090dff491863` to the required `/project` source
checkout, created or confirmed the run root and output directory, imported a
16,986-entry `SOURCE-MANIFEST`, recorded source provenance, host provenance,
remote T77 runner/wrapper hashes, and a no-model-command proof. T83 runs no
module load, R command, `Rscript`, `devtools::load_all()`, smoke command, model
fit, `pdHess`, Wald/profile interval, retained denominator, coverage, top-up,
or support-cell status edit. Every row keeps `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is
Tranche 84 only: a post-staging smoke-approval gate; no DRAC smoke may run from
T83 proof rows alone.

`structured-re-gaussian-lowq-row-selection.tsv` records the exact host gate for
the remaining Gaussian low-q point/fixture rows. It excludes the four q1 `mu`
one-slope rows already blocked by interval-shape evidence, keeps 23
point/fixture rows in scope, and marks nine rows as reviewed Nibi/Rorqual
substitute-smoke rows: four q1 `mu` intercept rows, four q2 intercept rows, and
the phylo q2-plus-q2 intercept row. Matched `mu+sigma`, direct-SD, and
`phylo_interaction()` rows remain local design holds, and sigma rows are split
by row-specific route evidence. The sidecar is
row-selection evidence only; it does not change interval or coverage statuses
and blocks Nibi/Rorqual/DRAC denominator work until a row-specific retained-
denominator or calibration contract is reviewed.
`structured-re-gaussian-lowq-sigma-intercept-denominator-contract.tsv` and
`structured-re-gaussian-lowq-sigma-intercept-pregrid-results.tsv` record the
animal/relmat q1 `sigma:(Intercept)` denominator review and imported Nibi
SR150 diagnostic blocker. Both rows keep `point_fit/planned/planned` because
the imported route had 150/150 fit/convergence/`pdHess`/`confint()` success but
only 115/150 usable raw-Wald intervals and 118/150 warning replicates. The
sidecars do not authorize top-up, `inference_ready`, or public support.
`structured-re-q-series-host-access-recheck.tsv` is the current host-access
sidecar: Totoro has interactive ControlMaster access for reviewed bounded smoke,
the `fiia` alias is unresolved, Nibi and Rorqual are reachable with qseries
project roots, Fir is reachable but still lacks the checked qseries run root,
and Trillium now has the qseries run root, R 4.4.0 after module load, and a
parse-ready source snapshot at dashboard build `r187`.
`structured-re-q-series-smoke-substitution-contract.tsv` is the Fisher/Rose/Grace
contract that permits Nibi/Rorqual only for exact q1/q2 n=5 substitute smoke;
Trillium still needs a row-specific command, seed manifest, module list, source
snapshot, and host-separated provenance before any Trillium output can be used
as evidence. The host ledger does not authorize denominator grids or promotion.

`structured-re-q2-intercept-interval-contract.tsv` turns the q2 intercept hold
into an exact 12-row interval-denominator contract: phylo, spatial, animal, and
relmat each get separate direct-SD targets for `mu1:(Intercept)` and
`mu2:(Intercept)`, plus a separate direct-correlation target for
`mu1:(Intercept)+mu2:(Intercept)`. It does not include the q2-plus-q2
location-and-scale row and does not promote any support-cell status. After the
local smoke below, Fisher/Rose signed off only the next tiny `n=5` smoke for
these 12 targets. The Nibi substitute-host smoke below has now been reviewed as
smoke-only evidence under `structured-re-q-series-smoke-substitution-contract.tsv`;
denominator work stays blocked until a target-specific retained-denominator or
calibration contract is reviewed.

`structured-re-q2-intercept-local-smoke.tsv` records the first local n=1 smoke
for that 12-row q2 intercept contract. It mirrors the summary under
`docs/dev-log/simulation-artifacts/2026-06-29-q2-intercept-local-smoke/` and
is backed by raw replicate rows, a seed manifest, `sessionInfo.txt`, and
`git-sha.txt`. The smoke verifies fit, convergence, `pdHess`, finite
default-Wald intervals, finite endpoint-profile intervals, and explicit
bootstrap-off accounting for all direct-SD and direct-correlation targets. It
records Wald and endpoint-profile lower/upper miss fields separately. It
is not coverage evidence and does not change `interval_status`,
`coverage_status`, `inference_ready`, `supported`, q2 slope, q2-plus-q2,
q4/q8, non-Gaussian, REML, AI-REML, bridge support, or public support claims.
Fisher/Rose sign-off is recorded for only the next `n=5` smoke. That smoke may
run on Totoro/FIIA if access is restored or on Nibi/Rorqual only under
`structured-re-q-series-smoke-substitution-contract.tsv`. The Nibi smoke has
now been reviewed as smoke-only evidence; denominator work stays blocked until a
target-specific retained-denominator or calibration contract is reviewed.

`structured-re-q2-intercept-nibi-smoke.tsv` records the Nibi `n=5`
substitute-host smoke for the 12 q2 intercept direct-SD and direct-correlation
targets. It mirrors the fetched artifact under
`docs/dev-log/simulation-artifacts/2026-06-30-q2-intercept-smoke-nibi-r44/`
with local artifact paths, SLURM host/runtime provenance, raw replicate rows, a
20-row seed manifest, source SHA manifest, local-state metadata, module list,
install logs, smoke logs, and exact-command metadata. All 12 target summaries
passed with 5/5 fit, convergence, `pdHess`, Wald-finite, and profile-finite
replicates. The sidecar promotes no support-cell status and leaves q2 intercept
denominator grids, q2 slope, q2-plus-q2, q4/q8, non-Gaussian rows, REML,
AI-REML, `inference_ready`, `supported`, bridge support, and public support
unclaimed. Its reviewed next gate is a target-specific retained-denominator or
calibration design; the Nibi smoke itself is not coverage evidence.

`structured-re-q2-plus-q2-intercept-nibi-smoke.tsv` records the Nibi n=5
substitute-host smoke for the phylo q2-plus-q2 intercept row. It mirrors the
fetched artifact under
`docs/dev-log/simulation-artifacts/2026-06-30-q2-plus-q2-intercept-smoke-nibi/`
with local artifact paths, host provenance, raw replicate rows, a five-seed
manifest, install logs, module metadata, and exact-command metadata. Five of
the six within-block direct targets passed; the `cor_sigma1_sigma2_intercept`
target retained one boundary profile failure at seed `823003` after the
run-local `rlang` dependency was installed. The sidecar promotes no
support-cell status and leaves q2-plus-q2 denominator grids, cross-block
correlations, q4/q8, non-Gaussian rows, REML, AI-REML, `inference_ready`,
`supported`, bridge support, and public support unclaimed.

`structured-re-gaussian-lowq-mu-intercept-dry-run.tsv` records the local n=2
screen for those four q1 `mu` intercept candidates. The run uses true
intercept-only Gaussian structured-RE DGPs for phylo, spatial, animal, and
relmat, and verifies fit, convergence, `pdHess`, and default Wald interval
extraction before any host smoke. Fisher/Rose later accepted only the next tiny
`n=5` smoke for these four rows. That smoke may run on Nibi/Rorqual only under
`structured-re-q-series-smoke-substitution-contract.tsv`; the Nibi substitute
smoke below has now passed review as smoke-only evidence. This row remains a
local dry-run only: it does not change interval, coverage, inference-readiness,
or support status, and Nibi/Rorqual/DRAC denominator work remains blocked until
a row-specific retained-denominator or calibration contract is reviewed.

`structured-re-gaussian-lowq-mu-intercept-smoke-contract.tsv` records the
Fisher/Rose-reviewed n=5 smoke contract for the same four rows. The accepted
channel is default `confint()` Wald extraction for direct `sd:mu:<provider>`
targets, with all attempted smoke replicates retained and the result treated as
fixture evidence rather than coverage evidence. The smoke has not been executed
from this sidecar: Totoro/FIIA remain valid if access is restored, and
Nibi/Rorqual are now valid only for exact n=5 substitute smoke under
`structured-re-q-series-smoke-substitution-contract.tsv`. The contract promotes
no row and does not authorize interval,
coverage, `inference_ready`, `supported`, sigma, q2, q4/q8, non-Gaussian, REML,
AI-REML, bridge, or public-support claims.

`structured-re-gaussian-lowq-mu-intercept-smoke-results.tsv` imports the local
n=5 smoke rehearsal for the same four q1 `mu` intercept rows. All four provider
rows have 5/5 fit, convergence, `pdHess`, `confint()`, usable finite Wald
intervals, and zero warning replicates, with 20 raw replicate rows and a seed
manifest mirrored under
`docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-intercept-smoke-local/`.
This is deliberately labelled `local_rehearsal`: it proves the smoke runner and
artifact path, not the reviewed Totoro/FIIA host gate. It promotes no row and
does not authorize Nibi/Rorqual/DRAC denominator work.

`structured-re-gaussian-lowq-mu-intercept-nibi-smoke-results.tsv` imports the
contract-bounded Nibi substitute-host n=5 smoke for the same four q1 `mu`
intercept rows. The fetched artifact is mirrored under
`docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-smoke-nibi/`
with the replicate TSV, seed manifest, session info, install/run logs, module
list, git SHA, and exact command. The seed manifest records
`structured-re-q-series-smoke-substitution-contract.tsv` and
`qseries_smoke_substitution_q1_mu_intercept`; all four provider rows are
`smoke_passed_fixture_only` and `do_not_promote`. This is substitute-host smoke
review material only: it does not authorize denominator work, interval or
coverage status, `inference_ready`, `supported`, sigma, q2, q4/q8,
non-Gaussian, REML, AI-REML, bridge, or public support claims. Its next gate is
a row-specific retained-denominator or calibration design that names interval
channel, MCSE target, one-sided misses, artifact retention, host, seeds, blocked
neighbours, and stop rules.

`structured-re-gaussian-lowq-mu-intercept-retained-denominator-contract.tsv`
records the reviewed next gate for those four q1 `mu` intercept rows. It
defines an SR150 retained-denominator pregrid using the default location-axis
direct-SD Wald channel, with all attempted fit, convergence, `pdHess`,
non-finite interval, and warning rows retained in the denominator. Fisher,
Rose, and Grace accepted this contract on 2026-06-30 for the first SR150 pregrid
dispatch on one primary DRAC host. The contract requires one-sided miss
reporting, raw replicate and seed artifacts, scheduler logs, `sessionInfo.txt`,
`git-sha.txt`, `module-list.txt`, and an after-task report. `MCSE <= 0.01` is a
top-up target before any inference claim, not an SR150 pass claim. It promotes
no row and does not authorize
`inference_ready`, `supported`, q1 sigma, matched `mu+sigma`, q2, q4/q8,
non-Gaussian interval, REML, AI-REML, bridge, or public-support claims.

`tools/run-structured-re-gaussian-lowq-mu-intercept-pregrid.R` and
`tools/slurm/q1-mu-intercept-pregrid-nibi.sbatch` are the reviewed execution
path for that contract. The wrapper defaults to SR150 and artifact-only output;
the SLURM script captures the source snapshot, module list, exact command,
session info, git SHA, scheduler logs, raw replicate TSV, summary TSV, seed
manifest, and `seff` when available. The runner refuses non-Nibi/Rorqual
pregrid host labels, refuses dashboard writes, and keeps all support cells at
`point_fit/planned/planned`.

`structured-re-gaussian-lowq-mu-intercept-pregrid-dispatch.tsv` records the
Nibi SR150 dispatch for those four rows. Job `16976756` failed before
simulation because the runner rejected the reviewed row-selection state; the
patched resubmission is job `16977254`, submitted from the source
snapshot rooted at
`/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q1-mu-sr150-77b634ed-r162`
and completed on Nibi. This sidecar is a job ledger only; it is not a status
promotion and still promotes no row.

`structured-re-gaussian-lowq-mu-intercept-pregrid-results.tsv` imports the
completed Nibi SR150 summary for the same four q1 `mu` intercept rows. All four
providers retained 150/150 attempted replicates with convergence, `pdHess`, and
finite intervals. Coverage was 0.9800 for phylo, animal, and relmat and 0.9733
for spatial; MCSE remains above the 0.01 top-up target for all four rows
(0.011431 or 0.013154), so the result is Fisher/Rose/Grace review and
SR475/SR1000 top-up evidence only. The linked support cells remain
`point_fit/planned/planned`.

`tools/run-structured-re-gaussian-lowq-mu-intercept-topup.R` and
`tools/slurm/q1-mu-intercept-topup-nibi.sbatch` define the parallel SR475
top-up route for the same four rows. The SLURM script runs one provider per
array task, defaults to seeds 151..475 (`n=325`) after the reviewed SR150
pregrid, uses per-shard R libraries to avoid concurrent install locks, and
writes artifacts only. It does not import results, update the widget, or promote
any support cell; the SR150 and shard outputs must be aggregated and reviewed
before any future status edit.

`structured-re-gaussian-lowq-mu-intercept-topup-dispatch.tsv` records the Nibi
array submission for that top-up route. It is a dispatch/import ledger only: job
`16978889` was submitted as a four-task array from the dirty source snapshot at
`/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q1-mu-sr475-topup-77b634ed-r163`.
Tasks 1-3 completed; task 4 (`relmat`) failed before the R runner with a CVMFS
R `INSTALL` input/output error and was resubmitted as relmat-only retry job
`16979505`, which completed and was imported. The sidecar keeps all rows at
`do_not_promote`; the completed shards feed the separate SR475 aggregate
sidecar, not a support-cell status edit.

`structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv` aggregates the
reviewed SR150 pregrid plus the completed SR325 top-up shards for the same four
q1 `mu` intercept rows. Each provider retains 475 attempted replicates. Phylo,
spatial, and relmat have 475/475 usable intervals and MCSE <= 0.01; animal has
473/475 usable intervals, so the finite-interval caveat is retained. Coverage
is 0.9832 (phylo), 0.9705 (spatial), 0.9747 (animal), and 0.9789 (relmat).
After Fisher/Grace review and Rose's corrected-surface audit, phylo, spatial,
and relmat are promoted to interval+coverage `inference_ready` with caveats
under the raw/default Wald direct-SD interval channel. Animal remains
`point_fit/planned/planned` and is blocked by two retained infinite-boundary
intervals at seeds `812407` and `812444`. The 104-row support-cell table points
the phylo, spatial, and relmat q1 `mu:(Intercept)` rows at this SR475 sidecar;
the animal row points at the separate hard-seed boundary-profile blocker
sidecar. The Gaussian low-q audit table retains only the animal blocker, while
the promoted rows join the eight-row inference-evidence summary. None of these
rows is `supported`, and the q1 `mu:(Intercept)` evidence does not promote q1
`sigma`, matched `mu+sigma`, q2, q4/q8, non-Gaussian intervals, REML, AI-REML,
broad bridge, or public-support claims.

`structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile.tsv` records
the local hard-seed replay for the two retained animal q1 `mu` seeds that made
the SR475 aggregate non-finite at the Wald boundary (`812407` and `812444`).
Both fits converge with `pdHess = TRUE`; endpoint profiles are finite 2/2 but
upper-miss the truth 2/2, while the `tmbprofile` fallback is finite 0/2. This
is a boundary/profile interval-shape blocker and a no-top-up decision for the
current route, not an MCSE problem and not new support-cell promotion evidence.

The imported SR475 artifact also carries the Nibi per-shard metadata under
`docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/metadata/`.
Mission control now requires each shard's exact command, module list, run log,
run status, session info, source manifest, and source label
`77b634ed-dirty-q1-mu-topup-r163`. The result-level `git-sha.txt` files mirror
that dirty-source label; they are not claimed as clean repository SHAs.

`tools/run-structured-re-gaussian-lowq-mu-intercept-smoke.R` is the
smoke-specific executable path for that contract. It wraps the local dry-run
harness in `--run-kind=smoke`, requires the reviewed n=5 replicate count, reads
the smoke-contract sidecar, writes `smoke_id`/`source_contract_id` artifact
fields, and refuses dashboard writes. Smoke artifacts must be reviewed and
imported through a validator-owned sidecar before they appear in the widget or
change any row status.

`structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv` records the
first local n=1 target smoke for the four q1 matched `mu+sigma` intercept rows.
Each provider retains three targets separately: direct `sd_mu`, direct
`sd_sigma`, and the same-group `mu`-to-`sigma` random-effect correlation. The
smoke fits and reaches `pdHess` for all four providers. Spatial, animal, and
relmat have 3/3 usable default-Wald target intervals in this seed; phylo is
diagnostic-only because the correlation target hits `wald_at_boundary`, with the
boundary warning retained in the raw target rows. The sidecar mirrors the
artifact directory under
`docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-sigma-intercept-smoke-local/`
and is guarded by mission control. It promotes no row, does not change
`interval_status` or `coverage_status`, and does not authorize Totoro/FIIA,
Nibi/Rorqual/DRAC, q2, q4/q8, non-Gaussian, REML, AI-REML, bridge, or public
support claims.

`structured-re-gaussian-lowq-sigma-intercept-route-contract.tsv` records the
route contract for the four q1 `sigma` intercept rows. Fisher accepts only the
route shape, and Gauss accepts the direct structured-SD target names:
`sd:sigma:phylo(1 | species)`, `sd:sigma:spatial(1 | site)`,
`sd:sigma:animal(1 | id)`, and `sd:sigma:relmat(1 | id)`. The first interval
channel is raw uncorrected log-SD Wald-z with `small_sample_df = "none"` and
`bias_correct = "none"`; endpoint profiles are diagnostic-only boundary
triage. The sidecar promotes no row, leaves the linked support cells at
`point_fit/planned/planned`, and keeps Totoro/FIIA, Nibi/Rorqual, denominator
work, and status edits blocked until a local n=5 direct sigma-SD smoke is run
and Fisher/Gauss/Rose review the retained rows.

`structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv` records that
local n=5 direct sigma-SD smoke. It mirrors the summary under
`docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-sigma-intercept-smoke-local/`
and is backed by 20 retained replicate rows, a seed manifest,
`sessionInfo.txt`, and `git-sha.txt`. All four providers fit, converged,
reported `pdHess = TRUE`, and used raw Wald intervals with
`small_sample_df = "none"` and `bias_correct = "none"`. Animal and relmat have
5/5 usable raw-Wald intervals in this local seed set; phylo retains one
`wald_at_boundary` row, and spatial retains three `wald_at_boundary` rows.
Endpoint profiles are diagnostic-only: failed or budget-limited profile rows
stay in the denominator-facing artifact instead of being dropped. The sidecar
promotes no row, does not change `interval_status` or `coverage_status`, and
does not authorize Totoro/FIIA, Nibi/Rorqual/DRAC, q2, q4/q8, non-Gaussian,
REML, AI-REML, bridge, or public support claims.

`structured-re-gaussian-lowq-sigma-intercept-denominator-contract.tsv` records
the reviewed pregrid contract for only the animal and relmat q1 `sigma`
intercept rows. Those two rows passed the local route-smoke shape with 5/5
usable raw-Wald intervals and no boundary/profile failures, but all warning
rows stay inside the evidence ledger. The contract pins raw log-SD Wald
intervals with `small_sample_df = "none"` and `bias_correct = "none"`,
endpoint profiles as diagnostics only, SR150 as the first Nibi pregrid, MCSE
`<= 0.01` as the top-up threshold, and all attempted
fit/convergence/`pdHess`/warning/boundary/profile rows retained. Fisher,
Gauss, and Rose accepted this warning ledger for pregrid execution only. It
promotes no row, leaves the linked support cells at `point_fit/planned/planned`,
and does not authorize `inference_ready`, `supported`, location-axis bias+t
correction, q1 `mu`, matched `mu+sigma`, q2, q4/q8, non-Gaussian intervals,
REML, AI-REML, bridge, completed DRAC denominator evidence, or public support
claims.

`structured-re-gaussian-lowq-sigma-intercept-pregrid-dispatch.tsv` records the
Nibi SR150 dispatch for those same animal and relmat q1 `sigma` intercept
rows. Job `16982141` failed before simulation because `devtools` was not
available in the isolated compute-node R library; retry job `16982458`
completed `0:0` after the runner fell back to the package installed by the
SLURM script. The dispatch table is still no-promotion evidence: it records
completed/imported reviewed-blocked artifacts, not an `interval_status`,
`coverage_status`, `inference_ready`, `supported`, q2, q4/q8, non-Gaussian,
REML, AI-REML, bridge, or public-support claim.

`structured-re-gaussian-lowq-sigma-intercept-pregrid-results.tsv` records the
imported Nibi SR150 result summary for the same two rows. Fit, convergence,
`pdHess`, and `confint()` all succeeded for 150/150 replicates per row, but
only 115/150 raw Wald intervals were usable and 118/150 replicates retained
warnings. The result is therefore `sr150_pregrid_completed_diagnostic_blocked_no_topup`:
Fisher/Gauss/Rose reviewed the finite-interval censoring, warning ledger,
profile failures, boundary rows, miss counts, and failure taxonomy; the sigma
interval route must be hardened or replaced before any SR475/SR1000 top-up or
status edit.

`structured-re-gaussian-lowq-sigma-profile-route-review.tsv` records the
route-hardening sequence for those animal and relmat q1 `sigma` intercept rows.
Raising the endpoint-profile budget from 12 to 48 rescued two of the three
selected profile failures per provider; the endpoint zero-boundary patch then
rescued the remaining selected seed and produced a local SR1000 profile-channel
aggregate. The current profile evidence is 1000/1000 finite intervals, coverage
0.9430 with MCSE 0.007332, and a lower/upper miss split of 12/45 for each row;
757/1000 profiles land on the lower SD boundary. The `tmbprofile` fallback is
still a negative smoke with 0/5 finite profile intervals. Fisher/Gauss/Rose now
treat this as profile-route blocker evidence, not a top-up candidate: support
cells stay `point_fit/planned/planned`, and no `interval_status`,
`coverage_status`, `inference_ready`, or `supported` claim is made from this
endpoint zero-boundary profile channel. The next q1 `sigma` move is a new
interval route or an explicit blocker decision, not more Totoro/DRAC replicas
on the current route.

`structured-re-gaussian-lowq-tranche49-q1-sigma-intercept-blocker-decision.tsv`
records that explicit blocker decision for the animal and relmat q1 `sigma`
intercept rows. The eight-row sidecar links back to the Nibi SR150 raw-Wald
pregrid and the local SR1000 endpoint zero-boundary profile replay. It blocks
the current profile route because the SR1000 profile channel is finite
1000/1000 but still has coverage 0.9430, MCSE 0.007332, 12 lower misses, 45
upper misses, and 757/1000 profiles on the lower SD boundary; the
`tmbprofile` fallback remains 0/5 finite. Every row keeps
`no_compute_in_tranche49`, `coverage_not_authorized`, and `do_not_promote`.
The linked support cells stay `point_fit`, `extractor_ready`,
`fixture_parity`, `planned`, `planned`, and `source`. The route can reopen only
through a new reviewed q1 `sigma` interval design; this sidecar authorizes no
Totoro, Nibi, Rorqual, Trillium, or DRAC top-up, no coverage job, and no
`inference_ready` or `supported` claim.

`structured-re-gaussian-lowq-tranche50-animal-q1-mu-intercept-blocker-decision.tsv`
records the corresponding no-compute blocker decision for the animal q1 `mu`
intercept boundary/profile route. The six-row sidecar links the Nibi SR475
aggregate to the local hard-seed replay: SR475 has 475/475 fits, convergence,
`pdHess`, and `confint`, but only 473/475 usable Wald intervals because seeds
812407 and 812444 are retained `wald_at_boundary` rows. The endpoint-profile
replay is finite 2/2, yet both finite intervals upper-miss truth 0.55; the
`tmbprofile` fallback is 0/2 finite with `nonfinite_interval`. This is
interval-shape blocker evidence, not an MCSE or top-up problem. Every Tranche
50 row keeps `no_compute_in_tranche50`, `coverage_not_authorized`, and
`do_not_promote`; the animal q1 `mu` support cell remains `point_fit`,
`extractor_ready`, `fixture_parity`, `planned`, `planned`, and `source`. The
route can reopen only through a new reviewed animal q1 `mu` interval design.

`structured-re-gaussian-lowq-tranche51-animal-q1-mu-interval-route-design.tsv`
records that reviewed interval-route design. The eight-row sidecar keeps the
current Wald route blocked by the SR475 retained `wald_at_boundary` rows,
keeps the endpoint-profile and `tmbprofile` paths blocked by the Tranche 50
replay, and parks split-calibration or adjusted-profile ideas until there is a
principled derivation. It selects a parametric-bootstrap direct-SD hard-seed
micro-smoke only as the next contract candidate. The q1 `mu` runner currently
lacks a bootstrap flag and refit-attempt accounting, so Tranche 51 writes no
runner patch, runs no bootstrap refits, sends no Totoro/FIIA/DRAC/Nibi/Rorqual
command, and makes no coverage, interval, `inference_ready`, or `supported`
claim. The animal q1 `mu` support cell remains `point_fit`, `extractor_ready`,
`fixture_parity`, `planned`, `planned`, and `source`; the next gate is a
Tranche 52 executable bootstrap micro-smoke contract, or an explicit rejection
of bootstrap after reviewer audit.

`structured-re-gaussian-lowq-tranche52-animal-q1-mu-bootstrap-smoke-contract.tsv`
closes that runner-gap contract without executing it. The eight-row sidecar
records the internal runner mode, approval-gated wrapper, exact animal hard
seeds 812407 and 812444, `bootstrap_R = 2`, artifact root, source runner,
source helper, reviewer stop rules, and SC396 member-board gate. The wrapper
and runner both refuse execution unless
`DRMTMB_Q1_MU_TRANCHE52_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace` is
set after Rose/Fisher/Gauss/Noether/Grace approval, and the run is
artifact-only with `--write-dashboard=false`. Tranche 52 executes no bootstrap
refits, sends no Totoro/FIIA/DRAC/Nibi/Rorqual/Trillium command, and makes no
bootstrap-finiteness, coverage, `inference_ready`, or `supported` claim. The
animal q1 `mu` support cell remains `point_fit`, `extractor_ready`,
`fixture_parity`, `planned`, `planned`, and `source`.

`structured-re-gaussian-lowq-tranche53-q1-sigma-interval-route-design.tsv`
records the next animal/relmat q1 `sigma` interval-route design after the
Tranche 49 endpoint-zero-boundary route blocker. The fourteen-row sidecar
keeps the raw Wald, endpoint-profile, `tmbprofile`, and split-tail routes
blocked or parked, then selects a parametric-bootstrap direct-`sigma`-SD
boundary-seed micro-smoke only as the next contract candidate. The q1 `sigma`
runner still lacks a bootstrap flag, exact seed-list mode, and refit
accounting, so Tranche 53 writes no runner patch, runs no bootstrap refits,
sends no Totoro/FIIA/DRAC/Nibi/Rorqual/Trillium command, and makes no
coverage, interval, `inference_ready`, or `supported` claim. The animal and
relmat q1 `sigma` support cells remain `point_fit`, `extractor_ready`,
`fixture_parity`, `planned`, `planned`, and `source`; the next gate is a
Tranche 54 executable bootstrap micro-smoke contract with an exact retained
boundary/failure seed manifest, or an explicit rejection of bootstrap after
reviewer audit.

`structured-re-gaussian-lowq-tranche54-q1-sigma-bootstrap-smoke-contract.tsv`
records the executable but approval-gated q1 `sigma` bootstrap micro-smoke
contract for the animal and relmat retained boundary seeds 914008 and 914011.
The q1 `sigma` runner now has `bootstrap_smoke` mode, exact `--seed-list`
handling, bootstrap refit accounting, and a sidecar command-row check; the
wrapper refuses without
`DRMTMB_Q1_SIGMA_TRANCHE54_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace`
and pins `bootstrap_R = 2`, `--profile=false`, and `--write-dashboard=false`.
Tranche 54 runs no bootstrap refits, sends no Totoro/FIIA/DRAC/Nibi/Rorqual/
Trillium command, pools no host denominator, and makes no bootstrap
finiteness, coverage, `inference_ready`, or `supported` claim. The animal and
relmat q1 `sigma` support cells remain `point_fit`, `extractor_ready`,
`fixture_parity`, `planned`, `planned`, and `source`; the next gate is an
explicit reviewer-approved artifact-only smoke followed by a separate Tranche
55 terminal review.

`structured-re-nongaussian-status-audit.tsv` records one audit row for each of
the 37 non-Gaussian Q-Series cells. It assigns eighteen Poisson/NB2 count
rows to `non_gaussian_recovery_only`, zero rows to
`non_gaussian_recovery_caveat`, eighteen intentional rejection rows to
`non_gaussian_rejected`, and one broader family-design row to
`non_gaussian_planned`. The table preserves the current
family distribution: 14 Poisson rows, 15 NB2 rows, two Student rows, two beta
rows, and one row each for Gamma, cumulative-logit, truncated-NB2, and the
non-count/extended-count future-design bucket. All linked rows keep
`interval_status = unsupported`; none of this audit promotes non-Gaussian
intervals, coverage, q2/q4 covariance, REML, AI-REML, bridge support,
`supported`, or public support.

`structured-re-count-intercept-recovery-results.tsv` records the local
80-rep recovery grid for the ten non-Gaussian q1 count `mu` intercept rows.
The artifacts under
`docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-grid-local/`
include raw replicate tables, summary tables, a seed manifest, run logs,
`sessionInfo.txt`, `git-sha.txt`, and local module information. Seven rows pass
the local recovery-only gate. Three rows remain in this local sidecar as
`non_gaussian_recovery_caveat`: `qseries_phylo_nbinom2_q1_mu_intercept`
because the run retained 13/320 `pdHess = FALSE` structured-SD rows, and
`qseries_phylo_poisson_q1_mu_intercept` plus
`qseries_spatial_nbinom2_q1_mu_intercept` because at least 25% of
structured-SD estimates fell below the near-zero threshold `1e-4`. This
sidecar is recovery evidence only: linked support cells keep
`interval_status = unsupported` and `coverage_status = planned`, and it does
not promote non-Gaussian intervals, coverage, q2/q4 covariance, REML,
AI-REML, bridge support, `supported`, or public support.

`structured-re-count-intercept-caveat-diagnostic.tsv` records 12 condition-level
diagnostic rows for the three caveated count-intercept recovery cells. It is
derived from the same local 80-rep recovery grid and explains the caveats
without changing any support-cell status: phylo Poisson has four
`condition_near_zero_caveat` rows; phylo NB2 has four
`condition_pdhess_caveat` rows; spatial NB2 has two weak-signal
`condition_near_zero_caveat` rows and two stronger-signal
`condition_recovery_ok` rows. This sidecar points the next gate toward a
targeted denominator diagnostic with stronger signal and/or larger count
denominators before public recovery wording; intervals and coverage remain
unsupported.

`structured-re-count-intercept-denominator-diagnostic.tsv` records the targeted
30-rep stronger-denominator follow-up for those same three caveated cells. It
uses larger phylo/spatial denominators, larger count means, and stronger
structured-SD signals than the caveated local 80-rep grid. All 12 condition
rows cleared locally: 30/30 fits, zero `pdHess = FALSE`, and zero structured-SD
estimates below `1e-4`. This makes the three row-level caveats
design-sensitive recovery blockers, not engine-wide non-Gaussian support
failures. It still does not promote intervals, coverage, `inference_ready`,
REML, AI-REML, bridge support, `supported`, or public support.

`structured-re-count-intercept-topup-recovery-results.tsv` records the
80-seed x four-condition stronger-denominator recovery top-up for the three
formerly caveated count-intercept cells, now reproduced by Rorqual SLURM job
`14897050`. The local artifacts under
`docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-topup-recovery-local/`
and the fetched Rorqual artifacts under
`docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-topup-recovery-rorqual/`
include raw replicate tables, condition manifests, summary tables, a seed
manifest, run logs, `sessionInfo.txt`, `git-sha.txt`, and module information.
All three rows pass the cluster-confirmed recovery-only top-up gate:
`qseries_phylo_poisson_q1_mu_intercept`,
`qseries_phylo_nbinom2_q1_mu_intercept`, and
`qseries_spatial_nbinom2_q1_mu_intercept` each have 320/320 fit success,
zero `pdHess = FALSE`, and zero structured-SD estimates below `1e-4`. This
sidecar supersedes the original weak-denominator caveat for widget row state
but preserves the original caveat sidecars as provenance. It does not promote
non-Gaussian intervals, coverage, q2/q4 covariance, REML, AI-REML, bridge
support, `supported`, or public support.

`structured-re-count-intercept-cluster-recovery-results.tsv` records the
Rorqual SLURM job `14918220` reproduction for all ten count-intercept and
`phylo_interaction()` non-Gaussian q1 count `mu` recovery rows. The fetched
artifacts under
`docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-rorqual/`
include raw replicate tables, summaries, seed manifests, run logs,
`sessionInfo.txt`, `git-sha.txt`, module lists, scheduler logs, and `seff`
metadata. Six rows are `cluster_confirmed_recovery_only`. Four original-grid
cluster caveats remain visible in this sidecar: the phylo Poisson, phylo NB2,
and spatial NB2 count-intercept rows are superseded by the stronger-denominator
top-up, while `qseries_phylo_interaction_nbinom2_q1_mu` remains a retained
historical cluster recovery caveat because the reproduction kept 5/80
boundary-warning rows. This sidecar is recovery evidence only; it does not promote
non-Gaussian intervals, coverage, q2/q4 covariance, REML, AI-REML, bridge
support, `supported`, or public support.

`structured-re-count-intercept-phylo-interaction-nb2-topup-recovery-results.tsv`
records the Rorqual SLURM job `14936834` top-up for
`qseries_phylo_interaction_nbinom2_q1_mu`. Combined with the original Rorqual
job `14918220`, the retained denominator is 160/160 fit_ok, 0 nonconverged,
0/160 `pdHess = FALSE`, 160/160 finite estimates, and 6/160 near-zero or
boundary-warning rows. The current widget recovery rollup therefore treats the
row as `cluster_confirmed_recovery_only`, while preserving the original 5/80
caveat as provenance. This is recovery-only evidence; it does not promote
non-Gaussian intervals, coverage, q2/q4 covariance, REML, AI-REML, bridge
support, `supported`, or public support.

`structured-re-nongaussian-recovery-rollup.tsv` records the separate Recovery
column used by the Q-Series widget for all 18 non-Gaussian Poisson/NB2 count
`mu` rows with recovery evidence. It deliberately separates recovery grade from
fit stability, interval status, and coverage status. All 18 rows are
`cluster_confirmed_recovery_only` after combining the Rorqual count-slope
array, the spatial NB2 count-slope top-up, the Rorqual count-intercept
reproduction, the stronger-denominator Rorqual count-intercept top-up, and the
Rorqual phylo-interaction NB2 top-up. No row is currently retained as
`cluster_recovery_caveat`. All linked support-cell rows keep
`interval_status = unsupported` and `coverage_status = planned`; the rollup
does not promote non-Gaussian intervals, coverage, q2/q4 covariance, REML,
AI-REML, bridge support, `supported`, or public support. Rollup-linked
support-cell source rows must also name recovery evidence in their
`claim_boundary` or `next_gate`; mission control rejects stale gates such as
"add recovery evidence" for rows where recovery is already banked.

`structured-re-count-intercept-topup-cluster-dispatch.tsv` records the
Rorqual confirmation job for those same three top-up rows. The current dispatch
row is `completed_passed` for SLURM job `14897050`, under
`/project/def-snakagaw/snakagaw/drmtmb-qseries/20260629-count-intercept-topup-rorqual-77b634eda91b/`.
It is cluster confirmation evidence for recovery-only row state: the runner and
summary both exited 0, and the fetched result TSV matches the local top-up
sidecar on the three target cells, retained denominators, `pdHess`, near-zero
counts, and recovery verdicts. It does not promote intervals, coverage,
`inference_ready`, REML, AI-REML, q2/q4 covariance, bridge support,
`supported`, or public support.

`structured-re-count-intercept-recovery-smoke-status.tsv` records the first
local smoke rung for six exact non-Gaussian q1 structured `mu` intercept
rows: spatial, animal, and relmat Poisson/NB2. The artifacts under
`docs/dev-log/simulation-artifacts/2026-06-28-count-intercept-recovery-smoke-local/`
show 24 total condition-replicates, zero failures, and for each of the six
cell subsets, 4/4 structured-SD rows with converged fits, `pdHess = TRUE`, and
finite estimates. The spatial NB2 subset is explicitly flagged because 3/4
structured-SD rows have lower-boundary warnings. This sidecar does not cover
the phylo count intercept rows, has been superseded for dashboard row state by
the 80-rep count-intercept recovery grid, and does not promote non-Gaussian intervals, coverage,
q2/q4 covariance, REML, AI-REML, bridge support, `supported`, or public
support.

`structured-re-phylo-count-intercept-recovery-smoke-status.tsv` records the
first local smoke rung for the two exact phylo non-Gaussian q1 structured `mu`
intercept rows: Poisson and NB2. The artifacts under
`docs/dev-log/simulation-artifacts/2026-06-28-phylo-count-intercept-recovery-smoke-local/`
come from the formal `poisson_phylo_q1_formal` and
`nbinom2_phylo_q1_formal` runners, restricted to shard 7 so the four
condition-replicates per family have nonzero `sd_phylo = 0.25`. Each family
has zero failures and 4/4 phylo SD rows with converged fits, `pdHess = TRUE`,
and finite estimates. This sidecar does not replace a replicated recovery
grid, does not promote non-Gaussian intervals, coverage, q2/q4 covariance,
REML, AI-REML, bridge support, `supported`, or public support.

`structured-re-phylo-interaction-count-recovery-smoke-status.tsv` records the
first local smoke rung for the two exact `phylo_interaction()` non-Gaussian q1
structured `mu` rows: Poisson and NB2. The artifacts under
`docs/dev-log/simulation-artifacts/2026-06-28-phylo-interaction-count-recovery-smoke-local/`
come from a reproducible local script with four replicate seeds, true pair SD
0.45, and the exact
`phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)`
formula in `mu`. Each family has zero failures and 4/4 pair-level SD rows with
converged fits, `pdHess = TRUE`, finite estimates, and ready profile targets.
This sidecar does not replace a replicated recovery grid, does not promote
non-Gaussian intervals, coverage, q2/q4 covariance, REML, AI-REML, bridge
support, additive partner-main support, structured-sigma support, `supported`,
or public support.

The same q-series support-cell table now includes provider-specific Poisson
and NB2 q1 `mu` one-slope rows for `phylo()`, fixed-covariance `spatial()`,
`animal()`, and `relmat()`. Those rows cite
`tests/testthat/test-count-structured-mu.R` as native TMB ML/Laplace point-fit
and extractor evidence for the exact unlabelled intercept-plus-one-slope count
cells, and the row text now also records the banked 80-rep local recovery grid.
That recovery grid is convergence and SD bias/RMSE evidence only. Bridge
support, intervals, coverage, REML, AI-REML, q2/q4 count covariance,
zero-inflated structured effects, labelled count covariance, pure or multiple
count slopes, and structured count scale routes remain planned or unsupported
unless an exact future support-cell row says otherwise.

`structured-re-count-slope-recovery-results.tsv` records the local 80-rep
recovery grid for the eight Poisson/NB2 q1 `mu` one-slope count cells. It
records fit_ok counts, nonconvergence, `pdHess` false counts, finite estimate
counts, SD bias/RMSE, and a recovery-only verdict. The Q-Series board renders
these rows with the more specific `non_gaussian_recovery_only` row state from
`structured-re-nongaussian-status-audit.tsv`; the recovery metrics still come
from this recovery-results sidecar. They have point and recovery evidence, but
`interval_status = unsupported`, `coverage_status = planned`, and no
`supported` claim. The fixed-covariance spatial NB2 row is not `pdHess` clean:
it records 80/80 fit_ok and finite estimates, but 2/80 `pdHess = FALSE`, so
the row carries a Hessian caveat and remains recovery-only.

`structured-re-count-slope-cluster-recovery-results.tsv` records the Rorqual
SLURM array 14916938 reproduction for the same eight Poisson/NB2 q1 `mu`
one-slope count cells. Seven rows are `cluster_confirmed_recovery_only`; the
fixed-covariance spatial NB2 row remains a historical `cluster_recovery_caveat`
inside this sidecar because the original array had 2/80 `pdHess = FALSE`. The
fetched artifacts live under
`docs/dev-log/simulation-artifacts/2026-06-29-count-slope-recovery-rorqual`.

`structured-re-count-slope-spatial-nb2-topup-recovery-results.tsv` records the
Rorqual SLURM job 14936279 top-up for that fixed-covariance spatial NB2
count-slope row. The top-up has 80/80 fit_ok, 0 nonconverged rows, 0/80
`pdHess = FALSE`, and 80/80 finite estimates. Combined with the original
array, the retained denominator is 160/160 fit_ok, 0 nonconverged, 2/160
`pdHess = FALSE`, and 160/160 finite estimates, so the widget recovery rollup
now treats the row as `cluster_confirmed_recovery_only`. This is still
recovery-only evidence; intervals, coverage, `inference_ready`, `supported`,
REML, AI-REML, q2/q4 count covariance, and public support remain unpromoted.

`structured-re-count-slope-fixture-recovery-contract.tsv` records the next
evidence contract for those eight ordinary count one-slope cells. It ties each
Poisson/NB2 provider row to the existing native TMB ML/Laplace point-fit and
extractor evidence, while the current 80-rep recovery metrics now live in
`structured-re-count-slope-recovery-results.tsv`. The native deterministic
fixture step is now `native_fixture_banked`; this is not bridge parity. It does
not promote bridge support, intervals, coverage, REML, AI-REML, q2/q4 count
covariance, public support, labelled or multiple count slopes, structured count
scale routes, or zero-inflated structured effects.

`structured-re-count-slope-native-fixture-status.tsv` records the eight exact
native-only deterministic fixture rows behind that status. Each row cites
`tests/testthat/test-count-structured-mu.R`; all rows remain ML/Laplace
native TMB point/extractor fixtures only, with bridge parity, calibrated
recovery, intervals, coverage, REML, AI-REML, q2/q4 count covariance, and
public support still separate gates.

`structured-re-count-slope-recovery-runner-contract.tsv` records the dry-run
runner contract for the same eight ordinary count one-slope cells. It is a
selected manifest and run-log contract only; it is superseded as recovery
evidence by the local 80-rep recovery-results sidecar, and no Totoro or DRAC job
has been submitted. The rows are not coverage-evaluable denominator evidence.
The contract preserves fit-error, nonconvergence, `pdHess`, boundary-warning,
nonfinite-estimate, seed/provider, and scheduler-exit retention requirements
before any public-support wording can move.

`structured-re-count-slope-recovery-dispatch-review.tsv` records the
provider/family dispatch preflight for those runner rows. It names shard
scopes, output namespaces, no-overwrite rules, seed partition locking, resume
policy, and retained failure accounting, while keeping
`submission_status = not_submitted`, `compute_status = not_executed`, and
`dispatch_gate_status = ready_for_human_review`. It is not human approval and
not execution evidence.

`structured-re-count-slope-recovery-shard-pack-contract.tsv` records the
next dry-run shard-pack contract for those eight provider/family cells. The
companion artifact directory contains an index plus one target manifest and
one run log per shard, so a later approved Totoro or DRAC execution can use
private provider/family files without overwriting the all-target runner
contract. Every row remains `submission_status = not_submitted`,
`compute_status = not_executed`, `recovery_status = shard_pack_only`, and
`coverage_evaluable = FALSE`; this is not recovery, coverage, interval,
bridge, REML, AI-REML, public-support, or broad bridge evidence.

`structured-re-count-slope-phylo-poisson-local-micro-shard.tsv` records the
first local execution smoke row for the ordinary count one-slope recovery
lane. It is intentionally only the `phylo()` plus `poisson()` q1 `mu`
one-slope cell, four seeds, and the local Codex source-install route. The row
links to the per-replicate, summary, and run-log artifacts and keeps
`coverage_evaluable = FALSE`, `denominator_status = not_coverage_evidence`,
bridge support, intervals, coverage, REML, AI-REML, public support, and
Totoro/DRAC execution closed.

`structured-re-count-slope-phylo-nbinom2-local-micro-shard.tsv` records the
matching local execution smoke row for the exact `phylo()` plus `nbinom2()` q1
`mu` one-slope cell. The NB2 row keeps `sigma` as fixed-effect overdispersion
only, links to its own per-replicate, summary, and run-log artifacts, and keeps
`coverage_evaluable = FALSE`, `denominator_status = not_coverage_evidence`,
bridge support, intervals, coverage, REML, AI-REML, structured count `sigma`,
public support, and Totoro/DRAC execution closed.

`structured-re-count-slope-spatial-poisson-local-micro-shard.tsv` records the
matching local execution smoke row for the exact fixed-covariance `spatial()`
plus `poisson()` q1 `mu` one-slope cell. The row links to its own
per-replicate, summary, and run-log artifacts and keeps
`coverage_evaluable = FALSE`, `denominator_status = not_coverage_evidence`,
range-estimating spatial support, bridge support, intervals, coverage, REML,
AI-REML, structured count `sigma`, labelled or multiple count slopes,
zero-inflated structure, public support, and Totoro/DRAC execution closed.

`structured-re-count-slope-spatial-nbinom2-local-micro-shard.tsv` records the
matching local execution smoke row for the exact fixed-covariance `spatial()`
plus `nbinom2()` q1 `mu` one-slope cell. The NB2 row keeps `sigma` as
fixed-effect overdispersion only, links to its own per-replicate, summary, and
run-log artifacts, and keeps `coverage_evaluable = FALSE`,
`denominator_status = not_coverage_evidence`, range-estimating spatial
support, bridge support, intervals, coverage, REML, AI-REML, structured count
`sigma`, labelled or multiple count slopes, zero-inflated structure, public
support, and Totoro/DRAC execution closed.

`structured-re-count-slope-animal-poisson-local-micro-shard.tsv` records the
matching local execution smoke row for the exact animal A/Ainv `animal()` plus
`poisson()` q1 `mu` one-slope cell fit through `Ainv = Q`. The row links to its
own per-replicate, summary, and run-log artifacts and keeps
`coverage_evaluable = FALSE`, `denominator_status = not_coverage_evidence`,
pedigree/Ainv bridge marshalling, bridge support, intervals, coverage, REML,
AI-REML, structured count `sigma`, labelled or multiple count slopes,
zero-inflated structure, public support, and Totoro/DRAC execution closed.

`structured-re-count-slope-animal-nbinom2-local-micro-shard.tsv` records the
matching local execution smoke row for the exact animal A/Ainv `animal()` plus
`nbinom2()` q1 `mu` one-slope cell fit through `Ainv = Q`. The NB2 row keeps
`sigma` as fixed-effect overdispersion only, links to its own per-replicate,
summary, and run-log artifacts, and keeps `coverage_evaluable = FALSE`,
`denominator_status = not_coverage_evidence`, pedigree/Ainv bridge marshalling,
bridge support, intervals, coverage, REML, AI-REML, structured count `sigma`,
labelled or multiple count slopes, zero-inflated structure, public support, and
Totoro/DRAC execution closed.

`structured-re-count-slope-relmat-poisson-local-micro-shard.tsv` records the
matching local execution smoke row for the exact relmat K/Q `relmat()` plus
`poisson()` q1 `mu` one-slope cell fit through `Q = Q`. The row links to its
own per-replicate, summary, and run-log artifacts and keeps
`coverage_evaluable = FALSE`, `denominator_status = not_coverage_evidence`, Q
bridge marshalling, bridge support, intervals, coverage, REML, AI-REML,
structured count `sigma`, labelled or multiple count slopes, zero-inflated
structure, public support, and Totoro/DRAC execution closed.

`structured-re-count-slope-relmat-nbinom2-local-micro-shard.tsv` records the
matching local execution smoke row for the exact relmat K/Q `relmat()` plus
`nbinom2()` q1 `mu` one-slope cell fit through `Q = Q`. The NB2 row keeps
`sigma` as fixed-effect overdispersion only, links to its own per-replicate,
summary, and run-log artifacts, and keeps `coverage_evaluable = FALSE`,
`denominator_status = not_coverage_evidence`, Q bridge marshalling, bridge
support, intervals, coverage, REML, AI-REML, structured count `sigma`,
labelled or multiple count slopes, zero-inflated structure, public support,
and Totoro/DRAC execution closed.

`structured-re-count-slope-sigma-one-slope-rejection-contract.tsv` records the
exact pre-optimization rejection contract for count NB2 `sigma` one-slope
structured-scale cells in `phylo()`, fixed-covariance `spatial()`, A-matrix
`animal()`, and K/Q `relmat()`. The engine rejects structured count scale
routes (`Structured non-Gaussian paths`), so each linked
`qseries_*_nbinom2_q1_sigma_one_slope_rejected` cell stays `unsupported`. This
answers the count half-cell question: the banked count `mu` one-slope cells do
not imply count `sigma` one-slope support, and Poisson has no `sigma`
parameter. The contract does not promote parser-ready, point-fit, bridge,
interval, coverage, REML, AI-REML, public support, or q4/q8 status.

`structured-re-nongaussian-structured-family-rejection-contract.tsv` records
the active pre-optimization rejection contract for the remaining
structured-family routes the engine still rejects at the formula gate:
`cumulative_logit()` `mu` with `phylo()` and `truncated_nbinom2()` `hu` with
`relmat()`. The previously banked beta, Gamma, Student `mu`, Student `nu`,
Poisson `zi`, beta `sigma`, and NB2 `sigma` one-slope rows now live in the
support cells and the local first-four smoke as local fit-only recovery rows.
Those moved rows still do not promote parser-ready broad support, bridge,
interval, coverage, REML, AI-REML, public support, or q4/q8 status.

`structured-re-count-structured-mu-rejection-contract.tsv` records the exact
pre-optimization rejection contract for six structured count `mu` routes the
engine rejects beyond the banked one-slope cells: non-canonical (slope-only)
coefficient, labelled `q=2` covariance, structured-plus-ordinary combination,
zero-inflated structured (Poisson and NB2), and simultaneous structured effect
types. Each cell is rejected at the formula gate with its own message, backed by
`tests/testthat/test-count-structured-mu.R`, and stays `unsupported`. It promotes
no parser-ready, point-fit, bridge, interval, coverage, REML, AI-REML, public
support, or q4/q8 status.

For `phylo_interaction()`, the q-series support-cell table keeps Poisson and
NB2 q1 `mu` intercept support as separate family-specific rows backed by
`tests/testthat/test-phylo-interaction.R`. Those rows remain native TMB
ML/Laplace point-fit and extractor evidence for a single pair-level Kronecker
field. They do not promote bridge support, intervals, coverage, REML,
AI-REML, q2/q4 endpoint covariance, slopes, additive partner-main effects,
binary incidence, structured count scale routes, or public support.

`structured-re-q2-plus-q2-sigma-rejection-contract.tsv` records the exact
pre-optimization rejection evidence for the fixed-covariance `spatial()`,
A-matrix `animal()`, and `relmat()` scale-only `sigma1+sigma2` q2-plus-q2
sibling cells. It keeps those rows `unsupported` and prevents q2 location
fixtures, q4 all-four rows, or K/Q parity from being read as scale-only
parser-ready, point-fit, bridge, interval, coverage, REML, AI-REML, public
support, q4, or q8 evidence.

`structured-re-balance-100-slices.tsv` records the structured random-effect
balance arc. SR001-SR060 bank the corrected scope, native ML q1/q2/q4, slope,
and native exact-Gaussian REML status. SR061-SR090 bank inference, bridge
readiness, and documentation status where evidence exists, while blocking
coverage pilots and bridge parity rows that are not yet proven. SR091-SR100
record closeout gates for live Ayumi issue access, Bayesian-result comparison,
reply approval, posting, final validation, commit approval, and recovery
checkpointing.

`structured-re-finish-100-slices.tsv` records the next structured random-effect
finish arc. SR101-SR110 bank the carryover scope, evidence ladder, and
validator ownership for the second 100-slice tranche. SR111-SR140 focus on q1,
q2, and q4 bridge parity, where a row can be promoted only after native R/TMB,
direct DRM.jl, and R-via-Julia evidence agree on the same target. SR141-SR150
scale pilot coverage accounting into calibrated simulation design. SR151-SR180
cover native REML boundaries, structured-type gaps, R docs, and user-facing
error/status text. SR181-SR190 synchronize direct DRM.jl evidence and
gate-vs-engine checks. SR191-SR200 keep the Ayumi reply, posting, commit, and
handoff gates explicit.

`structured-re-q4-reml-requested-effective-audit.tsv` records the SR135
requested-versus-effective estimator audit for q4. It separates native TMB q4
ML, unsupported native TMB q4 REML, direct DRM.jl q4 Patterson-Thompson REML,
experimental R-via-Julia q4 Patterson-Thompson REML, and the unsupported
HSquared AI-REML transfer boundary. It is an audit table only: no native q4
REML, HSquared AI-REML, public bridge support, interval reliability, or interval
coverage claim is promoted by those rows.

`structured-re-q4-calibrated-parity-probe.tsv` records the calibrated q4
same-fixture probes that found native-converged 32-tip candidates after the
direct DRM.jl log-Cholesky label-order fix. It separates direct DRM.jl to
R-wrapper reconstruction coverage and calibrated q4 point parity from interval
reliability, interval coverage, q4 REML, HSquared AI-REML, and public bridge
support.

`structured-re-r-docs-sync-status.tsv` records the SR171-SR180 documentation
and error-message synchronization gate. It points each row to source files and
exact scan commands for formula grammar, known limitations, README/pkgdown
status, rejection-message wording, examples/vignettes, forbidden-claim scans,
and the docs acceptance gate. These rows bank source-truth hygiene only; they
do not promote R-via-Julia bridge support, q4 REML, HSquared AI-REML,
non-Gaussian REML, public optimizer controls, or interval coverage.

`structured-re-julia-twin-status.tsv` records the SR181-SR190 Julia twin sync
gate. It names the active drmTMB and DRM.jl branches, full SHAs, dirty-state
lists, focused Julia q2/q4 direct-export test results, R bridge/parity test
results, Julia/R/JuliaCall versions, local issue/source-map status, and the twin
acceptance gate. These rows are provenance and guard evidence only. The q2
phylo result is one complete-response exact-Gaussian ML fixture; the file does
not promote broad q2 bridge support, q2 REML, q4 REML, AI-REML, interval
coverage, public bridge support, or release readiness.

`structured-re-ayumi-closeout-status.tsv` records the SR191-SR200 closeout
gates. SR191-SR198 stay blocked until current Ayumi issue text, exact reply
text, maintainer approval, public posting, posted URL evidence, and explicit
commit approval exist. SR199-SR200 bank only the recovery checkpoint and next
start point. This file deliberately records that no Ayumi reply, public issue
comment, commit, bridge promotion, REML promotion, AI-REML claim, or interval
coverage claim was made.

`member-roster.tsv`, `member-discussions.tsv`, and
`member-wave-assignments.tsv` are the mission-control member board. They turn
the standing Ada/Rose/Grace/etc. review perspectives into validator-owned
dashboard state: what each member can do, which waves they own, what they
should improve, which claims they sign off, and what discussion record blocks
or accepts a row transition.

`structured-re-conversion-200-slices.tsv` records the SC201-SC400 conversion
ledger. Its rows do not promote package behaviour by themselves; they track
the next 200 execution slices needed to move scoped `partial` or `planned`
structured random-effect rows toward `covered` matrix status or `banked`
slice-ledger status.

`structured-re-executable-evidence.tsv` records the first executable guards
added after the conversion ledger: q1/q2/q4 contract tests, the ADEMP
scaffold tests, and tiny diagnostic-pilot artifact checks. These rows bank
testable boundaries, runner/accounting scaffolds, and pilot failure accounting
only. They do not promote bridge support, native q2/q4 REML, q4 interval
coverage, non-Gaussian REML, or any Ayumi-facing reply text.

`structured-re-status-vocabulary.tsv` defines the row-level meaning of
`covered`, `partial`, `planned`, `banked`, `blocked`, `experimental`, and
`unsupported` for this structured random-effect arc. It keeps `covered` scoped
to an exact matrix/status row and keeps `banked` scoped to a slice-ledger row
with evidence.

`structured-re-q1-bridge-payload-contract.tsv` records the q1 bridge payload
fields that must exist before q1 bridge parity can be attempted. It names
target, estimator, matrix digest, endpoint fields, provenance, and unsupported
payload pieces without promoting R-via-Julia support.

`structured-re-q1-reconstruction-map.tsv` records how future q1 bridge payloads
should reconstruct `coef`, `vcov`, summary, profile-target, and unavailable
status fields. It is an extractor/status map, not interval or coverage
evidence.

`structured-re-q1-parity-fixture-contract.tsv` records deterministic q1 parity
fixture contracts for native R/TMB, direct DRM.jl, and future R-via-Julia
routes. Rows marked `covered` here mean the fixture contract is specified; they
do not mean executable bridge parity has passed. The spatial, animal, and
relmat scale-side rows are provider-scoped fixture contracts paired with
separate native point-fit evidence; they do not promote range-estimating
spatial support, pedigree/Ainv or Q precision bridge marshalling, intervals,
REML, coverage, or broader public support.

`structured-re-q2-target-contract.tsv` records the q2 target vocabulary. It
keeps q2 location covariance targets separate from q2-plus-q2 block evidence
and full q4 derived correlations, and it keeps native q2 REML unsupported
until an exact-Gaussian derivation and tests exist.

`structured-re-q2-native-evidence.tsv` records fixture-level native q2 evidence
for `phylo()`, `spatial()`, `animal()`, and `relmat()` rows. It is deliberately
point-only and does not promote q4, REML, bridge, or interval coverage claims.

`structured-re-q2-bridge-boundary.tsv` records the q2 bridge split. The phylo
row is experimental for one complete-response exact-Gaussian ML `mu1`/`mu2`
fixture, the `animal()` and `relmat()` rows are experimental for one
known-covariance bridge fixture each, and the `spatial()` row is experimental
for one fixed-covariance coordinate fixture. Q2 REML, one-axis and three-axis
phylo partials, scale-only partial blocks, range-estimating spatial routes,
mesh/SPDE routes, and broad bridge support remain unsupported or planned.

`structured-re-relmat-q-bridge-boundary.tsv` records the relmat `K` versus `Q`
bridge split across the one-slope cells now visible in the q-series ledger.
The rows keep K-matrix bridge fixtures separate from native R/TMB `Q`
precision evidence. The q1 `mu`, q1 `sigma`, matched `mu+sigma`, q2
`mu1+mu2`, q4 location one-slope, and all-four one-slope rows now point to
runtime K/Q same-target native evidence where it has been banked. The q4
location row cites
`structured-re-relmat-q4-location-kq-native-parity.tsv`, which is native R/TMB
runtime evidence only. Every row keeps `bridge_q_status`,
`direct_drmjl_q_status`, and `r_via_julia_q_status` at `unsupported`, so the
ledger does not promote relmat Q bridge marshalling, broad bridge support,
interval reliability, coverage, REML, or AI-REML.

`structured-re-relmat-kq-one-slope-native-parity.tsv` records the generated
six-row native R/TMB K/Q same-target parity ledger for those exact relmat
one-slope cells. It covers q1 `mu`, q1 `sigma`, matched q1 `mu+sigma`, q2
`mu1+mu2` slope-only, q4 location one-slope, and the q8-shaped all-four
one-slope row. This is native runtime evidence only: relmat Q bridge
marshalling, direct DRM.jl Q export, R-via-Julia Q transport, interval
reliability, coverage, REML, AI-REML, public support, and broader q8 support
remain separate gates.

`structured-re-relmat-q-payload-marshalling-gate.tsv` records the acceptance
gate before any relmat `Q` precision bridge work. Each row links back to the
relmat `K/Q` bridge-boundary row and now points to the reviewed payload
contract sidecar for matrix digest, input scale, `Q` precision source, level
alignment, missing-level policy, coefficient order, and provenance. The rows
keep direct DRM.jl, R-via-Julia, and R bridge `Q` statuses unsupported; native
`Q` runtime parity and the reviewed payload contract are not bridge
implementation and do not promote intervals, coverage, REML, AI-REML, public
support, or broader q8 support.

`structured-re-relmat-q-payload-contract-review.tsv` records the reviewed
payload contract for the same six relmat `K/Q` one-slope cells. It fixes the
Q-specific payload policies: stable payload id, digesting the user-supplied
precision matrix without implicit inversion, explicit `Q` input scale, observed
level alignment, fail-closed missing-level policy, endpoint/member coefficient
order, provenance, and no implicit `Q` to `K` conversion in the R bridge
payload. This is contract-review evidence only. Direct DRM.jl `Q`,
R-via-Julia `Q`, R bridge `Q`, intervals, coverage, REML, AI-REML, public
support, and broader q8 support remain unsupported or planned.

`structured-re-relmat-q-drmjl-provider-readiness.tsv` records the current
upstream dependency snapshot for relmat `Q` transport. It has one row for
DRM.jl #299, one row for DRM.jl #300, and one row for the R-side
transport gate after drmTMB #665. The two DRM.jl rows are draft-green upstream
q2 known-precision evidence, not merged support and not R-via-Julia relmat
`Q` transport. The drmTMB row keeps exact `Q` precision transport at
`contract_only_not_implemented` until the upstream stack is accepted and the
reviewed payload contract is matched in R bridge code.

`structured-re-relmat-q-drmjl-stack-review.tsv` records the exact-head review
decision for the current DRM.jl draft stack and the drmTMB #666 readiness gate.
It has rows for DRM.jl #297, #298, #299, #300, and drmTMB #666, including the
reviewed PR heads, local focused-test assertion counts, manual or attached
green evidence, and the next merge/retarget order. This sidecar keeps relmat
`Q` transport blocked until the upstream stack is accepted and the R payload
contract is implemented; it does not promote bridge support, intervals,
coverage, REML, AI-REML, public support, or broader q8 support.

`structured-re-relmat-q4-location-kq-native-parity.tsv` records the one-row
native R/TMB K/Q same-target parity result for
`relmat(1 + x | p | id, K/Q = ...)` in `mu1` and `mu2`. It is a runtime
evidence sidecar, not bridge marshalling evidence, and leaves interval
reliability, coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared
AI-REML, non-Gaussian REML, public support, and broader q8 support unpromoted.

`structured-re-q2-payload-contract.tsv` records the q2 payload shape and
coefficient-ordering contract. It keeps `mu1`/`mu2` location covariance separate
from q2-plus-q2, q4, REML, and interval coverage. The q2 phylo row is backed by
one narrow R-via-Julia fixture, the q2 `animal()` and `relmat()` rows are backed
by known-covariance R-via-Julia fixtures, and the q2 `spatial()` row is backed
by one fixed-covariance R-via-Julia fixture.

`structured-re-q2-payload-provenance.tsv` records the q2 payload provenance
obligations as row-shaped evidence: source repositories, branches, heads,
payload version, matrix ID, matrix digest, matrix slot, input scale,
missing-level policy, bridge-marshalling boundary, endpoint, required matrix
levels, version fields, and dirty-state policy. It is a provenance contract
only; the phylo, `spatial()`, `animal()`, and `relmat()` rows support one
narrow fixture each. The spatial row is fixed-covariance only. None of these
rows promotes broad q2 bridge support.

`structured-re-q2-coefficient-order-map.tsv` records the fixture-derived q2
coefficient order for `phylo()`, `spatial()`, `animal()`, and `relmat()`. It is
a coefficient-map contract only; all four rows have narrow fixture evidence,
with the q2 `spatial()` row limited to fixed-covariance coordinates.

`structured-re-q2-direct-drmjl-export.tsv` records the direct DRM.jl q2 export
status for `phylo()`, `spatial()`, `animal()`, and `relmat()`. The phylo row is
covered for one complete-response exact-Gaussian ML residual-correlation
same-target fixture. The `animal()` and `relmat()` rows now have direct
known-covariance and R-via-Julia same-target fixture evidence, and the
`spatial()` row has fixed-covariance direct and R-via-Julia fixture evidence.
This does not promote range-estimating q2 spatial support, broad q2 bridge
support, q2 REML, q4 support, or interval coverage.

`structured-re-q2-acceptance-gate.tsv` records q2 parity acceptance by
structured type. The phylo row is covered for one complete-response
exact-Gaussian ML native/direct/bridge fixture, the `animal()` and `relmat()`
rows are covered for known-covariance native/direct/bridge fixtures, and the
`spatial()` row is covered for one fixed-covariance coordinate native/direct/
bridge fixture. Aggregate q2 acceptance is fixture-scoped only; it does not
promote range-estimating spatial support, q2 REML, q4 support, broad public
bridge support, or interval coverage.

`structured-re-q4-target-contract.tsv` records q4 target classes. It separates
direct structured-standard-deviation targets from derived cross-axis
correlations and keeps native q4 REML unsupported.

`structured-re-q4-phylocov-target-map.tsv` records the q4 phylogenetic
covariance target names: four direct SD targets and six derived among-axis
correlation targets. It aligns target names to log-Cholesky source labels and
extractors, but does not promote q4 parity, q4 REML, AI-REML, or interval
coverage.

`structured-re-q4-profile-target-bridge-map.tsv` records the q4 profile-target
label bridge for the four direct SD axes. It maps native R/TMB
`sd:mu:<axis>:phylo(1 | p | species)` labels to bridge-facing
`sd:<axis>:phylo(1 | species)` labels and keeps interval reliability,
same-fixture parity, q4 REML, AI-REML, and interval coverage out of scope.

`structured-re-q4-scale-axis-interval-failures.tsv` records the target-specific
sigma-axis interval blockers for q4 `phylo()` fits. It keeps native 100-tip
bootstrap refit failures and direct DRM.jl scale-axis undercoverage visible
without promoting q4 interval reliability, coverage, REML, AI-REML, or bridge
support.

`structured-re-q4-interval-diagnostic-plan.tsv` records the SR150 q4 interval
diagnostic requirements before any calibrated coverage wording can move. It has
four direct SD rows and six derived-correlation rows, requires finite intervals,
denominator fields, and MCSE accounting, and remains plan-only: it does not
promote q4 interval reliability, interval coverage, q4 REML, AI-REML, or broad
bridge support.

`structured-re-q4-interval-diagnostic-status.tsv` records the observed q4
interval blocker from the existing coverage pilot rows. The direct SD rows have
two attempted q4 pilot rows each, zero converged rows, zero positive-Hessian
rows, and zero finite Wald intervals; the derived-correlation rows remain not
reconstructed. This is blocker evidence only and does not promote q4 interval
reliability, interval coverage, q4 REML, AI-REML, or broad bridge support.

`structured-re-q4-convergence-probe.tsv` records a small optimizer-preset probe
for the q4 interval blocker. The original 10-tip, `m = 2` pilot shape remains
nonconverged under default, careful, and robust presets. A denser 10-tip,
`m = 4` toy fixture reaches optimizer convergence under all three presets, but
every row still has `pdHess = false`; finite intervals and coverage wording
therefore remain blocked on Hessian/uncertainty diagnostics.

`structured-re-q4-boundary-separated-probe.tsv` records a stronger q4 toy probe
with larger direct SD truth, mild target correlations, denser sampling, and
default/careful/robust optimizer presets. Two 24-tip rows reach optimizer
convergence, but every row still has `pdHess = false` and the fitted derived
correlations remain near boundary, so q4 finite intervals and coverage wording
remain blocked.

`structured-re-q4-hessian-diagnostic-status.tsv` records the next diagnostic
layer for the converged 10-tip, `m = 4` toy fit. The fixed-gradient magnitude is
small, but `cov.fixed` has a negative eigenvalue, direct q4 SD estimates are
near zero, derived correlations are near +/-1, and direct-SD Wald intervals
remain 0/4 finite. This points the next gate toward boundary-separated fixtures
and Hessian diagnostics, not interval wording.

`structured-re-q4-stabilized-fixture-design.tsv` records the six gates a future
q4 fixture must clear before interval diagnostics can move: direct SD estimates
away from zero, interior fitted correlations, a positive Hessian, finite
direct-SD intervals, denominator accounting, and route-specific parity. It is a
fixture-design contract only, not q4 interval reliability, interval coverage,
q4 REML, AI-REML, or broad bridge support.

`structured-re-q4-stabilized-preflight.tsv` records the first compact
stabilized q4 preflight. Two of four 32-tip, eight-replicate rows reach
`pdHess = TRUE` with interior fitted correlations and 4/4 finite Wald direct-SD
interval rows; two companion rows remain singular-convergence,
`pdHess = false` negative evidence. This is preflight evidence only: it unblocks
the next finite-interval diagnostic design, not q4 interval reliability,
coverage, q4 REML, AI-REML, profile/bootstrap, or broad bridge support. The
runnable artifact lives under
`docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/`.

`structured-re-q4-stabilized-denominator-extension.tsv` summarizes the first
scale-wise denominator extension for the same stabilized fixture. Across four
seeds per scale level, scale `0.35` has 2/4 `pdHess = TRUE` finite-Wald rows
and scale `0.50` has 3/4, with one scale-`0.50` gradient-warning row. This is
denominator-preflight evidence only, not calibrated coverage or interval
reliability.

`structured-re-q4-stabilized-profile-smoke.tsv` records the first single-target
profile smoke on the stabilized q4 fixture. The scale-`0.50`, seed-`202606902`
row produced a finite fast `TMB::tmbprofile` interval for
`sd:mu:sigma1:phylo(1 | p | species)` with `conf.status = profile` and
`profile.boundary = false`. It is one direct-SD profile smoke only, not q4
interval reliability, interval coverage, q4 REML, AI-REML, profile/bootstrap
coverage, or broad bridge support.

`structured-re-q4-stabilized-all-direct-profile.tsv` records the all-four
direct-SD profile smoke on the same stabilized q4 row. The four direct q4 SD
targets in `mu1`, `mu2`, `sigma1`, and `sigma2` all returned finite ordered
fast `TMB::tmbprofile` intervals with `conf.status = profile` and
`profile.boundary = false`. It is one-row direct-SD profile evidence only, not
derived q4 correlation intervals, q4 interval reliability, interval coverage,
q4 REML, AI-REML, profile/bootstrap coverage, or broad bridge support.

`structured-re-q4-stabilized-profile-denominator-status.tsv` records the
profile-denominator status for the eight stabilized q4 seed-scale rows. It
keeps the four all-direct profile successes beside one gradient-warning holdout
and three `pdHess = false` rows. This is denominator accounting for the next
profile pass, not q4 interval reliability, interval coverage, q4 REML,
AI-REML, or broad bridge support.

`structured-re-q4-stabilized-eligible-profile.tsv` records the 12 direct-SD
profile rows from the three additional profile-eligible denominator fits. All
rows returned finite ordered endpoints with `conf.status = profile` and
`profile.boundary = false`, while the run-level warning context records two
`regularize.values()` duplicate-`x` warnings. This is diagnostic profile
evidence only, not coverage or reliability evidence.

`structured-re-q4-stabilized-coverage-design.tsv` records the calibrated q4
coverage-design gate opened by the stabilized profile diagnostics. It separates
direct-SD profile-grid readiness, `pdHess = false` denominator rows, the
gradient-warning holdout, profile duplicate-`x` warnings, derived-correlation
interval unavailability, bootstrap refit accounting, route-specific evidence,
and MCSE reporting. It is design evidence only; no q4 interval reliability,
interval coverage, q4 REML, AI-REML, or broad bridge support is promoted.

`structured-re-q4-stabilized-grid-runner-contract.tsv` records the executable
dry-run contract for the future calibrated q4 grid. The script
`docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-dry-run.R`
accepts only `--n-rep=0` and writes
`q4-stabilized-calibrated-grid-dry-run.tsv`, which names direct SD targets,
derived-correlation targets, denominator fields, warning fields, output schema,
and MCSE columns before any long grid is launched.

`structured-re-q4-stabilized-grid-smoke-status.tsv` records the first
executable q4 calibrated-grid smoke output from
`run-calibrated-grid-smoke.R`. The one-replicate smoke uses the known
stabilized seed `202606902` at scale `0.50`, writes ten target-level rows, keeps
four finite direct-SD Wald rows separate from six unavailable
derived-correlation interval rows, and labels all MCSE fields as
`insufficient_replicates`. It is plumbing evidence only, not q4 interval
reliability, interval coverage, q4 REML, AI-REML, or broad bridge support.

`structured-re-q4-derived-correlation-interval-contract.tsv` records the six q4
derived-correlation targets that remain interval-unavailable after the r46
smoke output. The contract ties each `corpairs` point target to the raw smoke
artifact, names `Sigma_a` and target-level warning/failure fields required for
future reconstruction, and requires delta/profile/bootstrap methods with
denominator and MCSE accounting before any interval or coverage wording.

`structured-re-q4-derived-correlation-interval-smoke.tsv` records the first
executable derived-correlation interval smoke. The companion artifact
`q4-derived-correlation-interval-smoke-results.tsv` fits the stabilized q4
Gaussian phylo smoke fixture and writes the six `corpairs(conf.int = TRUE)`
derived-correlation rows with profile targets mapped, point estimates
reconstructed, interval endpoints unavailable, denominator fields retained,
and MCSE fields marked `insufficient_replicates`. It is not q4 interval
reliability or coverage evidence.

`structured-re-q4-derived-correlation-delta-diagnostic.tsv` records the first
finite-difference delta diagnostic for the six q4 derived correlations. The
companion artifact `q4-derived-correlation-delta-diagnostic-results.tsv`
perturbs the full TMB parameter vector at the six `theta_phylo` positions,
reads the reported `phylo_q4_corr` matrix, verifies that the reconstructed
values match `corpairs()`, and writes finite one-replicate diagnostic
intervals from the `theta_phylo` covariance block. This is diagnostic
mechanics evidence only, not q4 interval reliability, interval coverage, q4
REML, AI-REML, or broad bridge support.

`structured-re-q4-derived-correlation-delta-grid-contract.tsv` records the
next gate for scaling the finite-difference delta diagnostic into a calibrated
q4 grid. It requires the future grid runner to retain seed/scale identity,
full-vector `theta_phylo` report reconstruction, finite or unavailable interval
fields, the exact six-target set, failed-fit and warning rows in denominators,
coverage and failure-rate MCSE fields, and no-coverage boundary wording. It is
a grid-extension contract only, not interval reliability or coverage evidence.

`structured-re-q4-derived-correlation-delta-grid-smoke-status.tsv` records the
first executable grid-shaped delta smoke for q4 derived correlations. The
companion artifact `q4-derived-correlation-delta-grid-smoke-results.tsv` writes
the six derived-correlation targets with seed/scale identity, full-vector
`theta_phylo` report reconstruction, finite diagnostic delta endpoints, retained
denominator rows, and single-replicate MCSE placeholders. It is executable
plumbing evidence only, not interval reliability or coverage evidence.

`structured-re-q4-derived-correlation-delta-grid-mini-status.tsv` records the
first replicated mini-grid for q4 derived-correlation delta diagnostics. The
companion artifact `q4-derived-correlation-delta-grid-mini-results.tsv` runs two
seeds across scale levels 0.35 and 0.50, writes 24 retained target rows, keeps
boundary-clamped rows visible, and populates diagnostic coverage and
failure-rate MCSE fields. It is mini-grid accounting evidence only, not interval
reliability or coverage evidence.

`structured-re-q4-derived-correlation-delta-grid-ademp-contract.tsv` records the
ADEMP-sized dry-run contract for the next calibrated q4 derived-correlation
delta grid. The companion artifact
`q4-derived-correlation-delta-grid-ademp-dry-run.tsv` freezes a 500-replicate
seed range for each scale level, 1000 planned seed-scale cells, 6000 planned
target rows, a nominal 0.95 coverage MCSE of 0.009747, denominator retention
for failures and clamped rows, and a route-specific no-coverage boundary. It is
execution planning evidence only, not interval reliability or coverage evidence.

`structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv` records the
r56 totoro resumable-runner pilot for the same q4 derived-correlation delta grid.
The runner delegates 24 seed-scale cells to the finite-difference delta smoke
(eight seeds crossed with scale levels 0.35, 0.50, and 0.65), writes one TSV per
cell, records 24 compute actions, reruns without force, and records 24
skipped-existing actions against the same outputs. The manifest and run log keep
warnings, pdHess=false rows, unavailable delta intervals, and boundary-clamped
rows in the denominator. They prove remote CPU resumability plumbing only; they
are not calibrated interval reliability or coverage evidence.

`structured-re-q4-derived-correlation-delta-grid-drac-shard-plan.tsv` records
the r57 DRAC/totoro shard plan for the ADEMP-sized q4 derived-correlation delta
grid. The companion artifact
`q4-derived-correlation-delta-grid-drac-shard-plan.tsv` maps 1000 seed-scale
cells and 6000 target rows over nine CPU worker slots: eight DRAC labels and
one `totoro` label. Each shard has a private cell directory, manifest, and run
log, so no compute job appends to a shared file. The aggregate gate remains
blocked until every shard manifest exists, the aggregate sees 1000 unique cell
IDs and 6000 target rows, and denominator, coverage, failure, warning, boundary
clamp, and MCSE fields are present. This is execution-planning evidence only,
not q4 interval reliability, interval coverage, q4 REML, AI-REML, HSquared
transfer, broad bridge support, or SR150 acceptance evidence.

`structured-re-q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv` records
the r63 dry-run dispatch pack for the same 1000-cell grid. The companion
directory `q4-derived-correlation-delta-grid-drac-dispatch-pack/` contains an
eight-task DRAC SLURM array template, a DRAC worker script that runs forced
compute then no-force resume passes in private shard roots, a separate shard-9
`totoro` worker script, an aggregate-afterok script with
`--compute-rate-mcse=true`, and a README. The pack is CPU-only and remains
dry-run/not-submitted until the maintainer selects the actual DRAC account or
host and logs in. It is dispatch safety evidence only, not q4 interval
reliability, interval coverage, q4 REML, AI-REML, HSquared transfer, broad
bridge support, DRAC readiness, or SR150 acceptance evidence.

`structured-re-q4-derived-correlation-delta-grid-two-shard-rehearsal.tsv`
records the r58 local two-shard rehearsal for the same q4 derived-correlation
delta-grid contract. The rehearsal uses two private shard roots, runs a compute
pass and a no-force resume pass, then aggregates the shard manifests and run
logs with `aggregate-calibrated-grid-delta-shards.R`. The aggregate sees four
unique seed-scale cells, four computed actions, four skipped-existing actions,
24 retained target rows, 24 finite delta diagnostic rows, and six
boundary-clamped rows. It proves private-output aggregation and resume behavior
on a tiny local grid only; it is not q4 interval reliability, interval coverage,
q4 REML, AI-REML, HSquared transfer, broad bridge support, or SR150 acceptance
evidence. DRAC remains gated behind local or `totoro` insufficiency.

The r59 aggregate-hardening update keeps the same two-shard rehearsal evidence
but makes the aggregate summary carry target-level denominator, warning,
failure, boundary-clamp, rate, and MCSE-placeholder fields. The focused contract
test also runs tempdir negative paths for missing shard manifests, missing cell
outputs, count mismatches, and duplicate computed cell IDs. This is aggregate
race-safety plumbing only; it is not coverage or interval-reliability evidence.

`structured-re-q4-derived-correlation-delta-grid-local-four-shard-rehearsal.tsv`
records the r60 local four-shard rehearsal with the hardened aggregate gate. The
rehearsal uses four private shard roots over twelve seed-scale cells, runs a
compute pass and a no-force resume pass, then aggregates the shard manifests and
run logs. The aggregate sees twelve unique cells, twelve computed actions,
twelve skipped-existing actions, 72 retained target rows, 71 finite delta
diagnostic rows, 24 warning rows, 18 failure-class denominator rows, 17
boundary-clamped rows, and zero coverage-evaluable rows. This is local
resumability, private-output, denominator-retention, and aggregate evidence
only. It is not q4 interval reliability, interval coverage, q4 REML, AI-REML,
HSquared transfer, broad bridge support, DRAC readiness, or SR150 acceptance
evidence.

`structured-re-q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal.tsv`
records the r61 local medium rehearsal with eight private shard roots over 48
seed-scale cells. Each shard wrote six computed cells and six skipped-existing
resume rows. The aggregate sees 48 unique cells, 48 computed actions, 48
skipped-existing actions, 288 retained target rows, 276 finite delta diagnostic
rows, 156 warning rows, 108 failure-class denominator rows, 61
boundary-clamped rows, and zero coverage-evaluable rows. This is medium local
resumability, private-output, denominator-retention, and aggregate evidence
only. It is not q4 interval reliability, interval coverage, q4 REML, AI-REML,
HSquared transfer, broad bridge support, DRAC readiness, or SR150 acceptance
evidence.

`structured-re-q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid.tsv`
records the r62 local MCSE pre-grid with sixteen private shard roots over 96
seed-scale cells. Each shard wrote six computed cells and six skipped-existing
resume rows. The aggregate sees 96 unique cells, 96 computed actions, 96
skipped-existing actions, 576 retained target rows, 555 finite delta diagnostic
rows, 306 warning rows, 192 failure-class denominator rows, 126
boundary-clamped rows, and zero coverage-evaluable rows. The aggregate summary
computes diagnostic MCSE fields for failure, warning, and boundary-clamp rates
while keeping coverage `not_evaluable`. This is local MCSE and denominator
evidence only. It is not q4 interval reliability, interval coverage, q4 REML,
AI-REML, HSquared transfer, broad bridge support, DRAC readiness, or SR150
acceptance evidence.

`structured-re-q4-direct-drmjl-export.tsv` records the direct DRM.jl q4 point
SD export contract for `sd_mu1`, `sd_mu2`, `sd_sigma1`, and `sd_sigma2` from
`fit.ranef.Sigma_a`. It is direct-Julia point-target evidence only, not
R-via-Julia q4 bridge parity, q4 REML, AI-REML, interval reliability, or
interval coverage.

`structured-re-q4-deterministic-fixture.tsv` records the reusable q4 fixture
metadata for a deterministic 8-species, 16-observation balanced-tree dataset
with known `Sigma_a`. It is fixture data only, not a native/direct/bridge
parity result.

`structured-re-q4-tolerance-policy.tsv` records the predeclared q4 point-parity
tolerances for log likelihood, fixed coefficients, direct SD targets, and
derived correlations on the deterministic fixture. It is a policy table only,
not parity acceptance.

`structured-re-q4-same-fixture-parity-probe.tsv` records the first live
same-data q4 parity probe after the tolerance policy. The current row is
negative evidence: native TMB did not converge on the probe, direct DRM.jl now
has a point-matrix export but has not yet been compared on this same fixture,
and the native versus R-via-Julia `corpairs()` delta exceeded the predeclared q4
correlation tolerance. It is not q4 parity, q4 REML, AI-REML, bridge support,
interval reliability, or interval coverage.

`structured-re-q4-parity-acceptance-gate.tsv` records the calibrated q4
point-parity acceptance gate. It covers same-fixture native R/TMB, direct
DRM.jl, and R-via-Julia point comparison only; interval reliability, interval
coverage, q4 REML, AI-REML, and broad bridge-support wording remain blocked.

`structured-re-q4-extractor-parity.tsv` records q4 point/extractor status for
summary covariance, profile targets, corpairs, and planned bridge
reconstruction. It is not interval coverage evidence.

`structured-re-q4-corpairs-parity-gate.tsv` records calibrated q4 corpairs
point parity. It covers same-fixture native R/TMB, direct DRM.jl, and
R-via-Julia derived correlations only; interval reliability, interval coverage,
q4 REML, AI-REML, and broad bridge-support wording remain blocked.

`structured-re-q4-bridge-boundary.tsv` records q4 bridge boundaries. Calibrated
point parity is separated from interval reliability, interval coverage, q4
REML, AI-REML, and broad bridge-support wording.

`structured-re-reml-scope-gate.tsv` records where REML wording is allowed and
where it is forbidden. It keeps REML exact-Gaussian and route-specific, blocks
native q2/q4 REML promotion until derivations and tests exist, and keeps q4
Patterson-Thompson REML separate from HSquared AI-REML.

`structured-re-ademp-design.tsv` records the ADEMP q1, q2, and q4 design
contracts. It names aims, data-generating mechanisms, estimands, methods,
performance measures, MCSE targets, failed-fit denominators, and interval
policies before any calibrated simulation grid is run. The companion design
note is `docs/design/217-structured-reml-and-ademp-conversion-gates.md`.

`structured-re-coverage-calibration-status.tsv` records SR142-SR149 as
coverage-calibration infrastructure: q1/q2/q4 diagnostic-pilot status,
interval-method separation, bootstrap refit accounting fields, MCSE targets,
failure taxonomy, and a report template. It is not a calibrated coverage
result; q1 has only one finite pilot interval, and q2/q4 have no finite pilot
intervals.

`structured-re-coverage-acceptance-gate.tsv` records SR150 as the stricter
coverage-acceptance blocker. It requires planned replicate counts, finite
interval accounting, denominator retention, and MCSE before review. The current
rows remain blocked because the diagnostic pilots are not calibrated coverage
evidence; q2 fixture parity is now banked separately, but q2 still has no
finite pilot intervals and no calibrated coverage evidence.

`structured-re-native-reml-scope-status.tsv` records SR151-SR159 as native
REML scope evidence. It keeps requested and effective estimator fields visible
for source maps, q1 allowed cells, sigma/q2/q4 rejection or feasibility rows,
Patterson-Thompson wording, public optimizer controls, and non-Gaussian
wording scans.

`structured-re-scope-gate-status.tsv` records SR160-SR170 as scope gates. It
keeps the blocked REML acceptance gate separate from structured-type gaps such
as mesh/SPDE, sparse animal pedigree helpers, `relmat()` precision `Q`, q1-only
`phylo_interaction()`, direct-SD grammar, structured slopes, structured
`rho12`, and non-Gaussian q2/q4 structured covariance.

`structured-re-mu-slope-fixture-audit.tsv` records the current one-slope
Gaussian structured `mu` artifact evidence for `phylo()`, `spatial()`,
`animal()`, and `relmat()`. These rows bank source-tested DGP, smoke-summary,
and grid-writer evidence plus extractor identity. They do not promote bridge
fixture parity, residual-scale slopes, broader labelled structured slope covariance,
interval reliability, or coverage.

`structured-re-mu-slope-parity-fixture.tsv` records the same-target bridge
fixture gate for those one-slope Gaussian structured `mu` rows. It banks
deterministic native/direct/R-via-Julia fixture contracts for `phylo()`,
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`
cells. The `relmat()` row is paired with runtime K/Q same-target parity
evidence, but this sidecar still does not promote broad bridge support,
sigma-slope bridge fixture parity, broader labelled structured slope covariance,
interval reliability, or coverage.

`structured-re-sigma-slope-parity-fixture.tsv` records the same-target bridge
fixture gate for the first Gaussian structured `sigma` one-slope rows:
`phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()`. The `relmat()` row is paired with runtime K/Q same-target parity
evidence from the native test file. This sidecar does not promote broad bridge
support, matched `mu+sigma` bridge or inference claims, labelled structured
slope covariance, interval reliability, or coverage.

`structured-re-sigma-slope-interval-diagnostic-plan.tsv` and
`structured-re-sigma-slope-interval-diagnostic-status.tsv` record the
sigma-only one-slope interval smoke for those four providers. This is a
separate half-cell diagnostic: sigma-only profile target names are
`sd:sigma:provider(...)`, not the matched `mu+sigma` names
`sd:sigma:sigma:provider(...)`. The smoke run found all eight direct SD
targets and kept all fits converged with `pdHess = TRUE`; seven targets had
finite Wald/profile/bootstrap intervals, while the animal `sigma:x` target had
finite Wald/bootstrap intervals but endpoint-profile failure. The sidecars
remain diagnostic-only and do not promote interval reliability, calibrated
coverage, REML, AI-REML, matched `mu+sigma` support, range-estimating spatial
support, pedigree/Ainv bridge marshalling, relmat Q bridge marshalling, or
broad bridge support.

`structured-re-sigma-slope-interval-stability-probe.tsv` records a
follow-up sigma-only one-slope diagnostic using two stronger deterministic
fixture variants and only Wald plus endpoint-profile intervals. It is backed
by
`docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-interval-stability-probe/structured-re-sigma-slope-interval-stability-probe-results.tsv`.
All 16 variant-target combinations had finite Wald/profile intervals,
including the animal `sigma:x` target that failed endpoint profiling in the
smoke run. This sidecar is still diagnostic-only evidence and does not itself
promote interval or coverage status. Later Q-Series evidence supersedes it only
for the exact phylo/animal/relmat q1 sigma one-slope rows in
`structured-re-sigma-slope-inference-evidence.tsv`; spatial sigma remains
unpromoted.

`structured-re-sigma-slope-spatial-animal-admission-audit.tsv` records the
current admission or promotion state for the spatial and animal q1 sigma
one-slope support cells. Spatial now has retained-denominator SR1000 evidence
for both direct-SD
endpoints, combining the SR475 local grid with the 2026-06-28 local top-up in
`docs/dev-log/simulation-artifacts/2026-06-28-spatial-sigma-slope-coverage-topup-local/spatial-sigma-sr1000-combined-summary.tsv`.
The `sigma:x` endpoint passes the finite-Wald gate at 954/1000 = 0.9540, but
`sigma:(Intercept)` remains below the row-promotion gate at 936/1000 = 0.9360,
so the widget marks the cell `admission_blocked`, not `inference_ready`.
Animal now has retained-denominator SR1000 evidence for both direct-SD
endpoints in
`docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/animal-sigma-sr1000-combined-summary.tsv`.
Both animal endpoints pass the raw-Wald finite-rate and MCSE gates
(`sigma:(Intercept)` 981/1000 = 0.9810, `sigma:x` 953/1000 = 0.9530), but
the profile channel remains low-finite/censoring-suspect. Fisher accepted the
raw-Wald sigma channel for the exact animal row and Rose required the
coordinated status edit, so the widget now marks the animal cell
`inference_ready`. The spatial support cell keeps `interval_status = planned`
and `coverage_status = planned`; the animal support cell is
`inference_ready` only under the raw uncorrected log-SD Wald-z sigma channel.
This ledger does not promote range-estimating spatial support, pedigree/Ainv
bridge marshalling, matched `mu+sigma`, q4/q8, REML, AI-REML, bridge support,
`supported`, or public support.

`structured-re-sigma-slope-denominator-admission.tsv` records the first
sigma-only one-slope denominator-admission ledger. Seven of eight direct SD
targets are marked `diagnostic_denominator_candidate`; animal `sigma:x`
remains `not_admitted_profile_failure` because the first Wald/profile/bootstrap
smoke still had endpoint-profile failure for that target. Coverage remains
`not_evaluated` in this admission sidecar. Later Q-Series promotion for the
exact phylo/animal/relmat q1 sigma rows comes from
`structured-re-sigma-slope-inference-evidence.tsv`, not from this denominator
admission table.

`structured-re-sigma-slope-replicated-denominator-rule.tsv` records the
historical replicated-denominator rule for those same sigma-only one-slope
targets. Seven targets are `eligible_for_pregrid_with_retention`; animal
`sigma:x` remains a visible holdout in that June 24 rule because the first
smoke had endpoint-profile failure. The June 28 animal SR1000 admission audit
supersedes the missing-coverage state for the Q-Series widget but does not
rewrite this provenance sidecar. The rule requires failed profiles,
nonconverged fits, nonfinite intervals, and bootstrap refit attempts to be
retained in any future denominator.

`structured-re-sigma-slope-coverage-pregrid-dry-run.tsv` records a dry-run
manifest for a future sigma-only one-slope coverage pre-grid. It declares 150
seeds and 1050 not-executed target-replicate cells for the seven eligible
targets, while excluding animal `sigma:x` from the executable cell manifest.
The nominal MCSE at 150 replicates is 0.017795, so SR150 remains insufficient
for coverage wording and coverage remains `not_evaluated`.

`structured-re-sigma-slope-coverage-dispatch-review.tsv` records the next
dispatch-review gate for that dry-run manifest. It carries the seven eligible
targets forward to a Totoro/DRAC review manifest, records provider shards and
the 740001-740150 seed range, and adds scheduler-exit retention. No jobs were
submitted, animal `sigma:x` remains excluded, and the linked support cells keep
planned interval and coverage status.

`structured-re-sigma-slope-coverage-runner-contract.tsv` records the
fail-closed dry-run runner contract for those same seven sigma-only one-slope
coverage targets. It validates the dispatch-review manifest, writes a selected
target manifest and run log, and refuses execution modes other than dry-run.
The runner also writes provider-filtered dry-run manifests with shard-specific
filenames so later Totoro or reviewed DRAC rehearsals cannot overwrite the
full seven-row contract. Every row remains `dry_run_not_submitted`,
`not_executed`, `runner_contract_only`, and `coverage_evaluable = FALSE`; this
sidecar does not submit jobs, admit a coverage-evaluable denominator, promote
MCSE-calibrated coverage, interval reliability, REML, AI-REML, q4/q8 support,
broad bridge support, public support, or SR150 readiness.

`structured-re-pr-stack-merge-readiness.tsv` records the ordered draft PR stack
for the current q-series lane (#639 through #663). It separates merge-clean
state from ordinary PR-attached checks: #639 has attached green checks against
`main`, while #640 through #663 have green commit-level R-CMD-check evidence
and must rerun normal PR checks after each retargets to `main`. This sidecar
does not undraft, merge, submit Totoro or DRAC jobs, admit coverage-evaluable
denominators, or promote interval, REML, AI-REML, bridge, public-support, or
SR150 readiness claims. Its next gate is explicit maintainer approval, then
merge from #639 upward with mission-control validation and normal PR checks
refreshed after each layer lands.

`structured-re-q-series-support-cells.tsv` now also records the first
bivariate Gaussian structured slope-only q=2 `mu1`/`mu2` covariance cells:
matching `phylo(0 + x | p | species, tree = tree)`,
fixed-covariance `spatial(0 + x | p | site, coords = coords)`,
`animal(0 + x | p | id, A/Ainv = ...)`, and
`relmat(0 + x | p | id, K/Q = ...)`. These rows now have native point-fit and
extractor evidence plus deterministic same-target fixture parity for the exact
`mu1:x+mu2:x` endpoint set only. They do not promote intercept-plus-slope q4/q8
structured covariance, broad bridge support, interval reliability, coverage,
REML, or AI-REML.

`structured-re-q2-slope-parity-fixture.tsv` records the corresponding q=2
slope-only same-target fixture gate for `phylo()`, fixed-covariance
`spatial()`, A-matrix `animal()`, and K-matrix `relmat()`. The `relmat()` row
is paired with runtime K/Q same-target parity evidence, but the sidecar does
not promote Q bridge marshalling, pedigree/Ainv bridge marshalling,
range-estimating spatial support, intervals, coverage, REML, AI-REML, or broad
bridge support.

`structured-re-q2-slope-interval-diagnostic-plan.tsv` records the next
target-level interval diagnostic plan for the same slope-only q=2 cells. Each
provider has three planned targets: `sd_mu1_x`, `sd_mu2_x`, and
`cor_mu1_mu2_x`. This is plan-only evidence and keeps the linked q-series rows
at `interval_status = planned` and `coverage_status = planned`; it does not
promote interval reliability, interval coverage, intercept-plus-slope q4/q8,
range-estimating spatial support, pedigree/Ainv bridge marshalling, relmat Q
bridge marshalling, REML, AI-REML, or broad bridge support.

`structured-re-q2-slope-interval-diagnostic-status.tsv` records the first
deterministic interval-smoke status for those 12 slope-only q=2 targets. It is
backed by
`docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-interval-smoke/structured-re-q2-slope-interval-smoke-results.tsv`
and separates finite Wald/profile/bootstrap rows from the two correlation
targets where Wald/bootstrap were finite but endpoint profiles failed. The
post slope-design-fix rerun has 10 all-finite method rows and two profile
failure rows, with all fits converged and `pdHess = TRUE`. The table is still
diagnostic-only: the linked q-series cells keep
`interval_status = planned` and `coverage_status = planned`.

`structured-re-q2-slope-interval-stability-probe.tsv` records a follow-up
deterministic stability probe for the same slope-only q=2 target set. It uses
two stronger slope-signal fixtures and only Wald plus endpoint-profile
intervals. The post slope-design-fix rerun has all 24 variant-target rows at
finite Wald/profile status with `pdHess = TRUE`. This remains diagnostic-only
and does not promote interval reliability, coverage, q4/q8, REML, AI-REML,
broad bridge support, range-estimating spatial support, pedigree/Ainv bridge
marshalling, or relmat Q bridge marshalling.

`structured-re-q2-slope-denominator-admission.tsv` records the first
denominator-admission ledger for the same q2 slope targets after the runtime
fix. It joins the interval-smoke and stability sidecars: 10 targets are marked
`diagnostic_denominator_candidate`, while the animal and relmat correlation
targets remain `not_admitted_profile_failure` because endpoint profiles failed
in the smoke run. The ledger keeps `coverage_status = not_evaluated` and the
linked q-series cells at `interval_status = planned` and
`coverage_status = planned`; it is not coverage-grid evidence and does not
promote interval reliability, coverage, REML, AI-REML, q4/q8, or broad bridge
support.

`structured-re-q2-slope-denominator-extension.tsv` records a two-variant
deterministic extension of that denominator-admission ledger. It reruns
Wald/profile diagnostics for all 12 q2 slope targets in two stronger fixture
variants and links back to the admission sidecar. All 24 extension rows have
finite Wald/profile diagnostics and `pdHess = TRUE`; 20 rows are
`extension_candidate`, while the animal and relmat correlation rows remain
`not_admitted_from_smoke` because their earlier smoke endpoint profiles
failed. The table keeps `coverage_status = not_evaluated`; it is not
coverage-evaluable denominator evidence and does not promote interval
reliability, coverage, REML, AI-REML, q4/q8, or broad bridge support.

`structured-re-q2-slope-replicated-denominator-rule.tsv` records the
predeclared rule for turning those q2 slope diagnostics into a future
coverage pre-grid denominator. The rule keeps all 12 target rows visible,
marks 10 rows `eligible_for_pregrid_with_retention`, and keeps the animal and
relmat correlation rows as `visible_holdout_until_smoke_profile_reconciled`.
It requires a predeclared 150-replicate seed manifest, retained failed
profiles, retained nonconverged fits, retained nonfinite intervals, recorded
bootstrap-refit attempts, and MCSE <= 0.01 before any coverage wording. The
table is policy-only: it keeps `coverage_evaluable = FALSE` and does not
promote interval reliability, calibrated coverage, REML, AI-REML, q4/q8,
DRAC execution, SR150 readiness, or broad bridge support.

`structured-re-q2-slope-spatial-animal-admission-audit.tsv` records the
current blocker state for the spatial and animal q2 location one-slope support
cells. Spatial has SR475 raw coverage for `mu1:x`, `mu2:x`, and
`mu1:x+mu2:x`, but the raw Wald/Profile intervals under-cover. The companion
`structured-re-q2-slope-bias-t-coverage-evidence.tsv` sidecar records the
SR475 default bias+t SD-endpoint revalidation: spatial `mu2:x` remains below
nominal at 0.9411 with MCSE 0.0108 and 24 upper-tail misses, so the widget
marks the cell `calibration_required`. Animal has raw coverage for the two SD
endpoints and bias+t endpoint revalidation, but `mu2:x` remains borderline at
0.9474 with MCSE 0.0102 and the `mu1:x+mu2:x` correlation target is absent from
the coverage grid after the replicated-denominator holdout, so the widget marks
the cell `admission_blocked`. Both linked support cells keep
`interval_status = planned` and `coverage_status = planned`; this ledger does
not promote range-estimating spatial support, pedigree/Ainv bridge marshalling,
q4/q8, REML, AI-REML, bridge support, `supported`, or public support.

`structured-re-q2-slope-bias-t-topup-runner-contract.tsv` records the executable
top-up contract for those four spatial/animal q2 SD endpoints. Shards 1-4 cover
spatial `mu1:x`, spatial `mu2:x`, animal `mu1:x`, and animal `mu2:x` with
525 planned replicates each for seeds 730476-731000. The local current-source
smoke has one finite fit, `pdHess = TRUE`, and finite default bias+t Wald
interval output for each endpoint. This is runner-contract evidence only: the
linked q-series rows remain `interval_status = planned` and
`coverage_status = planned`, and the contract does not promote inference
readiness, calibrated coverage, correlation targets, q4/q8, REML, AI-REML,
bridge support, `supported`, or public support.

`structured-re-q2-slope-bias-t-topup-results.tsv` records the completed Rorqual
top-up for those four SD endpoints. Shards 1 and 3 completed in array job
`14901064`; shard 2 was retried as `14901210` and shard 4 as `14901126` after
the first array exposed a shared-source install race, and the failed first
attempts remain archived beside the valid results. Combined with the SR475
sidecar, the SR1000 bias+t endpoint totals are spatial `mu1:x` 0.9590, spatial
`mu2:x` 0.9480, animal `mu1:x` 0.9600, and animal `mu2:x` 0.9540, all with MCSE
<= 0.01. This still does not promote the linked rows: spatial `mu2:x` has 47
upper-tail misses versus 5 lower misses, animal `mu2:x` has 36 versus 10, and
the q2 row-level correlation/denominator gates remain unresolved.

`structured-re-q2-slope-coverage-pregrid-dry-run.tsv` records the executable
manifest shape for that future q2 slope coverage pre-grid without running any
coverage fits. It links to a 150-row predeclared seed manifest and a 1500-row
target-by-seed cell manifest for the 10 currently eligible targets; the animal
and relmat correlation targets remain visible holdouts with zero planned
cells. The table also records that 150 replicates give nominal 0.95-coverage
MCSE about 0.017795, so the 0.01 MCSE threshold would require 475 replicates
before coverage wording. The dry run keeps `execution_status =
not_executed`, `coverage_evaluable = FALSE`, and `coverage_status =
not_evaluated`; it does not promote calibrated coverage, interval reliability,
REML, AI-REML, q4/q8, DRAC execution, SR150 readiness, or broad bridge
support.

`structured-re-mu-sigma-slope-parity-fixture.tsv` records the matched
`mu+sigma` one-slope same-target bridge fixture gate for `phylo()`,
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`.
It banks deterministic native/direct/R-via-Julia fixture contracts for the four
endpoint members while keeping labelled slope covariance, interval reliability,
coverage, REML, AI-REML, broad bridge support, and relmat Q bridge marshalling
out of scope.

`structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv` records the
target-level interval diagnostic plan for the same matched `mu+sigma`
one-slope cells. It names the 16 direct SD targets to smoke with Wald,
profile, and bootstrap intervals before any calibrated coverage wording. This
is plan-only evidence: it does not promote interval reliability, interval
coverage, REML, AI-REML, broad bridge support, range-estimating spatial
support, pedigree/Ainv bridge marshalling, or relmat Q bridge marshalling.

`structured-re-mu-sigma-slope-interval-diagnostic-status.tsv` records the
first deterministic interval-smoke status for those 16 direct SD targets. It is
backed by
`docs/dev-log/simulation-artifacts/2026-06-24-mu-sigma-slope-interval-smoke/structured-re-mu-sigma-slope-interval-smoke-results.tsv`
and separates finite Wald/profile/bootstrap rows from boundary/profile-failure
rows. The table is diagnostic-only: the linked q-series cells keep
`interval_status = planned` and `coverage_status = planned`.

`structured-re-mu-sigma-slope-interval-stability-probe.tsv` records a
follow-up diagnostic using two stronger deterministic fixture variants and only
Wald plus endpoint-profile intervals. It is backed by
`docs/dev-log/simulation-artifacts/2026-06-24-mu-sigma-slope-interval-stability-probe/structured-re-mu-sigma-slope-interval-stability-probe-results.tsv`.
The probe found finite Wald/profile rows for 28 of 32 variant-target
combinations; the persistent exceptions were fixed-covariance `spatial()` `mu`
intercept and `mu:x` targets in both variants. This table remains
diagnostic-only and does not promote interval reliability, interval coverage,
REML, AI-REML, broad bridge support, range-estimating spatial support,
pedigree/Ainv bridge marshalling, or relmat Q bridge marshalling.

`structured-re-spatial-mu-boundary-diagnostic.tsv` drills into those
fixed-covariance spatial `mu` failures. It is backed by
`docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-boundary-diagnostic/structured-re-spatial-mu-boundary-diagnostic-results.tsv`
and compares six deterministic designs: the original finite smoke seed, the
boundary-producing stronger seed, two alternate strong seeds, a higher
replication version of the boundary seed, and a `mu`-dominant/low-`sigma`
version of the boundary seed. Eight of 12 target rows had finite Wald/profile
intervals, two had finite Wald but failed endpoint profile, and two remained
at the Wald/profile boundary. This shows seed/design sensitivity, not
coverage readiness, and keeps the spatial q-series interval and coverage
statuses planned.

`structured-re-spatial-mu-profile-geometry.tsv` drills one layer deeper into
the fragile `mu:x` endpoint-profile path from the same spatial cell. It is
backed by
`docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-profile-geometry/structured-re-spatial-mu-profile-geometry-results.tsv`
and records lower and upper endpoint-profile crossings for the six diagnostic
designs. All six upper sides succeeded. Three lower sides succeeded, while the
three seed-202 lower sides failed with constrained-optimizer `NA/NaN gradient
evaluation`. This geometry evidence explains the profile fragility but remains
diagnostic-only; it does not promote interval reliability, coverage, or public
spatial support.

`structured-re-spatial-mu-profile-strategy.tsv` compares the existing
endpoint, `auto`, and `tmbprofile` profile engines for the finite
`smoke_seed102` control and the three seed-202 spatial `mu:x` designs that
failed the lower-side geometry diagnostic. It is backed by
`docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-profile-strategy/structured-re-spatial-mu-profile-strategy-results.tsv`.
The smoke control stayed finite under all three requested engines. The three
problematic designs remained nonfinite under endpoint profiling and under the
existing `auto`/`tmbprofile` fallback path, so fallback alone is not enough to
admit those rows to interval denominators. This table remains diagnostic-only
and does not promote interval reliability, coverage, range-estimating spatial
support, or public support.

`structured-re-spatial-mu-lower-start-diagnostic.tsv` tests whether a safer
lower-side constrained-endpoint start can rescue the same spatial `mu:x`
problem rows without changing runtime behavior. It is backed by
`docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-lower-start-diagnostic/structured-re-spatial-mu-lower-start-diagnostic-results.tsv`
and compares the current warm curvature start with reset curvature, reset
capped-step, and reset fixed-step variants. The smoke control stayed finite in
all four variants, but all three problematic seed-202 designs still failed
with `NA/NaN gradient evaluation`. These rows remain diagnostic-only and are
not admitted to interval denominators.

`structured-re-spatial-mu-domain-guard-diagnostic.tsv` tests whether the same
spatial `mu:x` lower-side problem is caused by immediate target-domain
non-finiteness or by the constrained optimizer path. It is backed by
`docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-domain-guard-diagnostic/structured-re-spatial-mu-domain-guard-diagnostic-results.tsv`.
For the finite control and all three seed-202 problem designs, fixed-nuisance
objective and gradient evaluations were finite at all nine lower target
offsets. Guarded lower-side prototypes that penalized nonfinite objective
values, with and without zero-gradient fallback, still rescued only the smoke
control; the three seed-202 designs remained nonfinite. The table is
diagnostic-only and does not admit interval denominators or promote interval
reliability, coverage, range-estimating spatial support, REML, AI-REML, broad
bridge support, or public support.

`structured-re-mu-sigma-slope-readiness.tsv` records the native point-fit and
extractor identity gate for matched Gaussian structured `mu+sigma` one-slope
cells. Each provider row names the four endpoint members, `mu:(Intercept)`,
`mu:x`, `sigma:(Intercept)`, and `sigma:x`, links back to the separate `mu` and
`sigma` one-slope fixture ledgers, and points to the provider test file. These
rows do not promote bridge support, intervals, coverage, REML, or AI-REML.

`structured-re-q4-intercept-parity-fixture.tsv` records deterministic
same-target native/direct/R-via-Julia fixture evidence for exact all-four
intercept `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and
K-matrix `relmat()` cells. It moves the spatial, animal, and relmat q4
all-four intercept support-cell rows to fixture parity; the phylo row already
has the older q4 parity acceptance gate. This is still point/fixture evidence
only: interval reliability, interval coverage, q4 REML, native-TMB q4 REML, q4
AI-REML, broad bridge support, public support, range-estimating spatial
support, pedigree/Ainv animal bridge marshalling, and relmat Q bridge
marshalling remain separate gates.

`structured-re-q4-intercept-interval-diagnostic-plan.tsv` records the
provider-scoped target plan for deterministic q4 all-four intercept interval
diagnostics. Each provider has four direct-SD rows and six derived-correlation
rows. The direct-SD rows require a future deterministic Wald/profile/bootstrap
smoke; the derived-correlation rows remain blocked until interval reconstruction
is designed. This is a plan contract only, not interval reliability, interval
coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad
bridge support, public support, range-estimating spatial support,
pedigree/Ainv animal bridge marshalling, or relmat Q bridge marshalling.

`structured-re-q4-intercept-interval-diagnostic-status.tsv` records the first
direct-SD interval smoke for those exact all-four intercept q4 cells. It links
to
`docs/dev-log/simulation-artifacts/2026-06-25-q4-intercept-interval-smoke/structured-re-q4-intercept-interval-smoke-results.tsv`
and covers only the 16 direct-SD rows from the plan. The phylo,
fixed-covariance spatial, and K-matrix relmat fits converged but returned
`pdHess = FALSE`, so their Wald/profile/bootstrap rows are recorded as
`not_run_pdhess_false`. The A-matrix animal fit returned `pdHess = TRUE` with
finite Wald/profile direct-SD intervals and nonfinite bootstrap rows. This is
diagnostic-only evidence: derived-correlation interval reconstruction,
denominator admission, interval reliability, interval coverage, q4 REML,
native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad bridge support, public
support, range-estimating spatial support, pedigree/Ainv animal bridge
marshalling, and relmat Q bridge marshalling remain unpromoted.

`structured-re-q4-intercept-denominator-precheck.tsv` records the denominator
precheck implied by the direct-SD interval smoke. It covers the same 16
direct-SD q4 all-four intercept targets. Phylo, fixed-covariance spatial, and
K-matrix relmat are marked `not_admitted_pdhess_false`; the A-matrix animal
targets are marked `not_admitted_bootstrap_nonfinite`. This precheck is a
blocking diagnostic only. It does not admit coverage denominators, evaluate
coverage, run DRAC/Totoro jobs, or promote interval reliability, interval
coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad
bridge support, public support, range-estimating spatial support,
pedigree/Ainv animal bridge marshalling, or relmat Q bridge marshalling.

`structured-re-q4-intercept-hessian-bootstrap-diagnostic.tsv` records the
provider-level Hessian/bootstrap follow-up for the same q4 all-four intercept
cells. It refits the deterministic smoke fixture and links back to both the
interval-status and denominator-precheck sidecars. Phylo, fixed-covariance
spatial, and K-matrix relmat have `pdHess = FALSE` with
`finite_indefinite` fixed-effect covariance diagnostics; the A-matrix animal
row has `pdHess = TRUE` and `finite_positive` fixed-effect covariance but keeps
all four direct-SD targets blocked by nonfinite bootstrap rows. This sidecar is
diagnostic only. It does not admit denominators, evaluate coverage, run
DRAC/Totoro jobs, or promote interval reliability, interval coverage, q4 REML,
native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad bridge support, public
support, range-estimating spatial support, pedigree/Ainv animal bridge
marshalling, or relmat Q bridge marshalling.

`structured-re-q4-slope-identity-preflight.tsv` records the q8-shaped identity
contract for all-four bivariate Gaussian one-slope cells. Each provider row
names the eight endpoint members, the matching eight direct-SD targets, and the
28 labelled covariance pairs required before runtime can be called implemented.
The phylo, fixed-covariance spatial, A-matrix animal, and K/Q relmat rows now
record native point-fit/extractor evidence for their exact shared-label
all-four cells. The identity ledger is the runtime/extractor map, not the
bridge evidence source.

`structured-re-q4-slope-parity-fixture.tsv` records deterministic same-target
native/direct/R-via-Julia fixture evidence for the exact all-four one-slope
`phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()` cells. It moves only those four exact q8-shaped cells to fixture
parity. Broad bridge support, intervals, coverage, q4 REML, AI-REML, and
public support remain planned; pedigree/Ainv animal bridge marshalling, relmat
Q bridge marshalling, range-estimating spatial support, and broader q8 layouts
remain separate gates.

`structured-re-q4-slope-interval-diagnostic-plan.tsv` records target-level
interval diagnostic planning for those exact q8-shaped cells. Each provider has
8 direct-SD rows and 28 derived-correlation rows. The direct-SD rows require a
future deterministic Wald/profile/bootstrap smoke; the derived-correlation rows
stay blocked until derived interval reconstruction is designed and validated.
All 144 rows are planned-only and do not admit coverage denominators, interval
reliability, coverage, q4 REML, AI-REML, broad bridge support, or public
support.

`structured-re-q4-slope-interval-diagnostic-status.tsv` records the first
direct-SD smoke for those same cells. It links to
`docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-smoke/structured-re-q4-slope-interval-smoke-results.tsv`
and covers only the 32 direct-SD targets from the plan. All four provider fits
converged, but all four returned `pdHess = FALSE`, so all Wald/profile/bootstrap
method rows are recorded as `not_run_pdhess_false` with zero finite intervals.
The status sidecar is diagnostic negative evidence only: derived correlations,
denominator admission, interval reliability, coverage, q4 REML, AI-REML, broad
bridge support, and public support remain planned or blocked.

`structured-re-q4-slope-interval-stability-probe.tsv` records a follow-up
Hessian-stability probe for the same 32 direct-SD q4 all-four one-slope targets.
It links to
`docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-stability-probe/structured-re-q4-slope-interval-stability-probe-results.tsv`
and covers two deterministic variants: a stronger signal design and a
more-levels design. The current-source refresh keeps `phylo()`, fixed-covariance
`spatial()`, and K-matrix `relmat()` Hessian-blocked in both variants. The
A-matrix `animal()` rows now have `pdHess = TRUE`, finite Wald intervals, and a
mixed profile signal: 9/16 animal endpoints are Wald/profile finite and 7/16
are Wald-finite/profile-nonfinite. This remains diagnostic evidence only:
denominator admission, interval reliability, coverage, q4 REML, AI-REML, broad
bridge support, public support, and broader q8 support remain unpromoted.

`structured-re-q4-animal-all-four-admission-probe.tsv` records the first
replicated admission smoke for the animal q4 all-four one-slope row. It links to
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-all-four-admission-probe-nibi/structured-re-q4-animal-all-four-admission-probe-replicates.tsv`
and retains the 16 corrected Nibi `more_levels` replicates in the denominator:
all 16 fits converged, only two had `pdHess = TRUE`, 112 Wald and 112 profile
target-replicate rows are retained as `not_run_pdhess_false`, and two profile
rows are nonfinite even among the positive-Hessian fits. The sidecar is
admission-smoke evidence only. It does not promote q4 interval reliability,
coverage, `inference_ready`, `supported`, q8 support, REML, AI-REML, broad
bridge support, or public support.

`structured-re-q4-animal-hessian-geometry-diagnostic.tsv` records an
endpoint-level diagnostic derived from the same 16-replicate Nibi artifact. The
eight direct-SD endpoint rows show that retained direct-SD estimates are not a
simple near-zero boundary collapse (`n_estimate_lt_0_10 = 0` for every
endpoint), while the admission denominator is still blocked by the 2/16
positive-Hessian rate and incomplete profile finiteness. The sidecar separates
Hessian/correlation geometry from coverage and promotion status: no q4 coverage
grid, `inference_ready`, `supported`, q8 inference, q4 REML, REML, AI-REML,
derived-correlation interval, or broad bridge claim follows from this table.

`structured-re-q4-animal-numerical-geometry-diagnostic.tsv` records a focused
four-seed local numerical-geometry smoke for the same animal q4 all-four
one-slope row. It links to
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-numerical-geometry-local/structured-re-q4-animal-numerical-geometry-diagnostic.tsv`
and contrasts two `pdHess = FALSE` admission seeds with two `pdHess = TRUE`
seeds. The blocked seeds retain large fixed-gradient norms, negative
`sdreport` covariance eigenvalues, extreme q4 theta magnitudes, and selected
fallback-BFGS fits whose objective is worse than the best failed default
attempt. The two `pdHess = TRUE` smoke rows have finite covariance geometry,
but one still selects a worse fallback objective. The companion
`structured-re-q4-animal-numerical-geometry-attempts.tsv` sidecar stores the
seven optimizer attempts behind those four fits. These tables are diagnostic
stability evidence only: they do not change interval status, coverage status,
`inference_ready`, `supported`, q8 inference, q4 REML, REML, AI-REML,
derived-correlation interval, or broad bridge support.

`structured-re-q4-animal-optimizer-route-diagnostic.tsv` records the matching
optimizer-route smoke for those four animal q4 all-four seeds. It links to
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-optimizer-route-local/structured-re-q4-animal-optimizer-route-diagnostic.tsv`
and stores 20 rows: four seeds crossed with the custom fallback route, the
default ladder without fallback, the robust preset without fallback, two-start
multistart without fallback, and two-start multistart with fallback. The two
failed-Hessian seeds (`910101`, `910102`) were not rescued by any route. The
seven `pdhess_pass_smoke` rows occur only on seeds that already had a passing
baseline route, and the selected-worse-objective rows keep the fallback
objective problem visible. This is diagnostic route evidence only: it does not
change interval status, coverage status, `inference_ready`, `supported`, q8
inference, q4 REML, REML, AI-REML, derived-correlation interval, or broad
bridge support.

`structured-re-q4-animal-start-map-diagnostic.tsv` records the lower-level
start/map follow-up for the same four animal q4 all-four seeds. It links to
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-start-map-local/structured-re-q4-animal-start-map-diagnostic.tsv`
and stores 28 rows: four seeds crossed with all-free default starts, all-free
small-correlation starts, all-free DGP-SD starts, zero-correlation maps with
default and DGP-SD starts, fixed-SD zero-correlation maps, and an all-free fit
seeded from the zero-correlation solution. The start/map diagnostic localizes
the q4 animal blocker to the free q4 correlation block: zero-correlation map
rows pass smoke in 11/12 cases and keep finite covariance geometry, while the
all-free and diagonal-staged all-free strategies remain blocked on seeds
`910101`, `910102`, and `910110`. This is diagnostic start/map evidence only:
it does not change interval status, coverage status, `inference_ready`,
`supported`, q8 inference, q4 REML, REML, AI-REML, derived-correlation
interval, or broad bridge support.

`structured-re-q4-animal-bounded-correlation-diagnostic.tsv` records the
bounded-correlation continuation follow-up for the three hard animal q4
all-four seeds (`910101`, `910102`, and `910110`). It links to
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-bounded-correlation-local/structured-re-q4-animal-bounded-correlation-diagnostic.tsv`
and stores 15 rows: three seeds crossed with the zero-correlation control, the
current unbounded staged fit, and optimizer-layer
`theta = cap * tanh(eta)` continuations at caps `0.50`, `0.80`, and `0.95`.
The zero-correlation controls pass, the current unbounded staged fits remain
gradient/Hessian blocked, and all nine bounded rows reach `pdHess = TRUE` only
by saturating their caps. This is boundary-seeking q4 correlation geometry
evidence only: it does not change interval status, coverage status,
`inference_ready`, `supported`, q8 inference, q4 REML, REML, AI-REML, the
production parameterization, derived-correlation intervals, or broad bridge
support.

The bounded-correlation diagnostic led to the local one-theta release gate
below, which then led to the multi-coordinate MAP/penalty sensitivity gate.
Both gates remain before any DRAC coverage grid. They retain the eight
direct-SD estimands as the only admission targets. A passing zero-correlation
map is not unrestricted all-free support, cap-saturated bounded fits are not
admission evidence, and optimizer-layer ridge stabilization is not a
production prior.

`structured-re-q4-animal-one-theta-release-diagnostic.tsv` records that
one-theta release diagnostic. It links to
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-one-theta-release-local/structured-re-q4-animal-one-theta-release-diagnostic.tsv`
and stores 84 rows: hard seeds `910101`, `910102`, and `910110` crossed with
the 28 assumed lower-triangle `theta_phylo` coordinates. The zero-correlation
controls pass for all three seeds; 73 one-coordinate releases pass the local
smoke gate, nine remain `release_watch`, and two remain `hessian_blocked`
with runaway `theta` and negative `sdr$cov.fixed` eigenvalues. This narrows the
next q4 animal gate toward multi-coordinate MAP/penalty sensitivity or a
production transform, but it is still diagnostic geometry evidence only: it
does not change interval status, coverage status, `inference_ready`,
`supported`, q8 inference, q4 REML, REML, AI-REML, derived-correlation
intervals, or broad bridge support.

`structured-re-q4-animal-map-penalty-sensitivity.tsv` records the follow-up
multi-coordinate MAP/penalty sensitivity diagnostic. It links to
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-map-penalty-local/structured-re-q4-animal-map-penalty-sensitivity.tsv`
and stores 30 rows: the three hard seeds crossed with 10 multi-coordinate
strategies derived from the one-theta non-pass, top-gain, global non-pass, and
all-28 coordinate sets. The unpenalized multi-coordinate releases still show
seven runaway/Hessian-blocked rows and two convergence-watch rows; the 21
ridge-penalized rows stabilize local modes at the optimizer layer. This is a
diagnostic sensitivity result, not a production prior or interval method: it
does not change interval status, coverage status, `inference_ready`,
`supported`, q8 inference, q4 REML, REML, AI-REML, derived-correlation
intervals, production parameterization, or broad bridge support.

`structured-re-q4-animal-ridge-continuation-diagnostic.tsv` records the
annealing follow-up to the MAP/penalty diagnostic. It links to
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-ridge-continuation-local/structured-re-q4-animal-ridge-continuation-diagnostic.tsv`
and stores 36 rows: hard seeds `910101`, `910102`, and `910110` crossed with
`seed_nonpass`, `global_nonpass`, and `all28` coordinate sets and the ridge
schedule `1 -> 0.1 -> 0.01 -> 0`. Twenty-five penalized stages stabilize local
modes, but final `lambda = 0` stages have zero clean admission passes: six are
runaway/Hessian-blocked, two are convergence-watch, and one is a large-theta
watch. This keeps q4 animal admission local and diagnostic; it does not change
interval status, coverage status, `inference_ready`, `supported`, q8
inference, q4 REML, REML, AI-REML, derived-correlation intervals, production
parameterization, or broad bridge support.

`structured-re-q4-animal-partial-cholesky-transform-diagnostic.tsv` records
the local partial-Cholesky coordinate diagnostic for the same animal all-four
hard seeds. It links to
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-cholesky-transform-local/structured-re-q4-animal-partial-cholesky-transform-diagnostic.tsv`
and stores nine rows: three zero-correlation controls, three current all-free
reference fits, and three all-free partial-correlation Cholesky coordinate
fits. The partial-Cholesky route has zero clean admission passes: all three
partial rows have convergence code 1 and `pdHess = FALSE`; seeds `910101` and
`910110` are additionally large-eta blocked, and direct-SD interval finiteness
is only 7/8, 0/8, and 2/8. This is a blocked local diagnostic, not a cluster
candidate: it does not change interval status, coverage status,
`inference_ready`, `supported`, q8 inference, q4 REML, REML, AI-REML,
derived-correlation intervals, production parameterization, or broad bridge
support.

`docs/dev-log/after-task/2026-06-29-q-series-q4-animal-partial-correlation-hard-seed-smoke.md`
records the follow-up hidden TMB partial-correlation hard-seed smoke. Unlike
the optimizer-layer diagnostic above, this route reached the public all-four
fit and converged for seeds `910101`, `910102`, and `910110`, but still failed
admission because all three retained fits had `pdHess = FALSE`. The output
bundle is
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local/`.
The result keeps the high-q row in `q8_stability_blocked` and makes the next
gate Hessian/geometry diagnosis, not cluster admission.

`structured-re-q4-animal-transform-admission-contract.tsv` records the
seven-row admission contract that turns the animal q4 hard-seed diagnostics
into a cluster-use gate. It separates the zero-correlation reference, current
all-free route, fixed soft-cap route, sparse one-theta localization route,
ridge MAP/penalty sensitivity route, ridge-continuation annealing route, the
blocked partial-Cholesky coordinate diagnostic, and the required next
production-transform experiment. The contract now routes that
experiment through
`docs/design/220-structured-q4-animal-production-transform-gate.md`: member
review says another optimizer-layer wrapper around current `theta_phylo` is not
a production transform. The contract keeps Nibi/Rorqual admission and any later
DRAC coverage grid on hold until a lower-level TMB parameterization design and
production route pass hard seeds `910101`, `910102`, and `910110` without cap
saturation, optimizer-layer ridge penalties, large-theta rows,
convergence-watch rows, or Hessian-blocked multi-coordinate rows. It does not
change interval status, coverage status, `inference_ready`, `supported`, q8
inference, q4 REML, REML, AI-REML, derived-correlation intervals, production
parameterization, or broad bridge support.

`structured-re-q4-admission-denominator-contract.tsv` records the Tranche 3 q4
admission-denominator contract before any coverage launch. It covers the
ordinary q4 location comparator, structured q4 location and all-four-intercept
cells for `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and
K-matrix `relmat()`, the q8-shaped all-four one-slope hold rows, and the
phylo bivariate direct-SD diagnostic row. The contract freezes the retained
denominator, convergence, `pdHess`, gradient, profile-warning, boundary, finite
direct-SD interval, and derived-correlation gates. Every row is
`do_not_promote`: it does not change fit status, interval status, coverage
status, `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
derived-correlation interval support, broad bridge support, or public support.

`structured-re-q4-admission-review-synthesis.tsv` records the Tranche 3 q4
admission review against current evidence. It keeps the same 14-row scope as
the denominator contract, but replaces the pre-compute gate with the current
review decision. The q4 location rows fail admission because existing SR475
retained-denominator evidence has `pdHess`/Wald-finite rates below 95%. The
all-four intercept rows fail on denominator precheck evidence: phylo, spatial,
and relmat are `pdHess`/finite-interval blocked, while animal is
bootstrap-nonfinite. The q8-shaped all-four one-slope rows remain
design-first Hessian/geometry holds, and the bivariate direct-SD row remains
diagnostic visibility only. Every row is `do_not_promote`, with coverage
`coverage_not_authorized`; this is a no-admission/no-coverage Tranche 3
decision artifact, not an interval or support promotion.

`structured-re-q4-location-target-admission-map.tsv` records the exact
target-level q4 location admission map required before any q4 coverage design.
It links the 16 direct-SD provider/endpoint members to their dispatch-plan
`profile_targets()` names and to the SR475 retained-denominator source rows.
Every row remains `not_admitted_cell_pdhess_below_threshold`,
`coverage_not_authorized`, and `do_not_promote`; it is a no-claim map, not
interval reliability, coverage, `inference_ready`, `supported`, q4 REML, REML,
AI-REML, q8 inference, derived-correlation interval support, broad bridge
support, or public support.

`structured-re-q4-location-admission-runner-design.tsv` records the Tranche 4
q4 location admission-runner design before any retained-denominator smoke is
executed. It maps one-to-one to the same 16 direct-SD `profile_targets()` rows,
sets the first smoke size to `n_rep_planned = 5`, and requires host provenance
plus separate Totoro/DRAC denominators. The runner design retains fit errors,
nonconvergence, `pdHess = FALSE`, gradient/profile warnings, boundary
estimates, finite direct-SD Wald/profile intervals, derived-correlation
unavailable status, and every attempted replicate. Every row remains
`coverage_not_authorized` and `do_not_promote`; this is design-only, not runner
execution, denominator evidence, interval reliability, coverage,
`inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
derived-correlation interval support, broad bridge support, or public support.

`structured-re-q4-location-admission-smoke.tsv` records the Tranche 4 local
`n = 5` retained-denominator admission smoke for the same 16 q4 location
direct-SD targets. Its raw retained target rows live in
`docs/dev-log/simulation-artifacts/2026-07-01-q4-location-admission-smoke/structured-re-q4-location-admission-smoke-results.tsv`.
Phylo, spatial, and animal fail the first local smoke gate because their
retained `pdHess`/Wald-finite rates are 2/5, 3/5, and 4/5 respectively for
each provider target; relmat is 5/5 on retained `pdHess`, Wald-finite, and
profile-finite rows but remains review-required with no admission claim. Every
row keeps `coverage_not_authorized` and `do_not_promote`; this is local
retained-denominator evidence, not interval reliability, coverage,
`inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
derived-correlation interval support, broad bridge support, or public support.

`structured-re-q4-location-admission-tranche5-review.tsv` records the Tranche
5 q4 location admission decision gate. It uses the Tranche 4 local smoke as
review input only: the 16 target rows keep `coverage_not_authorized` and
`do_not_promote`; phylo and spatial stay on diagnostic hold, animal requires
failure taxonomy before any top-up, and relmat is only a host-separated repeat
candidate after Rose/Fisher/Gauss/Noether/Grace review. The sidecar also banks
provider summaries, the overall zero-admission decision, Kim's
least-compute-needed rule, and member-board rows for every standing reviewer.
It authorizes no coverage grid and does not promote interval reliability,
`inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
derived-correlation interval support, broad bridge support, or public support.

`structured-re-q4-location-admission-tranche5-relmat-repeat.tsv` records the
host-separated Totoro repeat that Tranche 5 allowed after blocking-reviewer
approval. The repeat covers only the relmat q4 location direct-SD targets, links
to the copied Totoro raw results and run log under
`docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche5-relmat-repeat-totoro/`,
and keeps the source SHA, dirty flag, host label, and remote output path visible.
All four relmat targets have 5/5 retained `pdHess`, Wald-finite, and
profile-finite rows, with gradient/profile diagnostics retained. The repeat is
still post-run review evidence only: it does not admit q4, pool denominators,
authorize coverage, or promote interval reliability, `inference_ready`,
`supported`, q4 REML, REML, AI-REML, q8 inference, derived-correlation
intervals, broad bridge support, or public support.

`structured-re-q4-location-admission-tranche6-relmat-review.tsv` records the
post-repeat Rose/Fisher/Grace admission review for relmat q4 location direct-SD
targets. It links each target row to both the Tranche 4 local smoke row and the
Tranche 5 host-separated Totoro repeat row. Local and Totoro rates are kept in
separate columns; both are 5/5 on retained `pdHess`, Wald-finite, and
profile-finite direct-SD rows, while Totoro gradient/profile diagnostics remain
visible. The review records that the relmat direct-SD admission gate is met only
for coverage-design discussion. It still authorizes no coverage grid, does not
pool denominators, does not move the support-cell status, and does not claim
interval reliability, `inference_ready`, `supported`, q4 REML, REML, AI-REML,
q8 inference, derived-correlation intervals, broad bridge support, or public
support. The next gate is a separate relmat-only q4 location coverage pregrid
design contract.

`structured-re-q4-location-tranche7-relmat-coverage-pregrid-contract.tsv`
records that separate Tranche 7 design contract. It names the four relmat q4
location direct-SD coverage pregrid shards, `13` through `16`, with SR150 as a
screen only, Totoro/control-master submission as the primary host route, and
DRAC as fallback after submission-pack review. The contract requires external
source SHA, dirty-state, host-label, seed-manifest, exact-command, run-log, and
Mission Control provenance artifacts because the coverage-grid runner is not
yet the provenance source of truth. Rose, Fisher, and Grace are the blocking
reviewers before any execution. Every row remains `coverage_not_authorized` and
`do_not_promote`; the contract is not a coverage result, interval reliability
claim, `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
derived-correlation interval, denominator pooling, broad bridge support, or
public-support claim.

`structured-re-q4-location-tranche8-relmat-host-submission-pack.tsv` records
the next host submission pack for those same relmat q4 location direct-SD
targets. It banks exact Totoro and DRAC fallback commands, source SHA and dirty
state capture, host-label policy, expected output/log paths, and fail-closed
helper scripts: `tools/run-q4-location-relmat-pregrid-totoro.sh` for the
host-side Totoro path and `tools/slurm/q4-location-relmat-pregrid.sbatch` for
the relmat-only DRAC fallback. Both helpers require explicit
`DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace` before execution. The pack
is still not a run: every row stays `pack_banked_not_submitted`,
`coverage_not_authorized`, and `do_not_promote`; no Totoro command was executed,
no DRAC job was submitted, no result was imported, and no interval reliability,
`inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
derived-correlation interval, denominator pooling, broad bridge support, or
public-support claim is made.

`structured-re-q4-location-tranche34-relmat-host-preflight.tsv` records the
fresh host preflight requested by the Tranche 8 next gate. Totoro is reachable
through the ControlMaster route and has `Rscript` 4.5.3, but the path
`/home/snakagaw/codex/drmTMB` is not a normal source checkout for this run: git
resolves the top level to `/home/snakagaw`, `HEAD` is unavailable, the Tranche 8
Totoro wrapper is missing, and the relmat-only DRAC fallback script is missing
there as well. Grace therefore blocks execution before any fit starts. Every
row remains `no_compute_in_tranche34`, `coverage_not_authorized`, and
`do_not_promote`; no Totoro command was executed, no DRAC job was submitted, no
coverage-evaluable denominator was created, and no interval reliability,
`inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
derived-correlation interval, denominator pooling, broad bridge support, or
public-support claim is made. The next gate is source synchronization or a
verified DRAC fallback checkout, then another host preflight and checkpoint
before q4 relmat pregrid execution.

`structured-re-q4-location-tranche35-relmat-source-snapshot-preflight.tsv`
records the next provenance step. A new isolated Totoro source snapshot was
staged at
`/home/snakagaw/codex/drmTMB-q4loc-tranche35-source-56add7f0-20260702T002713Z`
with `SOURCE-PROVENANCE.tsv` and a 3,057-file `SOURCE-MANIFEST.sha256`; the
local q4 wrapper, q4 coverage runner, and DRAC fallback helper hashes match the
remote manifest. The Totoro wrapper dry-ran all four relmat q4 location shards,
and the execution path failed closed with exit 2 when the
`DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace` token was absent. This is
still source-preflight evidence only: the snapshot is dirty, no fit was run, no
DRAC job was submitted, no coverage-evaluable denominator was created, and no
interval reliability, `inference_ready`, `supported`, q4 REML, REML, AI-REML,
q8 inference, derived-correlation interval, denominator pooling, broad bridge
support, or public-support claim is made. The next gate is Rose/Fisher/Grace
review of dirty snapshot versus clean committed source, then a fresh checkpoint
before at most shard 13 can run.

`structured-re-q4-location-tranche36-relmat-shard13-execution-decision.tsv`
records the Rose/Fisher/Grace decision from that gate. The exact dirty,
manifested Totoro snapshot is accepted for one diagnostic SR150 pregrid shard
only: shard 13, `mu1:(Intercept)`, with source manifest hash
`ea168bf85286f7ac81d622105efd2b566f737384ab8f0d33c48c30994133ccf8`.
The decision does not authorize a four-shard run, DRAC submission, coverage
grid, result import, or status movement. Every row stays
`coverage_not_authorized` and `do_not_promote`; no coverage-evaluable
denominator exists until a terminal review imports retained attempts. The next
gate is a fresh checkpoint, then exactly one Totoro shard with
`DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace`; if command provenance,
host provenance, logs, output paths, or fail-closed guards drift, stop before
importing any result.

`structured-re-q4-location-tranche37-relmat-shard13-terminal-review.tsv`
records the terminal review of that one approved shard. Totoro reached the q4
runner, captured source and host provenance, and wrote 150 retained replicate
rows, but every row is `not_attempted`: `drmTMB` was not loadable and
`--attempt-temp-install` was not requested. The review therefore overrides the
runner's generic pending-MCSE wording with
`no_coverage_evaluable_denominator`. No retry is authorized. The next gate is a
reviewed loadable-source route, such as wrapper support for
`--attempt-temp-install` or a preinstalled matching `drmTMB` library, followed
by a new source snapshot, dry-run, checkpoint, and Rose/Fisher/Grace approval
before any retry.

`structured-re-q4-location-tranche38-relmat-temp-install-route-contract.tsv`
records the reviewed loadable-source route contract after the Tranche 37 load
blocker. The Totoro wrapper now exposes both `--attempt-temp-install` and
`DRMTMB_Q4LOC_ATTEMPT_TEMP_INSTALL=true`, and dry-run output shows the flag is
forwarded to `tools/run-structured-re-q4-location-coverage-grid.R` for shard 13.
The execute path still fails closed without
`DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace`. Tranche 38 runs no fit,
retries no shard, creates no denominator, and supersedes the old Tranche 35-36
helper hash for future execution planning. The next gate is a fresh Totoro
source snapshot with the new wrapper hash, a Totoro dry-run for shard 13 with
`--attempt-temp-install`, a checkpoint, and Rose/Fisher/Grace approval before
any retry.

`structured-re-q4-location-tranche39-relmat-source-snapshot-dryrun.tsv`
records that fresh Totoro source snapshot and dry-run proof. The snapshot at
`/home/snakagaw/codex/drmTMB-q4loc-tranche39-source-56add7f0-20260702T012433Z`
has source provenance, a 3,770-line SHA-256 manifest, wrapper hash
`9133474766f6968f4344871e48c8b8a92cfdedc2bfff15e94a6fcc4b3afa9b8c`, and a
dry-run transcript from the snapshot showing shard 13 with
`--attempt-temp-install`. No package temp install was executed, no fit ran, no
retry happened, and no denominator was created. The next gate is a checkpoint
and Rose/Fisher/Grace approval before exactly one shard-13 retry from this
snapshot.

`structured-re-q4-location-tranche40-relmat-shard13-execution-gate.tsv`
records that approval gate. A remote Totoro probe confirmed that the Tranche
39 snapshot still exists, the wrapper is executable, and the manifest,
provenance, wrapper, coverage-runner, and DRAC sbatch hashes still match the
banked source-snapshot proof. Rose/Fisher/Grace approve only one shard-13
temp-install retry after a checkpoint, from that snapshot and the planned
Tranche 40 run root, with
`DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace`. Tranche 40 itself executes
no R runner, attempts no package temp install, runs no fit, creates no retained
denominator, authorizes no coverage, and moves no support-cell status. The next
gate is a Tranche 41 terminal review before any denominator or status
discussion.

`structured-re-q4-location-tranche41-relmat-shard13-terminal-review.tsv`
records that one approved shard-13 retry did run and stopped before fitting.
The runner requested `--attempt-temp-install`, but the temporary package install
failed because `TMB` and `RcppEigen` were unavailable on Totoro. The imported
artifact has 150 replicate rows, all `not_attempted`, with zero fits, zero
`pdHess`, zero finite Wald intervals, and zero finite profile intervals. The
terminal review overrides the runner's generic `pending_mcse_check` wording
with `no_coverage_evaluable_denominator`; no retry, shards 14-16, DRAC
submission, coverage, or status movement is authorized. The next gate is a
dependency route for `TMB` and `RcppEigen` availability on Totoro or a
source-and-dependency-provenanced DRAC fallback.

`structured-re-q4-location-tranche42-relmat-dependency-route-preflight.tsv`
records that dependency-route preflight. The Totoro probe found R 4.5.3, a
writable user library at `/home/snakagaw/R/lib`, installed `Rcpp` and `Matrix`,
reachable CRAN metadata for `TMB` 1.9.21 and `RcppEigen` 0.3.4.0.2, and a
usable gcc/g++ toolchain. It also confirms that `TMB` and `RcppEigen` are not
installed yet. This is a route contract only: no dependency install, q4 retry,
shard execution, DRAC submission, package load proof, denominator, coverage, or
status movement happened in Tranche 42. The next gate is a checkpointed
Totoro-only install of `TMB` and `RcppEigen` into the user library, with install
logs and dependency provenance banked before any retry or denominator
discussion.

`structured-re-q4-location-tranche43-relmat-dependency-install-terminal-review.tsv`
records that Totoro-only dependency install. The first install script failed
before installation because the `download.packages()` matrix was parsed as if
it had column names; the second attempt installed `RcppEigen` 0.3.4.0.2 and
`TMB` 1.9.21 into `/home/snakagaw/R/lib` from CRAN source tarballs, recorded
SHA-256 hashes for both tarballs, and verified `requireNamespace()` for both
packages. This is dependency-install evidence only: no `drmTMB` load, q4 fit,
q4 retry, shard execution, denominator, coverage, or support-cell status
movement happened in Tranche 43. The next gate is a checkpoint and
Rose/Fisher/Grace approval before exactly one relmat q4 shard-13 temp-install
retry from the Tranche 39 source snapshot, followed by a Tranche 44 terminal
review before any denominator or status discussion.

`structured-re-q4-location-tranche44-relmat-shard13-after-deps-terminal-review.tsv`
records that single approved after-dependency-install retry. The Totoro shard
ran from the Tranche 39 source snapshot with
`DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace` and
`--attempt-temp-install`; `drmTMB` loaded, the run exited 0, and all 150
replicates fit. Admission still failed because retained-denominator `pdHess`
and Wald-finite rates were both 112/150 = 0.7467, below the 0.95 admission
threshold, despite profile-finite rate 149/150 = 0.9933. This is terminal
review evidence only: no denominator admission, no coverage authorization, no
shards 14-16, no DRAC submission, no top-up, no q4 support-cell status
movement, no interval-reliability claim, no `inference_ready`, and no
`supported` status. The next gate is a checkpointed relmat q4 route-hold and
failure-taxonomy decision reviewed by Rose/Fisher/Grace before any retry or
coverage discussion.

`structured-re-q4-location-tranche45-relmat-after-deps-route-hold-failure-taxonomy.tsv`
records that route-hold and failure-taxonomy decision. It reviews the existing
Tranche 44 Totoro shard-13 artifacts without running any new replicate. The
seven rows classify the admission failure as boundary-coupled `pdHess` and
Wald nonfiniteness: 150/150 fits succeeded, but `pdHess` and Wald-finite rates
were only 112/150 = 0.7467, with 38 boundary rows; profile-finite rate was
149/150 = 0.9933 and does not override the failed retained-denominator gate.
All standing reviewers are on the member board, with Rose, Fisher, Gauss,
Noether, and Grace blocking admission or compute decisions. This is taxonomy
only: no compute, no denominator admission, no shards 14-16, no DRAC
submission, no top-up, no coverage authorization, no support-cell movement, no
`inference_ready`, and no `supported` status. The next gate is exactly one
reviewed no-compute failure-class contract or an explicit parking decision.

`structured-re-q4-location-tranche46-relmat-boundary-hessian-inspection-contract.tsv`
records that selected failure-class contract. It does not run the inspection.
The seven rows define an artifact-only boundary/Hessian review over the
existing Tranche 44 and Tranche 45 files: boundary-row inventory,
`pdHess`/Wald coupling, optimizer and `NaN` messages, the single profile
exception, raw Hessian artifact availability, direct-SD scale patterns, and a
contract summary. The contract explicitly stops before model refits, Totoro
commands, DRAC submission, remote file fetches, optimizer changes, formula or
profile-target changes, denominator admission, or coverage. The next gate is
either an artifact-only inspection from existing files or an explicit relmat q4
parking decision.

`structured-re-q4-location-tranche47-relmat-boundary-hessian-inspection-result.tsv`
records that artifact-only inspection result. It reads the existing Tranche 44
Totoro shard-13 replicate TSV, summary TSV, log, and provenance files without
running any model or host command. The eight rows show that the 38 boundary rows
are exactly the 38 `pdHess = FALSE` rows and exactly the 38 Wald-nonfinite rows;
replicate 119 / seed 980118 is the single profile failure; fallback optimizer
and `NaN` messages are diagnostic only; and the imported artifact tree does not
contain raw Hessian or eigenstructure files. The retained-denominator admission
gate remains failed at 112/150 = 0.7467 for `pdHess` and Wald finiteness, so the
result authorizes no denominator admission, coverage, top-up, replay, shards
14-16, DRAC submission, Totoro command, support-cell movement,
`inference_ready`, or `supported` status. The next gate is to park relmat q4 or
write a separate design/instrumentation contract before any compute.

`structured-re-q4-location-tranche48-relmat-parking-decision.tsv` records that
parking decision. It parks the failed relmat q4 `mu1` direct-SD admission route
after the Tranche 47 inspection: `pdHess` and Wald-finite rates remain
112/150 = 0.7467, the 38 boundary rows are exactly the 38 `pdHess = FALSE` and
Wald-nonfinite rows, and the imported artifact tree still lacks raw Hessian or
eigenstructure evidence. This does not change the underlying support cell,
which remains `point_fit`, `extractor_ready`, `fixture_parity`,
`diagnostic_only`, `planned`, and `source`. Every row is
`no_compute_in_tranche48`, `coverage_not_authorized`, and `do_not_promote`. The
route can reopen only through a reviewed design or instrumentation contract
approved by Rose/Fisher/Gauss/Noether/Grace and checkpointed before compute.

`structured-re-q4-admission-tranche3-closure-audit.tsv` records the Tranche 3
q4 admission closure audit. It ties the clean checkpoint recheck, high-q
orientation, denominator contract, admission review, target map, compute policy,
and no-promotion status audit into a seven-row source-linked decision ledger.
Every row remains `coverage_not_authorized` and `do_not_promote`; this closes
the current q4 admission-before-coverage tranche without launching a q4 coverage
grid and without claiming interval reliability, `inference_ready`, `supported`,
q4 REML, REML, AI-REML, q8 inference, derived-correlation intervals, broad
bridge support, or public support.

`structured-re-q4-slope-hessian-geometry.tsv` records the follow-up
Hessian-geometry audit for those same provider-variant fits. It links to
`docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-hessian-geometry/structured-re-q4-slope-hessian-geometry-results.tsv`
and records one row for each `strong` / `more_levels` variant crossed with
`phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()`. All eight fits converged with `pdHess = FALSE`; all eight had
nonfinite `sdr$cov.fixed`, raw TMB Hessian extraction was unavailable for
random-effect models, and all four sigma-endpoint direct SD targets were at the
lower bound in every row. Seven rows selected the fallback optimizer. This is
diagnostic negative evidence only: denominator admission, interval reliability,
coverage, q4 REML, AI-REML, broad bridge support, public support, and broader
q8 support remain unpromoted.

`structured-re-q4-slope-sigma-axis-differential.tsv` records the first
reduced-axis contrast for those q4 all-four one-slope cells. It links to
`docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-sigma-axis-differential/structured-re-q4-slope-sigma-axis-differential-results.tsv`
and records three rows per provider-variant: the existing all-four baseline,
a `mu1+mu2` intercept-plus-slope partial axis, and a `sigma1+sigma2`
intercept-plus-slope partial axis. The all-four rows reproduce the
Hessian-blocked lower-bound sigma geometry. The `mu1+mu2` partial-axis rows now
fit for `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and
K-matrix `relmat()` with four direct SD targets, `pdHess = TRUE`, and finite
positive `sdr$cov.fixed`; they are recorded as exact diagnostic native
point-fit/extractor q4 location cells in
`structured-re-q-series-support-cells.tsv`. The `sigma1+sigma2` partial-axis
rows remain blocked by the current partial location-scale guard because
matching labelled intercepts in all four endpoints are required. This is
diagnostic runtime evidence only: it does not promote bridge parity, partial
location-scale support, interval reliability, coverage, q4 REML, AI-REML, broad
bridge support, public support, or broader q8 support.

`structured-re-q4-location-slope-parity-fixture.tsv` records deterministic
same-target native/direct/R-via-Julia fixture parity for the exact four-member
q4 location `mu1+mu2` endpoint map across `phylo()`, fixed-covariance
`spatial()`, A-matrix `animal()`, and K-matrix `relmat()`. The linked
q-series rows move to `fixture_parity` and `fixture_not_coverage`, but interval
and coverage statuses remain planned. The `relmat()` row is a K-matrix contract
only; Q precision marshalling remains separate and the sidecar does not claim
K/Q same-target parity, partial location-scale support, interval reliability,
coverage, q4 REML, AI-REML, broad bridge support, public support, or broader
q8 support.

`structured-re-q4-location-slope-interval-diagnostic-plan.tsv` records the
target-level interval diagnostic plan for the same exact q4 location cells. It
contains 40 planned rows: four direct-SD targets and six derived-correlation
targets per provider. Direct-SD rows are future Wald/profile/bootstrap smoke
targets, while derived-correlation rows remain blocked until derived interval
reconstruction is designed. The sidecar keeps denominators, interval
reliability, coverage, q4 REML, AI-REML, broad bridge support, public support,
partial location-scale support, Q precision marshalling, K/Q same-target
parity, and broader q8 support unpromoted.

`structured-re-q4-location-slope-interval-diagnostic-status.tsv` records the
bounded deterministic direct-SD interval smoke for those q4 location cells. The
strong fixture fit converged with `pdHess=TRUE` for `phylo()`,
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`;
Wald and profile intervals were finite for all 16 direct-SD targets. Bootstrap
is recorded as `not_run_smoke_budget` because a complete bootstrap pass is too
slow for this local dashboard smoke and must move to a bounded denominator or
coverage runner. The sidecar remains diagnostic only: derived-correlation
intervals, interval reliability, coverage, q4 REML, AI-REML, broad bridge
support, public support, partial location-scale support, Q precision
marshalling, K/Q same-target parity, and broader q8 support stay unpromoted.

`structured-re-q4-location-slope-bootstrap-budget-probe.tsv` records a
representative bootstrap-cost probe for the same q4 location cells. It runs
only the `phylo()` `mu1:(Intercept)` direct-SD target with two bootstrap refits
and records fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()` as `not_run_after_phylo_budget_probe` after the local runtime
boundary was exposed. The next gate is a reviewed Totoro or DRAC/totoro
provider-rotating denominator runner; this sidecar does not admit all-target
bootstrap denominators, derived-correlation intervals, interval reliability,
coverage, q4 REML, AI-REML, broad bridge support, public support, partial
location-scale support, Q precision marshalling, K/Q same-target parity, or
broader q8 support.

`structured-re-q4-location-slope-bootstrap-dispatch-plan.tsv` records the
reviewable dry-run dispatch manifest for that next gate. It names all 16
direct-SD provider/target cells, assigns provider-rotating shards, records the
representative budget probe source endpoint, and keeps scheduler and compute
status at `dry_run_not_submitted` and `not_executed`. The sidecar is a Totoro
or DRAC/totoro execution plan only; it does not submit jobs, admit all-target
bootstrap denominators, promote interval reliability or coverage, or change
q4 REML, AI-REML, bridge, public-support, partial location-scale, Q precision,
K/Q parity, or broader q8 boundaries.

`structured-re-q4-location-slope-bootstrap-runner-contract.tsv` records the
fail-closed dry-run runner contract for the same 16 direct-SD provider/target
cells. It validates the dispatch manifest, writes a selected target manifest
and run log, and refuses execution modes other than dry-run. Every row remains
`dry_run_not_submitted`, `not_executed`, `runner_contract_only`, and
`coverage_evaluable = FALSE`; this sidecar does not submit Totoro or DRAC jobs,
admit all-target bootstrap denominators, promote interval reliability or
coverage, or change q4 REML, AI-REML, bridge, public-support, partial
location-scale, Q precision, K/Q parity, or broader q8 boundaries. The runner
also writes provider-filtered dry-run manifests with shard-specific filenames,
so later provider/target rehearsals cannot overwrite the full 16-row contract.
Those shard files are race-safety evidence only, not executed bootstrap
denominators.

`structured-re-type-gaps.tsv` records the remaining structured-type gaps for
`phylo()`, `spatial()`, `animal()`, `relmat()`, and `phylo_interaction()`. It
states what users can run now and which cells remain missing or deferred.

`structured-re-r-docs-api-sync.tsv` records the R documentation and API sync
surface. It keeps dashboard/internal wording separate from public examples and
does not widen formula grammar or user-facing support.

`structured-re-julia-twin-sync.tsv` records the active DRM.jl and drmTMB
branches and heads used by this dashboard pass. It also records that the parked
`/Users/z3437171/Dropbox/Github Local/DRM.jl` Ayumi checkout was not edited.

`structured-re-closeout-package.tsv` records validator, served-widget,
check-log, after-task, hard-boundary, and git-boundary closeout rows. It is a
local recovery surface, not a staging, commit, pull-request, or public support
claim.

Rows marked `verified`, `banked`, or `covered` need evidence. Local evidence
files linked from the dashboard are copied into `/tmp/drm-dashboard` by the
start script so the served page can resolve them. The start script copies every
dashboard TSV by pattern, and the validator rejects copy-list drift when new
TSV ledgers are added.

The `drmTMB` Repo Truth row is refreshed in the served `/tmp` copy at launch
time from `git branch`, `git rev-parse`, and `git status --porcelain`. The
source JSON keeps a placeholder because a committed file cannot truthfully
contain its own final commit hash.

`structured-re-gaussian-mu-slope-tranche84-spatial-drac-smoke-approval-gate.tsv`
records the q1 `mu` one-slope spatial-only DRAC post-staging smoke-approval
review. It accepts the Tranche 83 Rorqual source/run-root staging proof as
provenance evidence, but withholds smoke authorization because the current
Tranche 77 runner and wrapper still require the exact Tranche 73 Totoro source
and run-root paths and refuse the Tranche 83 DRAC paths. The next gate is
Tranche 85 only: a fail-closed DRAC runner-path patch gate with dry-run/refusal
proof. Tranche 84 adds no host command, model fit, retained denominator,
coverage, support-cell status edit, `inference_ready`, or `supported` claim.

`structured-re-gaussian-mu-slope-tranche85-spatial-drac-runner-path-gate.tsv`
records the q1 `mu` one-slope spatial-only DRAC runner-path patch gate. It
adds a T85 R runner and shell wrapper that accept the exact Tranche 83 DRAC
source path and run root, preserve the Tranche 77 helper-source order, keep
the DRAC Rorqual host label, keep `write-dashboard=false`, and keep the
host-separated denominator policy. The local proof is shell-only: manifest
mode writes 10 seed-target rows, execute mode refuses before `Rscript` without
the preserved approval token, and hashes plus a no-Rscript proof are banked.
Tranche 85 adds no SSH, module load, R command, `Rscript`, model fit,
retained denominator, coverage, support-cell status edit, `inference_ready`,
or `supported` claim. The next gate is Tranche 86 only: a post-patch DRAC
smoke-approval review that either authorizes one future host-separated n5
smoke through the T85 wrapper or keeps the route held.

`structured-re-gaussian-mu-slope-tranche86-spatial-drac-smoke-approval-gate.tsv`
records the q1 `mu` one-slope spatial-only DRAC post-patch smoke-approval
gate. It reviews the T85 runner/wrapper hashes, shell manifest proof,
execute-refusal proof, no-Rscript proof, exact T83 DRAC source and run-root
paths, helper-source order, host label, fixed seeds, approval token,
`write-dashboard=false`, and host-separated denominator policy. T86 authorizes
at most one future DRAC Rorqual n5 smoke through the T85 wrapper after
checkpoint, but T86 itself runs no SSH, DRAC command, module load, R command,
`Rscript`, model fit, retained denominator, coverage, support-cell status
edit, `inference_ready`, or `supported` claim. The next gate is Tranche 87
only: a single-command DRAC Rorqual n5 smoke execution/terminal-review tranche.

`structured-re-gaussian-mu-slope-tranche87-spatial-drac-slurm-packet.tsv`
records the q1 `mu` one-slope spatial-only DRAC SLURM-packet blocker. T87
corrects the execution route before compute: Rorqual is reachable through the
remembered ControlMaster socket and the exact T83 source/run-root paths exist,
but the remote T85 runner and wrapper are missing. The local sbatch packet is
fail-closed: it refuses outside `SLURM_CLUSTER_NAME=rorqual` with
`SLURM_JOB_ID` set, checks the exact T85 runner/wrapper hashes, and preserves
the T77 wrapper approval token. T87 submits no `sbatch`, copies no remote file,
loads no module, runs no R command or `Rscript`, fits no model, and creates no
retained denominator, coverage result, support-cell status edit,
`inference_ready`, or `supported` claim. The next gate is Tranche 88 only: a
remote staging proof for the exact T85 runner, T85 wrapper, and T87 sbatch
packet, with remote hashes and a manifest-only no-R proof before any later
sbatch submission is considered.

`structured-re-gaussian-mu-slope-tranche88-spatial-drac-remote-staging-proof.tsv`
records the q1 `mu` one-slope spatial-only DRAC remote staging proof. T88 stages
the exact T85 runner and wrapper plus the T87 sbatch packet on Rorqual under the
exact T83 source/run-root paths, verifies remote SHA-256 hashes, chmods the
wrapper and sbatch packets, runs shell syntax checks, and runs wrapper manifest
mode only. T88 submits no `sbatch`, loads no module, runs no R command or
`Rscript`, fits no model, and creates no retained denominator, coverage result,
support-cell status edit, `inference_ready`, or `supported` claim. The next
gate is Tranche 89 only: a separate Rose/Fisher/Gauss/Noether/Grace-reviewed
Rorqual sbatch submission and terminal-review tranche after checkpoint.

`structured-re-gaussian-mu-slope-tranche89-spatial-drac-sbatch-terminal-review.tsv`
records the q1 `mu` one-slope spatial-only DRAC sbatch terminal review. T89
submitted exactly one Rorqual job, `15084376`, through the staged run-root
packet. The job reached node `rc31728` and failed after two seconds before model
fitting because the wrapper path guard compared an existing run root normalized
to `/lustre09/project/6098264/...` with a not-yet-created output directory that
remained under `/project/def-snakagaw/...`. The absent result directory and
imported wrapper stderr are failure-taxonomy evidence only: T89 creates zero
retained denominators, no `pdHess`, no Wald/profile interval evidence, no
coverage result, no support-cell status edit, no `inference_ready`, and no
`supported` claim. The next gate is Tranche 90 only: a no-compute path-alignment
patch/review before any repeat sbatch is considered.

`structured-re-gaussian-mu-slope-tranche90-spatial-drac-path-alignment-patch-review.tsv`
records the q1 `mu` one-slope spatial-only DRAC path-alignment patch review.
T90 patches the local T85 R runner so missing output paths are normalized
through their nearest existing parent before comparison with the exact T83 run
root, and refreshes the local T87 sbatch packet's expected runner hash. The
shell wrapper is unchanged and keeps its raw exact-run-root prefix guard. T90
runs only local parse, shell syntax, manifest-only, and approval-refusal checks:
no SSH, no remote copy, no `sbatch`, no module load, no R package load, no
`devtools::load_all()`, no smoke command, no model fit, no retained
denominator, and no support-cell status edit. The next gate is Tranche 91 only:
a no-compute remote restaging proof for the patched runner and sbatch packet,
with remote hashes and manifest-only no-R proof before any repeat sbatch is
considered.

`structured-re-gaussian-mu-slope-tranche91-spatial-drac-remote-restaging-proof.tsv`
records the q1 `mu` one-slope spatial-only DRAC remote restaging proof. T91
restages the T90-patched T85 runner, unchanged wrapper, and refreshed T87
sbatch packet on Rorqual, then records remote SHA-256 hashes, executable bits,
remote bash syntax checks, and wrapper manifest-only no-R proof. The manifest
has 10 planned seed-target rows plus a header; every row remains
`manifest_only_no_rscript_no_model_no_denominator`, `coverage_not_authorized`,
and `do_not_promote`. T91 runs no `sbatch`, no module load, no R command, no
`Rscript`, no package load, no smoke command, no model fit, no retained
denominator, no coverage result, and no support-cell status edit. The next gate
is Tranche 92 only: a separate Rose/Fisher/Gauss/Noether/Grace-reviewed sbatch
authorization gate after checkpoint.

`structured-re-gaussian-mu-slope-tranche92-spatial-drac-sbatch-authorization-gate.tsv`
records the q1 `mu` one-slope spatial-only DRAC sbatch authorization gate. T92
reviews the T91 remote restaging proof, exact runner/wrapper/sbatch hashes,
manifest-only no-R proof, host label, seeds, direct-SD target identity, and
host-separated denominator policy. It authorizes at most one future Rorqual
sbatch through the T91-restaged packet after validation and checkpoint, but T92
itself submits no job and runs no compute. Every row keeps
`not_submitted_in_tranche92`, `no_new_denominator`,
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 93 only: a
single Rorqual sbatch submission and terminal-review tranche that must stop
before coverage, top-up, support-cell status edit, `inference_ready`,
`supported`, public support, REML, AI-REML, or denominator pooling.

`structured-re-gaussian-mu-slope-tranche93-spatial-drac-sbatch-terminal-review.tsv`
records the q1 `mu` one-slope spatial-only DRAC sbatch terminal review. T93
submitted exactly one Rorqual job, `15087685`, through the T91-restaged
run-root sbatch packet. The job reached node `rc32114` and failed with Slurm
state `FAILED`, exit code `1:0`, and elapsed time `00:00:13`. The failure
occurred before package load and before model fit: `wrapper.stderr` reports
that `drmTMB` could not be loaded from the exact T83 DRAC source path, and the
run log records `devtools_load_all_failed` because the Tranche 85 runner
requires `devtools` for `load_all()`. T93 imports 10 manifest rows only, not fit
rows, so every row keeps zero retained denominator, `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is
Tranche 94 only: a no-compute dependency/load-route review before any repeat
sbatch.

`structured-re-gaussian-mu-slope-tranche94-spatial-drac-dependency-load-route-review.tsv`
records the q1 `mu` one-slope spatial-only DRAC dependency/load-route review.
T94 imports the T93 job `15087685` terminal evidence, runner source route,
wrapper stderr, remote-metadata tarball `sessionInfo.txt`, manifest rows, and
run log. It records that the current route requires `devtools::load_all()` from
the exact T83 DRAC source path and that the T93 R session had R 4.4.0 on
AlmaLinux 9.8 with only base packages and `compiler` loaded. T94 runs no ssh,
`sbatch`, module load, R command, `Rscript`, package load, `load_all()`, or
model fit. Every row keeps `no_new_denominator`, `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is
Tranche 95 only: a no-compute dependency-staging/load-route contract before any
repeat Rorqual sbatch or model command.

`structured-re-gaussian-mu-slope-tranche95-spatial-drac-dependency-staging-contract.tsv`
records the q1 `mu` one-slope spatial-only DRAC dependency-staging contract.
T95 converts the T94 load blocker into an economical route decision: broad
`devtools` staging is rejected for this tranche, the base-R staged-library
`R CMD INSTALL` plus `library(drmTMB)` route is selected for a future T96
no-model proof, and `pkgload` plus manual-source fallbacks are held until that
proof or explicit review needs them. T95 runs no ssh, `sbatch`, module load, R
command, `Rscript`, package install, package load, `devtools::load_all()`,
`pkgload::load_all()`, or model fit. Every row keeps `no_new_denominator`,
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 96 only: a
no-model/no-sbatch dependency proof of the base-R staged-library route before
any repeat Rorqual sbatch or model command.

`structured-re-gaussian-mu-slope-tranche96-spatial-drac-dependency-proof.tsv`
records the q1 `mu` one-slope spatial-only DRAC dependency proof. T96 reached
Rorqual as `snakagaw`, loaded the `StdEnv/2023`, `gcc/12.3`, and `r/4.4.0`
module route, confirmed the exact T83 source and run root exist, and attempted
only `R CMD INSTALL` into a run-local library. The proof failed closed because
`cli`, `TMB`, and `RcppEigen` were not available; `library(drmTMB)` was not
attempted after that install failure. T96 runs no `sbatch`, smoke runner,
simulation, model formula, or model fit. Every row keeps `no_new_denominator`,
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 97 only: a
no-model/no-sbatch dependency-install/staging contract for `cli`, `TMB`, and
`RcppEigen`, or an existing DRAC module/library route, before any repeat
Rorqual sbatch or model command.

`structured-re-gaussian-mu-slope-tranche97-spatial-drac-dependency-install-staging-contract.tsv`
records the q1 `mu` one-slope spatial-only DRAC dependency-install staging
contract. T97 imports the T96 missing-dependency blocker, limits the dependency
scope to `cli`, `TMB`, and `RcppEigen`, and selects a T98-only proof route:
probe default/project libraries first, then install exactly `cli`, `RcppEigen`,
and `TMB` into `Rlib-tranche98` only if the host policy is login-node safe. T97
runs no ssh, remote command, module load, R command, `Rscript`, package install,
package load, `R CMD INSTALL`, `library(drmTMB)`, `sbatch`, smoke runner,
simulation, model formula, or model fit. Every row keeps `no_new_denominator`,
`coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 98 only: a
no-model/no-sbatch dependency-install proof that either proves the run-local
dependency route and package load or stops with an allocation contract.

`structured-re-gaussian-mu-slope-tranche98-spatial-drac-dependency-install-proof.tsv`
records the q1 `mu` one-slope spatial-only DRAC dependency-install proof. T98
reached Rorqual as `snakagaw`, loaded `StdEnv/2023`, `gcc/12.3`, and `r/4.4.0`,
probed `.libPaths()` and package availability, and confirmed the exact T83
source and run root still exist. The proof found only the R 4.4.0 module
library on the path and confirmed `cli`, `TMB`, and `RcppEigen` are absent. T98
does not install packages or run `R CMD INSTALL` because compiling on a DRAC
login node is not policy-safe; it also does not load `drmTMB`, submit `sbatch`,
run a smoke runner, run a model formula, or create a retained denominator.
Every row keeps `no_new_denominator`, `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is
Tranche 99 only: an allocation-safe no-model dependency install/load proof via
`sbatch` or `salloc`, still before any repeat model job or coverage work.

`structured-re-gaussian-mu-slope-tranche99-spatial-drac-allocation-install-load-proof.tsv`
records the q1 `mu` one-slope spatial-only DRAC allocation install/load proof.
T99 submitted one Rorqual `sbatch` job (`15094722`) and fetched the terminal
artifacts. The job allocated on `rc32431` but failed after one second before
module load because the DRAC CVMFS profile referenced unset `SKIP_CC_CVMFS`
under `set -u`. T99 therefore records no Rscript, package install,
`R CMD INSTALL`, `library(drmTMB)`, smoke runner, model formula, model fit,
retained denominator, coverage, or support-cell status edit. Every row keeps
`no_new_denominator`, `coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 100 only: a
no-compute shell-profile guard/packet review before any repeat allocation.

`structured-re-gaussian-mu-slope-tranche100-spatial-drac-shell-profile-guard-packet-review.tsv`
records the q1 `mu` one-slope spatial-only DRAC shell-profile guard packet
review. T100 runs locally only: it defines `SKIP_CC_CVMFS` before sourcing the
DRAC CVMFS profile in the T101 candidate packet, moves `set -u` after that
profile source, records the T99 failed-packet hash, records the T101 candidate
packet hash, and passes `bash -n` with empty stderr. T100 performs no ssh,
remote copy, `sbatch`, `salloc`, module load, Rscript, package install,
`R CMD INSTALL`, `library(drmTMB)`, smoke runner, model formula, model fit,
retained denominator, coverage, or support-cell status edit. Every row keeps
`no_new_denominator`, `coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 101 only:
checkpoint first, then at most one allocation-safe no-model dependency
install/load proof with the T100 candidate packet.

`structured-re-gaussian-mu-slope-tranche101-spatial-drac-allocation-install-load-terminal-review.tsv`
records the q1 `mu` one-slope spatial-only DRAC allocation/install-load
terminal review. T101 submitted one allocation-safe no-model Rorqual `sbatch`
job (`15097440`) with the T100 candidate packet. The job completed with
`0:0` on allocation host `rc32607`, but `R` and `Rscript` were
command-not-found after module load, and the packet status file drifted by
recording install/load passes despite command-not-found stderr. T101 is
therefore not dependency-install success evidence, not package-load success
evidence, and not fit evidence. It records no smoke runner, model formula,
model fit, retained denominator, coverage, top-up, or support-cell status
edit. Every row keeps `no_new_denominator`, `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is
Tranche 102 only: checkpoint first, then a no-compute packet/module-executable
status guard review that checks `command -v R` and `command -v Rscript` after
module load and fixes status writes before any repeat allocation.

`structured-re-gaussian-mu-slope-tranche102-spatial-drac-packet-module-executable-status-guard-review.tsv`
records the q1 `mu` one-slope spatial-only DRAC packet/module-executable status
guard review. T102 is local and no-compute: no `ssh`, remote copy, `sbatch`,
`salloc`, module load, R command, Rscript, package install, `R CMD INSTALL`,
`library(drmTMB)`, smoke runner, simulation, model formula, or model fit ran.
The T103 candidate packet records `command -v R` and `command -v Rscript`
after module load, records module list/availability and executable paths, exits
fail-closed if either executable is missing, and writes status rows from real
command exit codes. T102 is not dependency-install success evidence, not
package-load success evidence, not fit evidence, and not retained-denominator
evidence. Every row keeps `no_new_denominator`, `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is
Tranche 103 only: checkpoint first, then at most one allocation-safe no-model
Rorqual `sbatch` dependency install/load proof with the T102 candidate packet.

`structured-re-gaussian-mu-slope-tranche103-spatial-drac-allocation-install-load-terminal-review.tsv`
records the q1 `mu` one-slope spatial-only DRAC allocation/install-load
terminal review. T103 submitted exactly one allocation-safe no-model Rorqual
`sbatch` job (`15102377`) with the T102 candidate packet. The job failed
closed with `127:0` on allocation host `rc32422`: module load returned exit 0,
but both `command -v R` and `command -v Rscript` exited 1. No package install,
`R CMD INSTALL`, `library(drmTMB)`, smoke runner, model formula, model fit,
retained denominator, coverage, top-up, or support-cell status edit occurred.
T103 is not dependency-install success evidence, not package-load success
evidence, not fit evidence, and not retained-denominator evidence. Every row
keeps `no_new_denominator`, `coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`. The next gate is Tranche 104 only:
checkpoint first, then a no-compute module-route/executable resolution review
from the T103 artifacts before any repeat allocation.

`structured-re-gaussian-mu-slope-tranche104-spatial-drac-module-route-executable-resolution-review.tsv`
records the q1 `mu` one-slope spatial-only DRAC module-route/executable
resolution review. T104 is local and no-compute: no `ssh`, `sbatch`, `salloc`,
module load, R command, Rscript, package install, `R CMD INSTALL`,
`library(drmTMB)`, smoke runner, model formula, or model fit ran. It reviews
the T103 artifacts and records the failure taxonomy as module-resolution
ambiguity: T103 module load exited 0, the loaded module list did not contain
`r/4.4.0`, `module avail r` listed `r/4.4.0`, and both executable probes
remained `NA`. T104 is not dependency-install success evidence, not
package-load success evidence, not fit evidence, and not retained-denominator
evidence. Every row keeps `no_new_denominator`, `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`. The next gate is
Tranche 105 only: checkpoint first, then a no-compute module-route packet
patch/contract before any repeat allocation.

`structured-re-gaussian-mu-slope-tranche105-spatial-drac-module-route-packet-contract.tsv`
records that packet contract without executing it. T105 encodes the reviewed
T104 candidate route: load `StdEnv/2023` then `r/4.4.0`, record the module
list, require the loaded module list to contain `r/4.4.0`, require `command -v
R` and `command -v Rscript` before any package install, and fail closed before
install/load/model if either executable guard fails. T105 runs no `ssh`,
`sbatch`, `salloc`, module load, R command, Rscript, package install, `R CMD
INSTALL`, `library(drmTMB)`, smoke runner, model formula, model fit, retained
denominator, coverage, top-up, or support-cell status edit. It is not
dependency-install success, package-load success, fit evidence, admission
evidence, `inference_ready`, `supported`, public support, REML, AI-REML, or
denominator-pooling permission. The next gate is Tranche 106 only: checkpoint
first, then at most one allocation-safe no-model Rorqual module-route/install-
load proof if Rose, Fisher, Gauss, Noether, and Grace approve.

`structured-re-gaussian-mu-slope-tranche106-spatial-drac-module-route-install-load-submission-pending.tsv`
records the submitted-but-pending state for that proof. T106 used the T105
packet and submitted exactly one allocation-safe no-model Rorqual `sbatch` job
(`15103184`) after the checkpoint. Remote preflight passed, the packet hash
matched, and `bash -n` passed remotely. While T106 was first banked the job was
still `PENDING` for scheduler reason `Priority`, so it was not terminal proof,
not module-load success, not R/Rscript success, not dependency-install success,
not package-load success, not fit evidence, and not retained-denominator
evidence. Every row keeps `no_new_denominator`, `coverage_not_authorized`,
`do_not_promote`, and `unchanged_point_fit_planned_planned`.

`structured-re-gaussian-mu-slope-tranche107-spatial-drac-module-route-install-load-terminal-review.tsv`
records the terminal review for the same job. Rorqual job `15103184` allocated
on `rc32522` and failed `127:0` after `00:00:02`. The module-load command
exited 0, but the loaded-module guard failed: `module-list-after-r-load.txt`
did not contain `r/4.4.0` and instead reported no loaded modules matching
`-t`. Therefore no R/Rscript probe, package install, `R CMD INSTALL`,
`library(drmTMB)`, smoke runner, model formula, model fit, retained
denominator, coverage, top-up, or support-cell status edit occurred. T107 is
terminal failure evidence only and authorizes no repeat allocation. The next
gate is Tranche 108 only: a no-compute module-list syntax/route review from
the T107 artifacts before any repeat `sbatch` or `salloc`.

`structured-re-gaussian-mu-slope-tranche108-spatial-drac-module-list-syntax-route-review.tsv`
records that no-compute route review. It runs no new host command, `sbatch`,
`salloc`, module load, R command, Rscript, package install, `R CMD INSTALL`,
`library(drmTMB)`, smoke runner, model formula, model fit, retained
denominator, coverage, top-up, or support-cell status edit. The review keeps
the T107 failure taxonomy narrow: `module list -t` was interpreted as matching
`-t`, while existing Slurm packets use plain `module list` capture. The next
gate is Tranche 109 only: a no-compute packet patch/contract that records the
raw plain module list, requires `r/4.4.0` in that captured list, and then
checks `command -v R` and `command -v Rscript` before any install/load/model
step. T108 is not module-load success, R/Rscript proof, dependency-install
success, package-load success, fit evidence, retained-denominator evidence,
admission evidence, coverage evidence, `inference_ready`, `supported`, public
support, REML, AI-REML, or denominator-pooling permission.

`structured-re-gaussian-mu-slope-tranche109-spatial-drac-module-list-packet-contract.tsv`
banks the corrected local packet contract without executing it. T109 replaces
the failing `module list -t` capture with plain `module list`, requires the raw
captured list to contain `r/4.4.0`, then probes `command -v R` and `command -v
Rscript` and fails closed before package install, `R CMD INSTALL`,
`library(drmTMB)`, smoke runner, model formula, model fit, retained denominator,
coverage, top-up, or support-cell status edit. T109 is not module-load success,
R/Rscript proof, dependency-install success, package-load success, fit evidence,
admission evidence, coverage evidence, `inference_ready`, `supported`, public
support, REML, AI-REML, or denominator-pooling permission. The next gate is
Tranche 110 only: checkpoint first, then at most one allocation-safe no-model
Rorqual module-list/executable proof from the T109 contract if Rose, Fisher,
Gauss, Noether, and Grace approve.

`structured-re-gaussian-mu-slope-tranche110-spatial-drac-module-list-executable-terminal-proof.tsv`
banks the one allocation-safe no-model Rorqual proof from the T109 contract.
T110 submitted exactly one Slurm job (`15104831`), allocated `rc32601`,
completed with exit `0:0`, captured the raw plain `module list` with `r/4.4.0`,
and proved `command -v R` plus `command -v Rscript` resolve to R 4.4.0 CVMFS
paths. The job then stopped before package install, `R CMD INSTALL`,
`library(drmTMB)`, smoke runner, model formula, model fit, retained denominator,
coverage, top-up, or support-cell status edit. T110 is not dependency-install
success, package-load success, fit evidence, admission evidence, coverage
evidence, `inference_ready`, `supported`, public support, REML, AI-REML, or
denominator-pooling permission. The next gate is Tranche 111 only: a no-compute
terminal decision review from existing T110 artifacts before any package-load
proof is considered.


`structured-re-gaussian-mu-slope-tranche111-spatial-drac-package-load-decision-review.tsv`
banks the no-compute terminal decision review from existing T110 artifacts. T111
runs no host command and records that T110 proved only the Rorqual
module/executable route: job `15104831` on `rc32601`, raw `module list` contains
`r/4.4.0`, and `R`/`Rscript` resolve to R 4.4.0 CVMFS paths. T111 is not
package-install success, not package-load success, not fit evidence, not
admission evidence, not coverage evidence, not `inference_ready`, not
`supported`, not public support, not REML/AI-REML, and not denominator-pooling
permission. The next gate is Tranche 112 only: checkpoint first, then at most
one allocation-safe no-model Rorqual package-install/load proof.

`structured-re-gaussian-mu-slope-tranche112-spatial-drac-package-install-load-terminal-review.tsv`
banks the terminal review of that single no-model Rorqual proof. T112 submitted
one Slurm job, `15105466`, on `rc32301`; the `r/4.4.0` module guard and
`R`/`Rscript` executable guard passed, then dependency installation failed
before `R CMD INSTALL` because the allocation could not access the CRAN
`PACKAGES` index and the installer error branch called `conditionMessage()` on
a logical value. T112 is not package-install success, not package-load success,
not fit evidence, not denominator evidence, not coverage evidence, not
`inference_ready`, not `supported`, not public support, not REML/AI-REML, and
not denominator-pooling permission. The next gate is Tranche 113 only: a
no-compute dependency/provenance review before any repeat allocation.

`structured-re-gaussian-mu-slope-tranche113-spatial-drac-dependency-provenance-review.tsv`
banks that no-compute dependency/provenance review from existing T112 artifacts.
T113 ran no host command and records four holds before any repeat allocation:
CRAN `PACKAGES` was unreachable from the T112 allocation, the installer error
branch called `conditionMessage()` on a logical value, `Rlib-tranche112` plus
`Rlib-tranche98` did not make `cli` available, and T112 host provenance reported
`source_sha` as `NA`. T113 is not package-install success, not package-load
success, not fit evidence, not denominator evidence, not coverage evidence, not
`inference_ready`, not `supported`, not public support, not REML/AI-REML, and
not denominator-pooling permission. The next gate is Tranche 114 only: a
no-compute dependency-route packet/contract before any repeat allocation.

`structured-re-gaussian-mu-slope-tranche114-spatial-drac-dependency-route-packet-contract.tsv`
banks that no-compute dependency-route packet/contract from the T113 review. T114
runs no host command and writes only local contract artifacts: a patched
installer-status script that avoids the T112 `conditionMessage()` logical-value
bug, an offline/pre-staged dependency-source route, a source-SHA contract for
`56add7f04fab7bec57a42e56eaeb090dff491863`, a terminal-status contract, and an
unsubmitted candidate T115 sbatch packet. T114 is not package-install success,
not package-load success, not fit evidence, not denominator evidence, not
coverage evidence, not `inference_ready`, not `supported`, not public support,
not REML/AI-REML, and not denominator-pooling permission. The next gate is
Tranche 115 only: checkpoint first, then at most one allocation-safe no-model
Rorqual dependency-route proof if Rose/Fisher/Gauss/Noether/Grace approve.

Tranche 115 then staged the file-backed dependency repository, source-SHA
provenance for `56add7f04fab7bec57a42e56eaeb090dff491863`, and exactly one
Rorqual sbatch job (`15106737`) as a submission-pending snapshot. Tranche 116 is
the terminal review of that same job: `sacct` reports `COMPLETED` with exit
`0:0` on allocation host `rc32501`; the job loaded `r/4.4.0`, matched the source
SHA, and made `cli`, `Matrix`, `RcppEigen`, and `TMB` available through the
staged dependency route. This is dependency-package availability only. It is not
`drmTMB` package-install success, not `R CMD INSTALL` success, not
`library(drmTMB)` success, not fit evidence, not denominator evidence, not
coverage evidence, not `inference_ready`, not `supported`, not public support,
not REML/AI-REML, and not denominator-pooling permission. The next gate is
Tranche 117 only: no-compute package-install/load route packet review before any
further allocation.

`structured-re-gaussian-mu-slope-tranche117-spatial-drac-package-install-load-packet-review.tsv`
banks that no-compute package-install/load packet review. T117 runs no host
command and writes only local packet artifacts: source-SHA and library-path
contracts, a fail-closed R install/load script contract, an unsubmitted
candidate T118 sbatch packet, a terminal-status contract, and a local hash
manifest. It imports the T116 dependency-route success for `cli`, `Matrix`,
`RcppEigen`, and `TMB`, but it does not attempt `R CMD INSTALL`,
`library(drmTMB)`, a smoke runner, a model formula, a model fit, a retained
denominator, coverage, top-up, or a support-cell status edit. The next gate is
Tranche 118 only: checkpoint first, then at most one allocation-safe no-model
Rorqual package-install/load proof if Rose/Fisher/Gauss/Noether/Grace approve.

`structured-re-gaussian-mu-slope-tranche118-spatial-drac-package-install-load-terminal-review.tsv`
banks the terminal review of that one allocation-safe no-model Rorqual proof.
T118 submitted job `15108138` from `rorqual2`; it allocated on `rc32123` and
failed after five seconds with exit `128:0` at the source-SHA guard, before
`R CMD INSTALL`, `library(drmTMB)`, any smoke runner, model formula, model fit,
retained denominator, coverage, top-up, or support-cell status edit. The packet
used `git rev-parse` inside a staged source snapshot that is not a git checkout,
so the next gate is Tranche 119 only: a no-compute source-provenance fallback
packet review that reads `SOURCE-PROVENANCE.tsv` when git metadata are absent.
T118 is not package-install success, not package-load success, not fit evidence,
not denominator evidence, not admission evidence, not coverage evidence, not
`inference_ready`, not `supported`, not public support, not REML/AI-REML, and
not denominator-pooling permission.

`structured-re-gaussian-mu-slope-tranche119-spatial-drac-source-provenance-fallback-packet-review.tsv`
banks the no-compute source-provenance fallback packet review required after
T118. T119 runs no host command and submits no job. It reviews a future T120
candidate packet that first tries git provenance, then reads
`SOURCE-PROVENANCE.tsv` field `source_sha_full` when git metadata are absent,
and writes `t120-terminal-status.tsv` before source-SHA guard exits. The
candidate packet hash is
`54bebceb21547a964d6815dd067115ef73630a4f323d738834b3f2358c980e6e`; the
reviewed source-provenance artifact hash is
`f805565beb238cb1a0711f1c564b37cbfdcafce4f7af0b4ea56dedf53a2e4fdd`. T119 is
not package-install success, not package-load success, not fit evidence, not
retained-denominator evidence, not admission evidence, not coverage evidence,
not `inference_ready`, not `supported`, not public support, not REML/AI-REML,
and not denominator-pooling permission. The next gate is Tranche 120 only:
checkpoint first, then at most one allocation-safe no-model Rorqual
package-install/load proof if Rose/Fisher/Gauss/Noether/Grace approve.

`structured-re-gaussian-mu-slope-tranche120-spatial-drac-package-install-load-terminal-review.tsv`
banks that one Rorqual proof. Job `15109947` was submitted from `rorqual2`,
allocated on `rc32218`, completed with exit `0:0` after `00:09:17`, matched the
source SHA through `SOURCE-PROVENANCE.tsv`, passed the dependency probe, passed
`R CMD INSTALL`, and loaded `drmTMB` 0.1.4. T120 is package-install/load
readiness evidence only: it ran no smoke runner, model formula, model fit,
`pdHess`, Wald/profile interval, retained denominator, admission pass, coverage,
top-up, support-cell status edit, `inference_ready`, `supported`, public
support, REML/AI-REML, or denominator pooling. The q1 `mu` one-slope spatial
support cell remains `point_fit/planned/planned`. The next gate is Tranche 121:
a no-compute model-smoke readiness and admission-boundary review before any
model command.

`structured-re-gaussian-mu-slope-tranche121-spatial-drac-model-smoke-readiness-review.tsv`
banks that review. T121 runs no host command and submits no job; it reviews the
fetched T120 install/load artifacts only and records that they are readiness
evidence for writing a future fail-closed T122 packet/contract, not fit evidence
or denominator evidence. It authorizes no smoke runner, model formula, model fit,
`pdHess`, Wald/profile interval, retained denominator, admission pass, coverage,
top-up, support-cell status edit, `inference_ready`, `supported`, public support,
REML/AI-REML, or denominator pooling. The q1 `mu` one-slope spatial support cell
remains `point_fit/planned/planned`. The next gate is Tranche 122 only: a
no-compute fail-closed model-smoke packet/contract from the T120 artifacts before
any execution tranche.

`structured-re-gaussian-mu-slope-tranche122-spatial-drac-model-smoke-packet-contract.tsv`
banks that packet/contract. T122 is local no-compute work only: it writes the
fail-closed model-smoke contract from the T120 install/load artifacts and T121
review, but runs no host command, submits no job, and evaluates no model
formula. It records the T120 source SHA, job/allocation host, packet hash,
SOURCE-PROVENANCE hash, terminal-status hash, direct-SD target identity, and
future stop rules. T122 is not fit evidence, not `pdHess` evidence, not
Wald/profile interval evidence, not retained-denominator evidence, not admission
evidence, not coverage evidence, not `inference_ready`, not `supported`, not
public support, not REML/AI-REML, and not denominator-pooling permission. The q1
`mu` one-slope spatial support cell remains `point_fit/planned/planned`. The
next gate is Tranche 123 only: a no-compute execution-approval/checkpoint review
before any `sbatch`, host command, smoke runner, model formula, model fit,
retained denominator, coverage, top-up, or support-cell status edit.

`structured-re-gaussian-mu-slope-tranche123-spatial-drac-model-smoke-execution-approval-checkpoint.tsv`
banks that approval checkpoint. T123 is still local no-compute work only: it
reviews the T122 packet, T120 source SHA, T120 job/allocation host, packet hash,
SOURCE-PROVENANCE hash, terminal-status hash, direct-SD target identity, and
host-separated denominator policy, but runs no host command, submits no job, and
evaluates no model formula. It authorizes at most one future host-separated DRAC
Rorqual `n = 5` model-smoke execution in Tranche 124 after checkpoint. T123 is
not fit evidence, not `pdHess` evidence, not Wald/profile interval evidence, not
retained-denominator evidence, not admission evidence, not coverage evidence, not
`inference_ready`, not `supported`, not public support, not REML/AI-REML, and not
denominator-pooling permission. The q1 `mu` one-slope spatial support cell
remains `point_fit/planned/planned`.

`structured-re-gaussian-mu-slope-tranche124-spatial-drac-model-smoke-execution-terminal-review.tsv`
banks the terminal review for the single authorized Rorqual execution. T124
submitted job `15112750` on node `rc31704`; the source SHA and `library(drmTMB)`
guards passed, but the job stopped before the runner because
`devtools_available = FALSE`. It produced no model formula, model fit, `pdHess`,
Wald interval, profile interval, output rows, retained denominator, admission
pass, coverage result, top-up, support-cell status edit, `inference_ready`,
`supported`, public support, REML/AI-REML, or denominator-pooling permission. The
q1 `mu` one-slope spatial support cell remains `point_fit/planned/planned`. The
next gate is Tranche 125 only: a no-compute dependency-route review before any
repeat execution.

`structured-re-gaussian-mu-slope-tranche125-spatial-drac-dependency-route-review.tsv`
banks that no-compute dependency-route review. T125 imports the T124 failure
taxonomy, rejects broad `devtools` prestaging as the first repeat route, and
selects the narrower internal runner path `--load-source=false` so a future
packet can use the installed `drmTMB` that T124 already loaded. T125 updates the
runner and shell wrapper, records local parse/dry-run/manifest evidence, and
runs no SSH command, remote copy, `sbatch`, allocation, module load, model
formula, model fit, retained denominator, coverage, top-up, or support-cell
status edit. The q1 `mu` one-slope spatial support cell remains
`point_fit/planned/planned`. The next gate is Tranche 126 only: a no-compute
patched-runner packet checkpoint before any repeat host-separated Rorqual
execution.

`structured-re-gaussian-mu-slope-tranche126-spatial-drac-patched-runner-packet-checkpoint.tsv`
banks that no-compute patched-runner packet checkpoint. T126 freezes the runner
hash, wrapper hash, source SHA `56add7f04fab7bec57a42e56eaeb090dff491863`,
host label `drac_rorqual_q1mu_slope_spatial_t120_t122_packet_n5`,
`--load-source=false`, the installed-package `library(drmTMB)` route, the local
dry-run hash, and a future T127 sbatch packet hash. T126 runs no SSH command,
remote copy, `sbatch`, allocation, module load, package install, smoke runner,
model formula, model fit, retained denominator, coverage, top-up, or
support-cell status edit. The q1 `mu` one-slope spatial support cell remains
`point_fit/planned/planned`. The next gate is Tranche 127 only: at most one
host-separated Rorqual model-smoke execution after checkpoint and
Rose/Fisher/Gauss/Noether/Grace approval.

Keep `version.txt` equal to the `BUILD` constant in `index.html`. Change both
only when the HTML or JavaScript changes. JSON and TSV data updates do not need
a version bump.
