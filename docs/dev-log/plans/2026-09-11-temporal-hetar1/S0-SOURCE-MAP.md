# P3 S0 source map — heterogeneous temporal AR1

**Read-only inspection at `bc905199f`, 2026-09-11.** This map records the existing seams for a future `hetar1` provider. It is not source-code authorization.

## Reusable contract

Existing AR1 already supplies independent standardized paths, stationary first-state densities, gap-aware transitions, two signed persistence starts, a separate residual `sigma`, random-effect extraction and conditional simulation.

P3 must preserve its actual integer gaps. If every occasion SD is equal, the P3 covariance must be exactly the existing AR1 covariance for the same raw times. The new common schedule supplies only an `occasion_index` selecting \(s_k\); it must not compress time into ranks. A schedule such as `0, 3, 6` therefore has correlations \(\phi^3\) and \(\phi^6\), matching AR1. A schedule with only even gaps, such as `0, 2, 4`, is rejected because it cannot distinguish the signs of \(\phi\).

## R boundary

| Surface | Current location | P3 change |
| --- | --- | --- |
| Raw metadata | `R/temporal.R:80–121` | Include `hetar1` in discrete-integer validation; retain pre-omission key validation. |
| Common layout | `R/temporal.R:252–373` | Generalize the homogeneous-Toeplitz complete common-schedule branch for `hetar1`, with K=3..12 and level support diagnostics. Preserve raw AR1 gaps. |
| TMB data | `R/temporal.R:376–401` | Add one zero-based per-node `temporal_mu_level_index` vector and structure code `4`; keep `temporal_mu_gap`. |
| Starts | `R/drmTMB.R:4540–4567` | Initialize a K-vector `log_sd_temporal` from the temporal variance split and retain `theta_temporal=±atanh(0.3)`. |
| Multi-start receipt | `R/drmTMB.R:674–713`, `946–977` | Treat `hetar1` as signed AR1, recording `persistence_start`; exact ties retain the positive first start as already implemented. |
| Random effects | `R/drmTMB.R:4716–4723` | Keep `u_temporal` random: P3 is a latent process, unlike marginal homogeneous Toeplitz. |
| Public components | `R/temporal.R:474–479`, `R/methods.R` temporal summaries | Replace the scalar label only for `hetar1` with one labelled process-SD entry per retained occasion; retain separate `sigma`. |
| Simulation | `R/temporal.R:546–590`, `R/methods.R:3512–3522` | Reuse AR1 latent draws, multiplying each node by its level-specific SD; do not use the homogeneous-Toeplitz marginal draw/whitening path. |

## Native likelihood boundary

`src/drmTMB.cpp:1051–1097` currently applies one scalar `exp(log_sd_temporal(0))` after the AR1/OU prior. P3 needs the same stationary prior and transition normalization, but adds

\[
\mu_i \mathrel{+}=\exp\{\ell_{k(i)}\}\,u_i,
\]

where `k(i)` is the common-level index. This leaves the prior standardized and preserves the separate observation likelihood at `src/drmTMB.cpp:2533–2541`. It must **not** use the homogeneous-Toeplitz direct marginal branch at `src/drmTMB.cpp:2489–2532`, which intentionally removes a separately estimable residual scale.

Required reports: `u_temporal`, all `log_sd_temporal` values, `theta_temporal`, `phi_temporal`, and a K-vector `sd_temporal`. Add no new latent state shared across IDs.

## Exact independent oracle

The oracle must construct, per ID,

\[
V_i=D\,R_i(\phi)\,D+\sigma^2 I,
\quad R_{kl}=\phi^{|t_k-t_l|},
\]

using the observed common level labels `t_k`, with independent blocks for IDs. It compares native marginal negative log likelihood, score, and observed Hessian with two finite-difference steps. Its mutation version independently detects: missing left/right `D`, rank-compressed times, a global SD, swapped `sigma`, shared IDs and omitted normalizers.

## Inference and evidence boundary

The existing AR1 `vcov()` path can be considered only after the new full-Hessian fixed-mean covariance test passes. P3 starts as interval-feasible: a finite interval merely confirms the declared information computation on a frozen fixture. The model must keep P1’s failed G13 coverage records in the programme ledger and make no coverage, calibrated-SE or general inference claim.
