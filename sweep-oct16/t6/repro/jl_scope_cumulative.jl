# Scope probe for jl-cumulativelogit-predict-rebuilds-dropped-intercept (not the issue repro).
# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; lane data cd6d3da (cumulative_logit_ri seed 20261016627).
using DRModels, CSV, DataFrames
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
short(e) = (s = sprint(showerror, e); s[1:min(end, 170)])
try_(f) = try f() catch e short(e) end
dfix = rd("cumulative_logit_fixed.csv"); dri = rd("cumulative_logit_ri.csv"); nd = rd("nd_main.csv")
for (lab, f, d) in [("x only, y ~ x", bf(@formula(y ~ x)), dfix),
                    ("explicit 0 +, y ~ 0 + x", bf(@formula(y ~ 0 + x)), dfix),
                    ("ri, y ~ x + f + (1 | g)", bf(@formula(y ~ x + f + (1 | g))), dri)]
    fit = try drm(f, CumulativeLogit(); data = d) catch e; println(lab, ": FIT ERROR ", short(e)); continue end
    println(lab, ": coefnames[:mu] = ", Dict(fit.coefnames)[:mu])
    println("   predict(fit, nd; type = :link)          -> ", try_(() -> predict(fit, nd; type = :link)[1:3]))
    println("   predict(fit, nd; se = true)              -> ", try_(() -> predict(fit, nd; se = true).se[1:3]))
    println("   predict_parameters(fit, nd; se = true)   -> ", try_(() -> predict_parameters(fit, nd; se = true)[:mu].value[1:3]))
    println("   fitted(fit)[1:3] = ", fitted(fit)[1:3], "  simulate ok: ", try_(() -> size(simulate(fit; nsim = 2))))
end
