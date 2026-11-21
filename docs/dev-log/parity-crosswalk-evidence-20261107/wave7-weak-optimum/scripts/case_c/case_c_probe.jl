include("case_c_h.jl")
th = [-0.151, 0.157, -1.109, 0.013, -8.995, -7.909, -10.019]
od = Optim.OnceDifferentiable(nll, grad!, theta0)
res = Optim.optimize(od, theta0, Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking()), Optim.Options(g_tol = 1e-6, iterations = 250))
th = Optim.minimizer(res); println(th)
f0 = nll(th); println("f0=", f0)
for j in eachindex(th)
  h = 2e-4*(1+abs(th[j])); e = zeros(7); e[j]=h
  println(j, "  +:", nll(th .+ e) - f0, "  -:", nll(th .- e) - f0)
end
