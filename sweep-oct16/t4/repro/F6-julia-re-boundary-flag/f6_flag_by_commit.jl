# F6-julia-re-boundary-flag: `converged` on the 50 re_sd1e-4 datasets, run against whichever
# DRModels.jl checkout is the active project. Used for main f71b292 and for draft PR #1044's head
# ef77368 (a detached worktree of refs/pull/1044/head with main's Manifest.toml copied in; no Pkg ops).
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=<DRModels.jl checkout> f6_flag_by_commit.jl > f6_flag_<label>.out 2>&1
using DRModels, Printf, Logging, InteractiveUtils
println("DRModels ", pkgversion(DRModels), " at ", pathof(DRModels), "\ngit HEAD ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)), "  Julia ", VERSION)
function read_rcsv(path)
    ls = readlines(path)
    hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]
        isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, strip(v, '"'))); end
    end
    Dict(Symbol(h) => cols[j] for (j, h) in enumerate(hdr))
end
const DDIR = joinpath(@__DIR__, "..", "..", "data")
lm_ll(y, X) = (r = y - X * (X \ y); n = length(y); -n / 2 * (log(2π * sum(abs2, r) / n) + 1))
nb = 0; nbt = 0; nit = 0; ni = 0; reps_false = Int[]
for r in 1:50
    d = read_rcsv(joinpath(DDIR, @sprintf("re_sd1e-4_r%02d.csv", r)))
    f = with_logger(NullLogger()) do
        drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
            data = (; y = d[:y], x = d[:x], g = string.("g", Int.(d[:g]))))
    end
    bnd = f.loglik - lm_ll(d[:y], [ones(length(d[:y])) d[:x]]) < 1e-6
    if bnd
        global nb += 1; global nbt += is_converged(f)
        is_converged(f) || push!(reps_false, r)
    else
        global ni += 1; global nit += is_converged(f)
    end
end
println("boundary datasets: $nb, is_converged = true on $nbt;  interior datasets: $ni, is_converged = true on $nit")
println("boundary reps with is_converged = false: ", reps_false)
