# P1.1 — Totoro pilot runbook: A1 exemplar (`qseries_spatial_q1_sigma_one_slope`)

Meta: 2026-07-06 · owner Curie (driver) + Fisher (design) · **for a human/Codex to run** —
Claude cannot ssh/scp to Totoro. Paste the two summary TSVs back into the session.

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

## What to paste back

The two **summary** TSVs (small):

```bash
cat docs/dev-log/simulation-artifacts/2026-07-06-a1-exemplar-totoro-pilot/03-spatial-sigma_intercept-summary.tsv
cat docs/dev-log/simulation-artifacts/2026-07-06-a1-exemplar-totoro-pilot/04-spatial-sigma_x-summary.tsv
```

Key columns Fisher reads: `n_fit_ok`, `n_pdhess`, `n_boundary`, `n_wald_finite`,
`n_profile_finite` (→ **finite-rate** = finite/`n_fit_ok`), `wald_coverage`, `profile_coverage`,
`wald_mcse`, `profile_mcse`, `bias_mean_est`. If any rep rows are useful for miss-side
diagnosis, the `*-replicates.tsv` files carry per-rep `*_contains` and interval endpoints.

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

## Next

On a clean pilot, Grace writes the **P1.3 Nibi certify runbook** (shards 3–4 at the sized rep
count, `--seed_start=740001`, `/project/def-snakagaw`); on a pathological pilot, the exemplar
route is revised (bootstrap fallback, or holdout) before any certify dispatch.
