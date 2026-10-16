# 10_harness_jl.jl -- t6 lane (predict()/simulate()), Julia engine, SPEC P1-P8.
#
# Run (one Julia process for all cells; DRModels load costs ~40 s):
#   JULIA_DEPOT_PATH=/opt/julia-depot /opt/julia-env/bin/julia --project=/opt/t6-env \
#     /home/user/drmTMB/sweep-oct16/t6/julia/10_harness_jl.jl [cell ...] \
#     > /home/user/drmTMB/sweep-oct16/t6/logs/harness_jl.log 2>&1
# Optional args restrict to cells named <family>_<re> (e.g. gaussian_ri).
#
# Outputs (SPEC output contract):
#   results/jl_<family>_<re>.json           per-cell record, tests P1..P11
#   results/jl_<family>_<re>_pred.csv       nd_main predictions, default fit
#   results/jl_<family>_ri_laplace_pred.csv nd_main predictions, marginal = :Laplace fit
#   results/jl_summary.csv                  one row per cell
#   results/jl_fits/<family>_<re>.jls       serialized DrmFit (default marginal)
#   results/jl_fits/<family>_ri_laplace.jls serialized marginal = :Laplace fit (where accepted)
#
# Seeds: Julia uses the literal cell seed from data/cells.csv; simulate() uses
# Random.Xoshiro(seed + 100).

include(joinpath(@__DIR__, "lib_t6.jl"))

const PIN = try
    readchomp(`git -C /home/user/DRModels.jl rev-parse HEAD`)
catch
    "unknown"
end
const TOL = 1e-10

println("t6 Julia harness  DRModels.jl pin = ", PIN, "  Julia ", VERSION, "  ", Libc.strftime(time()))
flush(stdout)

# ============================================================== P1 ==========
function test_P1(fam, fit, data)
    checks = []; notes = String[]
    dps = formula_dpars(fit)
    hp = hand_params(fam, fit, data)
    ok_pp = true
    ppl = ppr = nothing
    try
        ppl = predict_parameters(fit, data; type = :link)
        ppr = predict_parameters(fit, data; type = :response)
    catch e
        ok_pp = false
        push!(notes, "predict_parameters(fit, data) ERROR: " * sprint(showerror, e))
    end
    if ok_pp
        for d in dps
            push!(checks, check("pp_link_vs_Xb[$d]", maxabs(ppl[d], hp[d].eta), TOL))
            push!(checks, check("pp_resp_vs_docinvlink[$d]", maxrel(ppr[d], hp[d].resp), TOL))
            push!(checks, check("pp_resp_vs_invlink_of_pp_link[$d]", maxrel(ppr[d], doc_inv(fam, d, ppl[d])), TOL))
        end
        mp = marginal_parameters(fit)
        for d in dps
            haskey(mp, d) || continue
            c = check("pp_resp_vs_marginal_parameters[$d] (docstring: in-sample reproduces)", maxrel(ppr[d], mp[d]), TOL)
            push!(checks, c)
        end
    end
    pl = pr = nothing
    try
        pl = predict(fit, data; type = :link)
        pr = predict(fit, data; type = :response)
        push!(checks, check("predict_link_vs_Xb[mu]", maxabs(pl, hp[:mu].eta), TOL))
        push!(checks, check("predict_resp_vs_docinvlink[mu]", maxrel(pr, hp[:mu].resp), TOL))
        push!(checks, check("predict_resp_vs_fitted (docstring: in-sample predict ~ fitted)", maxrel(pr, fitted(fit)), 1e-8))
    catch e
        push!(checks, (name = "predict(fit, data) errors", value = Inf, tol = 0.0, pass = false))
        push!(notes, "predict(fit, data) ERROR: " * sprint(showerror, e))
    end
    stored, Ey = hand_stored_and_Ey(fam, fit, data)
    push!(checks, check("fit.means[:mu]_vs_hand_b0", maxrel(fit.means[:mu], stored), 1e-8))
    push!(checks, check("fitted_vs_E[y]_at_b0 (fitted docstring: 'Fitted mean(s)')", maxrel(fitted(fit), Ey), 1e-8))
    det = Dict{String,Any}()
    # What fit.means[:mu] holds for random-intercept fits: b = 0 or conditional?
    if blockrange(fit, :resd) !== nothing
        det["means_mu_vs_b0_maxrel"] = maxrel(fit.means[:mu], stored)
        try
            re = ranef(fit)
            bhat = re[:g]
            gidx = [findfirst(==(gl), unique(data.g)) for gl in data.g]
            ηc = hp[:mu].eta .+ bhat[gidx]
            det["means_mu_vs_conditional_Xb_plus_bhat_maxabs"] = maxabs(fit.means[:mu], doc_inv(fam, :mu, ηc))
            det["ranef_available"] = true
        catch e
            det["ranef_available"] = false
            det["ranef_error"] = sprint(showerror, e)
        end
        push!(notes, "ri fit: fit.means[:mu] equals the hand b = 0 value to " *
                     string(round(det["means_mu_vs_b0_maxrel"], sigdigits = 3)) *
                     (get(det, "ranef_available", false) ?
                      "; vs conditional X*b + bhat: " * string(round(det["means_mu_vs_conditional_Xb_plus_bhat_maxabs"], sigdigits = 3)) :
                      "; ranef() unavailable (" * first(get(det, "ranef_error", ""), 120) * ")"))
    end
    st, worst, n2, dd = summarize_checks(checks)
    det["checks"] = dd
    return mkres(st, "max abs/rel deviation (tol 1e-10; fitted/means 1e-8)", worst, join(vcat(n2, notes), " | "); details = det)
