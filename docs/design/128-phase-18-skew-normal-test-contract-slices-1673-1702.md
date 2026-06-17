# Phase 18 Skew-Normal First-Test Contract, Slices 1673-1702

Superseded status: the fixed-effect `skew_normal()` first slice now exists, and
the `skew_normal_fixed_effect` Phase 18 artifact lane adds repeatable
smoke/grid evidence. This note remains as historical test-contract context.

This note is Team B's design-only gate after the skew-normal
parameterization decision. It does not implement `skew_normal()`, add a
constructor, or admit any C++ likelihood branch. Its reader is the contributor
who will write the first tests before fitting support is exposed.

The contract keeps the first lane univariate and fixed-effect:

```r
# Historical gate example:
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ w),
  family = skew_normal(),
  data = dat
)
```

Here `mu` is the response mean, `sigma` is the response standard deviation,
and `nu` is the residual slant or shape parameter. This keeps the package-wide
one-/two-response scope intact, but the first skew-normal lane is one-response
only. Bivariate skew-normal models, composed families, mixed responses, and
residual `rho12` are outside this first lane.

## Density Normalization Target

The first density test should evaluate the moment-to-native transform chosen
in `docs/design/127-phase-18-skew-normal-parameterization-decision-slices-1669-1672.md`:

```text
delta_i = nu_i / sqrt(1 + nu_i^2)
omega_i = sigma_i / sqrt(1 - 2 * delta_i^2 / pi)
xi_i = mu_i - omega_i * delta_i * sqrt(2 / pi)
z_i = (y_i - xi_i) / omega_i
log f_i(y_i) = log(2) - log(omega_i) + log phi(z_i) + log Phi(nu_i z_i)
```

For a small deterministic grid of `mu`, `sigma`, and `nu` values, the density
must integrate to one on the real line with absolute error no larger than
`1e-8`. The same grid should compare log densities to a trusted native-density
comparator after transforming to `xi`, `omega`, and `alpha = nu`, with absolute
differences no larger than `1e-10` away from extreme machine-tail points. This
test must include negative, zero, and positive `nu`, small and moderate
`sigma`, and tail points. Constants are part of the target; a likelihood that
differs only by dropped normalizing constants is not acceptable.

## Normal-Limit Test

At `nu = 0`, the transform must reduce exactly to the Gaussian
location-scale density:

```text
delta_i = 0
omega_i = sigma_i
xi_i = mu_i
log f_i(y_i) = dnorm(y_i, mean = mu_i, sd = sigma_i, log = TRUE)
```

The first normal-limit test should compare per-observation log densities and
the summed negative log likelihood to the Gaussian target with absolute
differences no larger than `1e-10`. It should also compare `fitted()`
semantics for `mu`, `sigma()`, and future `predict(dpar = "nu")` output on
fixed-effect rows where `nu` is zero. It should run before any recovery or
comparator-fit test, because every later skew-normal claim depends on the
symmetric limit being the ordinary Gaussian location-scale model.

## Sign And Orientation Test

The public sign convention is:

```text
nu > 0  -> right-skewed residual distribution
nu = 0  -> Gaussian residual distribution
nu < 0  -> left-skewed residual distribution
```

The first sign test should be density-level, not fit-level. For matched
positive and negative values of `nu`, it should confirm that the signed third
central moment has the same sign as `nu` after the public `mu` and `sigma`
moment transform. A companion comparator test should check that positive
`nu` maps to positive native `alpha` in the trusted Azzalini density. Do not
infer orientation from a single simulated model fit or from coefficient signs
alone.

## False-Positive Boundaries

The first false-positive checks should ask whether `nu` is being used to
explain patterns that belong to `mu` or `sigma`. Before implementation is
called stable, Gaussian data with active `mu ~ x` and `sigma ~ z` should not
produce systematic support for `nu ~ w` when the data-generating residuals are
symmetric. The first grid should include at least:

- a homoscedastic Gaussian control with `nu ~ 1`;
- a heteroscedastic Gaussian case with `sigma ~ z` and `nu ~ w`;
- a correlated-design case where `x`, `z`, and `w` are deliberately related;
- a misspecified-scale case recorded as a boundary, not as skewness evidence.

