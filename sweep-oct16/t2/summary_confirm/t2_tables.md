### Convergence (pass bar: converged rate >= 99%)

| engine | cell | converged / reps | rate | errors | status counts | median fit s | pass |
|---|---|---:|---:|---:|---|---:|:---:|
| DRModels | n0200_none | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.000 | PASS |
| DRModels | n1000_none | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.002 | PASS |
| DRModels | n0200_G20 | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.001 | PASS |
| DRModels | n1000_G20 | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.004 | PASS |
| DRModels | n0200_G50 | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.001 | PASS |
| DRModels | n1000_G50 | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.004 | PASS |
| drmTMB | n0200_none | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.037 | PASS |
| drmTMB | n1000_none | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.059 | PASS |
| drmTMB | n0200_G20 | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.142 | PASS |
| drmTMB | n1000_G20 | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.459 | PASS |
| drmTMB | n0200_G50 | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.140 | PASS |
| drmTMB | n1000_G50 | 2000 / 2000 | 100.0% | 0 | converged:2000 | 0.474 | PASS |

### Bias and Wald coverage (converged fits)

Relative bias is (mean estimate - truth) / truth, with its Monte Carlo SE.
Coverage is the share of nominal 95% Wald intervals containing the truth,
with its binomial Monte Carlo SE. Gate cells (n >= 200) are marked PASS/FAIL;
n = 50 cells are reported only.

