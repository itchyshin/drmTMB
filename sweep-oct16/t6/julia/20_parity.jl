# 20_parity.jl -- t6 lane, SPEC P9 (R-vs-Julia predict at shared parameters,
# the 1e-8 parity) and P10 (fit-vs-fit predict parity), all 28 cells.
#
# Run (one Julia process for all cells):
#   JULIA_DEPOT_PATH=/opt/julia-depot /opt/julia-env/bin/julia --project=/opt/t6-env -t 1 \
#     /home/user/drmTMB/sweep-oct16/t6/julia/20_parity.jl [cell ...] \
#     > /home/user/drmTMB/sweep-oct16/t6/logs/parity.log 2>&1
#
# Inputs (written by the two harnesses, nothing is refitted here):
#   results/r_<cell>.json, results/r_<cell>_pred.csv       R fit: coef, vcov, cutpoints,
#                                                            sd_g, logLik; nd_main predictions
#                                                            (predict()) + predict_parameters SE
#   results/jl_fits/<cell>.jls, <cell>_laplace.jls          serialized DrmFit objects
#   results/jl_<cell>_pred.csv, jl_<cell>_laplace_pred.csv  harness nd_main predictions (sanity)
#   data/nd_main.csv
# Outputs:
#   results/parity_<cell>.json   per cell: P9 and P10 records with all numbers
#   results/parity_p9_p10.csv    long form: cell x test x dpar x type x metric
#
# P9: deepcopy the Julia default fit, overwrite fit.theta block by block with the
# R coefficients (mapped by NAME: R "(Intercept)","x","fb","fc" <-> Julia
# "(Intercept)","x","f: b","f: c"; a block whose names do not correspond stops the
# cell), cutpoints converted to the Julia increment parameterisation, RE SD to
# log scale; also overwrite each dpar's diagonal vcov block with R's vcov block
# (so the delta-method SE layer is compared at shared inputs too). Evaluate
# Julia predict / predict_parameters on nd_main and compare with R. Pass:
# max abs diff <= 1e-8 on the link scale for every dpar and on the response
# scale for every dpar whose response semantics are the same by design.
#
# P10: each engine's own fit (Julia ri: the marginal = :Laplace fit where it
# exists, else the default fit) on nd_main: abs/rel prediction gaps, coefficient
# gaps, logLik gap, gradients, SE gaps, and the decomposition
# (R_link - J_link) - X (beta_R - beta_J).

include(joinpath(@__DIR__, "lib_t6.jl"))
import DRModels.ForwardDiff

const PIN_J = try readchomp(`git -C /home/user/DRModels.jl rev-parse HEAD`) catch; "unknown" end
const PIN_R = try readchomp(`git -C /home/user/drmTMB rev-parse HEAD`) catch; "unknown" end
const TOL9 = 1e-8

println("t6 parity (P9/P10)  DRModels.jl pin = ", PIN_J, "  drmTMB pin = ", PIN_R,
        "  Julia ", VERSION, "  threads=", Threads.nthreads(), "  ", Libc.strftime(time()))
flush(stdout)

asvec(x) = x isa AbstractVector ? collect(x) : [x]
# R treatment-contrast name -> DRModels name: "fb" -> "f: b"; others unchanged.
r2j(n::AbstractString) = (m = match(r"^f([A-Za-z0-9_.]+)$", n); m === nothing ? String(n) : "f: " * m.captures[1])
jsonmat(rows) = (rs = asvec(rows); rs[1] isa AbstractVector ?
                 Matrix{Float64}(reduce(vcat, [permutedims(Float64.(asvec(r))) for r in rs])) :
                 reshape(Float64.(rs), 1, 1))
relv(a, b) = (length(a) == length(b) || return Inf; isempty(a) ? 0.0 :
              maximum(abs.(a .- b) ./ max.(abs.(b), 1e-300)))
fmt(x) = x isa Real ? (isfinite(x) ? string(round(x, sigdigits = 3)) : string(x)) : string(x)

# R documented inverse links (R/lib_t6.R T6_LINKS; ?predict.drmTMB, R/family.R).
function r_inv(fam::String, d::Symbol, η)
    if d === :mu
        fam in ("gaussian", "student", "skew_normal", "lognormal", "cumulative_logit") && return copy(η)
        fam in ("gamma", "poisson", "nbinom2", "truncated_nbinom2", "tweedie") && return exp.(η)
        return logistic.(η)
    elseif d === :sigma
        return exp.(η)
    elseif d === :nu
        fam == "student" && return 2 .+ exp.(η)
        fam == "skew_normal" && return copy(η)
        fam == "tweedie" && return 1 .+ logistic.(η)
    elseif d === :zoi || d === :coi
        return logistic.(η)
    end
    error("r_inv: no R link for $fam/$d")
end
function r_dinv(fam::String, d::Symbol, η)
    if d === :mu
        fam in ("gaussian", "student", "skew_normal", "lognormal", "cumulative_logit") && return ones(length(η))
        fam in ("gamma", "poisson", "nbinom2", "truncated_nbinom2", "tweedie") && return exp.(η)
        return logistic.(η) .* (1 .- logistic.(η))
    elseif d === :sigma
        return exp.(η)
    elseif d === :nu
        fam == "student" && return exp.(η)
        fam == "skew_normal" && return ones(length(η))
        fam == "tweedie" && return logistic.(η) .* (1 .- logistic.(η))
    elseif d === :zoi || d === :coi
        return logistic.(η) .* (1 .- logistic.(η))
    end
    error("r_dinv: no R link for $fam/$d")
