# (a) evaluate Julia's and R's estimates under the independent oracle.
using DRModels, Printf
include(joinpath(@__DIR__, "oracle.jl"))
D = joinpath(@__DIR__, "..", "wave2-joint-sigma")
d = load_gc(joinpath(D, "data_gamma_crossed.csv"))
jθ = DelimitedFiles.readdlm(joinpath(D, "jcoef_gamma_crossed.csv"), ',', header = true)[1][:, 3] .|> Float64
rθ = [0.778333, 0.38593, -0.695849, -1.15969, 0.788855, -1.96286, -1.94431]  # from gamma_crossed_probe.log (6 sig. digits)
for (nm, θ) in (("Julia", jθ), ("R(6sf)", rθ))
    ms = inner_modes(d, θ; nstart = 20)
    @printf("%s theta=%s\n", nm, round.(θ, digits = 5))
    for (ll, u) in ms; @printf("   inner mode: Laplace ll = %.8f  |a|max=%.3f |b|max=%.3f\n", ll, maximum(abs, u[1:d.Ga]), maximum(abs, u[d.Ga+1:end])); end
end
