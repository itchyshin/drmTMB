# Scope probe for jl-lognormal-truncnb2-fitted-predict-not-mean (not the issue repro).
# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; lane data cd6d3da (seeds in data/cells.csv).
# What does fitted() hold on each LogNormal route, and does predict(:response) / predict_parameters / simulate agree?
using DRModels, CSV, DataFrames, Random, Statistics
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
d = rd("lognormal_ri.csv")
routes = [("fixed  y ~ x + f", bf(@formula(y ~ x + f), @formula(sigma ~ x))),
          ("(1|g)  y ~ x + f + (1 | g)", bf(@formula(y ~ x + f + (1 | g)), @formula(sigma ~ x))),
          ("crossed y ~ x + (1 | g) + (1 | f)", bf(@formula(y ~ x + (1 | g) + (1 | f)), @formula(sigma ~ 1)))]
for (lab, f) in routes
    fit = drm(f, LogNormal(); data = d)
    η = predict(fit, d; type = :link); s = fit.scales[:sigma]
    Y = simulate(fit; nsim = 4000, rng = Xoshiro(20261016707))
    println(lab, ":  fitted[1] = ", round(fitted(fit)[1], digits = 5), "  eta[1] = ", round(η[1], digits = 5),
            "  exp(eta[1]) = ", round(exp(η[1]), digits = 5), "  predict(:response)[1] = ", round(predict(fit, d)[1], digits = 5),
            "  E[y|b=0] = ", round(exp(η[1] + s[1]^2 / 2), digits = 5), "  mean(simulate)[1] = ", round(mean(Y[1, :]), digits = 5),
            "  schema keys = ", collect(keys(fit.formula.schema_cache[])))
    println("      mean(residuals(fit)) = ", mean(residuals(fit)), "   mean(simulate) overall = ", mean(Y), "  mean(y) = ", mean(d.y))
end
# Bivariate LogNormal: fit.means are log-scale; does predict / predict_parameters(:response) reproduce them in-sample?
d1 = rd("lognormal_fixed.csv"); d2 = rd("lognormal_ri.csv")
db = (y1 = d1.y, y2 = d2.y, x = d1.x)
fb = drm(bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x), sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
            rho12 = @formula(rho12 ~ 1)), LogNormal(); data = db)
pp = predict_parameters(fb, db); pl = predict_parameters(fb, db; type = :link)
println("bivariate LogNormal: fitted(fb)[:mu1][1] = ", fitted(fb)[:mu1][1], "  link mu1[1] = ", pl[:mu1][1],
        "  predict_parameters(:response)[:mu1][1] = ", pp[:mu1][1], "  predict(fb, db)[:mu1][1] = ", predict(fb, db)[:mu1][1])