end

# Response-scale semantics that differ BY DESIGN (documented on both sides):
# drmTMB lognormal mu response = meanlog (identity link); DRModels LogNormal
# docstring (src/lognormal.jl:14-16) + _mean_response (src/gaussian_core.jl:1860-1869)
# report exp(meanlog) = the median.
const BY_DESIGN = Dict(("lognormal", :mu) =>
    "drmTMB predict(type='response') for lognormal mu is meanlog (identity link); DRModels predict/predict_parameters(:response) return exp(meanlog) = response-scale median (LogNormal docstring)")

const INVS = [("identity", η -> η), ("exp", exp), ("logistic", logistic),
              ("2+exp", η -> 2 + exp(η)), ("1+logistic", η -> 1 + logistic(η))]
function which_inv(link, resp)
    out = String[]
    for (n, f) in INVS
        v = maximum(abs.(f.(link) .- resp) ./ max.(1.0, abs.(resp)))
        v <= 1e-12 && push!(out, n)
    end
    isempty(out) ? "none of identity/exp/logistic/2+exp/1+logistic" : join(out, "|")
end

function read_rpred(key)
    df = CSV.read(joinpath(RES, "r_$(key)_pred.csv"), DataFrame; missingstring = ["NA", ""])
    out = Dict{Tuple{Symbol,Symbol},NamedTuple}()
    for dp in unique(String.(df.dpar)), ty in ("link", "response")
        sub = df[(String.(df.dpar) .== dp) .& (String.(df.type) .== ty), :]
        nrow(sub) == 0 && continue
        sort!(sub, :row)
        out[(Symbol(dp), Symbol(ty))] = (value = Float64.(coalesce.(sub.value, NaN)),
                                         se = Float64.(coalesce.(sub.se, NaN)))
    end
    return out
end

function read_jlpred(path)
    isfile(path) || return nothing
    df = CSV.read(path, DataFrame; missingstring = ["NA", "NaN", ""])
    nrow(df) == 0 && return nothing
    out = Dict{Tuple{Symbol,Symbol},NamedTuple}()
    for dp in unique(String.(df.dpar)), ty in ("link", "response")
        sub = df[(String.(df.dpar) .== dp) .& (String.(df.type) .== ty), :]
        nrow(sub) == 0 && continue
        sort!(sub, :row)
        out[(Symbol(dp), Symbol(ty))] = (value = Float64.(sub.value), se = Float64.(coalesce.(sub.se, NaN)))
    end
    return out
end

# Build the full theta in the Julia layout of `fit` from the R fit record.
# Returns (theta, ok, notes, idx, rnames) with idx[p] the R->Julia reorder per block.
function theta_from_R(fit, rj)
    θ = copy(fit.theta); ok = true; notes = String[]
    idx = Dict{Symbol,Vector{Int}}(); maps = Dict{String,Any}()
    jblocks = [p for (p, _) in fit.blocks]
    for (p, r) in fit.blocks
        if p === :cutpoints
            if !haskey(rj, "cutpoints")
                ok = false; push!(notes, "STOP: Julia has cutpoints, R record has none"); continue
            end
            c = Float64.(asvec(rj["cutpoints"]["values"]))
            if length(c) != length(r) || !all(diff(c) .> 0)
                ok = false; push!(notes, "STOP: cutpoint count/order mismatch (R $(length(c)), Julia $(length(r)))"); continue
            end
            θ[r] = [c[1]; log.(diff(c))]   # Julia: θ1 = δ1, θk = θk-1 + exp(δk) (src/cumulative.jl:66-70)
            maps["cutpoints"] = Dict("R_names" => String.(asvec(rj["cutpoints"]["names"])), "R_natural" => c,
                                     "julia_names" => coefnames_of(fit, p), "julia_increments" => θ[r],
                                     "mapping" => "positional after count+order check; delta1 = c1, deltak = log(ck - ck-1)")
        elseif p === :resd
            rr = get(rj, "ranef", nothing)
            if rr === nothing || length(r) != 1 || coefnames_of(fit, p) != ["g"]
                ok = false; push!(notes, "STOP: RE SD block cannot be mapped"); continue
            end
            θ[r] = [log(Float64(rr["sd_g"]))]
            maps["resd"] = Dict("R_sd_g" => rr["sd_g"], "julia_log_sd" => θ[r][1])
        else
            k = String(p)
            if !haskey(rj["coef"], k)
                ok = false; push!(notes, "STOP: R fit has no `$k` block"); continue
            end
            jn = coefnames_of(fit, p)
            rn = String.(asvec(rj["coef"][k]["names"])); rv = Float64.(asvec(rj["coef"][k]["values"]))
            mapped = r2j.(rn)
            if length(mapped) != length(jn) || Set(mapped) != Set(jn) || !allunique(mapped)
                ok = false
                push!(notes, "STOP: block `$k` names do not correspond: R [" * join(rn, ", ") * "] -> [" *
                             join(mapped, ", ") * "] vs Julia [" * join(jn, ", ") * "]")
                continue
            end
            ix = [findfirst(==(n), mapped) for n in jn]
            θ[r] = rv[ix]; idx[p] = ix
            maps[k] = Dict("julia" => jn, "R_in_julia_order" => rn[ix], "identity_order" => ix == collect(1:length(ix)))
        end
    end
    for k in keys(rj["coef"])
        Symbol(k) in jblocks || (ok = false; push!(notes, "STOP: R block `$k` absent from the Julia fit"))
    end
    return θ, ok, notes, idx, maps
