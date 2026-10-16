# lib_t6.jl -- helpers for the t6 (predict()/simulate()) Julia harness.
#
# Lane t6 of the 16 Oct 2026 sweep. Engine: DRModels.jl at the pinned checkout
# (f71b2923360e9e5d4591e0d6e15a9ef9db0356d7), called natively. Every "expected"
# value here is computed independently of the engine's predict/simulate code:
# design matrices are rebuilt by hand from the coefficient names (treatment
# contrasts, reference level = first level), links come from the family
# docstrings, and moments come from the SPEC table. Nothing here calls engine
# internals except to *record* a flag (`DRModels._gamma_sigma_is_shape`).
#
# Included by julia/10_harness_jl.jl.

using DRModels
using CSV, DataFrames, Random, Statistics, LinearAlgebra, Serialization
using CategoricalArrays
using JSON
using FastGaussQuadrature: gausshermite
import Distributions
import Logging

const T6 = "/home/user/drmTMB/sweep-oct16/t6"
const DATA = joinpath(T6, "data")
const RES = joinpath(T6, "results")
const FITDIR = joinpath(RES, "jl_fits")

logistic(x) = 1 / (1 + exp(-x))
logit(p) = log(p / (1 - p))

# ---------------------------------------------------------------- data ------
# CSV.jl returns string columns as an InlineStrings/PooledArray type: convert
# to Vector{String}; numbers to Vector{Float64}. Column order is kept.
function readnt(file)
    df = CSV.read(joinpath(DATA, file), DataFrame)
    nms = Symbol.(names(df))
    vals = map(names(df)) do n
        c = df[!, n]
        T = nonmissingtype(eltype(c))
        T <: AbstractString ? String.(c) : Vector{Float64}(c)
    end
    return NamedTuple{Tuple(nms)}(Tuple(vals))
end

dropcol(nt::NamedTuple, k::Symbol) = NamedTuple{Tuple(filter(!=(k), keys(nt)))}(nt)
setcol(nt::NamedTuple, k::Symbol, v) = merge(nt, NamedTuple{(k,)}((v,)))

# ---------------------------------------------------------------- families --
const FAMSPEC = Dict{String,Any}(
    "gaussian"          => (fam = Gaussian(),              sigma = true,  extra = Symbol[],      cb = false),
    "student"           => (fam = Student(),               sigma = true,  extra = [:nu],         cb = false),
    "skew_normal"       => (fam = SkewNormal(),            sigma = true,  extra = [:nu],         cb = false),
    "lognormal"         => (fam = LogNormal(),             sigma = true,  extra = Symbol[],      cb = false),
    "gamma"             => (fam = Gamma(),                 sigma = true,  extra = Symbol[],      cb = false),
    "beta"              => (fam = Beta(),                  sigma = true,  extra = Symbol[],      cb = false),
    "zero_one_beta"     => (fam = ZeroOneBeta(),           sigma = true,  extra = [:zoi, :coi],  cb = false),
    "beta_binomial"     => (fam = BetaBinomial(),          sigma = true,  extra = Symbol[],      cb = true),
    "binomial"          => (fam = Binomial(),              sigma = false, extra = Symbol[],      cb = true),
    "poisson"           => (fam = Poisson(),               sigma = false, extra = Symbol[],      cb = false),
    "nbinom2"           => (fam = NegBinomial2(),          sigma = true,  extra = Symbol[],      cb = false),
    "truncated_nbinom2" => (fam = TruncatedNegBinomial2(), sigma = true,  extra = Symbol[],      cb = false),
    "tweedie"           => (fam = Tweedie(),               sigma = true,  extra = [:nu],         cb = false),
    "cumulative_logit"  => (fam = CumulativeLogit(),       sigma = false, extra = Symbol[],      cb = false),
)

function mu_formula(cb::Bool, ri::Bool)
    if cb
        return ri ? @formula(cbind(successes, failures) ~ x + f + (1 | g)) :
                    @formula(cbind(successes, failures) ~ x + f)
    else
        return ri ? @formula(y ~ x + f + (1 | g)) : @formula(y ~ x + f)
    end
