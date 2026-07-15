# Arc 3a capability-ledger migration plan

**Verdict: MIGRATED.** The Arc 3a implementation and rejection guards are
present. The primary 6,000-fit campaign plus the separate fresh 2,400-fit
phylogenetic addendum support all three exact cells at
`point_fit_recovery`; no higher inference tier changes.

## Purpose and current contract

Arc 3a must record three narrowly admitted native-TMB model cells:
Gamma × `phylo()` q1 `mu` intercept, lognormal × `phylo()` q1 `mu`
intercept, and lognormal × `relmat()` q1 `mu` intercept. Existing Gamma ×
`relmat()` evidence remains a comparator, not a fourth Arc 3a promotion.

The ledger sources, rather than generated HTML or census files, are the source
of truth; a state edit requires linked evidence and an append-only transition
(`docs/dev-log/dashboard/capability-ledger/README.md:1-27`). The current
generator nevertheless hard-codes both the 668-row denominator and the exact
status counts (`tools/capability_ledger.py:424-426,510-514`), while its test
suite independently asserts 668 model rows
(`tools/tests/test_capability_ledger.py:27-31`). Therefore the three q1
admissions cannot be represented truthfully by editing the four existing rows
alone: the rejected non-intercept/q2+ neighbours also need rows.

## Before state

| Cell | Exact current axes | Current state | Boundary that must change or remain |
|---|---|---|---|
| `mc-0248` | Gamma; `mu`; structured; `relmat`; q1; ML | implemented / verified / `point_fit_recovery` | Preserve unchanged as comparator. It currently covers an intercept and an independent one-slope route, with 90/90 recovery evidence but no interval or coverage claim (`cells.tsv:249`; `tools/tests/test_capability_ledger.py:894-914`). |
| `mc-0251` | Gamma; `mu`; structured; `phylo`; q1; ML | rejected / deferred / none | Its q1 axes are already suitable for the new intercept cell, but its legacy claim also collapses all q gates and REML into this one row (`cells.tsv:252`). |
| `mc-0386` | lognormal; `mu`; structured; `phylo`; q=`na`; ML | rejected / deferred / none | The row represents q1/q2/q4/q6/q8/q12 because lognormal currently rejects before q-specific dispatch (`cells.tsv:387`). |
| `mc-0388` | lognormal; `mu`; structured; `relmat`; q=`na`; ML | rejected / deferred / none | The row similarly represents all q gates and both estimators (`cells.tsv:389`). |

The old rejection evidence and seed transitions must remain immutable history:
`ev-mc-0251-legacy`, `ev-mc-0386-legacy`, and `ev-mc-0388-legacy` document the
pre-Arc 3a engine, while their seed transitions establish the original
`deferred` state (`evidence.tsv:252,387,389`;
`transitions.tsv:252,387,389`).

## Stable-ID and row-splitting strategy

Keep every imported `mc-0001`--`mc-0668` identifier. Re-scope the three
existing provider rows to their now-exact q1 intercept meaning, and append the
next three never-used model IDs for the still-rejected neighbourhood. Do not
renumber any historical model or `mr-*` cell.

The new rejected rows use `q_gate=q2` as the ledger's representative
**beyond-admitted-intercept** marker. Their claim boundaries must explicitly
say that the row also covers unlabelled q1 slope-only/one-slope forms, labelled
or correlated blocks, multiple slopes, and q2/q4/q6/q8/q12. This follows the
existing representative-row convention used for Gamma × `relmat()` beyond
its admitted shapes (`evidence.tsv:251`) and prevents a q1 intercept admission
from implying slope support.

| Cell after migration | `route_variant` | q gate | Capability / work / evidence | Required exact boundary |
|---|---|---:|---|---|
| `mc-0248` | unchanged | q1 | unchanged: implemented / verified / `point_fit_recovery` | Comparator only; do not rewrite its historical one-slope evidence as Arc 3a evidence. |
| `mc-0251` | `base` | q1 | implemented / verified / `point_fit_recovery` | Gamma `mu ~ phylo(1 | id, tree=...)`, native TMB, univariate ML, unlabelled intercept only; no slopes, sigma structure, REML, interval, coverage, inference-ready, or supported claim. |
| `mc-0386` | `base` | q1 | implemented / verified / `point_fit_recovery` | Lognormal `mu ~ phylo(1 | id, tree=...)` on the log-location predictor; same exclusions. |
| `mc-0388` | `base` | q1 | implemented / verified / `point_fit_recovery` | Lognormal `mu ~ relmat(1 | id, K=...)` and only any separately verified representation parity; same exclusions. |
| `mc-0669` | `arc3a_beyond_intercept` | q2 representative | rejected / deferred / none | Gamma × phylo: all slopes, labelled/correlated and multiple-slope blocks, q2+, sigma structure, multiple providers; non-Gaussian REML remains rejected by the separate family-wide REML gate. |
| `mc-0670` | `arc3a_beyond_intercept` | q2 representative | rejected / deferred / none | Lognormal × phylo: the same beyond-intercept boundary. |
| `mc-0671` | `arc3a_beyond_intercept` | q2 representative | rejected / deferred / none | Lognormal × relmat: the same beyond-intercept boundary. |

