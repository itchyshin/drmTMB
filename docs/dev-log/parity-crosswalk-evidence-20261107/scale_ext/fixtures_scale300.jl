using DRModels, Random, LinearAlgebra
import Distributions

function _poisson_animal_q2_fixture(; G = 48, m = 24, seed = 202611071)
    rng = MersenneTwister(seed)
    ids = ["animal_$(i)" for i in randperm(rng, G)]
    R = 0.35 .^ abs.(reshape(1:G, :, 1) .- reshape(1:G, 1, :))
    scale = collect(range(0.7, 1.4; length = G))
    A = Diagonal(scale) * R * Diagonal(scale)
    group = repeat(ids, inner = m)
    gidx = repeat(1:G, inner = m)
    z0group = ifelse.(randperm(rng, G) .<= G ÷ 2, -1.0, 1.0)
    z1group = collect(range(-1.0, 1.0; length = G))[randperm(rng, G)]
    x = repeat(collect(range(-1.2, 1.2; length = m)), outer = G)
    alpha0 = [-0.9, 0.35]
    alpha1 = [-1.0, 0.45]
    L = cholesky(Symmetric(A)).L
    u0, u1 = L * randn(rng, G), L * randn(rng, G)
    eta = 0.2 .+ 0.3 .* x .+
        (exp.(alpha0[1] .+ alpha0[2] .* z0group) .* u0)[gidx] .+
        x .* (exp.(alpha1[1] .+ alpha1[2] .* z1group) .* u1)[gidx]
    y = Float64.([rand(rng, Distributions.Poisson(exp(v))) for v in eta])
    return (; data = (; y, x, z0 = z0group[gidx], z1 = z1group[gidx], g = group),
            A, gidx, z0group, z1group, alpha0, alpha1)
end

function _nb2_relmat_q2_fixture(; G = 48, m = 24, seed = 202611072, sigma = 0.45)
    rng = MersenneTwister(seed)
    ids = ["unit_$(i)" for i in randperm(rng, G)]
    R = 0.35 .^ abs.(reshape(1:G, :, 1) .- reshape(1:G, 1, :))
    scale = collect(range(0.7, 1.4; length = G))
    A = Diagonal(scale) * R * Diagonal(scale)
    group = repeat(ids, inner = m)
    gidx = repeat(1:G, inner = m)
    z0group = ifelse.(randperm(rng, G) .<= G ÷ 2, -1.0, 1.0)
    z1group = collect(range(-1.0, 1.0; length = G))[randperm(rng, G)]
    x = repeat(collect(range(-1.2, 1.2; length = m)), outer = G)
    alpha0 = [-0.9, 0.35]
    alpha1 = [-1.0, 0.45]
    L = cholesky(Symmetric(A)).L
    u0, u1 = L * randn(rng, G), L * randn(rng, G)
    eta = 0.2 .+ 0.3 .* x .+
        (exp.(alpha0[1] .+ alpha0[2] .* z0group) .* u0)[gidx] .+
        x .* (exp.(alpha1[1] .+ alpha1[2] .* z1group) .* u1)[gidx]
    r = 1 / sigma^2
    y = Float64.([rand(rng, Distributions.NegativeBinomial(r, r / (r + exp(v))))
                  for v in eta])
    return (; data = (; y, x, z0 = z0group[gidx], z1 = z1group[gidx], g = group),
            A, gidx, z0group, z1group, alpha0, alpha1, sigma)
end

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

# Gaussian ordinary q2, both coefficient SDs, rho 0.4 (generator of more-routes/H-q2-ordinary with a seed argument).
function _gord_fixture(; G = 150, m = 10, seed = 20261107)
    rng = MersenneTwister(seed)
    w0g = collect(range(-1.5, 1.5; length = G))[randperm(rng, G)]
    w1g = collect(range(-1.5, 1.5; length = G))[randperm(rng, G)]
    gi = repeat(1:G, inner = m); n = G * m
    x = randn(rng, n); y = 0.2 .+ 0.5 .* x .+ 0.4 .* randn(rng, n)
    Rm = [1 0.4; 0.4 1.0]
    for g in 1:G
        D = Diagonal(exp.([-0.5 + 0.5 * w0g[g], -0.8 - 0.4 * w1g[g]]))
        b = cholesky(Symmetric(D * Rm * D)).L * randn(rng, 2)
        rows = ((g - 1) * m + 1):(g * m); y[rows] .+= b[1] .+ x[rows] .* b[2]
    end
    return (; data = (; y, x, z0 = w0g[gi], z1 = w1g[gi], g = ["g$(g)" for g in gi]))
end
