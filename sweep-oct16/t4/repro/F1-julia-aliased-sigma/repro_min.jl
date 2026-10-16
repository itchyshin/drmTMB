# F1-julia-aliased-sigma: minimal repro (DRModels.jl).
# Gaussian y ~ 1 + x, sigma ~ 1 + x + z with z = 2x + 1 exactly (sweep-oct16 t4 cell 13, rep 1,
# nominal seed 20261017600, R seed 933664768). The sigma design has rank 2 of 3 columns.
# Run from this directory:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl repro_min.jl > repro_min.out 2>&1
using DRModels, LinearAlgebra, InteractiveUtils, ForwardDiff, Printf

versioninfo()
println("DRModels ", pkgversion(DRModels), " at ", pathof(DRModels))
println("DRModels git HEAD: ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)))

function read_rcsv(path)   # write.csv output: quoted header, numeric body
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
y, x, z = d.y, d.x, d.z
println("\nn = ", length(y), "; max |z - (2x + 1)| = ", maximum(abs.(z .- (2 .* x .+ 1))))
Xs = hcat(ones(length(x)), x, z)
println("rank([1 x z]) = ", rank(Xs), " of ", size(Xs, 2), " columns; svdvals = ", svdvals(Xs))

println("\n=== FULL fit: sigma ~ 1 + x + z (aliased) ===")
full = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; y, x, z))
println("fit.converged = ", full.converged, "   is_converged(fit) = ", is_converged(full))
println("logLik = ", loglik(full))
show(stdout, MIME("text/plain"), coeftable(full)); println()
println("check_drm(full):")
chk = check_drm(full)
println("  ok = ", chk.ok, "  vcov_posdef = ", chk.vcov_posdef, "  min_eigval = ", chk.min_eigval,
        "  cond = ", chk.cond, "  max_abs_grad = ", chk.max_abs_grad)

println("\n=== REDUCED fit: sigma ~ 1 + x (the identified model) ===")
red = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = (; y, x))
println("is_converged = ", is_converged(red), "   logLik = ", loglik(red))
show(stdout, MIME("text/plain"), coeftable(red)); println()

# theta order: mu:(Intercept), mu:x, sigma:(Intercept)=a, sigma:x=b, sigma:z=c
# log sigma = a + b x + c z = (a + c) + (b + 2c) x  =>  identified: a + c and b + 2c
th, V = coef(full), vcov(full)
L = [0 0 1 0 1;    # a + c  (reduced intercept)
     0 0 0 1 2]    # b + 2c (reduced slope)
est, se = L * th, sqrt.(diag(L * V * L'))
thr, ser = coef(red), stderror(red)
println("\nIdentified combinations from the FULL fit vs the REDUCED fit:")
@printf("  a + c : full %.8f (SE %.6f)   reduced sigma:(Intercept) %.8f (SE %.6f)\n", est[1], se[1], thr[3], ser[3])
@printf("  b + 2c: full %.8f (SE %.6f)   reduced sigma:x           %.8f (SE %.6f)\n", est[2], se[2], thr[4], ser[4])
@printf("  logLik difference full - reduced = %.3e\n", loglik(full) - loglik(red))

# The null direction (a, b, c) += t * (-1, -2, 1) leaves every fitted sigma unchanged,
# so the likelihood is exactly flat along it and the true SEs of a, b, c are infinite.
v = [0, 0, -1, -2, 1]
println("\nlogLik along the null direction theta + t * (0,0,-1,-2,1):")
for t in (-1000.0, -10.0, -1.0, 0.0, 1.0, 10.0, 1000.0)
    @printf("  t = %8.1f   sigma:z = %10.4f   logLik = %.10f\n", t, th[5] + t, -full.nll(th .+ t .* v))
end

H = ForwardDiff.hessian(full.nll, th)
ev = eigen(Symmetric(H))
println("\nHessian at the optimum: diag = ", diag(H))
println("eigenvalues = ", ev.values)
println("eigenvector of the smallest |eigenvalue| (normalised to sigma:z = 1): ",
        ev.vectors[:, argmin(abs.(ev.values))] ./ ev.vectors[5, argmin(abs.(ev.values))])
println("vcov_guard flat_coordinates rule: diag(H) <= 3e-8 * max(diag(H)) -> ",
        findall(<=(3e-8 * maximum(abs.(diag(H)))), abs.(diag(H))), " (empty: no single coordinate is flat)")

# Same model, same data, different (equally exact) alias: z2 = 4x + 2. The fitted sigma and
# logLik are unchanged, but the reported 'SE' of the aliased slope changes.
z2 = 4 .* x .+ 2
alt = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z2)), Gaussian(); data = (; y, x, z2))
println("\n=== Re-expressed alias sigma ~ 1 + x + z2, z2 = 4x + 2 ===")
println("is_converged = ", is_converged(alt), "   logLik = ", loglik(alt),
        "   max |sigma_full - sigma_alt| = ", maximum(abs.(sigma(full) .- sigma(alt))))
show(stdout, MIME("text/plain"), coeftable(alt)); println()