end

# ============================================================== P2 ==========
function test_P2(fam, fit, nd)
    checks = []; notes = String[]
    dps = formula_dpars(fit)
    try
        ppl = predict_parameters(fit, nd; type = :link)
        ppr = predict_parameters(fit, nd; type = :response)
        nog = dropcol(nd, :g)
        ppl2 = predict_parameters(fit, nog; type = :link)
        ppr2 = predict_parameters(fit, nog; type = :response)
        for d in dps
            η, _ = hand_eta(fit, d, nd)
            push!(checks, check("link_vs_Xnew_b[$d]", maxabs(ppl[d], η), TOL))
            push!(checks, check("resp_vs_docinvlink[$d]", maxrel(ppr[d], doc_inv(fam, d, η)), TOL))
            push!(checks, check("seen_vs_unseen_g_link[$d]", maxabs(ppl[d][1:9], ppl[d][10:18]), TOL))
            push!(checks, check("seen_vs_unseen_g_resp[$d]", maxabs(ppr[d][1:9], ppr[d][10:18]), TOL))
            push!(checks, check("g_column_removed_link[$d]", maxabs(ppl2[d], ppl[d]), TOL))
            push!(checks, check("g_column_removed_resp[$d]", maxabs(ppr2[d], ppr[d]), TOL))
        end
        pl = predict(fit, nd; type = :link); pr = predict(fit, nd; type = :response)
        pr2 = predict(fit, nog; type = :response)
        push!(checks, check("predict_vs_pp_link[mu]", maxabs(pl, ppl[:mu]), TOL))
        push!(checks, check("predict_vs_pp_resp[mu]", maxabs(pr, ppr[:mu]), TOL))
        push!(checks, check("predict_g_removed_resp[mu]", maxabs(pr2, pr), TOL))
    catch e
        push!(checks, (name = "predict on nd_main errors", value = Inf, tol = 0.0, pass = false))
        push!(notes, "ERROR: " * sprint(showerror, e))
    end
    st, worst, n2, dd = summarize_checks(checks)
    return mkres(st, "max abs deviation vs hand X_new*beta / invlink (tol 1e-10)", worst, join(vcat(n2, notes), " | "); details = Dict("checks" => dd))
end

# ============================================================== P3 ==========
# "Clear" = the engine's own newdata guard (#1015 unseen-level check or #1000
# column-mismatch check), which names the column/levels and says what to do.
# A raw StatsModels contrasts error ("only one level found: b ...") is not.
clear_level_msg(msg) = occursin("not seen when the model was fitted", msg) ||
                       occursin("different set or order of levels", msg)

