using DRModels, Random, LinearAlgebra
import Distributions

# Shared latent fields with a free correlation: unit fields (u0, u1) ~ N(0, R (x) A),
# R = [1 rho; rho 1]; b0 = s0[g] u0, b1 = s1[g] u1 (drmTMB's q2 covariance contract).
function _lrho_fixture(; G = 48, m = 24, seed = 202611073, rho = 0.5, sigma_nb = 0.45,
                       sigma_g = 0.5)
    rng = MersenneTwister(seed)
    ids = ["animal_$(i)" for i in randperm(rng, G)]
    R = 0.35 .^ abs.(reshape(1:G, :, 1) .- reshape(1:G, 1, :))
    scale = collect(range(0.7, 1.4; length = G))
    A = Matrix(Diagonal(scale) * R * Diagonal(scale))
    group = repeat(ids, inner = m)
    gidx = repeat(1:G, inner = m)
    z0group = ifelse.(randperm(rng, G) .<= G ÷ 2, -1.0, 1.0)
    z1group = collect(range(-1.0, 1.0; length = G))[randperm(rng, G)]
    x = repeat(collect(range(-1.2, 1.2; length = m)), outer = G)
    alpha0 = [-0.7, 0.35]
    alpha1 = [-0.9, 0.45]
    L = cholesky(Symmetric(A)).L
    n0, n1 = randn(rng, G), randn(rng, G)
    u0 = L * n0
    u1 = L * (rho .* n0 .+ sqrt(1 - rho^2) .* n1)
    eta = 0.2 .+ 0.3 .* x .+
        (exp.(alpha0[1] .+ alpha0[2] .* z0group) .* u0)[gidx] .+
        x .* (exp.(alpha1[1] .+ alpha1[2] .* z1group) .* u1)[gidx]
    yp = Float64.([rand(rng, Distributions.Poisson(exp(v))) for v in eta])
    r = 1 / sigma_nb^2
    yn = Float64.([rand(rng, Distributions.NegativeBinomial(r, r / (r + exp(v)))) for v in eta])
    yg = eta .+ sigma_g .* randn(rng, length(eta))
    return (; data = (; yp, yn, yg, x, z0 = z0group[gidx], z1 = z1group[gidx], g = group),
            A, gidx, z0group, z1group, alpha0, alpha1, rho)
end
