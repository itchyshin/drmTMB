# Four-fixture R--Julia ordinary-Laplace contract

## Scope and pins

This contract is the bridge-side prerequisite for the 0.7.1 ordinary-Laplace
parity programme. It began at drmTMB `1ae582c9` and DRM.jl `26f4c4dd`; the
guarded-covariance technical checkpoints are drmTMB `d24a30d09` and DRM.jl
`ded85602a`. The receipt runner records the exact clean heads at task start,
and reconciliation accepts only sidecars matching the heads used to invoke it.
Every task must record source cleanliness, R/TMB/JuliaCall/Julia identities,
Julia project and thread settings, requested and effective marginal integrators,
the family-specific objective convention, a fixture-byte digest, the runner
digest, and the target manifest. A receipt from an earlier source pin is
debugging material, not parity evidence.

## Frozen fixture table

| Fixture | R formula | Julia target | Current bridge evidence | Admission condition |
| --- | --- | --- | --- | --- |
| Binomial RI | `y ~ x + (1 | id)` | `Binomial(); marginal = :Laplace` | current-pin receipt pending | one ordinary mean RI |
| Poisson RI | `y ~ x + (1 | id)` | `Poisson(); marginal = :Laplace` | current-pin receipt pending | one ordinary mean RI |
| NB2 RI | `count ~ x + (1 | id), sigma ~ 1` | `NegBinomial2(); marginal = :Laplace` | current-pin receipt pending | one ordinary mean RI, constant `sigma` |
| coupled NB2 location--scale | `count ~ x + (1 | p | id), sigma ~ z + (1 | p | id)` | matching q=2 location--scale Laplace route | bridge admitted; current-pin receipt pending | one matching labelled intercept pair |

The target manifest, not an ad-hoc coefficient vector, will define all common,
free outer parameters on named link/transformed scales. Inner modes never enter
the comparison. Every requested target must receive point, SE, convergence,
gradient/Hessian, and profile-endpoint statuses; absence and non-finiteness are
classified outcomes, never dropped rows.

For the coupled fixture, the common covariance coordinates are explicitly the
three raw Cholesky entries `L11`, `L22`, and `L21`, because they are the shared
working-scale interface. Native R also exposes derived SD and correlation
targets; these are recorded as `engine_only` inventory rows, never profiled as
pretended same-target quantities or silently discarded from the receipt.

## Coupled-NB2 admission closure and remaining inference gate

The native prerequisite is now implemented for one complete-data, non-ZI,
ordinary NB2 cell with exactly one matching labelled intercept pair. The bridge
marshals `p` as a covariance label rather than a data column, reconstructs the
three `recov_group:L11/L22/L21` coordinates, and reports the corresponding
native-scale SD/correlation summaries. The current Julia route uses the same
guarded covariance domain as native TMB; it also rejects non-finite raw
coordinates and treats `L21 = 0` as an unconstrained native-covariance case.
Those source-level checks do not replace a current-pin point or profile receipt.

The remaining gate is inference rather than admission: each raw Cholesky
coordinate must retain a profile status. The R bridge profiles these coordinates
as `cholesky:recov:L11/L22/L21` on their declared working scale. It does not
relabel those endpoints as response-SD or correlation intervals; that would be
a different reparameterized profile. A non-finite or failed endpoint remains a
classified outcome.

## Campaign boundary

An earlier receipt was generated before the guarded coupled-covariance repair.
It is retained only for diagnosis and must not be reconciled or used to claim
point or endpoint parity. G4 remains open: the current-pin run must classify
every shared outer target, including an explicit status for each profile arm.
The next diagnostic, if an arm fails, retains profile NLL, likelihood-ratio
residual, nuisance gradient, and distance from the native correlation guard.

Consequently there are no coverage, cost, or DRAC claims. Matrix regeneration
and the paired 500-seed-per-fixture campaign remain blocked until same-target
profile parity is re-established and a separate cost-probe approval is given.
