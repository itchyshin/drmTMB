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

Rows marked `verified`, `banked`, or `covered` need evidence. Local evidence
files linked from the dashboard are copied into `/tmp/drm-dashboard` by the
start script so the served page can resolve them.

The `drmTMB` Repo Truth row is refreshed in the served `/tmp` copy at launch
time from `git branch`, `git rev-parse`, and `git status --porcelain`. The
source JSON keeps a placeholder because a committed file cannot truthfully
contain its own final commit hash.

Keep `version.txt` equal to the `BUILD` constant in `index.html`. Change both
only when the HTML or JavaScript changes. JSON and TSV data updates do not need
a version bump.
