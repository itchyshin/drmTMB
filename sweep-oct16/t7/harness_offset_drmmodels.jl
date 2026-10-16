# t7 native DRModels.jl offset log-2 shift at pin f71b292.
# Hard timeout is applied by the calling `timeout` wrapper.

using DRModels
using DelimitedFiles
using Random
using Statistics

const ROOT = "sweep-oct16/t7"
const LOG2 = log(2.0)
const PASS_BAR = 1e-8
const OUT = joinpath(ROOT, "results_offset_drmmodels.csv")

function read_csv(path)
    raw, hdr = readdlm(path, ',', header=true)
    hdr = String.(vec(hdr))
    col(name) = raw[:, findfirst(==(name), hdr)]
    y = Float64.(col("y"))
    x = Float64.(col("x"))
    off = Float64.(col("off"))
    g = string.(col("g"))
    return (; y, x, off, g)
end

function named(d; off = d.off)
    return (; y = d.y, x = d.x, off = off, g = d.g)
end

function intercept_and_names(fit)
    # First μ block; names live on fit.coef_names when present.
    θ = fit.theta
    nms = try
        String.(fit.coef_names)
    catch
        ["θ$i" for i in eachindex(θ)]
    end
    return θ, nms
end

function loglik_of(fit)
    try
        return loglik(fit)
    catch
        return fit.loglik
    end
end

open(OUT, "w") do io
    println(io, "family,re,dpar,syntax,engine,status,intercept_base,intercept_shift,intercept_delta,expected,abs_err,slope_max_diff,loglik_base,loglik_shift,loglik_delta,has_offset_coef,elapsed_s,note")
end

function append_row(io_fields...)
    open(OUT, "a") do io
        println(io, join(io_fields, ","))
    end
    println("[", time(), "] ", io_fields[1], " re=", io_fields[2], " dpar=", io_fields[3],
            " syn=", io_fields[4], " -> ", io_fields[6], " ", io_fields[end])
    flush(stdout)
end

function csv_escape(s)
    s = replace(string(s), "\n" => " ", "," => " ")
    return "\"" * s * "\""
end

families = ["poisson", "nbinom2", "gamma"]
res = ["fe", "re"]
dpars = ["mu", "sigma"]
syntaxes = ["formula", "offset_arg"]

fam_ctor = Dict(
    "poisson" => () -> Poisson(),
    "nbinom2" => () -> NegBinomial2(),
    "gamma" => () -> Gamma(),
)

function make_form(family, re, dpar, syntax)
    re_term = re == "re" ? " + (1|g)" : ""
    if syntax == "offset_arg"
        # keyword offset= on drm(); mean formula has no offset()
        if family == "poisson" && dpar == "mu"
            return :(bf(@formula(y ~ 1 + x $(Meta.parse(re_term)))))
        elseif dpar == "sigma"
            return :(bf(@formula(y ~ 1 + x $(Meta.parse(re == "re" ? "+ (1|g)" : ""))), @formula(sigma ~ 1)))
        else
            return :(bf(@formula(y ~ 1 + x $(Meta.parse(re_term))), @formula(sigma ~ 1)))
        end
    else
        if dpar == "mu"
            if family == "poisson"
                rhs = re == "re" ? :(y ~ 1 + x + offset(off) + (1|g)) : :(y ~ 1 + x + offset(off))
                return :(bf(@formula($rhs)))
            else
                rhs = re == "re" ? :(y ~ 1 + x + offset(off) + (1|g)) : :(y ~ 1 + x + offset(off))
                return :(bf(@formula($rhs), @formula(sigma ~ 1)))
            end
        else
            mu_rhs = re == "re" ? :(y ~ 1 + x + (1|g)) : :(y ~ 1 + x)
            return :(bf(@formula($mu_rhs), @formula(sigma ~ 1 + offset(off))))
        end
    end
end

# Build formulas as quoted bf() calls via strings, which is more reliable.
function form_string(family, re, dpar, syntax)
    re_term = re == "re" ? " + (1|g)" : ""
    if syntax == "offset_arg"
        if family == "poisson" && dpar == "mu"
            return "bf(@formula(y ~ 1 + x$re_term))"
        else
            return "bf(@formula(y ~ 1 + x$re_term), @formula(sigma ~ 1))"
        end
    elseif dpar == "mu"
        if family == "poisson"
            return "bf(@formula(y ~ 1 + x + offset(off)$re_term))"
        else
            return "bf(@formula(y ~ 1 + x + offset(off)$re_term), @formula(sigma ~ 1))"
        end
    else
        return "bf(@formula(y ~ 1 + x$re_term), @formula(sigma ~ 1 + offset(off)))"
    end
end

for family in families
    d = read_csv(joinpath(ROOT, "data_offset_$(family).csv"))
    for re in res, dpar in dpars, syntax in syntaxes
        ftxt = form_string(family, re, dpar, syntax)
        note = ""
        status = "ERROR"
        int1 = NaN; int2 = NaN; delta = NaN; abs_err = NaN
        slope_diff = NaN; ll1 = NaN; ll2 = NaN; ll_delta = NaN
        has_off = false
        elapsed = NaN
        t0 = time()
        try
            form = eval(Meta.parse(ftxt))
            fam = fam_ctor[family]()
            d1 = named(d)
            d2 = named(d; off = d.off .+ LOG2)
            if syntax == "offset_arg"
                fit1 = drm(form, fam; data = d1, offset = d1.off)
                fit2 = drm(form, fam; data = d2, offset = d2.off)
            else
                fit1 = drm(form, fam; data = d1)
                fit2 = drm(form, fam; data = d2)
            end
            elapsed = time() - t0
            θ1, nms1 = intercept_and_names(fit1)
            θ2, nms2 = intercept_and_names(fit2)
            has_off = any(occursin("offset", lowercase(n)) for n in nms1)
            # intercept is the first coefficient of the μ block; fall back to θ[1]
            int1 = Float64(θ1[1])
            int2 = Float64(θ2[1])
            delta = int1 - int2
            abs_err = abs(delta - LOG2)
            if length(θ1) >= 2 && length(θ2) >= 2
                slope_diff = maximum(abs.(θ1[2:end] .- θ2[2:end]))
            else
                slope_diff = 0.0
            end
            ll1 = Float64(loglik_of(fit1))
            ll2 = Float64(loglik_of(fit2))
            ll_delta = ll1 - ll2
            note = "coefs=" * join(nms1, "|")
            if has_off
                status = "FAIL"
                note *= " SILENT_OFFSET_COEF"
            elseif abs_err < PASS_BAR && abs(ll_delta) < 1e-6
                status = "PASS"
            else
                status = "FAIL"
            end
        catch e
            elapsed = time() - t0
            msg = sprint(showerror, e)
            note = csv_escape(msg)
            if occursin("offset", lowercase(msg)) || occursin("MethodError", msg) || occursin("unsupported", lowercase(msg)) || occursin("ArgumentError", msg)
                status = "REFUSED"
            else
                status = "ERROR"
            end
        end
        append_row(family, re, dpar, syntax, "drmmodels", status,
                   int1, int2, delta, LOG2, abs_err, slope_diff, ll1, ll2, ll_delta,
                   has_off, elapsed, note)
    end
end

println("wrote ", OUT)
