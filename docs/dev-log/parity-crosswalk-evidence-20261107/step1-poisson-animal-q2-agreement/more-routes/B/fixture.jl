using DRModels, Test, Random, LinearAlgebra
import Distributions

function _nb2_animal_q2_fixture(; G = 48, m = 24, seed = 202611072, sigma = 0.45)
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
    r = 1 / sigma^2
    y = Float64.([rand(rng, Distributions.NegativeBinomial(r, r / (r + exp(v))))
                  for v in eta])
    return (; data = (; y, x, z0 = z0group[gidx], z1 = z1group[gidx], g = group),
            A, gidx, z0group, z1group, alpha0, alpha1, sigma)
end

function _nb2_animal_q2_dense_laplace(theta, y, Xmu, x, Z0, Z1, gidx, A)
    G = size(A, 1)
    Q = inv(Symmetric(A))
    pmu = size(Xmu, 2)
    beta = theta[1:pmu]
    r = exp(-2 * theta[pmu + 1])
    p = size(Z0, 2)
    a0 = theta[(pmu + 2):(pmu + 1 + p)]
    a1 = theta[(pmu + 2 + p):end]
    eta0 = Xmu * beta
    load0 = exp.(Z0 * a0)
    load1 = x .* exp.(Z1 * a1)
    function joint(b)
        b0, b1 = @view(b[1:G]), @view(b[(G + 1):(2G)])
        value = 0.5 * dot(b0, Q * b0) + 0.5 * dot(b1, Q * b1)
        for i in eachindex(y)
            eta = eta0[i] + load0[i] * b0[gidx[i]] + load1[i] * b1[gidx[i]]
            value -= Distributions.logpdf(
                Distributions.NegativeBinomial(r, r / (r + exp(eta))), Int(y[i]))
        end
        value
    end
    result = DRModels.Optim.optimize(joint, zeros(2G), DRModels.Optim.LBFGS(),
        DRModels.Optim.Options(g_tol = 1e-10, iterations = 500);
        autodiff = :forward)
    mode = DRModels.Optim.minimizer(result)
    hessian = DRModels.ForwardDiff.hessian(joint, mode)
    Qjoint = [Matrix(Q) zeros(G, G); zeros(G, G) Matrix(Q)]
    return joint(mode) + 0.5 * logdet(Symmetric(hessian)) -
           0.5 * logdet(Symmetric(Qjoint))
end