end

# R vcov block of dpar p in Julia order (names checked).
function rvcov_block(rj, p::Symbol, ix)
    v = get(rj, "vcov", nothing)
    (v isa AbstractDict && haskey(v, String(p))) || return nothing
    nm = String.(asvec(v[String(p)]["names"]))
    M = jsonmat(v[String(p)]["matrix"])
    cn = [r2j(replace(n, Regex("^" * String(p) * ":") => "")) for n in nm]
    rn = String.(asvec(rj["coef"][String(p)]["names"]))
    cn == r2j.(rn) || return nothing
    return M[ix, ix]
end

# Gradient of the Julia objective at θ: nllgrad if the fit carries one, else
# ForwardDiff, and always a central finite difference as a cross-check.
function grad_info(fit, θ)
    out = Dict{String,Any}()
    if fit.nllgrad !== nothing
        try
            g = similar(θ); fit.nllgrad(g, θ); out["nllgrad_maxabs"] = maximum(abs.(g)); out["nllgrad"] = g
        catch e
            out["nllgrad_error"] = first(sprint(showerror, e), 200)
        end
    end
    try
        g = ForwardDiff.gradient(fit.nll, θ); out["ad_maxabs"] = maximum(abs.(g)); out["ad"] = g
    catch e
        out["ad_error"] = first(sprint(showerror, e), 200)
    end
    try
        g = similar(θ)
        for i in eachindex(θ)
            h = 1e-5 * max(1.0, abs(θ[i]))
            tp = copy(θ); tm = copy(θ); tp[i] += h; tm[i] -= h
            g[i] = (fit.nll(tp) - fit.nll(tm)) / (2h)
        end
        out["fd_maxabs"] = maximum(abs.(g)); out["fd"] = g
    catch e
        out["fd_error"] = first(sprint(showerror, e), 200)
    end
    best = haskey(out, "nllgrad_maxabs") ? out["nllgrad_maxabs"] : haskey(out, "ad_maxabs") ? out["ad_maxabs"] :
           get(out, "fd_maxabs", NaN)
    out["maxabs"] = best
    out["source"] = haskey(out, "nllgrad_maxabs") ? "nllgrad" : haskey(out, "ad_maxabs") ? "ForwardDiff" : "central FD"
    return out
end

rgrad(rj) = (m = match(r"max \|gradient\| = ([0-9.eE+-]+)", string(rj["convergence"]["opt_message"]));
             m === nothing ? NaN : parse(Float64, m.captures[1]))

const ROWS = DataFrame(cell = String[], family = String[], re = String[], test = String[], fit_used = String[],
                       dpar = String[], type = String[], metric = String[], value = Float64[],
                       tol = Float64[], pass = String[], note = String[])
addrow!(cell, fam, re, test, fu, dp, ty, metric, val, tol, pass, note = "") =
    push!(ROWS, (cell, fam, re, test, fu, String(dp), String(ty), metric,
                 val isa Real ? Float64(val) : NaN, tol, pass, note))
passstr(v, tol) = isnan(tol) ? "info" : (isfinite(v) && v <= tol ? "PASS" : "FAIL")

