# Wave 2: joint mean + sigma random effects, structured sigma, stress case 6a

Reader: whoever decides parity-matrix rows 3, 13 and 18 (see
`../PROPOSED-verdict-flips.md`). This folder is evidence only; no verdict or
matrix script is edited here.

Julia: DRModels.jl branch `claude/joint-sigma-wave2-20261107`, tip 81a937ea8 (from
`claude/q2-final-20261107`; pushed, not merged). R: native drmTMB 0.8.1 installed
from `origin/main` (`agree-poisson-q2/lib`). ML, one dataset per shape. Laplace
evidence is likelihood agreement at the optimum only: no coverage, bias, REML,
intervals or bridge (R calling Julia) parity.

## What native R fits (probe: `stress-6a/rprobe*.R`, logs alongside)

| Shape | drmTMB 0.8.1 |
| --- | --- |
| Gaussian `(1 \| id)` mean + `(1 \| id)` sigma, both with SD formulas (same group) | fits |
| Gaussian same group, correlated `(1 \| p \| id)` in mu and sigma, no SD formula | fits |
| Gaussian correlated `(1 \| p \| id)` + SD formulas | refused |
| Gaussian `sigma ~ 1 + phylo(1 \| id)`, `sd(id, level = "phylogenetic", dpar = "sigma")` | fits |
| Gaussian `sigma ~ 1 + spatial(1 \| id)`, `sd(id, level = "spatial", dpar = "sigma")` | fits (fixed range = median distance) |
| NB2 / Gamma joint mu + sigma intercepts with both SD formulas, crossed or same group | fits |
| NB2 / Gamma joint without SD formulas, or with a sigma slope | refused |

So `DESIGN-joint-sigma.md`'s statement that R refuses phylo sigma was wrong: the
level name is `"phylogenetic"`, not `"phylo"`.

## Agreement at the optimum (Julia vs native R, same data)

Each Julia shape also has a test against an independent dense Laplace oracle at
the fitted parameters (|logLik - oracle| < 1e-5): `test/test_joint_sigma_wave2.jl`
(NB2, Gamma, Gaussian same group, Gaussian correlated, kernels vs ForwardDiff,
refusals) and `test/test_gaussian_sigma_phylo_spatial_sd.jl` (phylo, spatial,
constant-SD limit, refusals).

Files: `julia_fit.jl`, `r_fit_compare.R` -> `comparison.csv`;
`julia_fit_structured.jl`, `r_fit_compare_structured.R` -> `comparison_structured.csv`.

| Case | params | max abs diff | max diff (SE units) | max SE rel diff | logLik R | logLik Julia | diff |
| --- | --- | --- | --- | --- | --- | --- | --- |
| NB2 crossed (30 id x 24 g, n 600) | 7 | 5.0e-8 | 9.0e-8 | 4.0e-7 | -1110.7409394814 | -1110.7409394814 | -9e-13 |
| NB2 same group | 7 | 1.0e-7 | 1.7e-7 | 4.4e-7 | -1245.6410793900 | -1245.6410793900 | 7.5e-12 |
| Gamma crossed | 7 | 0.37 | 1.93 | 0.27 | -832.5245271528 | -832.5085162004 | 0.016 |
| Gamma same group | 7 | 3.0e-12 | 9.0e-12 | 1.8e-6 | -916.0598285969 | -916.0598285968 | 1.3e-11 |
| Gaussian same group, both SD formulas | 7 | 1.5e-10 | 3.6e-10 | 1.9e-6 | -522.5933117099 | -522.5933117099 | 3.8e-11 |
| Gaussian phylo sigma + SD (48 tips) | 5 | 8.1e-9 | 2.6e-7 | 5.1e-6 | -937.4036633479 | -937.4036633464 | 1.5e-9 |
| Gaussian spatial sigma + SD (48 sites) | 5 | 4.6e-11 | 4.3e-10 | 3.5e-6 | -555.4360217410 | -555.4360217410 | 5.5e-11 |
| Gaussian correlated `(1 \| p \| id)` mu + sigma, no SD (40 groups, n 800) | 6 | 1.2e-8 | 6.1e-8 | 3.7e-6 | -701.2339661907 | -701.2339661907 | 8.3e-12 |

