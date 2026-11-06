# Beta related-matrix two-field SD contract

For independent coefficient fields k, u_k ~ N(0,K), log(s_gk)=W_gk alpha_k, b_gk=s_gk u_gk. Cov(b_k)=D_k K D_k. The supplied non-unit kernel is not normalized. The response predictor is X beta+b_0+x*b_1; Beta mean is eps+(1-2*eps)*plogis(eta), eps=1e-12, and phi=sigma^-2. The sigma intercept is estimated.

| Symbol | Formula | DGP | Extraction | Truth |
|---|---|---|---|---|
| beta | y ~ x | .2+.3*x | coef(mu) | .2,.3 |
| alpha0 | sd(id,level="relmat",coef="(Intercept)") ~ z0 | exp(log(.5)+.5*z0)*u0 | coef(sd_relmat intercept) | log(.5),.5 |
| alpha1 | sd(id,level="relmat",coef="x") ~ z1 | exp(log(.4)-.5*z1)*u1 | coef(sd_relmat x) | log(.4),-.5 |
| K | relmat(1+x\|id,K=K), equivalent Q=solve(K) | two independent full-K Gaussian draws | raw/scaled fields | non-unit AR-like K |
| sigma | sigma ~ 1 | rbeta precision .35^-2 | coef(sigma) | log(.35) |

Scope: native Beta complete-data mu, one unlabelled intercept-plus-one-slope relatedness term, no other random layer or sigma random effect. Explicitly refuse q1, slope-only, multiple slopes, labelled blocks and combined providers; this slice does not add those routes.

Predeclared seed 2026102709; 64 groups x20 observations; distinct binary z0/z1 and within-group varying x. Point SD-slope errors <.4 (single-seed smoke only). Dense independent Beta Laplace NLL/eta absolute errors <1e-4, latent gradient <1e-5; score/Hessian finite differences. K/Q, reversed formulas, constant-SD/base equality <1e-4. For supplied K, select the observed covariance before inversion. For supplied Q, invert the full named Q before selecting the observed covariance; never subset Q as though it were marginal precision. No coverage or live Julia claim.

Estimate: red parser tests <=15s; focused suite <=100s (prior Beta A/Ainv53s); neighbor suite <=240s; example <=25s. Stop/re-report overrun. No native compile expected.
