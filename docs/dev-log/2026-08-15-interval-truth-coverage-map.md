# Interval-truth coverage map — Wave 1 (classify)

**Arc:** drmTMB interval-claim truth audit · lane `claude/lane-interval-truth-audit` ·
base `origin/main` `82cd00560` · 2026-08-15
**Status:** Wave 1 complete. **This document is the `T1-classify` checkpoint.** No compute committed.

## What was measured

237 capability cells claim `evidence_tier` of `interval_feasible` or above. `tools/profile_truth_gate.py`
is the only machinery that checks whether a profile interval **contains its true value**; it derives
truth from `tools/profile-truth-manifest.tsv`, which reaches 30 cells (27 at a claiming tier). The
remaining **210** were classified as (a) genuinely unchecked for location, (b) checked by a stronger
instrument that does not route through the manifest, or (c) legacy import with no run behind it.

`mc-0282` is a documented `UNGATED` exemption (`tools/tests/test_profile_truth_gate.py:44-62`,
hand-verified: *"all five seeds bracket it… the gap is reproducibility, not correctness"*), so the
workload is **209**.

## The classification

> ### ⚠ CORRECTION (2026-08-15, later the same day) — class (c) is overstated
>
> A follow-up lane audited the 16 cells at `inference_ready_with_caveats` whose evidence was a
> single `legacy_model_evidence` stub. **All 16 turned out to have a real, reviewed, promoted
> campaign behind them.** Ten of those 16 are counted as class (c) below. That is a
> **10-cell overstatement of class (c)**, and the corrected count for those ten is class (b).
>
> **The failure mode, precisely.** This classification read each cell's `legacy_evidence_source`
> and stopped. That works when the field holds a direct artifact **path** — and it was **correct**
> for exactly those six (`mc-0001`, `mc-0003`, `mc-0057`, `mc-0397`, `mc-0398`, `mc-0427`, all
> class (b) here). It fails when the field holds a predecessor-board **key** such as
> `qseries_phylo_q1_mu_intercept`, which must be joined through
> `docs/dev-log/dashboard/structured-re-q-series-inference-evidence-summary.tsv` to reach the
> campaign. All ten wrong calls are of that second kind. **A blank or unresolvable field in the
> current ledger is not evidence of absence — it is usually the 2026-07-11 schema migration having
> dropped a link.**
>
> **What is NOT corrected.** The other 55 class-(c) cells were measured, not assumed, and they do
> **not** share this defect: 42 cite source code and tests (`src/drmTMB.cpp:…`,
> `tests/testthat/…`) which appear in **zero** predecessor-ledger files, 9 are blank `mr-*`
> missing-response routes, and 4 are the `qseries_ordinary_*` cells already re-tiered to
> `legacy_fit_supported`. Whether the 42 are correctly tiered is a separate question about what
> `interval_feasible` claims — see `docs/design/255-interval-feasible-tier-contract.md`.
>
> Corrected totals: class (b) **31**, class (c) **55**, defects **179** rather than 189.
> The table below is left as originally written; this log is not rewritten.

| class | meaning | cells | defect? |
| --- | --- | ---: | --- |
| **(a)** | genuinely unchecked for interval location | **124** | **yes** |
| **(b)** | checked by a stronger instrument (a coverage campaign brackets by construction) | **21** → **31** | no |
| **(c)** | legacy import with no run behind it at all | **65** → **55** | **yes** |
| | **total** | **210** | ~~189~~ **179 defects** |

**4 of the 21 class-(b) cells are soft** — `mc-0017`, `mc-0287`, `mc-0299`, `mc-0311` cite coverage
artifacts (Fir cluster archive; Totoro `full-1a085440`) that are **not present on local disk**. They
are recorded as (b) on the strength of the citation alone. The other 17 were confirmed against
artifacts that exist, 8 of them with a quoted empirical coverage rate (e.g. `mc-0242` 0.945,
`mc-0382` 0.9408, `mc-0061` 0.9325).

## THE CHECKPOINT NUMBER — re-check vs re-run

Over the **189 defect** cells:

| | cells | what it costs |
| --- | ---: | --- |
| **RE-CHECK** — a profile receipt exists on disk | **116** | no new compute |
| **RE-RUN** — no interval receipt anywhere in the repo | **73** | a first-ever profile campaign |

**Correction to the ultra-plan.** Its 107 / 52 split was measured over `docs/dev-log/interval-feasibility/`
alone. A **second interval-bearing receipt tree** exists at
`docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/totoro-receipts/`. Counting both,
435 interval-bearing TSVs carry 175 distinct `cell_id`s.

## The structural finding: the higher the claim, the less checkable the evidence

| tier | re-checkable | must be re-run |
| --- | ---: | ---: |
| `interval_feasible` | **116** | 47 |
| `inference_ready_with_caveats` | **0** | 22 |
| `supported` | **0** | 4 |

**Every re-checkable cell sits at the lowest of the three claiming tiers.** Not one of the 41
`inference_ready_with_caveats` cells and not one of the 4 `supported` cells has a profile receipt this
arc can re-check.

### All four `supported` cells rest on evidence rows with no run

Verified directly against `evidence.tsv`: across all 64 cohort-A cells, **zero** have a non-empty
`command`, `run_id`, or `replicates` on their primary evidence row. That includes all four cells at
the ledger's top tier, each on an `ev-mc-XXXX-legacy` row of class `legacy_model_evidence`:

- `mc-0069` and `mc-0070` — `claim_boundary` reads verbatim:
  *"fit_status=supported, extractor=extractor_ready, bridge=unsupported, **interval=interval_feasible,
  coverage=planned**"*. A cell at the ledger's top tier whose own boundary says coverage is *planned*.
