# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7 (Julia 1.12.7). Reference values: drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a.
# Data: sweep-oct16/t6/data/ at https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
# Seeds (data/cells.csv): student_fixed 20261016602, skew_normal_fixed 20261016604, zero_one_beta_fixed 20261016612.
using DRModels, CSV, DataFrames
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
nd = rd("nd_main.csv")          # row 1: x = -1, f = "a"
plogis(x) = 1 / (1 + exp(-x))

# Student: nu = 2 + exp(eta) (Student docstring); predict_parameters(:response) should reproduce fit.scales in-sample.
fs = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), Student(); data = rd("student_fixed.csv"))
e = predict_parameters(fs, nd; type = :link)[:nu][1]
println("Student nu response = ", predict_parameters(fs, nd)[:nu][1], "  fit.scales[:nu] = ", fs.scales[:nu][1],
        "  2+exp(eta) = ", 2 + exp(e))
# expected 5.9694 (= fit.scales = 2 + exp(eta); drmTMB 5.9694169198641); observed 3.9694 = exp(eta)

# SkewNormal: nu (slant) has an identity link (SkewNormal docstring), so response = link and response SE = link SE.
fk = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), SkewNormal(); data = rd("skew_normal_fixed.csv"))
r = predict_parameters(fk, nd; se = true)[:nu]; l = predict_parameters(fk, nd; type = :link, se = true)[:nu]
println("SkewNormal nu response = ", r.value[1], " (se ", r.se[1], ")  link = ", l.value[1], " (se ", l.se[1],
        ")  fit.scales[:nu] = ", fk.scales[:nu][1])
# expected response 1.9528 = link = fit.scales (drmTMB 1.95279955678383, se 0.47274); observed exp(1.9528) = 7.0484, se 3.33

# ZeroOneBeta: mu has a logit link (ZeroOneBeta docstring), so predict(:response) must lie in (0, 1).
dz = rd("zero_one_beta_fixed.csv")
fz = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(zoi ~ 1), @formula(coi ~ 1)), ZeroOneBeta(); data = dz)
p = predict(fz, nd; se = true); q = predict(fz, nd; type = :link, se = true)
println("ZeroOneBeta mu response = ", p.prediction[1], " (se ", p.se[1], ")  link = ", q.prediction[1], " (se ", q.se[1],
        ")  plogis(link) = ", plogis(q.prediction[1]))
println("ZeroOneBeta in-sample extrema(predict(fz, dz)) = ", extrema(predict(fz, dz)), "  extrema(dz.y) = ", extrema(dz.y))
# expected response 0.3661 = plogis(link) (drmTMB 0.366071885069022), se = 0.3661*(1-0.3661)*link se; observed -0.5491 = link, se = link se
