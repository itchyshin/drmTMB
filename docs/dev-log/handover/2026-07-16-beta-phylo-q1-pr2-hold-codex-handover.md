# Codex handover: Beta phylogenetic q1 PR 2 recovery HOLD

Meta: 2026-07-16 · from Codex · branch-only stopped arc

You are Codex, picking up `drmTMB` after the approved two-PR Beta
phylogenetic location-scale-scale goal reached its frozen PR 2 recovery gate.
Read this file and the repository `AGENTS.md` snapshot before taking any action.

## Critical Context

PR 1 is merged. PR 2 is **HOLD** and must not be opened. The exact frozen
decision is `HOLD_NO_PR2_PROMOTION`: distinct `g = 1024, m = 4` passed, but
shared `g = 1024, m = 4` retained only 399/400 finite fits because replicate
373, seed `2099879627`, generated a response at Beta's forbidden support
boundary and failed before optimization.

Do not rerun, filter, resample, replace that seed, weaken the gate, use the
successful subset as the denominator, promote the capability ledger, or claim
direct latent-`sd()` support. The boundary event diagnoses the frozen DGP at
finite precision; it does not diagnose estimator, Laplace, or optimizer bias.

Family `sigma` remains distinct from the latent target:

\[
\phi_i = \sigma_i^{-2}, \qquad
\tau_s = \exp(\alpha_0 + \alpha_1 x_s), \qquad
a \sim \mathcal N(0, D_\tau A D_\tau).
\]

The requested R syntax for the stopped PR 2 route was
`sd(spp_id, level = "phylogenetic") ~ 1 + x`; it models `tau_s`, not family
`sigma`.

## Goals and Plan

The original mission was to deliver two separately reviewed pull requests,
both capped at `point_fit_recovery`: first the constant-SD q1 Beta
phylogenetic `mu` prerequisite, then the exact direct latent-SD regression for
that same effect. PR 1 completed. PR 2 did not satisfy its prospective recovery
contract, so the approved plan terminates here.

The later hierarchical-`sd()` subarc remains separate. No successor work may
start until Shinichi explicitly chooses a new goal and approves a prospectively
frozen interior-response DGP or abandons the branch-only implementation.

## What Was Accomplished

- PR #786 merged PR 1 at
  `0bdfda144c976824bed604be2cfae22b33bd8fe0`; exact post-merge
  R-CMD-check run 29524995333 passed `os-matrix` and Ubuntu release jobs.
- PR 2 source commit `2f1b602b88f0fcf1ce67ebd60412c6bcf2fbaa27`
  added the bounded implementation, independent likelihood/gradient oracles,
  rejection tests, frozen design, and recovery runner.
- Exact evidence source `2f1399dda78253ea725f93e47a0e88da2ed5a8e6`
  fixed relative-path manifest authentication. The one-fit and all 12 Totoro
  smoke cells passed.
- The exact 4,800-attempt Totoro certification completed from the same source
  and DLL. Its 9,613-file imported output passed complete SHA-256 readback.
- Fisher returned GO on the HOLD disposition. Rose verified the evidence,
  compact packet, empty PR list, and unchanged capability surfaces, then
  required the exact closeout repairs now recorded here and in the after-task
  report.
- Mission Control records the HOLD and no-PR boundary.

## Current Working State

- **Working:** symbolic alignment; bounded branch implementation; independent
  likelihood/gradient/covariance sentinels; authenticated one-fit; 12-cell
  smoke; complete 4,800-attempt evidence; compact tracked evidence; closeout
  tests and validators.
- **In progress:** none. This arc is closed as HOLD.
- **Blocked:** PR 2 admission. The shared promotion arm failed the frozen
  all-400-finite rule.

Three other retained stress diagnostics are also part of the evidence:

- distinct `g = 256, m = 2`, replicate 103, seed `2099989897`: optimizer code
  1 and singular-convergence warning;
- shared `g = 256, m = 2`, replicate 153, seed `2099929847`: optimizer code 1
  and singular-convergence warning;
- shared `g = 512, m = 2`, replicate 74, seed `2099909926`: `pdHess = FALSE`
  and `NaNs produced`;
- shared `g = 1024, m = 4`, replicate 373, seed `2099879627`: pre-optimization
  Beta-support failure and the decisive promotion blocker.

## Key Decisions and Rationale

Both predeclared promotion arms had to pass independently. The successful
distinct arm cannot offset the failed shared arm. The 399 successful shared
fits are descriptive only because changing the denominator after observing the
failure would invalidate the prospective gate.

The implementation remains branch-only. Opening a code-only PR would break the
approved two-PR contract, which required recovery before PR 2. Public docs,
NEWS, formula grammar, pkgdown navigation, and capability-ledger rows therefore
remain unchanged.

## Landing State

