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

The same q-series support-cell table now includes provider-specific Poisson
and NB2 q1 `mu` one-slope rows for `phylo()`, fixed-covariance `spatial()`,
`animal()`, and `relmat()`. Those rows cite
`tests/testthat/test-count-structured-mu.R` as native TMB ML/Laplace
point-fit and extractor evidence for the exact unlabelled
intercept-plus-one-slope count cells only. Bridge support, intervals,
coverage, REML, AI-REML, q2/q4 count covariance, zero-inflated structured
effects, labelled count covariance, pure or multiple count slopes, and
structured count scale routes remain planned or unsupported unless an exact
future support-cell row says otherwise.

`structured-re-count-slope-fixture-recovery-contract.tsv` records the next
evidence gate for those eight ordinary count one-slope cells. It ties each
Poisson/NB2 provider row to the existing native TMB ML/Laplace point-fit and
extractor evidence, while keeping calibrated recovery `designed_not_run`. The
native deterministic fixture step is now `native_fixture_banked`; this is not
bridge parity. It does not promote bridge support, intervals, coverage, REML,
AI-REML, q2/q4 count covariance, public support, labelled or multiple count
slopes, structured count scale routes, or zero-inflated structured effects.

`structured-re-count-slope-native-fixture-status.tsv` records the eight exact
native-only deterministic fixture rows behind that status. Each row cites
`tests/testthat/test-count-structured-mu.R`; all rows remain ML/Laplace
native TMB point/extractor fixtures only, with bridge parity, calibrated
recovery, intervals, coverage, REML, AI-REML, q2/q4 count covariance, and
public support still separate gates.

`structured-re-count-slope-recovery-runner-contract.tsv` records the dry-run
runner contract for the same eight ordinary count one-slope cells. It is a
selected manifest and run-log contract only: no recovery simulation has been
executed, no Totoro or DRAC job has been submitted, and the rows are not
coverage-evaluable denominator evidence. The contract preserves fit-error,
nonconvergence, `pdHess`, boundary-warning, nonfinite-estimate, seed/provider,
and scheduler-exit retention requirements before any recovery or
public-support wording can move.

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
relmat `K/Q` bridge-boundary row and requires an explicit payload contract for
matrix digest, input scale, `Q` precision source, level alignment, missing-level
policy, coefficient order, and provenance. The rows keep direct DRM.jl,
R-via-Julia, and R bridge `Q` statuses unsupported; native `Q` runtime parity
is not bridge evidence and does not promote intervals, coverage, REML, AI-REML,
public support, or broader q8 support.

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
smoke run. This is still diagnostic-only evidence: the linked q-series cells
keep `interval_status = planned`, `coverage_status = planned`, and
`denominator_policy = fixture_not_coverage`.

`structured-re-sigma-slope-denominator-admission.tsv` records the first
sigma-only one-slope denominator-admission ledger. Seven of eight direct SD
targets are marked `diagnostic_denominator_candidate`; animal `sigma:x`
remains `not_admitted_profile_failure` because the first Wald/profile/bootstrap
smoke still had endpoint-profile failure for that target. Coverage remains
`not_evaluated`, and the linked support cells do not move to interval or
coverage support.

`structured-re-sigma-slope-replicated-denominator-rule.tsv` records the
replicated-denominator rule for those same sigma-only one-slope targets. Seven
targets are `eligible_for_pregrid_with_retention`; animal `sigma:x` remains a
visible holdout until the smoke endpoint-profile failure is reconciled. The
rule requires failed profiles, nonconverged fits, nonfinite intervals, and
bootstrap refit attempts to be retained in any future denominator.

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
for the current q-series lane (#639 through #655). It separates merge-clean
state from ordinary PR-attached checks: #639 has attached green checks against
`main`, while #640 through #655 have green commit-level R-CMD-check evidence
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
more-levels design. All eight provider-variant fits converged, but all eight
returned `pdHess = FALSE`, so the 128 Wald/profile method rows are recorded as
`not_run_pdhess_false`. This is diagnostic negative evidence only: denominator
admission, interval reliability, coverage, q4 REML, AI-REML, broad bridge
support, public support, and broader q8 support remain unpromoted.

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

Keep `version.txt` equal to the `BUILD` constant in `index.html`. Change both
only when the HTML or JavaScript changes. JSON and TSV data updates do not need
a version bump.
