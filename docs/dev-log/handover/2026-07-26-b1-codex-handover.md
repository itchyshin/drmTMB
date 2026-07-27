# Session Handoff: B1 DRAC scalar `sd()` breadth execution → Codex

**Meta:** 2026-07-26 · from Codex → Codex · B1 execution campaign complete.

> ## ⚠ Lane boundary
>
> Continue **Lane B — `sd()` scale and intervals**. Do not touch the independent
> Arc 6 / association lane. Do not implement Arc D, change bootstrap methods,
> modify missing-response work, update the capability ledger, or make a
> public/default/NEWS claim from B1.

## Critical context

B1 is a completed **execution census**, not an inference study. It ran 16
predeclared scalar `sd()`/fixed-parameter routes at low, medium, and high
information rungs: 200 replicates per cell/rung, 9,600 attempts in 960
single-CPU Fir tasks. It has no truth, bias, interval, coverage, comparator,
or Monte Carlo-uncertainty quantity. Its only conclusion is that the frozen
execution map ran and retained the evidence.

The broader Lane-B roadmap remains unchanged: Arc D is blocked on Shinichi's
written contract choice, while diagnosing the marginal-bootstrap coverage
shortfall is a separate unstarted question. B1 does not authorize either.

## What was accomplished

- Added the immutable B1 contract, deterministic manifest/seed map, fixture
  adapters, task runner, Fir dispatch, strict aggregator, Slurm templates, and
  canonical evidence/replay validator.
- Local smoke retained a completed low-rung fit for all 16 routes.
- Final Fir preflight passed with R 4.4.0, TMB 1.9.21, final source
  `061c2891cdc617113334d128425228f4b4145753`, and installed DLL SHA
  `fe8af02215b4f96491dbe0b0675659f778e48fdf84635502782ae09e8d4abc03`.
- Fir array `51292149` completed all 960 tasks: 9,600 retained attempts =
  9,599 `fit_completed` + one genuine Beta response-boundary `fit_error`.
- The task-41 original serialization error was preserved. Only that copied-root
  replay was permitted after the worker normalized multiline fit errors.
- Independent inference review withholds every recovery/inference claim. The
  systems review prompted canonical-map, receipt, replay, and source-lineage
  checks; the final post-hoc gate passed.

Read the complete evidence record before interpreting any B1 field:

- `docs/dev-log/2026-07-26-b1-drac-breadth-campaign-report.md`
- `docs/dev-log/after-task/2026-07-26-b1-drac-breadth-validation.md`

## Current working state

- **Working:** B1 implementation, tests, report, after-task reconciliation, and
  process note are committed locally on `codex/b1-drac-breadth`.
- **Complete:** the user-approved B1 execution-only goal.
- **Next task:** the user asked for a fresh planning lane. Use `arc-creation`,
  then `ultra-plan`, to propose the next Lane-B arc. Research and plan only;
  stop for explicit approval before any implementation or compute.
- **Remote evidence:** Fir root
  `/project/def-snakagaw/snakagaw/drmTMB-b1-breadth-399cba13/`. The final Fir
  source is banked locally as `/private/tmp/b1-fir-061c2891.bundle` (SHA-256
  `96cf716801512b2cb24493e741fa32b137862e6a555b11e69e6badf306ae89ff`).

## Key decisions and rationale

- The one Beta boundary failure stays in the all-attempt denominator; do not
  silently discard or retry it away.
- Finite estimates, profiles, convergence, and `pdHess` are diagnostics only,
  never coverage or capability verdicts.
- The final post-hoc gate binds this campaign to its canonical manifest and
  source/receipt/replay provenance. It records a remaining improvement: future
  workers should perform full DLL/R-library receipt verification at task start.
- The root checkout is foreign/dirty under the prior Lane-B handover. Work only
  in a clean, isolated worktree and stage explicit paths.

## Landing state

The shared `handoff_gate.sh` reports this branch as **CARRIED-OVER**: it is 14
commits ahead of `origin/main`; the gate also reports separate unpushed branches
that are not B1 and must not be touched. This handover is committed locally but
not pushed. A fresh Codex task should therefore use this local branch explicitly.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/b1-drac-breadth` through `d90530f8` | yes | no | none | CARRIED-OVER — local branch only |
| This handover + `AGENTS.md` pointer | pending handover commit | no | none | CARRIED-OVER — commit with B1 branch |

## Files created or modified

`tools/b1-breadth-contract.R`; `tools/b1-breadth-adapters.R`;
`tools/run-b1-breadth-validation.R`; `tools/prepare-b1-drac-dispatch.R`;
`tools/summarize-b1-breadth-validation.R`;
`tools/validate-b1-breadth-evidence.R`;
`tools/slurm/b1-breadth-validation.sbatch`;
`tools/slurm/install-b1-ape.sbatch`;
`tests/testthat/test-b1-breadth-contract.R`;
`tests/testthat/test-b1-breadth-adapters.R`;
`tests/testthat/test-b1-breadth-dispatch.R`;
`docs/dev-log/2026-07-26-b1-drac-breadth-campaign-report.md`;
`docs/dev-log/after-task/2026-07-26-b1-drac-breadth-validation.md`;
`docs/dev-log/check-log.md`; `docs/dev-log/team-improvements.md`; `AGENTS.md`;
and this handover file.

## Next immediate steps

1. Run `tools/lane_preflight.sh`, inspect status/history/open PRs/origin main,
   and classify the handover as `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`.
2. Read the two B1 reports. Preserve the execution-only boundary.
3. Read the `arc-creation` and `ultra-plan` skills; orient on the Lane-B
   evidence and create a scoped next-arc plan. Do not execute Phase 3 or launch
   compute before Shinichi approves the plan.
4. Before a later status/inference claim, use Rose's independent audit and the
   applicable review gate.

## Gotchas and failed approaches

- Preflight-only jobs cannot require a task manifest.
- Recursive source-content hashing was too slow on project storage; retain the
  Git tree/source receipt and tracked-index checksum instead.
- B1 needed an isolated R-4.4 `ape` 5.8.1 library; do not mutate the shared
  read-only dependency base.
- Multiline fit errors corrupt line-based TSV aggregation. The runner now
  normalizes error whitespace before atomic publication.

## Codex live-toolchain recipe

```sh
cd "/private/tmp/drmtmb-b1-drac-breadth"
export R_PROFILE_USER=/dev/null NOT_CRAN=true
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
Rscript --no-init-file -e 'testthat::test_file("tests/testthat/test-b1-breadth-contract.R"); testthat::test_file("tests/testthat/test-b1-breadth-adapters.R"); testthat::test_file("tests/testthat/test-b1-breadth-dispatch.R")'
```

Codex owns future live R/TMB fits, checks, rendering, and separately approved
Totoro/DRAC computation. Rose's `.codex/agents/` audit is mandatory before any
completion or public status claim.

## How to resume

Paste into a fresh Codex task:

```text
Rehydrate from docs/dev-log/handover/2026-07-26-b1-codex-handover.md and the
AGENTS.md Active Lane Split. You are Lane B (sd()/scale/intervals), not
association. First create the next arc using arc-creation then ultra-plan;
research and plan only, and stop for my explicit approval before execution.
```

## Mission control

| Lane / item | Branch / state | Next leverage step |
| --- | --- | --- |
| B1 execution census | `codex/b1-drac-breadth`, local-only | preserve evidence-only boundary |
| Next Lane-B arc | unplanned | `arc-creation` then `ultra-plan`, approval gate |
| Arc D contract | #851, plan-only | await written choice |
| Association (Lane A) | independent | protected; do not touch |