function test_P3(fam, fit, nd_main, nds)
    dps = formula_dpars(fit)
    ref = try
        (link = predict_parameters(fit, nd_main; type = :link), resp = predict_parameters(fit, nd_main; type = :response))
    catch e
        return mkres("ERROR", "", nothing, "nd_main prediction itself errors, P3 cannot be evaluated: " * sprint(showerror, e))
    end
    rows = [4, 5, 6, 13, 14, 15]   # f == "b" rows of nd_main, same order as nd_subset
    variants = [
        ("Vector{String}", nds),
        ("CategoricalArray levels=[b]", setcol(nds, :f, categorical(nds.f))),
        ("CategoricalArray levels=[a,b,c]", setcol(nds, :f, categorical(nds.f; levels = ["a", "b", "c"]))),
    ]
    det = Dict{String,Any}(); bad = String[]; refused = String[]
    worst = 0.0
    for (nm, v) in variants
        try
            pl = predict_parameters(fit, v; type = :link); pr = predict_parameters(fit, v; type = :response)
            pm = predict(fit, v; type = :response)
            dev = maximum(vcat([maxabs(pl[d], ref.link[d][rows]) for d in dps],
                               [maxabs(pr[d], ref.resp[d][rows]) for d in dps],
                               [maxabs(pm, ref.resp[:mu][rows])]))
            worst = max(worst, dev)
            det[nm] = Dict("outcome" => "values", "max_abs_dev_vs_nd_main_rows" => dev)
            dev <= TOL || push!(bad, "$nm silent mismatch $(round(dev, sigdigits=4))")
        catch e
            msg = sprint(showerror, e)
            det[nm] = Dict("outcome" => "refused", "message" => msg)
            push!(refused, nm)
            clear_level_msg(msg) || push!(bad, "$nm refused with unclear message")
        end
    end
    st = isempty(bad) ? "PASS" : "FAIL"
    notes = isempty(bad) ? ("all variants equal nd_main rows" * (isempty(refused) ? "" : "; refused clearly: " * join(refused, ", "))) :
            join(bad, "; ")
    return mkres(st, "max abs deviation vs nd_main f=b rows (tol 1e-10)", worst, notes; details = det)
end

# ============================================================== P4 ==========
function test_P4(fam, fit, ndu)
    variants = [("Vector{String}", ndu),
                ("CategoricalArray", setcol(ndu, :f, categorical(ndu.f)))]
    det = Dict{String,Any}(); bad = String[]; msgs = String[]
    for (nm, v) in variants, (fn, call) in (("predict", () -> predict(fit, v)),
                                             ("predict_parameters", () -> predict_parameters(fit, v)))
        key = "$fn / $nm"
        try
            out = call()
            det[key] = Dict("outcome" => "returned values (no refusal)", "values" => out)
            push!(bad, "$key returned numbers for unseen level f = d")
        catch e
            msg = sprint(showerror, e)
            names_it = occursin("`f`", msg) || occursin(r"level\(s\) d\b", msg) || occursin("f: d", msg)
            det[key] = Dict("outcome" => "refused", "message" => msg, "names_factor_or_level" => names_it)
            push!(msgs, msg)
            names_it || push!(bad, "$key refused without naming f or level d")
        end
    end
    st = isempty(bad) ? "PASS" : "FAIL"
    notes = isempty(bad) ? "refused, message: " * first(unique(msgs), 1)[1] : join(bad, "; ")
    return mkres(st, "refusal naming factor/level", nothing, notes; details = det)
end

# ============================================================== P5 ==========
function allpreds(fit, nd)
    dps = formula_dpars(fit)
    pl = predict_parameters(fit, nd; type = :link); pr = predict_parameters(fit, nd; type = :response)
    return Dict(d => (link = pl[d], resp = pr[d]) for d in dps)
end
predmaxabs(a, b) = maximum(vcat([maxabs(a[d].link, b[d].link) for d in keys(b)], [maxabs(a[d].resp, b[d].resp) for d in keys(b)]))
predmaxrel(a, b) = maximum(vcat([maxrel(a[d].link, b[d].link) for d in keys(b)], [maxrel(a[d].resp, b[d].resp) for d in keys(b)]))