end
const SIG_X = @formula(sigma ~ x)
const SIG_1 = @formula(sigma ~ 1)
const EXTRA_F = Dict(:nu => @formula(nu ~ 1), :zoi => @formula(zoi ~ 1), :coi => @formula(coi ~ 1))

function build_forms(spec, ri::Bool; sigma1::Bool = false)
    forms = Any[mu_formula(spec.cb, ri)]
    s = [(spec.cb ? "cbind(successes, failures)" : "y") * " ~ x + f" * (ri ? " + (1 | g)" : "")]
    if spec.sigma
        push!(forms, sigma1 ? SIG_1 : SIG_X)
        push!(s, sigma1 ? "sigma ~ 1" : "sigma ~ x")
    end
    for e in spec.extra
        push!(forms, EXTRA_F[e]); push!(s, "$(e) ~ 1")
    end
    return forms, "bf(" * join(s, ", ") * ")"
end

# Fit with warnings captured. Returns (fit|nothing, error string|nothing, seconds, warnings).
function tryfit(forms, fam, data; marginal = nothing)
    buf = IOBuffer()
    lg = Logging.SimpleLogger(buf, Logging.Warn)
    t0 = time()
    fit = nothing; err = nothing
    try
        Logging.with_logger(lg) do
            f = bf(forms...)
            fit = marginal === nothing ? drm(f, fam; data = data) :
                                         drm(f, fam; data = data, marginal = marginal)
        end
    catch e
        err = errstring(e, catch_backtrace())
    end
    w = String(take!(buf))
    isempty(w) || print("    [captured warnings]\n", w)
    return fit, err, time() - t0, w
end

function errstring(e, bt = nothing; nframes = 4)
    msg = sprint(showerror, e)
    if bt !== nothing
        st = stacktrace(bt)
        fr = join(["      " * string(st[i]) for i in 1:min(nframes, length(st))], "\n")
        return msg * "\n    first frames:\n" * fr
    end
    return msg
end
errhead(s) = s === nothing ? nothing : first(split(s, "\n    first frames:"))

# ---------------------------------------------------------------- hand design
coefnames_of(fit, d::Symbol) = begin
    for (p, ns) in fit.coefnames
        p === d && return ns
    end
    nothing
end
blockrange(fit, d::Symbol) = begin
    for (p, r) in fit.blocks
        p === d && return r
    end
    nothing
end
# Distributional parameters that carry a formula (blocks named in the formula).
function formula_dpars(fit)
    forms = Dict(fit.formula.forms)
    return [p for (p, _) in fit.blocks if haskey(forms, p)]
end

# Treatment-contrast design by hand from the engine's coefficient names.
function handX(names::Vector{String}, nd)
    n = length(nd.x)
    X = zeros(n, length(names))
    fs = haskey(nd, :f) ? string.(nd.f) : fill("", n)
    for (j, nm) in enumerate(names)
        if nm == "(Intercept)"
            X[:, j] .= 1.0
        elseif nm == "x"
            X[:, j] .= Float64.(nd.x)
        elseif startswith(nm, "f: ")
            X[:, j] .= Float64.(fs .== nm[4:end])
        else
            error("handX: unknown coefficient name `$nm`")
        end
    end
    return X
end
function hand_eta(fit, d::Symbol, nd)
    X = handX(coefnames_of(fit, d), nd)
    return X * fit.theta[blockrange(fit, d)], X
end

# Documented inverse links (family docstrings at the pin):
#  mu: identity (Gaussian/Student/SkewNormal); exp (Gamma/Poisson/NB2/TruncNB2/Tweedie;
#      LogNormal: docstring "response-scale median is exp(mu)", predict applies exp);
#      logistic (Beta/ZeroOneBeta/BetaBinomial/Binomial); CumulativeLogit: identity (eta).
#  sigma: exp.  nu: Student 2 + exp(eta); SkewNormal identity; Tweedie 1 + logistic(eta).
#  zoi/coi: logistic.
function doc_inv(fam::String, d::Symbol, η)
    if d === :mu
        fam in ("gaussian", "student", "skew_normal", "cumulative_logit") && return copy(η)
        fam in ("lognormal", "gamma", "poisson", "nbinom2", "truncated_nbinom2", "tweedie") && return exp.(η)
        fam in ("beta", "zero_one_beta", "beta_binomial", "binomial") && return logistic.(η)
    elseif d === :sigma
        return exp.(η)
    elseif d === :nu
        fam == "student" && return 2 .+ exp.(η)
        fam == "skew_normal" && return copy(η)
        fam == "tweedie" && return 1 .+ logistic.(η)
    elseif d === :zoi || d === :coi
        return logistic.(η)
    end
    error("doc_inv: no documented link for $fam/$d")
