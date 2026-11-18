# Beta coordinate-spatial two-field SD contract

Independent u_k ~ N(0,K), b_k=D_k u_k, D_k=diag(exp(W_k alpha_k)), covariance D_k K D_k. The coordinate kernel is independently calculated as exp(-distance/median_positive_unordered_distance)+1e-6 I. Range is fixed by the existing coordinate policy, not estimated; no diagonal normalization. Mean is eps+(1-2*eps)*plogis(X beta+b0+x*b1), eps=1e-12; Beta precision phi=sigma^-2.

| Symbol | Formula | DGP | Extractor | Truth |
|---|---|---|---|---|
| beta | y~x | .2+.3*x | coef(mu) | .2,.3 |
| alpha0 | sd(id,level="spatial",coef="(Intercept)")~z0 | exp(log(.5)+.5*z0)u0 | coef(sd_spatial intercept) | log(.5),.5 |
| alpha1 | sd(id,level="spatial",coef="x")~z1 | exp(log(.4)-.5*z1)u1 | coef(sd_spatial x) | log(.4),-.5 |
| K | spatial(1+x|id,coords=coords) | independent pairwise-distance covariance | inverse precision | diagonal1.000001 |
| sigma | sigma~1 | Beta phi=.35^-2 | coef(sigma) | log(.35) |

Predeclared seed2026102803,64sites on8x8grid x20 observations. Group-constant binary SD predictors and within-site varying x. SD-slope error<.4 (one-seed smoke); absolute dense Beta Laplace NLL/eta/reordering/constant-base differences<1e-4; latent gradient<1e-5; score/Hessian finite differences. No seed/tolerance/data-size adjustment after results. Coordinates and factor order independently permuted. No unused-site route, mesh, q1 incidental admission, labels, correlated/multiple slopes, extra random layers, sigma spatial, missing data, new-data prediction, coverage or live Julia claim.

Red estimate15s; focused100s; neighbors300s; example25s. One BLAS/OMP thread per process. No native rebuild expected. Stop/re-report any overrun.
