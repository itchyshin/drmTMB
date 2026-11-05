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

# Prepared only. Initial four-seed probe; no calibration or repair claim.
root = get(ENV, "DRM_JL_PATH", pwd())
pinned_fixture(root, "test/test_nb2_animal_sd_regression.jl",
    "fa26fdbd9844b6ab2fe86271da35db74573b12eff7eb6ca2f1eba6934db9b786",
    "function _nb2_animal_sd_fixture", "@testset")
alpha = [-0.65, 0.4]
emit("kind", "seed", "route", "status", "converged", "stored_nll", "current_nll",
     "stored_current_delta", "mu", "sigma", "sd_or_resd", "gradient", "constant_minus_plain_nll", "error")
for seed in (isempty(ARGS) ? collect(20261022:20261025) : parse.(Int, ARGS))
    data, R, zgroup, fit_levels, ignored = _nb2_animal_sd_fixture(alpha; seed)
    scale = collect(range(0.7, 1.8; length=length(zgroup)))
    A = Diagonal(scale) * R * Diagonal(scale)
    plain = bf(@formula(y ~ x + animal(1 | g)), @formula(sigma ~ 1))
    constant = bf(@formula(y ~ x + animal(1 | g)), @formula(sigma ~ 1),
                  @formula(sd(g, animal) ~ 1))
    fits = Dict{String,Any}()
    for (route, form) in (("plain", plain), ("constant_sd", constant))
        try
            fit = drm(form, NegBinomial2(); data, A, se=false)
            fits[route] = fit
            stored = -fit.loglik
            current = current_nll(fit)
            emit("fit", seed, route, "returned", fit.converged, stored, current,
                 ismissing(current) ? missing : stored-current,
                 block(fit, :mu), block(fit, :sigma),
                 block(fit, route == "plain" ? :resd : :sd),
                 diagnostic(fit, (:gradient, :grad, :final_grad, :gradient_norm)), "", "")
        catch err
            emit("fit", seed, route, "error", "", "", "", "", "", "", "", "", "",
                 sprint(showerror, err, catch_backtrace()))
        end
    end
    if haskey(fits, "plain") && haskey(fits, "constant_sd")
        delta = -fits["constant_sd"].loglik + fits["plain"].loglik
        emit("comparison", seed, "constant_sd_vs_plain", "both_returned", "", "", "", "", "", "", "", "", delta, "")
    else
        emit("comparison", seed, "constant_sd_vs_plain", "incomplete", "", "", "", "", "", "", "", "", "", "one or both fits failed")
    end
end
