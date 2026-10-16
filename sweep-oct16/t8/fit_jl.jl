#!/usr/bin/env julia
# sweep-oct16/t8: fit DRModels.jl on a prepared case.
# Usage: julia --project=/tmp/DRModels.jl fit_jl.jl <case_id>

using DRModels
using CSV
using JSON
using Statistics

id = ARGS[1]
root = get(ENV, "T8_ROOT", "/workspace/sweep-oct16/t8")
spec = JSON.parsefile(joinpath(root, "fits", id, "spec.json"))
csv_path = spec["csv"]
df = CSV.File(csv_path)

fam_name = spec["family_jl"]
fam = if fam_name == "Gaussian"
    Gaussian()
elseif fam_name == "NegBinomial2"
    NegBinomial2()
elseif fam_name == "Beta"
    Beta()
elseif fam_name == "BetaBinomial"
    BetaBinomial()
elseif fam_name == "Binomial"
    Binomial()
elseif fam_name == "Poisson"
    Poisson()
elseif fam_name == "Gamma"
    Gamma()
else
    error("unknown family_jl $fam_name")
end

function parse_formula(s::AbstractString)
    expr = Meta.parse("@formula(" * s * ")")
    return eval(expr)
end

mu_s = spec["mu_jl"]
sigma_s = get(spec, "sigma_jl", nothing)
has_re = spec["has_re"] === true

is_blank(x) = x === nothing || x == "null" || x == "" ||
    (x isa AbstractDict && isempty(x))

if is_blank(sigma_s)
    form = bf(parse_formula(String(mu_s)))
else
    form = bf(parse_formula(String(mu_s)), parse_formula(String(sigma_s)))
end

function dump_result(path, d)
    open(path, "w") do io
        JSON.print(io, d, 2)
    end
end

t0 = time()
result = Dict{String,Any}(
    "engine" => "DRModels.jl",
    "ok" => false,
    "error" => nothing,
    "logLik" => nothing,
    "converged" => nothing,
    "nobs" => nothing,
    "coef" => Dict{String,Any}(),
    "se" => Dict{String,Any}(),
    "elapsed_s" => nothing,
    "marginal" => has_re ? "Laplace" : nothing,
)
try
    # `:Laplace` on this pin is only for ordinary (1|g) on Poisson/Binomial/
    # NegBinomial2/Gamma/Beta, and for a Gaussian *scale* intercept. Gaussian
    # mean RE uses the exact Woodbury marginal (equals TMB Laplace); passing
    # `:Laplace` is refused. BetaBinomial RE has no Laplace route (#943 neighbour).
    use_laplace = has_re && fam_name in ("NegBinomial2", "Binomial", "Poisson", "Gamma", "Beta")
    fit = if use_laplace
        drm(form, fam; data = df, marginal = :Laplace)
    else
        drm(form, fam; data = df)
    end
    result["marginal"] = use_laplace ? "Laplace" : "default"
    elapsed = time() - t0
    result["elapsed_s"] = elapsed
    result["ok"] = true
    result["logLik"] = loglik(fit)
    result["converged"] = try
        is_converged(fit)
    catch
        getproperty(fit, :converged)
    end
    result["nobs"] = nobs(fit)
    ct = coeftable(fit)
    names_ = ct.rownms
    est = ct.cols[1]
    se = ct.cols[2]
    coefd = Dict{String,Any}()
    sed = Dict{String,Any}()
    for i in eachindex(names_)
        coefd[names_[i]] = est[i]
        sed[names_[i]] = se[i]
    end
    result["coef"] = coefd
    result["se"] = sed
    result["theta"] = collect(coef(fit))
    try
        result["re_sd"] = collect(re_sd(fit))
    catch
    end
catch e
    elapsed = time() - t0
    result["elapsed_s"] = elapsed
    result["ok"] = false
    result["error"] = sprint(showerror, e)
end

out = joinpath(root, "fits", id, "jl.json")
dump_result(out, result)
lls = result["logLik"] === nothing ? "NA" : string(result["logLik"])
err = result["error"] === nothing ? "NULL" : result["error"]
println("[", id, "] DRModels.jl ok=", result["ok"], " logLik=", lls,
        " elapsed=", round(result["elapsed_s"]; digits = 1), "s error=", err)

# Owls ZI+RE probe
if id == "Owls"
    t1 = time()
    probe = Dict{String,Any}("engine" => "DRModels.jl-zi-re-probe", "ok" => false)
    try
        fprobe = bf(
            parse_formula("NCalls ~ 1 + FoodTreatment * ArrivalTime + offset(logBroodSize) + (1 | Nest)"),
            parse_formula("zi ~ 1 + FoodTreatment"),
        )
        fitp = drm(fprobe, NegBinomial2(); data = df, marginal = :Laplace)
        probe["ok"] = true
        probe["logLik"] = loglik(fitp)
        probe["converged"] = is_converged(fitp)
        probe["error"] = nothing
    catch e
        probe["ok"] = false
        probe["error"] = sprint(showerror, e)
        probe["logLik"] = nothing
    end
    probe["elapsed_s"] = time() - t1
    dump_result(joinpath(root, "fits", id, "jl_zi_re_probe.json"), probe)
    println("[", id, "] ZI+RE probe ok=", probe["ok"], " error=",
            probe["error"] === nothing ? "NULL" : probe["error"])
end
