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

## Next steps, in priority order

1. **Run the investigation campaign for the 8 ticks** (compute; Claude can't ssh). Re-run each of the 8
   at `n_miss ≥ 40` (N ≈ 800–1600), **uncensored denominators**, then run
   `tools/gate-inference-ready.R <replicates.tsv> --truth= --members=` on each. If a cell returns
   FAIL/INTERVAL_FEASIBLE, it is not `inference_ready`. This decides demote-vs-keep and whether the 27
   are reachable at all. Wire `gate-inference-ready.R` into `validate-mission-control.py` (Fisher G4)
   so the board can never again promote by allowlist.
2. **REML provider-gate relaxation** (spatial/animal/relmat) — the 27-cell *capability* unlock. R-side
   only; recovery-validated this session (40/40 intercept debiasing, `scratchpad/reml_provider_ladder.R`).
   Safe to *admit the fit*; cannot *certify* until step 1's gate lands. Gate on the provider recovery
   ladder, not on the broken miss-balance path.
3. **Location-scale-scale** (Ayumi #3, design 222) — attempted + reverted. Next attempt starts from
   design 222 "Attempt 1": leading suspect is that the surface scales only tip rows while the GMRF prior
   is over the augmented node set (not a similarity transform). Run `scratchpad/location_scale_scale_recovery.R`
   before and after; the null control (arm B) passes, the live case (arm C) inverts.
4. **Doc 218** still cites the pre-REML scope premise (via doc 199, now corrected). Add a pointer banner.
   `sdreport_scaling_probe.R` → a benchmark test asserting sub-quadratic cost. Big-data arc
   (dense animal/relmat/spatial precisions) remains unscoped.

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
