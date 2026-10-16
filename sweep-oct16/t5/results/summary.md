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
| nobs: bridge = native | Poisson/Gamma, 18 cells | fits returned | 0 / 18 | **BLOCKED** (drmTMB#1551: aborts after the Julia fit, at the label echo; the R-side drop rule is the family-agnostic one exercised by the Gaussian rows) |
| nobs: DRModels `drm_listwise` = native | 27 cells | mismatches | 0 | **PASS** |
| DRModels `drm_listwise` fit = complete-case fit | 27 cells | max \|ΔlogLik\| / max \|Δslope\| | 0.0e+00 / 0.0e+00 | **PASS** |
| DRModels raw `drm()` with missing y only = complete-case fit | Poisson/Gamma, 4 cells | max \|ΔlogLik\| | 0.0e+00 | **PASS** |
| nobs: DRModels raw data with `missing` = native | 27 cells | fits returned / matching | 7 / 7 | **FAIL** (DRModels.jl#1089: KeyError on missing x; Gaussian (1\|g) refuses missing y) |
| `engine = "julia"` = native | Gaussian, 9 cells | max \|ΔlogLik\| / max \|Δcoef\| | 2.0e-12 / 1.8e-10 | **PASS** |
| `engine = "julia"` = native | Poisson/Gamma, 18 cells | fits returned | 0 / 18 | **FAIL / BLOCKED** (drmTMB#1551; even with the label fixed, parity needs `marginal = "Laplace"` forwarded) |
| `engine = "julia"` with any `weights` (incl. `NULL`) | 27 cells × 4 | fits returned | 0 / 108 | fenced (drmTMB#1450; draft drmTMB#1502) |
| Julia on duplicated rows = native integer weights | bridge, Gaussian, 9 cells | max \|ΔlogLik\| / max \|Δcoef\| | 1.0e-12 / 3.3e-11 | **PASS** |
| DRModels direct, complete cases = native | Gaussian, 9 cells | max \|ΔlogLik\| / max \|Δcoef\| | 2.4e-12 / 1.8e-10 | **PASS** |
| DRModels direct, `marginal = :Laplace` = native | Poisson/Gamma, 18 cells | max \|ΔlogLik\| / max \|Δcoef\| | 9.7e-11 / 4.6e-09 | **PASS** |
| DRModels direct, default `:LA` (AGHQ-5) vs native Laplace | Poisson/Gamma, 18 cells | max \|ΔlogLik\| / max \|Δcoef\| | 4.5e-02 / 5.0e-03 | different integrator (informative) |
| DRModels direct on duplicated rows = native integer weights | 27 cells (Laplace for Poisson/Gamma) | max \|ΔlogLik\| / max \|Δcoef\| | 1.6e-10 / 2.0e-08 | **FAIL** on coefficients vs the 1e-8 bar: DRModels' `:Laplace` optimiser stopping point (`ordinary_laplace.jl:165`; DRModels.jl#947 comment), not a weights or NA defect |
| DRModels `drm(...; weights = w)` | 27 cells | fits returned | 0 / 27 (`MethodError`) | not implemented (DRModels.jl#931, #691; draft #1061) |
| DRModels raw `drm()`, NaN-coded missing x | 18 cells with NA in x | outcomes | ArgumentError: 6; DomainError: 6; fit with non-finite loglik: 6 | **FAIL** (DRModels.jl#1113; fixed on draft DRModels.jl#1045) |
| Explicit `miss_control()` with NA in x: Julia fails like native | Gaussian, 6 cells | Julia fits instead of failing | 6 / 6 | **FAIL** (drmTMB#1454 comment) |

