# Gamma tree two-field SD contract

Independent u_k ~ N(0,K), b_gk=exp(W_gk alpha_k)u_gk, covariance D_k K D_k. K is shared ancestry divided by tree height, preserving existing ultrametric-tree correlation scaling. A hand-built balanced64-tip binary tree has five internal edges .1 and terminal1.5, height2. Independent expected K has diagonal1 and offdiagonal .1 times common binary-prefix depth divided by2. The Gamma mean is exp(X beta+b_0+x*b_1), shape=sigma^-2.

| Symbol | Formula | DGP | Extractor | Truth |
|---|---|---|---|---|
| beta | y~x | .2+.3*x | coef(mu) | .2,.3 |
| alpha0 | sd(id,level="phylogenetic",coef="(Intercept)")~z0 | exp(log(.5)+.5*z0)*u0 | coef(sd_phylo intercept) | log(.5),.5 |
| alpha1 | sd(id,level="phylogenetic",coef="x")~z1 | exp(log(.4)-.5*z1)*u1 | coef(sd_phylo x) | log(.4),-.5 |
| K | phylo(1+x|id,tree=tree) | independent normalized shared ancestry | augmented-Q inverse tip block | height2 |
| sigma | sigma~1 | Gamma shape .35^-2 | coef(sigma) | log(.35) |

Seed2026102713,64tips x20 observations, distinct group-constant binary SD predictors and varying within-tip x. Predeclared single-seed SD-slope error<.4; absolute dense Gamma Laplace NLL/eta/constant-base/reordered-tree differences<1e-4; latent gradient<1e-5; score/Hessian finite differences. Observed-tip covariance is inverted after subsetting, never the observed augmented precision block. Internal nodes integrated by dense-tip oracle; unused-tip test assembly/extraction only. Preserve existing q1 and other families through Gamma-only opt-in. No labels,multiple slopes,extra random effects,sigma tree,missing-data,new-data,coverage or liveJulia claim.

Estimates: red parser15s, focused100s, Gamma neighbors150s, example25s; stop/re-report overrun. OneBLAS/OMP thread per process; no rebuild expected.
