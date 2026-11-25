# (b),(c) Julia: default fit, restart from R's estimate, and multistart. Run from the DRModels worktree:
#   julia --project=test <this file>
using DRModels, Random, Printf, LinearAlgebra, DelimitedFiles
const D = joinpath(@__DIR__, "..", "wave2-joint-sigma")
const O = @__DIR__
include(joinpath(D, "fixture.jl"))   # not used for data; data read from csv below
M, _ = readdlm(joinpath(D, "data_gamma_crossed.csv"), ',', header = true)
data = (; y = Float64.(M[:, 1]), x = Float64.(M[:, 2]), id = String.(M[:, 3]), g = String.(M[:, 4]),
        w = Float64.(M[:, 5]), z = Float64.(M[:, 6]))
f = bf(@formula(y ~ x + (1 | id)), @formula(sigma ~ 1 + (1 | g)), @formula(sd(id) ~ w), @formula(sd(g, sigma) ~ z))
fam = DRModels.Gamma()
thetaof(fit) = vcat((vec(coef(fit, k)) for (k, _) in fit.blocks)...)
function run1(start)
    t0 = time()
    fit = DRModels._drm_joint_sigma_sd_laplace(f, fam; data, start = start, se = true)
    θ = fit.theta; V = fit.vcov
    pd = all(isfinite, V) && isposdef(Symmetric(inv(V)))
    (θ = θ, ll = loglik(fit), conv = fit.converged, pd = pd, t = time() - t0)
end
jθ = readdlm(joinpath(D, "jcoef_gamma_crossed.csv"), ',', header = true)[1][:, 3] .|> Float64
rθ = [0.778333, 0.38593, -0.695849, -1.15969, 0.788855, -1.96286, -1.94431]
rows = []
push!(rows, ("default", run1(nothing)))
push!(rows, ("from_R_est", run1(rθ)))
push!(rows, ("from_J_est", run1(jθ)))
base = [0.8, 0.4, log(0.5), log(0.5), 0.0, log(0.3), 0.0]
rng = MersenneTwister(20261108)
for s in (0.5, 1.0), r in 1:15
    st = base .+ s .* randn(rng, 7)
    push!(rows, ("rand_s$(s)_$r", run1(st)))
end
open(joinpath(O, "julia_multistart.csv"), "w") do io
    println(io, "label,ll,conv,pd,secs,", join(("th$i" for i in 1:7), ","))
    for (l, r) in rows; println(io, l, ",", r.ll, ",", r.conv, ",", r.pd, ",", round(r.t, digits = 1), ",", join(r.θ, ",")); end
end
for (l, r) in rows
    @printf("%-14s ll=%.8f conv=%-5s pd=%-5s %5.1fs  th=%s\n", l, r.ll, r.conv, r.pd, r.t, round.(r.θ, digits = 4))
end
