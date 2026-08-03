# Arc 7b — the interval-truth gate: execution brief

Written 2026-08-03 at the close of Arc 7a, for a fresh lane. Design decisions are **already
settled** (owner-approved during Arc 7a's Phase-2 review); this brief is the record so the next
session does not re-derive them.

```text
🎯 GOAL
Platform: Claude Code (solo lane).
Deliverable: interval-feasibility promotions gated on interval LOCATION by machine, not by a
human remembering to do arithmetic.
HEADLINE: tools/arc2_profile_reconcile.py validates interval SHAPE and is structurally blind
to interval LOCATION. Two cells hold interval_feasible on main today with a truth-excluding
interval in their cohort: mc-0424 (seed 2026080301, [0.2567, 0.5156] vs true 0.55) and
mc-0260m (seed 2026080233, [0.2335, 0.4232] vs true 0.20).
EXPECT THE SURFACE TO FALL 184 -> 182. That is the gate working, not a regression.
DEFER (fenced): Prong B / the 14-cell Tier-1 campaign · Tier-2 zoi + structured-mu pilots ·
ALL five `coi` cells (owner-declined in writing) · the q12 decision.
DISCIPLINE: exact bracketing comparison, no tolerance · truth derived from the fixture, never
declared twice · no coverage/calibration/CRAN claim · fresh worktree, never the primary checkout.
```

## The defect

`validate_profile_artifacts` (`tools/arc1_profile_reconcile.py:63-161`) is the shared choke
point for all five reconcilers. It parses `estimate`, `lower`, `upper` and checks only their
*internal* ordering:

```python
if not lower < estimate < upper:
    fail(prefix, f"{receipt_path}: estimate is not strictly inside the interval")
```

No truth is compared. The truth *is* recorded — as **prose**. `mc-0417`'s receipt reads
`true_parameter_scale = "0.6 spatial random-intercept SD on mu (log link; PRIMARY target),
simultaneous with an independent 0.5 relmat random-intercept SD ... (kappa = 66.2) ... 5
observations per (site, id) cell"`. Four numbers in one sentence; one is the truth.

`mc-0424`'s evidence row credits `reviewed_by: tools/arc2_profile_reconcile.py` — the machine
is named as reviewer, and the machine never looked. Its point estimate 0.3710 is a 32.5%
relative error, *under* the 0.35 point-fit gate, so only a location clause catches it.

## The four settled decisions

**D1 — gate rule: miss-magnitude + miss-count, NOT "any miss blocks."**
Fail on **≥2 misses of k seeds**, or **any single miss exceeding ~10% of interval width**.

Rationale, and this is the load-bearing one: a correctly calibrated 95% interval *should* miss
~5% of the time. "Any miss blocks" falsely rejects **22.6%** of good routes at 5 seeds and
**33.7%** at 8 — making the tier depend on compute budget, and predicting 3–5 of Prong B's 14
cells lost to chance alone. The corpus is *already* calibrated: 3 exclusions in 122 in-cohort
receipts (97.5%, p = 0.136 against nominal), and P(zero misses | calibrated, n=122) = 0.0019 —
so enforcing zero would itself be evidence of miscalibration. The chosen rule catches mc-0424
(13.3% of width), mc-0423 (20.6%) and mc-0260m (17.7%), and correctly spares mc-0409-each8
(3.5%) and mc-0292 (2.2%) for human judgment.

**Do NOT fold `brackets_truth` into `clean` or the runner's exit code.** `clean` means "the
machinery produced a well-formed interior interval" — a software property. Bracketing is a
sampling outcome. Conflating them makes `quit(status = 2)` fire on a 1-in-20 event, and the
cheapest response to that is to re-run until it passes.

**D2 — derive truth from the fixture, don't declare it twice.**
The obvious design (declare in runner and reconciler, require agreement) is **not independent**:
same author, same session, same reading — and for `mc-0321`/`mc-0409` the "second source" *is*
the runner (`sd_pair = 0.6` at the call site). The fixture builders already return their truths
(`true_sd_intercept`, `true_log_sd_phylo`, `truth`, `sd_pair`), and the runner already holds
`fixture_result` at `tools/run-arc2-profile-feasibility.R:741`. Add a per-cell
`truth_from_fixture` accessor mirroring the existing `data_from_fixture`. Precedent:
`tools/run-arc1-gaussian-fixed-profile-feasibility.R:111` already builds its prose from a
numeric `contract$truth`.

**D3 — pin the seed denominator.**
`tools/arc2_profile_reconcile.py:236-243` takes `--seeds` from the CLI; the arc1 reconcilers
hardcode `SEEDS`. As written, running 8 seeds and reconciling the 5 that bracket passes cleanly.
Pin per-cell seed sets in `CELL_CONTRACTS`.

**D4 — land the sweep as a wired test, not a script.**
The "retroactive" claim is false for arc2/3/4: `validate_profile_artifacts:81` requires a live
`runner_sha256`, and those receipts carry stale hashes (`a88195f296…` vs `241dbd00cb…`), so they
can never be re-reconciled. Only the 5 arc1 cells are live. A one-off sweep script with no caller
reproduces the exact failure being fixed. Land it as a `unittest` under `tools/tests/` with a
checked-in expected-exclusions manifest, and add it to `.github/workflows/R-CMD-check.yaml`.

## Scope

**31 cells**, not 15: the post-#908 registry is 26 (main 15 + #907's 2 + #908's 9) plus 5 arc1
(`mc-0260` 0.55, `mc-0262` 0.18, `mc-0266` 0.35, `mc-0269` 0.35, `mc-0260m` 0.20). Eight fixture
generators must be read. **Verify each cell's `fixture_call` does not override the default** —
`mc-0423`'s already does (`n_founders = 8L`).

Truth values are code-verified but **re-verify each against its cited source before writing it in**:

| cell | truth | source | cell | truth | source |
|---|---|---|---|---|---|
| mc-0186 | 0.4 | `test-reml-bivariate.R:14` | mc-0423 | 0.55 | `arc3-nbinom2-sigma-provider-fixtures.R:377` |
| mc-0263 | **0** | see note | mc-0424 | 0.55 | `…:481` |
| mc-0274 | 0.6 | `test-reml-phylo-location.R:14` | mc-0321 | 0.6 | `run-arc2-profile-feasibility.R:506` |
| mc-0277 | 0.7 | `arc2-phylo-sigma-fixtures.R:52` | mc-0409 | 0.6 | `…:568` |
| mc-0283 | 0.7 | `…:139` (0.6 = companion mu SD) | mc-0123 | 0.45 | `arc4-q6-spatial-mu1-fixture.R:61` (5 decoys) |
| mc-0013 | 0.55 | `arc2-beta-animal-fixtures.R:72` (0.50 = intercept) | mc-0417 | 0.6 | `arc4-multiprovider-mu-fixtures.R:133` (0.5 = companion) |
| mc-0015 | 0.55 | `…:161` | mc-0421 | 0.55 | `arc3-nbinom2-…:271` |
| mc-0422 | 0.55 | `…:316` | | | |

**Declare the number; never parse it from the prose.** "First number in the string" happens to
work for 14 of 15 today, but that is an accident of writing style — `mc-0123` carries six
SD-shaped numbers and `mc-0424`'s prose contains the substring `AR1`.

**`mc-0263` — decided: `true_value = 0`, checked.** Its DGP puts the sigma effect on `z` while
the fit profiles `sigma ~ x`, with `x ⟂ z` (`tests/testthat/test-reml-heteroscedastic.R:12-15`),
so the pseudo-true coefficient of `x` is exactly 0. The standing "never profile a variance
component whose true value is zero" rule does **not** apply — the target is a fixef on
(−∞, ∞), not a variance component, and all three receipts show `profile_boundary = FALSE` with
finite two-sided intervals straddling zero. Call it a **null-bracketing** check, not
"null-coverage": this programme's own rules forbid coverage claims.

**Exact comparison, no tolerance.** The retained arc1 target `mc-0260m` brackets by 0.0022
(`[0.0377, 0.2022]` vs 0.20) on a *different* seed than the failing one; any tolerance flips a
currently-green golden fixture.

## The two demotions

Owner-approved. Surface **184 → 182**; the frozen constant moves 58 → **59** (mc-0424 has
`source_order = 424`, inside the 676 window; mc-0260m has 694, outside).

**What the mc-0424 record must say.** (i) The "32.5% error vs the 0.35 gate" framing is a
category error — the gate is a *mean over seeds* (cohort mean 23.8%), and a second seed barely
brackets (margin 0.0030, 98.9th percentile). So it is "1 miss and 1 hairline pass out of 3", not
"one bad seed". (ii) There is a **family-level signal**: all four nbinom2 structured-sigma cells
(`mc-0421`/`0422`/`0423`/`0424`, all truth 0.55) are biased low — 11 of 12 estimates below truth,
**sign test p = 0.0032**, family mean 0.4352 (−20.9%). Demoting only mc-0424 leaves mc-0421 and
mc-0422 standing on the same biased estimator. **Open a triage item; report mean *signed* error,
not mean |error|.**

`mc-0260m`'s bad seed (2026080233) is pinned in `tools/reconcile-arc1-meta-v-profiles.py:15` and
its runner hash is live, so `tools/tests/test_arc1_profile_reconcilers.py` — which CI runs — will
go red the moment the gate lands unless the demotion ships with it.

## Also for the record

`mc-0316` seed 505 brackets 0.7 by 0.0091 (4.2% of width) while its withheld sibling `mc-0292`
missed by 0.00625 (2.2%) on the same side — a 0.0154 difference on one endpoint decided opposite
dispositions. **The promotion note must state the margin, not the tally**; a bare "5/5" is not
defensible next to a withheld sibling at 2.2%.

## Mechanical hazards

- `mc-0409`'s directory holds **10** receipts flat (each8 ×5 + each24 ×5) and the reconciler
  requires `len(receipts) == len(seeds)` — the GREEN test case must copy only the each24 five.
- Two retained receipts carry `estimate = NA`; there are duplicate paths (`…/mc-0277/mc-0277/`)
  and 24 files named `receipt.tsv` rather than `*-receipt.tsv`. **Join to the `reconcile.tsv`
  cohort; do not bare-glob.** The "213 receipts" figure from earlier notes is wrong — `main`
  carries 188 matching `-receipt.tsv`.
- Red-test fixtures must rewrite `runner_sha256` to the live hash, or the retained mc-0423/mc-0409
  receipts fail for the *wrong reason* before bracketing is ever reached.
- There is **no arc2 reconciler test file** — the reconciler gating 15 cells is untested. Create
  `tools/tests/test_arc2_profile_reconcile.py`; arc1's `run_reconciler` is not reusable (it takes
  only `--root`/`--out` and globs `seed-*/`, while arc2 needs `--cell`/`--seeds` and globs flat).

## Standing lesson from Arc 7a

**A guard's definition of done includes the line in CI that runs it.** Three guard defects
surfaced in one day — this one, the B4-CI neighbour pins, and the parity-triage claims — and all
three share a shape: a claim recorded in one place about the state of another, with no mechanical
link between them. See `docs/dev-log/after-task/2026-08-03-b4-ci-mc-0207-pin-drift.md`.
