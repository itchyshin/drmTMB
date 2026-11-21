ENV["METAMORPHIC_LIB"] = "1"
using DRModels, Test
include(joinpath(ENV["WT"], "test", "test_metamorphic_sd_routes.jl"))
const M = TestMetamorphicSDRoutes
r = only(filter(x -> x[1].name == "nb2_sigma_animal", M.ROUTES))[1]
r = M.Route(; (k => getfield(r, k) for k in fieldnames(M.Route) if k != :seed)..., seed = 20261108)
fx = M.gen(r); data, kw = M.materialize(r, fx)
out = ARGS[1]
open(joinpath(out, "data.csv"), "w") do io
    println(io, "y,x,v,w0,id")
    for i in eachindex(data.y)
        println(io, join((Int(data.y[i]), data.x[i], data.v[i], data.w0[i], data.id[i]), ','))
    end
end
open(joinpath(out, "A.csv"), "w") do io
    for i in 1:size(kw.A, 1); println(io, join(kw.A[i, :], ',')); end
end
