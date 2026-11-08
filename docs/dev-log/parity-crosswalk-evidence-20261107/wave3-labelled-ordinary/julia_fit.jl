# Julia labelled ordinary q2 fits `(1 + x | p | g)` on the R-generated fixtures (run from this directory).
# Usage: SEEDS="2026110801 ..." julia --project=<DRModels test env> julia_fit.jl
# Writes julia_<family>_<seed>.csv (block, est, se) and julia_ll.csv.
using DRModels, DelimitedFiles, Printf
const O = @__DIR__

function readcsv(path)
    m, h = readdlm(path, ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]
    Dict(h[j] => m[:, j] for j in eachindex(h))
end

seeds = split(get(ENV, "SEEDS", "2026110801"))
lls = ["seed,family,ll,converged,secs"]
for sd_ in seeds
    d = readcsv(joinpath(O, "data_$(sd_).csv"))
    data = (; yp = Float64.(d["yp"]), yn = Float64.(d["yn"]), x = Float64.(d["x"]),
            z0 = Float64.(d["z0"]), z1 = Float64.(d["z1"]), g = String.(d["g"]))
    for (lab, resp, fam) in (("poisson", :yp, Poisson()), ("nb2", :yn, NegBinomial2()))
        mu = DRModels.@eval(@formula($resp ~ x + (1 + x | p | g)))
        f0 = @formula(sd(g, coef(intercept)) ~ z0); f1 = @formula(sd(g, coef(x)) ~ z1)
        f = fam isa Poisson ? bf(mu, f0, f1) : bf(mu, @formula(sigma ~ 1), f0, f1)
        t = @elapsed fit = drm(f, fam; data)
        se = stderror(fit)
        blocks = String[]
        for (b, r) in fit.blocks, _ in r; push!(blocks, String(b)); end
        open(joinpath(O, "julia_$(lab)_$(sd_).csv"), "w") do io
            println(io, "block,est,se")
            for k in eachindex(fit.theta)
                @printf(io, "%s,%.12f,%.12f\n", blocks[k], fit.theta[k], se[k])
            end
        end
        push!(lls, @sprintf("%s,%s,%.12f,%s,%.2f", sd_, lab, loglikelihood(fit), fit.converged, t))
        @printf("%s %s ll=%.10f conv=%s t=%.1fs\n", sd_, lab, loglikelihood(fit), fit.converged, t)
    end
end
write(joinpath(O, "julia_ll.csv"), join(lls, "\n") * "\n")
