# Skeptic re-check of F1 claims (DRModels.jl f71b292). Run from this directory:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl skeptic_checks.jl > skeptic_checks.out 2>&1
using DRModels, LinearAlgebra, Logging, Test, Printf, InteractiveUtils
versioninfo()
println("DRModels ", pkgversion(DRModels), " ", strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)))
function read_rcsv(path)
    ls = readlines(path); hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]; isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, v)); end; end
    NamedTuple{Tuple(Symbol.(hdr))}(Tuple(cols))
end
q(f) = with_logger(f, Test.TestLogger(min_level = Logging.Error))
ddir = joinpath(@__DIR__, "..", "..", "..", "data")
dat = [read_rcsv(joinpath(ddir, @sprintf("collin_sigma_exact_r%02d.csv", r))) for r in 1:50]

println("\n[1] cell 13: does check_drm ok track the SIGN of min_eigval(V)?")
rows = []
for (r, d) in enumerate(dat)
    f = q(() -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; d.y, d.x, d.z)))
    c = q(() -> check_drm(f))
    V = vcov(f); chol_ok = isposdef(Symmetric(V)); me = minimum(eigvals(Symmetric(V)))
    push!(rows, (r, is_converged(f), c.ok, c.vcov_posdef, chol_ok, me, c.cond))
end
println("is_converged: ", count(r -> r[2], rows), "/50; ok: ", count(r -> r[3], rows), "/50")
tab = Dict{Tuple{Bool,Bool},Int}()
for r in rows; k = (r[6] > 0, r[3]); tab[k] = get(tab, k, 0) + 1; end
println("(min_eigval > 0, ok) counts: ", sort(collect(tab)))
println("cond when ok = true: ", [@sprintf("%.1e", r[7]) for r in rows if r[3]][1:min(8, end)])

println("\n[2] mu alias y ~ 1 + x + z, sigma ~ 1 + x: raw converged vs huge coefs vs logLik above reduced")
n_huge = 0; n_huge_conv = 0; n_above = 0; n_conv = 0; above_reps = Int[]
for (r, d) in enumerate(dat)
    f = q(() -> drm(bf(@formula(y ~ 1 + x + z), @formula(sigma ~ 1 + x)), Gaussian(); data = (; d.y, d.x, d.z)))
    red = q(() -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = (; d.y, d.x)))
    huge = maximum(abs, coef(f)) > 1e6
    global n_huge += huge; global n_huge_conv += huge && is_converged(f); global n_conv += is_converged(f)
    if loglik(f) > loglik(red) + 1e-6; global n_above += 1; push!(above_reps, r); end
end
println("huge coefs: $n_huge; huge AND is_converged: $n_huge_conv; is_converged: $n_conv; logLik > reduced + 1e-6: $n_above  reps=$above_reps")

println("\n[3] REML, xdup in sigma (rep 1)")
d = dat[1]
try
    q(() -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + xdup)), Gaussian(); data = (; d.y, d.x, xdup = copy(d.x)), method = :REML))
    println("no error")
catch e
    println("ERROR: ", first(sprint(showerror, e), 200))
end
try
    q(() -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; d.y, d.x, d.z), method = :REML))
    println("no error")
catch e
    println("ERROR (z alias): ", first(sprint(showerror, e), 200))
    bt = catch_backtrace(); st = stacktrace(bt)
    println("  top DRModels frames: ", [string(s.file, ":", s.line) for s in st if occursin("DRModels", string(s.file))][1:min(3, end)])
end

println("\n[4] exact alias built in Julia (no CSV rounding): z = 2x .+ 1, rep 1 y/x")
z = 2 .* d.x .+ 1
println("svdvals [1 x z] = ", svdvals(hcat(ones(100), d.x, z)), "; rank (default) = ", rank(hcat(ones(100), d.x, z)))
f = q(() -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; d.y, d.x, z)))
println("is_converged = ", is_converged(f), "; SE = ", round.(stderror(f); digits = 4))

println("\n[5] scaled duplicate xdup = 1000x: individual SE changes with an arbitrary rescale of the aliased column")
f2 = q(() -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + xk)), Gaussian(); data = (; d.y, d.x, xk = 1000 .* d.x)))
println("is_converged = ", is_converged(f2), "; coef sigma = ", coef(f2)[3:5], "; SE = ", stderror(f2)[3:5])
