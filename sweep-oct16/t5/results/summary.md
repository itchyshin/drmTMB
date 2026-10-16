## Pass bars (computed by R/compare.R)

| Bar | Scope | Metric | Value | Verdict |
|---|---|---|---|---|
| Integer weights = row duplication (logLik) | native, 27 cells | max \|ΔlogLik\| | 1.7e-10 | **PASS** |
| Integer weights = row duplication (coefficients) | native, 27 cells | max \|Δ\| over β_μ, β_σ, log SD(g) | 1.5e-10 | **PASS** |
| Same, objective at fixed θ | native, 27 cells | max \|Δ nll(θ̂)\| | 4.0e-10 | **PASS** |
| `weights = NULL` and all-ones = omitted | native, 27 cells | max \|ΔlogLik\| | 0.0e+00 | **PASS** |
| Random positive weights: NA-row drop keeps weights aligned | native, 27 cells | max \|ΔlogLik\| raw vs pre-dropped | 0.0e+00 | **PASS** |
| Weighted logLik = independent Laplace oracle | native, 27 cells × 4 weightings | max \|Δ\| | 4.1e-10 | **PASS** |
| nobs: native = harness complete cases | 27 cells | mismatches | 0 | **PASS** |
| nobs: bridge = native | Gaussian, 9 cells | mismatches | 0 | **PASS** |
| nobs: bridge = native | Poisson/Gamma, 18 cells | fits returned | 0 / 18 | **FAIL** (#1551) |
| nobs: DRModels `drm_listwise` = native | 27 cells | mismatches | 0 | **PASS** |
| nobs: DRModels raw data with `missing` = native | 27 cells | fits returned / matching | 7 / 7 | **FAIL** (#1089: KeyError on missing x; Gaussian (1\|g) refuses missing y) |
| `engine = "julia"` = native | Gaussian, 9 cells | max \|ΔlogLik\| / max \|Δcoef\| | 2.0e-12 / 1.8e-10 | **PASS** |
| `engine = "julia"` = native | Poisson/Gamma, 18 cells | fits returned | 0 / 18 | **FAIL** (#1551) |
| `engine = "julia"` with any `weights` (incl. `NULL`) | 27 cells × 4 | fits returned | 0 / 108 | fenced (#1450; #1502 draft) |
| Julia on duplicated rows = native integer weights | bridge, Gaussian, 9 cells | max \|ΔlogLik\| | 1.0e-12 | **PASS** |
| DRModels direct, complete cases = native | Gaussian, 9 cells | max \|ΔlogLik\| / max \|Δcoef\| | 2.4e-12 / 1.8e-10 | **PASS** |
| DRModels direct, `marginal = :Laplace` = native | Poisson/Gamma, 18 cells | max \|ΔlogLik\| / max \|Δcoef\| | 9.7e-11 / 4.6e-09 | **PASS** |
| DRModels direct, default `:LA` (AGHQ-5) vs native Laplace | Poisson/Gamma, 18 cells | max \|ΔlogLik\| / max \|Δcoef\| | 4.5e-02 / 5.0e-03 | different integrator (informative) |
| DRModels direct on duplicated rows = native integer weights | 27 cells (Laplace for Poisson/Gamma) | max \|ΔlogLik\| / max \|Δcoef\| | 1.6e-10 / 2.0e-08 | **FAIL** |
| DRModels `drm(...; weights = w)` | 27 cells | fits returned | 0 / 27 (`MethodError`) | not implemented (#931, #691; #1061 draft) |
| Explicit `miss_control()` with NA in x: Julia fails like native | Gaussian, 6 cells | Julia fits instead of failing | 6 / 6 | **FAIL** (#1454 comment) |

