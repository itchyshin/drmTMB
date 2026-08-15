# The profile-truth gate: how it decides, how it is fed, and where to extend it

**Audience.** The engineer who will extend `tools/profile_truth_gate.py`'s reach in Wave 2/3 of
the interval-claim truth audit (`LOOP/GOAL.md`, `LOOP/ultra-plan.md`). This is a read-only
document — no tool, test, or ledger file was changed to produce it.

**Scope.** Answers the six checkpoint questions in the T1 brief, each with file:line citations.
Every claim below was verified against the on-disk repository state in this worktree
(`claude/lane-interval-truth-audit`, `git log --oneline -1` = `b62c5a343`), not copied from the
ultra-plan's prose. Where the ultra-plan's numbers and my own re-derivation disagree, both are
reported.

---

## 1. The gate rule

`evaluate_cell()` (`tools/profile_truth_gate.py:185-236`) takes a cell id, a numeric `true_value`,
and a `seeds` map of `seed -> (lower, upper)`. It:

1. Computes a per-seed bracketing verdict via `seed_verdict()` (`:168-182`): `brackets = lower <=
   true_value <= upper`; if it misses, `relative_miss = distance / miss_scale(...)` where
   `miss_scale` is `abs(true_value)` normally, or the interval's own half-width when
   `true_value == 0` (`:135-165`, the `mc-0263` structural-zero fallback).
2. Collects `misses = {seed: verdict for seed that does not bracket}` and `worst = max(relative_miss
   over all seeds)` (`:207-208`).
3. Fails the cell (appends a reason string, `:210-225`) when **either**:
   - `worst > MISS_MAGNITUDE_TOL` (`:71`, `= 0.05`) — a **location** failure: some seed's interval
     is more than 5% of |truth| (or half-width, for a zero truth) away from the true value.
   - `len(misses) > MISS_COUNT_TOL` (`:75`, `= 1`) — a **rate** failure: more than one seed misses
     at all, regardless of how narrow.
4. `passed = not reasons` (`:233`).

**Why "any miss demotes" would be wrong.** The module docstring states the statistical reasoning
directly (`profile_truth_gate.py:26-32`): a 95% profile interval is *supposed* to miss the true
value about 5% of the time. With 3–5 retained seeds per cell (the calibration population), P(at
least one miss) is about 15–23%, so demoting on any miss would punish an interval for behaving
exactly as a correctly calibrated 95% interval must. The rule instead separates two failure
signatures: a *location* problem (the interval sits in the wrong place, magnitude arm) from a
*rate* problem (misses happen too often even if each is narrow, count arm). `MISS_COUNT_TOL = 1`
means one narrow miss is tolerated and a second is treated as a pattern
(`profile_truth_gate.py:73-75`).

### The one-seed question — the checkpoint answer

**With exactly one retained seed, the count arm is structurally unreachable.** `len(misses)` can
only be `0` or `1` when there is one seed. The count-arm condition is `len(misses) >
MISS_COUNT_TOL`, i.e. `len(misses) > 1` (`profile_truth_gate.py:221`). `1 > 1` is `False`, so the
count arm can never fire for a one-seed cell — it fires only from two or more seeds. This is not
an inference from the calibration prose; it is the literal boolean the code evaluates at
`:221-225`.

**Consequence for Wave 2/3.** For the 106 (of 107) receiptless-turned-receipted cohort cells that
the ultra-plan records as having exactly one retained seed (`LOOP/ultra-plan.md:151-159`,
un-reverified by me — see "what I did not verify" below), only the **magnitude arm** can ever
decide the verdict. A pass at one seed proves the interval was not egregiously mislocated on that
one draw; it says nothing about the *rate* half of the rule, because the rate half needs a second
data point to even be evaluable. `test_a_single_narrow_miss_does_not_demote`
(`tools/tests/test_profile_truth_gate.py:340-358`) and
`test_one_narrow_miss_still_passes` (`:393-399`) exercise this boundary directly, and
`test_two_narrow_misses_fail_by_the_count_rule_alone` (`:370-391`) is explicit that "no retained
cohort on disk has two misses, so without a synthetic case this clause is dead" — i.e. even on the
current 3–5-seed, 31-cell surface, the count arm is exercised only by a hand-built synthetic case,
not by any live cell. On a 1-seed cell it cannot be exercised even synthetically through
`evaluate_cell(cell_id, true_value, seeds)` as currently wired to real receipts, because there is
only one `(lower, upper)` pair to feed it.

