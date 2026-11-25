# usage: julia --project=<env> nb2phylo.jl seed [seed...]   (data in ./data, tree.nwk here)
using DRModels, DelimitedFiles, Printf
const HERE = @__DIR__
tree = strip(read(joinpath(HERE, "tree.nwk"), String))
function load(s)
    tag = @sprintf("nb2_phylo_s%03d", s)
    m, h = readdlm(joinpath(HERE, "data", tag * ".csv"), ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]; c = Dict(h[j] => m[:, j] for j in eachindex(h))
    (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), g = String.(c["g"]))
end
f = bf(@formula(y ~ x + phylo(1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, phylogenetic, coef(intercept)) ~ z0), @formula(sd(g, phylogenetic, coef(x)) ~ z1))
for s in parse.(Int, ARGS)
    d = load(s)
    t = @elapsed fit = drm(f, NegBinomial2(); data = d, tree, se = false)
    @printf("s%03d ll=%.10f conv=%s it=%s t=%.1f theta=%s\n", s, loglikelihood(fit), fit.converged, string(fit.iterations), t, string(round.(fit.theta, digits = 3)))
end