function test_P5(fam, spec, fit, data, forms, nd)
    det = Dict{String,Any}(); bad = String[]; notes = String[]
    base = try
        allpreds(fit, nd)
    catch e
        return mkres("ERROR", "", nothing, "nd_main prediction errors on the base fit: " * sprint(showerror, e))
    end
    dcat = setcol(data, :f, categorical(data.f))
    drel = setcol(data, :f, categorical(data.f; levels = ["c", "a", "b"]))
    fcat, ecat, tcat, _ = tryfit(forms, spec.fam, dcat)
    frel, erel, trel, _ = tryfit(forms, spec.fam, drel)
    det["fit_cat_error"] = errhead(ecat); det["fit_relevel_error"] = errhead(erel)
    det["fit_cat_seconds"] = tcat; det["fit_relevel_seconds"] = trel
    ndcat = setcol(nd, :f, categorical(nd.f))
    ndrel = setcol(nd, :f, categorical(nd.f; levels = ["c", "a", "b"]))
    function cmp!(label, fitx, ndx, refp, tol; rel = false)
        try
            p = allpreds(fitx, ndx)
            dev = rel ? predmaxrel(p, refp) : predmaxabs(p, refp)
            det[label] = dev
            dev <= tol || push!(bad, "$label = $(round(dev, sigdigits=4)) > $tol")
        catch e
            det[label] = "ERROR: " * sprint(showerror, e)
            push!(bad, "$label errored")
        end
    end
    # String fit with categorical newdata (both level orders)
    cmp!("charfit x catnewdata(default) vs charfit x String", fit, ndcat, base, TOL)
    cmp!("charfit x catnewdata(c,a,b) vs charfit x String", fit, ndrel, base, TOL)
    if fcat !== nothing
        det["coefnames_cat"] = fcat.coefnames
        cd = fcat.coefnames == fit.coefnames ? maxabs(fcat.theta, fit.theta) : Inf
        det["coef_char_vs_cat_maxabs"] = cd
        det["loglik_char_minus_cat"] = fit.loglik - fcat.loglik
        cd <= TOL || push!(bad, "coef char vs categorical(default) = $(round(cd, sigdigits=4))")
        cmp!("catfit x String vs charfit x String", fcat, nd, base, TOL)
        cmp!("catfit x catnewdata vs charfit x String", fcat, ndcat, base, TOL)
    else
        push!(bad, "categorical(default) refit errored: " * first(errhead(ecat), 200))
    end
    if frel !== nothing
        det["coefnames_relevel"] = frel.coefnames
        det["loglik_char_minus_relevel"] = fit.loglik - frel.loglik
        cmp!("relevelfit x String vs charfit x String (rel)", frel, nd, base, 1e-6; rel = true)
        cmp!("relevelfit x catnewdata(default) vs charfit x String (rel)", frel, ndcat, base, 1e-6; rel = true)
    else
        push!(bad, "categorical(c,a,b) refit errored: " * first(errhead(erel), 200))
    end
    # Int x column vs Float64 (same values)
    xi = Int[-1, 0, 2, -1, 0, 2, -1, 0, 2, -1, 0, 2, -1, 0, 2, -1, 0, 2]
    ndi = setcol(nd, :x, xi); ndf = setcol(nd, :x, Float64.(xi))
    try
        pf = allpreds(fit, ndf)
        cmp!("Int x vs Float64 x", fit, ndi, pf, 1e-12)
    catch e
        det["Int x vs Float64 x"] = "ERROR: " * sprint(showerror, e); push!(bad, "Float64 x newdata errored")
    end
    st = isempty(bad) ? "PASS" : "FAIL"
    return mkres(st, "coef/prediction agreement across predictor types", nothing,
                 isempty(bad) ? "char == categorical (coef & preds), relevel within 1e-6 rel, cross-type newdata and Int x agree" : join(bad, "; ");
                 details = det)
end

# ============================================================== P6 ==========
function test_P6(fit, nd)
    qn = [String(n) for n in names(DRModels) if occursin("quantile", lowercase(String(n)))]
    msg = try
        predict(fit, nd; type = :quantile); "predict(type = :quantile) returned values"
    catch e
        sprint(showerror, e)
    end
    return mkres("NA", "quantile prediction available", nothing,
                 "no quantile-prediction API in DRModels.jl exports (exported names containing 'quantile': " *
                 (isempty(qn) ? "none" : join(qn, ", ")) * "); predict(fit, nd_main; type = :quantile) -> " * msg)
end

# ============================================================== P7 ==========
relerr(a, b) = (length(a) == length(b) || return Inf; maximum(abs.(a .- b) ./ max.(abs.(b), 1e-300)))

