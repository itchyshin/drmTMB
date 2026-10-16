# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7 (Julia 1.12.7).
# Data: sweep-oct16/t6/data/<family>_ri.csv (seeds 20261016601..20261016627, data/cells.csv) at
# https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
# What does `marginal = :Laplace` (the drmTMB/TMB integrator) do for one ordinary (1 | g) on the mean, per family?
using DRModels, CSV, DataFrames
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
R = @formula(y ~ x + f + (1 | g)); RB = @formula(cbind(successes, failures) ~ x + f + (1 | g)); S = @formula(sigma ~ x); S1 = @formula(sigma ~ 1)
cells = [("gaussian", Gaussian(), bf(R, S)), ("student", Student(), bf(R, S, @formula(nu ~ 1))),
         ("lognormal", LogNormal(), bf(R, S)), ("gamma", Gamma(), bf(R, S)), ("gamma", Gamma(), bf(R, S1)),
         ("beta", Beta(), bf(R, S)), ("zero_one_beta", ZeroOneBeta(), bf(R, S1, @formula(zoi ~ 1), @formula(coi ~ 1))),
         ("beta_binomial", BetaBinomial(), bf(RB, S1)), ("binomial", Binomial(), bf(RB)), ("poisson", Poisson(), bf(R)),
         ("nbinom2", NegBinomial2(), bf(R, S)), ("tweedie", Tweedie(), bf(R, S1, @formula(nu ~ 1))),
         ("cumulative_logit", CumulativeLogit(), bf(R)), ("skew_normal", SkewNormal(), bf(R, S, @formula(nu ~ 1))),
         ("truncated_nbinom2", TruncatedNegBinomial2(), bf(R, S))]
for (c, fam, f) in cells
    msg = try
        fit = drm(f, fam; data = rd(c * "_ri.csv"), marginal = :Laplace)
        "accepted, fit.marginal = $(fit.marginal), logLik = $(round(loglik(fit), digits = 6))"
    catch e
        "$(nameof(typeof(e))): " * first(split(sprint(showerror, e), '\n'))[1:min(end, 140)]
    end
    println(rpad("$c $(length(f.forms) > 1 ? "sigma ~ " * string(Dict(f.forms)[:sigma]) : "")", 34), msg)
end
# observed: LogNormal, ZeroOneBeta (even with sigma ~ 1), Tweedie (sigma ~ 1), CumulativeLogit, SkewNormal and
#   TruncatedNegBinomial2 answer "MethodError: no method matching drm(...; data, marginal::Symbol) ... unsupported keyword
#   argument "marginal""; the others either fit (Student, Gamma sigma ~ 1, Binomial, Poisson) or raise an ArgumentError
#   that explains the :Laplace scope (docs/src/model-guides/marginal-la-vs-va.md: "Any other model ... is refused").
# expected (design rule of src/ordinary_laplace.jl `_ordinary_laplace_reject`): an explained ArgumentError for every family.
