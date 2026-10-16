# Scope probe for jl-nongaussian-fitters-no-training-schema-cache (not the issue repro).
# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; lane data cd6d3da (seeds in data/cells.csv).
# Every lane family (fixed; plus poisson_ri, gamma_ri, lognormal_ri), probes P3/P4/P5. Any SUCCESS is compared with the
# reference (String fit, String nd_main) so a silent wrong value would be flagged "WRONG".
using DRModels, CSV, DataFrames, CategoricalArrays, Printf
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
fam = Dict("gaussian" => Gaussian(), "student" => Student(), "skew_normal" => SkewNormal(), "lognormal" => LogNormal(),
  "gamma" => Gamma(), "beta" => Beta(), "zero_one_beta" => ZeroOneBeta(), "beta_binomial" => BetaBinomial(),
  "binomial" => Binomial(), "poisson" => Poisson(), "nbinom2" => NegBinomial2(), "truncated_nbinom2" => TruncatedNegBinomial2(),
  "tweedie" => Tweedie(), "cumulative_logit" => CumulativeLogit())
function form(c, ri)
    cb = c in ("binomial", "beta_binomial")
    mu = cb ? (ri ? @formula(cbind(successes, failures) ~ x + f + (1 | g)) : @formula(cbind(successes, failures) ~ x + f)) :
              (ri ? @formula(y ~ x + f + (1 | g)) : @formula(y ~ x + f))
    fs = Any[mu]
    c in ("binomial", "poisson", "cumulative_logit") || push!(fs, @formula(sigma ~ x))
    c in ("student", "skew_normal", "tweedie") && push!(fs, @formula(nu ~ 1))
    c == "zero_one_beta" && append!(fs, [@formula(zoi ~ 1), @formula(coi ~ 1)])
    return bf(fs...)
end
nd = rd("nd_main.csv"); nds = rd("nd_subset.csv"); ndu = rd("nd_unseen_f.csv")
sub = [4:6; 13:15]
cat_(t, lv) = merge(t, (f = categorical(t.f; levels = lv),))
short(e) = (s = replace(sprint(showerror, e), '\n' => ' '); s[1:min(end, 150)])
function probe(lab, ref, call; rtol = 1e-8)
    v = try call() catch e; return @printf("    %-44s ERROR  %s\n", lab, short(e)) end
    v = v isa Dict ? v[:mu] : v
    ok = ref === nothing ? "(no ref)" : (isapprox(v, ref; rtol = rtol, atol = 1e-10) ? "OK (matches ref)" : "WRONG  max|diff| = $(maximum(abs.(v .- ref)))")
    @printf("    %-44s %s\n", lab, ok)
end
cells = [(c, false) for c in sort(collect(keys(fam)))]; append!(cells, [("poisson", true), ("gamma", true), ("lognormal", true)])
for (c, ri) in cells
    d = rd(c * (ri ? "_ri.csv" : "_fixed.csv"))
    fit = try drm(form(c, ri), fam[c]; data = d) catch e; println(c, ri ? "_ri" : "_fixed", ": FIT ERROR ", short(e)); continue end
    println(c, ri ? "_ri" : "_fixed", ": cached schema keys = ", collect(keys(fit.formula.schema_cache[])))
    ref = try predict(fit, nd) catch e; println("    reference predict(fit, nd_main) ERROR ", short(e)); nothing end
    rs = ref === nothing ? nothing : ref[sub]
    probe("P3 nd_subset String", rs, () -> predict(fit, nds))
    probe("P3 nd_subset categorical(levels=[b])", rs, () -> predict(fit, cat_(nds, ["b"])))
    probe("P3 nd_subset categorical(levels=[a,b,c])", rs, () -> predict(fit, cat_(nds, ["a", "b", "c"])))
    probe("P3 predict_parameters(nd_subset)[:mu]", rs, () -> predict_parameters(fit, nds))
    probe("P4 nd_unseen_f (f = d)", nothing, () -> predict(fit, ndu))
    probe("P5 String fit, nd_main categorical[c,a,b]", ref, () -> predict(fit, cat_(nd, ["c", "a", "b"])))
    probe("P5 String fit, nd_main categorical[a,b,c]", ref, () -> predict(fit, cat_(nd, ["a", "b", "c"])))
    refx = try predict(fit, merge(nd, (x = 2.0 .* nd.x,))) catch; nothing end
    probe("P5 String fit, Int x (2x)", refx, () -> predict(fit, merge(nd, (x = round.(Int, 2 .* nd.x),))))
    fr = try drm(form(c, ri), fam[c]; data = cat_(d, ["c", "a", "b"])) catch e; println("    releveled fit ERROR ", short(e)); continue end
    probe("P5 fit f[c,a,b], String nd_main", ref, () -> predict(fr, nd); rtol = 1e-6)
    probe("P5 fit f[c,a,b], categorical[c,a,b] nd_main", ref, () -> predict(fr, cat_(nd, ["c", "a", "b"])); rtol = 1e-6)
end
# Extra: the cache lives on the formula OBJECT (DrmFormula.schema_cache). Reuse one bf(...) object for two Gaussian fits.
dg = rd("gaussian_fixed.csv")
F = bf(@formula(y ~ x + f), @formula(sigma ~ x))
fA = drm(F, Gaussian(); data = dg)                                   # fills F's cache with levels a, b, c
keep = findall(!=("a"), dg.f); dB = map(c -> c[keep], dg)          # data B: levels b, c only
fB_reuse = try drm(F, Gaussian(); data = dB) catch e; short(e) end
ndB = map(c -> c[[4:9; 13:18]], nd)
fB_fresh = drm(bf(@formula(y ~ x + f), @formula(sigma ~ x)), Gaussian(); data = dB)
println("formula reuse: fresh fit on B coefnames ", Dict(fB_fresh.coefnames)[:mu], " logLik ", loglik(fB_fresh))
fB_reuse isa String ? println("formula reuse: refit on B -> ERROR ", fB_reuse) :
    println("formula reuse: refit on B coefnames ", Dict(fB_reuse.coefnames)[:mu], " logLik ", loglik(fB_reuse),
            "  max|predict diff on nd_main rows f != a| = ", maximum(abs.(predict(fB_reuse, ndB) .- predict(fB_fresh, ndB))))
dC = merge(dg, (f = categorical(dg.f; levels = ["c", "a", "b"]),))
fC = drm(F, Gaussian(); data = dC)                                   # same object again, releveled data
println("formula reuse: refit on f[c,a,b] coefnames ", Dict(fC.coefnames)[:mu], " (fresh fit would be [(Intercept), x, f: a, f: b])")
