# (d) Oracle Laplace log-likelihood along the straight segment between the two optima
# (t=0 R's, t=1 Julia's, plus overshoot), inner mode from zero AND from the neighbour's mode.
using Printf
include(joinpath(@__DIR__, "oracle.jl"))
D = joinpath(@__DIR__, "..", "wave2-joint-sigma")
d = load_gc(joinpath(D, "data_gamma_crossed.csv"))
jθ = DelimitedFiles.readdlm(joinpath(D, "jcoef_gamma_crossed.csv"), ',', header = true)[1][:, 3] .|> Float64
rθ = [0.778333, 0.38593, -0.695849, -1.15969, 0.788855, -1.96286, -1.94431]
for t in -0.25:0.125:1.25
    θ = rθ .+ t .* (jθ .- rθ)
    ms = inner_modes(d, θ; nstart = 3)
    @printf("t=%6.3f  ll=%.6f   (inner modes found: %d)\n", t, ms[1][1], length(ms))
end
