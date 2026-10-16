# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7 (Julia 1.12.7). Reference values: drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a.
# Data: sweep-oct16/t6/data/cumulative_logit_fixed.csv (seed 20261016626, data/cells.csv) at
# https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
using DRModels, CSV, DataFrames
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
d = rd("cumulative_logit_fixed.csv")
fit = drm(bf(@formula(y ~ x + f)), CumulativeLogit(); data = d)
println("coefnames[:mu] = ", Dict(fit.coefnames)[:mu], "   fitted(fit)[1:3] = ", fitted(fit)[1:3])
for (lab, call) in [("predict(fit, d)", () -> predict(fit, d)),                       # the TRAINING data itself
                    ("predict(fit, nd_main; type = :link)", () -> predict(fit, rd("nd_main.csv"); type = :link)),
                    ("predict_parameters(fit, nd_main)", () -> predict_parameters(fit, rd("nd_main.csv")))]
    try
        println(lab, " -> ", call()[1:3])
    catch e
        println(lab, " -> ", sprint(showerror, e))
    end
end
# expected: no error; the link is X*beta without an intercept (the fitter drops it), e.g. nd_main rows 1:3
# (x = -1, 0, 1.5; f = "a") = -coef(fit,:mu)[1], 0, 1.5*coef(fit,:mu)[1]  (drmTMB: -0.4209346, 0, 0.6314020).
# observed: ArgumentError "... columns [(Intercept), x, f: b, f: c] but the fitted coefficients are [x, f: b, f: c].
#           A factor in `newdata` probably has a different set or order of levels ..." for all three calls.
println("by hand X*beta on nd_main rows 1:3: ", [-1.0, 0.0, 1.5] .* coef(fit, :mu)[1])
