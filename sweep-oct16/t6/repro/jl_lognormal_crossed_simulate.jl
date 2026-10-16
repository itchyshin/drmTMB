# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7 (Julia 1.12.7).
# Data: sweep-oct16/t6/data/lognormal_ri.csv (seed 20261016607, data/cells.csv; simulate seed 20261016707) at
# https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
# The crossed LogNormal route delegates to Gaussian-on-log(y) and keeps the Gaussian fit's log-scale means
# (src/lognormal.jl `_lognormal_jacobian_shift`), but fitted()/simulate() treat fit.means[:mu] as the response-scale median.
using DRModels, CSV, DataFrames, Random, Statistics
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
d = rd("lognormal_ri.csv")
for (lab, f) in [("(1 | g)          ", bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1))),
                 ("(1 | g) + (1 | f)", bf(@formula(y ~ x + (1 | g) + (1 | f)), @formula(sigma ~ 1)))]
    fit = drm(f, LogNormal(); data = d)
    η = predict(fit, d; type = :link); s = fit.scales[:sigma]
    Y = simulate(fit; nsim = 1000, rng = Xoshiro(20261016707))
    println(lab, ": fitted[1] = ", fitted(fit)[1], "  exp(eta[1]) = ", exp(η[1]), "  eta[1] = ", η[1],
            "  mean(simulate) = ", mean(Y), "  mean(exp(eta + sigma^2/2)) = ", mean(exp.(η .+ s .^ 2 ./ 2)), "  mean(y) = ", mean(d.y))
end
# expected: both routes behave alike: fitted = exp(eta) and mean(simulate) ~ mean(exp(eta + sigma^2/2)) (b = 0 draws)
# observed on the crossed route: fitted = eta (log scale), and simulate() draws exp(log(eta) + sigma*z), mean ~ 1.1 against y mean 4.2