function test_P7(fam, fit, nd)
    checks = []; notes = String[]
    V = try
        vcov(fit)
    catch e
        return mkres("NA", "", nothing, "vcov(fit) errors: " * sprint(showerror, e))
    end
    dps = formula_dpars(fit)
    vfin = all(isfinite, V[vcat([collect(blockrange(fit, d)) for d in dps]...), :])
    vfin || push!(notes, "vcov has non-finite entries in the formula blocks")
    try
        for type in (:link, :response)
            pps = predict_parameters(fit, nd; type = type, se = true)
            pp0 = predict_parameters(fit, nd; type = type)
            for d in dps
                r = blockrange(fit, d)
                η, X = hand_eta(fit, d, nd)
                Vd = V[r, r]
                sel = vec(sqrt.(max.(0.0, sum((X * Vd) .* X; dims = 2))))
                exp_se = type === :link ? sel : abs.(doc_deriv(fam, d, η)) .* sel
                push!(checks, check("pp_se[$d,$type] vs delta(doc link)", relerr(pps[d].se, exp_se), 1e-8))
                push!(checks, check("pp_value[$d,$type] == se=false value", maxabs(pps[d].value, pp0[d]), 0.0))
            end
            ps = predict(fit, nd; type = type, se = true)
            p0 = predict(fit, nd; type = type)
            r = blockrange(fit, :mu); η, X = hand_eta(fit, :mu, nd)
            sel = vec(sqrt.(max.(0.0, sum((X * V[r, r]) .* X; dims = 2))))
            exp_se = type === :link ? sel : abs.(doc_deriv(fam, :mu, η)) .* sel
            push!(checks, check("predict_se[mu,$type] vs delta(doc link)", relerr(ps.se, exp_se), 1e-8))
            push!(checks, check("predict_prediction[mu,$type] == se=false", maxabs(ps.prediction, p0), 0.0))
        end
    catch e
        push!(checks, (name = "se=true prediction errors", value = Inf, tol = 0.0, pass = false))
        push!(notes, "ERROR: " * sprint(showerror, e))
    end
    st, worst, n2, dd = summarize_checks(checks)
    return mkres(st, "max relative SE deviation vs independent delta method (tol 1e-8)", worst,
                 join(vcat(n2, notes), " | "); details = Dict("checks" => dd))
end

# ============================================================== P8 ==========
function test_P8(fam, fit, data, seed::Int)
    det = Dict{String,Any}(); notes = String[]
    Y = try
        simulate(fit; nsim = 1000, rng = Random.Xoshiro(seed + 100))
    catch e
        return mkres("ERROR", "", nothing, "simulate errors: " * sprint(showerror, e))
    end
    n = length(fit.means[:mu])
    det["class"] = string(typeof(Y)); det["size"] = collect(size(Y))
    det["colnames"] = "none (plain Matrix)"
    shape_ok = Y isa AbstractMatrix && size(Y) == (n, 1000)
    det["shape_ok_n_x_nsim"] = shape_ok
    y1 = simulate(fit; nsim = 1, rng = Random.Xoshiro(seed + 100))
    det["nsim1_class"] = string(typeof(y1)); det["nsim1_is_vector_len_n"] = y1 isa AbstractVector && length(y1) == n
    det["nsim1_equals_first_column"] = y1 == Y[:, 1]
    Y2 = simulate(fit; nsim = 1000, rng = Random.Xoshiro(seed + 100))
    det["rng_reproducible"] = Y == Y2
    Random.seed!(424242); a = rand()
    Random.seed!(424242); simulate(fit; nsim = 3, rng = Random.Xoshiro(1)); b = rand()
    det["explicit_rng_leaves_global_rng_untouched"] = a == b
    Random.seed!(77); s1 = simulate(fit; nsim = 2); Random.seed!(77); s2 = simulate(fit; nsim = 2)
    det["default_rng_reproducible_after_seed!"] = s1 == s2
    if fam in ("binomial", "beta_binomial")
        det["binomial_scale"] = all(isinteger, Y) && maximum(Y) > 1 ? "counts (successes)" : "proportions?"
        det["fitted_scale"] = "probability (fitted(fit) = mu)"
    end
    if fam == "gamma"
        det["gamma_sigma_is_shape_flag"] = DRModels._gamma_sigma_is_shape(fit)
    end
    E0, V0 = expected_moments(fam, fit)
    st0 = p8_stats(Y, E0, V0, data)
    det["b0"] = st0
    pass0 = abs(st0["z_mean"]) < 3 && (isnan(st0["z_var"]) || abs(st0["z_var"]) < 3)
    isnan(st0["z_var"]) && push!(notes, "variance test skipped (non-finite expected variance)")
    status = (shape_ok && det["rng_reproducible"] && pass0) ? "PASS" : "FAIL"
    if blockrange(fit, :resd) !== nothing
        sdg = re_sd(fit)[:g]
        Em, Vm = expected_moments(fam, fit; sd = sdg)
        stm = p8_stats(Y, Em, Vm, data)
        det["marginal"] = stm; det["sd_g"] = sdg
        passm = abs(stm["z_mean"]) < 3 && (isnan(stm["z_var"]) || abs(stm["z_var"]) < 3)
        det["draws_match"] = pass0 && passm ? "both (indistinguishable)" : pass0 ? "b = 0 (docstring)" : passm ? "marginal over b" : "neither"
        push!(notes, "ri: b=0 z_mean=$(round(st0["z_mean"], digits=2)) z_var=$(round(st0["z_var"], digits=2)); " *
                     "marginal z_mean=$(round(stm["z_mean"], digits=2)) z_var=$(round(stm["z_var"], digits=2)); draws match: " * det["draws_match"])
    else
        push!(notes, "z_mean=$(round(st0["z_mean"], digits=2)) z_var=$(round(st0["z_var"], digits=2))")
    end
    st0["reg_flag_gt4"] && push!(notes, "regression flag: max|t| = $(round(st0["reg_max_abs_t"], digits=2)) > 4")
    push!(notes, "rows |z|>3: $(st0["row_n_abs_z_gt3"]) (expected $(round(n*0.0027, digits=2))), max|z_i| $(round(st0["row_max_abs_z"], digits=2))")
    shape_ok || push!(notes, "shape not n x nsim")
    det["rng_reproducible"] || push!(notes, "rng not reproducible")
    return mkres(status, "z (global mean, batch-means variance) vs b=0 moments; |z|<3", [st0["z_mean"], st0["z_var"]],
                 join(notes, " | "); details = det)
