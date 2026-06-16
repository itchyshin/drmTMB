# Numerical Guard Simulation Audit

## Motivation

Hao Qin flagged a legitimate release-risk question on 2026-06-16: some
constants in `src/drmTMB.cpp` look like hard-coded truncations. If a guard
silently changes the likelihood, it can create apparent numerical convergence
without a matching statistical justification. That concern should be tested,
not waved away.

The project position is:

- domain transforms are allowed when they define the legal parameter space;
- model-defining restrictions are allowed when the documentation says exactly
  what model is being fitted;
- starting-value floors are allowed when they only choose an initial point;
- likelihood-altering guards are diagnostic safeguards, not evidence that the
  fitted model is identified or inferentially reliable.

If a guard has little impact in the intended operating range, the feature can
remain useful, but users still need an honest explanation of the guard and a
diagnostic when it is active.

## Current Guard Classes

| Class | Examples | Interpretation | Simulation question |
|---|---|---|---|
| Domain transform | `rho12 = 0.99999999 * tanh(eta_rho12)` and random-effect correlation guards | Correlations must stay inside `(-1, 1)` so covariance matrices remain positive definite. The multiplier is a numerical guard near singularity. | Do estimates, intervals, and boundary diagnostics behave correctly for true correlations near 0, moderate values, and high `|rho|`? |
| Model-defining restriction | Student-t `nu = 2 + exp(eta_nu)` | The fitted Student-t route is a finite-variance model with `nu > 2`. It deliberately excludes infinite-variance tails. | How often do low-`nu` data push estimates to the boundary, and do diagnostics prevent overconfident interval claims? |
| Density-domain floor | beta and zero-one beta mean/shape epsilons, missing-data beta shape floors | These avoid evaluating beta densities exactly at illegal open-support boundaries. They are acceptable only when paired with response validation and boundary wording. | Are estimates unchanged away from support boundaries, and are boundary-near failures/warnings visible? |
| Tail log floor | skew-normal `log(Phi(nu * z) + 1e-300)` | Prevents `log(0)` in extreme tails while leaving ordinary likelihood values effectively unchanged. | Does the floor matter in strong-skew or outlier scenarios, and does it change sign or scale conclusions? |
| Likelihood-altering scale guard | Gaussian `log(sigma)` soft-clamp | This is a numerical overflow guard. It cannot create identifiability; if active at the optimum, the fit is a guarded diagnostic fit. | Compare disabled/default/wider/tighter clamp settings for bias, coverage, Hessian status, guard activation, and warning rates. |
| Starting-value floor | R-side `pmin()`/`pmax()` starts for probabilities, scales, counts, and missing-data predictors | These choose feasible starting values. They should not change the likelihood once optimization begins. | Verify that changing starts does not change the optimum for well-posed fits, and record when multiple starts expose local minima. |

## Big-Simulation Contract

The big simulation programme should include a numerical-guard sensitivity lane
before guard-dependent routes are used for public inference claims. The lane
should compare at least the default guard configuration with a less restrictive
or disabled configuration whenever the implementation allows it. For the
Gaussian `log(sigma)` clamp, compare:

- `logsigma_clamp = NULL`;
- the default identity-in-band clamp;
- a wider band;
- a narrower diagnostic band.

Each simulation cell should record:

- guard configuration and package SHA;
- whether the guard was active at the optimum or along failed evaluations when
  detectable;
- estimates, standard errors, log likelihood, objective, convergence code,
  `pdHess`, gradient diagnostics, warnings, and elapsed time;
- bias, RMSE, empirical interval coverage, MCSE, boundary flags, failures, and
  refit discrepancies across guard settings;
- the interpretation label: `diagnostic`, `parity`, `guard_sensitivity`, or
  `promotion`.

The acceptance rule is conservative. If guard activation is rare and estimates,
standard errors, log likelihood, and coverage agree within Monte Carlo error in
well-posed cells, the guard can remain a documented numerical safeguard. If a
guard frequently changes estimates, interval coverage, or model status, the
corresponding feature must stay diagnostic or experimental until the likelihood,
parameterization, or diagnostic workflow is redesigned.

## User-Facing Rule

Do not let a numerical guard upgrade a fit. A guarded fit may avoid overflow
and preserve a useful point-estimate diagnostic, but it does not erase
non-convergence, a non-positive-definite Hessian, boundary status, weak
identification, or a failed profile/bootstrap/simulation check.

The documentation should say what the guard does, when it is expected to be
inactive, and how users can see whether it affected their model. That is more
useful than pretending the constants are invisible.
