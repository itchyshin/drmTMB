# Session Handoff: Arc 1b-S1 PR #783 merge boundary

Meta: 2026-07-15 05:16 MDT · from Codex to a new Codex session · target Codex
· context percentage not exposed by the Codex app · PR #783

You are Codex, picking up `drmTMB` after Arc 1b-S1 closeout. Read
`AGENTS.md` first, then this file and the linked after-task report. The
repository, GitHub, and live Mission Control are technical truth. This handoff
is a docs-only successor to a verified green head, so resolve the PR head and
its checks live before reporting status.

## Goals / Mission

`drmTMB` provides fast univariate and bivariate distributional regression with
Template Model Builder. Arc 1b-S1 had one bounded goal: replace the blanket
bivariate-spatial REML rejection with one native-TMB, oracle-backed admission
for the exact bivariate-Gaussian fixed-covariance spatial q2 location-intercept
cell below, and stop at `point_fit_recovery`.

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

That goal is complete. The next session must protect the evidence boundary and
stop at the merge decision. It must not infer authorization to merge PR #783,
absorb unrelated PR #781, select the next arc, or start the banked `sd()`
proposal.

## Plans / Roadmap

The approved Arc 1b-S1 ultra-plan is complete through implementation, local and
Totoro verification, surfaces, independent review, PR creation, and exact-head
CI. The remaining plan is deliberately sequential:

1. Reverify the live branch, PR, CI, and Mission Control state.
2. Wait for Shinichi to say explicitly `merge PR #783` or equivalent.
3. Only after that authorization, merge PR #783, synchronize updated `main`,
   and re-run the final-base checks appropriate to the merge.
4. Compare the remaining main-lane candidates from updated `main`, including
   the banked family-specific `sd()` proposal. Present a new copy-paste GOAL
   and ultra-plan, then wait for approval before implementation.

The `sd()` proposal is a candidate, not the chosen next arc. Its first possible
gate is Beta phylogenetic location-scale-scale, but that route presently
combines separate missing capabilities and requires family-specific scale
contracts. Do not implement it from this handoff.

## Mission Control

| Repo | Branch / main | CI | What shipped | Plan by leverage |
| --- | --- | --- | --- | --- |
| `drmTMB` | `codex/arc1b-s1-spatial-q2-reml` at pre-handoff head `0630d9b3`; `origin/main=29a4458a`; PR #783 open | run `29394850631` green at `0630d9b3`; this docs-only successor must be checked live | one exact bivariate-Gaussian spatial q2 location-intercept REML cell at `point_fit_recovery`; verified implementation/evidence ancestor `38c57f6c` | explicit merge decision first; then sync `main`; then a fresh GOAL/ultra-plan for the next selected arc |

Live Mission Control at `http://127.0.0.1:8823/` and its
`/p/drmTMB/status.json` route agree that PR #783 is open, mergeable, unmerged,
and gated only on separate authorization. The local-only brain-vault status
has committed authoring ancestor `55115c0`; a final-head status successor may
follow this docs push, so resolve the vault head live. Unrelated dirty files
`memory/LESSONS.md` and `skills/ultra-plan/SKILL.md` belong to the user and were
not staged.

## Critical Context

- Verified implementation/evidence ancestor:
  `38c57f6c0c054ccf7a323bff312a4c0ae56d5af3`.
- Pre-handoff branch head:
  `0630d9b3c57540cabe69b6ca1b2885eae1980b8f`.
