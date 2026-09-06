# The R-hub `rchk` red is inherited, not ours (2026-09-06)

**Short version: stop re-running it expecting green.** For a TMB-based package the
`rchk` container will show red, and it is not a drmTMB defect. Run
`tools/rchk-triage.sh <run-id>` to decide it in seconds rather than reading an
hour-long log.

## What was actually measured

Six consecutive R-hub runs were red (2026-08-09 through 2026-09-05, on `main`
and on three different branches). Taking the most recent, run `33986925008`:

| container | result |
|---|---|
| clang-asan | **pass** |
| gcc-asan | **pass** |
| clang-ubsan | **pass** |
| rchk | fail |

So the sanitizers — the checks that actually exercise drmTMB's own compiled code
— are green. Only the static analyzer fails.

Partitioning that run's rchk output by *who owns the file*:

- **12 findings, all in `TMB/include/tmb_core.hpp`** (lines 1251, 1253, 1525,
  2287): `[PB] has possible protection stack imbalance`, `[PB] has negative
  depth`, `[UP] attempt to unprotect more items (4) than protected (3)`. That is
  the **TMB dependency's** header. Every TMB-based package inherits them.
- **0 findings in `src/` or `inst/include/`** — nothing in code this package owns.
- **5 `ERROR: too many states (abstraction error?)`** lines. These are not bug
  reports: they are rchk's analyzer giving up on a function too complex to model.
  Three were in **R's own base C** (`strptime_internal`, `bcEval_loop`,
  `RunGenCollect`); two were TMB's `objective_function<double>::operator()()`
  template expansion.

## The rule this gives us

The useful question is never *"is rchk red?"* — for this package it will be. It is
***"does rchk name a file we own?"*** `tools/rchk-triage.sh` answers exactly that
and exits 1 only when a finding lands in `src/` or `inst/include/`.

The script ships a **red control**: `tools/rchk-triage.sh --self-test` injects one
synthetic finding at `src/drmTMB.cpp:99` and requires the verdict to flip to REAL
(exit 1). A triage tool that can only ever say "fine" would be worthless, so that
control is the thing that makes its green meaningful.

## What this does NOT say

- It does not say TMB has a bug. `[PB]`/`[UP]` are *possible* imbalances from a
  conservative static analyzer; TMB is on CRAN and its sanitizers pass here.
- It does not say drmTMB is free of protection bugs — only that **rchk found none
  in our files**, and that rchk could not analyze the TMB template at all
  (capacity error), so that path is UNCHECKED by this tool rather than proven
  clean. The sanitizer containers are what cover it dynamically.
- It is not a CRAN verdict. CRAN does not gate on rchk.
