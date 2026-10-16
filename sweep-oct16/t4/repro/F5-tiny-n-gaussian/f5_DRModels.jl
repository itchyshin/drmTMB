# F5-tiny-n-gaussian: DRModels.jl on the n = 8 Gaussian location-scale datasets of sweep-oct16 t4.
# Run from this folder:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl f5_DRModels.jl > f5_DRModels.out 2>&1
# Data: ../../data/gauss_n8_rNN.csv (R seed 933663568 + rep - 1; see ../../t4_gen_data.R)
# Model: drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = (; y, x))
using DRModels, LinearAlgebra, Printf, Random, Statistics, InteractiveUtils
const FD = DRModels.ForwardDiff
const Optim = DRModels.Optim
versioninfo()
println("DRModels ", pkgversion(DRModels), " at ", pathof(DRModels))
println("DRModels git HEAD: ", strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)))

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

# best finite local maximum of the exact likelihood from the engine-independent scan
# (f5_reference.R -> f5_reference_maxima.csv): rep -> (ll, b0, b1, g0, g1)
function read_best(path)
    isfile(path) || return Dict{Int,NTuple{5,Float64}}()
    ls = readlines(path); hdr = [strip(h, '"') for h in split(ls[1], ',')]
    ix(n) = findfirst(==(n), hdr)
    best = Dict{Int,NTuple{5,Float64}}()
    for l in ls[2:end]
        v = split(l, ',')
        parse(Float64, v[ix("grid_edge")]) == 0 || continue
        r = parse(Int, v[ix("rep")]); ll = parse(Float64, v[ix("ll")])
        t = (ll, parse(Float64, v[ix("b0")]), parse(Float64, v[ix("b1")]),
             parse(Float64, v[ix("g0")]), parse(Float64, v[ix("g1")]))
        (!haskey(best, r) || ll > best[r][1]) && (best[r] = t)
    end
    best
end
const BEST = read_best("f5_reference_maxima.csv")

fitit(y, x) = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = (; y, x))

for r in (5, 9, 28, 4, 29, 30, 31, 6, 19, 49)
    d = read_rcsv(joinpath("..", "..", "data", @sprintf("gauss_n8_r%02d.csv", r)))
    y, x = d[:y], d[:x]
    fit = fitit(y, x)
    θ = fit.theta; nll = fit.nll
    g = FD.gradient(nll, θ)
    H = FD.hessian(nll, θ)
    V = fit.vcov
    se = sqrt.(abs.(diag(V)))
    nstep = all(isfinite, V) ? maximum(abs.(V * g) ./ se) : NaN
    lsig = log.(fit.scales[:sigma])
    @printf("\n=== gauss_n8_r%02d ===\n", r)
    @printf("  loglik %.7f | best finite local max (exact, f5_reference) %s\n", loglik(fit),
            haskey(BEST, r) ? @sprintf("%.7f", BEST[r][1]) : "NA")
    @printf("  fit.converged %s | is_converged %s | iterations %s\n", fit.converged, is_converged(fit),
            (try niterations(fit) catch; "NA" end))
    @printf("  theta = [%s]\n", join([@sprintf("%.6g", t) for t in θ], ", "))
    @printf("  max|grad| %.3e (absolute g_tol 1e-8) | Newton step / SE %.3e | Hessian finite %s, min eig %.3e, cond %.2e\n",
            maximum(abs, g), nstep, all(isfinite, H), all(isfinite, H) ? eigmin(Symmetric(H)) : NaN,
            all(isfinite, H) ? cond(H) : NaN)
    @printf("  log sigma range [%.2f, %.2f], spread %.2f (draft PR #1066 rule: spread > log(1e4) = %.2f)\n",
            minimum(lsig), maximum(lsig), maximum(lsig) - minimum(lsig), log(1e4))
    # replicate the route's own optimiser call (src/gaussian_core.jl:1207-1244) to read Optim's flags
    X = hcat(ones(length(y)), x)
    b0 = X \ y; θ0 = [b0; log(std(y - X * b0) + eps()); 0.0]
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = 1e-8); autodiff = :forward)
    @printf("  Optim replay: same minimizer %s | converged %s g_converged %s f_converged %s x_converged %s | iterations %d (limit reached %s) | g_residual %.3e\n",
            isapprox(Optim.minimizer(res), θ; rtol = 1e-10), Optim.converged(res), Optim.g_converged(res),
            Optim.f_converged(res), Optim.x_converged(res), Optim.iterations(res),
            Optim.iteration_limit_reached(res), Optim.g_residual(res))
    # the package's own objective at the engine-independent best maximum, and a restart from there
    if haskey(BEST, r)
        θs = collect(BEST[r][2:5])
        res2 = Optim.optimize(nll, θs, Optim.LBFGS(), Optim.Options(g_tol = 1e-8); autodiff = :forward)
        @printf("  -nll at the reference maximum %.7f | restart from it: -nll %.7f, max|grad| %.2e\n",
                -nll(θs), -Optim.minimum(res2), maximum(abs, FD.gradient(nll, Optim.minimizer(res2))))
    end
    # harness-level multi-start (no package option exists, DRModels.jl#994): 20 seeded perturbations
    rng = MersenneTwister(20261016 + r)
    lls = Float64[]
    for s in 1:20
        st = θ0 .+ 2.0 .* randn(rng, 4)
        rs = try Optim.optimize(nll, st, Optim.LBFGS(), Optim.Options(g_tol = 1e-8, iterations = 5000); autodiff = :forward) catch; nothing end
        rs === nothing || push!(lls, -Optim.minimum(rs))
    end
    lls = filter(isfinite, lls)
    @printf("  harness multi-start (20 starts, sd 2): best %.5f, distinct values (rounded 1e-3): %s\n",
            maximum(lls), join(sort(unique(round.(lls; digits = 3)); rev = true)[1:min(6, end)], ", "))
end
