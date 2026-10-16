# F1-julia-aliased-sigma: data-free variant (exact duplicate column), no CSV needed.
# Run: JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#        --project=/home/user/DRModels.jl repro_selfcontained.jl > repro_selfcontained.out 2>&1
using DRModels, Random, LinearAlgebra
println("DRModels ", pkgversion(DRModels), " ", strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)), "; Julia ", VERSION)
rng = MersenneTwister(20261017600)
n = 100
x = randn(rng, n)
y = 1 .+ 0.5 .* x .+ exp.(-0.4 .+ 0.3 .* x) .* randn(rng, n)
xdup = copy(x)                                   # bitwise duplicate: rank([1 x xdup]) == 2
fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + xdup)), Gaussian(); data = (; y, x, xdup))
red = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = (; y, x))
println("is_converged(fit) = ", is_converged(fit), "   logLik full / reduced = ", loglik(fit), " / ", loglik(red))
show(stdout, MIME("text/plain"), coeftable(fit)); println()
show(stdout, MIME("text/plain"), coeftable(red)); println()
c = check_drm(fit)
println("check_drm: ok = ", c.ok, ", vcov_posdef = ", c.vcov_posdef, ", min_eigval = ", c.min_eigval)
