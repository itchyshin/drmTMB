# SkewNormal() with one missing response throws from _vcov_from_hessian; every other univariate family drops the row.
# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7, Julia 1.12.7. Data: skew_normal_fixed.csv / student_fixed.csv
# (seeds 20261016604 / 20261016602), committed at https://github.com/itchyshin/drmTMB/tree/42ca52186e9da6af01280feea599daaa6d8ca93d/sweep-oct16/t6/data
using DRModels, CSV, DataFrames
D = "/home/user/drmTMB/sweep-oct16/t6/data"
function withmissing(file)
    df = CSV.read(joinpath(D, file), DataFrame)
    y = Vector{Union{Missing,Float64}}(df.y); y[1] = missing
    (x = Float64.(df.x), f = String.(df.f), y = y)
end
f3 = bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1))
for (lab, fam, file) in [("SkewNormal", SkewNormal(), "skew_normal_fixed.csv"), ("Student", Student(), "student_fixed.csv")]
    try
        r = drm(f3, fam; data = withmissing(file)); println(lab, ": fits, nobs = ", r.nobs, ", loglik = ", r.loglik)
    catch e
        println(lab, ": ", typeof(e), ": ", sprint(showerror, e))
    end
end
# expected: both drop the missing row with the observed-rows warning and fit (nobs = 239)
