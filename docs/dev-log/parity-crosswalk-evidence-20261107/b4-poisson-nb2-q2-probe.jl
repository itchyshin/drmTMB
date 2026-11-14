using DRModels, Test, Random, LinearAlgebra
import Distributions
function fx(fam; G=48, m=24, seed=202611071)
    rng = MersenneTwister(seed); ids=["animal_$(i)" for i in randperm(rng,G)]
    R = 0.35 .^ abs.(reshape(1:G,:,1) .- reshape(1:G,1,:))
    A = Matrix(R); group=repeat(ids,inner=m); gidx=repeat(1:G,inner=m)
    z0g = ifelse.(randperm(rng,G).<=G÷2,-1.0,1.0); z1g=collect(range(-1,1;length=G))[randperm(rng,G)]
    z0,z1=z0g[gidx],z1g[gidx]; x=repeat(collect(range(-1.2,1.2;length=m)),outer=G)
    L=cholesky(Symmetric(A)).L; u0,u1=L*randn(rng,G),L*randn(rng,G)
    eta=0.2 .+ 0.3 .*x .+ (exp.(-0.9 .+ 0.35 .*z0g).*u0)[gidx] .+ x.*(exp.(-1.0 .+ 0.45 .*z1g).*u1)[gidx]
    y = fam=="poisson" ? Float64.([rand(rng,Distributions.Poisson(exp(v))) for v in eta]) :
        Float64.([rand(rng,Distributions.NegativeBinomial(5.0, 5.0/(5.0+exp(v)))) for v in eta])
    (; data=(; y, x, z0, z1, g=group), A)
end
for (name,fam) in (("poisson",Poisson()),("nb2",NegBinomial2()))
    f=fx(name)
    sig = name=="poisson" ? "" : "sigma ~ 1,"
    args = Any[@formula(y ~ x + animal(1 + x | g))]
    name=="nb2" && push!(args,@formula(sigma ~ 1))
    push!(args,@formula(sd(g, animal, coef(intercept)) ~ z0),@formula(sd(g, animal, coef(x)) ~ z1))
    try
        fm=bf(args...); t=@elapsed fit=drm(fm,fam;data=f.data,A=f.A)
        println(name," converged=",fit.converged," t=",round(t;digits=1)," blocks=",first.(fit.blocks))
        for b in fit.blocks[end-1:end]; println("  ",b[1]," ",coef(fit,b[1])); end
    catch e
        println(name," THREW: ",sprint(showerror,e)[1:min(400,end)])
    end
end
