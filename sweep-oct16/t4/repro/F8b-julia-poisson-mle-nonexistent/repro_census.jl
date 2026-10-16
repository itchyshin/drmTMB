# F8b-julia-poisson-mle-nonexistent: census + feasibility of reusing the Binomial separation screen.
# (a) all 50 reps of t4 cell 15 (pois_n8_lowmean): DRModels status vs the data's MLE existence;
# (b) the existing Binomial screen DRModels._detect_separation (src/separation.jl), fed the Poisson
#     existence condition (Santos Silva & Tenreyro 2010): rows with y > 0 must satisfy x'd = 0,
#     rows with y = 0 must satisfy x'd <= 0. In the screen's encoding that is s = 1{y > 0},
#     ntr = 1 + s (a row with 0 < s < ntr contributes both +x and -x, i.e. an equality);
#     checked on the 50 lowmean reps and, as negatives, on the 150 reps of cells 4-6 (pois_n8/12/20);
# (c) a factor with an all-zero level (the common applied form of the same defect);
# (d) scope probes: the all-zero response on the Poisson (1|g) and offset routes.
# Run from this directory:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl repro_census.jl > repro_census.out 2>&1
using DRModels, LinearAlgebra, InteractiveUtils, Logging, Test, Printf, Random

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
datafile(cell, r) = joinpath(@__DIR__, "..", "..", "data", @sprintf("%s_r%02d.csv", cell, r))
quietly(f) = (lg = Test.TestLogger(min_level = Logging.Warn); r = with_logger(f, lg); (r, lg.logs))
quietcheck(fit) = with_logger(() -> check_drm(fit), Test.TestLogger(min_level = Logging.Error))

# Ground truth for one-covariate Poisson y ~ 1 + x (n distinct x): the MLE fails to exist iff
# all y = 0, or every positive count sits at the minimum x or every one at the maximum x
# (then a recession direction keeps those rows' eta fixed and lowers all the others).
function mle_exists_1x(y, x)
    pos = findall(>(0), y)
    isempty(pos) && return false
    all(x[pos] .== maximum(x)) && return false
    all(x[pos] .== minimum(x)) && return false
    return true
end
poisson_screen(X, y) = (s = Float64.(y .> 0); DRModels._detect_separation(X, s, 1 .+ s))

# ---------------------------------------------------------------- (a) + (b) lowmean cell
println("\n=== (a)+(b) cell pois_n8_lowmean, 50 reps")
@printf("%4s %-12s %6s %6s %5s %9s %22s %22s %5s %6s %-28s\n", "rep", "data", "exists", "isconv",
        "niter", "logLik", "coef", "SE", "nwarn", "chk_ok", "Poisson-mapped screen")
tab = Dict{Tuple{Bool,Bool,Bool},Int}()
for r in 1:50
    d = read_rcsv(datafile("pois_n8_lowmean", r)); y, x = d.y, d.x
    kind = all(==(0), y) ? "all-zero" : (mle_exists_1x(y, x) ? "interior" : "pos@extreme")
    ex = mle_exists_1x(y, x)
    fit, logs = quietly(() -> drm(bf(@formula(y ~ 1 + x)), Poisson(); data = (; y, x)))
    chk = quietcheck(fit)
    scr = poisson_screen(hcat(ones(length(x)), x), y)
    key = (ex, scr.separated, isempty(logs))
    tab[key] = get(tab, key, 0) + 1
    @printf("%4d %-12s %6s %6s %5d %9.4g %22s %22s %5d %6s %-28s\n", r, kind, ex, is_converged(fit),
            niterations(fit), loglik(fit), string(round.(coef(fit), sigdigits = 4)),
            string(round.(stderror(fit), sigdigits = 3)), length(logs), chk.ok,
            "sep=$(scr.separated) flag=$(scr.flagged) concl=$(scr.conclusive)")
end
println("\ncounts by (MLE exists, screen says separated, drm() silent):")
for (k, v) in sort(collect(tab)); println("  ", k, " => ", v); end

println("\n=== (b') negatives: Poisson-mapped screen on cells pois_n8 / pois_n12 / pois_n20 (150 reps)")
for cell in ("pois_n8", "pois_n12", "pois_n20")
    nflag = 0; nex = 0
    for r in 1:50
        d = read_rcsv(datafile(cell, r))
        nex += mle_exists_1x(d.y, d.x)
        nflag += poisson_screen(hcat(ones(length(d.x)), d.x), d.y).separated
    end
    println("  ", cell, ": MLE exists in ", nex, "/50; screen flags ", nflag, "/50")
end

# ---------------------------------------------------------------- (c) factor with an all-zero level
println("\n=== (c) y ~ f with level \"c\" all zero (n = 60, StableRNG-free: MersenneTwister(20261016))")
rng = MersenneTwister(20261016)
f = repeat(["a", "b", "c"], inner = 20)
yf = [fi == "c" ? 0.0 : Float64(rand(rng, 0:4)) for fi in f]
fitf, logsf = quietly(() -> drm(bf(@formula(yf ~ f)), Poisson(); data = (; yf, f)))
chkf = quietcheck(fitf)
@printf("is_converged = %s  niter = %d  logLik = %.10g\n", is_converged(fitf), niterations(fitf), loglik(fitf))
println("coef = ", round.(coef(fitf), sigdigits = 6), "\nSE   = ", round.(stderror(fitf), sigdigits = 6))
println("check_drm ok = ", chkf.ok, "; warnings: ", length(logsf))
for l in logsf; println("  ", replace(string(l.message), '\n' => ' ')[1:min(end, 160)], " ", Dict(pairs(l.kwargs))); end
Xf = hcat(ones(60), Float64.(f .== "b"), Float64.(f .== "c"))
println("Poisson-mapped screen: ", poisson_screen(Xf, yf))

# ---------------------------------------------------------------- (d) scope probes (all-zero rep 3)
println("\n=== (d) scope probes on rep 3 (all y = 0)")
d3 = read_rcsv(datafile("pois_n8_lowmean", 3)); y, x = d3.y, d3.x
g = repeat(["g1", "g2", "g3", "g4"], inner = 2)
for (lab, thunk) in (
        ("y ~ 1 + x + (1 | g)", () -> drm(bf(@formula(y ~ 1 + x + (1 | g))), Poisson(); data = (; y, x, g))),
        ("y ~ 1 + x + offset(lt), lt = 0", () -> (lt = zeros(8); drm(bf(@formula(y ~ 1 + x + offset(lt))), Poisson(); data = (; y, x, lt)))),
        ("NegBinomial2 y ~ 1 + x, sigma ~ 1", () -> drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), NegBinomial2(); data = (; y, x))))
    res = try
        quietly(thunk)
    catch e
        println("  ", lab, ": ERROR ", first(sprint(showerror, e), 200)); continue
    end
    fit, logs = res
    @printf("  %-36s is_converged=%s niter=%d logLik=%.4g coef=%s SE=%s nwarn=%d\n", lab, is_converged(fit),
            niterations(fit), loglik(fit), string(round.(coef(fit), sigdigits = 5)),
            string(round.(stderror(fit), sigdigits = 3)), length(logs))
    for l in logs; println("      warn: ", replace(string(l.message), '\n' => ' ')[1:min(end, 110)]); end
end
