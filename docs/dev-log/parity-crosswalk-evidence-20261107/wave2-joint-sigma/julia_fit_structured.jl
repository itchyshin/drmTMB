# Julia side, Gaussian phylo / spatial sigma intercept with an SD formula.
using DRModels, Random, LinearAlgebra, Statistics, Printf
const O = @__DIR__
include(joinpath(O, "fixture_structured.jl"))
for (p, seed) in ((:phylo, 2026110711), (:spatial, 2026110712))
    fx = _gps_fixture(p; seed); d = fx.data
    nm = "gaussian_$(p)_sigma"
    open(joinpath(O, "data_$nm.csv"), "w") do io
        println(io, "y,x,id,z"); for i in eachindex(d.y); println(io, join((d.y[i], d.x[i], d.id[i], d.z[i]), ",")); end
    end
    if p === :phylo
        write(joinpath(O, "tree_$nm.nwk"), fx.tree)
        fm = bf(@formula(y ~ x), @formula(sigma ~ 1 + phylo(1 | id)), @formula(sd(id, phylogenetic, sigma) ~ z))
        fit = drm(fm, Gaussian(); data = d, tree = fx.tree)
    else
        open(joinpath(O, "coords_$nm.csv"), "w") do io
            println(io, "id,cx,cy"); for j in eachindex(fx.ids); println(io, "$(fx.ids[j]),$(fx.coords[j,1]),$(fx.coords[j,2])"); end
        end
        fm = bf(@formula(y ~ x), @formula(sigma ~ 1 + spatial(1 | id)), @formula(sd(id, spatial, sigma) ~ z))
        fit = drm(fm, Gaussian(); data = d, coords = fx.coords)
    end
    se = stderror(fit); pos = 0
    open(joinpath(O, "jcoef_$nm.csv"), "w") do io
        println(io, "block,k,est,se")
        for (k, _) in fit.blocks
            est = vec(coef(fit, k)); for i in eachindex(est); pos += 1; println(io, "$k,$i,$(est[i]),$(se[pos])"); end
        end
    end
    write(joinpath(O, "jll_$nm.txt"), repr(loglik(fit)))
    @printf("%s conv=%s ll=%.10f\n", nm, fit.converged, loglik(fit))
end
