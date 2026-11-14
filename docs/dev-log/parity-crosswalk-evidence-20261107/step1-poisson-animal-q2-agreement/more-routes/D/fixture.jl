# Gaussian independent two-field structured intercept-plus-slope with one SD
# formula per coefficient:
#   y ~ x + animal|relmat(1 + x | g),  sd(g, <level>, coef(intercept)) ~ z0,
#   sd(g, <level>, coef(x)) ~ z1.
# Exact marginal likelihood y ~ N(X b, sigma^2 I + L0 C L0' + L1 C L1'), C RAW.
# Oracle is an independent dense MvNormal log density (no fitter code shared).
# Tolerances (fixed before the first run): nll vs oracle atol 1e-6; SD
# coefficient recovery |est - truth| < 1.0 (G = 30 levels, loose, no calibration
# claim); fit sits at an optimum of the oracle surface (+/- 0.05 steps).
using DRModels, Test, Random, LinearAlgebra
import Distributions

function _gq2_fixture(; G = 30, m = 12, seed = 20261107)
    rng = MersenneTwister(seed)
    R = 0.4 .^ abs.(reshape(1:G, :, 1) .- reshape(1:G, 1, :))
    s = collect(range(0.7, 1.6; length = G))
    C = Matrix(Diagonal(s) * R * Diagonal(s))
    labels = ["id_$(i)" for i in randperm(rng, G)]
    z0 = repeat([-1.0, 1.0], inner = G ÷ 2)
    z1 = collect(range(-1.0, 1.0; length = G))[randperm(rng, G)]
    a0, a1 = [-0.7, 0.4], [-0.9, 0.5]
    L = cholesky(Symmetric(C)).L
    u0 = exp.(a0[1] .+ a0[2] .* z0) .* (L * randn(rng, G))
    u1 = exp.(a1[1] .+ a1[2] .* z1) .* (L * randn(rng, G))
    gi = repeat(1:G, inner = m)
    x = randn(rng, G * m)
    y = 0.3 .+ 0.2 .* x .+ u0[gi] .+ x .* u1[gi] .+ 0.4 .* randn(rng, G * m)
    ord = randperm(rng, length(y))
    group = labels[gi][ord]
    fitted = unique(group)
    orig = [findfirst(==(l), labels) for l in fitted]
    gidx = [findfirst(==(l), fitted) for l in group]
    data = (; y = y[ord], x = x[ord], z0 = z0[orig][gidx], z1 = z1[orig][gidx], g = group)
    return (; data, C = C[orig, orig], gidx, z0 = z0[orig], z1 = z1[orig], a0, a1)
end

function _gq2_oracle(theta, fx)
    y, x, gi = fx.data.y, fx.data.x, fx.gidx
    n, G = length(y), length(fx.z0)
    beta, sigma, a0, a1 = theta[1:2], exp(theta[3]), theta[4:5], theta[6:7]
    d0 = exp.(hcat(ones(G), fx.z0) * a0); d1 = exp.(hcat(ones(G), fx.z1) * a1)
    L0 = zeros(n, G); L1 = zeros(n, G)
    for i in 1:n
        L0[i, gi[i]] = d0[gi[i]]; L1[i, gi[i]] = x[i] * d1[gi[i]]
    end
    V = sigma^2 * Matrix(I, n, n) + L0 * fx.C * L0' + L1 * fx.C * L1'
    return -Distributions.logpdf(
        Distributions.MvNormal(hcat(ones(n), x) * beta, Symmetric(V)), y)
end

_gq2_formula(kind) = bf(
    kind === :animal ? @formula(y ~ x + animal(1 + x | g)) : @formula(y ~ x + relmat(1 + x | g)),
    @formula(sigma ~ 1),
    kind === :animal ? @formula(sd(g, animal, coef(intercept)) ~ z0) :
                       @formula(sd(g, relmat, coef(intercept)) ~ z0),
    kind === :animal ? @formula(sd(g, animal, coef(x)) ~ z1) :
                       @formula(sd(g, relmat, coef(x)) ~ z1))
_gq2_kw(kind, fx) = kind === :animal ? (; A = fx.C) : (; K = fx.C)

