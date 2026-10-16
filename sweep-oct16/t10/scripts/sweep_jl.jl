# t10 Julia 500-rep sweep. One row per seed, appended immediately.
# Usage: T10_CELL=gauss|nb2|re julia --project=/tmp/t10-jl sweep_jl.jl

using Pkg
Pkg.activate("/tmp/t10-jl")
using DRModels
using CSV
using DataFrames

cell = get(ENV, "T10_CELL", "gauss")
nrep = parse(Int, get(ENV, "T10_NREP", "500"))
seed0 = parse(Int, get(ENV, "T10_SEED0", "20261017000"))
data_dir = get(ENV, "T10_DATA", "/tmp/t10-data")
log_dir = "/workspace/sweep-oct16/t10/logs"
mkpath(log_dir)

timeout_for(c) = c == "gauss" ? 30 : c == "nb2" ? 60 : 90
seconds = timeout_for(cell)

csv_path = joinpath(log_dir, "jl_$(cell).csv")
header = "engine,cell,seed,status,elapsed_reduced,elapsed_full,loglik_reduced,loglik_full,aic_reduced,aic_full,aicc_reduced,aicc_full,statistic,df,pvalue,p_method,chibar_p,naive_p,converged_reduced,converged_full,error"
if !isfile(csv_path)
    write(csv_path, header * "\n")
end
done = Set{Int}()
if filesize(csv_path) > length(header)
    prev = CSV.read(csv_path, DataFrame)
    for s in prev.seed
        push!(done, Int(s))
    end
end

function append_row(vals...)
    open(csv_path, "a") do io
        formatted = map(vals) do v
            if v === nothing || (v isa Number && !isfinite(v))
                ""
            elseif v isa AbstractString
                replace(replace(v, "," => ";"), "\n" => " ")
            else
                string(v)
            end
        end
        println(io, join(formatted, ","))
    end
end

function with_timeout(f, seconds)
    t0 = time()
    result = Ref{Any}(nothing)
    err = Ref{Any}(nothing)
    task = @async begin
        try
            result[] = f()
        catch e
            err[] = e
        end
    end
    timed = timedwait(() -> istaskdone(task), float(seconds))
    elapsed = time() - t0
    if timed == :timed_out
        try
            schedule(task, InterruptException(); error = true)
        catch
        end
        return (; ok = false, value = nothing, error = "TIMEOUT after $(seconds)s", elapsed, timeout = true)
    end
    if err[] !== nothing
        return (; ok = false, value = nothing, error = sprint(showerror, err[]), elapsed, timeout = false)
    end
    return (; ok = true, value = result[], error = nothing, elapsed, timeout = false)
end

function load_cell(path)
    CSV.read(path, DataFrame)
end

function slice_seed(df, seed)
    df[df.seed .== seed, :]
end

println("T10 JL sweep cell=", cell, " nrep=", nrep, " timeout=", seconds, "s")

if cell == "gauss"
    df = load_cell(joinpath(data_dir, "gauss_sigma.csv"))
    for i in 0:(nrep - 1)
        seed = seed0 + i
        seed in done && continue
        d = slice_seed(df, seed)
        data = (; y = d.y, x = d.x, z = d.z)
        red = with_timeout(seconds) do
            drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), Gaussian(); data = data)
        end
        ful = if red.ok
            with_timeout(seconds) do
                drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + z)), Gaussian(); data = data)
            end
        else
            (; ok = false, value = nothing, error = "skipped: reduced failed", elapsed = 0.0, timeout = false)
        end
        if !(red.ok && ful.ok)
            st = (red.timeout || ful.timeout) ? "TIMEOUT" : "ERROR"
            append_row("jl", cell, seed, st, red.elapsed, ful.elapsed,
                       "", "", "", "", "", "", "", "", "", "", "", "",
                       "", "", string(red.error, " | ", ful.error))
        else
            t = lrtest(red.value, ful.value)
            append_row("jl", cell, seed, "OK", red.elapsed, ful.elapsed,
                       loglik(red.value), loglik(ful.value),
                       aic(red.value), aic(ful.value),
                       aicc(red.value), aicc(ful.value),
                       t.statistic, t.dof, t.pvalue, "chisq",
                       chibar_pvalue(t.statistic, 1), t.pvalue,
                       red.value.converged, ful.value.converged, "")
        end
        if (i + 1) % 25 == 0
            println("  gauss ", i + 1, "/", nrep)
        end
    end