Append model `source_order` values 669--671. Shift only the 18 `mr-*`
`source_order` values from 669--686 to 672--689 so `source_order` remains a
globally unique monotone display key; the `mr-*` IDs, axes, evidence, work
states, and transitions do not change. Introduce named generator constants
such as `IMPORTED_MODEL_COUNT = 668` and `MODEL_SURFACE_COUNT = 671` rather
than changing the bootstrap's historical 668-row import assertion into a false
claim about the legacy census.

After migration the exact model counts are:

- 671 model cells and 18 missing-response routes;
- 301 implemented, 330 rejected by design, and 40 not implemented;
- 159 implemented cells at `point_fit_recovery` (up from 156);
- Gamma: 25 rows, 7 implemented and 18 rejected;
- lognormal: 25 rows, 7 implemented and 18 rejected.

No `supported`, `inference_ready_with_caveats`, `interval_feasible`, or
`diagnostic_only` count changes.

## Evidence and transition records

For each admitted cell append, rather than replace, at least two evidence
records:

1. an implementation/rejection-contract record pointing to the Arc 3a focused
   test file and exact implementation commit; and
2. a `recovery_test` record pointing to the checked-in compact all-attempted
   summary plus its manifest/hash and reporting attempted, successful,
   convergence, `pdHess`, boundary, bias, and RMSE denominators.

Use the recovery record as `primary_evidence_id`, then append these state
transitions:

- `tr-mc-0251-arc3a-verified`: `deferred -> verified`;
- `tr-mc-0386-arc3a-verified`: `deferred -> verified`;
- `tr-mc-0388-arc3a-verified`: `deferred -> verified`.

Each transition cites both the implementation/rejection-contract evidence and
the recovery evidence. Do not edit the MR-T0 seed transitions.

For `mc-0669`--`mc-0671`, append one direct `rejection_test` record per
provider and a seed transition from blank to `deferred`. The rejection tests
must exercise at least an unlabelled structured slope, a labelled/correlated
form, and a q2+ or multiple-slope form. A source-code inference alone is not
enough for the new primary evidence. New evidence paths must resolve because
the validator applies that rule to every non-legacy record
(`tools/capability_ledger.py:490-500`).

The primary evidence and transition invariants are already enforced: evidence
must belong to the same cell, transition evidence IDs must exist, and the
latest transition must agree with the displayed work state
(`tools/capability_ledger.py:431-452,501-508,528-536`).

## Files to edit

### Authoritative sources

- `docs/dev-log/dashboard/capability-ledger/cells.tsv`
- `docs/dev-log/dashboard/capability-ledger/evidence.tsv`
- `docs/dev-log/dashboard/capability-ledger/transitions.tsv`
- `docs/dev-log/dashboard/capability-ledger/schema.json`
- `tools/capability_ledger.py`
- `tools/tests/test_capability_ledger.py`
- `docs/dev-log/dashboard/capability-ledger/README.md`
- `docs/dev-log/dashboard/README.md`

`schema.json` stays schema version 1 because field shapes and enum semantics do
not change; only `expected_counts.model_surface` changes to 671. The generator
must produce the same value (`tools/capability_ledger.py:183-201`), because
source loading rejects schema drift (`tools/capability_ledger.py:1245-1253`).

Replace public hard-coded 668 strings with `len(model)` or
`MODEL_SURFACE_COUNT`, including the HTML scope, detailed-table text, caption,
and JavaScript filter denominator (`tools/capability_ledger.py:1152-1166,1176`).
Keep the one-time bootstrap language explicitly at 668 imported rows.

### Test additions

Add one focused generator test that asserts:

