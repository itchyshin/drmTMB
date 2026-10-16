# Consequence of the inverse-link defect on stored parameters: a fit with ONE missing response rebuilds fit.scales
# through predict_parameters (src/gaussian_core.jl:1408), so Student/SkewNormal store the wrong nu and simulate() draws from it.
# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7, Julia 1.12.7. Data seeds 20261016602 (student_fixed), 20261016604 (skew_normal_fixed).
using DRModels, CSV, DataFrames, Random, Statistics
D = "/home/user/drmTMB/sweep-oct16/t6/data"
function fitmiss(file, fam)
    df = CSV.read(joinpath(D, file), DataFrame)
    y = Vector{Union{Missing,Float64}}(df.y); y[1] = missing
    drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), fam;
        data = (x = Float64.(df.x), f = String.(df.f), y = y))
end
skew(v) = mean(((v .- mean(v)) ./ std(v)) .^ 3)
fs = fitmiss("student_fixed.csv", Student())
e = coef(fs, :nu)[1]; s2 = fs.scales[:sigma][2]^2
Y = simulate(fs; nsim = 20000, rng = Xoshiro(20261016702))
println("Student (1 missing y): stored nu = ", fs.scales[:nu][2], " (exp(eta)); documented nu = 2 + exp(eta) = ", 2 + exp(e))
println("  row 2 simulated var = ", var(Y[2, :]), "; sigma^2*nu/(nu-2) at stored nu = ", s2 * fs.scales[:nu][2] / (fs.scales[:nu][2] - 2),
        "; at documented nu = ", s2 * (2 + exp(e)) / exp(e))
# SkewNormal with one missing response could not be checked: the fit itself throws (incidental, outside t6).
try
    fitmiss("skew_normal_fixed.csv", SkewNormal())
catch err
    println("SkewNormal (1 missing y): drm throws ", typeof(err), ": ", sprint(showerror, err))
end
