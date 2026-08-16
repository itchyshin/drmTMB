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

Side observation: each `drmTMB(se = TRUE)` fit spawned parallel PSOCK workers that outlive the
Rscript (4 orphans after 3 fits; killed). This is the same leak seen at 18:45 with 14 orphans —
worth a look at the sdreport/parallel path someday. Recorded, not chased.
