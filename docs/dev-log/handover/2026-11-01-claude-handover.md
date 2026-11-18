# General random-effect SD regression: handover to Claude

Date: 2026-11-01

## Mission

Continue the approved general predictor-dependent random-effect SD regression programme in `drmTMB`, across the supported family, endpoint, random-effect, provider, layout, and engine combinations. The priority sequence starts with the five common families (Gaussian, Binomial/Bernoulli, Poisson, NB2, and Gamma), but those are not the whole finish line. Coverage calibration was explicitly deferred; implementation and uncertainty workflows remain in scope, but do not describe intervals as calibrated.

The owner clarified that this lane owns the SD implementation across native R/TMB and Julia. Coordinate around shared files and preserve unrelated work from the documentation/audit lane and other active lanes. No email is part of this task.

## Current milestone and evidence

- G2, the bounded Bernoulli both-engine milestone, is marked complete in `.unlazy/general-sd-regression/GATES.md`. Its evidence covers ordinary intercepts, independent slopes, and selected unlabelled correlated q2 routes. It does not establish the full Bernoulli universe or broad parity.
- The current candidate includes additional narrow Bernoulli evidence for selected links, structured providers, and bridge outputs. Each receipt is route-specific; inspect its source hashes and limitations before reusing it.
- The required-row ledger has 20,350 rows. The latest recorded reconciliation has 214 evidence-linked rows, 20,136 without linked evidence, and 241 evidence records. Linked means a receipt is attached, not that the row has passed independent review or is generally supported. These counts are not a completion percentage.
- G0, G1, G3, G4, G6, G7, and G8 remain open. G5 interval-coverage calibration is deferred by decision and must remain tracked as follow-up work.
- The handoff-gate snapshot listed 12 unmet slice ledgers under `.unlazy/general-sd-regression/gates/`; their paths are listed below. Re-read each ledger because the dirty checkout may have changed since that snapshot.
- A recent source audit identified a possible next implementation gap: native Gamma correlated q2 assembly appears blocked before its existing model-type-5 machinery can be used, while the Julia Gamma SD route accepts a single independent intercept or slope and refuses correlated blocks. Treat this as a lead, not a verified bug. Reproduce the boundary with exact-source tests before editing.

## Exact checkout state

- Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
- Worktree: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression`
- Branch: `codex/general-sd-regression`
- HEAD at handover: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- The handoff-gate snapshot reported 6 commits ahead and 559 behind `origin/main`, plus 1,242 uncommitted status entries. The checkout also contains a large untracked `docs/dev-log/design` tree (reported as 27,075 files). Recheck current state before acting.
- Path/status snapshot: [`2026-11-01-general-sd-path-inventory.txt`](2026-11-01-general-sd-path-inventory.txt). It records paths, not file contents.
- The handover gate also reported 1,043 unpushed commits on other branches and 31 active lanes. These are protected and outside this handoff.
- `docs/dev-log/active-lane-split.md` and `AGENTS.md` have substantial concurrent edits absent from this checkout. Do not edit either or replace the shared lane board based on this note.

## Landing state

| Item | State | Required treatment |
|---|---|---|
| Existing implementation and evidence | CARRIED-OVER | Preserve the dirty checkout. Do not reset, clean, or stage broad paths. |
| Six commits on this branch | CARRIED-OVER, not pushed | Do not push or merge without a separate explicit instruction. |
| 1,242 uncommitted entries and untracked design material | CARRIED-OVER | Reconcile ownership path by path before editing or staging. |
| Other branches and active lanes | PROTECTED | Do not alter their branches, files, leases, or work. Coordinate before shared-file edits. |
| 12 unmet slice ledgers | CARRIED-OVER / UNMET | Reconcile against fresh source and evidence; do not mark complete from this handover. |
| Interval coverage calibration | DEFERRED | Keep visible as follow-up. No calibrated-interval claims. |

## Immediate resume steps

1. Read repository `AGENTS.md`, `CLAUDE.md`, and `docs/dev-log/active-lane-split.md`; then inspect this handover and the path inventory.
2. Rehydrate the checkout before making changes:

   ```sh
   cd '/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression'
   git status --short --branch
   git rev-parse HEAD
   bash ~/shinichi-brain/tools/lane_preflight.sh "$PWD"
   ```

3. Reconcile `OWED`, `DONE`, `RETRACTED`, and `PROTECTED` against the live status, goal, `.unlazy/general-sd-regression/GATES.md`, and evidence receipts. The notes in this handover are leads; exact current source and receipts control.
4. Before editing, run path-specific `lane_preflight.sh --file PATH` for every target. The shared lease registry has been intermittently busy; verify any lease with `lane_lease.sh --list general-sd-regression`. Do not treat a preflight as a lease or infer that another lane is inactive from silence.
5. Select one bounded unresolved required-row slice. For the Gamma q2 lead, first prove the R formula/builder refusal and Julia restriction on this exact checkout, then map the native and Julia likelihood/data structures, write a failing focused test, and coordinate before touching shared model assembly. Keep tests and user documentation with any implementation.
6. Codex owns live R/TMB/Julia toolchain checks under repository policy. Arrange exact-source focused checks after implementation. Do not claim completion, full parity, or calibrated uncertainty from a narrow passing fixture.

## Unmet slice ledgers recorded by the handoff gate

Recheck status before changing these files:

- `.unlazy/general-sd-regression/gates/binomial-selectors.md`
- `.unlazy/general-sd-regression/gates/julia-bernoulli-q2-bridge-dpars.md`
- `.unlazy/general-sd-regression/gates/lognormal-intercept.md`
- `.unlazy/general-sd-regression/gates/lognormal-slope-sd.md`
- `.unlazy/general-sd-regression/gates/native-binomial.md`
- `.unlazy/general-sd-regression/gates/native-student-slope-sd.md`
- `.unlazy/general-sd-regression/gates/ordinary-targets.md`
- `.unlazy/general-sd-regression/gates/poisson-label.md`
- `.unlazy/general-sd-regression/gates/poisson-ordinary.md`
- `.unlazy/general-sd-regression/gates/poisson-slope.md`
- `.unlazy/general-sd-regression/gates/student-slope-julia-bridge.md`
- `.unlazy/general-sd-regression/gates/tweedie-julia-ordinary-sd.md`

## Finding of record

FINDINGS-OF-RECORD: none. The Gamma correlated q2 observation above is an unverified source-audit lead, not a closed finding.

## Paste-ready Claude prompt

Read `AGENTS.md`, `CLAUDE.md`, and `docs/dev-log/active-lane-split.md`, then read `docs/dev-log/handover/2026-11-01-claude-handover.md` and its path inventory. Rehydrate the current worktree and ownership using the listed commands. Preserve all dirty and foreign work. Reconcile the live goal and acceptance ledgers, then continue one bounded unresolved SD-regression slice with tests and documentation. Do not push, merge, edit shared lane pointers, or claim full parity or calibrated uncertainty from narrow evidence.
