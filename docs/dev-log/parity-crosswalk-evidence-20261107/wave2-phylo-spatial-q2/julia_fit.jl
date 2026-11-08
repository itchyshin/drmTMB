# Julia fits for the wave-2 phylo/spatial q2 cases on the R-generated fixture.
# Usage: julia --project=<DRModels test env> julia_fit.jl [cases...]
using DRModels, DelimitedFiles, LinearAlgebra, Printf
const O = "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/w2ps"

function readcsv(path)
    m, h = readdlm(path, ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]
    Dict(h[j] => m[:, j] for j in eachindex(h))
end

function load(kind, fam)
    d = readcsv(joinpath(O, kind == "phy" ? "data_phylo.csv" : "data_spatial.csv"))
    y = Float64.(d[fam == "g" ? "yg" : fam == "p" ? "yp" : "yn"])
    data = (; y, x = Float64.(d["x"]), z0 = Float64.(d["z0"]), z1 = Float64.(d["z1"]),
            id = String.(d["id"]))
    tree = strip(read(joinpath(O, "tree.nwk"), String))
    c = readcsv(joinpath(O, "coords.csv"))
    coords = Dict(String(c["id"][k]) => [Float64(c["easting"][k]), Float64(c["northing"][k])]
                  for k in eachindex(c["id"]))
    return data, tree, coords
end

function fitcase(case)
    fam, kind = case[1:1], case[2:end]
    data, tree, coords = load(kind, fam)
    lvl = kind == "phy" ? "phylogenetic" : "spatial"
    mu = kind == "phy" ? @formula(y ~ x + phylo(1 + x | id)) : @formula(y ~ x + spatial(1 + x | id))
    f0 = kind == "phy" ? @formula(sd(id, phylogenetic, coef(intercept)) ~ z0) :
                         @formula(sd(id, spatial, coef(intercept)) ~ z0)
    f1 = kind == "phy" ? @formula(sd(id, phylogenetic, coef(x)) ~ z1) :
                         @formula(sd(id, spatial, coef(x)) ~ z1)
    family = fam == "g" ? Gaussian() : fam == "p" ? Poisson() : NegBinomial2()
    form = fam == "p" ? bf(mu, f0, f1) : bf(mu, @formula(sigma ~ 1), f0, f1)
    kw = kind == "phy" ? (; tree) : (; coords)
    t = @elapsed fit = drm(form, family; data, kw...)
    se = stderror(fit)
    est = fit.theta
    @printf("%s: converged=%s ll=%.10f time=%.1fs\n", case, fit.converged, loglikelihood(fit), t)
    open(joinpath(O, "j_$(case).csv"), "w") do io
        println(io, "est,se")
        for k in eachindex(est); println(io, @sprintf("%.12g,%.12g", est[k], se[k])); end
    end
    open(joinpath(O, "j_$(case)_ll.txt"), "w") do io; @printf(io, "%.12f\n", loglikelihood(fit)); end
    return fit
end

cases = isempty(ARGS) ? ["gphy", "pphy", "nphy", "gsp", "psp", "nsp"] : ARGS
for c in cases
    try
        fitcase(c)
    catch e
        println(c, ": ERROR ", sprint(showerror, e)[1:min(end, 600)])
    end
end
