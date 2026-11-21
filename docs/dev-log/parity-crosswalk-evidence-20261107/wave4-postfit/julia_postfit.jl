# Julia counterpart of r_postfit.R: same fits, same per-row columns. Run from this directory:
#   julia --project=<DRModels test env> julia_postfit.jl
# PIT bounds are computed here from Distributions.jl at Julia's conditional parameters
# (population mean on the link scale + scales[:cond_eta_re], the Laplace modes at theta_hat).
using DRModels, DelimitedFiles, LinearAlgebra, Random, Printf, Statistics
import Distributions
const O = @__DIR__
function readcsv(path)
    m, h = readdlm(path, ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]
    Dict(h[j] => m[:, j] for j in eachindex(h))
end
mkpath(joinpath(O, "out"))
summ = ["tag,ll,conv,sd_r"]
function dump_fit(tag, fit, fam::Symbol, y)
    mu_pop = fit.means[:mu]
    ηre = get(fit.scales, :cond_eta_re, zeros(length(y)))
    mu = fam === :gaussian ? mu_pop .+ ηre : exp.(log.(mu_pop) .+ ηre)
    sg = haskey(fit.scales, :sigma) ? fit.scales[:sigma] : fill(NaN, length(y))
    r = residuals(fit; type = :quantile, rng = MersenneTwister(1))
    lo = zeros(length(y)); hi = zeros(length(y))
    for i in eachindex(y)
        k = 1 / sg[i]^2
        d = fam === :poisson ? Distributions.Poisson(mu[i]) :
            fam === :nb2 ? Distributions.NegativeBinomial(k, k / (k + mu[i])) :
            fam === :gamma ? Distributions.Gamma(k, mu[i] / k) :
            Distributions.Normal(mu[i], sg[i])
        hi[i] = Distributions.cdf(d, y[i])
        lo[i] = fam in (:poisson, :nb2) ? (y[i] > 0 ? Distributions.cdf(d, y[i] - 1) : 0.0) : hi[i]
    end
    open(joinpath(O, "out", "julia_$(tag).csv"), "w") do io
        println(io, "row,y,mu,sigma,lo,hi,r")
        for i in eachindex(y)
            @printf(io, "%d,%.10g,%.12g,%.12g,%.12g,%.12g,%.12g\n", i, y[i], mu[i], sg[i], lo[i], hi[i], r[i])
        end
    end
    open(joinpath(O, "out", "jcoef_$(tag).csv"), "w") do io
        println(io, "est"); foreach(v -> @printf(io, "%.12g\n", v), fit.theta)
    end
    push!(summ, @sprintf("%s,%.10f,%s,%.6f", tag, loglikelihood(fit), fit.converged, std(r)))
end
d = readcsv(joinpath(O, "data", "data.csv")); A = readdlm(joinpath(O, "data", "A.csv"), ',')
ids = unique(String.(d["g"]))
data = (; y_cnt = Float64.(d["y_cnt"]), y_nb2 = Float64.(d["y_nb2"]), y_gamma = Float64.(d["y_gamma"]),
        y_gauss = Float64.(d["y_gauss"]), x = Float64.(d["x"]), w1 = Float64.(d["w1"]),
        w2 = Float64.(d["w2"]), g = String.(d["g"]))
Ainv = Matrix(Symmetric(inv(A)))
for (fam, resp, F) in ((:poisson, :y_cnt, Poisson()), (:nb2, :y_nb2, NegBinomial2()),
                       (:gamma, :y_gamma, DRModels.Gamma()), (:gaussian, :y_gauss, Gaussian()))
    mu = DRModels.@eval(@formula($resp ~ x + animal(1 + x | p | g)))
    f0 = @formula(sd(g, animal, coef(intercept)) ~ w1); f1 = @formula(sd(g, animal, coef(x)) ~ w2)
    f = F isa Poisson ? bf(mu, f0, f1) : bf(mu, @formula(sigma ~ 1), f0, f1)
    for (inp, kw) in (("A", (; A, ids)), ("Ainv", (; Ainv)))
        fit = drm(f, F; data, kw...)
        dump_fit("$(fam)_$(inp)", fit, fam, getproperty(data, resp))
        @printf("%s %s ll=%.6f conv=%s\n", fam, inp, loglikelihood(fit), fit.converged)
    end
end
d3 = readcsv(joinpath(O, "data", "wave3_data_2026110801.csv"))
data3 = (; yp = Float64.(d3["yp"]), yn = Float64.(d3["yn"]), x = Float64.(d3["x"]),
         z0 = Float64.(d3["z0"]), z1 = Float64.(d3["z1"]), g = String.(d3["g"]))
for (fam, resp, F) in ((:poisson, :yp, Poisson()), (:nb2, :yn, NegBinomial2()))
    mu = DRModels.@eval(@formula($resp ~ x + (1 + x | g)))
    f0 = @formula(sd(g, coef(intercept)) ~ z0); f1 = @formula(sd(g, coef(x)) ~ z1)
    f = F isa Poisson ? bf(mu, f0, f1) : bf(mu, @formula(sigma ~ 1), f0, f1)
    fit = drm(f, F; data = data3)
    dump_fit("ordinary_$(fam)", fit, fam, getproperty(data3, resp))
    @printf("ordinary %s ll=%.6f conv=%s\n", fam, loglikelihood(fit), fit.converged)
end
write(joinpath(O, "out", "julia_summary.csv"), join(summ, "\n") * "\n")
