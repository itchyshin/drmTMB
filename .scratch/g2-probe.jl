# G2: does DRM.jl at pin 430ef64cc actually ROUTE the "biv_student" tag through
# drm_bridge with the mu1/mu2/sigma1/sigma2/nu/rho12 vocabulary?
using Pkg
Pkg.activate("/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc"; io = devnull)
using DRM
using Random, Statistics

Random.seed!(6401)
n = 120
x = collect(range(-1, 1; length = n))
z1 = randn(n)
rho = 0.35
z2 = rho .* z1 .+ sqrt(1 - rho^2) .* randn(n)
nu = 7.0
w = sqrt.(nu ./ (nu .* rand(n) .+ 1))   # arbitrary heavy-tail-ish scale, shape only
y1 = 0.2 .+ 0.45 .* x .+ 0.55 .* z1 .* w
y2 = -0.3 .- 0.25 .* x .+ 0.85 .* z2 .* w
dat = (x = x, y1 = y1, y2 = y2)

println("=== _bridge_family(\"biv_student\") ===")
println(DRM._bridge_family("biv_student"))

println("\n=== drm_bridge(family = \"biv_student\") ===")
out = DRM.drm_bridge(
    formula = Dict("mu1" => "y1 ~ x", "mu2" => "y2 ~ x",
                   "sigma1" => "sigma1 ~ 1", "sigma2" => "sigma2 ~ 1",
                   "nu" => "nu ~ 1", "rho12" => "rho12 ~ 1"),
    family = "biv_student", data = dat)
println("KEYS: ", sort(collect(keys(out))))
println("ROUTED_OK")
for k in ("coefnames", "coefficients", "loglik", "logLik", "dpars", "scales",
          "residual_correlation", "npar", "converged")
    if haskey(out, k)
        v = out[k]
        println("  ", k, " => ", v isa AbstractDict ? sort(collect(keys(v))) : v)
    end
end
