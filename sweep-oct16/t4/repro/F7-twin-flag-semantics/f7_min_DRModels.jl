# F7-twin-flag-semantics, minimal repro (DRModels.jl side). Reads the three CSVs written by
# f7_min_drmTMB.R (byte-identical to the lane's data/*.csv) and prints the Julia flag, the fit-time
# warnings and check_drm(fit).ok next to the logLik that drmTMB reached.
#   cd sweep-oct16/t4/repro/F7-twin-flag-semantics && JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia \
#     /home/user/jlenv/bin/julia --project=/home/user/DRModels.jl f7_min_DRModels.jl > f7_min_DRModels.out 2>&1
using DRModels, Logging, Test, Printf, InteractiveUtils
versioninfo()
println("DRModels ", pkgversion(DRModels), " git HEAD ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)), "\n")
function read_rcsv(path)
    ls = readlines(path); hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]
        isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, strip(v, '"'))); end
    end
    Dict(Symbol(h) => cols[j] for (j, h) in enumerate(hdr))
end
rd(nm) = read_rcsv(joinpath(@__DIR__, "f7_$(nm).csv"))
cases = [
  ("bin_quasi_r01", -3.2508297405,
   d -> drm(bf(@formula(y ~ 1 + x)), Binomial(); data = (; y = d[:y], x = d[:x]))),
  ("nb2_poisdata_r01", -192.7357893861,
   d -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), NegBinomial2(); data = (; y = d[:y], x = d[:x]))),
  ("collin_sigma_near_r01", -104.7262516860,
   d -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; y = d[:y], x = d[:x], z = d[:z]))),
]
for (nm, ll_R, f) in cases
    d = rd(nm)
    lg = Test.TestLogger(min_level = Logging.Warn)
    fit = with_logger(() -> f(d), lg)
    chk = with_logger(() -> check_drm(fit), NullLogger())
    println("==== ", nm, " ====")
    @printf("fit.converged (raw) = %s; is_converged = %s; check_drm(fit).ok = %s (vcov_posdef = %s)\n",
            fit.converged, is_converged(fit), chk.ok, chk.vcov_posdef)
    @printf("logLik = %.10f   (drmTMB: %.10f; diff %.2e)\n", loglik(fit), ll_R, loglik(fit) - ll_R)
    se = stderror(fit)
    for (i, (c, s)) in enumerate(zip(coef(fit), se)); @printf("  theta[%d] = % .6g  SE = %.6g\n", i, c, s); end
    println("fit-time @warn records: ", length(lg.logs))
    for r in lg.logs; println("  - ", first(replace(string(r.message), '\n' => ' '), 300)); end
    println()
end
