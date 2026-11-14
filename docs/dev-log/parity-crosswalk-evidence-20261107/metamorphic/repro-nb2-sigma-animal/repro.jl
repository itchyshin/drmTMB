# Reproducer: NB2 structured sigma random effect (Julia-only "shape B"), animal kernel.
#   y ~ x + v,  sigma ~ 1 + animal(1 | id),  sd(id, animal, sigma) ~ w0      (NegBinomial2, log link)
# data.csv: 240 rows, 24 animals; A.csv: the 24 x 24 relationship matrix in first-seen level order.
# Run from a DRModels.jl checkout at origin/claude/binomial-phylo-spatial-q2-20261108 (or the branch
# claude/metamorphic-20261108):   julia --project=test repro.jl
using DRModels, DelimitedFiles
raw = readdlm(joinpath(@__DIR__, "data.csv"), ','; header = true)[1]
data = (; y = Float64.(raw[:, 1]), x = Float64.(raw[:, 2]), v = Float64.(raw[:, 3]),
        w0 = Float64.(raw[:, 4]), id = string.(raw[:, 5]))
A = readdlm(joinpath(@__DIR__, "A.csv"), ',')
f = bf(@formula(y ~ x + v), @formula(sigma ~ 1 + animal(1 | id)), @formula(sd(id, animal, sigma) ~ w0))
fit(d) = drm(f, NegBinomial2(); data = d, A, se = false)

f1 = fit(data)
println("as generated        : converged = ", f1.converged, "  logLik = ", loglikelihood(f1))
# The same model after rescaling the SD-formula covariate (w0 -> 2.5 w0 is a pure reparametrisation:
# the logLik surface is identical, only a_w -> a_w / 2.5). Expected: a fit (converged or not); observed: an exception.
try
    f2 = fit(merge(data, (; w0 = 2.5 .* data.w0)))
    println("w0 rescaled by 2.5  : converged = ", f2.converged, "  logLik = ", loglikelihood(f2))
catch e
    println("w0 rescaled by 2.5  : ", sprint(showerror, e))
end
