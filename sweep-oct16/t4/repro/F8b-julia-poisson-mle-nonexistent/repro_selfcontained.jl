# F8b: data inlined (t4 cell 15, reps 3 and 27), exactly the snippet proposed for the issue body.
# Run: JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#        --project=/home/user/DRModels.jl repro_selfcontained.jl > repro_selfcontained.out 2>&1
using DRModels
println("DRModels ", pkgversion(DRModels), " ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)), "; Julia ", VERSION)

# rep 3: all y = 0
x = [-0.0292785730789077, -2.07527755306188, -1.26224739973712, -0.135456173606004,
     -1.05584042635037, 0.218711141103825, 0.915790979674801, 0.0391185640938337]
y = zeros(8)
f0 = drm(bf(@formula(y ~ 1 + x)), Poisson(); data = (; y, x))
println("rep 3 : is_converged=", is_converged(f0), " niter=", niterations(f0), " coef=", coef(f0),
        " SE=", stderror(f0), " check_drm ok=", check_drm(f0).ok)
println("        log(eps()) = ", log(eps()))

# rep 27: y = 2 at max(x), 0 elsewhere
x = [0.874179376754336, -1.80802294417958, 1.07582680175277, 1.99152036375555,
     -0.34920696964089, -0.0158223689737766, 0.928431408635883, 1.09143738410038]
y = [0.0, 0, 0, 2, 0, 0, 0, 0]
f1 = drm(bf(@formula(y ~ 1 + x)), Poisson(); data = (; y, x))   # warns: "variance/dispersion boundary"
println("rep 27: is_converged=", is_converged(f1), " niter=", niterations(f1), " coef=", coef(f1),
        " SE=", stderror(f1), " check_drm ok=", check_drm(f1).ok)

# the existing Binomial screen, fed the Poisson existence condition, flags both:
s0 = Float64.(f0.obs[:mu] .> 0); s1 = Float64.(f1.obs[:mu] .> 0)
X0 = hcat(ones(8), [-0.0292785730789077, -2.07527755306188, -1.26224739973712, -0.135456173606004,
                    -1.05584042635037, 0.218711141103825, 0.915790979674801, 0.0391185640938337])
X1 = hcat(ones(8), x)
println("screen rep 3 : ", DRModels._detect_separation(X0, s0, 1 .+ s0))
println("screen rep 27: ", DRModels._detect_separation(X1, s1, 1 .+ s1))