end

# ============================================================== pred CSV ====
function write_pred_csv(path, fit, nd)
    rows = DataFrame(row = Int[], dpar = String[], type = String[], value = Float64[], se = Float64[])
    dps = try formula_dpars(fit) catch; Symbol[] end
    note = ""
    for type in (:link, :response)
        pps = try
            predict_parameters(fit, nd; type = type, se = true)
        catch e
            note *= "se=true error ($type): " * sprint(showerror, e) * "; "
            try
                Dict(d => (value = v, se = fill(NaN, length(v))) for (d, v) in predict_parameters(fit, nd; type = type))
            catch e2
                note *= "se=false error ($type): " * sprint(showerror, e2) * "; "
                nothing
            end
        end
        pps === nothing && continue
        for d in dps, i in 1:length(nd.x)
            push!(rows, (i, String(d), String(type), pps[d].value[i], pps[d].se[i]))
        end
    end
    CSV.write(path, rows)
    return note
end

# ============================================================== per cell ====
coefdict(fit) = Dict(String(p) => Dict("names" => ns, "values" => fit.theta[blockrange(fit, p)],
                                       "se" => sqrt.(abs.(diag(fit.vcov)[blockrange(fit, p)])))
                     for (p, ns) in fit.coefnames)

function fitinfo(fit)
    Dict{String,Any}("converged" => fit.converged, "loglik" => fit.loglik, "marginal" => String(fit.marginal),
                     "nobs" => fit.nobs, "blocks" => [String(p) => [first(r), last(r)] for (p, r) in fit.blocks],
                     "coef" => coefdict(fit), "re_sd" => re_sd(fit), "niterations" => DRModels.niterations(fit))
end

function serialize_fit(path, fit, nd)
    serialize(path, fit)
    back = deserialize(path)
    try
        a = predict_parameters(fit, nd; type = :link); b = predict_parameters(back, nd; type = :link)
        return all(a[d] == b[d] for d in keys(a))
    catch
        return back.theta == fit.theta
    end
end

function run_tests(fam, spec, fit, data, forms, nd, nds, ndu, seed; secondary = false)
    tests = Dict{String,Any}()
    for (id, f) in (("P1", () -> test_P1(fam, fit, data)),
                    ("P2", () -> test_P2(fam, fit, nd)),
                    ("P3", () -> test_P3(fam, fit, nd, nds)),
                    ("P4", () -> test_P4(fam, fit, ndu)),
                    ("P5", () -> test_P5(fam, spec, fit, data, forms, nd)),
                    ("P6", () -> test_P6(fit, nd)),
                    ("P7", () -> test_P7(fam, fit, nd)),
                    ("P8", () -> test_P8(fam, fit, data, seed)))
        secondary && id in ("P3", "P4", "P5", "P6") && continue
        t0 = time()
        tests[id] = try
            f()
        catch e
            println("    !! harness exception in $id: ", errstring(e, catch_backtrace()))
            mkres("ERROR", "", nothing, "harness exception: " * sprint(showerror, e))
        end
        r = tests[id]
        println("    $id: ", r["status"], "  ", first(string(r["notes"]), 400), "  [", round(time() - t0, digits = 1), "s]")
        flush(stdout)
    end
    return tests