end
function doc_deriv(fam::String, d::Symbol, η)
    if d === :mu
        fam in ("gaussian", "student", "skew_normal", "cumulative_logit") && return ones(length(η))
        fam in ("lognormal", "gamma", "poisson", "nbinom2", "truncated_nbinom2", "tweedie") && return exp.(η)
        fam in ("beta", "zero_one_beta", "beta_binomial", "binomial") && return logistic.(η) .* (1 .- logistic.(η))
    elseif d === :sigma
        return exp.(η)
    elseif d === :nu
        fam == "student" && return exp.(η)
        fam == "skew_normal" && return ones(length(η))
        fam == "tweedie" && return logistic.(η) .* (1 .- logistic.(η))
    elseif d === :zoi || d === :coi
        return logistic.(η) .* (1 .- logistic.(η))
    end
    error("doc_deriv: no documented link for $fam/$d")
end

# Cumulative-logit cutpoints from the raw increments (docstring: θ1 = δ1, θk = θk-1 + exp(δk)).
function hand_cuts(fit)
    δ = fit.theta[blockrange(fit, :cutpoints)]
    c = similar(δ); c[1] = δ[1]
    for k in 2:length(δ); c[k] = c[k-1] + exp(δ[k]); end
    return c
end
function cum_probs(η::Real, cuts)
    K = length(cuts) + 1
    F(z) = logistic(z)
    return [k == 1 ? F(cuts[1] - η) : k == K ? 1 - F(cuts[end] - η) : F(cuts[k] - η) - F(cuts[k-1] - η) for k in 1:K]
end

# Hand-computed per-row parameters at b = 0 for every formula dpar.
function hand_params(fam::String, fit, nd)
    out = Dict{Symbol,Any}()
    for d in formula_dpars(fit)
        η, _ = hand_eta(fit, d, nd)
        out[d] = (eta = η, resp = doc_inv(fam, d, η))
    end
    return out
end

# What DRModels documents/stores as fit.means[:mu] at b = 0 (hand version), and
# the true response mean E[y] at b = 0 (SPEC moment table).
function hand_stored_and_Ey(fam::String, fit, nd)
    hp = hand_params(fam, fit, nd)
    if fam == "cumulative_logit"
        cuts = hand_cuts(fit)
        η = hp[:mu].eta
        sc = [sum(k * p for (k, p) in enumerate(cum_probs(e, cuts))) for e in η]
        return sc, sc
    end
    μ = hp[:mu].resp
    if fam == "lognormal"
        σ = hp[:sigma].resp
        return μ, exp.(hp[:mu].eta .+ σ .^ 2 ./ 2)
    elseif fam == "zero_one_beta"
        zoi = hp[:zoi].resp; coi = hp[:coi].resp
        m = (1 .- zoi) .* μ .+ zoi .* coi
        return m, m
    elseif fam == "truncated_nbinom2"
        k = 1 ./ hp[:sigma].resp .^ 2
        p0 = (k ./ (k .+ μ)) .^ k
        return μ, μ ./ (1 .- p0)
    end
    return μ, μ
end

# ---------------------------------------------------------------- compare ---
maxabs(a, b) = (length(a) == length(b) || return Inf; isempty(a) ? 0.0 : maximum(abs.(a .- b)))
maxrel(a, b) = (length(a) == length(b) || return Inf; isempty(a) ? 0.0 : maximum(abs.(a .- b) ./ max.(1.0, abs.(b))))
check(name, val, tol) = (name = name, value = val, tol = tol, pass = isfinite(val) && val <= tol)

# A test result record (SPEC output contract: status, metric, value, notes).
mkres(status, metric, value, notes; details = nothing) =
    Dict{String,Any}("status" => status, "metric" => metric, "value" => value,
                     "notes" => notes, "details" => details)

