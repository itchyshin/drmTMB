# sweep-oct16 / t5 -- supplementary probes run one cell per process (under an
# external `timeout`), because some of these fits are pathological.
#
# Modes (all on a t5 dataset id):
#   cc_union        complete cases; x stored as Vector{Union{Missing,Float64}}
#                   holding no missing value (what `df[completecases(df), :]`
#                   leaves behind in DataFrames).
#   cc_concrete     the same rows with x::Vector{Float64} (reference).
#   listwise_union  all columns Union-typed (as after `allowmissing!`) and no
#                   missing anywhere, passed through drm_listwise(): it drops
#                   nothing and returns the columns unchanged.
#   g_missing       x, y complete; g missing on rows 1, 9, 17, ..., 73 (10 rows).
#   g_dropped       the same 10 rows removed (reference for g_missing).
# Prints one CSV line: id,mode,status,errtype,errmsg,secs,loglik,nobs,ncoef_mu,
#                      b_mu1,log_sd_g,converged,n_groups_seen
# Usage: julia --project=<DRModels.jl> probe_union.jl <datadir> <id> <mode>
using DRModels, Printf

datadir, id, mode = ARGS
fam = String(split(id, '_')[1])
lines = readlines(joinpath(datadir, id * ".csv"))
hdr = split(lines[1], ',')
cols = Dict(h => String[] for h in hdr)
for l in lines[2:end], (h, v) in zip(hdr, split(l, ','))
    push!(cols[h], v)
end
num(v) = v == "NA" ? missing : parse(Float64, v)
y = num.(cols["y"]); x = num.(cols["x"]); g = String.(cols["g"])
keep = .!ismissing.(y) .& .!ismissing.(x)
yc = Float64.(y[keep]); xc = Float64.(x[keep]); gc = g[keep]
U(v) = Vector{Union{Missing,eltype(v)}}(v)

fm = fam == "gaussian" ? Gaussian() : fam == "poisson" ? Poisson() : DRModels.Gamma()
F() = fam == "poisson" ? bf(@formula(y ~ x + (1 | g))) :
                         bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1))
lap = fam == "gaussian" ? (;) : (; marginal = :Laplace)
gm_rows = 1:8:80

data, nseen = if mode == "cc_union"
    (y = yc, x = U(xc), g = gc), length(unique(gc))
elseif mode == "cc_concrete"
    (y = yc, x = xc, g = gc), length(unique(gc))
elseif mode == "listwise_union"
    any(.!keep) && error("listwise_union needs a dataset without missing values")
    f0 = F()
    drm_listwise(f0, (y = U(yc), x = U(xc), g = U(gc))), length(unique(gc))
elseif mode == "g_missing"
    gg = Vector{Union{Missing,String}}(gc); gg[gm_rows] .= missing
    (y = yc, x = xc, g = gg), length(unique(gg))
elseif mode == "g_dropped"
    k = setdiff(eachindex(yc), gm_rows)
    (y = yc[k], x = xc[k], g = gc[k]), length(unique(gc[k]))
else
    error("unknown mode $mode")
end

oneline(s) = replace(first(split(s, '\n')), ',' => ';', '"' => "'")
t0 = time()
out = try
    fit = drm(F(), fm; data = data, lap...)
    mu = coef(fit, :mu)
    ["ok", "", "", @sprintf("%.17g", loglik(fit)), string(nobs(fit)), string(length(mu)),
     @sprintf("%.17g", length(mu) >= 2 ? mu[2] : NaN), @sprintf("%.17g", coef(fit, :resd)[1]),
     string(is_converged(fit))]
catch e
    ["error", string(typeof(e)), oneline(sprint(showerror, e)), "", "", "", "", "", ""]
end
println(join([id, mode, out[1:3]..., @sprintf("%.1f", time() - t0), out[4:end]..., string(nseen)], ','))
