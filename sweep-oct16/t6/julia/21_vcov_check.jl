# 21_vcov_check.jl -- t6 lane, follow-up to 20_parity.jl (P10 SE comparison).
#
# P10 found own-fit SE gaps of 1e-7..1e-6 relative between drmTMB and DRModels.jl
# on cells whose coefficients agree to ~1e-11. This script locates the source:
# at the R optimum theta_R (mapped into the Julia layout; same objective on these
# cells, checked in parity_<cell>.json), it builds
#   H_ad : exact ForwardDiff Hessian of the Julia objective,
#   H_fd : TMB::sdreport's recipe = stats::optimHess(par, fn, gr) = central
#          differences of the (exact) gradient with ndeps = 1e-3, symmetrised,
# inverts both, and compares each dpar block with R's vcov (from r_<cell>.json)
# and with the Julia fit's stored vcov.
#
# Run: JULIA_DEPOT_PATH=/opt/julia-depot /opt/julia-env/bin/julia --project=/opt/t6-env -t 1 \
#        julia/21_vcov_check.jl > logs/vcov_check.log 2>&1

include(joinpath(@__DIR__, "lib_t6.jl"))
import DRModels.ForwardDiff

asvec(x) = x isa AbstractVector ? collect(x) : [x]
r2j(n::AbstractString) = (m = match(r"^f([A-Za-z0-9_.]+)$", n); m === nothing ? String(n) : "f: " * m.captures[1])
jsonmat(rows) = (rs = asvec(rows); rs[1] isa AbstractVector ?
                 Matrix{Float64}(reduce(vcat, [permutedims(Float64.(asvec(r))) for r in rs])) :
                 reshape(Float64.(rs), 1, 1))
relv(a, b) = maximum(abs.(a .- b) ./ max.(abs.(b), 1e-300))

function thetaR(fit, rj)
    θ = copy(fit.theta)
    for (p, r) in fit.blocks
        if p === :cutpoints
            c = Float64.(asvec(rj["cutpoints"]["values"])); θ[r] = [c[1]; log.(diff(c))]
        elseif p === :resd
            θ[r] = [log(Float64(rj["ranef"]["sd_g"]))]
        else
            jn = coefnames_of(fit, p); rn = r2j.(String.(asvec(rj["coef"][String(p)]["names"])))
            rv = Float64.(asvec(rj["coef"][String(p)]["values"]))
            θ[r] = rv[[findfirst(==(n), rn) for n in jn]]
        end
    end
    return θ
end

gradf(fit) = fit.nllgrad !== nothing ? (θ -> (g = similar(θ); fit.nllgrad(g, θ); g)) :
                                        (θ -> ForwardDiff.gradient(fit.nll, θ))

function optimhess(gr, θ; h = 1e-3)
    p = length(θ); H = zeros(p, p)
    for i in 1:p
        tp = copy(θ); tm = copy(θ); tp[i] += h; tm[i] -= h
        H[i, :] = (gr(tp) .- gr(tm)) ./ (2h)
    end
    return (H .+ H') ./ 2
end

rows = DataFrame(cell = String[], fit = String[], dpar = String[], se_rel_Rvcov_vs_inv_Had = Float64[],
                 se_rel_Rvcov_vs_inv_Hfd1e3 = Float64[], se_rel_Jvcov_vs_inv_Had = Float64[],
                 se_rel_Jvcov_vs_Rvcov = Float64[], note = String[])
cells = ["gaussian_fixed", "student_fixed", "skew_normal_fixed", "lognormal_fixed", "gamma_fixed", "beta_fixed",
         "zero_one_beta_fixed", "beta_binomial_fixed", "binomial_fixed", "poisson_fixed", "nbinom2_fixed",
         "truncated_nbinom2_fixed", "tweedie_fixed", "cumulative_logit_fixed",
         "gaussian_ri", "lognormal_ri", "student_ri_laplace", "binomial_ri_laplace", "poisson_ri_laplace"]
for c in cells
    base = replace(c, "_laplace" => "")
    rj = JSON.parsefile(joinpath(RES, "r_$(base).json"))
    fit = deserialize(joinpath(FITDIR, "$(c).jls"))
    θ = thetaR(fit, rj)
    gr = gradf(fit)
    note = ""
    Had = try
        ForwardDiff.hessian(fit.nll, θ)
    catch e
        note = "AD Hessian unavailable (" * first(sprint(showerror, e), 80) * "); used FD(h=1e-6) of gradient"
        optimhess(gr, θ; h = 1e-6)
    end
    Hfd = optimhess(gr, θ; h = 1e-3)
    Vad = inv(Symmetric(Had)); Vfd = inv(Symmetric(Hfd))
    for p in formula_dpars(fit)
        r = blockrange(fit, p)
        rv = rj["vcov"][String(p)]
        rn = r2j.(String.(asvec(rj["coef"][String(p)]["names"]))); jn = coefnames_of(fit, p)
        ix = [findfirst(==(n), rn) for n in jn]
        VR = jsonmat(rv["matrix"])[ix, ix]
        seR = sqrt.(diag(VR)); seAD = sqrt.(diag(Vad[r, r])); seFD = sqrt.(diag(Vfd[r, r]))
        seJ = sqrt.(diag(fit.vcov[r, r]))
        push!(rows, (base, c, String(p), relv(seR, seAD), relv(seR, seFD), relv(seJ, seAD), relv(seJ, seR), note))
        println(rpad(c, 26), rpad(String(p), 7), " |SE_R/SE_invHad - 1| ", round(relv(seR, seAD), sigdigits = 3),
                "   |SE_R/SE_invHfd(1e-3) - 1| ", round(relv(seR, seFD), sigdigits = 3),
                "   |SE_J/SE_invHad - 1| ", round(relv(seJ, seAD), sigdigits = 3),
                "   |SE_J/SE_R - 1| ", round(relv(seJ, seR), sigdigits = 3), "  ", note)
    end
end
CSV.write(joinpath(RES, "parity_vcov_check.csv"), rows)
println("Done ", Libc.strftime(time()))
