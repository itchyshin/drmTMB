using DRModels, DelimitedFiles
cd("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/binom-probe")
nwk = strip(read("tree.nwk", String))
cc = readdlm("coords.csv", ',', skipstart=1); coords = Dict(String(cc[i,1]) => [Float64(cc[i,2]), Float64(cc[i,3])] for i in 1:size(cc,1))
for kind in (:phylo, :spatial)
  M = readdlm(kind === :phylo ? "data_phylo.csv" : "data_spatial.csv", ',', skipstart=1)
  d = (; id = String.(M[:,1]), x = Float64.(M[:,2]), z0 = Float64.(M[:,3]), z1 = Float64.(M[:,4]), y = Float64.(M[:,5]))
  f = kind === :phylo ? bf(@formula(y ~ x + phylo(1 + x | id)), @formula(sd(id, phylogenetic, coef(intercept)) ~ z0), @formula(sd(id, phylogenetic, coef(x)) ~ z1)) :
        bf(@formula(y ~ x + spatial(1 + x | id)), @formula(sd(id, spatial, coef(intercept)) ~ z0), @formula(sd(id, spatial, coef(x)) ~ z1))
  kw = kind === :phylo ? (; tree = nwk) : (; coords)
  for lk in (:logit, :probit)
    try fit = drm(f, Binomial(lk); data = d, kw...); println(kind, " ", lk, " OK ll=", loglikelihood(fit))
    catch e; println(kind, " ", lk, " ERR: ", sprint(showerror, e)); end
  end
end
