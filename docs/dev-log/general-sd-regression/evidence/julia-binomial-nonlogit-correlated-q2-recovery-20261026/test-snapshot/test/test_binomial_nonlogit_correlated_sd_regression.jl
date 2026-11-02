# Characterize the ordinary correlated q=2 Binomial SD route for probit and
# cloglog links. This is recovery evidence for this exact family/block slice,
# not interval-coverage validation.
using DRModels, Test, Random
import Distributions

@testset "Binomial non-logit correlated-block SD regression" begin
    for (link, seed) in ((:probit, 202610251), (:cloglog, 202610252))
        rng = MersenneTwister(seed)
        G, m = 160, 32
        g = repeat(1:G, inner = m)
        z0_group = repeat([-1.0, 1.0], inner = G ÷ 2)
        z1_group = repeat([0.0, 1.0, 1.0, 0.0], inner = G ÷ 4)
        z0, z1 = z0_group[g], z1_group[g]
        x = repeat(range(-1.2, 1.2; length = m), outer = G)
        alpha0 = [-0.65, 0.55]
        alpha1 = [-0.75, 0.6]
        rho = 0.4
        tau0 = exp.(alpha0[1] .+ alpha0[2] .* z0_group)
        tau1 = exp.(alpha1[1] .+ alpha1[2] .* z1_group)
        u = randn(rng, 2, G)
        b0 = tau0 .* u[1, :]
        b1 = tau1 .* (rho .* u[1, :] .+ sqrt(1 - rho^2) .* u[2, :])
        eta = -0.1 .+ 0.25 .* x .+ b0[g] .+ x .* b1[g]
        probability = link === :probit ?
            Distributions.cdf.(Distributions.Normal(), eta) : -expm1.(-exp.(eta))
        y = Float64.(rand.(Ref(rng), Distributions.Bernoulli.(probability)))
        data = (; y, x, z0, z1, g)
        f = bf(
            @formula(y ~ x + (1 + x | g)),
            @formula(sd(g, coef(intercept)) ~ z0),
            @formula(sd(g, coef(x)) ~ z1),
        )

        fit = drm(f, Binomial(link = link); data, nq = 9)
        @test fit.converged
        @test fit.family.link === link
        target_blocks = DRModels._sd_target_blocks(DRModels._sd_target_parts(f))
        sd0, sd1 = coef(fit, target_blocks[1]), coef(fit, target_blocks[2])
        @test length(sd0) == 2
        @test length(sd1) == 2
        @test sd0[2] > 0
        @test sd1[2] > 0
        @test abs(sd0[2] - alpha0[2]) < 0.35
        @test abs(sd1[2] - alpha1[2]) < 0.35
        @test abs(tanh(fit.theta[end]) - rho) < 0.25
        @test fit.scales[target_blocks[1]][1:m:end] ≈ exp.(sd0[1] .+ sd0[2] .* z0_group)
        @test fit.scales[target_blocks[2]][1:m:end] ≈ exp.(sd1[1] .+ sd1[2] .* z1_group)
        eta_hat = predict(fit, data; type = :link)
        @test predict(fit, data) ≈ DRModels._binomial_mean.(Ref(fit.family), eta_hat)
        simulated = simulate(fit; rng = MersenneTwister(seed + 1))
        @test length(simulated) == length(y)
        @test all(value -> value == 0.0 || value == 1.0, simulated)
    end
end