The handoff gate was rerun after pushing the commit containing this handover.
It reported no uncommitted or unpushed state on the active branch, but still
reported 358 commits on unrelated pre-existing local branches. Those branches
predate this task and are declared out of scope; do not push, rewrite, delete,
or claim them.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| `main` PR #786 at `0bdfda14` | yes | yes | #786 merged | LANDED: constant-SD PR 1 only |
| `codex/beta-phylo-q1-sd-regression` through this handover commit | yes | yes | none | CARRIED-OVER: deliberate branch-only HOLD; recovery forbids PR 2 |
| 358 unrelated local branch commits reported by the gate | pre-existing | mixed | unrelated | CARRIED-OVER: outside this task; leave untouched |
| Shinichi Mission Control `master` at `6d9b8b2` | yes | local-only by policy | none | LANDED: live HOLD status |

Resume the carried-over drmTMB branch only after a new explicit goal:

```sh
git switch codex/beta-phylo-q1-sd-regression
git status --short --branch
git log -5 --oneline
```

## Files Created or Modified

Implementation and contracts:

- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-beta-location-scale.R`
- `tests/testthat/test-beta-phylo-direct-sd.R`
- `tests/testthat/test-beta-phylo-q1-sd-regression-runner.R`
- `tools/run-beta-phylo-q1-sd-regression-recovery.R`
- `docs/dev-log/2026-07-16-beta-phylo-q1-pr2-symbolic-alignment.md`
- all three files under
  `docs/dev-log/simulation-designs/2026-07-16-beta-phylo-q1-pr2-sd-regression/`

Evidence and closeout:

- all files under
  `docs/dev-log/simulation-artifacts/2026-07-16-beta-phylo-q1-pr2-sd-regression-one_fit/`
- all files under
  `docs/dev-log/simulation-artifacts/2026-07-16-beta-phylo-q1-pr2-sd-regression-smoke/`
- all files under
  `docs/dev-log/simulation-artifacts/2026-07-16-beta-phylo-q1-pr2-sd-regression-certification-compact/`
- `docs/dev-log/after-task/2026-07-16-beta-phylo-q1-pr2-recovery-hold.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `ROADMAP.md`
- `AGENTS.md`
- this handover

The full certification shards and invalid first one-fit quarantine are local at
`/Users/z3437171/Dropbox/Github Local/drmTMB-local-artifacts/2026-07-16-beta-phylo-q1-pr2/`.
The authenticated Totoro source and full output remain under
`/home/snakagaw/drmtmb_work/beta-phylo-q1-pr2-2f1399dd/`.

## Checks and Receipts

- Full certification manifest authentication: PASS; 9,611 manifest rows plus
  manifest and seal; manifest SHA-256
  `7e5532c61e0f97f107e54c0be43f438e2859421e8630129bbba529e91123459f`.
- Fresh direct-SD closeout tests: 44/44 PASS.
- Fresh runner tests: 81/81 PASS.
- Compact evidence audit: 4,800 attempts, failed seed `2099879627`, exact HOLD
  decision: PASS.
- `tools/validate-mission-control.py`: PASS.
- after-task structure validator: PASS.
- public and capability-ledger surfaces expected to remain unchanged: PASS.
- `gh pr list --state all --head codex/beta-phylo-q1-sd-regression`: empty.

## Mission Control

| Repo | Branch / main | CI and evidence | What shipped | Plan by leverage |
|---|---|---|---|---|
| `drmTMB` | PR 1 on `main` at `0bdfda14`; PR 2 held on `codex/beta-phylo-q1-sd-regression` | PR 1 run 29524995333 green; PR 2 one-fit/smoke green; certification HOLD | Constant-SD q1 Beta phylogenetic `mu` only | Stop. Await explicit successor goal; preserve family `sigma` versus latent `sd()` boundary |

Live Mission Control: <http://127.0.0.1:8823/p/drmTMB/>

## Next Immediate Steps

None under the current goal. Stop. If Shinichi explicitly opens a successor
goal, first read the after-task report and compact evidence, then prospectively
design an interior-response DGP without altering this campaign. Do not bundle
the separate hierarchical-`sd()` subarc.

## Blockers and Open Questions

The product decision is whether a future goal should abandon the branch-only
admission or design a new interior-support recovery campaign. The current arc
does not answer that question and supplies no authority to continue.

## Gotchas and Failed Approaches

- The first local one-fit wrote an output manifest with path-sensitive
  authentication. It is quarantined and is not evidence. Commit `2f1399dd`
  repaired relative-path readback before every valid stage.
- Do not describe the decisive boundary draw as estimator bias. No optimization
  or estimate occurred for that attempt.
- Do not hide the three additional warning/Hessian attempts merely because they
  are outside the two promotion cells.
- Do not treat large `g` as sufficient by itself: the N ladder addresses
  information, while strict Beta support is a separate DGP condition.
- Certification is exactly bound to source `2f1399dd`; later documentation
  commits do not change its provenance.

## How to Resume

In a new Codex task, open the repository and paste:

> Rehydrate from `docs/dev-log/handover/2026-07-16-beta-phylo-q1-pr2-hold-codex-handover.md` plus the `AGENTS.md` snapshot. Preserve the branch-only HOLD and stop unless Shinichi has supplied an explicit successor goal.

Use the live R/TMB environment as:

```sh
R_PROFILE_USER=/dev/null OPENBLAS_NUM_THREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "beta-phylo-direct-sd", stop_on_failure = TRUE)'
```

Do not run a fit, compute campaign, check, push, or PR merely to rehydrate.
