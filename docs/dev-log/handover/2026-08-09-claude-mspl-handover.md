# Session Handoff: MSPL point-estimation evidence to inference-promotion lane

Meta: 2026-08-09 · from Codex to Claude · multi-lane repository · local-only handover

## Critical Context

You are Claude, taking over **Lane 2 only: drmTMB MSPL inference promotion**.
Lane 1 (0.7/main) continues under its existing owner and is not handed over here;
it appears below only because its moving baseline can collide with Lane 2. The
current MSPL implementation is a locally verified,
experimental **point-estimation** slice in
`/Users/z3437171/local-scratch/worktrees/drmTMB-rose-nit` on
`codex/mspl-binomial-glmm-experimental`. It is deliberately uncommitted and
unpushed. Treat all 43 working-tree entries as `CARRIED-OVER`; do not clean,
reset, stage broadly, or assume they are present on a remote branch.

The desired next subject is a separate inference-promotion lane, not an extension
performed blindly in this stale-base worktree. The proposed lane is
`claude/mspl-binomial-inference-promotion`, created from a freshly fetched exact
`origin/main` only after the point-estimation state has been preserved and its
overlap with current main has been reconciled path by path.

Current local `origin/main` is `ac363cadb` and is four commits ahead of the MSPL
base `efb5af4f`: `6a5113fab`, `31da19f28`, `08c9f2330`, and `ac363cadb`. Main
changed several overlapping surfaces, including `R/drmTMB.R`, `NEWS.md`,
`README.md`, the family registry, check log, limitations, `man/drmTMB.Rd`, and
formula/model-map vignettes. Never wholesale-copy those files from the
experimental tree onto current main.

The canonical multi-lane coordination entrypoint now lives on current main at
`docs/dev-log/active-lane-split.md`. Read every row before editing. In particular,
the 0.7 scope/packaging owner decision, Lane B PR #858, GVA PR #937, and the dirty
primary checkout are `PROTECTED`. Do not replace the repository's single latest
snapshot pointer with this handover; that would orphan the moving release lane.

## Lane Ownership: This Handover Transfers Only Lane 2

There are two active subjects in the repository, but this document transfers
only **Lane 2**. The old experimental MSPL branch is a carried evidence source
for Lane 2, not a third active implementation lane. Lane 1 is listed only as a
protected synchronization boundary.

| Lane | Owner and branch | Objective | May change | Must not change or claim |
| --- | --- | --- | --- | --- |
| **Lane 2 — MSPL inference promotion (HANDED OVER)** | Claude; proposed `claude/mspl-binomial-inference-promotion` from a freshly fetched exact main SHA | Replay the bounded point estimator, then earn Wald, MSPL penalized-profile, and parametric-bootstrap inference | MSPL implementation, its exact q2 binomial prerequisite where required, MSPL-specific tests/design/receipts, and narrowly necessary S3 inference routing | Must not bump DESCRIPTION, write `platform-clean`, edit CRAN/release audits, change the frozen capability census/ledger, close issues, modify Lane B/GVA, launch compute, or make a 0.7/public-support claim |
| **Lane 1 — 0.7/main (NOT HANDED OVER)** | Existing release/candidate owner; moving `origin/main` and whatever focused release branch the current board names | Decide and, only when owner-authorized, prepare the exact 0.7 candidate and release evidence | Candidate/version/package/release surfaces defined by the current-main board and release plan | Claude must not execute, pause, redirect, or claim this lane; Lane 1 must not absorb the dirty MSPL worktree or treat this handover as candidate authorization |

### Protected external context — Lane 1 moving 0.7/main

Lane 1 is **not part of Claude's assigned work**. Its existing owner remains
authoritative for `origin/main`, the exact candidate SHA, DESCRIPTION
versioning, release audits, platform evidence, `cran-comments.md`, D-43 release
review, and any CRAN action. Claude must neither execute nor manage Lane 1. At
every Lane-2 start or integration checkpoint, fetch and record the new exact
`origin/main` SHA and reread `docs/dev-log/active-lane-split.md` from that SHA.
A main movement is expected; it is not permission to overwrite the newer main
version with the experimental file.

