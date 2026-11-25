# Stress case 6a diagnostic: sigma ~ 1 + (1|site), 200x200, n=2400, seed 20261110.
using DRModels, Random, LinearAlgebra, Printf
const AS = "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-sigma"
include(joinpath(AS, "fix_joint.jl"))
fx = _gjs_fixture(; seed = 20261110, n_id = 200, n_site = 200, n_each = 12, slope = false)
d = fx.data
n = length(d.y)
X = hcat(ones(n), d.x)

# Independent negative joint (raw scale) with gradient and Hessian, built from the oracle code.
function parts(θ)
    sd_a = exp.(θ[4] .+ θ[5] .* fx.w_id); sd_b = exp.(θ[6] .+ θ[7] .* fx.v_site)
    return (y = d.y, mu0 = X * θ[1:2], s0 = θ[3], sd_a = sd_a, sd_b = sd_b)
end
function lap(θ; u0 = nothing, verbose = false)
    p = parts(θ)
    na, nb = 200, 200; m = na + nb; gi, gs = fx.gi, fx.gs
    function fgh(u; deriv = true)
        a = u[1:na]; b = u[na+1:m]
        r = p.y .- p.mu0 .- a[gi]; eta = p.s0 .+ b[gs]; ie = exp.(-2 .* eta)
        F = sum(eta .+ 0.5 .* r .^ 2 .* ie) + sum(0.5 .* a .^ 2 ./ p.sd_a .^ 2 .+ log.(p.sd_a)) +
            sum(0.5 .* b .^ 2 ./ p.sd_b .^ 2 .+ log.(p.sd_b)) + 0.5 * log(2π) * (n + m)
        deriv || return F, nothing, nothing
        g = zeros(m); H = zeros(m, m)
        for i in 1:n
            g[gi[i]] -= r[i] * ie[i]; g[na+gs[i]] += 1 - r[i]^2 * ie[i]
            H[gi[i], gi[i]] += ie[i]; H[na+gs[i], na+gs[i]] += 2 * r[i]^2 * ie[i]
            x = 2 * r[i] * ie[i]; H[gi[i], na+gs[i]] += x; H[na+gs[i], gi[i]] += x
        end
        g[1:na] .+= a ./ p.sd_a .^ 2; g[na+1:m] .+= b ./ p.sd_b .^ 2
        for k in 1:na; H[k, k] += 1 / p.sd_a[k]^2; end
        for j in 1:nb; H[na+j, na+j] += 1 / p.sd_b[j]^2; end
        return F, g, H
    end
    u = u0 === nothing ? zeros(m) : copy(u0)
    Opt = DRModels.Optim
    fo(u) = fgh(u; deriv = false)[1]
    g!(G, u) = (G .= fgh(u)[2])
    h!(Hm, u) = (Hm .= fgh(u)[3])
    res = Opt.optimize(fo, g!, h!, u, Opt.NewtonTrustRegion(),
                       Opt.Options(g_tol = 1e-10, iterations = 2000))
    u = Opt.minimizer(res)
    verbose && println("  inner iters done")
    F, g, H = fgh(u)
    ev = eigvals(Symmetric(H))
    C = cholesky(Symmetric(H); check = false)
    ll = issuccess(C) ? -F + 0.5 * m * log(2π) - 0.5 * logdet(C) : NaN
    return (ll = ll, it = 0, F = F, maxg = maximum(abs, g), mineig = ev[1], maxeig = ev[end], u = u,
            ldet = issuccess(C) ? logdet(C) : NaN)
end

θJ = [0.2738656512543831, 0.5008374254739447, -0.7035612147782503, -0.5033351874652356,
      0.42031546043062795, -1.1041288073041713, 0.41887983471924795]
θR = [0.2768119, 0.4979230, -0.7273682, -0.5196211, 0.3548358, -1.1293745, 0.4567086]
# DRModels engine inner mode (standardised v) at θ, from a given start
function engine(θ, v0)
    p = parts(θ)
    ymu = p.y .- p.mu0; eta0 = fill(p.s0, n)
    c = p.sd_a[fx.gi]; dd = p.sd_b[fx.gs]
    joint = (vv, deriv) -> DRModels._gsl_joint(ymu, eta0, fx.gi, c, fx.gs, dd, nothing,
                                               view(vv, 1:200), view(vv, 201:400), 200, 200; deriv = deriv)
    v, ok = DRModels._gsl_mode(joint, v0)
    F, g, H = joint(v, true)
    C = cholesky(Symmetric(H); check = false)
    ll = issuccess(C) ? -(F + 0.5 * logdet(C) + 0.5 * n * log(2π)) : NaN
    u = vcat(p.sd_a .* v[1:200], p.sd_b .* v[201:400])
    return (; ll, ok, u, maxg = maximum(abs, g))
end
std_of(θ, u) = (p = parts(θ); vcat(u[1:200] ./ p.sd_a, u[201:400] ./ p.sd_b))
# F of the two modes at θJ
p = parts(θJ)
for (nm, u0) in (("zero", nothing), ("alt(R-start)", lap(θR).u))
    o = lap(θJ; u0 = u0)
    @printf("θJ mode %-12s F=%.4f  halfldet=%.4f  ll=%.6f\n", nm, o.F, 0.5o.ldet, o.ll)
end
fm = bf(@formula(y ~ x + (1 | id)), @formula(sigma ~ 1 + (1 | site)), @formula(sd(id) ~ w), @formula(sd(site, sigma) ~ v))
t0 = time(); fit = drm(fm, Gaussian(); data = d); t1 = time() - t0
θh = reduce(vcat, [vec(coef(fit, first(b))) for b in fit.blocks])
@printf("refit (global-mode rule): conv=%s ll=%.6f time=%.1fs\n", fit.converged, loglik(fit), t1)
println("θ̂ = ", θh); println("SE = ", stderror(fit))
o = lap(θh); @printf("oracle at θ̂ from zero: ll=%.6f g=%.1e eig=%.3e\n", o.ll, o.maxg, o.mineig)
o2 = lap(θh; u0 = lap(θR).u); @printf("oracle at θ̂ from alt start: ll=%.6f\n", o2.ll)
open(joinpath(@__DIR__, "theta_global.txt"), "w") do io; println(io, join(θh, ",")); end
