using DRModels, DelimitedFiles, LinearAlgebra
O = "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-nb2relmat/"
include(joinpath(O,"fixture.jl"))
fx = _nb2_relmat_q2_fixture(); d = fx.data; K = fx.A
open(joinpath(O,"data.csv"),"w") do io
  println(io,"y,x,z0,z1,g")
  for i in eachindex(d.y); println(io, join((d.y[i],d.x[i],d.z0[i],d.z1[i],d.g[i]),",")); end
end
ids = unique(d.g)
writedlm(joinpath(O,"K.csv"), K, ',')
open(joinpath(O,"K_ids.csv"),"w") do io; println(io,"id"); foreach(s->println(io,s), ids); end
formula = bf(@formula(y ~ x + relmat(1 + x | g)), @formula(sigma ~ 1),
  @formula(sd(g, relmat, coef(intercept)) ~ z0), @formula(sd(g, relmat, coef(x)) ~ z1))
t = @elapsed fit = drm(formula, NegBinomial2(); data = d, K = K)
println("time=", t, " converged=", fit.converged, " ll=", loglikelihood(fit))
println(first.(fit.blocks[1:4]))
sev = stderror(fit)
names_ = ("mu","sigma","sd_intercept","sd_x")
open(joinpath(O,"julia_coef.csv"),"w") do io
  println(io,"block,term,est,se"); pos = 0
  for (bi,b) in enumerate(fit.blocks[1:4])
    est = vec(coef(fit, first(b)))
    for k in eachindex(est); pos += 1; println(io, "$(names_[bi]),$k,$(est[k]),$(sev[pos])"); end
  end
end
open(joinpath(O,"julia_ll.txt"),"w") do io; println(io, repr(loglikelihood(fit)), "\n", fit.converged); end
