# Gamma coordinate-spatial two-field SD contract

Independent u_k ~ N(0,K), b_gk=exp(W_gk alpha_k)u_gk, Cov(b_k)=D_k K D_k. Distances are Euclidean between the two supplied coordinate columns. The established fixed range is the median of strictly positive unordered pairwise distances. K=exp(-distance/range)+1e-6 I, without diagonal normalization. No near-singularity fallback is invoked in this fixture. Mean=exp(X beta+b0+x*b1), Gamma shape=sigma^-2.

| Symbol | Formula | Independent DGP | Extractor | Truth |
|---|---|---|---|---|
| beta | y~x | .2+.3*x | coef(mu) | .2,.3 |
| alpha0 | sd(id,level="spatial",coef="(Intercept)")~z0 | exp(log(.5)+.5*z0)u0 | coef(sd_spatial intercept) | log(.5),.5 |
| alpha1 | sd(id,level="spatial",coef="x")~z1 | exp(log(.4)-.5*z1)u1 | coef(sd_spatial x) | log(.4),-.5 |
| K | spatial(1+x|id,coords=coords) | pairwise-distance covariance | inverse precision | diagonal1.000001 |
| sigma | sigma~1 | Gamma shape .35^-2 | coef(sigma) | log(.35) |

Predeclared seed2026102801,64sites on8x8grid x20 observations. Distinct group-level SD predictors, varying within-site x. Single-seed SD-slope errors<.4; absolute independent Laplace NLL/eta/reorder/constant-base differences<1e-4; latent gradient<1e-5 and derivative/Hessian finite differences. No seed or tolerance adjustment after results. Existing q1 and other-family boundaries preserved by Gamma-only opt-in. Coordinate rownames and factor levels are separately permuted. No extra unused-site coordinates accepted, no unseen-site claim.

Scope: native complete-data Gamma mu, one independent intercept+numeric slope, fixed-effect sigma, unit weights; no mesh, labels, multiple slopes, additional random layers, new-data prediction, uncertainty workflows, coverage or live Julia claim. Red estimate15s, focus100s, neighbors180s, example25s; stop/re-report overrun. One BLAS/OMP thread per process; no rebuild expected.
