# Handover — drmTMB, 2026-07-08 evening → next Claude

From Claude (Opus 4.8). Repo state is authority; trust `main`, not this note.
`main` = `3523ab28` (pushed). Branch `drmtmb/biv-scale-side-reml` == `main`. Tag `v0.2.0.9001` pushed.

## One-paragraph state

The "crosses to ticks" arc did **not** advance the board (0 cells promoted) and its promise **shrank**:
the honest ceiling is **8 → ~35 of 95**, not 95. What this session actually produced: (1) fixed a live
user's 48 GB `sdreport()` ceiling at root + two other REML defects, tagged `v0.2.0.9001`, replied to
Ayumi (issue #3); (2) a `(REML × surface)` conformance harness that turns silent cross-cutting breakage
into a test failure; (3) a **Fisher SOFT verdict** — the 8 existing `inference_ready` ticks were
promoted by a hard-coded allowlist, not a computed gate, and 6 of 8 fail a miss-ratio check; (4) a
binding-gate tool (`tools/gate-inference-ready.R`) to replace the allowlist; (5) a corrected design-219
premise (F3). One capability was attempted and **reverted** (location-scale-scale).

## The blocking fact for the arc — read before promoting anything

**The promotion gate does not bind.** `validate-mission-control.py` admits `inference_ready` via a
literal set `CERTIFIED_INFERENCE_READY_CELLS`; design 217 never mentions miss-balance; the coded
miss-ratio checks live only in the *blocked* mu-slope pipeline. Fisher recomputed from the replicate
TSVs: phylo/relmat `sigma` one-slope intercepts miss **11:1 / 10.6:1** (p<1e-10); the 3 mu-intercept
cells look clean only because over-coverage leaves too few misses to test. **Shinichi's decision:
investigate before any status change — do not demote, do not promote.** Full detail + the P0–G4 gate
spec: `docs/dev-log/after-task/2026-07-08-reml-surfaces-ayumi-fisher.md` §7a and the Fisher report
(reproduce via `scratchpad/fisher.R`).

## Next steps — ORDERED SLICES (decided with Shinichi, 2026-07-08 evening)

Two tracks in parallel. Track G (gate) is the critical path — nothing gets a NEW tick until G1+G2 land.
Track C (capability) is board-neutral and runs alongside. Entry slice chosen: **G1**.

### Track G — make the gate bind, then adjudicate the 8

**G1 · Wire the binding gate into `validate-mission-control.py`. [Claude, no compute, FRESH SESSION]**
The choke point is one function: `_promoted_status_ok` (line ~13181), which admits `inference_ready`
iff `cell in CERTIFIED_INFERENCE_READY_CELLS` (the allowlist, line ~13152). Build a driver that writes
`docs/dev-log/dashboard/inference-gate-results.tsv` from each cell's `evidence_url` via
`tools/gate-inference-ready.R`, then wire the validator to check `gate_status == PASS`.
**⚠️ DESIGN SUBTLETY (do not miss this):** `gate-inference-ready.R` needs G2's *uncensored* replicates
to return PASS. On the EXISTING censored SR475 evidence, most of the 8 return FAIL. So if G1 fails
**closed** now, the board goes red immediately = **demotion-by-CI**, which contradicts Shinichi's
"investigate first, don't demote until G2" decision. Therefore G1 must be a **transitional bridge**:
compute the gate result, **cross-check it against the allowlist as a WARNING**, and flip to fail-closed
only in G3 after G2 replaces the evidence. The file is 98k lines with hardcoded counts (the documented
repeat-breakage) — reconcile counts in lockstep, full `devtools::test()` + 4 validators after. This is
why it is a fresh-session slice, not an end-of-session one.

**G2 · The 8-tick investigation campaign. [LOCAL — this Mac has 20 cores; Codex NOT required]**
The fits are tiny (g=8, ~160 obs); the campaign is minutes locally, not a cluster job. Re-run each at
`n_miss ≥ 40`, **uncensored denominators**, then `tools/gate-inference-ready.R`. The 3 sigma one-slope
cells reuse the existing `tools/run-structured-re-sigma-slope-coverage-grid.R` (shards 1/5/6 =
`sigma:(Intercept)`, 2/7 = `sigma:x`) — no new runner. **STARTED 2026-07-08 evening:** shards 1,2,5,6,7
at `n_rep=600` → `docs/dev-log/simulation-artifacts/2026-07-08-g2-sigma-oneslope-adjudication/`
(launcher `scratchpad/g2_launch.sh`). The mu-intercept and q2 cells still need their own campaign runs
(their existing raw replicates are pre-Fisher-fix and censored).

**G1 driver — the cell→file→schema map (discovered 2026-07-08; this is the non-obvious part).**
`evidence_url` is NOT a uniform data pointer, and the three cell-types have three schemas:
| cell group | real replicate file | schema / members | adapter needed |
|---|---|---|---|
| sigma one-slope (3) | G2 output `…/2026-07-08-g2-…/0{1,2,5,6,7}-*-replicates.tsv` | `wald_lower/upper`, `profile_lower/upper` | none — `gate-inference-ready.R` reads directly |
| q2 mu1+mu2 (2) | `…/2026-06-27-bias-corrected-engine-coverage-g8[-spatial-animal]/replicates.tsv` | `wald_lower/upper`, `bc_lower/upper`; `truth` | `--members=wald,bc`; **evidence_url points at design 219, not this file — fix the map** |
| mu-intercept (3) | `…/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/results/shard_*/…-replicates.tsv` | `provider`, `truth_sd_mu_intercept`, `estimate`, `lower_miss`/`upper_miss` — **no `{member}_lower/upper`** | filter by `provider`; adapt columns to the gate's schema, or extend the gate to accept this layout |
So the driver = a small config table (cell → file, provider filter, member cols, truth col) + a
mu-intercept adapter. Emit `docs/dev-log/dashboard/inference-gate-results.tsv`. THEN the validator wiring.

**G3 · Adjudicate + flip to fail-closed. [Fisher/Claude]** Demote whatever fails; the board headline
becomes true for the first time. Blocked on G1 + G2.

### Track C — capability, board-neutral (Shinichi approved C1 + C2)

**C1 · REML provider-gate relaxation (spatial/animal/relmat). [Claude + Noether]** R-side only;
recovery-validated this session (40/40 intercept debiasing, `scratchpad/reml_provider_ladder.R`). Admits
the *fit*; cannot *certify* until Track G lands. Gate on the provider recovery ladder, not miss-balance.

**C2 · Location-scale-scale, attempt 2. [Claude + Gauss + Noether — deep C++ session]** Start from
design 222 "Attempt 1": leading suspect is the surface scaling only tip rows while the GMRF prior is
over the augmented node set (not a similarity transform). Run `scratchpad/location_scale_scale_recovery.R`
before/after — null control (arm B) passes, live case (arm C) inverts. Proven silent-wrong-model hazard.

**C3 · `sdreport_scaling_probe.R` → benchmark test** asserting sub-quadratic cost (cheap; guards Ayumi's
ceiling from regressing). Plus: doc 218 still cites the pre-REML scope premise via doc 199 (now
corrected) — add a pointer banner. Big-data arc (dense animal/relmat/spatial precisions) unscoped.

## Traps this session hit (don't repeat)

- **Focused test runs hid 5 failures.** Always full unfiltered `devtools::test()` before merge.
- **`bf()` NSE**: `tree`/`coords` must be bare symbols, not `env$tree`.
- **Hand-built TMB data lists** (`test-phylo-utils.R`) mirror the `DATA_*` contract — every new
  `DATA_INTEGER` in `src/drmTMB.cpp` must be added there too or `MakeADFun()` aborts.
- **I asserted "DRM.jl fix unpushed" and "A1 never spiked" from stale docs** — both false. Verify
  against `origin`/repo state, not prose. `read.delim` coerces `"TRUE"`/`"FALSE"` to logical
  (`colClasses="character"`).
- **A clean fit (`conv=0`, `pdHess=TRUE`) can be a wrong model** — the location-scale-scale case
  returned inverted parameters. Recovery gate is the arbiter, not convergence.

## Resume command

```
claude "Rehydrate from docs/dev-log/handover/2026-07-08-evening-claude-handover.md + the after-task
2026-07-08-reml-surfaces-ayumi-fisher.md. The promotion gate does NOT bind (Fisher SOFT): do not
promote any cell. Start with step 1 — the 8-tick investigation campaign + wiring gate-inference-ready.R
into the board validator."
```
