# Arc 9 plan — honest extractors for legacy Julia cross-family fits

Status: **APPROVED for execution by Shinichi, 2026-07-24.**

## GOAL

Repair issue [#806](https://github.com/itchyshin/drmTMB/issues/806): an existing
`drmTMB_julia_xfam` object must never make standard extractors silently return
`NULL`.  The repaired legacy bridge will expose only quantities whose meaning
can be reconstructed exactly in R, and will fail loudly for unavailable
cross-family covariance/inference.

This is a drmTMB-only compatibility arc.  It does not re-enable or promote new
Julia cross-family fitting, does not rename `rho_latent` to `rho12`, and does
not edit DRM.jl.

## Decision and boundary

The Julia helper currently serializes point estimates, log likelihood,
convergence, and fixed 95% `rho_latent` intervals, but not a named coefficient
covariance, Hessian, fitted values, residuals, or a parameter index map.  It is
therefore invalid to manufacture Wald uncertainty or claim full extractor
parity.

The implementation contract is:

- `fitted()` and stored `predict()` return per-axis response-scale means at
  latent `u = 0`.
- `residuals(type = "response")` returns per-axis observed-minus-fitted values;
  it is neither a Pearson, quantile, marginal, nor latent-posterior residual.
- `AIC`, `BIC`, `df.residual`, and `logLik(df = ...)` use the exact counted
  fitted parameter vector: `mu1`, `mu2`, non-empty `sigma1`/`sigma2`, and two
  latent loadings.
- `vcov()` and fixed-effect Wald summaries abort clearly, because no verified
  covariance payload exists.
- New-data predictions retain the current fixed-effect, `u = 0` contract and
  are tested against the stored training predictions.

## Slices and acceptance checks

1. **Contract and object reconstruction.** Add xfam-specific helpers/methods
   and fields, without relying on inherited `drmTMB_julia` fall-through.
   Check that no affected standard generic can return `NULL`.
2. **Pure-R test matrix.** Build realistic mocked bridge payloads through the
   constructor for Gaussian x Poisson and a dispersion-carrying pair.  Check
   exact links, names, dimensions, AIC/BIC identities, response residuals,
   explicit `vcov()` failure, and no accidental `rho12` claim.
3. **Pinned live bridge check.** Run an existing legacy cross-family Julia
   round-trip against a clean, pinned DRM.jl source when locally available.
   A skipped test is not closure evidence; record any environment blocker.
4. **Reader surface.** Document the legacy-xfam exception in generated
   prediction/reference text, NEWS, capability-and-limits, and the check log.
   Preserve the current halted/deferred wording.
5. **Closure.** Run focused tests, documentation generation, `R CMD check` in
   proportion to the result, independent review, after-task report, and open a
   draft PR. Merge only when GitHub checks are clean and no blocking feedback
   remains.

## Team concerns resolved

Fisher required an explicit covariance/index payload before any covariance or
Wald claim; this plan rejects synthetic covariance.  Rose required a
drmTMB-only repair because the available DRM.jl worktree is dirty and separately
owned; this plan does not modify it.  A later clean DRM.jl API arc may add a
named covariance payload if full parity is desired.

## Compute and ownership

This is API/documentation/test work, not a recovery or coverage campaign, so
Totoro/DRAC is not used.  Work occurs in
`/private/tmp/drmtmb-arc9-julia-xfam` on
`codex/julia-xfam-extractors`, based on `origin/main` at `988b2b38`.
