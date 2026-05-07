# Testing Strategy

Testing must constrain the modelling ambitions of `drmTMB`.

## Test Layers

- Unit tests for formula parsing and family validation.
- Simulation tests for each likelihood.
- Prediction and simulation method tests.
- Snapshot tests for clear user-facing errors.
- Optional long simulation tests outside CRAN checks.

## Simulation Recovery

Each family should have tests that:

1. simulate from known parameters;
2. fit the corresponding model;
3. check convergence;
4. check estimates within tolerance;
5. cover boundary-prone cases.

## Bivariate Required Cases

- `rho12 = 0`;
- moderate positive `rho12`;
- moderate negative `rho12`;
- predictor-dependent `rho12`;
- unequal `sigma1` and `sigma2`.

## CRAN Constraints

Routine tests should be deterministic, fast, and small. Larger recovery studies
belong in optional scripts or scheduled CI.
