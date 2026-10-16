# After Task: sweep-oct16 lane t2, Gaussian location-scale simulation recovery

**Reader.** Whoever reads the 2026-10-16 sweep, and the maintainers deciding on the filed issues.
**Pins.** drmTMB `ca3ddefa5`, DRModels.jl `f71b29233`.
**Branch / PR.** `claude/intelligent-euler-h4b2is`, itchyshin/drmTMB#1549.
**Receipt.** `sweep-oct16/t2/RECEIPT_t2.md` holds the full tables, design and reproduce commands; this note only records what was done and what was learned.

## What was asked and what was run

The lane asked for parameter recovery of `mu = 1 + 0.5 x`, `log sigma = -0.5 + 0.4 z` over n ∈ {50, 200, 1000}, with and without a `(1 | g)` mean intercept (G = 20 and 50, sd 0.5), 500 reps per cell, in both engines. Pass bar:
- |relative bias| < 5% for n ≥ 200;
- Wald 95% coverage in [93%, 97%] for n ≥ 200;
- converged rate ≥ 99%.

Every dataset was generated once in R and fitted by both engines, so the comparison is paired. A further 2,000 reps per gate cell (seeds `+ 501..2500`) were run in both engines to separate Monte Carlo noise from real failures.

## Result in one paragraph

The engines are numerically the same model at n ≥ 200: |ΔlogLik| ≤ 2e-11, |Δestimate| ≤ 4e-10 and identical coverage indicators on 15,000 shared datasets. So the pass-bar verdicts are identical too.
- Bias passes everywhere.
- Coverage fails formally in 4 of 28 gate rows. Two of these, both σ-intercept rows at n = 1000, are Monte Carlo noise and vanish over 2,500 reps.
- Two are real z-Wald under-coverage at G = 20 (sd(g) 92.4%, mean intercept 92.6%), matching a χ²₁₉ limit almost exactly.
- The convergence bar fails only at n = 50: boundary labelling in DRModels.jl, and the all-singleton cell that drmTMB refuses by design.

## Findings filed

- DRModels.jl#969 (comment): at the sd(g) = 0 boundary, the vcov guard's pinv leaves a tiny positive variance. That gives a zero-width Wald interval and also breaks the profile interval, which reports an unbounded upper limit with `failed = 0`.
- DRModels.jl#1050 (comment): valid boundary MLEs are labelled not converged by the absolute gradient test, and the restart tie-break discards gradient-converged candidates.
- DRModels.jl#1114 (new): a bare `ArgumentError` on all-singleton groups; `gaussian_ranef.jl:612` missed the #968 fix.
- DRModels.jl#1059 (comment): collapsed residual scales are reported converged on all-singleton groups, with SEs understated by about 10^7 or that should be infinite.
- drmTMB#1558 (new): the ordinary `(1 | g)` SD and the mean intercept under-cover at G = 20; `small_sample_df` / `bias_correct` do not reach ordinary `(1 | g)` SDs.

## Lessons for the team

1. **A nominal seed above 2^31 − 1 cannot be passed to R.** `set.seed(20261016101)` errors. Future lane specs should either give seeds below `.Machine$integer.max` or state the mapping. This lane used `(seed) %% 2^31`.
2. **One 500-rep coverage verdict is noisy.** The [93%, 97%] band is ±2.06 Monte Carlo SEs at 500 reps, so about one chance failure is expected per 28 rows. Correlated cells (common random numbers) can fail together. A confirmatory replicate turned two formal failures into "noise" and two into "real" with a mechanism; budget one when a lane has a hard coverage bar.
3. **Paired engine comparison on identical files was the most informative single check.** It showed at once that every gate failure was a property of the procedure, not of either package.
4. **Every finding was adversarially re-derived before filing, and each needed corrections.** Examples: a mechanism stated too narrowly (pinv), a missed second cause (the restart tie-break), an incomplete fix history (#1054 also patched Student-t), and a ridge confused with a degenerate maximum. Posting first and correcting later would have put five partly wrong reports on the trackers.
5. **Issue bodies posted through the GitHub tool lose the trailing attribution footer; comments keep it.** Bodies were read back through the public API and diffed byte-for-byte.
