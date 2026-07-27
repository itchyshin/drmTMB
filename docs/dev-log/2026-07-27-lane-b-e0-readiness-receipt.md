# Arc E0 — Lane-B interval campaign readiness receipt

## Scope

This receipt records local-only campaign plumbing.  It does not authorise a
pregrid, a DRAC/Totoro request, or any capability/public-status change.

## Immutable cohort

`phase18_interval_campaign_manifest()` derives the eligible cohort directly
from `capability-ledger/cells.tsv` and asserts all of the following each time:

- 159 implemented `point_fit_recovery` model-surface candidates;
- 158 original candidates at `source_order <= 676`;
- exactly one approved addition, `mc-0260m` at source order 694; and
- 18 `missing_response` records retained as foreign exclusions, not failures.

The returned table carries both the source-file MD5 and a canonical manifest
MD5, plus the primary-evidence ID for each worklist row.  This is an internal
reproducibility receipt, not an edit to the ledger.
The exact sorted cell-ID set is also pinned by MD5, so a same-size substitution
cannot silently alter the cohort.

## Fail-closed target contract

The contract table stratifies fixed coefficients and ordinary RE-SD intercepts
and slopes.  It keeps structured candidates by provider/q but deliberately
marks their component as unbound: the capability ledger's legacy route labels
do not reliably distinguish intercept, one-slope, or multi-component blocks.
The reviewed exact binding, rather than a heuristic, must supply that identity.
`rho12` is labelled `excluded_foreign_association` and never enters a Lane-B
campaign route.  K=12 targets are explicitly marked negative controls.

Here K=12 means only the approved `mc-0260m` meta-V small-study-count
condition. It does **not** mean every structured `q12` covariance block:
`q12` names a twelve-dimensional block and is not negative evidence by itself.

Each Lane-B row begins as `needs_exact_dgp_binding`: `dgp_id`, formula, true
parameter scale, profile parameter, and information rung are deliberately `NA`
until an exact route binding is reviewed. The binding API requires every
non-foreign cell, rejects duplicates or partial tables, and fingerprints the
completed table to catch accidental drift. That fingerprint is not a substitute
for the required human review. Consequently no
helper can silently turn the current 159-row census into a runnable pregrid.
Bindings are `cell × target`, rather than a silent one-target choice for a
route-level ledger cell: a cell may carry several direct profile estimands,
but each target must have a unique namespaced `cell_id::target` identity and
the distinct-cell set must still exactly equal the frozen 158 Lane-B cells.
K=12 must remain incomplete or unavailable; a finite K=12 profile is a
fail-closed reducer error, not a finite-profile success.  The reducer uses the
actual profile-success label (`conf.status = "profile"`), rather than the
human-facing message field.

The packet also writes a 158-row binding worklist. It joins every Lane-B
candidate to its primary evidence source and preserves any formula hint already
recorded in the ledger notes, without treating that hint as an executable DGP
binding. On the frozen cohort, 46 rows have such a hint and 112 must be
reconstructed from their cited source records.

It also writes a full-cohort binding inventory. Each recovered target remains
a separate row, while every other frozen cell is present once as
`needs_exact_binding`; therefore a reviewer can see both target cardinality and
unresolved work without treating a partial table as a schedule.

## All-attempt accounting

The seed schedule is deterministic but is unavailable unless every exact
binding is present.  Its rows carry the cell, target, information rung, and
negative-control marker.  The reducer uses the scheduled attempt count as the
denominator and keeps `not_run`, nonfinite, `clamp_limited`, and
trace-incomplete attempts non-covering.  Availability and conditional results
remain descriptive fields; they do not replace all-attempt coverage.  The
readiness-packet writer produces the manifest, contract table, binding worklist,
and runtime receipt only, and always reports `pregrid_authorized = FALSE`. It
also requires a source SHA and writes an RDS runtime receipt containing the R, drmTMB, TMB, and loaded-drmTMB
DLL identities and DLL digest.  The source SHA must equal the Git HEAD at the
declared source root; the receipt also retains its porcelain status.

## Local technical smokes

The local test receipt covers the new manifest/contract/reducer module plus
existing exact-DGP smoke routes for fixed effects, ordinary random intercepts,
ordinary random slopes, and structured direct-SD meta-V.  The latter retains
the K=12 negative-control route.  Additional local exact-DGP checks cover
structured q1, q4, q6, q12, and phylogenetic interaction routes.  These are
technical route checks only, not coverage evidence.

## Validation receipt

At the readiness implementation commit, the readiness unit test and the Arc-D
regression tests pass:

```r
devtools::test(filter = "(arc-d-profile-trace|arc-d-sd-overflow-guard|interval-campaign-readiness)")
```

The local exact-DGP technical smokes also pass for the fixed-effect, ordinary
RE-intercept, ordinary RE-slope, structured q1/q4/q6/q12, and
phylogenetic-interaction fixture routes.  They were run through their existing
focused `testthat` files, with no remote backend and no retained campaign
output.

## Explicit next gate

Before any pregrid packet can be sent, every non-foreign candidate needs a
reviewed exact DGP/formula/truth/profile binding.  The pregrid request must then
name the source SHA, manifest hashes, 150-attempt seed schedule, resource
estimate, output location, validation command, and the no-ledger boundary.
Remote compute remains prohibited unless Shinichi separately approves that
packet.
