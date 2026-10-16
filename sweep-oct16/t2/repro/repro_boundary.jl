# t2 repro: Gaussian y ~ x + (1 | g), sigma ~ z at the sd(g) = 0 boundary, and
# the all-singleton-group cell. DRModels.jl f71b292, Julia 1.12.7.
# Run from this directory: julia --project=<env with DRModels> repro_boundary.jl
using DRModels, DelimitedFiles, LinearAlgebra

function load(path)
    raw, hdr = readdlm(path, ','; header = true)
    (y = Float64.(raw[:, 1]), x = Float64.(raw[:, 2]), z = Float64.(raw[:, 3]),
     g = string.(Int.(raw[:, 4])))
end
f = bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ z))

println("== sd(g) boundary, n = 50, G = 20 (2-3 rows per group) ==")
for file in ["n0050_G20_rep121.csv", "n0050_G20_rep143.csv",
             "n0050_G20_rep175.csv", "n0050_G20_rep253.csv"]
    fit = drm(f, Gaussian(); data = load(file))
    k = last(fit.blocks[findfirst(p -> first(p) === :resd, fit.blocks)])[1]
    ci = confint(fit; method = :wald)
    row = ci[findfirst(r -> r.param === :resd, ci)]
    println(rpad(file, 24), " loglik = ", round(fit.loglik; digits = 6),
            "  is_converged = ", is_converged(fit),
            "  log sd(g) = ", round(fit.theta[k]; digits = 3),
            "  vcov[k,k] = ", fit.vcov[k, k],
            "  stderror = ", stderror(fit)[k],
            "  Wald sd(g) = [", exp(row.lower), ", ", exp(row.upper), "]")
end

println("\n== all-singleton groups, n = 50, G = 50 ==")
for file in ["n0050_G50_rep068.csv", "n0050_G50_rep072.csv", "n0050_G50_rep077.csv"]
    try
        fit = drm(f, Gaussian(); data = load(file))
        s = fit.scales[:sigma]
        println(rpad(file, 24), " loglik = ", round(fit.loglik; digits = 4),
                "  is_converged = ", is_converged(fit),
                "  coef(sigma) = ", round.(coef(fit, :sigma); digits = 3),
                "  SE(sigma) = ", round.(stderror(fit)[3:4]; sigdigits = 3),
                "  fitted sigma range = ", extrema(s),
                "  sd(g) = ", round(exp(fit.theta[5]); digits = 4))
    catch e
        println(rpad(file, 24), " ERROR: ", sprint(showerror, e))
    end
end
