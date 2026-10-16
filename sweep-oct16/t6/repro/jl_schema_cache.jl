# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7 (Julia 1.12.7).
# Data: sweep-oct16/t6/data/{poisson_fixed (seed 20261016618), gaussian_fixed (seed 20261016600), nd_main, nd_subset}.csv
# (seeds from data/cells.csv) at https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
using DRModels, CSV, DataFrames, CategoricalArrays
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
nd = rd("nd_main.csv"); nds = rd("nd_subset.csv")      # nd_subset = nd_main rows 4:6 and 13:15 (every f = "b")
dg = rd("gaussian_fixed.csv"); dp = rd("poisson_fixed.csv")
try_(f) = try f() catch e sprint(showerror, e) end
fg = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), Gaussian(); data = dg)
fp = drm(bf(@formula(y ~ x + f)), Poisson(); data = dp)
println("cached schema keys: Gaussian ", collect(keys(fg.formula.schema_cache[])), ", Poisson ", collect(keys(fp.formula.schema_cache[])))
println("Gaussian predict(nd_subset) == predict(nd_main)[[4:6;13:15]]: ", predict(fg, nds) ≈ predict(fg, nd)[[4:6; 13:15]])
println("Poisson  predict(nd_subset): ", try_(() -> predict(fp, nds)))
# expected (as Gaussian): the nd_main rows 4:6, 13:15, printed next
println("Poisson  predict(nd_main)[[4:6;13:15]] (what the subset should return): ", predict(fp, nd)[[4:6; 13:15]])
# observed: ArgumentError: only one level found: b (need at least two to compute contrasts).
relev(d) = merge(d, (f = categorical(d.f; levels = ["c", "a", "b"]),))
fgr = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), Gaussian(); data = relev(dg))
fpr = drm(bf(@formula(y ~ x + f)), Poisson(); data = relev(dp))
println("Gaussian fit on f levels [c,a,b], String nd_main: max|diff vs String fit| = ", maximum(abs.(predict(fgr, nd) .- predict(fg, nd))))
println("Poisson  fit on f levels [c,a,b], String nd_main: ", try_(() -> predict(fpr, nd)))
# expected: predictions equal to the String-fit's (a reparameterisation); observed: ArgumentError from the #1000 column guard
