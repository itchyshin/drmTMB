include("case_c_h.jl")
function run_from(th0)
  last_b .= 0
  od = Optim.OnceDifferentiable(nll, grad!, th0)
  r = Optim.optimize(od, th0, Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking()), Optim.Options(g_tol = 1e-6, iterations = 250))
  th = Optim.minimizer(r); gf = zeros(7); grad!(gf, th)
  @printf("f=%.7f  gmax/n=%.2e iters=%d  th=%s\n", nll(th), maximum(abs, gf)/length(y), Optim.iterations(r), round.(th, digits=2))
end
for (a,b,r) in ((log(0.7), log(0.7), 0.0), (log(0.7), log(0.7), 1.0), (log(0.4), log(0.8), -1.0), (log(0.4), log(1.5), 0.5))
  th0 = copy(theta0); th0[3:4] .= Xsd0 \ fill(a, G); th0[5:6] .= Xsd1 \ fill(b, G); th0[7] = r
  run_from(th0)
end
