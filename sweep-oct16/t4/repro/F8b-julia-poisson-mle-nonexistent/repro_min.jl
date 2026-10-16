# F8b-julia-poisson-mle-nonexistent: minimal repro (DRModels.jl, fixed-effect Poisson).
# sweep-oct16 / t4 cell 15 (pois_n8_lowmean): n = 8, x ~ N(0,1), y ~ Poisson(exp(-1.5 + 0.5 x)).
# Nominal seed = 20261016400 + 100*(15-1) + (rep-1); R seed = nominal %% 2^31.
# Two datasets:
#   rep 3  (R seed 933664970): all y = 0              -> MLE does not exist (intercept -> -Inf)
#   rep 27 (R seed 933664994): y = 2 at max(x), else 0 -> MLE does not exist (slope -> +Inf)
# Run from this directory:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl repro_min.jl > repro_min.out 2>&1
using DRModels, LinearAlgebra, InteractiveUtils, Logging, Test, Printf

versioninfo()
println("DRModels ", pkgversion(DRModels), " at ", pathof(DRModels))
println("DRModels git HEAD: ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)))

function read_rcsv(path)   # write.csv output: quoted header, numeric body
    ls = readlines(path)
    hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]
        isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, v)); end
    end
    NamedTuple{Tuple(Symbol.(hdr))}(Tuple(cols))
end
datafile(r) = joinpath(@__DIR__, "..", "..", "data", @sprintf("pois_n8_lowmean_r%02d.csv", r))

function fit_logged(y, x; fam = Poisson())
    lg = Test.TestLogger(min_level = Logging.Warn)
    fit = with_logger(() -> drm(bf(@formula(y ~ 1 + x)), fam; data = (; y, x)), lg)
    chk = with_logger(() -> check_drm(fit), Test.TestLogger(min_level = Logging.Error))
    return fit, lg.logs, chk
end
function report(label, fit, logs, chk)
    println("\n--- ", label)
    @printf("converged (raw) = %s   is_converged = %s   niterations = %d   logLik = %.12g\n",
            fit.converged, is_converged(fit), niterations(fit), loglik(fit))
    @printf("coef = %s\nSE   = %s\n", string(round.(coef(fit), sigdigits = 8)),
            string(round.(stderror(fit), sigdigits = 6)))
    println("check_drm: ok = ", chk.ok, ", max_abs_grad = ", chk.max_abs_grad,
            ", vcov_posdef = ", chk.vcov_posdef, ", min_eigval = ", chk.min_eigval)
    println("warnings emitted by drm(): ", length(logs))
    for l in logs
        println("  [", l.level, "] ", replace(string(l.message), '\n' => ' '))
        isempty(l.kwargs) || println("     kwargs: ", Dict(pairs(l.kwargs)))
    end
end

# ---------------------------------------------------------------- (A) all-zero response
d3 = read_rcsv(datafile(3)); y, x = d3.y, d3.x
println("\n=== (A) rep 3: y = ", Int.(y))
fitA, logsA, chkA = fit_logged(y, x)
report("drm(bf(@formula(y ~ 1 + x)), Poisson())", fitA, logsA, chkA)
θ0 = [log(sum(y) / length(y) + eps()), 0.0]          # src/poisson.jl:516 start value
println("start value theta0 = ", θ0, "   (log(eps()) = ", log(eps()), ")")
println("estimate == start value exactly: ", coef(fitA) == θ0)
g0 = [sum(exp.(θ0[1] .+ θ0[2] .* x) .- y), sum((exp.(θ0[1] .+ θ0[2] .* x) .- y) .* x)]
println("analytic nll gradient at the start = ", g0, "  (g_tol default 1e-8)")
println("recession direction d = (-1, 0): logLik(theta_hat + t d) for t = 0, 1, 10, 100:")
for t in (0.0, 1.0, 10.0, 100.0)
    @printf("   t = %5g  logLik = %.6e\n", t, -fitA.nll(coef(fitA) .+ t .* [-1.0, 0.0]))
end
println("sup logLik = 0 (all-zero Poisson); the reported intercept is log(eps()) only because the start is.")

# ---------------------------------------------------------------- (B) positives only at max(x)
d27 = read_rcsv(datafile(27)); y, x = d27.y, d27.x
k = argmax(x)
println("\n=== (B) rep 27: y = ", Int.(y), "; positive rows = ", findall(>(0), y),
        "; argmax(x) = ", k, " (x = ", x[k], ")")
fitB, logsB, chkB = fit_logged(y, x)
report("drm(bf(@formula(y ~ 1 + x)), Poisson())", fitB, logsB, chkB)
d = [-x[k], 1.0]                                     # keeps eta_k fixed, lowers every other eta
println("recession direction d = (-x_max, 1): logLik(theta_hat + t d) for t = 0, 10, 100:")
for t in (0.0, 10.0, 100.0)
    @printf("   t = %5g  logLik = %.12f  coef = %s\n", t, -fitB.nll(coef(fitB) .+ t .* d),
            string(round.(coef(fitB) .+ t .* d, sigdigits = 6)))
end
@printf("sup logLik = y_k log y_k - y_k - log y_k! = %.12f\n", y[k] * log(y[k]) - y[k] - log(factorial(Int(y[k]))))
se = stderror(fitB); b = coef(fitB)
@printf("Wald 95%% CI implied by the reported SEs: slope %.3f +/- %.3f; intercept %.3f +/- %.3f\n",
        b[2], 1.96 * se[2], b[1], 1.96 * se[1])

# ---------------------------------------------------------------- (C) same data, Binomial route
println("\n=== (C) the same two designs on the Binomial (Bernoulli) route, which runs the separation screen")
for (lab, dd) in (("rep 3 (all zero)", d3), ("rep 27 (1{y > 0})", d27))
    yb = Float64.(dd.y .> 0)
    fitC, logsC, chkC = fit_logged(yb, dd.x; fam = Binomial())
    report("Binomial, " * lab, fitC, logsC, chkC)
end
