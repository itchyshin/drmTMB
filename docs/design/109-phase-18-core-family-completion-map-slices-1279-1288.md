# Phase 18 Core Family Completion Map, Slices 1279-1288

This note restores the Phase 18 routing map onto the clean reconciliation
branch. It is a planning map, not a new fitted-surface claim.

The purpose is to finish a coherent first public story for common one-response
measurement processes before adding richer covariance, inflation-random-effect,
or skew-family syntax. A family row is ready for public support only when fitted
likelihoods, focused tests, artifact or recovery evidence, reader-facing docs,
unsupported-neighbour boundaries, check-log evidence, and after-task notes agree.

## Status By Measurement Process

| Measurement process | Current clean-branch status | Next small action |
| --- | --- | --- |
| Ordinary counts | Fixed-effect Poisson, NB2, zero-inflated Poisson/NB2, zero-truncated NB2, and hurdle NB2 are fitted where documented. Ordinary non-zero-inflated Poisson/NB2 `mu` random intercepts and independent numeric `mu` slopes are fitted. Ordinary NB2 log-`sigma` random intercepts are fitted. Ordinary Poisson/NB2 q=1 phylogenetic `mu` intercepts are fitted as narrow first slices, with formal-admission infrastructure and sharded dispatch for the NB2 q1 grid. | Keep the first-wave count story narrow: ordinary count mixed models plus q=1 phylogenetic smoke/formal-admission routes. Do not promote formal recovery until the 500-replicate shards are run and audited together. |
| Proportions and bounded responses | Fixed-effect `beta()` and `beta_binomial()` are fitted, the fixed-effect ADEMP sheet exists, Slices 1289-1298 restore the private DGP, summariser, smoke runner, summary helper, repeatable grid writer, and focused test lane, and the clean-branch follow-up wires that lane into the first-wave summary runner plus the manual `proportion_fixed_effect` Actions task. | Keep the lane fixed-effect only. Add the positive-continuous artifact lane before any bounded-response random effects, `zoi`, `coi`, exact 0/1 boundary mass, known-covariance bounded responses, or mixed-response bounded models. |
| Positive continuous responses | Fixed-effect lognormal location-scale and Gamma mean-CV likelihoods are fitted. The clean reconciliation branch does not yet carry a dedicated Phase 18 artifact lane for them. | Add a fixed-effect-only lognormal/Gamma artifact lane before Tweedie, generalized Gamma, positive-response random effects, known-covariance positive responses, structured effects, or mixed-response positive-continuous models. |
| Ordinal responses | Fixed-effect univariate `cumulative_logit()` models are fitted with ordered cutpoints and fixed latent logistic scale. The fixed-effect ordinal ADEMP sheet exists, but the clean reconciliation branch does not yet carry the later private artifact lane. | Add a location-only ordinal artifact lane before ordinal random effects, scale/discrimination formulas, bivariate ordinal models, or mixed-response ordinal models. |
| Shape and skewness | Fixed-effect Student-t `nu` is fitted and simulation-staged. Skew-normal and skew-t are planned gates only. | Keep Student-t as the only fitted shape family. For skew-normal, require a density comparator, Gaussian-limit check, prediction contract, profile-target policy, diagnostics, and recovery tests before public examples. |

## Recommended Order

1. Keep NB2 q1 formal recovery on the sharded Actions path, not a local
   singleton run.
2. Add the fixed-effect positive-continuous artifact lane.
3. Add the fixed-effect ordinal artifact lane.
4. Only then choose between skew-normal implementation and deeper formal grids
   for already fitted families.

This order gives applied readers broad measurement-process coverage while
keeping non-Gaussian structured slopes, inflation random effects, mixed-response
families, and skew-family syntax behind separate gates.