function summarize_checks(checks; metric = "max deviation over checks")
    fails = [c for c in checks if !c.pass]
    det = [Dict("check" => c.name, "value" => c.value, "tol" => c.tol, "pass" => c.pass) for c in checks]
    worst = isempty(checks) ? NaN : maximum(c.value for c in checks)
    status = isempty(fails) ? "PASS" : "FAIL"
    notes = isempty(fails) ? "all $(length(checks)) checks pass" :
            "failing: " * join(["$(c.name) ($(round(c.value, sigdigits=4)) > $(c.tol))" for c in fails], "; ")
    return status, worst, notes, det
end

# ---------------------------------------------------------------- JSON ------
sanitize(x::AbstractFloat) = isfinite(x) ? Float64(x) : string(x)
sanitize(x::Integer) = x
sanitize(x::Bool) = x
sanitize(x::Nothing) = nothing
sanitize(x::AbstractString) = String(x)
sanitize(x::Symbol) = String(x)
sanitize(x::AbstractDict) = Dict{String,Any}(string(k) => sanitize(v) for (k, v) in x)
sanitize(x::NamedTuple) = Dict{String,Any}(string(k) => sanitize(v) for (k, v) in pairs(x))
sanitize(x::Union{AbstractVector,Tuple}) = Any[sanitize(v) for v in x]
sanitize(x::AbstractMatrix) = Any[sanitize(collect(r)) for r in eachrow(x)]
sanitize(x) = string(x)

function writejson(path, obj)
    open(path, "w") do io
        write(io, JSON.json(sanitize(obj); pretty = true))
    end
end

# ---------------------------------------------------------------- P8 --------
# Per-row moment functions at the fitted parameters as DRModels stores them
# (fit.means / fit.scales, which is exactly what _simulate_once draws from,
# src/gaussian_core.jl:2210-2334). Returns (η0, mv) with mv(i, η) -> (mean, var)
# for row i at mean-link value η (η0 = the stored, b = 0 value).
function moment_fns(fam::String, fit)
    M = fit.means; S = fit.scales
    if fam == "gaussian"
        σ = S[:sigma]; return M[:mu], (i, η) -> (η, σ[i]^2)
    elseif fam == "student"
        σ = S[:sigma]; ν = S[:nu]
        return M[:mu], (i, η) -> (η, ν[i] > 2 ? σ[i]^2 * ν[i] / (ν[i] - 2) : NaN)
    elseif fam == "skew_normal"
        σ = S[:sigma]; return M[:mu], (i, η) -> (η, σ[i]^2)
    elseif fam == "lognormal"
        σ = S[:sigma]
        return log.(M[:mu]), (i, η) -> (exp(η + σ[i]^2 / 2), (exp(σ[i]^2) - 1) * exp(2η + σ[i]^2))
    elseif fam == "gamma"
        σ = S[:sigma]; return log.(M[:mu]), (i, η) -> (exp(η), σ[i]^2 * exp(2η))
    elseif fam == "beta"
        φ = 1 ./ S[:sigma] .^ 2
        return logit.(M[:mu]), (i, η) -> (m = logistic(η); (m, m * (1 - m) / (1 + φ[i])))
    elseif fam == "zero_one_beta"
        φ = 1 ./ S[:sigma] .^ 2; z = S[:zoi]; c = S[:coi]
        return logit.(S[:beta_mu]), (i, η) -> begin
            μ = logistic(η); m = (1 - z[i]) * μ + z[i] * c[i]
            e2 = z[i] * c[i] + (1 - z[i]) * (μ * (1 - μ) / (1 + φ[i]) + μ^2)
            (m, e2 - m^2)
        end
    elseif fam == "beta_binomial"
        φ = 1 ./ S[:sigma] .^ 2; nt = S[:trials]
        return logit.(M[:mu]), (i, η) -> (μ = logistic(η); (nt[i] * μ, nt[i] * μ * (1 - μ) * (1 + (nt[i] - 1) / (φ[i] + 1))))
    elseif fam == "binomial"
        nt = S[:trials]
        return logit.(M[:mu]), (i, η) -> (μ = logistic(η); (nt[i] * μ, nt[i] * μ * (1 - μ)))
    elseif fam == "poisson"
        return log.(M[:mu]), (i, η) -> (exp(η), exp(η))
    elseif fam == "nbinom2"
        σ = S[:sigma]; return log.(M[:mu]), (i, η) -> (μ = exp(η); (μ, μ + σ[i]^2 * μ^2))
    elseif fam == "truncated_nbinom2"
        σ = S[:sigma]
        return log.(M[:mu]), (i, η) -> begin
            μ = exp(η); k = 1 / σ[i]^2; p0 = (k / (k + μ))^k
            m = μ / (1 - p0); (m, (μ + σ[i]^2 * μ^2 + μ^2) / (1 - p0) - m^2)
        end
    elseif fam == "tweedie"
        σ = S[:sigma]; p = S[:nu]
        return log.(M[:mu]), (i, η) -> (μ = exp(η); (μ, σ[i]^2 * μ^p[i]))
    elseif fam == "cumulative_logit"
        cuts = S[:ordinal_cuts]
        return copy(S[:ordinal_eta]), (i, η) -> begin
            p = cum_probs(η, cuts); K = length(p)
            m = sum(k * p[k] for k in 1:K); (m, sum(k^2 * p[k] for k in 1:K) - m^2)
        end
    end
    error("moment_fns: unknown family $fam")
