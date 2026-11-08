# Gaussian ordinary correlated block of 3 or 4 coefficients with one SD formula per coefficient.
# Same generator as ../multiseed2/fixtures_q34.jl (Test dependency and oracle removed).
using DRModels, Random, LinearAlgebra
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
    data = (; y, x = U[:, 2], z = U[:, 3], (q == 4 ? (; u = U[:, 4]) : (;))...,
            w = w[gi], id = ["g$(g)" for g in gi])
    return (; data, q)
end
function _q34_formula(q)
    mean = q == 3 ? @formula(y ~ x + z + (1 + x + z | id)) : @formula(y ~ x + z + (1 + x + z + u | id))
    sds = Any[@formula(sd(id, coef(intercept)) ~ w), @formula(sd(id, coef(x)) ~ w), @formula(sd(id, coef(z)) ~ w)]
    q == 4 && push!(sds, @formula(sd(id, coef(u)) ~ w))
    return bf(mean, @formula(sigma ~ 1), sds...)
end
