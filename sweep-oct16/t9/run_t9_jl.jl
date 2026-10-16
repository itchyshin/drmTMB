#!/usr/bin/env julia
# t9 Julia harness — Gaussian location-scale (1|g) CI coverage
# Pin: DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
# Expected runtime: over 3 h for the full lane (both engines).

using DRModels
using Random
using Dates
using Statistics

const SEED_BASE = 20261016900
const N_REP = parse(Int, get(ENV, "T9_N_REP", "300"))
const N_BOOT_REP = parse(Int, get(ENV, "T9_N_BOOT_REP", "100"))
const N_G = 10
const B = parse(Int, get(ENV, "T9_B", "199"))
const LEVEL = 0.95
const ONLY_CELL = parse(Int, get(ENV, "T9_ONLY_CELL", "0"))

const CELLS = [
    (cell_index = 1, G = 10, sd_g = 0.1),
    (cell_index = 2, G = 10, sd_g = 0.5),
    (cell_index = 3, G = 30, sd_g = 0.1),
    (cell_index = 4, G = 30, sd_g = 0.5),
]

const TARGETS = [
    (key = "sigma_intercept", param = :sigma, coef = "(Intercept)", truth_fn = (sd_g) -> 0.0),
    (key = "sigma_slope", param = :sigma, coef = "x", truth_fn = (sd_g) -> 0.3),
    (key = "sd_g", param = :resd, coef = "g", truth_fn = (sd_g) -> log(sd_g)),
]

function simulate_dat(G, n_g, sd_g, spec_seed)
    rng = MersenneTwister(spec_seed)
    g = repeat(1:G, inner = n_g)
    x = repeat(collect(range(-1, 1, length = n_g)), G)
    u = sd_g .* randn(rng, G)
    sigma = exp.(0.0 .+ 0.3 .* x)
    y = 0.0 .+ 0.5 .* x .+ u[g] .+ sigma .* randn(rng, length(x))
    return (; y, x, g)
end

function timeout_call(f, seconds::Real, label::String)
    t0 = time()
    done = Channel{Any}(1)
    task = @async begin
        try
            put!(done, (:ok, f()))
        catch e
            put!(done, (:err, e, sprint(showerror, e)))
        end
    end
    result = timedwait(() -> istaskdone(task), seconds)
    elapsed = time() - t0
    if result == :timed_out
        return (ok = false, value = nothing, elapsed = elapsed,
                error = "TIMEOUT_$(label)", timed_out = true)
    end
    payload = take!(done)
    if payload[1] === :ok
        return (ok = true, value = payload[2], elapsed = elapsed,
                error = missing, timed_out = false)
    end
    return (ok = false, value = nothing, elapsed = elapsed,
            error = "ERROR_$(label): $(payload[3])", timed_out = false)
end

function find_row(rows, param, coef)
    for r in rows
        if r.param === param && r.coef == coef
            return r
        end
    end
    return nothing
end

function estimate_from_fit(fit, param, coef)
    names = Dict(fit.coefnames)
    haskey(names, param) || return NaN
    idx = findfirst(==(coef), names[param])
    idx === nothing && return NaN
    block = nothing
    for (p, r) in fit.blocks
        if p === param
            block = r
            break
        end
    end
    block === nothing && return NaN
    return fit.theta[first(block) + idx - 1]
end

function tsv_escape(s)
    s = replace(string(s), "\t" => " ", "\n" => " ")
    return s
end

const HEADER = join([
    "engine", "cell_index", "G", "sd_g", "n_g", "n", "rep", "spec_seed",
    "method", "parm", "truth", "estimate", "lower", "upper", "scale",
    "conf_status", "profile_boundary", "profile_message", "bootstrap_n",
    "bootstrap_failed", "covered", "finite_interval", "silent_nan",
    "fit_ok", "timed_out", "error", "elapsed_fit", "elapsed_method",
    "do_bootstrap",
], '\t')

function write_row(io, rec)
    println(io, join([
        rec.engine, rec.cell_index, rec.G, rec.sd_g, rec.n_g, rec.n, rec.rep,
        rec.spec_seed, rec.method, rec.parm, rec.truth, rec.estimate,
        rec.lower, rec.upper, rec.scale, rec.conf_status, rec.profile_boundary,
        tsv_escape(rec.profile_message), rec.bootstrap_n, rec.bootstrap_failed,
        rec.covered, rec.finite_interval, rec.silent_nan, rec.fit_ok,
        rec.timed_out, tsv_escape(rec.error), rec.elapsed_fit, rec.elapsed_method,
        rec.do_bootstrap,
    ], '\t'))
    flush(io)
