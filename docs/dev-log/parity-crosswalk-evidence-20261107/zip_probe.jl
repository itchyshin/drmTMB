using DRModels
rows = [split(l, ",") for l in readlines(joinpath(@__DIR__, "zip_slope.csv"))[2:end]]
data = (; y = [parse(Float64, r[1]) for r in rows], x = [parse(Float64, r[2]) for r in rows], g = [parse(Int, r[3]) for r in rows])
function tryfit(label, f)
    try
        fit = drm(f, Poisson(); data, nAGQ = 9)
        println(label, " converged=", fit.converged, " blocks=", first.(fit.blocks))
        println("  mu=", coef(fit, :mu), " zi=", coef(fit, :zi))
        for b in first.(fit.blocks); b == :sd && println("  sd=", coef(fit, :sd)); end
        println("  logLik=", loglikelihood(fit))
    catch e
        println(label, " REFUSED/ERROR: ", sprint(showerror, e)[1:min(end, 400)])
    end
end
tryfit("plain", bf(@formula(y ~ x + (0 + x | g)), @formula(zi ~ 1)))
tryfit("constant-sd", bf(@formula(y ~ x + (0 + x | g)), @formula(zi ~ 1), @formula(sd(g, coef(x)) ~ 1)))