If a Wave 3 verdict is published for a 1-seed cell, it must say **"magnitude-only verdict; the
gate's rate arm requires ≥2 seeds and did not evaluate this cell"** rather than implying the same
strength of check as the 3–5-seed surface. This is exactly the caveat the ultra-plan's Wave 3 row
already states (`LOOP/ultra-plan.md:238`), and the code above is what makes that caveat true rather
than merely prudent.

---

## 2. The manifest derivation

`tools/emit-profile-truth-manifest.R` derives, never hand-types, `true_value` for two disjoint
cohorts:

- **25 Arc 2 cells** (`:139-163`): for each `cell_id` in `cell_registry` (a top-level binding
  parsed out of `tools/run-arc2-profile-feasibility.R` via `source_top_level_binding()`,
  `:70-88`, which `eval()`s only the *one* matching top-level `<-` and nothing else — so this
  never re-runs the runner's CLI parsing or fitting), the script:
  1. resolves the cell's first pinned seed from the on-disk receipts
     (`first_pinned_seed()`, `:99-122`, lexicographically-first radix-sorted receipt path under
     `docs/dev-log/interval-feasibility/results/` naming that `cell_id`);
  2. sources the cell's `fixture_file`/`fixture_name` binding and calls the contract's own
     `contract$fixture_call(fixture_fn, seed)` (`:147-150`) — the *same* call the runner itself
     would make;
  3. reads the numeric truth off the resulting fixture object via the contract's own
     `true_value = function(fx) fx$<element>` accessor (`:151`), e.g.
     `true_value = function(fx) fx$true_rho12` for `mc-0186`
     (`tools/run-arc2-profile-feasibility.R:106`);
  4. validates it fail-closed (`validate_truth()`, `:125-135`: not `NULL`/length!=1/`NA`/non-finite
     aborts the whole run).
- **5 Arc 1 cells** (`:165-203`): a hardcoded list of `{cell_id, runner, constant, target}` entries
  (`:167-188`); for each, the script reads a *literal top-level constant* out of the named frozen
  Arc 1 runner (e.g. `truth_mu_x` in
  `tools/run-arc1-gaussian-fixed-profile-feasibility.R` for `mc-0260`) via the same
  `source_top_level_binding()` helper, then validates it the same way.

**Valid `source_kind` values.** Exactly two appear in the emitted rows and in the committed
manifest: `"fixture_builder"` (Arc 2 cells, `:158`) and `"arc1_runner_constant"` (Arc 1 cells,
`:198`). Verified directly against the committed file: `cut -f5
tools/profile-truth-manifest.tsv | sort -u` returns `arc1_runner_constant`, `fixture_builder`, and
the header token `source_kind` — no third value exists on disk.

**What `truth_element` does.** It is a human-readable trace of *which expression* produced the
number, not a second source of truth. For Arc 2 rows it is
`paste(deparse(body(contract$true_value)), collapse = " ")` (`:152`) — the deparsed body of the
accessor closure itself, e.g. `fx$true_rho12`. For Arc 1 rows it is simply the constant's name,
e.g. `"truth_mu_x"` (`:200`). Grepping the committed manifest confirms this shape: row 2 reads
`... fx$sd_slope` and Arc 1 rows read bare constant names (not independently checked cell-by-cell
here, but the generator code at `:152`/`:200` is unambiguous and the manifest's `--check` mode,
`:219-233`, byte-diffs the regenerated table against the committed one, so drift between the code
and the file cannot survive CI).

**Output schema.** `cell_id`, `target_id` (`<cell_id>::<profile_parameter>`), `profile_parameter`,
`true_value` (`format(..., digits = 15)`), `source_kind`, `source_file`, `truth_element`
(`:153-162`, `:193-202`). Verified against the committed file (31 lines = 1 header + 30 rows,
`wc -l tools/profile-truth-manifest.tsv`).

**What a new cohort must provide.** Concretely, exactly one of:
- an Arc-2-style entry: a `cell_registry` entry in `tools/run-arc2-profile-feasibility.R` carrying
  a `true_value = function(fx) fx$<element>` accessor that operates on the *same* fixture object
  the runner fits against, plus at least one retained receipt under
  `docs/dev-log/interval-feasibility/results/` so `first_pinned_seed()` can resolve a seed
  (`:113-122` — this is a hard requirement: no receipt means `stop()`, not a skip); or
- an Arc-1-style entry: a new `{cell_id, runner, constant, target}` block appended to the
  `arc1_cells` list (`:167-188`), naming a literal top-level `truth_*` constant that already exists
  in a frozen runner file.

No cohort can supply `true_value` any other way — there is no third code path in this script, and
`--check` mode (`:219-233`) will reject any manual edit to `profile-truth-manifest.tsv` that the
generator itself would not produce.

---

## 3. The extension point — exact edit shape for both files

### 3a. The manifest generator (`tools/emit-profile-truth-manifest.R`)

For a new Arc-2-style cohort, the edit is entirely on the **runner side**, not this script: add a
`true_value = function(fx) fx$<element>` accessor to the cohort's existing `cell_registry` entry in
`tools/run-arc2-profile-feasibility.R` (mirroring the 25 existing accessors, e.g.
`true_value = function(fx) fx$true_sd_intercept` at `:364`). `emit-profile-truth-manifest.R` needs
**no edit at all** for such a cohort — its Arc-2 loop (`:144-163`) iterates
`names(cell_registry)` generically, so a new `cell_registry` entry with a `true_value` accessor is
picked up automatically the next time the script runs. This is the cheap path: no new code in this
file, only a new accessor on the existing registry entry, subject to the fail-closed
`validate_truth()` check.

For a genuinely new Arc-1-style frozen cohort (a new `reconcile-arc1-*.py` sibling with its own
frozen runner and literal truth constant), the edit **is** in this script: append one list entry to
`arc1_cells` (`:167-188`), of the shape

```r
list(
  cell_id  = "mc-XXXX",
  runner   = "tools/run-arc1-<new>-profile-feasibility.R",
  constant = "truth_<name>",   # a literal top-level `<-` binding in that runner
  target   = "<profile_parameter>"
)
```

and nothing else — the loop at `:190-203` handles derivation, validation, and row assembly for any
entry added to that list.

### 3b. The test sweep (`tools/tests/test_profile_truth_gate.py:97-120`)

The lines the brief points at are `ARC1_MODULES` (`:97-102`) and `arc1_pins()` (`:105-119`), the
mechanism that gates the four frozen Arc 1 reconcilers *without* those reconcilers calling the gate
themselves (see §4). The two-part edit, mirroring the existing four entries exactly:

1. Add the new reconciler module to `ARC1_MODULES` (`:97-102`):
   ```python
   ARC1_MODULES = {
       "fixed": _load("r_arc1_fixed", "reconcile-arc1-gaussian-fixed-profiles.py"),
       "meta_v": _load("r_arc1_meta", "reconcile-arc1-meta-v-profiles.py"),
       "sigma_re": _load("r_arc1_sigma", "reconcile-arc1-gaussian-sigma-re-profiles.py"),
       "reml_slope": _load("r_arc1_slope", "reconcile-arc1-gaussian-reml-slope-profiles.py"),
       "<new_key>": _load("r_arc1_<new>", "reconcile-arc1-<new>-profiles.py"),
   }
   ```
2. Wire its `cell_id -> pinned seeds` mapping inside `arc1_pins()` (`:105-119`). If the new
   reconciler follows the `fixed` pattern (one module, many contract cells, e.g. via a `CONTRACTS`
   dict), add a loop like the existing `for cell in fixed.CONTRACTS: pins[cell] = frozenset(fixed.SEEDS)`
   (`:109-110`). If it follows the single-cell pattern (`meta_v`/`sigma_re`/`reml_slope`), add one
   tuple to the `for key, cell in (...)` loop at `:111-115`, e.g. `("<new_key>", "mc-XXXX")`, which
   asserts `module.TARGET_ID.startswith(f"{cell}::")` before pinning `module.SEEDS`.

**Why this is the correct location, and not adding a manual `pins["mc-XXXX"] = ...` line
elsewhere:** `test_every_arc1_reconciler_on_disk_is_swept`
(`tools/tests/test_profile_truth_gate.py:197-208`) asserts `{p.name for p in
TOOLS.glob("reconcile-arc1-*.py")} == {Path(m.__file__).name for m in ARC1_MODULES.values()}` — a
new `reconcile-arc1-*.py` file that is not added to `ARC1_MODULES` fails this test outright, by
design ("If someone adds a fifth `reconcile-arc1-*.py` and does not wire it into `ARC1_MODULES`,
that cell would be silently ungated", `:198-204`).

For a **new Arc-2-style cohort** (the far more common Wave 2/3 case per the ultra-plan's 107-cell
receipt-bearing cohort), no edit to `test_profile_truth_gate.py` is needed at all: the sweep derives
its Arc-2 surface from `arc2.CELL_CONTRACTS` (`:147`, imported, never restated) and iterates
`set(self.arc2_contracts) | set(self.arc1)` throughout (e.g. `:154-158`, `:256`, `:309`, `:514`).
Adding a cohort there means adding an entry to `CELL_CONTRACTS` in
`tools/arc2_profile_reconcile.py` (shape below) *and* the corresponding `true_value` accessor in
`run-arc2-profile-feasibility.R`'s `cell_registry` (§3a) — the test picks both up automatically.

**Concrete shape of a new `CELL_CONTRACTS` entry** (`tools/arc2_profile_reconcile.py:40-305`, 26
entries currently, one dict literal per cell), copying the existing `mc-0423` entry
(`:141-150`) as the template:

```python
"mc-XXXX": {
    "target_id": "mc-XXXX::<profile_parameter>",
    "cohort_id": "<cohort-slug>-profile-feasibility",
    "family": "<family_name>",
    "provider": "<provider or 'none'>",
    "estimator": "ML" | "REML",
    "profile_parameter": "<same as target_id's suffix>",
    "information_rung": "<rung label matching execution_information_rung on retained receipts>",
    "seeds": ("<seed1>", "<seed2>", ...),
},
```

The `information_rung` string must match the `execution_information_rung` column value on the
retained receipts the cell is meant to pin (verified from the receipt schema,
`docs/dev-log/interval-feasibility/results/.../mc-0423-...-receipt.tsv` header column 12), and the
`seeds` tuple is what `verdict_for()` (`tools/tests/test_profile_truth_gate.py:531-547`) and the
reconciler's own seed loop iterate — every seed listed must resolve to exactly one retained receipt
row, or `test_every_pinned_receipt_resolves_to_one_retained_row`
(`:217-240`) fails.

---

## 4. What NOT to touch, and why

**Do not add gate calls to the four `reconcile-arc1-*.py` scripts.** `tools/arc1_profile_reconcile.py`'s
header states the reasoning directly (`:4-27`), quoted verbatim:

> "The four `reconcile-arc1-*.py` scripts deliberately do NOT call it. They are frozen provenance
> checks over already-merged cohorts: their job is to prove the retained bytes are the bytes that
> were run, and their committed `reconciliation.tsv` outputs are historical artifacts that
> `tools/tests/test_arc1_profile_reconcilers.py` byte-compares. Adding a claim gate here would
> conflate 'these bytes are authentic' with 'these bytes support the claim' and would force
> rewriting frozen history to record a changed verdict."
> (`tools/arc1_profile_reconcile.py:11-17`)

The header goes on to name `mc-0260m` as the worked example (`:25-26`): "its provenance is intact
and its reconciler still passes, but its interval misses truth, so the ledger demoted it" — i.e.
the split is intentional and already produces the correct answer through the *sweep*
(`test_profile_truth_gate.py`), not through the reconciler. `tools/arc2_profile_reconcile.py`, by
contrast, **does** call the gate inline (`:31-37`, `:399-403`) because `arc2_profile_reconcile.py`'s
own docstring explains why: "Arc 2 is an ACTIVE contract that still mints promotions and a bad one
must never be minted in the first place" (`arc1_profile_reconcile.py:7-9`, restated in
`arc2_profile_reconcile.py`'s own comment at `:393-398`). A new frozen historical cohort (an Arc-1
pattern) belongs behind the sweep only; a new active-contract cohort (an Arc-2 pattern) belongs in
`CELL_CONTRACTS` with the gate called inline as it already is.

---

## 5. The two known blockers — both confirmed still live, read directly from current code

### 5a. `runner_sha256` mismatch blocking `arc2_profile_reconcile.py` on `mc-0421`/`mc-0423`/`mc-0424`

Confirmed still true. `tools/arc2_profile_reconcile.py:321` builds `runner_path =
Path(__file__).with_name("run-arc2-profile-feasibility.R")` — always the **current** in-tree file —
and passes it to `validate_profile_artifacts(..., runner_path=runner_path, ...)` (`:362-365`),
which (via `tools/arc1_profile_reconcile.py:90-109`) requires the receipt's `runner_sha256` field to
equal `sha256(runner_path)` computed fresh, *before* the truth gate is ever reached
(`arc2_profile_reconcile.py:393-403` — the truth-gate call is the last step in `reconcile()`, after
the shape checks).

I hashed the current runner and compared it against the `runner_sha256` values recorded on the
retained receipts for these three cells:

```
current sha256(tools/run-arc2-profile-feasibility.R) = 3d9167f7fc53e7f6663d57314a651d037158ac288e7a1e8b74588af8162bbfbe
mc-0423 receipt runner_sha256                          = fc4fc368cb93b907c81dade0b5f61762aa10fe44522552213e54eb0b6a7d3153
mc-0421 / mc-0424 receipt runner_sha256                = a88195f2965aeeb3bba52ea8e6fd37ca868517674c01129072a3370b99568753
```

None match. This is exactly the state the arc7b after-task report recorded as found-not-fixed
(`docs/dev-log/after-task/2026-08-03-arc7b-profile-truth-gate.md:143-152`: "Retained receipts also
disagree among themselves (`mc-0423`'s record `fc4fc368…`, `mc-0421`/`mc-0424`'s `a88195f2…`), so no
single runner version reconciles the whole surface... Editing the runner here moved the hash again,
from `76f62be4…` to `3d9167f7…`"). The current hash (`3d9167f7...`) is the *same* value that
after-task report recorded as its own post-edit hash — so the runner file has not been re-touched
since arc7b in any way that changes its hash, and the blocker is unchanged.

**What a Wave 2/3 agent will see:** running `python3 tools/arc2_profile_reconcile.py --cell mc-0423
--root <retained-receipt-dir> --out <path>` against the retained receipts will fail inside
`validate_profile_artifacts()`/`require_fields()` (`arc1_profile_reconcile.py:90-109`) on the
`runner_sha256` field mismatch, **before** the truth gate at `arc2_profile_reconcile.py:399-403` is
ever reached. This is a false negative from the reconciler's point of view (the receipt's *shape*
and *bracketing* are both fine — the after-task report's own temp-tree experiment with only
`runner_sha256` repointed showed `mc-0421` reconciles PASS and `mc-0423`/`mc-0424` correctly fail at
the truth gate, not the hash check — `arc7b after-task :158-168`), but as committed today the
reconciler cannot be run end-to-end against these three cohorts without that same workaround (copy
receipts to a temp tree, repoint only `runner_sha256`).

### 5b. `mc-0423`'s `n_founders = 4` receipts vs. current default handling

Confirmed still true, and I found a second, more concrete face of the same defect while verifying
it: `arc2_profile_reconcile.py`'s pinned `CELL_CONTRACTS["mc-0423"]["information_rung"]` is
`"id40_each25"` (`tools/arc2_profile_reconcile.py:148`) — matching the **retained receipts**, whose
`execution_information_rung` column reads `id40_each25` and whose `true_parameter_scale` prose
reads "40-individual (3-generation) pedigree" (verified by reading a retained receipt row directly:
`docs/dev-log/interval-feasibility/results/a34bb75092c7733e5d65e4bf427895b4318ced7c/.../mc-0423-...-seed2026080303-receipt.tsv`).

But the **live `cell_registry` entry** for `mc-0423` in `tools/run-arc2-profile-feasibility.R`
explicitly calls the fixture at `n_founders = 8L` (`:442`, `fixture_call = function(fixture_fn,
seed) fixture_fn(seed = seed, n_founders = 8L)`) and computes `information_rung = function(seed)
"id80_each25"` (`:444`) — an 80-individual pedigree, not 40. The function's own default parameter is
`n_founders = 4L` (`tools/arc3-nbinom2-sigma-provider-fixtures.R:376`), so the `8L` in the
`cell_registry` entry is an explicit override, documented in an inline comment
(`run-arc2-profile-feasibility.R:422-441`) as a deliberate diagnosis-driven change that nonetheless
did not clear a 5/5-seed bar and left the cell at `point_fit_recovery`.

**Net effect:** the reconciler's own pinned contract (`id40_each25`, matching retained receipts) and
the runner's live `cell_registry` (`id80_each25`, n_founders=8) now disagree with each other. This
is precisely why the after-task report says `source_sha` "cannot distinguish the two" — the
receipt's `source_sha` field is `git rev-parse HEAD` at run time on a tree that had uncommitted
edits (arc7b after-task, `:132-137`), so it cannot certify which `n_founders` value produced a given
receipt, and now the reconciler's pinned rung and the runner's live default have also drifted apart
from each other on top of that. **This does not corrupt the manifest's `true_value` for mc-0423**:
`true_sd_intercept = 0.55` is a function *default argument*, not a value computed from simulated
data, so it is identical under `n_founders = 4` or `8`
(`tools/arc3-nbinom2-sigma-provider-fixtures.R:376`) — I confirmed the manifest row for mc-0423
reads `0.55` (`tools/profile-truth-manifest.tsv`, `mc-0423` row). The defect is entirely in
*provenance/reproducibility* (whether a fresh reconcile of these receipts against the current runner
is even meaningful), not in the derived truth number itself.

**What a Wave 2/3 agent will see:** if they try to add `mc-0423` (or verify its existing entry) by
running the runner's `cell_registry` fresh, they get an `id80_each25` fixture; if they try to
reconcile the *retained* receipts, those are tagged `id40_each25` and will not match a fresh run's
rung, on top of failing the `runner_sha256` check in §5a first. Both blockers must be scoped around
explicitly (e.g. treat `mc-0423` as "receipted but not reconcilable without a repointed copy",
matching what arc7b already did) rather than assumed fixed.

---

## 6. Receipt columns — `true_value` / `brackets_truth`

**Claim as stated in the brief:** "no committed receipt carries `true_value`/`brackets_truth` even
though `run-arc2-profile-feasibility.R` writes those columns." **Confirmed, with an exact count.**

`tools/run-arc2-profile-feasibility.R:1284-1310` computes `true_value <-
contract$true_value(fixture_result)` and `brackets_truth <- is.finite(true_value) && ... && lower <=
true_value && true_value <= upper`, then writes both as columns of the `receipt` data.frame
(`:1310`, `true_value = true_value, brackets_truth = brackets_truth`), explicitly noting
`brackets_truth` is "informational only ... never wired into `promotion_eligible`/`clean`" (`:1280-1283`).

I checked every committed receipt under `docs/dev-log/interval-feasibility/results/` (233 files
matching `*-receipt.tsv`, the same glob `test_profile_truth_gate.py:125` (`RESULTS.rglob("*-receipt.tsv")`)
uses):

```
find docs/dev-log/interval-feasibility/results -name "*-receipt.tsv" | wc -l          -> 233
find ... -exec head -1 {} \; | tr '\t' '\n' | sort -u | grep -c '^true_value$\|^brackets_truth$'  -> 0
```

Zero of 233 committed receipt files have a `true_value` or `brackets_truth` column in their header
(18 distinct header shapes exist across the tree, from schema evolution over the arcs; none of the
18 includes either column — verified by sorting all headers and grepping). This matches the
`mc-0423` header I read column-by-column above (36 columns, ending `interval_sha256`, no
`true_value`/`brackets_truth`). The gate never reads a receipt's own truth field for exactly this
reason — `evaluate_cell()` always recomputes bracketing from `lower`/`upper` against the
independently-derived manifest (`profile_truth_gate.py:168-182`), so a receipt without these columns
is not a gap in the gate's logic, only evidence that every currently-retained receipt predates the
column addition.

**One number correction against the ultra-plan.** `LOOP/ultra-plan.md:187-189` states "zero of the
256 receipts committed... have them." My own count of files matching the identical glob the test
suite uses is **233**, not 256. I did not investigate the discrepancy further — it may reflect a
different counting method (e.g. including non-`-receipt.tsv` sidecar files, or a different git ref)
in the ultra-plan's derivation. The qualitative claim (zero receipts carry the columns) holds either
way; the exact denominator does not.

---

## What I verified vs. what I did not (fail-closed accounting)

**Verified directly, with commands shown above:** the gate rule and one-seed unreachability
(§1), the manifest generator's two code paths and schema (§2), the exact `CELL_CONTRACTS` /
`ARC1_MODULES` shapes and their guard tests (§3), the arc1-reconciler non-gating rationale quoted
verbatim (§4), both named blockers by re-hashing the current runner and reading the current
`cell_registry` entries directly rather than trusting the after-task report's prose (§5), and the
receipt-column absence by scanning every committed receipt header (§6).

**NOT ESTABLISHED — flagged rather than guessed:**
- Whether the ultra-plan's "107 cells have ≥1 profile receipt, 106 with exactly one seed" partition
  (`LOOP/ultra-plan.md:151-159`) is itself correct. I did not re-derive this count; it is a T2/T3
  classification claim, out of this slice's scope (the brief asks me to read the truth-gate
  machinery, not re-run the census). Treat it as an input to Wave 2/3, not as something this
  document re-verifies.
- The exact reason for the 233-vs-256 receipt-count discrepancy in §6 (a narrow file-count mismatch,
  not re-investigated further as instructed — a narrow grep result is not proof of the cause).
- Whether any cell beyond `mc-0423` has a similar `CELL_CONTRACTS`-vs-`cell_registry` rung drift; I
  checked `mc-0423` specifically because it was named in the brief, not the full 26-cell surface.

No claim above rests on a negative grep alone without also citing the positive code path that
produces the result (e.g. §6's zero-column finding is paired with the receipt-writing code at
`run-arc2-profile-feasibility.R:1310` to show the columns exist in the *generator*, so their absence
on disk is a freshness gap, not a tooling bug).
