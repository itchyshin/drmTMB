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

using SparseArrays; const Optim = DRModels.Optim
const D = DRModels
G = f.G
y = data.y; ntr = ones(length(y))
Xmu = hcat(ones(length(y)), data.x)
z0g = f.z0; Xsd0 = hcat(ones(G), z0g); Xsd1 = hcat(ones(G), z0g)
Q = sparse(inv(cholesky(Symmetric(Matrix(f.A)))))
qchol = cholesky(Symmetric(Q)); logdetQ = logdet(qchol)
sint = round.(Int, y); nint = round.(Int, ntr)
logchoose = zeros(length(y))
aux = (s = sint, ntr = nint, logchoose = logchoose)
gidx = f.gidx; x = Float64.(data.x)
last_b = zeros(2G)
function nll(theta)
    value, b, ok = D._binomial_animal_q2_laplace(aux, y, ntr, Xmu, Xsd0, Xsd1, gidx, Q, logdetQ, x, theta; b0 = last_b, correlated = true)
    if !ok
        value, b, ok = D._binomial_animal_q2_laplace(aux, y, ntr, Xmu, Xsd0, Xsd1, gidx, Q, logdetQ, x, theta; b0 = zeros(2G), correlated = true)
    end
    ok || return 1e18
    last_b .= b
    value
end
function grad!(g, theta)
    for j in eachindex(theta)
        h = 2e-4 * (1 + abs(theta[j]))
        e = zeros(length(theta)); e[j] = h
        g[j] = (nll(theta .+ e) - nll(theta .- e)) / (2h)
    end
    g
end
theta0 = zeros(7)
theta0[1] = D._binomial_start(DRModels.Binomial(), clamp(sum(y)/length(y), 1e-4, 1-1e-4))
theta0[3:4] .= Xsd0 \ fill(log(0.4), G)
theta0[5:6] .= Xsd1 \ fill(log(0.3), G)