For the design gate, a "positive" skew-normal result means recovery or
predictive improvement under a skew-normal data-generating process. A Gaussian
or Student-t sensitivity model, heteroscedastic residual spread, outliers, or
mean-model misspecification must not be reported as evidence that
`skew_normal()` is fitted or that `nu ~ w` is ready for examples.

## No-C++ Admission Criteria

This design-only no-C++ gate is now superseded by the fitted first slice. At
the time, it was admissible only while all of these remained true:

- the constructor was not part of that slice;
- no file under `src/` changes and no TMB family enum, switch branch, or
  density helper was added;
- no `R/`, `tests/`, or `NAMESPACE` change exposed or exercised skew-normal
  support in that slice;
- shared `ROADMAP.md` and `docs/dev-log/check-log.md` changes may record the
  design status only, not fitted support;
- every code block using the family was labelled non-runnable;
- the note keeps `mu`, `sigma`, and `nu` as the only first-lane
  distributional parameters and keeps `rho12` out;
- the first implementation PR is still required to add density tests,
  normal-limit tests, sign-orientation tests, false-positive checks,
  malformed-neighbour tests, extractor checks, documentation, and after-task
  evidence before user-facing support is claimed.

Boole's syntax gate is that the public formula remains one formula per
distributional parameter, with no `skew ~ x` alias and no `skew(id) ~ x`.
Noether's math gate is exact agreement among the public moments, native
transform, density constants, and normal limit. Gauss's likelihood gate is
finite gradients and stable optimization after the density tests pass. Pat's
user gate is that unsupported examples tell the reader to fit Gaussian and
Student-t sensitivity models until skew-normal support is actually admitted.

## Slice Status

| Slice | Status | Evidence |
| --- | --- | --- |
| 1673 | Done | This note records the first-test contract after the moment-parameter decision. |
| 1674 | Done | The planned syntax remains `bf(y ~ x, sigma ~ z, nu ~ w)` with one formula per distributional parameter. |
| 1675 | Done | The density normalization target includes constants and quadrature to one. |
| 1676 | Done | The native-density comparator route transforms public `mu`, `sigma`, and `nu` to `xi`, `omega`, and `alpha`. |
| 1677 | Done | The normal-limit test requires equality to Gaussian location-scale at `nu = 0`. |
| 1678 | Done | The sign convention is `nu > 0` for right-skewed residuals and `nu < 0` for left-skewed residuals. |
| 1679 | Done | The sign test is density-level and moment-based, not inferred from fitted coefficients alone. |
| 1680 | Done | The false-positive boundary separates skewness evidence from mean, scale, outlier, and misspecification signals. |
| 1681 | Done | The first false-positive grid includes homoscedastic, heteroscedastic, correlated-design, and misspecified-scale cases. |
| 1682 | Done | The no-C++ admission criteria forbid a constructor, `src/` edit, TMB family enum, switch branch, and density helper in this slice. |
| 1683 | Done | The note keeps `rho12`, bivariate skew-normal, composed families, and mixed responses outside the first lane. |
| 1684 | Done | The first implementation PR must add tests, documentation, and after-task evidence before user-facing support is claimed. |
| 1685 | Done | `docs/design/130-phase-18-comparator-boundary-decisions-slices-1631-1632-1685-1686.md` records finite continuous response support and model-frame filtering before support validation. |
| 1686 | Done | The same note records that rank-deficiency handling should use shared fixed-effect infrastructure unless density tests reveal a skew-normal-specific failure. |
| 1687 | Done | `tests/testthat/test-skew-normal-boundary.R` now reads this first-test contract as part of the no-fit boundary scan. |
| 1688 | Superseded | The old absence boundary is replaced by constructor/export checks plus unsupported-neighbour rejection. |
| 1689-1702 | Planned | The next implementation slice should turn this contract into source-level density tests, malformed-neighbour tests, extractor checks, and documentation before exposing `skew_normal()`. |
