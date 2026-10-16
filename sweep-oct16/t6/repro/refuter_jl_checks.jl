# Refuter quick checks. DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7, Julia 1.12.7.
# Data: sweep-oct16/t6/data (committed at drmTMB cd6d3da751bdec440996ca2168f68c4d31490ffa).
# Seeds (data/cells.csv): student_fixed 20261016602, skew_normal_fixed 20261016604,
# cumulative_logit_fixed 20261016626, poisson_fixed 20261016618.
using DRModels, CSV, DataFrames
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
msg(f) = try f(); "no error" catch e; first(split(sprint(showerror, e), '\n')) end

# (A) Scope extension of the inverse-link finding: a fit with one missing response
# rebuilds fit.scales from predict_parameters (gaussian_core.jl:1408-1414), so the
# STORED nu is wrong too, not only predict output.
ds = rd("student_fixed.csv"); ys = copy(ds.y); ys[1] = NaN; ds1 = merge(ds, (y = ys,))
fs1 = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), Student(); data = ds1)
println("A Student missing-y: fit.scales[:nu][1] = ", fs1.scales[:nu][1], "  2+exp(coef nu) = ", 2 + exp(coef(fs1, :nu)[1]))
# expected fit.scales[:nu] == 2 + exp(coef(:nu)); a mismatch means stored nu = exp(eta)
dk = rd("skew_normal_fixed.csv"); yk = copy(dk.y); yk[1] = NaN; dk1 = merge(dk, (y = yk,))
# SkewNormal has no observed-rows wrapper (skewnormal.jl:45-63), so a NaN response errors instead:
println("A SkewNormal missing-y: ", msg(() -> drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), SkewNormal(); data = dk1)))

# (B) CumulativeLogit predict on the training data
dc = rd("cumulative_logit_fixed.csv")
fc = drm(bf(@formula(y ~ x + f)), CumulativeLogit(); data = dc)
println("B CumulativeLogit predict(fit, training data): ", msg(() -> predict(fc, dc; type = :link)))

# (C) Poisson predict on a single-level newdata (nd_subset: f all "b")
fp = drm(bf(@formula(y ~ x + f)), Poisson(); data = rd("poisson_fixed.csv"))
nds = rd("nd_subset.csv")
println("C Poisson predict(nd_subset): ", msg(() -> predict(fp, nds)))
println("C unique f in nd_subset: ", unique(nds.f))
