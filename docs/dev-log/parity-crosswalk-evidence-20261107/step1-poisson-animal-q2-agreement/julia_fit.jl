include("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/fixture.jl")
using DelimitedFiles
O = "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2"
fx = _poisson_animal_q2_fixture()
d = fx.data
open(joinpath(O,"data.csv"),"w") do io
  println(io,"y,x,z0,z1,g")
  for i in eachindex(d.y); println(io, join((Int(d.y[i]),d.x[i],d.z0[i],d.z1[i],d.g[i]),",")); end
end
ids = unique(d.g)  # order of A rows = ids order by gidx
writedlm(joinpath(O,"A.csv"), fx.A, ',')
open(joinpath(O,"A_ids.csv"),"w") do io; println(io,"id"); foreach(s->println(io,s), ids); end
formula = bf(@formula(y ~ x + animal(1 + x | g)),
    @formula(sd(g, animal, coef(intercept)) ~ z0),
    @formula(sd(g, animal, coef(x)) ~ z1))
fit = drm(formula, Poisson(); data = d, A = fx.A)
println("converged=", fit.converged, " ll=", loglikelihood(fit))
println(fit.blocks[1:3] .|> first)
sev = stderror(fit); println("len se=", length(sev), " theta=", length(fit.theta))
open(joinpath(O,"julia_coef.csv"),"w") do io
  println(io,"block,term,est,se")
  pos = 0
  for (bi,b) in enumerate(fit.blocks[1:3])
    est = vec(coef(fit, first(b)))
    for k in eachindex(est); pos += 1; println(io, "$(("mu","sd_intercept","sd_x")[bi]),$k,$(est[k]),$(sev[pos])"); end
  end
end
open(joinpath(O,"julia_ll.txt"),"w") do io; println(io, loglikelihood(fit)); end
