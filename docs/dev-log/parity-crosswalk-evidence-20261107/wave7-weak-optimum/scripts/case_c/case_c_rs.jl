include("case_c_h.jl")
function run_from(th0)
  od = Optim.OnceDifferentiable(nll, grad!, th0)
  r = Optim.optimize(od, th0, Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking()), Optim.Options(g_tol = 1e-6, iterations = 250))
  th = Optim.minimizer(r); gf = zeros(7); grad!(gf, th)
  @printf("f=%.9f  gmax/n=%.2e iters=%d status=%s\n", nll(th), maximum(abs, gf)/length(y), Optim.iterations(r), string(Optim.converged(r)))
  th
end
let; th = run_from(theta0)
for k in 1:4; th = run_from(th); end; end
