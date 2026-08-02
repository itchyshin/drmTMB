# Mesh/SPDE Gaussian intercept: symbolic alignment

## Earned first-slice contract

This record fixes the only fitted mesh route as
`bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1)` with a univariate Gaussian
response.  The existing `coords =` route remains a separate dense
coordinate-covariance likelihood.  It is the same scientific role, not the
same stochastic model.

| Symbol in prose | Keyword / covstruct | DGP draw | Recovery extractor | Truth value |
| --- | --- | --- | --- | --- |
| `X_i beta` | ordinary fixed effects in `mu` | fixed linear predictor | `coef(fit)` | fitted |
| `omega` | `spatial(1 \| site, mesh = mesh)` | mesh-vertex field | `ranef(fit, "spatial_mu")$latent` | fitted; local-fit capability only |
| `A omega` | mesh projection, never a node index | one barycentric projection row per retained observation | conditional `mu` contribution | fitted and independently compared; local-fit capability only |
| `Q(kappa_0)` | `mesh$spde$c0/g1/g2`, fixed `mesh$kappa` | `kappa_0^4 c0 + 2 kappa_0^2 g1 + g2` | internal contract only | fixed configuration, not an estimand |
| `s = exp(log_sd)` | fixed-kappa GMRF field scale | positive covariance-scale multiplier (precision is `s^-2 Q`) | `sdpars$mu[["spatial(1 | site)"]]` | fitted; recovery gate blocked, not an inference claim |

The fitted model is

`y_i | omega ~ Normal(X_i beta + (A omega)_i, sigma_e^2)` and
`omega | s, kappa_0 ~ Normal(0, s^2 Q(kappa_0)^-1)`.

The field prior contributes

`1/2 {m log(2 pi) + 2m log(s) - log|Q(kappa_0)| + s^-2 omega'Q(kappa_0)omega}`.

`kappa_0` must be finite and positive, belongs to the mesh object, and is
reported only as `kappa_fixed`.  There is no `log_kappa_spde`, range estimate,
range profile, or interval claim in this arc.  Mesh units are the supplied
projected-coordinate units; decimal longitude/latitude must be transformed
before mesh construction.  The projected marginal SD is location-dependent,
`s sqrt(a_i' Q^-1 a_i)`; the first slice therefore calls `s` a GMRF field
scale rather than presenting it as one uniform field SD.

## Fences

This slice does not admit mesh slopes, residual-scale or shape mesh effects,
non-Gaussian or bivariate mesh models, anisotropy, barriers, replicated fields,
spatiotemporal fields, or extrapolation outside the mesh.  A retained
observation must have a finite projection row summing to one.