end

function empty_rec(; cell, spec_seed, rep_i, method, parm, truth, do_boot)
    return (
        engine = "DRModels.jl",
        cell_index = cell.cell_index,
        G = cell.G,
        sd_g = cell.sd_g,
        n_g = N_G,
        n = cell.G * N_G,
        rep = rep_i,
        spec_seed = spec_seed,
        method = method,
        parm = parm,
        truth = truth,
        estimate = NaN,
        lower = NaN,
        upper = NaN,
        scale = "working",
        conf_status = "",
        profile_boundary = "",
        profile_message = "",
        bootstrap_n = "",
        bootstrap_failed = "",
        covered = "",
        finite_interval = false,
        silent_nan = false,
        fit_ok = false,
        timed_out = false,
        error = "",
        elapsed_fit = NaN,
        elapsed_method = NaN,
        do_bootstrap = do_boot,
    )
end

function fill_from_ci(rec, lower, upper, estimate, status; message = "", boundary = "")
    finite = isfinite(lower) && isfinite(upper)
    has_nan = (isnan(lower) || isnan(upper)) && status in ("wald", "profile", "bootstrap")
    covered = finite ? (lower <= rec.truth <= upper) : ""
    return merge(rec, (
        estimate = estimate,
        lower = lower,
        upper = upper,
        conf_status = status,
        profile_boundary = boundary,
        profile_message = message,
        covered = covered,
        finite_interval = finite,
        silent_nan = has_nan,
        fit_ok = true,
        error = "",
    ))
end

function already_done(path)
    done = Set{Tuple{Int,Int,String}}()
    isfile(path) || return done
    for (i, line) in enumerate(eachline(path))
        i == 1 && continue
        parts = split(line, '\t')
        length(parts) >= 9 || continue
        cell_index = parse(Int, parts[2])
        rep = parse(Int, parts[7])
        method = parts[9]
        push!(done, (cell_index, rep, method))
    end
    return done
end

