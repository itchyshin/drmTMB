# usage: julia --project=<env> fit_spatial.jl <datadir> <outdir> seed_from seed_to  (coords.csv in <datadir>/..)
using DRModels, DelimitedFiles, Printf
datadir, outdir = ARGS[1], ARGS[2]; mkpath(outdir)
cm, _ = readdlm(joinpath(datadir, "..", "coords.csv"), ',', Any; header = true)
coords = Dict(String(cm[k, 1]) => [Float64(cm[k, 2]), Float64(cm[k, 3])] for k in 1:size(cm, 1))
function readd(path)
    m, h = readdlm(path, ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]; c = Dict(h[j] => m[:, j] for j in eachindex(h))
    (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), g = String.(c["g"]))
end
f = bf(@formula(y ~ x + spatial(1 + x | g)), @formula(sd(g, spatial, coef(intercept)) ~ z0), @formula(sd(g, spatial, coef(x)) ~ z1))
for s in parse(Int, ARGS[3]):parse(Int, ARGS[4])
    tag = @sprintf("poisson_spatial_s%03d", s)
    d = readd(joinpath(datadir, tag * ".csv"))
    try
        t = @elapsed fit = drm(f, Poisson(); data = d, coords = coords)
        se = stderror(fit)
        open(joinpath(outdir, tag * ".csv"), "w") do io
            println(io, "block,k,est,se")
            for (b, r) in fit.blocks, (k, j) in enumerate(r); println(io, "$(b),$(k),$(repr(fit.theta[j])),$(repr(se[j]))"); end
        end
        open(joinpath(outdir, tag * "_ll.csv"), "w") do io
            println(io, "ll,converged,seconds"); println(io, "$(repr(loglikelihood(fit))),$(fit.converged),$t")
        end
        @printf("%s ll=%.10f converged=%s t=%.1fs\n", tag, loglikelihood(fit), fit.converged, t)
    catch e
        open(joinpath(outdir, tag * "_ll.csv"), "w") do io; println(io, "ll,converged,seconds"); println(io, "NA,error,NA"); end
        println(tag, " ERROR ", sprint(showerror, e)[1:min(end, 300)])
    end
end
