# Supplementary: does open draft DRModels.jl PR #1106 (head ecb2dd87511385fdf7b5e497ca3d6678f67e0569,
# "#936: unit-free singular / boundary decision in the vcov guard"; it touches src/poisson.jl:532)
# change F8b? Not part of the repro.
# Tree prepared with:  git -C /home/user/DRModels.jl archive ecb2dd8 | tar -x -C <dir>; cp Manifest.toml <dir>/
# Run:  JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia --project=<dir> check_pr1106.jl
using DRModels, LinearAlgebra, Logging, Test, Printf
println("DRModels ", pkgversion(DRModels), " at ", pathof(DRModels), "  (PR #1106 head ecb2dd8); Julia ", VERSION)
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
datafile(r) = joinpath(@__DIR__, "..", "..", "data", @sprintf("pois_n8_lowmean_r%02d.csv", r))
for r in (3, 4, 6, 11, 21, 22, 32, 39, 48, 25, 27, 33, 38, 47)
    d = read_rcsv(datafile(r)); y, x = d.y, d.x
    lg = Test.TestLogger(min_level = Logging.Warn)
    fit = with_logger(() -> drm(bf(@formula(y ~ 1 + x)), Poisson(); data = (; y, x)), lg)
    chk = with_logger(() -> check_drm(fit), Test.TestLogger(min_level = Logging.Error))
    @printf("rep %2d  is_converged=%s niter=%2d logLik=%.6g coef=%s SE=%s chk_ok=%s nwarn=%d\n", r,
            is_converged(fit), niterations(fit), loglik(fit), string(round.(coef(fit), sigdigits = 5)),
            string(round.(stderror(fit), sigdigits = 3)), chk.ok, length(lg.logs))
    for l in lg.logs
        println("     warn: ", replace(string(l.message), '\n' => ' ')[1:min(end, 140)], "  ", Dict(pairs(l.kwargs)))
    end
end