# ============================================================== P9 ==========
function run_P9(cell, fam, re, rj, rp, fitJ, nd; fitL = nothing)
    det = Dict{String,Any}(); notes = String[]
    θR, ok, mnotes, idx, maps = theta_from_R(fitJ, rj)
    det["mapping"] = maps; append!(notes, mnotes)
    for (k, m) in maps
        haskey(m, "identity_order") || continue
        addrow!(cell, fam, re, "P9", "julia default + R theta", k, "coef", "name_map_ok(R->Julia by name)", 0.0, 0.0, "PASS",
                "R [" * join(m["R_in_julia_order"], ",") * "] -> Julia [" * join(m["julia"], ",") * "]" *
                (m["identity_order"] ? " (same order)" : " (REORDERED)"))
    end
    if !ok
        return mkres("ERROR", "", nothing, "cell stopped: " * join(mnotes, "; "); details = det), θR
    end
    fc = deepcopy(fitJ)
    fc.theta .= θR
    vinj = String[]
    for p in formula_dpars(fc)
        haskey(idx, p) || continue
        Vb = rvcov_block(rj, p, idx[p])
        if Vb === nothing
            push!(notes, "R vcov block `$p` unavailable or names mismatch; SE parity skipped for $p")
        else
            r = blockrange(fc, p); fc.vcov[r, r] .= Vb; push!(vinj, String(p))
        end
    end
    det["vcov_injected_blocks"] = vinj
    det["theta_injected"] = θR
    # R-side self-consistency: R predict() link == hand X * beta_R (both from the R record).
    selfc = Dict{String,Any}()
    for p in formula_dpars(fc)
        haskey(rp, (p, :link)) || continue
        X = handX(coefnames_of(fc, p), nd)
        v = maxabs(rp[(p, :link)].value, X * θR[blockrange(fc, p)])
        selfc[String(p)] = v
        addrow!(cell, fam, re, "P9", "julia default + R theta", p, "link", "R_predict_vs_handXbetaR", v, 1e-12, passstr(v, 1e-12),
                "harness self-check: R CSV link vs hand X beta_R")
    end
    det["R_link_vs_hand_XbetaR"] = selfc
    # cutpoints natural-scale round trip (cumulative_logit)
    if blockrange(fc, :cutpoints) !== nothing
        cJ = hand_cuts(fc); cR = Float64.(asvec(rj["cutpoints"]["values"]))
        det["cutpoints_roundtrip_maxabs"] = maxabs(cJ, cR)
        addrow!(cell, fam, re, "P9", "julia default + R theta", "cutpoints", "natural", "cutpoint_roundtrip", maxabs(cJ, cR), 1e-12,
                passstr(maxabs(cJ, cR), 1e-12))
    end
    # Engine evaluation.
    pp = Dict{Symbol,Any}(); perr = nothing
    try
        pp[:link] = predict_parameters(fc, nd; type = :link, se = true)
        pp[:response] = predict_parameters(fc, nd; type = :response, se = true)
    catch e
        perr = sprint(showerror, e)
    end
    pr = Dict{Symbol,Any}(); prerr = nothing
    try
        pr[:link] = predict(fc, nd; type = :link, se = true)
        pr[:response] = predict(fc, nd; type = :response, se = true)
    catch e
        prerr = sprint(showerror, e)
    end
    if perr !== nothing || prerr !== nothing
        det["predict_parameters_error"] = perr; det["predict_error"] = prerr
        # informational: what a hand-built Julia-layout X beta_R gives (not an engine check)
        aux = Dict{String,Any}()
        for p in formula_dpars(fc)
            haskey(rp, (p, :link)) || continue
            X = handX(coefnames_of(fc, p), nd)
            aux[String(p)] = maxabs(X * coef(fc, p), rp[(p, :link)].value)
        end
        det["aux_hand_XbetaR_vs_R_link_NOT_engine"] = aux
        msg = perr !== nothing ? perr : prerr
        addrow!(cell, fam, re, "P9", "julia default + R theta", "ALL", "link", "engine_error", Inf, TOL9, "FAIL", first(msg, 300))
        return mkres("FAIL", "max abs diff Julia(R theta) vs R, nd_main", nothing,
                     "Julia predict/predict_parameters REFUSE nd_main while drmTMB predicts it: " * first(msg, 400) *
                     (isempty(notes) ? "" : " | " * join(notes, "; ")); details = det), θR
    end
    worst_link = 0.0; worst_resp = 0.0; worst_se = 0.0; resp_fail = String[]; design_diff = String[]
    sefail = String[]; pd = Dict{String,Any}()
    for p in formula_dpars(fc)
        haskey(rp, (p, :link)) || (push!(notes, "R has no nd_main prediction for `$p`"); continue)
        Rl = rp[(p, :link)]; Rr = rp[(p, :response)]
        Jl = pp[:link][p]; Jr = pp[:response][p]
        dl = maxabs(Jl.value, Rl.value); dr = maxabs(Jr.value, Rr.value)
        rdr = maxrel(Jr.value, Rr.value)
        sel = relv(Jl.se, Rl.se); ser = relv(Jr.se, Rr.se)
        jinv = which_inv(Jl.value, Jr.value); rinv = which_inv(Rl.value, Rr.value)
        bd = get(BY_DESIGN, (fam, p), nothing)
        q = Dict{String,Any}("link_maxabs" => dl, "response_maxabs" => dr, "response_maxrel_mixed" => rdr,
                             "se_link_maxrel" => sel, "se_response_maxrel" => ser,
                             "julia_response_is" => jinv * "(link)", "R_response_is" => rinv * "(link)",
                             "by_design" => bd === nothing ? false : bd)
        worst_link = max(worst_link, dl)
        addrow!(cell, fam, re, "P9", "julia default + R theta", p, "link", "maxabs_value", dl, TOL9, passstr(dl, TOL9))
        addrow!(cell, fam, re, "P9", "julia default + R theta", p, "link", "maxrel_se(R vcov injected)", sel, TOL9, passstr(sel, TOL9))
        if bd === nothing
            worst_resp = max(worst_resp, dr)
            dr > TOL9 && push!(resp_fail, "$p: Julia $(jinv)(eta) vs R $(rinv)(eta), max|diff| $(fmt(dr))")
            addrow!(cell, fam, re, "P9", "julia default + R theta", p, "response", "maxabs_value", dr, TOL9, passstr(dr, TOL9),
                    "Julia=$(jinv)(eta); R=$(rinv)(eta)")
            addrow!(cell, fam, re, "P9", "julia default + R theta", p, "response", "maxrel_se(R vcov injected)", ser, TOL9, passstr(ser, TOL9))
            worst_se = max(worst_se, sel, ser)
            ser > TOL9 && push!(sefail, "$p response SE rel $(fmt(ser))")
        else
            # judged on the link scale; the semantic gap is quantified separately
            push!(design_diff, "$p: Julia $(jinv)(eta) vs R $(rinv)(eta), max|diff| $(fmt(dr)) (by design)")
            addrow!(cell, fam, re, "P9", "julia default + R theta", p, "response", "maxabs_value(by-design semantics)", dr, NaN, "info",
                    "Julia=$(jinv)(eta); R=$(rinv)(eta); " * bd)
            addrow!(cell, fam, re, "P9", "julia default + R theta", p, "response", "maxrel_se(by-design semantics)", ser, NaN, "info")
            # same-semantics check: Julia response mapped back through R's invlink of Julia link
            q["aligned_response_maxabs"] = maxabs(r_inv(fam, p, Jl.value), Rr.value)
            worst_se = max(worst_se, sel)
        end
        sel > TOL9 && push!(sefail, "$p link SE rel $(fmt(sel))")
        pd[String(p)] = q
    end
    # predict() (mu only)
    if haskey(rp, (:mu, :link))
        a = maxabs(pr[:link].prediction, rp[(:mu, :link)].value)
        b = maxabs(pr[:response].prediction, rp[(:mu, :response)].value)
        sa = relv(pr[:link].se, rp[(:mu, :link)].se); sb = relv(pr[:response].se, rp[(:mu, :response)].se)
        pd["predict()_mu"] = Dict("link_maxabs" => a, "response_maxabs" => b, "se_link_maxrel" => sa, "se_response_maxrel" => sb)
        worst_link = max(worst_link, a)
        addrow!(cell, fam, re, "P9", "julia default + R theta", "mu[predict()]", "link", "maxabs_value", a, TOL9, passstr(a, TOL9))
        if get(BY_DESIGN, (fam, :mu), nothing) === nothing
            worst_resp = max(worst_resp, b)
            b > TOL9 && push!(resp_fail, "predict() mu response max|diff| $(fmt(b))")
            addrow!(cell, fam, re, "P9", "julia default + R theta", "mu[predict()]", "response", "maxabs_value", b, TOL9, passstr(b, TOL9))
        else
            addrow!(cell, fam, re, "P9", "julia default + R theta", "mu[predict()]", "response", "maxabs_value(by-design semantics)", b, NaN, "info")
        end
    end
    det["per_dpar"] = pd
    # same injection into the Laplace fit object (ri cells): must be identical
    if fitL !== nothing
        try
            θL, okL, _, _, _ = theta_from_R(fitL, rj)
            fl = deepcopy(fitL); fl.theta .= θL
            a = predict_parameters(fl, nd; type = :link); b = pp[:link]
            det["laplace_object_same_injection_maxabs"] = maximum(maxabs(a[p], b[p].value) for p in keys(a))
        catch e
            det["laplace_object_same_injection_error"] = sprint(showerror, e)
        end
    end
    link_ok = worst_link <= TOL9
    resp_ok = isempty(resp_fail)
    st = link_ok && resp_ok ? "PASS" : "FAIL"
    msg = "link max|diff| $(fmt(worst_link)) ($(link_ok ? "<=" : ">") 1e-8)" *
          (resp_ok ? "; response (same-semantics dpars) max|diff| $(fmt(worst_resp))" : "; RESPONSE FAIL: " * join(resp_fail, "; ")) *
          (isempty(design_diff) ? "" : "; by-design response difference: " * join(design_diff, "; ")) *
          "; SE at injected R vcov: " * (isempty(sefail) ? "max rel $(fmt(worst_se)) PASS" : "FAIL " * join(sefail, "; ")) *
          (isempty(notes) ? "" : " | " * join(notes, "; "))
    det["worst_link"] = worst_link; det["worst_response_same_semantics"] = worst_resp; det["worst_se_rel"] = worst_se
    det["link_pass"] = link_ok; det["response_pass"] = resp_ok; det["se_pass"] = isempty(sefail)
    return mkres(st, "max abs diff Julia predict(R theta) vs R predict, nd_main (tol 1e-8)", worst_link, msg; details = det), θR
