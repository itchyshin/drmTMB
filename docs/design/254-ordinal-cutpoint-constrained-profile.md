# Constrained Profile Design for Ordinal Cutpoints

This note defines the constrained profile used when an applied ecology or
evolution reader asks where an ordered-score boundary lies on the latent
logistic axis. It covers only public
`ordinal:cutpoint:<label>` targets from ML/Laplace `cumulative_logit()` fits.
It does not change the fitted likelihood, formula grammar, default interval
method, or the model scope.

## Public estimand and parameterization

For a `K`-category response, let `c_1, ..., c_{K-1}` be the ordered
latent-logistic cutpoints used in

```text
Pr(Y_i <= j) = logit^-1(c_j - mu_i).
```

The optimizer stores an unconstrained vector `theta_ord`, but readers should
interpret and request cumulative cutpoints. The fixed mapping is

```text
c_1 = theta_1,
c_j = c_{j-1} + exp(theta_j),  j = 2, ..., K - 1.
```

Thus `theta_1` happens to equal the first cutpoint, whereas each later
`theta_j` is a log gap. Calling a raw `theta_ord[j]` a cutpoint would answer a
different scientific question and would mislabel its scale. The public target
namespace therefore exposes `ordinal:cutpoint:<label>` and keeps raw
`ordinal:theta_ord:<label>` entries internal diagnostics.

Location is the latent shift `mu_i`; the residual logistic scale is fixed in
this model; shape is not fitted here; and coscale means modelling residual
correlation such as `rho12`, which is outside this univariate ordinal model.
These terms deliberately remain separate from the ordered cutpoints.

## Constrained profile

To profile a chosen cumulative cutpoint `c_m = a`, the pure-R profile evaluator
substitutes the constrained ordinal parameterization into the existing
objective and re-optimizes all remaining free parameters. For `m = 1`, it sets
`theta_1 = a`. For `m > 1`, it retains the later log gaps and substitutes

```text
theta_1 = a - sum_{r = 2}^m exp(theta_r).
```

This substitution gives `c_m = a` exactly while retaining strict ordering:
all adjacent gaps remain `exp(theta_r) > 0`. It is a constraint on the
cumulative scientific estimand, not a post-hoc relabelling of an unconstrained
`theta_ord[m]` profile. Because this is direct constrained optimization of the
existing likelihood, no Jacobian adjustment is added: the procedure profiles
the original objective over the constrained parameter set rather than treating
the substitution as a density transformation.

At each candidate `a`, the optimizer must satisfy two invariants. First, the
reconstructed cutpoints must be strictly ordered. Second, the constrained
negative log likelihood must not fall below the fitted unconstrained objective
except for numerical tolerance; a lower value signals a failed constraint or
optimization defect, not a better fit. The endpoint search then compares the
re-optimized objective with the likelihood-ratio cutoff for the requested
level. `profile_engine = "auto"` selects this constrained ordinal engine for a
public cutpoint target.

## Interval interpretation and scope fence

A successful result is a pointwise likelihood-ratio interval for one named
cutpoint on the latent-logistic cutpoint scale. It may be finite, unavailable,
or one-sided when the profile cannot cross the cutoff on one side. A finite
result must not be described as simultaneous uncertainty across all thresholds
or as uncertainty for category probabilities.

The initial scope excludes Wald cutpoint intervals, bootstrap cutpoint
intervals, profile curves exported through `profile()`, default broadening of
`confint(fit)`, ordinal scale or discrimination formulae, bivariate or mixed
ordinal models, and coverage or G5 calibration claims. The reader should use
the explicit profile call and inspect status, boundary, and message columns.
The implementation tests in `tests/testthat/test-profile-targets.R` exercise
the public constrained target and its finite-endpoint contract; the repeated-
sampling question is deliberately reserved for the DRAC contract cited below.

## Evidence required before a calibration claim

Availability and calibration are distinct quantities. The no-compute campaign
contract
[`2026-08-12-ordinal-cutpoint-profile-drac-contract.md`](../dev-log/interval-availability/2026-08-12-ordinal-cutpoint-profile-drac-contract.md)
pre-registers the denominator, failure ledger, and gates required before any
coverage statement. It authorizes neither a launch nor a public promotion;
explicit DRAC approval follows a local timing smoke for each DGP, information
rung, and missingness mechanism.
