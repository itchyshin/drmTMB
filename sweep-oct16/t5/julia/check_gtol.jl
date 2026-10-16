# sweep-oct16 / t5 -- is the 1e-8-level gap between DRModels on duplicated rows
# and native integer weights an optimiser stopping effect? Refit at tighter g_tol.
# Usage: julia --project=<DRModels.jl> check_gtol.jl <datadir> <id>...
using DRModels, Printf
datadir = ARGS[1]
for id in ARGS[2:end]
    fam = String(split(id, '_')[1])
    lines = readlines(joinpath(datadir, id * ".csv")); hdr = split(lines[1], ',')
    cols = Dict(h => String[] for h in hdr)
    for l in lines[2:end], (h, v) in zip(hdr, split(l, ',')); push!(cols[h], v); end
    keep = (cols["y"] .!= "NA") .& (cols["x"] .!= "NA")
    y = parse.(Float64, cols["y"][keep]); x = parse.(Float64, cols["x"][keep]); g = cols["g"][keep]
    w = parse.(Int, cols["w_int"][keep]); idx = reduce(vcat, [fill(i, w[i]) for i in eachindex(y)])
    dup = (y = y[idx], x = x[idx], g = g[idx])
    fm = fam == "poisson" ? Poisson() : DRModels.Gamma()
    for gt in (1e-8, 1e-10, 1e-12)
        F = fam == "poisson" ? bf(@formula(y ~ x + (1 | g))) : bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1))
        fit = drm(F, fm; data = dup, marginal = :Laplace, g_tol = gt)
        mu = coef(fit, :mu)
        @printf("%s g_tol=%.0e loglik=%.15f b_mu0=%.15f b_mu1=%.15f log_sd=%.15f%s\n", id, gt, loglik(fit), mu[1], mu[2],
                coef(fit, :resd)[1], fam == "gamma" ? @sprintf(" b_sigma0=%.15f", coef(fit, :sigma)[1]) : "")
    end
end
