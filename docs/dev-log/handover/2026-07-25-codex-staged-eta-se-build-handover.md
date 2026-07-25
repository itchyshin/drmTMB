# Session Handoff: staged-eta SE build

Meta: 2026-07-25 · from Codex · to Codex · status: implementation and small-test phase

## Critical Context

The owner has explicitly reopened staged Bernoulli × ordinary-NB2 association
uncertainty and requests a valid SE for the two-stage eta estimator. This is
not permission to expose the existing conditional stage-2 curvature: it omits
fitted-margin uncertainty and cross-stage covariance, so it is not an eta SE.

Build a stacked-score/Godambe (sandwich) SE. First complete the symbolic
derivation, implementation, and small deterministic/unit/integration tests.
Only after the estimator and tests are frozen may a separately approved large
validation campaign begin. The stopped 24 × 200 × 399 bootstrap campaign must
not resume.

## Goals and Plan

1. State the two-stage estimating equations and the eta/link estimand.
2. Derive and independently check all margin, association, and cross-stage
   score/derivative blocks needed for a sandwich variance.
3. Implement the developer-facing SE path without prematurely adding a public
   `vcov()`, Wald, profile, or `confint()` interface.
4. Add small deterministic tests, numerical-derivative checks, boundary and
   malformed-input tests, and an end-to-end tiny fit.
5. Freeze the method and ask for approval to run one large validation study on
   Totoro/DRAC. Only that frozen study can decide whether a public SE or Wald
   CI claim is defensible.

## What Was Accomplished Before This Handoff

- The narrow fixed-effect literal-Bernoulli × ordinary-NB2 eta point-estimate
  route and numeric `association = ~ x` extension are implemented.
- Developer-only full-refit-bootstrap infrastructure, independent DGP oracle,
  guarded runner, and retained-ledger schema exist on this local branch. The
  final focused local check passed 20 staged-bootstrap and 69 Bernoulli × NB2
  expectations.
- The over-scaled bootstrap campaign was stopped. Its 284 Totoro and 513 Fir
  outer-result shards are preserved as non-evidential provenance only.

## Current Working State

- Working: eta point estimates and the closed direct `biv_lognormal()` rho12
  inference route.
- In progress: a principled staged-eta SE implementation, beginning with
  equations and small tests.
- Not authorized: any public staged-eta SE/Wald/profile/`confint()` claim;
  any large compute before the method is frozen; aggregation of partial shards.

## Key Decisions and Rationale

The product decision is now made: staged eta needs an SE. The method decision
is not yet made beyond requiring a two-stage stacked-score/Godambe approach.
The former full-refit bootstrap remains a later comparator/validation tool,
not the primary development loop. Direct `biv_lognormal()` rho12 evidence is
not mathematical evidence for this frozen-margin estimator.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/staged-eta-bootstrap-hold` (current local tip) | yes | no | none | CARRIED-OVER |

The branch is intentionally local and unmerged. Do not push or merge merely
because the SE build begins; land only a reviewed, honest method slice.

## Files Created / Modified

The complete current inventory is in the preceding
`2026-07-25-codex-staged-eta-hold-handover.md`. The live files for this phase
are `R/associate-pairs.R`, `R/associate-pairs-bootstrap.R`, the staged-bootstrap
test, design 240, the two simulation runner tools, and the new handover.

## Blockers and Open Questions

- Exact sandwich block structure, especially cross-stage derivatives and how
  to represent the margin score numerically/analytically.
- Whether the resulting SE is stable near the finite `[-8, 8]` association
  boundary. Boundary-unresolved fits must remain unavailable.
- Which small frozen design is sufficient to compare sandwich and full-refit
  bootstrap before the large study.

## Gotchas

- Do not call `I_{alpha alpha | fitted margins}` an SE.
- Do not restart the previous 1.9-million-refit campaign or use partial shards.
- Use `R_PROFILE_USER=/dev/null Rscript --no-init-file` for local R commands.
- Run the project-local `symbolic-alignment`, `tmb-likelihood-review` where
  relevant, and Rose's after-task audit before any capability claim.

## Mission Control

| Lane | State | Claim boundary | Next by leverage |
| --- | --- | --- | --- |
| Direct `biv_lognormal()` rho12 | complete | exact direct fixed-effect rho12 only | leave closed |
| Staged eta point estimator | implemented | point estimate / diagnostic only | derive valid two-stage SE |
| Staged eta SE | active build | no public inference claim yet | small tests → freeze → one large validation |
| Former bootstrap campaign | stopped | provenance only | never aggregate or resume |

## How to Resume

Read `AGENTS.md`, this handover, design 240, the campaign-stop report, and the
previous hold handover. Then begin the symbolic derivation and small-test plan;
do not request or run compute.

```text
Rehydrate from docs/dev-log/handover/2026-07-25-codex-staged-eta-se-build-handover.md
and the AGENTS.md staged-eta SE-build snapshot. Implement the full two-stage
stacked-score/Godambe SE path with small tests first. Do not use the
conditional Hessian as an SE, run large compute, or claim an interval.
```
