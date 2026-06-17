# Skew-normal fixed-effect ADEMP pilot

_Generated 2026-06-10 by `tools/skew-normal-pilot.R`._

Formal ADEMP pilot (Morris, White & Crowther 2019, *Stat. Med.*;
reported per Williams et al. 2024, *Methods Ecol. Evol.* 11-item checklist)
for drmTMB's **fixed-effect** `skew_normal()` family. Scope is fixed-effect
only -- no random / structured / bivariate / `rho12` / skew-t.

## Design

- **Conditions:** n in {100, 400} x true slant nu in {0, 4} = 4 cells.
- **Replicates:** 200 per cell (master seed 20260610; per-(cell,rep) seeds).
- **Truth:** mu = 0.20 + 0.45 x, sigma = 1.00 (constant), nu in {0, 4}.
- **Estimator:** `drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = skew_normal(),`
  `control = drm_control(optimizer_preset = "careful"))`.
- **CI / coverage level:** 95% (Wald).
- `sigma:(Intercept)` truth is on the **log** scale (= log(1.00) = 0.000).
- **Runtime:** 23.6 s on R 4.5.2, drmTMB 0.1.3.9000.

Performance measures are computed over **converged + pdHess** fits; the
convergence and pdHess rates are reported separately so no failed fit is
silently dropped (Williams item 10b). MCSE in parentheses.

## Convergence

| cell | n | nu | reps | converged | pdHess | n used |
|---|---|---|---|---|---|---|
| `skew_fe_n0100_nu00` | 100 | 0 | 200 | 100.0% | 100.0% | 200 |
| `skew_fe_n0400_nu00` | 400 | 0 | 200 | 100.0% | 100.0% | 200 |
| `skew_fe_n0100_nu04` | 100 | 4 | 200 | 96.0% | 96.0% | 192 |
| `skew_fe_n0400_nu04` | 400 | 4 | 200 | 100.0% | 100.0% | 200 |

## Bias & RMSE (MCSE)

| cell | parameter | truth | n used | bias (MCSE) | RMSE (MCSE) |
|---|---|---|---|---|---|
| `skew_fe_n0100_nu00` | mu:(Intercept) | 0.20 | 200 | 0.012 (0.007) | 0.100 (0.032) |
| `skew_fe_n0100_nu00` | mu:x | 0.45 | 200 | -0.005 (0.007) | 0.095 (0.030) |
| `skew_fe_n0100_nu00` | sigma:(Intercept) | 0.00 | 200 | -0.010 (0.005) | 0.072 (0.023) |
| `skew_fe_n0100_nu00` | nu:(Intercept) | 0.00 | 200 | -0.106 (0.093) | 1.322 (0.361) |
| `skew_fe_n0400_nu00` | mu:(Intercept) | 0.20 | 200 | -0.003 (0.003) | 0.044 (0.014) |
| `skew_fe_n0400_nu00` | mu:x | 0.45 | 200 | -0.006 (0.004) | 0.051 (0.015) |
| `skew_fe_n0400_nu00` | sigma:(Intercept) | 0.00 | 200 | -0.004 (0.003) | 0.037 (0.013) |
| `skew_fe_n0400_nu00` | nu:(Intercept) | 0.00 | 200 | -0.047 (0.064) | 0.897 (0.203) |
| `skew_fe_n0100_nu04` | mu:(Intercept) | 0.20 | 192 | 0.008 (0.007) | 0.095 (0.031) |
| `skew_fe_n0100_nu04` | mu:x | 0.45 | 192 | -0.003 (0.006) | 0.088 (0.027) |
| `skew_fe_n0100_nu04` | sigma:(Intercept) | 0.00 | 192 | -0.021 (0.006) | 0.085 (0.026) |
| `skew_fe_n0100_nu04` | nu:(Intercept) | 4.00 | 192 | 1.076 (0.285) | 4.079 (2.191) |
| `skew_fe_n0400_nu04` | mu:(Intercept) | 0.20 | 200 | 0.002 (0.003) | 0.049 (0.016) |
| `skew_fe_n0400_nu04` | mu:x | 0.45 | 200 | 0.004 (0.003) | 0.041 (0.013) |
| `skew_fe_n0400_nu04` | sigma:(Intercept) | 0.00 | 200 | -0.000 (0.003) | 0.041 (0.014) |
| `skew_fe_n0400_nu04` | nu:(Intercept) | 4.00 | 200 | 0.217 (0.058) | 0.848 (0.303) |

## Slant interval: availability, coverage, false-positive at nu = 0

| cell | nu | n used | CI avail | coverage (MCSE) | false-pos@nu0 (MCSE) |
|---|---|---|---|---|---|
| `skew_fe_n0100_nu00` | 0 | 200 | 100.0% | 76.0% (3.0%) | 24.0% (3.0%) |
| `skew_fe_n0400_nu00` | 0 | 200 | 100.0% | 59.5% (3.5%) | 40.5% (3.5%) |
| `skew_fe_n0100_nu04` | 4 | 192 | 100.0% | 91.7% (2.0%) | -- |
| `skew_fe_n0400_nu04` | 4 | 200 | 100.0% | 95.0% (1.5%) | -- |

_Coverage = fraction of replicates whose Wald CI for `nu:(Intercept)`
contains the truth. False-positive@nu0 = fraction whose CI **excludes 0**
when the truth is nu = 0 (a Type-I rate; nominal target ~5%)._

## Reproduce

```sh
/usr/local/bin/Rscript tools/skew-normal-pilot.R
```

Scale precision by raising `N_REPS` (currently 200) at the top of the
script: 500 -> coverage MCSE ~1%, 1000 -> ~0.7%.

