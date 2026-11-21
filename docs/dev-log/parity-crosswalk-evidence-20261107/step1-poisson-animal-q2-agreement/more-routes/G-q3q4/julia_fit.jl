include("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-q34/fixture.jl")
using DelimitedFiles
O = "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-q34"
for q in (3,4)
  fx = _q34_fixture(q; G=150, m=10, seed=777+q)
  d = fx.data
  cols = q==3 ? (:y,:x,:z,:w,:id) : (:y,:x,:z,:u,:w,:id)
  open(joinpath(O,"data$q.csv"),"w") do io
    println(io, join(cols,","))
    for i in eachindex(d.y); println(io, join((getproperty(d,c)[i] for c in cols),",")); end
  end
  t0=time()
  fit = drm(_q34_formula(fx), Gaussian(); data = d)
  println("q$q converged=", fit.converged, " ll=", loglik(fit), " t=", time()-t0)
  println([p.first for p in fit.blocks])
  se = stderror(fit)
  open(joinpath(O,"julia_coef$q.csv"),"w") do io
    println(io,"block,k,est,se"); pos=0
    for (k,b) in fit.blocks
      est = vec(coef(fit,k))
      for i in eachindex(est); pos+=1; println(io,"$k,$i,$(est[i]),$(se[pos])"); end
    end
  end
  A,Rm,beta,sigma = _q34_parts(fit,fx)
  writedlm(joinpath(O,"julia_R$q.csv"), Matrix(Rm), ',')
  open(joinpath(O,"julia_ll$q.txt"),"w") do io; println(io, repr(loglik(fit))); end
  println("length se=",length(se)," total=",sum(length(coef(fit,p.first)) for p in fit.blocks))
end
