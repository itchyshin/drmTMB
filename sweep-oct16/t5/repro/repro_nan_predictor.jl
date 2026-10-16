# Repro: a NaN-coded predictor with (1 | g). Poisson returns a DrmFit of
# starting values (loglik -Inf, slope 0, finite SEs) with no error; Gaussian
# and Gamma throw unnamed errors. DRModels.jl f71b2923. Run from drmTMB root:
#   julia --project=/path/to/DRModels.jl sweep-oct16/t5/repro/repro_nan_predictor.jl
include(joinpath(@__DIR__, "common.jl"))
for fam in ("poisson", "gaussian", "gamma")
    d = t5_read("$(fam)_y00_x05")              # 10 NA in x, none in y
    y = Float64.(d.y); x = Float64[ismissing(v) ? NaN : v for v in d.x]; g = d.g
    try_fit("$fam  x with 10 NaN", () -> drm(F(fam), fam_of(fam); data = (; y, x, g)))
    if fam == "poisson"
        fit = drm(F(fam), fam_of(fam); data = (; y, x, g))
        println("poisson  coef = ", coef(fit), "   stderror = ", round.(stderror(fit), digits = 4),
                "   log(mean(y)) = ", log(sum(y) / length(y)))
    end
end
