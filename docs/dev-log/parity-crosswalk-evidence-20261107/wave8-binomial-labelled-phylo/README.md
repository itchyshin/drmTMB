# Wave 8: Binomial labelled phylo(1 + x | p | g), R 0.8.1 vs DRM.jl (2026-11-08)

Question: does native drmTMB 0.8.1 really estimate the cross-coefficient correlation for the
labelled logit-Binomial phylo block, and does DRM.jl (branch claude/binomial-phylo-spatial-q2-20261108,
commit 2acddb5f1) agree?

Answer: yes to both. R prints no rho in `coef(fit)`, but the correlation is estimated: it is
`fit$corpars$phylo` (key `cor(mu:(Intercept),mu:x | p | g)`) and the parameter `eta_cor_phylo` in
`fit$opt$par` (rho = 0.999999 * tanh(eta_cor_phylo)); its SE is in `summary(fit$sdr, "fixed")`.

Design: 10 seeds, 64 tips (balanced binary ultrametric tree, `tree.nwk`, height 1.9), 30 Bernoulli
rows per tip (1920 rows), logit, ML, true rho 0.6, intercept SD ~ z0, slope SD ~ z1 (`gen.jl`,
StableRNG(20261108 + seed)). Same CSVs fed to both (`data/`). R: drmTMB 0.8.1 on Totoro (one thread,
own dir ~/drm_binfix_20261108, no engine = julia), `runR.R` (run with the CSVs beside it). Julia:
DRM.jl on Julia 1.10 on the Mac, `runJ.jl` (run from this folder). Parameter order identical:
beta_mu (2), sd intercept coefs (2), sd slope coefs (2), atanh rho.

Results (`agreement.csv`): R convergence code 0 on 10/10; Julia converged 10/10, 0 non-finite SEs,
0 boundary flags (|rho| > 0.99 or |SD coef| > 5).

| quantity | range over 10 seeds |
|---|---|
| loglik diff (Julia - R) | -8.3e-07 to +1.7e-07 |
| max absolute coefficient diff | 1.1e-05 to 7.7e-05 |
| max coefficient diff in R-SE units | 9e-05 to 3.7e-04 |
| rho diff | -2.9e-06 to +1.2e-05 |
| SE ratio Julia / R (all 7 parameters) | 1.0000 to 1.0002 |

No tuning was done to reach this. Timing: R 46-62 s per fit; Julia 0.4-0.8 s (first fit 14 s with
compilation). Scope: ten seeds at one design; no calibration or coverage claim.