Lane-1 protected surfaces include, at minimum:

```text
AGENTS.md latest/multi-lane pointer
DESCRIPTION version and release metadata
docs/dev-log/active-lane-split.md
docs/dev-log/release-audits/**
docs/dev-log/platform/** and platform-clean evidence
docs/dev-log/dashboard/capability-census/**
docs/dev-log/dashboard/capability-ledger/**
cran-comments.md and release submission material
Lane B #858 and GVA #937 artifacts
```

Lane 1 may legitimately modify shared package files while Lane 2 is underway.
That does not stop isolated MSPL kernel/test work, but it prevents an integration
or landing claim until Lane 2 is reconciled again with the newest exact main.

### Transferred subject — Lane 2 MSPL inference promotion

Claude owns only the bounded MSPL subject. The initial expected ownership fence
is:

```text
R/mspl.R
R/mspl-estimator.R
tests/testthat/test-mspl-kernels.R
tests/testthat/test-mspl-estimator.R
tests/testthat/test-binomial-correlated-re-mspl-prereq.R
scratchpad/mspl-*
docs/design/250-mspl-binomial-logit-alignment.md
a new MSPL-inference symbolic/design note
the MSPL after-task, plan-actual, and check-log entries
```

The following shared files may be edited only after a semantic three-way
comparison of experimental base, current main, and the intended MSPL delta:

```text
R/drmTMB.R
R/methods.R
R/profile.R
R/check.R
src/drmTMB.cpp
NAMESPACE and generated man pages
README.md, NEWS.md, family/formula docs, and vignettes
```

For those shared files, retain current-main capability and release wording first,
then apply only the smallest MSPL-specific delta. Never copy the experimental
file wholesale. Public README/NEWS/pkgdown wording remains deferred until local
inference gates and the separately authorized calibration campaign pass; design
notes and limitations may describe the experimental state precisely.

### Synchronization and collision rules

1. Claude works only on Lane 2. Lane 1 continues independently and Lane 2 must
   not freeze, delay, or redirect it.
2. Preserve `codex/mspl-binomial-glmm-experimental` at its current local
   handover-only HEAD plus its 43 carried implementation entries. It is the
   recovery oracle.
3. Do not create Lane 2 inside that dirty tree. Allocate or recycle a separate
   clean worktree only after checking current ownership; no new worktree number
   or location is assumed by this handover.
4. Create Lane 2 from the exact `origin/main` observed **at creation time**, not
   automatically from `efb5af4f` or the dated `ac363cadb` observation.
5. First replay pure MSPL helpers/tests and the minimum q2 engine delta. Reconcile
   shared docs and package routing only after the implementation is locally green.
6. If Lane 1 changes an MSPL-owned pure helper/test file, stop and ask Shinichi
   because the subject lanes have collided. If it changes a shared package/doc
   file, continue isolated work but mark integration `STALE-MAIN` until a fresh
   semantic reconciliation is completed.
7. Before any later PR request, rerun lane preflight, fetch main, record the exact
   merge base, inspect every overlapping file, and rerun the full local gates.
8. No cross-lane staging: explicit paths only, never `git add -A`.

### Landing order

There is no authorized landing in this handover. If both lanes later earn
landing approval, Lane 1's exact candidate/release decision remains independent.
Lane 2 must reconcile onto the then-current main and pass its own checks. An MSPL
merge before 0.7 would be a separate owner decision that deliberately changes
the candidate; an MSPL merge after 0.7 would be a normal post-release feature
lane. Neither outcome is implied here.

## Goals and Scope

Promote the bounded binomial-logit MSPL estimator beyond point estimates while
preserving its earned scope. The first inference target is the method-paper Wald
covariance: invert the Hessian of the independently evaluated **unpenalized
Laplace approximate likelihood at the MSPL estimate**. The penalized Hessian
remains an optimizer diagnostic, not the primary frequentist covariance.

