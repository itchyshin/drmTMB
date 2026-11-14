# Gaussian joint mean + sigma ordinary random intercepts, each with an SD formula
# (twin of drmTMB test-gaussian-mu-sigma-joint-sd.R):
#   y ~ x + (1 | id),  sigma ~ 1 + (0 + z | site) | (1 | site)
#   sd(id) ~ w,        sd(site, sigma[, coef(z)]) ~ v
# The marginal is non-Gaussian, so the oracle is an independent dense Laplace
# in the RAW effect scale u = (a, b) (own mode finder, own derivatives; no
# DRModels internals), evaluated at the fitted parameters. Tolerances fixed
# before the first run: |logLik - oracle| < 1e-4; oracle mode |grad|_inf < 1e-8,
# Hessian PD; constant-SD limit logLik 1e-5, coefficients 1e-3; recovery
# |alpha_hat - alpha| < 0.5 (mean SD formula) / 0.6 (sigma SD formula).
using DRModels, Random, Test, LinearAlgebra

function _gjs_fixture(; seed = 20261101, n_id = 50, n_site = 80, n_each = 32,
                      alpha_mu = [log(0.6), 0.4], alpha_sigma = [log(0.35), 0.6],
                      slope = true)
    rng = MersenneTwister(seed)
    n = n_id * n_each
    row = 1:n
    id = [string("id", lpad(string((r - 1) ÷ n_each + 1), 2, '0')) for r in row]
    site = [string("s", lpad(string((r - 1) % n_site + 1), 2, '0')) for r in row]
    gi = [(r - 1) ÷ n_each + 1 for r in row]
    gs = [(r - 1) % n_site + 1 for r in row]
    w_id = collect(range(-1, 1; length = n_id))
    v_site = collect(range(-1, 1; length = n_site))
    sd_id = exp.(alpha_mu[1] .+ alpha_mu[2] .* w_id)
    sd_site = exp.(alpha_sigma[1] .+ alpha_sigma[2] .* v_site)
    a = sd_id .* randn(rng, n_id)
    b = sd_site .* randn(rng, n_site)
    x = randn(rng, n)
    z = slope ? randn(rng, n) : ones(n)
    eta = log(0.5) .+ b[gs] .* z
    y = 0.2 .+ 0.5 .* x .+ a[gi] .+ exp.(eta) .* randn(rng, n)
    data = (; y, x, z, id, site, w = w_id[gi], v = v_site[gs])
    return (; data, w_id, v_site, gi, gs, alpha_mu, alpha_sigma)
end

# Dense Laplace over u = (a, b), a_g ~ N(0, sd_a_g^2), b_j ~ N(0, sd_b_j^2),
# eta_i = s0 + b[gs_i] z_i; written from the model equations only.
function _gjs_oracle(y, mu0, z, gi, gs, s0, sd_a, sd_b)
    na, nb = length(sd_a), length(sd_b)
    m = na + nb
    pr(u) = begin
        a = u[1:na]; b = u[na+1:m]
        r = y .- mu0 .- a[gi]
        eta = s0 .+ b[gs] .* z
        return r, eta, exp.(-2 .* eta), a, b
    end
    negjoint(u) = begin
        r, eta, ie, a, b = pr(u)
        sum(eta .+ 0.5 .* r .^ 2 .* ie .+ 0.5 * log(2π)) +
            sum(0.5 .* a .^ 2 ./ sd_a .^ 2 .+ log.(sd_a) .+ 0.5 * log(2π)) +
            sum(0.5 .* b .^ 2 ./ sd_b .^ 2 .+ log.(sd_b) .+ 0.5 * log(2π))
    end
    grad(u) = begin
        r, eta, ie, a, b = pr(u)
        ge = 1 .- r .^ 2 .* ie
        g = zeros(m)
        for i in eachindex(y)
            g[gi[i]] += -r[i] * ie[i]
            g[na+gs[i]] += ge[i] * z[i]
        end
        g[1:na] .+= a ./ sd_a .^ 2
        g[na+1:m] .+= b ./ sd_b .^ 2
        return g
    end
    hess(u) = begin
        r, eta, ie, a, b = pr(u)
        H = zeros(m, m)
        for i in eachindex(y)
            H[gi[i], gi[i]] += ie[i]
            H[na+gs[i], na+gs[i]] += 2 * r[i]^2 * ie[i] * z[i]^2
            x = 2 * r[i] * ie[i] * z[i]
            H[gi[i], na+gs[i]] += x
            H[na+gs[i], gi[i]] += x
        end
        for k in 1:na; H[k, k] += 1 / sd_a[k]^2; end
        for j in 1:nb; H[na+j, na+j] += 1 / sd_b[j]^2; end
        return H
    end
    u = zeros(m)
    # coarse gradient descent with backtracking, then pure Newton to 1e-11
    for _ in 1:2000
        g = grad(u)
        maximum(abs, g) < 1e-3 && break
        H = hess(u)
        step = try cholesky(Symmetric(H)) \ g catch; g ./ (diag(H) .+ 1) end
        t = 1.0
        f0 = negjoint(u)
        while t > 1e-10 && negjoint(u .- t .* step) > f0
            t /= 2
        end
        u .-= t .* step
    end
    for _ in 1:50
        g = grad(u)
        maximum(abs, g) < 1e-11 && break
        u .-= hess(u) \ g
    end
    H = hess(u)
    ll = -negjoint(u) + 0.5 * m * log(2π) - 0.5 * logdet(cholesky(Symmetric(H)))
    return (; loglik = ll, max_grad = maximum(abs, grad(u)),
            min_eig = minimum(eigvals(Symmetric(H))))
end

function _gjs_oracle_from_fit(fit, fx, key_mu, key_sig)
    d = fx.data
    am = coef(fit, key_mu); asg = coef(fit, key_sig)
    sd_a = exp.(am[1] .+ am[2] .* fx.w_id)
    sd_b = exp.(asg[1] .+ asg[2] .* fx.v_site)
    X = hcat(ones(length(d.y)), d.x)
    return _gjs_oracle(d.y, X * coef(fit, :mu), d.z, fx.gi, fx.gs,
                       coef(fit, :sigma)[1], sd_a, sd_b)
end

