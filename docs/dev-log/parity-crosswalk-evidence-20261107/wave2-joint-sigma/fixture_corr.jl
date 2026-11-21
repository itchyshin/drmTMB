# Copy of the fixture in DRModels test/test_joint_sigma_wave2.jl.
using Random, LinearAlgebra
function _jsw_corr_fixture(; seed = 2026110706, G = 40, n = 800, rho = 0.5)
    rng = MersenneTwister(seed)
    gi = vcat(1:G, rand(rng, 1:G, n - G))
    S = [0.6^2 rho*0.6*0.3; rho*0.6*0.3 0.3^2]
    L = cholesky(Symmetric(S)).L
    u = L * randn(rng, 2, G)
    x = randn(rng, n)
    y = 0.2 .+ 0.5 .* x .+ u[1, gi] .+ exp.(-0.7 .+ u[2, gi]) .* randn(rng, n)
    return (; data = (; y, x, id = string.("g", gi)), gi, G)
end

