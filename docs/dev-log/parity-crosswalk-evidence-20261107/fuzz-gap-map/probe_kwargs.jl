# Follow-up probe for the crash class: what does the user see with and without the keyword the map passed?
using DRModels, DelimitedFiles
const DD = get(ENV, "FUZZ_DATA", "data")
function load(fam, kind)
    m, h = readdlm(joinpath(DD, "data_$(fam)_$(kind).csv"), ',', Any; header = true); h = String.(vec(h))
    col(n) = m[:, findfirst(==(n), h)]
    (; y = Float64.(col("y")), x1 = Float64.(col("x1")), x2 = Float64.(col("x2")), x3 = Float64.(col("x3")), z = Float64.(col("z")), g = String.(col("g")), g2 = String.(col("g2")), z2 = Float64.(col("z2")))
end
nwk = strip(read(joinpath(DD, "tree.nwk"), String))
cc = readdlm(joinpath(DD, "coords.csv"), ',', Any; skipstart = 1); coords = Dict(String(cc[i, 1]) => [Float64(cc[i, 2]), Float64(cc[i, 3])] for i in 1:size(cc, 1))
ids = String.(vec(readdlm(joinpath(DD, "A_ids.csv"), ',', Any; skipstart = 1))); A = Matrix{Float64}(readdlm(joinpath(DD, "A.csv"), ',', Float64))
mk(s) = eval(Meta.parse("@formula(" * s * ")"))
function tryit(label, f, fam, d; kw...)
    r = try
        fit = drm(f, fam; data = d, kw...); "FITS ll=$(round(loglikelihood(fit); digits = 4)) converged=$(fit.converged)"
    catch e
        first(replace(sprint(showerror, e), '\n' => ' '), 230) * "   [" * string(typeof(e)) * "]"
    end
    println(rpad(label, 62), r)
end
println("# structured keyword supplied vs omitted, one cell per family (q1, no SD formula)")
for (fam, F, kind, term, kws, kwname) in (
    ("lognormal", LogNormal(), "animal", "animal(1 | g)", (; A, ids), "A,ids"),
    ("lognormal", LogNormal(), "spatial", "spatial(1 | g)", (; coords), "coords"),
    ("student", Student(), "phylo", "phylo(1 | g)", (; tree = nwk), "tree"),
    ("student", Student(), "relmat", "relmat(1 | g)", (; K = A), "K"),
    ("student", Student(), "animal", "animal(1 | g)", (; A, ids), "A,ids"),
    ("tweedie", Tweedie(), "animal", "animal(1 | g)", (; A, ids), "A,ids"),
    ("binomial", Binomial(:logit), "animal", "animal(1 | g)", (; A, ids), "A,ids"))
    d = load(fam, kind)
    f = fam in ("binomial",) ? bf(mk("y ~ x1 + x2 + x3 + $term")) : bf(mk("y ~ x1 + x2 + x3 + $term"), mk("sigma ~ 1"))
    tryit("$fam $kind with $kwname", f, F, d; kws...)
    tryit("$fam $kind with NO structured keyword", f, F, d)
end
println("# method = :REML on ordinary (1 | g), no SD formula")
for (fam, F) in (("gamma", DRModels.Gamma()), ("lognormal", LogNormal()), ("student", Student()), ("tweedie", Tweedie()), ("nb2", NegBinomial2()), ("beta", Beta()), ("poisson", Poisson()), ("binomial", Binomial(:logit)))
    d = load(fam, "ordinary")
    f = fam in ("poisson", "binomial") ? bf(mk("y ~ x1 + x2 + x3 + (1 | g)")) : bf(mk("y ~ x1 + x2 + x3 + (1 | g)"), mk("sigma ~ 1"))
    tryit("$fam method=:REML", f, F, d; method = :REML)
end
