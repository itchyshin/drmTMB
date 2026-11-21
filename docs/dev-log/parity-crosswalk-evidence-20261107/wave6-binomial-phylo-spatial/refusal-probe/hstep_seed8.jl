using DRModels, DelimitedFiles, LinearAlgebra
here = "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/drmr/docs/dev-log/parity-crosswalk-evidence-20261107/wave6-binomial-phylo-spatial"
cc = readdlm(joinpath(here, "coords.csv"), ',', skipstart = 1)
coords = Dict(String(cc[i, 1]) => [Float64(cc[i, 2]), Float64(cc[i, 3])] for i in 1:size(cc, 1))
M = readdlm(joinpath(here, "data", "spatial_8.csv"), ',', skipstart = 1)
d = (; id = String.(M[:, 1]), x = Float64.(M[:, 2]), z0 = Float64.(M[:, 3]), z1 = Float64.(M[:, 4]), y = Float64.(M[:, 5]))
f = bf(@formula(y ~ x + spatial(1 + x | id)), @formula(sd(id, spatial, coef(intercept)) ~ z0), @formula(sd(id, spatial, coef(x)) ~ z1))
fit = drm(f, Binomial(); data = d, coords, se = false)
th = fit.theta
println("default step: ", DRModels._fd_hessian_step(length(d.y)))
for h in (1e-2, 3e-3, 1e-3, 4.8e-4, 3e-4)
    H = DRModels._finite_hessian(fit.nll, th; h = h)
    println(h, " se=", round.(sqrt.(abs.(diag(inv(Symmetric(H))))), digits = 4))
end
