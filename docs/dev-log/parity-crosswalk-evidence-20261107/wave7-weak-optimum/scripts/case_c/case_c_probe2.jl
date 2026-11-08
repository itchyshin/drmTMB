include("case_c_h.jl")
th = [-0.15088265325041833, 0.15666157785159493, -1.108608003630318, 0.013434753532268265, -8.994925616545407, -7.909232088338465, -10.019015734104176]
f0 = nll(th); println("f0=", f0)
for hh in (2e-3, 1.6e-3, 1e-3, 5e-4, 2e-4, 1e-4, 1e-5)
  e = zeros(7); e[6] = hh
  # warm and cold
  tp = th .+ e
  v1 = nll(tp); last_b .= 0
  println(hh, " warm/cold nll-f0: ", v1-f0)
end
# diagnose inner solve directly at theta+h (cold start)
e = zeros(7); e[6]=1.6e-3; tp = th .+ e
gamma = tp[7]; rho = tanh(gamma); sech = D._binomial_stable_sech(gamma); println("sech=", sech, " den=", sech^2)
Rinv = [1.0 -rho; -rho 1.0] ./ sech^2
println("Rinv entries ", Rinv)
sc1 = D._binomial_sd_scale(Xsd1*tp[5:6]); println("scale1 range ", extrema(sc1))
sc0 = D._binomial_sd_scale(Xsd0*tp[3:4]); println("scale0 range ", extrema(sc0))
