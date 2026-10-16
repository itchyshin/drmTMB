# F1-julia-aliased-sigma: census over the 50 reps of t4 cell 13 (collin_sigma_exact) and
# variants (exact duplicate column; aliasing in the mu formula; Poisson/Binomial fixed routes).
# Run from this directory:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl repro_census.jl > repro_census.out 2>&1
using DRModels, LinearAlgebra, InteractiveUtils, Logging, Test, Printf, Random
import Distributions   # a DRModels dependency; used only to simulate counts in part (e)

versioninfo()
println("DRModels ", pkgversion(DRModels), " at ", pathof(DRModels))
println("DRModels git HEAD: ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)))

function read_rcsv(path)
    ls = readlines(path)
    hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]
        isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, v)); end
    end
    NamedTuple{Tuple(Symbol.(hdr))}(Tuple(cols))
end
quiet(f) = (lg = Test.TestLogger(min_level = Logging.Warn); r = with_logger(f, lg); (r, lg.logs))
quietcheck(fit) = first(quiet(() -> with_logger(() -> check_drm(fit), Test.TestLogger(min_level = Logging.Error))))

function summarise(label, fits_and_logs, alias_idx)
    n = length(fits_and_logs)
    conv = count(((f, _),) -> is_converged(f), fits_and_logs)
    chks = [quietcheck(f) for (f, _) in fits_and_logs]
    ok = count(c -> c.ok, chks); pd = count(c -> c.vcov_posdef, chks)
    sing = count(((_, lg),) -> any(r -> occursin("numerically singular", string(r.message)), lg), fits_and_logs)
    flat_empty = count(((_, lg),) -> any(r -> occursin("numerically singular", string(r.message)) &&
                                          isempty(Dict(pairs(r.kwargs))[:flat_coordinates]), lg), fits_and_logs)
    se_fin = count(((f, _),) -> all(isfinite, stderror(f)[alias_idx]), fits_and_logs)
    sig = count(((f, _),) -> any(i -> 2 * (1 - Distributions.cdf(Distributions.Normal(), abs(coef(f)[i] / stderror(f)[i]))) < 0.05, alias_idx), fits_and_logs)
    mineig = [c.min_eigval for c in chks]
    @printf("%-44s n=%2d  is_converged=%2d  singular-warning=%2d (flat_coordinates empty in %2d)  finite SEs on aliased coefs=%2d  any aliased coef with Wald p<0.05=%2d  check_drm ok=%2d  vcov_posdef=%2d  min_eigval(V) in [%.1e, %.1e]\n",
            label, n, conv, sing, flat_empty, se_fin, sig, ok, pd, minimum(mineig), maximum(mineig))
end

ddir = joinpath(@__DIR__, "..", "..", "data")
dat = [read_rcsv(joinpath(ddir, @sprintf("collin_sigma_exact_r%02d.csv", r))) for r in 1:50]

println("\n(a) cell 13 as in the grid: sigma ~ 1 + x + z, z = 2x + 1 (CSV round-trip, |z-(2x+1)| <= ~1e-14)")
A = [quiet(() -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; d.y, d.x, d.z))) for d in dat]
summarise("sigma ~ 1 + x + z", A, [4, 5])
println("check_drm ok per rep: ", join([quietcheck(f).ok ? "T" : "F" for (f, _) in A]))
println("sigma:x / sigma:z estimates (reps 1-5): ", [round.(coef(f)[4:5]; digits = 4) for (f, _) in A[1:5]])
println("sigma:x / sigma:z SEs       (reps 1-5): ", [round.(stderror(f)[4:5]; digits = 4) for (f, _) in A[1:5]])

println("\n(c1) exact duplicate column in sigma: sigma ~ 1 + x + xdup, xdup = x (bitwise)")
C1 = [quiet(() -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + xdup)), Gaussian(); data = (; d.y, d.x, xdup = copy(d.x)))) for d in dat]
summarise("sigma ~ 1 + x + xdup", C1, [4, 5])
println("sigma:x / sigma:xdup estimates (reps 1-3): ", [round.(coef(f)[4:5]; digits = 4) for (f, _) in C1[1:3]])
println("sigma:x / sigma:xdup SEs       (reps 1-3): ", [round.(stderror(f)[4:5]; digits = 4) for (f, _) in C1[1:3]])

println("\n(c2) aliasing in the mu formula: y ~ 1 + x + z, sigma ~ 1 + x, z = 2x + 1")
C2 = [quiet(() -> drm(bf(@formula(y ~ 1 + x + z), @formula(sigma ~ 1 + x)), Gaussian(); data = (; d.y, d.x, d.z))) for d in dat]
summarise("y ~ 1 + x + z", C2, [1, 2, 3])
println("reps with max|coef| > 1e6 (start value Xmu \\ y on a numerically singular Xmu): ",
        count(((f, _),) -> maximum(abs, coef(f)) > 1e6, C2), " of 50")
println("mu coefs, rep 1: ", coef(C2[1][1])[1:3], "   logLik = ", loglik(C2[1][1]))
println("mu SEs (reps 1-3): ", [round.(stderror(f)[1:3]; digits = 4) for (f, _) in C2[1:3]])
println("first warning, rep 1: ", isempty(C2[1][2]) ? "(none)" : first(string(C2[1][2][1].message), 120), " ",
        isempty(C2[1][2]) ? "" : Dict(pairs(C2[1][2][1].kwargs)))

println("\n(c3) exact duplicate in mu: y ~ 1 + x + xdup, sigma ~ 1")
C3 = [quiet(() -> drm(bf(@formula(y ~ 1 + x + xdup), @formula(sigma ~ 1)), Gaussian(); data = (; d.y, d.x, xdup = copy(d.x)))) for d in dat]
summarise("y ~ 1 + x + xdup, sigma ~ 1", C3, [2, 3])

println("\n(e) other fixed-effect routes, same aliased designs (one dataset each, rep 1; seed 1 for simulated counts)")
d = dat[1]; Random.seed!(1)
yp = Float64.([rand(Distributions.Poisson(exp(0.5 + 0.3 * xi))) for xi in d.x])
yb = Float64.([rand() < 1 / (1 + exp(-(0.2 + 0.8 * xi))) for xi in d.x])
for (lab, thunk, idx) in (
        ("Poisson y ~ 1 + x + z",           () -> drm(bf(@formula(y ~ 1 + x + z)), Poisson(); data = (; y = yp, d.x, d.z)), [2, 3]),
        ("Binomial y ~ 1 + x + z",          () -> drm(bf(@formula(y ~ 1 + x + z)), Binomial(); data = (; y = yb, d.x, d.z)), [2, 3]),
        ("Gaussian REML sigma ~ 1 + x + z", () -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; d.y, d.x, d.z), method = :REML), [4, 5]))
    local f, lg
    (f, lg) = try quiet(thunk) catch e; (e, []) end
    if f isa Exception
        println(rpad(lab, 36), " ERROR: ", first(sprint(showerror, f), 200)); continue
    end
    ch = quietcheck(f)
    println(rpad(lab, 36), " is_converged=", is_converged(f), "  SE(aliased)=", round.(stderror(f)[idx]; digits = 4),
            "  check_drm ok=", ch.ok, "  warnings: ",
            isempty(lg) ? "(none)" : join([first(replace(string(r.message), '\n' => ' '), 90) * " " * string(Dict(pairs(r.kwargs))) for r in lg], " | "))
end