end

function run_cell(row, nd, nds, ndu)
    fam = String(row.family); re = String(row.re); seed = Int(row.seed)
    cell = "$(fam)_$(re)"
    println("\n=== cell $(row.k): $cell  seed=$seed  file=$(row.file) ===")
    flush(stdout)
    spec = FAMSPEC[fam]; ri = re == "ri"
    data = readnt(String(row.file))
    forms, fstr = build_forms(spec, ri)
    out = Dict{String,Any}("family" => fam, "re" => re, "engine" => "julia", "engine_commit" => PIN,
                           "julia_version" => string(VERSION), "seed" => seed, "sim_seed" => seed + 100,
                           "formula" => fstr, "fallback" => nothing)
    fit, err, secs, warns = tryfit(forms, spec.fam, data)
    println("  fit default: ", fit === nothing ? "REFUSED/ERROR: " * err : "ok ($(round(secs, digits=1))s)")
    out["fit_seconds"] = secs; out["fit_warnings"] = warns
    if fit === nothing
        out["fit_error_first"] = err
        if spec.sigma
            forms1, fstr1 = build_forms(spec, ri; sigma1 = true)
            fit, err1, secs1, w1 = tryfit(forms1, spec.fam, data)
            out["fallback"] = Dict("formula" => fstr1, "fit_ok" => fit !== nothing, "error" => err1, "seconds" => secs1)
            println("  fit fallback sigma ~ 1: ", fit === nothing ? "REFUSED/ERROR: " * errhead(err1) : "ok")
            fit === nothing || (forms = forms1; out["formula_used"] = fstr1)
        else
            out["fallback"] = "no sigma formula to simplify; no retry"
        end
    end
    out["fit_ok"] = fit !== nothing
    out["fit_error"] = fit === nothing ? errhead(err) : nothing
    tests = Dict{String,Any}()
    if fit !== nothing
        merge!(out, fitinfo(fit))
        jls = joinpath(FITDIR, "$(cell).jls")
        out["serialized"] = jls; out["serialize_roundtrip_ok"] = serialize_fit(jls, fit, nd)
        out["pred_csv_note"] = write_pred_csv(joinpath(RES, "jl_$(cell)_pred.csv"), fit, nd)
        tests = run_tests(fam, spec, fit, data, forms, nd, nds, ndu, seed)
    else
        for id in ("P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8")
            tests[id] = mkres("NA", "", nothing, "fit refused by engine: " * first(errhead(err), 300))
        end
        CSV.write(joinpath(RES, "jl_$(cell)_pred.csv"),
                  DataFrame(row = Int[], dpar = String[], type = String[], value = Float64[], se = Float64[]))
    end
    for id in ("P9", "P10", "P11")
        tests[id] = mkres("NA", "", nothing, "not run by the Julia-native harness (parity/bridge agents own P9-P11)")
    end
    out["tests"] = tests
    # ---- marginal = :Laplace for ri cells -----------------------------------
    if ri
        lap = Dict{String,Any}("formula" => fstr)
        fl, el, sl, wl = tryfit(forms, spec.fam, data; marginal = :Laplace)
        lap["fit_ok"] = fl !== nothing; lap["error"] = errhead(el); lap["seconds"] = sl; lap["warnings"] = wl
        println("  fit marginal=:Laplace: ", fl === nothing ? "REFUSED/ERROR: " * errhead(el) : "ok ($(round(sl, digits=1))s)")
        if fl !== nothing
            merge!(lap, fitinfo(fl))
            jls = joinpath(FITDIR, "$(cell)_laplace.jls")
            lap["serialized"] = jls; lap["serialize_roundtrip_ok"] = serialize_fit(jls, fl, nd)
            lap["pred_csv_note"] = write_pred_csv(joinpath(RES, "jl_$(cell)_laplace_pred.csv"), fl, nd)
            println("  -- secondary tests on the :Laplace fit")
            lap["tests"] = run_tests(fam, spec, fl, data, forms, nd, nds, ndu, seed; secondary = true)
            if fit !== nothing
                lap["coef_maxabs_vs_default"] = fl.coefnames == fit.coefnames ? maxabs(fl.theta, fit.theta) : "coefnames differ"
                lap["loglik_minus_default"] = fl.loglik - fit.loglik
            end
        elseif spec.sigma && el !== nothing && occursin("non-constant `sigma`", el)
            # Laplace route needs sigma ~ 1 for NB2/Gamma/Beta; record that model too
            # (NOT the SPEC model: sigma ~ x; kept only as a labelled extra).
            forms1, fstr1 = build_forms(spec, ri; sigma1 = true)
            f1, e1, s1, _ = tryfit(forms1, spec.fam, data; marginal = :Laplace)
            lap["sigma1_extra"] = Dict("formula" => fstr1, "fit_ok" => f1 !== nothing, "error" => errhead(e1), "seconds" => s1)
            println("  fit marginal=:Laplace with sigma ~ 1 (extra, not the SPEC model): ",
                    f1 === nothing ? "REFUSED/ERROR: " * errhead(e1) : "ok")
            if f1 !== nothing
                merge!(lap["sigma1_extra"], fitinfo(f1))
                jls = joinpath(FITDIR, "$(cell)_laplace_sigma1.jls")
                lap["sigma1_extra"]["serialized"] = jls
                lap["sigma1_extra"]["serialize_roundtrip_ok"] = serialize_fit(jls, f1, nd)
            end
        end
        out["laplace"] = lap
    end
    writejson(joinpath(RES, "jl_$(cell).json"), out)
    return out
