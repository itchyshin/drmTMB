# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7 (Julia 1.12.7). Twin: drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a.
# Data: sweep-oct16/t6/data/poisson_ri.csv (seed 20261016619, data/cells.csv; simulate seed = 20261016619 + 100) at
# https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
# fitted() docstring: "Univariate / random-effect models return the μ vector (the population/marginal mean `Xβ̂`)".
# simulate() docstring: "for random-effect models the draw is conditional on the random effects being zero (population level)".
using DRModels, CSV, DataFrames, Random, Statistics
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
d = rd("poisson_ri.csv")
fit = drm(bf(@formula(y ~ x + f + (1 | g))), Poisson(); data = d)
η = predict(fit, d; type = :link); sd = re_sd(fit)[:g]
println("re_sd = ", sd, ";  fitted(fit) == exp(X*beta) (b = 0): ", fitted(fit) ≈ exp.(η))
println("mean fitted = ", mean(fitted(fit)), "   marginal mean E_b[exp(eta + b)] = mean(exp(eta + sd^2/2)) = ", mean(exp.(η .+ sd^2 / 2)),
        "   mean(y) = ", mean(d.y))
# expected if fitted() were the "marginal mean" its docstring names: about mean(exp(eta + sd^2/2)); observed exp(eta) (b = 0)
Y = simulate(fit; nsim = 1000, rng = Xoshiro(20261016719))
gm(v) = [mean(v[d.g .== l]) for l in unique(d.g)]
println("mean(simulate) = ", mean(Y), ";  variance of the 24 group means: data ", var(gm(d.y)),
        ", draws (average over 1000) ", mean(var(gm(Y[:, s])) for s in 1:1000))
# simulate() matches its own docstring (b = 0: no between-group variation in the draws); drmTMB's simulate() default
# (re.form = NA) draws fresh b per replicate, so the two engines' default replicates differ for any (1 | g) fit.
