include("case_c_h.jl")
th = [-0.15088265325041833, 0.15666157785159493, -1.108608003630318, 0.013434753532268265, -8.994925616545407, -7.909232088338465, -10.019015734104176]
e = zeros(7); e[6]=1.6e-3; tp = th .+ e
f0 = nll(th); b_warm = copy(last_b)
pmu = 2; r0 = 3:4; r1 = 5:6; rc = 7
gamma = tp[rc]; rho = tanh(gamma); sech = D._binomial_stable_sech(gamma); den = sech^2
Rinv = [1.0 -rho; -rho 1.0] ./ den
Qjoint = kron(Q, sparse(Rinv))
scale0 = D._binomial_sd_scale(Xsd0*tp[r0]); scale1 = D._binomial_sd_scale(Xsd1*tp[r1])
load1 = x .* scale1[gidx]
eta0 = Xmu * tp[1:2]
function run(b0; maxiter=80, verbose=true)
  b = copy(b0)
  function joint(bb)
    value = 0.5 * dot(bb, Qjoint * bb)
    for i in eachindex(y)
        gi = gidx[i]
        value += D._laplace_value(Val(:binomial), aux, i, eta0[i] + scale0[gi]*bb[2gi-1] + load1[i]*bb[2gi])
    end
    value
  end
  for it in 1:maxiter
    grad = Qjoint * b
    I = Int[]; J = Int[]; V = Float64[]
    for i in eachindex(y)
        gi = gidx[i]; j0, j1 = 2gi-1, 2gi; l0, l1 = scale0[gi], load1[i]
        eta = eta0[i] + l0*b[j0] + l1*b[j1]
        _, d1, d2, _ = D._laplace_v123(Val(:binomial), aux, i, eta)
        grad[j0] += l0*d1; grad[j1] += l1*d1
        append!(I, (j0,j0,j1,j1)); append!(J,(j0,j1,j0,j1)); append!(V, (d2*l0^2, d2*l0*l1, d2*l0*l1, d2*l1^2))
    end
    H = Qjoint + sparse(I,J,V,2G,2G)
    ch = cholesky(Symmetric(H); check=false)
    if !issuccess(ch); println(it, " chol fail"); return b, false; end
    step = ch \ grad
    f0j = joint(b)
    verbose && @printf("it %2d |step|=%.3e |grad|=%.3e joint=%.10f  amount-accepted:", it, norm(step), norm(grad), f0j)
    if norm(step) <= 1e-10*(1+norm(b)); println(" converged tol"); return b, true; end
    if norm(step) <= 1e-7*(1+norm(b)); println(" converged 1e-7"); return b, true; end
    amount=1.0; acc=false
    while amount >= 1e-5
      trial = b .- amount.*step
      if joint(trial) <= f0j; b=trial; acc=true; break; end
      amount *= 0.5
    end
    verbose && println(acc ? " $amount" : " NONE")
    acc || return b, false
  end
  return b, false
end
println("--- warm start"); run(b_warm)
println("--- cold start"); run(zeros(2G))
