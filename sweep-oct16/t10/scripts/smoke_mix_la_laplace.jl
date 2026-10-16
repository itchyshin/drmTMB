# Poisson (1|g): :LA (GHQ-32) vs :Laplace must error in lrtest (mixing guard).
using Pkg
Pkg.activate("/tmp/t10-jl")
using DRModels, Random
using Distributions: Poisson as DPoisson

Random.seed!(20261017001 - 19000000000)
G = 20; m = 8; n = G * m
g = string.(repeat(1:G, inner = m))
x = randn(n)
y = Float64.(rand.(DPoisson.(exp.(0.2 .+ 0.3 .* x))))
data = (; y, x, g)
la = drm(bf(@formula(y ~ 1 + x + (1 | g))), Poisson(); data, se = false, marginal = :LA)
lp = drm(bf(@formula(y ~ 1 + x + (1 | g))), Poisson(); data, se = false, marginal = :Laplace)
println("loglik_LA=", loglik(la), " loglik_Laplace=", loglik(lp),
        " abs_diff=", abs(loglik(la) - loglik(lp)))
println("marginals: ", la.marginal, " vs ", lp.marginal)
try
    t = lrtest(la, lp)
    println("NO_ERROR statistic=", t.statistic, " p=", t.pvalue)
catch e
    println("ERROR_AS_REQUIRED: ", sprint(showerror, e))
end
try
    t = lrt_boundary(la, lp; q = 1)
    println("lrt_boundary NO_ERROR stat=", t.statistic)
catch e
    println("lrt_boundary ERROR: ", sprint(showerror, e))
end
