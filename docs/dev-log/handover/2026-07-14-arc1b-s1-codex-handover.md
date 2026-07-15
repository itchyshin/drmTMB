# Session Handoff: Arc 1b-S1 PR #783 merge boundary

Meta: 2026-07-14 · from Codex to a new Codex session · PR #783

Read `AGENTS.md` first, then this file and the linked after-task report. The
repository, GitHub, and live Mission Control are technical truth; re-read all
three before acting because this handoff itself is a docs-only successor commit.

## Critical Context

Arc 1b-S1 is complete and evidence-backed. PR #783 is open, non-draft,
mergeable, and unmerged. Verified implementation/evidence ancestor
`38c57f6c0c054ccf7a323bff312a4c0ae56d5af3` passed current-head GitHub run
[29392088529](https://github.com/itchyshin/drmTMB/actions/runs/29392088529):
`os-matrix` and `ubuntu-latest (release)` are green. This handoff and the
refreshed `AGENTS.md` banner form a docs-only successor, so resolve the live PR
head dynamically, verify that it contains `38c57f6c`, and wait for the
docs-only run if pending.

Do **not** merge PR #783 without a separate explicit instruction from Shinichi
such as `merge PR #783`. Do not start another arc, including the banked `sd()`
candidate, before that merge decision and a fresh approved GOAL/ultra-plan.

## Exact Admitted Cell

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + spatial(1 | p | site, coords = coords),
    mu2 = y2 ~ x2 + spatial(1 | p | site, coords = coords),
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  ),
  family = biv_gaussian(),
  data = data,
  REML = TRUE
)
```

This exact native-TMB route requires complete response pairs, unit weights, no
known `meta_V()` covariance, and no additional ordinary random effect,
direct-SD formula, or `corpair()` regression. Its maturity ceiling is
`point_fit_recovery`.

## What Was Accomplished

- Added one fail-closed R admission predicate; no C++ likelihood rewrite was
  necessary because the existing Gaussian covariance engine was already exact.
- Matched an independent dense response-major restricted-likelihood oracle at
  the optimum and two displaced parameter vectors. A deliberately wrong
  correlation-layer oracle did not match.
- Added a 41-expectation direct admission/oracle/boundary matrix covering the
  full deferred-neighbour set.
- Ran a predeclared Totoro campaign with 1,200/1,200 retained attempts: 1,200
  fits, 1,200 convergence-code-zero fits, 1,198 `pdHess`, and 9
  target-boundary attempts. All high-information recovery gates passed.
- Migrated `mc-0199` and `mc-0672` to verified `point_fit_recovery`; added
  `mc-0673` for the rejected remainder. The ledger now has 673 model rows:
  303 implemented, 330 rejected, and 40 not implemented.
- Synchronized source docs, generated surfaces, pkgdown, and live Mission
  Control. Fisher, Noether, and Rose returned PASS.

Authoritative detail:

- `docs/dev-log/after-task/2026-07-14-arc1b-s1-spatial-q2-reml.md`
- `docs/dev-log/2026-07-14-arc1b-s1-recovery-design.md`
- `docs/dev-log/simulation-artifacts/2026-07-14-arc1b-spatial-q2-reml-recovery/README.md`

## Verification

- Focused direct admission/oracle test: 41/41 expectations passed.
- Focused recovery-runner contract: 10/10 expectations passed.
- Full source `devtools::test()`: 0 failures, 62 known warnings, 24 expected
  optional-Julia skips.
- Genuine `--as-cran`: 0 errors, 0 warnings, 0 normalized notes; raw known
  long-test NOTE only.
- `devtools::document()`, `pkgdown::check_pkgdown()`, and full pkgdown build:
  passed.
- Capability ledger: all 30 generated outputs current; 35 tests passed; all 18
  runtime routes passed.
- Repository Mission Control validation and live port-8823 readback: passed.
- GitHub run 29392088529: green for verified ancestor `38c57f6c`.

## Claim Boundary

This arc does **not** cover spatial slopes, estimated range, mesh/SPDE,
animal/`relmat()` bivariate REML, scale-only q2, q2-plus-q2, q4+, incomplete
pairs, non-unit weights, known `meta_V()`, additional random/direct-SD/
`corpair()` layers, random `rho12`, non-Gaussian REML, AI-REML, bridge parity,
intervals, coverage, `inference_ready_with_caveats`, `supported`, or the
distribution-wide `sd()` proposal.

## Current Working State

- **Working:** branch `codex/arc1b-s1-spatial-q2-reml` is clean and pushed.
- **Working:** PR #783 is open and unmerged; verified ancestor `38c57f6c` is
  green and `mergeStateStatus=CLEAN` before the docs-only handoff push.
- **Working:** PR #781 remains unrelated, parked, and untouched.
- **In progress:** only the docs-only handoff-head CI readback.
- **Blocked by policy:** merge requires separate explicit authorization.
- **Not started:** any next arc, including the banked `sd()` arc.

## Landing State

The landing gate confirms the active branch is committed and pushed but exits
nonzero because 358 unrelated pre-existing local branches contain commits
absent from all remote refs. Those branches are protected user state and are
explicitly carried over; do not modify, stage, push, delete, merge, or rewrite
them.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | ---: | ---: | --- | --- |
| `codex/arc1b-s1-spatial-q2-reml`; verified ancestor `38c57f6c` plus docs-only handoff successor | yes | yes after handoff push | #783 open | LANDED on remote; verify current head/CI, then wait for merge authorization |
| PR #781 | n/a | n/a | open | CARRIED-OVER unrelated; do not absorb |
| Banked `sd()` proposal | n/a | n/a | none | CARRIED-OVER design candidate; fresh GOAL required |
| 358 unrelated local branches | mixed | mixed | mixed | CARRIED-OVER protected user state |

Reproduce the gate:

```sh
/Users/z3437171/Dropbox/Github\ Local/Shinichi/tools/handoff_gate.sh \
  /Users/z3437171/.codex/worktrees/3d16/drmTMB
```

## Resume Commands

```sh
cd /Users/z3437171/.codex/worktrees/3d16/drmTMB
git status --short --branch
git fetch origin
git rev-parse HEAD
git rev-parse origin/codex/arc1b-s1-spatial-q2-reml
git merge-base --is-ancestor 38c57f6c origin/codex/arc1b-s1-spatial-q2-reml
gh pr view 783 --json state,mergedAt,isDraft,mergeable,mergeStateStatus,headRefOid,statusCheckRollup,url
gh pr checks 783
R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py
curl -fsS http://127.0.0.1:8823/api/projects/drmTMB
```

Expected result: local and remote branch heads agree; PR #783 remains open and
unmerged; the live head contains `38c57f6c`; every current-head check is green;
Mission Control names PR #783 and the explicit merge-authorization boundary.

## Copy-Paste Continuation Prompt

```text
Rehydrate drmTMB from AGENTS.md and
docs/dev-log/handover/2026-07-14-arc1b-s1-codex-handover.md on branch
codex/arc1b-s1-spatial-q2-reml.

Verify local HEAD equals the remote branch, PR #783 remains open and unmerged,
the live head contains verified ancestor 38c57f6c, current-head GitHub CI is
green, and Mission Control at http://127.0.0.1:8823/ agrees. Wait if the
docs-only handoff run is pending.

PR #783 is evidence-backed and recommended to merge, but do not merge without
my separate explicit authorization. Do not start the next arc or the banked
sd() proposal. Report verified status and wait for direction.
```
