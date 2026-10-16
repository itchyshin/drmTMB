# Fit one t6 cell in DRModels.jl and write predict() values for the shared grid.
# Usage: julia --project=<env> t6_run_DRModels.jl <root> <family> <fe|re>
using DRModels, DelimitedFiles, Random, Statistics, LinearAlgebra

root = ARGS[1]
family = ARGS[2]
re_lab = ARGS[3]
re = re_lab == "re"
cell = family * "_" * (re ? "re" : "fe")
datadir = joinpath(root, "data")
resdir = joinpath(root, "results")
mkpath(resdir)
log_path = joinpath(resdir, "cells_julia_" * cell * ".csv")

function csvq(s)
    "\"" * replace(replace(string(s), "\"" => "'"), "\n" => " ") * "\""
end

function append_row(; check, status, pass, detail, time_s)
    hdr = !isfile(log_path)
    open(log_path, "a") do io
        hdr && println(io, "engine,cell,family,re,check,status,pass,detail,time_s")
        println(io, join(["DRModels", cell, family, re, check, status, pass,
                          csvq(detail), time_s], ","))
    end
    println(check, " ", status, " pass=", pass, " ", detail)
end

function read_cell(path)
    raw, hdr = readdlm(path, ','; header = true)
    cols = Dict(String(h) => j for (j, h) in enumerate(vec(hdr)))
    getc(n) = raw[:, cols[n]]
    return (
        y = Float64.(getc("y")),
        x = Float64.(getc("x")),
        f = string.(getc("f")),
        g = string.(getc("g")),
        trials = Int.(getc("trials")),
    )
end

function family_obj()
    family == "gaussian" && return Gaussian()
    family == "student" && return Student()
    family == "lognormal" && return LogNormal()
    family == "gamma" && return Gamma()
    family == "poisson" && return Poisson()
    family == "nbinom2" && return NegBinomial2()
    family == "binomial" && return Binomial()
    family == "beta" && return Beta()
    family == "tweedie" && return Tweedie()
    family == "skew_normal" && return SkewNormal()
    family == "beta_binomial" && return BetaBinomial()
    family == "zero_one_beta" && return ZeroOneBeta()
    error("unknown family $family")
end

function build_formula()
    if family == "beta_binomial"
        return re ?
            bf(@formula(cbind(y, failures) ~ x + f + (1 | g)), @formula(sigma ~ 1)) :
            bf(@formula(cbind(y, failures) ~ x + f), @formula(sigma ~ 1))
    end
    if family in ("poisson", "binomial")
        return re ? bf(@formula(y ~ x + f + (1 | g))) :
                    bf(@formula(y ~ x + f))
    end
    if family == "zero_one_beta"
        return bf(@formula(y ~ x + f), @formula(sigma ~ 1),
                  @formula(zoi ~ 1), @formula(coi ~ 1))
    end
    if family in ("student", "tweedie", "skew_normal")
        return re ?
            bf(@formula(y ~ x + f + (1 | g)), @formula(sigma ~ 1), @formula(nu ~ 1)) :
            bf(@formula(y ~ x + f), @formula(sigma ~ 1), @formula(nu ~ 1))
    end
    return re ?
        bf(@formula(y ~ x + f + (1 | g)), @formula(sigma ~ 1)) :
        bf(@formula(y ~ x + f), @formula(sigma ~ 1))
end

function dpars()
    family in ("poisson", "binomial") && return [:mu]
    family == "zero_one_beta" && return [:mu, :sigma, :zoi, :coi]
    family in ("student", "tweedie", "skew_normal") && return [:mu, :sigma, :nu]
    return [:mu, :sigma]
end

D = read_cell(joinpath(datadir, cell * ".csv"))
failures = D.trials .- round.(Int, D.y)
dat = (y = D.y, x = D.x, f = D.f, g = D.g, trials = D.trials,
       failures = Float64.(failures))
fam = family_obj()
form = build_formula()

t0 = time()
fit = try
    if re && family in ("poisson", "gamma", "nbinom2", "binomial", "beta",
                        "student", "lognormal")
        drm(form, fam; data = dat, marginal = :Laplace)
    else
        drm(form, fam; data = dat)
    end
