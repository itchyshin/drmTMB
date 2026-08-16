# After Task: the `se = TRUE` PSOCK worker leak did not reproduce, and the workers belong to another project

**Read this first.** The task was to find, test, and fix a parallel-worker leak
on `drmTMB()`'s `se = TRUE` path. There is no such leak. The reported symptom is
real — orphaned PSOCK workers do accumulate on this machine — but the culprit is
`pigauto`'s benchmark scripts, not `drmTMB`. What landed here is a regression
guard for the invariant, not a fix, and this report is mostly evidence for the
re-attribution.

## 1. Goal

Locate where `drmTMB()` creates a parallel cluster on the `se`/`sdreport` path,
explain why teardown is skipped, write a failing test that counts child
processes across a fit, and fix the teardown. Verification target: three
consecutive `se = TRUE` fits leave zero `workRSOCK` processes.

The verification target is met. The first three steps could not be carried out
as specified, because each of their premises is false. That is the finding.

## 2. Implemented

1. `tests/testthat/test-parallel-worker-hygiene.R` — two regression guards.
   The first scans every function in the `drmTMB` namespace for a cluster
   constructor (`makeCluster`, `makePSOCKcluster`, `makeForkCluster`,
   `makeClusterPSOCK`) and requires the offender set to be empty. The second
   fits a Gaussian location-scale model with `drm_control(se = TRUE)` and
   asserts the process's own child count is unchanged across the fit, after
   pinning that `fit$sdr` is non-`NULL` so a skipped `sdreport()` cannot make
   the count trivially true.
2. This report.

No package code changed. `R/`, `src/`, `DESCRIPTION`, and `NAMESPACE` are
untouched, because there was nothing on the `se` path to repair.

## 3a. Decisions and Rejected Alternatives

**The re-attribution rests on a live capture, not on absence of evidence.**
While grepping, a `workRSOCK` process was running on this host: PID 60768,
PPID 1, 73% CPU, `TIMEOUT=2592000`, `PORT=11136` — matching the reported
signature in every particular, including the PPID 1 that the report read as
orphaning. `lsof -nP -iTCP:11136` showed both ends of an ESTABLISHED
connection: the worker at 60768 and its master at 60545, alive, which `ps`
identified as `pigauto`'s `script/bench_zi_count.R` running in a concurrent
lane. That script calls `parallel::makeCluster()` at line 192 and
`parallel::stopCluster(cl)` at line 211 with no `on.exit()` — the exact defect
the task description predicted, in a different repository. All eight
`script/bench_*.R` files in that lane share it (`grep -c on.exit` = 0 for each).

**PPID 1 is not evidence of orphaning, and this is what made the original
attribution look sound.** Since R 4.0, `makePSOCKcluster()` on localhost
defaults to `setup_strategy = "parallel"`, which launches all workers from one
backgrounded shell command; they are reparented to `init` immediately, while
healthy and connected. The captured worker's command line ends
`SETUPSTRATEGY=parallel`, and it was reparented from birth. A `workRSOCK`
census that reads PPID 1 as "master is dead" will report healthy workers as
orphans, and on a machine running ten lanes it will attribute them to whichever
project the observer happened to be looking at.

**The guard counts this process's own children, not a global `workRSOCK`
census.** A global census is exactly the instrument that produced the wrong
answer. Counting children by PPID is self-attributing and cannot be
contaminated by a concurrent lane. The cost is that it would not catch a leak
routed through a detached grandchild — an acceptable gap, since drmTMB creates
no subprocess of any kind on this path.

**Nothing was changed in `pigauto`.** It is another lane's repository and
another lane's live working tree; the bench run was mid-flight during this
session. Surfaced, not touched.

**The static scan is deliberately broader than PSOCK.** `makeForkCluster()` is
not PSOCK and would not produce the reported signature, but it returns a
cluster object that leaks identically when `stopCluster()` is skipped, so
excluding it would guard the symptom rather than the mechanism.

## 4. Files Touched

| File | Change |
| --- | --- |
| `tests/testthat/test-parallel-worker-hygiene.R` | New. 2 tests, 3 assertions. |
| `docs/dev-log/after-task/2026-08-16-se-path-worker-leak-nonrepro.md` | New. This report. |

