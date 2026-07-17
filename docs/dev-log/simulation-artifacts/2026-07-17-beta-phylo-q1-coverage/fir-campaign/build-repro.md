# drmTMB on DRAC fir — build + reproducibility gate (commit a9b2633c)

Date: 2026-07-17
Engineer: Grace (reproducibility)
Cluster: fir (login node), account def-snakagaw
Repo: /home/snakagaw/projects/def-snakagaw/z3437171/drmTMB-cov/repo (a9b2633c, detached HEAD, clean)
R library: /home/snakagaw/projects/def-snakagaw/z3437171/drmTMB-cov/Rlib (== /project/6098264/z3437171/drmTMB-cov/Rlib)

## 1. BUILD: OK

Module: `module load r/4.5.0` (auto-loads StdEnv/2023, gcccore/12.3, flexiblas/3.3.1,
aocl-blas/5.1, aocl-lapack/5.1). R 4.5.0, `BLAS/LAPACK: FlexiBLAS AOCL; LAPACK 3.11.0`.

```
module load r/4.5.0
export R_LIBS_USER=/home/snakagaw/projects/def-snakagaw/z3437171/drmTMB-cov/Rlib
mkdir -p "$R_LIBS_USER"
```

Lean deps installed from CRAN source (DRAC has no binary repo for these; ~5 min,
all compiled cleanly against gcc 12.3.1/g++ 12.3.1):

```
R -q -e 'install.packages(c("TMB","RcppEigen","cli","lifecycle","ape","pkgload"),
                           repos="https://cloud.r-project.org")'
```

`Matrix` is already present as an R-recommended base-priority package in the
r/4.5.0 module tree — no install needed.

Package install (compiles the TMB C++ template into `drmTMB.so`):

```
R CMD INSTALL --no-multiarch --with-keep.source repo
```

Result: `* DONE (drmTMB)`, 1m56s wall. Only harmless Eigen template-instantiation
`-Wignored-attributes` warnings (AVX-512 packet type, cosmetic, same class of
warning RcppEigen/TMB produce on most modern gcc). No compile errors.
`library(drmTMB)` loads cleanly (only the expected `beta` masks
`base::beta` message).

## 2. CRITICAL PORTABILITY FINDING: FlexiBLAS threading, not OpenBLAS

fir's BLAS backend is **FlexiBLAS (AOCL)**, not OpenBLAS. `OPENBLAS_NUM_THREADS=1`
(as specified in the task brief) **has no effect** on fir and was silently ignored.

First attempt (env: only `OPENBLAS_NUM_THREADS=1`) spawned **65 threads** for a
trivial g=256/m=2 fit (512 rows) and had not finished the DGP+fit call after
**12+ minutes of wall time / 75+ minutes of CPU time** — a fit that takes ~3s
single-threaded. This is thread-oversubscription pathology: TMB's inner
Newton/Laplace loop calls many small BLAS/sparse-Cholesky operations per
gradient evaluation, and each one was paying full 64-thread fork/join overhead.
The process was killed (pid 4153152) rather than let run further.

**Fix:** pin threads explicitly for FlexiBLAS/OpenMP/BLIS:

```
export OMP_NUM_THREADS=1
export FLEXIBLAS_NUM_THREADS=1
export BLIS_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1   # harmless no-op on fir, kept for portability
export MKL_NUM_THREADS=1        # harmless no-op, defensive
```

With this fix the process dropped to 2 threads and ran single-core at ~90-98%
CPU, matching expected single-fit timings (see below).

**This must go in the SLURM array script** (`export` lines above, plus
`--cpus-per-task=1`), or a large array job will silently blow its time budget
and/or oversubscribe shared login-node/compute-node cores.

## 3. REPRODUCIBILITY GATE: REPRODUCES YES

Driver: sourced `tools/run-beta-phylo-q1-sd-interior-recovery.R` (successor),
which `sys.source()`s `tools/run-beta-phylo-q1-sd-regression-recovery.R`
(predecessor) for the tested `pr2_recovery_attempt()` / `beta_phylo_sd_regression_dgp()`
code. Used `pr2_recovery_attempt(row)` for point estimates + timing (reusing the
tested DGP+fit path), and separately reconstructed the identical
`beta_phylo_sd_regression_dgp()` + `drmTMB::drmTMB(...)` call (same seed, same
formula/family/control) to obtain the fit object for `confint()`. Point estimates
from both paths agreed exactly, confirming the reconstruction is faithful.