function main()
    out = get(ENV, "T9_JL_OUT", "/workspace/sweep-oct16/t9/results/jl_reps.tsv")
    mkpath(dirname(out))
    done = already_done(out)
    io = open(out, isfile(out) && filesize(out) > 0 ? "a" : "w")
    if filesize(out) == 0
        println(io, HEADER)
        flush(io)
    end

    # Warm compile
    let
        data = simulate_dat(10, 10, 0.5, 1)
        fit = drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1 + x)), Gaussian(); data)
        confint(fit; method = :wald, parm = [:sigma, :resd])
        profile_result(fit; parm = :sigma)
        bootstrap_ci(fit; data, B = 2, rng = MersenneTwister(1), failures = :skip)
        println("WARM_DONE ", Dates.now())
    end

    for cell in CELLS
        ONLY_CELL == 0 || cell.cell_index == ONLY_CELL || continue
        for rep_i in 1:N_REP
            spec_seed = SEED_BASE + (cell.cell_index - 1) * N_REP + (rep_i - 1)
            do_boot = rep_i <= N_BOOT_REP
            methods = do_boot ? ("wald", "profile", "bootstrap") : ("wald", "profile")
            if all(((cell.cell_index, rep_i, m) in done) for m in methods)
                continue
            end
            data = simulate_dat(cell.G, N_G, cell.sd_g, spec_seed)
            fit_res = timeout_call(30.0, "fit") do
                drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1 + x)), Gaussian(); data)
            end
            if !fit_res.ok
                for method in methods
                    (cell.cell_index, rep_i, method) in done && continue
                    for tgt in TARGETS
                        rec = empty_rec(; cell, spec_seed, rep_i, method, parm = tgt.key,
                                        truth = tgt.truth_fn(cell.sd_g), do_boot)
                        rec = merge(rec, (error = fit_res.error, timed_out = fit_res.timed_out,
                                          elapsed_fit = fit_res.elapsed))
                        write_row(io, rec)
                    end
                end
                println("cell=$(cell.cell_index) G=$(cell.G) sd_g=$(cell.sd_g) rep=$(lpad(rep_i,3,'0')) FIT_FAIL $(fit_res.error)")
                continue
            end
            fit = fit_res.value

            if !((cell.cell_index, rep_i, "wald") in done)
                wald_res = timeout_call(15.0, "wald") do
                    confint(fit; method = :wald, parm = [:sigma, :resd])
                end
                for tgt in TARGETS
                    rec = empty_rec(; cell, spec_seed, rep_i, method = "wald", parm = tgt.key,
                                    truth = tgt.truth_fn(cell.sd_g), do_boot)
                    rec = merge(rec, (elapsed_fit = fit_res.elapsed, elapsed_method = wald_res.elapsed,
                                      fit_ok = true, timed_out = wald_res.timed_out))
                    if !wald_res.ok
                        rec = merge(rec, (error = wald_res.error,))
                    else
                        row = find_row(wald_res.value, tgt.param, tgt.coef)
                        if row === nothing
                            rec = merge(rec, (error = "ERROR_wald: missing row $(tgt.key)",))
                        else
                            rec = fill_from_ci(rec, row.lower, row.upper, row.estimate, "wald")
                            rec = merge(rec, (elapsed_fit = fit_res.elapsed, elapsed_method = wald_res.elapsed))
                        end
                    end
                    write_row(io, rec)
                end
            end

            if !((cell.cell_index, rep_i, "profile") in done)
                # Profile each target separately so one failed resd arm does not drop sigma rows.
                t0 = time()
                for tgt in TARGETS
                    rec = empty_rec(; cell, spec_seed, rep_i, method = "profile", parm = tgt.key,
                                    truth = tgt.truth_fn(cell.sd_g), do_boot)
                    rec = merge(rec, (elapsed_fit = fit_res.elapsed, fit_ok = true))
                    pres = timeout_call(60.0, "profile_$(tgt.key)") do
                        profile_result(fit; level = LEVEL, parm = tgt.param)
                    end
                    rec = merge(rec, (elapsed_method = time() - t0, timed_out = pres.timed_out))
                    if !pres.ok
                        rec = merge(rec, (error = pres.error,))
                    else
                        result = pres.value
                        row = find_row(result.ci, tgt.param, tgt.coef)
                        stats = nothing
                        for s in result.stats
                            if s.param === tgt.param && s.coef == tgt.coef
                                stats = s
                                break
                            end
                        end
                        if row === nothing
                            rec = merge(rec, (error = "ERROR_profile: missing row $(tgt.key)",))
                        else
                            failed = stats !== nothing && (stats.lower_endpoint_failed || stats.upper_endpoint_failed)
                            msg = if stats === nothing
                                "profile_result"
                            elseif failed
                                "endpoint_failed lower=$(stats.lower_nuisance_reason) upper=$(stats.upper_nuisance_reason)"
                            else
                                "ok"
                            end
                            status = failed ? "profile_failed" : "profile"
                            rec = fill_from_ci(rec, row.lower, row.upper, row.estimate, status; message = msg)
                            rec = merge(rec, (elapsed_fit = fit_res.elapsed, elapsed_method = time() - t0))
                        end
                    end
                    write_row(io, rec)
                end
            end

            if do_boot && !((cell.cell_index, rep_i, "bootstrap") in done)
                boot_res = timeout_call(180.0, "bootstrap") do
                    bootstrap_ci(fit; data, B = B, level = LEVEL,
                                 rng = MersenneTwister(spec_seed + 17),
                                 failures = :skip)
                end
                for tgt in TARGETS
                    rec = empty_rec(; cell, spec_seed, rep_i, method = "bootstrap", parm = tgt.key,
                                    truth = tgt.truth_fn(cell.sd_g), do_boot)
                    rec = merge(rec, (elapsed_fit = fit_res.elapsed, elapsed_method = boot_res.elapsed,
                                      fit_ok = true, timed_out = boot_res.timed_out))
                    if !boot_res.ok
                        rec = merge(rec, (error = boot_res.error,))
                    else
                        row = find_row(boot_res.value, tgt.param, tgt.coef)
                        if row === nothing
                            rec = merge(rec, (error = "ERROR_bootstrap: missing row $(tgt.key)",))
                        else
                            rec = fill_from_ci(rec, row.lower, row.upper, row.estimate, "bootstrap")
                            rec = merge(rec, (elapsed_fit = fit_res.elapsed, elapsed_method = boot_res.elapsed))
                        end
                    end
                    write_row(io, rec)
                end
            end

            println("cell=$(cell.cell_index) G=$(cell.G) sd_g=$(cell.sd_g) rep=$(lpad(rep_i,3,'0')) fit=$(round(fit_res.elapsed; digits=3))s")
        end
        println("DONE cell $(cell.cell_index)")
    end
    close(io)
    println("ALL_DONE ", Dates.now())
end

main()
