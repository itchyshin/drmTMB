# Lane C Z7 — zero-one-beta phylogenetic sigma q1 local receipt

**Candidate:** `mc-0593`, q1 only. Point-fit recovery remains conditional on
the completion panel and ledger transition.

## Exact contract

```r
bf(y ~ x, sigma ~ phylo(1 | species, tree = tree), zoi ~ 1, coi ~ 1)
```

For one unlabelled intercept field, `b ~ N(0, tau_sigma^2 Q^-1)`,
`tau_sigma = exp(log_sd_phylo)`, and
`log(sigma_i) = X_sigma beta_sigma + b_species(i)`. The beta interior and atom
probabilities remain fixed-effect-only.

## Numerical evidence

Source SHA: `1ec79267e9f30ea123912e3ff52b0fc78478aaab`; run-3 MD5:
`d6873af8f320f76a899a95384af2b258`. The independent augmented-tree
precision/determinant/order oracle and AD-FD gradient test are in
`tests/testthat/test-zero-one-beta.R`.

All four run-3 seeds pass the frozen rule: convergence zero, `pdHess`, gradient
at most 0.01, inactive clamp, non-boundary SD, separate zero/one/interior
support, mode correlation above 0.45, and mean SD relative error 0.1270
(limit 0.40). The zero-truth-SD fit is diagnostic only.

## Runner provenance

Run 1 retains four tree-scope environment errors. Run 2's report-access error
is retained in the adjacent record. Run 3 reran all four frozen seeds after
only these mechanical repairs; no DGP, seeds, truth, or gate changed.

## Claim boundary

This is not interval, calibration, coverage, or inference evidence. It does
not change the Future-extension audit.
