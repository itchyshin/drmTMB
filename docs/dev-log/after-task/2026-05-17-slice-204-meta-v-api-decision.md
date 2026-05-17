# Slice 204 Meta-V API Decision

## Goal

Decide the public spelling for the future additive known-covariance marker
before implementing an alias or rename.

## Decision

Use `meta_V(V = V)` as the preferred future public spelling for additive known
sampling variance or covariance. Do not use a positional response or value
argument such as `meta_V(value, V = V)`, because the response is already on the
left-hand side of the model formula. Keep `meta_known_V(V = V)` as a
compatibility alias after the rename, not as a second likelihood path.

`V` should accept the same additive inputs as the current `meta_known_V(V = V)`
route: a column, numeric vector, diagonal matrix, block-diagonal matrix, or
dense matrix after model-row filtering.

The proportional branch remains design-only:

```r
meta_V(w = w, scale = "proportional")
```

It is not ordinary likelihood weighting and should not be implemented as a
wrapper around top-level `weights =`.

## What Changed

- Updated the meta-analysis design note to record the Slice 204 decision.
- Updated the meta-analysis tutorial's future-design snippet from
  `meta_V(value, V = V)` to `meta_V(V = V)`.
- Marked Slice 204 locally done in the roadmap return block.
- Updated NEWS and the check log.

## Role Notes

- Boole made the formula grammar reader-centred: the response stays on the
  left-hand side, so `meta_V()` should not repeat it.
- Ada kept this as a decision slice before implementation.
- Fisher kept the additive known-`V` path separate from proportional
  sampling-variance models and top-level likelihood weights.
- Pat checked that the tutorial wording tells users what to write today:
  `meta_known_V(V = V)` until the alias exists.
- Grace required pkgdown validation because the tutorial and design docs
  changed.
- Rose checked that this slice does not claim `meta_V()` is implemented yet.

## Remaining Boundary

This slice does not implement `meta_V()`, deprecate `meta_known_V()`, or add the
proportional sampling-variance likelihood. It only fixes the public API
decision before implementation.
