# A8 G3 qualification receipt -- measured 2026-09-05 11:43:40 MDT

tol_ci (wald/profile, both bounds) = 1e-04; bootstrap R = 99, seed = 20260905

## G2 (profile) / G5 (estimator) per route

### base_gaussian_location_scale (target `fixef:mu:x`)
- converged: tmb=TRUE julia=TRUE; julia estimator=ML
- wald: tmb=[-0.7469550459, -0.5476759554] julia=[-0.7469550392, -0.5476759621] delta=[6.69774e-09, 6.69542e-09]
- profile: tmb=[-0.7486550064, -0.5481371739] julia=[-0.7486578029, -0.5481365851] delta=[2.79654e-06, 5.88863e-07] PASS(tol=1e-4)=TRUE
- bootstrap (R=99): tmb=[-0.753364, -0.538943] (failed=0/99) julia=[-0.739446, -0.544052] (failed=0/99) OVERLAP=TRUE

### gaussian_response_mask (target `fixef:mu:x`)
- converged: tmb=TRUE julia=FALSE; julia estimator=ML
- wald: tmb=[0.1230156708, 0.8078740798] julia=[0.1230157493, 0.8078740013] delta=[7.85573e-08, 7.85425e-08]
- profile: tmb=[0.1128339409, 0.7989615793] julia=[0.1128288121, 0.7989687552] delta=[5.1288e-06, 7.17584e-06] PASS(tol=1e-4)=TRUE
- bootstrap (R=99): tmb_ok=TRUE julia_ok=FALSE -- NOT COVERED for this route
  julia error: Error happens in Julia.
all 99 bootstrap replicates failed
Stacktrace:
 [1] _bootstrap_result(fit0::DrmFit{Gaussian}, formula::DrmFormula, data::@NamedTuple{y::Vector{Union{Missing, Float64}}, x::Vector{Float64}}, B::Int64, level::Float64, rng::MersenneTwister, threads::Bool, refit::DRM.var"#1362#1363"{Nothing, Nothing, Nothing, Nothing, Symbol, Float64, DrmFit{Gaussian}, @NamedTuple{}, DrmFormula}; failures::Symbol, check_converged::Bool, simulate_fn::Nothing)
   @ DRM ~/local-scratch/parity-joint/drmjl-430ef64cc/src/inference.jl:2127
 [2] bootstrap_result(fit::DrmFit{Gaussian}; data::@NamedTuple{y::Vector{Union{Missing, Float64}}, x::Vector{Float64}}, B::Int64, level::Float64, rng::MersenneTwister, K::Nothing, A::Nothing, tree::Nothing, coords::Nothing, threads::Bool, failures::Symbol, check_converged::Bool, algorithm::Symbol, g_tol::Float64)
   @ DRM ~/local-scratch/parity-joint/drmjl-430ef64cc/src/inference.jl:1668
 [3] drmTMB_drm_bridge_fixef_inference(formula::OrderedCollections.OrderedDict{Symbol, Any}, family::String, data::OrderedCollections.OrderedDict{Symbol, Any}, tree::Nothing, K::Nothing, A::Nothing, coords::Nothing, options::OrderedCollections.OrderedDict{Symbol, Any}, method::String, level::Float64, B::Int64, seed::Int64, threads::Bool, dpar::String, coefname::String)
   @ Main ./none:0
 [4] docall(call1::Ptr{Nothing})
   @ Main.JuliaCall ~/Library/R/arm64/4.6/library/JuliaCall/julia/setup.jl:0

### plain_binomial_nonphylo (target `fixef:mu:x`)
- converged: tmb=TRUE julia=TRUE; julia estimator=ML
- wald: tmb=[0.3479328121, 0.5480261921] julia=[0.3479328172, 0.548026187] delta=[5.18431e-09, 5.1843e-09]
- profile: tmb=[0.3488908676, 0.5490818066] julia=[0.348890774, 0.5490841101] delta=[9.35263e-08, 2.30344e-06] PASS(tol=1e-4)=TRUE
- bootstrap (R=99): tmb=[0.340906, 0.529445] (failed=0/99) julia=[0.368069, 0.551723] (failed=0/99) OVERLAP=TRUE

## biv_gaussian_residual -- NOT COVERED (no ready target)

profile_targets() reports profile_ready=FALSE for all 9 rows (all-not-ready=TRUE).
confint(method="profile") on fixef:mu1:x raised:

> Julia-engine target "fixef:mu1:x" is not ready for profile or bootstrap
intervals.
ℹ Inventory note: "missing_tmb_parameter".

## G4/G8 -- boundary honesty / #631 regression cell

Quasi-complete-separation binomial (n=40, x in {-2,2}, p in {0.02,0.98}, trials=8).
- julia coef(mu:x)=312; tmb coef(mu:x)=2.25663
- julia profile confint(): errored=TRUE
  message: Error happens in Julia.
ArgumentError: drm_bridge_inference: refusing to return an infinite bound for `mu:x` under status `profile_failed` — profile endpoint solve failed: lower (nuisance=below_reference; lbfgs_forward; fallback=false)
Stacktrace:
 [1] _bridge_inference_flatten(row::@NamedTuple{param::Symbol, coef::String, estimate::Float64, lower::Float64, upper::Float64}; method::String, status::String, attempted::Int64, used::Int64, failed::Int64, elapsed::Float64, threaded::Bool, worker_threads::Int64, julia_threads::Int64, blas_threads::Int64, message::String)
   @ DRM ~/local-scratch/parity-joint/drmjl-430ef64cc/src/bridge.jl:2595
 [2] drmTMB_drm_bridge_fixef_inference(formula::OrderedCollections.OrderedDict{Symbol, Any}, family::String, data::OrderedCollections.OrderedDict{Symbol, Any}, tree::Nothing, K::Nothing, A::Nothing, coords::Nothing, options::OrderedCollections.OrderedDict{Symbol, Any}, method::String, level::Float64, B::Int64, seed::Nothing, threads::Bool, dpar::String, coefname::String)
   @ Main ./none:23
 [3] docall(call1::Ptr{Nothing})
   @ Main.JuliaCall ~/Library/R/arm64/4.6/library/JuliaCall/julia/setup.jl:0
- G8 (never a non-finite bound reaches the caller): PASS=TRUE
- raw DRM.jl profile_result() stats for mu:x (diagnostic, bypasses the R flatten): lower=-Inf upper=Inf lower_endpoint_failed=TRUE upper_endpoint_failed=FALSE lower_unbounded=FALSE upper_unbounded=TRUE
- tmb profile confint() on the same fixture: [1.78879, 3.01789], boundary=FALSE (context only; TMB's optimizer does not land at the same boundary on this fixture)

## G6 -- RED CONTROL (tolerance tightened to 1e-9)

- base_gaussian_location_scale: profile delta=[2.79654e-06, 5.88863e-07] -> FAILS at tol=1e-9
- gaussian_response_mask: profile delta=[5.1288e-06, 7.17584e-06] -> FAILS at tol=1e-9
- plain_binomial_nonphylo: profile delta=[9.35263e-08, 2.30344e-06] -> FAILS at tol=1e-9

Comparison is LIVE (not vacuous): at least one route fails at tol=1e-9, as expected a priori.
Tolerance restored to the committed 1e-4 bar above (no code change was made -- tol_ci is a script parameter, not hardcoded state).
