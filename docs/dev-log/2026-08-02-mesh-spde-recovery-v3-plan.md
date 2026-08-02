# Fixed-kappa mesh field-scale recovery V3 plan

## GOAL

```text
PLATFORM: Codex. Resolve issue #881 only if a fresh current-source Totoro
campaign earns point-fit recovery for the exact fixed-kappa Gaussian mu
intercept cell. Preserve the retained V2 n=64 failure as a boundary result;
predeclare n=128 and n=256 as the narrower deployment domain; use new seeds,
50 attempts per rung, immutable provenance, all-attempt denominators, and
Monte Carlo uncertainty around the recovery metrics. Do not edit the article,
change C++, estimate range, or claim intervals or coverage in this slice.
```

## Prior-work sweep and reconciliation

The live lane is PR #893 on `codex/drmtmb-spatial-mesh`; issue #881 is its
recovery acceptance gate. The V2 receipt retained 150/150 fits and failed at
`n=64` because one cleanly optimized estimate reached the near-zero boundary.
The `n=128` and `n=256` rungs passed. Repeating the failed seed with multiple
starts on Totoro returned the same boundary optimum, so post-hoc seed removal
or optimizer tuning is retracted. The independent dense marginal-likelihood
comparator and paired mesh-resolution check remain valid controls. gllvmTMB
issue #904 tracks the sibling package's separate absolute SPDE field-scale
evidence gap; it is not a comparator dependency for this gate.

## Frozen capability and estimand

The fitted model is exactly

\[
y = X\beta + A_{st}\omega + \epsilon, \qquad
\omega \sim N\{0, s^2 Q(\kappa_0)^{-1}\}, \qquad
\epsilon \sim N(0, \sigma^2 I),
\]

where `kappa = 5e-5`, `s_truth = 1e-4`, `sigma = 0.25`, locations are uniform
in a 100-km square, and the existing mesh recipe is frozen. The estimand is the
raw GMRF covariance-scale multiplier `s`, not a projected marginal standard
deviation and not range. `n=128` and `n=256` are exact tested design rungs, not
a universal sample-size guarantee because mesh vertex count changes with the
frozen recipe.

## Promotion gate

Each rung must retain exactly 50 attempts. All 50 must have a finite positive
estimate, optimizer convergence code zero, `pdHess = TRUE`, finite objective,
and maximum absolute gradient at most `1e-3`. No estimate may fall below five
percent of `s_truth`. Absolute relative bias must be at most 0.15 and log-scale
RMSE at most 0.30. In addition, the two-sided 95% Monte Carlo interval for bias
must remain within `[-0.15, 0.15]`, and the upper 95% Monte Carlo bound for
RMSE must remain below 0.30. Any missing value, incomplete receipt, overwritten
output directory, dirty source tree, seed overlap, or uncertainty-boundary
overlap yields `BLOCKED_POINT_RECOVERY_GATE`.

## Execution and claim boundary

Run a two-attempt local smoke only to test plumbing. Run the 100-fit promotion
campaign on Totoro, not GitHub Actions. If both rungs pass, issue #881 may close
at `point_fit_recovery` for this exact fixed-domain design and the package may
document that earned boundary. Confidence intervals, coverage, range, slopes,
non-Gaussian mesh models, anisotropy, barriers, bivariate fields, replicated
fields, and spatiotemporal fields remain deferred. The spatial-models article
is frozen until this decision is complete; a later interval-calibration arc is
required before drawing mesh confidence intervals.

## Review disposition

Fisher gave conditional GO with all-attempt denominators, Monte Carlo
uncertainty, exact-domain wording, and interval deferral. Curie gave conditional
GO after requiring a disjoint seed ledger, clean-tree/source authentication,
immutable output, dependency and DLL checksums, heartbeats, and fail-closed
aggregation. Those conditions are implemented in the V3 helper and runner.

