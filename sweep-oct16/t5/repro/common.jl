# Shared reader for the t5 repro scripts: reads a t5 CSV ("NA" = missing) into
# concrete columns. Run from the drmTMB repository root.
using DRModels, Printf
function t5_read(id; dir = "sweep-oct16/t5/data")
    lines = readlines(joinpath(dir, id * ".csv")); hdr = split(lines[1], ',')
    cols = Dict(h => String[] for h in hdr)
    for l in lines[2:end], (h, v) in zip(hdr, split(l, ',')); push!(cols[h], v); end
    num(v) = v == "NA" ? missing : parse(Float64, v)
    (y = num.(cols["y"]), x = num.(cols["x"]), g = String.(cols["g"]))
end
fam_of(f) = f == "gaussian" ? Gaussian() : f == "poisson" ? Poisson() : DRModels.Gamma()
# A fresh bf() for every fit: DrmFormula caches its schema (#1086).
F(f) = f == "poisson" ? bf(@formula(y ~ x + (1 | g))) : bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1))
show_fit(tag, fit) = @printf("%-44s loglik=%14.6f  nobs=%d  n_mu_coef=%d  converged=%s\n",
                             tag, loglik(fit), nobs(fit), length(coef(fit, :mu)), is_converged(fit))
function try_fit(tag, thunk)
    try show_fit(tag, thunk()) catch e
        @printf("%-44s ERROR %s: %s\n", tag, typeof(e), first(split(sprint(showerror, e), '\n')))
    end
end