Read but not modified: `R/drmTMB.R` (`drm_compute_uncertainty()`, lines
2675–2745), `R/profile.R` (lines 2733–2812), `tests/testthat/test-profile-targets.R`,
`tools/run-135-trace-campaign.R`, `DESCRIPTION`, and — outside this repository,
read-only — `pigauto/.worktrees/bench-rerun/script/bench_zi_count.R`.

## 5. Checks Run

Runtime evidence used the installed `drmTMB` 0.7.0
(`~/Library/R/arm64/4.6/library/drmTMB`); the source evidence is `grep` over
this worktree's `R/`. Both point the same way, and the divergence is stated in
§10.

**Source scan.** `grep` for `makeCluster|makePSOCKcluster|makeForkCluster|stopCluster|clusterExport|parLapply|future::|multisession|doParallel|foreach` across `R/` returns
nothing. The only hits in the whole repository are
`tools/ayumi-parametric-bootstrap-prototype.R:431-462`, a prototype outside the
package that already pairs `makeCluster()` with
`on.exit(parallel::stopCluster(cluster), add = TRUE)` on the next line. The
package's only parallel mechanism is `parallel::mclapply()` at
`R/profile.R:2804` and `:2811`, reached solely from the opt-in bootstrap and
profile helpers via `parallel = "multicore"`, never from `se`.

**`se = TRUE` is a single in-process call.** `drm_compute_uncertainty()`
(`R/drmTMB.R:2675`) dispatches to `TMB::sdreport()` inside `tryCatch()` and
returns. No process is created on any branch, including the error branch.

**Reproduction, direct fits.** Three `drmTMB(se = TRUE)` fits of the mc-0596
fixture — zero-one-beta, `sigma ~ spatial(1 | site)`, 640 rows, 16 sites,
transcribed from `tools/run-135-trace-campaign.R:484-506` — run in one
`Rscript`, recording the `workRSOCK` PID **set** and the process's own child
count before and after each fit:

```
BEFORE: workRSOCK pids = 60768        # pre-existing, pigauto's, still connected
fit 1: 0.9s  workRSOCK now = 1  own children = 1
fit 2: 0.6s  workRSOCK now = 1  own children = 1
fit 3: 0.6s  workRSOCK now = 1  own children = 1
NEW workers attributable to this run: 0
```

The constant `own children = 1` is the `ps` subprocess doing the counting.

**Reproduction, the named test file.** `test-profile-targets.R` run three
consecutive times with `NOT_CRAN=true`, with a worker census between runs:

```
== BEFORE ==  workRSOCK: []   R procs: 1
run: FAIL=0 PASS=986   after run 1 -> workRSOCK: []
run: FAIL=0 PASS=986   after run 2 -> workRSOCK: []
run: FAIL=0 PASS=986   after run 3 -> workRSOCK: []
== AFTER ==   workRSOCK: []   R procs: 0
```

986 assertions pass, 41 s per run, zero workers and zero stray R processes
after three runs. This is the task's stated verification target, met — though
it was already met before this branch existed.

**New guard.** `test_file("tests/testthat/test-parallel-worker-hygiene.R")` →
`FAIL=0 PASS=3 SKIP=0`.

## 6. Tests of the Tests

**The static scan has teeth.** Run against a stand-in environment holding one
innocent function and one planted
`function() { cl <- parallel::makeCluster(2L); parallel::stopCluster(cl) }`,
the same scan logic returns `drm_fake_cluster_helper` — so the guard fails when
an offender exists. The plant was done in a separate environment because
`drmTMB`'s namespace is locked and cannot take a new binding; the logic under
test is identical.

**The process-count guard is honestly weak, and the report says so.** It cannot
fail today, because the mechanism it guards is absent. Its value is that it
would have failed had the reported symptom been real, which is what makes the
non-reproduction a measurement rather than an assertion. The `expect_false(is.null(fit$sdr))`
line exists because without it, a future change that silently skipped
`sdreport()` would leave the process assertion green and meaningless.

**Not tested: the `mclapply` paths.** Fork children are not `workRSOCK` and are
not on the `se` path, so no guard was added for
`confint(method = "bootstrap", parallel = "multicore")`. See §10.

