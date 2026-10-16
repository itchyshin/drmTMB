# F3-r-complete-separation: DRModels.jl census over the same 100 CSVs
# (cells bin_complete k = 7 and bin_quasi k = 8, 50 seeds each).
# Run from this directory:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl census_DRModels.jl > census_DRModels.out 2>&1
using DRModels, Logging, Test, InteractiveUtils, Printf
versioninfo()
println("DRModels ", pkgversion(DRModels))

function read_rcsv(path)   # minimal reader for R write.csv output (numeric columns)
    ls = readlines(path)
    hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]
        isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, strip(v, '"'))); end
    end
    Dict(Symbol(h) => cols[j] for (j, h) in enumerate(hdr))
end

rows = NamedTuple[]
for cell in ("bin_complete", "bin_quasi"), r in 1:50
    d = read_rcsv(joinpath(@__DIR__, "..", "..", "data", @sprintf("%s_r%02d.csv", cell, r)))
    y = d[:y]; x = d[:x]
    lg = Test.TestLogger(min_level = Logging.Warn)
    fit = with_logger(() -> drm(bf(@formula(y ~ 1 + x)), Binomial(); data = (; y, x)), lg)
    sepw = filter(l -> haskey(Dict(pairs(l.kwargs)), :separation), lg.logs)
    flagged = isempty(sepw) ? "" : join(Dict(pairs(sepw[1].kwargs))[:flagged_coefficients], "+")
    se = stderror(fit)
    push!(rows, (; cell, r, n_warn = length(lg.logs), sep_warn = !isempty(sepw), flagged,
                 raw = fit.converged, conv = is_converged(fit), ll = loglik(fit),
                 bx = coef(fit)[2], n_inf = count(!isfinite, se)))
end

for cell in ("bin_complete", "bin_quasi")
    s = filter(t -> t.cell == cell, rows)
    println("\n== ", cell, " (50 seeds) ==")
    println("separation warning: ", count(t -> t.sep_warn, s), " ; flagged sets: ",
            Dict(f => count(t -> t.flagged == f, s) for f in unique(getfield.(s, :flagged))))
    println("fit.converged true: ", count(t -> t.raw, s), " ; is_converged(fit) true: ", count(t -> t.conv, s))
    println("non-finite SEs per fit: ", Dict(k => count(t -> t.n_inf == k, s) for k in unique(getfield.(s, :n_inf))))
    println("logLik range: ", extrema(getfield.(s, :ll)), " ; slope range: ", extrema(getfield.(s, :bx)))
end
open(joinpath(@__DIR__, "census_DRModels.csv"), "w") do io
    println(io, "cell,rep,n_warn,sep_warn,flagged,fit_converged,is_converged,logLik,b_x,n_se_nonfinite")
    for t in rows
        println(io, join((t.cell, t.r, t.n_warn, t.sep_warn, t.flagged, t.raw, t.conv, t.ll, t.bx, t.n_inf), ","))
    end
end
