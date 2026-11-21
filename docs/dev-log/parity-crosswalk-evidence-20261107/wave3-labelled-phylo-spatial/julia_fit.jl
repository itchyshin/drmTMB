# Julia labelled phylo/spatial q2 fits on the R-generated fixture (run from this directory).
# Usage: julia --project=<DRModels test env> julia_fit.jl
# Writes julia_<family>_<kind>.csv (block, k, est, se), plus julia_poisson_phylo_const.csv
# (the constant-SD restriction, `sd(...) ~ 1`, which is the only labelled Poisson phylo
# shape native R fits) and julia_ll.csv.
using DRModels, DelimitedFiles, Printf
const O = @__DIR__

function readcsv(path)
    m, h = readdlm(path, ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]
    Dict(h[j] => m[:, j] for j in eachindex(h))
end

function load(kind)
    d = readcsv(joinpath(O, kind == :phylo ? "data_phylo.csv" : "data_spatial.csv"))
    data = (; yp = Float64.(d["yp"]), yn = Float64.(d["yn"]), yg = Float64.(d["yg"]),
            x = Float64.(d["x"]), z0 = Float64.(d["z0"]), z1 = Float64.(d["z1"]), id = String.(d["id"]))
    tree = strip(read(joinpath(O, "tree.nwk"), String))
    c = readcsv(joinpath(O, "coords.csv"))
    coords = Dict(String(c["id"][k]) => [Float64(c["easting"][k]), Float64(c["northing"][k])]
                  for k in eachindex(c["id"]))
    return data, tree, coords
end

function formula(resp, kind, fam; const_sd = false)
    mu = DRModels.@eval(@formula($resp ~ x + $kind(1 + x | p | id)))
    lvl = kind === :phylo ? :phylogenetic : :spatial
    z0, z1 = const_sd ? (1, 1) : (:z0, :z1)
    f0 = DRModels.@eval(@formula(sd(id, $lvl, coef(intercept)) ~ $z0))
    f1 = DRModels.@eval(@formula(sd(id, $lvl, coef(x)) ~ $z1))
    return fam isa Poisson ? bf(mu, f0, f1) : bf(mu, @formula(sigma ~ 1), f0, f1)
end

lls = String[]
for kind in (:phylo, :spatial)
    data, tree, coords = load(kind)
    kw = kind === :phylo ? (; tree) : (; coords)
    for (lab, resp, fam) in (("poisson", :yp, Poisson()), ("nb2", :yn, NegBinomial2()), ("gaussian", :yg, Gaussian())),
        const_sd in (false, true)
        const_sd && !(lab == "poisson" && kind === :phylo) && continue
        name = const_sd ? "$(lab)_$(kind)_const" : "$(lab)_$(kind)"
        t = @elapsed fit = drm(formula(resp, kind, fam; const_sd), fam; data, kw...)
        se = stderror(fit)
        open(joinpath(O, "julia_$(name).csv"), "w") do io
            println(io, "block,k,est,se")
            for (b, r) in fit.blocks, (k, j) in enumerate(r)
                println(io, "$(b),$(k),$(repr(fit.theta[j])),$(repr(se[j]))")
            end
        end
        push!(lls, "$(lab),$(kind),$(const_sd),$(repr(loglikelihood(fit))),$(fit.converged)")
        @printf("%s: converged=%s ll=%.10f rho=%.6f time=%.1fs\n", name, fit.converged,
                loglikelihood(fit), 0.999999 * tanh(fit.theta[end]), t)
    end
end
open(joinpath(O, "julia_ll.csv"), "w") do io
    println(io, "family,kind,const_sd,ll,converged"); foreach(l -> println(io, l), lls)
end
