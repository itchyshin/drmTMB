# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7 (Julia 1.12.7). Reference values: drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a.
# Data: sweep-oct16/t6/data/{lognormal_fixed (seed 20261016606), truncated_nbinom2_fixed (seed 20261016622)}.csv
# (data/cells.csv) at https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
# fitted() docstring: "Fitted mean(s). Univariate / random-effect models return the μ vector (the population/marginal mean `Xβ̂`)".
# predict() docstring: "`type = :response` (default) returns the response-scale mean — the family inverse link applied to `Xβ̂`".
using DRModels, CSV, DataFrames, Random, Statistics
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
d = rd("lognormal_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), LogNormal(); data = d)
η = predict(fit, d; type = :link); s = fit.scales[:sigma]; Ey = exp.(η .+ s .^ 2 ./ 2)
Y = simulate(fit; nsim = 20000, rng = Xoshiro(20261016706))
println("LogNormal row 1: fitted = ", fitted(fit)[1], "  predict(:response) = ", predict(fit, d)[1], "  exp(eta) = ", exp(η[1]),
        "  E[y] = exp(eta + sigma^2/2) = ", Ey[1], "  mean of 20000 simulate() draws = ", mean(Y[1, :]), " (MC se ", std(Y[1, :]) / sqrt(20000), ")")
println("LogNormal mean(fitted) = ", mean(fitted(fit)), "  mean(E[y]) = ", mean(Ey), "  mean(y) = ", mean(d.y))
# expected (if "mean" means E[y], as drmTMB fitted() documents for lognormal): fitted = E[y] = 2.315; observed 2.1735 = exp(eta), the median
t = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), TruncatedNegBinomial2(); data = rd("truncated_nbinom2_fixed.csv"))
μ = fitted(t); k = 1 ./ t.scales[:sigma] .^ 2; p0 = (k ./ (k .+ μ)) .^ k; Et = μ ./ (1 .- p0)
Yt = simulate(t; nsim = 20000, rng = Xoshiro(20261016722))
println("TruncNB2 row 1: fitted = ", μ[1], "  E[y] = mu/(1 - p0) = ", Et[1], "  mean of 20000 simulate() draws = ", mean(Yt[1, :]),
        " (MC se ", std(Yt[1, :]) / sqrt(20000), ");  mean(fitted) = ", mean(μ), "  mean(E[y]) = ", mean(Et), "  mean(y) = ", mean(t.obs[:mu]))
# expected (if "mean" means E[y], as drmTMB fitted() returns for truncated_nbinom2): fitted = 4.556; observed 3.740, the untruncated NB mu
