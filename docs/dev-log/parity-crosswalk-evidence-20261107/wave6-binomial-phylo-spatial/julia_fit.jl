# DRModels.jl fits (ML) for the same datasets. Usage: julia --project=<test env> julia_fit.jl <seed> ...
using DRModels, DelimitedFiles
here = @__DIR__
nwk = strip(read(joinpath(here, "tree.nwk"), String))
cc = readdlm(joinpath(here, "coords.csv"), ',', skipstart = 1)
coords = Dict(String(cc[i, 1]) => [Float64(cc[i, 2]), Float64(cc[i, 3])] for i in 1:size(cc, 1))
for seed in parse.(Int, ARGS), kind in (:phylo, :spatial)
    M = readdlm(joinpath(here, "data", "$(kind)_$(seed).csv"), ',', skipstart = 1)
    d = (; id = String.(M[:, 1]), x = Float64.(M[:, 2]), z0 = Float64.(M[:, 3]), z1 = Float64.(M[:, 4]), y = Float64.(M[:, 5]))
    f = kind === :phylo ?
        bf(@formula(y ~ x + phylo(1 + x | id)), @formula(sd(id, phylogenetic, coef(intercept)) ~ z0), @formula(sd(id, phylogenetic, coef(x)) ~ z1)) :
        bf(@formula(y ~ x + spatial(1 + x | id)), @formula(sd(id, spatial, coef(intercept)) ~ z0), @formula(sd(id, spatial, coef(x)) ~ z1))
    kw = kind === :phylo ? (; tree = nwk) : (; coords)
    tag = "$(kind)_$(seed)"
    t = @elapsed fit = try drm(f, Binomial(); data = d, kw...) catch e; println(tag, " JULIA ERROR: ", sprint(showerror, e)); continue end
    se = stderror(fit)
    open(joinpath(here, "out", "j_$(tag).csv"), "w") do io
        println(io, "term,est,se")
        for (k, nm) in enumerate(("mu_int", "mu_x", "sd0_int", "sd0_z0", "sd1_int", "sd1_z1"))
            println(io, "$nm,$(fit.theta[k]),$(se[k])")
        end
    end
    sdmin = minimum(minimum(fit.scales[Symbol(string(first(b)), "_group")]) for b in fit.blocks[2:3])
    open(joinpath(here, "out", "j_$(tag)_ll.txt"), "w") do io
        println(io, "$(loglikelihood(fit)) $(fit.converged) $(round(t, digits = 2)) $(sdmin)")
    end
    println(tag, " ll=", loglikelihood(fit), " conv=", fit.converged, " t=", round(t, digits = 1))
end
