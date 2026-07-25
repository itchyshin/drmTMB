# Ultra Plan: general latent-normal association sandwich engine

```text
🎯 GOAL
PLATFORM: Codex. Deliver a private, reusable two-stage stacked-score/Godambe
engine for drmTMB's already admitted fixed-effect, ML, complete-pair
latent-normal association classes. HEADLINE: factor the existing
Bernoulli × ordinary-NB2 candidate into a common sandwich assembler plus
explicit family/pair adapters, without treating a shared architecture as shared
validation. IN PARALLEL: PR #844 coordination, symbolic adapter-contract
review, and deterministic oracle/test design. DEFER: public vcov(), Wald,
profile(), confint(), intervals, coverage, large simulations, the stopped
bootstrap grid, random effects, missingness, offsets/weights, and all direct
biv_lognormal() rho12 work. DISCIPLINE: merge and freeze the narrow reference
first; use deterministic/unit/integration checks while code changes; obtain
separate approval before every full-refit comparison; run any later compute on
Totoro/DRAC, never GitHub Actions.
```

## Context and product decision

`associate_pairs()` already supplies five fixed-effect, complete-pair
latent-normal association point-estimation classes: Gaussian × Bernoulli,
Gaussian × ordinary-NB2, Bernoulli × Bernoulli, Bernoulli × ordinary-NB2, and
ordinary-NB2 × ordinary-NB2.  All remain public point-estimation routes.  A
private Bernoulli × ordinary-NB2 candidate sandwich is now on draft PR #844;
it is a reference implementation, not a general or validated SE facility.

The common latent-normal construction makes a reusable internal engine
appropriate:

\[
u_i(\theta)=\{s_{1i}(\psi_1),s_{2i}(\psi_2),
s_{Ai}(\alpha;\psi_1,\psi_2)\},\qquad
\widehat{\operatorname{Var}}(\hat\theta)=
n^{-1}A^{-1}BA^{-T}.
\]

Here \(A\) and \(B\) are row averages.  The bread has zero upper-right
blocks because stage-one margins do not depend on association coefficients; its
lower-left blocks and the full paired-row empirical meat remain nonzero.  This
does **not** make all row scores identical: continuous Gaussian margins,
Bernoulli thresholds, and ordinary-NB2 CDF-jump intervals have distinct local
coordinates and numerical risks.

## Phase 0.25 — prior-work sweep receipt

| Surface | Evidence | Finding | Forced call |
| --- | --- | --- | --- |
| Repository state | `git status -sb`; `git log --oneline -8`; worktree/stash inventory; `branch_drift_check.sh` | `codex/staged-eta-godambe-se` is a clean draft-PR branch with two candidate commits; it must not silently become the general lane. | Preserve #844 as the narrow reference. |
| Open-PR coordination | GitHub PR #843 and #844 metadata, 2026-07-25 | Both lanes use a `docs/design/243-*` record. #843 is active and not yet mergeable; #844 is draft. | Wait for #843; then rebase #844, renumber its record to `244`, rerun focused tests, and review. |
| Existing implementation | `R/associate-pairs.R`; `R/associate-pairs-sandwich.R`; staged sandwich tests | Five point-estimation pair classes exist; only Bernoulli × NB2 has a candidate sandwich. | Build one assembler with explicit adapters. |
| Sisters | Targeted `rg` across DRM.jl, GLLVM.jl, and gllvmTMB | No reusable frozen-margin Gaussian-copula sandwich implementation found. | Build the genuine gap; do not copy unrelated covariance machinery. |
| Brain | `search_notes(search_all_projects = TRUE, query = "staged eta association sandwich normal copula general uncertainty Arc 6")` | No contrary decision or existing general implementation found. | Continue as a bounded architecture arc. |

**Verdict:** build the gap in a fresh lane only after the narrow reference has
been resolved.  No novelty claim is made, so a literature sweep is not a gate
for this engineering plan.

## Architecture contract

The private engine owns:

- exact frozen-input/provenance, row-order, response-side, and association-design checks;
- stable unique parameter labels, block assembly, row-average bread and full meat;
- conditioning/symmetry diagnostics, `unavailable` failure semantics, and eta
  delta transformation;
- no attachment of a covariance or SE to the public association object.

Each adapter owns its margin score/bread blocks, ordered local-link layout, row
log-density or log-mass, and mixed association/margin derivatives.  A common
five-point derivative plus half-step stability service may be reused, but each
row kernel needs an independent oracle and pair-specific failure tests.

