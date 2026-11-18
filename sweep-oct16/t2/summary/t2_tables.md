### Convergence (pass bar: converged rate >= 99%)

| engine | cell | converged / reps | rate | errors | status counts | median fit s | pass |
|---|---|---:|---:|---:|---|---:|:---:|
| DRModels | n0050_none | 500 / 500 | 100.0% | 0 | converged:500 | 0.000 | PASS |
| DRModels | n0200_none | 500 / 500 | 100.0% | 0 | converged:500 | 0.000 | PASS |
| DRModels | n1000_none | 500 / 500 | 100.0% | 0 | converged:500 | 0.002 | PASS |
| DRModels | n0050_G20 | 493 / 500 | 98.6% | 0 | converged:493 not_converged:7 | 0.000 | **FAIL** |
| DRModels | n0200_G20 | 500 / 500 | 100.0% | 0 | converged:500 | 0.001 | PASS |
| DRModels | n1000_G20 | 500 / 500 | 100.0% | 0 | converged:500 | 0.004 | PASS |
| DRModels | n0050_G50 | 306 / 500 | 61.2% | 4 | converged:306 error:4 not_converged:190 | 0.001 | **FAIL** |
| DRModels | n0200_G50 | 500 / 500 | 100.0% | 0 | converged:500 | 0.001 | PASS |
| DRModels | n1000_G50 | 500 / 500 | 100.0% | 0 | converged:500 | 0.005 | PASS |
| drmTMB | n0050_none | 500 / 500 | 100.0% | 0 | converged:500 | 0.036 | PASS |
| drmTMB | n0200_none | 500 / 500 | 100.0% | 0 | converged:500 | 0.039 | PASS |
| drmTMB | n1000_none | 500 / 500 | 100.0% | 0 | converged:500 | 0.056 | PASS |
| drmTMB | n0050_G20 | 500 / 500 | 100.0% | 0 | boundary:13 converged:487 | 0.095 | PASS |
| drmTMB | n0200_G20 | 500 / 500 | 100.0% | 0 | converged:500 | 0.150 | PASS |
| drmTMB | n1000_G20 | 500 / 500 | 100.0% | 0 | converged:500 | 0.454 | PASS |
| drmTMB | n0050_G50 | 0 / 500 | 0.0% | 500 | error:500 | 0.020 | **FAIL** |
| drmTMB | n0200_G50 | 500 / 500 | 100.0% | 0 | converged:500 | 0.142 | PASS |
| drmTMB | n1000_G50 | 500 / 500 | 100.0% | 0 | converged:500 | 0.483 | PASS |

### Bias and Wald coverage (converged fits)

Relative bias is (mean estimate - truth) / truth, with its Monte Carlo SE.
Coverage is the share of nominal 95% Wald intervals containing the truth,
with its binomial Monte Carlo SE. Gate cells (n >= 200) are marked PASS/FAIL;
n = 50 cells are reported only.

