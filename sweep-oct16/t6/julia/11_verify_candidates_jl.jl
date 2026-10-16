# 11_verify_candidates_jl.jl -- t6 lane: second-route verification of the Julia
# candidate findings from 10_harness_jl.jl. Each block is a minimal,
# self-contained repro that reads the lane data files directly and derives the
# expected value a second way (by hand from coef() and the family docstring,
# or from the engine's own simulate() draws), so a FAIL is not a harness bug.
#
#   JULIA_DEPOT_PATH=/opt/julia-depot /opt/julia-env/bin/julia --project=/opt/t6-env \
#     /home/user/drmTMB/sweep-oct16/t6/julia/11_verify_candidates_jl.jl \
#     > /home/user/drmTMB/sweep-oct16/t6/logs/verify_candidates_jl.log 2>&1

using DRModels, CSV, DataFrames, Random, Statistics, CategoricalArrays
const D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(file) = (df = CSV.read(joinpath(D, file), DataFrame);
            NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
logistic(x) = 1 / (1 + exp(-x))
nd = rd("nd_main.csv")   # row 2 of nd_main is x = 0, f = "a", g = "g01"
# (a one-row newdata cannot be used: non-Gaussian fits rebuild contrasts from newdata, see V5)
println("DRModels pin: ", readchomp(`git -C /home/user/DRModels.jl rev-parse HEAD`), "  Julia ", VERSION)
show_err(f) = try f() catch e; "ERROR: " * sprint(showerror, e) end

println("\n[V1] ZeroOneBeta: predict(:response) vs logistic(intercept) at x=0,f=a")
d = rd("zero_one_beta_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(zoi ~ 1), @formula(coi ~ 1)), ZeroOneBeta(); data = d)
b0 = coef(fit, :mu)[1]
println("  coef(fit,:mu)[1] (logit mu at x=0,f=a) = ", b0)
println("  predict(fit, nd_main)[2]                = ", predict(fit, nd)[2])
println("  logistic(b0)  (documented logit link)    = ", logistic(b0))
println("  predict_parameters(fit, nd_main)[:mu][2]= ", predict_parameters(fit, nd)[:mu][2])
println("  predict(nd_main; se=true) row 2         = ", (p = predict(fit, nd; se = true); (p.prediction[2], p.se[2])), "  logit-scale se = ", predict(fit, nd; type = :link, se = true).se[2])
println("  in-sample predict(fit,d)[1:3]           = ", predict(fit, d)[1:3], "  fitted(fit)[1:3] = ", fitted(fit)[1:3])
println("  minimum(predict(fit, d)) = ", minimum(predict(fit, d)), " (a [0,1] response mean cannot be negative)")
Y = simulate(fit; nsim = 2000, rng = Xoshiro(1)); println("  mean(simulate)[1:3] = ", vec(mean(Y; dims = 2))[1:3])

println("\n[V2] Student: predict_parameters(:nu) vs 2 + exp(coef nu) (docstring) and fit.scales[:nu]")
d = rd("student_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), Student(); data = d)
bnu = coef(fit, :nu)[1]
println("  coef(fit,:nu) = ", bnu, "  2 + exp = ", 2 + exp(bnu), "  exp = ", exp(bnu))
println("  predict_parameters(fit, nd_main)[:nu][2] = ", predict_parameters(fit, nd)[:nu][2])
println("  fit.scales[:nu][1] (used by simulate) = ", fit.scales[:nu][1])
println("  marginal_parameters(fit)[:nu][1] = ", marginal_parameters(fit)[:nu][1])

println("\n[V3] SkewNormal: predict_parameters(:nu) vs identity-link slant (docstring) and fit.scales[:nu]")
d = rd("skew_normal_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x), @formula(nu ~ 1)), SkewNormal(); data = d)
bnu = coef(fit, :nu)[1]
println("  coef(fit,:nu) = ", bnu, " (docstring: 'coef(fit, :nu)[1] # estimated slant alpha (identity)')")
println("  predict_parameters(fit, nd_main)[:nu][2] = ", predict_parameters(fit, nd)[:nu][2], "  exp(coef) = ", exp(bnu))
println("  fit.scales[:nu][1] = ", fit.scales[:nu][1])
println("  predict_parameters(nd_main; se=true)[:nu] row 2 = ", (q = predict_parameters(fit, nd; se = true)[:nu]; (q.value[2], q.se[2])),
        "  sqrt(vcov[nu,nu]) = ", sqrt(vcov(fit)[end, end]))

println("\n[V4] CumulativeLogit: predict on the training data and on nd_main")
d = rd("cumulative_logit_fixed.csv")
fit = drm(bf(@formula(y ~ x + f)), CumulativeLogit(); data = d)
println("  coefnames = ", fit.coefnames)
println("  predict(fit, d)            -> ", show_err(() -> predict(fit, d)))
println("  predict_parameters(fit, nd)-> ", show_err(() -> predict_parameters(fit, nd)))
println("  predict(fit, d; type=:link)-> ", show_err(() -> predict(fit, d; type = :link)))
println("  fitted(fit)[1:3] = ", fitted(fit)[1:3])

println("\n[V5] Training-schema cache: Gaussian vs Poisson on a level-subset newdata (f = b only)")
nds = rd("nd_subset.csv")
dg = rd("gaussian_fixed.csv"); dp = rd("poisson_fixed.csv")
fg = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), Gaussian(); data = dg)
fp = drm(bf(@formula(y ~ x + f)), Poisson(); data = dp)
println("  Gaussian predict(nd_subset) -> ", show_err(() -> predict(fg, nds)))
println("  Poisson  predict(nd_subset) -> ", show_err(() -> predict(fp, nds)))
println("  Poisson  predict(nd_main)[4:6] (same rows) = ", predict(fp, nd)[4:6])
println("  Poisson  schema cache keys: ", collect(keys(fp.formula.schema_cache[])), "   Gaussian: ", collect(keys(fg.formula.schema_cache[])))
fpr = drm(bf(@formula(y ~ x + f)), Poisson(); data = merge(dp, (f = categorical(dp.f; levels = ["c", "a", "b"]),)))
fgr = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), Gaussian(); data = merge(dg, (f = categorical(dg.f; levels = ["c", "a", "b"]),)))
println("  Poisson  fit f=categorical(levels c,a,b), predict with String nd_main -> ", show_err(() -> predict(fpr, nd)[1:3]))
println("  Gaussian fit f=categorical(levels c,a,b), predict with String nd_main -> ", show_err(() -> predict(fgr, nd)[1:3]))
for fam in ("beta_fixed.csv" => Beta(), "gamma_fixed.csv" => Gamma(), "nbinom2_fixed.csv" => NegBinomial2(), "lognormal_fixed.csv" => LogNormal())
    dd = rd(fam.first); ff = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), fam.second; data = dd)
    println("  $(fam.first): predict(nd_subset) -> ", first(show_err(() -> predict(ff, nds)), 140))
