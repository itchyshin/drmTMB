# Where does the Gaussian REML route fail on the aliased sigma design? (rep 1, DRModels.jl f71b292)
using DRModels, Logging, Test
function read_rcsv(path)
    ls = readlines(path); hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]; isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, v)); end; end
    NamedTuple{Tuple(Symbol.(hdr))}(Tuple(cols))
end
d = read_rcsv(joinpath(@__DIR__, "..", "..", "..", "data", "collin_sigma_exact_r01.csv"))
try
    with_logger(() -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; d.y, d.x, d.z), method = :REML), Test.TestLogger(min_level = Logging.Error))
catch e
    println(sprint(showerror, e)[1:min(end, 120)])
    for s in stacktrace(catch_backtrace())
        f = string(s.file)
        (occursin("DRModels", f) || occursin("LineSearches", f) || occursin("Optim", f)) && println("  ", s.func, " @ ", basename(f), ":", s.line)
    end
end