| engine | cell | parameter | n_conv | rel. bias (MCSE) | median rel. bias | SE/SD | coverage (MCSE) | below / above | bias | coverage |
|---|---|---|---:|---:|---:|---:|---:|---:|:---:|:---:|
| DRModels | n0050_none | mu_intercept | 500 | -0.09% (0.35) | +0.14% | 0.942 | 92.2% (1.2) | 3.4% / 4.4% | report | report |
| DRModels | n0050_none | mu_x | 500 | -0.66% (0.68) | -0.93% | 0.962 | 94.2% (1.0) | 2.4% / 3.4% | report | report |
| DRModels | n0050_none | sigma_intercept | 500 | +7.16% (0.96) | +6.01% | 0.948 | 90.4% (1.3) | 1.4% / 8.2% | report | report |
| DRModels | n0050_none | sigma_z | 500 | +4.31% (1.32) | +4.30% | 0.956 | 93.8% (1.1) | 3.8% / 2.4% | report | report |
| DRModels | n0200_none | mu_intercept | 500 | +0.02% (0.18) | -0.07% | 0.921 | 92.0% (1.2) | 4.2% / 3.8% | PASS | **FAIL** |
| DRModels | n0200_none | mu_x | 500 | -0.26% (0.34) | -0.32% | 0.956 | 94.0% (1.1) | 3.2% / 2.8% | PASS | PASS |
| DRModels | n0200_none | sigma_intercept | 500 | +1.43% (0.46) | +1.43% | 0.968 | 94.2% (1.0) | 2.6% / 3.2% | PASS | PASS |
| DRModels | n0200_none | sigma_z | 500 | +1.37% (0.57) | +1.24% | 1.007 | 94.8% (1.0) | 2.6% / 2.6% | PASS | PASS |
| DRModels | n1000_none | mu_intercept | 500 | +0.08% (0.07) | +0.13% | 1.004 | 95.6% (0.9) | 1.8% / 2.6% | PASS | PASS |
| DRModels | n1000_none | mu_x | 500 | +0.06% (0.14) | -0.07% | 1.044 | 94.6% (1.0) | 3.6% / 1.8% | PASS | PASS |
| DRModels | n1000_none | sigma_intercept | 500 | +0.37% (0.19) | +0.50% | 1.047 | 97.2% (0.7) | 1.4% / 1.4% | PASS | **FAIL** |
| DRModels | n1000_none | sigma_z | 500 | +0.24% (0.25) | +0.33% | 1.002 | 95.0% (1.0) | 2.8% / 2.2% | PASS | PASS |
| DRModels | n0050_G20 | mu_intercept | 493 | -0.75% (0.64) | -0.69% | 0.941 | 90.7% (1.3) | 3.4% / 5.9% | report | report |
| DRModels | n0050_G20 | mu_x | 493 | -1.02% (0.85) | -1.32% | 0.987 | 94.3% (1.0) | 2.6% / 3.0% | report | report |
| DRModels | n0050_G20 | sigma_intercept | 493 | +9.24% (1.34) | +7.33% | 0.930 | 92.7% (1.2) | 1.0% / 6.3% | report | report |
| DRModels | n0050_G20 | sigma_z | 493 | +2.34% (1.86) | +1.70% | 0.946 | 94.1% (1.1) | 2.2% / 3.7% | report | report |
| DRModels | n0050_G20 | sd_g | 493 | -7.46% (1.26) | -4.73% | 0.189 | 98.2% (0.6) | 1.0% / 0.8% | report | report |
| DRModels | n0200_G20 | mu_intercept | 500 | +0.62% (0.50) | +0.64% | 1.002 | 94.0% (1.1) | 3.8% / 2.2% | PASS | PASS |
| DRModels | n0200_G20 | mu_x | 500 | -0.42% (0.36) | -0.34% | 0.984 | 94.6% (1.0) | 2.6% / 2.8% | PASS | PASS |
| DRModels | n0200_G20 | sigma_intercept | 500 | +1.06% (0.50) | +0.29% | 0.948 | 93.2% (1.1) | 3.0% / 3.8% | PASS | PASS |
| DRModels | n0200_G20 | sigma_z | 500 | +1.11% (0.64) | +0.42% | 1.010 | 94.8% (1.0) | 2.8% / 2.4% | PASS | PASS |
| DRModels | n0200_G20 | sd_g | 500 | -4.98% (0.80) | -4.40% | 0.873 | 93.2% (1.1) | 0.0% / 6.8% | PASS | PASS |
| DRModels | n1000_G20 | mu_intercept | 500 | +0.24% (0.51) | +0.73% | 0.960 | 92.6% (1.2) | 3.8% / 3.6% | PASS | **FAIL** |
| DRModels | n1000_G20 | mu_x | 500 | +0.03% (0.14) | -0.12% | 1.044 | 95.0% (1.0) | 3.2% / 1.8% | PASS | PASS |
| DRModels | n1000_G20 | sigma_intercept | 500 | +0.27% (0.19) | +0.36% | 1.038 | 97.6% (0.7) | 1.6% / 0.8% | PASS | **FAIL** |
| DRModels | n1000_G20 | sigma_z | 500 | +0.04% (0.26) | +0.10% | 1.003 | 95.0% (1.0) | 2.2% / 2.8% | PASS | PASS |
| DRModels | n1000_G20 | sd_g | 500 | -3.40% (0.73) | -4.25% | 0.940 | 92.6% (1.2) | 0.6% / 6.8% | PASS | **FAIL** |
| DRModels | n0050_G50 | mu_intercept | 306 | -0.85% (0.62) | -0.78% | 0.987 | 93.8% (1.4) | 2.6% / 3.6% | report | report |
| DRModels | n0050_G50 | mu_x | 306 | -1.40% (1.24) | +0.91% | 0.999 | 94.1% (1.3) | 2.3% / 3.6% | report | report |
| DRModels | n0050_G50 | sigma_intercept | 306 | +348.68% (84.41) | +58.03% | 0.197 | 92.8% (1.5) | 5.6% / 1.6% | report | report |
| DRModels | n0050_G50 | sigma_z | 306 | +170.39% (45.13) | +48.68% | 0.255 | 96.1% (1.1) | 1.6% / 2.3% | report | report |
| DRModels | n0050_G50 | sd_g | 306 | -3.77% (2.66) | +7.21% | 0.288 | 73.2% (2.5) | 18.6% / 8.2% | report | report |
| DRModels | n0200_G50 | mu_intercept | 500 | +0.07% (0.36) | -0.26% | 0.984 | 94.0% (1.1) | 3.2% / 2.8% | PASS | PASS |
| DRModels | n0200_G50 | mu_x | 500 | -0.40% (0.40) | -0.37% | 0.966 | 94.0% (1.1) | 2.4% / 3.6% | PASS | PASS |
| DRModels | n0200_G50 | sigma_intercept | 500 | +1.95% (0.55) | +2.58% | 0.954 | 94.2% (1.0) | 2.0% / 3.8% | PASS | PASS |
| DRModels | n0200_G50 | sigma_z | 500 | +1.32% (0.74) | +1.37% | 0.991 | 94.2% (1.0) | 3.2% / 2.6% | PASS | PASS |
| DRModels | n0200_G50 | sd_g | 500 | -2.63% (0.60) | -2.77% | 0.967 | 95.8% (0.9) | 1.2% / 3.0% | PASS | PASS |
| DRModels | n1000_G50 | mu_intercept | 500 | +0.29% (0.32) | +0.02% | 0.989 | 94.6% (1.0) | 3.8% / 1.6% | PASS | PASS |
| DRModels | n1000_G50 | mu_x | 500 | +0.05% (0.15) | +0.08% | 1.020 | 94.4% (1.0) | 3.2% / 2.4% | PASS | PASS |
| DRModels | n1000_G50 | sigma_intercept | 500 | +0.26% (0.20) | +0.31% | 1.039 | 96.6% (0.8) | 2.0% / 1.4% | PASS | PASS |
| DRModels | n1000_G50 | sigma_z | 500 | +0.27% (0.27) | +0.22% | 1.003 | 95.4% (0.9) | 3.2% / 1.4% | PASS | PASS |
| DRModels | n1000_G50 | sd_g | 500 | -1.70% (0.48) | -1.81% | 0.949 | 93.8% (1.1) | 1.6% / 4.6% | PASS | PASS |
| drmTMB | n0050_none | mu_intercept | 500 | -0.09% (0.35) | +0.14% | 0.942 | 92.2% (1.2) | 3.4% / 4.4% | report | report |
| drmTMB | n0050_none | mu_x | 500 | -0.66% (0.68) | -0.93% | 0.962 | 94.2% (1.0) | 2.4% / 3.4% | report | report |
| drmTMB | n0050_none | sigma_intercept | 500 | +7.16% (0.96) | +6.01% | 0.948 | 90.4% (1.3) | 1.4% / 8.2% | report | report |
| drmTMB | n0050_none | sigma_z | 500 | +4.31% (1.32) | +4.30% | 0.956 | 93.8% (1.1) | 3.8% / 2.4% | report | report |
| drmTMB | n0200_none | mu_intercept | 500 | +0.02% (0.18) | -0.07% | 0.921 | 92.0% (1.2) | 4.2% / 3.8% | PASS | **FAIL** |
| drmTMB | n0200_none | mu_x | 500 | -0.26% (0.34) | -0.32% | 0.956 | 94.0% (1.1) | 3.2% / 2.8% | PASS | PASS |
| drmTMB | n0200_none | sigma_intercept | 500 | +1.43% (0.46) | +1.43% | 0.968 | 94.2% (1.0) | 2.6% / 3.2% | PASS | PASS |
| drmTMB | n0200_none | sigma_z | 500 | +1.37% (0.57) | +1.24% | 1.007 | 94.8% (1.0) | 2.6% / 2.6% | PASS | PASS |
| drmTMB | n1000_none | mu_intercept | 500 | +0.08% (0.07) | +0.13% | 1.004 | 95.6% (0.9) | 1.8% / 2.6% | PASS | PASS |
| drmTMB | n1000_none | mu_x | 500 | +0.06% (0.14) | -0.07% | 1.044 | 94.6% (1.0) | 3.6% / 1.8% | PASS | PASS |
| drmTMB | n1000_none | sigma_intercept | 500 | +0.37% (0.19) | +0.50% | 1.047 | 97.2% (0.7) | 1.4% / 1.4% | PASS | **FAIL** |
| drmTMB | n1000_none | sigma_z | 500 | +0.24% (0.25) | +0.33% | 1.002 | 95.0% (1.0) | 2.8% / 2.2% | PASS | PASS |
| drmTMB | n0050_G20 | mu_intercept | 500 | -0.78% (0.64) | -0.68% | 0.936 | 90.4% (1.3) | 3.4% / 6.2% | report | report |
| drmTMB | n0050_G20 | mu_x | 500 | -0.93% (0.85) | -1.43% | 0.985 | 94.2% (1.0) | 2.6% / 3.2% | report | report |
| drmTMB | n0050_G20 | sigma_intercept | 500 | +8.88% (1.33) | +6.54% | 0.925 | 92.4% (1.2) | 1.4% / 6.2% | report | report |
| drmTMB | n0050_G20 | sigma_z | 500 | +2.28% (1.84) | +1.90% | 0.945 | 94.0% (1.1) | 2.2% / 3.8% | report | report |
| drmTMB | n0050_G20 | sd_g | 500 | -8.75% (1.33) | -5.18% | 406.182 | 99.0% (0.4) | 1.0% / 0.0% | report | report |
| drmTMB | n0200_G20 | mu_intercept | 500 | +0.62% (0.50) | +0.64% | 1.002 | 94.0% (1.1) | 3.8% / 2.2% | PASS | PASS |
| drmTMB | n0200_G20 | mu_x | 500 | -0.42% (0.36) | -0.34% | 0.984 | 94.6% (1.0) | 2.6% / 2.8% | PASS | PASS |
| drmTMB | n0200_G20 | sigma_intercept | 500 | +1.06% (0.50) | +0.29% | 0.948 | 93.2% (1.1) | 3.0% / 3.8% | PASS | PASS |
| drmTMB | n0200_G20 | sigma_z | 500 | +1.11% (0.64) | +0.42% | 1.010 | 94.8% (1.0) | 2.8% / 2.4% | PASS | PASS |
| drmTMB | n0200_G20 | sd_g | 500 | -4.98% (0.80) | -4.40% | 0.873 | 93.2% (1.1) | 0.0% / 6.8% | PASS | PASS |
| drmTMB | n1000_G20 | mu_intercept | 500 | +0.24% (0.51) | +0.73% | 0.960 | 92.6% (1.2) | 3.8% / 3.6% | PASS | **FAIL** |
| drmTMB | n1000_G20 | mu_x | 500 | +0.03% (0.14) | -0.12% | 1.044 | 95.0% (1.0) | 3.2% / 1.8% | PASS | PASS |
| drmTMB | n1000_G20 | sigma_intercept | 500 | +0.27% (0.19) | +0.36% | 1.038 | 97.6% (0.7) | 1.6% / 0.8% | PASS | **FAIL** |
| drmTMB | n1000_G20 | sigma_z | 500 | +0.04% (0.26) | +0.10% | 1.003 | 95.0% (1.0) | 2.2% / 2.8% | PASS | PASS |
| drmTMB | n1000_G20 | sd_g | 500 | -3.40% (0.73) | -4.25% | 0.940 | 92.6% (1.2) | 0.6% / 6.8% | PASS | **FAIL** |
| drmTMB | n0200_G50 | mu_intercept | 500 | +0.07% (0.36) | -0.26% | 0.984 | 94.0% (1.1) | 3.2% / 2.8% | PASS | PASS |
| drmTMB | n0200_G50 | mu_x | 500 | -0.40% (0.40) | -0.37% | 0.966 | 94.0% (1.1) | 2.4% / 3.6% | PASS | PASS |
| drmTMB | n0200_G50 | sigma_intercept | 500 | +1.95% (0.55) | +2.58% | 0.954 | 94.2% (1.0) | 2.0% / 3.8% | PASS | PASS |
| drmTMB | n0200_G50 | sigma_z | 500 | +1.32% (0.74) | +1.37% | 0.991 | 94.2% (1.0) | 3.2% / 2.6% | PASS | PASS |
| drmTMB | n0200_G50 | sd_g | 500 | -2.63% (0.60) | -2.77% | 0.967 | 95.8% (0.9) | 1.2% / 3.0% | PASS | PASS |
| drmTMB | n1000_G50 | mu_intercept | 500 | +0.29% (0.32) | +0.02% | 0.989 | 94.6% (1.0) | 3.8% / 1.6% | PASS | PASS |
| drmTMB | n1000_G50 | mu_x | 500 | +0.05% (0.15) | +0.08% | 1.020 | 94.4% (1.0) | 3.2% / 2.4% | PASS | PASS |
| drmTMB | n1000_G50 | sigma_intercept | 500 | +0.26% (0.20) | +0.31% | 1.039 | 96.6% (0.8) | 2.0% / 1.4% | PASS | PASS |
| drmTMB | n1000_G50 | sigma_z | 500 | +0.27% (0.27) | +0.22% | 1.003 | 95.4% (0.9) | 3.2% / 1.4% | PASS | PASS |
| drmTMB | n1000_G50 | sd_g | 500 | -1.70% (0.48) | -1.81% | 0.949 | 93.8% (1.1) | 1.6% / 4.6% | PASS | PASS |

