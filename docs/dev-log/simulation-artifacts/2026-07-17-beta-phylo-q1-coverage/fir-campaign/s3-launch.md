# drmTMB Beta-phylo-q1 direct-SD coverage campaign — fir SLURM launch (S3)

Date: 2026-07-17
Engineer: Grace (reproducibility)
Cluster: fir, account **def-snakagaw_cpu** (NOTE: the brief said `def-snakagaw`;
fir's actual CPU account is `def-snakagaw_cpu` — `def-snakagaw` is rejected).
Repo: /home/snakagaw/projects/def-snakagaw/z3437171/drmTMB-cov/repo (a9b2633c)
Harness: repo/tools/run-beta-phylo-q1-sd-coverage.R
R library: /home/snakagaw/projects/def-snakagaw/z3437171/drmTMB-cov/Rlib (/project)
Campaign root: /home/snakagaw/projects/def-snakagaw/z3437171/drmTMB-cov/coverage-out

## Design decisions & findings

1. **Grid = full 12 cells (superset of the harness default).** The harness's
   `pr2c_cells()` deliberately DROPS the two g1024xm2 cells (its documented
   "2 promotion + 8 context" = 10-cell design). The coordinator's spec is the
   full 2x3x2 = 12-cell factorial at N=1200 each (14,400 units). The 12-cell
   grid is reachable WITHOUT modifying the harness: pass `cells = pr2_cells()`
   (all 12) with a `role` column added. The g1024xm2 frozen seeds already live
   in `pr2_seed_grid("certification")`, so the coverage seed audit passes for
   all 12 cells. g1024xm2 cells are treated as CONTEXT.

2. **`--file=` gotcha (Curie) is real and was hit.** Invoking `Rscript wrapper.R`
   poisons the harness `pr2c_here()` (it reads `--file=` before the option
   fallback), resolving the interior-runner path to the wrong directory. FIX,
   used everywhere: invoke as
   `Rscript -e "options(drmTMB.coverage.runner_path=..., drmTMB.successor.runner_path=...); source('<harness>'); source('<driver>')"`.
   Sourcing (not `Rscript file.R`) also keeps the harness's `sys.nframe()==0`
   auto-run guard from firing.

3. **FlexiBLAS thread pinning (from S2 reproducibility).** Every task exports
   `OMP_NUM_THREADS=1 FLEXIBLAS_NUM_THREADS=1 BLIS_NUM_THREADS=1
   OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1` and `--cpus-per-task=1`.

4. **Memory is tiny.** Measured peak maxRSS for the most expensive cell
   (g1024xm4 fit+profile) = 348 MB; smoke g256 tasks = 266-293 MB. The brief's
   6-8 GB guess was ~20x too high. Array `--mem=2G` (6x headroom); aggregation
   `--mem=8G` (concatenates 816 TSVs).

5. **Measured per-replicate cost (fit+wald+profile, single-thread), m=4:**
   g256 ~69s, g512 ~186s, g1024 ~367s. profile dominates. reps-per-task sized
   to ~60 min base: **g256=50, g512=20, g1024=10** (m=2 cells reuse the same
   per-g chunking and finish faster). 816 tasks total (g256:96, g512:240,
   g1024:480), 14,400 replicates.

6. **Robustness for the strict `afterok` chain.** Each replicate is wrapped in
   `tryCatch` in the task driver, so a single pathological rep (e.g. tripping the
   harness scale guard) is logged and skipped rather than failing the task and
   blocking aggregation. Gaps are caught by the aggregation completeness check.

## Seed provenance

Frozen grid: coverage-out/seed-audit/coverage-seed-grid.tsv (14,400 rows)
SHA-256: 1c67e66be2e348efc565ace523e84cae017a5e3845747b25ebd7da49dfbf33f6
Audit (via harness `pr2c_seed_audit`): frozen_matches_certification=TRUE,
extra_disjoint_from_known=TRUE, seeds_unique=TRUE, pass=TRUE.
Per cell: reps 1-400 = frozen certification seeds (shared with the point
campaign); reps 401-1200 = deterministic `extra_coverage` draws
(base 1990000000 - 10000*cell_number - replicate), disjoint from every known
certification/smoke/one_fit grid in both lineages.

## SMOKE (job 49347996, array 1-2): PASS

2 tasks x 3 g256 reps (distinct_g0256_m02, distinct_g0256_m04). Both COMPLETED
(exit 0:0), 0 rep_errors, all fit_success=TRUE / pdHess=TRUE. Column gate over
all 6 reps:
- wald + profile, alpha_intercept + alpha_x: lower/upper/covered non-NA 6/6 each.
- scale == "link" for all four method x coefficient combinations.
- covered is a genuine TRUE/FALSE mix (not trivially all-TRUE), confirming live
  scoring: e.g. wald alpha_x covered = T,T,F,T,F,T.
- profile per-rep elapsed 60-99s (g256), consistent with sizing.

## FULL ARRAY

- Job id: **49348332**  (`sbatch --parsable coverage-out/scripts/cov_array.sh`)
- Array: **1-816%400**  (816 tasks, concurrency capped at 400)
- Per task: `--cpus-per-task=1`, `--mem=2G`, `--time=02:30:00`,
  `--account=def-snakagaw_cpu`
- Each task writes its OWN TSV: coverage-out/per-task/raw-coverage-task-NNNNN.tsv
  (+ progress-task-NNNNN.log, errors-task-NNNNN.log) — no shared-append lock
  contention across tasks.

## AGGREGATION (chained)

- Job id: **49348333**, submitted `--dependency=afterok:49348332`.
- Reads coverage-out/per-task/*.tsv, concatenates, runs the harness
  `pr2c_aggregate_coverage` + `pr2c_aggregate_tree`, plus a manifest-based
  completeness check.
- Writes to coverage-out/summary/:
  - coverage-summary.tsv (per cell x method x coefficient: attempted,
    interval_finite_n/rate [= profile_finite_rate for profile rows], hits, rate,
    mcse, exact_ci_lower/upper [Clopper-Pearson], miss_below_n, miss_above_n,
    mean_width)
  - coverage-tree-summary.tsv (per-cell tree structure: depth, mean pairwise
    distance, mean off-diagonal correlation, effective-N proxy)
  - raw-coverage-all.tsv (concatenated raw)
  - coverage-completeness.tsv (expected vs observed reps per cell)

## Output paths (all on /project, not /scratch)

- Per-task raw TSVs: coverage-out/per-task/raw-coverage-task-*.tsv
- Final summaries:   coverage-out/summary/{coverage-summary,coverage-tree-summary,raw-coverage-all,coverage-completeness}.tsv
- Frozen seeds:      coverage-out/seed-audit/coverage-seed-grid.tsv (+ .sha256)
- Manifest:          coverage-out/scripts/coverage-task-manifest.tsv
- SLURM logs:        coverage-out/logs/cov-49348332_*.{out,err}, agg-*.{out,err}

## Estimated completion

Total compute ~= 660 CPU-hours (measured per-rep x 14,400). At the 400-core
concurrency cap, fully packed => ~1.7 h of compute; realistically, with fir
queue ramp and g1024 task granularity (480 tasks at ~60-95 min each),
**~3-6 h wall** from now to the last array task, subject to cluster load. The
aggregation job auto-releases within ~5-10 min of the final task and runs in
~5-15 min. Monitor: `squeue -j 49348332`, `sacct -j 49348332`, and
coverage-out/summary/ for the final TSVs once 49348333 completes.