end

# ============================================================== main ========
function main(args)
    cells = CSV.read(joinpath(DATA, "cells.csv"), DataFrame)
    nd = readnt("nd_main.csv"); nds = readnt("nd_subset.csv"); ndu = readnt("nd_unseen_f.csv")
    mkpath(FITDIR)
    summ = DataFrame()
    for row in eachrow(cells)
        cell = "$(row.family)_$(row.re)"
        (isempty(args) || cell in args) || continue
        t0 = time()
        out = try
            run_cell(row, nd, nds, ndu)
        catch e
            println("  !! cell-level exception: ", errstring(e, catch_backtrace(); nframes = 8))
            Dict{String,Any}("family" => String(row.family), "re" => String(row.re), "fit_ok" => false,
                             "fit_error" => "harness exception: " * sprint(showerror, e), "tests" => Dict{String,Any}())
        end
        tests = get(out, "tests", Dict{String,Any}())
        stat(id) = haskey(tests, id) ? tests[id]["status"] : "NA"
        p8 = haskey(tests, "P8") ? tests["P8"] : nothing
        p8d = p8 === nothing ? nothing : p8["details"]
        getz(sec, k) = (p8d isa AbstractDict && haskey(p8d, sec)) ? p8d[sec][k] : NaN
        lap = get(out, "laplace", nothing)
        push!(summ, (cell = cell, family = String(row.family), re = String(row.re),
                     fit_ok = get(out, "fit_ok", false),
                     fallback = string(get(out, "fallback", nothing) === nothing ? "" : "sigma~1 retry attempted"),
                     converged = string(get(out, "converged", "")),
                     loglik = Float64(get(out, "loglik", NaN)),
                     marginal = string(get(out, "marginal", "")),
                     re_sd_g = Float64(get(get(out, "re_sd", Dict()), :g, NaN)),
                     laplace = lap === nothing ? "n/a" : (lap["fit_ok"] ? "ok" : "refused"),
                     laplace_loglik = lap === nothing || !lap["fit_ok"] ? NaN : Float64(lap["loglik"]),
                     P1 = stat("P1"), P2 = stat("P2"), P3 = stat("P3"), P4 = stat("P4"),
                     P5 = stat("P5"), P6 = stat("P6"), P7 = stat("P7"), P8 = stat("P8"),
                     P8_zmean_b0 = getz("b0", "z_mean"), P8_zvar_b0 = getz("b0", "z_var"),
                     P8_zmean_marg = getz("marginal", "z_mean"), P8_zvar_marg = getz("marginal", "z_var"),
                     P8_draws_match = p8d isa AbstractDict ? string(get(p8d, "draws_match", "")) : "",
                     seconds = round(time() - t0, digits = 1)); promote = true)
        CSV.write(joinpath(RES, isempty(args) ? "jl_summary.csv" : "jl_summary_partial.csv"), summ)
    end
    println("\nDone ", Libc.strftime(time()))
end

main(ARGS)