## Slice plan

| Slice | Member / model / dispatch | Time | Output and dependency |
| --- | --- | ---: | --- |
| RECON + PR coordination | Luna / low / tiered CLI | 0.5 day | PR #843/#844 status and post-merge rebase/renumber receipt. Luna-suitable: bounded, read-only, mechanical. |
| S1: symbolic adapter contract | Noether / Terra high / native explicit | 0.5 day | Parameter order, links, score blocks, provenance contract, and left/right labels. Depends on #844 reference review. |
| S2: common-engine refactor | Gauss / Terra high / native explicit | 1 day | Private assembler plus regression-equivalent Bernoulli × NB2 adapter. Depends on S1. |
| S3a: Gaussian × Bernoulli | Gauss / Terra high / native explicit | 0.5–1 day | Continuous–binary adapter and independent oracle. Depends on S2. |
| S3b: Gaussian × NB2 | Gauss / Terra high / native explicit | 0.5–1 day | Continuous–discrete adapter and tail-safe tests. Depends on S3a. |
| S3c: Bernoulli × Bernoulli | Gauss / Terra high / native explicit | 0.5–1 day | Repeated-family side-label adapter and oracle. Depends on S2; parallel with S3a only if file ownership is separated. |
| S3d: NB2 × NB2 | Gauss / Terra high / native explicit | 1–2 days | Two-interval adapter and strict tail/boundary tests. Depends on S3b and S3c. |
| S4: deterministic integration matrix | Curie / Terra medium / native explicit | 1 day | Orientation/order, naming, rank, factorization, boundary, and fail-closed tests. Depends on S2–S3d. |
| S5: claims and freeze document | Rose / Terra medium / native explicit | 0.5 day | Updated design and no-public-inference fence. Depends on S1 and S4. |
| FREEZE REVIEW | Fisher + Noether + Rose / Terra high | 0.5 day | Exact engine/spec/fixtures/tolerances frozen; separate approval required for any validation. |
| MECHANICAL VERIFY | Luna / low / tiered CLI | 0.25 day | Name/dimension/ledger/direct-rho separation check. Luna-suitable: bounded, read-only. |
| RECONCILE | Melissa / Terra medium / native explicit | 0.25 day | `docs/dev-log/plan-actual/` material plan-versus-actual record. |

**Fan-out:** at most six new children before the freeze checkpoint; no Sol
child is expected unless the symbolic review finds a genuine derivation impasse.
**Estimate:** about one focused implementation week after #844 is resolved;
the general engine and its deterministic checks fit a fresh implementation
session plus a handover.  Validation is a later, separately approved campaign.

## Test and validation gates

1. Refactor Bernoulli × NB2 without changing its candidate results or failure paths.
2. For every adapter, verify analytic marginal scores/bread and association/mixed
   derivatives against an independent numerical oracle and step ladder.
3. Require response-order invariance, side-specific labels for repeated families,
   eta-zero factorization, fixed-seed end-to-end fits, and `unavailable` results
   for malformed, incomplete, boundary, derivative-unstable, and rank-deficient inputs.
4. Keep `vcov()`, `profile()`, `confint()`, Wald output, interval wording, and
   public-SE language unavailable throughout.
5. Freeze code, fixtures, derivations, tolerances, and failure semantics before
   requesting separate approval for any full-refit comparison.
6. Later validation samples mechanisms, but never promotes an untested pair:
   Bernoulli × NB2 first; then Gaussian × Bernoulli and NB2 × NB2 as separate
   continuous–binary and discrete–discrete pilots; remaining classes require
   their own named admission.

## Decisions locked

- Scope is fixed-effect ML, unit-weight, no-offset, complete-pair association
  fits under the existing latent-normal kernel only.
- The general product is a developer diagnostic engine, not a public inference API.
- Direct `biv_lognormal()` `rho12` is exact joint-likelihood work and cannot
  validate staged eta or any adapter.
- The old 24 × 200 × 399 bootstrap campaign remains stopped; partial shards
  remain provenance only.
- Compute is post-freeze only, requires separate approval, and belongs on
  Totoro/DRAC rather than GitHub Actions.

## Approval boundary

Approval authorizes PR #844 coordination, a fresh general-engine lane, private
implementation, documentation, and deterministic/unit/integration tests only.
It does not authorize resampling, a pilot, Totoro/DRAC work, coverage, public
SEs, intervals, or a merge of either PR.
