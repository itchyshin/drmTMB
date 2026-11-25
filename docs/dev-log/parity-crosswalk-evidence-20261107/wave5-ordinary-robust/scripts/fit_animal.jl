# usage: julia --project=<env> fit_animal.jl <datadir> <outdir> seed_from seed_to
using DRModels, DelimitedFiles, Printf
datadir, outdir = ARGS[1], ARGS[2]; mkpath(outdir)
for s in parse(Int, ARGS[3]):parse(Int, ARGS[4])
    tag = @sprintf("gauss_animal_s%03d", s)
    m, h = readdlm(joinpath(datadir, tag * ".csv"), ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]; c = Dict(h[j] => m[:, j] for j in eachindex(h))
    d = (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), g = String.(c["g"]))
    K = readdlm(joinpath(datadir, tag * "_K.csv"), ',', Float64)
    f = bf(@formula(y ~ x + animal(1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, animal, coef(intercept)) ~ z0), @formula(sd(g, animal, coef(x)) ~ z1))
    try
        t = @elapsed fit = drm(f, Gaussian(); data = d, A = K)
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
