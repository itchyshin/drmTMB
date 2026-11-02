# After-task report: G1 condition C2, selector contract

Date: 2026-11-01. Lane: general-sd-regression. Source condition: section 1 and
condition C2 of `docs/dev-log/general-sd-regression/g1-joint-contract-review-20261101.md`.

## Goal

Write the selector and key contract for `sd(group, level =, dpar =, coef =, block =)`,
test it, and make `predict(dpar = )` match SD keys exactly.

## What changed

- `docs/design/18-random-effect-scale-models.md`: new section "Selector and key
  contract". It states that the key is the user's spelling (two spellings of one
  coefficient are two keys, documented rather than merged), that selector call
  order does not change the key, that structured keys drop selectors, the
  `level = "group"` alias rule (internal label only, refused publicly), and that
  `block` is reserved.
- `R/methods.R` (`predict.drmTMB`): `match.arg(dpar, names(object$coefficients))`
  replaced by an exact membership check that aborts with the available names.
  Before the change, `predict(f, dpar = "sd(id")` silently resolved to `sd(id)`
  (probed on a Gaussian fit).
- `tests/testthat/test-sd-selector-contract.R` (new, 29 expectations).

## Decisions

- Key policy: documented as two keys, not canonicalised. Canonicalising would
  rename existing fitted coefficients and break saved targets; the review allows
  either outcome if recorded.
- `level = "group"`: recorded as non-public; no code change.
- `block`: recorded as reserved; no code change.

## Not done, known limits

- Review risk 5 (the "Add an ordinary (1 | group) term" message does not mention
  `level =`) is not part of C2 and is unchanged.
- `coef.drmTMB()` (`R/methods.R`, `match.arg` on `dpar`) and the `fixef` helper
  at the second `match.arg` site still partial-match. Out of scope for C2; recorded
  in the design section.
- The key still depends on the number of formulas for the structured q2 routes.

## Verification

See the commands and counts in the hand-off message. No tolerance was loosened and
no assertion was deleted. The new test file passed on its first run.
