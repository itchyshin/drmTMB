# Session Handoff: meta_V B3 retained-evidence closeout

Meta: 2026-07-23 · from Codex · target Codex

## Goals / Mission

Maintain honest, evidence-bounded `drmTMB` capability surfaces. This lane ran
the approved B3 Gaussian known-`V` campaign to establish whether the existing
`meta_V(V = V)` interval channel could support a stronger inference claim. It
does not authorize CRAN work or capability promotion.

## Mission Control

| Repository | Branch / state | What shipped | Evidence boundary | Next leverage |
| --- | --- | --- | --- | --- |
| drmTMB | `codex/meta-v-b3-contract`, pushed | scoped B3 approval/provenance contract and retained campaign evidence | Gaussian ML, known vector/dense `V`, constant `sigma`; no tier promotion | keep `meta_V()` tier-unregistered; choose a new separately approved arc only after reading the evidence |

## Critical Context

The campaign is technically complete and fully retained, but its conclusion is
**NOT-DONE for promotion**. The primary rate is finite-and-truth-covering over
all scheduled attempts. For `sigma`, 3,712 of 16,800 rows are retained
`degenerate_zero_infinite`; conditional coverage among finite intervals cannot
replace the primary denominator. Fisher and Rose both withhold any coverage,
inference, capability, or public claim.

CRAN is **PARKED, not failed**. Do not re-freeze, run a platform matrix, edit
`cran-comments.md`, or submit. Do not force-push the three divergent historical
branches named in `AGENTS.md`.

## What Was Accomplished

- Bound smoke and campaign approvals, exact source hashes (including both
  execution entrypoints), host selection, and all 96 shard receipts into the
  B3 contract.
- Retained the initial smoke and campaign preflight failures rather than
  overwriting them. Neither reached a fit; they are excluded from the campaign
  denominator.
- Ran and reviewed a repaired Totoro smoke. K=12/vector seed 4 retained
  `sigma` `[0, Inf]`; K=36/dense retained finite positive intervals.
- Ran 96 Totoro shards at one R worker and `OPENBLAS_NUM_THREADS=1`. Reduction
  authenticated 16,800 scheduled attempts and 50,400 parameter rows: all fits
  `ok`, zero convergence/Hessian/fit errors, 3,712 retained degenerate sigma
  intervals, and 46,688 finite intervals.

## Current Working State

- **Working:** all B3 source/receipt/host/provenance gates; compact artifacts
  are versioned and full raw evidence is local.
- **Complete:** campaign execution, reduction, Fisher/Rose retained-evidence
  review, and after-task report.
- **Withheld:** all interval, coverage, inference, capability-tier, release,
  CRAN, Julia, REML, non-Gaussian, and predictor-dependent `sigma` claims.
- **In progress:** the uncapped local full-suite census was launched with the
  prescribed `testthat::test_local()` command. Confirm its final printed
  failure/error count before treating this handover as fully closed if it has
  not completed by session turnover.

## Key Decisions & Rationale

- Use Totoro only after the retained smoke chose it: one-minute load was 0.03
  and projected shard time 259.2187 seconds, below the six-hour policy limit.
- Keep the raw 203 MB campaign and full 31 MB reduction in the ignored local
  store `inst/sim/results/meta-v-b3-2026-07-23/`; version only compact receipts,
  coverage tables, and after-task documentation.
- The campaign’s all-attempt primary `sigma` rate is 0.4117–0.8900 across cells;
  it therefore cannot justify reportable sigma intervals across the grid.

## Files Created / Modified

Core contract and runner files:

- `inst/sim/run/sim_meta_v_b3_contract.R`
- `tools/run-meta-v-b3-smoke.R`
- `tools/run-meta-v-b3-shard.R`
- `tests/testthat/test-phase18-meta-v-grid-writer.R`

Durable B3 records:

- `docs/dev-log/2026-07-22-meta-v-b3-decision-packet.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-22-meta-v-b3-contract-hardening.md`
- `docs/dev-log/after-task/2026-07-23-meta-v-b3-campaign.md`
- `docs/dev-log/simulation-artifacts/2026-07-22-meta-v-b3-smoke/`

The prior branch diff also contains the existing B3 design/DGP/comparator and
reader-surface files. See `git diff --name-only origin/main...HEAD` before
altering or staging anything.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/meta-v-b3-contract` | yes (closeout commit pending this handover) | yes before final closeout commit | none | CARRIED-OVER until the final docs commit and push |
| `inst/sim/results/meta-v-b3-2026-07-23/` | ignored by design | local only | none | LANDED local retained evidence; never stage raw results |

## Plans / Roadmap

`docs/design/48-phase-18-meta-v-ademp.md` remains the controlling ADEMP. Any
future meta-analysis work must be a new decision: this B3 result closes the
constant-`sigma` Wald interval channel as promotion evidence, rather than
opening a broader capability surface.

## Next Immediate Steps

1. Confirm the full local test census result, using exactly:
   `NOT_CRAN=true R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'd <- as.data.frame(testthat::test_local(".", reporter = "silent")); sum(d$failed); sum(d$error)'`.
2. Run `tools/handoff_gate.sh .`, commit/push the final closeout docs and this
   handover with explicit paths, and confirm a clean branch.
3. Do not start a new compute, promotion, or CRAN lane without Shinichi’s new
   goal. If a new `meta_V` arc is requested, begin with a fresh ultra-plan and
   default to NOT-DONE.

## Blockers / Open Questions

There is no execution blocker. The only substantive decision is what to do
with the negative B3 inference result; the safe default is no change to public
status. A new method/interval design would need a distinct approved scope.

## Gotchas / Failed Approaches

- The first smoke failed pre-fit because `requireNamespace()` does not attach
  the `drmTMB()` function needed by sourced runners. Both entrypoints now attach
  it and are source-hashed.
- The first formal launch failed pre-fit because a local campaign receipt
  referenced a local artifact path on Totoro. Retain the 96 logs and make the
  host-local receipt from the transferred authenticated smoke bundle.
- Do not use `devtools::test()` as a failure census: testthat caps displayed
  failures. Use `test_local()` and sum both failure and error columns.

## How to Resume

From the repository root, start Codex and paste:

> Rehydrate from `docs/dev-log/handover/2026-07-23-codex-handover.md` plus the
> `AGENTS.md` Latest block, confirm the full test census and landing state, then
> follow Next Immediate Steps without promoting meta_V.

For R commands use `NOT_CRAN=true`, `R_PROFILE_USER=/dev/null`, and
`Rscript --no-init-file`. Codex should run any future live R/TMB validation;
Rose remains mandatory before a public claim.
