# 2026-10-11: parallel lane follow-up (owner decisions 18, 19, 27)

Reader: the maintainer reviewing the stacked follow-up to PR #1510.

## What the decisions asked for

At 08:53 UTC the maintainer accepted the defaults on the owner digest. The
decisions for this lane were:

- Decision 19 (#1236, #1247, #1248, #1254): add a PSOCK `"cluster"` backend;
  reuse `parallel`/`workers` in `profile()`, in `simulate()` (RNG-safe) and
  in `drm_control(multi_start)` after a benchmark; keep single fits serial
  and defer OpenMP (#1250).
- Decision 27 (#1387, #914): already done in #1510.
- Decision 18 (#861): an internal retained-bootstrap object and an internal
  shard reducer, with no export.

## What changed

**`parallel = "cluster"`.** `drm_parallel_lapply()` in `R/profile.R` now
dispatches all three backends for profile targets, endpoint arms, `newdata`
rows and bootstrap refits. Shipping the fit to PSOCK workers needed no
rebuild code. TMB's `MakeADFun` closures check `isNullPointer(ADFun$ptr)` and
re-tape from the serialized data, parameters and `last.par`. A local check on
a random-intercept fit gave `identical()` serial and cluster profiles.
Workers prepend the library holding the parent's `drmTMB`
(`drm_cluster_lib_paths()`), so a build loaded with `lib.loc` is found.
`"multicore"` on Windows now points users at `"cluster"`.

**Parallel multi-start.** `drm_control(parallel, workers)` applies only to
the `multi_start` starts. Each worker starts from the parent's untouched TMB
state. Afterwards the parent evaluates `obj$fn`/`obj$gr` at the winning start
so that `last.par` and `last.par.best` hold its optimum. Bootstrap refits
force `parallel = "none"` inside parallel bootstrap workers.

**`simulate()`** was benchmarked and left serial (table below).

**Bootstrap shards (`R/bootstrap-shards.R`, internal).** Replicate `j` draws
its data from L'Ecuyer-CMRG stream `j` after `set.seed(seed)`, so its data do
not depend on the shard or worker that runs it. Shards carry a header with
the schema version, package version and git SHA, estimator, fit
fingerprint, targets, seed, `re_form` and refit settings.
`drm_bootstrap_combine()` refuses any header difference and any repeated
replicate index. `drm_bootstrap_ledger()` reports attempted, usable and
failed counts per target.

## Measurements (4 cores, R 4.3.3, TMB 1.9.10)

| Check | Serial | Parallel | Identity |
| --- | --- | --- | --- |
| `profile()` 4 targets, cluster(4) | 11.05 s | 6.52 s (1.70x) | identical apart from `elapsed` |
| multi_start = 4, Gaussian LS RE, multicore(4) | 4.80 s | 1.95 s (2.47x) | max abs dpar 6.8e-8 |
| same, cluster(4) | 4.80 s | 3.24 s (1.48x) | same as multicore, bitwise |
| multi_start = 4, nbinom2 zi FE, multicore(4) | 0.32 s | 0.18 s (1.81x) | identical |
| same, cluster(4) | 0.32 s | 1.38 s (0.23x) | identical; startup dominates |
| `simulate()` n = 10,000, 500 marginal draws | 1.20 s vectorised | 0.89 s multicore(4) per-draw; 0.70 s serial per-draw | not adopted |
| `simulate()` conditional, same size | 0.29 s | 0.92 s multicore(4) | not adopted |

The `simulate()` per-draw path changes the random stream and does not beat
plain serial per-draw calls, so parallel `simulate()` was not added.

## Checks

New tests: `test-profile-parallel.R` (cluster profile, confint and bootstrap
identity; parallel multi-start identity for a fixed-effect fit and agreement
to 1e-6 with random effects; `drm_control()` validation) and
`test-bootstrap-shards.R` (replay, partition equality, five fail-closed
cases, retained failures, multicore identity). The Julia control-totality
tests gained probes for the two new `drm_control()` fields. Suite results
are in the PR body.

## Not done

OpenMP (#1250) stays parked by decision. Parallel `simulate()` was not added
after the benchmark.