end

println("\n[V6] LogNormal: fitted()/predict(:response) vs the mean of the engine's own simulate() draws")
d = rd("lognormal_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), LogNormal(); data = d)
Y = simulate(fit; nsim = 20000, rng = Xoshiro(2))
η = predict(fit, d; type = :link); σ = sigma(fit)
println("  row 1: fitted = ", fitted(fit)[1], "  predict(:response) = ", predict(fit, d)[1],
        "  exp(eta) = ", exp(η[1]), "  exp(eta + sigma^2/2) = ", exp(η[1] + σ[1]^2 / 2),
        "  mean of 20000 simulate draws = ", mean(Y[1, :]), " (MC SE ", std(Y[1, :]) / sqrt(20000), ")")
println("  over rows: mean(fitted) = ", mean(fitted(fit)), "  mean(rowmeans(simulate)) = ", mean(Y), "  mean(observed y) = ", mean(d.y))

println("\n[V7] TruncatedNegBinomial2: fitted() vs mean of the engine's own simulate() draws")
d = rd("truncated_nbinom2_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), TruncatedNegBinomial2(); data = d)
Y = simulate(fit; nsim = 20000, rng = Xoshiro(3))
μ = fitted(fit); s = sigma(fit); k = 1 ./ s .^ 2; p0 = (k ./ (k .+ μ)) .^ k
println("  min(simulate) = ", minimum(Y), "  row 1: fitted = ", μ[1], "  mu/(1-p0) = ", μ[1] / (1 - p0[1]),
        "  mean of draws = ", mean(Y[1, :]), " (MC SE ", std(Y[1, :]) / sqrt(20000), ")")
println("  mean(fitted) = ", mean(μ), "  mean(simulate) = ", mean(Y), "  mean(observed y) = ", mean(d.y))

println("\n[V8] (1 | g) refusals: SkewNormal and TruncatedNegBinomial2")
d = rd("skew_normal_ri.csv")
println("  SkewNormal ri -> ", show_err(() -> drm(bf(@formula(y ~ x + f + (1 | g)), @formula(sigma ~ x), @formula(nu ~ 1)), SkewNormal(); data = d)))
d = rd("truncated_nbinom2_ri.csv")
println("  TruncNB2 ri   -> ", show_err(() -> drm(bf(@formula(y ~ x + f + (1 | g)), @formula(sigma ~ x)), TruncatedNegBinomial2(); data = d)))

println("\n[V9] simulate() on a (1 | g) fit: per-draw group means carry no group-level variance")
d = rd("poisson_ri.csv")
fit = drm(bf(@formula(y ~ x + f + (1 | g))), Poisson(); data = d)
Y = simulate(fit; nsim = 2000, rng = Xoshiro(4))
gidx = [parse(Int, s[2:end]) for s in d.g]
# Var over draws of each group's mean residual (y - mu) / sqrt(mu): if b were redrawn it
# would include sd_g^2-scale variation; under b = 0 it is ~ 1/10 (10 rows/group).
z = (Y .- fitted(fit)) ./ sqrt.(fitted(fit))
gm = [vec(mean(z[gidx .== g, :]; dims = 1)) for g in 1:24]
println("  re_sd(fit) = ", re_sd(fit), "  mean over groups of var_s(group-mean std. residual) = ",
        mean(var.(gm)), "  (1/10 = 0.1 expected if b = 0)")
println("  observed data: var over groups of group-mean std residual = ",
        var([mean(((d.y .- fitted(fit)) ./ sqrt.(fitted(fit)))[gidx .== g]) for g in 1:24]))
println("\n[V10] beta_fixed P8 diagnostic (3 rows with |z_i| > 3 at nsim = 1000): rerun at nsim = 20000, new stream")
d = rd("beta_fixed.csv")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), Beta(); data = d)
Y = simulate(fit; nsim = 20000, rng = Xoshiro(20261016610 + 101))
μ = fitted(fit); φ = 1 ./ sigma(fit) .^ 2; v = μ .* (1 .- μ) ./ (1 .+ φ)
zi = (vec(mean(Y; dims = 2)) .- μ) ./ sqrt.(v ./ 20000)
println("  rows |z_i| > 3: ", count(>(3), abs.(zi)), " (expected 0.65), max |z_i| = ", maximum(abs.(zi)),
        ";  rows |z_i| > 3 with the SAME seed+100 stream at nsim=1000 (theoretical SE): ",
        count(>(3), abs.((vec(mean(simulate(fit; nsim = 1000, rng = Xoshiro(20261016610 + 100)); dims = 2)) .- μ) ./ sqrt.(v ./ 1000))))
println("\nDone")