Formula fit: `y ~ x_mu + phylo(1 | spp_id, tree=tree)`, `sigma ~ x_sigma`,
`sd(spp_id, level="phylogenetic") ~ x_tau`, `family = beta()`,
`control = drm_control(optimizer_preset="robust", se_report_covariance=FALSE, se_group_sd=FALSE)`.

### g=256, m=2, distinct, seed=2079989999

| | fir | local reference |
|---|---|---|
| Intercept point est | -0.9124137 | -0.91241 |
| x_tau point est | 0.3333454 | 0.33335 |
| Wald CI Intercept | [-1.319634, -0.5051929] | [-1.31963, -0.50519] |
| Wald CI x_tau | [0.203881, 0.4628098] | [0.20388, 0.46281] |
| Profile CI Intercept | [-1.3129544, -0.5057865] | [-1.31295, -0.50579] |
| Profile CI x_tau | [0.2095891, 0.4703114] | [0.20959, 0.47031] |

fit_diag: convergence=0, pdHess=TRUE, max|gradient|=3.95e-05.

### g=1024, m=4, distinct, seed=2079939999

| | fir | local reference |
|---|---|---|
| Intercept point est | -1.1005105 | -1.10051 |
| x_tau point est | 0.1991623 | 0.19916 |
| Wald CI Intercept | [-1.3672181, -0.8338028] | [-1.36722, -0.83380] |
| Wald CI x_tau | [0.1346043, 0.2637204] | [0.13460, 0.26372] |
| Profile CI Intercept | [-1.3708339, -0.8381182] | [-1.37083, -0.83812] |
| Profile CI x_tau | [0.1357259, 0.2645715] | [0.13573, 0.26457] |

fit_diag: convergence=0, pdHess=TRUE, max|gradient|=3.42e-03.

All values agree with the local (R 4.6.0) reference to ~1e-4–1e-5 — tighter than
the ~1e-3 (point)/~1e-2 (CI) pass bar requested. No sign of cross-platform BLAS
or optimizer divergence.

## 4. TIMINGS (single-threaded, correctly pinned; login node, no other load)

| stage | g=256,m=2 (fir) | g=256,m=2 (local) | g=1024,m=4 (fir) | g=1024,m=4 (local) |
|---|---|---|---|---|
| DGP+fit (`pr2_recovery_attempt`) | 2.96s | ~3s | 21.9s | ~29s |
| DGP only | 0.52s | — | 7.55s | — |
| fit only (reconstructed) | 0.78s | — | 6.45s | — |
| Wald confint | 0.10s | — | 0.39s | — |
| Profile confint | 40.6s | ~157s | 348.8s (5.8 min) | ~1456s (24.3 min) |

fir is consistently faster per fit/profile than the local reference machine
(~3.9x on profile at g=256, ~4.2x on profile at g=1024) once threading is
correctly pinned to 1 core per fit. This is good news for array sizing: a
single (fit + Wald + profile) replicate at the largest cell (g=1024, m=4) costs
well under 6.5 minutes wall time on fir.

## 5. GO/NO-GO

**GO** for running the coverage campaign on fir as a SLURM array, conditional on:

1. Every array task must set the thread-pinning env vars in Section 2
   (`OMP_NUM_THREADS=1`, `FLEXIBLAS_NUM_THREADS=1`, `BLIS_NUM_THREADS=1`) and
   request `--cpus-per-task=1`. Untested/default threading reproduced a >36x
   slowdown (12+ min vs 3s) on a trivial fit.
2. `R_LIBS_USER` must point at `/project/.../drmTMB-cov/Rlib` (not `/scratch`),
   as already configured.
3. Size arrays using the timings in Section 4: at g=1024/m=4 (worst cell),
   budget ~6.5 min/replicate for fit+Wald+profile; smaller cells are faster.
   A 400-replicate x 12-cell certification run (per `pr2_seed_grid("certification")`)
   is dominated by the profile-CI step; consider restricting profile CI to a
   subset of replicates/cells if the full grid is run, or budgeting
   `--time` generously per array task (e.g. 15-20 min ceiling per task with
   margin, not the ~6.5 min best case) and using array concurrency
   (`--array=1-N%K`) to bound simultaneous core usage on the shared allocation.

No build, dependency, or numerical divergence blockers were found.
