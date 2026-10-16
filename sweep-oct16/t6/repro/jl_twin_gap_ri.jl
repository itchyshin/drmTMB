# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7 (Julia 1.12.7). Twin: drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a.
# Data: sweep-oct16/t6/data/{skew_normal_ri (seed 20261016605), truncated_nbinom2_ri (seed 20261016623), zero_one_beta_ri (seed 20261016613)}.csv
# (data/cells.csv) at https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
using DRModels, CSV, DataFrames
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
fitmsg(f, fam, file) = try (r = drm(f, fam; data = rd(file)); "fits, logLik = $(loglikelihood(r))") catch e sprint(showerror, e) end
println("SkewNormal + (1 | g):            ", fitmsg(bf(@formula(y ~ x + f + (1 | g)), @formula(sigma ~ x), @formula(nu ~ 1)), SkewNormal(), "skew_normal_ri.csv"))
println("TruncatedNegBinomial2 + (1 | g): ", fitmsg(bf(@formula(y ~ x + f + (1 | g)), @formula(sigma ~ x)), TruncatedNegBinomial2(), "truncated_nbinom2_ri.csv"))
# drmTMB fits both: drmTMB(bf(y ~ x + f + (1 | g), sigma ~ x, nu ~ 1), family = skew_normal(), data) -> logLik -290.763;
#                   drmTMB(bf(y ~ x + f + (1 | g), sigma ~ x), family = truncated_nbinom2(), data) -> logLik -498.565
# docs/src/capabilities.md lists ZeroOneBeta mean-axis random effects as "—" ("Tested fixed effects"), yet:
println("ZeroOneBeta + (1 | g):           ", fitmsg(bf(@formula(y ~ x + f + (1 | g)), @formula(sigma ~ x), @formula(zoi ~ 1), @formula(coi ~ 1)), ZeroOneBeta(), "zero_one_beta_ri.csv"))
