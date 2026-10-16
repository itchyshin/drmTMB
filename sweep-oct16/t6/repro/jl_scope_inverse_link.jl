# Scope probe for jl-response-inverse-link-table-student-nu-skewnormal-nu-zob-mu (not the issue repro).
# DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; lane data cd6d3da (seeds in data/cells.csv).
# For every lane fixed cell (+ zero_one_beta_ri, tweedie_ri, bivariate Student): compare predict_parameters(:response)
# and its SE against the family's DOCUMENTED inverse link (docstrings) and against fit.scales / fit.means in-sample.
using DRModels, CSV, DataFrames, Printf
D = "/home/user/drmTMB/sweep-oct16/t6/data"
rd(f) = (df = CSV.read(joinpath(D, f), DataFrame);
         NamedTuple{Tuple(Symbol.(names(df)))}(Tuple(eltype(c) <: AbstractString ? String.(c) : Float64.(c) for c in eachcol(df))))
plogis(x) = 1 / (1 + exp(-x))
# documented inverse link and its derivative, per (family, dpar), from the family docstrings at f71b292
const ID = (identity, η -> one(η)); const EX = (exp, exp)
const LG = (plogis, η -> plogis(η) * (1 - plogis(η)))
const M2 = (η -> 2 + exp(η), exp); const L12 = (η -> 1 + plogis(η), η -> plogis(η) * (1 - plogis(η)))
doc = Dict(
  "gaussian" => Dict(:mu => ID, :sigma => EX), "student" => Dict(:mu => ID, :sigma => EX, :nu => M2),
  "skew_normal" => Dict(:mu => ID, :sigma => EX, :nu => ID), "lognormal" => Dict(:mu => ID, :sigma => EX),
  "gamma" => Dict(:mu => EX, :sigma => EX), "beta" => Dict(:mu => LG, :sigma => EX),
  "zero_one_beta" => Dict(:mu => LG, :sigma => EX, :zoi => LG, :coi => LG),
  "beta_binomial" => Dict(:mu => LG, :sigma => EX), "binomial" => Dict(:mu => LG), "poisson" => Dict(:mu => EX),
  "nbinom2" => Dict(:mu => EX, :sigma => EX), "truncated_nbinom2" => Dict(:mu => EX, :sigma => EX),
  "tweedie" => Dict(:mu => EX, :sigma => EX, :nu => L12), "cumulative_logit" => Dict(:mu => ID))
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
nd = rd("nd_main.csv")
cells = [(c, false) for c in keys(doc)]; append!(cells, [("zero_one_beta", true), ("tweedie", true), ("student", true)])
println(rpad("cell", 24), rpad("dpar", 6), "  max|resp - doc_invlink(link)|   max|se_resp - |doc'|*se_link|/se   in-sample |resp - stored|")
for (c, ri) in sort(cells)
    d = rd(c * (ri ? "_ri.csv" : "_fixed.csv"))
    fit = try drm(form(c, ri), fam[c]; data = d) catch e; println(rpad(c * (ri ? "_ri" : "_fixed"), 24), "FIT ERROR ", sprint(showerror, e)[1:min(end, 120)]); continue end
    local R, L, Ri
    try
        R = predict_parameters(fit, nd; se = true); L = predict_parameters(fit, nd; type = :link, se = true)
        Ri = predict_parameters(fit, d)
    catch e
        println(rpad(c * (ri ? "_ri" : "_fixed"), 24), "predict_parameters ERROR: ", sprint(showerror, e)[1:min(end, 160)]); continue
    end
    for p in sort(collect(keys(R)))
        g, dg = doc[c][p]
        dv = maximum(abs.(R[p].value .- g.(L[p].value)))
        ds = maximum(abs.(R[p].se .- abs.(dg.(L[p].value)) .* L[p].se) ./ max.(abs.(dg.(L[p].value)) .* L[p].se, 1e-300))
        stored = p === :mu ? fit.means[:mu] : fit.scales[p]
        di = maximum(abs.(Ri[p] .- stored))
        @printf("%-24s%-6s  %-30.3e  %-36.3e  %.3e%s\n", c * (ri ? "_ri" : "_fixed"), p, dv, ds, di,
                (dv > 1e-10 || ds > 1e-8) ? "   <-- MISMATCH vs documented link" : "")
    end
end
# ZeroOneBeta: predict(:response) vs fitted(fit) in-sample (docstring: "In-sample, predict(fit, data) ≈ fitted(fit)")
dz = rd("zero_one_beta_fixed.csv")
fz = drm(form("zero_one_beta", false), ZeroOneBeta(); data = dz)
println("ZOB fixed: max|predict(fz, dz) - fitted(fz)| = ", maximum(abs.(predict(fz, dz) .- fitted(fz))),
        "; first 3 predict = ", predict(fz, dz)[1:3], " fitted = ", fitted(fz)[1:3])
# Bivariate Student (src/bivariate_student.jl stores nu = 2 .+ exp.(eta)): y1 = student_fixed y, y2 = student_ri y (row-aligned)
s1 = rd("student_fixed.csv"); s2 = rd("student_ri.csv")
db = (y1 = s1.y, y2 = s2.y, x = s1.x)
fb = drm(bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x), sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
            nu = @formula(nu ~ 1), rho12 = @formula(rho12 ~ 1)), Student(); data = db)
pb = predict_parameters(fb, db; se = true); lb = predict_parameters(fb, db; type = :link, se = true)
println("Bivariate Student nu: response = ", pb[:nu].value[1], "  fit.scales[:nu] = ", fb.scales[:nu][1],
        "  2+exp(link) = ", 2 + exp(lb[:nu].value[1]), "  se_resp = ", pb[:nu].se[1], "  exp(link)*se_link = ", exp(lb[:nu].value[1]) * lb[:nu].se[1])
for p in sort(collect(keys(pb)))
    p === :nu && continue
    st = p in (:mu1, :mu2) ? fb.means[p] : fb.scales[p]
    println("  bivariate Student ", p, ": max|in-sample response - stored| = ", maximum(abs.(pb[p].value .- st)))
end