The second target is an explicitly named **MSPL penalized-profile interval** that
profiles the MSPL criterion with nuisance reoptimization. Do not describe this as
ordinary profile likelihood. A parametric bootstrap that simulates and refits the
entire MSPL procedure is the robust comparator/fallback. Keep `logLik()`, AIC,
BIC, ordinary likelihood-ratio `anova()`, and unsupported model cells fenced.

This handover authorizes local reconciliation, implementation planning, and local
toy verification only. It does not authorize Totoro/DRAC, a PR, push, merge,
release promotion, or a universal separation-coverage claim. Stop for owner
authorization before compute.

## What Was Accomplished

- Implemented an opt-in clean-room MSPL point estimator for the declared q1/q2
  Bernoulli and grouped-binomial logit ordinary-random-effect cells.
- Added the stable q2 correlated binomial prerequisite across likelihood,
  extraction, prediction, simulation, and reporting.
- Stored penalized and independently evaluated unpenalized objectives, penalty
  components, scaling, detector output, gradients, Hessians, and boundary facts.
- Fenced all public likelihood and interval inference for MSPL fits.
- Passed focused tests, independent clean-room penalty value/gradient checks,
  exact q1/q2 quadrature reoptimization, full local package checks, and pkgdown.
- Retained initial NOT-DONE reviews and repaired their architecture, inference,
  rejection-matrix, fallback, documentation, and receipt findings.
- Did not launch Totoro/DRAC or make any remote mutation.

Authoritative evidence:

- `docs/design/250-mspl-binomial-logit-alignment.md`
- `docs/dev-log/after-task/2026-08-08-mspl-binomial-glmm-experimental.md`
- `docs/dev-log/plan-actual/2026-08-08-mspl-binomial-glmm-experimental.md`
- `scratchpad/mspl-binomial-quadrature-spike.R`
- `scratchpad/mspl-binomial-quadrature-results.tsv`

## Current Working State

- **Working:** experimental point estimation, diagnostic storage, q1/q2 exact
  quadrature comparison, point prediction, and simulation within the declared
  eligibility fence.
- **In progress:** none. The point-estimation slice is complete locally but is
  uncommitted, unpushed, and not replayed against current main.
- **Blocked/gated:** Wald, penalized-profile, and bootstrap inference require a
  new-lane design and validation contract. Totoro calibration requires separate
  owner authorization. Main/release promotion requires fresh evidence and a
  separate landing decision.

## Key Decisions and Rationale

1. Preserve the experimental point-estimation lane as evidence. Do not convert
   it in place into an inference lane.
2. Reconcile from current main rather than rebasing a dirty 43-entry worktree.
3. Implement the paper-aligned unpenalized-Hessian Wald method first.
4. Profile the penalized MSPL criterion and label it accordingly. Profiling the
   unpenalized likelihood around a non-MLE MSPL estimate is not coherent.
5. Use full-procedure parametric bootstrap as the strongest interval comparator.
6. Keep likelihood-value methods and ordinary LRTs fenced because the MSPL point
   is not the unpenalized MLE and the MSPL criterion is not an ordinary likelihood.
7. Interval existence is not coverage evidence. Any public interval claim needs
   a predeclared Totoro campaign and independent inference review.
8. The MSPL programme does not discharge the independent D-93/D-117 0.7 interval
   holds.

## Landing State

