# Future: evidence-first free-rate and correlated phylogenetic OU

## Status

Park full free-rate phylogenetic OU development after the bounded fixed-alpha
sensitivity delivery. This is not a bug report and does not withdraw the BM
default or the experimental `ou_sensitivity()` helper.

## Why parked

- Existing rate-recovery diagnostics found weak alpha--amplitude geometry despite clean convergence.
- Ayumi’s passerine body-mass receipt has BM AIC 4691.289; every declared fixed-alpha OU value was worse (best OU 4705.362 at normalized alpha 0.1).
- R7’s 128-species AVONET mass--morphology subset has BM AIC 70.510 and best OU AIC 73.476 (alpha 0.3).
- Two fixed-seed simulated OU draws, including a deliberately stronger signal, also had BM as the lowest-AIC member of the declared grid. This is retained negative evidence about the current decision route, not evidence that OU is universally inferior.

## Current usable surface

`ou_sensitivity()` is an experimental tool for prespecified biological
robustness grids: BM plus fixed location-side OU alpha values on the same
data/tree/formula/settings. It must be described as conditional sensitivity,
not alpha estimation, interval inference, or generic BM-versus-OU selection.

## Preconditions to reopen

1. Freeze a narrow estimand and simulation regime with adequate replication and separated signal.
2. Establish rate recovery and profile geometry against an independent marginal-likelihood reference, retaining failures.
3. Only then derive correlated multi-field continuous-time OU with separate alpha_mu/alpha_sigma and a PSD transition covariance, and validate it through its own oracle/recovery arc.
4. Do not widen to all families, bivariate/missing-response structures, temporal combinations, or public OU-preference language until those gates pass.

## Out of scope

No release claim, manifest promotion, free-alpha recovery campaign, or temporal OU work follows from this issue.
