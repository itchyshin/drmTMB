# Julia fit of NB2 structured sigma intercept + one slope (fixed SDs); reads data/ written by r_run.R.
# usage: julia --project=<DRModels test env> julia_run.jl <route> [seed_from seed_to]
using DRModels, DelimitedFiles, Printf
route = ARGS[1]
s_from = length(ARGS) >= 3 ? parse(Int, ARGS[2]) : 1
s_to = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1
O = @__DIR__
function readcsv(path)
    lines = readlines(path); uq(t) = strip(t, '"')
    hdr = uq.(split(lines[1], ','))
    cols = [uq.(split(l, ',')) for l in lines[2:end]]
    return (; (Symbol(h) => [c[j] for c in cols] for (j, h) in enumerate(hdr))...)
end
form = Dict("animal" => bf(@formula(y ~ x), @formula(sigma ~ 1 + animal(1 + x | id))),
            "relmat" => bf(@formula(y ~ x), @formula(sigma ~ 1 + relmat(1 + x | id))),
            "phylo" => bf(@formula(y ~ x), @formula(sigma ~ 1 + phylo(1 + x | id))),
            "spatial" => bf(@formula(y ~ x), @formula(sigma ~ 1 + spatial(1 + x | id))))[route]
for s in s_from:s_to
    tag = @sprintf("%s_s%02d", route, s)
    r = readcsv(joinpath(O, "data", tag * ".csv"))
    d = (; y = parse.(Float64, r.y), x = parse.(Float64, r.x), id = String.(r.id))
    kw = if route in ("animal", "relmat")
        K = readdlm(joinpath(O, "data", tag * "_K.csv"), ',', Float64)
        route == "animal" ? (; A = K) : (; K = K)
    elseif route == "phylo"
        (; tree = strip(read(joinpath(O, "data", tag * "_tree.nwk"), String)))
    else
        c = readdlm(joinpath(O, "data", tag * "_coords.csv"), ',', Any; skipstart = 1)
        (; coords = Matrix{Float64}(c[:, 2:3]))
    end
    t0 = time()
    fit = try
        drm(form, NegBinomial2(); data = d, kw...)
    catch e
        println(tag, " JULIA ERROR: ", sprint(showerror, e)[1:min(end, 300)])
        open(joinpath(O, "julia", tag * "_ll.csv"), "w") do io
            println(io, "ll,converged,seconds\nNA,error,$(time() - t0)")
        end
        continue
    end
    el = time() - t0
    se = stderror(fit)
    open(joinpath(O, "julia", tag * ".csv"), "w") do io
        println(io, "block,est,se")
        k = 0
        for (b, rg) in fit.blocks, i in rg
            k += 1; println(io, "$b,$(repr(fit.theta[i])),$(repr(se[i]))")
        end
    end
    open(joinpath(O, "julia", tag * "_ll.csv"), "w") do io
        println(io, "ll,converged,seconds"); println(io, "$(@sprintf("%.12f", loglik(fit))),$(fit.converged),$el")
    end
    @printf("%s ll=%.8f converged=%s t=%.1fs\n", tag, loglik(fit), fit.converged, el)
end