The correlated case reports rho = 0.6684865 in both (Julia `tanh(eta)`, R
`corpars$mu_sigma`); files `julia_fit_corr.jl`, `r_fit_compare_corr.R`,
`comparison_corr.csv`.

**Gamma crossed is a different local maximum, not a different likelihood.**
`gamma_crossed_probe.R`: R's own Laplace objective at Julia's estimate is
-832.5085161977 (Julia -832.5085162004, diff 2.7e-9) with gradient 1e-7, i.e. a
stationary point of R's objective too; R's default start converged (gradient
5e-9) to a lower maximum, -832.5245. Restarting R's `nlminb` at Julia's estimate
stays there (parameter diff 0, SE rel diff 7e-5). The outer surface has two
maxima; Julia reached the higher one. One dataset; whether R or Julia lands on
the better maximum more often is not shown.

## Stress case 6a: diagnosis (Gaussian `sigma ~ 1 + (1 | site)`, 200 x 200, n 2400, seed 20261110)

Verdict: **inner-mode multiplicity (a Laplace failure), not identifiability,
parameter scaling, outer start values or the outer optimiser.** Scripts and
logs in `stress-6a/`.

1. The joint density in (mean effect a, log-sigma effect b) is not log-concave
   (each observation's 2x2 block has determinant -2 r^2 e^{-4 eta} < 0). At this
   design (12 observations per site, crossed mean effects) the inner problem has
   at least two positive-definite modes at the same theta. At Julia's reported
   estimate: mode A (reached from v = 0) has joint objective F = 1733.281,
   half log det H = 775.960, Laplace logLik -2141.666; mode B (reached from the
   mode found at R's estimate) has F = 1732.642 (lower, so the global maximiser
   of the joint density), half log det H = 792.268, Laplace logLik -2157.335. In
   mode B site 199's log-sigma effect sits at -2.82 (about -5.6 SD) instead of
   -1.22: a narrow spike. Julia's -2157.335 is the mode-B branch, reached through
   the warm start (`diag2.log`, `diag4.log`).
2. Both packages compute the same Laplace value on the same branch: R's TMB
   objective at Julia's estimate from a zero inner start is -2141.665677, Julia
   (and an independent oracle) -2141.665677 (`r_branch.log`).
3. R's reported -2137.95 is not shown to be a valid Laplace value: at R's
   estimate a trust-region Newton oracle from zero and from R's own mode vector,
   and Julia's engine from a converged start, all find a -2157.99 mode (gradient
   1e-13, Hessian PD; Julia's engine from zero fails there), and R's own objective is
   not reproducible there (-2137.95 at the optimiser's end, -2138.00 from
   `last.par.best`, -2138.86 from a zero inner start, gradient ~1e7). R's inner
   solve does not reach a stationary point there.
4. A deterministic "always take the global joint mode" rule was tried in Julia
   and does not help: it chooses the spike mode, the fit ends at -2155.08, not
   converged, non-PD Hessian (`diag4.log`). Laplace at either peak misses the
   other peak's mass; a principled fix would need an integration method that
   sees both peaks (importance sampling or a mixture of Laplace terms), which
   would no longer match TMB's Laplace definition. Not implemented.

What changed in Julia: the engine now checks, at the estimate, whether a zero
inner start reaches a different Laplace value than the optimiser's path. If so it
warns ("the random-effect mode is not unique at the estimate ... the fit is
marked not converged") and sets `converged = false`. Test:
`test/test_joint_sigma_multimodal.jl` (this exact fixture, about 30 s). R gives
no such warning (it reports false convergence code 1 on this data).

Treat crossed sigma-intercept designs with few observations per sigma group as
unreliable in both packages. The failure is detectable in Julia; it is not fixed.

## Not covered

* Other seeds, REML, intervals, conditional modes (BLUPs), prediction, the R
  bridge, labelled structured forms.
* NB2/Gamma structured sigma, NB2/Gamma sigma slopes (R refuses those slopes
  in the joint route).