| engine | cell | parameter | n_conv | rel. bias (MCSE) | median rel. bias | SE/SD | coverage (MCSE) | below / above | bias | coverage |
|---|---|---|---:|---:|---:|---:|---:|---:|:---:|:---:|
| DRModels | n0200_none | mu_intercept | 2000 | +0.13% (0.08) | +0.09% | 0.973 | 93.2% (0.6) | 4.0% / 2.8% | PASS | PASS |
| DRModels | n0200_none | mu_x | 2000 | -0.19% (0.17) | -0.05% | 0.979 | 94.5% (0.5) | 3.0% / 2.5% | PASS | PASS |
| DRModels | n0200_none | sigma_intercept | 2000 | +2.20% (0.22) | +1.98% | 1.033 | 95.0% (0.5) | 1.0% / 4.0% | PASS | PASS |
| DRModels | n0200_none | sigma_z | 2000 | +1.25% (0.29) | +1.24% | 1.004 | 95.4% (0.5) | 2.9% / 1.7% | PASS | PASS |
| DRModels | n1000_none | mu_intercept | 2000 | -0.08% (0.04) | -0.06% | 0.990 | 94.7% (0.5) | 2.0% / 3.3% | PASS | PASS |
| DRModels | n1000_none | mu_x | 2000 | -0.08% (0.07) | -0.01% | 0.998 | 94.9% (0.5) | 2.3% / 2.8% | PASS | PASS |
| DRModels | n1000_none | sigma_intercept | 2000 | +0.55% (0.10) | +0.44% | 0.997 | 95.2% (0.5) | 1.6% / 3.2% | PASS | PASS |
| DRModels | n1000_none | sigma_z | 2000 | +0.14% (0.12) | +0.11% | 1.033 | 95.8% (0.5) | 2.4% / 1.8% | PASS | PASS |
| DRModels | n0200_G20 | mu_intercept | 2000 | -0.04% (0.27) | -0.17% | 0.957 | 92.9% (0.6) | 3.4% / 3.7% | PASS | **FAIL** |
| DRModels | n0200_G20 | mu_x | 2000 | -0.22% (0.18) | -0.21% | 0.976 | 94.6% (0.5) | 3.2% / 2.1% | PASS | PASS |
| DRModels | n0200_G20 | sigma_intercept | 2000 | +1.96% (0.23) | +1.55% | 1.013 | 94.5% (0.5) | 1.2% / 4.2% | PASS | PASS |
| DRModels | n0200_G20 | sigma_z | 2000 | +0.79% (0.32) | +0.66% | 0.988 | 94.2% (0.5) | 3.4% / 2.5% | PASS | PASS |
| DRModels | n0200_G20 | sd_g | 2000 | -4.19% (0.40) | -4.32% | 0.929 | 93.7% (0.5) | 0.9% / 5.5% | PASS | PASS |
| DRModels | n1000_G20 | mu_intercept | 2000 | -0.52% (0.25) | -0.52% | 0.962 | 92.5% (0.6) | 2.9% / 4.5% | PASS | **FAIL** |
| DRModels | n1000_G20 | mu_x | 2000 | -0.09% (0.07) | -0.06% | 0.997 | 94.8% (0.5) | 2.8% / 2.4% | PASS | PASS |
| DRModels | n1000_G20 | sigma_intercept | 2000 | +0.49% (0.10) | +0.38% | 0.995 | 94.7% (0.5) | 1.8% / 3.6% | PASS | PASS |
| DRModels | n1000_G20 | sigma_z | 2000 | +0.09% (0.13) | -0.13% | 1.030 | 95.5% (0.5) | 2.4% / 2.1% | PASS | PASS |
| DRModels | n1000_G20 | sd_g | 2000 | -4.37% (0.36) | -4.72% | 0.931 | 92.3% (0.6) | 0.4% / 7.2% | PASS | **FAIL** |
| DRModels | n0200_G50 | mu_intercept | 2000 | +0.04% (0.18) | +0.18% | 1.001 | 94.7% (0.5) | 2.2% / 3.1% | PASS | PASS |
| DRModels | n0200_G50 | mu_x | 2000 | -0.23% (0.20) | -0.26% | 0.972 | 94.2% (0.5) | 2.9% / 2.9% | PASS | PASS |
| DRModels | n0200_G50 | sigma_intercept | 2000 | +2.11% (0.26) | +1.88% | 1.016 | 95.2% (0.5) | 1.1% / 3.8% | PASS | PASS |
| DRModels | n0200_G50 | sigma_z | 2000 | +0.64% (0.37) | +1.00% | 0.991 | 95.1% (0.5) | 2.5% / 2.4% | PASS | PASS |
| DRModels | n0200_G50 | sd_g | 2000 | -1.95% (0.30) | -1.70% | 0.949 | 95.3% (0.5) | 1.3% / 3.4% | PASS | PASS |
| DRModels | n1000_G50 | mu_intercept | 2000 | -0.35% (0.16) | -0.28% | 1.005 | 94.3% (0.5) | 2.3% / 3.4% | PASS | PASS |
| DRModels | n1000_G50 | mu_x | 2000 | -0.06% (0.08) | -0.09% | 1.000 | 94.4% (0.5) | 2.8% / 2.8% | PASS | PASS |
| DRModels | n1000_G50 | sigma_intercept | 2000 | +0.47% (0.10) | +0.46% | 0.998 | 95.3% (0.5) | 1.6% / 3.0% | PASS | PASS |
| DRModels | n1000_G50 | sigma_z | 2000 | +0.07% (0.13) | -0.20% | 1.037 | 95.6% (0.5) | 2.4% / 2.0% | PASS | PASS |
| DRModels | n1000_G50 | sd_g | 2000 | -1.66% (0.24) | -1.81% | 0.963 | 93.8% (0.5) | 1.2% / 5.0% | PASS | PASS |
| drmTMB | n0200_none | mu_intercept | 2000 | +0.13% (0.08) | +0.09% | 0.973 | 93.2% (0.6) | 4.0% / 2.8% | PASS | PASS |
| drmTMB | n0200_none | mu_x | 2000 | -0.19% (0.17) | -0.05% | 0.979 | 94.5% (0.5) | 3.0% / 2.5% | PASS | PASS |
| drmTMB | n0200_none | sigma_intercept | 2000 | +2.20% (0.22) | +1.98% | 1.033 | 95.0% (0.5) | 1.0% / 4.0% | PASS | PASS |
| drmTMB | n0200_none | sigma_z | 2000 | +1.25% (0.29) | +1.24% | 1.004 | 95.4% (0.5) | 2.9% / 1.7% | PASS | PASS |
| drmTMB | n1000_none | mu_intercept | 2000 | -0.08% (0.04) | -0.06% | 0.990 | 94.7% (0.5) | 2.0% / 3.3% | PASS | PASS |
| drmTMB | n1000_none | mu_x | 2000 | -0.08% (0.07) | -0.01% | 0.998 | 94.9% (0.5) | 2.3% / 2.8% | PASS | PASS |
| drmTMB | n1000_none | sigma_intercept | 2000 | +0.55% (0.10) | +0.44% | 0.997 | 95.2% (0.5) | 1.6% / 3.2% | PASS | PASS |
| drmTMB | n1000_none | sigma_z | 2000 | +0.14% (0.12) | +0.11% | 1.033 | 95.8% (0.5) | 2.4% / 1.8% | PASS | PASS |
| drmTMB | n0200_G20 | mu_intercept | 2000 | -0.04% (0.27) | -0.17% | 0.957 | 92.9% (0.6) | 3.4% / 3.7% | PASS | **FAIL** |
| drmTMB | n0200_G20 | mu_x | 2000 | -0.22% (0.18) | -0.21% | 0.976 | 94.6% (0.5) | 3.2% / 2.1% | PASS | PASS |
| drmTMB | n0200_G20 | sigma_intercept | 2000 | +1.96% (0.23) | +1.55% | 1.013 | 94.5% (0.5) | 1.2% / 4.2% | PASS | PASS |
| drmTMB | n0200_G20 | sigma_z | 2000 | +0.79% (0.32) | +0.66% | 0.988 | 94.2% (0.5) | 3.4% / 2.5% | PASS | PASS |
| drmTMB | n0200_G20 | sd_g | 2000 | -4.19% (0.40) | -4.32% | 0.929 | 93.7% (0.5) | 0.9% / 5.5% | PASS | PASS |
| drmTMB | n1000_G20 | mu_intercept | 2000 | -0.52% (0.25) | -0.52% | 0.962 | 92.5% (0.6) | 2.9% / 4.5% | PASS | **FAIL** |
| drmTMB | n1000_G20 | mu_x | 2000 | -0.09% (0.07) | -0.06% | 0.997 | 94.8% (0.5) | 2.8% / 2.4% | PASS | PASS |
| drmTMB | n1000_G20 | sigma_intercept | 2000 | +0.49% (0.10) | +0.38% | 0.995 | 94.7% (0.5) | 1.8% / 3.6% | PASS | PASS |
| drmTMB | n1000_G20 | sigma_z | 2000 | +0.09% (0.13) | -0.13% | 1.030 | 95.5% (0.5) | 2.4% / 2.1% | PASS | PASS |
| drmTMB | n1000_G20 | sd_g | 2000 | -4.37% (0.36) | -4.72% | 0.931 | 92.3% (0.6) | 0.4% / 7.2% | PASS | **FAIL** |
| drmTMB | n0200_G50 | mu_intercept | 2000 | +0.04% (0.18) | +0.18% | 1.001 | 94.7% (0.5) | 2.2% / 3.1% | PASS | PASS |
| drmTMB | n0200_G50 | mu_x | 2000 | -0.23% (0.20) | -0.26% | 0.972 | 94.2% (0.5) | 2.9% / 2.9% | PASS | PASS |
| drmTMB | n0200_G50 | sigma_intercept | 2000 | +2.11% (0.26) | +1.88% | 1.016 | 95.2% (0.5) | 1.1% / 3.8% | PASS | PASS |
| drmTMB | n0200_G50 | sigma_z | 2000 | +0.64% (0.37) | +1.00% | 0.991 | 95.1% (0.5) | 2.5% / 2.4% | PASS | PASS |
| drmTMB | n0200_G50 | sd_g | 2000 | -1.95% (0.30) | -1.70% | 0.949 | 95.3% (0.5) | 1.3% / 3.4% | PASS | PASS |
| drmTMB | n1000_G50 | mu_intercept | 2000 | -0.35% (0.16) | -0.28% | 1.005 | 94.3% (0.5) | 2.3% / 3.4% | PASS | PASS |
| drmTMB | n1000_G50 | mu_x | 2000 | -0.06% (0.08) | -0.09% | 1.000 | 94.4% (0.5) | 2.8% / 2.8% | PASS | PASS |
| drmTMB | n1000_G50 | sigma_intercept | 2000 | +0.47% (0.10) | +0.46% | 0.998 | 95.3% (0.5) | 1.6% / 3.0% | PASS | PASS |
| drmTMB | n1000_G50 | sigma_z | 2000 | +0.07% (0.13) | -0.20% | 1.037 | 95.6% (0.5) | 2.4% / 2.0% | PASS | PASS |
| drmTMB | n1000_G50 | sd_g | 2000 | -1.66% (0.24) | -1.81% | 0.963 | 93.8% (0.5) | 1.2% / 5.0% | PASS | PASS |