end

# ============================================================== P10 =========
function run_P10(cell, fam, re, rj, rp, fitP, fitused, nd, jlpred)
    det = Dict{String,Any}("julia_fit_used" => fitused, "julia_marginal" => String(fitP.marginal),
                           "R_marginal" => (re == "ri" ? "TMB Laplace" : "none (fixed effects)"))
    notes = String[]
    θR, ok, mnotes, idx, maps = theta_from_R(fitP, rj)
    ok || return mkres("ERROR", "", nothing, "cell stopped: " * join(mnotes, "; "); details = det)
    # ---- coefficients
    cd = Dict{String,Any}(); maxcoef = 0.0; maxz = 0.0
    for p in formula_dpars(fitP)
        r = blockrange(fitP, p)
        d = θR[r] .- fitP.theta[r]
        Vb = rvcov_block(rj, p, idx[p])
        seR = Vb === nothing ? fill(NaN, length(r)) : sqrt.(diag(Vb))
        seJ = sqrt.(abs.(diag(fitP.vcov)[r]))
        cd[String(p)] = Dict("names" => coefnames_of(fitP, p), "R" => θR[r], "julia" => fitP.theta[r], "diff" => d,
                             "diff_over_R_se" => d ./ seR, "se_R" => seR, "se_julia" => seJ,
                             "se_maxrel" => relv(seJ, seR))
        maxcoef = max(maxcoef, maximum(abs.(d))); maxz = max(maxz, maximum(abs.(d ./ seR)))
        addrow!(cell, fam, re, "P10", fitused, p, "coef", "maxabs_coef_diff", maximum(abs.(d)), NaN, "info")
        addrow!(cell, fam, re, "P10", fitused, p, "coef", "maxrel_coef_se_diff", relv(seJ, seR), NaN, "info")
    end
    if blockrange(fitP, :cutpoints) !== nothing
        cJ = hand_cuts(fitP); cR = Float64.(asvec(rj["cutpoints"]["values"]))
        cd["cutpoints_natural"] = Dict("R" => cR, "julia" => cJ, "diff" => cR .- cJ)
        maxcoef = max(maxcoef, maximum(abs.(cR .- cJ)))
        addrow!(cell, fam, re, "P10", fitused, "cutpoints", "natural", "maxabs_coef_diff", maximum(abs.(cR .- cJ)), NaN, "info")
    end
    if blockrange(fitP, :resd) !== nothing
        sJ = re_sd(fitP)[:g]; sR = Float64(rj["ranef"]["sd_g"])
        cd["sd_g"] = Dict("R" => sR, "julia" => sJ, "diff" => sR - sJ, "rel" => (sR - sJ) / sR)
        addrow!(cell, fam, re, "P10", fitused, "sd_g", "natural", "abs_diff", abs(sR - sJ), NaN, "info",
                "marginal: Julia $(fitP.marginal) vs R TMB Laplace")
    end
    det["coef"] = cd; det["max_coef_absdiff"] = maxcoef; det["max_coef_diff_over_R_se"] = maxz
    # ---- logLik / objective cross-evaluation / gradients
    llR = Float64(rj["loglik"]); llJ = fitP.loglik
    det["loglik_R"] = llR; det["loglik_julia"] = llJ; det["loglik_julia_minus_R"] = llJ - llR
    nllJR = try fitP.nll(θR) catch e; push!(notes, "nll(theta_R) error: " * first(sprint(showerror, e), 200)); NaN end
    det["julia_nll_at_R_theta"] = nllJR
    det["julia_nll_at_R_theta_plus_llR"] = nllJR + llR            # 0 => same objective value at the same theta
    det["julia_nll_at_R_theta_minus_at_J_theta"] = nllJR + llJ    # >= 0 if theta_J is the Julia optimum
    gJ = grad_info(fitP, fitP.theta); gRt = grad_info(fitP, θR)
    det["julia_grad_at_julia_theta"] = gJ; det["julia_grad_at_R_theta"] = gRt
    det["R_max_abs_gradient"] = rgrad(rj); det["R_opt_message"] = rj["convergence"]["opt_message"]
    det["julia_converged"] = fitP.converged; det["R_converged"] = rj["converged"]; det["R_pdHess"] = rj["convergence"]["pdHess"]
    addrow!(cell, fam, re, "P10", fitused, "ALL", "loglik", "loglik_julia_minus_R", llJ - llR, NaN, "info")
    addrow!(cell, fam, re, "P10", fitused, "ALL", "objective", "julia_nll(theta_R)+llR", nllJR + llR, NaN, "info",
            "0 => same objective at the same theta")
    addrow!(cell, fam, re, "P10", fitused, "ALL", "gradient", "julia_grad_maxabs_at_theta_J($(gJ["source"]))", gJ["maxabs"], NaN, "info")
    addrow!(cell, fam, re, "P10", fitused, "ALL", "gradient", "R_grad_maxabs(opt_message)", rgrad(rj), NaN, "info")
    # ---- predictions
    pp = Dict{Symbol,Any}(); perr = nothing
    try
        pp[:link] = predict_parameters(fitP, nd; type = :link, se = true)
        pp[:response] = predict_parameters(fitP, nd; type = :response, se = true)
    catch e
        perr = sprint(showerror, e)
    end
    if perr !== nothing
        det["predict_parameters_error"] = perr
        aux = Dict{String,Any}()
        for p in formula_dpars(fitP)
            haskey(rp, (p, :link)) || continue
            X = handX(coefnames_of(fitP, p), nd)
            aux[String(p)] = maxabs(X * coef(fitP, p), rp[(p, :link)].value)
        end
        det["aux_hand_XbetaJ_vs_R_link_NOT_engine"] = aux
        addrow!(cell, fam, re, "P10", fitused, "ALL", "link", "engine_error", Inf, TOL9, "FAIL", first(perr, 300))
        return mkres("ERROR", "max abs diff Julia own fit vs R own fit, nd_main", nothing,
                     "Julia predict_parameters refuses nd_main (same root cause as P9): " * first(perr, 300) *
                     "; coefficient-level parity: max|coef diff| $(fmt(maxcoef)), logLik diff $(fmt(llJ - llR)); hand X beta_J vs R link " *
                     join(["$k=$(fmt(v))" for (k, v) in aux], ", ") * " (NOT an engine evaluation)"; details = det)
    end
    # harness consistency: recomputed Julia predictions == harness pred CSV
    if jlpred !== nothing
        hc = 0.0
        for p in formula_dpars(fitP), ty in (:link, :response)
            haskey(jlpred, (p, ty)) || continue
            hc = max(hc, maxabs(pp[ty][p].value, jlpred[(p, ty)].value))
        end
        det["recomputed_vs_harness_pred_csv_maxabs"] = hc
    end
    pd = Dict{String,Any}(); worst = 0.0; worst_resp_aligned = 0.0; worst_resid = 0.0; worst_se = 0.0
    worst_rel = 0.0
    for p in formula_dpars(fitP)
        haskey(rp, (p, :link)) || continue
        r = blockrange(fitP, p)
        Rl = rp[(p, :link)]; Rr = rp[(p, :response)]
        Jl = pp[:link][p]; Jr = pp[:response][p]
        X = handX(coefnames_of(fitP, p), nd)
        dlink = Rl.value .- Jl.value
        expl = X * (θR[r] .- fitP.theta[r])
        resid = maxabs(dlink, expl)
        al = maximum(abs.(dlink)); rl = maxrel(Jl.value, Rl.value)
        ar = maxabs(Jr.value, Rr.value); rr = maxrel(Jr.value, Rr.value)
        # semantics-aligned response: R's documented invlink applied to the Julia link
        Jr_al = r_inv(fam, p, Jl.value)
        aal = maxabs(Jr_al, Rr.value); ral = maxrel(Jr_al, Rr.value)
        sel = relv(Jl.se, Rl.se)
        Jse_al = abs.(r_dinv(fam, p, Jl.value)) .* Jl.se
        ser = relv(Jse_al, Rr.se)
        ser_raw = relv(Jr.se, Rr.se)
        pd[String(p)] = Dict("link_maxabs" => al, "link_maxrel_mixed" => rl, "response_maxabs_raw" => ar,
                             "response_maxrel_raw" => rr, "response_maxabs_aligned" => aal,
                             "response_maxrel_aligned" => ral, "resid_after_Xdbeta" => resid,
                             "se_link_maxrel" => sel, "se_response_maxrel_aligned" => ser,
                             "se_response_maxrel_raw" => ser_raw)
        worst = max(worst, al); worst_rel = max(worst_rel, rl); worst_resp_aligned = max(worst_resp_aligned, aal)
        worst_resid = max(worst_resid, resid); worst_se = max(worst_se, sel, ser)
        addrow!(cell, fam, re, "P10", fitused, p, "link", "maxabs_value", al, TOL9, passstr(al, TOL9))
        addrow!(cell, fam, re, "P10", fitused, p, "link", "maxrel_value(mixed)", rl, NaN, "info")
        addrow!(cell, fam, re, "P10", fitused, p, "link", "resid_after_X(betaR-betaJ)", resid, 1e-10, passstr(resid, 1e-10))
        addrow!(cell, fam, re, "P10", fitused, p, "response", "maxabs_value(aligned semantics)", aal, TOL9, passstr(aal, TOL9))
        addrow!(cell, fam, re, "P10", fitused, p, "response", "maxrel_value(aligned semantics)", ral, NaN, "info")
        addrow!(cell, fam, re, "P10", fitused, p, "response", "maxabs_value(raw, engine semantics)", ar, NaN, "info")
        addrow!(cell, fam, re, "P10", fitused, p, "link", "maxrel_se(own vcov)", sel, NaN, "info")
        addrow!(cell, fam, re, "P10", fitused, p, "response", "maxrel_se(own vcov, aligned)", ser, NaN, "info")
    end
    det["per_dpar"] = pd
    det["worst_link_maxabs"] = worst; det["worst_link_maxrel"] = worst_rel
    det["worst_response_aligned_maxabs"] = worst_resp_aligned; det["worst_resid_after_Xdbeta"] = worst_resid
    det["worst_se_rel"] = worst_se
    bar = worst <= TOL9 && worst_resp_aligned <= TOL9
    det["bar_1e8_met"] = bar
    explained = worst_resid <= 1e-10
    same_obj = isfinite(nllJR) && abs(nllJR + llR) <= 1e-6 * max(1.0, abs(llR))
    flat = isfinite(nllJR) && abs(nllJR + llJ) <= 1e-6
    cause = if bar
        "1e-8 met"
    elseif !explained
        "NOT explained by X(betaR-betaJ): residual $(fmt(worst_resid))"
    elseif same_obj && flat
        "optimizer tolerance: same objective (Julia nll(theta_R) + llR = $(fmt(nllJR + llR))), " *
        "Julia nll(theta_R) - nll(theta_J) = $(fmt(nllJR + llJ)), logLik diff $(fmt(llJ - llR)), " *
        "max|dbeta|/SE_R = $(fmt(maxz)); not a predict defect"
    elseif !same_obj && re == "ri" && fitP.marginal !== :Laplace
        "marginal approximation: Julia $(fitP.marginal) (GHQ/exact route) vs TMB Laplace; Julia nll(theta_R) + llR = $(fmt(nllJR + llR)) " *
        "(DRModels.jl #1071, not new); predictions differ only through X(betaR-betaJ); not a predict defect"
    else
        "explained by X(betaR-betaJ) but objectives differ at theta_R (Julia nll(theta_R) + llR = $(fmt(nllJR + llR)), " *
        "nll(theta_R) - nll(theta_J) = $(fmt(nllJR + llJ)))"
    end
    det["explanation"] = cause
    det["predict_defect"] = !explained
    st = bar ? "PASS" : "FAIL"
    msg = "max|link diff| $(fmt(worst)) (rel $(fmt(worst_rel))), aligned response $(fmt(worst_resp_aligned)); " *
          "max|coef diff| $(fmt(maxcoef)) (max $(fmt(maxz)) R-SE); logLik J-R $(fmt(llJ - llR)); " *
          "grad J $(fmt(gJ["maxabs"])) ($(gJ["source"])), R $(fmt(rgrad(rj))); SE max rel $(fmt(worst_se)); " *
          "resid after X dbeta $(fmt(worst_resid)); " * cause * (isempty(notes) ? "" : " | " * join(notes, "; "))
    return mkres(st, "max abs link diff, own fits, nd_main (1e-8 bar)", worst, msg; details = det)
