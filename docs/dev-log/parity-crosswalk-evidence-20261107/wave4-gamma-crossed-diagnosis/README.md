# Wave 4: Gamma crossed joint mu+sigma SD, R-vs-Julia 0.016 loglik gap

Reader: whoever decides the parity-matrix row for joint mu + sigma SD regression, Gamma crossed (row 18 in `../PROPOSED-verdict-flips.md`; this folder's earlier name for it was "row 3").
Evidence only. Data: `../wave2-joint-sigma/data_gamma_crossed.csv` (30 id x 24 g, n 600), model
`bf(y ~ x + (1|id), sigma ~ 1 + (1|g), sd(id) ~ w, sd(g, sigma) ~ z)`, Gamma log link, ML Laplace.
Julia: DRModels at 04581709d (no source change). R: native drmTMB 0.8.1. Parameter layout identical in both
(mu 2, sigma 1, sd(id) 2, sd(g) 2).

## Verdict

**Pure outer multimodality. Julia's default fit is the better optimum, not the worse one. No bug, no definition
difference; no source change.**

(a) Independent oracle (`oracle.jl`: raw-coordinate dense Laplace, hand-written Gamma/Normal log densities,
ForwardDiff Hessian, own damped-Newton inner solver, 21 inner starts per theta; `step1_oracle_eval.jl`):
| estimate | oracle Laplace logLik | engine value |
| --- | --- | --- |
| Julia | -832.50851620 | Julia -832.50851620; R's TMB objective at it -832.5085161977 (wave 2) |
| R (6 s.f. theta) | -832.52452715 | R -832.5245 (R's own objective, gradient 5e-9) |
The inner random-effect mode is unique at both thetas (all 21 starts agree): the Gamma/crossed gap is not a
Laplace inner-mode problem (contrast stress case 6a). Julia is higher by 0.0160.

(b) Start values (`julia_multistart.log`, `r_multistart.log`): Julia started at R's estimate stays there
(-832.52452715, converged, PD; `from_R_est`). Julia started at its own estimate stays. R's `nlminb` restarted at
Julia's estimate stays at -832.5085162 (gradient 1e-7, also wave 2). Both are genuine, converged, PD maxima of both
packages' objectives.

(c) Multistart, 30 random starts per side (`base + N(0, s^2)`, s = 0.5 and 1.0, same distribution):
| side | -832.5245 (R's) | -832.5085 (Julia's) | other | Hessian PD | converge flag |
| --- | --- | --- | --- | --- | --- |
| Julia | 14 | 16 | 0 | 30/30 | 30/30 true |
| R (nlminb on drmTMB objective) | 25 | 5 | 0 | 30/30 | code 0: 4, code 1: 26 |
Exactly two optima, no others, on either side. Julia's default start lands on the higher one; R's default start on the
lower one. R's code 1 (false convergence) arises because rel.tol 1e-12 is below the noise of the inner solve (max gradient
1e-4); those fits still sit at the same two optima. The split of basins (Julia 16/30, R 5/30 for the higher max) is one
dataset and one start distribution; it does not show that R is generally worse.

(d) Why two maxima (`step4_segment_profile.jl`, `segment_profile.log`): along the straight line between the two
estimates the oracle logLik dips by about 0.7 (to -833.21 at t about 0.62) and recovers, inner mode unique throughout, so there
is a real (small) barrier in the outer surface. The weakly identified block is the SD regressions: sd(g) intercept and `z` slope SEs
are 0.81 and 1.06 (24 sigma groups), sd(id) slope 0.19; the two optima differ mostly in sd(id) (-1.46, 1.16 vs -1.16, 0.79) and the
sd(g) slope (-1.76 vs -1.94). Size of the difference: log-lik gap 0.016 (2 x gap = 0.03); the sd(id) slope differs by 1.9 SE (0.37 on an SE of 0.19), so the fits are not shown to be
distinguishable by likelihood, but the SD estimates are not the same; R lands on the lower optimum in 25 of 30 random starts. The mean and sigma fixed effects differ by at most 0.003 (mu) and 0.002 (sigma); the differences are in the SD parameters (up to 0.37).

## What changed

Nothing in DRModels (branch `claude/gamma-crossed-diagnosis-20261108` has no commits; not pushed). Julia's default
start finding the higher optimum means a multistart option is not needed for parity; adding one would be new surface
for no demonstrated defect. A temporary internal `start` keyword was used for the Julia runs: see `start-kwarg.patch.txt`
(`step2_julia_multistart.jl` needs it).

## Suggested matrix wording

Gamma crossed joint mu+sigma (row 18): "agrees at the shared stationary point (R's objective at Julia's estimate equals Julia's to 3e-9);
the default fits land on different local maxima of a bimodal outer surface (two optima, 0.016 apart, barrier about 0.7);
Julia's is the higher". Do not record this as an engine disagreement.

## Not covered

One dataset (seed 2026110703), one start distribution; other seeds, NB2 crossed (agreed to 1e-12 on its dataset), REML,
sigma-group sizes smaller than 24 (see stress-6a for the inner-mode failure at 200 x 200, n 2400).
