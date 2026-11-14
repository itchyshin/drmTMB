# Gaussian sigma-side structured intercept with an SD formula (twin of drmTMB
# test-gaussian-sigma-structured-sd.R, animal / relmat providers):
#   y ~ x,  sigma ~ 1 + animal(1 | id, A) | relmat(1 | id, K)
#   sd(id, <level>, sigma) ~ z
#   eta_i = s0 + exp(alpha0 + alpha1 z_g) u_g,  u ~ N(0, K)  (K raw, not normalised)
# The marginal is non-Gaussian; the oracle is an independent dense Laplace over u
# (own mode finder and derivatives; no DRModels internals) at the fitted
# parameters. Tolerances fixed before the first run: |logLik - oracle| < 1e-4,
# oracle mode |grad|_inf < 1e-8 with PD Hessian, constant-SD limit logLik 1e-5
# against the same fit with `sd ~ 1` evaluated at the oracle, recovery
# |alpha_hat - alpha| < 0.8 (n_g = 48 groups; loose, scope is likelihood).
using DRModels, Random, Test, LinearAlgebra

function _gss_fixture(; seed = 2026110103, n_g = 48, n_each = 20)
    rng = MersenneTwister(seed)
    diagonal = collect(range(0.7, 1.4; length = n_g))
    K = [0.3^abs(i - j) * sqrt(diagonal[i] * diagonal[j]) for i in 1:n_g, j in 1:n_g]
    z = collect(range(-1, 1; length = n_g))
    u = cholesky(Symmetric(K)).L * randn(rng, n_g)
    alpha = [log(0.45), 0.5]
    group = repeat(1:n_g; inner = n_each)
    x = randn(rng, length(group))
    scale = exp.(alpha[1] .+ alpha[2] .* z)
    y = 0.2 .+ 0.5 .* x .+ exp.(log(0.5) .+ scale[group] .* u[group]) .* randn(rng, length(group))
    id = [string("s", lpad(string(g), 2, '0')) for g in group]
    return (; data = (; y, x, id, z = z[group]), K, z, group, alpha)
end

function _gss_oracle(y, mu0, K, group, s0, scale)
    m = size(K, 1)
    P = inv(K); P = (P + P') / 2
    ldK = logdet(cholesky(Symmetric(K)))
    eta(u) = s0 .+ scale[group] .* u[group]
    f(u) = begin
        e = eta(u); r = y .- mu0
        sum(0.5 * log(2π) .+ e .+ 0.5 .* r .^ 2 .* exp.(-2 .* e)) +
            0.5 * dot(u, P * u) + 0.5 * ldK + 0.5 * m * log(2π)
    end
    grad(u) = begin
        e = eta(u); r = y .- mu0
        w = 1 .- r .^ 2 .* exp.(-2 .* e)
        g = zeros(m)
        for i in eachindex(y); g[group[i]] += scale[group[i]] * w[i]; end
        g .+ P * u
    end
    hess(u) = begin
        e = eta(u); r = y .- mu0
        H = copy(P)
        for i in eachindex(y)
            H[group[i], group[i]] += scale[group[i]]^2 * 2 * r[i]^2 * exp(-2 * e[i])
        end
        H
    end
    u = zeros(m)
    for _ in 1:5000                        # damped Newton to the coarse basin
        g = grad(u); maximum(abs, g) < 1e-3 && break
        H = hess(u)
        step = H \ g
        t = 1.0; f0 = f(u)
        while t > 1e-10 && f(u .- t .* step) > f0; t /= 2; end
        u .-= t .* step
    end
    for _ in 1:50                          # pure Newton polish
        g = grad(u); maximum(abs, g) < 1e-11 && break
        u .-= hess(u) \ g
    end
    H = hess(u)
    return (; loglik = -f(u) + 0.5 * m * log(2π) - 0.5 * logdet(cholesky(Symmetric(H))),
            max_grad = maximum(abs, grad(u)),
            min_eig = minimum(eigvals(Symmetric(H))))
end

function _gss_fit(fx, kind; constant = false)
    d = fx.data; K = fx.K
    if kind === :animal
        return drm(bf(@formula(y ~ x), @formula(sigma ~ 1 + animal(1 | id)),
                      constant ? @formula(sd(id, animal, sigma) ~ 1) :
                                 @formula(sd(id, animal, sigma) ~ z)),
                   Gaussian(); data = d, A = K)
    end
    return drm(bf(@formula(y ~ x), @formula(sigma ~ 1 + relmat(1 | id)),
                  constant ? @formula(sd(id, relmat, sigma) ~ 1) :
                             @formula(sd(id, relmat, sigma) ~ z)),
               Gaussian(); data = d, K = K)
end

