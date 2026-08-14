# MD9b joint Gaussian recovery campaign: preregistration

## Question and boundary

Does the narrow MD9b route recover the response, predictor-model, scale, and
predictor-correlation parameters when two continuous predictors are missing
independently under MCAR? This is only for
`bf(y ~ z + mi(x1) + mi(x2), sigma ~ 1)` with
`impute_joint(cbind(x1, x2) ~ z)`. It does not test MAR, response masking,
random or structured terms, more predictors, mixed predictor families, REML,
or any wider non-Gaussian surface.

## Frozen DGP and grid

The runner `tools/run-joint-mi-gaussian-recovery.R` draws independent rows:

\[
z \sim N(0, 1), \quad (e_1,e_2) \sim N(0, \Sigma_{\rho_x}),
\]

\[
x_1 = 0.3 + 0.7z + e_1, \quad
x_2 = -0.2 - 0.4z + 1.2e_2,
\]

\[
y = 1 + 0.5z + 0.8x_1 - 0.6x_2 + \varepsilon,
\quad \varepsilon \sim N(0, 0.7^2).
\]

Each predictor is independently masked with probability `missing_rate`. The
12 cells cross `n = 300, 600, 1200`, `rho_x = 0.2, 0.6`, and
`missing_rate = 0.2, 0.4`. The DRAC array has 250 predeclared replicates per
cell (3,000 attempted fits), in five disjoint 50-replicate shards. Seed
`r` in cell `c` is `2026081300 + 100000*c + r`.

## Recorded quantities and proposed decision rule

Every attempt is retained with its seed, elapsed time, warnings, error,
convergence code, `pdHess`, maximum gradient, truth, and estimate. A usable
fit is `fit_success`, convergence code zero, `pdHess = TRUE`, and maximum
gradient at most `0.01`. The report will show every parameter's mean error,
RMSE, Monte Carlo SE, and the usable-fit fraction by cell. A promotion request
requires at least 95% usable fits in every cell and no material systematic
bias; it remains subject to independent inference and systems review. This is
a point-fit recovery gate, not an interval-coverage claim.

## Pre-run receipt

On 2026-08-13, cell `n0300_rho20_miss20`, replicates 9--10, completed 2/2
fits: convergence code zero, `pdHess = TRUE`, gradients
`7.18e-4` and `4.98e-4`, with a mean 1.17 seconds per fit. The prior two
harness faults (namespaced `mi()` and incorrect coefficient extraction) were
found and repaired before this receipt. At this rate the 3,000-fit workload is
roughly one CPU hour; the submitted array requests a conservative six-hour
per-task ceiling to include installation and heterogeneous cluster timing. A
separate installed-package pre-run of the hardest cell (`n1200_rho60_miss40`)
also converged with `pdHess = TRUE` in 1.56 seconds and gradient `0.00292`;
this is why the usable-fit gradient criterion is `0.01`, matching the focused
recovery smoke, rather than a stricter arbitrary threshold.

## Poisson proof-route status

The ordinary Poisson MD9b test uses no response mask and no random or
structured response terms. Its independent one-dimensional quadrature oracle
gave an observed-data negative-log-likelihood difference of `0.0109669` from
the TMB/Laplace objective on the fixed test DGP, below its `0.05` test
tolerance. This verifies the route as an experimental numerical proof only;
it does not supply a Poisson recovery or coverage claim.

## Current state

**SUPERSEDED by the completion receipt below.** The DRAC sockets were expired,
so this exact preregistered campaign ran on Totoro instead on 2026-08-13, using
60 one-core workers (below the binding 150-core cap). All 60 shards and all
3,000 attempts completed and are retained under
`docs/dev-log/simulation-artifacts/2026-08-13-joint-mi-gaussian-recovery/`.
The completed run did not use GitHub Actions. See
`2026-08-13-joint-mi-gaussian-recovery-completion.md` for immutable receipts
and the earned verdict.
