using DRModels, StableRNGs, Random, LinearAlgebra, SHA
import Distributions

function pinned_fixture(root, relative, expected, startmarker, endmarker)
    path = joinpath(root, relative)
    bytes = read(path)
    actual = bytes2hex(sha256(bytes))
    actual == expected || error("fixture source hash changed: $relative: $actual")
    text = String(bytes)
    first = findfirst(startmarker, text)
    first === nothing && error("missing fixture start")
    rest = SubString(text, first.start)
    last = findfirst(endmarker, rest)
    last === nothing && error("missing fixture end")
    include_string(Main, String(rest[1:prevind(rest, last.start)]), path)
end
clean(x) = replace(string(x), '\t' => ' ', '\n' => ' ', '\r' => ' ')
function emit(values...)
    println(join(clean.(values), '\t')); flush(stdout)
end
function diagnostic(fit, names)
    for name in names
        hasproperty(fit, name) && return getproperty(fit, name)
    end
    return "unavailable"
end
function current_nll(fit)
    hasproperty(fit, :nll) || return missing
    getproperty(fit, :nll)(fit.theta)
end
function block(fit, name)
    try
        return join(coef(fit, name), ',')
    catch err
        return "unavailable: " * sprint(showerror, err)
    end
end

# Locator probe only: retained scalar q1 fixture, NOT identified as the inherited -26.9 case.
root = get(ENV, "DRM_JL_PATH", pwd())
pinned_fixture(root, "test/test_binomial_sd_regression.jl",
    "3f830788bd26e858886769e917c48209060c9cf8205467037f43bbc0f6b2beba",
    "function _binomial_sd_fixture", "@testset")
emit("seed", "route", "status", "converged", "sd_coefficients", "gradient", "stored_nll",
     "current_nll", "stored_current_delta", "minimum_log_sd", "maximum_log_sd",
     "max_abs_clamped_vs_exp", "max_abs_log_clamp_delta", "historical_case_status", "error")
try
    data, alpha = _binomial_sd_fixture()
    form = bf(@formula(cbind(s, fail) ~ x + (1 | g)), @formula(sd(g) ~ z))
    fit = drm(form, Binomial(); data)
    sdcoef = coef(fit, :sd)
    eta = sdcoef[1] .+ sdcoef[2] .* [zeros(14); ones(14)]
    # Report the exact route's current guard without changing its thresholds.
    clamped = DRModels._binomial_sd_scale.(eta)
    unclamped = exp.(eta)
    current = current_nll(fit)
    stored = -fit.loglik
    emit(20261017, "scalar_q1", "returned", fit.converged, join(sdcoef, ','),
         diagnostic(fit, (:gradient, :grad, :final_grad, :gradient_norm)), stored, current,
         ismissing(current) ? missing : stored-current, minimum(eta), maximum(eta),
         maximum(abs.(clamped .- unclamped)), maximum(abs.(log.(clamped) .- eta)),
         "locator_only_not_bound_to_historical_minus26.9", "")
catch err
    emit(20261017, "scalar_q1", "error", "", "", "", "", "", "", "", "", "", "",
         "locator_only_not_bound_to_historical_minus26.9", sprint(showerror, err, catch_backtrace()))
end
