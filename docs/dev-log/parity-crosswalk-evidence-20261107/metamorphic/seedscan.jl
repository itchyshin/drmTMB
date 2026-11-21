# Seed scan: how often does the base fit converge, and does the row-permutation invariance hold, over 8 data seeds?
ENV["METAMORPHIC_LIB"] = "1"
using DRModels, Test
include(joinpath(ENV["WT"], "test", "test_metamorphic_sd_routes.jl"))
const M = TestMetamorphicSDRoutes
skip = ("gauss_ord_q3", "gauss_ord_q4", "binom_ord_q2", "gamma_ord_q2", "gauss_lab_animal")
open(ARGS[1], "w") do io
    for (r0, _) in M.ROUTES
        (isempty(r0.fixture[1]) && r0.name ∉ skip) || continue
        for seed in 1:8
            r = M.Route(; (k => getfield(r0, k) for k in fieldnames(M.Route) if k != :seed)..., seed)
            t0 = time()
            line = try
                b = M.basefit(r)
                st, det = b.fit.converged ? M.p_perm(b) : ("NOCONV", "")
                join((r.name, seed, b.fit.converged, st, round(loglikelihood(b.fit); digits = 3), round(maximum(abs, b.fit.theta); digits = 1)), '\t')
            catch e
                join((r.name, seed, "ERROR", first(sprint(showerror, e), 60), "", ""), '\t')
            end
            println(io, line, '\t', round(time() - t0; digits = 1)); flush(io)
        end
    end
end
