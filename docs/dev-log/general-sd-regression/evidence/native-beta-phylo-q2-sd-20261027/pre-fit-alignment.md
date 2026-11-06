# Beta phylogenetic two-field SD contract

Independent u_k ~ N(0,K), b_gk=exp(W_gk alpha_k)u_gk; Cov(b_k)=D_k K D_k. K is Brownian shared ancestry divided by tree height, preserving the existing tree correlation convention. The DGP uses a hand-specified balanced64-tip binary tree: five internal path edges .1 and terminal1.5, height2. K diagonal1 and offdiagonal .1 times common binary-prefix depth divided by2. No package covariance helper generates K.

| Symbol | Formula | DGP | Extractor | Truth |
|---|---|---|---|---|
| beta | y ~ x | .2+.3*x | coef(mu) | .2,.3 |
| alpha0 | sd(id,level="phylogenetic",coef="(Intercept)")~z0 | exp(log(.5)+.5*z0)u0 | coef(sd_phylo intercept) | log(.5),.5 |
| alpha1 | sd(id,level="phylogenetic",coef="x")~z1 | exp(log(.4)-.5*z1)u1 | coef(sd_phylo x) | log(.4),-.5 |
| K | phylo(1+x|id,tree=tree) | two independent K Gaussian draws | latent/scaled fields | normalized shared ancestry |
| sigma | sigma~1 | Beta phi=.35^-2 | coef(sigma) | log(.35) |

Seed2026102711,64 tips x20 observations, distinct binary SD predictors, varying within-tip x. Prior single-seed slope tolerance .4 and absolute NLL/eta/constant-base/reordered-tree equivalence1e-4 unchanged. Dense Beta derivative/oracle from preceding independently tested slice; observed-tip K inverted after subsetting, not observed augmented precision submatrix. Inverse augmented Q tip block must equal independent K. Internal nodes and an unused tip retain raw fields, scaled extraction NA without predictors (assembly-only unused-tip check).

Scope complete native Beta mu, independent unlabelled intercept+one numeric slope, no extra random layer/sigma random effect/missing-data route. Preserve existing q1 route. No coverage/liveJulia claim. Red estimate15s; focused100s; neighboring suite300s; example25s. Stop/re-report any overrun. No native rebuild expected.
