# Deploy + run the SR475 sigma-slope coverage grid on DRAC (fir)

This is a **self-contained runbook for you to execute on fir** (Claude is blocked
from transferring code to external hosts, so you run the `scp` + cluster steps).
Everything here has been built and locally verified; the only thing left is
deployment + the cluster run.

## What this runs

A coverage grid for the **7 admitted** Gaussian structured-RE sigma one-slope
direct-SD targets:

| shard | provider | target |
|---|---|---|
| 1 | phylo | sigma:(Intercept) |
| 2 | phylo | sigma:x |
| 3 | spatial | sigma:(Intercept) |
| 4 | spatial | sigma:x |
| 5 | animal | sigma:(Intercept) |
| 6 | relmat | sigma:(Intercept) |
| 7 | relmat | sigma:x |

`animal sigma:x` is the excluded profile-failure holdout (not in the array).
475 reps/target → MCSE ≈ 0.01 at nominal 0.95. Intervals: Wald + endpoint-profile
(bootstrap off). Runtime is small: measured ~0.1–0.2 s/fit locally, so each shard
is **a few minutes**, not hours. The runner is **resumable** (re-running a shard
skips seeds already written).

Pilot status: **phylo + relmat coverage is pilot-validated near-nominal** (96–98%,
100 reps). **spatial + animal coverage is estimated by this grid** (their DGP was
verified to match the fitted model's covariance, but coverage itself wasn't
pre-measured). Expect a non-trivial **spatial profile** non-finite rate (known;
retained in the denominator, not dropped).

## Files to transfer (from this Mac)

- `drmTMB_0.1.4.tar.gz` (repo root) — clean source tarball
- `tools/run-structured-re-sigma-slope-coverage-grid.R`
- `tools/slurm/sigma-slope-coverage-grid.sbatch`

## Step 1 — transfer to fir

```sh
# run locally (your terminal)
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
DEST=/project/def-snakagaw/snakagaw/sigcov-deploy
ssh fir "mkdir -p $DEST/tools/slurm"
scp drmTMB_0.1.4.tar.gz fir:$DEST/
scp tools/run-structured-re-sigma-slope-coverage-grid.R fir:$DEST/tools/
scp tools/slurm/sigma-slope-coverage-grid.sbatch fir:$DEST/tools/slurm/
```

## Step 2 — install drmTMB on fir (one time)

```sh
ssh fir          # then, on the login node:
module load StdEnv/2023 gcc/12.3 r/4.4.0
export DRMTMB_RLIB=/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4
mkdir -p "$DRMTMB_RLIB"
export R_LIBS="$DRMTMB_RLIB"

# deps need internet -> login node:
R -e 'install.packages(c("cli","RcppEigen","TMB"), repos="https://cloud.r-project.org/")'

# drmTMB compile (drmTMB.cpp is a large TMB model -> RAM-heavy).
# Try on the login node first:
R CMD INSTALL /project/def-snakagaw/snakagaw/sigcov-deploy/drmTMB_0.1.4.tar.gz
# If it is killed (login nodes kill RAM hogs), compile on a compute node instead
# (no internet needed now that deps are installed):
#   salloc --account=def-snakagaw_cpu --time=0:45:00 --cpus-per-task=2 --mem=8G
#   module load StdEnv/2023 gcc/12.3 r/4.4.0
#   export R_LIBS=/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4
#   R CMD INSTALL /project/def-snakagaw/snakagaw/sigcov-deploy/drmTMB_0.1.4.tar.gz
#   exit
```

If you hit a `TMB was built with Matrix version ...` mismatch at load time,
reinstall TMB from source against the cluster's Matrix:
`R -e 'install.packages("TMB", type="source", repos="https://cloud.r-project.org/")'`.

## Step 3 — verify it loads

```sh
R_LIBS=$DRMTMB_RLIB Rscript -e 'library(drmTMB); cat("drmTMB OK\n")'
```

## Step 4 — test ONE shard, then submit the full array

```sh
export DRMTMB_RLIB=/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4
export DRMTMB_REPO=/project/def-snakagaw/snakagaw/sigcov-deploy
cd "$DRMTMB_REPO"

# (a) quick test: shard 1, 10 reps, ~1 min — confirms the cluster path end-to-end
sbatch --array=1 --time=0:20:00 \
  --export=ALL,DRMTMB_RLIB,DRMTMB_REPO \
  tools/slurm/sigma-slope-coverage-grid.sbatch
#   ^ then check the .out file + the result TSV before the full run.
#     (the runner reads --n_rep=475 from the sbatch; for a 10-rep smoke,
#      temporarily edit --n_rep in the sbatch, or just run the full array —
#      each shard is only a few minutes.)

# (b) full grid: all 7 shards
sbatch --export=ALL,DRMTMB_RLIB,DRMTMB_REPO \
  tools/slurm/sigma-slope-coverage-grid.sbatch
```

