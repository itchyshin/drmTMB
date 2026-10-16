# F4-r-student-ll-above-sup -- DRModels.jl on the same t4 student_gaussdata CSVs
# DRModels.jl pin f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
# Run from this directory:
#   JULIA_PKG_SERVER="" julia --project=<DRModels.jl checkout> repro_DRModels.jl > repro_DRModels.out 2>&1
using DRModels, Logging, Test, Printf, LinearAlgebra, InteractiveUtils

const DDIR = joinpath(@__DIR__, "..", "..", "data")
function read_rcsv(path)               # minimal reader for R write.csv output
    ls = readlines(path); hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]; isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, strip(v, '"'))); end
    end
    Dict(Symbol(h) => cols[j] for (j, h) in enumerate(hdr))
end
gauss_ml(y, x) = (X = [ones(length(x)) x]; r = y - X * (X \ y); n = length(y); -n / 2 * (log(2π * sum(abs2, r) / n) + 1))
# DRModels' own stable standardised Student log-density (src/student.jl:22-28) at given parameters
ll_jl(y, x, b0, b1, ls, eta) = sum(DRModels._student_logpdf_std((yi - b0 - b1 * xi) / exp(ls), eta) - ls for (yi, xi) in zip(y, x))

# drmTMB ca3ddef estimates (opt$par) on the same CSVs, copied from repro_drmTMB.out
const R_PAR = Dict(4  => (0.9287216383, 0.471546148, -0.01825985411, 15.37309648),
                   17 => (1.124565108, 0.5174527312, -0.01166537531, 14.2131327),
                   20 => (1.172521216, 0.6421648916, -0.04531454858, 14.78223428),
                   46 => (0.983465562, 0.3633570989, 0.05596305804, 14.81272985),
                   15 => (1.008564438, 0.2235815972, -0.2007231567, 120.7588921))

println("DRModels ", pkgversion(DRModels), " at ", pathof(DRModels))
println("DRModels git HEAD: ", strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)))
println()
@printf("%4s %10s %22s %22s %12s %10s %6s %s\n", "rep", "eta_nu", "logLik", "Gaussian ML", "diff", "converged", "nwarn", "first warning (truncated)")
res = Dict{Int,Float64}()
for r in 1:50
    d = read_rcsv(joinpath(DDIR, @sprintf("student_gaussdata_r%02d.csv", r))); y = d[:y]; x = d[:x]
    lg = Test.TestLogger(min_level = Logging.Warn)
    fit = with_logger(lg) do
        drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1), @formula(nu ~ 1)), Student(); data = (; y, x))
    end
    g = gauss_ml(y, x); ll = loglik(fit); res[r] = ll - g
    w = isempty(lg.logs) ? "" : first(replace(string(lg.logs[1].message), '\n' => ' '), 70)
    @printf("%4d %10.4f %22.12f %22.12f %+12.3e %10s %6d %s\n", r, coef(fit)[end], ll, g, ll - g, is_converged(fit), length(lg.logs), w)
end
bnd = [r for r in 1:50 if res[r] < 1e-6]   # Student optimum == Gaussian limit
println("\nreps whose DRModels Student logLik is within 1e-6 of the Gaussian ML (boundary): ", length(bnd))
println("max (logLik - Gaussian ML) over those: ", @sprintf("%+.3e", maximum(res[r] for r in bnd)),
        "   min: ", @sprintf("%+.3e", minimum(res[r] for r in bnd)))

println("\nDRModels' stable Student kernel evaluated at drmTMB's own estimates (same CSV):")
for r in (4, 17, 20, 46, 15)
    d = read_rcsv(joinpath(DDIR, @sprintf("student_gaussdata_r%02d.csv", r))); y = d[:y]; x = d[:x]
    v = ll_jl(y, x, R_PAR[r]...)
    @printf("rep %2d: eta_nu=%9.4f  ll_DRModels_kernel(theta_drmTMB) - Gaussian ML = %+.3e\n", r, R_PAR[r][4], v - gauss_ml(y, x))
end
println()
versioninfo()
