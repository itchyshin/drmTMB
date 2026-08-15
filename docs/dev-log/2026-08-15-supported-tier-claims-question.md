# The four `supported` cells — the claims question, answered

**Arc:** drmTMB interval-claim truth audit · lane `claude/lane-interval-truth-audit` · 2026-08-15
**Cells:** `mc-0069`, `mc-0070`, `mc-0264`, `mc-0268` — the entire top tier of the ledger.

## The question

All four sit at `evidence_tier = supported`, the top of the ladder, on evidence rows
(`ev-mc-XXXX-legacy`, class `legacy_model_evidence`) with **no `command`, no `run_id`, no
`replicates`**, imported in the 2026-07-11 migration (`095409c0`). Two of them state
`interval=interval_feasible, coverage=planned` in their own boundary. Should the ledger's top tier be
occupied by cells with no run behind them?

## The answer: `supported` is TWO different tokens, and the reader surface is already safe

**`supported` means two incompatible things inside `tools/capability_ledger.py`.**

**Meaning A — the top of the evidence ladder.** `TIER_ORDER` (`:801-804`) places it first, and the
dashboard prose (`:4014`) states: *"The evidence ladder is point-fit recovery → interval feasible →
inference-ready with caveats → supported. … coverage promotes the tested domain to inference-ready."*
On that reading, `supported` is strictly stronger than coverage-backed inference-readiness.

**Meaning B — a legacy board fit-status label.** The reader-permission translator (`:3174-3184`)
returns, for `supported`:

> *"No — the **legacy supported label** does not authorize an interval."*

and grants only *"report the point estimate only within the stated exact scope."*

### The inversion this produces

| tier | rank in `TIER_ORDER` | may a reader report an interval? |
| --- | ---: | --- |
| `supported` | **1 (top)** | **NO** — *"the legacy supported label does not authorize an interval"* |
| `inference_ready_with_caveats` | 2 | **YES** — within scope and caveat |
| `interval_feasible` | 3 | NO — method exists, no calibrated permission |
| `point_fit_recovery` | 4 | NO |

**The ladder's summit authorizes strictly less than the rung beneath it.**

### Where this is safe, and where it is not

**Safe — the reader surface.** `reader_*` wording refuses these four cells any interval permission and
labels the tier "legacy". A user reading the generated capability surface is *not* over-claimed to.
This is the opposite of what the audit expected to find, and it is to the ledger's credit.

**Not safe — every aggregate.** The same token is counted as the ladder's top rung:

- `:3793` — the evidence summary line prints **`N supported`** *first*, ahead of inference-ready, as
  the strongest category.
- `:3722` — `supported` is CSS-classed `"inference"` **together with**
  `inference_ready_with_caveats`, so it renders as inference-grade in the board.
- `:2279` — the internal-estimator guard treats `{"supported", "inference_ready_with_caveats"}` as one
  equally-high class.

So four cells with no run behind them are **counted and rendered as the package's strongest evidence**,
while the prose one layer down correctly calls them legacy and refuses them an interval.

## Provenance: how they got there

`legacy_evidence_source` names an old Q-Series board cell (`qseries_ordinary_q2_mu1_mu2_intercept`,
`qseries_ordinary_q1_intercept`, `qseries_ordinary_q1_independent_slope`). On that board the field was
**`fit_status`**, and `supported` there meant *the model fits and the route is a supported capability*
— a statement about implementation, not about intervals or coverage. `mc-0069`'s own note preserves
the board's full record and makes the distinction explicit:

> `fit_status=supported, extractor=extractor_ready, bridge=unsupported,`
> **`interval=interval_feasible, coverage=planned`**

The 2026-07-11 migration carried the board's `fit_status` value into the ledger's `evidence_tier`
column. **Same word, different axis** — a capability status became an evidence tier. `mc-0264` and
`mc-0268` are the same import and are RECORD SILENT on intervals; `mc-0264`'s note even says it is
*"kept as the structured-RE arc's baseline comparator, not itself part of the structured campaign."*

All four carry `next_gate = "Preserve the existing model-surface evidence tier."` — the ledger's own
instruction for its top tier is to *preserve*, not to earn.

## This also explains the "0 supported authority" discrepancy

`docs/dev-log/release-audits/q-series-v1-release-status.md` states *"`supported` authority: 0 cells"*.
That is not a contradiction and must not be chased as one: the doc was generated 2026-07-14 from a
superseded 104-row board and scopes itself to **structured** rows (*"Structured rows with support
authority; this remains zero"*), while all four cells carry `structure_provider = none`. Different
populations. The doc is nonetheless **stale and still linked live** from `README.md:75` and
`NEWS.md:1173` with no supersession pointer to the current 740-row ledger.

## Recommended disposition

The defect is the **token collision**, not the four cells. Two changes, in order:

1. **Separate the token** (the real fix). `supported` should not name both "legacy board fit-status"
   and "top of the evidence ladder". Renaming the legacy value — e.g. `legacy_fit_supported`, placed
   *below* `interval_feasible` — makes every aggregate honest at once and matches what the reader
   translator already says. Touches `EVIDENCE_TIERS`, `TIER_ORDER`, the two aggregate sites, the
   schema enum, and 4 rows.
2. **Or, minimally, re-tier the four cells to what their own boundaries say.** `mc-0069`/`mc-0070`
   state `interval=interval_feasible, coverage=planned` verbatim, so `interval_feasible` is their own
   recorded position. `mc-0264`/`mc-0268` are silent on intervals and have no run, so they have no
   basis above the legacy-implementation statement.

Either way the wording follows the arc's rule: **"this claim is not currently supported"** — never
"this route is broken". Nothing here says these models do not fit. The Q-Series board's finding that
they fit is undisturbed; only the *evidence-tier* reading of that finding is wrong.

## What is NOT established

- **No ledger row has been changed.** This is analysis and a recommendation; the re-tiering is a
  claims decision for the owner (D-43/D-87), not for the executing session.
- I did **not** audit whether other tiers carry the same collision — only `supported` was traced
  through all its uses.
- Whether the four models *fit* is not in question and was not tested here.
- The staleness of `q-series-v1-release-status.md` is recorded, not fixed.