## Step 5 — monitor

```sh
squeue -u $USER
ls -t sigcov-*.out | head        # SLURM logs in the submit dir
```

## Step 6 — collect results

Each shard copies its TSVs to `/project/def-snakagaw/snakagaw/sigcov-results/`.
Pull them back to this repo for analysis + banking:

```sh
# run locally
scp 'fir:/project/def-snakagaw/snakagaw/sigcov-results/*.tsv' \
  "/Users/z3437171/Dropbox/Github Local/drmTMB/docs/dev-log/simulation-artifacts/2026-06-27-sigma-slope-coverage-grid/"
```

## Step 7 — after results land (next Claude/Codex session)

- Read the 7 shard summaries → per-target coverage (Wald + profile), boundary
  rate, MCSE.
- Only then: bank a coverage sidecar + validator + after-task, and (if coverage
  is acceptable at MCSE ≤ 0.01) move the linked q-series cells'
  `coverage_status` off `planned`. Do **not** promote `supported` without the
  full ladder (point-fit + fixture-parity + interval reliability + coverage).
- Keep animal `sigma:x` a visible holdout until its profile failure is resolved.

## Second lane — q2-slope coverage grid (optional, after sigma)

The bivariate Gaussian structured **q2 slope-only** lane (`mu1:x + mu2:x`) is also
deploy-ready (banked in PR #681; runner Fisher-verified SOUND, DGP↔model aligned).
drmTMB is already installed from Steps 2–3, so this lane only needs transfer +
submit + collect.

| shard | provider | target |
|---|---|---|
| 1 | phylo | mu1:x |
| 2 | phylo | mu2:x |
| 3 | phylo | cor(mu1:x, mu2:x) |
| 4 | spatial | mu1:x |
| 5 | spatial | mu2:x |
| 6 | spatial | cor(mu1:x, mu2:x) |
| 7 | animal | mu1:x |
| 8 | animal | mu2:x |
| 9 | relmat | mu1:x |
| 10 | relmat | mu2:x |

`animal cor` and `relmat cor` are excluded profile-failure holdouts (not in the
array). Seed manifest 730001..730475.

```sh
# (a) transfer the two q2 files (drmTMB already installed):
DEST=/project/def-snakagaw/snakagaw/sigcov-deploy
scp tools/run-structured-re-q2-slope-coverage-grid.R fir:$DEST/tools/
scp tools/slurm/q2-slope-coverage-grid.sbatch        fir:$DEST/tools/slurm/

# (b) submit all 10 shards (on fir, with DRMTMB_RLIB/DRMTMB_REPO exported):
sbatch --export=ALL,DRMTMB_RLIB,DRMTMB_REPO tools/slurm/q2-slope-coverage-grid.sbatch

# (c) collect (run locally):
scp 'fir:/project/def-snakagaw/snakagaw/q2slopcov-results/*.tsv' \
  "/Users/z3437171/Dropbox/Github Local/drmTMB/docs/dev-log/simulation-artifacts/2026-06-27-q2-slope-coverage-grid/"
```

Then Step 7 applies identically (per-target coverage → bank a coverage sidecar →
move only the exact q2 slope cells' `coverage_status` off `planned`).

**Note (MCSE bar):** 475 reps gives MCSE ≈ 0.01 only *at* nominal 0.95 coverage;
under-coverage inflates MCSE above 0.01, so SR475 sizes the coverage *estimate*,
not a guaranteed-passable 0.01-MCSE *gate*. Read the `mcse_threshold_met` column
accordingly. The **q4-location** runner exists but is **HELD** (unverified
`sdpars$mu` key + a stale pilot artifact) — do **not** deploy it until Codex
regenerates its pilot and confirms the SD key against a live fit.

## Guard reminders

- These grids are the **sigma one-slope** and **q2 slope-only** lanes only. They
  do not touch q4/bridge/REML/AI-REML, and they do not by themselves promote
  public support.
- `def-snakagaw_cpu` allocation; jobs are tiny (~minutes), so cost is minimal.
