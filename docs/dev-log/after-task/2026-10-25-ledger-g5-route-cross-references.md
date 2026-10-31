# Ledger: pin routes named by the G5 family-map rows

## Goal

Implement the owner decision on #1011 (25 Oct 2026): item 2 (route-name
cross-reference check) applies only to the G5 family-map rows, not to every
route named in a `claim_boundary`.

## Implemented

- `validate_route_cross_references(cells, evidence)` in
  `tools/capability_ledger.py`, called from `load_sources()`. The rows in scope
  are those with a `g5_policy_not_grounded` contract (`mr-beta`, `mr-tweedie`,
  `mr-skew-normal`, cell and evidence fields). A backticked name equal to
  another family route must have a `route_state` contract for that cell and
  field.
- `live-prose-contracts.tsv`: 12 new `route_state` rows pinning
  `mr-cumulative-logit-mu-x` (the `cumulative_logit` exclusion, #967) and
  `mp-beta-binomial-bernoulli` (the `beta_binomial` predictor-route
  disclaimer) for each of the three rows and their evidence fields.
- Ledger README documents the rule.

## Tests

`tools/tests/test_capability_ledger.py`: live ledger passes; an unpinned route
name fails; a dropped contract fails; promoting either referenced route fails
`validate_live_prose_contracts`. Four of these fail before the change.

## Not done

- Item 3 (keyed `excludes_routes` / `gate_policy` columns) needs its own design
  issue per the decision. The issue could not be opened from this lane.
- Items 1 and the rest of item 2 are out of scope by the decision.
