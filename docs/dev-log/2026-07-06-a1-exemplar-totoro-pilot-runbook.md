# P1.1 — Totoro pilot runbook: A1 exemplar (`qseries_spatial_q1_sigma_one_slope`)

Meta: 2026-07-06 · owner Curie (driver) + Fisher (design) · **executed by Claude directly over
ssh** — Totoro is reachable from the Mac (12h ControlPersist socket); no scheduler, run directly
(≤100 cores, `OPENBLAS_NUM_THREADS=1`). Results + interpretation recorded in the "Results"
section below.

## Purpose (and claim boundary)

De-risk and **size** the A1 exemplar certification before spending a Nibi array. The exemplar
is the Gaussian cell `sigma ~ spatial(1 + x | site, coords)` with two independent SD targets:

- `sd:sigma:spatial(1 | site)` — the **intercept SD**, home of the documented finite-Wald
  blocker (finite rate 0.9360 < 0.95);
- `sd:sigma:spatial(0 + x | site)` — the **slope SD** (the "one-slope" target).

**This pilot does NOT certify anything.** At n≈150 the coverage MCSE floor is
`sqrt(.95·.05/150) ≈ 0.018` — above the ≤ 0.01 gate. Its job is: (a) confirm the profile route
runs at scale without pathology, (b) give a rough profile-vs-Wald **finite-rate** and
**miss-side**, (c) produce the MCSE estimate that **sizes the certify run** (SR475 vs SR1000).
The ≥ 0.95 finite-rate adjudication happens on the full Nibi certify run, not here.

## Prerequisites (one-time Totoro setup)

Golden rules (see `~/.agents/tools/totoro-setup.md`): **≤ 100 cores**, `OPENBLAS_NUM_THREADS=1`,
work under `~/drmtmb_work` (not a shared scratch). This pilot is tiny (2 shards × 150 fits) so
cores are not a concern — a single core per shard is fine.

```bash
# attach over the existing ControlMaster socket (the plain `ssh totoro` stanza lacks ControlPath)
SOCK=~/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22
ssh -o ControlPath="$SOCK" -o ControlMaster=no totoro

# one-time: clone the repo + confirm R/TMB present
mkdir -p ~/drmtmb_work && cd ~/drmtmb_work
git clone https://github.com/itchyshin/drmTMB.git   # or rsync your local checkout
cd drmTMB
git checkout drmtmb/a1-spatial-sigma-slope-interval  # the branch carrying the runner
R --version   # expect R 4.x with TMB/glmmTMB installed
```

The coverage runner builds drmTMB from the cloned source into a temp library via
`--attempt-temp-install`, so no separate `R CMD INSTALL` step is required.

## Run the pilot (both exemplar shards)

The runner is `tools/run-structured-re-sigma-slope-coverage-grid.R`. Shards **3** (spatial
intercept) and **4** (spatial slope) are the exemplar's two SD targets. Pilot config:
`n_rep = 150`, a **distinct** `seed_start = 750001` (kept off the canonical certify draw
`740001` so the Nibi certification stays an independent sample), `bootstrap = 0` (profile is the
star; bootstrap is the fallback, exercised only if a profile endpoint fails to bracket).

```bash
cd ~/drmtmb_work/drmTMB
export OPENBLAS_NUM_THREADS=1
OUT=docs/dev-log/simulation-artifacts/2026-07-06-a1-exemplar-totoro-pilot

for SH in 3 4; do
  R_PROFILE_USER=/dev/null Rscript --no-init-file \
    tools/run-structured-re-sigma-slope-coverage-grid.R \
    --shard=$SH --n_rep=150 --seed_start=750001 --n_each=20 \
    --bootstrap=0 --attempt-temp-install \
    --out_dir="$OUT" &
done
wait
```

(Two shards run in parallel — 2 cores, well under the cap. Each is ~150 fast fits; expect a few
minutes wall.)

## Results — EXECUTED 2026-07-06 (Totoro, n=150, seed_start 750001)

Claude ran both shards on Totoro (`~/drmtmb_work/pilot-out/`). All fits healthy:
150/150 fit, converged, `pdHess`, 0 boundary for both targets.

| Target (truth SD) | Wald finite | **Profile finite** | **Profile coverage** (MCSE) | mean est (bias) |
|---|---|---|---|---|
| `sd:sigma:spatial(1 \| site)` — intercept (0.50) | 138/150 = 0.920 | **150/150 = 1.000** | **0.853** (0.029) ✗ | 0.395 (−0.105) |
| `sd:sigma:spatial(0 + x \| site)` — slope (0.38) | 144/150 = 0.960 | **150/150 = 1.000** | **0.947** (0.018) ✓ | 0.339 (−0.041) |

**Read:**
1. **Profile fixes the finite-Wald blocker** — 1.000 finite for both vs Wald 0.920/0.960 (Wald
   reproduces the documented ~0.936 on the intercept). The stated `planned` blocker is resolved.
2. **Slope SD (the namesake target) ≈ nominal** — profile coverage 0.947 within 1 MCSE of 0.95;
   a certify candidate (SR475 projects MCSE ~0.010).
3. **Intercept SD under-covers (0.853, ~3.3 MCSE low) with −0.10 downward bias** — profile is
   finite but too narrow/low; truth misses high. This is the **right-tail miss-asymmetry** on the
   sigma axis, where the design-219 bias+t widening (location-axis only) does not reach. Matches
   the ledger next_gate's "validate a sigma-specific interval channel."

## Decision rule (Fisher, on the pasted summaries)

1. **Pathology triage** — `pdHess`/finite ≥ ~0.95 and `n_boundary` small ⇒ the cell is
   grid-healthy; if not, it may be a holdout (like the excluded `animal sigma:x`), recorded with
   a reason rather than forced.
2. **Finite-rate signal** — does profile's finite-rate sit at/above Wald's, and does Wald's
   reproduce the ~0.936 order near the intercept SD? (Directional only at n=150; the certify run
   adjudicates 0.95.)
3. **Size the certify run** — project `profile_mcse` to n=475; if it clears ≤ 0.01 with margin,
   **SR475**; if marginal or the estimator shows right-tail skew, **SR1000**. This number feeds
   the P1.3 Nibi `--array` runbook.

## Next (revised by the result)

Not a clean go-to-certify: the fits are healthy and profile fixes finiteness, but the two SD
targets diverge on coverage. So the certify dispatch waits on a **method/scope decision**:
- **Slope SD** — certify-ready; queue an SR475 grid (Totoro or Nibi) to confirm 0.947 at MCSE ≤ 0.01.
- **Intercept SD** — under-covers; before any certify, probe the **bootstrap fallback** (does the
  percentile bootstrap cover better than profile's 0.853?), and decide whether the cell's
  inference target is the slope alone (→ certifiable) or requires both SDs (→ intercept blocks,
  needs a sigma-axis small-sample channel — a method slice adjacent to the deferred `supported`
  skew work). Fisher/Rose call.
