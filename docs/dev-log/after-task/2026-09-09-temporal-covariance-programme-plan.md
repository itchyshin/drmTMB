# Temporal covariance programme planning closeout

## 1. Goal

Create a reviewable Ultra Plan and Unlazy programme ledger for temporal covariance in
drmTMB through the six-part roadmap, after the completed AR1/OU work and the separately
planned phylogenetic-stable-plus-independent-OU slice.

## 2. Implemented

Planning artifacts only: the master plan, a 19-gate Unlazy ledger and a portable R
planning-ledger checker. No Toeplitz, heterogeneous, seasonal, random-walk, ARMA or
Matérn implementation was started.

## 3a. Decisions and Rejected Alternatives

Homogeneous Toeplitz is the next temporal implementation after the phylogenetic-OU
slice. Heterogeneous AR1 and heterogeneous Toeplitz are separate later arcs because
occasion-specific process SDs change the scientific model and raise information demands.
Item 6 is a decision map. ARMA is reachable, but only ARMA(1,1) is proposed for a future
scientifically justified regular-time arc; arbitrary order selection is excluded.

## 4. Files Touched

- `docs/dev-log/plans/2026-09-09-temporal-covariance-programme/PLAN.md`
- `docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/GATES.md`
- `docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

The runner self-test passed one malformed-ledger negative control. All 16 runnable
planning/contract checks returned their success tokens, including G18 in reverify mode.
The Unlazy parser found 19 gates: 16 runnable and three manual. G17 is met with an
independent mathematical approval and reader repair/review; the other 18 remain pending.
`git diff --check` passed. These checks validate plan and ledger integrity, not a temporal
covariance implementation.

## 6. Tests of the Tests

G1 removes the G0 gate from a copied ledger and requires the checker to reject the
malformed IDs. The self-test also builds a valid miniature ledger and then removes its
first gate. Future model arcs must add dense-oracle and mutation tests; the programme
checker deliberately cannot make an implementation claim.

## 7a. Issue Ledger

No external issue, message, push, merge, release or campaign action occurred. Existing
issue #1302 remains the separate tracker for phylogenetic-stable-plus-independent-OU.

## 8. Consistency Audit

The plan keeps ordinary stable intercepts, temporal covariance, phylogenetic stable
covariance, spatial covariance and bivariate residual correlation separate. It records
the completed AR1/OU provider as a predecessor, not as validation for Toeplitz or ARMA.
Toeplitz needs a positive-definite correlation map; ARMA needs a state/innovation
contract and regular time. Both boundaries are explicit in the ledger.

## 9. What Did Not Go Smoothly

The local basic-memory command could not change permissions in its configuration
directory under the sandbox. The plan therefore relies only on previously available
durable context and direct repository/source evidence; it does not elevate a failed
retrieval into evidence. The initial path lease attempt used the wrong multi-path syntax;
the corrected, path-specific lease was granted before planning artifacts were written.
Reader review found that ARMA could be mistaken for a shared population shock. The plan
now states that its first form is one independent ARMA process per id, with shared shocks
as a separate future model; the reviewer accepted the repair.

## 10. Known Residuals

All programme gates remain pending until user approval. The source map needs a bounded
NotebookLM distillation at P0. Every model after the completed AR1/OU provider needs its
own source pin, formula plan, executable implementation ledger, review and evidence.
No campaign, inference, package-check or public-capability claim is made here.

The after-task validator accepted this report's structure, then returned nonzero because
this planning checkout retains the older, intentionally pending `.unlazy/temporal-ar1/`
execution ledger. That is foreign unfinished scope on this branch, not a failed programme
check. The new programme ledger independently parsed as 19 gates with G17 reviewed and
18 pending; its runner passed all 16 runnable planning-contract checks.

## 11. Team Learning

A useful temporal roadmap distinguishes models by the mechanism they represent and the
data they require. It should not grow by copying a comparator's option list. In
particular, a free Toeplitz lag vector needs a positive-definite map, and ARMA brings an
innovation process as well as correlation.

## 12. Cross-Product Coverage

This task covers a plan for Gaussian temporal covariance sequencing and its acceptance
discipline. It does not cover implemented models beyond the existing AR1/OU provider,
the planned phylogeny-plus-OU slice, any non-Gaussian/bivariate/forecasting extension,
temporal slopes, generic covariance syntax, an ARMA fit, temporal Matérn, seasonality,
random walks, spatiotemporal fields, remote computation, deployment or release.
