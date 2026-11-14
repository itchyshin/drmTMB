using DRModels, Random, LinearAlgebra, SparseArrays, Printf
import Distributions
_sll_bern(rng, eta) = Float64[rand(rng, Distributions.Bernoulli(1 / (1 + exp(-v)))) for v in eta]
function _sll_animal_fixture(; G = 24, m = 12, seed = 20261104, rho = 0.4)
    rng = MersenneTwister(seed)
    ids = ["animal_$(i)" for i in randperm(rng, G)]
    R = rho .^ abs.(reshape(1:G, :, 1) .- reshape(1:G, 1, :))
    scale = collect(range(0.7, 1.5; length = G))
    A = Diagonal(scale) * R * Diagonal(scale)
    gidx = repeat(1:G, inner = m)
    z0 = repeat([-1.0, 1.0], inner = G ÷ 2)[randperm(rng, G)]
    z1 = collect(range(-1.0, 1.0; length = G))[randperm(rng, G)]
    x = repeat(collect(range(-1.2, 1.2; length = m)), outer = G)
    L = cholesky(Symmetric(A)).L
    return (; rng, G, m, ids, A, gidx, z0, z1, x, L, group = repeat(ids, inner = m))
end
f = _sll_animal_fixture(G = 24, m = 16, seed = 20261107, rho = 0.3)
l0 = f.L * randn(f.rng, f.G); l1 = 0.4 .* l0 .+ sqrt(1 - 0.4^2) .* (f.L * randn(f.rng, f.G))
eta = -0.1 .+ 0.25 .* f.x .+ (exp.(-0.6 .+ 0.5 .* f.z0) .* l0)[f.gidx] .+
      f.x .* (exp.(-0.75 .+ 0.6 .* f.z0) .* l1)[f.gidx]
data = (; y = _sll_bern(f.rng, eta), x = f.x, z0 = f.z0[f.gidx], z1 = f.z0[f.gidx], group = f.group)
fm = bf(@formula(y ~ x + animal(1 + x | group)),
        @formula(sd(group, animal, coef(intercept)) ~ z0),
        @formula(sd(group, animal, coef(x)) ~ z1))
t = @elapsed fit = drm(fm, DRModels.Binomial(); data, A = f.A, se = false)
@printf("VERSION=%s ll=%.8f converged=%s iters=%s t=%.1f\n", VERSION, loglikelihood(fit), fit.converged, string(fit.iterations), t)
println("theta=", fit.theta)
