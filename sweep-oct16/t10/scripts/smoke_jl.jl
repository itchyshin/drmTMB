# t10 Julia smoke, second pass: no soft-scope, Gaussian without se=.
using Pkg
Pkg.activate("/tmp/t10-jl")
using DRModels
using Random
using Distributions: Poisson as DPoisson
using InteractiveUtils: versioninfo
using Logging

const LOG = "/workspace/sweep-oct16/t10/logs/smoke_jl.jsonl"
mkpath(dirname(LOG))
# keep the first-pass log; write a clean second file
const LOG2 = "/workspace/sweep-oct16/t10/logs/smoke_jl2.jsonl"
isfile(LOG2) && rm(LOG2)

json_escape(s) = replace(replace(string(s), "\\" => "\\\\"), "\"" => "\\\"", "\n" => "\\n")

function emit(; kwargs...)
    parts = String[]
    for (k, v) in pairs(kwargs)
        if v === nothing
            push!(parts, "\"$(k)\":null")
        elseif v isa Bool
            push!(parts, "\"$(k)\":$(v ? "true" : "false")")
        elseif v isa Number && isfinite(Float64(v))
            push!(parts, "\"$(k)\":$(v)")
        else
            push!(parts, "\"$(k)\":\"$(json_escape(v))\"")
        end
    end
    line = "{" * join(parts, ",") * "}"
    open(LOG2, "a") do io
        println(io, line)
    end
    println(line)
    return nothing
end

function catch_call(f)
    try
        return (; ok = true, value = f(), error = nothing)
    catch e
        return (; ok = false, value = nothing, error = sprint(showerror, e))
    end
end

