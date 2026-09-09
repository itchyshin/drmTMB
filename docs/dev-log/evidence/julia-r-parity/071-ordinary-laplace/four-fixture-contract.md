# Four-fixture R--Julia ordinary-Laplace contract

## Scope and pins

This contract records the bridge-side four-fixture classification prerequisite
for the 0.7.1 ordinary-Laplace parity programme. The frozen receipts were run
at drmTMB `9939ace07967af9a9b6e23a4d021080d5d7d76a7` and DRM.jl
`b877f5136dbd13b6ff1cb3a1de02ee826b0fdf1c`; their compact authoritative
reconciliation is [`reconciled-summary.tsv`](reconciled-summary.tsv). Earlier
pins (`1ae582c9`, `26f4c4dd`, `d24a30d09`, and `ded85602a`) are technical
history, not substitute evidence. The receipt runner records the exact clean
heads at task start, and reconciliation accepts only sidecars matching the
heads used to invoke it.
Every task must record source cleanliness, R/TMB/JuliaCall/Julia identities,
Julia project and thread settings, requested and effective marginal integrators,
the family-specific objective convention, a fixture-byte digest, the runner
digest, and the target manifest. A receipt from an earlier source pin is
debugging material, not parity evidence.

## Frozen fixture table

| Fixture | R formula | Julia target | Current bridge evidence | Admission condition |
| --- | --- | --- | --- | --- |
| Binomial RI | `y ~ x + (1 | id)` | `Binomial(); marginal = :Laplace` | classified; 6 finite engine-target profiles | one ordinary mean RI |
| Poisson RI | `y ~ x + (1 | id)` | `Poisson(); marginal = :Laplace` | classified; 6 finite engine-target profiles | one ordinary mean RI |
| NB2 RI | `count ~ x + (1 | id), sigma ~ 1` | `NegBinomial2(); marginal = :Laplace` | classified; 8 finite engine-target profiles | one ordinary mean RI, constant `sigma` |
| coupled NB2 location--scale | `count ~ x + (1 | p | id), sigma ~ z + (1 | p | id)` | matching q=2 location--scale Laplace route | classified; 12 finite profiles and 2 retained L22 non-finite endpoints | one matching labelled intercept pair |

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

The inference gate is met as a classification exercise: each raw Cholesky
coordinate retained a terminal profile status. The R bridge profiles these
coordinates as `cholesky:recov:L11/L22/L21` on their declared working scale. It
does not relabel those endpoints as response-SD or correlation intervals; that
would be a different reparameterized profile. Both L22 endpoints are
non-finite and remain retained classifications, not successful intervals.

## Campaign boundary

An earlier receipt generated before the guarded coupled-covariance repair is
retained only for diagnosis and must not be reconciled or used to support this
classification. The current-source reconciliation classifies all 34
engine-target profile attempts: 32 finite profiles and two matched L22
non-finite endpoints. That completes the four-fixture same-target
classification and matrix-regeneration prerequisites.

These receipts are not interval-coverage evidence. The separate
[`cost probe`](cost-probe.md) estimates the retained campaign at 275 CPU-hours;
the paired 500-seed-per-fixture DRAC campaign remains unsent until the
post-probe approval gate is explicitly reopened.
