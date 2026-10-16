# F6-julia-re-boundary-flag: mechanism check for DRModels.jl's `converged` flag on the
# Gaussian (1 | g) route when the random-intercept SD is at its zero boundary.
# Run from this folder:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl f6_mechanism.jl > f6_mechanism.out 2>&1
# Data: ../../data/re_sd1e-4_rNN.csv (sweep-oct16 t4 cell k = 12; R seed = (20261017500 + rep - 1) %% 2^31)
# DGP: G = 20 groups x m = 5, x ~ N(0,1), y = 1 + 0.5 x + b_g + N(0,1), b_g ~ N(0, 1e-4^2)
# Model: drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian(); data = (; y, x, g))
using DRModels, LinearAlgebra, Printf, Statistics, Logging, InteractiveUtils
const FD = DRModels.ForwardDiff
const Optim = DRModels.Optim
versioninfo()
println("DRModels ", pkgversion(DRModels), " at ", pathof(DRModels))
println("DRModels git HEAD: ", strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)))
println("Optim ", pkgversion(Optim), "  ForwardDiff ", pkgversion(FD))

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

# closed-form ML logLik of the RE-free model y ~ 1 + x, sigma ~ 1 (the boundary supremum)
function lm_ll(y, x)
    X = [ones(length(y)) x]; b = X \ y; r = y - X * b; n = length(y)
    -n / 2 * (log(2π * sum(abs2, r) / n) + 1)
end

fitq(d; kw...) = with_logger(NullLogger()) do
    drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
        data = (; y = d[:y], x = d[:x], g = string.("g", Int.(d[:g]))), kw...)
end
optflags(r) = (conv = Optim.converged(r), g = Optim.g_converged(r), f = Optim.f_converged(r),
               x = Optim.x_converged(r), it = Optim.iterations(r), gres = Optim.g_residual(r))

println("\n== Part A: all 50 datasets, default g_tol = 1e-8, then g_tol = 1e-6 ==")
println("rep  ll-lm_ll      conv_raw is_conv  lsd_g     |grad|_inf  argmax  grad(b0,b1,lsig,lsd)                               conv@1e-6 is_conv@1e-6 dll@1e-6")
nb = 0; nb_false = 0; nb_false_1e6 = 0; nint_false = 0
for r in 1:50
    d = read_rcsv(joinpath(DDIR, @sprintf("re_sd1e-4_r%02d.csv", r)))
    f = fitq(d)
    g = FD.gradient(f.nll, f.theta)
    llm = lm_ll(d[:y], d[:x])
    bnd = f.loglik - llm < 1e-6           # at the zero-variance boundary (RE adds nothing)
    f6 = fitq(d; g_tol = 1e-6)
    global nb += bnd; global nb_false += bnd && !f.converged
    global nb_false_1e6 += bnd && !f6.converged; global nint_false += !bnd && !f.converged
    @printf("%3d %s %+.3e  %-6s   %-6s  %8.3f  %.2e    %d     [%s]  %-6s    %-6s       %+.1e\n",
            r, bnd ? "B" : " ", f.loglik - llm, f.converged, is_converged(f), f.theta[end],
            maximum(abs, g), argmax(abs.(g)), join([@sprintf("%+.1e", v) for v in g], ","),
            f6.converged, is_converged(f6), f6.loglik - f.loglik)
end
println("boundary fits (logLik - lm logLik < 1e-6): $nb;  converged = false among them at g_tol 1e-8: $nb_false;  at g_tol 1e-6: $nb_false_1e6")
println("interior fits with converged = false at g_tol 1e-8: $nint_false")

println("\n== Part B: replay of `_re_lbfgs_with_restart` (gaussian_ranef.jl:417-455) on rep 1 ==")
d = read_rcsv(joinpath(DDIR, "re_sd1e-4_r01.csv"))
f = fitq(d)
y = d[:y]; X = [ones(length(y)) d[:x]]; Xs = ones(length(y), 1)
gidx = Int.(d[:g]); G = maximum(gidx)
b0 = X \ y; res0 = y - X * b0
θ0 = [b0; DRModels._ranef_sigma_ols_start(Xs, res0); DRModels._ranef_sdg_mom_start(res0, gidx, G)]
θ0r = [b0; log(std(res0) + eps()); log(std(res0) / 2 + eps())]
opts = Optim.Options(g_tol = 1e-8)
rp = Optim.optimize(f.nll, θ0, Optim.LBFGS(), opts; autodiff = :forward)
rr = Optim.optimize(f.nll, θ0r, Optim.LBFGS(), opts; autodiff = :forward)
for (lab, rs) in (("primary (data-driven start)", rp), ("restart (interior start)", rr))
    θ = Optim.minimizer(rs)
    println(rpad(lab, 30), " nll = ", @sprintf("%.10f", f.nll(θ)), "  lsd_g = ", @sprintf("%.3f", θ[end]),
            "  ", optflags(rs), "  |grad|_inf(ForwardDiff) = ", @sprintf("%.2e", maximum(abs, FD.gradient(f.nll, θ))))
end
println("start lsd_g: primary = ", θ0[end], "  restart = ", θ0r[end])
println("at_boundary trigger (exp(lsd_g) < 1e-3 * std(res0)) for primary: ",
        exp(Optim.minimizer(rp)[end]) < 1e-3 * std(res0))
println("returned fit.theta == primary minimizer: ", f.theta == Optim.minimizer(rp),
        "   == restart minimizer: ", f.theta == Optim.minimizer(rr))
println("fit.converged = ", f.converged, "  (drm_optim_converged = Optim.converged && Optim.g_converged; optim_minimum_guard.jl:71)")

println("\n== Part C: rep 1, the Hessian / SE of log sd_g at the boundary ==")
H = FD.hessian(f.nll, f.theta)
println("Hessian diag = ", diag(H))
println("stderror(fit) = ", stderror(f))
println("re_sd(fit) = ", re_sd(f))
c = with_logger(NullLogger()) do; check_drm(f) end
println("check_drm: converged = ", c.converged, "  max_abs_grad = ", c.max_abs_grad, "  ok = ", c.ok,
        "  vcov_posdef = ", c.vcov_posdef, "  variance_boundary.structured_at_boundary = ", c.variance_boundary.structured_at_boundary)
println("\nwarnings emitted by drm() on rep 1:")
lg = Test_logger = Logging.ConsoleLogger(stdout, Logging.Warn)
with_logger(lg) do
    drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
        data = (; y = d[:y], x = d[:x], g = string.("g", Int.(d[:g]))))
end