function run_smoke()
    Random.seed!(20261017000 - 19000000000)
    n = 200
    x = randn(n); z = randn(n)
    y = 0.3 .+ 0.5 .* x .+ randn(n)
    data_a = (; y, x, z)
    m0 = catch_call() do
        drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), Gaussian(); data = data_a)
    end
    m1 = catch_call() do
        drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + z)), Gaussian(); data = data_a)
    end
    emit(case = "A_reduced", status = m0.ok ? "OK" : "ERROR", error = m0.error)
    emit(case = "A_full", status = m1.ok ? "OK" : "ERROR", error = m1.error)
    if m0.ok && m1.ok
        t = lrtest(m0.value, m1.value)
        emit(case = "A_lrtest", status = "OK", statistic = t.statistic, dof = t.dof, pvalue = t.pvalue,
             aic_reduced = aic(m0.value), aic_full = aic(m1.value),
             aicc_reduced = aicc(m0.value), aicc_full = aicc(m1.value),
             loglik_reduced = loglik(m0.value), loglik_full = loglik(m1.value),
             anova_equals_lrtest = anova(m0.value, m1.value) == t)
    end

    Random.seed!(20261017000 - 19000000000)
    n = 250
    x = randn(n)
    mu = exp.(0.4 .+ 0.3 .* x)
    y = rand.(DPoisson.(mu))
    data_b = (; y = Float64.(y), x)
    p0 = catch_call() do
        drm(bf(@formula(y ~ 1 + x)), Poisson(); data = data_b, se = false)
    end
    p1 = catch_call() do
        drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), NegBinomial2(); data = data_b, se = false)
    end
    emit(case = "B_poisson", status = p0.ok ? "OK" : "ERROR", error = p0.error)
    emit(case = "B_nbinom2", status = p1.ok ? "OK" : "ERROR", error = p1.error)
    if p0.ok && p1.ok
        warns = String[]
        t = nothing
        Logging.with_logger(SimpleLogger(devnull)) do
            t = lrtest(p0.value, p1.value)
        end
        # capture warnings properly
        warn_buf = IOBuffer()
        t = with_logger(SimpleLogger(warn_buf)) do
            lrtest(p0.value, p1.value)
        end
        warn_txt = String(take!(warn_buf))
        lb = catch_call() do
            lrt_boundary(p1.value, p0.value; q = 1)
        end
        emit(case = "B_lrtest", status = "OK", statistic = t.statistic, dof = t.dof, pvalue = t.pvalue,
             aic_reduced = aic(p0.value), aic_full = aic(p1.value),
             loglik_reduced = loglik(p0.value), loglik_full = loglik(p1.value),
             dof_reduced = dof(p0.value), dof_full = dof(p1.value),
             lrtest_warning = warn_txt,
             lrt_boundary_ok = lb.ok,
             lrt_boundary_p = lb.ok ? lb.value.pvalue : nothing,
             lrt_boundary_stat = lb.ok ? lb.value.statistic : nothing,
             lrt_boundary_err = lb.error)
    end

    Random.seed!(20261017000 - 19000000000)
    G = 25; m = 12; n = G * m
    g = string.(repeat(1:G, inner = m))
    x = randn(n)
    y = 0.4 .- 0.5 .* x .+ 0.7 .* randn(n)
    data_c = (; y, x, g)
    r0 = catch_call() do
        drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), Gaussian(); data = data_c)
    end
    r1 = catch_call() do
        drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
            data = data_c, marginal = :Laplace)
    end
    r1_la = catch_call() do
        drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
            data = data_c, marginal = :LA)
    end
    emit(case = "C_reduced", status = r0.ok ? "OK" : "ERROR", error = r0.error)
    emit(case = "C_full_laplace", status = r1.ok ? "OK" : "ERROR", error = r1.error,
         marginal = r1.ok ? string(r1.value.marginal) : nothing)
    emit(case = "C_full_LA", status = r1_la.ok ? "OK" : "ERROR", error = r1_la.error,
         marginal = r1_la.ok ? string(r1_la.value.marginal) : nothing)
    if r0.ok && r1.ok
        warn_buf = IOBuffer()
        t = with_logger(SimpleLogger(warn_buf)) do
            lrtest(r0.value, r1.value)
        end
        lb = lrt_boundary(r1.value, r0.value; q = 1)
        emit(case = "C_lrtest_laplace", status = "OK", statistic = t.statistic, dof = t.dof,
             pvalue_naive = t.pvalue, chibar_p = lb.pvalue, naive_p = lb.pvalue_naive,
             aic_reduced = aic(r0.value), aic_full = aic(r1.value),
             loglik_reduced = loglik(r0.value), loglik_full = loglik(r1.value),
             lrtest_warning = String(take!(warn_buf)))
    end

    if r1.ok && r1_la.ok
        mix = catch_call() do
            lrtest(r1_la.value, r1.value)
        end
        emit(case = "mix_LA_vs_Laplace_lrtest",
             status = mix.ok ? "NO_ERROR" : "ERROR_AS_REQUIRED",
             error = mix.error,
             loglik_LA = loglik(r1_la.value),
             loglik_Laplace = loglik(r1.value),
             abs_diff = abs(loglik(r1_la.value) - loglik(r1.value)))
    end

    Random.seed!(20261017001 - 19000000000)
    G = 20; m = 8; n = G * m
    g = string.(repeat(1:G, inner = m))
    x = randn(n)
    y = rand.(DPoisson.(exp.(0.2 .+ 0.3 .* x)))
    data_va = (; y = Float64.(y), x, g)
    va_red = catch_call() do
        drm(bf(@formula(y ~ 1 + (1 | g))), Poisson(); data = data_va, se = false, marginal = :VA)
    end
    va_full = catch_call() do
        drm(bf(@formula(y ~ 1 + x + (1 | g))), Poisson(); data = data_va, se = false, marginal = :VA)
    end
    lap_full = catch_call() do
        drm(bf(@formula(y ~ 1 + x + (1 | g))), Poisson(); data = data_va, se = false, marginal = :Laplace)
    end
    emit(case = "mix_VA_re_reduced", status = va_red.ok ? "OK" : "ERROR", error = va_red.error)
    emit(case = "mix_VA_re_full", status = va_full.ok ? "OK" : "ERROR", error = va_full.error)
    emit(case = "mix_Laplace_re_full", status = lap_full.ok ? "OK" : "ERROR", error = lap_full.error)

    if va_red.ok && va_full.ok
        mix = catch_call() do
            lrtest(va_red.value, va_full.value)
        end
        emit(case = "mix_VA_vs_VA_lrtest",
             status = mix.ok ? "NO_ERROR" : "ERROR_AS_REQUIRED",
             error = mix.error,
             statistic = mix.ok ? mix.value.statistic : nothing,
             pvalue = mix.ok ? mix.value.pvalue : nothing)
        aic_try = catch_call() do
            aic(va_full.value)
        end
        emit(case = "mix_VA_aic",
             status = aic_try.ok ? "NO_ERROR" : "ERROR_AS_REQUIRED",
             error = aic_try.error)
    end
    if va_full.ok && lap_full.ok
        mix = catch_call() do
            lrtest(va_full.value, lap_full.value)
        end
        emit(case = "mix_VA_vs_Laplace_lrtest",
             status = mix.ok ? "NO_ERROR" : "ERROR_AS_REQUIRED",
             error = mix.error)
    end
    return nothing
end

run_smoke()
open("/workspace/sweep-oct16/t10/logs/versioninfo_jl.txt", "w") do io
    versioninfo(io)
    println(io, "DRModels pin: f71b2923360e9e5d4591e0d6e15a9ef9db0356d7")
end
println("SMOKE_JL2_OK")
