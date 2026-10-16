# Supplementary: does open draft DRModels.jl PR #1106 (head ecb2dd87511385fdf7b5e497ca3d6678f67e0569,
# "#936: unit-free singular / boundary decision in the vcov guard") change F1? Not part of the repro.
# Tree prepared with:  git -C /home/user/DRModels.jl archive ecb2dd8 | tar -x -C <dir>; cp Manifest.toml <dir>/
# Run:  JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia --project=<dir> check_pr1106.jl
using DRModels, LinearAlgebra, Logging, Test, Printf
println("DRModels ", pkgversion(DRModels), " at ", pathof(DRModels), "  (PR #1106 head ecb2dd8)")
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
d = read_rcsv(joinpath(@__DIR__, "..", "..", "data", "collin_sigma_exact_r01.csv"))
full = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; d.y, d.x, d.z))
println("is_converged = ", is_converged(full))
show(stdout, MIME("text/plain"), coeftable(full)); println()
ok = 0
for r in 1:50
    dd = read_rcsv(joinpath(@__DIR__, "..", "..", "data", @sprintf("collin_sigma_exact_r%02d.csv", r)))
    lg = Test.TestLogger(min_level = Logging.Warn)
    f = with_logger(() -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; dd.y, dd.x, dd.z)), lg)
    c = with_logger(() -> check_drm(f), Test.TestLogger(min_level = Logging.Error))
    global ok += c.ok
end
println("check_drm ok over 50 reps: ", ok)
