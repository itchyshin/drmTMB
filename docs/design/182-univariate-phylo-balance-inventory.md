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

Under native TMB REML, only the mean-side phylogenetic Gaussian row is admitted.
Scale-side structured effects are intentionally rejected because the current
native restricted-likelihood validation restricts the likelihood for the
location fixed effects only.

## Current Rows

| Row | Meaning | Boundary |
| --- | --- | --- |
| `uni_mu_phylo_native_ml` | Native ML mean-side phylogenetic random intercept. | Point-fit support; no interval-coverage claim. |
| `uni_mu_phylo_native_reml` | Native exact-Gaussian REML for a mean-side phylogenetic field. | Mean-side only under native REML. |
| `uni_sigma_phylo_native_ml` | Native ML residual-scale phylogenetic random intercept. | Covered by the S023 focused test; no interval-coverage claim. |
| `uni_sigma_phylo_native_reml` | Tempting native REML residual-scale phylogenetic row. | Unsupported; S024 pins the early scale-side rejection. |
| `uni_mu_sigma_phylo_native_ml` | Native ML matched `mu` and `sigma` phylogenetic fields with a latent mean-scale correlation. | No coverage claim. |
| `uni_mu_sigma_phylo_native_reml` | Tempting native balanced REML row. | Unsupported; native REML rejects scale-side structured effects. |
| `uni_mu_sigma_phylo_julia_reml_bridge` | Experimental R-to-Julia Gaussian sigma-phylo REML bridge row. | No public bridge promotion without row-specific parity evidence. |
| `biv_q4_phylo_native_ml` | Native q4 ML diagnostic row for `mu1`, `mu2`, `sigma1`, and `sigma2`. | Diagnostic only; no calibrated q4 interval claim. |
| `biv_q4_phylo_native_reml` | Tempting native q4 REML row. | Unsupported; not HSquared AI-REML. |
| `biv_q4_phylo_julia_reml_bridge` | Experimental R-to-Julia q4 PLSM REML row. | Bridge evidence only; no native TMB REML claim. |

## Next Gate

S023 added the focused univariate `sigma`-only ML test. S024 added the
corresponding `sigma`-only native REML rejection test. S025 should expand
scale-side phylo diagnostics without turning them into interval-coverage claims.

This note does not draft or post an Ayumi reply.
