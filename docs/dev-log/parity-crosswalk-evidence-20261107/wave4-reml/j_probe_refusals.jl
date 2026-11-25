using DRModels, Random, LinearAlgebra
import Distributions
G=40; m=12; rng=MersenneTwister(7)
ids=["a$(i)" for i in randperm(rng,G)]
A=Matrix(0.35 .^ abs.(reshape(1:G,:,1) .- reshape(1:G,1,:)))
g=repeat(ids,inner=m); gidx=repeat(1:G,inner=m)
z0g=randn(rng,G); z1g=randn(rng,G)
x=randn(rng,G*m); zz=randn(rng,G*m)
L=cholesky(Symmetric(A)).L; u0,u1=L*randn(rng,G),L*randn(rng,G)
mu=0.2 .+0.3 .*x .+ (exp.(-0.9 .+0.3 .*z0g).*u0)[gidx] .+ x.*(exp.(-1.0 .+0.3 .*z1g).*u1)[gidx]
y=mu .+ 0.4 .*randn(rng,length(mu))
data=(; y, x, z=zz, z0=z0g[gidx], z1=z1g[gidx], g, h=repeat(1:12,outer=G))
function tryfit(label, f)
  for meth in (:ML,:REML)
    try r=f(meth); println("OK     ",meth," ",label," conv=",r.converged," ll=",round(loglik(r);digits=4))
    catch e; println("REFUSE ",meth," ",label,": ",first(split(sprint(showerror,e),'\n')) |> s->s[1:min(400,end)]) end
  end
end
tryfit("ordinary q2", m->drm(bf(@formula(y ~ x + (1 + x | g)),@formula(sigma ~ 1),@formula(sd(g, coef(intercept)) ~ z0),@formula(sd(g, coef(x)) ~ z1)),Gaussian();data,method=m))
tryfit("ordinary q3", m->drm(bf(@formula(y ~ x + z + (1 + x + z | g)),@formula(sigma ~ 1),@formula(sd(g, coef(intercept)) ~ z0),@formula(sd(g, coef(x)) ~ z1),@formula(sd(g, coef(z)) ~ z0)),Gaussian();data,method=m))
tryfit("animal q2", m->drm(bf(@formula(y ~ x + animal(1 + x | g)),@formula(sigma ~ 1),@formula(sd(g, animal, coef(intercept)) ~ z0),@formula(sd(g, animal, coef(x)) ~ z1)),Gaussian();data,A,method=m))
tryfit("relmat q2", m->drm(bf(@formula(y ~ x + relmat(1 + x | g)),@formula(sigma ~ 1),@formula(sd(g, relmat, coef(intercept)) ~ z0),@formula(sd(g, relmat, coef(x)) ~ z1)),Gaussian();data,K=A,method=m))
tryfit("joint mu+sigma ordinary", m->drm(bf(@formula(y ~ x + (1 | g)),@formula(sigma ~ 1 + (1 | g)),@formula(sd(g) ~ z0),@formula(sd(g, sigma) ~ z0)),Gaussian();data,method=m))
tryfit("ordinary iid sd(g)", m->drm(bf(@formula(y ~ x + (1 | g)),@formula(sigma ~ 1),@formula(sd(g) ~ z0)),Gaussian();data,method=m))
tryfit("sigma animal intercept", m->drm(bf(@formula(y ~ x),@formula(sigma ~ 1 + animal(1 | g)),@formula(sd(g, animal, sigma) ~ z0)),Gaussian();data,A,method=m))
