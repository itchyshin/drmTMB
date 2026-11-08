# Writes data/data.csv and data/A.csv from the Julia test fixture `tf_case` (40 animals x 14 rows,
# labelled `animal(1 + x | p | g)` with coefficient SD formulas, truth rho = 0.5).
# Run from the DRModels.jl worktree root:  julia --project=test <this file> <out dir>
# y_nb2 is the NB2 draw, y_gamma the Gamma draw (same latent field), y_gauss = log(y_gamma), and y_cnt a
# Poisson draw from the same kind of latent field (own generator below: independent fields scaled by the
# fixture's SD formulas, rho = 0.5), so the Poisson model is not badly misspecified.
using DRModels, LinearAlgebra, Random, DelimitedFiles
import Distributions, ForwardDiff
using SpecialFunctions: loggamma
src = read("test/test_gamma_nb2_twofield_sd.jl", String)
include_string(Main, src[1:first(findfirst("for (fam, shape) in", src)) - 1])
out = ARGS[1]; mkpath(out)
cn = tf_case(:nb2, :labanimal); cg = tf_case(:gamma, :labanimal)
@assert cn.data.g == cg.data.g
writedlm(joinpath(out, "A.csv"), cn.kw.A, ',')
d = cn.data
G = size(cn.kw.A, 1); m = length(d.y) ÷ G; gi = repeat(1:G, inner = m)
rng = MersenneTwister(77)
Lc = cholesky(Symmetric(cn.kw.A)).L
f0 = Lc * randn(rng, G); f1 = 0.5 .* f0 .+ sqrt(0.75) .* (Lc * randn(rng, G))
z1 = d.w1[1:m:end]; z2 = d.w2[1:m:end]
b1 = exp.(log(0.5) .+ 0.6 .* z1) .* f0; b2 = exp.(log(0.35) .- 0.6 .* z2) .* f1
y_cnt = [rand(rng, Distributions.Poisson(exp(0.4 + 0.3 * d.x[i] + b1[gi[i]] + d.x[i] * b2[gi[i]]))) for i in eachindex(d.y)]
open(joinpath(out, "data.csv"), "w") do io
    println(io, "y_nb2,y_gamma,y_cnt,y_gauss,x,w1,w2,g")
    for i in eachindex(d.y)
        println(io, d.y[i], ",", cg.data.y[i], ",", y_cnt[i], ",", log(cg.data.y[i]), ",", d.x[i], ",", d.w1[i], ",", d.w2[i], ",", d.g[i])
    end
end