- the exact 671/18 and 301/330/40 denominators;
- the three admitted IDs are q1, ML, implemented, verified, and exactly
  `point_fit_recovery`;
- their boundaries name intercept-only scope and explicitly exclude REML,
  intervals, coverage, `inference_ready`, and `supported`;
- `mc-0669`--`mc-0671` are q2-representative rejected rows whose boundaries
  retain slopes, labelled blocks, q2+, sigma, and multiple-provider exclusions;
- `mc-0248` remains unchanged;
- all six Arc 3a rows have same-cell primary evidence and a latest transition
  matching work state;
- no duplicate `cell_id`, `source_order`, evidence ID, or transition ID exists;
- `schema.json` and generated outputs match the generator.

The existing fail-closed no-denominator assertion for recovery-grade cells
must continue to pass (`tools/tests/test_capability_ledger.py:907-914`).

## Generated surfaces

Run `python3 tools/capability_ledger.py --write`; do not hand-edit outputs. The
generator owns the census, widget JSON, Markdown/HTML capability surface,
vignette includes, tranche summaries, and per-family TSVs
(`tools/capability_ledger.py:1208-1242`). Content diffs are expected at least in:

- `docs/dev-log/dashboard/capability-census/_master.tsv`;
- `docs/dev-log/dashboard/capability-census/_widget_data.json`;
- `docs/dev-log/dashboard/capability-census/gamma.tsv`;
- `docs/dev-log/dashboard/capability-census/lognormal.tsv`;
- `docs/dev-log/dashboard/capability-surface.md`;
- `docs/dev-log/dashboard/capability-surface.html`;
- `vignettes/includes/capability-ledger-family-map.md`.

Audit every generated path reported by `--write`, even if Git records no
content change. Do not edit the dated 2026-07-11 snapshots or
`capability-census/capability-map.html`; the dashboard README identifies dated
files as archived and the undated surface as canonical
(`docs/dev-log/dashboard/README.md:23-26`).

## Validation commands

Run in this order after implementation and recovery evidence are present:

```sh
python3 tools/capability_ledger.py --write
python3 tools/capability_ledger.py --check
python3 tools/capability_ledger.py --summary
python3 -m unittest tools/tests/test_capability_ledger.py
R_PROFILE_USER=/dev/null Rscript --no-init-file tools/check-capability-runtime.R
python3 tools/validate-mission-control.py
```

Then inspect the generated Markdown and HTML for `mc-0248`, `mc-0251`,
`mc-0386`, `mc-0388`, `mc-0669`, `mc-0670`, and `mc-0671`, and verify that the
served Mission Control agrees with the source. The runtime checker currently
reconciles only the separate 18-route missing-response axis
(`tools/check-capability-runtime.R:19-46`); it is necessary but does not prove
the Arc 3a model cells. The focused Arc 3a fit/rejection tests and recovery
records remain load-bearing.

## Risks and fail-closed rules

1. **Collapsed-row overclaim.** Promoting `mc-0386` or `mc-0388` without an
   appended rejection row advertises all q gates. The migration must be
   additive before promotion.
2. **Slope inheritance.** A q1 covariance label does not mean every q1-shaped
   slope is admitted. The new rejection boundary must name slope-only and
   one-slope forms explicitly.
3. **Comparator drift.** `mc-0248` includes historical Gamma-relmat slope
   evidence outside Arc 3a. Preserve it verbatim and do not use it to infer
   lognormal or phylogenetic recovery.
4. **Estimator inheritance.** All three new admissions are ML only.
   Non-Gaussian REML remains separately rejected; no row or family-map text may
   imply otherwise.
5. **Evidence inflation.** A successful toy fit permits, at most,
   `diagnostic_only`; `point_fit_recovery` requires the declared all-attempted
   recovery result. Apply the three verified transitions only after that result
   is reviewed.
6. **Generated-surface drift.** `--check` compares every generated byte and
   reports stale outputs (`tools/capability_ledger.py:1265-1284`); a green
   source-only test is insufficient.

## Final verdict

**COMPLETE.** The stable-ID split is implemented: `mc-0251`, `mc-0386`, and
`mc-0388` are verified at `point_fit_recovery`; `mc-0669`--`mc-0671` preserve
the directly tested rejected neighbourhood; and `mc-0248` remains unchanged.
The original primary phylogenetic HOLD remains explicit, while the fresh
addendum is the primary recovery evidence for the two phylogenetic cells. No
inference tier changes.
