# Phase 6c Bivariate Slope-Only Evidence Gate

This note closes the #440 gate for the first bivariate Gaussian random-slope
surface before the larger #446 power, accuracy, and coverage plan. The reader is
a future `drmTMB` developer deciding whether the matching `mu1`/`mu2` slope-only
row is ready for broad simulation.

Supersession note: matching q=4 and q=6 `mu1`/`mu2` location blocks now have
their own smoke artifact routes. This note remains the artifact gate for the
narrower #440 slope-only lane.

## Gate Result

The `biv_gaussian_mu_slope` lane is artifact-ready and held from recovery,
coverage, and power claims.

The fitted model surface is deliberately narrow:

```r
bf(
  mu1 = y1 ~ x + (0 + x | p | id),
  mu2 = y2 ~ x + (0 + x | p | id),
  sigma1 = ~1,
  sigma2 = ~1,
  rho12 = ~1
)
```

This estimates two ordinary group-level slope SDs and one ordinary group-level
slope-slope correlation between the two response-specific slopes. It does not
describe the later q4/q6 location smoke routes, a residual-scale slope block, a
random effect in residual `rho12`, or the first q8 diagnostic all-endpoint
artifact lane.

## Evidence Table

| Requirement | Current evidence | Gate decision |
| --- | --- | --- |
| Fitted slope-only route | `tests/testthat/test-biv-gaussian.R` fits matching `(0 + x | p | id)` in `mu1` and `mu2` and checks convergence, slope SDs, the `cor(mu1:x,mu2:x | p | id)` row, the covariance-block registry, profile targets, and diagnostics. | Fitted first slice. |
| Extractor separation | `sdpars$mu`, `corpars$mu`, `corpairs()`, `summary(fit)$covariance`, `profile_targets()`, and `check_drm()` expose the slope-only row as a group-level `slope-slope` covariance. | Extractor-ready. |
| Residual `rho12` separation | `corpairs(fit, level = "group")` returns the group-level row, while `corpairs(fit, level = "residual")` and `rho12(fit)` report residual correlation. The Phase 18 summariser records `random_correlation` for `cor:mu:cor(mu1:x,mu2:x | p | id)` and `residual_rho12` for `rho12`. | Distinct enough for #440. |
| Simulation helper and artifact writer | `tests/testthat/test-phase18-biv-gaussian-mu-slope.R` covers the seeded DGP, smoke runner, aggregate table, replicate table, manifest, failure ledger, overwrite protection, and malformed-input errors. | Artifact-ready. |
| Actions routing | `.github/workflows/phase18-simulation-grid.yaml` includes the manual-only `biv_gaussian_mu_slope` task, and `inst/sim/registry/phase18_structured_workflow_registry.csv` maps `bivariate_gaussian_slope_only` to that task. | Dispatch-ready, manual-only. |
| Pilot artifact | Manual run `26689587073` produced a `biv_gaussian_mu_slope` artifact with two manifest rows marked `ok`, 20 converged replicate-summary rows, `pdHess = TRUE`, zero warnings, and an empty failure ledger. | Smoke artifact only; not coverage or power. |

## Still Closed

The gate does not promote neighbouring endpoints. These remain planned or
unsupported until separate code, tests, and evidence exist:

- q > 2 bivariate location recovery and coverage claims;
- broader same-response location-scale slope covariance beyond the named q2
  source-tested slice;
- residual-scale slope blocks in `sigma1` or `sigma2` beyond the named q2
  scale-scale slice;
- random effects or latent covariance in residual `rho12`;
- p8 endpoint blocks and q8 variants beyond the first ordinary diagnostic lane;
- predictor-dependent slope `corpair()` regressions;
- mixed-response bivariate random-slope models.

## Follow-Up Routing

No new extractor, simulation-runner, or Actions-routing issue is needed for
#440. The remaining evidence gap is intentional: #446 owns the recovery,
accuracy, coverage, power, convergence-rate, and reporting plan for this lane,
and #59 owns the broader Phase 18 simulation programme. The broad model-design
neighbours remain under #5, #33, and #128.
