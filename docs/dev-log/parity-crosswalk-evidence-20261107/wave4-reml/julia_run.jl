# Julia (DRModels.jl, claude/gaussian-sd-reml-20261108) REML + ML fits on the R-generated wave4-reml data.
# usage: julia --project=<DRModels test env> julia_run.jl seed_from seed_to      (run from this directory)
using DRModels, DelimitedFiles, LinearAlgebra, Printf
s_from, s_to = parse(Int, ARGS[1]), parse(Int, ARGS[2])
function readcsv(path)
    m, h = readdlm(path, ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]
    Dict(h[j] => m[:, j] for j in eachindex(h))
end
cases = [("animal", :animal, :plain), ("relmat", :relmat, :plain), ("phylo", :phylo, :plain),
         ("spatial", :spatial, :plain), ("phylo_lab", :phylo, :lab), ("phylo_sx", :phylo, :sx)]
lev = Dict(:animal => :animal, :relmat => :relmat, :phylo => :phylogenetic, :spatial => :spatial)
function formula(kind, variant)
    mu = kind === :phylo ? (variant === :lab ? @formula(y ~ x + phylo(1 + x | p | id)) : @formula(y ~ x + phylo(1 + x | id))) :
         kind === :spatial ? @formula(y ~ x + spatial(1 + x | id)) :
         kind === :animal ? @formula(y ~ x + animal(1 + x | id)) : @formula(y ~ x + relmat(1 + x | id))
    L = lev[kind]
    f0 = eval(:(@formula(sd(id, $L, coef(intercept)) ~ z0))); f1 = eval(:(@formula(sd(id, $L, coef(x)) ~ z1)))
    bf(mu, variant === :sx ? @formula(sigma ~ x) : @formula(sigma ~ 1), f0, f1)
end
for s in s_from:s_to, (cn, kind, variant) in cases
    tag = @sprintf("%s_s%02d", cn, s)
    d = readcsv(joinpath("data", tag * ".csv"))
    data = (; y = Float64.(d["y"]), x = Float64.(d["x"]), z0 = Float64.(d["z0"]), z1 = Float64.(d["z1"]), id = String.(d["id"]))
    kw = if kind === :phylo
        (; tree = strip(read(joinpath("data", tag * "_tree.nwk"), String)))
    elseif kind === :spatial
        c = readcsv(joinpath("data", tag * "_coords.csv"))
        (; coords = Dict(String(c["id"][k]) => [Float64(c["lon"][k]), Float64(c["lat"][k])] for k in eachindex(c["id"])))
    else
        K = readdlm(joinpath("data", tag * "_K.csv"), ',', Float64)
        ids = unique(data.id)   # the K file is written in id order s01..s40, which is the order of first appearance
        kind === :animal ? (; A = K, ids) : (; K)
    end
    for method in (:REML, :ML)
        t = @elapsed fit = drm(formula(kind, variant), Gaussian(); data, method, kw...)
        se = stderror(fit)
        @printf("%s %s: converged=%s ll=%.10f time=%.1fs\n", tag, method, fit.converged, loglikelihood(fit), t)
        open(joinpath("julia", "$(tag)_$(method).csv"), "w") do io
            println(io, "est,se")
            for (e, v) in zip(fit.theta, se); @printf(io, "%.12f,%.12f\n", e, v); end
        end
        open(joinpath("julia", "$(tag)_$(method)_ll.csv"), "w") do io
            println(io, "ll,converged,reml_loglik,ml_loglik,seconds")
            @printf(io, "%.12f,%s,%.12f,%.12f,%.2f\n", loglikelihood(fit), fit.converged, reml_loglik(fit), ml_loglik(fit), t)
        end
    end
end
