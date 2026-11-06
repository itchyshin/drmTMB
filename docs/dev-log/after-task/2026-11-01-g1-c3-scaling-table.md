# After-task report: G1 condition C3, kernel scaling table

Date: 2026-11-01. Scope: docs and comments only. No R code behaviour changed
and no test was added or edited.

## What changed

- `docs/design/18-random-effect-scale-models.md`: new section "Kernel scaling
  by provider and engine" with the provider-by-engine table, the NB2 open
  parity row, and a statement that the existing 0.25 native-versus-Julia
  tolerance is a smoke check.
- `R/julia-simulate.R:11-15` and `R/methods.R:3175-3177` (and the rendered
  `man/simulate.drmTMB.Rd`): roxygen now says Julia Gamma animal simulation uses
  the supplied raw `A`. I read the simulator first. It already keeps the raw
  matrix (`R/julia-simulate.R:307-309`), so the 2026-10-24 decision is
  implemented there and the roxygen was stale, not the code.
- `.unlazy/general-sd-regression/GATES.md`: the 2026-10-22 Poisson line "Julia
  normalizes `A`" is marked superseded.
- `docs/dev-log/known-limitations.md`: NB2 Julia versus native kernel scaling
  recorded as an open parity row.

## Not done, by design

- No live Julia parity test with a non-unit-diagonal kernel. The review allowed
  stating that the 0.25 tolerance is a smoke check instead, and that is what
  is recorded.
- The NB2 mismatch is recorded, not fixed. It needs a Julia change or a
  refusal, and neither is in this slice.
- Julia rows for spatial, mesh and `phylo_interaction`, and the native
  `phylo_interaction` diagonal, are marked not reviewed.

## Caveats

Julia rows come from reading `../general-sd-julia` at head `70dbf564e`, not
from running it. The Julia Gamma relmat row (normalised) is inferred from
`normalize = kind !== :animal` at `gamma.jl:147`.

## Neighbouring checks

See the final report for test counts.

Counts (passed/failed/error/skipped), run in the private copy:
`test-structured-sd-nonunit-k-and-missing.R` 53/0/0/0;
`test-gamma-animal-q2-nonunit-kernel-parity.R` 0/0/0/1 and
`test-gamma-animal-q2-nonunit-kernel-simulation.R` 0/0/0/1 (both skip without a
live Julia).