end

# Expected per-row moments: b = 0 (sd = 0) or marginal over b ~ N(0, sd^2) by
# 64-node Gauss-Hermite (E = E_b m, Var = E_b v + Var_b m).
function expected_moments(fam::String, fit; sd::Float64 = 0.0)
    η0, mv = moment_fns(fam, fit)
    n = length(η0)
    E = zeros(n); V = zeros(n)
    if sd == 0.0
        for i in 1:n
            E[i], V[i] = mv(i, η0[i])
        end
    else
        xk, wk = gausshermite(64); wk = wk ./ sqrt(pi); bk = sqrt(2) * sd .* xk
        for i in 1:n
            m1 = 0.0; m2 = 0.0; vv = 0.0
            for k in eachindex(bk)
                m, v = mv(i, η0[i] + bk[k])
                m1 += wk[k] * m; m2 += wk[k] * m^2; vv += wk[k] * v
            end
            E[i] = m1; V[i] = vv + (m2 - m1^2)
        end
    end
    return E, V
end

# SPEC P8 statistics: global mean z, batch-means variance z, row diagnostics.
function p8_stats(Y::AbstractMatrix, E, V, nd)
    n, S = size(Y)
    G = vec(mean(Y; dims = 1))
    zmean = (mean(G) - mean(E)) / (std(G) / sqrt(S))
    B = 40; L = S ÷ B
    Vb = [mean(var(Y[:, (b-1)*L+1:b*L]; dims = 2)) for b in 1:B]
    zvar = all(isfinite, V) ? (mean(Vb) - mean(V)) / (std(Vb) / sqrt(B)) : NaN
    ybar = vec(mean(Y; dims = 2)); s = vec(std(Y; dims = 2))
    ok = s .> 0
    zi = (ybar[ok] .- E[ok]) ./ (s[ok] ./ sqrt(S))
    r = ybar .- E
    X = hcat(ones(n), Float64.(nd.x), Float64.(string.(nd.f) .== "b"), Float64.(string.(nd.f) .== "c"))
    β = X \ r; res = r .- X * β
    s2 = sum(abs2, res) / (n - size(X, 2))
    se = sqrt.(s2 .* diag(inv(X' * X)))
    t = β ./ se
    return Dict{String,Any}(
        "z_mean" => zmean, "z_var" => zvar,
        "mean_sim" => mean(G), "mean_expected" => mean(E),
        "var_sim_batchmean" => mean(Vb), "var_expected" => mean(V),
        "row_max_abs_z" => isempty(zi) ? NaN : maximum(abs.(zi)),
        "row_n_abs_z_gt3" => count(>(3), abs.(zi)),
        "row_n_expected_gt3" => n * 0.0027,
        "row_n_zero_sd" => count(!, ok),
        "reg_t_intercept" => t[1], "reg_t_x" => t[2], "reg_t_fb" => t[3], "reg_t_fc" => t[4],
        "reg_max_abs_t" => maximum(abs.(t[2:4])),
        "reg_flag_gt4" => maximum(abs.(t[2:4])) > 4,
    )
end
