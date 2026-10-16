# F6-julia-re-boundary-flag: Wald SE of the random-intercept log-SD on the 29 boundary datasets of
# sweep-oct16 t4 cell re_sd1e-4. Shows which side of `pinv`'s own cutoff the flat Hessian
# eigenvalue lands on (vcov_guard.jl:107 `V0 = pinv(Hs)`; Julia's default pinv rtol = eps * min(size)).
# Run from this folder:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl f6_se_census.jl > f6_se_census.out 2>&1
using DRModels, LinearAlgebra, Printf, Statistics, Logging, InteractiveUtils
const FD = DRModels.ForwardDiff
println("DRModels ", pkgversion(DRModels), " git HEAD ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)), "  Julia ", VERSION)

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
lm_ll(y, X) = (r = y - X * (X \ y); n = length(y); -n / 2 * (log(2π * sum(abs2, r) / n) + 1))
pinv_rtol = eps(Float64) * 4
println("Julia pinv default rtol for a 4x4 Hessian = eps * 4 = ", pinv_rtol, ";  vcov_guard _VCOV_RTOL = ", DRModels._VCOV_RTOL)
println("rep  lsd_g     sd_g      eig_min/eig_max  side-of-pinv-cutoff  SE(lsd_g)    Wald95 CI for lsd_g (confint)")
nzero = 0; nhuge = 0; nb = 0
for r in 1:50
    d = read_rcsv(joinpath(DDIR, @sprintf("re_sd1e-4_r%02d.csv", r)))
    f = with_logger(NullLogger()) do
        drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
            data = (; y = d[:y], x = d[:x], g = string.("g", Int.(d[:g]))))
    end
    X = [ones(length(d[:y])) d[:x]]
    f.loglik - lm_ll(d[:y], X) < 1e-6 || continue
    global nb += 1
    H = FD.hessian(f.nll, f.theta); ev = eigvals(Symmetric((H + H') / 2)); ratio = minimum(abs, ev) / maximum(abs, ev)
    se = stderror(f)[end]
    ci = with_logger(NullLogger()) do; confint(f) end
    cil = ci isa AbstractMatrix ? ci[end, :] : ci
    se < 1e-6 && (global nzero += 1); se > 1e3 && (global nhuge += 1)
    @printf("%3d %8.3f  %.2e   %.2e         %-20s %.3e    %s\n", r, f.theta[end], exp(f.theta[end]), ratio,
            ratio < pinv_rtol ? "below (truncated)" : "above (inverted)", se, string(cil))
end
println("boundary fits: $nb;  SE(lsd_g) < 1e-6: $nzero;  SE(lsd_g) > 1e3: $nhuge")
