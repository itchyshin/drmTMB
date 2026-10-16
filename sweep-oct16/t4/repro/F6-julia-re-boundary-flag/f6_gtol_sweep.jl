# F6-julia-re-boundary-flag: how the flag on the 29 boundary datasets (sweep-oct16 t4, re_sd1e-4) depends on
# `g_tol`, including the docs' advice for a non-converged fit ("tighten the gradient tolerance", convergence.md:58-66).
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl f6_gtol_sweep.jl > f6_gtol_sweep.out 2>&1
using DRModels, Printf, Logging
println("DRModels ", pkgversion(DRModels), " git HEAD ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)), "  Julia ", VERSION)
function read_rcsv(path)
    ls = readlines(path); hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]
        isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, strip(v, '"'))); end
    end
    Dict(Symbol(h) => cols[j] for (j, h) in enumerate(hdr))
end
const DDIR = joinpath(@__DIR__, "..", "..", "data")
lm_ll(y, X) = (r = y - X * (X \ y); n = length(y); -n / 2 * (log(2π * sum(abs2, r) / n) + 1))
tols = (1e-10, 1e-9, 1e-8, 1e-7, 1e-6)
cnt = Dict(t => 0 for t in tols); maxdll = Dict(t => 0.0 for t in tols); nb = 0
for r in 1:50
    d = read_rcsv(joinpath(DDIR, @sprintf("re_sd1e-4_r%02d.csv", r)))
    data = (; y = d[:y], x = d[:x], g = string.("g", Int.(d[:g])))
    llm = lm_ll(d[:y], [ones(length(d[:y])) d[:x]])
    f8 = with_logger(NullLogger()) do; drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian(); data) end
    f8.loglik - llm < 1e-6 || continue
    global nb += 1
    for t in tols
        f = with_logger(NullLogger()) do
            drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian(); data, g_tol = t)
        end
        cnt[t] += is_converged(f); maxdll[t] = max(maxdll[t], abs(f.loglik - llm))
    end
end
println("boundary datasets: $nb")
for t in tols
    @printf("g_tol = %.0e : is_converged = true on %2d of %d;  max |logLik - lm logLik| = %.1e\n", t, cnt[t], nb, maxdll[t])
end
