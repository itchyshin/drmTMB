using DRModels, LinearAlgebra
nwk = read("tree.nwk", String)
function readcsv(p)
    L = readlines(p); rows = [split(l, ',') for l in L[2:end]]
    col(j) = [r[j] for r in rows]
    (; y = parse.(Float64, col(1)), x = parse.(Float64, col(2)), z0 = parse.(Float64, col(3)),
       z1 = parse.(Float64, col(4)), id = String.(col(5)))
end
f = bf(@formula(y ~ x + phylo(1 + x | p | id)),
       @formula(sd(id, phylogenetic, coef(intercept)) ~ z0),
       @formula(sd(id, phylogenetic, coef(x)) ~ z1))
open("J_pars.csv", "w") do io; println(io, "seed,idx,est,se"); end
open("J_summary.csv", "w") do io; println(io, "seed,conv,ll,secs,rho,nonfinite_se,boundary,err"); end
for seed in 1:10
    d = readcsv("data/data_seed$(seed).csv")
    t0 = time()
    try
        fit = drm(f, Binomial(); data = d, tree = nwk)
        secs = time() - t0
        th = fit.theta; se = stderror(fit)
        rho = tanh(th[7])
        bnd = abs(rho) > 0.99 || any(abs.(th[3:6]) .> 5)
        open("J_pars.csv", "a") do io
            for i in eachindex(th); println(io, "$seed,$i,$(th[i]),$(se[i])"); end
        end
        open("J_summary.csv", "a") do io
            println(io, "$seed,$(fit.converged),$(loglikelihood(fit)),$secs,$rho,$(count(!isfinite, se)),$bnd,")
        end
    catch e
        open("J_summary.csv", "a") do io
            println(io, "$seed,NA,NA,$(time()-t0),NA,NA,NA,\"$(replace(sprint(showerror, e), '\n' => ' '))\"")
        end
    end
end
println("done")
