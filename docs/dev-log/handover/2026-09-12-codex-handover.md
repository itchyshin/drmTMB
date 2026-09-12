# Session Handoff: phylogenetic OU evidence arc

Meta: 2026-09-12 MDT · from Codex · target Codex · branch
`codex/temporal-ar1-plan-20260908` at `475b5e0658d5fb1003448acec8e15573cde1ff5c`

## Critical Context

You are Codex, picking up a fresh evidence-and-design lane for the existing
evolutionary phylogenetic OU covariance model:

```r
phylo(1 | species, tree = tree, model = "ou")
```

This provider already exists. It is a univariate Gaussian ML location-side
random intercept with stationary tree OU covariance and a positive point estimate
`decay_phylo`. Do **not** implement it again. Its retained 12-fixture panel found
weak separation between the global fixed intercept and the phylogenetic tree
field, so it has no point-recovery, interval, or coverage claim.

The prior temporal covariance programme is closed through P3. Heterogeneous
Toeplitz (P4) and seasonal/random-walk/ARMA/temporal-Matérn models (P5) are
protected deferred work. Do not open them in this lane. A temporal Matérn may
learn from spatial Matérn parameterizations, but cannot reuse spatial code without
its own time-domain model contract, likelihood, identification analysis and
evidence.

Read the repository's multi-lane entrypoint first:
[`../active-lane-split.md`](../active-lane-split.md). Preserve its foreign lanes.

## Goals and Roadmap

The immediate mission is to decide how the already working phylogenetic OU route
can become scientifically useful without overstating its current evidence. Start
with the separation failure, a concrete ecological/evolutionary use case, and a
small evidence ladder. Use `ultra-plan` and `unlazy` before new source edits.

The programme order is fixed for now:

1. Phylogenetic OU evidence and scope decision.
2. A separate, fully planned scale-side phylogenetic OU child only if the
   location-side evidence supports proceeding.
3. Future temporal P4 only with regular replicated schedules and evidence that
   homogeneous Toeplitz and heterogeneous AR1 are inadequate.
4. Future temporal P5 only after a named scientific process motivates seasonal,
   random-walk, ARMA, or temporal-Matérn structure.

Keep evolutionary tree OU, temporal autocorrelation and spatial covariance as
separate providers. The paired Brownian phylogenetic intercept plus independent
temporal OU work is a different model and remains under issue #1302.

## What Was Accomplished

- Closed and committed the direct temporal programme checkpoint at `475b5e065`.
  It records AR1/OU, homogeneous Toeplitz and heterogeneous AR1 at their earned
  boundaries; P1 and P3 are interval-feasibility only, and P4/P5 remain deferred.
- Integrated P1's phylogeny-plus-independent-temporal-OU closeout at
  `875bdf305`. Its retained G13 fixed-mean profile coverage failures prevent a
  calibrated-inference claim.
- Previously implemented and closed the distinct evolutionary tree OU provider
  at `84bd42133`; its complete receipt is
  [`../after-task/2026-09-11-phylogenetic-ou-covariance.md`](../after-task/2026-09-11-phylogenetic-ou-covariance.md).
- Refreshed the multi-lane board and `AGENTS.md` pointer so this new Codex lane
  cannot orphan release or sibling work.

## Current Working State

- **Working:** the repository state is clean at `475b5e065`; all P1/P2/P3 and
  phylogenetic-OU closeout receipts are committed locally on the branch above.
- **In progress:** none. The receiving lane owns a new evidence/design arc, not
  a half-edited implementation.
- **Blocked:** the existing recovery panel reveals an identification limitation.
  It is not a code failure. The next lane must diagnose it before proposing any
  promotion in scope or any larger campaign.

## Key Decisions and Rationale

- `phylo(..., model = "ou")` means evolutionary attraction along tree branch
  lengths. Its covariance is
  \(s_{phylo}^2\exp(-\alpha d_{ij})\), \(\alpha>0\), and it is not temporal
  OU or spatial OU.
- Brownian motion remains the default `phylo()` model. Evolutionary OU is an
  explicit alternative, not a Brownian boundary.
- The provider may report labelled point estimates, modes, fitted values,
  residuals and seeded simulation. Fixed-effect and decay intervals remain
  unavailable until separately justified.
- No long campaign, remote compute, push, merge, release or external message is
  authorized by this handover. Estimate every proposed run first. Runs estimated
  at more than three hours require Shinichi's approval.
- The checked checkout does not contain the shared `tools/handoff_gate.sh` or
  `tools/lane_preflight.sh` wrappers named in the general protocol. Treat this
  documented absence as a procedural limitation, not permission to skip current
  git-state, ownership and gate checks.

## Landing State

| Item | State | Evidence / resume rule |
| --- | --- | --- |
| Current programme branch | `CARRIED-OVER` | Local branch `codex/temporal-ar1-plan-20260908` at `475b5e065`; it contains the handover and is not pushed. Do not lose it. Start the new Codex worktree from the current working-tree state. |
| Direct temporal programme | `DONE` | `docs/dev-log/after-phase/2026-09-11-temporal-covariance-programme-checkpoint.md`; reverify is `Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G18 --reverify`. |
| Evolutionary phylogenetic OU provider | `DONE` at local-fit-only scope | After-task receipt and PO ledger below; do not call its existence evidence for recovery, intervals or coverage. |
| Phylogenetic OU evidence/design arc | `OWED` | Begin from the next immediate steps; no code change is currently owed. |
| Temporal P4/P5 | `PROTECTED` | Defer until their separate entry conditions in the programme checkpoint are met. |

