# C17-C1 local smoke: ordinary `coi` random intercept

This one-fit local smoke exercises the exact complete-response ML model

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id))
```

at the diagnostic `M = 16` rung and seed `2026081701`. It is not promotion
evidence. The formal claim requires all four frozen attempts at `M = 64`, with
the `M = 16` and `M = 32` rungs retained only as sample-information
diagnostics.

The smoke fit converged with `pdHess = TRUE`, maximum gradient
`4.65e-05`, an interior `coi` SD estimate `0.4268`, mode correlation `0.746`,
and the required per-group zero/one/interior support. The full-package estimate
and the boundary-only `lme4::glmer()` comparator differed by at most
`1.08e-05`. The fixed `coi` intercept error was `0.324` at this small
diagnostic rung, which is not a failure because the predeclared fixed-effect
recovery thresholds apply only at `M = 64`.

`provenance.tsv` records the runner digest, source-file blob hashes, loaded
namespace, command, and dirty-state path. The recorded Git SHA predates the
working-tree implementation, so this smoke is authenticated by the recorded
blob hashes and remains diagnostic-only. Formal evidence must run from a clean,
committed source SHA.

The retained historical C1 attempt at commit `653a8c915` remains separately
negative evidence: its `M = 32`, seeds `2026073601:2026073604` fixture passed
only three of four fits because seed `2026073603` collapsed to the SD boundary.
This smoke neither replaces nor erases that failure.
