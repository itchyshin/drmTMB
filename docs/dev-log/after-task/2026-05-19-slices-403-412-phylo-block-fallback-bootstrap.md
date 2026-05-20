# After-Task Report: Slices 403-412 Phylogenetic Block-Diagonal Fallback

## Active Perspectives

Ada integrated the parser, likelihood, diagnostics, and evidence. Boole checked
that the grammar distinguishes full q4 from two-q2 block-diagonal phylogenetic
syntax. Gauss and Noether reviewed the covariance representation. Fisher and
Curie checked the boundary behavior, tests, and bootstrap interpretation.
Grace kept the bootstrap capped at 10 cores. Pat and Rose checked that the
docs do not oversell the fallback as clean inference.

## Implemented

- Added a fitted block-diagonal phylogenetic q4 mode for bivariate Gaussian
  location-scale models.
- Kept the existing full q4 syntax unchanged: one label across `mu1`, `mu2`,
  `sigma1`, and `sigma2` still estimates six phylogenetic correlations.
- Added the fallback syntax: one label across `mu1`/`mu2` and another label
  across `sigma1`/`sigma2` estimates two independent q2 tree blocks.
- Updated `corpairs()`, `summary(fit)$covariance`, `sdpars`, `corpars`, and
  `profile_targets()` so the fallback reports two direct tanh correlation
  targets rather than six derived unstructured correlations.
- Extended the Ayumi bootstrap prototype to target `PV2_phylo_fallback` and
  clamp requested workers to at most 10.

## Evidence

Targeted tests passed:

```sh
Rscript -e "devtools::test(filter = '^phylo-gaussian$')"
Rscript -e "devtools::test(filter = '^phylo-utils$')"
Rscript -e "devtools::test(filter = '^profile-targets$')"
```

The real Mass + Beak fallback fit no longer aborts. It ran on all 6,196
species and returned logLik -4220.555, AIC 8499.111, residual `rho12 = -0.720`,
phylogenetic `mu1`-`mu2 = -0.750`, and phylogenetic
`sigma1`-`sigma2 = -0.999999`. It still had convergence 1 and `pdHess = FALSE`.

The 10-core bootstrap smoke (`B = 10`) completed all refits but every refit
kept convergence code 1. The scale-scale phylogenetic correlation stayed
essentially at `-1` in every replicate.

## Interpretation

The implementation gap is closed: the prereg block-diagonal fallback is now a
real fitted model path. The scientific interpretation gap remains open for
Ayumi Mass + Beak. The fallback is a useful diagnostic and stress test, but the
scale phylogenetic block is too close to the boundary to use as a clean
uncertainty target today.

## Follow-Up

- Keep `PV2_locphylo` as the clean all-species Mass + Beak example.
- Treat full q4 and block-diagonal q4 Mass + Beak fits as diagnostic ledger
  entries until profiles, simplified scale structures, or regularized starts
  give a defensible optimum.
- Promote bootstrap/profile infrastructure only with worker caps, per-replicate
  convergence diagnostics, and explicit interval provenance.
