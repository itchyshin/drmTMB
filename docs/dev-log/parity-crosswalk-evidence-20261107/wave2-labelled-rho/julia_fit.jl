# Writes data.csv, A.csv, A_ids.csv and julia_<route>.csv (est, se) + julia_ll.csv.
include(joinpath(@__DIR__, "fixture.jl"))
using DelimitedFiles
O = @__DIR__
fx = _lrho_fixture(); d = fx.data
open(joinpath(O, "data.csv"), "w") do io
    println(io, "yp,yn,yg,x,z0,z1,g")
    for i in eachindex(d.yp)
        println(io, join((Int(d.yp[i]), Int(d.yn[i]), repr(d.yg[i]), repr(d.x[i]), d.z0[i], repr(d.z1[i]), d.g[i]), ","))
    end
end
ids = unique(d.g)
open(joinpath(O, "A.csv"), "w") do io
    for i in 1:size(fx.A, 1); println(io, join(repr.(fx.A[i, :]), ",")); end
end
open(joinpath(O, "A_ids.csv"), "w") do io; println(io, "id"); foreach(s -> println(io, s), ids); end
lls = String[]
for (lab, resp, fam, extra) in (("poisson", :yp, Poisson(), ()),
                                ("nb2", :yn, NegBinomial2(), (@formula(sigma ~ 1),)),
                                ("gaussian", :yg, Gaussian(), (@formula(sigma ~ 1),)))
    for kind in (:animal, :relmat)
        f = kind === :animal ?
            bf(DRModels.@eval(@formula($resp ~ x + animal(1 + x | p | g))), extra...,
               @formula(sd(g, animal, coef(intercept)) ~ z0), @formula(sd(g, animal, coef(x)) ~ z1)) :
            bf(DRModels.@eval(@formula($resp ~ x + relmat(1 + x | p | g))), extra...,
               @formula(sd(g, relmat, coef(intercept)) ~ z0), @formula(sd(g, relmat, coef(x)) ~ z1))
        fit = kind === :animal ? drm(f, fam; data = d, A = fx.A) : drm(f, fam; data = d, K = fx.A)
        se = stderror(fit)
        open(joinpath(O, "julia_$(lab)_$(kind).csv"), "w") do io
            println(io, "block,k,est,se")
            for (b, r) in fit.blocks, (k, j) in enumerate(r)
                println(io, "$(b),$(k),$(repr(fit.theta[j])),$(repr(se[j]))")
            end
        end
        push!(lls, "$(lab),$(kind),$(repr(loglikelihood(fit))),$(fit.converged)")
        println(lab, " ", kind, " ll=", loglikelihood(fit), " conv=", fit.converged)
    end
end
open(joinpath(O, "julia_ll.csv"), "w") do io; println(io, "family,kind,ll,converged"); foreach(l -> println(io, l), lls); end
