# Dispatch — Trust Dossier #1 full coverage grid on Totoro

The calibrated complement to the parity dossier: the broad coverage/type-I/power grid
that answers *"thousands of tests, not a few examples."* Runs on **Totoro** (384 cores,
no queue) — **never GitHub Actions** (D-50). Results stay **local**.

Driver: [`run_grid.R`](run_grid.R). Three tiers via env: `TD_SMOKE` (toy) · `TD_LOCAL`
(broad, vector-V, minutes on a laptop) · full (default, calibrated).

## Full-grid size
4 measure regimes (SMD, lnRR, logOR, logIRR) × n_study {10,20,40,80} × σ {0,0.1,0.25,0.5}
× known-V {vector, dense} × ρ {0,0.2,0.5} × 2 sampling-SD scales
= **768 cells × 2000 reps ≈ 1.5M fits**. MCSE ≈ 0.005 on a 0.95 coverage.

## Run it

```bash
# 1. Attach over the existing ControlMaster socket (the plain `ssh totoro` stanza
#    lacks ControlPath; see ~/shinichi-brain/tools/totoro-setup.md).
SOCK=~/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22
ssh -o ControlPath="$SOCK" -o ControlMaster=no totoro

# 2. One-time setup under ~/hsq_work (or any home dir — Totoro has no /project).
mkdir -p ~/td_work && cd ~/td_work
git clone https://github.com/itchyshin/drmTMB.git         # or copy the tree
cd drmTMB && git checkout claude/trust-dossier-metafor-comparison
#    Install deps into a user library (drmTMB compiles TMB — needs a compiler):
Rscript -e 'install.packages(c("TMB","metafor","glmmTMB","metadat"))'
Rscript -e 'install.packages(".", repos=NULL, type="source")'   # drmTMB itself

# 3. Launch the full grid. PIN BLAS TO 1 THREAD; cap cores <= 100 on shared Totoro.
cd ~/td_work/drmTMB
OPENBLAS_NUM_THREADS=1 TD_CORES=96 TD_OUT=~/td_work/results-grid \
  nohup Rscript inst/trust-dossier/totoro/run_grid.R > ~/td_work/grid.log 2>&1 &

# 4. Watch, then pull results back LOCAL (do not leave on a shared box long-term).
tail -f ~/td_work/grid.log
#    Each measure -> results-grid/<measure>/tables/meta-v-wald-coverage.csv
rsync -avz totoro:~/td_work/results-grid/ ./inst/trust-dossier/results-grid/
```

## Golden rules (tools/totoro-setup.md)
- **Never a login-node hog beyond your share.** Totoro is Shinichi's lab server, shared —
  keep parallelism **≤ 100 cores** (`TD_CORES=96`).
- **`OPENBLAS_NUM_THREADS=1`** always — TMB is already parallel across replicates; nested
  BLAS threads oversubscribe and slow it down.
- **Results LOCAL, not GitHub artifacts** (D-50: Actions storage is a hard 2 GB/month cap).
- Right-size before the full run: `TD_LOCAL=1` first, read one `grid.log` timing, then scale.

## DRAC alternative (job array)
Swap the launch for a SLURM array — one measure or one σ-block per `$SLURM_ARRAY_TASK_ID`,
`--account=def-<pi>`, depot/library on `/project` (never `/scratch`, ~60-day purge). See
`~/shinichi-brain/tools/drac-setup.md`.
