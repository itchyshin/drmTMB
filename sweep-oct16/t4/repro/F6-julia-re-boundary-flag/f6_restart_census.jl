# F6-julia-re-boundary-flag: restart census on the 50 re_sd1e-4 datasets (sweep-oct16 t4, cell k = 12).
# For every dataset, replays `_re_lbfgs_with_restart` (src/gaussian_ranef.jl:417-455 at f71b292) with
# the exact starts `_fit_ranef_gaussian` builds (:552-567), and reports which LBFGS run was returned,
# whether each run met the gradient criterion, and what the flag would be under the draft PR #1044 rule.
# Run from this folder:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#     --project=/home/user/DRModels.jl f6_restart_census.jl > f6_restart_census.out 2>&1
using DRModels, LinearAlgebra, Printf, Statistics, Logging, InteractiveUtils
const FD = DRModels.ForwardDiff
const Optim = DRModels.Optim
println("DRModels ", pkgversion(DRModels), " git HEAD ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)),
        "  Julia ", VERSION, "  Optim ", pkgversion(Optim))

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

# Draft PR #1044's rule for this route (optim_minimum_guard.jl on its head ef77368), copied here
# so it can be evaluated against main's fits: Optim.converged && !iteration_limit && unit-free test,
# which falls back to max|g| <= 1e-3 when H is singular (the boundary case).
function unitfree_1044(H, g)
    abs_ok = maximum(abs, g) <= 1e-3
    Hs = Symmetric((H .+ H') ./ 2); ev = eigvals(Hs); sc = maximum(abs, ev)
    minimum(ev) < -3e-8 * sc && return false
    minimum(abs, ev) <= 3e-8 * sc && return abs_ok
    C = cholesky(Hs; check = false); issuccess(C) || return abs_ok
    δ = C \ g; se = sqrt.(max.(diag(inv(C)), 0.0))
    maximum(abs.(δ) ./ se) <= 1e-3
end

println("rep bnd | primary: lsd     g_conv f_conv |g|     | restart: lsd     g_conv |g|     | dnll(r-p)  near_tie returned | fit.converged  rule#1044")
cnt = Dict{Symbol,Int}()
bump(k) = (cnt[k] = get(cnt, k, 0) + 1)
for r in 1:50
    d = read_rcsv(joinpath(DDIR, @sprintf("re_sd1e-4_r%02d.csv", r)))
    f = with_logger(NullLogger()) do
        drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
            data = (; y = d[:y], x = d[:x], g = string.("g", Int.(d[:g]))))
    end
    y = d[:y]; X = [ones(length(y)) d[:x]]; Xs = ones(length(y), 1)
    gidx = Int.(d[:g]); G = maximum(gidx)
    b0 = X \ y; res0 = y - X * b0
    θ0 = [b0; DRModels._ranef_sigma_ols_start(Xs, res0); DRModels._ranef_sdg_mom_start(res0, gidx, G)]
    θ0r = [b0; log(std(res0) + eps()); log(std(res0) / 2 + eps())]
    opts = Optim.Options(g_tol = 1e-8)
    rp = Optim.optimize(f.nll, θ0, Optim.LBFGS(), opts; autodiff = :forward)
    θp = Optim.minimizer(rp); fp = f.nll(θp)
    at_bnd = exp(θp[end]) < 1e-3 * std(res0)
    trig = !(maximum(abs, FD.gradient(f.nll, θp)) <= 1e-8) || at_bnd
    bnd = f.loglik - lm_ll(y, X) < 1e-6
    rr = trig ? Optim.optimize(f.nll, θ0r, Optim.LBFGS(), opts; autodiff = :forward) : nothing
    returned = f.theta == θp ? "primary" : (rr !== nothing && f.theta == Optim.minimizer(rr) ? "restart" : "??")
    resret = returned == "restart" ? rr : rp
    g = FD.gradient(f.nll, f.theta); H = FD.hessian(f.nll, f.theta)
    rule = Optim.converged(resret) && !Optim.iteration_limit_reached(resret) && unitfree_1044(H, g)
    if rr === nothing
        @printf("%3d %s  | %8.3f %-6s %-6s %.1e | (no restart: trigger false)                           %-8s | %-6s        %-6s\n",
                r, bnd ? "B" : " ", θp[end], Optim.g_converged(rp), Optim.f_converged(rp),
                Optim.g_residual(rp), returned, f.converged, rule)
    else
        θr = Optim.minimizer(rr); Δ = f.nll(θr) - fp; nt = abs(Δ) <= 1e-6 * max(1, abs(fp))
        @printf("%3d %s  | %8.3f %-6s %-6s %.1e | %8.3f %-6s %.1e | %+.1e  %-6s   %-8s | %-6s        %-6s\n",
                r, bnd ? "B" : " ", θp[end], Optim.g_converged(rp), Optim.f_converged(rp), Optim.g_residual(rp),
                θr[end], Optim.g_converged(rr), Optim.g_residual(rr), Δ, nt, returned, f.converged, rule)
        if bnd && !f.converged
            bump(:bnd_false)
            other = returned == "primary" ? rr : rp          # the LBFGS run the tie-break did NOT return
            if Optim.g_converged(other)
                bump(:bnd_false_other_run_gconv_discarded)
                returned == "restart" && bump(:bnd_false_primary_gconv_replaced_by_restart)
            else
                bump(:bnd_false_neither_run_gconv)
            end
        end
    end
    bnd && bump(:bnd); bnd && f.converged && bump(:bnd_true)
    bnd && rule && bump(:bnd_rule1044_true); !bnd && rule && bump(:int_rule1044_true)
    !bnd && f.converged && bump(:int_true)
end
println()
for k in sort(collect(keys(cnt))); println(rpad(string(k), 40), cnt[k]); end