- PR: [#783](https://github.com/itchyshin/drmTMB/pull/783), open,
  non-draft, mergeable, `mergeStateStatus=CLEAN`, and unmerged at authoring.
- Exact-head CI: [run 29394850631](https://github.com/itchyshin/drmTMB/actions/runs/29394850631)
  passed `os-matrix` in 3 seconds and `ubuntu-latest (release)` in 25 minutes
  58 seconds at `0630d9b3`.
- This handoff and the refreshed `AGENTS.md` pointer are another docs-only
  successor. Fetch the live head, prove it contains `38c57f6c`, and wait if its
  CI is pending.
- PR #781 is unrelated and remains parked. Do not combine it with PR #783.

Do **not** merge PR #783 without a separate explicit instruction from Shinichi.
Do not start another arc before the merge decision and a fresh approved GOAL.

## What Was Accomplished

- Added one fail-closed R admission predicate. No C++ likelihood rewrite was
  needed because the existing Gaussian covariance engine already represented
  the admitted model.
- Matched an independent dense response-major restricted-likelihood oracle at
  the optimum and two displaced parameter vectors to about `3e-13`. A
  deliberately wrong correlation-layer oracle did not match.
- Added a 41-expectation admission/oracle/boundary matrix and a 10-expectation
  recovery-runner contract.
- Ran a predeclared Totoro campaign with 1,200 retained attempts: 1,200 fit
  objects, 1,200 convergence-code-zero fits, 1,198 `pdHess`, and 9
  target-boundary attempts. All high-information recovery gates passed.
- Promoted only `mc-0199` and `mc-0672` to verified
  `point_fit_recovery`; `mc-0673` records the rejected remainder. The ledger
  has 673 rows: 303 implemented, 330 rejected, and 40 not implemented.
- Synchronized source documentation, generated capability surfaces, pkgdown,
  the check log, after-task record, and live Mission Control.
- Fisher, Noether, and Rose returned final PASS verdicts.

Authoritative detail:

- `docs/dev-log/after-task/2026-07-14-arc1b-s1-spatial-q2-reml.md`
- `docs/dev-log/2026-07-14-next-arc1b-spatial-q2-reml-ultra-plan.md`
- `docs/dev-log/2026-07-14-arc1b-s1-symbolic-alignment.md`
- `docs/dev-log/2026-07-14-arc1b-s1-recovery-design.md`
- `docs/dev-log/simulation-artifacts/2026-07-14-arc1b-spatial-q2-reml-recovery/README.md`

## Current Working State

- **Working:** local and remote branch heads matched at `0630d9b3` before this
  handoff edit; the worktree was clean.
- **Working:** PR #783 was open, non-draft, mergeable, clean, unmerged, and
  green at exact head `0630d9b3`.
- **Working:** repository Mission Control validation and live port-8823
  readback passed.
- **In progress after this document is pushed:** only the docs-only successor
  CI readback.
- **Blocked by policy:** merging PR #783 requires separate explicit
  authorization.
- **Not running:** no local, Totoro, or DRAC process/job remains. The 1,200-fit
  Totoro campaign is complete; there is no partial simulation to resume.
- **Timings:** retained attempt-level elapsed values are in `raw-attempts.tsv`.
  Aggregate Totoro wall time was not recorded, so do not invent it. Exact-head
  GitHub CI took 3 seconds for `os-matrix` and 25 minutes 58 seconds for
  `ubuntu-latest (release)`.
- **Fitted objects:** no untracked fitted-object checkpoint is load-bearing.
  The retained raw attempt table, summary, design, session information, and
  hashes are committed under the simulation-artifact directory.
- **Not started:** any next arc, including the banked `sd()` proposal.

## Verification State

- Focused direct admission/oracle test: 41/41 expectations passed.
- Focused recovery-runner contract: 10/10 expectations passed.
- Full source `devtools::test()`: 0 failures, 62 known warnings, 24 expected
  optional-Julia skips.
- Genuine `--as-cran`: 0 errors, 0 warnings, 0 normalized notes; only the raw
  known long-installed-test NOTE appeared.
- `devtools::document()`, `pkgdown::check_pkgdown()`, and full pkgdown build:
  passed.
- Capability ledger: all 30 generated outputs current; 35 tests and all 18
  runtime routes passed.
- Repository Mission Control validator and live readback: passed.
- GitHub run `29394850631`: both checks passed at `0630d9b3`.

## Claim Boundary

The exact route requires matching labelled
`spatial(1 | p | site, coords = coords)` intercepts in `mu1` and `mu2`,
intercept-only `sigma1`, `sigma2`, and `rho12`, complete response pairs, unit
weights, no known `meta_V()` covariance, and no additional ordinary random,
direct-SD, or `corpair()` layer.

This arc does **not** cover spatial slopes, estimated range, mesh/SPDE,
animal/`relmat()` bivariate REML, scale-only q2, q2-plus-q2, q4+, incomplete
pairs, non-unit weights, known `meta_V()`, extra random/direct-SD/`corpair()`
layers, random `rho12`, non-Gaussian REML, AI-REML, bridge parity, intervals,
coverage, `inference_ready_with_caveats`, `supported`, or the distribution-wide
`sd()` proposal.

## Key Decisions and Rationale

- The first bivariate non-phylogenetic REML admission is a fixed-covariance
  spatial q2 intercept because it has an exact dense Gaussian restricted-
  likelihood oracle and an already-working ML route.
- The engine did not need a covariance rewrite; the narrowest correct change
  was an R-side fail-closed admission predicate plus explicit rejection guards.
- Recovery evidence caps the claim at `point_fit_recovery`. It cannot support
  interval, coverage, or `supported` language.
- Simulations ran on Totoro and their retained evidence stays local/tracked in
  the dev log; GitHub Actions was used only for package checks.
- The next arc must be selected only from updated `main` after PR #783 is
  authorized and merged. The banked `sd()` proposal is not pre-approved.

## Landing State

`handoff_gate.sh` exits nonzero because 358 unrelated, pre-existing local
branches contain commits absent from all remote refs. Those branches are
protected user state. They are explicitly carried over; do not modify, stage,
push, delete, merge, or rewrite them.

Compact verbatim gate summary from this session:

```text
LANDING GATE -- run before writing a handoff. Across Claude<->Codex the next agent reads origin, not your disk.
XX drmTMB codex/arc1b-s1-spatial-q2-reml 358 UNPUSHED on other branch(es)
PR #783 OPEN: Arc 1b-S1: certify exact bivariate spatial q2 REML
GATE FAIL -- 1 of 1 repo(s) have UNLANDED state.
```

| Artifact / branch | Committed | Pushed | PR | State |
| --- | ---: | ---: | --- | --- |
| `codex/arc1b-s1-spatial-q2-reml`; verified ancestor `38c57f6c`, green pre-handoff head `0630d9b3`, plus this docs-only successor | yes | yes after this handoff push | #783 open | LANDED on remote; CARRIED-OVER merge decision requires Shinichi |
| PR #781 | n/a | n/a | #781 open | CARRIED-OVER unrelated; do not absorb |
| Banked family-specific `sd()` proposal | n/a | n/a | none | CARRIED-OVER design candidate; fresh GOAL and approval required |
| 358 unrelated local branches | mixed | mixed | mixed | CARRIED-OVER protected historical/user state; outside this task |
| Brain-vault Mission Control status | yes; authoring ancestor `55115c0` | local-only by policy | none | LANDED in the local-only vault; resolve the final status successor live |

Safe continuation commands for carried-over rows:

- **PR #783 merge decision:** inspect with
  `gh pr view 783 --json state,mergedAt,mergeable,mergeStateStatus,headRefOid,statusCheckRollup,url`.
  No merge command is authorized until Shinichi explicitly says to merge it.
- **PR #781:** no continuation is authorized in this task. If Shinichi later
  scopes it separately, start read-only with
  `gh pr view 781 --json state,mergedAt,isDraft,headRefName,baseRefName,statusCheckRollup,url`.
- **Banked `sd()` proposal:** no execution command is authorized until a fresh
  GOAL and approval. The safe design-only rehydration command is
  `rg -n "Distribution-wide.*sd\(\)|Candidate comparison" docs/dev-log/2026-07-14-next-arc1b-spatial-q2-reml-ultra-plan.md`.
- **358 protected branches:** inventory only by rerunning the landing gate
  below. Do not run any mutating branch command.

Reproduce the gate and inventory the carried-over state without changing it:

```sh
/Users/z3437171/Dropbox/Github\ Local/Shinichi/tools/handoff_gate.sh \
  /Users/z3437171/.codex/worktrees/3d16/drmTMB
```

## Files Created / Modified

Relative to merged Arc 3a base `29a4458addb550c9d82a9dc8c4324c15702e0591`,
the Arc 1b-S1 branch contains these paths. The final two entries are the
outbound handoff files written in this continuation.

```text
AGENTS.md
NEWS.md
R/drmTMB.R
README.md
ROADMAP.md
docs/design/01-formula-grammar.md
docs/design/03-likelihoods.md
docs/dev-log/2026-07-14-arc1b-s1-admission-ledger-plan.md
docs/dev-log/2026-07-14-arc1b-s1-recovery-design.md
docs/dev-log/2026-07-14-arc1b-s1-symbolic-alignment.md
docs/dev-log/2026-07-14-next-arc1b-spatial-q2-reml-ultra-plan.md
docs/dev-log/after-task/2026-07-14-arc1b-s1-spatial-q2-reml.md
docs/dev-log/check-log.md
docs/dev-log/dashboard/README.md
docs/dev-log/dashboard/capability-census/_master.tsv
docs/dev-log/dashboard/capability-census/_widget_data.json
docs/dev-log/dashboard/capability-census/biv_gaussian.tsv
docs/dev-log/dashboard/capability-ledger/README.md
docs/dev-log/dashboard/capability-ledger/cells.tsv
docs/dev-log/dashboard/capability-ledger/evidence.tsv
docs/dev-log/dashboard/capability-ledger/schema.json
docs/dev-log/dashboard/capability-ledger/transitions.tsv
docs/dev-log/dashboard/capability-surface.html
docs/dev-log/dashboard/capability-surface.md
docs/dev-log/dashboard/estimator-surface-conformance.tsv
docs/dev-log/handover/2026-07-14-arc1b-s1-codex-handover.md
docs/dev-log/handover/2026-07-15-codex-handover.md
docs/dev-log/known-limitations.md
docs/dev-log/simulation-artifacts/2026-07-14-arc1b-spatial-q2-reml-recovery/README.md
docs/dev-log/simulation-artifacts/2026-07-14-arc1b-spatial-q2-reml-recovery/SHA256SUMS
docs/dev-log/simulation-artifacts/2026-07-14-arc1b-spatial-q2-reml-recovery/design.tsv
docs/dev-log/simulation-artifacts/2026-07-14-arc1b-spatial-q2-reml-recovery/raw-attempts.tsv
docs/dev-log/simulation-artifacts/2026-07-14-arc1b-spatial-q2-reml-recovery/session-info.txt
docs/dev-log/simulation-artifacts/2026-07-14-arc1b-spatial-q2-reml-recovery/summary.tsv
docs/dev-log/team-improvements.md
man/drmTMB.Rd
tests/testthat/test-arc1b-spatial-q2-reml-recovery.R
tests/testthat/test-reml-bivariate-spatial-q2.R
tools/capability_ledger.py
tools/run-arc1b-spatial-q2-reml-recovery.R
tools/tests/test_capability_ledger.py
vignettes/capability-and-limits.Rmd
vignettes/formula-grammar.Rmd
vignettes/includes/capability-ledger-family-map.md
vignettes/spatial-models.Rmd
```

The related external live-status file is
`/Users/z3437171/Dropbox/Github Local/Shinichi/Shinichi/Dashboards/mission-control/live/status/drmTMB.json`
with committed authoring ancestor `55115c0`; use the live vault head after the
final docs-only PR head is recorded.

Never stage ignored local products such as `*.Rcheck/`, package tarballs,
compiled objects in `src/`, local R libraries, `pkgdown-site/`, recovery
checkpoints, scratch logs/RDS files, or Totoro run directories. Stage explicit
paths only.

## Blockers / Open Questions

- **Only live blocker:** Shinichi has not separately authorized merging PR
  #783.
- The next arc is intentionally undecided. It must be prioritized after the
  authorized merge from updated `main`.
- The external mirror artifact mentioned in older arcs was not used as Arc
  1b-S1 evidence and needs no action here.

## Gotchas and Failed Approaches

- The first `--as-cran` run exposed a source-only runner-contract test trying
  to read `tools/` from the built package. The repaired test skips only when the
  source-only runner is absent; source-tree tests still exercise the contract.
- The live Mission Control board initially read an old Arc 4a checkout and Arc
  3a status card. Both routing and curated status were repaired. Use
  `/p/drmTMB/status.json`; `/api/projects/drmTMB` does not exist.
- The first Totoro install used an incompatible library route. The successful
  campaign used the isolated Arc 1b-S1 library shown below.
- On this Mac, the user `.Rprofile` can route R 4.6 into an incompatible R 4.5
  library. Always set `R_PROFILE_USER=/dev/null` and use `--no-init-file`.
- A negative `exists()`/namespace probe cannot establish that formula grammar
  is unsupported. Verify grammar with a toy fit or the focused tests.
- Do not clean the 358 historical branches. Their nonremote commits are
  unrelated protected user state, not Arc 1b debt.

## Codex Live-Toolchain Recipe

`AGENTS.md` is native. The launchable team is in `.codex/agents/*.toml`.
Launch Rose from `.codex/agents/systems-auditor.toml` immediately for a
read-only rehydration audit before making any renewed completion or public-
status claim. Codex owns the live R/TMB toolchain, real fits, checks,
simulations, and rendering in the next session.

Local Mac environment:

```sh
cd /Users/z3437171/.codex/worktrees/3d16/drmTMB
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

/usr/local/bin/Rscript --no-init-file -e 'devtools::document()'
/usr/local/bin/Rscript --no-init-file -e 'devtools::test()'
/usr/local/bin/Rscript --no-init-file -e 'devtools::check()'
/usr/local/bin/Rscript --no-init-file -e 'pkgdown::check_pkgdown()'
```

Verified toolchain: R 4.6.0 at `/usr/local/bin/Rscript`; Apple clang 21 at
`/usr/bin/clang`; Homebrew GNU Fortran 15.1 at
`/opt/homebrew/bin/gfortran`; `gh` at `/opt/homebrew/bin/gh`.

The completed Totoro campaign used no scheduler and no job ID:

```sh
R_ENVIRON_USER=/dev/null \
R_LIBS_USER="$HOME/drmtmb_work/arc1b-s1-lib:$HOME/R/lib" \
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
R_PROFILE_USER=/dev/null \
Rscript --no-init-file tools/run-arc1b-spatial-q2-reml-recovery.R \
  --n-rep=200 --cores=32 \
  --out-dir="$HOME/drmtmb_work/arc1b-s1-campaign"
```

Do not rerun that campaign unless a later approved task changes the model or
the evidence contract. New simulation/coverage campaigns belong on Totoro or
DRAC, never GitHub Actions.

Mission Control is a read-only local process. If port 8823 is not listening,
start it in a separate terminal with the exact permanent launcher below, keep
that process running, and retry the status readback:

```sh
sh "/Users/z3437171/Dropbox/Github Local/Shinichi/Shinichi/Dashboards/mission-control/live/start.sh"
```

## Next Immediate Steps

Launch Rose for the mandatory read-only audit, run these checks, report the
result, and stop. Start Mission Control with the launcher above first if the
curl endpoint is unavailable:

```sh
cd /Users/z3437171/.codex/worktrees/3d16/drmTMB
git status --short --branch
git fetch origin
git rev-parse HEAD
git rev-parse origin/codex/arc1b-s1-spatial-q2-reml
git merge-base --is-ancestor 38c57f6c \
  origin/codex/arc1b-s1-spatial-q2-reml
gh pr view 783 \
  --json state,mergedAt,isDraft,mergeable,mergeStateStatus,headRefOid,statusCheckRollup,url
gh pr checks 783
R_PROFILE_USER=/dev/null NOT_CRAN=true \
  python3 tools/validate-mission-control.py
curl -fsS http://127.0.0.1:8823/p/drmTMB/status.json | \
  python3 -m json.tool
```

Expected result: local and remote branch heads agree; PR #783 remains open and
unmerged; the current head contains `38c57f6c`; all current-head checks are
green; Mission Control names PR #783 and the explicit merge-authorization
boundary. Wait if the docs-only successor run is pending.

After reporting, wait for Shinichi's direction. Do not merge or start the next
arc from this handoff.

## How to Resume

One command from an authenticated terminal starts a fresh Codex session in the
correct repository and passes the exact continuation prompt:

```sh
cd /Users/z3437171/.codex/worktrees/3d16/drmTMB && codex "Rehydrate from docs/dev-log/handover/2026-07-15-codex-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."
```