### Cross-engine agreement on identical datasets

Estimates and SEs are compared on reps where both engines converged, excluding
reps where either engine puts sd(g) below 1e-4 (a flat log-sd direction; counted, not compared).

| cell | both converged | of which sd(g) < 1e-4 (excluded) | only drmTMB | only DRModels | max abs dlogLik | reps with abs dlogLik > 1e-4 (DRModels higher / drmTMB higher) | max abs d(link est) | SE ratio range |
|---|---:|---:|---:|---:|---:|---|---:|---|
| n0200_none | 2000 | 0 | 0 | 0 | 1.02e-12 | 0 (0 / 0) | 4.35e-11 | 1.0000 - 1.0000 |
| n1000_none | 2000 | 0 | 0 | 0 | 1.75e-11 | 0 (0 / 0) | 9.25e-12 | 1.0000 - 1.0000 |
| n0200_G20 | 2000 | 0 | 0 | 0 | 1.25e-12 | 0 (0 / 0) | 3.59e-10 | 1.0000 - 1.0000 |
| n1000_G20 | 2000 | 0 | 0 | 0 | 1.76e-11 | 0 (0 / 0) | 2.56e-10 | 1.0000 - 1.0000 |
| n0200_G50 | 2000 | 0 | 0 | 0 | 1.68e-12 | 0 (0 / 0) | 3.36e-10 | 1.0000 - 1.0000 |
| n1000_G50 | 2000 | 0 | 0 | 0 | 1.92e-11 | 0 (0 / 0) | 1.38e-10 | 1.0000 - 1.0000 |