catch e
    e
end
el = time() - t0

if fit isa Exception
    append_row(check = "fit", status = "error", pass = false,
               detail = sprint(showerror, fit), time_s = el)
    exit(0)
end

append_row(check = "fit", status = "ok",
           pass = is_converged(fit),
           detail = "converged=$(is_converged(fit)) loglik=$(fit.loglik) iter=$(fit.iterations)",
           time_s = el)

nd = (x = [-0.5, 0.0, 0.5], f = ["a", "b", "c"], g = fill(D.g[1], 3),
      trials = fill(12, 3))

# predict types
for typ in (:response, :link)
    t1 = time()
    val = try
        predict(fit, nd; type = typ)
    catch e
        e
    end
    elp = time() - t1
    if val isa Exception
        append_row(check = "predict_$(typ)_mu", status = "error", pass = false,
                   detail = sprint(showerror, val), time_s = elp)
    else
        v = val isa NamedTuple ? val.prediction : val
        v = v isa Dict ? v[:mu] : v
        ok = all(isfinite, v) && length(v) == 3
        append_row(check = "predict_$(typ)_mu", status = "ok", pass = ok,
                   detail = "n=$(length(v)) range=$(extrema(v))", time_s = elp)
    end
end

# each distributional parameter via predict_parameters
t1 = time()
pp = try
    predict_parameters(fit, nd; type = :response)
catch e
    e
end
elp = time() - t1
if pp isa Exception
    append_row(check = "predict_parameters", status = "error", pass = false,
               detail = sprint(showerror, pp), time_s = elp)
else
    missing = [string(p) for p in dpars() if !haskey(pp, p)]
    append_row(check = "predict_parameters", status = "ok",
               pass = isempty(missing),
               detail = "keys=$(join(string.(keys(pp)), '/')) missing=$(join(missing, '/'))",
               time_s = elp)
end

# write R-comparable predict table
pred_path = joinpath(resdir, "predict_J_" * cell * ".csv")
open(pred_path, "w") do io
    cols = ["row"]
    for p in dpars()
        push!(cols, string(p) * "_response")
        push!(cols, string(p) * "_link")
    end
    println(io, join(cols, ","))
    pp_r = try predict_parameters(fit, nd; type = :response) catch; Dict() end
    pp_l = try predict_parameters(fit, nd; type = :link) catch; Dict() end
    for i in 1:3
        row = Any[i]
        for p in dpars()
            vr = haskey(pp_r, p) ? pp_r[p][i] : NaN
            vl = haskey(pp_l, p) ? pp_l[p][i] : NaN
            push!(row, vr, vl)
        end
        println(io, join(row, ","))
    end
end

# unseen factor level
nd_bad = (x = [0.0], f = ["z"], g = [D.g[1]], trials = [12])
t1 = time()
unseen = try
    predict(fit, nd_bad)
catch e
    e
end
elp = time() - t1
if unseen isa Exception
    msg = sprint(showerror, unseen)
    named = occursin("level", lowercase(msg)) || occursin("column", lowercase(msg)) ||
            occursin("factor", lowercase(msg))
    append_row(check = "newdata_unseen_level", status = "error_ok", pass = named,
               detail = msg, time_s = elp)
else
    append_row(check = "newdata_unseen_level", status = "silent", pass = false,
               detail = "predict returned a value for unseen level z", time_s = elp)
end

# character vs factor: Julia stores f as String already; compare to a
# re-coded copy (same strings). This is a smoke equality, not an R factor.
t1 = time()
nd_chr = (x = [-0.5, 0.5], f = ["a", "c"], g = fill(D.g[1], 2), trials = fill(12, 2))
p1 = try predict(fit, nd_chr) catch e; e end
p2 = try predict(fit, nd_chr) catch e; e end
elp = time() - t1
if p1 isa Exception || p2 isa Exception
    append_row(check = "char_vs_factor", status = "error", pass = false,
               detail = sprint(showerror, p1 isa Exception ? p1 : p2), time_s = elp)
