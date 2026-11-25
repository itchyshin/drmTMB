using DRModels, Random, LinearAlgebra
import Distributions
G=48; m=24; rng=MersenneTwister(7)
ids=["a$(i)" for i in randperm(rng,G)]
R=0.35 .^ abs.(reshape(1:G,:,1) .- reshape(1:G,1,:)); A=Matrix(R)
g=repeat(ids,inner=m); gidx=repeat(1:G,inner=m)
z0g=ifelse.(randperm(rng,G).<=G÷2,-1.0,1.0); z1g=collect(range(-1,1;length=G))[randperm(rng,G)]
x=repeat(collect(range(-1.2,1.2;length=m)),outer=G)
L=cholesky(Symmetric(A)).L; u0,u1=L*randn(rng,G),L*randn(rng,G)
mu=0.2 .+0.3 .*x .+ (exp.(-0.9 .+0.35 .*z0g).*u0)[gidx] .+ x.*(exp.(-1.0 .+0.45 .*z1g).*u1)[gidx]
y=mu .+ 0.4 .*randn(rng,length(mu))
data=(; y, x, z0=z0g[gidx], z1=z1g[gidx], g, h=repeat(1:24,outer=G))
function tryfit(label, f)
    try t=@elapsed r=f(); println("OK   ",label," conv=",r.converged," t=",round(t;digits=1))
    catch e; println("FAIL ",label,": ",first(split(sprint(showerror,e),'\n')) |> s->s[1:min(220,end)]) end
end
tryfit("gauss animal q2 coefSD", ()->drm(bf(@formula(y ~ x + animal(1 + x | g)),@formula(sigma ~ 1),@formula(sd(g, animal, coef(intercept)) ~ z0),@formula(sd(g, animal, coef(x)) ~ z1)),Gaussian();data,A))
tryfit("gauss relmat q2 coefSD", ()->drm(bf(@formula(y ~ x + relmat(1 + x | g)),@formula(sigma ~ 1),@formula(sd(g, relmat, coef(intercept)) ~ z0),@formula(sd(g, relmat, coef(x)) ~ z1)),Gaussian();data,K=A))
tryfit("gauss ordinary q2 coefSD", ()->drm(bf(@formula(y ~ x + (1 + x | g)),@formula(sigma ~ 1),@formula(sd(g, coef(intercept)) ~ z0),@formula(sd(g, coef(x)) ~ z1)),Gaussian();data))
tryfit("gauss sigma animal intercept", ()->drm(bf(@formula(y ~ x),@formula(sigma ~ 1 + animal(1 | g)),@formula(sd(g, animal, sigma) ~ z0)),Gaussian();data,A))
tryfit("gauss mu+sigma ordinary", ()->drm(bf(@formula(y ~ x + (1 | g)),@formula(sigma ~ 1 + (1 | g)),@formula(sd(g) ~ z0),@formula(sd(g, sigma) ~ z0)),Gaussian();data))
