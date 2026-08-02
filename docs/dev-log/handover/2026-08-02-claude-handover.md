# Claude handover — current-source interval feasibility after Arc 1

Date: 2026-08-02  
From: Codex  
To: Claude  
Repository: `drmTMB`  
Platform/lane: `PLATFORM: codex | LANE: current-source direct-target interval feasibility | FOREIGN LANE: none detected`  
Branch: `codex/q1-interval-contracts-arc1`  
Draft PR: [#896](https://github.com/itchyshin/drmTMB/pull/896)  
Implementation commit: `1b6fd3dbd4597da12ff3e8fe0f7f9322553bd615`  
Base used for all retained evidence: `c8e04258d9d550384b037b1e2a91734c22aaaab5`

## Critical context

Shinichi approved a new interval-feasibility goal: move almost all eligible
point-fit recoveries toward `interval_feasible`, but promote only an exact direct
target whose current-source profile is finite, ordered, two-sided, and unclamped.
Arc 0 reconciled the live source with the previous handover. The immutable source
contains 100 `point_fit_recovery` rows; excluding 18 missing-response rows leaves
82, not the stale 81. The complete denominator, classification, and remaining
ranking are frozen in
`docs/dev-log/interval-feasibility/arc0-candidate-manifest-c8e04258.md` (SHA-256
`c9bf43b167011a2b4f289ff24bd966cc688d29caf93b4f83317bdc60526f2ea2`).

Do not reinterpret a finite interval produced by a clamp as inference evidence.
Do not reuse B4-source receipts. Do not widen this lane into missing-response,
coverage/calibration, public claims, q12 execution, or changes to the R API/TMB
model. Repeated feasibility receipts belong on Totoro; future replicated
coverage/calibration belongs on DRAC and needs a new approval.

## Accomplished

Five exact direct targets moved from `point_fit_recovery` to
`interval_feasible`, supported by three independent Totoro seeds each (15
receipts total):

1. `mc-0260::fixef:mu:x`, Gaussian ML, `n = 240`.
2. `mc-0262::fixef:sigma:x`, Gaussian ML, the same frozen fixture family.
3. `mc-0260m::fixef:mu:(Intercept)`, ML `meta_V`, `K = 48`; heterogeneity SD is
   explicitly excluded and the K=12 tau=.10 `[0, Inf]` STOP is retained.
4. `mc-0266::sd:sigma:(1 | id)`, Gaussian ML residual-scale RE SD,
   `g = 48`, `each = 20`.
5. `mc-0269::sd:mu:(0 + x | id)`, Gaussian REML independent slope SD,
   `g = 64`, `each = 12`.

`mc-0438::sd:mu:phylo_interaction(1 | plant:pollinator)` remains STOP: both
local attempts converged, but both had nonfinite profile endpoints. Hessian
inference is unavailable for those `se = FALSE` fits.

The fail-closed contract records the exact source SHA, estimator, target type,
runner SHA, immutable fixture/hash, retained profile trace/hash, derived
interval/hash, convergence, `pdHess`, boundary and clamp states. Reconciliation
requires byte-identical fresh recomputation and tests mutations of estimator,
runner, target, fixture, endpoint, trace, duplicate seeds, and missing seeds.

## Current state

- Ledger counts: 161 `interval_feasible`, 77 `point_fit_recovery`.
- Draft PR #896 is open; implementation commit `1b6fd3dbd` is pushed.
- No R API, likelihood, formula grammar, or TMB source changed.
- Fisher, Grace, and Rose returned GO. Rose's final recheck found no blocker.
- The working tree should be clean after the handover commit is pulled.
- The five completed targets are DONE. Do not rerun or rescore them.

## Decisions and rationale

- Promotion is target-specific, never cell-wide by implication.
- A single local feasibility fit is diagnostic only; promotion required three
  independent current-source Totoro receipts and independent reconciliation.
- The profile is executed once per fit; the interval is derived from the
  retained trace rather than invoking a second profile operation.
- `mc-0438` is retained as a falsifying result instead of being tuned until it
  passes.
- q12 rows, profile-fenced rows, row-structure/estimator holds, and coverage are
  outside the executable denominator for this arc.

## Files changed

Implementation commit `1b6fd3dbd` contains 119 changed paths. The exact list is
reproducible with `git show --name-only --format= 1b6fd3dbd`. Its complete path
groups are:

- `.github/workflows/R-CMD-check.yaml` — runs the new reconciliation unittest.
- `docs/dev-log/after-task/2026-08-02-arc1-first-interval-feasibility-cohort.md`.
- `docs/dev-log/check-log.md`.
- `docs/dev-log/interval-feasibility/arc0-candidate-manifest-c8e04258.md`.
- Every file under
  `docs/dev-log/interval-feasibility/results/c8e04258d9d550384b037b1e2a91734c22aaaab5/`
  in the five Arc-1 result trees (README, immutable fixtures, receipts, traces,
  intervals, and reconciliation tables).
- Generated capability surfaces: `docs/dev-log/dashboard/capability-census/`,
  `docs/dev-log/dashboard/capability-ledger/`,
  `docs/dev-log/dashboard/capability-surface.html`,
  `docs/dev-log/dashboard/capability-surface.md`, and
  `docs/dev-log/dashboard/parity-triage.tsv`.
- `tools/arc1_profile_reconcile.py`, the four
  `tools/reconcile-arc1-*-profiles.py` cohort reconcilers, and five
  `tools/run-arc1-*-profile-feasibility.R` runners.
- `tools/capability_ledger.py`, `tools/tests/test_capability_ledger.py`, and
  `tools/tests/test_arc1_profile_reconcilers.py`.
- This handover and the latest `AGENTS.md` pointer are the handover commit.

## Landing state

| Item | State |
| --- | --- |
| Implementation | committed and pushed at `1b6fd3dbd` |
| Branch | `codex/q1-interval-contracts-arc1` tracks origin |
| Pull request | draft PR #896 into `main` |
| Arc 1 evidence | DONE; five targets, 15 Totoro receipts |
| `mc-0438` | RETAINED STOP |
| Remaining ranked candidates | CARRIED-OVER in the frozen Arc 0 manifest |
| Coverage/calibration, q12, missing response, public claims | PROTECTED / out of scope |

## Checks and receipts

- `python3 -B tools/capability_ledger.py --check`: 30 generated outputs current.
- `python3 -m unittest tools.tests.test_capability_ledger tools.tests.test_arc1_profile_reconcilers`:
  53 tests passed.
- Focused R profile suite: 861 passed, 0 failed, six existing deprecation
  warnings.
- After-task structure validator: passed.
- `git diff --check`: passed.
- Lane preflight: no Claude lane detected in the prior 12 hours; this is weak
  evidence, so rerun it before claiming the next subject.

Use `R_PROFILE_USER=/dev/null Rscript --no-init-file` for R. The retained Totoro
source checkout is `/home/snakagaw/drmtmb_interval_arc1_c8e04258/repo`. Attach
only through the existing `cm-*totoro*` ControlMaster and do not reuse a mutable
old run directory for new evidence.

## Next immediate steps

1. Read `AGENTS.md`, this handover, the after-task report, and the frozen Arc 0
   manifest. Run lane preflight and classify every continuation item as
   OWED, DONE, RETRACTED, or PROTECTED.
2. Reconcile PR #896 and `origin/main`; do not silently rebase evidence away
   from its declared `c8e04258` source.
3. Start at Rank 2 and choose exactly one direct-target/fixture packet:
   `mc-0186::rho12` with the frozen `biv_reml_fixture(n = 150)`, or
   `mc-0263::fixef:sigma:x` with `reml_hetero_fixture()`. First assert that the
   current profile surface addresses that exact target. Do not bundle both.
4. Reuse the fail-closed Arc-1 receipt/reconciliation contract. Run the local
   fixture only as a diagnostic, then stop for compute approval before new
   repeated Totoro receipts if the exact target remains feasible.
5. Stop immediately on a nonfinite, unordered, one-sided, boundary-hit, clamped,
   source-mismatched, or target-mismatched interval. Preserve the failure.

## Blockers and questions

There is no blocker to reading and ranking the next exact packet. New repeated
compute still needs the normal explicit campaign approval. Whether PR #896
should be merged before the next packet is Shinichi's decision; do not merge it
as part of rehydration.

## Gotchas

- The denominator is 82. “81” was a stale handover count caused by `mc-0578`
  landing before reconciliation.
- `interval_feasible` is not coverage-ready and does not authorize public
  inference claims.
- `pdHess` is a property of the populated fit; do not infer it from a nearby
  status field or from optimizer convergence alone.
- Keep ML and REML receipts separate. A fit under one estimator cannot promote
  the other.
- A finite profile endpoint created by `logsigma_clamp` is false precision.
- The handoff gate reports many unrelated historical branches as unpushed; they
  are not part of this lane. Scope by this branch and PR #896.

## How to resume

```sh
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
git fetch origin
git worktree add /private/tmp/drmtmb-claude-interval-next origin/codex/q1-interval-contracts-arc1
cd /private/tmp/drmtmb-claude-interval-next
/Users/z3437171/shinichi-brain/tools/lane_preflight.sh .
python3 -B tools/capability_ledger.py --check
python3 -m unittest tools.tests.test_capability_ledger tools.tests.test_arc1_profile_reconcilers
```

## Mission-control reconciliation

| Item | Classification |
| --- | --- |
| Five promoted direct targets | DONE |
| `mc-0438` profile attempt | DONE, retained STOP |
| Frozen 82-cell denominator and ranking | DONE |
| Rank-2 exact packet selection | OWED |
| New repeated compute | OWED only after explicit approval |
| q12, profile-fenced rows, missing response, coverage, public claims | PROTECTED |

Paste-ready continuation prompt:

> Read AGENTS.md and docs/dev-log/handover/2026-08-02-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
