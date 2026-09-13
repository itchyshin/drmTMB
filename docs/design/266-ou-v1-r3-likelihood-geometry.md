# R3: likelihood geometry of independent OU location and scale fields

## Purpose

R2 ruled out poor recovery as a small-tree or low-replication artifact: at 128
tips and 12 observations per tip, both rates still show large errors. R3 asks
whether this comes from an implementation mismatch or from the intended
marginal likelihood geometry. It makes no capability, recovery, interval, or
model-selection claim.

## Profile contract

Use two prespecified retained R2 data sets: `rate1_rep1` (a large-error
location-rate example) and `rate2_rep1` (the complementary ordered truth).
For each, profile the two log rates on the fixed natural-scale grid
`(0.3, 0.7, 1.3, 3, 8)` squared. At every grid point map both decay coordinates
to their fixed values and re-optimise fixed intercepts, two field SDs, and all
latent modes. Retain every point's objective, convergence, Hessian status,
gradient, and field-SD estimates. The reference objective is the minimum
finite grid objective; report `delta_objective` relative to it. A profile grid
with fixed SDs or latent values is not an admissible R3 profile.

## Independent marginal-integration contract

Generate one independent 3-tip, 3-replicate-per-tip Gaussian data set with
the same two stationary OU fields. At fixed positive SDs/rates and fixed
intercepts, compare:

1. the native TMB Laplace marginal objective, which integrates its augmented
   all-node latent field; and
2. direct product Gauss-Hermite integration over the six tip-level
   `(u_1,u_2,u_3,v_1,v_2,v_3)` variables under their known joint stationary
   tip covariance.

The latter analytically marginalises internal nodes through the OU tip
covariance and is independent of the native sparse evaluator. Run 5- and
7-node-per-dimension quadrature. The refinement difference is the numerical
accuracy diagnostic; it must be reported separately from the Laplace-minus-
quadrature difference. The calculation compares objectives at a fixed
hyperparameter point; it is not a profile or a validation of global
optimisation.

## Decision rule

If profiles show wide near-equivalent valleys or the Laplace-versus-quadrature
difference is material relative to the profile span, G15 remains a no-go and
the independent two-field route stays local-fit/oracle only. If neither is
seen, R3 merely motivates a new, approved design discussion; it does not
promote OU v1 automatically.