### Cross-engine agreement on identical datasets

Estimates and SEs are compared on reps where both engines converged, excluding
reps where either engine puts sd(g) below 1e-4 (a flat log-sd direction; counted, not compared).

| cell | both converged | of which sd(g) < 1e-4 (excluded) | only drmTMB | only DRModels | max abs dlogLik | reps with abs dlogLik > 1e-4 (DRModels higher / drmTMB higher) | max abs d(link est) | SE ratio range |
|---|---:|---:|---:|---:|---:|---|---:|---|
| n0050_none | 500 | 0 | 0 | 0 | 1.28e-13 | 0 (0 / 0) | 1.63e-10 | 1.0000 - 1.0000 |
| n0200_none | 500 | 0 | 0 | 0 | 9.66e-13 | 0 (0 / 0) | 3.77e-11 | 1.0000 - 1.0000 |
| n1000_none | 500 | 0 | 0 | 0 | 1.53e-11 | 0 (0 / 0) | 7.96e-12 | 1.0000 - 1.0000 |
| n0050_G20 | 493 | 7 | 7 | 0 | 9.99e-10 | 0 (0 / 0) | 3.77e-09 | 1.0000 - 1.0000 |
| n0200_G20 | 500 | 0 | 0 | 0 | 1.17e-12 | 0 (0 / 0) | 3.45e-10 | 1.0000 - 1.0000 |
| n1000_G20 | 500 | 0 | 0 | 0 | 1.76e-11 | 0 (0 / 0) | 2.38e-10 | 1.0000 - 1.0000 |
| n0200_G50 | 500 | 0 | 0 | 0 | 1.51e-12 | 0 (0 / 0) | 1.65e-10 | 1.0000 - 1.0000 |
| n1000_G50 | 500 | 0 | 0 | 0 | 1.81e-11 | 0 (0 / 0) | 1.14e-10 | 1.0000 - 1.0000 |
