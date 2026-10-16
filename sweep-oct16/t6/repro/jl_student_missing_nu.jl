# Side check for the inverse-link issue: what does a Student fit with a missing response store in fit.scales[:nu]?
# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; data seed 20261016602 (student_fixed.csv), first response set to missing.
using DRModels, CSV, DataFrames
D = "/home/user/drmTMB/sweep-oct16/t6/data"
df = CSV.read(joinpath(D, "student_fixed.csv"), DataFrame)
y = Vector{Union{Missing,Float64}}(df.y); y[1] = missing
dat = (x = Float64.(df.x), f = String.(df.f), y = y)
fs = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), Student(); data = dat)
eta = coef(fs, :nu)[1]
println("missing-response Student: fit.scales[:nu][1] = ", fs.scales[:nu][1], "  exp(eta) = ", exp(eta), "  2 + exp(eta) = ", 2 + exp(eta))
dat2 = (x = Float64.(df.x), f = String.(df.f), y = Float64.(df.y))
f2 = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), Student(); data = dat2)
println("complete-data Student:     fit.scales[:nu][1] = ", f2.scales[:nu][1], "  2 + exp(eta) = ", 2 + exp(coef(f2, :nu)[1]))
