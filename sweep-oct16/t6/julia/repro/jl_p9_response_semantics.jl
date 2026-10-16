# t6 P9 repro, DRModels.jl pin f71b2923360e9e5d4591e0d6e15a9ef9db0356d7.
# Native fits on the lane data; prints predict_parameters(:link/:response) on
# nd_main next to each family's documented inverse link and the fit's own stored
# parameter (fit.scales), then shows CumulativeLogit predict refusing even the
# training data. Pair with R/repro/r_p9_reference.R (drmTMB values).
using DRModels, CSV, DataFrames, InteractiveUtils
const D = "/home/user/drmTMB/sweep-oct16/t6/data"
function readnt(file)
    df = CSV.read(joinpath(D, file), DataFrame)
    NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Vector{Float64}(c) for c in eachcol(df)))
end
logistic(x) = 1 / (1 + exp(-x))
nd = readnt("nd_main.csv")

d = readnt("student_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), Student(); data = d)
b = coef(fit, :nu)[1]
pr = predict_parameters(fit, nd; type = :response)[:nu][1]
println("Student nu: coef = $b; docstring nu = 2 + exp(eta) = $(2 + exp(b)); fit.scales[:nu][1] = $(fit.scales[:nu][1]); ",
        "predict_parameters(:response)[:nu][1] = $pr (exp(eta) = $(exp(b)))")

d = readnt("skew_normal_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), SkewNormal(); data = d)
b = coef(fit, :nu)[1]
pp = predict_parameters(fit, nd; type = :response, se = true)[:nu]
pl = predict_parameters(fit, nd; type = :link, se = true)[:nu]
println("SkewNormal nu: coef = $b (docstring: identity link, nu = slant alpha); fit.scales[:nu][1] = $(fit.scales[:nu][1]); ",
        "predict_parameters(:response)[:nu][1] = $(pp.value[1]) (exp(eta) = $(exp(b))); response se = $(pp.se[1]) vs link se = $(pl.se[1])")

d = readnt("zero_one_beta_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(zoi ~ 1), @formula(coi ~ 1)), ZeroOneBeta(); data = d)
l = predict_parameters(fit, nd; type = :link)[:mu][1:3]
r = predict_parameters(fit, nd; type = :response)[:mu][1:3]
r2 = predict(fit, nd; type = :response)[1:3]
println("ZeroOneBeta mu: link[1:3] = $l; predict_parameters(:response)[:mu][1:3] = $r; predict(:response)[1:3] = $r2; ",
        "documented logit link => logistic(link) = $(logistic.(l))")

d = readnt("lognormal_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), LogNormal(); data = d)
l = predict_parameters(fit, nd; type = :link)[:mu][1:3]
r = predict_parameters(fit, nd; type = :response)[:mu][1:3]
println("LogNormal mu: link[1:3] = $l; response[1:3] = $r (= exp(link), the median); drmTMB response = meanlog = link")

d = readnt("cumulative_logit_fixed.csv")
fit = drm(bf(@formula(y ~ x + f)), CumulativeLogit(); data = d)
println("CumulativeLogit coefnames = ", fit.coefnames)
for (nm, nd2) in (("training data", d), ("nd_main", nd))
    try
        predict(fit, nd2); println("  predict on $nm: ok")
    catch e
        println("  predict on $nm: ", sprint(showerror, e))
    end
end
versioninfo()
