# R3.3: independent importance-sampling likelihood reference

R3.2 product quadrature did not converge fast enough for a reliable direct
relative-profile comparison. R3.3 replaces the tensor grid with a
Laplace-centered importance-sampling calculation in the six *standard-normal*
latent coordinates. This is an independent numerical reference, not a new
package fitting method.

For fixed rate/amplitude values and native optimized intercepts, let `w` be
the six independent standard-normal coordinates. The target is

\[
  p(w)\prod_i p(y_i\mid w),
\]

and the proposal is a Gaussian centred at the directly optimized target mode,
with covariance equal to an eigenvalue-floored inverse numerical Hessian.
Every importance weight explicitly subtracts the proposal log-density.

The two unresolved R3.2 cells are `ridge/interior` and `interior/interior`.
The predeclared acceptance criteria are eight independent batches of 2,000
draws, a batch standard error no larger than 0.01 NLL, and ESS at least 200 in
every batch. This does not validate 128-tip Laplace behavior, rate recovery,
or an OU capability expansion.
