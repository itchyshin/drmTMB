include("case_c_h.jl")
od = Optim.OnceDifferentiable(nll, grad!, theta0)
res = Optim.optimize(od, theta0, Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking()),
   Optim.Options(g_tol = 1e-6, iterations = 250, store_trace=true, extended_trace=true))
println(res)
for t in res.trace; @printf("%3d f=%.8f gnorm=%.2e  th=%s\n", t.iteration, t.value, t.g_norm, round.(t.metadata["x"], digits=3)); end
