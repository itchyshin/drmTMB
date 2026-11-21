using DRModels, Random, LinearAlgebra, DelimitedFiles
O = "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-q2ord"
G, m = 150, 10
rng = MersenneTwister(20261107)
w0g = collect(range(-1.5, 1.5; length = G))[randperm(rng, G)]
w1g = collect(range(-1.5, 1.5; length = G))[randperm(rng, G)]
gi = repeat(1:G, inner = m); n = G*m
x = randn(rng, n); y = 0.2 .+ 0.5 .* x .+ 0.4 .* randn(rng, n)
Rm = [1 0.4; 0.4 1.0]
for g in 1:G
    D = Diagonal(exp.([-0.5 + 0.5*w0g[g], -0.8 - 0.4*w1g[g]]))
    b = cholesky(Symmetric(D*Rm*D)).L * randn(rng, 2)
    rows = ((g-1)*m+1):(g*m); y[rows] .+= b[1] .+ x[rows] .* b[2]
end
d = (; y, x, w0 = w0g[gi], w1 = w1g[gi], id = ["g$(g)" for g in gi])
open(joinpath(O,"data.csv"),"w") do io
    println(io,"y,x,w0,w1,id")
    for i in 1:n; println(io, join((d.y[i],d.x[i],d.w0[i],d.w1[i],d.id[i]),",")); end
end
sdI = @formula(sd(id, coef(intercept)) ~ w0); sdx = @formula(sd(id, coef(x)) ~ w1)
for (tag, sds) in (("both",(sdI,sdx)), ("slope",(sdx,)))
    t0=time()
    fit = drm(bf(@formula(y ~ x + (1 + x | id)), @formula(sigma ~ 1), sds...), Gaussian(); data = d)
    println(tag, " converged=", fit.converged, " ll=", loglik(fit), " t=", time()-t0, " ", [p.first for p in fit.blocks])
    se = stderror(fit)
    open(joinpath(O,"julia_coef_$tag.csv"),"w") do io
        println(io,"block,k,est,se"); pos=0
        for (k,b) in fit.blocks
            est = vec(coef(fit,k))
            for i in eachindex(est); pos+=1; println(io,"$k,$i,$(est[i]),$(se[pos])"); end
        end
    end
    th = coef(fit,:recov)[1]
    open(joinpath(O,"julia_ll_$tag.txt"),"w") do io; println(io, repr(loglik(fit)), " ", th/sqrt(1+th^2)); end
    println("npar se=",length(se))
end