else
    v1 = p1 isa NamedTuple ? p1.prediction : p1
    v2 = p2 isa NamedTuple ? p2.prediction : p2
    mx = maximum(abs.(v1 .- v2))
    append_row(check = "char_vs_factor", status = "ok", pass = mx <= 1e-14,
               detail = "max_abs_diff=$mx (Julia strings; R char-vs-factor is the real cell)",
               time_s = elp)
end

# se.fit where offered: Julia predict(...; se=true)
t1 = time()
se_pred = try
    predict(fit, nd; se = true)
catch e
    e
end
elp = time() - t1
if se_pred isa Exception
    append_row(check = "se.fit_predict", status = "error", pass = false,
               detail = sprint(showerror, se_pred), time_s = elp)
elseif se_pred isa NamedTuple && haskey(se_pred, :se)
    ok = all(isfinite, se_pred.se)
    append_row(check = "se.fit_predict", status = "ok", pass = ok,
               detail = "se range=$(extrema(se_pred.se))", time_s = elp)
else
    append_row(check = "se.fit_predict", status = "missing", pass = false,
               detail = "predict(; se=true) did not return se", time_s = elp)
end

# simulate nsim=1000 vs fitted moments (training rows; Julia has no newdata)
t1 = time()
sims = try
    simulate(fit; nsim = 1000, rng = MersenneTwister(202610166))
catch e
    e
end
elp = time() - t1
if sims isa Exception
    append_row(check = "simulate_conditional", status = "error", pass = false,
               detail = sprint(showerror, sims), time_s = elp)
else
    μ = fit.means[:mu]
    sim_mean = vec(mean(sims; dims = 2))
    sim_var = vec(var(sims; dims = 2))
    # Fitted conditional moments from stored means/scales.
    if haskey(fit.scales, :sigma)
        σ = fit.scales[:sigma]
        if family == "gaussian" || family == "skew_normal"
            m, v = μ, σ .^ 2
        elseif family == "lognormal"
            m = exp.(μ .+ σ .^ 2 ./ 2)
            v = exp.(2 .* μ .+ σ .^ 2) .* (exp.(σ .^ 2) .- 1)
        elseif family == "gamma"
            m, v = μ, (μ .* σ) .^ 2
        elseif family == "nbinom2"
            m, v = μ, μ .+ σ .^ 2 .* μ .^ 2
        elseif family == "beta"
            ϕ = 1 ./ (σ .^ 2)
            m, v = μ, μ .* (1 .- μ) ./ (1 .+ ϕ)
        elseif family == "student" && haskey(fit.scales, :nu)
            ν = fit.scales[:nu]
            m, v = μ, σ .^ 2 .* ν ./ (ν .- 2)
        else
            m, v = μ, fill(NaN, length(μ))
        end
    elseif family == "poisson"
        m, v = μ, μ
    elseif family == "binomial"
        m, v = μ, μ .* (1 .- μ)
    else
        m, v = μ, fill(NaN, length(μ))
    end
    mcse = sqrt.(max.(v, 0) ./ 1000)
    z = abs.(sim_mean .- m) ./ replace(mcse, 0 => NaN)
    z = filter(isfinite, z)
    pass = !isempty(z) && maximum(z) <= 3
    append_row(check = "simulate_mean_vs_fitted",
               status = pass ? "ok" : "fail", pass = pass,
               detail = "max_z=$(isempty(z) ? NaN : maximum(z)) n=$(length(z))",
               time_s = elp)
    if all(isfinite, v)
        mcse_v = v .* sqrt(2 / 999)
        zv = abs.(sim_var .- v) ./ replace(mcse_v, 0 => NaN)
        zv = filter(isfinite, zv)
        passv = !isempty(zv) && maximum(zv) <= 3
        append_row(check = "simulate_var_vs_fitted",
                   status = passv ? "ok" : "fail", pass = passv,
                   detail = "max_z=$(isempty(zv) ? NaN : maximum(zv))",
                   time_s = 0)
    else
        append_row(check = "simulate_var_vs_fitted", status = "skip", pass = false,
                   detail = "no closed-form variance", time_s = 0)
    end
end

# simulate(newdata=) — Julia has no newdata formal either
append_row(check = "simulate_newdata", status = "no_formal", pass = false,
           detail = "simulate(fit; nsim, rng) has no newdata; draws are training rows",
           time_s = 0)
