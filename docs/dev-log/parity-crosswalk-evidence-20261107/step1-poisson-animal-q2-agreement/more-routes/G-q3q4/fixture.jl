# Gaussian ordinary correlated block of 3 or 4 coefficients with one SD
# formula per coefficient (twin of drmTMB test-gaussian-q3-per-coef-sd*.R):
#   y ~ x + z + (1 + x + z | id), sd(id, coef(intercept)) ~ w, sd(id, coef(x)) ~ w, …
# Exact marginal y_g ~ N(X_g b, s^2 I + U_g D R D U_g'), D = diag(exp(Z a_k)).
# Oracle: independent dense per-group MvNormal log density at the FITTED
# parameters (R rebuilt here from theta by the TMB UNSTRUCTURED_CORR_t map,
# no fitter helper shared). Tolerances, fixed before the first run:
#   logLik vs oracle   atol 1e-6
#   SD-formula slopes  |est - truth| < 1.0  (G = 60 groups, loose, no calibration claim)
#   correlations       |est - truth| < 0.4  (loose)
#   bug emulations (swapped SD columns, R = I) move the oracle by > 1 nat
#   nesting: logLik(w model) >= logLik(constant-SD model) - 1e-6
using DRModels, Test, Random, LinearAlgebra
import Distributions

function _q34_fixture(q; G = 60, m = 8, seed = 20261107)
    rng = MersenneTwister(seed)
    Rm = q == 3 ? [1 0.4 -0.3; 0.4 1 0.2; -0.3 0.2 1.0] :
                  [1 0.4 -0.3 0.2; 0.4 1 0.2 -0.1; -0.3 0.2 1 0.3; 0.2 -0.1 0.3 1.0]
    w = collect(range(-1.5, 1.5; length = G))[randperm(rng, G)]
    a0 = [-0.5, -0.8, -0.7, -0.6][1:q]
    a1 = [0.5, -0.4, 0.7, 0.3][1:q]
    n = G * m
    gi = repeat(1:G, inner = m)
    U = hcat(ones(n), randn(rng, n, q - 1))
    y = 0.2 .+ 0.5 .* U[:, 2] .- 0.3 .* U[:, 3] .+ 0.4 .* randn(rng, n)
    for g in 1:G
        D = Diagonal(exp.(a0 .+ a1 .* w[g]))
        b = cholesky(Symmetric(D * Rm * D)).L * randn(rng, q)
        rows = ((g-1)*m+1):(g*m)
        y[rows] .+= U[rows, :] * b
    end
    names = (:x, :z, :u)[1:q-1]
    data = (; y, x = U[:, 2], z = U[:, 3], (q == 4 ? (; u = U[:, 4]) : (;))...,
            w = w[gi], id = ["g$(g)" for g in gi])
    return (; data, U, gi, w, G, q, Rm, a0, a1, names)
end

function _q34_formula(fx; sd_members = nothing)
    q = fx.q
    mean = q == 3 ? @formula(y ~ x + z + (1 + x + z | id)) :
                    @formula(y ~ x + z + (1 + x + z + u | id))
    sds = Any[@formula(sd(id, coef(intercept)) ~ w), @formula(sd(id, coef(x)) ~ w),
              @formula(sd(id, coef(z)) ~ w)]
    q == 4 && push!(sds, @formula(sd(id, coef(u)) ~ w))
    return bf(mean, @formula(sigma ~ 1), sds...)
end

# R from theta, TMB UNSTRUCTURED_CORR_t: unit-diagonal L, free entries row-major.
function _q34_R(theta, q)
    L = Matrix{Float64}(I, q, q); k = 0
    for i in 1:q, j in 1:i-1
        k += 1; L[i, j] = theta[k]
    end
    S = L * L'
    d = 1 ./ sqrt.(diag(S))
    return Symmetric(d .* S .* d')
end

function _q34_oracle(fx, beta, sigma, A, Rm)   # A: q x (1 + w) SD coefficients
    q, G = fx.q, fx.G
    n = size(fx.U, 1)
    ll = 0.0
    for g in 1:G
        rows = findall(==(g), fx.gi)
        Ug = fx.U[rows, :]
        D = Diagonal(exp.(A[:, 1] .+ A[:, 2] .* fx.w[g]))
        V = Ug * (D * Rm * D) * Ug' + sigma^2 * I
        Xg = Ug[:, 1:3]    # mean design (1, x, z)
        ll += Distributions.logpdf(Distributions.MvNormal(Xg * beta, Symmetric(V)), fx.data.y[rows])
    end
    return ll
end

function _q34_parts(fit, fx)
    sdkeys = [p.first for p in fit.blocks if p.first ∉ (:mu, :sigma, :recov)]
    A = reduce(vcat, [coef(fit, k)' for k in sdkeys])
    Rm = _q34_R(coef(fit, :recov), fx.q)
    return A, Rm, coef(fit, :mu), exp(coef(fit, :sigma)[1])
end

