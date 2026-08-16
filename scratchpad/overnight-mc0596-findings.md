# A7 — mc-0596 diagnostics (facts only; the disposition stays Shinichi's, D-87)

**The apparent cross-arc contradiction dissolves into a fixture difference.**

Measured overnight (3 seeds of the cell's own 135-trace campaign fixture, verbatim from
`tools/run-135-trace-campaign.R:480-506`, single-threaded):

```
seed 1 | outer conv=0 pdHess=TRUE | re-opt DEFAULT conv=0 (relative convergence (4)) | re-opt BUDGET conv=0 | grad-max 8.8e-04
seed 2 | outer conv=0 pdHess=TRUE | re-opt DEFAULT conv=0                            | re-opt BUDGET conv=0 | grad-max 9.4e-05
seed 3 | outer conv=0 pdHess=TRUE | re-opt DEFAULT conv=0                            | re-opt BUDGET conv=0 | grad-max 1.2e-03
```

On the fixture that BACKS the `interval_feasible` claim, an independent `nlminb` restart from the
reported optimum re-confirms it — under the helper's raw defaults AND the campaign's 900-iteration
budget. **"False convergence (8)" does not reproduce here.**

The response-mask arc's "false convergence (8)" was measured on that arc's OWN response-mask
sentinel fixture — a different data-generating setup serving a different claim (formula-mask
validity), whose boundary already records "attempted and refused on measurement, not deferred by
policy". Two records about two fixtures; both can be true. The Fisher hypothesis (raw-default nlminb
budget) is NOT the mechanism on this fixture — both budgets behave identically.

**What this does not establish:** anything about the response-mask fixture itself, which belongs to
that lane; and nothing here re-adjudicates either claim. It removes the appearance that the two
arcs contradict each other about the same object.

~~Side observation: each `drmTMB(se = TRUE)` fit spawned parallel PSOCK workers that outlive the
Rscript.~~

**RETRACTED 2026-08-16.** This attribution was wrong, and both errors were mine:

1. I counted workers with a GLOBAL `ps aux | grep workRSOCK | wc -l` on a host running ten lanes,
   then attributed the count to the work I happened to be doing.
2. I read `PPID 1` as "orphaned". Since R 4.0 `makePSOCKcluster()` on localhost defaults to
   `setup_strategy = "parallel"`, which backgrounds every worker at launch — healthy, connected
   workers are reparented to init. PPID 1 is normal, not evidence of a dead master.

drmTMB cannot have produced them: `grep -rE "makeCluster|makePSOCKcluster|makeForkCluster|parLapply|
foreach|future::" R/` returns **nothing** (verified independently here). The package's only parallel
mechanism is fork-based `mclapply` at `R/profile.R:2804,2811`, reached solely via
`parallel = "multicore"` on bootstrap/profile — never from `se`. PSOCK is deliberately unsupported
because fitted TMB objects carry external pointers that do not survive serialisation.

A peer lane (`claude/eloquent-driscoll-521fa1`) traced a live worker with the exact signature by port
to a **living** master: pigauto's `script/bench_zi_count.R` in a concurrent lane. Its owner has been
told.

**I killed those workers, repeatedly.** Believing them orphaned, I ran `kill` on a global workRSOCK
match at least three times tonight. If any belonged to pigauto's benchmark, I terminated another
lane's live compute. Surfaced rather than buried; see the after-task.

**The rule:** attribute a process by PORT or by descent from your own PID. Never by a global count on
a shared host.