end

# First line of the recorded marginal = :Laplace refusal (from the Julia harness record).
function lap_refusal(cell)
    jj = joinpath(RES, "jl_$(cell).json")
    isfile(jj) || return "unknown"
    lap = get(JSON.parsefile(jj), "laplace", nothing)
    (lap === nothing || get(lap, "error", nothing) === nothing) && return "unknown"
    return first(replace(string(lap["error"]), "\n" => " "), 90) * "..."
end

# ============================================================== main ========
function main(args)
    cells = CSV.read(joinpath(DATA, "cells.csv"), DataFrame)
    nd = readnt("nd_main.csv")
    summary = Dict{String,Any}()
    for row in eachrow(cells)
        fam = String(row.family); re = String(row.re); cell = "$(fam)_$(re)"
        (isempty(args) || cell in args) || continue
        println("\n=== $cell ==="); flush(stdout)
        out = Dict{String,Any}("cell" => cell, "family" => fam, "re" => re, "pins" => Dict("drmTMB" => PIN_R, "DRModels.jl" => PIN_J),
                               "nd" => "data/nd_main.csv (18 rows)", "tol" => TOL9)
        rjp = joinpath(RES, "r_$(cell).json"); jls = joinpath(FITDIR, "$(cell).jls")
        jlap = joinpath(FITDIR, "$(cell)_laplace.jls")
        rj = isfile(rjp) ? JSON.parsefile(rjp) : nothing
        if rj === nothing || !rj["fit_ok"] || !isfile(jls)
            why = rj === nothing ? "no R record" : !rj["fit_ok"] ? "R fit failed" : "DRModels.jl refused the fit (no serialized fit; see jl_$(cell).json)"
            jj = joinpath(RES, "jl_$(cell).json")
            if isfile(jj)
                jd = JSON.parsefile(jj)
                why *= ": " * first(string(get(jd, "fit_error", "")), 200)
            end
            out["P9"] = mkres("NA", "", nothing, "not evaluable: " * why)
            out["P10"] = mkres("NA", "", nothing, "not evaluable: " * why)
            addrow!(cell, fam, re, "P9", "", "ALL", "", "not_evaluable", NaN, NaN, "NA", why)
            addrow!(cell, fam, re, "P10", "", "ALL", "", "not_evaluable", NaN, NaN, "NA", why)
            println("  NA: ", why)
            writejson(joinpath(RES, "parity_$(cell).json"), out)
            summary[cell] = out
            continue
        end
        rp = read_rpred(cell)
        fitJ = deserialize(jls)
        fitL = isfile(jlap) ? deserialize(jlap) : nothing
        t0 = time()
        p9, θR = try
            run_P9(cell, fam, re, rj, rp, fitJ, nd; fitL = fitL)
        catch e
            println("  !! P9 harness exception: ", errstring(e, catch_backtrace()))
            mkres("ERROR", "", nothing, "harness exception: " * sprint(showerror, e)), nothing
        end
        out["P9"] = p9
        println("  P9: ", p9["status"], "  ", p9["notes"]); flush(stdout)
        fitP, fitused, jlpp = fitL !== nothing ?
            (fitL, "julia marginal=:Laplace ($(cell)_laplace.jls)", joinpath(RES, "jl_$(cell)_laplace_pred.csv")) :
            (fitJ, "julia default marginal=:$(fitJ.marginal) ($(cell).jls)" *
                   (re == "ri" ? "; marginal=:Laplace refused for this cell: " * lap_refusal(cell) : ""),
             joinpath(RES, "jl_$(cell)_pred.csv"))
        p10 = try
            run_P10(cell, fam, re, rj, rp, fitP, fitused, nd, read_jlpred(jlpp))
        catch e
            println("  !! P10 harness exception: ", errstring(e, catch_backtrace()))
            mkres("ERROR", "", nothing, "harness exception: " * sprint(showerror, e))
        end
        out["P10"] = p10
        out["seconds"] = time() - t0
        for (id, r) in (("P9", p9), ("P10", p10))
            v = r["value"]
            addrow!(cell, fam, re, id, id == "P9" ? "julia default + R theta" : fitused, "ALL", "summary", "status",
                    v isa Real ? v : NaN, TOL9, r["status"], first(string(r["notes"]), 600))
        end
        println("  P10 [$fitused]: ", p10["status"], "  ", p10["notes"]); flush(stdout)
        writejson(joinpath(RES, "parity_$(cell).json"), out)
        summary[cell] = out
    end
    CSV.write(joinpath(RES, isempty(args) ? "parity_p9_p10.csv" : "parity_p9_p10_partial.csv"), ROWS)
    println("\nSummary")
    for row in eachrow(cells)
        cell = "$(row.family)_$(row.re)"
        haskey(summary, cell) || continue
        s = summary[cell]
        println(rpad(cell, 26), " P9=", rpad(s["P9"]["status"], 6), " P10=", s["P10"]["status"])
    end
    println("\nDone ", Libc.strftime(time()))
end

main(ARGS)