The required handoff gate returned nonzero because the MSPL implementation has
43 uncommitted entries. It also reported many unrelated historical local branches;
those are not owned by this lane and are `PROTECTED`.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/mspl-binomial-glmm-experimental` at base `efb5af4f` plus 43-entry working tree | no | no | none | CARRIED-OVER |
| This Claude handover document | yes, local handover commit | no | none | CARRIED-OVER |
| Current `origin/main` at observed `ac363cadb` | yes | yes | merged through #954 | PROTECTED moving baseline |
| 0.7 scope/packaging owner-decision lane | repository board | repository board | none for next arc | PROTECTED |
| Lane B E0 | yes | yes | #858 draft | PROTECTED |
| GVA decision docs | yes | yes | #937 open | PROTECTED |
| Primary checkout `claude/handover-freshness-0718` | dirty/stale | mixed | none | PROTECTED |

Why the MSPL implementation is carried over: the approved Phase 3 prohibited
push, PR, and merge, and current main advanced during local completion. Preserve
it in place and reconcile it rather than manufacturing landed state.

Exact resume command:

```sh
cd '/Users/z3437171/local-scratch/worktrees/drmTMB-rose-nit'
git status --short --branch
git diff --check
```

## Files Created / Modified

Every current MSPL working-tree path is intentional unless the fresh
reconciliation proves otherwise.

Modified tracked paths:

```text
DESCRIPTION
NAMESPACE
NEWS.md
R/check.R
R/drmTMB.R
R/methods.R
R/profile.R
README.md
_pkgdown.yml
docs/design/01-formula-grammar.md
docs/design/02-family-registry.md
docs/design/151-phase6c-random-slope-tutorial-ledger.md
docs/design/33-phase-6c-core-random-effects.md
docs/design/37-worked-example-inventory.md
docs/design/41-phase-18-simulation-programme.md
docs/design/46-pre-simulation-readiness-matrix.md
docs/design/59-structural-slope-and-non-gaussian-map.md
docs/design/79-supported-nongaussian-evidence-goal.md
docs/dev-log/check-log.md
docs/dev-log/internal-roadmap.md
docs/dev-log/known-limitations.md
man/drmTMB.Rd
src/drmTMB.cpp
tests/testthat/test-arc2a-mu-random-intercept.R
tests/testthat/test-arc2b-mu-random-slope.R
tests/testthat/test-guard-branch-continuity.R
tests/testthat/test-phylo-utils.R
tests/testthat/test-reml-bivariate-relmat-q2.R
vignettes/formula-grammar.Rmd
vignettes/implementation-map.Rmd
vignettes/model-map.Rmd
vignettes/proportion-beta-binomial.Rmd
```

Untracked additions:

```text
R/mspl-estimator.R
R/mspl.R
docs/design/250-mspl-binomial-logit-alignment.md
docs/dev-log/after-task/2026-08-08-mspl-binomial-glmm-experimental.md
docs/dev-log/plan-actual/2026-08-08-mspl-binomial-glmm-experimental.md
man/anova.drmTMB.Rd
scratchpad/mspl-binomial-quadrature-results.tsv
scratchpad/mspl-binomial-quadrature-spike.R
tests/testthat/test-binomial-correlated-re-mspl-prereq.R
tests/testthat/test-mspl-estimator.R
tests/testthat/test-mspl-kernels.R
```

This document is the twelfth untracked addition before its local handover-only
commit.

## Next Immediate Steps

1. Read `AGENTS.md`, then read current-main
   `docs/dev-log/active-lane-split.md`, this handover, design 250, the MSPL
   after-task report, and the plan-versus-actual receipt.
2. Run `tools/lane_preflight.sh` and compare the handover against a freshly
   fetched `origin/main`. Classify every item `OWED`, `DONE`, `RETRACTED`, or
   `PROTECTED`; execute only `OWED`.
3. Preserve the current 43-entry experimental tree. Do not reset or rebase it.
   Record its patch and hashes before creating or recycling any inference
   worktree.
4. Prepare a narrow symbolic alignment for three distinct objects:
   unpenalized-Hessian Wald inference at the MSPL point, MSPL penalized-profile
   intervals, and full-procedure parametric bootstrap intervals.
5. Reconstruct the point estimator onto a fresh exact-current-main branch
   `claude/mspl-binomial-inference-promotion`, resolving overlapping main files
   semantically. Do not use a blanket cherry-pick or file copy.
6. Implement and locally verify Wald first. Require a finite symmetric
   positive-definite unpenalized Hessian; return explicit unavailability rather
   than fabricated standard errors when the gate fails.
7. Implement explicitly labelled penalized profiling and parametric bootstrap,
   retaining all failures. Keep AIC/BIC/logLik/LRT fences.
8. Complete local focused and neighbour tests plus independent objective,
   Hessian, profile, and bootstrap checks. Update receipts and run fresh
   architecture/inference/mechanical reviews.
9. Stop and ask Shinichi before any Totoro campaign, PR, push, merge, capability
   promotion, or 0.7 release claim.

## Blockers / Open Questions

- Main is moving. The observed `origin/main@ac363cadb` is a dated baseline, not
  authority to assume it remains current.
- A clean/released worktree for the new inference lane has not been allocated.
- The exact Totoro ADEMP grid and coverage gates are not yet owner-approved.
- Whether calibrated MSPL intervals ship in 0.7 is a later evidence-based owner
  decision; this handover does not pre-decide it.

## Gotchas and Failed Approaches

- Existing `profile()` uses `object$obj`; for MSPL that is the penalized
  objective. Removing the fence silently would create a penalized profile while
  presenting it as ordinary likelihood profiling.
- Do not use the penalized outer Hessian as the paper-matching frequentist Wald
  covariance. Evaluate the unpenalized approximate-likelihood Hessian at the
  MSPL estimate independently.
- Do not expose the stored diagnostic unpenalized objective through `logLik()`;
  it is not evaluated at its own MLE.
- The first quadrature spike merely evaluated exact likelihood at a Laplace
  solution. The repaired oracle reoptimizes the full exact q1/q2 criterion.
- The optional fixed-X separation detector is conservative GLMM screening, not
  a complete mixed-model oracle.
- Exact oracle hashes at handover:
  `22386a957dd2747a7d9d2a92cc54c0312fa9f90da7884bb5d772116517380027`
  for the script and
  `4be95fe8b5cfc8fd10964741188b26c335a06cc7c463368c3b41bd3bfe8e3ece`
  for the TSV.

## Mission Control

| Repository/lane | Branch or baseline | Verification | What exists | Next by leverage |
| --- | --- | --- | --- | --- |
| Lane 2 active subject — MSPL inference promotion | proposed `claude/mspl-binomial-inference-promotion` from the exact main SHA at lane creation | Not started | Nothing yet | Symbolic alignment, Wald, penalized profile, bootstrap, local verification |
| Lane 2 evidence source — MSPL point estimator | `codex/mspl-binomial-glmm-experimental` / current local handover-only HEAD, implementation based on `efb5af4f` | Local focused, exact quadrature, full check and pkgdown PASS; no platform/compute evidence | Experimental q1/q2 point estimator, diagnostics and inference fences | Preserve, classify, and replay semantically; this is not a third active lane |
| Protected context only — Lane 1 drmTMB 0.7/main | observed `origin/main@ac363cadb`; moving | See current board and release receipts | Capability reconciliation and issue sweep landed; candidate work still owner-gated | Not transferred to Claude; protect and do not conflate with MSPL inference |
| Remote/compute | none authorized | Not run | No PR, push, merge, Totoro or DRAC | Stop for owner approval after local gates |

## How to Resume

Working directory:

```sh
cd '/Users/z3437171/local-scratch/worktrees/drmTMB-rose-nit'
```

Environment and safe first verification:

```sh
R_PROFILE_USER=/dev/null OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript --no-init-file -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_local(".", filter = "(mspl|binomial-correlated-re-mspl-prereq)", reporter = "summary", load_package = "none")'
```

Do not stage the dirty primary checkout, current-main release files from another
worktree, Lane B artifacts, S0 separation artifacts, or unrelated local branches.
Never use `git add -A`.

Paste-ready Claude prompt:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-09-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Lane 2 MSPL inference-promotion steps. Do not take over Lane 1.
```