FINDINGS-OF-RECORD: none. This handover creates no new scientific finding beyond
the already committed programme and phylogenetic-OU receipts.

## Files Created or Modified in This Handover

- `AGENTS.md` — refreshed current multi-lane snapshot pointer.
- `docs/dev-log/active-lane-split.md` — added the phylogenetic-OU evidence lane
  and temporal-programme P1--P3 row.
- `docs/dev-log/handover/AGENTS-handover-log-archive.md` — preserved the former
  `AGENTS.md` latest snapshot verbatim.
- `docs/dev-log/handover/2026-09-12-codex-handover.md` — this durable handover.

For implementation history, do not rediscover it from commits. Read:

- `docs/dev-log/after-task/2026-09-11-phylogenetic-ou-covariance.md`
- `docs/dev-log/plans/2026-09-11-phylo-ou-covariance/PLAN.md`
- `docs/dev-log/plans/2026-09-11-phylo-ou-covariance/unlazy/GATES.md`
- `docs/dev-log/after-phase/2026-09-11-temporal-covariance-programme-checkpoint.md`
- `docs/design/01-formula-grammar.md` and `docs/design/03-likelihoods.md`
- `docs/dev-log/known-limitations.md`

## Next Immediate Steps

1. Read `AGENTS.md`, the Active-Lane Split, this handover, the phylogenetic-OU
   after-task report, plan and PO ledger. Run `git status --short`, inspect
   `git log -5`, and classify every lane item `OWED`, `DONE`, `RETRACTED`, or
   `PROTECTED` before editing.
2. Use `/ask-brain` and a grounded NotebookLM/Ranga search to identify a real
   evolutionary question where stationary phylogenetic OU is preferable to
   Brownian covariance. Check how related tools describe tree OU, but keep their
   temporal and spatial implementations out of this model contract.
3. Audit the frozen recovery fixtures and the dense `ape::corMartins` oracle to
   determine whether the intercept--tree-field weakness is expected information
   geometry, a fixture-design limitation, or an implementation flaw. Preserve
   failed fixtures and thresholds.
4. Write a new ultra-plan plus Unlazy ledger before source changes. It must state
   the intended scientifically useful scope, a deterministic reference, mutation
   tests, recovery criteria, interval boundary, compute estimate and reader
   question.
5. A short local diagnostic may run after a stated estimate if it is expected to
   take at most 30 minutes. Do not launch a campaign until a measured pre-run
   plan is reviewed and, if it exceeds three hours, separately authorized.
6. Use Codex for live R/TMB compilation, real fits, package checks and rendering.
   The planning/research side should not claim live numerical results without
   this lane's receipts.

## Blockers and Open Questions

- What scientific design (tree depth, taxon sampling, residual variance and
  fixed-effect structure) identifies both a global mean and a stationary tree
  OU field well enough for a user-facing claim?
- Does a fixed-effect covariance or interval feasibility target make sense only
  after an intercept parameterization/design decision, or should the earned
  endpoint remain a carefully diagnosed point-fit provider?
- Is a scale-side phylogenetic OU model valuable enough to plan after location
  evidence, given its separate decay and identification burden?

## Gotchas and Failed Approaches

- The public grammar requires the tree argument to be a symbol: bind
  `tree <- fixture$tree` first rather than using `tree = fixture$tree` directly.
- `decay_phylo` is inverse branch-length scale. It is not temporal persistence,
  so never describe it as an AR1 coefficient or use elapsed-time transitions.
- Do not use the P1 phylogeny-plus-temporal-OU G13 coverage failure as evidence
  for, or against, the evolutionary tree-OU provider; the models differ.
- The retained 12-fixture panel has an all-fixture intercept failure. It must
  remain visible. Do not adjust seeds, exclude draws, or silently relax its
  threshold.
- P4 heterogeneous Toeplitz needs common regular occasions and enough replicated
  series for its lag correlations and occasion-specific SDs. P5 temporal Matérn
  is not implemented; spatial Matérn ideas are not an automatic code-sharing
  route.

## Codex Rehydration and Checks

From the fresh worktree root, Codex should use the live R/TMB toolchain:

```sh
Rscript --vanilla -e 'devtools::load_all(quiet = TRUE)'
Rscript --vanilla tools/phylo-ou-covariance-gates.R PO11 --reverify
Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-phylo-ou-covariance-native.R")'
```

The PO11 reverify checks retained evidence; it does not launch a campaign.
Use `devtools::document()`, focused `testthat` tests, `devtools::check()` and
`pkgdown::check_pkgdown()` only when the proposed change requires them.

## Mission Control

| Repository | Branch / state | What is shipped or retained | Plan by leverage |
| --- | --- | --- | --- |
| `drmTMB` | local `codex/temporal-ar1-plan-20260908` at `475b5e065`, clean and unpushed | Direct temporal P1--P3 checkpoint; evolutionary tree OU provider at local-fit-only scope | Diagnose phylogenetic-OU identifiability and state its useful endpoint before changing source. |
| `drmTMB` temporal P4/P5 | protected deferred | P4/P5 entry conditions in the programme checkpoint | Wait for a real scientific use case and create a separate child plan. |
| `drmTMB` release and foreign lanes | protected | Active-Lane Split | Preserve; this lane has no release authority. |

## How to Resume

Start Codex in the fresh drmTMB worktree and paste:

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-12-codex-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
