# Univariate Phylo Balance Inventory

This note banks S022 of the 100-slice finish run. It answers a narrow question:
which `phylo()` location and scale combinations are fitted, tested, or rejected
today, and under which estimator?

The machine-readable row source is
`docs/dev-log/dashboard/phylo-balance-inventory.tsv`.

## Main Distinction

Native TMB maximum likelihood and native TMB restricted maximum likelihood have
different support surfaces.

Under native TMB ML, the univariate Gaussian parser and likelihood can fit:

- `mu` only: `y ~ x + phylo(1 | species, tree = tree)`, `sigma ~ 1`
- `sigma` only: `y ~ x`, `sigma ~ phylo(1 | species, tree = tree)`
- matched `mu` and `sigma`: `phylo()` on both axes with the same source

Under native TMB REML, the tested mean-side, sigma-side, and matched
mean-plus-sigma phylogenetic Gaussian rows are admitted at different evidence
tiers. The mean-side q1 row has retained interval evidence. The sigma-only and
matched rows have point-fit/recovery evidence only and do not inherit that
interval or coverage authority.

## Current Rows

| Row | Meaning | Boundary |
| --- | --- | --- |
| `uni_mu_phylo_native_ml` | Native ML mean-side phylogenetic random intercept. | Point-fit support; no interval-coverage claim. |
| `uni_mu_phylo_native_reml` | Native exact-Gaussian REML for a mean-side phylogenetic field. | Row-specific retained interval evidence; no transfer to sigma-side rows. |
| `uni_sigma_phylo_native_ml` | Native ML residual-scale phylogenetic random intercept. | Covered by the S023 focused test; no interval-coverage claim. |
| `uni_sigma_phylo_native_reml` | Native REML residual-scale phylogenetic intercept. | Point-fit/recovery only; no interval reliability or coverage claim. |
| `uni_mu_sigma_phylo_native_ml` | Native ML matched `mu` and `sigma` phylogenetic fields with a latent mean-scale correlation. | No coverage claim. |
| `uni_mu_sigma_phylo_native_reml` | Native REML matched mean-plus-scale phylogenetic intercepts. | Point-fit/recovery only; no interval reliability or coverage claim. |
| `uni_mu_sigma_phylo_julia_reml_bridge` | Experimental R-to-Julia Gaussian sigma-phylo REML bridge row. | No public bridge promotion without row-specific parity evidence. |
| `biv_q4_phylo_native_ml` | Native q4 ML diagnostic row for `mu1`, `mu2`, `sigma1`, and `sigma2`. | Diagnostic only; no calibrated q4 interval claim. |
| `biv_q4_phylo_native_reml` | Native block-diagonal and dense q4 phylogenetic REML. | Recovery evidence only; no interval reliability or coverage, and not HSquared AI-REML. |
| `biv_q4_phylo_julia_reml_bridge` | Experimental R-to-Julia q4 PLSM REML row. | Bridge evidence only; native recovery is separate and does not establish parity. |

## Next Gate

The historical S023-S025 rejection plan is superseded by the implemented
native sigma-only, matched, q2, and q4 rows. The next gate is retained,
target-specific interval evidence; point or recovery admission must not be
turned into an interval-coverage claim.

This note does not draft or post an Ayumi reply.
