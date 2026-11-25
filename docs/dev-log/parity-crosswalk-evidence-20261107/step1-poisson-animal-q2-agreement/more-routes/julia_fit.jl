# usage: julia --project=<drmjl-q2> julia_fit.jl <A|B|C|D>
route = ARGS[1]
O = "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-more/" * route
include(joinpath(O, "fixture.jl"))
using DelimitedFiles
fx = route == "A" ? _poisson_relmat_q2_fixture() : route == "B" ? _nb2_animal_q2_fixture() : _gq2_fixture()
d = fx.data
Kmat = route == "A" || route == "B" ? fx.A : fx.C
fam = route == "A" ? Poisson() : route == "B" ? NegBinomial2() : Gaussian()
term, lev = route == "A" || route == "D" ? ("relmat", "relmat") : ("animal", "animal")
open(joinpath(O,"data.csv"),"w") do io
  println(io,"y,x,z0,z1,g")
  for i in eachindex(d.y); println(io, join((d.y[i],d.x[i],d.z0[i],d.z1[i],d.g[i]),",")); end
end
ids = unique(d.g)
writedlm(joinpath(O,"A.csv"), Kmat, ',')
open(joinpath(O,"A_ids.csv"),"w") do io; println(io,"id"); foreach(s->println(io,s), ids); end
mu = term == "animal" ? @formula(y ~ x + animal(1 + x | g)) : @formula(y ~ x + relmat(1 + x | g))
s0 = term == "animal" ? @formula(sd(g, animal, coef(intercept)) ~ z0) : @formula(sd(g, relmat, coef(intercept)) ~ z0)
s1 = term == "animal" ? @formula(sd(g, animal, coef(x)) ~ z1) : @formula(sd(g, relmat, coef(x)) ~ z1)
formula = route == "A" ? bf(mu, s0, s1) : bf(mu, @formula(sigma ~ 1), s0, s1)
kw = term == "animal" ? (; A = Kmat) : (; K = Kmat)
t = @elapsed fit = drm(formula, fam; data = d, kw...)
println("time=", t, " converged=", fit.converged, " ll=", loglikelihood(fit))
nb = route == "A" ? 3 : 4
names_ = route == "A" ? ("mu","sd_intercept","sd_x") : ("mu","sigma","sd_intercept","sd_x")
println(first.(fit.blocks[1:nb]))
sev = stderror(fit); println("len se=", length(sev), " theta=", length(fit.theta))
open(joinpath(O,"julia_coef.csv"),"w") do io
  println(io,"block,term,est,se")
  pos = 0
  for (bi,b) in enumerate(fit.blocks[1:nb])
    est = vec(coef(fit, first(b)))
    for k in eachindex(est); pos += 1; println(io, "$(names_[bi]),$k,$(est[k]),$(sev[pos])"); end
  end
end
open(joinpath(O,"julia_ll.txt"),"w") do io; println(io, repr(loglikelihood(fit)), "\n", fit.converged); end