## 7a. Issue Ledger

- **Closed by evidence, not by code:** "drmTMB `se = TRUE` leaks PSOCK
  workers." Not reproducible; no such code path exists. Re-attributed below.
- **Opened and CLOSED the same day, another repository:** `pigauto`'s eight
  `script/bench_*.R` files called `parallel::makeCluster()` with
  `stopCluster()` on the success path only and no `on.exit()`. Any error,
  interrupt, or non-local exit between the two leaked the whole cluster —
  workers at 60-100% CPU with a 30-day `TIMEOUT`, which is the reported
  signature. Reported to that lane rather than fixed here (foreign lane, live
  working tree); it verified the claim independently and fixed it in
  `pigauto` PR #166 / `c536499` on `fix/bench-cluster-on-exit`, 8 files, 5
  lines each. Confirmed by reading that commit: it adds
  `on.exit(try(parallel::stopCluster(cl), silent = TRUE), add = TRUE)`. The
  `try()` is a correction to the one-liner suggested from here — a bare second
  `stopCluster()` on the success path errors on already-closed connections, so
  the guard needed to tolerate an already-stopped cluster.
- **Opened, method:** any future worker census must attribute by master PID
  (`lsof -nP -iTCP:<PORT>` against the worker's `PORT=` argument), never by
  PPID and never by a global count. Recorded in §11.

## 8. Consistency Audit

The design record already says drmTMB has no PSOCK path, and the code matches
it. `docs/design/43-phase-18-interval-producer-contract.md:124`,
`docs/design/35-optimizer-start-map-multistart.md:430`, and six after-task
reports from 2026-05-19/20 all state that PSOCK is excluded because fitted TMB
objects carry external pointers that do not survive serialisation to a fresh
worker, and that `multicore` is capped at 10 workers. `NEWS.md:1451` states the
same for users. Nothing in the documentation claimed a cluster that the code
does not create, so no doc drift was introduced by this task and none needed
correcting.

The new test file's placement and comment style match the repository's other
guard files (`test-clamp-active-guard.R`, `test-arc-c-clamp-hardening.R`),
including the explicit falsification-status paragraph those files carry.

## 9. What Did Not Go Smoothly

**The premise was specific, internally coherent, and wrong, which is the hard
case.** It named a signature (`TIMEOUT=2592000`), a mechanism (missing
`on.exit`), a trigger (`se = TRUE`), a file, and a deliberate reproduction with
a count. Every element was true of something; only the attribution was wrong.
Had the first move been "grep `R/` for `makeCluster` and find nothing, then
conclude the helper must hide it elsewhere", this would have ended in a
fabricated fix. What broke the loop was catching a live worker and asking who
owned its port — one `lsof` call.

**The machine was running ten lanes concurrently**, including a second drmTMB
lane at `~/local-scratch/lanes/drmTMB-interval-truth-audit`, a `gllvmTMB`
compile, and the `pigauto` bench. That is what made a global `workRSOCK` count
uninterpretable, and it is also what made the live capture possible.

**The first reproduction script failed on `spatial(1 | site, coords = fx$coords)`** —
the marker requires `coords` to name an object, not an expression. Assigning
`coords <- fx$coords` first fixed it. Worth knowing for anyone transcribing
campaign fixtures into a scratch script.

## 10. Known Residuals

- **Runtime evidence is against installed 0.7.0, not a build of this
  worktree.** The worktree has no compiled `src/*.so` and building it would
  have competed with a concurrent `gllvmTMB` compile for the machine. The
  source-level claim (no cluster constructor in `R/`) is verified against this
  worktree's HEAD directly by `grep`; the runtime claim is verified against
  0.7.0. If HEAD's `R/` had gained a cluster since 0.7.0, the `grep` would have
  caught it, so the two do not disagree — but the guard test has not been run
  against a `pkgload::load_all()` of this tree.
- **The `mclapply` paths are unguarded.** `confint(method = "bootstrap",
  parallel = "multicore")` and the profile helpers fork children. `mclapply()`
  reaps them on normal return and on worker error, but a user interrupt during
  the fork window can leave them. That is upstream base-R behaviour, was not
  the reported symptom, and no test covers it.
- ~~**The `pigauto` leak is reported, not fixed.**~~ **Closed 2026-08-16** by
  `pigauto` PR #166 / `c536499`; see §7a. That lane also reported the
  behavioural check this report could not run from here: a simulated mid-run
  failure now returns the worker count to baseline, and the success path still
  exits cleanly with the double stop.
- **No `R CMD check` was run.** The change is one new test file with no new
  dependency; a full check was not proportionate and the machine was loaded.

## 11. Team Learning

**Rose.** The re-attribution is the deliverable; the guard test is the
by-product. A report that had simply said "fixed the leak" after adding an
`on.exit()` somewhere plausible would have been worse than useless, because the
real leak would have kept running while the ticket read closed.

**Grace.** PPID 1 on a PSOCK worker means nothing since R 4.0 — the
`setup_strategy = "parallel"` default backgrounds every localhost worker at
launch. The only sound liveness test for a worker is its port: read `PORT=`
from the worker's own command line and run `lsof -nP -iTCP:<PORT>`. Two
ESTABLISHED endpoints means healthy; one means orphaned.

Two neighbouring traps on the same mechanism, both hit by other lanes this
week and both worth knowing before touching anyone's running compute.
**Master CPU is not a liveness signal**: `parLapply` logs nothing until every
cell finishes, so a healthy driver looks idle — the `pigauto` lane killed two
healthy drivers reading it that way. And **never `renice` a process that will
later fork PSOCK workers**: niceness is inherited at fork, the workers then
miss `makePSOCKcluster()`'s connect window, and no later renice of the parent
fixes them. Bound cluster load by worker count, never by priority. Filed by
the `gllvmTMB` lane at `~/shinichi-brain/memory/LESSONS.md:2082` (verified
present), and not duplicated here.

**Shannon.** On a host running ten lanes, any global process census is a shared
resource and cannot attribute anything. Measure by PID set difference plus
ownership, or do not measure.

**Fisher.** The distinguishing evidence was cheap and available from the first
minute. The expensive path — build the tree, run the campaign, count again —
would have produced the same ambiguous global count at far higher cost.

## 12. Cross-Product Coverage

**What this task covers.** The `se = TRUE` / `TMB::sdreport()` route in
`drm_compute_uncertainty()`, exercised through two fixtures (Gaussian
location-scale, and zero-one-beta with a spatial `sigma` random effect), plus
the whole of `test-profile-targets.R` at 986 assertions. Both the static
namespace scan and the runtime child-process census were applied.

**What this task does NOT cover.**

- It does **NOT** cover `parallel = "multicore"` execution. The fork-based
  `mclapply()` paths at `R/profile.R:2804` and `:2811` were never exercised;
  the direct fits and `test-profile-targets.R` both ran with
  `bootstrap.parallel == "none"` and `workers == 1`. Whether an interrupted
  `mclapply()` leaves fork children is untested.
- It does **NOT** cover Windows. Both guards' runtime half is
  `skip_on_os("windows")`, and `mclapply()` is unavailable there anyway.
- It does **NOT** cover a leak routed through a detached grandchild, which a
  PPID-based census cannot see.
- It does **NOT** cover other fitted-model surfaces (`predict()`, `simulate()`,
  `confint(method = "profile")`, the Julia bridge, `callr`-based tests). The
  `callr` tests in `tests/testthat/test-julia-*.R` deliberately spawn R
  subprocesses; that is intended behaviour and was not audited here.
- It does **NOT** establish that the specific 14 workers seen on 2026-08-15
  were `pigauto`'s. It establishes that the named code path cannot produce
  them, that the named test file does not, and that a concurrent process on
  the same machine can and does. **Corroboration arrived after this report was
  written**, from the `pigauto` lane's own account of that night: `bench_count`
  died at cluster setup and `bench_zi_count` died mid-run with an "error
  reading from connection" signature, and four orphaned masters were killed by
  hand and written off as environmental flakiness. That is the leak mechanism
  firing on the reported night, and it matches the count in the deliberate
  reproduction. It is that lane's report of its own incident, not something
  verified from here — what was verified from here is the fix commit.
- It does **NOT** cover whatever else on this host creates PSOCK clusters. The
  `pigauto` scripts are fixed; nothing audited the other eight live lanes.