elseif cell == "nb2"
    df = load_cell(joinpath(data_dir, "nb2_pois.csv"))
    for i in 0:(nrep - 1)
        seed = seed0 + i
        seed in done && continue
        d = slice_seed(df, seed)
        data = (; y = Float64.(d.y), x = d.x)
        red = with_timeout(seconds) do
            drm(bf(@formula(y ~ 1 + x)), Poisson(); data = data, se = false)
        end
        ful = if red.ok
            with_timeout(seconds) do
                drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), NegBinomial2(); data = data, se = false)
            end
        else
            (; ok = false, value = nothing, error = "skipped: reduced failed", elapsed = 0.0, timeout = false)
        end
        if !(red.ok && ful.ok)
            st = (red.timeout || ful.timeout) ? "TIMEOUT" : "ERROR"
            append_row("jl", cell, seed, st, red.elapsed, ful.elapsed,
                       "", "", "", "", "", "", "", "", "", "", "", "",
                       "", "", string(red.error, " | ", ful.error))
        else
            t = lrtest(red.value, ful.value)
            lb = try
                lrt_boundary(ful.value, red.value; q = 1)
            catch
                nothing
            end
            append_row("jl", cell, seed, "OK", red.elapsed, ful.elapsed,
                       loglik(red.value), loglik(ful.value),
                       aic(red.value), aic(ful.value),
                       aicc(red.value), aicc(ful.value),
                       t.statistic, t.dof, t.pvalue, "chisq",
                       lb === nothing ? chibar_pvalue(t.statistic, 1) : lb.pvalue,
                       lb === nothing ? t.pvalue : lb.pvalue_naive,
                       red.value.converged, ful.value.converged, "")
        end
        if (i + 1) % 25 == 0
            println("  nb2 ", i + 1, "/", nrep)
        end
    end
elseif cell == "re"
    df = load_cell(joinpath(data_dir, "re_ri.csv"))
    for i in 0:(nrep - 1)
        seed = seed0 + i
        seed in done && continue
        d = slice_seed(df, seed)
        data = (; y = d.y, x = d.x, g = string.(d.g))
        red = with_timeout(seconds) do
            drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), Gaussian(); data = data)
        end
        ful = if red.ok
            with_timeout(seconds) do
                # Gaussian mean (1|g) has a closed-form marginal; :Laplace is
                # refused (sigma-RE only). Default :LA is the exact Gaussian
                # integral and is the Laplace-comparable number for this family.
                drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
                    data = data)
            end
        else
            (; ok = false, value = nothing, error = "skipped: reduced failed", elapsed = 0.0, timeout = false)
        end
        if !(red.ok && ful.ok)
            st = (red.timeout || ful.timeout) ? "TIMEOUT" : "ERROR"
            append_row("jl", cell, seed, st, red.elapsed, ful.elapsed,
                       "", "", "", "", "", "", "", "", "", "", "", "",
                       "", "", string(red.error, " | ", ful.error))
        else
            t = lrtest(red.value, ful.value)
            lb = lrt_boundary(ful.value, red.value; q = 1)
            append_row("jl", cell, seed, "OK", red.elapsed, ful.elapsed,
                       loglik(red.value), loglik(ful.value),
                       aic(red.value), aic(ful.value),
                       aicc(red.value), aicc(ful.value),
                       t.statistic, t.dof, t.pvalue, "chisq",
                       lb.pvalue, lb.pvalue_naive,
                       red.value.converged, ful.value.converged, "")
        end
        if (i + 1) % 10 == 0
            println("  re ", i + 1, "/", nrep)
        end
    end
else
    error("unknown T10_CELL: $cell")
end

println("T10_JL_DONE cell=", cell)
