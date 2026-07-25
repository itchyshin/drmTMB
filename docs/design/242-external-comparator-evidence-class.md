# External-Comparator Evidence: A Class, Not A Tier

This note records a ledger-policy decision made on 2026-07-25. Its reader is the
contributor who wants to record that a `drmTMB` cell agrees with an established package,
and the maintainer deciding what such agreement is allowed to license.

## The problem

`tests/testthat/test-comparators.R` is 1,245 lines of agreement tests against `lme4`,
`glmmTMB`, `metafor`, `MASS::glm.nb` and base `glm`, at tolerances from 1e-4 to 1e-6.
Before this change, exactly **one** implemented cell cited a comparator anywhere in the
ledger. The validation was real and structurally invisible: there was no field a
comparator result could be recorded in, so it was recorded nowhere.

`mc-0260`, the core Gaussian fixed-effect location cell, states the mechanism plainly in
its own boundary: it is "extensively tested across dozens of files but no q-series board
cell exists for a pure fixed-effect (no RE) model, so tier is kept conservative per the
never-claim-supported-without-a-board-cell rule."

## The decision

**Comparator agreement is recorded as `evidence_class = "external_comparator"` in
`capability-ledger/evidence.tsv`. It is NOT a new `evidence_tier`.**

The originating plan proposed a `parity_validated` *tier*. That was rejected during
review, for a reason worth keeping:

`evidence_tier` is a single **ordered** scale of inferential strength — point recovery,
then interval feasible, then coverage-verified. `TIER_ORDER` encodes that order and
`_evidence_summary()` picks each family's highest tier from it. Comparator agreement is
**orthogonal** to that scale. It speaks to implementation correctness and says nothing
about interval calibration. Two facts make the orthogonality concrete: `mc-0227` and
`mc-0242` are `inference_ready_with_caveats` with **no** comparator at all, while
`mc-0260` has near-exact comparator agreement and sits at `point_fit_recovery`. Inserting
a parity value into the ordered list would force a false comparison and would silently
rewrite the family map for every cell carrying it.

`evidence.tsv` already had everything needed and cost no schema migration: it is a
one-to-many join on `cell_id`, and its `claim_boundary` field is exactly the mandatory
"what this does not cover" statement, already used in that style by existing rows.

## What agreement licenses, and what it does not

**Licensed.** That `drmTMB`'s likelihood and optimizer reach the same optimum as an
independent implementation of the same model, on the dataset tested.

**Not licensed.** Any interval, coverage, bias, recovery or small-sample calibration
claim. Every comparator test in the repo is single-seed and single-dataset, and none
asserts standard-error or confidence-interval equality across packages. Every
`external_comparator` row must say so in its own `claim_boundary`; a test enforces that
the words "interval", "coverage" and "single-seed" appear there.

**The governing constraint.** Agreement licenses the **overlap** region only, never the
**frontier**. Where `drmTMB` is genuinely novel — scale-side random effects, `sd()`
regression, bivariate LSS, phylogenetic structure on residual log-SD — no established
implementation exists to borrow credibility from, and that is precisely where `mc-0227`
and `mc-0242` found real small-sample bias. A design that blurs the two is
credibility-laundering.

Two mechanisms enforce this rather than leaving it to reviewer memory:

1. The annotation is keyed by `cell_id` and never aggregated. `family_map_rows()` buckets
   every row sharing a `family_route` — fixed, random, structured, phylogenetic, spatial
   and bivariate together — and reports one highest-evidence string per family. A
   family-level comparator badge would read as covering frontier routes with no
   comparator at all. A test asserts no comparator token reaches the family map.
2. Package detection scans `run_id` and `result` only, never `claim_boundary`, because
   the boundary is where a row says what it does *not* cover.

## Independence is not uniform

The rendered badge carries a strength, because the package name alone made three
different situations look identical.

- **strong** — a separate estimation engine. `lme4` and `metafor` share no code with
  `drmTMB`, so agreement is a genuine cross-implementation check.
- **weak** — `glmmTMB` is built on the same TMB/AD stack and outer optimizer as `drmTMB`,
  so agreement is a consistency check between related implementations.

A blank cell is not a deficiency. For structured, scale-side, bivariate and phylogenetic
routes there is usually **no comparator in existence**.

## Terminology

Two adjacent names already exist and mean different things. Do not conflate them.

- `parity_status` (`tools/validate-mission-control.py`) — DRM.jl-bridge / native-TMB
  numerical parity. Unrelated to external packages. This is why the class is **not**
  called `parity_*`.
- `external_comparator_status` (`docs/design/178-ai-reml-hsquared-transfer-gate.md`) — a
  comparator dependency is *planned but absent*. The `external_comparator` evidence class
  means the opposite: a comparator test **exists and passed**.

## What this decision does NOT do

- It promotes nothing. Recording comparator evidence never changes a cell's
  `evidence_tier`, and there is no rule by which it could.
- It does not cover the two remaining Arc A slices: no overlap-region sweep was run, and
  no user-facing vignette was written.
- It adds no comparator for any frontier route, because none exists.
