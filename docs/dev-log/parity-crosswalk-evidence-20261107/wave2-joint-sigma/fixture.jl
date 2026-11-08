# Copy of the fixture in DRModels test/test_joint_sigma_wave2.jl (branch claude/joint-sigma-wave2-20261107).
using Random, Distributions
function _jsw_fixture(fam::Symbol; seed, n_id = 30, n_g = 24, n = 600, same = false,
                      alpha_mu = [log(0.45), 0.5], alpha_sg = [log(0.35), -0.6])
    rng = MersenneTwister(seed)
    n_g = same ? n_id : n_g
    gi = vcat(1:n_id, rand(rng, 1:n_id, n - n_id))
    gs = same ? gi : vcat(1:n_g, rand(rng, 1:n_g, n - n_g))
    w_lvl = sin.((1:n_id) .* 1.7)
    z_lvl = same ? w_lvl : cos.((1:n_g) .* 0.9 .+ 1)
    a = exp.(alpha_mu[1] .+ alpha_mu[2] .* w_lvl) .* randn(rng, n_id)
    b = exp.(alpha_sg[1] .+ alpha_sg[2] .* z_lvl) .* randn(rng, n_g)
    x = randn(rng, n)
    lin = (fam === :gaussian ? 0.2 : 0.8) .+ 0.4 .* x .+ a[gi]
    ls = (fam === :gaussian ? log(0.5) : -0.7) .+ b[gs]
    y = map(1:n) do i
        k = exp(-2ls[i])
        fam === :gaussian ? lin[i] + exp(ls[i]) * randn(rng) :
        fam === :nb2 ? Float64(rand(rng, NegativeBinomial(k, k / (k + exp(lin[i]))))) :
                       rand(rng, Distributions.Gamma(k, exp(lin[i]) / k))
    end
    id = [string("i", lpad(string(g), 2, '0')) for g in gi]
    g = same ? id : [string("g", lpad(string(j), 2, '0')) for j in gs]
    data = (; y, x, id, g, w = w_lvl[gi], z = z_lvl[gs])
    return (; data, gi, gs, w_lvl, z_lvl, same)
end