- `mc-0264` — *"Board fit_status=supported for (1 | id) in mu; kept as the structured-RE arc's baseline
  comparator, not itself part of the structured campaign."*
- `mc-0268` — boundary describes a boarded slope cell; **RECORD SILENT** on intervals.

All four carry `next_gate = "Preserve the existing model-surface evidence tier."` The ledger's own
instruction for its top tier is to *preserve*, not to earn.

## The instrument problem: 110 of the 116 re-checks can only ever be magnitude-only

The gate fails a cell when **either** arm fires (`tools/profile_truth_gate.py:210-225`):

- **magnitude** — `worst_relative_miss > MISS_MAGNITUDE_TOL` (0.05)
- **count** — `len(misses) > MISS_COUNT_TOL` (1)

Its own docstring (`:26-32`) explains why: a 95% interval is *supposed* to miss ~5% of the time, so at
3–5 seeds P(at least one miss) is 15–23% and "any miss demotes" would demote correct intervals.

**With one retained seed the count arm is structurally unreachable**: the maximum possible
`len(misses)` is 1, and `1 > 1` is False. Only the magnitude arm can decide such a cell. So a one-seed
"pass" means *no single interval missed truth by more than 5% of scale* — a materially weaker
statement than the 3–5-seed standard the gate was calibrated for.

| seeds | cells | which arms can fire |
| --- | ---: | --- |
| 5 | **6** — `mc-0282`, `mc-0568`, `mc-0576`, `mc-0595`, `mc-0596`, `mc-0653` | **both** — full calibration |
| 1 | 87 | magnitude only |
| 0 (older receipt format, no `seed` column) | 23 | magnitude only |

The 23 seedless cells share a single 26-column header signature and **do** carry finite `conf.low`,
`conf.high`, `conf.status = profile` and `target_id`, so they are re-checkable — they simply cannot be
seed-counted.

## Disclosure: the 116 re-checks rest on 105 independent runs, not 116

**13 pairs of cells carry bit-identical interval endpoints.** Every pair is `animal` ↔ `relmat`,
identical on family route, dpar, effect type, dimension, q-gate, estimator and model type:

```
mc-0129/0151  mc-0130/0152  mc-0135/0157  mc-0136/0158  mc-0137/0159  mc-0138/0160
mc-0139/0161  mc-0140/0162  mc-0145/0167  mc-0146/0168  mc-0300/0312  mc-0407/0408
mc-0447/0451
```

This is the **expected equivalence** — `animal()` derives the relatedness matrix, `relmat()` takes one
supplied; given the same K the likelihood is identical — not a provenance defect. But one profile run
evidences two cells, so a published coverage table must not imply 116 independent checks.

## The two known blockers — both confirmed still live

Re-verified against current code, not taken from the 2026-08-03 after-task:

1. **`runner_sha256` mismatch.** The runner's current sha256 (`3d9167f7…`) matches neither retained
   receipt's `runner_sha256` for the `mc-0421/0423/0424` cohorts, so `arc2_profile_reconcile.py`
   cannot reconcile them end-to-end.
2. **`mc-0423` fixture drift.** Its `CELL_CONTRACTS` pin (`id40_each25`) now disagrees with the live
   `cell_registry` call (`n_founders = 8L` → `id80_each25`). This does **not** corrupt the manifest's
   `true_value = 0.55`, which is a fixed default rather than data-derived — but it is a second, more
   concrete face of the same provenance gap.

## The extension point (for Wave 2 — reuse, do not rebuild)

`emit-profile-truth-manifest.R` iterates `cell_registry` generically, so a new **Arc-2** cohort needs
**no edit to the generator**: only a `true_value` accessor on the runner's registry entry plus a
`CELL_CONTRACTS` entry in `arc2_profile_reconcile.py`; the sweep at
`test_profile_truth_gate.py:97-120` then picks it up automatically. A new **Arc-1** cohort needs an
entry in `arc1_cells` and in both `ARC1_MODULES` and `arc1_pins()`, enforced by
`test_every_arc1_reconciler_on_disk_is_swept`.

Two `source_kind` values exist and no others: `fixture_builder` (25 cells) and `arc1_runner_constant`
(5 cells). `truth_element` is a deparsed trace of the accessor, **not a second source of truth**.

**Do not add gate calls to the four `reconcile-arc1-*.py` scripts.** Their own header
(`tools/arc1_profile_reconcile.py:11-17`) states that doing so *"would conflate 'these bytes are
authentic' with 'these bytes support the claim.'"*

## What Wave 1 did NOT cover

- It did **not** run the gate on any cell. No cell has a location verdict yet; 116 are merely
  *eligible* for one without new compute.
- It did **not** derive a single `true_value`. Wave 2 must derive them from fixture builders —
  `mc-0595`/`0596`/`0653` state their true SD (0.45, 0.45, 0.60) in `claim_boundary` prose, and that
  prose is **not** usable as truth; lifting it would recreate this arc's own defect one layer up.
- It did **not** adjudicate `mc-0596`, where `cells.tsv` records `interval_feasible`/`verified` on a
  five-seed campaign while the landed response-mask arc recorded *"the outer fit reports convergence
  0, but the sentinel helper's independent nlminb re-optimization from that same optimum returns
  'false convergence (8)'."* Different instruments, not formally contradictory — surfaced for the
  owner under D-87.
- It did **not** verify the 4 soft class-(b) citations whose artifacts are off local disk.
- One count could not be reconciled: the ultra-plan cites 256 committed receipts; the file census
  finds **233**. Flagged, not resolved.

## Baseline (unchanged by Wave 1 — it wrote no tool, test or ledger file)

```
python3 -B tools/tests/test_profile_truth_gate.py   ->  Ran 24 tests ... OK
python3 tools/capability_ledger.py --check         ->  capability-ledger: OK (31 generated outputs)
```
