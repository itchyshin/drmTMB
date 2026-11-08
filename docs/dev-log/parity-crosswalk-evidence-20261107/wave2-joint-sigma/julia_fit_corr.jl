using DRModels, Random, LinearAlgebra, Printf
const O = @__DIR__
include(joinpath(O, "fixture_corr.jl"))
fx = _jsw_corr_fixture(); d = fx.data
open(joinpath(O, "data_gaussian_corr_same.csv"), "w") do io
    println(io, "y,x,id"); for i in eachindex(d.y); println(io, "$(d.y[i]),$(d.x[i]),$(d.id[i])"); end
end
fit = drm(bf(@formula(y ~ x + (1 | p | id)), @formula(sigma ~ 1 + (1 | p | id))), Gaussian(); data = d)
se = stderror(fit)
let pos = 0; open(joinpath(O, "jcoef_gaussian_corr_same.csv"), "w") do io
    println(io, "block,k,est,se")
    for (k, _) in fit.blocks
        est = vec(coef(fit, k)); for i in eachindex(est); pos += 1; println(io, "$k,$i,$(est[i]),$(se[pos])"); end
    end
end; end
write(joinpath(O, "jll_gaussian_corr_same.txt"), repr(loglik(fit)))
@printf("gaussian_corr_same conv=%s ll=%.10f rho=%.6f\n", fit.converged, loglik(fit), tanh(coef(fit, :cor)[1]))
