# F6-julia-re-boundary-flag: would the unit-free rules in the open drafts certify the 22 boundary fits that
# main f71b292 reports as not converged? Evaluated on main's own fits (theta-hat, ForwardDiff g and H):
#  - draft PR #1044 `_unitfree_converged(H, g)` (optim_minimum_guard.jl on ef77368; falls back to max|g| <= 1e-3
#    when H is singular) -- also verified directly on that branch in f6_flag_pr1044_ef77368.out;
#  - draft PR #1107 `_newton_decrement_small(g, H, n)` (optim_minimum_guard.jl on its head; needs a successful
#    Cholesky of H, then 0.5 g'H^-1 g <= n * 1e-10).
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl f6_draft_rules.jl > f6_draft_rules.out 2>&1
using DRModels, LinearAlgebra, Printf, Logging
const FD = DRModels.ForwardDiff
println("DRModels ", pkgversion(DRModels), " git HEAD ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)), "  Julia ", VERSION)
function read_rcsv(path)
    ls = readlines(path); hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]
        isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, strip(v, '"'))); end
    end
    Dict(Symbol(h) => cols[j] for (j, h) in enumerate(hdr))
end
const DDIR = joinpath(@__DIR__, "..", "..", "data")
lm_ll(y, X) = (r = y - X * (X \ y); n = length(y); -n / 2 * (log(2π * sum(abs2, r) / n) + 1))
println("rep  min eig(H)   chol_ok  0.5g'H^-1g   nd_small(#1107)")
n_false = 0; n_chol = 0; n_nd = 0
for r in 1:50
    d = read_rcsv(joinpath(DDIR, @sprintf("re_sd1e-4_r%02d.csv", r)))
    f = with_logger(NullLogger()) do
        drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
            data = (; y = d[:y], x = d[:x], g = string.("g", Int.(d[:g]))))
    end
    (f.loglik - lm_ll(d[:y], [ones(100) d[:x]]) < 1e-6 && !f.converged) || continue
    global n_false += 1
    g = FD.gradient(f.nll, f.theta); H = FD.hessian(f.nll, f.theta)
    C = cholesky(Symmetric(H); check = false); ok = issuccess(C)
    nd = ok ? 0.5 * dot(g, C \ g) : NaN
    small = ok && nd <= 100 * 1e-10
    global n_chol += ok; global n_nd += small
    @printf("%3d  %+.2e   %-6s   %.2e     %s\n", r, minimum(eigvals(Symmetric(H))), ok, nd, small)
end
println("boundary fits with converged = false on main: $n_false; Cholesky of H succeeds: $n_chol; Newton-decrement branch passes: $n_nd")
