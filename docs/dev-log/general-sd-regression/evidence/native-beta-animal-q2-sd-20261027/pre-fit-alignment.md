# Beta animal coefficient SD slice: pre-implementation contract

One complete-data unlabelled animal intercept and numeric slope, supplied SPD A or its full named Ainv,
sigma regression without random effects, no ordinary additional random effects. Fields are independent.
For k=0,1: log(s_gk)=W_gk alpha_k, u_k~N(0,A), b_gk=s_gk*u_gk.
eta_i=0.2+0.3*x_i+b_g0+x_i*b_g1; mu_i=1e-12+(1-2e-12)*plogis(eta_i).
phi=sigma^-2, y_i~Beta(mu_i*phi,(1-mu_i)*phi). Shape-floor activity is excluded
from this ordinary fixture by an explicit assertion, never by clipping y.

| Symbol | Formula | DGP | Recovery | Truth |
|---|---|---|---|---|
| beta | y~x+animal(1+x\|id,A=A) | fixed intercept+x effect | coef(fit,"mu") | .2,.3 |
| alpha0 | sd(id,level="animal",coef="(Intercept)")~z0 | exp(alpha0[1]+alpha0[2]*z0) times first A-normal draw | coef(fit, canonical intercept SD key) | log(.5),.5 |
| alpha1 | sd(id,level="animal",coef="x")~z1 | exp(alpha1[1]+alpha1[2]*z1) times independent A-normal draw | coef(fit, canonical slope SD key) | log(.4),-.5 |
| sigma | sigma~1 | phi=.35^-2 | exp(coef(fit,"sigma")) | .35 |
| A | supplied non-unit named matrix | Cholesky of same supplied matrix, shuffled only after DGP | independent dense oracle | fixed SPD covariance |

Fixed seed 2026102705, 64 groups x20 repeats; distinct group binary SD predictors,
varying within-group x, permuted provider/factor labels. Declared checks: both
SD slope errors<.4, optimizer convergence0, independently solved mode gradient
<1e-5, positive-definite latent Hessian, absolute NLL and eta oracle errors<1e-4,
constant-SD/base objective equivalence<1e-4, conditional predictor/report error
<1e-7. Two independent deterministic mode starts and derivative finite-difference
checks. These are numerical/single-seed checks; no coverage claim or automatic
threshold relaxation. Failure is diagnosed before any design change.
