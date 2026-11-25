# Plan: Julia feature work to close refused parity rows (draft, not started)

Reader: Shinichi, deciding whether and in what order to spend Julia implementation time.
Outcome: each row below moves from "Julia refuses" to a passing Julia test plus a bridge fit that agrees with R, or is recorded as a permanent, documented non-goal.
Status: nothing here is implemented. No DRModels.jl repository changes were made.

## What the code already tells us

Refusals live in per-family files, not one shared gate (`src/gamma.jl:618`, `src/poisson.jl:549,619`, `src/skewnormal.jl:113`, `src/gaussian_lss.jl:149,1001`). Gamma and Binomial already carry a two-SD animal q2 path, so Poisson and NB2 can copy it. Gaussian is different: its sd() route is intercept-only by design, so q2 there is a new route, not a copy.

## Ranked work (cheapest first; estimates are guesses from file size, not measured)

| # | Work | Template to copy | Guess | Main risk |
| --- | --- | --- | --- | --- |
| 1 | Poisson animal q2, two coefficient SDs | `test_gamma_animal_intercept_slope_sd.jl`, Binomial q2 | 0.5 to 1 day | Poisson file has a single-SD assumption in its parser |
| 2 | NB2 animal q2, two coefficient SDs | same, plus NB2 sigma handling | 1 day | NB2 dispersion and q2 identifiability |
| 3 | Poisson and NB2 relmat q2 | step 1 and 2 with relmat kernel | 1 day after 1 and 2 | kernel scaling convention |
| 4 | Gaussian structured q2 (animal, relmat) | none; new route in `gaussian_lss.jl` | 3 to 5 days | sd() is intercept-only by design |
| 5 | Gaussian ordinary q3 and q4 | none | 1 to 2 weeks | block dimension, optimiser cost |
| 6 | mu plus sigma joint SDs, Gaussian structured sigma | none | 1 to 2 weeks | the two refusals are deliberate (identifiability) |

Rows 5 and 6 should first get a go or no-go decision from you, because the refusals look intentional.

## Gates before any step

1. Check the R side first. Several of these shapes may also be unsupported or only point-fit in R, in which case parity means "both refuse", not new Julia code. Read `docs/dev-log/known-limitations.md` for each shape before writing Julia.
2. Work happens in a fresh DRModels.jl branch off its main, not the `ba502d9d7` detached worktree. Pushing it is outward-facing: ask before the first push.
3. Each step ships a passing Julia test, then an R-to-Julia bridge fit with a stated tolerance. Neither alone counts as parity.
4. Per D-287, state a time estimate before any simulation or fit run; anything over 3 hours needs a pre-run test and your approval.
5. Only after a step passes do `tools/write-parity-matrix.R` verdicts change, in a separate reviewed PR.

## Outside judge

For each step, run the R implementation and the new Julia implementation on the same simulated data and compare coefficients and SD-regression coefficients against a fixed tolerance written down beforehand. A step that passes only its own Julia oracle is not done.
