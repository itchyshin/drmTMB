# sweep-oct16 / t5 -- direct DRModels.jl leg (no R in the loop).
# Reads the same CSVs as the R legs and records, per dataset:
#   JD_raw        drm() on the raw columns (y, x as Union{Missing,Float64})
#   JD_nan        drm() with missing cells coded as NaN (plain Float64)
#   JD_listwise   drm() on drm_listwise(formula, raw)
#   JD_cc         drm() on concrete Float64 complete cases (default marginal)
#   JD_cc_lap     as JD_cc with marginal = :Laplace (Poisson / Gamma only)
#   JD_cc_union   complete cases, x stored as Union{Missing,Float64} with no missing
#   JD_dup        complete cases duplicated by w_int (Laplace for Poisson / Gamma)
#   JD_weights    drm(...; weights = w_int) on complete cases
# Usage: julia --project=<DRModels.jl> run_direct.jl <datadir> <outfile>
using DRModels
using Logging, Test, Printf

const datadir, outfile = ARGS[1], ARGS[2]

function read_cell(path)
    lines = readlines(path)
    hdr = split(lines[1], ',')
    cols = Dict(h => String[] for h in hdr)
    for l in lines[2:end]
        for (h, v) in zip(hdr, split(l, ','))
            push!(cols[h], v)
        end
    end
    num(v) = v == "NA" ? missing : parse(Float64, v)
    (y = Vector{Union{Missing,Float64}}(num.(cols["y"])),
     x = Vector{Union{Missing,Float64}}(num.(cols["x"])),
     g = String.(cols["g"]),
     w_int = parse.(Int, cols["w_int"]))
end

famof(f) = f == "gaussian" ? Gaussian() : f == "poisson" ? Poisson() : DRModels.Gamma()
formula_for(f) = f == "poisson" ? bf(@formula(y ~ x + (1 | g))) :
                                   bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1))

oneline(s) = replace(first(split(s, '\n')), ',' => ';', '"' => "'")

function record(id, fam, cell, thunk)
    logger = Test.TestLogger(min_level = Logging.Warn)
    t0 = time()
    res = Dict{String,Any}("id" => id, "family" => fam, "cell" => cell)
    fit = nothing
    try
        fit = with_logger(thunk, logger)
        res["status"] = "ok"
    catch e
        res["status"] = "error"
        res["errtype"] = string(typeof(e))
        res["errmsg"] = oneline(sprint(showerror, e))
    end
    res["secs"] = time() - t0
    res["nwarn"] = length(logger.logs)
    res["warn1"] = isempty(logger.logs) ? "" : oneline(string(logger.logs[1].message))
    if fit !== nothing
        mu = coef(fit, :mu)
        res["loglik"] = loglik(fit)
        res["nobs"] = nobs(fit)
        res["ncoef_mu"] = length(mu)
        res["b_mu0"] = mu[1]
        res["b_mu1"] = length(mu) >= 2 ? mu[2] : NaN
        res["b_sigma0"] = fam == "poisson" ? NaN : coef(fit, :sigma)[1]
        res["log_sd_g"] = coef(fit, :resd)[1]
        res["converged"] = is_converged(fit)
        res["marginal"] = string(hasproperty(fit, :marginal) ? fit.marginal : "")
    end
    res
end

const COLS = ["id", "family", "cell", "status", "errtype", "errmsg", "secs", "nwarn", "warn1",
              "loglik", "nobs", "ncoef_mu", "b_mu0", "b_mu1", "b_sigma0", "log_sd_g",
              "converged", "marginal"]

fmt(v) = v === nothing ? "" : v isa AbstractFloat ? @sprintf("%.17g", v) : string(v)

ids = [split(l, ',')[1] for l in readlines(joinpath(datadir, "manifest.csv"))[2:end]]
open(outfile, "w") do io
    println(io, join(COLS, ','))
    for id in ids
        fam = String(split(id, '_')[1])
        d = read_cell(joinpath(datadir, id * ".csv"))
        F = () -> formula_for(fam)           # fresh bundle per fit (schema cache)
        fm = famof(fam)
        lapkw = fam == "gaussian" ? (;) : (; marginal = :Laplace)
        keep = .!ismissing.(d.y) .& .!ismissing.(d.x)
        cc = (y = Float64.(d.y[keep]), x = Float64.(d.x[keep]), g = d.g[keep], w_int = d.w_int[keep])
        nanv = v -> Float64[ismissing(a) ? NaN : a for a in v]
        dnan = (y = nanv(d.y), x = nanv(d.x), g = d.g, w_int = d.w_int)
        ccu = (y = cc.y, x = Vector{Union{Missing,Float64}}(cc.x), g = cc.g)
        idx = reduce(vcat, [fill(i, cc.w_int[i]) for i in eachindex(cc.y)])
        dup = (y = cc.y[idx], x = cc.x[idx], g = cc.g[idx])
        cells = [
            "JD_raw"      => () -> drm(F(), fm; data = (y = d.y, x = d.x, g = d.g)),
            "JD_nan"      => () -> drm(F(), fm; data = (y = dnan.y, x = dnan.x, g = dnan.g)),
            "JD_listwise" => () -> (f = F(); drm(f, fm; data = drm_listwise(f, (y = d.y, x = d.x, g = d.g)))),
            "JD_cc"       => () -> drm(F(), fm; data = (y = cc.y, x = cc.x, g = cc.g)),
            "JD_cc_union" => () -> drm(F(), fm; data = ccu),
            "JD_dup"      => () -> drm(F(), fm; data = dup, lapkw...),
            "JD_weights"  => () -> drm(F(), fm; data = (y = cc.y, x = cc.x, g = cc.g), weights = Float64.(cc.w_int)),
        ]
        fam == "gaussian" || push!(cells, "JD_cc_lap" => () -> drm(F(), fm; data = (y = cc.y, x = cc.x, g = cc.g), marginal = :Laplace))
        for (cell, th) in cells
            r = record(id, fam, cell, th)
            println(io, join([fmt(get(r, c, nothing)) for c in COLS], ','))
            flush(io)
            @printf("[%s] %-11s %-5s %s\n", id, cell, r["status"], get(r, "errtype", ""))
        end
    end
end
println("wrote ", outfile)
