using DRModels, Random, LinearAlgebra, DelimitedFiles
O = @__DIR__
include(joinpath(O,"fix_joint.jl")); include(joinpath(O,"fix_structured.jl"))
function dump(name, d, cols)
  open(joinpath(O,"data_$name.csv"),"w") do io
    println(io, join(cols,","))
    for i in eachindex(d.y); println(io, join((getproperty(d,c)[i] for c in cols),",")); end
  end
end
function save(name, fit)
  se = stderror(fit); pos = 0
  open(joinpath(O,"jcoef_$name.csv"),"w") do io
    println(io,"block,k,est,se")
    for (k,b) in fit.blocks
      est = vec(coef(fit,k))
      for i in eachindex(est); pos+=1; println(io,"$k,$i,$(est[i]),$(se[pos])"); end
    end
  end
  write(joinpath(O,"jll_$name.txt"), repr(loglik(fit)))
  println(name," conv=",fit.converged," ll=",loglik(fit)," blocks=",[p.first for p in fit.blocks])
end
cases = [("slope", (;)), ("int", (; seed=20261102, n_id=30, n_site=40, n_each=24, slope=false)),
         ("big", (; seed=20261109, n_id=200, n_site=200, n_each=12, slope=true)),
         ("bigint", (; seed=20261110, n_id=200, n_site=200, n_each=12, slope=false))]
for (nm, kw) in cases
  fx = _gjs_fixture(; kw...); d = fx.data
  dump("6a_$nm", d, (:y,:x,:z,:id,:site,:w,:v))
  sl = nm in ("slope","big")
  fm = sl ? bf(@formula(y ~ x + (1 | id)), @formula(sigma ~ 1 + (0 + z | site)), @formula(sd(id) ~ w), @formula(sd(site, sigma, coef(z)) ~ v)) :
            bf(@formula(y ~ x + (1 | id)), @formula(sigma ~ 1 + (1 | site)), @formula(sd(id) ~ w), @formula(sd(site, sigma) ~ v))
  t0=time(); fit = drm(fm, Gaussian(); data = d); println("time ",time()-t0)
  save("6a_$nm", fit)
end
for (kind, seed) in ((:animal, 2026110102), (:relmat, 2026110103))
  fx = _gss_fixture(; seed); d = fx.data
  dump("6b_$kind", d, (:y,:x,:id,:z))
  writedlm(joinpath(O,"K_$kind.csv"), fx.K, ',')
  t0=time(); fit = _gss_fit(fx, kind); println("time ",time()-t0)
  save("6b_$kind", fit)
end
