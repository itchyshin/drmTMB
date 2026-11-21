# Julia side of the wave-2 joint mu+sigma agreement. Run from the DRModels
# worktree:  julia --project=test <this file>
using DRModels, Random, Distributions, Printf
const O = @__DIR__
include(joinpath(O, "fixture.jl"))
fams = Dict(:gaussian => Gaussian(), :nb2 => NegBinomial2(), :gamma => DRModels.Gamma())
cases = [("nb2_crossed", :nb2, false, 2026110701), ("nb2_same", :nb2, true, 2026110702),
         ("gamma_crossed", :gamma, false, 2026110703), ("gamma_same", :gamma, true, 2026110704),
         ("gaussian_same", :gaussian, true, 2026110705)]
for (nm, fam, same, seed) in cases
    fx = _jsw_fixture(fam; seed, same); d = fx.data
    open(joinpath(O, "data_$nm.csv"), "w") do io
        println(io, "y,x,id,g,w,z")
        for i in eachindex(d.y); println(io, join((d.y[i], d.x[i], d.id[i], d.g[i], d.w[i], d.z[i]), ",")); end
    end
    fm = same ?
        bf(@formula(y ~ x + (1 | id)), @formula(sigma ~ 1 + (1 | id)), @formula(sd(id) ~ w), @formula(sd(id, sigma) ~ z)) :
        bf(@formula(y ~ x + (1 | id)), @formula(sigma ~ 1 + (1 | g)), @formula(sd(id) ~ w), @formula(sd(g, sigma) ~ z))
    t0 = time(); fit = drm(fm, fams[fam]; data = d); t1 = time() - t0
    se = stderror(fit); pos = 0
    open(joinpath(O, "jcoef_$nm.csv"), "w") do io
        println(io, "block,k,est,se")
        for (k, _) in fit.blocks
            est = vec(coef(fit, k))
            for i in eachindex(est); pos += 1; println(io, "$k,$i,$(est[i]),$(se[pos])"); end
        end
    end
    write(joinpath(O, "jll_$nm.txt"), repr(loglik(fit)))
    @printf("%s conv=%s ll=%.10f time=%.1fs\n", nm, fit.converged, loglik(fit), t1)
end
